# Deploy Rails on Railway (shared live MySQL)

The Rails app deploys from this `rails/` directory and uses the **same Railway
MySQL that Streamlit already uses**. It is not a copy.

Do not run `bin/rails db:prepare` or `db:schema:load` against that database.
Those commands can try to recreate `articulos` and the other inventory tables.
Boot uses `bin/rails shared_production:prepare` instead (see
`bin/docker-entrypoint`).

A first Railway deploy was attempted and failed. Diagnose that from Railway
logs before retrying (Revision 2 of the deploy plan). Until then, stop the
Rails service so it does not keep retrying against production MySQL.

## Dashboard settings (required)

Create the Rails service in the **same Railway project** as Streamlit + MySQL.

| Setting | Value |
| --- | --- |
| Source | GitHub repo `rtrujillougalde/almacen_usse`, branch `main-ruby-rails` |
| Root Directory | `rails` |
| Builder | Dockerfile (`rails/Dockerfile`) |
| Start command | leave empty (use image CMD: `./bin/thrust ./bin/rails server`) |
| Health check path | `/up` |
| Target port | `80` |
| MySQL | attach the **existing** plugin; do not create a second MySQL |

[`railway.toml`](../railway.toml) repeats builder + health check for services
that still read Config as Code. New Railway projects may ignore that file —
set the table above in the dashboard either way.

## Variables (Rails service only)

Add these under the Rails service **Variables**. Do not commit them.

| Name | Value |
| --- | --- |
| `RAILS_ENV` | `production` |
| `RAILS_MASTER_KEY` | contents of `rails/config/master.key` on your laptop |
| `DATABASE_URL` | existing MySQL URL, scheme **`mysql2://`**, **including the database name**: `mysql2://user:pass@host:3306/the_db`. A URL without `/the_db` causes `No database selected`. If Railway omits the path, also set `MYSQLDATABASE` to that same name. |
| `SOLID_QUEUE_IN_PUMA` | `true` |
| `APP_HOST` | public hostname only, e.g. `your-service.up.railway.app` (no `https://`) |

Do not set `CACHE_DATABASE_URL`, `QUEUE_DATABASE_URL`, or `CABLE_DATABASE_URL`
unless you have a reason. Railway MySQL is one database (`railway`). Cache,
queue, and cable tables are created in that same database.

Copy `DATABASE_URL` from the existing MySQL service. That is how Rails and
Streamlit share one database.

## First-boot checklist

1. Backup the live MySQL (Railway dump or `mysqldump`) before any retry.
2. Deploy. Boot should add `users` + `schema_migrations` if missing, create the
   sibling Solid databases, and leave inventory tables untouched.
3. Create the first admin with a **strong** password via a Railway one-off /
   shell. Do not run `db:seed` in production.

```bash
BOOTSTRAP_ADMIN_PASSWORD='choose-a-strong-password' \
  bin/rails runner 'User.create!(username: "admin", email: "admin@usse.local", role: :admin, password: ENV.fetch("BOOTSTRAP_ADMIN_PASSWORD"))'
```

Remove `BOOTSTRAP_ADMIN_PASSWORD` after the command succeeds.

4. Open `https://<APP_HOST>/up`, then sign in and compare inventario with Streamlit.

## After it is live

- Streamlit and Rails both write the same rows until you stop Streamlit.
- Local `bin/rails db:migrate` does not change Railway.
- Future schema changes must be additive. Never drop or recreate inventory tables.
- Streamlit `secrets.toml` users are not Devise users. Create Rails users explicitly.
