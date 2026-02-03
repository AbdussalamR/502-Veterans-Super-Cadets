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

The Singing Cadets Events & Attendance Platform is a full-stack Ruby on Rails application designed to streamline operations for the Texas A&M Singing Cadets. The platform provides comprehensive tools for managing member attendance, tracking disciplinary actions, processing absence excuses, coordinating events, and facilitating administrative workflows with role-based access control.

Built with modern web technologies including Ruby on Rails 7.0, PostgreSQL, Bootstrap 5, and Stimulus JavaScript framework, the application supports three user roles (members, officers, and directors) with distinct permissions and capabilities. The system features Google OAuth2 authentication, fractional absence point calculations (0.33/0.66/1.0 point system), multi-event excuse management, and comprehensive reporting dashboards.

## Requirements

### Internal Components

**Core Application Stack:**
- **Ruby** 3.0+ (programming language)
- **Ruby on Rails** 7.0.2+ (web application framework)
- **PostgreSQL** 9.3+ (relational database)
- **Bundler** 2.0+ (Ruby dependency manager)
- **Node.js** 16.20.2+ (JavaScript runtime for asset compilation)
- **Yarn** or npm (JavaScript package manager)

**Ruby Gems (Dependencies):**
- **devise** - User authentication framework
- **omniauth-google-oauth2** (~> 1.1) - Google OAuth2 strategy
- **omniauth-rails_csrf_protection** - CSRF protection for OmniAuth
- **pg** (~> 1.1) - PostgreSQL adapter
- **puma** (>= 5.0) - Web server
- **turbo-rails** - Hotwire's SPA-like page accelerator
- **stimulus-rails** - JavaScript framework for progressive enhancement
- **importmap-rails** - JavaScript module management
- **propshaft** - Modern asset pipeline
- **bootsnap** - Boot time optimization
- **lograge** - Structured logging
- **logstash-event** - JSON logging format

**Development & Testing:**
- **rspec-rails** - Testing framework
- **factory_bot_rails** - Test data generation
- **capybara** - Integration testing
- **selenium-webdriver** - Browser automation for testing
- **simplecov** - Code coverage analysis
- **brakeman** - Security vulnerability scanner
- **rubocop-rails-omakase** - Ruby style guide enforcement

**Database Structure:**
- **Users** - Authentication, roles (user/officer/super_admin), approval workflow
- **Events** - Rehearsals, performances with date/time/location, self-check-in capability
- **Attendances** - Attendance records with status (present/excused/absent) and notes
- **Excuses** - Absence excuse submissions with multi-event support (bulk excuses)
- **Demerits** - Disciplinary point tracking system
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
- **Heroku** - Cloud platform (production deployment)
- **Docker** - Containerization (development environment)
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

# Rails Environment
RAILS_ENV=development  # or production
NODE_ENV=development   # or production

# Production-Only Variables
RAILS_MASTER_KEY=your_master_key_for_credentials
RAILS_SERVE_STATIC_FILES=true
RAILS_LOG_TO_STDOUT=true
```

**Configuration Files:**

- `config/database.yml` - Database connection settings
- `config/credentials.yml.enc` - Encrypted credentials (use `rails credentials:edit`)
- `config/master.key` - Master key for credentials (DO NOT commit to version control)
- `.env` (optional) - Environment variables for local development

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

# Install Node.js 16.20.2+
# macOS: brew install node
# Ubuntu: sudo apt-get install nodejs npm

# Install Yarn
npm install -g yarn
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

   # Install JavaScript packages
   yarn install
   ```

3. **Configure environment variables:**
   ```bash
   # Copy example env file (if provided)
   cp .env.example .env
   
   # Edit .env file with your configuration
   # Add your Google OAuth credentials
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

### Option 2: Docker Development Setup

**Prerequisites:**
- Docker Desktop installed
- Docker Compose (optional)

**Setup Steps:**

1. **Build and run Docker container:**
   ```bash
   docker build -t cadets-app .
   docker run -p 3000:3000 cadets-app
   ```

2. **Inside the container:**
   ```bash
   cd /501-cadets
   bundle install
   rails db:create
   rails db:migrate
   rails s --binding=0.0.0.0
   ```

3. **Access the application:**
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
- View personal demerit records
- Submit absence excuses for upcoming events
- Track absence points (0.33/0.66/1.0 fractional system)
- View event schedules
- Self-check-in to events (when enabled)

**Officers (role: 'officer'):**
- All member permissions, plus:
- Take attendance for events
- Approve/reject member registrations
- Create, edit, and delete events
- Review and process absence excuses (preliminary review)
- Issue demerits to members
- View comprehensive member attendance reports
- Generate absence point reports
- Manage event check-in passcodes

**Directors/Super Admins (role: 'super_admin'):**
- All officer permissions, plus:
- Final approval of absence excuses
- Promote/demote user roles
- Manage officer transitions
- Access comprehensive system analytics
- View audit logs and system health
- Archive old events and reset attendance

### Common Workflows

**Taking Attendance (Officers/Directors):**
1. Navigate to Events page
2. Select event from list
3. Click "Take Attendance"
4. Mark each member as Present, Excused, or Absent
5. Add optional notes for individual members
6. Save attendance

**Submitting Excuses (Members):**
1. Navigate to "My Excuses"
2. Click "New Excuse"
3. Select events to excuse (single or multiple)
4. Provide reason and supporting documentation link
5. Submit for review

**Processing Excuses (Officers/Directors):**
1. Navigate to "Excuses" management page
2. Review pending excuses
3. Officers: Preliminary approve/reject
4. Directors: Final approval after officer review
5. System automatically updates attendance records

**Member Registration Approval (Officers/Directors):**
1. Navigate to Admin > Registration Approvals
2. Review pending member applications
3. Approve or reject with optional notes
4. Approved members receive system access

## Features

### Core Functionality

**Authentication & Authorization:**
- Google OAuth2 single sign-on integration
- Role-based access control (3 tiers)
- Registration approval workflow
- Session management and security

**Event Management:**
- Create rehearsals and performances
- Specify date, time, location, and description
- Enable/disable self-check-in capability
- Generate unique check-in passcodes
- Archive old events automatically

**Attendance Tracking:**
- Multi-status attendance (present/excused/absent)
- Fractional absence point system (0.33, 0.66, 1.0, 1.33...)
- Real-time attendance statistics
- Historical attendance reports
- Bulk attendance recording
- Optional notes for each attendance record

**Excuse Management:**
- Multi-event excuse submissions (bulk excuses)
- Date range specifications
- Two-tier review process (officer + director)
- Automatic attendance updates upon approval
- Supporting documentation links
- Excuse history tracking

**Disciplinary System:**
- Demerit issuance and tracking
- Point value assignment
- Reason documentation
- Member demerit history
- Comprehensive demerit reports

**Reporting & Analytics:**
- Individual member attendance history
- Absence point calculations and reports
- Event attendance summaries
- Member statistics dashboards
- Demerit tracking reports
- Approval status analytics

**Administrative Tools:**
- Bulk member management
- Role promotion/demotion
- Event archival system
- Member information form integration (Google Forms)
- Structured logging with Lograge
- Security audit trails

### Technical Features

- **Responsive Design:** Bootstrap 5-based UI works on desktop, tablet, and mobile
- **Progressive Enhancement:** Stimulus controllers for JavaScript functionality
- **Turbo Navigation:** Fast, SPA-like page transitions without full reloads
- **Structured Logging:** JSON-formatted logs with Logstash integration
- **Test Coverage:** Comprehensive RSpec test suite with FactoryBot
- **Security:** CSRF protection, SQL injection prevention, XSS mitigation
- **Performance:** Database indexing, query optimization, caching strategies
- **Accessibility:** ARIA labels, semantic HTML, keyboard navigation

## Documentation

### Project Structure
```
501-cadets/
├── app/
│   ├── controllers/      # Request handling and business logic
│   ├── models/          # Data models and Active Record
│   ├── views/           # ERB templates
│   ├── javascript/      # Stimulus controllers and JS
│   ├── assets/          # Stylesheets and images
│   └── helpers/         # View helper methods
├── config/
│   ├── routes.rb        # URL routing configuration
│   ├── database.yml     # Database connection settings
│   ├── initializers/    # Rails initializers
│   └── environments/    # Environment-specific configs
├── db/
│   ├── migrate/         # Database migrations
│   ├── schema.rb        # Current database schema
│   └── seeds.rb         # Seed data
├── spec/                # RSpec tests
├── lib/tasks/           # Custom Rake tasks
└── public/              # Static assets

```

### Key Models

- **User:** Authentication, roles, approval workflow, absence calculations
- **Event:** Event scheduling, check-in management, attendance associations
- **Attendance:** Attendance records, status management, event/user relationships
- **Excuse:** Multi-event excuses (bulk), two-tier approval
- **Demerit:** Disciplinary tracking, point system, member associations
- **EventsToExcuse:** Join table for event-excuse relationships
- **ReviewersToExcuse:** Join table for excuse review workflow

### API Endpoints

The application uses RESTful routes following Rails conventions:
- `/events` - Event CRUD operations
- `/attendances` - Attendance management
- `/excuses` - Excuse submission and review
- `/demerits` - Demerit management
- `/users` - User management and reports
- `/admin/registrations` - Registration approvals
- `/auth/*` - Authentication endpoints

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
- **CSCE 431 Software Engineering Team Fall 2025** - Original development team - Jessica Jakubik, Owen Brown, Taylor Smith, Lucas Bryant, Anjali Varghese

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
- **Original Development Team** - CSCE 431 students who built the initial platform

## Third-Party Libraries

### Ruby Gems
- **devise** (4.9+) - Flexible authentication solution
- **omniauth-google-oauth2** (~> 1.1) - Google OAuth2 strategy
- **pg** (~> 1.1) - PostgreSQL database adapter
- **puma** (>= 5.0) - High-performance web server
- **turbo-rails** - Hotwire's Turbo framework
- **stimulus-rails** - JavaScript framework
- **lograge** - Structured logging
- **rspec-rails** - Testing framework
- **factory_bot_rails** - Test data generation
- **capybara** - Integration testing
- **bootsnap** - Application boot optimizer
- **propshaft** - Asset pipeline

### JavaScript Libraries
- **@rails/actioncable** (^6.0.0) - WebSocket framework
- **@rails/activestorage** (^6.0.0) - File upload framework
- **@rails/ujs** (^6.0.0) - Unobtrusive JavaScript helpers
- **@rails/webpacker** (5.4.3) - JavaScript bundler integration
- **turbolinks** (^5.2.0) - Fast navigation
- **webpack** (^4.46.0) - Module bundler

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
- **Original Developers:** CSCE 431 Software Engineering Team (Fall 2025) - Jessica Jakubik, Owen Brown, Taylor Smith, Lucas Bryant, Anjali Varghese
- **Contact:** Through Texas A&M Singing Cadets official channels

### Organization
**Texas A&M Singing Cadets**
- Website: https://singingcadets.tamu.edu/
- Email: Contact through organization website
- Location: Texas A&M University, College Station, TX

---

**Last Updated:** December 2025  
**Version:** 1.0.0  
**License:** Proprietary - Texas A&M Singing Cadets  
**Rails Version:** 7.0.2+  
**Ruby Version:** 3.0+
