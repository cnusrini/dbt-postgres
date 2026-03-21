# dbt-core-production

A production-grade **dbt Core** learning environment built on **PostgreSQL + Docker**, structured as a hands-on module-based walkthrough. This repo captures everything from infrastructure setup through Git discipline — the full Phase 1 foundation before any modeling begins.

---

## What This Repo Contains

```
dbt-core-production/
├── Dockerfile                          # dbt container (python:3.11-slim)
├── docker-compose.yml                  # Orchestrates dbt + PostgreSQL containers
├── .gitignore                          # Excludes artifacts, logs, credentials
└── dbt_project/
    ├── .dbt/
    │   └── profiles.yml                # Connection config (dev + prod targets)
    └── dbt_project/
        ├── dbt_project.yml             # Project config — links to profiles.yml
        ├── models/                     # SQL transformation models go here
        ├── analyses/
        ├── macros/
        ├── seeds/
        ├── snapshots/
        └── tests/
```

---

## Architecture

```
Your Mac (no local Python/dbt needed)
    │
    └── Docker Network (dbt_network)
            │
            ├── dbt_core container
            │       └── python:3.11-slim
            │               └── dbt-core 1.8.6
            │               └── dbt-postgres 1.8.2
            │
            └── dbt_postgres container
                    └── postgres:15
                            └── dbt_warehouse (database)
                                    ├── dev_schema   ← models land here in dev
                                    └── prod_schema  ← models land here in prod
```

**Key principle:** dbt never stores data. It sends SQL → PostgreSQL executes it → results live in schemas.

---

## Prerequisites

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) installed and running
- Git installed
- VS Code (recommended)

---

## Phase 1 — Production Setup & Runtime

### Module 1 — Production Runtime Architecture

**Purpose:** Build the containerized stack. PostgreSQL as the warehouse, dbt as the transformation engine, Docker as the determinism layer.

#### What you build:
- `docker-compose.yml` — defines both containers, shared network, and volume
- `Dockerfile` — builds the dbt image with pinned versions

#### Steps:

**1. Create project folder**
```bash
mkdir dbt-core-production
cd dbt-core-production
```

**2. Create `docker-compose.yml`** — see file in repo root

**3. Create `Dockerfile`** — see file in repo root

> ⚠️ Use `dbt-core==1.8.6` and `dbt-postgres==1.8.2`. Version `1.8.6` does not exist for the postgres adapter.

**4. Build and start the stack**
```bash
docker compose up -d --build
docker ps
```

**Expected output:**
```
CONTAINER ID   IMAGE         STATUS        NAMES
xxxxxxxxxxxx   postgres:15   Up X seconds  dbt_postgres
```

> The `dbt_core` container exits immediately — this is normal. It only runs on-demand CLI commands.

**5. Validate the database**
```bash
docker exec -it dbt_postgres psql -U dbt_user -d dbt_warehouse
\l
\q
```

**Expected:** `dbt_warehouse` database listed, owned by `dbt_user`.

---

### Module 2 — Runtime Configuration, Environment Isolation & Connectivity Validation

**Purpose:** Connect dbt to PostgreSQL via `profiles.yml`, initialize the project structure, and validate the full end-to-end pipeline.

#### Lab 1 — Create `profiles.yml`

```bash
mkdir -p dbt_project/.dbt
```

Create `dbt_project/.dbt/profiles.yml`:

```yaml
dbt_production_profile:
  target: dev
  outputs:
    dev:
      type: postgres
      host: postgres        # Docker resolves container name as hostname
      user: dbt_user
      password: dbt_password
      port: 5432
      dbname: dbt_warehouse
      schema: dev_schema    # Models write here in dev
      threads: 4
    prod:
      type: postgres
      host: postgres
      user: dbt_user
      password: dbt_password
      port: 5432
      dbname: dbt_warehouse
      schema: prod_schema   # Models write here in prod
      threads: 8
```

> **Key design principle:** Credentials live in `profiles.yml`, never in model SQL files. Environment routing belongs in profile, logic belongs in models.

#### Lab 2 — Initialize dbt Project

```bash
docker compose run --rm dbt init dbt_project
# When prompted: select [1] postgres
# Fill in: host=postgres, user=dbt_user, dbname=dbt_warehouse, schema=dev_schema, threads=4
```

Then configure `dbt_project/dbt_project/dbt_project.yml`:

```yaml
name: 'dbt_project'
version: '1.0'
config-version: 2

profile: 'dbt_production_profile'   # Must exactly match key in profiles.yml

model-paths: ["models"]
seed-paths: ["seeds"]
snapshot-paths: ["snapshots"]
macro-paths: ["macros"]
test-paths: ["tests"]
target-path: "target"
clean-targets:
  - "target"
  - "dbt_packages"

models:
  dbt_project:
    +materialized: view
```

Remove example models:
```bash
rm -rf dbt_project/dbt_project/models/example
```

#### Lab 3 — Full Runtime Debug

```bash
docker compose run --rm dbt debug --project-dir dbt_project
```

**Expected output (all green):**
```
profiles.yml file [OK found and valid]
dbt_project.yml file [OK found and valid]
git [OK found]
Connection test: [OK connection ok]
All checks passed!
```

**What this validates internally:**
- `dbt_project.yml` parsed ✅
- `profiles.yml` loaded ✅
- Target `dev` resolved ✅
- Postgres adapter initialized ✅
- Test query executed against `dbt_warehouse` ✅

#### Lab 4 — Permission & Schema Validation

Create a minimal test model:
```bash
echo "select 1 as connection_test" > dbt_project/dbt_project/models/test_connection.sql
```

Run dbt:
```bash
docker compose run --rm dbt run --project-dir dbt_project
```

**Expected output:**
```
1 of 1 START sql view model dev_schema.test_connection ... [RUN]
1 of 1 OK created sql view model dev_schema.test_connection ... [CREATE VIEW in 0.04s]
Completed successfully
PASS=1  WARN=0  ERROR=0  SKIP=0  TOTAL=1
```

Validate directly in Postgres:
```bash
docker exec -it dbt_postgres psql -U dbt_user -d dbt_warehouse
SELECT * FROM dev_schema.test_connection;
# Expected: 1 row with connection_test = 1
\q
```

**What this confirms:**
- DAG construction works ✅
- Schema auto-creation works ✅
- Write privileges exist ✅
- Materialization (`view`) applies correctly ✅
- Artifacts generated in `target/` ✅

Remove test model:
```bash
rm dbt_project/dbt_project/models/test_connection.sql
```

---

### Module 3 — Git Foundation for dbt

**Purpose:** Establish Git as the mandatory control layer. dbt without Git is not production-ready.

#### Lab 1 — Initialize Repository

```bash
git init
```

Create `.gitignore` at project root — see file in repo.

Stage and commit:
```bash
git add .
git status         # Verify: no target/, no logs/, no .user.yml
git commit -m "Initial production-ready dbt core environment setup"
```

**What this baseline commit represents:**
- Docker configuration ✅
- dbt project structure ✅
- Modeling directories ✅
- Infrastructure definitions ✅

#### Lab 2 — Simulated Branch Workflow

Every dbt model change = a branch + a commit. No direct edits to `main`.

```bash
# Create feature branch
git checkout -b feature/add-staging-layer

# Make model changes, then:
git add .
git commit -m "Add initial staging models"

# Merge back to main
git checkout main
git merge feature/add-staging-layer
```

---

## Running the Stack

**Start containers:**
```bash
docker compose up -d
```

**Run dbt models:**
```bash
docker compose run --rm dbt run --project-dir dbt_project
```

**Run dbt debug:**
```bash
docker compose run --rm dbt debug --project-dir dbt_project
```

**Stop containers:**
```bash
docker compose down
```

**Full reset (destroys volumes + data):**
```bash
docker compose down -v
```

---

## Key Design Principles

| Principle | Detail |
|---|---|
| Credentials never in models | Profiles handle connection, SQL handles logic |
| Artifacts never in Git | `target/`, `logs/`, `dbt_packages/` are always gitignored |
| Every change = a branch | No direct commits to `main` |
| Containers guarantee determinism | No host Python, no local Postgres installs |
| Environment belongs in profile | Never use `{% if target.name == 'prod' %}` in model SQL |

---

## What's Next (Phase 2 — Core Modeling Engine)

- **Module 4** — dbt Project Structure & Compilation Model
- **Module 5** — Dependency Graph & DAG Mechanics
- **Module 6** — Materializations & Incremental Strategy
- **Module 7** — Jinja & Macro System
- **Module 8** — Sources, Seeds & Snapshots