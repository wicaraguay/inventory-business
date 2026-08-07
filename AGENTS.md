# Inventy — Agent Guide

Inventory system with low-stock alerts for a single footwear business (calzado).
Everything runs **local via Docker**. Dart everywhere it can: Flutter client + Dart backend.

## Architecture (decided)

- **Backend** → Dart backend with **Hexagonal architecture** (Ports & Adapters): `domain / application / infrastructure`. Postgres is an adapter, never leaks into domain.
- **Flutter app** (web + native, one codebase) → **Feature-first** (`presentation / domain / data`), Riverpod, container-presentational, atomic design. NOT hexagonal (it is a UI).
- **Database** → Postgres (local, Docker). Core model: Product → Variant (talle/color, own stock + low-stock threshold) → StockMovement (stock = sum of movements).
- **Scanning** → barcode + QR via `mobile_scanner`, on web AND native. Web camera needs HTTPS → Caddy.
- **Alerts** → in-app first (badge/dashboard). WhatsApp Business API deferred to phase 2.

## Decided stack

- Backend framework: **Dart Frog** (clean hexagonal, full control).
- Data access: raw **`postgres`** package (SQL by hand in infrastructure adapters).
- Migrations: **dbmate**. IDs: **uuid** (client can generate offline). Variant attributes: **JSONB**.

## Project Skills

Read the matching `SKILL.md` before working in that area.

| Skill | When |
|-------|------|
| [hexagonal-backend](.claude/skills/hexagonal-backend/SKILL.md) | Any backend code (domain, use cases, repositories, routes) |
| [flutter-architecture](.claude/skills/flutter-architecture/SKILL.md) | Any Flutter app code (screens, widgets, Riverpod, scanning) |
| [testing-strategy](.claude/skills/testing-strategy/SKILL.md) | Writing/running tests; TDD cycle; test pyramid |
| [docker-workflow](.claude/skills/docker-workflow/SKILL.md) | Run/build/migrate/test execution; compose services; local HTTPS |
| [project-conventions](.claude/skills/project-conventions/SKILL.md) | Commits, branches, naming, structure |

## Intended layout

```
inventy-bussiness/
├── backend/            # Dart Frog — hexagonal
├── app/                # Flutter — feature-first
├── db/                 # dbmate migrations
├── caddy/Caddyfile     # local HTTPS reverse proxy
├── docker-compose.yml
└── .env.example
```
