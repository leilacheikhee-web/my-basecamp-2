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

### The Core Team

<span><i>Made at <a href='https://qwasar.io'>Qwasar SV -- Software Engineering School</a></i></span>
<span><img alt='Qwasar SV -- Software Engineering School's Logo' src='https://storage.googleapis.com/qwasar-public/qwasar-logo_50x50.png' width='20px' /></span>
