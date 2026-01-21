## YYYY‑MM‑DD HH:MM UTC – Iteration N (Tool)

**Prompt:** prompts/iteration_N.md (sha256=<PROMPT_HASH>)

**Agent:** <tool> (<agent/model>), allowed tools: [Read,Edit,Bash]

**Result:** COMPLETE|FAILED|ESCALATED

**Summary:** Short description of what happened in this iteration.  Mention key files changed and any notable decisions or failures.

**Evidence:**

* events: artifacts/iteration_N_events.jsonl
* diff: artifacts/iteration_N_diff.patch
* tests: artifacts/iteration_N_test_output.txt
* commit: <commit_hash>

---

Replace placeholder values (`N`, `<tool>`, `<agent/model>`, `<PROMPT_HASH>`, `<commit_hash>`) with actual values when logging.  Each iteration should append a new entry below the previous one to maintain an audit trail.