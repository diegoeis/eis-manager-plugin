# Data root and global config

Every skill in this plugin starts here. Read this file before touching any state.

## Where state lives

State lives in a folder on the user's machine that the user names during `mgr-setup`. Call it `DATA_ROOT`. It holds `config.json` and `workspaces/`. Hosts differ in what they let a plugin read and write (Cowork, for example, only reaches the folder connected to the session; `${CLAUDE_PLUGIN_DATA}` and `~/.claude/` are not reachable there), so the plugin never assumes or probes a hidden location: the user says where.

Default offered by setup: `{{connected folder}}/manager-assistant/`, when a folder is connected to the session. Keeping state inside the connected folder means later sessions with the same folder find it without asking. The user may type any other absolute path.

Never write inside `${CLAUDE_PLUGIN_ROOT}`; it changes on every plugin update.

## Finding `DATA_ROOT` in any skill

Three steps only. There is no pointer file, no lookup in `~/.claude/`, no lookup in `${CLAUDE_PLUGIN_DATA}`, and no walking up parent directories.

1. **A path the user gave in the request**, as `--data-root {{path}}` or in prose. When present it wins: the folder must hold `config.json` with `"plugin": "eis-manager-assistant"`, else `BLOCKED` naming the path. This is how schedules and other agents run without a connected folder.
2. **Connected folder.** Otherwise, if a folder is connected to the session, look for `config.json` with that marker in it, in `manager-assistant/` inside it, or one level down. Use the folder that holds it.
3. **Ask, only when allowed.** `mgr-setup`, and any other skill running with `--interactive`, asks the user for the absolute path of the plugin's data folder, after explaining why, and uses it if `config.json` exists there. Every other skill in silent mode (the default, used by schedules and other agents) does not ask and stops:

```
STATUS: BLOCKED
No configuration found. Connect the folder that holds manager-assistant/, or pass --data-root {{path}}, or run /mgr-setup first.
```

A path given in `--interactive` that has no `config.json` ends the same way, naming the path. Only `mgr-setup` may continue from there.

## `config.json`

Path: `DATA_ROOT/config.json`. The only JSON file in the state; everything else is Markdown with YAML frontmatter.

```json
{
  "plugin": "eis-manager-assistant",
  "version": 1,
  "dataRoot": "/absolute/path/of/this/folder",
  "activeWorkspace": "workspace-slug",
  "workspaces": {
    "workspace-slug": {
      "name": "Workspace Display Name",
      "path": "workspaces/workspace-slug",
      "referenceFolders": ["/absolute/path/the/user/works/in"],
      "createdAt": "YYYY-MM-DD",
      "tools": {
        "tracker": { "tool": "jira", "url": "https://acme.atlassian.net" },
        "messenger": { "tool": "slack", "url": "https://acme.slack.com" }
      },
      "sources": {}
    }
  }
}
```

- `activeWorkspace` is the slug used when the user does not name one. Switching workspaces is out of scope for now.
- `referenceFolders` are the folders the user pointed to for inference (connected folder, vault, project folders). Setup scans them for names; other skills use them as the default places to look for local notes. Empty list when none.
- `tools` holds only what setup asked for: the tracker and the messenger. The `tool` value is inferred from the URL domain (see below).
- `sources` is filled lazily and grows on its own. Whenever the user mentions a path or URL that other skills will need again (an Obsidian vault, a Drive folder, a meetings folder, a docs URL), or a skill discovers one while working (the folder where a team's transcripts actually live, a channel that belongs to a topic), it is recorded here under a short key, for example `"obsidianVault": "/Users/.../Vault"` or `"transcripts": "/Users/.../Meetings"`, without asking. Topic-specific finds go to the topic's `## Fontes` instead. A skill that needs a source it cannot find works with what exists and says what was missing; it asks only in `--interactive`.
- No language field. Every skill answers in the language the user is writing in.
- Never store credentials, tokens or personal data beyond names and roles.

## Inferring the tool from a URL

| Domain contains | `tool` |
| --- | --- |
| `atlassian.net`, `jira` | `jira` |
| `linear.app` | `linear` |
| `trello.com` | `trello` |
| `asana.com` | `asana` |
| `clickup.com` | `clickup` |
| `notion.so`, `notion.site` | `notion` |
| `github.com` (projects) | `github` |
| `azure.com`, `visualstudio.com` | `azure-devops` |
| `slack.com` | `slack` |
| `teams.microsoft.com` | `teams` |
| `discord.com`, `discord.gg` | `discord` |
| `chat.google.com` | `google-chat` |

Unknown domain: store `tool: "other"` and keep the URL. Never guess beyond the domain.
