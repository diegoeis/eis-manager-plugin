# Data model: associative notes

State is a set of Markdown notes per workspace, one folder per note type. Relationships live in YAML frontmatter as wikilinks, never in folder structure: the folder only says what type a note is. Never create folders other than the ones below (no `teams/{{team}}/topics/`, no per-subject folders).

## Workspace folder

```
DATA_ROOT/workspaces/{{workspace-slug}}/
  AGENTS.md                  workspace narrative (company, context, what matters)
  CLAUDE.md                  one line pointing to AGENTS.md
  teams/
    {{Team Name}}.md
  forums/
    {{Forum Name}}.md
  people/
    {{Person Name}}.md
  topics/
    {{Topic Name}}.md          a topic is a shared subject and can be linked from several teams, forums or people
  reports/
    {{YYYY-MM}}/               month the report was generated
      Report - {{Subject Name}} - {{YYYY-MM-DD}}.md   written by mgr-status-report, never overwritten; `--update` adds to it in place
  memory/                    defined in a later slice
```

`WS` is the workspace folder. The folder is what says a note's type (the frontmatter `type` repeats it):

| Type | Folder | File name |
| --- | --- | --- |
| team | `WS/teams/` | `{{Name}}.md` |
| forum | `WS/forums/` | `{{Name}}.md` |
| person | `WS/people/` | `{{Name}}.md` |
| topic | `WS/topics/` | `{{Name}}.md` |
| report | `WS/reports/{{YYYY-MM}}/`, where `{{YYYY-MM}}` is the month of `created` (the day the report was written), whatever the period it covers | `Report - {{Subject Name}} - {{YYYY-MM-DD}}.md`, date = `periodEnd` |

`reports/` is the only folder with subfolders, one per month. The type folders are flat. A skill that writes a note creates its folder when it does not exist yet. Folder names: kebab-case.

File names are the note's `name`, exactly, in Title Case, with no type prefix; the H1 title of the note is the same name. Only reports keep a prefix and a date segment (`Report - {{Subject Name}} - {{date}}.md`), which is part of the file name and therefore of every wikilink to it. A topic's file name never carries a subject suffix.

Names are unique across the workspace: no two notes in `teams/`, `forums/`, `people/` and `topics/` share a name, because a wikilink carries no folder. A new topic that reuses an existing topic name is the same topic (add its wikilink to the new subject's `topics` list instead of creating a second file). Any other clash (a topic named like a team, two people with the same name) is not created: ask for a distinct name in an interactive run, stop with `STATUS: BLOCKED` naming the existing note otherwise.

### Workspaces created before 0.3.0

Up to plugin version 0.2.x every note lived directly in `WS` with a type prefix (`Team - X.md`, `Topic - X.md`) and wikilinks carried it (`[[Team - X]]`). A workspace with prefixed notes at its root is a legacy workspace: `mgr-setup` migrates it (see its Step 0), including the workspace `AGENTS.md` (intro paragraph and wikilinks) and `CLAUDE.md`; it also fixes those two on their own when the notes were already moved but they still describe the old layout. Every other skill that finds such notes stops with `STATUS: BLOCKED` and asks the user to run `/mgr-setup` once.

## Subjects

A **subject** is anything that owns topics, carries sources and receives status reports: a team, a forum (a recurring decision or alignment meeting with participants, not a team) or a person (a direct report the user follows individually; `tracked: true`). The three share the same body sections `## Topics` and `## Fontes`, so `mgr-status-report` treats them alike; what differs is listed per type below. **The subject owns its topic list**: every subject note has a `topics: [...]` list in its frontmatter (source of truth for programmatic reads) and a `## Topics` table in the body (for human reading). A topic note never lists its subjects — the relation lives on the subject side.

## Wikilinks

`[[X]]` resolves to the note `X.md` in the workspace, exactly like Obsidian (which resolves by file name, whatever the folder): look for it in `teams/`, `forums/`, `people/` and `topics/`, or, for `[[Report - ...]]`, in `reports/*/`. Wikilinks carry the file name only, never a folder or a type prefix: `"[[Squad X]]"`, `"[[Comitê de Produto]]"`, `"[[Ana Souza]]"`, `"[[Checkout v2]]"`, `"[[Report - Squad X - 2026-09-08]]"`. The type of the target is the folder where it was found. Never resolve by the `name` field alone. A link to a file that does not exist is a label; do not fail on it. `isPartOf` on a team or forum points to the workspace, which has no note, so it is always a label.

Markdown links to a person (`[Nome](...)`, used in reports and in topic `## Status` descriptions so names are clickable outside Obsidian too) are relative to the note that contains them: from a report, `[Nome](../../people/Nome.md)`; from a topic, `[Nome](../people/Nome.md)`. A markdown link from a report to another report points to the month folder where that report actually is: `[YYYY-MM-DD](../{{YYYY-MM}}/Report - {{Subject Name}} - {{YYYY-MM-DD}}.md)`.

## Frontmatter

Templates with the full body live inside the skill that creates the note: `${CLAUDE_PLUGIN_ROOT}/skills/mgr-setup/templates/` (`AGENTS.md`, `CLAUDE.md`, `Team.md`, `Forum.md`, `Person.md`, `Topic.md`) and `${CLAUDE_PLUGIN_ROOT}/skills/mgr-status-report/templates/Report.md`. Always create notes from them. `description` is at most 350 characters. Dates are `YYYY-MM-DD`. A field whose value is not yet known and is required holds the literal `TBD`.

**Person** (`people/{{Name}}.md`)

```yaml
name: "Ana Souza"
type: person
role: Product Manager        # Product Manager | Tech Lead | Head of Product | Head of Tech | Developer | Designer | Delivery Manager
isPartOf: "[[Squad X]]"   # omit when the person has no known team (e.g. a forum participant)
description: "..."
tracked: false               # true when the user follows this person as a subject (topics, sources, reports)
topics: []                   # only when tracked: true; wikilinks of every topics/*.md the person answers for
```

A person created as a team member has `tracked: false` and no `topics` field. `mgr-setup --person` sets `tracked: true`, initializes `topics: []` and adds the body sections. Default accountable on a person's report: the person.

**Forum** (`forums/{{Name}}.md`)

```yaml
name: "Comitê de Produto"
type: forum
facilitator: "[[Ana Souza]]"
members:
  - "[[João Lima]]"
isPartOf: "[[Workspace Name]]"
description: "..."
cadence: "quinzenal"
trackerBoardKey: "TBD"       # a forum rarely has a board; TBD skips the tracker
trackerBoardUrl: "TBD"
topics: []                   # wikilinks of every topics/*.md handled by this forum
```

Default accountable on a forum's report: the facilitator.

**Team** (`teams/{{Name}}.md`)

```yaml
name: "Squad X"
type: team
productManager: "[[Ana Souza]]"
techLead: "[[João Lima]]"
isPartOf: "[[Workspace Name]]"
description: "..."
trackerBoardKey: "ABC"
trackerBoardUrl: "https://..."
topics: []                   # wikilinks of every topics/*.md this team works on
```

Default accountable on a team's report: Product Manager and Tech Lead.

**Topic** (`topics/{{Name}}.md`)

```yaml
type: topic
name: "Checkout v2"
id: checkout-v2              # slug of name (lowercase, hyphenated)
status: on_track             # on_track | in_risk | problem | TBD
description: "..."
created: 2026-09-01
# Optional, only when explicitly requested by the user:
# isPartOf: "[[Parent Topic]]"
# dueDate: 2026-12-15
```

A topic has **no** back-reference to teams, forums or people, and **no** maintainer. Which subjects a topic belongs to is inferred from every subject whose `topics` list contains this topic's wikilink. `id` is the slug of `name` (lowercase, non-alphanumeric replaced with `-`, trimmed). `isPartOf` and `dueDate` are added only when the user asks for them; do not initialize them as `TBD`.

**Report** (`reports/{{YYYY-MM of created}}/Report - {{Subject Name}} - {{YYYY-MM-DD}}.md`, date = `periodEnd`)

```yaml
name: "Squad X - 2026-09-08"
type: report
owner: "[[Squad X]]"          # the subject; its type follows from the owner note's folder
periodStart: 2026-09-02
periodEnd: 2026-09-08
created: 2026-09-08
topics:
  - "[[Checkout v2]]"
previousReport: "[[Report - Squad X - 2026-09-01]]"   # omit on the first report
updated: 2026-09-10          # only after `mgr-status-report --update`; date of the last update
```

## Body sections

Fixed H2 headings, in this order, so any agent can extract by heading.

Every subject (Team, Forum, tracked Person) and every Topic share the same two source sections: `## Fontes relacionadas` (single table Nome | URL/Link | Tipo) and `## Arquivos e assets` (public bullet list plus a "locais e privados" bullet list). Subject and topic Fontes are added together in every report brief; the topic-specific line still filters by topic, the subject-level line covers channels/meetings/files that concern the whole subject.

- **Team**: `## Sobre`, `## Pessoas e papéis` (table: Nome, Role, Descrição), `## Topics` (table: Nome, Link, Descrição; one row per wikilink in the `topics` frontmatter list — the two are kept in sync), `## Fontes relacionadas`, `## Arquivos e assets`.
- **Forum**: `## Sobre`, `## Participantes` (table: Nome, Papel no fórum, Descrição), `## Topics` (mirrors `topics`), `## Fontes relacionadas`, `## Arquivos e assets`.
- **Person** with `tracked: true`: `## Sobre`, `## Topics` (mirrors `topics`), `## Fontes relacionadas`, `## Arquivos e assets`. Direct messages are never a source; the user's own 1:1 notes enter through `## Arquivos e assets` (locais e privados).
- **Topic**: `## Contexto`, `## Status` (one `### YYYY-MM-DD` subsection per day a report touched the topic; inside each day, one bullet per report of that day with **Report** link, **Farol** and **Descrição**), `## Fontes relacionadas`, `## Arquivos e assets`.
- **Report**: `## Resumo executivo`, `## Farol por tópico` (table), `## Tópicos e temas` (one `###` per topic, with `#### Ações e Pendências` inside), `## Entregas no período` (table), `## Riscos e pontos de atenção`, `## Decisões e pendências`, `## Fontes consultadas` (table `Ref | Tipo | Fonte | Data`), `## Não verificado`. Every factual sentence ends with `[Fn]`, a row of `## Fontes consultadas`. Evidence contract in `evidence.md`.

Everything that is not an identifier (channels, meetings, docs, links) goes in the body, never in frontmatter.

## Editing rules

- Skills that update a note edit only the target section or field. Never rewrite a whole existing note.
- **Adding a topic to a subject**: append its wikilink to the subject's `topics` frontmatter list AND append a row to the subject's `## Topics` table. The two must stay in sync. Never touch the topic note's frontmatter for this — the topic has no back-reference.
- **Adding a person listed in a team's `## Pessoas e papéis`** also creates `people/{{Name}}.md` if missing.
- **Writing a report** touches each related topic note in two places only: the frontmatter `status` (new farol) and one appended entry under `## Status` in the `### {{periodEnd}}` subsection (creating the subsection if it does not exist). Each entry is a bullet: `- **Report**: [[Report - {{Subject Name}} - {{periodEnd}}]]` followed by nested `**Farol**` and `**Descrição**` lines. It never touches `## Contexto`, `## Fontes relacionadas`, `## Arquivos e assets`, `description`, `id`, `created`, `dueDate` or `isPartOf`.
- On a team, forum or person note the report skill may only append rows to `## Fontes relacionadas` or bullets to `## Arquivos e assets` (what the sub-agents learned).
- A rerun of a report on the same day creates `... - {{date}}-2.md` in the current month folder instead of overwriting the previous one. Reports can be edited afterwards when necessary (e.g. `link-keeper` rewriting a wikilink target on rename), but skills should avoid touching factual content (`[Fn]`, farol, evidence text). The exception is `mgr-status-report --update`: it adds facts from material the user handed over, may flip `- [ ]` to `- [x]`, move items out of `## Não verificado`, recompute a topic's farol and adjust the executive summary, and sets `updated`. It never deletes or rewords a sourced fact, never changes period, `owner`, `created`, `previousReport` or the file name. A topic whose farol changed gets an extra `## Status` entry marked `(atualizado em {{date}})`.
- Latest report of a subject: the `Report - {{Subject Name}} - *.md` with the greatest date in the file name, across every `WS/reports/*/` folder.

## Inferences

- **Topics of a subject**: the `topics` frontmatter list of the subject note (source of truth). The `## Topics` table mirrors it.
- **Subjects of a topic**: every `teams/*.md`, `forums/*.md` and `people/*.md` (`tracked: true`) whose `topics` list contains this topic's wikilink. Read the frontmatter, never the file name.
- **Subjects of the workspace**: every note in `WS/teams/` and `WS/forums/`, and every note in `WS/people/` with `tracked: true`.
- **People of a team**: every `people/*.md` whose `isPartOf` links to it. A person without `isPartOf` belongs to no team (forum participant, external).
- **Project tree**: `isPartOf` between topics (when present).

Section headings are in Portuguese by design; they are stable identifiers and are never translated, whatever language the user writes in.
