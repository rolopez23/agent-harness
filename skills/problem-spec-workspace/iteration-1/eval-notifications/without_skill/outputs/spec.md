# Notifications Feature Spec

**App:** Rails + PostgreSQL task management SaaS
**Scale:** ~500 users
**Date:** 2026-03-29

---

## What We're Solving

Users need to know when things happen in the app — task assigned to them, a comment on their task, a deadline approaching, etc. Right now they have no in-app feedback loop, which means they miss things and have to manually check.

## What We're NOT Solving (Yet)

- Email digests / email notifications (can be layered on later)
- Push notifications (mobile/PWA)
- Third-party integrations (Slack, webhooks)
- Notification preferences per-notification-type (phase 2)
- Real-time WebSocket delivery (nice-to-have, not required for v1)

---

## Notification Types (MVP)

Based on a task management app, the most valuable notification events are:

| Event | Trigger | Recipient |
|---|---|---|
| `task_assigned` | Task assigned to a user | Assignee |
| `task_commented` | Comment added to a task | Task owner + assignee (if different) |
| `task_completed` | Task marked done | Task owner (if they didn't complete it) |
| `task_due_soon` | Task due in 24 hours | Assignee |
| `task_overdue` | Task past due date | Assignee |
| `mentioned` | User @mentioned in comment | Mentioned user |

Start with `task_assigned` and `task_commented` — these have the clearest trigger points and highest value.

---

## Data Model

### `notifications` table

```sql
CREATE TABLE notifications (
  id          bigserial PRIMARY KEY,
  user_id     bigint NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  actor_id    bigint REFERENCES users(id) ON DELETE SET NULL,  -- who caused it
  action      varchar(50) NOT NULL,   -- 'task_assigned', 'task_commented', etc.
  notifiable_type  varchar(50) NOT NULL,  -- polymorphic: 'Task', 'Comment'
  notifiable_id    bigint NOT NULL,
  read_at     timestamp,
  created_at  timestamp NOT NULL DEFAULT now()
);

CREATE INDEX idx_notifications_user_unread
  ON notifications(user_id, read_at)
  WHERE read_at IS NULL;

CREATE INDEX idx_notifications_notifiable
  ON notifications(notifiable_type, notifiable_id);
```

Key decisions:
- `read_at` nullable timestamp (not a boolean) — lets you show "read X minutes ago" later if needed
- Polymorphic `notifiable` — keeps the table flexible without separate tables per type
- Soft data: notifications are cheap, keep them (or add a 90-day cleanup job later)
- No `message` text stored — generate display text from action + notifiable at render time. Avoids stale text when task names change.

### Rails Model

```ruby
class Notification < ApplicationRecord
  belongs_to :user
  belongs_to :actor, class_name: 'User', optional: true
  belongs_to :notifiable, polymorphic: true

  scope :unread, -> { where(read_at: nil) }
  scope :recent, -> { order(created_at: :desc).limit(50) }

  def read?
    read_at.present?
  end

  def mark_read!
    update!(read_at: Time.current) unless read?
  end
end
```

---

## Creating Notifications

Use a service object to keep logic out of models and callbacks:

```ruby
# app/services/notification_service.rb
class NotificationService
  def self.notify(user:, actor:, action:, notifiable:)
    return if user == actor  # don't notify yourself
    Notification.create!(
      user: user,
      actor: actor,
      action: action,
      notifiable: notifiable
    )
  end

  def self.task_assigned(task, assigned_by:)
    return unless task.assignee
    notify(
      user: task.assignee,
      actor: assigned_by,
      action: 'task_assigned',
      notifiable: task
    )
  end

  def self.task_commented(comment)
    task = comment.task
    recipients = [task.owner, task.assignee].compact.uniq - [comment.user]
    recipients.each do |user|
      notify(user: user, actor: comment.user, action: 'task_commented', notifiable: comment)
    end
  end
end
```

Call from controllers or model callbacks — controllers are cleaner and avoid callback hell:

```ruby
# In TasksController#update
if @task.save
  NotificationService.task_assigned(@task, assigned_by: current_user) if assignee_changed?
  # ...
end
```

---

## API / Controller

```ruby
# config/routes.rb
resources :notifications, only: [:index] do
  collection do
    patch :mark_all_read
  end
  member do
    patch :mark_read
  end
end
```

```ruby
# app/controllers/notifications_controller.rb
class NotificationsController < ApplicationController
  before_action :authenticate_user!

  def index
    @notifications = current_user.notifications.recent.includes(:actor, :notifiable)
    @unread_count = current_user.notifications.unread.count
  end

  def mark_read
    notification = current_user.notifications.find(params[:id])
    notification.mark_read!
    head :ok
  end

  def mark_all_read
    current_user.notifications.unread.update_all(read_at: Time.current)
    head :ok
  end
end
```

---

## UI

### Bell Icon in Nav

Show an unread count badge. Keep it simple:

```erb
<!-- app/views/layouts/_navbar.html.erb -->
<%= link_to notifications_path do %>
  <span class="bell-icon">&#x1F514;</span>
  <% if current_user.unread_notifications_count > 0 %>
    <span class="badge"><%= current_user.unread_notifications_count %></span>
  <% end %>
<% end %>
```

Add a helper on User:

```ruby
# app/models/user.rb
def unread_notifications_count
  notifications.unread.count
end
```

Cache this with Rails.cache if it becomes a hot query:
```ruby
def unread_notifications_count
  Rails.cache.fetch("user_#{id}_unread_notifications", expires_in: 1.minute) do
    notifications.unread.count
  end
end
```

Invalidate on notification create/read.

### Notification List Page

Simple list at `/notifications`:

```erb
<!-- app/views/notifications/index.html.erb -->
<% @notifications.each do |n| %>
  <div class="notification <%= 'unread' unless n.read? %>">
    <span class="actor"><%= n.actor&.name || 'Someone' %></span>
    <span class="action"><%= notification_text(n) %></span>
    <span class="time"><%= time_ago_in_words(n.created_at) %></span>
  </div>
<% end %>
```

```ruby
# app/helpers/notifications_helper.rb
def notification_text(notification)
  case notification.action
  when 'task_assigned'
    "assigned you the task \"#{notification.notifiable.title}\""
  when 'task_commented'
    "commented on \"#{notification.notifiable.task.title}\""
  when 'task_completed'
    "completed \"#{notification.notifiable.title}\""
  when 'mentioned'
    "mentioned you in \"#{notification.notifiable.task.title}\""
  else
    "did something"
  end
end
```

---

## Performance Considerations

At 500 users this is not a scaling problem. However:

1. **Index on `(user_id, read_at)` with partial index for unread** — covered above, fast for the common query
2. **Avoid N+1** — always `includes(:actor, :notifiable)` in the controller
3. **Unread count caching** — only if you're hitting the DB on every page load (nav bar badge). With 500 users this is probably fine without cache initially.
4. **Cleanup job** — after 90 days, notifications can be deleted. Add a recurring job with `whenever` or Sidekiq scheduler later.

---

## Real-Time (Optional, Phase 2)

For v1, polling is fine. Add a simple JS snippet that hits `/notifications/unread_count` every 30 seconds and updates the badge. No WebSockets needed at this scale.

```javascript
// Minimal polling approach
setInterval(() => {
  fetch('/notifications/unread_count')
    .then(r => r.json())
    .then(data => {
      document.querySelector('.notification-badge').textContent = data.count || '';
    });
}, 30000);
```

Add the endpoint:
```ruby
def unread_count
  render json: { count: current_user.notifications.unread.count }
end
```

Real-time via ActionCable or Hotwire Turbo Streams would be a clean upgrade path later since you're on Rails.

---

## Implementation Order

1. **Migration + Model** (1-2 hours) — create the table, model, associations
2. **NotificationService** (1 hour) — service object, start with `task_assigned`
3. **Controller + Routes** (1 hour) — index, mark_read, mark_all_read
4. **Nav badge** (30 min) — bell icon with unread count
5. **Notification list page** (1-2 hours) — simple list view
6. **Wire up remaining events** (1-2 hours) — add other notification types
7. **Optional: polling** (30 min) — JS polling for badge updates

Total estimated effort: ~1-2 days for a working v1.

---

## What to Decide Before Building

1. **Which events matter most to your users?** The table above is a guess — validate against what users actually complain about missing. `task_assigned` and `@mentions` are almost always the top two.
2. **Do you want email notifications too?** If yes, the same `NotificationService` can enqueue a mailer job alongside creating the DB record. Design for this now even if you don't implement it.
3. **Should users be able to turn off specific notification types?** Skip for v1, but the `action` column makes it easy to add a `NotificationPreference` model later.

---

## Files to Create/Modify

| File | Change |
|---|---|
| `db/migrate/TIMESTAMP_create_notifications.rb` | New migration |
| `app/models/notification.rb` | New model |
| `app/models/user.rb` | Add `has_many :notifications` + helper |
| `app/services/notification_service.rb` | New service |
| `app/controllers/notifications_controller.rb` | New controller |
| `app/helpers/notifications_helper.rb` | New helper |
| `app/views/notifications/index.html.erb` | New view |
| `app/views/layouts/_navbar.html.erb` | Add bell icon |
| `config/routes.rb` | Add notification routes |
