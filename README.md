# iDriver Operations & Growth Command Center — Neomorphic Public Dashboard

Plain PHP + MySQL build for XAMPP. No Laravel, Artisan, Composer install, or `/public` routing is required.

## Run on XAMPP

1. Extract the folder as `C:\xampp\htdocs\idriver-command-center`.
2. Start Apache and MySQL in XAMPP.
3. Open `http://localhost/idriver-command-center/`.
4. On a fresh database, the browser setup screen prepares the schema and creates the first Super Administrator.

The project root is the read-only public dashboard. Admin sign-in is available at `http://localhost/idriver-command-center/login.php`.

## New public experience

The public dashboard uses a light professional neomorphic visual system with soft raised/inset surfaces, animated loading/reload state, responsive charts, live counters, driver campaign progress, team capacity, campaign cards, activity feed, and task operations.

Employee task performance is calculated as:

`completed non-cancelled assigned tasks / all non-cancelled assigned tasks * 100`

Each active employee can display:

- completion percentage from 0–100%
- assigned and completed tasks
- in-progress and overdue task counts
- average task progress
- public task list with title, status, priority, category, due date and task progress

Collaborator assignments from `task_assignees` and the primary assignee are both counted once.

## Admin-managed branding

Go to **Admin > Settings > Public Dashboard Control Center** to:

- upload/update the navbar logo (PNG/JPG/WebP, max 2 MB)
- change company name and navbar subtitle
- edit public hero text and announcement
- control public refresh frequency and footer text
- show/hide Driver Growth
- show/hide Employee Performance
- show/hide Employee Task Lists
- show/hide Operations / recent task table
- show/hide Team, Campaigns and Activity

The uploaded logo is used on the public navbar/footer and the admin sidebar. If no logo is uploaded, the built-in `iD` mark is shown.

## Public security

The public dashboard is read-only. It does not expose employee emails/contact numbers, driver names/phone numbers, credentials, private notes, or audit-log internals. All mutating handlers still require an authenticated user, permission checks, and CSRF protection.

## Database

Fresh-install schema: `database/idriver_command_center.sql`.

If upgrading the immediately previous plain-PHP public-dashboard build, there are no new tables or columns. The new public settings are created automatically when Admin saves the Public Dashboard settings. Logo settings are created automatically on upload.

## Main folders

- `admin/` — admin entry
- `api/` — live dashboard endpoints
- `assets/css/` — public/admin neomorphic UI
- `assets/js/` — animation, charts, live refresh
- `assets/uploads/branding/` — admin-uploaded navbar logo
- `handlers/` — authenticated form actions
- `includes/` — database, security, layout and public-data logic
- `database/` — MySQL schema

## Validation

Run-time requirements: PHP 8.2+, PDO MySQL, MySQL 8+, Apache/XAMPP.

## Demo data included

Fresh installations now include realistic demo content so the public dashboard is populated immediately:

- 6 sample employee user accounts
- 45 verified sample drivers counted toward the active campaign
- 30 sample tasks (5 per employee)
- Employee task completion profiles: 100%, 80%, 60%, 40%, 20%, and 0%
- Mixed task statuses, priorities, deadlines, progress values, registration sources, and employee assignments

Sample user password: `Demo@12345`

Sample accounts:

- `layla.demo@idriver.local` — Manager
- `omar.demo@idriver.local` — Employee
- `noor.demo@idriver.local` — Employee
- `rafiq.demo@idriver.local` — Employee
- `maya.demo@idriver.local` — Employee
- `samir.demo@idriver.local` — Employee

Existing installations can load the same data from **Admin > Settings > Demo workspace > Load demo data**. The operation is idempotent and the demo button will report when the seed is already loaded.

## Full CRUD coverage

Authorized administrators now have complete Create / Read / Update / Delete flows for:

- Drivers: create, search/read, edit, verify, delete, export
- Employees: create, read, edit, activate/deactivate, delete
- Tasks: create, read on Kanban, edit all major fields, progress/status updates, delete
- Campaigns: create, read, edit name/dates/target/manager/status/notes, delete

The public dashboard remains read-only and exposes only privacy-safe operational information.


## Count-only registration workflow

The current build does not require customer or driver personal details for growth reporting. Admin uses **Registration Counts** to save one daily record containing only:

- Date
- Customers registered
- Drivers registered

The system calculates Today, Yesterday, 7-day, campaign, and all-time totals automatically. The public root page is a compact one-screen command center, and the Task List button opens a detailed read-only task drawer.

## Professional Kanban Task Workflow
The task module supports optional descriptions, starting workflow status/progress, independent assignment to all active employees, duplication, and authenticated drag-and-drop status changes across Backlog, To Do, In Progress, Blocked, In Review, and Completed. Team-wide assignment creates one independent task record per employee so employee completion percentages remain accurate.
