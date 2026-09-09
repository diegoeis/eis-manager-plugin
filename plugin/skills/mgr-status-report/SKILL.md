---
name: mgr-status-report
description: Generate a team status report for a period from the tracker, messenger and meeting tools, every fact cited, then propose updates to the topics' farol. Use when the user says "status report do time X", "gera o report da semana", "como está o time X", "relatório de acompanhamento", or runs /mgr-status-report. Arguments as flags or prose - team name (optional with one team); period ("--period 14d", "de 1 a 15 de setembro"; default last 7 days); "--sources tracker,messenger,meetings" to restrict; "--data-root /path" when no folder is connected; "--interactive" to confirm team and farol changes (default is silent - no questions). Reads sources only via the source-* sub-agents and records what it learns for the next run. Does not create tasks or specs, does not cover several teams at once, does not set up teams or topics (use mgr-setup).
allowed-tools: Read Write Edit Glob Grep Agent
---

# mgr-status-report

Produces `Report - <Team Name> - <YYYY-MM-DD>.md` in the active workspace from evidence gathered by the `source-*` sub-agents, updates each topic's farol and report links, and records what it learned about the team's sources so the next run starts from more. Facts only, each with a reference; anything without a source is marked as unverified or left out.

## Step 0 — Find existing state

The data root is where `mgr-setup` saved `config.json` (marker `"plugin": "eis-manager-assistant"`). Find it from what the user gave: a path in the request (flag or prose), or the folder connected to the session (the marker in it, in `manager-assistant/` inside it, or one level down). Do not look anywhere the user did not point to: no `~/.claude/`, no `${CLAUDE_PLUGIN_DATA}`, no parent directories.

Found: `DATA_ROOT` is its folder; `WS` is `DATA_ROOT/<workspaces.<activeWorkspace>.path>`. Not found: with `--interactive`, ask once for the path and explain why. Otherwise:

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
- Never invent. No `[Fn]`, no sentence in the body. Never guess a next step or a date.
- Every action, pending item, risk and next step names who is accountable. When the evidence names someone (`who:`), use that name. When it does not, write the team's Product Manager and Tech Lead (from the team note) marked as default, `<PM> e <Tech Lead> (padrão)`, so the reader can tell an assignment stated by the source from the team's default accountability. Never pick any other person.
- No customer names, personal data or document numbers in the report.
- Engineering mechanics are not actions. Pull requests, merge requests, code reviews, commits, branches, pipelines and deploy notices never appear as an action, pending item, risk or next step, whatever the source. They may only support a delivery statement about the work item they belong to ("ABC-123 entregue [F4]"), never stand on their own. When a source's whole content is a PR or MR, drop it.
- Sources are read only by the sub-agents, only with the brief from `evidence.md`.
- Never rewrite an existing note or report. Reports are new files; topic notes receive edits in the fields and sections named below.
- Learn as you go. Anything found about the team's sources that will be useful again - a channel, a meeting, a folder of transcripts, a board convention, a keyword that maps issues to a topic - is recorded where it belongs (topic `## Fontes`; team `## Fontes` when it concerns the team and no single topic; workspace `AGENTS.md`; `config.json → sources`) in the same run, without asking. The user should not have to hand over sources twice.

## Step 1 — Read the request

`$ARGUMENTS` is free text; flags and prose mean the same thing. Resolve:

- **Team**: match against `WS/Team - *.md`. One team in the workspace and none named: use it. Ambiguous: ask in `--interactive`, otherwise `BLOCKED` listing the teams.
- **Period**: whatever the user declared with days or dates. Nothing declared: the last 7 days ending today. Print the resolved dates in the summary so the user can rerun if they meant otherwise. Never ask.
- **Sources**: tracker, messenger and meetings unless the user narrowed them.
- **Interactive**: only when asked for.

## Step 2 — Load workspace context

Read what the workspace already knows and nothing more: `WS/AGENTS.md` (what matters this period, conventions such as which tracker column means done, registered channels); the team note (board, people, and `## Fontes`: team channels, meetings and files that every report of this team consults); the team's topics (every `Topic - * - <Team Name>.md`, checking `teamOwner` agrees - frontmatter, `## Fontes`, current farol); the newest previous report of the team (frontmatter and farol table only); `config.json` (`referenceFolders` and `sources`, which together are the `localFolders` where notes or transcripts may live).

A team without topics still gets a report; the topic sections say so and point to `/mgr-setup --topic`.

## Step 3 — Gather evidence

Read `evidence.md`. Build one brief per selected source with what Step 2 found: team `## Fontes` feeds the brief's `channels`, `meetings` and the head of `localFolders`; each topic's `## Fontes` feeds its own line; `config.json` closes `localFolders`. Invoke, in parallel, one call each with the brief as the prompt: `eis-manager-assistant:source-tracker` (skip when the board key is `TBD` and say so), `eis-manager-assistant:source-messenger`, `eis-manager-assistant:source-meetings`.

Merge what comes back. Drop items without a source. A source whose connector was absent is "not consulted", not "no news". One pass; do not go back for more.

Record every `learned:` line now, where it belongs.

## Step 4 — Write the report

Read `${CLAUDE_PLUGIN_ROOT}/skills/mgr-status-report/templates/Report.md` and fill it: `WS/Report - <Team Name> - <periodEnd>.md`, suffixed `-2`, `-3` if the name exists. Apply the farol rule from `evidence.md` per topic. Every section of the template is present; a section with nothing says "Nenhum identificado nas fontes consultadas". `topic: unknown` evidence goes to the team-level sections. Frontmatter lists are `[]` when empty; `previousReport` is omitted on the first report. No placeholder survives.

## Step 5 — Update topic notes

For each topic whose farol was decided (not the no-evidence case):

- `--interactive`: show topic, previous farol, proposed farol and reason; apply what the user confirms.
- Silent: apply, list every change in the summary under "Farol atualizado sem confirmação", and set `STATUS: WARN`.

Applying touches only frontmatter `status`, the `Farol`, `Descrição` (up to 100 words, with `[Fn]`) and `Último report` lines of `## Status atual`, and one appended line in `## Reports`. Topics without evidence get only the `## Reports` line.

## Summary

`STATUS: OK | WARN | BLOCKED` first. `WARN` when a source was not consulted, a topic had no evidence, evidence was cut, a farol changed silently, or the board key was `TBD`. Then, briefly: report path, period, sources consulted and skipped with reasons, farol changes, what was learned and recorded, items in `## Não verificado`, and the natural next step.

## Never

- Ask anything outside `--interactive`, including the period, the language or the sources.
- Read a tracker, messenger or meeting tool yourself, or send note bodies and previous reports to a sub-agent.
- Write a factual sentence without `[Fn]`.
- Report on more than one team in one run, or create tasks, stories or specs.
- Overwrite a report, rewrite a note, or change a topic's `dueDate`, `maintainer`, `teamOwner` or `description`.
- Write outside `WS` and `config.json`, or inside `${CLAUDE_PLUGIN_ROOT}`.
