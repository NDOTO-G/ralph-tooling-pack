# Stop Conditions & Budgets – OpenCode

OpenCode offers configurable limits on agent behaviour that are particularly useful in a Ralph loop.  Combined with harness‑level controls, these settings prevent runaway iterations and manage cost.

## Agent step limits

OpenCode agents can be given a `maxSteps` property in their configuration.  This value caps how many tool calls the agent may perform in a single run【559550733105805†L491-L524】.  When the limit is reached, OpenCode sends a system prompt instructing the agent to summarise its progress and stop.  In a Ralph harness you should:

* Define multiple agent profiles with different `maxSteps` values (e.g., planning vs implementation).
* Choose a conservative default (e.g., 10–15 steps) and increase only for tasks that require more operations.
* Treat the summary produced at the limit as a special stop signal and log it accordingly.

## Output token caps and timeouts

Use environment variables to restrict resource consumption:

* `OPENCODE_EXPERIMENTAL_OUTPUT_TOKEN_MAX` – maximum number of tokens in model output.  Prevents verbose responses【674709478433772†L710-L717】.
* `OPENCODE_EXPERIMENTAL_BASH_MAX_OUTPUT_LENGTH` – maximum characters returned from bash commands【674709478433772†L710-L717】.
* `OPENCODE_EXPERIMENTAL_BASH_DEFAULT_TIMEOUT_MS` – default timeout for bash commands in milliseconds【674709478433772†L710-L717】.

Adjust these variables in your harness or CI environment to enforce global budgets.  Combine them with per‑iteration wall‑clock timeouts in your script.

## Permission policies

Define `permission` rules in `opencode.json` to control tool access.  Each tool can be set to `allow`, `ask` or `deny`.  Wildcards allow pattern matching (e.g., `bash(git *): allow`).  Special guards include:

* **doom_loop** – triggers when the same tool call repeats three times; defaults to `ask`【310356558666353†L193-L214】.
* **external_directory** – triggers when accessing files outside the project; defaults to `ask`【310356558666353†L193-L214】.

Set global defaults and override them per agent.  Deny or ask for high‑risk tools (`write`, destructive bash commands) and allow low‑risk tools (`read`, `grep`).  Use the `skill` permission to gate which skills the agent can load【474358579328195†L218-L247】.

## MCP server management

External MCP servers extend the agent’s capabilities (e.g., Puppeteer for browser automation).  However, they also increase context size and may introduce security risks.  In `opencode.json`:

* Define servers under the `mcp` key with a unique name, `type` set to `local` and a `command` array to start the server, or with `type` set to `remote` and a `url`【605040260244603†L195-L223】.
* Set `enabled: true` only for the servers you need; disable unused connectors to conserve tokens【605040260244603†L106-L115】.
* Use `opencode mcp auth` to authenticate servers that require OAuth【605040260244603†L403-L425】.

By combining agent step limits, output caps, permission policies and selective MCP usage, you can keep OpenCode sessions predictable and cost‑effective within a Ralph loop.
