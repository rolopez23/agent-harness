# Spec: Notifications

## Problem Statement

Users of the task management app have no way to know when relevant things happen — tasks being assigned to them, new comments on tasks they're involved with, or upcoming due dates — unless they manually check. This creates missed work and poor coordination. We need a notification system that alerts users to these events in-app and, for higher-priority events, via email.

## What We Are Solving

- A `notifications` table that stores per-user notification records, each tied to a specific event type and source object.
- Notifications are created when:
  - A task is assigned to a user (new task created with an assignee, or existing task reassigned to a new user).
  - A new comment is posted on a task where the recipient is involved (created the task, is the assignee, or has previously commented) — excluding notifications to the comment's own author.
  - A task's due date is within 24 hours (`due_at` between now and now+24h), checked by a periodic background job.
- An in-app notification feed: a JSON API endpoint that returns the authenticated user's notifications (unread count + list), ordered by recency.
- Opening the feed (GET request) marks all of the user's unread notifications as read atomically.
- Email delivery via ActionMailer/SendGrid for assignment events and due-date reminder events.
- A scheduled Sidekiq job that runs periodically (e.g., every 15 minutes) to enqueue due-date reminder notifications for tasks whose `due_at` falls in the next 24 hours and have not yet had a reminder sent.
- Auto-deletion of notification records older than 30 days, handled by a scheduled Sidekiq job.

## What We Are NOT Solving

- User-controlled notification preferences (which events trigger email or in-app alerts).
- Email notifications for comment events.
- Notifications for task unassignment.
- Repeating due-date reminders (e.g., 1-hour-before reminders); only one reminder per task, 24 hours before due.
- Per-notification read/dismiss actions; all notifications are bulk-marked read when the feed is opened.
- Real-time browser push (WebSockets / ActionCable) for the unread count or feed; polling or page refresh is acceptable.
- Mobile or browser push notifications.
- Notification grouping or threading.

## Actors & Triggers

| Actor / Trigger | Event |
|---|---|
| Any user or system action that assigns a task | Creates assignment notifications for the new assignee |
| Any user posting a comment | Creates comment notifications for all involved users except the commenter |
| Scheduled Sidekiq job (periodic, e.g., every 15 min) | Creates due-date reminder notifications for tasks with `due_at` within the next 24 hours that haven't yet received a reminder |
| Authenticated user opening the notification feed | Returns notification list; marks all unread as read |
| Scheduled Sidekiq job (daily or periodic) | Deletes notification records older than 30 days |

## Success Criteria

- When a task is assigned (created or reassigned), the assignee has a new unread notification record within the same request/transaction.
- When a comment is posted, all involved users (excluding the commenter) have new unread notification records within the same request/transaction.
- A user whose task is due in 23 hours has exactly one unread due-date reminder notification (not zero, not two).
- A task that has already had a reminder sent does not receive a second one on the next job run.
- `GET /api/notifications` returns the authenticated user's notifications (fields: id, event_type, read, created_at, and a summary payload) and the current unread count.
- After calling `GET /api/notifications`, all previously unread notifications for that user are marked read; a subsequent call returns unread count of 0 for those same records.
- Assignment and due-date reminder events result in a delivered email to the recipient's address via SendGrid (verifiable in SendGrid activity logs or ActionMailer test mode).
- Notification records with `created_at` older than 30 days are absent from the database after the cleanup job runs.
- Comment events do not produce email deliveries.

## Interfaces

### Schemas

**New table: `notifications`**

| Column | Type | Constraints | Notes |
|---|---|---|---|
| `id` | integer | PK | |
| `user_id` | integer | NOT NULL, FK → users.id | Recipient |
| `event_type` | string | NOT NULL | One of: `task_assigned`, `comment_posted`, `due_date_reminder` |
| `read` | boolean | NOT NULL, default false | |
| `notifiable_type` | string | NOT NULL | Polymorphic: e.g., `"Task"`, `"Comment"` |
| `notifiable_id` | integer | NOT NULL | Polymorphic source object ID |
| `created_at` | timestamp | NOT NULL | |
| `updated_at` | timestamp | NOT NULL | |

Index: `(user_id, read)` for efficient unread-count queries.
Index: `(notifiable_type, notifiable_id)` for dedup lookups.
Index: `created_at` for the cleanup job.

**New column on `tasks`: `reminder_sent_at`**

| Column | Type | Constraints | Notes |
|---|---|---|---|
| `reminder_sent_at` | timestamp | nullable | Set when a due-date reminder notification is created; used to prevent duplicate reminders |

**Existing table: `tasks`** (relevant columns, no changes except `reminder_sent_at` above)

| Column | Type | Notes |
|---|---|---|
| `id` | integer | PK |
| `title` | string | Used in notification summary |
| `assignee_id` | integer | FK → users.id, nullable |
| `creator_id` | integer | FK → users.id |
| `due_at` | timestamp | nullable; source for reminder scheduling |
| `project_id` | integer | FK → projects.id |

**Existing table: `comments`** (relevant columns, no changes)

| Column | Type | Notes |
|---|---|---|
| `id` | integer | PK |
| `task_id` | integer | FK → tasks.id |
| `author_id` | integer | FK → users.id |
| `body` | text | |
| `created_at` | timestamp | |

**Existing table: `users`** (relevant columns, no changes)

| Column | Type | Notes |
|---|---|---|
| `id` | integer | PK |
| `email` | string | Unique; used for email delivery |
| `name` | string | Used in email copy |

### Contracts

**`GET /api/notifications`**
- Auth: JWT Bearer token, validated by `Api::BaseController`.
- Response (200):
  ```json
  {
    "unread_count": 3,
    "notifications": [
      {
        "id": 42,
        "event_type": "task_assigned",
        "read": false,
        "created_at": "2026-03-28T10:00:00Z",
        "summary": "You were assigned to \"Fix login bug\""
      }
    ]
  }
  ```
- Side effect: all unread notifications for the authenticated user are marked `read = true` atomically (single UPDATE).
- Errors: 401 if token invalid/missing.

**`UserMailer` (existing class, new methods added)**
- `UserMailer#task_assigned(notification)` — emails the assignee; triggered synchronously or via ActiveJob after the notification record is created.
- `UserMailer#due_date_reminder(notification)` — emails the task owner; triggered by the due-date reminder job.
- Delivery: via existing SendGrid configuration (`config.action_mailer.delivery_method = :sendgrid_actionmailer`).
- No changes to existing mailer methods.

**Sidekiq jobs (new)**
- `DueDateReminderJob` — queries `tasks` where `due_at BETWEEN NOW() AND NOW() + INTERVAL '24 hours'` AND `reminder_sent_at IS NULL` AND `assignee_id IS NOT NULL`; creates notification records and enqueues mailer for each; sets `reminder_sent_at`. Inherits from `ApplicationJob`.
- `NotificationCleanupJob` — deletes `notifications` where `created_at < NOW() - INTERVAL '30 days'`. Inherits from `ApplicationJob`.

### Shared State

- **`tasks.assignee_id`**: read by the notification layer to determine the assignment recipient and by `DueDateReminderJob` to find eligible tasks. Owned by the task update flow; notifications are a consumer, not an authority.
- **`tasks.reminder_sent_at`**: written by `DueDateReminderJob` to prevent duplicate reminders. No other system currently writes this column; the job owns it.
- **`comments.author_id` and `comments.task_id`**: read by the notification layer to determine comment event recipients. Owned by the comment creation flow.
- **`notifications.read`**: written by the `GET /api/notifications` endpoint. The same table is written by the event triggers. Both paths must be safe under concurrent access (use DB-level update, not read-modify-write in Ruby).

## Open Questions

- **Who is "involved" in a task for comment notifications when a task has multiple past commenters?** Decided: creator + current assignee + any prior commenter (excluding the new commenter). Needs a query across the `comments` table to find prior commenters — confirm this is acceptable performance-wise at current scale (~500 users, typical task comment counts). *(Owner: developer to validate query plan before implementation.)*
- **`DueDateReminderJob` run frequency:** Every 15 minutes was suggested but not formally decided. At 15-minute intervals with a 24-hour lookahead window and `reminder_sent_at` guard, duplicates are prevented. Confirm cron schedule before implementation. *(Owner: developer.)*
- **Notification payload richness:** The spec defines a `summary` string. If the frontend later needs structured data (task ID, comment ID) to deep-link, the schema may need a `metadata` JSONB column. Deferred. *(Owner: developer + frontend.)*
