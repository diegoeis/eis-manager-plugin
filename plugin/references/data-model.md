# Data model: associative notes

State is a flat set of Markdown notes per workspace. Relationships live in YAML frontmatter as wikilinks, not in folder structure. Never create nested folders such as `teams/<team>/topics/`.

## Workspace folder

```
DATA_ROOT/workspaces/<workspace-slug>/
  AGENTS.md                  workspace narrative (company, context, what matters)
  CLAUDE.md                  one line pointing to AGENTS.md
  Team - <Team Name>.md
  Forum - <Forum Name>.md
  Person - <Person Name>.md
  Topic - <Topic Name>.md    name only, no owner suffix; a topic is not owned by one subject and can relate to several teams, forums or people
  Report - <Subject Name> - <YYYY-MM-DD>.md written by mgr-status-report, never overwritten
  memory/                    defined in a later slice
```

Folder names: kebab-case. File names: `<Type> - <Name>.md`, Title Case, type prefix mandatory. A report carries a second segment (`Report - <Subject Name> - <date>.md`); it is part of the file name and therefore of every wikilink to it. A topic's file name is only `Topic - <Name>.md` — never a subject suffix, since a topic can relate to several teams, forums or people at once. Topic names must be unique per workspace; a new topic that reuses an existing name is the same topic (add the new subject to its `relatedTeam`/`relatedForum`/`relatedPerson` instead of creating a second file).

## Subjects

A **subject** is anything that owns topics, carries sources and receives status reports: a `Team`, a `Forum` (a recurring decision or alignment meeting with participants, not a team) or a `Person` (a direct report the user follows individually; `tracked: true`). The three share the same body sections `## Topics` and `## Fontes`, so `mgr-status-report` treats them alike; what differs is listed per type below.

## Wikilinks

`[[X]]` resolves to the file `X.md` in the same workspace folder, exactly like Obsidian. Links always carry the full file name with prefix: `"[[Team - Squad X]]"`, `"[[Forum - Comitê de Produto]]"`, `"[[Person - Ana Souza]]"`, `"[[Topic - Checkout v2]]"`. Never resolve by the `name` field, never infer a prefix. A link to a file that does not exist is a label; do not fail on it. `isPartOf` on a team or forum points to the workspace, which has no note, so it is always a label.

## Frontmatter

Templates with the full body live inside the skill that creates the note: `${CLAUDE_PLUGIN_ROOT}/skills/mgr-setup/templates/` (`AGENTS.md`, `CLAUDE.md`, `Team.md`, `Forum.md`, `Person.md`, `Topic.md`) and `${CLAUDE_PLUGIN_ROOT}/skills/mgr-status-report/templates/Report.md`. Always create notes from them. `description` is at most 350 characters. Dates are `YYYY-MM-DD`. A field whose value is not yet known holds the literal `TBD`; on a topic, `status` and `dueDate` start as `TBD` and are set by the report skills or by the user.

**Person** (`Person - <Name>.md`)

```yaml
name: "Ana Souza"
type: person
role: Product Manager        # Product Manager | Tech Lead | Head of Product | Head of Tech | Developer | Designer | Delivery Manager
isPartOf: "[[Team - Squad X]]"   # omit when the person has no known team (e.g. a forum participant)
description: "..."
tracked: false               # true when the user follows this person as a subject (topics, sources, reports)
```

A person created as a team member has `tracked: false` and frontmatter only. `mgr-setup --person` sets `tracked: true` and adds the body sections. Default accountable on a person's report: the person.

**Forum** (`Forum - <Name>.md`)

```yaml
name: "Comitê de Produto"
type: forum
facilitator: "[[Person - Ana Souza]]"
members:
  - "[[Person - João Lima]]"
isPartOf: "[[Workspace Name]]"
description: "..."
cadence: "quinzenal"
trackerBoardKey: "TBD"       # a forum rarely has a board; TBD skips the tracker
trackerBoardUrl: "TBD"
```

Default accountable on a forum's report: the facilitator.

**Team** (`Team - <Name>.md`)

```yaml
name: "Squad X"
type: team
productManager: "[[Person - Ana Souza]]"
techLead: "[[Person - João Lima]]"
isPartOf: "[[Workspace Name]]"
description: "..."
trackerBoardKey: "ABC"
trackerBoardUrl: "https://..."
```

Default accountable on a team's report: Product Manager and Tech Lead.

**Topic** (`Topic - <Name>.md`; `name` in the frontmatter also holds only the topic name)

```yaml
name: "Checkout v2"
type: topic
status: on_track             # on_track | in_risk | problem
maintainer: "[[Person - Ana Souza]]"
isPartOf: "[[Topic - Parent]]"   # full file name of the parent topic; omit when there is no parent
description: "..."
relatedTeam:
  - "[[Team - Squad X]]"      # every team this topic touches; can be zero, one or many
  - "[[Team - Squad Y]]"
relatedForum:
  - "[[Forum - Comitê de Produto]]"   # empty list when none
relatedPerson:
  - "[[Person - João Lima]]"          # empty list when none
created: 2026-09-01
dueDate: 2026-12-15
```

A topic is never "owned" by a single subject. `relatedTeam`, `relatedForum` and `relatedPerson` are independent lists — a topic can sit in none, one or several of each — and together they are what makes the topic show up in a subject's `## Topics` table and in that subject's status reports. `maintainer` is the person accountable for the topic day to day; it is unrelated to which subjects the topic is related to.

**Report** (`Report - <Subject Name> - <YYYY-MM-DD>.md`, date = `periodEnd`)

```yaml
name: "Squad X - 2026-09-08"
type: report
reportType: status
subjectType: team            # team | person | forum
subject: "[[Team - Squad X]]"
periodStart: 2026-09-02
periodEnd: 2026-09-08
generated: 2026-09-08
topics:
  - "[[Topic - Checkout v2]]"
sourcesConsulted: [tracker, messenger]
sourcesSkipped: [meetings]
previousReport: "[[Report - Squad X - 2026-09-01]]"   # omit on the first report
```

## Body sections

Fixed H2 headings, in this order, so any agent can extract by heading.

- **Team**: `## Sobre`, `## Pessoas e papéis` (table: Nome, Role, Descrição), `## Topics` (table: Nome, Link, Descrição; every topic whose `relatedTeam` includes this team), `## Fontes` (same three subsections as Topic; consulted in every report of the team).
- **Forum**: `## Sobre`, `## Participantes` (table: Nome, Papel no fórum, Descrição), `## Topics` (every topic whose `relatedForum` includes this forum), `## Fontes` (as Team).
- **Person** with `tracked: true`: `## Sobre`, `## Topics` (every topic whose `relatedPerson` includes this person), `## Fontes` (as Team). Direct messages are never a source; the user's own 1:1 notes enter through `### Arquivos`.
- **Topic**: `## Contexto`, `## Status atual` (farol, up to 100 words, link to last report), `## Fontes` (`### Canais` table Nome/URL, `### Reuniões e transcrições` - one meeting per bullet with the places where it can be found nested under it, `### Arquivos`), `## Reports`.
- **Report**: `## Resumo executivo`, `## Farol por tópico` (table), `## Por tópico` (one `###` per topic), `## Entregas no período` (table), `## Riscos e pontos de atenção`, `## Decisões e pendências`, `## Fontes consultadas` (table `Ref | Tipo | Fonte | Data`), `## Não verificado`. Every factual sentence ends with `[Fn]`, a row of `## Fontes consultadas`. Evidence contract in `evidence.md`.

Everything that is not an identifier (channels, meetings, docs, links) goes in the body, never in frontmatter.

## Editing rules

- Skills that update a note edit only the target section or field. Never rewrite a whole existing note.
- Adding a topic also appends a row to the `## Topics` table of every subject in its `relatedTeam`, `relatedForum` and `relatedPerson`.
- Adding a person listed in a team's `## Pessoas e papéis` also creates `Person - <Name>.md` if missing.
- Writing a report touches a topic note in three places only: frontmatter `status`, the `Farol`, `Descrição` and `Último report` lines of `## Status atual`, and one appended line in `## Reports`. It never touches `relatedTeam`, `relatedForum`, `relatedPerson` or `maintainer`. On a team, forum or person note it may only append rows or lines under `## Fontes` (what the sub-agents learned). Reports themselves are never edited after creation; a rerun on the same day creates `... - <date>-2.md`.
- Latest report of a subject: the `Report - <Subject Name> - *.md` with the greatest date in the file name.

## Inferences

- Topics of a subject: every `Topic - *.md` whose `relatedTeam` (team), `relatedForum` (forum) or `relatedPerson` (tracked person) links to it — read the frontmatter, never the file name.
- Subjects of the workspace: every `Team - *.md`, `Forum - *.md`, and `Person - *.md` with `tracked: true`.
- People of a team: every `Person - *.md` whose `isPartOf` links to it. A person without `isPartOf` belongs to no team (forum participant, external).
- Teams involved in a topic: its `relatedTeam` list.
- Project tree: `isPartOf` between topics.

Section headings are in Portuguese by design; they are stable identifiers and are never translated, whatever language the user writes in.
