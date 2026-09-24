# Evidence format

Shared contract between the report skills and the `source-*` sub-agents. A sub-agent reads one kind of source and returns evidence; the skill merges evidence from every source, maps it to topics and writes the report. The subject of a report is a team, a forum or a tracked person; the brief is the same for all three, and the agents do not care which it is beyond the fields below. Nothing reaches a report without passing through this format. The shape is fixed so the skill can merge blindly; how each agent gets there is up to the agent.

## Brief the skill sends to a sub-agent

Plain text. Include what the workspace knows; leave out what it does not. Never send note bodies, previous reports or the user's own commentary; the agent's job is to look at the source, not to echo the workspace.

```
subject: {{Subject Name}}
subjectType: team | forum | person
period: {{YYYY-MM-DD}}..{{YYYY-MM-DD}}
language: {{language the user is writing in}}
people: {{PM, Tech Lead, facilitator, members - names only; for a person, that person}}
topics:
  - {{Topic Name}} | keywords: {{name, aliases, epic keys}} | channels: {{...}} | meetings: {{what: where, where, ...}} | files: {{...}}
board: {{key and URL}}                          # tracker; absent when the subject has none (TBD)
assignee: {{person name}}                       # tracker, person subjects only: restrict to items assigned to or reported by them
doneStatuses / blockedStatuses: {{...}}         # tracker, when the workspace states them
channels: {{subject channels from its `## Fontes relacionadas` (rows whose `Tipo` names a messenger tool), then workspace channels}}       # messenger; never DMs
meetings: {{what: where, where, ... - from the subject's `## Fontes relacionadas` (rows whose `Tipo` names a meeting tool, grouped by `Nome`)}}  # meetings
meetingTools: {{every place listed under a meeting in the subject or its topics, or "any"}}  # meetings
localFolders: {{paths where notes or transcripts may exist}}   # meetings and local notes
```

`localFolders` is built in this order, first entries being the most specific: the subject's `## Arquivos e assets`, then each topic's `## Arquivos e assets` (also repeated on the topic's `files:`), then `config.json → sources` and `referenceFolders`. Subject-level entries carry `topic: subject` unless the note names a topic.

Every note (subject or topic) exposes sources through the same two sections: `## Fontes relacionadas` (single table Nome | URL/Link | Tipo) and `## Arquivos e assets`. Rows whose `Tipo` names a messenger tool feed `channels`; rows whose `Tipo` names a meeting tool feed `meetings` (grouped by `Nome` when several rows share a title); `## Arquivos e assets` bullets feed `files`.

`meetings` keeps each meeting with the places listed under it, as written (`Weekly do time: Granola, Pasta local /path, Google Drive {{link}}`). `meetingTools` is the set of all places; when the user registered none it is `any`.

For a person subject the evidence is about the work the person answers for: items, decisions, blockers and deliveries tied to them or their topics. Nothing about conduct, tone or availability; direct messages are never opened.

## What a sub-agent returns

Markdown, in this shape:

```
coverage:
  queried: {{what was actually looked at}}
  failed: {{what could not be looked at, and why - or "none"}}

evidence:
- id: E1
  date: YYYY-MM-DD
  type: delivery | progress | blocker | risk | decision | pending | context
  topic: {{Topic Name from the brief | subject | unknown}}
  fact: {{one sentence, factual, no interpretation}}
  who: {{person named by the source, else omit}}
  source: {{URL, issue key, permalink, meeting title + date, file path}}

learned: {{optional - things worth recording for next time: a channel, a recurring meeting, a folder, a board convention, an epic that maps to a topic}}
```

Rules that keep the report honest:

- One fact per item, and a fact is what the source states or shows, not a conclusion about it.
- `source` MUST be an openable URL — Jira/Linear issue URL, Slack message permalink, Slack channel URL, Granola/Tactiq meeting URL, Google Drive doc URL, or absolute local file path. Never a bare title like "Sync Squad X no Granola". A meeting evidence without a permalink to the meeting's page (Granola, Tactiq, Drive) is not evidence — do not return it; put the meeting in `coverage.failed` instead with the reason ("Granola meeting matched but permalink not exposed by the connector"). No URL, no item.
- `topic` only when the source names the topic, a keyword or an issue that belongs to it; otherwise `unknown`. Never by adjacency.
- Inside the period, except open blockers and overdue items still open at `periodEnd`.
- No customer names, no personal data beyond team members' names, no long copies of messages or transcripts.
- Pull requests, merge requests, code reviews, commits, pipelines and deploys are not evidence by themselves. Do not return "PR #42 aberto" or "MR aguardando review" as `pending`, `blocker` or `progress`. Return the work item they close when the source says it was delivered (`type: delivery`, source = the issue or the message announcing it); otherwise omit.
- Keep it to what a report can use, roughly a dozen or so items; when cutting, keep deliveries, blockers and decisions and say how many were left out. Empty is valid.

## How the skill uses evidence

- Every factual sentence in the report carries the evidence's `source` URL as an inline markdown link `[descrição curta](url)` — not the old `[Fn]` marker. A sentence with no item behind it goes to `## Não verificado` or is dropped. The `## Fontes consultadas` section is a consolidated list of the URLs used, not a numbered index the body points back to.
- `coverage.failed` from every agent becomes "Fontes não consultadas".
- `topic: unknown` and `topic: subject` items appear in the subject-level sections, never under a topic.
- `learned:` lines are recorded where they belong (`## Fontes relacionadas` for channels/meetings and `## Arquivos e assets` for files; on the topic when it concerns a single topic, on the subject when it concerns the subject at large; workspace `AGENTS.md`; `config.json → sources`) so the next run starts from more.

## Farol rule

Per topic, from evidence mapped to it. First match wins:

1. No evidence for the topic: the farol is not decided. Repeat the previous value (including `TBD`), reason "sem evidência no período", list the topic in `## Não verificado`, touch the topic note only to append the report link.
2. `problem`: an open blocker at `periodEnd`, or `dueDate` already past with nothing closing the topic.
3. `in_risk`: a risk or pending item nothing in the period answers, or a `dueDate` within about a month with no delivery or progress.
4. `on_track`: delivery or progress and none of the above.
5. Evidence that fits none of these (only decisions or context): keep the previous farol; if it was `TBD`, set `on_track` and say why.

`TBD` in a report's "Farol atual" comes only from case 1.
