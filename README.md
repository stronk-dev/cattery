# Cattery Website

Dutch cattery website built with Astro (static site generation) and Directus CMS.

## Stack

- **Frontend**: [Astro](https://astro.build/) — static HTML, scoped CSS, zero JS by default
- **CMS**: [Directus 11.5](https://directus.io/) — headless CMS with SQLite
- **Contact forms**: [Steward](https://github.com/livepeer/frameworks) — form handler with SMTP + Turnstile bot protection
- **Dev proxy**: Caddy — serves static files + proxies to Directus/Steward
- **Prod proxy**: nginx — same routing, TLS termination

## Project Structure

```
cattery/
├── frontend/              # Astro site
│   ├── src/
│   │   ├── pages/         # Routes (onze-katten, kittens, nesten, blog, etc.)
│   │   ├── components/    # Astro components (Nav, Gallery, Cards, etc.)
│   │   ├── layouts/       # Base layout with SEO
│   │   ├── lib/           # Directus client, types
│   │   └── styles/        # Global CSS
│   └── public/            # Static assets (favicons, robots.txt, llms.txt)
├── scripts/
│   ├── setup-schema.sh    # Creates Directus collections, fields, relations
│   ├── seed.sh            # Populates Directus with example data
│   ├── rebuild.sh         # Debounced rebuild triggered by Directus webhook
│   └── hooks.json.tpl     # Webhook receiver config template
├── directus/              # Directus data (database, uploads) — gitignored
├── nginx/                 # Production nginx config
├── docker-compose.yml     # Dev: Directus + Steward + Caddy
├── docker-compose.prod.yml # Prod override: disables Caddy
├── Caddyfile              # Dev reverse proxy config
├── Makefile               # All commands
└── .env.example           # Environment variables template
```

## Local Development

### Prerequisites

- Docker & Docker Compose
- Node.js 20+
- npm

### Setup

```bash
# 1. Configure environment
cp .env.example .env
# Edit .env — for dev, defaults are fine except DIRECTUS_SECRET/ADMIN_PASSWORD

# 2. Start Directus + Steward + Caddy
make up

# 3. Create CMS schema
bash scripts/setup-schema.sh

# 4. Seed example data (cats, kittens, nests, blog posts, FAQ, testimonials)
bash scripts/seed.sh

# 5. Build the static site
cd frontend && npm install && npm run build && cd ..

# 6. Open http://localhost — the site
#    Open http://localhost:8055 — Directus admin panel
```

### Day-to-day

```bash
make dev          # Astro dev server (hot reload) at http://localhost:4321
make build        # Rebuild static site
make up / down    # Start/stop Docker services
```

After editing content in Directus, run `make build` to regenerate the static site. Caddy serves the new files automatically.

## Production Deployment

### First-time setup on the server

```bash
# 1. Clone the repo
git clone <repo-url> /var/www/cattery
cd /var/www/cattery

# 2. Configure environment
cp .env.example .env
# Edit .env with real values:
#   DIRECTUS_SECRET        — run: openssl rand -hex 32
#   DIRECTUS_ADMIN_EMAIL   — your email
#   DIRECTUS_ADMIN_PASSWORD — strong password
#   DIRECTUS_PUBLIC_URL    — https://cats.stronk.tech
#   SMTP_HOST/USER/PASSWORD — your mail provider
#   FROM_EMAIL             — noreply@yourdomain
#   TO_EMAIL               — where contact emails go
#   FORMS_ALLOWED_ORIGINS  — https://cats.stronk.tech
#   REBUILD_TOKEN          — run: openssl rand -hex 16
#   TURNSTILE_SITE_KEY     — from Cloudflare (optional)
#   TURNSTILE_FORMS_SECRET_KEY — from Cloudflare (optional)

# 3. Start Directus + Steward (no Caddy — nginx handles traffic)
make prod-up

# 4. Create CMS schema + seed data + rebuild flow
bash scripts/setup-schema.sh
bash scripts/seed.sh

# 5. Build the frontend
cd frontend && npm install && npm run build && cd ..

# 6. Install nginx config
sudo cp nginx/cats.stronk.tech.conf /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl reload nginx

# 7. Install auto-rebuild webhook (optional but recommended)
sudo bash scripts/install-webhook.sh
```

### nginx

The nginx config at `nginx/cats.stronk.tech.conf` listens on port 42080 and:

- Serves static files from `frontend/dist`
- Proxies `/api/*` to Steward (contact form)
- Falls through to Directus for everything else (`/admin`, `/assets`, API paths)

TLS is handled by certbot:

```bash
sudo certbot --nginx -d cats.stronk.tech
```

### Updating the site

```bash
cd /var/www/cattery
git pull
cd frontend && npm install && npm run build
# nginx serves new files immediately — no restart needed
```

### Auto-rebuild on CMS changes

When the breeder edits content in Directus, the static site needs rebuilding. This is fully automated:

```bash
# Install webhook receiver + systemd service (one-time)
sudo bash scripts/install-webhook.sh
```

The Directus Flow is created automatically by `setup-schema.sh` (when `REBUILD_TOKEN` is set in `.env`). It fires on any content create/update/delete and POSTs to the local webhook receiver, which runs a debounced rebuild.

If the breeder saves 5 items in a row, only one rebuild runs (30s cooldown + flock).

## Environment Variables

| Variable | Used by | Required | Description |
|----------|---------|----------|-------------|
| `DIRECTUS_SECRET` | Directus | Yes | Random string for session encryption |
| `DIRECTUS_ADMIN_EMAIL` | Directus | Yes | Admin login email |
| `DIRECTUS_ADMIN_PASSWORD` | Directus | Yes | Admin login password |
| `DIRECTUS_PUBLIC_URL` | Directus | Yes | External URL for admin panel |
| `DIRECTUS_URL` | Astro build | Yes | Directus URL for data fetching (use `http://localhost:8055`) |
| `SMTP_HOST` | Steward | Yes | Mail server hostname |
| `SMTP_PORT` | Steward | No | Mail server port (default: 587) |
| `SMTP_USER` | Steward | Yes | Mail server username |
| `SMTP_PASSWORD` | Steward | Yes | Mail server password |
| `FROM_EMAIL` | Steward | Yes | Sender address for contact form |
| `TO_EMAIL` | Steward | Yes | Recipient address for contact form |
| `FORMS_ALLOWED_ORIGINS` | Steward | Yes | CORS origin (your site URL) |
| `TURNSTILE_SITE_KEY` | Astro build | No | Cloudflare Turnstile site key |
| `TURNSTILE_FORMS_SECRET_KEY` | Steward | No | Cloudflare Turnstile secret key |
| `REBUILD_TOKEN` | Webhook | No | Secret for rebuild webhook auth |

Without Turnstile keys, the contact form falls back to honeypot + behavioral bot detection.

## Makefile Commands

| Command | Description |
|---------|-------------|
| `make up` | Start all services (dev) |
| `make down` | Stop all services |
| `make dev` | Astro dev server with hot reload |
| `make build` | Build static site |
| `make prod-up` | Start Directus + Steward (no Caddy) |
| `make prod-down` | Stop prod services |
| `make prod-deploy` | Build + rsync to serving directory |
| `make hooks` | Generate webhook config from .env |
| `make favicons` | Generate favicon sizes |
| `make schema-snapshot` | Export Directus schema |
| `make schema-apply` | Import Directus schema |

## CMS Collections

| Collection | Description |
|------------|-------------|
| `site_instellingen` | Singleton — cattery name, contact info, hero image, social links |
| `katten` | Breeding cats with photos, health info, pedigree |
| `kittens` | Kittens linked to nests, with status (beschikbaar/optie/gereserveerd/verkocht) |
| `nesten` | Litters linking mother + father cats to kittens |
| `blog_berichten` | Blog posts with rich text + photo galleries |
| `paginas` | Static pages (Over Ons, Informatie) |
| `veelgestelde_vragen` | FAQ entries grouped by category |
| `ervaringen` | Testimonials from adoption families |

All collections support photo galleries via junction tables (`katten_fotos`, `kittens_fotos`, `nesten_fotos`, `blog_berichten_fotos`).
