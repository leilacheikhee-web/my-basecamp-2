# Quick Deployment Reference

## Local Development

```bash
cp .env.example .env
bundle install
bundle exec rackup
# Visit http://localhost:8080
# Uses SQLite automatically
```

## Deploy to Render (5 Minutes)

### 1. Generate Session Secret

```bash
ruby -e "puts SecureRandom.random_bytes(32).unpack('H*')[0]"
```

### 2. Push Code to GitHub

```bash
git add .
git commit -m "Add cloud deployment support"
git push origin main
```

### 3. On Render Dashboard

**Create Web Service:**

- Connect GitHub repo
- Environment: Docker
- Keep defaults, click Create

**Create PostgreSQL Database:**

- New → PostgreSQL
- Keep defaults, click Create

**Connect Database to Web Service:**

- Go to Web Service → Environment
- Verify `DATABASE_URL` appears from PostgreSQL

**Add Environment Variables:**

- `SESSION_SECRET=` (paste from step 1)
- `RACK_ENV=production`

**Deploy:**

- Wait for auto-deploy (Render handles this)
- Click "Visit Site" when ready

## How It Works

| Component | Local               | Production          |
| --------- | ------------------- | ------------------- |
| Database  | SQLite (local file) | PostgreSQL (Render) |
| Detection | No `DATABASE_URL`   | `DATABASE_URL` set  |
| Data      | Lost on restart     | Persistent          |

**App automatically switches based on `DATABASE_URL` env variable!**

## Troubleshooting

| Issue                      | Solution                                            |
| -------------------------- | --------------------------------------------------- |
| Database connection failed | Verify `DATABASE_URL` in Environment vars, redeploy |
| Tables don't exist         | Check Render logs for errors, tables auto-create    |
| Files not persisting       | Use Render Disk or cloud storage (S3)               |
| Can't login                | Normal after redeploy - re-register user            |

See [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md) for full details.
