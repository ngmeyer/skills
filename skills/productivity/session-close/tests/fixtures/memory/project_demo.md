---
name: Demo project state
description: Fixture for session-close eval — a plausible starting memory file.
type: project
---

# Demo

**Stack:** Next.js 16, Postgres, Vercel
**Status 2026-04-20:** in flight — building the auth flow

## Status

Mid-task on `/api/auth/register`. Next step: add validation.

## Backlog

- Write integration tests for auth
- Document .env.example
- Set up Stripe webhooks

## Architecture

REST API at `/api/*`, server components for pages, session cookies for auth.
