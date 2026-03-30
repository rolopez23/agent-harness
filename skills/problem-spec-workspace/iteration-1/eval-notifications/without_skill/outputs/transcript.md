# Transcript: Notifications Feature

## Approach

The user gave a vague request ("add notifications so users know when something happens") along with context: Rails + PostgreSQL, ~500 users, task management app.

Rather than asking clarifying questions upfront, I made reasonable assumptions based on the domain and proceeded directly to a spec. The rationale: for a well-understood feature like notifications in a task management app, the best clarifying questions are embedded in the spec itself (as "What to Decide Before Building"), which is more useful than a back-and-forth Q&A.

## Key Decisions Made

### 1. In-app only for v1
Email and push notifications are explicitly out of scope for the first version. The data model and service layer are designed to make email easy to add later (same service object, enqueue a mailer alongside the DB write).

### 2. Single `notifications` table with polymorphic notifiable
Chose a single table over separate tables per notification type. At 500 users and with a task management domain, the flexibility of a polymorphic reference outweighs the minor complexity. Keeps queries simple.

### 3. `read_at` timestamp instead of boolean
A nullable timestamp costs nothing extra and enables "read X minutes ago" display later without a schema change.

### 4. No stored message text
Generate display text at render time from `action` + `notifiable`. Avoids the problem of stale notification text when task names are edited.

### 5. Service object over model callbacks
`NotificationService` keeps notification logic explicit and testable. Avoids the "mysterious side effect" problem of ActiveRecord callbacks, which is a common Rails footgun for features like this.

### 6. Polling over WebSockets for real-time
At 500 users, a 30-second polling interval is entirely sufficient and adds zero infrastructure complexity. ActionCable/Turbo Streams is noted as a clean upgrade path.

### 7. Skipped notification preferences for v1
The `action` column makes it easy to add per-type preferences later. Adding preferences to v1 would double the complexity for unclear benefit at this scale.

## What Was Assumed

- Users can be assigned tasks (there's an `assignee` field on tasks)
- Tasks have an `owner` (creator or manager)
- Users can comment on tasks
- @mentions exist or are planned (included as a notification type but flagged as optional)
- The app uses Devise or similar for `current_user`
- Standard Rails MVC structure

## Estimated Effort

1-2 days for a working v1, broken into clear steps in the spec.

## Files Produced

- `spec.md` — Full implementation spec with schema, code samples, and implementation order
