---
name: "{{Topic Name}}"
type: topic
status: {{on_track | in_risk | problem | TBD}}
teamOwner: "[[Team - {{Team Name}}]]"
maintainer: "[[Person - {{Person Name}}]]"
isPartOf: "[[Topic - {{Parent Topic Name}} - {{Parent Owner Team Name}}]]"
description: "{{Até 350 caracteres sobre o tópico: problema que ataca, resultado esperado, por que importa agora}}"
relatedTeam:
  - "[[Team - {{Other Team Name}}]]"
created: {{YYYY-MM-DD}}
dueDate: {{YYYY-MM-DD}}
---

## Contexto

{{Por que esse tópico existe, qual objetivo ou indicador ele pretende mover, decisões que o originaram.}}

## Status atual

- Farol: {{on_track | in_risk | problem | TBD}}
- Descrição: {{Até 100 palavras sobre o estado atual, o que avançou, o que bloqueia.}}
- Último report: [[Report - {{Team Name}} - {{YYYY-MM-DD}}]]

## Fontes

### Canais

| Nome | URL |
| --- | --- |
| {{#canal}} | {{https://...}} |

### Reuniões e transcrições

- {{Nome da reunião recorrente}}
  - {{Granola | Tactiq | Google Drive | Pasta local | Obsidian | ... — com path ou link quando houver}}

### Arquivos

- {{Path ou URL de documento relevante}}

## Reports

- [[Report - {{Team Name}} - {{YYYY-MM-DD}}]]
