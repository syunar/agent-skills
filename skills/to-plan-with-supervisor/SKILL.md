---
name: to-plan-with-supervisor
description: Ask the supervisor model to turn one public GitHub ticket into a local executable implementation plan.
disable-model-invocation: true
---

# To Plan With Supervisor

Delegate `/to-plan` to the supervisor model, then save its Markdown response as the local implementation plan.

## 1. Validate the ticket

Treat the invocation argument as one public GitHub issue URL. If it is missing or is not an `https://github.com/<owner>/<repo>/issues/<number>` URL, ask for that URL.

The supervisor resolves `@github` and `@to-plan.md`, then fetches the ticket and its parent spec. Do not duplicate their contents in the prompt.

Completion criterion: one public GitHub issue URL is available.

### Supervisor configuration

The helper reads the merged OpenCode configuration through:

```bash
opencode debug config
```

The supervisor configuration must be nested under `provider.supervisor.options` because OpenCode's config validator rejects unknown top-level keys:

```jsonc
{
  "$schema": "https://opencode.ai/config.json",
  "provider": {
    "supervisor": {
      "options": {
        "baseUrl": "http://127.0.0.1:8000",
        "apiKey": "<required-api-key>",
        "model": "gpt-5-6-thinking-extended"
      }
    }
  }
}
```

Place this in the global file at `~/.config/opencode/opencode.json`, or in a project-root `opencode.jsonc` to override it per-project. `baseUrl`, `apiKey`, and `model` are required. `baseUrl` is the server root; the helper appends `/v1/chat/completions`. No endpoint, credential, or model default is stored in this repository.

When the `opencode` command is unavailable, the helper falls back to the JSON file at `$XDG_CONFIG_HOME/opencode/opencode.json` or `~/.config/opencode/opencode.json`. That fallback requires strict JSON rather than JSONC.

## 2. Request and save the plan

Run the bundled helper from the repository root:

```bash
bash skills/to-plan-with-supervisor/scripts/request-plan.sh '<ticket-url>'
```

The helper:

1. Resolves the ticket title and derives `.scratch/<ticket-slug>/plans/<ticket-number>-<ticket-slug>.md`, adding a numeric run suffix when needed to preserve existing plans.
2. Prints the start time, API URL, masked API key, model, destination path, input prompt, and request time.
3. Reads the shared supervisor URL, API key, and model from merged OpenCode configuration, then sends `@github`, `@to-plan.md`, the ticket URL, repository URL, and exact destination path to that configured supervisor.
4. Waits up to 30 minutes for a non-streaming response.
5. Extracts the implementation-plan Markdown from the response.
6. Atomically writes the plan without overwriting an existing file.

If the API request or response extraction fails, report its error and leave the filesystem unchanged. Do not replace the supervisor response with a locally authored plan.

Completion criterion: the helper prints a saved plan path and an `/implement <plan-path>` handoff.

## 3. Report the handoff

Report only the saved plan path and the `/implement <plan-path>` command printed by the helper.
