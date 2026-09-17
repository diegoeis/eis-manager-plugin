---
name: "{{Forum Name}}"
type: forum
facilitator: "[[Person - {{Facilitator Name}}]]"
members:
  - "[[Person - {{Member Name}}]]"
isPartOf: "[[{{Workspace Name}}]]"
description: "{{Até 350 caracteres sobre o fórum: para que existe, o que decide, quem participa}}"
cadence: "{{semanal | quinzenal | mensal | sob demanda}}"
trackerBoardKey: "{{ABC ou TBD}}"
trackerBoardUrl: "{{https://... ou TBD}}"
---

## Sobre

{{Propósito do fórum, que tipo de decisão sai dele, o que ele não decide, como se relaciona com os times.}}

## Participantes

| Nome | Papel no fórum | Descrição |
| --- | --- | --- |
| [[Person - {{Person Name}}]] | {{Facilitador | Participante | Convidado}} | {{Uma linha sobre o que a pessoa representa ali}} |

## Topics

| Nome | Link | Descrição |
| --- | --- | --- |
| {{Topic Name}} | [[Topic - {{Topic Name}}]] | {{Uma linha sobre o tópico}} |

## Fontes

Fontes consultadas pelo `mgr-status-report` em todo report deste fórum, além das fontes de cada tópico. Edite à mão ou use `/mgr-setup --source`; a skill também acrescenta aqui o que descobrir sozinha.

### Canais

| Nome | URL |
| --- | --- |
| {{#canal-do-forum}} | {{https://...}} |

### Reuniões e transcrições

Uma reunião por item; embaixo, os lugares onde ela pode ser encontrada (Granola, Tactiq, Google Drive, pasta local, Obsidian, Notion...), com o path ou link quando houver. Só os lugares listados aqui e nos tópicos são consultados; se não houver nenhum, o report usa o que a sessão tiver.

- {{Reunião do fórum}}
  - {{Granola}}
  - {{Pasta local: /Users/.../Reuniões/Forum X/}}

### Arquivos

- {{Path de pasta ou nota (ex.: pasta do fórum no Obsidian) ou URL de documento}}
