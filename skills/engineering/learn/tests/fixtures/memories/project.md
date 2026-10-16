# project memory (fixture)
- Scheduled job routes must call the shared auth helper in `src/jobs/auth.ts` because a bare header check rejects the scheduler.
- The legacy importer lives in `scripts/legacy-import.sh` and must run before seeding.
- Run npm run verify before every push because CI does not run end-to-end tests.
- I prefer tabs and my editor is set to wrap at 100 columns.
