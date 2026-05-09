require 'sinatra'
require 'sinatra/base'
require 'bcrypt'
require 'json'
require 'fileutils'
require 'uri'
require 'dotenv/load'  # Load .env file for local development

# Database setup based on environment
begin
  require 'pg'
rescue LoadError
  # pg might not be installed locally
end

begin
  require 'sqlite3'
rescue LoadError
  # sqlite3 might not be installed in production
end

# PostgreSQL result wrapper to match SQLite's interface
class PostgresWrapper
  def initialize(pg_conn)
    @pg_conn = pg_conn
  end

  def method_missing(method, *args)
    @pg_conn.send(method, *args)
  end

  def execute(sql, params = [])
  # Convert ? placeholders to $1, $2, $3 for PostgreSQL
  index = 0
  converted_sql = sql.gsub('?') { index += 1; "$#{index}" }
  result = @pg_conn.exec_params(converted_sql, params)
  result.to_a
end

  def execute_batch(sql)
    # Split SQL statements and execute each, handling multiple statements
    statements = sql.split(';').map(&:strip).reject(&:empty?)
    statements.each do |stmt|
      @pg_conn.exec(stmt) unless stmt.empty?
    end
  end

  def close
    @pg_conn.close
  end
end

class App < Sinatra::Base
  configure do
    set :port, ENV['PORT'] || 8080
    set :bind, '0.0.0.0'
    set :views, File.dirname(__FILE__) + '/views'
    set :public_folder, File.dirname(__FILE__) + '/public'
    enable :sessions
    set :method_override, true
    set :session_secret, ENV['SESSION_SECRET'] || 'change_me_in_production_a_very_long_random_string_that_is_at_least_64_characters_long'
  end

  def using_postgres?
    !ENV['DATABASE_URL'].nil?
  end

  def db
    @db ||= begin
      if using_postgres?
        require 'pg'
        establish_postgres_connection
      else
        require 'sqlite3'
        establish_sqlite_connection
      end
    end
  end

  def establish_sqlite_connection
    d = SQLite3::Database.new(File.dirname(__FILE__) + '/basecamp.db')
    d.results_as_hash = true
    init_sqlite_tables(d)
    d
  end

  def establish_postgres_connection
    begin
      uri = URI.parse(ENV['DATABASE_URL'])
      conn = PG.connect(
        host: uri.host,
        port: uri.port,
        user: uri.user,
        password: uri.password,
        dbname: uri.path.delete('/')
      )
      wrapper = PostgresWrapper.new(conn)
      init_postgres_tables(wrapper)
      wrapper
    rescue => e
      puts "PostgreSQL connection error: #{e.class} - #{e.message}"
      puts e.backtrace.join("\n")
      raise
    end
  end

  def init_sqlite_tables(d)
    d.execute_batch <<-SQL
      CREATE TABLE IF NOT EXISTS users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE NOT NULL,
        email TEXT UNIQUE NOT NULL,
        password_hash TEXT NOT NULL,
        is_admin INTEGER DEFAULT 0,
        created_at TEXT DEFAULT (datetime('now'))
      );
      CREATE TABLE IF NOT EXISTS projects (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT,
        owner_id INTEGER NOT NULL,
        created_at TEXT DEFAULT (datetime('now')),
        FOREIGN KEY (owner_id) REFERENCES users(id)
      );
      CREATE TABLE IF NOT EXISTS project_members (
        project_id INTEGER,
        user_id INTEGER,
        is_admin INTEGER DEFAULT 0,
        PRIMARY KEY (project_id, user_id),
        FOREIGN KEY (project_id) REFERENCES projects(id),
        FOREIGN KEY (user_id) REFERENCES users(id)
      );
      CREATE TABLE IF NOT EXISTS attachments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        project_id INTEGER NOT NULL,
        user_id INTEGER NOT NULL,
        filename TEXT NOT NULL,
        format TEXT NOT NULL,
        file_path TEXT NOT NULL,
        created_at TEXT DEFAULT (datetime('now')),
        FOREIGN KEY (project_id) REFERENCES projects(id),
        FOREIGN KEY (user_id) REFERENCES users(id)
      );
      CREATE TABLE IF NOT EXISTS threads (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        project_id INTEGER NOT NULL,
        user_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        description TEXT,
        created_at TEXT DEFAULT (datetime('now')),
        updated_at TEXT DEFAULT (datetime('now')),
        FOREIGN KEY (project_id) REFERENCES projects(id),
        FOREIGN KEY (user_id) REFERENCES users(id)
      );
      CREATE TABLE IF NOT EXISTS messages (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        thread_id INTEGER NOT NULL,
        user_id INTEGER NOT NULL,
        content TEXT NOT NULL,
        created_at TEXT DEFAULT (datetime('now')),
        updated_at TEXT DEFAULT (datetime('now')),
        FOREIGN KEY (thread_id) REFERENCES threads(id),
        FOREIGN KEY (user_id) REFERENCES users(id)
      );
    SQL
    
    # Migration: Add is_admin column to project_members if it doesn't exist
    begin
      d.execute("ALTER TABLE project_members ADD COLUMN is_admin INTEGER DEFAULT 0")
    rescue SQLite3::SQLException => e
      # Column already exists or other error, ignore
    end
  end

  def init_postgres_tables(conn)
    conn.execute_batch <<-SQL
      CREATE TABLE IF NOT EXISTS users (
        id SERIAL PRIMARY KEY,
        username TEXT UNIQUE NOT NULL,
        email TEXT UNIQUE NOT NULL,
        password_hash TEXT NOT NULL,
        is_admin INTEGER DEFAULT 0,
        created_at TIMESTAMP DEFAULT now()
      );
      CREATE TABLE IF NOT EXISTS projects (
        id SERIAL PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        owner_id INTEGER NOT NULL,
        created_at TIMESTAMP DEFAULT now(),
        FOREIGN KEY (owner_id) REFERENCES users(id)
      );
      CREATE TABLE IF NOT EXISTS project_members (
        project_id INTEGER,
        user_id INTEGER,
        is_admin INTEGER DEFAULT 0,
        PRIMARY KEY (project_id, user_id),
        FOREIGN KEY (project_id) REFERENCES projects(id),
        FOREIGN KEY (user_id) REFERENCES users(id)
      );
      CREATE TABLE IF NOT EXISTS attachments (
        id SERIAL PRIMARY KEY,
        project_id INTEGER NOT NULL,
        user_id INTEGER NOT NULL,
        filename TEXT NOT NULL,
        format TEXT NOT NULL,
        file_path TEXT NOT NULL,
        created_at TIMESTAMP DEFAULT now(),
        FOREIGN KEY (project_id) REFERENCES projects(id),
        FOREIGN KEY (user_id) REFERENCES users(id)
      );
      CREATE TABLE IF NOT EXISTS threads (
        id SERIAL PRIMARY KEY,
        project_id INTEGER NOT NULL,
        user_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        description TEXT,
        created_at TIMESTAMP DEFAULT now(),
        updated_at TIMESTAMP DEFAULT now(),
        FOREIGN KEY (project_id) REFERENCES projects(id),
        FOREIGN KEY (user_id) REFERENCES users(id)
      );
      CREATE TABLE IF NOT EXISTS messages (
        id SERIAL PRIMARY KEY,
        thread_id INTEGER NOT NULL,
        user_id INTEGER NOT NULL,
        content TEXT NOT NULL,
        created_at TIMESTAMP DEFAULT now(),
        updated_at TIMESTAMP DEFAULT now(),
        FOREIGN KEY (thread_id) REFERENCES threads(id),
        FOREIGN KEY (user_id) REFERENCES users(id)
      );
    SQL
    
    # Migration: Add is_admin column if it doesn't exist
    begin
      conn.execute("ALTER TABLE project_members ADD COLUMN is_admin INTEGER DEFAULT 0")
    rescue PG::Error => e
      # Column already exists, ignore
    end
  end

  def current_user
    return nil unless session[:user_id]
    row = db.execute('SELECT * FROM users WHERE id = ?', [session[:user_id]]).first
    row
  end

  def require_login
    redirect '/login' unless current_user
  end

  def require_admin
    redirect '/' unless current_user && current_user['is_admin'] == 1
  end

  def is_project_member?(user_id, project_id)
    result = db.execute(
      'SELECT COUNT(*) as c FROM project_members WHERE project_id = ? AND user_id = ?',
      [project_id, user_id]
    ).first
    result['c'] > 0
  end

  def is_project_admin?(user_id, project_id)
    result = db.execute(
      'SELECT COUNT(*) as c FROM project_members WHERE project_id = ? AND user_id = ? AND is_admin = 1',
      [project_id, user_id]
    ).first
    result['c'] > 0
  end

  def is_project_owner?(user_id, project_id)
    project = db.execute('SELECT owner_id FROM projects WHERE id = ?', [project_id]).first
    project && project['owner_id'] == user_id
  end

  helpers do
    def h(text)
      text.to_s.gsub('&','&amp;').gsub('<','&lt;').gsub('>','&gt;').gsub('"','&quot;')
    end
  end

  # ===================== ROUTES =====================

  get '/' do
    @user = current_user
    if @user
      @projects = db.execute(
        'SELECT p.*, u.username as owner_name FROM projects p JOIN users u ON p.owner_id = u.id
         LEFT JOIN project_members pm ON pm.project_id = p.id
         WHERE p.owner_id = ? OR pm.user_id = ? GROUP BY p.id ORDER BY p.created_at DESC',
        [@user['id'], @user['id']]
      )
      erb :dashboard
    else
      erb :home
    end
  end

  # ---- AUTH ----
  get '/register' do
    redirect '/' if current_user
    erb :register
  end

  post '/register' do
    username = params['username'].to_s.strip
    email = params['email'].to_s.strip
    password = params['password'].to_s
    confirm = params['confirm_password'].to_s

    if username.empty? || email.empty? || password.empty?
      @error = 'All fields are required'
      return erb :register
    end
    if password != confirm
      @error = 'Passwords do not match'
      return erb :register
    end
    if password.length < 6
      @error = 'Password must be at least 6 characters'
      return erb :register
    end

    hash = BCrypt::Password.create(password)
    begin
      db.execute('INSERT INTO users (username, email, password_hash) VALUES (?, ?, ?)',
        [username, email, hash])
      user = db.execute('SELECT * FROM users WHERE email = ?', [email]).first
      # First user is admin
      count = db.execute('SELECT COUNT(*) as c FROM users').first['c']
      db.execute('UPDATE users SET is_admin = 1 WHERE id = ?', [user['id']]) if count == 1
      session[:user_id] = user['id']
      redirect '/'
    rescue BCrypt::Errors::InvalidHash => e
      @error = 'Password processing error'
      erb :register
    rescue => e
      if e.message.include?('UNIQUE constraint failed') || e.message.include?('duplicate key') || e.message.include?('violates unique constraint')
        @error = 'Username or email already taken'
      elsif e.message.include?('no such table') || e.message.include?('does not exist')
        @error = 'Database error: tables not initialized'
      else
        puts "Registration error: #{e.class} - #{e.message}"
        puts e.backtrace.join("\n")
        @error = 'An error occurred during registration'
      end
      erb :register
    end
  end

  get '/login' do
    redirect '/' if current_user
    erb :login
  end

  post '/login' do
    email = params['email'].to_s.strip
    password = params['password'].to_s
    user = db.execute('SELECT * FROM users WHERE email = ?', [email]).first
    if user && BCrypt::Password.new(user['password_hash']) == password
      session[:user_id] = user['id']
      redirect '/'
    else
      @error = 'Invalid email or password'
      erb :login
    end
  end

  delete '/logout' do
    session.clear
    redirect '/login'
  end

  post '/logout' do
    session.clear
    redirect '/login'
  end

  # ---- USERS ----
  get '/users' do
    require_admin
    @user = current_user
    @users = db.execute('SELECT * FROM users ORDER BY created_at DESC')
    erb :users
  end

  get '/users/:id' do
    require_login
    @user = current_user
    @profile = db.execute('SELECT * FROM users WHERE id = ?', [params['id']]).first
    halt 404 unless @profile
    @projects = db.execute(
      'SELECT p.* FROM projects p WHERE p.owner_id = ? ORDER BY p.created_at DESC',
      [@profile['id']]
    )
    erb :user_show
  end

  delete '/users/:id' do
    require_login
    @user = current_user
    target_id = params['id'].to_i
    unless @user['is_admin'] == 1 || @user['id'] == target_id
      redirect '/'
    end
    db.execute('DELETE FROM project_members WHERE user_id = ?', [target_id])
    db.execute('DELETE FROM projects WHERE owner_id = ?', [target_id])
    db.execute('DELETE FROM users WHERE id = ?', [target_id])
    session.clear if @user['id'] == target_id
    redirect '/users'
  end

  post '/users/:id/admin' do
    require_admin
    db.execute('UPDATE users SET is_admin = 1 WHERE id = ?', [params['id']])
    redirect '/users'
  end

  post '/users/:id/remove_admin' do
    require_admin
    db.execute('UPDATE users SET is_admin = 0 WHERE id = ?', [params['id']])
    redirect '/users'
  end

  # ---- PROJECTS ----
  get '/projects/new' do
    require_login
    @user = current_user
    erb :project_new
  end

  post '/projects' do
    require_login
    @user = current_user
    name = params['name'].to_s.strip
    desc = params['description'].to_s.strip
    if name.empty?
      @error = 'Project name is required'
      return erb :project_new
    end
    db.execute('INSERT INTO projects (name, description, owner_id) VALUES (?, ?, ?)',
      [name, desc, @user['id']])
    redirect '/'
  end

  get '/projects/:id' do
    require_login
    @user = current_user
    @project = db.execute('SELECT p.*, u.username as owner_name FROM projects p JOIN users u ON p.owner_id = u.id WHERE p.id = ?', [params['id']]).first
    halt 404 unless @project
    @members = db.execute('SELECT u.* FROM users u JOIN project_members pm ON pm.user_id = u.id WHERE pm.project_id = ?', [@project['id']])
    @all_users = db.execute('SELECT * FROM users WHERE id != ?', [@user['id']])
    @attachments = db.execute('SELECT a.*, u.username as uploader_name FROM attachments a JOIN users u ON a.user_id = u.id WHERE a.project_id = ? ORDER BY a.created_at DESC', [@project['id']])
    @threads = db.execute('SELECT t.*, u.username as author_name FROM threads t JOIN users u ON t.user_id = u.id WHERE t.project_id = ? ORDER BY t.created_at DESC', [@project['id']])
    erb :project_show
  end

  get '/projects/:id/edit' do
    require_login
    @user = current_user
    @project = db.execute('SELECT * FROM projects WHERE id = ?', [params['id']]).first
    halt 404 unless @project
    redirect '/' unless @project['owner_id'] == @user['id'] || @user['is_admin'] == 1
    erb :project_edit
  end

  post '/projects/:id' do
    require_login
    @user = current_user
    @project = db.execute('SELECT * FROM projects WHERE id = ?', [params['id']]).first
    halt 404 unless @project
    redirect '/' unless @project['owner_id'] == @user['id'] || @user['is_admin'] == 1
    name = params['name'].to_s.strip
    desc = params['description'].to_s.strip
    db.execute('UPDATE projects SET name = ?, description = ? WHERE id = ?',
      [name, desc, params['id']])
    redirect "/projects/#{params['id']}"
  end

  delete '/projects/:id' do
    require_login
    @user = current_user
    @project = db.execute('SELECT * FROM projects WHERE id = ?', [params['id']]).first
    halt 404 unless @project
    redirect '/' unless @project['owner_id'] == @user['id'] || @user['is_admin'] == 1
    db.execute('DELETE FROM project_members WHERE project_id = ?', [params['id']])
    db.execute('DELETE FROM projects WHERE id = ?', [params['id']])
    redirect '/'
  end

  post '/projects/:id/members' do
    require_login
    @user = current_user
    project_id = params['id'].to_i
    @project = db.execute('SELECT * FROM projects WHERE id = ?', [project_id]).first
    halt 404 unless @project
    redirect '/' unless @project['owner_id'] == @user['id'] || @user['is_admin'] == 1
    
    user_id = params['user_id'].to_i
    begin
      db.execute('INSERT INTO project_members (project_id, user_id) VALUES (?, ?)',
        [project_id, user_id])
    rescue => e
      # Member already exists or other constraint error
    end
    redirect "/projects/#{project_id}"
  end

  delete '/projects/:id/members/:user_id' do
    require_login
    @user = current_user
    project_id = params['id'].to_i
    member_id = params['user_id'].to_i
    @project = db.execute('SELECT * FROM projects WHERE id = ?', [project_id]).first
    halt 404 unless @project
    redirect '/' unless @project['owner_id'] == @user['id'] || @user['is_admin'] == 1
    
    db.execute('DELETE FROM project_members WHERE project_id = ? AND user_id = ?',
      [project_id, member_id])
    redirect "/projects/#{project_id}"
  end

  # ---- ATTACHMENTS ----
  post '/projects/:id/attachments' do
    require_login
    @user = current_user
    project_id = params['id'].to_i
    @project = db.execute('SELECT * FROM projects WHERE id = ?', [project_id]).first
    halt 404 unless @project
    
    is_member = is_project_member?(@user['id'], project_id)
    halt 403 unless is_member || @project['owner_id'] == @user['id'] || @user['is_admin'] == 1
    
    unless params[:file]
      @error = 'File is required'
      redirect back
    end

    file = params[:file]
    filename = file[:filename]
    format = File.extname(filename).downcase.delete('.')
    temp_file = file[:tempfile]
    
    allowed_formats = ['png', 'jpg', 'jpeg', 'pdf', 'txt']
    unless allowed_formats.include?(format)
      @error = 'Only png, jpg, jpeg, pdf, txt formats allowed'
      redirect back
    end

    uploads_dir = File.dirname(__FILE__) + '/uploads'
    Dir.mkdir(uploads_dir) unless Dir.exist?(uploads_dir)
    
    new_filename = "#{Time.now.to_i}_#{filename}"
    file_path = File.join(uploads_dir, new_filename)
    FileUtils.copy_file(temp_file.path, file_path)
    
    db.execute('INSERT INTO attachments (project_id, user_id, filename, format, file_path) VALUES (?, ?, ?, ?, ?)',
      [project_id, @user['id'], filename, format, file_path])
    
    redirect "/projects/#{project_id}"
  end

  delete '/attachments/:id' do
    require_login
    @user = current_user
    attachment = db.execute('SELECT * FROM attachments WHERE id = ?', [params['id']]).first
    halt 404 unless attachment
    
    @project = db.execute('SELECT * FROM projects WHERE id = ?', [attachment['project_id']]).first
    redirect '/' unless @project['owner_id'] == @user['id'] || @user['id'] == attachment['user_id'] || @user['is_admin'] == 1
    
    File.delete(attachment['file_path']) if File.exist?(attachment['file_path'])
    db.execute('DELETE FROM attachments WHERE id = ?', [params['id']])
    
    redirect "/projects/#{attachment['project_id']}"
  end

  # ---- THREADS ----
  get '/projects/:id/threads/new' do
    require_login
    @user = current_user
    project_id = params['id'].to_i
    @project = db.execute('SELECT * FROM projects WHERE id = ?', [project_id]).first
    halt 404 unless @project
    
    is_admin = is_project_admin?(@user['id'], project_id) || @project['owner_id'] == @user['id'] || @user['is_admin'] == 1
    halt 403 unless is_admin
    
    erb :thread_new
  end

  post '/projects/:id/threads' do
    require_login
    @user = current_user
    project_id = params['id'].to_i
    @project = db.execute('SELECT * FROM projects WHERE id = ?', [project_id]).first
    halt 404 unless @project
    
    is_admin = is_project_admin?(@user['id'], project_id) || @project['owner_id'] == @user['id'] || @user['is_admin'] == 1
    halt 403 unless is_admin
    
    title = params['title'].to_s.strip
    description = params['description'].to_s.strip
    
    if title.empty?
      @error = 'Thread title is required'
      return erb :thread_new
    end
    
    db.execute('INSERT INTO threads (project_id, user_id, title, description) VALUES (?, ?, ?, ?)',
      [project_id, @user['id'], title, description])
    
    redirect "/projects/#{project_id}"
  end

  get '/threads/:id' do
    require_login
    @user = current_user
    @thread = db.execute('SELECT t.*, u.username as author_name FROM threads t JOIN users u ON t.user_id = u.id WHERE t.id = ?', [params['id']]).first
    halt 404 unless @thread
    
    @project = db.execute('SELECT * FROM projects WHERE id = ?', [@thread['project_id']]).first
    is_member = is_project_member?(@user['id'], @project['id'])
    halt 403 unless is_member || @project['owner_id'] == @user['id'] || @user['is_admin'] == 1
    
    @messages = db.execute('SELECT m.*, u.username as author_name FROM messages m JOIN users u ON m.user_id = u.id WHERE m.thread_id = ? ORDER BY m.created_at ASC', [@thread['id']])
    erb :thread_show
  end

  get '/threads/:id/edit' do
    require_login
    @user = current_user
    @thread = db.execute('SELECT * FROM threads WHERE id = ?', [params['id']]).first
    halt 404 unless @thread
    
    @project = db.execute('SELECT * FROM projects WHERE id = ?', [@thread['project_id']]).first
    halt 403 unless @thread['user_id'] == @user['id'] || @project['owner_id'] == @user['id'] || @user['is_admin'] == 1
    
    erb :thread_edit
  end

  post '/threads/:id' do
    require_login
    @user = current_user
    @thread = db.execute('SELECT * FROM threads WHERE id = ?', [params['id']]).first
    halt 404 unless @thread
    
    @project = db.execute('SELECT * FROM projects WHERE id = ?', [@thread['project_id']]).first
    halt 403 unless @thread['user_id'] == @user['id'] || @project['owner_id'] == @user['id'] || @user['is_admin'] == 1
    
    title = params['title'].to_s.strip
    description = params['description'].to_s.strip
    
    if title.empty?
      @error = 'Thread title is required'
      return erb :thread_edit
    end
    
    if using_postgres?
      db.execute('UPDATE threads SET title = ?, description = ?, updated_at = now() WHERE id = ?',
        [title, description, params['id']])
    else
      db.execute('UPDATE threads SET title = ?, description = ?, updated_at = datetime("now") WHERE id = ?',
        [title, description, params['id']])
    end
    
    redirect "/threads/#{params['id']}"
  end

  delete '/threads/:id' do
    require_login
    @user = current_user
    @thread = db.execute('SELECT * FROM threads WHERE id = ?', [params['id']]).first
    halt 404 unless @thread
    
    @project = db.execute('SELECT * FROM projects WHERE id = ?', [@thread['project_id']]).first
    halt 403 unless @thread['user_id'] == @user['id'] || @project['owner_id'] == @user['id'] || @user['is_admin'] == 1
    
    project_id = @thread['project_id']
    db.execute('DELETE FROM messages WHERE thread_id = ?', [params['id']])
    db.execute('DELETE FROM threads WHERE id = ?', [params['id']])
    
    redirect "/projects/#{project_id}"
  end

  # ---- MESSAGES ----
  post '/threads/:id/messages' do
    require_login
    @user = current_user
    thread_id = params['id'].to_i
    @thread = db.execute('SELECT * FROM threads WHERE id = ?', [thread_id]).first
    halt 404 unless @thread
    
    @project = db.execute('SELECT * FROM projects WHERE id = ?', [@thread['project_id']]).first
    is_member = is_project_member?(@user['id'], @project['id'])
    halt 403 unless is_member || @project['owner_id'] == @user['id'] || @user['is_admin'] == 1
    
    content = params['content'].to_s.strip
    if content.empty?
      @error = 'Message content is required'
      redirect "/threads/#{thread_id}"
    end
    
    db.execute('INSERT INTO messages (thread_id, user_id, content) VALUES (?, ?, ?)',
      [thread_id, @user['id'], content])
    
    redirect "/threads/#{thread_id}"
  end

  get '/messages/:id/edit' do
    require_login
    @user = current_user
    @message = db.execute('SELECT * FROM messages WHERE id = ?', [params['id']]).first
    halt 404 unless @message
    
    @thread = db.execute('SELECT * FROM threads WHERE id = ?', [@message['thread_id']]).first
    halt 403 unless @message['user_id'] == @user['id'] || @user['is_admin'] == 1
    
    erb :message_edit
  end

  post '/messages/:id' do
    require_login
    @user = current_user
    @message = db.execute('SELECT * FROM messages WHERE id = ?', [params['id']]).first
    halt 404 unless @message
    
    halt 403 unless @message['user_id'] == @user['id'] || @user['is_admin'] == 1
    
    content = params['content'].to_s.strip
    if content.empty?
      @error = 'Message content is required'
      @thread = db.execute('SELECT * FROM threads WHERE id = ?', [@message['thread_id']]).first
      return erb :message_edit
    end
    
    if using_postgres?
      db.execute('UPDATE messages SET content = ?, updated_at = now() WHERE id = ?',
        [content, params['id']])
    else
      db.execute('UPDATE messages SET content = ?, updated_at = datetime("now") WHERE id = ?',
        [content, params['id']])
    end
    
    @thread = db.execute('SELECT * FROM threads WHERE id = ?', [@message['thread_id']]).first
    redirect "/threads/#{@thread['id']}"
  end

  delete '/messages/:id' do
    require_login
    @user = current_user
    @message = db.execute('SELECT * FROM messages WHERE id = ?', [params['id']]).first
    halt 404 unless @message
    
    halt 403 unless @message['user_id'] == @user['id'] || @user['is_admin'] == 1
    
    thread_id = @message['thread_id']
    db.execute('DELETE FROM messages WHERE id = ?', [params['id']])
    
    redirect "/threads/#{thread_id}"
  end

  run! if app_file == $0
end