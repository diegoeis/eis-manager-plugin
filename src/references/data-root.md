# Data root and global config

Every skill in this plugin starts here. Read this file before touching any state.

## Where state lives

State lives in a folder on the user's machine that the user names during `mgr-setup`. Call it `DATA_ROOT`. It holds `config.json` and `workspaces/`. Hosts differ in what they let a plugin read and write (Cowork, for example, only reaches the folder connected to the session; `${CLAUDE_PLUGIN_DATA}` and `~/.claude/` are not reachable there), so the plugin never assumes or probes a hidden location: the user says where.

Default offered by setup: `{{connected folder}}/manager-assistant/`, when a folder is connected to the session. Keeping state inside the connected folder means later sessions with the same folder find it without asking. The user may type any other absolute path.

Never write inside the plugin's own folder; it changes on every plugin update.

## Finding `DATA_ROOT` in any skill

Four steps only. There is no pointer file in the state, no lookup in `~/.claude/` or `${CLAUDE_PLUGIN_DATA}`, and nothing above the user's home folder.

1. **A path the user gave in the request**, as `--data-root {{path}}` or in prose. When present it wins: the folder must hold `config.json` with `"plugin": "eis-manager-assistant"`, else `BLOCKED` naming the path. This is how schedules and other agents run without a connected folder.
2. **Connected folder.** Otherwise, if a folder is connected to the session, look for `config.json` with that marker in it, in `manager-assistant/` inside it, or one level down. Use the folder that holds it. On hosts without folder connection, the session's working directory counts as the connected folder. Not there: check the folders above it, one at a time, up to the user's home folder, looking only for `config.json` and `manager-assistant/config.json` in each (a session opened inside a subfolder of the vault still finds state kept at the vault root). Stop at the first folder the host cannot read (Cowork reaches only the connected folder) and treat it as not found.
3. **A path the host remembers.** Otherwise, a path the host keeps for this user across sessions (an entry in the host's persistent memory, a line in the user's instructions file, or the `EIS_MANAGER_ASSISTANT_DATA_ROOT` environment variable). Same check as step 1. `mgr-setup` offers to save it there when the data root is outside the connected folder; hosts without such memory (Cowork) skip this step.
4. **Ask, only when allowed.** `mgr-setup`, and any other skill running with `--interactive`, asks the user for the absolute path of the plugin's data folder, after explaining why, and uses it if `config.json` exists there. Every other skill in silent mode (the default, used by schedules and other agents) does not ask and stops:

```
STATUS: BLOCKED
No configuration found. Connect the folder that holds manager-assistant/, pass --data-root {{path}}, save that path in the host's memory, or run /mgr-setup first.
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
      }
    }
  }
}
```

- `activeWorkspace` is the slug used when the user does not name one. Switching workspaces is out of scope for now.
- `referenceFolders` is the one list of local folders and files of the workspace: the ones the user pointed to in setup (connected folder, vault, project folders) and any folder or file the user names later (in `--source` or in a request), such as an Obsidian vault or a transcripts folder. Absolute paths, no duplicates. Setup scans them for names; `mgr-status-report` uses them as the general places to look for local notes and transcripts, after the `## Arquivos e assets` of the subject and its topics. Channels, meetings, boards and files of one subject or topic never go here: they live in the `## Fontes relacionadas` and `## Arquivos e assets` of that note, which is what ties the evidence to it. No skill adds entries on its own. Empty list when none.
- `tools` holds only what setup asked for: the tracker and the messenger. The `tool` value is inferred from the URL domain (see below).
- Older configs may still carry a `sources` object (`"obsidianVault": "/path"`). Every skill that reads `referenceFolders` also reads the paths in `sources` as part of it; `mgr-setup` moves them into `referenceFolders` and deletes `sources` the next time it writes `config.json`.
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
