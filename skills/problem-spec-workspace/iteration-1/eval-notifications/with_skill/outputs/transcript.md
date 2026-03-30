# Transcript: Notifications Feature — Problem Specification Session

## Initial Request

**User:** I want to add notifications to my app so users know when something happens.

---

## Step 1: Understand the Problem

**AI:** Thanks — let's make sure I understand what you're going for before we get into any design. A few questions to start:

Can you describe the app? What kind of "something happens" are you referring to — are there specific events you have in mind? And when you say users should "know," do you mean they see a notification inside the app, get an email, a push notification, or something else?

**User:** It's a task management SaaS app built in Rails with Postgres, about 500 users. The main events I care about are: when a task is assigned to you, when someone comments on a task you're involved with, and when a task's due date is approaching. I'm thinking in-app notifications first — like a little bell icon with a count — but I also want email for the more important ones.

**AI:** Got it. Let me restate to confirm: you want to build a notification system for your task management app that captures specific task-related events (assignment, comments, due date reminders), stores them per-user, and surfaces them in two ways: an in-app notification feed (with an unread count) and email delivery for selected events. Does that capture it?

**User:** Yes, exactly.

---

## Step 2: Clarifying Questions

**AI:** Great. A couple of questions about the events:

For "task assigned to you" — does this fire when a new task is created and assigned, or also when an existing task is reassigned to someone new? And if a task is unassigned (assignee removed), does anything happen?

**User:** Both cases — new task created with an assignee, and reassignment. Unassignment doesn't need a notification.

---

**AI:** For comments — you said "a task you're involved with." Can you define "involved"? Does that mean: you created the task, you're the assignee, or you've previously commented on it? Could be all three, or just some.

**User:** All three — if you created it, you're assigned to it, or you've commented on it before, you get notified about new comments. But you shouldn't get notified about your own comments.

---

**AI:** For due date reminders — how far in advance should the reminder fire? And is this a one-time notification or can it repeat (e.g., 24 hours before AND 1 hour before)?

**User:** Just once, 24 hours before the due date. No repeats.

---

**AI:** For email — which of the three event types should trigger an email, and which are in-app only?

**User:** Assignment and due date reminders should send email. Comments are in-app only.

---

**AI:** A couple more on delivery:

Can users control which notifications they receive — for example, can they turn off email for due date reminders? Or is this a fixed system with no user preferences for now?

**User:** No preferences for now. Everyone gets the same thing. We can add that later.

---

**AI:** For the in-app notification feed — when a user reads a notification (or opens the feed), do all notifications in the feed get marked as read, or does each notification have to be individually dismissed?

**User:** Opening the feed marks all as read. No individual dismissal needed.

---

**AI:** One more: is there a limit to how long notifications persist? Should old notifications be deleted after some period (e.g., 30 days), or do they accumulate indefinitely?

**User:** Let's say 30 days. Auto-delete anything older than that.

---

**AI:** Last question before we define scope: for due date reminders, what's the source of truth for the due date — is it stored on the tasks table already? And what's the mechanism you'd expect to use for scheduling (a cron job, background worker, etc.)? I'm not asking for your implementation choice yet, just whether a scheduled job is an acceptable constraint.

**User:** Yes, due date is a `due_at` timestamp on the `tasks` table. And yes, a background job running periodically is fine — we already use Sidekiq.

---

## Step 3: Define the Boundary

**AI:** Let me confirm what's in and out of scope.

**In scope (confirming):**
- A `notifications` table storing per-user notification records
- Notification creation triggered by: task assignment (new or reassignment), new comment on a task where the user is involved, and due-date reminder 24h before `due_at`
- An in-app notification feed endpoint (unread count + list)
- Marking all notifications read when the feed is opened
- Email delivery for assignment and due-date reminder events
- Auto-deletion of notifications older than 30 days

**Out of scope (confirming):**
- User notification preferences / settings UI
- Push notifications (mobile or browser)
- Comment notifications via email
- Unassignment notifications
- Repeating due-date reminders
- Read receipts per individual notification
- Real-time push to the browser (websockets/ActionCable) for the unread count

Does that match your intent? Anything to move in or out?

**User:** That all looks right. Yes, no real-time push for now — polling or page-refresh is fine.

---

## Step 4: Define Interfaces

**AI:** Now let's nail down the interfaces. What does the `tasks` table look like? I need the relevant columns.

**User:** The relevant columns are: `id` (integer), `title` (string), `assignee_id` (integer, FK to users), `creator_id` (integer, FK to users), `due_at` (timestamp, nullable), `project_id` (integer).

**AI:** And comments — is there a `comments` table? What columns are relevant?

**User:** Yes: `id`, `task_id` (FK to tasks), `author_id` (FK to users), `body` (text), `created_at`.

**AI:** What does the `users` table look like — specifically do you have an email column, and is there anything controlling whether a user account is active?

**User:** `id`, `email` (string, unique), `name` (string), `created_at`. No soft-delete or active flag — all rows are active users.

**AI:** For email delivery — are you already using a mailer gem or service? ActionMailer with something like SendGrid, or something else?

**User:** ActionMailer with SendGrid via the `sendgrid-ruby` gem. We have a `UserMailer` class already.

**AI:** For Sidekiq — do you have an existing job infrastructure? Any base job class or conventions I should know about?

**User:** We have `ApplicationJob < ActiveJob::Base` and use `ApplicationJob` as the base for all jobs. Jobs live in `app/jobs/`.

**AI:** One last interface question: for the in-app feed, will this be a JSON API endpoint consumed by a JS frontend, or a Rails controller rendering HTML?

**User:** JSON API — we have a React frontend that calls our Rails API. Auth is handled via JWT tokens in the Authorization header. We have a base `Api::BaseController` that handles auth.

---

## Step 5: Spec Written

**AI:** I have everything I need. Writing the spec now.

The feature name is `notifications`. Spec saved to `docs/notifications/spec.md`.

Please review it before any implementation begins.
