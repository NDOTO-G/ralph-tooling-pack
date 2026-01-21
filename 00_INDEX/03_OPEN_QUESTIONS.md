# Open Questions

During the research we identified several areas where additional investigation or experimentation could refine the Ralph harness.  These questions are intentionally left open for future work:

* **Optimal budgeting strategies** – What are the best heuristics for setting `maxSteps`, token budgets and iteration limits per project?  How do these choices vary by model, task complexity and codebase size?
* **Adaptive back‑pressure** – Can the harness automatically adjust task scope or model choice based on validation failures or cost metrics?  How should retry policies be tuned to maximise throughput without running away?
* **Dynamic skill injection** – In headless Claude runs, skills must be inlined.  Could a harness dynamically extract and inject skill content on demand, preserving modularity without enabling slash commands?
* **Multi‑tool coordination** – What is the optimal strategy for splitting work across OpenCode, Codex and Claude within a single project?  Are there patterns for handing off partially completed tasks between tools while maintaining context consistency?
* **Security hardening** – How can hooks be audited or sandboxed to prevent leakage of secrets when running external commands?  Are there best practices for running agents in untrusted repositories?
* **Incremental compilation of PRD** – How can the planning phase be shortened or automated while still producing reliable story breakdowns?  Can back‑pressure be applied to the planning step itself?

Contributions or insights addressing any of these questions are welcome.  They will help evolve the Ralph harness into a more robust and adaptive system.
