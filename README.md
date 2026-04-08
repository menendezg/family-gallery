# Photo Gallery

A private, self-hosted photo gallery. Only authenticated users can view photos. Only admins can upload or delete them.

**Stack:** Ruby on Rails 8.1 · Hotwire (Turbo + Stimulus) · SQLite · Active Storage (local disk)

---

## Table of Contents

- [Requirements](#requirements)
- [Local Development](#local-development)
- [User Management](#user-management)
- [Production Deployment](#production-deployment)
- [Backups](#backups)
- [Environment Variables](#environment-variables)

---

## Requirements

| Dependency | Version |
|---|---|
| Ruby | 3.3+ |
| Rails | 8.1+ |
| SQLite | 3.8+ |
| libvips | 8.x (image thumbnails) |

Install libvips on Ubuntu/Debian:

```bash
sudo apt install libvips
```

Install libvips on macOS:

```bash
brew install vips
```

---

## Local Development

```bash
# Install dependencies
bundle install

# Set up the database and create the default admin user
rails db:migrate db:seed

# Start the server
rails server
```

Visit `http://localhost:3000` and sign in with:

```
Username: admin
Password: changeme123
```

**Change the admin password immediately** — see [User Management](#user-management).

---

## User Management

All user management is done via Rails tasks.

```bash
# Create a read-only user
rails users:create USERNAME=alice PASSWORD=secret123

# Promote a user to admin (can upload and delete photos)
rails users:make_admin USERNAME=alice
```

To change a password, use the Rails console:

```bash
rails console
User.find_by(username: "alice").update!(password: "newpassword")
```

---

## Production Deployment

### 1. Clone and install

```bash
git clone <your-repo-url> /var/www/photo-gallery
cd /var/www/photo-gallery
bundle install --deployment --without development test
```

### 2. Configure credentials

Rails uses an encrypted credentials file. Set a secret key base:

```bash
rails credentials:edit
```

Add the following inside the file:

```yaml
secret_key_base: <output of `rails secret`>
```

Or set it as an environment variable instead (see [Environment Variables](#environment-variables)).

### 3. Set up the database

```bash
RAILS_ENV=production rails db:migrate
RAILS_ENV=production rails db:seed
```

### 4. Precompile assets

```bash
RAILS_ENV=production rails assets:precompile
```

### 5. Run the server

Use a process manager like systemd. Example unit file at `/etc/systemd/system/photo-gallery.service`:

```ini
[Unit]
Description=Photo Gallery (Rails)
After=network.target

[Service]
Type=simple
User=www-data
WorkingDirectory=/var/www/photo-gallery
Environment=RAILS_ENV=production
Environment=RAILS_LOG_LEVEL=info
EnvironmentFile=/var/www/photo-gallery/.env
ExecStart=/usr/local/bin/bundle exec puma -C config/puma.rb
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
```

```bash
sudo systemctl enable photo-gallery
sudo systemctl start photo-gallery
```

### 6. Reverse proxy with Nginx

```nginx
server {
    listen 80;
    server_name yourdomain.com;

    # Redirect HTTP to HTTPS
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl;
    server_name yourdomain.com;

    ssl_certificate     /etc/letsencrypt/live/yourdomain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/yourdomain.com/privkey.pem;

    root /var/www/photo-gallery/public;

    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # Serve static assets directly without hitting Rails
    location ~ ^/(assets|packs) {
        gzip_static on;
        expires max;
        add_header Cache-Control public;
    }
}
```

Enable HTTPS with Let's Encrypt:

```bash
sudo apt install certbot python3-certbot-nginx
sudo certbot --nginx -d yourdomain.com
```

### 7. Enable SSL in Rails

Uncomment these two lines in `config/environments/production.rb`:

```ruby
config.assume_ssl = true
config.force_ssl = true
```

---

## Backups

All persistent data lives in the `storage/` directory:

| Path | Contents |
|---|---|
| `storage/production.sqlite3` | Users, photo metadata |
| `storage/production_cache.sqlite3` | Cache (safe to delete) |
| `storage/production_queue.sqlite3` | Job queue (safe to delete) |
| `storage/` (blob files) | Uploaded photo files |

**Back up the entire `storage/` directory.** A simple cron job:

```bash
# /etc/cron.d/photo-gallery-backup
0 3 * * * www-data tar -czf /backups/photo-gallery-$(date +\%F).tar.gz /var/www/photo-gallery/storage
```

To restore: stop the server, replace `storage/` with the backup, restart.

---

## Environment Variables

Create a `.env` file in the project root (never commit this):

```bash
SECRET_KEY_BASE=<output of rails secret>
RAILS_LOG_LEVEL=info
```

`SECRET_KEY_BASE` is required in production if you are not using `rails credentials:edit`.
