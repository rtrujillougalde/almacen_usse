# Almacén USSE (Rails)

Rails 8 port of the USSE warehouse app. Run from this directory:

```bash
bin/setup
bin/dev
```

## UI conventions (Bootstrap 5)

- Primary actions: `btn btn-primary`
- Secondary / cancel: `btn btn-outline-secondary`
- Tables: `table table-striped table-hover table-sm`
- Forms: `form-label`, `form-control`, `form-select`, `mb-3`
- Flashes: Bootstrap `alert` (see `shared/flashes`)
- Low stock (later): `table-warning` / `text-danger`
- Shared chrome: `shared/sidebar`, `shared/page_header`, `shared/coming_soon`

Tailwind was removed in favor of vendored Bootstrap 5.3 under `app/assets/stylesheets/bootstrap.min.css` and `vendor/javascript/bootstrap.bundle.min.js`.

## Auth (Stage 3)

- Devise login with **username** (no public registration).
- Roles: `admin`, `operador`, `consulta` (same page access as the Streamlit app).
- Seed users (`bin/rails db:seed`): `admin` / `operador` / `consulta` — password `password`.

## Domain schema (Stage 4)

Spanish table/column names match the legacy MySQL schema (`proveedores`, `articulos`, `proyectos`, `movimientos`, `stock_puntas`, `detalle_movimientos`) with custom primary keys (`id_proveedor`, etc.). Domain tables have no `created_at`/`updated_at`.

## Production (Railway)

Shared live MySQL (same database as Streamlit). Dashboard settings, env vars,
and the admin bootstrap command: [docs/deploy-railway.md](docs/deploy-railway.md).

Do not run `db:prepare` or `db:schema:load` against production. Boot uses
`shared_production:prepare`. Seed users (`password`) are for local development only.
