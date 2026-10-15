# REHLA — release status (2026-10-15)

## What is in this package
- Arabic RTL customer storefront/PWA UI.
- Supabase Auth hooks and catalog loading.
- Remote order creation through a server-side Edge Function that recalculates item prices.
- Database schema and migrations for roles/RLS, status transitions, courier assignment, merchant review, and audit timestamps.
- Admin dashboard wiring for shared shop/product/order/courier/application data when Supabase is configured.
- Edge Functions: `create-order`, `update-order-status`, `assign-courier`, `create-courier`.
- GitHub Actions workflow to deploy Supabase migrations and Edge Functions after repository secrets are configured.
- Static smoke checks.

## Verified locally
- `app.js` passes `node --check`.
- `tests/smoke_test.py` validates expected files and key security/integration hooks.
- ZIP archive integrity checked after packaging.

## Not yet verified / not complete until user-owned services are configured
- No Supabase project has been created or linked from this environment.
- No real database migrations or Edge Functions have been deployed.
- No live URL exists yet; frontend hosting is not connected to a repository.
- End-to-end tests against real accounts and RLS policies have not run.
- Email invitation delivery, realtime updates, image uploads, and production monitoring need configuration and testing.

**Do not accept real customer orders until deployment and end-to-end checks pass.** The package is deployment-ready code, not a claim of a live production system.
