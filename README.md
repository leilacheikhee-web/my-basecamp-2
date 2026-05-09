# Welcome to My Basecamp 2

---

##  Live Demo

**[Click here to view My Basecamp 2](https://my-basecamp-2-1-98dw.onrender.com/)**

> https://my-basecamp-2-1-98dw.onrender.com/

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

This app is configured to run on Render with PostgreSQL.

### Environment Variables

- `DATABASE_URL` - PostgreSQL connection string (automatically provided by Render)
- `SESSION_SECRET` - A secure random string for session encryption
- `PORT` - Port to run on (defaults to 8080)
- `RACK_ENV` - Set to `production` on Render

### Setup on Render

1. **Create a new Web Service on Render**
   - Connect your GitHub repository
   - Build command: `bundle install`
   - Start command: `bundle exec rackup --host 0.0.0.0 --port $PORT`

2. **Add PostgreSQL Database**
   - Create a new PostgreSQL instance on Render
   - Render automatically injects `DATABASE_URL`

3. **Configure Environment Variables**
   - Add `SESSION_SECRET`: Generate with `ruby -e "puts SecureRandom.random_bytes(32).unpack('H*')[0]"`
   - Add `RACK_ENV`: Set to `production`

### Local Development

1. Copy `.env.example` to `.env`:

   ```bash
   cp .env.example .env
   ```

2. Install dependencies:

   ```bash
   bundle install
   ```

3. Run the app:
   ```bash
   bundle exec rackup
   ```

The app will use SQLite locally and PostgreSQL when `DATABASE_URL` is set.

### The Core Team

<span><i>Made at <a href='https://qwasar.io'>Qwasar SV -- Software Engineering School</a></i></span>
<span><img alt='Qwasar SV -- Software Engineering School's Logo' src='https://storage.googleapis.com/qwasar-public/qwasar-logo_50x50.png' width='20px' /></span>