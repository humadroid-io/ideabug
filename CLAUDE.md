# ideabug

Self-hosted, embeddable widget for in-app announcements + bug/feature feedback. Host app embeds `script.js`, authenticates contacts via JWT (RS256), polls API for announcements. WIP.

## Stack
- Rails 8 (Ruby 3.4.8) + Postgres + Redis
- Hotwire (Turbo + Stimulus, importmap-rails), Tailwind + DaisyUI, ActionText/Trix
- Auth: cookie sessions for admin (Rails 8 generated `Authentication` concern), RS256 JWT for embed API
- Serializers: Blueprinter (`app/blueprints/`)
- Tests: Minitest + shoulda + capybara/selenium + factory_bot. **No RSpec** despite stray `.rspec` file.
- Lint: Standard via rubocop (`.rubocop.yml`), TargetRubyVersion 3.3, line length 100
- Dev env: dip + Docker (`dip.yml`, `.dockerdev/`); plain `bin/dev` (Procfile.dev → puma:3001 + tailwind watch) also works

## Domain (see `db/schema.rb`)
- `User` + `Session` — admin login (email/password, bcrypt)
- `Contact` — end-user of host app, keyed by `external_id` (from JWT `id`); has `info_payload`, `segments_payload` jsonb
- `Segment` / `SegmentValue` — targeting taxonomy; HABTM with Contact and Announcement
- `Announcement` — `has_rich_text :content`, HABTM `segment_values`; `AnnouncementRead` join tracks per-contact read state
- `Ticket` — bug/feature/task; enums `status` (new/in_progress/completed) + `classification` (unclassified/bug/feature_request/task)

## Routes
- Admin (cookie auth): `/dashboard`, `announcements`, `segments`, `segment_values`, `tickets`, `contacts` (index/show/destroy), `session`, `passwords/:token`
- Public: `GET /` (welcome#home → redirects), `GET /script.js` (embed loader, CSRF-exempt, layout false)
- API (JWT): `/api/v1/announcements` (index/show), `POST /api/v1/announcements/:id/read`

## Auth flow
- `ApplicationController` includes `Authentication` (Rails 8 generated). Use `allow_unauthenticated_access only: %i[...]` to opt out.
- API controllers inherit `Api::V1::BaseController`: skips session auth, runs `authenticate_jwt_token`, finds-or-creates `Contact` by JWT `id`, syncs `info`/`segments`, sets `Current.contact`.
- JWT verified in `JwtCredentialService` using keys from `config/jwt/{private,public}.pem` (or `JWT_{PRIVATE,PUBLIC}_KEY[_FILE]` env). Generate per README. Host app signs with private key; this app verifies with public.
- Feature flag `ANNOUNCEMENTS_PUBLICLY_ACCESSIBLE` → `Rails.config.x.announcements_publicly_accessible` (helper method on AC).

## Conventions
- Models follow ordered comment skeleton: `## SCOPES / CONCERNS / CONSTANTS / ATTRIBUTES & RELATED / ASSOCIATIONS / VALIDATIONS / CALLBACKS / OTHER`. Preserve when editing.
- Schema annotations via custom `annotate` fork (`mlitwiniuk/annotate_models`) — leave the `# == Schema Information` block intact; regenerated automatically.
- `Current` (ActiveSupport::CurrentAttributes) holds `session` (admin) and `contact` (API).
- Stray `.null-ls_*.tmp` files in `app/views/layouts/` are editor crashes — safe to ignore/delete, do not commit.

## Common commands
- `bin/dev` — start puma + tailwind watch
- `bin/rails test` (or via dip: `dip test`) — full Minitest suite
- `bin/rails test test/models/foo_test.rb` — single file
- `bundle exec rubocop` — lint (Standard preset)
- `bin/rails db:prepare` — create + migrate + seed
- `dip provision` — bootstrap docker stack

## Gotchas
- `Announcement#read` reads from `attributes["read"]` first (set via SQL select in index queries) — preserve when refactoring.
- `Contact#update_segments_from_payload` short-circuits if normalized payload unchanged; only creates new `SegmentValue`s if `segment.allow_new_values?`.
- Embed JS at `app/views/welcome/script.js.erb` is plain JS, not ESM/Stimulus — served at `/script.js`.
- Two JWT concerns exist: `Api::V1::BaseController` does the real work; `JwtAuthenticatable` concern is currently unused (uses `params.require(:token)` not header).
- README JWT example uses `user.id` and an `info` payload; the app actually expects `id` to be the contact's `external_id` (string identifier from host app).
