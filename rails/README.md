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
