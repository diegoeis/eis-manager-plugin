---
name: "{{Person Name}}"
type: person
role: {{Product Manager | Tech Lead | Head of Product | Head of Tech | Developer | Designer | Delivery Manager}}
isPartOf: "[[Team - {{Team Name}}]]"
description: "{{Até 350 caracteres sobre a pessoa: foco, responsabilidades, contexto relevante para o acompanhamento}}"
tracked: {{true | false}}
---

## Sobre

{{Só quando `tracked: true`. Escopo do acompanhamento: o que esta pessoa lidera ou responde por, o que você quer enxergar nos reports dela.}}

## Topics

| Nome | Link | Descrição |
| --- | --- | --- |
| {{Topic Name}} | [[Topic - {{Topic Name}}]] | {{Uma linha sobre o tópico}} |

## Fontes

Fontes consultadas pelo `mgr-status-report` em todo report desta pessoa, além das fontes de cada tópico. Edite à mão ou use `/mgr-setup --source`. Mensagens diretas nunca são lidas; suas notas de 1:1 entram por `Arquivos`.

### Canais

| Nome | URL |
| --- | --- |
| {{#canal}} | {{https://...}} |

### Reuniões e transcrições

- {{1:1 com a pessoa}}
  - {{Granola}}
  - {{Pasta local: /Users/.../1on1/Nome/}}

### Arquivos

- {{Path de pasta ou nota (ex.: pasta da pessoa no Obsidian)}}
