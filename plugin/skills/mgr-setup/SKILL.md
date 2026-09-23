---
name: mgr-setup
description: Set up or extend the manager-assistant workspace. Use when the user says "configura o plugin", "setup do manager assistant", "cria um workspace", "adiciona um time", "cadastra um fórum", "quero acompanhar a pessoa X", "cadastra um tópico", or runs /mgr-setup. Modes via argument - none or "--workspace" creates a workspace and chains into team and topic setup; "--team" adds a team and its people; "--forum" adds a forum (recurring decision meeting followed like a team); "--person" starts following a direct report individually; "--topic" adds a topic that can relate to one or several teams, forums or people, not owned by a single one; "--source" plus a sentence registers a channel, meeting or folder in the Fontes section of a subject or topic note, e.g. "--source adicione a reunião Sync - Squad X, do Granola e do vault /path". Interactive but frugal - asks only what cannot be inferred from the scanned folders. Never reads trackers or messengers, only records URLs. Do not use to generate reports.
allowed-tools: Read Write Edit Glob Grep Agent Bash(mkdir *) Bash(ls *) Bash(test *) Bash(echo *) Bash(mv *)
---

# mgr-setup

Creates the state every other `mgr-*` skill depends on: a data folder chosen by the user, its `config.json`, a workspace folder with its narrative, and the `Team`, `Forum`, `Person` and `Topic` notes that describe who does what. Teams, forums and tracked people are the **subjects** the report skill works on; they share `## Topics`, `## Fontes relacionadas` and `## Arquivos e assets`.

## Step 0 — Find existing state (before reading anything else)

Do this first, with no other reads. If a folder is connected to the session, look for `config.json` containing `"plugin": "eis-manager-assistant"` in it, in `manager-assistant/` inside it, or one level down. That is the whole search: no pointer file, nothing under `~/.claude/` or `${CLAUDE_PLUGIN_DATA}`. If you can't find the "eis-manager-assistant", make up parent directories pwd.

Found `config.json`: `DATA_ROOT` is its folder; say so in one line and skip Round 1. Not found, or no folder connected: go to Round 1.

**Migrate a workspace from 0.2.x.** Notes now live in one folder per type inside the workspace (`teams/`, `forums/`, `people/`, `topics/`, `reports/<YYYY-MM>/`) and, except reports, their file names carry no type prefix (table in `data-model.md`). If the active workspace still has prefixed notes at its root (`Team - X.md`, `Forum - X.md`, `Person - X.md`, `Topic - X.md`, `Report - ....md`), in any mode, migrate before doing anything else:

1. Move each note with `mv`, creating folders as needed: `Team - X.md` → `teams/X.md`, `Forum - X.md` → `forums/X.md`, `Person - X.md` → `people/X.md`, `Topic - X.md` → `topics/X.md`, `Topic - archived - X.md` → `topics/archived - X.md`. A report keeps its name and goes to `reports/<YYYY-MM>/`, the month of its `generated` frontmatter field (the date in its file name when `generated` is missing). If two notes would end with the same name, move neither, and list the clash in the summary for the user to rename.
2. Invoke the `eis-manager-assistant:link-keeper` agent with `operation: migrate` and `ws: <WS absolute path>`. It rewrites the wikilinks and the markdown links to people in every note. Do not edit notes yourself for this.

List the moves and the agent output in the summary.

## References

Read only when the step needs them, not upfront:

- `${CLAUDE_PLUGIN_ROOT}/references/data-root.md` — before writing `config.json` (schema, tool inference from URLs).
- `${CLAUDE_PLUGIN_ROOT}/references/data-model.md` — before creating the first note (frontmatter, body sections, wikilinks).

Templates: `${CLAUDE_PLUGIN_ROOT}/skills/mgr-setup/templates/` (this skill's own folder: `AGENTS.md`, `CLAUDE.md`, `Team.md`, `Forum.md`, `Person.md`). Topics are owned by the `mgr-topic` skill; this skill never writes `topics/*.md` directly — it delegates to `/mgr-topic --add`. Read each template right before creating that kind of note. **The template is the schema**: every note is created from its template, every `{{placeholder}}` is replaced with a real value from the current conversation, example rows that were not filled are removed, and no placeholder ever survives. Never add fields that are not in the template. Never omit fields that are in the template unless the template explicitly marks them optional (a comment starting with `# Optional`). If the user did not provide a value for a required field, use `TBD` and list it in the summary — never invent a value.

## Principles

- Answer in the language the user is writing in. Never ask which language to use.
- Ask only what you cannot infer. Before each question, check the data folder and the notes already created in this run.
- Every question, picker or form is preceded by one or two sentences saying why it is being asked and what will be done with the answer. A bare folder picker or a form with no context is a defect. On hosts that collapse text between tool calls (Cowork), that context must be sent with the user-message tool, not as plain text.
- File names are the note's name with no type prefix, and the H1 is the same name. Names are unique across `teams/`, `forums/`, `people/` and `topics/` (wikilinks carry no folder): before creating a team, forum or person, check the name is free; if another note already has it (a topic called like the team, two people with the same name), ask for a distinct name. An existing person reused as a PM, member or facilitator is the same note, not a clash.
- Rounds are small. Round 1 is one question. Later rounds group at most five related fields. Use the question tool when available; otherwise ask in plain chat. Offer inferred values as defaults the user confirms with one word.
- Collection is cheap: file and folder names plus frontmatter of Markdown files. No deep crawling, no following links, no calls to trackers, messengers, meeting tools or the web.
- Never invent a value. A field the user skips stays as an explicit `TBD` and is listed in the final summary.
- When the user mentions a path or URL of a source (an Obsidian vault, a Drive folder, a docs site), record it in `config.json` under `workspaces.<slug>.sources` right away, without asking.
- Never store credentials, tokens or personal data beyond names and roles.

## Mode resolution

Parse `$ARGUMENTS`:

| Argument | Mode |
| --- | --- |
| none, `--workspace` | **workspace**: find or create the data folder, create a workspace, then chain to team, then topic |
| `--team` | **team**: add a team to the active workspace, then offer topics |
| `--forum` | **forum**: add a forum (recurring decision or alignment meeting) as a subject, then offer topics |
| `--person` | **person**: start following an existing person individually (`tracked: true`), then offer topics |
| `--topic` | **topic**: add a topic related to one or several teams, forums or tracked people |
| `--source <prose>` | **source**: register a channel, meeting or folder in `## Fontes relacionadas` / `## Arquivos e assets` of a subject or topic note |

`--team`, `--forum`, `--person`, `--topic` and `--source` require Step 0 to have found `config.json` with an active workspace. If it did not, ask once for the data folder path; if there is still no `config.json`, print `STATUS: BLOCKED` with the reason and tell the user to run `/mgr-setup` without arguments.

## Round 1 — Folders (workspace mode)

Reached only when Step 0 found nothing. Two questions, in this order, always preceded by context. Never open a folder picker or ask for a path without first saying what it is for.

**1a. A folder is connected to the session.** Do not ask where to look; it is the reference folder. Go to 1b.

**1b. No folder connected.** First send a short message in the user's language explaining the situation. Reference wording (adapt, do not translate literally when the user writes in another language):

> Para começar, preciso fazer o setup do plugin. Me indique uma pasta que eu possa ler para entender os contextos que você quer gerenciar (times, projetos, pessoas). Eu leio só nomes de arquivos e frontmatter, nada é alterado nela.

How to deliver that message matters. On hosts where text written between tool calls is not shown verbatim (Cowork collapses it into a summary), send it through the host's user-message tool (`send_user_message` or equivalent; load it first if tools are deferred) and only then open the folder picker. Writing the explanation as plain text and then calling the picker produces exactly the defect this rule prevents: a bare picker. On hosts without such a tool, plain text before the picker is fine.

Then obtain the folder: if the host offers a folder-picker tool (Cowork's connect-a-folder request), use it right after the message; otherwise ask for the absolute path in chat. The user may decline; then there is nothing to scan and 1c still applies.

**1c. Where to write.** Ask, with the two choices as options:

> Posso criar a minha pasta de trabalho dentro dela (`<pasta>/manager-assistant/`), ou você prefere indicar outro lugar para guardar o workspace de gestão?
>
> Opções: **Mesma pasta** (recomendado: sessões futuras com essa pasta conectada encontram tudo sozinhas) | **Vou indicar outra**

If the user picks the second option, ask for the absolute path. Warn in one line that on hosts which only write inside connected folders (Cowork), a path outside the connected folder will fail and the setup will stop.

When no folder was connected at all (user declined 1b) there is no default; ask for the path directly, with the same warning.

Then:

- Read `data-root.md`. Create `DATA_ROOT` and `DATA_ROOT/workspaces/`. Write `config.json` (schema in `data-root.md`) with `workspaces: {}` for now. If the write fails, stop with `STATUS: BLOCKED`, say which path failed, and ask the user to connect that folder to the session or choose a path inside the connected folder. Do not try other locations on your own.
- Scan the reference folders: list `*.md` names and read the first 40 lines of each for frontmatter. Skip `DATA_ROOT` itself. Collect candidate team, person and project names. Cap at roughly 200 files in total; if more, sample top-level folders and say so.

## Round 2 — The workspace

Ask in one round:

- Workspace display name (company or front). Default: derived from the folder name. Show the kebab-case slug.
- One-paragraph description of the company or front (feeds `description` and `## Sobre`). Offer a draft if the scan found a README or an index note.
- URL of the main board in the task tracker.
- URL of the company messenger.

Infer `tools.tracker.tool` and `tools.messenger.tool` from the URL domains per `data-root.md`. Keep the full URLs.

Create `DATA_ROOT/workspaces/<slug>/` with its type folders `teams/`, `forums/`, `people/`, `topics/` and `reports/`, then `AGENTS.md` and `CLAUDE.md` at the workspace root from the templates. Fill `## Sobre` and `## Ferramentas` (two rows: tracker and messenger, with inferred tool and URL). Leave `## Acompanhamentos` with a header only; rows are added as teams, forums and tracked people are created. Fill `## O que importa acompanhar` and `## Convenções e armadilhas` only if the user volunteered content; otherwise leave one line saying the section is empty and can be edited by hand.

Register the workspace in `config.json` (`workspaces.<slug>` with `referenceFolders`, `tools`, `activeWorkspace`).

Then run **team** mode. Do not stop here.

## Chain

After the first team, ask whether to add another team (default no). After teams, ask whether to add topics now (default yes) and run **topic** mode for each. End with the summary.

## Mode: team

Show inferred team candidates from the scan, if any. Ask in one round:

- Team name (Title Case as it will appear in the file name).
- Product Manager and Tech Lead names.
- Description (up to 350 chars).
- Board URL for this team. Default: the workspace board URL. Derive `trackerBoardKey` from the URL when the pattern is obvious (Jira `projectKey=ABC`, `/projects/ABC`, `/browse/ABC-`); otherwise ask for the key or accept `TBD`.

Then a second round only if needed: other people as a list of `name, role, one-line description`. PM and Tech Lead are included automatically; if the user has no one else to add, skip.

Create `teams/<Name>.md` from the template:

- `isPartOf` links to the workspace display name.
- `productManager` and `techLead` link to `[[<Person Name>]]`.
- `topics: []` in the frontmatter (empty list; filled in topic mode).
- `## Pessoas e papéis` with every person, including PM and Tech Lead.
- `## Topics` with header only (table body rows are added in topic mode, in sync with `topics`).
- `## Fontes relacionadas` (table header only) and `## Arquivos e assets` (empty); if the user volunteered a channel, meeting or folder for this team, record it there without asking further (channels/meetings as rows in `## Fontes relacionadas` with `Tipo` = the tool; files as bullets in `## Arquivos e assets`).

Create one `people/<Name>.md` per person in the table, from the template, if the file does not exist. `isPartOf` links to `[[<Team Name>]]`. If the person already exists with a different team, do not overwrite; report it in the summary.

Append a row (`team`) to `## Acompanhamentos` in the workspace `AGENTS.md`.

## Mode: forum

A forum is a recurring meeting where decisions or alignments happen (a product committee, a leadership sync, a steering group). It is followed like a team: it owns topics, has sources, gets reports. Ask in one round:

- Forum name (Title Case as it will appear in the file name).
- Facilitator name and participants (names; existing `people/*.md` are offered as defaults).
- Description (up to 350 chars) and cadence.
- Board URL only if the user mentions one; otherwise `trackerBoardKey` and `trackerBoardUrl` are `TBD` and the tracker is skipped in reports.

Create `forums/<Name>.md` from the template: `facilitator` and `members` as `[[<Person Name>]]`; `topics: []` in the frontmatter (empty; filled in topic mode); `## Participantes` with every person and their role in the forum; `## Topics` header only (rows added in topic mode, in sync with `topics`); `## Fontes relacionadas` (table header only) and `## Arquivos e assets` (empty), filled with anything the user volunteered (the forum's own meeting is the natural first row in `## Fontes relacionadas` with `Tipo` = the meeting tool). Create `people/<Name>.md` for participants that do not exist yet (`tracked: false`; omit `isPartOf` when their team is unknown; do not add `topics` to untracked people).

Append a row (`forum`) to `## Acompanhamentos` in the workspace `AGENTS.md`. Then offer topics (default yes).

## Mode: person

Following a person means the user wants status reports about the topics that person answers for. Ask in one round:

- Which person: offer existing `people/*.md`; a new name creates the note (ask role and team).
- One paragraph on the scope of the follow-up (feeds `## Sobre`): what the person leads or answers for.

Set `tracked: true`, initialize `topics: []` in the frontmatter, and add `## Sobre`, `## Topics` (header only; rows in sync with `topics`), `## Fontes relacionadas` (table header only) and `## Arquivos e assets` (empty; anything volunteered goes here as bullets) to the person's note without touching the rest of the existing frontmatter or other content. Say in one line that direct messages are never read and that the user's own 1:1 notes enter through `## Arquivos e assets`.

Append a row (`person`) to `## Acompanhamentos` in the workspace `AGENTS.md`. Then offer topics (default yes).

## Mode: topic

Topic creation is owned by `mgr-topic`. This mode is a thin wrapper: it gathers name, description and target subjects, then invokes `/mgr-topic --add` for each topic. Do **not** write `topics/*.md` directly here.

List the subjects of the active workspace (`teams/*.md`, `forums/*.md`, `people/*.md` with `tracked: true`) and ask which one(s) each topic belongs to (multi-select). If none exist, run team mode first. With a single subject in the workspace, use it without asking. When run as part of the team/forum/person chain, pre-select the subject just created as a default the user can extend with more subjects.

Ask in one round, for all topics being added at once (one line per topic is fine):

- Topic name.
- Description (up to 300 chars).

Do not ask for status, due date, parent topic, current state, sources or a maintainer. Then, for each topic, invoke `/mgr-topic --add "<Name>" | "<Description>"` with the resolved subjects passed as a subject list. `mgr-topic` handles the file creation, the `topics` frontmatter update and the `## Topics` table row on every chosen subject.

Ask whether to add another topic (default no).

## Mode: source

The user describes, in prose after the flag, what to register and where it lives. Example: `--source adicione a reunião com título "Sync - Squad X" para pegar do Granola e das notas no meu vault /path/do/vault`. Read `data-model.md` for the shape of `## Fontes relacionadas` and `## Arquivos e assets` if unsure.

Resolve from the sentence, in this order:

- **Target note.** A topic named in the sentence ("do tópico X", "no tópico X") targets `topics/X.md`; otherwise the subject: the team, forum or tracked person named, or the only subject in the workspace. With several subjects and none named, ask which one, listing them by type. Never guess.
- **Kind**, by what the sentence describes: a channel or URL of a messenger is `channel`; a meeting title, "reunião", "sync", "weekly", or a transcript is `meeting`; a folder, note, vault path, document, URL or repo with no meeting is `file`. Ask only when it fits none.
- **Places** (meetings only): every tool or location the sentence names, normalized to the names used in the template (`Granola`, `Tactiq`, `Google Drive`, `Pasta local: <path>`, `Obsidian: <path>`, `Notion: <url>`). A path with no tool named is `Pasta local`. Keep paths and URLs exactly as given.

Then append to the target note only (same shape for subjects and topics):

- `channel` or `meeting` → one row in `## Fontes relacionadas` (`| Nome | URL/Link | Tipo |`) with `Tipo` = the tool (`Slack`, `Granola`, `Reunião`, `Google Drive`, etc.). For a meeting with several places, add one row per place with the same `Nome`. Missing URL → `TBD`.
- `file` → one bullet in `## Arquivos e assets`, using the top list for public URLs and the "locais e privados" bullet list for local paths.

Create `## Fontes relacionadas` (with the table header) or `## Arquivos e assets` from the template when the note predates them. Never touch other sections. A path pointing into a vault or folder not yet in `config.json → sources` is recorded there too, per the principles above.

Finish with the summary showing the exact lines appended and the file they went to. Several sources in one sentence are all registered in the same run.

## Summary

Always finish with:

```
STATUS: OK | WARN
```

`WARN` when any field was left as `TBD` or any note was skipped because it already existed. If `DATA_ROOT` is outside the connected folder, add one line saying later sessions will ask for its path. Then list: data root, reference folders, workspace path, files created, files skipped, lines appended (source mode), fields left as `TBD`, and the next step: run `/mgr-status-report <subject>` for the first report, or edit any note by hand (the plugin reads frontmatter and section headings, not folder structure).

## Never

- Ask for the output language, the user's name or role.
- Ask for topic status, due date, current state or sources during team, forum, person and topic setup; sources are registered only through `--source` or by hand.
- Ask which tools the company uses; ask for URLs and infer.
- Read tracker, messenger, meeting or email tools during setup.
- Write inside `${CLAUDE_PLUGIN_ROOT}`, inside a reference folder (other than the `DATA_ROOT` the user chose), or anywhere other than `DATA_ROOT`.
- Look for state in `~/.claude/`, `${CLAUDE_PLUGIN_DATA}`, a pointer file, or parent directories of the connected folder.
- Pick a data location the user did not name, or fall back to another path when the chosen one fails.
- Open a folder picker or show a form without first explaining what it is for.
- Create folders inside a workspace other than `teams/`, `forums/`, `people/`, `topics/` and `reports/<YYYY-MM>/`, or put a typed note outside its folder.
- Rewrite an existing note; only append rows or fill empty fields.
- Guess a board key, URL, person or date. Use `TBD` and report it.
