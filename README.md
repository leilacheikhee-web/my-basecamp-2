# Welcome to My Basecamp 2

---

## Task

Build a Basecamp-like project management web app with user authentication, roles, and project management. Includes attachments, discussion threads, and messaging.

## Description

Full-stack Ruby Sinatra application with SQLite database. Features user registration, login, admin roles, and CRUD operations for projects. MyBasecamp2 adds support for file attachments, discussion threads, and team messaging. Beautiful dark-themed UI.

## Installation

```bash
gem install sinatra bcrypt sqlite3
ruby my_basecamp.rb
```

## Required Gems

- **sinatra** - Web framework
- **sinatra/base** - Advanced Sinatra features
- **sqlite3** - Database
- **bcrypt** - Password hashing
- **json** - JSON support
- **fileutils** - File handling for attachments

## Usage

Open http://localhost:8080 in your browser.
First registered user becomes admin automatically.

## Features

### MyBasecamp 1 Features

- User registration and login
- Admin roles
- Project creation and management
- Project member management
- User profiles

### MyBasecamp 2 Features

#### Attachments

- Any project member can upload attachments (png, jpg, jpeg, pdf, txt)
- Attachments are displayed on the project page
- Multiple file formats supported
- View uploader and upload date
- Delete own attachments or admin can delete any

#### Threads (Discussion Forums)

- Project admins can create discussion threads
- Threads have title and description
- Edit and delete threads (creator or admin)
- Organize team conversations by topic

#### Messages (Thread Replies)

- Any project member can post messages in threads
- Edit and delete own messages (or admin can delete any)
- View full conversation history
- See who posted and when

## API Routes

### Attachments

- `POST /projects/:id/attachments` - Upload file
- `DELETE /attachments/:id` - Delete attachment

### Threads

- `GET /projects/:id/threads/new` - New thread form (admin only)
- `POST /projects/:id/threads` - Create thread (admin only)
- `GET /threads/:id` - View thread
- `GET /threads/:id/edit` - Edit thread form
- `POST /threads/:id` - Update thread
- `DELETE /threads/:id` - Delete thread

### Messages

- `POST /threads/:id/messages` - Post message
- `GET /messages/:id/edit` - Edit message form
- `POST /messages/:id` - Update message
- `DELETE /messages/:id` - Delete message

## Database Schema

### New Tables (MyBasecamp 2)

**attachments**

- id, project_id, user_id, filename, format, file_path, created_at

**threads**

- id, project_id, user_id, title, description, created_at, updated_at

**messages**

- id, thread_id, user_id, content, created_at, updated_at

## Deployment to Render

This app is configured to run on Render (or any cloud platform) with PostgreSQL.

### Prerequisites

- Git repository pushed to GitHub
- Render account (render.com)

### Environment Variables

The app uses the following environment variables:

- `DATABASE_URL` - PostgreSQL connection string (automatically provided by Render)
- `SESSION_SECRET` - A secure random string for session encryption (generate one)
- `PORT` - Port to run on (defaults to 8080)
- `RACK_ENV` - Set to 'production' on Render

### Setup on Render

1. **Create a new Web Service on Render**
   - Connect your GitHub repository
   - Choose Node runtime
   - Build command: `bundle install`
   - Start command: `bundle exec rackup --host 0.0.0.0 --port $PORT`

2. **Add PostgreSQL Database**
   - Create a new PostgreSQL instance on Render
   - Note the internal database URL

3. **Configure Environment Variables**
   - Add `SESSION_SECRET`: Generate a secure random string (at least 64 characters)
   - Add `RACK_ENV`: Set to `production`
   - Render automatically injects `DATABASE_URL`

### Local Development

1. Copy `.env.example` to `.env`:

   ```bash
   cp .env.example .env
   ```

2. Edit `.env` with your local settings (or leave commented for SQLite)

3. Install dependencies:

   ```bash
   bundle install
   ```

4. Run the app:
   ```bash
   bundle exec rackup
   ```

The app will use SQLite locally and PostgreSQL when `DATABASE_URL` is set.

### Database Handling

- **Local**: Uses SQLite (`basecamp.db`) automatically
- **Production (Render)**: Uses PostgreSQL via `DATABASE_URL`

The app automatically detects which database to use based on the `DATABASE_URL` environment variable. Tables are created automatically on first run.

### Important Notes for Cloud Deployment

⚠️ **Ephemeral Filesystem**: Render's file system is ephemeral (read-only for app code, temporary for generated files).

- Uploaded files in `public/uploads/` will be lost when the app restarts
- For persistent file storage, use:
  - Render Disk (add a persistent volume)
  - AWS S3 or similar cloud storage
  - Configure in `UPLOAD_DIRECTORY` env variable

### Generate Session Secret

```bash
ruby -e "puts SecureRandom.random_bytes(32).unpack('H*')[0]"
```

Then set `SESSION_SECRET` in Render environment variables.

### The Core Team

<span><i>Made at <a href='https://qwasar.io'>Qwasar SV -- Software Engineering School</a></i></span>
<span><img alt='Qwasar SV -- Software Engineering School's Logo' src='https://storage.googleapis.com/qwasar-public/qwasar-logo_50x50.png' width='20px' /></span>
