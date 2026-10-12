---
name: error-taxonomy-can-enumerate
description: An endpoint that must not disclose whether a record exists has to equalize its error reasons too, not just its response bodies
metadata:
  type: feedback
---
Identical bodies on both branches are only half the fix.

**Why:** a reason code reachable only when the record exists leaks the record's existence just as plainly as a different body would, and so does a measurable latency difference.

**How to apply:** enumerate every terminal state of the flow, mark which ones require the record to exist, and give them one shared message. The shared handler lives in `src/jobs/auth.ts`. Related: [[timing-oracles]].
