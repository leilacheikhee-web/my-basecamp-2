# MyBasecamp 2 Implementation Summary

## Overview

MyBasecamp 2 extends the MyBasecamp 1 project management application with three major new features:

1. **Attachments** - File management with multiple format support
2. **Threads** - Discussion forums for project collaboration
3. **Messages** - Team messaging within threads

## Required Dependencies

All required gems are already in the original MyBasecamp1 project, with one addition:

```ruby
require 'sinatra'
require 'sinatra/base'
require 'sqlite3'
require 'bcrypt'
require 'json'
require 'fileutils'  # NEW - for file operations
```

## Key Features Implemented

### 1. Attachments System

- **Upload**: Any project member can upload files
- **Supported Formats**: png, jpg, jpeg, pdf, txt
- **Storage**: Files stored in `/uploads` directory with timestamp-based naming
- **Display**: Attachments shown on project page with format badges
- **Deletion**: File creator or admin can delete
- **Database Fields**: filename, format, file_path, uploader, timestamp

**Routes:**

- `POST /projects/:id/attachments` - Upload attachment
- `DELETE /attachments/:id` - Remove attachment

### 2. Threads System (Discussion Forums)

- **Creation**: Project admin only (project owner or designated admin)
- **Discussion**: Thread title + description for organizing conversations
- **Edit/Delete**: Creator or admin can modify
- **Display**: All threads shown on project page with message count (via view)
- **Access**: All project members can view and post in threads

**Routes:**

- `GET /projects/:id/threads/new` - New thread form (admin only)
- `POST /projects/:id/threads` - Create thread (admin only)
- `GET /threads/:id` - View thread with messages
- `GET /threads/:id/edit` - Edit form
- `POST /threads/:id` - Update thread
- `DELETE /threads/:id` - Delete thread

### 3. Messages System (Thread Replies)

- **Posting**: Any project member can post in threads
- **Editing**: Users can edit their own messages (admin can edit any)
- **Deletion**: Users can delete their own messages (admin can delete any)
- **Timestamps**: Creation and modification times tracked
- **Display**: Messages shown in chronological order with author info

**Routes:**

- `POST /threads/:id/messages` - Post message
- `GET /messages/:id/edit` - Edit form
- `POST /messages/:id` - Update message
- `DELETE /messages/:id` - Delete message

## Database Schema

### New Tables

**attachments**

```sql
CREATE TABLE attachments (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  project_id INTEGER NOT NULL,
  user_id INTEGER NOT NULL,
  filename TEXT NOT NULL,
  format TEXT NOT NULL,
  file_path TEXT NOT NULL,
  created_at TEXT DEFAULT (datetime('now'))
)
```

**threads**

```sql
CREATE TABLE threads (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  project_id INTEGER NOT NULL,
  user_id INTEGER NOT NULL,
  title TEXT NOT NULL,
  description TEXT,
  created_at TEXT DEFAULT (datetime('now')),
  updated_at TEXT DEFAULT (datetime('now'))
)
```

**messages**

```sql
CREATE TABLE messages (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  thread_id INTEGER NOT NULL,
  user_id INTEGER NOT NULL,
  content TEXT NOT NULL,
  created_at TEXT DEFAULT (datetime('now')),
  updated_at TEXT DEFAULT (datetime('now'))
)
```

### Modified Tables

**project_members** - Added is_admin field for project-level admin roles

```sql
ALTER TABLE project_members ADD COLUMN is_admin INTEGER DEFAULT 0;
```

## File Structure

```
my_basecamp_1/
├── my_basecamp.rb                 [UPDATED] Main application
├── basecamp.db                    (auto-created with new tables)
├── README.md                       [UPDATED] Full documentation
├── uploads/                        (auto-created for attachment files)
├── public/
│   └── style.css                  [UPDATED] Added new styling
└── views/
    ├── layout.erb                 (no changes)
    ├── project_show.erb           [UPDATED] Shows attachments & threads
    ├── thread_new.erb             [NEW] Create thread form
    ├── thread_edit.erb            [NEW] Edit thread form
    ├── thread_show.erb            [NEW] View thread & messages
    └── message_edit.erb           [NEW] Edit message form
```

## Helper Functions Added

```ruby
def is_project_member?(user_id, project_id)
  # Check if user is a project member

def is_project_admin?(user_id, project_id)
  # Check if user is project admin

def is_project_owner?(user_id, project_id)
  # Check if user owns the project
```

## Access Control Matrix

| Feature           | Project Owner | Project Admin | Project Member | Non-Member |
| ----------------- | ------------- | ------------- | -------------- | ---------- |
| View Project      | ✓             | ✓             | ✓              | ✗          |
| Create Attachment | ✓             | ✓             | ✓              | ✗          |
| Delete Attachment | ✓ (own/all)   | ✓ (all)       | ✓ (own)        | ✗          |
| Create Thread     | ✓             | ✓             | ✗              | ✗          |
| Post Message      | ✓             | ✓             | ✓              | ✗          |
| Edit Message      | ✓ (own/all)   | ✓ (all)       | ✓ (own)        | ✗          |
| Delete Message    | ✓ (own/all)   | ✓ (all)       | ✓ (own)        | ✗          |

## CSS Enhancements

New classes for styling:

- `.project-attachments` - Attachments section
- `.attachment-item`, `.attachment-format` - Attachment display
- `.project-threads` - Threads container
- `.thread-item`, `.thread-title` - Thread display
- `.messages-container`, `.message-item` - Message display
- `.add-message` - Message form styling
- `.message-actions`, `.thread-actions` - Action buttons

## Installation & Running

```bash
# Navigate to project directory
cd c:/qwasr/basecamp/my_basecamp_1

# Install dependencies (if not already installed)
gem install sinatra bcrypt sqlite3

# Run the application
ruby my_basecamp.rb

# Open browser to http://localhost:8080
```

## Testing Workflow

1. Register first user (becomes admin)
2. Create a project
3. Add members to project
4. Upload attachments to project
5. Create a thread (as admin)
6. Post messages in thread
7. Edit/delete messages and threads as needed
8. Verify file upload to `/uploads` directory

## Notes

- File uploads stored with timestamp prefix to avoid collisions
- All user input is sanitized with h() helper
- Proper error handling with user-friendly messages
- Comprehensive access control on all operations
- Full audit trail with created_at/updated_at timestamps
- Project-level permissions distinct from system admin
