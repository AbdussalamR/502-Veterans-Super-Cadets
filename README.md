*** GO TO RAHEEM'S PERSONAL REPO TO VIEW PR HISTORY ***
https://github.com/AbdussalamR/502-Veterans-Super-Cadets

# Singing Cadets Events & Attendance Platform

A comprehensive web application for managing events, attendance, disciplinary actions, and member workflows for the Texas A&M Singing Cadets organization.

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

The Singing Cadets Events & Attendance Platform is a full-stack Ruby on Rails application designed to streamline operations for the Texas A&M Singing Cadets. The platform provides comprehensive tools for managing member attendance (including tardy tracking), tracking disciplinary actions, processing absence excuses, coordinating events (with recurring event support), and facilitating administrative workflows with role-based access control.

Built with modern web technologies including Ruby on Rails 7.0, PostgreSQL, Bootstrap 5, and Stimulus JavaScript framework, the application supports three user roles (members, officers, and directors) with distinct permissions and capabilities. The system features Google OAuth2 authentication, an absence point system (1 point per absence, 0.33 per tardy, demerits at value x 0.33), multi-event excuse management with two-tier approval, self-check-in with passcodes, and calendar subscription feeds (iCal/RSS).

## Requirements

### Internal Components

**Core Application Stack:**
- **Ruby** 3.0+ (programming language)
- **Ruby on Rails** 7.0.2+ (web application framework)
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
- **solid_queue** - Database-backed job queue
- **kamal** - Docker-based deployment tool
- **thruster** - HTTP asset caching/compression

**Development & Testing:**
- **rspec-rails** - Testing framework
- **factory_bot_rails** - Test data generation
- **capybara** - Integration testing
- **selenium-webdriver** - Browser automation for testing
- **simplecov** - Code coverage analysis
- **brakeman** - Security vulnerability scanner
- **rubocop-rails-omakase** - Ruby style guide enforcement
- **dotenv-rails** - Environment variable management

**Database Structure:**
- **Users** - Authentication, roles (user/officer/super_admin), approval workflow, calendar_token for feed subscriptions
- **Events** - Rehearsals, performances with date/time/location, self-check-in capability (passcode-based)
- **Attendances** - Attendance records with status (present/excused/absent/tardy) and notes
- **Excuses** - Absence excuse submissions with multi-event support, recurring excuse fields (start_date, end_date, frequency), two-tier approval (officer_status + final status)
- **Demerits** - Disciplinary point tracking system with configurable point values
- **EventsToExcuse** - Many-to-many relationship between events and excuses
- **ReviewersToExcuse** - Many-to-many relationship for excuse review workflow

### External Dependencies

**Third-Party Services:**
- **Google Cloud Platform** - OAuth2 authentication provider
  - Google OAuth 2.0 API for single sign-on
  - Requires valid Google Client ID and Secret
  - Configured redirect URIs for development and production

**Front-End Libraries (via CDN):**
- **Bootstrap 5.1.3** - CSS framework for responsive design
- **Bootstrap Icons 1.8.1** - Icon library
- **Chart.js** (optional) - Data visualization for attendance statistics

**Deployment Services (Optional):**
- **Heroku** - Cloud platform (production deployment, heroku-24 stack)
- **Docker Compose** - PostgreSQL 16 for local development
- **Kamal** - Docker-based deployment tool

**External APIs:**
- Google OAuth2 API (accounts.google.com)
- Google Forms API (for additional member information collection)

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

# Rails Environment
RAILS_ENV=development  # or production

# Production-Only Variables
RAILS_MASTER_KEY=your_master_key_for_credentials
RAILS_SERVE_STATIC_FILES=true
RAILS_LOG_TO_STDOUT=true
```

**Configuration Files:**

- `config/database.yml` - Database connection settings
- `config/credentials.yml.enc` - Encrypted credentials (use `rails credentials:edit`)
- `config/master.key` - Master key for credentials (DO NOT commit to version control)
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

## Installation & Setup

### Option 1: Local Development Setup

**Prerequisites:**
```bash
# Install Ruby 3.0+ (using rbenv or rvm)
rbenv install 3.0.0
rbenv global 3.0.0

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
   # Install Ruby gems
   bundle install
   ```

3. **Configure environment variables:**
   ```bash
   # Create a .env file for local development
   # Add your Google OAuth credentials and database config
   ```

4. **Set up the database:**
   ```bash
   # Create database
   rails db:create

   # Run migrations
   rails db:migrate

   # Seed database (optional)
   rails db:seed
   ```

5. **Start the development server:**
   ```bash
   # Start Rails server
   rails server

   # Or using specific binding
   rails s -b 0.0.0.0 -p 3000
   ```

6. **Access the application:**
   - Open browser to http://localhost:3000
   - Sign in with Google OAuth

### Option 2: Docker Compose (Database Only)

The included `docker-compose.yml` provides a PostgreSQL 16 instance for local development.

**Prerequisites:**
- Docker Desktop installed

**Setup Steps:**

1. **Start the PostgreSQL container:**
   ```bash
   docker-compose up -d
   ```
   This starts PostgreSQL on port **5433** (mapped from container port 5432).

2. **Configure database connection:**
   Set your environment variables to connect to the Docker PostgreSQL instance:
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
   # Find your user
   user = User.find_by(email: "your.email@tamu.edu")

   # Set role (choose one)
   user.update!(role: 'super_admin', approval_status: 'approved')  # Director
   user.update!(role: 'officer', approval_status: 'approved')      # Officer
   user.update!(role: 'user', approval_status: 'approved')         # Member

   # Verify changes
   puts "Role: #{user.role}, Status: #{user.approval_status}"
   ```

4. Sign out and sign back in to apply changes

## Usage

### User Roles & Permissions

**Members (role: 'user'):**
- View personal attendance history and statistics
- View personal demerit records and absence points
- Submit absence excuses for upcoming events (single or multiple events)
- Track absence points (1 point per absence, 0.33 per tardy, demerits at value x 0.33)
- View event schedules
- Self-check-in to events (when enabled, within the check-in time window)
- Subscribe to event calendar feeds (iCal/RSS)

**Officers (role: 'officer'):**
- All member permissions, plus:
- Take attendance for events (present/absent/excused/tardy)
- Approve/reject member registrations
- Create, edit, and delete events (including recurring weekly events)
- Review and process absence excuses (provisional/preliminary decision)
- Issue demerits to members
- View comprehensive member attendance reports
- Generate absence point reports
- Manage event check-in passcodes

**Directors/Super Admins (role: 'super_admin'):**
- All officer permissions, plus:
- Final approval/denial of absence excuses (after officer review)
- Promote/demote user roles
- Delete user accounts
- Access absence reports for all members

### Common Workflows

**Taking Attendance (Officers/Directors):**
1. Navigate to Events page
2. Select event from list
3. Click "Take Attendance"
4. Mark each member as Present, Absent, Excused, or Tardy
5. Add optional notes for individual members
6. Save attendance

**Self-Check-In (Members):**
1. Navigate to the event page
2. Click "Self Check-In" (available within ±10 minutes of event start time through end time)
3. Enter the 4-digit passcode provided by an officer
4. Attendance is automatically recorded as "Present"

**Submitting Excuses (Members):**
1. Navigate to "My Excuses"
2. Click "New Excuse"
3. Select events to excuse (single or multiple)
4. Provide reason and supporting documentation link (URL)
5. Submit for review

**Processing Excuses (Two-Tier Approval):**
1. **Officer Review:** Navigate to "Excuses" management page, review pending excuses, make provisional approve/reject decision
2. **Director Review:** Director reviews officer's provisional decision, makes final approval or denial
3. Upon final approval, attendance records for related events are automatically updated to "excused"
4. Upon final denial, any previously excused attendance records are reverted to "absent"

**Member Registration Approval (Officers/Directors):**
1. Navigate to Admin > Registration Approvals
2. Review pending member applications
3. Approve or reject
4. Approved members can sign in; rejected members are blocked

**Calendar Subscription:**
1. Each user has a unique calendar token (generated automatically)
2. Subscribe to the iCal feed URL in any calendar app (Google Calendar, Apple Calendar, etc.)
3. Events are synced automatically

## Features

### Core Functionality

**Authentication & Authorization:**
- Google OAuth2 single sign-on integration
- Role-based access control (3 tiers: member, officer, director)
- Registration approval workflow (pending/approved/rejected)
- Session management and security

**Event Management:**
- Create rehearsals and performances with title, date, end time, location, and description
- Recurring weekly event creation (specify repeat_until date)
- Enable/disable self-check-in capability per event
- Auto-generated 4-digit check-in passcodes
- Self-check-in time window enforcement (±10 minutes from event start through end time)
- Calendar feed subscriptions (iCal .ics and RSS formats)

**Attendance Tracking:**
- Four attendance statuses: present, absent, excused, tardy
- Absence point system:
  - Absences: 1 point each
  - Tardies: 0.33 points each
  - Demerits: value x 0.33 points
- Real-time attendance statistics per event
- Historical attendance reports per member
- Bulk attendance recording
- Optional notes for each attendance record

**Excuse Management:**
- Multi-event excuse submissions (select multiple events per excuse)
- Recurring excuse support (start_date, end_date, frequency)
- Two-tier review process:
  1. Officer makes provisional decision (officer_status)
  2. Director/Super Admin makes final decision (status)
- Automatic attendance updates upon approval (marks as "excused")
- Automatic reversion upon denial (marks back as "absent")
- Supporting documentation via proof links (URLs)
- Excuse history tracking with reviewer audit trail

**Disciplinary System:**
- Demerit issuance and tracking
- Configurable point values per demerit (default: 1)
- Demerits contribute to absence points (value x 0.33)
- Reason documentation
- Member demerit history (via /my-demerits)
- Tracks who issued each demerit

**Reporting & Analytics:**
- Individual member attendance history with percentage calculations
- Absence point reports across all approved members
- Event attendance summaries (present/absent/excused/tardy counts and percentages)
- Demerit tracking reports

**Administrative Tools:**
- User search and filtering by role
- Role promotion/demotion (super_admin only)
- User account deletion (super_admin only)
- Registration approval management with status filtering
- Structured logging with Lograge (JSON format)
- Help page for users

### Technical Features

- **Responsive Design:** Bootstrap 5-based UI works on desktop, tablet, and mobile
- **Progressive Enhancement:** Stimulus controllers for JavaScript functionality
- **Turbo Navigation:** Fast, SPA-like page transitions without full reloads
- **Importmap:** Modern JavaScript module management without Node.js or bundlers
- **Calendar Feeds:** iCalendar (.ics) and RSS feed generation for event subscriptions
- **Structured Logging:** JSON-formatted logs with Logstash integration via Lograge
- **Test Coverage:** Comprehensive RSpec test suite with FactoryBot and Capybara
- **Security:** CSRF protection, OAuth2, SQL injection prevention, XSS mitigation
- **Database Indexing:** Indexes on user email, role, approval_status, calendar_token, and attendance uniqueness constraints

## Documentation

### Project Structure
```
502-Veterans-Super-Cadets/
├── app/
│   ├── controllers/      # Request handling (14 controllers)
│   │   ├── concerns/     # Shared controller concerns (Loggable)
│   │   ├── admin/        # Admin namespace (registrations)
│   │   └── users/        # User namespace (omniauth, sessions)
│   ├── models/           # Data models and Active Record (9 models)
│   │   └── concerns/     # Shared model concerns (LoggableModel)
│   ├── views/            # ERB templates
│   ├── javascript/       # Stimulus controllers
│   ├── assets/           # Stylesheets and images
│   └── helpers/          # View helper methods
├── config/
│   ├── routes.rb         # URL routing configuration
│   ├── database.yml      # Database connection settings
│   ├── importmap.rb      # JavaScript module mapping
│   ├── initializers/     # Rails initializers (devise, omniauth, lograge)
│   └── environments/     # Environment-specific configs
├── db/
│   ├── migrate/          # Database migrations (21 migrations)
│   ├── schema.rb         # Current database schema
│   └── seeds.rb          # Seed data
├── spec/                 # RSpec tests (models, requests, views, controllers)
├── docker-compose.yml    # PostgreSQL 16 for local development
├── Procfile              # Heroku release commands
├── app.json              # Heroku deployment manifest
└── public/               # Static assets

```

### Key Models

- **User:** Authentication, roles (user/officer/super_admin), approval workflow, absence point calculations, calendar token for feed subscriptions
- **Event:** Event scheduling, recurring event support, self-check-in management (passcode, time window), iCal/RSS conversion
- **Attendance:** Attendance records with 4 statuses (present/absent/excused/tardy), unique per user-event pair
- **Excuse:** Multi-event excuses, two-tier approval (officer provisional + admin final), recurring excuse support
- **Demerit:** Disciplinary tracking with point values, absence point contribution (value x 0.33)
- **EventsToExcuse:** Join table for event-excuse many-to-many relationships
- **ReviewersToExcuse:** Join table for excuse review audit trail

### API Endpoints

The application uses RESTful routes following Rails conventions:
- `/` - Root (events index)
- `/events` - Event CRUD operations (also serves .ics and .rss feeds)
- `/events/:id/self_checkin` - Self-check-in form and submission
- `/events/:id/attendances` - Attendance management (nested under events)
- `/excuses` - Excuse submission, review, and processing
- `/demerits` - Demerit management
- `/my-demerits` - Current user's demerit dashboard
- `/user_management` - User listing, role management, attendance history
- `/user_management/absence_report` - Absence point report for all members
- `/admin/registrations` - Registration approvals
- `/auth/*` - Authentication endpoints (sign in, sign out, OAuth redirect)
- `/help` - Help page

### Testing

```bash
# Run all tests
bundle exec rspec

# Run specific test file
bundle exec rspec spec/models/user_spec.rb

# Run with coverage report
COVERAGE=true bundle exec rspec

# Run security audit
bundle exec brakeman

# Run linter
bundle exec rubocop
```

### Rake Tasks

```bash
# Database tasks
rails db:migrate
rails db:seed
rails db:reset
```

## Credits & Acknowledgements

### Development Team
- **Texas A&M Singing Cadets** - Project sponsors and stakeholders
- **CSCE 431 Software Engineering Team Fall 2025** - Original development team (Phase 1) - Jessica Jakubik, Owen Brown, Taylor Smith, Lucas Bryant, Anjali Varghese
- **CSCE 431 Software Engineering Team Spring 2026** - Phase 2 development team - [Team member names here]

### AI & Development Tools
This project was developed with assistance from:
- **GitHub Copilot** - AI-powered code completion and suggestions
- **ChatGPT (OpenAI)** - Technical problem-solving and documentation assistance
- **Claude (Anthropic)** - Code review and architecture guidance
- **Cursor AI** - AI-powered code editor and development assistant

### Special Recognition
- **Google Cloud Platform** - OAuth2 authentication infrastructure
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
- **solid_queue** - Database-backed job queue
- **kamal** - Docker deployment
- **thruster** - HTTP asset caching
- **rspec-rails** - Testing framework
- **factory_bot_rails** - Test data generation
- **capybara** - Integration testing
- **bootsnap** - Application boot optimizer
- **dotenv-rails** - Environment variable management

### Front-End Frameworks (CDN)
- **Bootstrap 5.1.3** - CSS framework
- **Bootstrap Icons 1.8.1** - Icon library
- **Chart.js** (optional) - Data visualization

### Development Tools
- **rubocop-rails-omakase** - Ruby style guide
- **brakeman** - Security scanner
- **simplecov** - Code coverage
- **selenium-webdriver** - Browser automation

## Contact Information

### Project Repository
- **GitHub:** [Contact organization for repository access]

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

**Last Updated:** February 2026
**Version:** 2.0.0
**License:** Proprietary - Texas A&M Singing Cadets
**Rails Version:** 7.0.2+
**Ruby Version:** 3.0+
