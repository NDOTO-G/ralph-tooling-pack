# Table of Contents

This section lists every file in the research pack with a short description.  Paths are relative to the `ralph-tooling-research-pack/` folder.

## 00_INDEX

* **00_TABLE_OF_CONTENTS.md** – this file.
* **01_EXEC_SUMMARY.md** – a high‑level overview of the pack and its key takeaways.
* **02_GLOSSARY.md** – definitions of key terms used throughout the research (e.g., Ralph loop, skill, MCP).
* **03_OPEN_QUESTIONS.md** – open issues or questions identified during the research.

## 10_RALPH_CORE

* **ralph_overview.md** – explains what a Ralph loop is, why it exists and how it changes agent orchestration.
* **ralph_primitives.md** – describes the fundamental data structures of a Ralph harness (PRD, progress log, prompt templates).
* **ralph_failure_modes.md** – catalogues common failure modes like context rot, compaction loss and runaway loops.
* **ralph_validation_backpressure.md** – discusses validation strategies, tests and back‑pressure mechanisms.
* **ralph_stop_conditions.md** – summarises recommended stop conditions and budgets for Ralph iterations.
* **ralph_reference_prompts.md** – collects sample prompts and sentinel patterns used across tools.

## 20_OPENCODE

* **00_opencode_overview.md** – overview of OpenCode, its architecture and why it suits Ralph loops.
* **01_tools_inventory.md** – inventory of built‑in tools (bash, read, edit, glob, skill, etc.) and key commands.
* **02_skills_how_they_work.md** – how OpenCode skills are defined, discovered and invoked.
* **03_hooks_how_they_work.md** – describes the plugin and event system for hooking into OpenCode’s lifecycle.
* **04_stop_conditions_and_budgets.md** – discusses `maxSteps`, token budgets and permission policies.
* **05_best_practices_playbook.md** – recommended patterns, pitfalls and guidelines for running OpenCode unattended.
* **06_example_workflows.md** – outlines example harness workflows using OpenCode.
* **07_sample_prompts/opencode_sample_prompt.md** – example prompt file for OpenCode.

## 30_CODEX

* **00_codex_overview.md** – introduction to Codex CLI, key features and limitations.
* **01_tools_inventory.md** – list of important commands and concepts (bash, run, exec, skills, etc.).
* **02_prompting_patterns.md** – prompting patterns for non‑interactive use, including JSON output and schemas.
* **03_validation_and_gates.md** – how to implement validation, approvals and gating around Codex.
* **04_stop_conditions_and_budgets.md** – outlines stop criteria, cost control, sandbox modes and approval policies.
* **05_best_practices_playbook.md** – guidelines for structuring tasks and using skills with Codex.
* **06_example_workflows.md** – sample harness workflows for Codex.
* **07_sample_prompts/codex_sample_prompt.md** – example prompt file for Codex.

## 40_CLAUDE_CODE

* **00_claude_code_overview.md** – explains headless Claude, capabilities and use‑cases.
* **01_tools_inventory.md** – outlines available tools and commands in Claude Code.
* **02_skills_how_they_work.md** – describes Claude skills, including subagents and dynamic context.
* **03_hooks_how_they_work.md** – explains hook events in Claude Code.
* **04_stop_conditions_and_budgets.md** – discusses stop criteria, thinking budgets and permissions.
* **05_best_practices_playbook.md** – best practices for working with Claude Code.
* **06_example_workflows.md** – example workflows for Claude in a Ralph harness.
* **07_sample_prompts/claude_sample_prompt.md** – example prompt file for Claude.

## 50_COMPARISONS

* **01_feature_matrix.md** – a comparative matrix of OpenCode, Codex and Claude across key dimensions.
* **02_equivalence_map.md** – maps equivalent concepts and commands across the three tools.
* **03_recommended_architectures.md** – recommends which tool to use for which stage of the harness.
* **04_security_sandboxing.md** – summarises security and sandboxing differences.

## 60_SCRIPTS_AND_TEMPLATES

* **prompts/open_code_prompt.md** – a reusable prompt template for OpenCode agents.
* **prompts/codex_prompt.md** – a reusable prompt template for Codex CLI.
* **prompts/claude_prompt.md** – a reusable prompt template for Claude Code.
* **scripts/harness_template.sh** – shell pseudocode illustrating how to orchestrate iterations, call the `run_agent` interface and log progress.
* **schemas/prd_template.json** – a template for the Product Requirements Document (PRD) used by the harness.
* **schemas/progress_template.md** – a template for entries in the `PROGRESS.md` log.
* **schemas/skill_template.md** – a template for defining a skill with YAML front‑matter.

## 70_SOURCES

* **sources.md** – lists external articles, documentation and other references used in the research.
