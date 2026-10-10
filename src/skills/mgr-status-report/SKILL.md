---
name: mgr-status-report
description: Generate a status report of a subject - a team, a forum or a person the user follows - for a period from the tracker, messenger and meeting tools, every fact cited, then update the topics' farol. Use when the user says "status report do time X", "report do fórum Y", "como está a pessoa Z", "gera o report da semana", "atualiza o report com isso", or runs /mgr-status-report. Arguments as flags or prose - subject name (optional with one subject); period ("--period 14d", "de 1 a 15 de setembro"; default last 7 days); "--sources tracker,messenger,meetings"; "--data-root /path" when no folder is connected; "--interactive" to confirm subject and farol changes (default silent); "--update" plus a file, transcript, text or link edits the subject's latest report in place with the new facts. Reads external sources only via the source-* sub-agents. Does not create tasks or specs, does not cover several subjects at once, does not set up subjects or topics (use mgr-setup).
allowed-tools: Read Write Edit Glob Grep Agent
---

# mgr-status-report

Produces `reports/{{YYYY-MM}}/Report - {{Subject Name}} - {{YYYY-MM-DD}}.md` in the active workspace from evidence gathered by the `source-*` sub-agents, updates each topic's farol and report links. The **subject** is a team (`teams/*.md`), a forum (`forums/*.md`) or a person the user follows (`people/*.md` with `tracked: true`); the flow is the same for the three, and the few differences are marked below. Facts only, each with a reference; anything without a source is marked as unverified or left out.

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
- A topic may be shared by several subjects. Evidence about a person who belongs to **another** subject still appears in this report as context of the topic, with the suffix `(via {{Outro Time}})` after the fact, but never becomes an action, pending item, risk, decision or next step of this subject — the other subject's report owns it. The rule and how to resolve the person's team are in `evidence.md → Pertencimento`.
- Every action, pending item, risk and next step names who is accountable. When the evidence names someone (`who:`), use that name. Risks, decisions and next steps with no one named take the subject's default accountable, marked as default so the reader can tell it from an assignment stated by the source: team → `{{PM}} e {{Tech Lead}} (padrão)`; forum → `{{facilitator}} (padrão)`; person → `{{the person}} (padrão)`. An item of `#### Ações e Pendências` never takes a default accountable: no owner named by the source, no action (see Step 4). Never pick any other person.
- Every task/issue key from the tracker (`ABC-123`, `PROJ-42` — any `{{UPPERCASE}}-{{number}}` shape) that appears anywhere in the report MUST be rendered as a markdown link to the item in the tracker. Build the URL from `config.json → workspaces.{{active}}.tools.tracker`: for `tool: "jira"`, `{{url}}/browse/{{KEY}}` (ex.: `[ABC-123](https://acme.atlassian.net/browse/ABC-123)`); for `tool: "linear"`, `{{url}}/issue/{{KEY}}`; other trackers follow their own convention. Never write the key as plain text. Applies ao resumo executivo, bullets de tópicos, ações, entregas, riscos e decisões. When `tools.tracker.url` is missing from `config.json`, set `STATUS: WARN`, deixe as chaves como texto puro e sinalize no summary pedindo pro usuário rodar `/mgr-setup` pra completar; não invente base URL.
- Every person name that appears anywhere in the report (resumo executivo, tópicos, ações, riscos, decisões) MUST be rendered as a wikilink-style markdown link to the matching Person note, relative to the report's folder: `[Nome da Pessoa](../../people/Nome da Pessoa.md)` (the report lives in `WS/reports/{{YYYY-MM}}/`, people in `WS/people/`). When a Person note does not exist for that name, still write the link with the expected path — the reader will follow it and create the note if needed. Applies to both cited names and default accountables (still include the "(padrão)" suffix outside the link).
- No customer names, personal data or document numbers in the report.
- Report work, not people's states of mind. Never write what someone feels, believes, fears or how confident they are ("sem confiança na entrega", "está preocupado", "acha que não dá"), even when a source quotes it. Write the work fact behind it (a date at risk, a scope still undefined) only when the source states that fact.
- Links never use angle brackets (`[x](<...>)`). A note inside the user's Obsidian vault is linked as a wikilink with its file name, `[[Nome da nota|descrição]]`; any other local file is a markdown link with spaces encoded as `%20`.
- A person's report is about the work that person answers for: topics, deliveries, blockers, decisions. Never about conduct, tone, hours or availability, even when a source mentions them. Direct messages are never a source. The summary of a person's report ends with one line saying it lives in the manager's workspace and is not meant to be shared.
- Engineering mechanics are not actions. Pull requests, merge requests, code reviews, commits, branches, pipelines and deploy notices never appear as an action, pending item, risk or next step, whatever the source. They may only support a delivery statement about the work item they belong to ("ABC-123 entregue [F4]"), never stand on their own. When a source's whole content is a PR or MR, drop it.
- Tracker, messenger and meeting tools are read only by the sub-agents, only with the brief from `evidence.md`. The one thing this skill reads itself is material the user hands over in `--update` (a file path or pasted text).
- Never rewrite an existing note or report. Reports are new files; topic notes receive edits in the fields and sections named below. The only edits to an existing report are `--update`, which adds to it and never regenerates it, and Step 4.5, which moves the open items out of the previous report's `#### Ações e Pendências`.

## Step 1 — Read the request

`$ARGUMENTS` is free text; flags and prose mean the same thing. Resolve:

- **Subject**: match the name against `WS/teams/*.md`, `WS/forums/*.md` and `WS/people/*.md` with `tracked: true`. A type word in the request ("time", "fórum", "pessoa") narrows the match. One subject in the workspace and none named: use it. Ambiguous, or a person named who is not `tracked`: ask in `--interactive`, otherwise `BLOCKED` listing the subjects by type (and pointing to `/mgr-setup --person` for the untracked person).
- **Period**: whatever the user declared with days or dates. Nothing declared: the last 7 days ending today. Print the resolved dates in the summary so the user can rerun if they meant otherwise. Never ask.
- **Sources**: tracker, messenger and meetings unless the user narrowed them.
- **Interactive**: only when asked for.
- **Update**: `--update`, or prose asking to update an existing report with new information ("atualiza o report do time X com esse transcript"). Go to [Update mode](#update-mode) instead of Steps 2-5.

## Step 2 — Load workspace context

Read what the workspace already knows and nothing more: `WS/AGENTS.md` (what matters this period, conventions such as which tracker column means done, registered channels); the subject note (board if any, people - PM and Tech Lead, or facilitator and members, or the person and her team - the `topics` frontmatter list, `## Fontes relacionadas` and `## Arquivos e assets`: channels, meetings and files that every report of this subject consults); the subject's topics (every `WS/topics/*.md` whose wikilink appears in the subject's `topics` frontmatter list - read the frontmatter, `## Fontes relacionadas`, `## Arquivos e assets`, current `status`; a topic may also appear in other subjects' `topics`, that is expected); the newest previous report of the subject, searched across every `WS/reports/*/` folder (frontmatter, farol table AND every `#### Ações e Pendências` block from each topic — specifically the `- [ ]` items that were left open, keeping the original responsible, description, source link and the original date + link to the report they came from); `config.json` (`referenceFolders` and `sources`, which together are the `localFolders` where notes or transcripts may live).

Also collect, from the subject note and from `WS/people/*.md`, the **people of the subject** (team: every person whose `isPartOf` links to it, plus PM and Tech Lead; forum: facilitator and members; person: herself). This set decides what is an action of this subject and what is context from another team (`evidence.md → Pertencimento`).

The open action items (`- [ ]`) collected from the previous report are candidates to carry over into the corresponding topic's `#### Ações e Pendências` in the new report, on top of any new items identified in the current period. Each one passes the same admission test as a new item (Step 4) before it is carried; the ones that fail are listed in the summary and cancelled in the previous report by Step 4.5. Never re-include items already marked `- [x]` or `- [-]` in past reports. If an open item from the previous report is verified as completed in this period's evidence, move it in as `- [x]` with the new evidence link and keep its original `➕` date and origin report link.

A subject without topics still gets a report; the topic sections say so and point to `/mgr-setup --topic`.

## Step 3 — Gather evidence

Read `evidence.md`. Build one brief per selected source with what Step 2 found: `subject` and `subjectType`; the subject's `## Fontes relacionadas` and `## Arquivos e assets` feed the brief's `channels`, `meetings` and the head of `localFolders` (same mapping used for topics: row `Tipo` = messenger → `channels`, `Tipo` = meeting tool → `meetings`, `## Arquivos e assets` bullets → `files`); each topic's `## Fontes relacionadas` and `## Arquivos e assets` feed its own topic line the same way; `config.json` closes `localFolders`. By type: a team's brief carries its `board`; a forum's carries `board` only when it has one; a person's carries the board of her team (`isPartOf`) plus `assignee: {{her name}}`. Invoke, in parallel, one call each with the brief as the prompt: `eis-manager-assistant:source-tracker` (skip when there is no board or its key is `TBD`, and say so), `eis-manager-assistant:source-messenger`, `eis-manager-assistant:source-meetings`.

Merge what comes back. Drop items without a source. A source whose connector was absent is "not consulted", not "no news". One pass; do not go back for more.

## Step 3.5 — Recheck the open items at their source

First run the admission test of Step 4 on every open item of the previous report; the ones that fail are not rechecked (they will be cancelled by Step 4.5), which keeps the recheck short. Every `- [ ]` that passes and whose inline source link points to a tool a sub-agent owns is rechecked **at that link**, not only through the period sweep. Group them by tool (messenger permalink → `source-messenger`; issue URL or key → `source-tracker`; meeting page → `source-meetings`), build one `mode: recheck` brief per tool in the shape of `evidence.md → Recheck brief` (one `items:` entry per open item, with `what`, `source` and the date it was first recorded) and invoke those sub-agents in parallel, once. Items whose source is a local file the session can read are rechecked by reading the file. Items with no link are not rechecked.

Apply what comes back when writing the item in `#### Ações e Pendências`:

- `resolved`: write the item as `- [x]`, keeping the original responsible, description, original source link, origin report link and `➕` date, append ` ✅ {{date}}` (the date of the follow-up that resolved it) at the very end of the line, and add one sub-bullet below it: `  - {{date}}: {{one sentence from the recheck}} ([fonte](url))`, with any person name linked.
- `updated`: the item stays `- [ ]` and gets one sub-bullet: `  - {{date}}: {{one sentence}} ([fonte](url))`.
- `unchanged`: the item stays `- [ ]` with no sub-bullet.
- `unreachable`: the item stays `- [ ]` with a sub-bullet `  - {{today}}: não foi possível verificar na fonte ({{reason}})`, and `STATUS: WARN`.

Sub-bullets carried from the previous report stay as they are; new ones go below them, oldest first. A sub-bullet is the only place an update goes: never paste "(atualizado ...)" or any other update into the item's own line.

A recheck never creates a new item, never changes an item's wording and never reopens an item already `- [x]`. A `resolved` recheck that is also a delivery of the period may feed `## Entregas no período` with its own source.

## Step 4 — Write the report

Read `${CLAUDE_PLUGIN_ROOT}/skills/mgr-status-report/templates/Report.md` and fill it: `WS/reports/{{YYYY-MM of today}}/Report - {{Subject Name}} - {{periodEnd}}.md`. The month folder is the month the report is created (`created`, today), not the month of the period; create it when it does not exist. Suffix `-2`, `-3` when a report with that name already exists in any `WS/reports/*/` folder. Links to the previous report and to the reports where carried-over action items came from point to the month folder where each of those reports actually is (`../{{YYYY-MM}}/Report - ....md`). `owner` in the frontmatter is the wikilink to the subject from Step 1; the subject type is not written, it follows from the folder of the owner note (`teams/`, `forums/`, `people/`). Apply the farol rule from `evidence.md` per topic (evidence from people of other subjects counts for the farol, since it is about the topic, but never as an action of this subject). Apply `evidence.md → Pertencimento` to every fact before placing it, and the Step 3.5 rechecks to every carried-over item. Every section of the template is present; a section with nothing says "Nenhum identificado nas fontes consultadas". `topic: unknown` and `topic: subject` evidence goes to the subject-level sections. Frontmatter lists are `[]` when empty; `previousReport` is omitted on the first report. No placeholder survives.

### What enters `#### Ações e Pendências`

Few items, each one something a person has to deliver. A new item, or one carried from the previous report, enters only when **all** of these hold:

1. **Owner named by the source**: the evidence's `who:`, or the assignee for a tracker item. No `(padrão)` here.
2. **Something to deliver**: a concrete result someone committed to or was given (a plan, an analysis, a fix outside the tracker, a contract, a definition with a date). Not a state, not a wish.
3. **Of this subject**: the owner is one of the people of the subject (`evidence.md → Pertencimento`). An owner from another subject makes it context `(via {{Outro Time}})`, never an action here.
4. **Not one of these**, whatever the source:
   - tracker housekeeping: assign, triage, prioritize, move, estimate, update a card or its date, create a story;
   - communicate, inform, notify, reply, answer, align, ask, follow up, "cobrar";
   - a message, comment or mention in a thread that nobody turned into a commitment;
   - a decision (goes to `## Decisões e pendências` or Avanços, never as `- [x]`);
   - an alert, a "sem mudança" state, a PR/MR or any engineering mechanic.
5. **A tracker issue is an action only when** it is in a doing status (the workspace's execution statuses, e.g. In Progress, Coding Review, Testing, Validation; never Ready to Dev, Backlog, Icebox or any waiting status), has an assignee, is not flagged, and matters for the topic: it — or its parent or an issue it blocks (`tracker:` field) — has priority High or above and is due within the next 3 days. The line names the issue, why it is there ("High, vence {{DD/MM}}" or "bloqueia [KEY](url), High, vence {{DD/MM}}") and its assignee as owner. Any other tracker issue goes to Avanços, Riscos e bloqueios or `## Entregas no período`, never here.

**Blocked tracker items become one single item per topic**, never one item each: `- [ ] [{{Tech Lead}}](../../people/{{Tech Lead}}.md) - Hoje existem {{N}} tasks bloqueadas: [KEY](url), [KEY](url), ... ➕ {{today}}`, owned by the subject's Tech Lead (facilitator for a forum, the person herself for a person). It lists every flagged open item of the topic the tracker returned, whatever its status. It is rebuilt in every report and never carried: Step 4.5 removes the previous one like a migrated item. A topic with no blocked item has no such line. The blocked items do not repeat in Riscos e bloqueios.

What fails the test goes where it belongs: a stalled state → **Riscos e bloqueios**; a decision → **Avanços** or `## Decisões e pendências`; a next step without owner → **Próximos passos** with the default accountable; anything else is left out.

**One fact, one item.** Before adding an item, compare it with the carried ones of the same topic: same source (permalink, thread, issue, meeting) or same deliverable means it is the same item, and the new fact becomes a dated sub-bullet of it. Two candidates from the same thread or meeting about the same deliverable are one item. Never nest a `- [ ]` under another. A fact that became an action is not repeated in **Próximos passos** of the same topic.

**Line format** (template has the canonical shape; it follows the Obsidian Tasks emoji format, so the dates stay plain at the end of the line):

- `- [ ] [{{Nome}}](../../people/{{Nome}}.md) - {{descrição}} ([fonte](url)) ➕ {{YYYY-MM-DD}}` for an item first recorded in this report; `➕` is the date of the evidence.
- A carried item keeps its original `➕` date and adds `- [origem](../{{YYYY-MM}}/Report - {{Subject Name}} - {{YYYY-MM-DD}}.md)` before it, pointing to the report where it first appeared.
- A done item ends with ` ✅ {{YYYY-MM-DD}}`, the date it was resolved.
- Lines start at column 0 (`- [ ]`, no leading spaces); sub-bullets are indented by two spaces and read `  - {{YYYY-MM-DD}}: {{fato}} ([fonte](url))`.
- A carried item written in an older format is normalized without changing its words: `- [{{date}}](link)` at the end becomes `- [origem](link) ➕ {{date}}`; each `(atualizado DD/MM: ...)` or `(concluído DD/MM: ...)` inside the line becomes a sub-bullet `  - {{YYYY-MM-DD}}: ...` (year of the report it came from); `Atualização em {{date}}:` and `Resolvido em {{date}}:` become `{{date}}:`; a `- [x]` gets ` ✅ {{date}}` when it lacks one.

## Step 4.5 — Move the open items out of the previous report

Only after the new report is written, and only in a normal run (never in `--update`). Edit the previous report read in Step 2, inside each `#### Ações e Pendências` block and nowhere else:

- Delete every `- [ ]` that was carried into the new report (whether it is still open or became `- [x]` there), together with its sub-bullets, and the previous "Hoje existem N tasks bloqueadas" line (counted as moved).
- Every `- [ ]` that failed the admission test becomes `- [-]` with ` ❌ {{today}}` at the end of the line (cancelled in the Obsidian Tasks format), so it stays on record but no longer counts as open.
- Keep every `- [x]` and `- [-]` as it is.
- Right after the block's list, add one line when at least one item was moved from that block: `{{N}} tarefas não feitas migradas para [Report - {{Subject Name}} - {{periodEnd}}](../{{YYYY-MM}}/Report - {{Subject Name}} - {{periodEnd}}.md)`, with the path relative to the previous report's folder. When the block had only items to move, the line stands alone under the heading.

Touch nothing else in the previous report (frontmatter, other sections, wording). If the edit fails, say so in the summary with `STATUS: WARN`; the new report stays as written.

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

- Add the new facts to the topic sections, deliveries, risks, decisions and `#### Ações e Pendências` where they belong. `topic: unknown` and `topic: subject` go to the subject-level sections. In a topic's Avanços, Riscos e bloqueios and Próximos passos, put each fact under the `**YYYY-MM-DD**` group of its date (create the group in date order, newest first), as the template says.
- New items in `#### Ações e Pendências` pass the admission test of Step 4 and use its line format. An open `- [ ]` that the new evidence shows done becomes `- [x]` with ` ✅ {{date}}` at the end of the line, keeping its original `➕` date and origin link, plus the `  - {{date}}: ...` sub-bullet of Step 3.5. New material that only moves an item forward adds a `  - {{date}}: ...` sub-bullet and leaves it `- [ ]`; never write the update inside the item's line. `--update` does not run Step 3.5 rechecks on its own; it only applies what the user handed over.
- An item in `## Não verificado` that the new material now sources moves to its section with the link.
- Re-apply the farol rule to each topic that got new evidence, counting old and new evidence together; update its row in `## Farol por tópico`. The "Por quê" cell is **replaced** by one sentence that explains the current farol with its source, never appended to ("Atualizado DD/MM: ..." chains are not allowed).
- Update `## Resumo executivo` only if the new facts change what leadership needs to know; still up to 100 words, every item sourced.
- Append the new sources to `## Fontes consultadas`, and remove from "Fontes não consultadas" whatever is now consulted.
- Frontmatter: add `updated: {{today}}` (replace the date if the field exists); add new topics to `topics`. Sources, including files or text the user handed over, are recorded only in `## Fontes consultadas`, never in the frontmatter.

Never delete or reword a fact that already has a source. When the new material contradicts one, keep both, each with its source and date, and list the contradiction in the summary. Never change `name`, `owner`, `periodStart`, `periodEnd`, `created`, `previousReport` or the file name.

**Topic notes.** For each topic whose farol changed, append one entry under `### {{periodEnd}}` in its `## Status`, same shape as Step 5, with `- **Report**: [[Report - {{Subject Name}} - {{periodEnd}}]] (atualizado em {{today}})`, and update the frontmatter `status` with the same confirmation rule as Step 5. Topics whose farol did not change are not touched.

## Summary

`STATUS: OK | WARN | BLOCKED` first. `WARN` when a source was not consulted, a topic had no evidence, evidence was cut, a farol changed silently, an open item could not be rechecked at its source, or the subject has no board (`TBD`). Then, briefly: report path, period, sources consulted and skipped with reasons, farol changes, items in `## Não verificado`, the open items carried over and the ones cancelled by the admission test (each with one line saying why and where its fact went), the previous report edited by Step 4.5, and the natural next step.

In update mode the summary is an update report, in the chat, with these blocks in this order (a block with nothing says "nenhum"). Every line names the section or note it refers to and carries the source link:

1. **Report atualizado**: path, and the material received (files, links, text) with what was consulted and what was not, and why.
2. **Modificado**: facts added, per report section; items moved out of `## Não verificado`; executive summary adjusted or not; frontmatter fields changed.
3. **Marcado como concluído**: every `- [ ]` flipped to `- [x]`, with its accountable and the new source. In a normal run, this block also lists the Step 3.5 rechecks: items closed at the source, items that only got an update, and items that could not be verified, each with the link.
4. **Farol**: every topic whose farol changed (previous → new, reason), in the report and in the topic note, and whether it was applied without confirmation.
5. **Contradições**: each fact of the new material that conflicts with one already in the report, both sides with their sources and dates. The skill does not decide which one is right.
6. **Atualizar manualmente**: what the new material says but this skill cannot or must not write, each with where it should go and the command when there is one. For example: a fact that fits no topic of the subject (`/mgr-topic --add`); a change of deadline, scope or description of a topic (`dueDate`, `description`, `## Contexto` are never edited here); a new person or source for the subject (`/mgr-setup --person`, `/mgr-setup --source`); pasted text that needs a link to leave `## Não verificado`; a contradiction the user must resolve in the report.

## Never

- Ask anything outside `--interactive`, including the period, the language or the sources.
- Read a tracker, messenger or meeting tool yourself, or send note bodies and previous reports to a sub-agent.
- Write a factual sentence without an inline source link, or fall back to the old `[Fn]` marker format.
- Write a person's name in the report without wrapping it as `[Nome](../../people/Nome.md)`.
- Write a tracker key (`ABC-123`, `PROJ-42`) as plain text — always link to the item URL.
- Turn evidence about a person of another subject into an action, pending item, risk, decision or next step of this report.
- Mark an item `- [x]` from a recheck that is not `resolved`, reopen an item already `- [x]`, or reword a carried-over item.
- Report on more than one subject in one run, or create tasks, stories or specs.
- Put in `#### Ações e Pendências` an item with a `(padrão)` owner, tracker housekeeping, a "communicate/reply/align" item, a decision or a plain thread message; add a second item for a deliverable already listed; write an update inside an item's line instead of a dated sub-bullet.
- Overwrite or regenerate a report (`--update` only adds to it; Step 4.5 only moves open items out of the previous one), rewrite a note, or change a topic's `description`, `id`, `created`, `dueDate` or `isPartOf`.
- Write outside `WS` and `config.json`, or inside `${CLAUDE_PLUGIN_ROOT}`.
