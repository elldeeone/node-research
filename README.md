# Node Research

Purpose:
- umbrella repo for node-focused investigations
- each investigation folder self-contained
- shared tooling for all node investigations lives under `shared/`

Local bootstrap:
- `python3 -m venv .venv`
- `. .venv/bin/activate`
- `python investigations/node-resource-usage/scripts/check-audit-pack.py`
- `python shared/charting/generate-timeline-charts.py --config investigations/node-resource-usage/charts/timeline-charts.json`

Layout:
- `investigations/`
- `shared/`

Shared layout:
- `shared/collectors/` for capture scripts used across investigations
- `shared/parsers/` for raw-to-normalized parsers used across investigations
- `shared/schemas/` for common templates and formats
- `shared/charting/` for reusable chart generators and helpers

Repo rules:
- each investigation should be publishable on its own
- no investigation should depend on another investigation's internal files
- `shared/` is only for reusable tooling, helpers, schemas, or common chart logic
- investigation-local `scripts/` should only contain investigation-specific helpers
- heavy raw artifacts stay out of Git; manifests stay in Git

Current verified flow:
- audit-pack validation from copied investigation data
- timeline chart regeneration via `shared/charting/generate-timeline-charts.py`
- raw bundle packaging into local ignored `release-bundles/`

Current investigation shape:
- `figures/`
- `charts/`
- `scripts/` for investigation-specific helpers only
- `data/manifests/`
- `data/runs/`
- `data/supporting/`
