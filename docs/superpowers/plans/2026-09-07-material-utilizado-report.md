# Material utilizado report Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers-ruby:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the Comparativo report with Material utilizado: `compras + salidas − entradas` per article, with a 5% tool depreciation rule.

**Architecture:** Keep the existing Reportes pipeline (Query → preview/controller → PDF/Excel). Rename `comparativo` to `utilizado` and change the aggregation formula. Load articles in one query.

**Tech Stack:** Rails 8, Active Record, Prawn, caxlsx, RSpec

---

### Task 1: Query formula

**Files:**
- Modify: `rails/spec/services/reportes/query_spec.rb`
- Modify: `rails/app/services/reportes/query.rb`

- [ ] Write failing specs for `utilizado_rows` (material formula, tool formula, raw entrada shown for tools)
- [ ] Implement `utilizado_rows` and remove `comparativo_rows`
- [ ] Run `env -u BUNDLE_PATH bundle exec rspec spec/services/reportes/query_spec.rb`

### Task 2: PDF and Excel

**Files:**
- Modify: `rails/spec/services/reportes/generators_spec.rb`
- Modify: `rails/app/services/reportes/pdf_generator.rb`
- Modify: `rails/app/services/reportes/excel_generator.rb`
- Modify: `rails/app/services/reportes/pdf_styles.rb`

- [ ] Rewrite generator specs for `.utilizado`
- [ ] Replace `.comparativo` with `.utilizado` (title, Compras column, Utilizado, Costo)
- [ ] Filename spec uses `utilizado`

### Task 3: Controller, views, request specs

**Files:**
- Modify: `rails/app/controllers/reportes_controller.rb`
- Modify: `rails/app/views/reportes/index.html.erb`
- Modify: `rails/app/views/reportes/_results_panel.html.erb`
- Modify: `rails/app/helpers/application_helper.rb`
- Modify: `rails/spec/requests/reportes_spec.rb`

- [ ] Rewrite request specs for `kind=utilizado`
- [ ] Swap allow-list, preview columns, labels, empty message
- [ ] Run full reportes specs
