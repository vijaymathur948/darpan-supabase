# Darpan Supabase

Remote-only Supabase backend. Migrations live in git and are pushed directly to the hosted production project. Local Docker / `supabase start` is not used.

## Prerequisites

- [Supabase CLI](https://supabase.com/docs/guides/cli) (`supabase` ≥ 2.x)
- A hosted project in the [Supabase Dashboard](https://supabase.com/dashboard)

## One-time setup

```bash
# 1. Authenticate (opens browser, or use --token <ACCESS_TOKEN>)
supabase login

# 2. Link this repo to the hosted project
#    Project ref is in Dashboard → Project Settings → General
supabase link --project-ref <PROJECT_REF>

# 3. Push schema migrations to production
supabase db push
```

Copy production keys from **Dashboard → Project Settings → API** into `.env` (see `.env.example`).

## Day-to-day workflow

```bash
# Create a new migration
supabase migration new <name>

# Edit the SQL under supabase/migrations/, then push
supabase db push

# Preview without applying
supabase db push --dry-run
```

## Project layout

```
supabase/
  config.toml          # CLI / project metadata
  migrations/          # Source of truth — pushed with `supabase db push`
  seed.sql             # Not applied on push unless you pass --include-seed
```

Orders can have a custom dated schedule in `order_installments`, with received payments recorded against individual installments in `order_payments`. Payment records store the paid date and an optional local time, as well as the database record timestamp. The Orders page calculates paid, remaining, and scheduled balances from this history. Fully paid installments are locked against amount and due-date changes, while new installments can still be added. Once a receipt check is saved, the payable total is adjusted for priced missing or extra books and is used by payment and installment validation; the original order amount remains the expected amount. The invoice can store a manually selected expected date for the current pending payment. Receipt checks store actual received quantities on order items; checked quantities are used for inventory. Apply the migrations with the normal `supabase db push` workflow.

Auth (profiles, RLS on user data, Dashboard URL config) is deferred to a later step.

## Env vars for clients

| Variable | Where to find it |
| --- | --- |
| `SUPABASE_URL` | Project Settings → API → Project URL |
| `SUPABASE_ANON_KEY` | Project Settings → API → `anon` `public` |
| `SUPABASE_SERVICE_ROLE_KEY` | Project Settings → API → `service_role` (server only) |
