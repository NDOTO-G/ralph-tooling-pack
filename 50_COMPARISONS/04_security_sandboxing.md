# Security and Sandboxing

Running agentic coding tools on arbitrary repositories involves executing code, reading files and potentially invoking network operations.  This document summarises the security posture of each engine and offers recommendations to minimise risk when integrating them into a Ralph harness.

## Threat model

1. **Malicious repository contents** – The target repo may contain scripts, configuration files or dependencies that attempt to exfiltrate secrets or exploit the host environment.
2. **Agent hallucinations** – An LLM may incorrectly run destructive commands if prompts or permissions are misconfigured.
3. **Hook misuse** – Plugins or hooks run user‑defined scripts with your credentials, which could leak secrets or modify system state if not audited.

## OpenCode

* **Sandboxing:** Uses a local environment.  Plugins and tools execute commands directly on your machine; there is no built‑in FS sandbox.  Mitigate by running OpenCode in a container or virtual machine.
* **Permission policies:** The `permission` section in `opencode.json` allows `allow`, `ask` or `deny` decisions per tool and file pattern【474358579328195†L218-L247】.  Set strict defaults (deny risky tools like `bash rm*`) and use `ask` for operations that modify files.
* **Doom loop protection:** Guards prevent repeated calls to the same command and restrict access to external directories【310356558666353†L193-L214】.  Keep these enabled.
* **Plugins:** Hooks can modify or intercept commands【543225958782144†L170-L336】.  Audit plugin code, keep it short and deterministic, and avoid loading untrusted npm packages.  Use a version control commit hook to require review of plugin changes.
* **MCP servers:** External connectors run additional processes; ensure they are isolated and do not have network access beyond what is needed【605040260244603†L195-L223】.

## Codex CLI

* **Sandboxing:** Offers three levels via `--sandbox`: `read-only`, `workspace-write` and `danger-full-access`【413965132490193†L772-L801】.  Always start with `read-only` and only elevate to `workspace-write` when necessary.  Never use `danger-full-access` outside of disposable environments.
* **Approval rules:** Use `--ask-for-approval` to require confirmation before executing commands; values include `untrusted`, `on-failure`, `on-request` and `never`【413965132490193†L220-L287】.  Create `.rules` files to forbid or prompt for specific commands【40854120253895†L214-L280】.
* **No plugin support:** Because there is no hook system, all instrumentation must happen in the harness.  Wrap `codex exec` in a script that filters dangerous commands and monitors outputs.

## Claude Code

* **Sandboxing:** There is no built‑in FS sandbox.  When running headlessly, combine `--allowedTools` to restrict tool calls (e.g., limit to `Read,Edit,Bash`)【649120918286103†L161-L173】.  Always run in an isolated container or throwaway environment.
* **Permission prompts:** If you do not specify `--allowedTools`, Claude will prompt for each tool call interactively.  Do not use `--dangerously-skip-permissions` outside of controlled test rigs【135116144821332†L299-L309】.
* **Hooks:** Hook scripts can run arbitrary commands and will inherit your environment【995113787448290†L90-L94】.  Store hooks under version control, review them regularly and avoid complex logic.  Consider disabling hooks when running on untrusted code.
* **Skills:** Because skills can include `!` prefixed shell commands【500585924894070†L498-L531】, audit each skill’s content.  In headless mode skills must be inlined manually, giving you the opportunity to vet them.

## General recommendations

1. **Run in containers.** Use Docker or similar to provide a clean environment for each run.  Mount the repository as a volume with the minimal privileges required.
2. **Restrict network access.** Only allow network access when strictly necessary (e.g., fetching dependencies).  Otherwise disable network interfaces inside the container.
3. **Redact secrets.** Remove API keys, tokens and secrets from repositories before running agents.  Use environment filtering (e.g., `[shell_environment_policy]` in Codex config) to avoid leaking environment variables【454175575763456†L405-L423】.
4. **Audit logs.** Store JSON event streams, diffs and hook outputs for later review.  Look for unexpected commands or network calls.
5. **Review user‑supplied inputs.** Validate PRDs, prompt files and progress logs to ensure they do not contain malicious code or prompt injections.
6. **Keep dependencies up‑to‑date.** Monitor vendor patches and upgrade your agent runtimes and models regularly to benefit from security fixes.

By combining strict permission policies, containerisation and careful auditing, a Ralph harness can safely orchestrate powerful agentic tools on untrusted codebases.