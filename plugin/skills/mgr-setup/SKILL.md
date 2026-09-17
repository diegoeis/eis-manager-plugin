---
name: mgr-setup
description: Set up or extend the manager-assistant workspace. Use when the user says "configura o plugin", "setup do manager assistant", "cria um workspace", "adiciona um time", "cadastra um fórum", "quero acompanhar a pessoa X", "cadastra um tópico", or runs /mgr-setup. Modes via argument - none or "--workspace" creates a workspace and chains into team and topic setup; "--team" adds a team and its people; "--forum" adds a forum (recurring decision meeting followed like a team); "--person" starts following a direct report individually; "--topic" adds a topic that can relate to one or several teams, forums or people, not owned by a single one; "--source" plus a sentence registers a channel, meeting or folder in the Fontes section of a subject or topic note, e.g. "--source adicione a reunião Sync - RPA, do Granola e do vault /path". Interactive but frugal - asks only what cannot be inferred from the scanned folders. Never reads trackers or messengers, only records URLs. Do not use to generate reports.
allowed-tools: Read Write Edit Glob Grep Bash(mkdir *) Bash(ls *) Bash(test *) Bash(echo *)
---

# mgr-setup

Creates the state every other `mgr-*` skill depends on: a data folder chosen by the user, its `config.json`, a workspace folder with its narrative, and the `Team`, `Forum`, `Person` and `Topic` notes that describe who does what. Teams, forums and tracked people are the **subjects** the report skill works on; they share `## Topics` and `## Fontes`.

## Step 0 — Find existing state (before reading anything else)

Do this first, with no other reads. If a folder is connected to the session, look for `config.json` containing `"plugin": "eis-manager-assistant"` in it, in `manager-assistant/` inside it, or one level down. That is the whole search: no pointer file, nothing under `~/.claude/` or `${CLAUDE_PLUGIN_DATA}`, no walking up parent directories.

Found `config.json`: `DATA_ROOT` is its folder; say so in one line and skip Round 1. Not found, or no folder connected: go to Round 1.

## References

Read only when the step needs them, not upfront:

- `${CLAUDE_PLUGIN_ROOT}/references/data-root.md` — before writing `config.json` (schema, tool inference from URLs).
- `${CLAUDE_PLUGIN_ROOT}/references/data-model.md` — before creating the first note (frontmatter, body sections, wikilinks).

Templates: `${CLAUDE_PLUGIN_ROOT}/skills/mgr-setup/templates/` (this skill's own folder: `AGENTS.md`, `CLAUDE.md`, `Team.md`, `Forum.md`, `Person.md`, `Topic.md`). Read each one right before creating that kind of note. Every note is created from its template; replace every `{{placeholder}}`, remove example rows that were not filled, never leave a placeholder behind.

## Principles

- Answer in the language the user is writing in. Never ask which language to use.
- Ask only what you cannot infer. Before each question, check the data folder and the notes already created in this run.
- Every question, picker or form is preceded by one or two sentences saying why it is being asked and what will be done with the answer. A bare folder picker or a form with no context is a defect. On hosts that collapse text between tool calls (Cowork), that context must be sent with the user-message tool, not as plain text.
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
| `--source <prose>` | **source**: register a channel, meeting or folder in the `## Fontes` of a subject or topic note |

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

Create `DATA_ROOT/workspaces/<slug>/`, then `AGENTS.md` and `CLAUDE.md` from the templates. Fill `## Sobre` and `## Ferramentas` (two rows: tracker and messenger, with inferred tool and URL). Leave `## Acompanhamentos` with a header only; rows are added as teams, forums and tracked people are created. Fill `## O que importa acompanhar` and `## Convenções e armadilhas` only if the user volunteered content; otherwise leave one line saying the section is empty and can be edited by hand.

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

Create `Team - <Name>.md` from the template:

- `isPartOf` links to the workspace display name.
- `productManager` and `techLead` link to `[[Person - <Name>]]`.
- `## Pessoas e papéis` with every person, including PM and Tech Lead.
- `## Topics` with header only.
- `## Fontes` with the three subsection headers only (`### Canais`, `### Reuniões e transcrições`, `### Arquivos`); if the user volunteered a channel, meeting or folder for this team, record it there without asking further.

Create one `Person - <Name>.md` per person in the table, from the template, if the file does not exist. `isPartOf` links to `[[Team - <Name>]]`. If the person already exists with a different team, do not overwrite; report it in the summary.

Append a row (`team`) to `## Acompanhamentos` in the workspace `AGENTS.md`.

## Mode: forum

A forum is a recurring meeting where decisions or alignments happen (a product committee, a leadership sync, a steering group). It is followed like a team: it owns topics, has sources, gets reports. Ask in one round:

- Forum name (Title Case as it will appear in the file name).
- Facilitator name and participants (names; existing `Person - *.md` are offered as defaults).
- Description (up to 350 chars) and cadence.
- Board URL only if the user mentions one; otherwise `trackerBoardKey` and `trackerBoardUrl` are `TBD` and the tracker is skipped in reports.

Create `Forum - <Name>.md` from the template: `facilitator` and `members` as `[[Person - <Name>]]`; `## Participantes` with every person and their role in the forum; `## Topics` header only; `## Fontes` with the three subsection headers, filled with anything the user volunteered (the forum's own meeting is the natural first entry under `### Reuniões e transcrições`). Create `Person - <Name>.md` for participants that do not exist yet (`tracked: false`; omit `isPartOf` when their team is unknown).

Append a row (`forum`) to `## Acompanhamentos` in the workspace `AGENTS.md`. Then offer topics (default yes).

## Mode: person

Following a person means the user wants status reports about the topics that person answers for. Ask in one round:

- Which person: offer existing `Person - *.md`; a new name creates the note (ask role and team).
- One paragraph on the scope of the follow-up (feeds `## Sobre`): what the person leads or answers for.

Set `tracked: true` and add `## Sobre`, `## Topics` (header only) and `## Fontes` (headers, plus anything volunteered) to the person's note without touching the existing frontmatter or other content. Say in one line that direct messages are never read and that the user's own 1:1 notes enter through `### Arquivos`.

Append a row (`person`) to `## Acompanhamentos` in the workspace `AGENTS.md`. Then offer topics (default yes).

## Mode: topic

A topic is not owned by a single subject: it can relate to several teams (and, less commonly, forums or tracked people) at once. List the subjects of the active workspace (`Team - *.md`, `Forum - *.md`, `Person - *.md` with `tracked: true`) and ask which one(s) this topic relates to (multi-select). If none exist, run team mode first. With a single subject in the workspace, use it without asking. When run as part of the team/forum/person chain, pre-select the subject just created as a default the user can extend with more teams, not the only option.

Before creating anything, check whether `Topic - <Name>.md` already exists for the topic name given. If it does, this is the same topic gaining a new related subject: add the missing wikilink(s) to its `relatedTeam`/`relatedForum`/`relatedPerson` list and append a row to the new subject's `## Topics` table — do not create a second file, do not touch its other fields.

For a genuinely new topic, ask in one round, for all topics being added at once (one line per topic is fine):

- Topic name.
- Maintainer: offer the people of the chosen subject(s) (team's `## Pessoas e papéis`, forum's `## Participantes`, or the person herself as default).
- Description (up to 350 chars).
- Parent topic and additional related teams/forums/people only if the user mentions them; do not ask.

Do not ask for status, due date, current state or sources. Those are filled later by the report and analysis skills, or by the user editing the note.

Create `Topic - <Name>.md` from the template. `name` in the frontmatter is the topic name only — never a subject name. `relatedTeam`, `relatedForum` and `relatedPerson` each list the wikilinks (with prefix) of every chosen subject of that type; use an empty list for the ones that got none. `maintainer` links to the person chosen. `created` is today. `status` and `dueDate` are `TBD`. Omit `isPartOf` when there is no parent, otherwise link the parent's file name (`[[Topic - <Parent Name>]]`, no suffix). Leave `## Status atual` with the farol as `TBD` and no report link, `## Fontes` with headers only, `## Reports` empty. Fill `## Contexto` from the description and anything the user said about why the topic exists.

Append a row to the `## Topics` table of every chosen subject with name, `[[Topic - <Name>]]` and the description's first sentence.

Ask whether to add another topic (default no).

## Mode: source

The user describes, in prose after the flag, what to register and where it lives. Example: `--source adicione a reunião com título "Sync - RPA" para pegar do Granola e das notas no meu vault /path/do/vault`. Read `data-model.md` for the shape of `## Fontes` if unsure.

Resolve from the sentence, in this order:

- **Target note.** A topic named in the sentence ("do tópico X", "no tópico X") targets `Topic - X.md`; otherwise the subject: the team, forum or tracked person named, or the only subject in the workspace. With several subjects and none named, ask which one, listing them by type. Never guess.
- **Kind**, by what the sentence describes: a channel or URL of a messenger goes to `### Canais`; a meeting title, "reunião", "sync", "weekly", a transcript goes to `### Reuniões e transcrições`; a folder, note, vault path, document or link with no meeting goes to `### Arquivos`. Ask only when it fits none.
- **Places** (meetings only): every tool or location the sentence names, normalized to the names used in the template (`Granola`, `Tactiq`, `Google Drive`, `Pasta local: <path>`, `Obsidian: <path>`, `Notion: <url>`). A path with no tool named is `Pasta local`. Keep paths and URLs exactly as given.

Then append to the target note only:

- Canais: one table row `| #nome | url |` (`TBD` for a missing URL).
- Reuniões: one bullet with the meeting title as written, and one nested bullet per place. If the meeting already exists in the note, add only the places that are missing under it.
- Arquivos: one bullet with the path or URL.

Create the `## Fontes` block from the template when the note predates it. Never touch other sections. A path pointing into a vault or folder not yet in `config.json → sources` is recorded there too, per the principles above.

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
- Create nested folders inside a workspace.
- Rewrite an existing note; only append rows or fill empty fields.
- Guess a board key, URL, person or date. Use `TBD` and report it.
