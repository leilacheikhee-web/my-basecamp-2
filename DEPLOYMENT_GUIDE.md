# Deployment Guide: MyBasecamp 2 on Render

## Overview

This guide walks you through deploying MyBasecamp 2 to Render with PostgreSQL database support.

## Key Architecture Points

### Local Development

- Uses **SQLite3** (local file database)
- No `DATABASE_URL` environment variable set
- Quick setup, perfect for development

### Production (Render)

- Uses **PostgreSQL** (managed by Render)
- `DATABASE_URL` automatically injected by Render
- App automatically detects and uses it

**The Problem Solved**: The app now checks for `DATABASE_URL` and switches database backends automatically. No more crashes on ephemeral filesystems!

## Step-by-Step Deployment

### Step 1: Update Your Code

Ensure you have the latest code with environment variable support:

```bash
# Pull latest changes if working with a team
git pull

# Install updated gems locally first
bundle install
```

### Step 2: Configure Local Development

```bash
# Copy the example environment file
cp .env.example .env

# Edit .env - for local dev with SQLite, leave DATABASE_URL commented
nano .env
```

Your `.env` should look like:

```
PORT=8080
SESSION_SECRET=your_development_secret_here
RACK_ENV=development
# DATABASE_URL is commented out - SQLite will be used
```

### Step 3: Test Locally

```bash
# Install dependencies
bundle install

# Run the app
bundle exec rackup

# Visit http://localhost:8080
```

### Step 4: Generate Production SESSION_SECRET

Generate a secure random string:

```bash
ruby -e "puts SecureRandom.random_bytes(32).unpack('H*')[0]"
```

Save this output - you'll need it in Step 7.

### Step 5: Commit and Push to GitHub

```bash
git add .
git commit -m "Add cloud deployment support with PostgreSQL"
git push origin main
```

**Ensure these files are committed:**

- `my_basecamp.rb` (updated)
- `Gemfile` (updated)
- `Dockerfile` (updated)
- `.env.example` (new)
- `.gitignore` (new)

### Step 6: Create Render Account & Services

1. Go to [render.com](https://render.com)
2. Sign up and connect your GitHub repository

### Step 7: Create Web Service on Render

1. Click **New +** → **Web Service**
2. Select your repository
3. Fill in the form:
   - **Name**: `mybasecamp` (or your choice)
   - **Environment**: `Docker`
   - **Build Command**: Leave as default (uses Dockerfile)
   - **Start Command**: Leave as default

4. Click **Create Web Service**

**Wait 5-10 minutes** while Render builds and deploys.

### Step 8: Create PostgreSQL Database on Render

1. In Render dashboard, click **New +** → **PostgreSQL**
2. Fill in:
   - **Name**: `mybasecamp-db`
   - **Database**: `basecamp`
   - **User**: `basecamp`
   - **Region**: Same as Web Service
   - **Version**: Default is fine

3. Click **Create Database**

### Step 9: Connect Database to Web Service

1. Go back to your **Web Service**
2. Go to **Environment** tab
3. Click **Add Environment Variable**
4. Render should auto-detect and add `DATABASE_URL` from the PostgreSQL database

**Verify it appears** - it should look like:

```
DATABASE_URL=postgresql://basecamp:xxxxx@xxxxx.render.internal:5432/basecamp
```

### Step 10: Set Application Environment Variables

In the **Environment** tab, add these variables:

```
SESSION_SECRET=<paste the secure random string from Step 4>
RACK_ENV=production
```

### Step 11: Deploy

1. Render should auto-redeploy when variables are saved
2. Watch the **Logs** tab for deployment progress
3. Once deployed, click **Visit Site** to test

### Step 12: Create First Admin User

1. Visit your Render app URL
2. Click **Register**
3. Fill in the form (first user becomes admin)
4. Log in and start using!

## Troubleshooting

### "Database connection failed"

**Check:**

- `DATABASE_URL` is set in Environment variables
- PostgreSQL database is fully created (may take 1-2 min)
- Redeploy the Web Service after setting DATABASE_URL

**Deploy again:**

```
Go to Web Service → Manual Deploy → Select your branch
```

### "Tables don't exist"

**Solution:**

- Tables are created automatically on first app startup
- Check logs: **Web Service → Logs → top of logs**
- Look for "CREATE TABLE" messages

### "File uploads not persisting"

This is expected! Render has ephemeral storage. Solutions:

**Option 1: Use Render Disk (Simple)**

- Web Service → **Disks** tab
- Add a new disk at `/app/public/uploads`
- Files persist between restarts

**Option 2: Use Cloud Storage (Advanced)**

- AWS S3, Cloudinary, or similar
- Modify upload code to use their APIs
- Files persist forever

### "Can't login after redeployment"

This is normal! Each database restart clears SQLite data. With PostgreSQL:

- Data persists between restarts ✓
- Re-register if your user data was lost
- This shouldn't happen once properly deployed

## Environment Variable Reference

| Variable         | Local         | Production   | Example                          |
| ---------------- | ------------- | ------------ | -------------------------------- |
| `DATABASE_URL`   | (not set)     | ✓ (auto)     | `postgresql://user:pass@host/db` |
| `SESSION_SECRET` | optional      | ✓ required   | (64-char random string)          |
| `RACK_ENV`       | `development` | `production` | -                                |
| `PORT`           | `8080`        | (auto)       | -                                |

## Database Considerations

### SQLite (Local Development)

- File: `basecamp.db`
- Pros: Simple, no setup
- Cons: Single-user, not for production

### PostgreSQL (Production)

- Managed by Render
- Pros: Multi-user, fast, reliable, automatic backups
- Cons: Slightly slower for tiny projects

**The App Handles Both Automatically** - no code changes needed!

## How It Works Under the Hood

```ruby
# In my_basecamp.rb

def db
  @db ||= begin
    if ENV['DATABASE_URL']
      # Production: Use PostgreSQL via Render
      establish_postgres_connection
    else
      # Development: Use SQLite locally
      establish_sqlite_connection
    end
  end
end
```

When Render injects `DATABASE_URL`, the app automatically switches!

## Next Steps After Deployment

1. **Test all features**: Register, create projects, upload files
2. **Share with team**: Give them the Render URL
3. **Monitor logs**: Check for errors in Render logs tab
4. **Set up backups**: PostgreSQL data is auto-backed up, but good to know

## Support

If issues persist:

1. Check Render logs: **Web Service → Logs**
2. Check Dockerfile: Make sure image built successfully
3. Check Environment Variables: All required vars set?
4. Test locally first: Ensure code works with `bundle exec rackup`

## Security Checklist

- [ ] `SESSION_SECRET` is unique and strong
- [ ] Never commit `.env` file (only `.env.example`)
- [ ] `RACK_ENV=production` is set
- [ ] Database credentials only in environment variables
- [ ] Review Render documentation for SSL/HTTPS (auto-enabled)

Happy deploying! 🚀
