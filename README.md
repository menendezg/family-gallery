# Photo Gallery

A private, self-hosted photo gallery. Only authenticated users can view photos. Only admins can upload or delete them.

**Stack:** Ruby on Rails 8.1 · Hotwire (Turbo + Stimulus) · SQLite · Active Storage (local disk)

---

## Table of Contents

- [Requirements](#requirements)
- [Local Development](#local-development)
- [User Management](#user-management)
- [Production Deployment](#production-deployment)
- [Cloudflare Setup](#cloudflare-setup)
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

## Cloudflare Setup

Cloudflare sits in front of your server and handles DNS, DDoS protection, and SSL termination. The traffic flow is:

```
Browser → Cloudflare (HTTPS) → Your server (HTTP, local only) → Rails
```

### 1. DNS

In the Cloudflare dashboard, add an **A record** pointing your domain to your server's public IP with the proxy enabled (orange cloud).

### 2. SSL/TLS mode

Go to **SSL/TLS → Overview** and set the mode to **Full (strict)**.

- **Full (strict)** encrypts traffic between Cloudflare and your server using a valid certificate. This is the most secure option.
- Do **not** use "Flexible" — it sends traffic to your server over plain HTTP and creates false security.

To get a free origin certificate from Cloudflare (valid 15 years):

1. Go to **SSL/TLS → Origin Server → Create Certificate**
2. Download the certificate and key to your server
3. Reference them in your Nginx config:

```nginx
ssl_certificate     /etc/ssl/cloudflare/origin.pem;
ssl_certificate_key /etc/ssl/cloudflare/origin.key;
```

### 3. Nginx config for Cloudflare

Cloudflare connects to your server on port 443. Your server should only accept traffic from Cloudflare's IP ranges — not from the open internet — so the gallery stays private even if someone discovers your server's IP.

```nginx
server {
    listen 443 ssl;
    server_name yourdomain.com;

    ssl_certificate     /etc/ssl/cloudflare/origin.pem;
    ssl_certificate_key /etc/ssl/cloudflare/origin.key;

    # Only allow Cloudflare IPs — block direct access to your server IP.
    # Keep this list updated: https://www.cloudflare.com/ips/
    allow 173.245.48.0/20;
    allow 103.21.244.0/22;
    allow 103.22.200.0/22;
    allow 103.31.4.0/22;
    allow 141.101.64.0/18;
    allow 108.162.192.0/18;
    allow 190.93.240.0/20;
    allow 188.114.96.0/20;
    allow 197.234.240.0/22;
    allow 198.41.128.0/17;
    allow 162.158.0.0/15;
    allow 104.16.0.0/13;
    allow 104.24.0.0/14;
    allow 172.64.0.0/13;
    allow 131.0.72.0/22;
    # IPv6
    allow 2400:cb00::/32;
    allow 2606:4700::/32;
    allow 2803:f800::/32;
    allow 2405:b500::/32;
    allow 2405:8100::/32;
    allow 2a06:98c0::/29;
    allow 2c0f:f248::/32;
    deny all;

    # Pass the real visitor IP from Cloudflare to Rails
    set_real_ip_from 173.245.48.0/20;
    set_real_ip_from 103.21.244.0/22;
    set_real_ip_from 103.22.200.0/22;
    set_real_ip_from 103.31.4.0/22;
    set_real_ip_from 141.101.64.0/18;
    set_real_ip_from 108.162.192.0/18;
    set_real_ip_from 190.93.240.0/20;
    set_real_ip_from 188.114.96.0/20;
    set_real_ip_from 197.234.240.0/22;
    set_real_ip_from 198.41.128.0/17;
    set_real_ip_from 162.158.0.0/15;
    set_real_ip_from 104.16.0.0/13;
    set_real_ip_from 104.24.0.0/14;
    set_real_ip_from 172.64.0.0/13;
    set_real_ip_from 131.0.72.0/22;
    real_ip_header CF-Connecting-IP;

    root /var/www/photo-gallery/public;

    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location ~ ^/assets {
        gzip_static on;
        expires max;
        add_header Cache-Control public;
    }
}
```

### 4. Rails config for Cloudflare

Because Cloudflare terminates SSL and forwards HTTP to your server, Rails needs to know it is behind a trusted proxy. Uncomment these lines in `config/environments/production.rb`:

```ruby
config.assume_ssl = true   # tells Rails that all requests are HTTPS even if forwarded as HTTP
config.force_ssl  = true   # redirects any plain HTTP requests and sets secure cookies
```

### 5. Firewall: block port 443 from the public internet

With the Nginx IP allowlist above, Cloudflare IPs are the only ones that can reach your app over HTTPS. For extra hardening, also block port 443 at the firewall level for all IPs except Cloudflare:

```bash
# Allow SSH
sudo ufw allow 22

# Block public HTTPS — Nginx allowlist handles Cloudflare filtering,
# but closing the port at the OS level is a second layer of defense.
# Instead, only open it locally (Nginx listens; Cloudflare connects).
sudo ufw allow from any to any port 443  # keep open so Cloudflare can reach Nginx

sudo ufw enable
```

> If you want the strictest setup, use `ufw` with Cloudflare's IP ranges directly. Cloudflare publishes the current list at `https://www.cloudflare.com/ips/` — update your allowlist whenever that list changes.

### 6. Recommended Cloudflare settings

| Setting | Recommended value |
|---|---|
| SSL/TLS mode | Full (strict) |
| Always Use HTTPS | On |
| Minimum TLS Version | TLS 1.2 |
| Opportunistic Encryption | On |
| HTTP Strict Transport Security (HSTS) | Enable after confirming HTTPS works |
| Browser Cache TTL | 4 hours (photos are served by Rails, not cached by CF) |
| Caching level | Standard |

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
