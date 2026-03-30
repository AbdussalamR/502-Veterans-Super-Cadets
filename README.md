*** GO TO RAHEEM'S PERSONAL REPO TO VIEW PR HISTORY ***
https://github.com/AbdussalamR/502-Veterans-Super-Cadets

# Singing Cadets Events & Attendance Platform

A comprehensive web application for managing events, attendance, disciplinary actions, member workflows, public website content, and booking inquiries for the Texas A&M Singing Cadets organization.

## Table of Contents
- [Description](#description)
- [Requirements](#requirements)
  - [Internal Components](#internal-components)
  - [External Dependencies](#external-dependencies)
- [Environmental Variables/Files](#environmental-variablesfiles)
- [Installation & Setup](#installation--setup)
- [Usage](#usage)
- [Features](#features)
- [Documentation](#documentation)
- [Credits & Acknowledgements](#credits--acknowledgements)
- [Third-Party Libraries](#third-party-libraries)
- [Contact Information](#contact-information)

## Description

The Singing Cadets Events & Attendance Platform is a full-stack Ruby on Rails application designed to streamline operations for the Texas A&M Singing Cadets. The platform provides comprehensive tools for managing member attendance (including tardy tracking), tracking disciplinary actions, processing absence excuses, coordinating events, and facilitating administrative workflows with role-based access control.

Phase 2 (Spring 2026) expanded the platform significantly. A fully public-facing website was added (Home, Book Us, Media Gallery, Auditions, Calendar, Contact), along with a Director-only Website Management dashboard for editing and publishing all public content without developer involvement. An async email notification system was built (event reminders, excuse status updates, failed-delivery alerts) using SendGrid for delivery and Cloudinary for image hosting. The excuse workflow gained personal/private routing directly to the Director, section-based filtering for Officers, and recurring excuse patterns. The navigation was reorganized for usability, and all views were updated for WCAG accessibility compliance.

Built with Ruby on Rails 8.0, PostgreSQL, Bootstrap 5, and Stimulus JavaScript framework. The application supports three user roles (members, officers, and directors) with distinct permissions. It features Google OAuth2 authentication, an absence point system, multi-event excuse management with two-tier approval, self-check-in with passcodes, calendar subscription feeds (iCal/RSS), an async background job queue (Solid Queue), and a CMS-style public website.

## Requirements

### Internal Components

**Core Application Stack:**
- **Ruby** 3.2+ (programming language)
- **Ruby on Rails** 8.0.0 (web application framework)
- **PostgreSQL** 9.3+ (relational database)
- **Bundler** 2.0+ (Ruby dependency manager)

**Ruby Gems (Dependencies):**
- **devise** - User authentication framework
- **omniauth-google-oauth2** (~> 1.1) - Google OAuth2 strategy
- **omniauth-rails_csrf_protection** - CSRF protection for OmniAuth
- **pg** (~> 1.1) - PostgreSQL adapter
- **puma** (>= 5.0) - Web server
- **turbo-rails** - Hotwire's SPA-like page accelerator
- **stimulus-rails** - JavaScript framework for progressive enhancement
- **importmap-rails** - JavaScript module management (no Node.js/Yarn required)
- **propshaft** - Modern asset pipeline
- **bootsnap** - Boot time optimization
- **lograge** - Structured logging
- **logstash-event** - JSON logging format
- **icalendar** - iCalendar (.ics) feed generation
- **yaml_db** - YAML database utilities
- **solid_cable** - Database-backed ActionCable adapter
- **solid_cache** - Database-backed cache store
- **solid_queue** - Database-backed background job queue (used for async notifications)
- **kamal** - Docker-based deployment tool
- **thruster** - HTTP asset caching/compression
- **jbuilder** - JSON API response builder
- **nokogiri** (~> 1.16.2) - HTML/XML parsing
- **rexml** - XML processing (Ruby 3.x compatibility)
- **mutex_m** - Thread synchronization (Ruby 3.4 compatibility)
- **sendgrid-ruby** - SendGrid API client for transactional email delivery
- **cloudinary** (~> 1.28) - Cloudinary API client for image hosting via Active Storage

**Development & Testing:**
- **rspec-rails** - Testing framework
- **factory_bot_rails** - Test data generation
- **capybara** - Integration testing
- **selenium-webdriver** - Browser automation for testing
- **simplecov** - Code coverage analysis (95%+ maintained)
- **brakeman** - Security vulnerability scanner
- **rubocop-rails-omakase** - Ruby style guide enforcement
- **dotenv-rails** - Environment variable management

**Database Structure:**
- **Users** - Authentication, roles (user/officer/super_admin), approval workflow, section assignment, calendar_token, email_notifications_enabled preference
- **Sections** - Named voice sections (e.g. Tenor 1, Bass 2) for member organization
- **Events** - Rehearsals and performances with date/time/location, self-check-in capability
- **Attendances** - Per-user-per-event records with status (present/excused/absent/tardy)
- **Excuses** - Multi-event excuse submissions with recurring fields (start_date, end_date, recurring_days, time window), is_personal flag, two-tier approval (officer_status + final status)
- **Demerits** - Disciplinary point tracking
- **EventsToExcuse** - Many-to-many join between events and excuses
- **ReviewersToExcuse** - Reviewer audit trail for excuse approvals
- **PageContent** - CMS records for all public website pages (page, key, value, draft/published)
- **MediaPhoto** - Photo records for the public media gallery (Cloudinary-hosted, published flag)
- **MediaVideo** - Video records for the media gallery (YouTube URL, published flag)
- **PerformanceRequest** - Booking inquiries submitted via the public form (name, organization, event_date, location, contact_email, status)
- **ContactMessage** - Messages submitted via the public contact form (read/unread status)
- **AdminAlert** - In-app notification banners shown to Directors when email delivery fails
- **ApplicationSetting** - Singleton for system-wide config (reminder_hours_before for event reminders)
- **AuditionSession** - Audition date and time slots managed by the Director

### External Dependencies

**Third-Party Services:**
- **Google Cloud Platform** - OAuth2 authentication provider
  - Google OAuth 2.0 API for single sign-on
  - Requires valid Google Client ID and Secret
  - Configured redirect URIs for development and production
- **SendGrid** - Transactional email delivery (excuse notifications, event reminders, director alerts)
  - Requires a SendGrid account and API key
  - Used via the `sendgrid-ruby` gem through a custom `Notifications::EmailDelivery` service
- **Cloudinary** - Cloud image hosting for Active Storage
  - Stores uploaded media photos and user profile images
  - Requires a Cloudinary account (free tier sufficient for development)
  - Configured via `CLOUDINARY_URL` environment variable

**Front-End Libraries (via CDN):**
- **Bootstrap 5.1.3** - CSS framework for responsive design
- **Bootstrap Icons 1.8.1** - Icon library
- **FullCalendar** (optional) - Interactive calendar display on the public calendar page

**Deployment Services (Optional):**
- **Heroku** - Cloud platform (production deployment)
- **Docker Compose** - PostgreSQL 16 for local development and test suite
- **Kamal** - Docker-based deployment tool

**External APIs:**
- Google OAuth2 API (accounts.google.com)
- SendGrid Web API v3 (api.sendgrid.com)
- Cloudinary Upload & Delivery API

## Environmental Variables/Files

**Required Environment Variables:**

```bash
# Database Configuration
DATABASE_USER=your_postgres_username
DATABASE_PASSWORD=your_postgres_password
RAILS_MAX_THREADS=5

# Google OAuth2 Configuration (REQUIRED)
GOOGLE_CLIENT_ID=your_google_client_id
GOOGLE_CLIENT_SECRET=your_google_client_secret

# Super Admin Emails (Optional - comma-separated list)
SUPER_ADMIN_EMAILS=admin1@tamu.edu,admin2@tamu.edu

# Application Host (Optional - used for OAuth callback URLs)
APP_HOST=your-app.herokuapp.com

# Email Notification Delivery via SendGrid (required in production)
SENDGRID_API_KEY=your_sendgrid_api_key
NOTIFICATION_FROM_EMAIL=no-reply@your-domain.com
NOTIFICATION_FROM_NAME=Singing Cadets
NOTIFICATION_REPLY_TO=leadership@your-domain.com

# Cloudinary Image Hosting (required for media uploads)
# Set the full URL (preferred) - provided by Cloudinary dashboard
CLOUDINARY_URL=cloudinary://api_key:api_secret@cloud_name
# OR set individual variables:
CLOUDINARY_CLOUD_NAME=your_cloud_name
CLOUDINARY_API_KEY=your_api_key
CLOUDINARY_API_SECRET=your_api_secret

# Rails Environment
RAILS_ENV=development  # or production

# Production-Only Variables
RAILS_MASTER_KEY=your_master_key_for_credentials
RAILS_SERVE_STATIC_FILES=true
RAILS_LOG_TO_STDOUT=true
```

**Configuration Files:**

- `config/database.yml` - Database connection settings
- `config/solid_queue.yml` - Background job worker/dispatcher settings for async notification delivery
- `config/credentials.yml.enc` - Encrypted credentials (use `rails credentials:edit`)
- `config/master.key` - Master key for credentials (DO NOT commit to version control)
- `config/storage.yml` - Active Storage configuration (Cloudinary in production, local disk in development)
- `.env` (optional) - Environment variables for local development (managed by dotenv-rails)

**Setting Up Google OAuth2:**

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select existing project
3. Enable Google+ API
4. Configure OAuth consent screen
5. Create OAuth 2.0 Client ID credentials
6. Add authorized redirect URIs:
   - Development: `http://localhost:3000/auth/google_oauth2/callback`
   - Production: `https://your-domain.com/auth/google_oauth2/callback`
7. Copy Client ID and Client Secret to environment variables

**Setting Up SendGrid:**

1. Create a free account at [SendGrid](https://sendgrid.com/)
2. Go to Settings > API Keys and create a key with "Mail Send" permissions
3. Add the key to your environment as `SENDGRID_API_KEY`
4. Set `NOTIFICATION_FROM_EMAIL` to a verified sender address in your SendGrid account

**Setting Up Cloudinary:**

1. Create a free account at [Cloudinary](https://cloudinary.com/)
2. Copy the `CLOUDINARY_URL` from your dashboard (Environment variable section)
3. Add it to your `.env` file
4. In production, set it as an environment variable on your hosting platform

## Installation & Setup

### Option 1: Local Development Setup

**Prerequisites:**
```bash
# Install Ruby 3.2+ (using rbenv or rvm)
rbenv install 3.2.0
rbenv global 3.2.0

# Install PostgreSQL
# macOS: brew install postgresql
# Ubuntu: sudo apt-get install postgresql postgresql-contrib
```

**Setup Steps:**

1. **Clone the repository:**
   ```bash
   git clone [repository-url]
   cd [repository-name]
   ```
   *Note: Contact the Texas A&M Singing Cadets organization for the current repository URL.*

2. **Install dependencies:**
   ```bash
   bundle install
   ```

3. **Configure environment variables:**
   ```bash
   # Copy the example env file and fill in your values
   cp .env.example .env
   # Edit .env with your Google OAuth, SendGrid, and Cloudinary credentials
   ```

4. **Set up the database:**
   ```bash
   rails db:create
   rails db:migrate
   rails db:seed  # optional
   ```

5. **Start the background job worker** (required for email notifications):
   ```bash
   # In a second terminal window:
   bundle exec rake solid_queue:start
   ```

6. **Start the development server:**
   ```bash
   rails server
   # Or: rails s -b 0.0.0.0 -p 3000
   ```

7. **Access the application:**
   - Open browser to http://localhost:3000
   - The root URL redirects to the public home page (`/public/home`)
   - Sign in at `/auth/sign_in` with Google OAuth

### Option 2: Docker Compose (Database Only)

The included `docker-compose.yml` provides a PostgreSQL 16 instance for local development and is also used by the test suite.

**Prerequisites:**
- Docker Desktop installed

**Setup Steps:**

1. **Start the PostgreSQL container:**
   ```bash
   docker-compose up -d
   ```
   This starts PostgreSQL on port **5433** (mapped from container port 5432).

2. **Configure database connection:**
   ```bash
   DATABASE_USER=postgres
   DATABASE_PASSWORD=postgres
   DATABASE_PORT=5433
   ```

3. **Set up and run the Rails app locally:**
   ```bash
   bundle install
   rails db:create
   rails db:migrate
   rails server
   ```

   > **Note for tests:** The Docker test container uses `rails db:schema:load` (not `db:migrate`) to set up the test database. Always ensure `db/schema.rb` is up to date before running the test suite.

4. **Access the application:**
   - Open browser to http://localhost:3000

### Setting Up Admin/Officer Roles

**Method 1: Environment Variables**
Add super admin emails to `SUPER_ADMIN_EMAILS` environment variable before first login.

**Method 2: Rails Console**

1. Sign in with Google OAuth to create your user account
2. Open Rails console:
   ```bash
   rails console
   ```

3. Update user role:
   ```ruby
   user = User.find_by(email: "your.email@tamu.edu")

   user.update!(role: 'super_admin', approval_status: 'approved')  # Director
   user.update!(role: 'officer', approval_status: 'approved')      # Officer
   user.update!(role: 'user', approval_status: 'approved')         # Member
   ```

4. Sign out and sign back in to apply changes

### Setting Up Sections (Optional)

Sections (e.g. "Tenor 1", "Bass 2") can be created by a Director via the app at
`/internal/sections`, or seeded via the Rails console:

```ruby
Section.create!(name: "Tenor 1")
Section.create!(name: "Tenor 2")
Section.create!(name: "Bass 1")
Section.create!(name: "Bass 2")
```

Members can then be assigned to sections via the User Management page.

## Usage

### User Roles & Permissions

**Members (role: 'user'):**
- View personal attendance history and statistics
- View personal demerit records and absence points
- Submit absence excuses (single, multi-event, recurring, or personal/private)
- Cancel recurring excuses for future events
- Self-check-in to events (when enabled, within the check-in time window)
- Subscribe to event calendar feeds (iCal/RSS)
- Receive email notifications when an excuse is approved or denied

**Officers (role: 'officer'):**
- All member permissions, plus:
- Take attendance for events
- Create, edit, and delete events
- Make a provisional approve/deny decision on excuse submissions for members in their own section
- Issue and manage demerits
- View comprehensive member attendance reports
- Approve or reject member registrations
- Manage event check-in passcodes

**Directors/Super Admins (role: 'super_admin'):**
- All officer permissions, plus:
- Final approval/denial of all excuses (after officer provisional review)
- Access personal/private excuses (hidden from officers)
- Manage public website content via the Website Management dashboard
- View and respond to Performance Booking requests
- View and dismiss contact form messages
- Configure notification reminder window (e.g. 24 or 48 hours before an event)
- Receive in-app alerts when email delivery fails
- Promote/demote user roles
- Manage sections
- Manage audition sessions and public audition page content

### Common Workflows

**Taking Attendance (Officers/Directors):**
1. Navigate to Events
2. Select event, click "Take Attendance"
3. Mark each member as Present, Absent, Excused, or Tardy
4. Add optional notes, save

**Self-Check-In (Members):**
1. Navigate to the event page
2. Click "Self Check-In" (available within ±10 minutes of event start through end time)
3. Enter the 4-digit passcode provided by an officer
4. Attendance is automatically recorded as "Present"

**Submitting an Excuse (Members):**
1. Navigate to Excuses > New Excuse
2. **Single/multi-event:** Select one or more events from the list
3. **Recurring:** Toggle "Mark as Recurring", select days of the week, date range, and time window
4. Enter a reason and proof link (URL to documentation)
5. Check "Personal Reason" if the matter is sensitive — this routes directly to the Director and is hidden from officers
6. Submit — the system notifies the appropriate reviewers automatically

**Processing Excuses (Two-Tier Approval):**
1. **Officer Review:** Officer sees pending excuses for their section, makes a provisional approve/deny
2. **Director Review:** Director makes the final decision (approve/deny)
3. On final approval, attendance records for all linked events are automatically updated to "Excused"
4. On final denial, any previously excused records revert to "Absent"
5. The member receives an email notification with the outcome

**Managing the Public Website (Directors):**
1. Navigate to Manage > Website Management
2. Select the page tab (Home, Book Us, Auditions, Media, Contact, Messages)
3. Edit content fields and click Save Draft
4. Click Preview to verify how the page looks before publishing
5. Click Publish to push the changes live

**Handling Performance Booking Requests (Directors):**
1. An external organizer fills out the public form at `/public/performance_request`
2. The Director receives an email notification and sees a badge in the nav bar
3. Navigate to Manage > Website Management > Book Us tab
4. Review the request details and mark as Reviewed when processed

**Configuring Email Reminders (Directors):**
1. Navigate to Manage > Notification Settings
2. Set the number of hours before an event that reminders should be sent (e.g. 24 or 48)
3. Save — the `Notifications::EventReminderJob` background job uses this setting on its next run

**Member Registration Approval (Officers/Directors):**
1. Navigate to Manage > Registration Approval
2. Review pending applications, approve or reject

**Calendar Subscription:**
1. Each user has a unique calendar token (generated automatically)
2. Subscribe to the iCal feed URL in any calendar app (Google Calendar, Apple Calendar, etc.)
3. Events sync automatically

## Features

### Core Functionality

**Authentication & Authorization:**
- Google OAuth2 single sign-on integration
- Email format validation on OAuth sign-in (helpful error message for malformed addresses)
- Role-based access control (3 tiers: member, officer, director)
- Registration approval workflow (pending/approved/rejected)
- Section-based access: officers only see excuses for members in their own section

**Public Website:**
- Home page with hero section, editable text, and published photo gallery
- Performance Request (Book Us) page — public booking inquiry form (no login required)
- Media Gallery with published photos and YouTube videos, lightbox modal
- Audition Information page with editable requirements and upcoming audition session schedule
- Interactive public calendar (FullCalendar)
- Contact page with contact form and social media links
- All pages follow WCAG accessibility standards (skip navigation, aria-labels, live regions, 44 px touch targets)

**Website Management Dashboard (Directors only):**
- Edit and publish content for every public page without a developer
- Draft/save workflow — changes are saved as drafts and only go live on Publish
- Preview page before publishing to the live site
- Upload and manage photos (Cloudinary-hosted, publish/unpublish per image)
- Add YouTube video links and manage the video gallery
- Manage audition session dates and times
- View and dismiss contact form messages (read/unread tracking)
- View and manage performance booking requests (mark as reviewed)

**Email Notification System:**
- **Event reminders:** Configurable hours-before-event reminders sent to all approved members
- **Excuse submitted:** Notifies section officers (or Director for personal excuses) when a member submits
- **Excuse decided:** Notifies the member when a Director approves or denies their excuse
- **New performance request:** Notifies all Directors when a public booking inquiry is received
- **Failed email alert:** Creates an in-app AdminAlert banner visible to all Directors if a send fails
- **Email opt-out:** Members can disable email notifications from their profile; the system respects the preference at the job level
- Powered by SendGrid via the `sendgrid-ruby` gem; delivered asynchronously via Solid Queue

**Event Management:**
- Create rehearsals and performances with title, date, end time, location, and description
- Recurring weekly event creation
- Enable/disable self-check-in per event with auto-generated 4-digit passcodes
- Self-check-in time window enforcement
- Calendar feed subscriptions (iCal .ics and RSS formats)

**Attendance Tracking:**
- Four statuses: present, absent, excused, tardy
- Absence point system: absences 1 pt, tardies 0.33 pt, demerits value × 0.33 pt
- Attendance automatically updated when an excuse is approved or denied
- Historical reports per member, event summaries, absence point reports

**Excuse Management:**
- Single or multi-event excuse submissions
- Recurring excuse support: select days of the week, a date range, and an optional time window — the system automatically links all matching events
- Cancel future events on a recurring excuse while keeping past records intact
- Personal/private excuses (`is_personal` flag): bypass officer review, hidden from officers, route directly to Director
- Two-tier review: officer provisional decision → Director final decision
- Automatic attendance sync on approval/denial
- Supporting documentation via proof link (URL)
- Reviewer audit trail

**Disciplinary System:**
- Demerit issuance, tracking, and history
- Configurable point values per demerit
- Contribution to absence point total (value × 0.33)
- Member demerit dashboard (/my-demerits)

**Section Management:**
- Directors create and manage named sections (e.g. Tenor 1, Bass 2)
- Members assigned to sections via User Management
- Officers see only excuses from members in their own section

**Reporting & Analytics:**
- Individual member attendance history with percentage calculations
- Absence point reports across all approved members
- Event attendance summaries

### Technical Features

- **Rails 8.0:** Latest framework version with Solid Queue, Solid Cache, and Solid Cable
- **Async Jobs:** Solid Queue powers all email notification delivery; no Redis required
- **Active Storage + Cloudinary:** Media uploads stored in Cloudinary in production, local disk in development
- **Responsive Design:** Bootstrap 5 UI with mobile-optimized touch targets (44 px minimum)
- **WCAG Accessibility:** Skip navigation, `aria-live` regions, `aria-label` on all badges and icon buttons, `aria-current="page"` on breadcrumbs, `role="tablist/tab/tabpanel"` on all tab widgets, `visually-hidden` text for colour-coded indicators
- **Progressive Enhancement:** Stimulus controllers for JavaScript functionality
- **Turbo Navigation:** Fast SPA-like page transitions without full reloads
- **CMS Architecture:** `PageContent` model with draft/publish workflow decouples content from code
- **Structured Logging:** JSON-formatted logs with Logstash integration via Lograge
- **Test Coverage:** RSpec request specs (integration), model specs, factory specs — 95%+ coverage via SimpleCov
- **Security:** CSRF protection, OAuth2, SQL injection prevention via parameterized queries, Brakeman static analysis

## Documentation

### Project Structure
```
singing-cadets-platform/
├── app/
│   ├── controllers/
│   │   ├── admin/            # Admin namespace (registrations, website CMS, media, auditions)
│   │   ├── internal/         # Member-facing controllers (events, excuses, demerits, users, settings, alerts)
│   │   ├── public/           # Public pages controller (home, booking, gallery, contact)
│   │   └── concerns/         # Shared controller concerns (Loggable)
│   ├── models/               # ActiveRecord models (18 models)
│   │   └── concerns/         # Shared model concerns
│   ├── jobs/
│   │   └── notifications/    # Background jobs (DeliverNotificationJob, EventReminderJob)
│   ├── services/
│   │   └── notifications/    # Notification services (Dispatcher, Payloads, Audience,
│   │                         #   EmailDelivery, AlertDirectors, EventReminderJob)
│   ├── views/
│   │   ├── admin/            # Website CMS, media, audition session views
│   │   ├── internal/         # Member portal views (events, excuses, users, demerits, settings)
│   │   ├── public/           # Public-facing page views
│   │   └── layouts/          # application, internal, and public layouts
│   ├── javascript/           # Stimulus controllers
│   ├── assets/               # Stylesheets and images
│   └── helpers/              # View helper methods
├── config/
│   ├── routes.rb             # URL routing (public, internal, admin namespaces)
│   ├── database.yml          # Database connection settings
│   ├── solid_queue.yml       # Background job worker/dispatcher settings
│   ├── storage.yml           # Active Storage (Cloudinary in production)
│   └── initializers/         # Rails initializers (devise, omniauth, lograge, cloudinary)
├── db/
│   ├── migrate/              # Database migrations
│   ├── schema.rb             # Authoritative schema (used by test suite via db:schema:load)
│   └── seeds.rb              # Seed data
├── spec/                     # RSpec tests
│   ├── models/               # Unit tests for all models
│   ├── requests/             # Integration tests (full HTTP stack)
│   ├── factories/            # FactoryBot definitions for all models
│   ├── services/             # Service object tests
│   └── jobs/                 # Background job tests
├── docker-compose.yml        # PostgreSQL 16 for local dev and test
├── Procfile                  # Heroku release commands
└── app.json                  # Heroku deployment manifest
```

### Key Models

- **User:** Authentication, roles (user/officer/super_admin), approval workflow, section assignment, email notification preference, absence point calculations, calendar token
- **Section:** Named voice sections for organizing members and scoping officer permissions
- **Event:** Event scheduling, recurring support, self-check-in management (passcode, time window), iCal/RSS conversion
- **Attendance:** Per-user-per-event records, 4 statuses, automatically synced on excuse approval/denial
- **Excuse:** Multi-event excuses, recurring pattern (days, date range, time window), personal/private flag, two-tier approval, reviewer audit trail
- **Demerit:** Disciplinary tracking with point values
- **PageContent:** Key-value CMS records per page with draft/published versions
- **MediaPhoto:** Cloudinary-hosted photos with publish flag for the public gallery
- **MediaVideo:** YouTube video links with publish flag
- **PerformanceRequest:** Public booking inquiry records with pending/reviewed status
- **ContactMessage:** Public contact form messages with read/unread tracking
- **AdminAlert:** In-app alerts displayed to Directors when email delivery fails
- **ApplicationSetting:** Singleton for system configuration (event reminder window)
- **AuditionSession:** Audition date slots managed by Directors

### Routes Overview

```
Public (no login required):
  GET  /public/home
  GET  /public/performance_request
  POST /public/performance_request
  GET  /public/media_gallery
  GET  /public/audition_information
  GET  /public/calendar
  GET  /public/contact
  POST /public/contact

Internal (authenticated members):
  /internal/events              Event CRUD, attendance, self-check-in, iCal/RSS
  /internal/excuses             Excuse submission, review, recurring cancel
  /internal/user_management     Member profiles, role management, attendance history
  /internal/demerits            Demerit management
  /internal/sections            Section management (director)
  /internal/settings            Notification settings (director)
  /internal/admin_alerts        Dismiss director alerts
  /internal/performance_requests View and update booking requests (director)

Admin:
  /admin/registrations          Registration approval workflow
  /admin/website                Website CMS dashboard (director only)
  /admin/media_photos           Photo upload and publish
  /admin/media_videos           Video add and publish
  /admin/audition_sessions      Audition session management

Auth:
  /auth/sign_in                 Sign in page
  /auth/sign_out                Sign out
  /auth/google_oauth2           OAuth redirect
  /auth/google_oauth2/callback  OAuth callback
```

### Testing

```bash
# Run all tests (inside Docker container or locally)
bundle exec rspec

# Run a specific file
bundle exec rspec spec/requests/excuses_spec.rb

# Run with coverage report (outputs to /coverage)
COVERAGE=true bundle exec rspec

# Run security audit
bundle exec brakeman

# Run linter
bundle exec rubocop
```

> **Coverage target:** The test suite maintains ≥ 95% line coverage measured by SimpleCov.
> Integration tests live in `spec/requests/` — these test the full HTTP stack through routes, controllers, models, and views.

### Rake Tasks

```bash
rails db:migrate       # Run pending migrations
rails db:schema:load   # Load schema directly (used by Docker test container)
rails db:seed          # Seed the database
rails db:reset         # Drop, create, and migrate
```

## Credits & Acknowledgements

### Development Team
- **Texas A&M Singing Cadets** - Project sponsors and stakeholders
- **CSCE 431 Software Engineering Team Fall 2025** - Original development team (Phase 1) - Jessica Jakubik, Owen Brown, Taylor Smith, Lucas Bryant, Anjali Varghese
- **CSCE 431 Software Engineering Team Spring 2026** - Phase 2 development team - Daniel Trinh, Junseok Kim, Abdussalam Raheem, Zaahir Sharma, Deniz Telci

### AI & Development Tools
This project was developed with assistance from:
- **GitHub Copilot** - AI-powered code completion and suggestions
- **ChatGPT (OpenAI)** - Technical problem-solving and documentation assistance
- **Claude (Anthropic)** - Code review, architecture guidance, and pair programming
- **Cursor AI** - AI-powered code editor and development assistant

### Special Recognition
- **Google Cloud Platform** - OAuth2 authentication infrastructure
- **SendGrid** - Email delivery infrastructure
- **Cloudinary** - Image hosting and delivery
- **Texas A&M University** - Institutional support and resources
- **Dr. Pauline Wade** - Faculty advisor and project sponsor

## Third-Party Libraries

### Ruby Gems
- **devise** (4.9+) - Flexible authentication solution
- **omniauth-google-oauth2** (~> 1.1) - Google OAuth2 strategy
- **pg** (~> 1.1) - PostgreSQL database adapter
- **puma** (>= 5.0) - High-performance web server
- **turbo-rails** - Hotwire's Turbo framework
- **stimulus-rails** - JavaScript framework
- **importmap-rails** - JavaScript module management
- **propshaft** - Modern asset pipeline
- **lograge** - Structured logging
- **logstash-event** - JSON log formatting
- **icalendar** - iCalendar feed generation
- **yaml_db** - YAML database utilities
- **solid_cable** - Database-backed ActionCable
- **solid_cache** - Database-backed cache
- **solid_queue** - Database-backed async job queue
- **kamal** - Docker deployment
- **thruster** - HTTP asset caching
- **jbuilder** - JSON API builder
- **nokogiri** (~> 1.16.2) - HTML/XML parsing
- **sendgrid-ruby** - SendGrid API client for email delivery
- **cloudinary** (~> 1.28) - Cloudinary API client for image hosting
- **rspec-rails** - Testing framework
- **factory_bot_rails** - Test data generation
- **capybara** - Integration testing
- **bootsnap** - Application boot optimizer
- **dotenv-rails** - Environment variable management
- **simplecov** - Code coverage reporting
- **brakeman** - Security scanner

### Front-End Frameworks (CDN)
- **Bootstrap 5.1.3** - CSS framework
- **Bootstrap Icons 1.8.1** - Icon library

### Development Tools
- **rubocop-rails-omakase** - Ruby style guide
- **brakeman** - Security scanner
- **simplecov** - Code coverage
- **selenium-webdriver** - Browser automation

## Contact Information

### Project Repository
- **GitHub:** https://github.com/AbdussalamR/502-Veterans-Super-Cadets

### Support & Issues
For bugs, feature requests, or technical support:
1. Create an issue on the GitHub repository
2. Contact Texas A&M Singing Cadets organization leadership
3. Consult this README for troubleshooting and configuration guidance

### Project Maintenance
- **Current Maintainers:** Texas A&M Singing Cadets organization
- **Phase 1 Developers:** CSCE 431 Software Engineering Team (Fall 2025) - Jessica Jakubik, Owen Brown, Taylor Smith, Lucas Bryant, Anjali Varghese
- **Phase 2 Developers:** CSCE 431 Software Engineering Team (Spring 2026) - Daniel Trinh, Junseok Kim, Abdussalam Raheem, Zaahir Sharma, Deniz Telci
- **Contact:** Through Texas A&M Singing Cadets official channels

### Organization
**Texas A&M Singing Cadets**
- Website: https://singingcadets.tamu.edu/
- Email: Contact through organization website
- Location: Texas A&M University, College Station, TX

---

**Last Updated:** March 2026
**Version:** 3.0.0
**License:** Proprietary - Texas A&M Singing Cadets
**Rails Version:** 8.0.0
**Ruby Version:** 3.2+
