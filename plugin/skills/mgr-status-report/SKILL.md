---
name: mgr-status-report
description: Generate a status report of a subject - a team, a forum or a person the user follows - for a period from the tracker, messenger and meeting tools, every fact cited, then update the topics' farol. Use when the user says "status report do time X", "report do fórum Y", "como está a pessoa Z", "gera o report da semana", "atualiza o report com isso", or runs /mgr-status-report. Arguments as flags or prose - subject name (optional with one subject); period ("--period 14d", "de 1 a 15 de setembro"; default last 7 days); "--sources tracker,messenger,meetings"; "--data-root /path" when no folder is connected; "--interactive" to confirm subject and farol changes (default silent); "--update" plus a file, transcript, text or link edits the subject's latest report in place with the new facts. Reads external sources only via the source-* sub-agents and records what it learns. Does not create tasks or specs, does not cover several subjects at once, does not set up subjects or topics (use mgr-setup).
allowed-tools: Read Write Edit Glob Grep Agent
---

# mgr-status-report

Produces `reports/{{YYYY-MM}}/Report - {{Subject Name}} - {{YYYY-MM-DD}}.md` in the active workspace from evidence gathered by the `source-*` sub-agents, updates each topic's farol and report links, and records what it learned about the subject's sources so the next run starts from more. The **subject** is a team (`teams/*.md`), a forum (`forums/*.md`) or a person the user follows (`people/*.md` with `tracked: true`); the flow is the same for the three, and the few differences are marked below. Facts only, each with a reference; anything without a source is marked as unverified or left out.

## Step 0 — Find existing state

The data root is where `mgr-setup` saved `config.json` (marker `"plugin": "eis-manager-assistant"`). Find it from what the user gave: a path in the request (flag or prose), or the folder connected to the session (the marker in it, in `manager-assistant/` inside it, or one level down). Do not look anywhere the user did not point to: no `~/.claude/`, no `${CLAUDE_PLUGIN_DATA}`, no parent directories.

Found: `DATA_ROOT` is its folder; `WS` is `DATA_ROOT/{{workspaces[activeWorkspace].path}}`. Notes live in one folder per type inside `WS` (`teams/`, `forums/`, `people/`, `topics/`, `reports/{{YYYY-MM}}/`; table in `data-model.md`). File names carry no type prefix (only reports do), and wikilinks resolve by file name across those folders. If `WS` still has prefixed notes (`Team - X.md`, `Topic - X.md`, `Report - ...`) at its root, it predates 0.3.0: stop with `STATUS: BLOCKED` and ask the user to run `/mgr-setup` once to migrate. Not found: with `--interactive`, ask once for the path and explain why. Otherwise:

```
STATUS: BLOCKED
No configuration found. Connect the folder that holds manager-assistant/, tell me its path, or run /mgr-setup first.
```

## References

Read at the step that needs them: `${CLAUDE_PLUGIN_ROOT}/references/evidence.md` before gathering evidence (brief, evidence shape, farol rule); `${CLAUDE_PLUGIN_ROOT}/skills/mgr-status-report/templates/Report.md` (this skill's own template) right before writing; `${CLAUDE_PLUGIN_ROOT}/references/data-model.md` if unsure how to edit a note.

**To reference, look the messages between the user the execute the action and the people listed in the team file or the `evidence.md` file.**

## Principles

- First line of the final output is `STATUS: OK | WARN | BLOCKED`.
- Silent by default: no questions unless `--interactive`. Missing something essential: stop with `BLOCKED` and one line saying what to do.
- Answer and write in the language the user is writing in. Report headings stay as in the template; they are identifiers.
- Never invent. Every factual sentence in the body carries the source as an inline markdown link (`[descrição curta](url)`) — never the old `[Fn]` marker, never italic text without a link ("Sync Squad X no Granola"). If a sub-agent returned a meeting evidence without a permalink URL, drop the fact or move it to `## Não verificado`; do not render meeting citations as descriptive italic. Never guess a next step or a date.
- Every action, pending item, risk and next step names who is accountable. When the evidence names someone (`who:`), use that name. When it does not, write the subject's default accountable, marked as default so the reader can tell it from an assignment stated by the source: team → `{{PM}} e {{Tech Lead}} (padrão)`; forum → `{{facilitator}} (padrão)`; person → `{{the person}} (padrão)`. Never pick any other person.
- Every task/issue key from the tracker (`ABC-123`, `PROJ-42` — any `{{UPPERCASE}}-{{number}}` shape) that appears anywhere in the report MUST be rendered as a markdown link to the item in the tracker. Build the URL from `config.json → workspaces.{{active}}.tools.tracker`: for `tool: "jira"`, `{{url}}/browse/{{KEY}}` (ex.: `[ABC-123](https://acme.atlassian.net/browse/ABC-123)`); for `tool: "linear"`, `{{url}}/issue/{{KEY}}`; other trackers follow their own convention. Never write the key as plain text. Applies ao resumo executivo, bullets de tópicos, ações, entregas, riscos e decisões. When `tools.tracker.url` is missing from `config.json`, set `STATUS: WARN`, deixe as chaves como texto puro e sinalize no summary pedindo pro usuário rodar `/mgr-setup` pra completar; não invente base URL.
- Every person name that appears anywhere in the report (resumo executivo, tópicos, ações, riscos, decisões) MUST be rendered as a wikilink-style markdown link to the matching Person note, relative to the report's folder: `[Nome da Pessoa](../../people/Nome da Pessoa.md)` (the report lives in `WS/reports/{{YYYY-MM}}/`, people in `WS/people/`). When a Person note does not exist for that name, still write the link with the expected path — the reader will follow it and create the note if needed. Applies to both cited names and default accountables (still include the "(padrão)" suffix outside the link).
- No customer names, personal data or document numbers in the report.
- A person's report is about the work that person answers for: topics, deliveries, blockers, decisions. Never about conduct, tone, hours or availability, even when a source mentions them. Direct messages are never a source. The summary of a person's report ends with one line saying it lives in the manager's workspace and is not meant to be shared.
- Engineering mechanics are not actions. Pull requests, merge requests, code reviews, commits, branches, pipelines and deploy notices never appear as an action, pending item, risk or next step, whatever the source. They may only support a delivery statement about the work item they belong to ("ABC-123 entregue [F4]"), never stand on their own. When a source's whole content is a PR or MR, drop it.
- Tracker, messenger and meeting tools are read only by the sub-agents, only with the brief from `evidence.md`. The one thing this skill reads itself is material the user hands over in `--update` (a file path or pasted text).
- Never rewrite an existing note or report. Reports are new files; topic notes receive edits in the fields and sections named below. The only edit to an existing report is `--update`, which adds to it and never regenerates it.
- Learn as you go. Anything found about the subject's sources that will be useful again - a channel, a meeting, a folder of transcripts, a board convention, a keyword that maps issues to a topic - is recorded where it belongs (`## Fontes relacionadas` for channels/meetings and `## Arquivos e assets` for files; on the topic when it concerns a single topic, on the subject when it concerns the subject at large; workspace `AGENTS.md`; `config.json → sources`) in the same run, without asking. The user should not have to hand over sources twice.

## Step 1 — Read the request

`$ARGUMENTS` is free text; flags and prose mean the same thing. Resolve:

- **Subject**: match the name against `WS/teams/*.md`, `WS/forums/*.md` and `WS/people/*.md` with `tracked: true`. A type word in the request ("time", "fórum", "pessoa") narrows the match. One subject in the workspace and none named: use it. Ambiguous, or a person named who is not `tracked`: ask in `--interactive`, otherwise `BLOCKED` listing the subjects by type (and pointing to `/mgr-setup --person` for the untracked person).
- **Period**: whatever the user declared with days or dates. Nothing declared: the last 7 days ending today. Print the resolved dates in the summary so the user can rerun if they meant otherwise. Never ask.
- **Sources**: tracker, messenger and meetings unless the user narrowed them.
- **Interactive**: only when asked for.
- **Update**: `--update`, or prose asking to update an existing report with new information ("atualiza o report do time X com esse transcript"). Go to [Update mode](#update-mode) instead of Steps 2-5.

## Step 2 — Load workspace context

Read what the workspace already knows and nothing more: `WS/AGENTS.md` (what matters this period, conventions such as which tracker column means done, registered channels); the subject note (board if any, people - PM and Tech Lead, or facilitator and members, or the person and her team - the `topics` frontmatter list, `## Fontes relacionadas` and `## Arquivos e assets`: channels, meetings and files that every report of this subject consults); the subject's topics (every `WS/topics/*.md` whose wikilink appears in the subject's `topics` frontmatter list - read the frontmatter, `## Fontes relacionadas`, `## Arquivos e assets`, current `status`; a topic may also appear in other subjects' `topics`, that is expected); the newest previous report of the subject, searched across every `WS/reports/*/` folder (frontmatter, farol table AND every `#### Ações e Pendências` block from each topic — specifically the `- [ ]` items that were left open, keeping the original responsible, description, source link and the original date + link to the report they came from); `config.json` (`referenceFolders` and `sources`, which together are the `localFolders` where notes or transcripts may live).

The open action items (`- [ ]`) collected from the previous report must be carried over into the corresponding topic's `#### Ações e Pendências` in the new report, on top of any new items identified in the current period. Never re-include items already marked `- [x]` in past reports. If an open item from the previous report is verified as completed in this period's evidence, move it in as `- [x]` with the new evidence link and keep the original date and origin report link.

A subject without topics still gets a report; the topic sections say so and point to `/mgr-setup --topic`.

## Step 3 — Gather evidence

Read `evidence.md`. Build one brief per selected source with what Step 2 found: `subject` and `subjectType`; the subject's `## Fontes relacionadas` and `## Arquivos e assets` feed the brief's `channels`, `meetings` and the head of `localFolders` (same mapping used for topics: row `Tipo` = messenger → `channels`, `Tipo` = meeting tool → `meetings`, `## Arquivos e assets` bullets → `files`); each topic's `## Fontes relacionadas` and `## Arquivos e assets` feed its own topic line the same way; `config.json` closes `localFolders`. By type: a team's brief carries its `board`; a forum's carries `board` only when it has one; a person's carries the board of her team (`isPartOf`) plus `assignee: {{her name}}`. Invoke, in parallel, one call each with the brief as the prompt: `eis-manager-assistant:source-tracker` (skip when there is no board or its key is `TBD`, and say so), `eis-manager-assistant:source-messenger`, `eis-manager-assistant:source-meetings`.

Merge what comes back. Drop items without a source. A source whose connector was absent is "not consulted", not "no news". One pass; do not go back for more.

Record every `learned:` line now, where it belongs.

## Step 4 — Write the report

Read `${CLAUDE_PLUGIN_ROOT}/skills/mgr-status-report/templates/Report.md` and fill it: `WS/reports/{{YYYY-MM of today}}/Report - {{Subject Name}} - {{periodEnd}}.md`. The month folder is the month the report is created (`created`, today), not the month of the period; create it when it does not exist. Suffix `-2`, `-3` when a report with that name already exists in any `WS/reports/*/` folder. Links to the previous report and to the reports where carried-over action items came from point to the month folder where each of those reports actually is (`../{{YYYY-MM}}/Report - ....md`). `owner` in the frontmatter is the wikilink to the subject from Step 1; the subject type is not written, it follows from the folder of the owner note (`teams/`, `forums/`, `people/`). Apply the farol rule from `evidence.md` per topic. Every section of the template is present; a section with nothing says "Nenhum identificado nas fontes consultadas". `topic: unknown` and `topic: subject` evidence goes to the subject-level sections. Frontmatter lists are `[]` when empty; `previousReport` is omitted on the first report. No placeholder survives.

## Step 5 — Update topic notes

For **every** topic of the subject — with or without evidence in the period — append one entry to `## Status` under the `### {{periodEnd}}` subsection (create the subsection if it does not exist; the header format is `### YYYY-MM-DD` matching `periodEnd`). Each entry is:

```
- **Report**: [[Report - {{Subject Name}} - {{periodEnd}}]]
  - **Farol**: {{on_track | in_risk | problem | TBD}}
  - **Descrição**: {{up to 80 words, with the source linked inline (`[descrição](url)`) when there is evidence, or "sem evidência no período" when there is none. Nomes de pessoas linkados como `[Nome](../people/Nome.md)` (relativo à pasta `topics/`).}}
```

Never sort, rewrite or dedupe existing entries on the same day — just append. Several subjects reporting on the same topic on the same day stack their bullets under the same `### YYYY-MM-DD`.

Also update the frontmatter `status` of the topic, but only when the farol was decided from evidence (not the "sem evidência no período" case):

- `--interactive`: show topic, previous farol, proposed farol and reason; apply what the user confirms.
- Silent: apply, list every change in the summary under "Farol atualizado sem confirmação", and set `STATUS: WARN`.

Never touch `## Contexto`, `## Fontes relacionadas`, `## Arquivos e assets`, `description`, `id`, `created`, `dueDate` or `isPartOf`. The topic note has no `## Reports` section anymore — the report link lives inside `## Status`.

## Update mode

`--update` adds what the user handed over to an existing report, editing it in place. It does not re-read the tracker, messenger or meetings of the period; only the new material.

**Target report.** The one the user named (path, file name or date); otherwise the latest report of the subject resolved in Step 1 (greatest date in the file name across every `WS/reports/*/`). None found: `BLOCKED`, pointing to `/mgr-status-report {{subject}}` to generate the first one.

**New material.** Whatever came with the request, as free text: a local file (transcript, notes, export), pasted text, one or more links. Nothing handed over: `BLOCKED`, saying what to attach. Turn it into evidence in the `evidence.md` shape (read it right before this step):

- Local file: read it yourself; `source` is the absolute path.
- Link to a tracker, messenger or meeting tool: send a brief to the matching `source-*` sub-agent (by the link's domain) with the report's subject (`owner`) and its type (from the folder of the owner note), period and topics, and the link in `board`, `channels` or `meetings`. Connector absent: the link is "not consulted" and `STATUS: WARN`. Any other link (a doc, a page): treat as a file if the session can open it, otherwise not consulted.
- Pasted text with no link: its facts go to `## Não verificado` as "fornecido pelo usuário sem referência". Links inside the text count as sources.

The same rules as a new report apply to every fact written: inline source link, accountable named, tracker keys and person names linked, no engineering mechanics, no customer data, nothing about a person's conduct. Facts dated outside the report's period are accepted, since the user handed them over; write the date next to them.

**Edit the report.** Read the template once if unsure of a section. Edit only what the new evidence touches, section by section:

- Add the new facts to the topic sections, deliveries, risks, decisions and `#### Ações e Pendências` where they belong. `topic: unknown` and `topic: subject` go to the subject-level sections.
- An open `- [ ]` that the new evidence shows done becomes `- [x]` with the new source link, keeping its original date and origin link.
- An item in `## Não verificado` that the new material now sources moves to its section with the link.
- Re-apply the farol rule to each topic that got new evidence, counting old and new evidence together; update its row in `## Farol por tópico` ("Farol anterior" stays as it was).
- Update `## Resumo executivo` only if the new facts change what leadership needs to know; still up to 100 words, every item sourced.
- Append the new sources to `## Fontes consultadas`, and remove from "Fontes não consultadas" whatever is now consulted.
- Frontmatter: add `updated: {{today}}` (replace the date if the field exists); add new topics to `topics`. Sources, including files or text the user handed over, are recorded only in `## Fontes consultadas`, never in the frontmatter.

Never delete or reword a fact that already has a source. When the new material contradicts one, keep both, each with its source and date, and list the contradiction in the summary. Never change `name`, `owner`, `periodStart`, `periodEnd`, `created`, `previousReport` or the file name.

**Topic notes.** For each topic whose farol changed, append one entry under `### {{periodEnd}}` in its `## Status`, same shape as Step 5, with `- **Report**: [[Report - {{Subject Name}} - {{periodEnd}}]] (atualizado em {{today}})`, and update the frontmatter `status` with the same confirmation rule as Step 5. Topics whose farol did not change are not touched.

Record `learned:` lines and any recurring channel, meeting or folder found in the new material, as in a new report.

## Summary

`STATUS: OK | WARN | BLOCKED` first. `WARN` when a source was not consulted, a topic had no evidence, evidence was cut, a farol changed silently, or the subject has no board (`TBD`). Then, briefly: report path, period, sources consulted and skipped with reasons, farol changes, what was learned and recorded, items in `## Não verificado`, and the natural next step.

In update mode the summary is an update report, in the chat, with these blocks in this order (a block with nothing says "nenhum"). Every line names the section or note it refers to and carries the source link:

1. **Report atualizado**: path, and the material received (files, links, text) with what was consulted and what was not, and why.
2. **Modificado**: facts added, per report section; items moved out of `## Não verificado`; executive summary adjusted or not; frontmatter fields changed.
3. **Marcado como concluído**: every `- [ ]` flipped to `- [x]`, with its accountable and the new source.
4. **Farol**: every topic whose farol changed (previous → new, reason), in the report and in the topic note, and whether it was applied without confirmation.
5. **Contradições**: each fact of the new material that conflicts with one already in the report, both sides with their sources and dates. The skill does not decide which one is right.
6. **Atualizar manualmente**: what the new material says but this skill cannot or must not write, each with where it should go and the command when there is one. For example: a fact that fits no topic of the subject (`/mgr-topic --add`); a change of deadline, scope or description of a topic (`dueDate`, `description`, `## Contexto` are never edited here); a new person or source for the subject (`/mgr-setup --person`, `/mgr-setup --source`); pasted text that needs a link to leave `## Não verificado`; a contradiction the user must resolve in the report.

## Never

- Ask anything outside `--interactive`, including the period, the language or the sources.
- Read a tracker, messenger or meeting tool yourself, or send note bodies and previous reports to a sub-agent.
- Write a factual sentence without an inline source link, or fall back to the old `[Fn]` marker format.
- Write a person's name in the report without wrapping it as `[Nome](../../people/Nome.md)`.
- Write a tracker key (`ABC-123`, `PROJ-42`) as plain text — always link to the item URL.
- Report on more than one subject in one run, or create tasks, stories or specs.
- Overwrite or regenerate a report (`--update` only adds to it), rewrite a note, or change a topic's `description`, `id`, `created`, `dueDate` or `isPartOf`.
- Write outside `WS` and `config.json`, or inside `${CLAUDE_PLUGIN_ROOT}`.
