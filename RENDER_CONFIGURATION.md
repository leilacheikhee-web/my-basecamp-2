# Render Configuration Values

Use these specific values when setting up your MyBasecamp 2 Web Service on Render.

## Environment Variables

Add these in the **Environment** tab of your Web Service:

### Required Variables

| Name             | Value                         | Notes                                    |
| ---------------- | ----------------------------- | ---------------------------------------- |
| `SESSION_SECRET` | (generate with command below) | **Must be unique and secret**            |
| `RACK_ENV`       | `production`                  | Tells the app it's running in production |

### Automatically Provided

| Name           | What It Is                                                            |
| -------------- | --------------------------------------------------------------------- |
| `DATABASE_URL` | Automatically injected by Render when you connect PostgreSQL database |
| `PORT`         | Automatically set by Render (defaults to 8080)                        |

### How to Generate SESSION_SECRET

Run this in your terminal **locally** (not on Render):

```bash
ruby -e "puts SecureRandom.random_bytes(32).unpack('H*')[0]"
```

Copy the output (a long hex string) and paste it as the value for `SESSION_SECRET`.

---

## Health Check Path (Optional but Recommended)

**Field**: Health Check Path

**Value**: `/`

**Why**: Render will periodically check that your app is responding at the root URL. If it fails, Render can auto-restart your service.

---

## Pre-Deploy Command (Database Migrations)

**Field**: Pre-Deploy Command

**Leave EMPTY** - MyBasecamp 2 automatically creates tables on first run.

(If you add migration logic later, you'd put: `ruby db_migrate.rb` or similar)

---

## Auto-Deploy

**Setting**: Auto-Deploy

**Recommendation**: Keep **ON** (default)

- Your app deploys automatically whenever you push to GitHub
- Great for development
- Can disable later if you want manual control

---

## Build Filters (Optional - For Performance)

These prevent unnecessary rebuilds when you only change certain files.

### Ignored Paths (Don't trigger rebuild)

Add these paths to avoid rebuilding when you change:

```
.gitignore
README.md
QUICK_DEPLOY.md
DEPLOYMENT_GUIDE.md
public/style.css
```

**Why**: These files don't affect your app's runtime - no need to rebuild Docker image for documentation changes.

### Included Paths (Do trigger rebuild)

Leave empty OR add to be explicit about what triggers builds:

```
my_basecamp.rb
Gemfile
Gemfile.lock
Dockerfile
config.ru
views/
public/
```

---

## Complete Configuration Summary

```
🔧 Environment Variables:
   SESSION_SECRET = (your generated secret)
   RACK_ENV = production

🏥 Health Check Path:
   /

📋 Pre-Deploy Command:
   (leave empty)

⚙️ Build Filters - Ignored Paths:
   .gitignore
   README.md
   QUICK_DEPLOY.md
   DEPLOYMENT_GUIDE.md
   public/style.css

🔄 Auto-Deploy:
   ON (checked)
```

---

## Secret Files (Alternative Method)

If you prefer to store environment variables in a **Secret File** instead:

1. Create a `.env` file locally with your secrets
2. In Render: **Secret Files** → **Add Secret File**
3. Upload your `.env` file
4. It will be available at `/etc/secrets/.env` at runtime

Your app uses `require 'dotenv/load'` which handles this automatically.

**For most projects**: Use **Environment Variables** above (simpler, recommended).

---

## Step-by-Step on Render Dashboard

1. Go to your **Web Service** settings
2. Click the **Environment** tab
3. Add `SESSION_SECRET` and `RACK_ENV`:
   - Click **Add Environment Variable**
   - Enter name and value
   - Hit Enter to save
4. (Optionally) Set **Health Check Path** to `/`
5. (Optionally) Add **Ignored Paths** for build filters
6. Leave everything else as default
7. Render auto-deploys when you save

---

## What Each Part Does

| Setting                   | Purpose             | For MyBasecamp 2                                 |
| ------------------------- | ------------------- | ------------------------------------------------ |
| **Environment Variables** | App configuration   | Tells app it's production, stores session secret |
| **DATABASE_URL**          | Database connection | Auto-provided by Render's PostgreSQL             |
| **Health Check**          | Uptime monitoring   | Checks that `/` responds with HTTP 200           |
| **Pre-Deploy Command**    | Setup before deploy | Not needed - tables auto-create                  |
| **Build Filters**         | CI/CD optimization  | Skip rebuilds for doc-only changes               |
| **Auto-Deploy**           | Deployment trigger  | Deploy on every GitHub push                      |

---

## Troubleshooting

| Problem                     | Check                                                                           |
| --------------------------- | ------------------------------------------------------------------------------- |
| "App won't start"           | Verify `SESSION_SECRET` and `RACK_ENV=production` are set                       |
| "Database connection error" | Verify PostgreSQL database is created and `DATABASE_URL` appears in Environment |
| "Unnecessary rebuilds"      | Add more paths to Ignored Paths in build filters                                |
| "App keeps restarting"      | Check Health Check Path is set to `/` and working                               |

---

## After Setting Up

1. Click **Manual Deploy** to deploy with new settings
2. Watch the **Logs** tab for deployment progress
3. Once deployed, click **Visit Site**
4. Register your first user (becomes admin)
5. Test all features!

**Done!** 🚀
