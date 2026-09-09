# Data model: associative notes

State is a flat set of Markdown notes per workspace. Relationships live in YAML frontmatter as wikilinks, not in folder structure. Never create nested folders such as `teams/<team>/topics/`.

## Workspace folder

```
DATA_ROOT/workspaces/<workspace-slug>/
  AGENTS.md                  workspace narrative (company, context, what matters)
  CLAUDE.md                  one line pointing to AGENTS.md
  Team - <Team Name>.md
  Topic - <Topic Name> - <Team Name>.md   team = teamOwner; the suffix keeps same-named topics of different teams apart
  Person - <Person Name>.md
  Report - <Team Name> - <YYYY-MM-DD>.md   written by mgr-status-report, never overwritten
  memory/                    defined in a later slice
```

Folder names: kebab-case. File names: `<Type> - <Name>.md`, Title Case, type prefix mandatory. Topics and reports carry a second segment (`Topic - <Name> - <Team Name>.md`, `Report - <Team Name> - <date>.md`); it is part of the file name and therefore of every wikilink to it.

## Wikilinks

`[[X]]` resolves to the file `X.md` in the same workspace folder, exactly like Obsidian. Links always carry the full file name with prefix: `"[[Team - Squad X]]"`, `"[[Person - Ana Souza]]"`, `"[[Topic - Checkout v2 - Squad X]]"`. Never resolve by the `name` field, never infer a prefix. A link to a file that does not exist is a label; do not fail on it. `isPartOf` on a team points to the workspace, which has no note, so it is always a label.

## Frontmatter

Templates with the full body live inside the skill that creates the note: `${CLAUDE_PLUGIN_ROOT}/skills/mgr-setup/templates/` (`AGENTS.md`, `CLAUDE.md`, `Team.md`, `Topic.md`, `Person.md`) and `${CLAUDE_PLUGIN_ROOT}/skills/mgr-status-report/templates/Report.md`. Always create notes from them. `description` is at most 350 characters. Dates are `YYYY-MM-DD`. A field whose value is not yet known holds the literal `TBD`; on a topic, `status` and `dueDate` start as `TBD` and are set by the report skills or by the user.

**Person** (`Person - <Name>.md`)

```yaml
name: "Ana Souza"
type: person
role: Product Manager        # Product Manager | Tech Lead | Head of Product | Head of Tech | Developer | Designer | Delivery Manager
isPartOf: "[[Team - Squad X]]"
description: "..."
```

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

**Topic** (`Topic - <Name> - <Team Name>.md`, team = the `teamOwner` team; `name` holds only the topic name)

```yaml
name: "Checkout v2"
type: topic
status: on_track             # on_track | in_risk | problem
teamOwner: "[[Team - Squad X]]"
maintainer: "[[Person - Ana Souza]]"
isPartOf: "[[Topic - Parent - Squad X]]"   # full file name of the parent, including its owner team; omit when there is no parent
description: "..."
relatedTeam:
  - "[[Team - Squad Y]]"       # empty list when none
created: 2026-09-01
dueDate: 2026-12-15
```

**Report** (`Report - <Team Name> - <YYYY-MM-DD>.md`, date = `periodEnd`)

```yaml
name: "Squad X - 2026-09-08"
type: report
reportType: team-status
team: "[[Team - Squad X]]"
periodStart: 2026-09-02
periodEnd: 2026-09-08
generated: 2026-09-08
topics:
  - "[[Topic - Checkout v2 - Squad X]]"
sourcesConsulted: [tracker, messenger]
sourcesSkipped: [meetings]
previousReport: "[[Report - Squad X - 2026-09-01]]"   # omit on the first report
```

## Body sections

Fixed H2 headings, in this order, so any agent can extract by heading.

- **Team**: `## Sobre`, `## Pessoas e papéis` (table: Nome, Role, Descrição), `## Topics` (table: Nome, Link, Descrição; only topics where this team is `teamOwner`), `## Fontes` (same three subsections as Topic; consulted in every report of the team).
- **Topic**: `## Contexto`, `## Status atual` (farol, up to 100 words, link to last report), `## Fontes` (`### Canais` table Nome/URL, `### Reuniões e transcrições` - one meeting per bullet with the places where it can be found nested under it, `### Arquivos`), `## Reports`.
- **Person**: frontmatter only for now.
- **Report**: `## Resumo executivo`, `## Farol por tópico` (table), `## Por tópico` (one `###` per topic), `## Entregas no período` (table), `## Riscos e pontos de atenção`, `## Decisões e pendências`, `## Fontes consultadas` (table `Ref | Tipo | Fonte | Data`), `## Não verificado`. Every factual sentence ends with `[Fn]`, a row of `## Fontes consultadas`. Evidence contract in `evidence.md`.

Everything that is not an identifier (channels, meetings, docs, links) goes in the body, never in frontmatter.

## Editing rules

- Skills that update a note edit only the target section or field. Never rewrite a whole existing note.
- Adding a topic also appends a row to the owner team's `## Topics` table.
- Adding a person listed in a team's `## Pessoas e papéis` also creates `Person - <Name>.md` if missing.
- Writing a report touches a topic note in three places only: frontmatter `status`, the `Farol`, `Descrição` and `Último report` lines of `## Status atual`, and one appended line in `## Reports`. On a team note it may only append rows or lines under `## Fontes` (what the sub-agents learned). Reports themselves are never edited after creation; a rerun on the same day creates `... - <date>-2.md`.
- Latest report of a team: the `Report - <Team Name> - *.md` with the greatest date in the file name.

## Inferences

- Topics of a team: every `Topic - * - <Team Name>.md`; `teamOwner` must agree with the suffix.
- People of a team: every `Person - *.md` whose `isPartOf` links to it.
- Teams involved in a topic: `teamOwner` plus `relatedTeam`.
- Project tree: `isPartOf` between topics.

Section headings are in Portuguese by design; they are stable identifiers and are never translated, whatever language the user writes in.
