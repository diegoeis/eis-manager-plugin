---
name: mgr-topic
description: Manage topics in the manager-assistant workspace - create, list, remove and archive. Use when the user says "cria um tópico", "adiciona tópico", "lista tópicos", "remove o tópico X", "arquiva o tópico X", "quais tópicos temos", "novo tópico", or runs /mgr-topic. Flags - "--list-topics" lists every topics/*.md with status and the subjects that link to it; "--add" creates a new topic from the template and registers it in the subject(s) chosen; "--remove NAME" deletes the topic file and cleans every wikilink to it in Team/Forum/Person notes; "--archive NAME" renames the file to "archived - NAME.md", updates the H1 title and the frontmatter status to archived, and updates every subject wikilink to the new name. Other skills (mgr-setup, agents) that need to create a topic MUST delegate here with --add instead of creating the file themselves. Does not read trackers, messengers or meeting tools. Does not generate reports.
allowed-tools: Read Write Edit Glob Grep Bash(ls *) Bash(mv *) Bash(rm *) Bash(test *)
---

# mgr-topic

Single point of authority over `topics/*.md` notes. Everything that creates, lists, removes or archives a topic goes through this skill; other skills invoke `/mgr-topic --add` instead of writing a topic file directly.

## Step 0 — Find existing state

`DATA_ROOT` is where `mgr-setup` saved `config.json` (marker `"plugin": "eis-manager-assistant"`). Find it exactly as the other `mgr-*` skills do: a path in the request (`--data-root`), or the folder connected to the session (marker in it, in `manager-assistant/` inside it, or one level down). No `~/.claude/`, no `${CLAUDE_PLUGIN_DATA}`, no parent walking.

`WS` is `DATA_ROOT/workspaces/{{activeWorkspace}}`. Topics live in `WS/topics/`; subjects in `WS/teams/`, `WS/forums/` and `WS/people/`; reports in `WS/reports/{{YYYY-MM}}/` (table in `data-model.md`). File names carry no type prefix: a topic is `WS/topics/{{Name}}.md` and its wikilink is `[[{{Name}}]]`. If `WS` still has prefixed notes (`Team - X.md`, `Topic - X.md`) at its root, it predates 0.3.0: stop with `STATUS: BLOCKED` and ask the user to run `/mgr-setup` once to migrate. Not found:

```
STATUS: BLOCKED
No configuration found. Connect the folder that holds manager-assistant/, tell me its path, or run /mgr-setup first.
```

## References

- `${CLAUDE_PLUGIN_ROOT}/references/data-model.md` — before any write, for frontmatter, wikilinks and the editing rules.
- `${CLAUDE_PLUGIN_ROOT}/skills/mgr-topic/templates/Topic.md` — before `--add`, this is the schema. Fill every placeholder, remove the example row of `## Fontes relacionadas` and the example bullets of `## Arquivos e assets` when unfilled, keep only the fields the template defines. Optional fields (`isPartOf`, `dueDate`) are added only if the user provided a value; otherwise omit them entirely — do not emit them as `TBD`.

## Mode resolution

Parse `$ARGUMENTS`:

| Argument | Mode |
| --- | --- |
| `--list-topics` (or no flag) | **list**: list every topic with status and the subjects that link to it |
| `--add` | **add**: create a new topic |
| `--remove {{name}}` | **remove**: delete the topic file and every wikilink to it |
| `--archive {{name}}` | **archive**: rename the file, set status archived, update wikilinks |
| `--update` | Not implemented in this version. Print `STATUS: WARN` and one line explaining the flag is reserved. |

All modes require Step 0 to have found `config.json` with an active workspace. If it did not, print `BLOCKED` per Step 0.

## Principles

- First line of the final output is `STATUS: OK | WARN | BLOCKED`.
- Answer in the language the user is writing in.
- Never invent a value. A required field the user did not provide stays as `TBD` and is listed in the summary; optional fields (`isPartOf`, `dueDate`) are simply omitted when absent.
- Never write outside `WS` or inside `${CLAUDE_PLUGIN_ROOT}`.
- Never rewrite an existing note in full. Every write is either a new file, an appended row/bullet, a renamed file, or a surgical edit to a single field or line.
- Reports (`Report - *.md`) may be edited by dedicated skills or agents (e.g. `link-keeper` rewriting a wikilink on rename), but this skill never edits report factual content (`[Fn]`, farol, resumo). On remove, broken wikilinks in reports are left as plain labels per `data-model.md`.

## Mode: list

Read every `WS/topics/*.md`, then every `WS/teams/*.md`, `WS/forums/*.md`, `WS/people/*.md` (`tracked: true`) to invert the relation.

Print a single Markdown table:

```
| Tópico | Status | Sujeitos |
| --- | --- | --- |
| {{name}} | {{status}} | {{Squad X (time), Comitê de Produto (fórum)}} (or "—" when none) |
```

Sort archived topics to the bottom. Summary: total, breakdown by status, count of orphans (topics with zero subjects) and one-line pointer to `--archive` or `--remove` if any archived or orphaned topics were listed.

## Mode: add

The invoker can pass the topic name and description in the argument (`--add "{{Name}}" | "{{Description}}"`) or in free prose after the flag; also accepted from another skill piping a payload. If neither is present:

- `--interactive`: ask for name and description in one round; offer the subjects of the active workspace as multi-select. When another skill invoked this mode and pre-selected a subject, keep it pre-selected.
- Silent: `STATUS: BLOCKED`, one line explaining that a topic name, description and at least one subject are required.

Resolve the target subjects:

- Names in the argument that match `teams/*.md`, `forums/*.md` or `people/*.md` (`tracked: true`) are the chosen subjects.
- The caller can hand over a resolved list of subject wikilinks; use it as is.
- One subject in the workspace and none named: use it.

Before creating anything, check `WS/topics/{{Name}}.md`:

- File exists: this is the same topic gaining a new subject. Do not touch the topic note. Append the topic's wikilink to the `topics` frontmatter list and one row to the `## Topics` table of every new subject. If every chosen subject already links to it, `STATUS: WARN` and say nothing changed.
- A note with that name exists in `WS/teams/`, `WS/forums/` or `WS/people/`: names are unique across the workspace because wikilinks carry no folder. Do not create the topic; in `--interactive` ask for a distinct name, otherwise `STATUS: BLOCKED` naming the existing note.
- File does not exist: read `templates/Topic.md`, fill it, and write `WS/topics/{{Name}}.md` (create `WS/topics/` if it does not exist).

Filling the template:

- `name`: the topic name, unchanged.
- `id`: slug of `name` — lowercase, replace non-alphanumeric with `-`, collapse repeated `-`, trim leading/trailing `-`.
- `status`: `TBD` (the report skill will update it later).
- `description`: what the user gave, up to 300 characters.
- `created`: today (`YYYY-MM-DD`).
- `isPartOf` and `dueDate`: omit unless the user or the caller provided them. Never emit as `TBD`.
- Body: fill `## Contexto` from the description plus anything the user said. Leave `## Status` empty (no dated subsection yet). `## Fontes relacionadas` keeps only the table header. `## Arquivos e assets` keeps only its explanation lines and the "locais e privados" heading — remove the example bullets.

After the file is written, for each chosen subject:

- Append the topic's wikilink to the `topics` frontmatter list.
- Append a row to the `## Topics` table with `{{Name}}` | `[[{{Name}}]]` | first sentence of the description.

Summary: file created, subjects linked, `TBD` fields left, and the natural next step (add another via `--add` or generate a report).

## Mode: remove

Requires a name after the flag (`--remove "{{Name}}"`). Resolution:

- Exact match on `WS/topics/{{Name}}.md` → target.
- No match: list existing topics (via list mode's inversion) and stop with `STATUS: BLOCKED`.

Before deleting, in `--interactive` mode, show the topic name, its subjects and how many reports reference it (from a Grep on `[[{{Name}}]]` inside `WS/reports/*/Report - *.md`), and ask to confirm. In silent mode, proceed without confirmation but list the same facts in the summary and set `STATUS: WARN`.

Delete steps, in order:

1. `rm "WS/topics/{{Name}}.md"`.
2. Invoke the `eis-manager-assistant:link-keeper` agent with the brief:
   ```
   operation: remove
   ws: {{WS absolute path}}
   old: [[{{Name}}]]
   kind: topic
   ```
   The agent removes the wikilink from every subject note (frontmatter `topics` list AND `## Topics` table row) and counts remaining orphan occurrences in reports and prose without editing them.

This skill does not edit report files on `--remove`; a report that referenced the topic keeps `[[{{Name}}]]` as a broken label. (On `--archive`, `link-keeper` does rewrite the wikilink in reports because it is a pointer update.)

Summary: file removed, agent output (files edited, orphan occurrences left as labels in reports).

## Mode: archive

Requires a name after the flag (`--archive "{{Name}}"`). Same resolution as `--remove`.

If the topic filename already starts with `archived - `, `STATUS: WARN` and stop — already archived.

Steps, in order:

1. Read the topic note. Compute the new filename `archived - {{Name}}.md` and the new display name `archived - {{Name}}`.
2. Edit the topic note in place: set frontmatter `status: archived`; set the H1 (`# {{Name}}` line) to `# archived - {{Name}}`; `name` in the frontmatter also becomes `archived - {{Name}}`. Leave everything else untouched.
3. `mv "WS/topics/{{Name}}.md" "WS/topics/archived - {{Name}}.md"` (same folder; only the name changes).
4. Invoke the `eis-manager-assistant:link-keeper` agent with the brief:
   ```
   operation: rename
   ws: {{WS absolute path}}
   old: [[{{Name}}]]
   new: [[archived - {{Name}}]]
   kind: topic
   ```
   The agent rewrites every occurrence of the old wikilink to the new one across every note of the workspace (type folders and `reports/*/`), including subject frontmatter, `## Topics` tables, prose, and — by design — report files. Rewriting a wikilink target is a pointer update; the factual content of reports (`[Fn]`, farol, resumo) is untouched.

Summary: new filename, new display name, agent output (files edited, occurrences edited across subjects, topics and reports).

## Update

Not implemented in this version. `--update` returns `STATUS: WARN` and one line: "flag reservada; nesta versão o `mgr-status-report` já atualiza `## Status` e o frontmatter `status` do tópico a cada execução".

## Never

- Read a tracker, messenger, meeting tool or the web.
- Create tasks, stories, specs or reports.
- Rewrite report files, or delete anything under `Report - *.md`.
- Emit optional fields (`isPartOf`, `dueDate`) as `TBD` — omit them instead.
- Fabricate a subject name, board key or date.
- Skip the subject sync in `--add`/`--remove`/`--archive`: the topics list of every affected subject and its `## Topics` table must stay consistent.
