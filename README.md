# Hermes Personal Assistant Stack

Multi-agent personal assistant: finance, tech news, second brain (Obsidian), email triage, n8n automation, GitHub coding tasks. All orchestrated through a single Discord interface.

## Architecture

```
Discord ──► Hermes Master (gateway:8642)
              │
              ├─ delegate_task (sync)  ─► fork-join lookups
              └─ Kanban dispatcher     ─► spawns workers per profile
                    │
                    ├── finance     (polymarket, Alpha Vantage, CoinGecko)
                    ├── news        (HN, RSS, X, arXiv, YouTube)
                    ├── brain       (Obsidian REST + obsidian-mcp)
                    ├── email       (Gmail — DRAFT-ONLY guard)
                    ├── n8n-eng     (n8n-mcp programmatic workflow CRUD)
                    └── gh-eng      (sandboxed coding, opens PRs)

n8n (5678) ──► cron triggers ──► HTTP POST master
n8n-mcp (3001) ◄── n8n-eng builds workflows here
obsidian-mcp (3002) ──► host Obsidian Local REST API plugin (27124)
postgres (5432) ──► n8n state
hermes-dashboard (9119) ──► Kanban UI
```

## Prerequisites

- Docker + Docker Compose
- Discord bot token + guild
- Obsidian + Local REST API plugin installed on host (vault path in `.env`)
- Gmail OAuth credentials (client id/secret/refresh token)
- GitHub PAT with `repo` scope
- LLM API key (OpenRouter recommended)

## First-Time Setup

```bash
cp .env.example .env
$EDITOR .env                    # fill in tokens
make up                         # docker compose up -d
make setup                      # interactive Hermes setup wizard
make status                     # hermes doctor
```

Open dashboard: http://localhost:9119
Open n8n: http://localhost:5678 (basic auth from `.env`)

## Daily Use

All interaction is in Discord:
- DM the bot or mention it in `#master`
- Master routes to the right specialist (you don't pick)
- After approving a session, master may suggest an n8n cron workflow

Channels (you create on Discord side, paste IDs into `.env`):
- `#master` — general
- `#finance`, `#news`, `#brain`, `#email` — topic-specific output

## Persistence Model

Static (in git):
- `hermes/<profile>/config.yaml` and `SOUL.md`
- `hermes/shared/skills/`, `hermes/shared/hooks/`
- `n8n/workflows/*.json` (cron definitions)

Runtime (named volumes, NEVER in git):
- `hermes-runtime` — memories, sessions, kanban.db, checkpoints, logs
- `n8n-data` — n8n internal state
- `postgres-data` — n8n DB

Backup: `make backup` snapshots `hermes-runtime` to `./backups/`.

## n8n Runtime Builder

After a session, master evaluates if the task is recurring. If yes, it asks in Discord:

> 🛠️ This looks repeatable. Convert to n8n cron workflow?
> Reply `/n8n approve` to build, `/n8n skip` to dismiss.

On approval, master delegates to `n8n-eng` with full session context. `n8n-eng` uses `n8n-mcp` tools to:
1. Search templates (`search_templates`)
2. Discover nodes (`search_nodes`)
3. Validate node configs (`validate_node`)
4. Build + validate workflow (`validate_workflow`)
5. Deploy (`n8n_create_workflow`) and persist JSON to `n8n/workflows/` for git

## Email Safety

`hermes/shared/hooks/pre_tool.sh` intercepts every `gmail_send` / `messages.send` call and downgrades to draft creation. Set `EMAIL_DRAFT_ONLY=false` in `.env` to disable (NOT recommended).

Approval flow:
1. Email agent drafts reply → posts to `#email` with diff
2. User reacts ✅ or types `Approve`
3. Master calls `users.drafts.send`

## GitHub Coding Tasks

Master detects coding intent → opens issue in `${GITHUB_REPO}` labeled `${GITHUB_ISSUE_LABEL}`. `gh-eng` polls labeled-unassigned issues, claims, plans (in issue comment), branches, implements in sandboxed Docker, opens PR. Never pushes to default branch.

## Customization

- **Add an agent**: create `hermes/<name>/{config.yaml,SOUL.md}`, mount in `docker-compose.yml` under hermes service profiles section, restart.
- **Add an n8n workflow manually**: drop JSON in `n8n/workflows/`, run `make import-workflows`.
- **Tune master routing**: edit `hermes/master/SOUL.md` routing table.
- **Add a skill**: drop `SKILL.md` in `hermes/shared/skills/<name>/`, list in profile's `skills.enabled`.

## Troubleshooting

| Problem | Fix |
|---|---|
| `obsidian-mcp` can't reach plugin | Check Obsidian is running, plugin enabled, port 27124 open. Use `host.docker.internal` not `localhost`. |
| Discord bot offline | Verify token; check `make logs-hermes` for OAuth errors |
| n8n workflows not imported | `make import-workflows`; check `make logs-n8n` |
| Email send not blocked | Verify `EMAIL_DRAFT_ONLY=true`, hook executable: `ls -l hermes/shared/hooks/pre_tool.sh` |
| Kanban worker not picking up tasks | Check assignee matches profile name exactly: `make kanban` |

## File Tree

```
hermes-stack/
├── docker-compose.yml          # all services
├── .env.example                # config template
├── Makefile                    # convenience targets
├── README.md
├── scripts/
│   └── n8n-import.sh           # auto-imports workflows on n8n startup
├── hermes/
│   ├── master/{config,SOUL}    # gateway + dispatcher
│   ├── finance/{config,SOUL}
│   ├── news/{config,SOUL}
│   ├── brain/{config,SOUL}
│   ├── email/{config,SOUL}
│   ├── n8n-eng/{config,SOUL}
│   ├── gh-eng/{config,SOUL}
│   └── shared/
│       ├── skills/             # custom skill packs (empty by default)
│       └── hooks/
│           ├── pre_tool.sh     # email guard
│           └── post_session.sh # n8n suggestion trigger
└── n8n/
    └── workflows/              # cron definitions, in git
        ├── daily-finance-brief.json
        ├── tech-news-digest.json
        ├── email-triage.json
        ├── obsidian-daily-note.json
        └── weekly-review.json
```

## Stack Versions Pinned

- `nousresearch/hermes-agent:latest` — pin to a tag for prod
- `n8nio/n8n:latest`
- `ghcr.io/czlonkowski/n8n-mcp:latest`
- `ghcr.io/cyanheads/obsidian-mcp-server:latest`
- `postgres:16-alpine`

For prod, pin all tags to specific versions in `docker-compose.yml`.
