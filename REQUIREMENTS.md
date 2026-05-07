# MyBasecamp 2 - Requirements & Dependencies

## Required Gems

### Complete Requirements List

Install all required gems using:

```bash
gem install sinatra bcrypt sqlite3
```

## Detailed Requirements

### 1. **sinatra**

**Purpose**: Web application framework
**Version**: Latest (recommended 2.x or 3.x)
**Function**: HTTP routing, request handling, response generation

```ruby
require 'sinatra'
```

**Usage in MyBasecamp2**:

- Route definitions (GET, POST, DELETE)
- Route parameters (:id extraction)
- Session management
- Response rendering (ERB templates)

### 2. **sinatra/base**

**Purpose**: Advanced Sinatra features
**Function**: Class-based Sinatra applications (modular architecture)

```ruby
require 'sinatra/base'
```

**Usage in MyBasecamp2**:

- Extends Sinatra with `class App < Sinatra::Base`
- Allows configuration blocks
- Better organization for larger applications
- Session management
- Custom middleware support

### 3. **sqlite3**

**Purpose**: SQLite database driver for Ruby
**Version**: Latest (recommended 1.5.x or higher)
**Function**: Database connectivity and query execution

```ruby
require 'sqlite3'
```

**Usage in MyBasecamp2**:

- Database connection: `SQLite3::Database.new(path)`
- SQL query execution: `db.execute(sql, params)`
- Result handling: `results_as_hash = true`
- Transaction support
- Foreign key constraints

**MyBasecamp2 Database Operations**:

- Create/read/update/delete projects
- Create/read/update/delete threads
- Create/read/update/delete messages
- Create/read/delete attachments
- Project member management
- User management

### 4. **bcrypt**

**Purpose**: Password hashing and verification
**Version**: Latest (recommended 3.x)
**Function**: Secure password storage using bcrypt algorithm

```ruby
require 'bcrypt'
```

**Usage in MyBasecamp2**:

- Hash passwords on registration: `BCrypt::Password.create(password)`
- Verify passwords on login: `BCrypt::Password.new(hash) == password`
- Salting automatically included
- One-way encryption (cannot reverse)

### 5. **json** (Standard Library)

**Purpose**: JSON encoding/decoding
**Function**: JSON data serialization

```ruby
require 'json'
```

**Usage in MyBasecamp2**:

- Optional: Could be used for API responses
- Currently loaded but not actively used in base app

### 6. **fileutils** (Standard Library - NEW)

**Purpose**: File and directory operations
**Function**: File upload handling

```ruby
require 'fileutils'
```

**Usage in MyBasecamp2**:

- Copy uploaded files: `FileUtils.copy_file(source, dest)`
- Create upload directory: `Dir.mkdir(path)`
- Delete files on attachment removal: `File.delete(path)`
- File existence checking: `File.exist?(path)`

## Installation Instructions

### Windows (Git Bash/MinGW)

```bash
# First, ensure you have Ruby installed
ruby --version

# Install required gems
gem install sinatra -v '~> 3.0'
gem install bcrypt -v '~> 3.1'
gem install sqlite3 -v '~> 1.5'

# Verify installation
gem list | grep -E 'sinatra|bcrypt|sqlite3'
```

### macOS

```bash
# Using Homebrew (if Ruby installed via Homebrew)
brew install ruby

# Install gems
gem install sinatra bcrypt sqlite3
```

### Linux (Ubuntu/Debian)

```bash
# Install Ruby first if needed
sudo apt-get install ruby ruby-dev

# Install gems
gem install sinatra bcrypt sqlite3
```

## Dependency Graph

```
MyBasecamp2 Application
├── sinatra (web routing)
│   ├── Provides HTTP handling
│   └── Template rendering
├── sinatra/base (advanced features)
│   ├── Modular architecture
│   └── Session management
├── sqlite3 (database)
│   ├── Project data
│   ├── User data
│   ├── Attachments metadata
│   ├── Threads
│   └── Messages
├── bcrypt (authentication)
│   └── Password security
├── fileutils (file handling)
│   └── Attachment upload/delete
└── json (optional serialization)
```

## Gemfile (if using Bundler)

```ruby
# Gemfile for MyBasecamp2
source "https://rubygems.org"

gem "sinatra", "~> 3.0"
gem "bcrypt", "~> 3.1"
gem "sqlite3", "~> 1.5"

# Optional: for development
group :development do
  gem "rake"
end
```

**To use Bundler:**

```bash
# Create Gemfile in project directory
# Add content above
# Then install:
bundle install

# Run app:
bundle exec ruby my_basecamp.rb
```

## Gem Size & Download Info

| Gem     | Size   | Downloads  | Latest Version |
| ------- | ------ | ---------- | -------------- |
| sinatra | ~15 MB | 1M+/week   | 4.0.0          |
| bcrypt  | ~5 MB  | 500K+/week | 3.1.18         |
| sqlite3 | ~3 MB  | 500K+/week | 1.6.6          |

## Port & Configuration

**Default Settings in MyBasecamp2:**

- Port: 8080
- Bind: 0.0.0.0 (all interfaces)
- Sessions: Enabled
- Method Override: Enabled (for PUT/DELETE)
- Session Secret: 64+ character random string

**To run on different port:**

```bash
# In terminal
PORT=3000 ruby my_basecamp.rb

# Or modify in code:
set :port, 3000
```

## Troubleshooting

### "command not found: ruby"

- Ruby not installed or not in PATH
- Solution: Install Ruby using RVM, rbenv, or official installer

### "cannot load such file -- sinatra"

- Gem not installed
- Solution: `gem install sinatra`

### "SQLite database is locked"

- Multiple processes accessing database
- Solution: Ensure only one instance of app running

### "Permission denied" on file upload

- Wrong permissions on uploads directory
- Solution: `chmod 755 uploads/`

### "Bcrypt version incompatibility"

- Bcrypt compiled against wrong Ruby version
- Solution: `gem uninstall bcrypt && gem install bcrypt`

## Security Notes

1. **Passwords**: Bcrypt with salt (automatically handled)
2. **SQL Injection**: All queries use parameterized statements
3. **Sessions**: Stored in-memory (production: use Redis)
4. **File Uploads**: File type validation (extension check)
5. **CSRF Protection**: Sinatra sessions handle this
6. **XSS Protection**: HTML escaping with `h()` helper

## Performance Considerations

- SQLite good for single-instance apps
- For production with multiple instances: use PostgreSQL
- File uploads stored locally (use cloud storage in production)
- Sessions in-memory (use Redis/Memcached in production)
- Consider caching for frequently accessed data

## Next Steps for Production

1. Use PostgreSQL instead of SQLite
2. Deploy to Heroku/AWS/DigitalOcean
3. Use cloud storage (AWS S3) for attachments
4. Implement Redis for sessions and caching
5. Add SSL/HTTPS certificate
6. Set up monitoring and error tracking
7. Implement rate limiting
8. Add email notifications
