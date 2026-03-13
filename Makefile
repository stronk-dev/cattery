.PHONY: up down build rebuild dev schema-snapshot schema-apply favicons prod-up prod-down prod-deploy hooks

PROD_COMPOSE = docker compose -f docker-compose.yml -f docker-compose.prod.yml
SITE_DIR ?= /var/www/cattery

# ── Dev ─────────────────────────────────
up:
	mkdir -p directus/database directus/uploads directus/extensions
	chmod 777 directus/database directus/uploads directus/extensions
	docker compose up -d

down:
	docker compose down

build:
	cd frontend && npm run build

rebuild: build
	@echo "Site rebuilt. Caddy serves new files automatically."

# ── Prod ────────────────────────────────
prod-up:
	mkdir -p directus/database directus/uploads directus/extensions
	chmod 777 directus/database directus/uploads directus/extensions
	$(PROD_COMPOSE) up -d

prod-down:
	$(PROD_COMPOSE) down

prod-deploy: build
	rsync -a --delete frontend/dist/ $(SITE_DIR)/
	@echo "Deployed to $(SITE_DIR). Nginx serves new files automatically."

dev:
	cd frontend && npm run dev

schema-snapshot:
	docker compose exec directus npx directus schema snapshot /directus/database/schema-snapshot.yaml
	docker compose cp directus:/directus/database/schema-snapshot.yaml ./directus/schema-snapshot.yaml

favicons:
	bash scripts/generate-favicons.sh

hooks:
	@REBUILD_TOKEN=$$(grep -m1 '^REBUILD_TOKEN=' .env | cut -d= -f2-) && \
		sed "s/\$${REBUILD_TOKEN}/$$REBUILD_TOKEN/" scripts/hooks.json.tpl > scripts/hooks.json
	@echo "Generated scripts/hooks.json"

schema-apply:
	docker compose cp ./directus/schema-snapshot.yaml directus:/directus/database/schema-snapshot.yaml
	docker compose exec directus npx directus schema apply /directus/database/schema-snapshot.yaml --yes
