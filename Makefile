.PHONY: up down restart logs setup status ps backup

# Primary
up:
	docker compose up -d

down:
	docker compose down

restart:
	docker compose restart

# Hermes-specific
setup:
	@echo "Running Hermes first-time setup..."
	docker compose run --rm hermes setup

status:
	docker compose exec hermes hermes doctor

kanban:
	docker compose exec hermes hermes kanban list

agents:
	docker compose exec hermes hermes sessions list

# Observability
logs:
	docker compose logs -f --tail 100

logs-hermes:
	docker compose logs -f --tail 100 hermes

logs-n8n:
	docker compose logs -f --tail 100 n8n

ps:
	docker compose ps

# Maintenance
backup:
	@mkdir -p backups
	docker compose exec hermes tar czf - /opt/data/runtime | \
		cat > backups/hermes-runtime-$$(date +%F-%H%M).tar.gz
	@echo "Backup saved to backups/"

import-workflows:
	docker compose exec n8n n8n import:workflow --separate --input=/workflows

# Development
shell-hermes:
	docker compose exec hermes /bin/bash

shell-n8n:
	docker compose exec n8n /bin/sh

validate:
	docker compose config --quiet && echo "docker-compose.yml valid"
