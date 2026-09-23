---
name: "{{Person Name}}"
type: person
role: {{Product Manager | Tech Lead | Head of Product | Head of Tech | Developer | Designer | Delivery Manager}}
isPartOf: "[[Team - {{Team Name}}]]"
description: "{{Até 350 caracteres sobre a pessoa: foco, responsabilidades, contexto relevante para o acompanhamento}}"
tracked: {{true | false}}
topics:
  - "[[Topic - {{Topic Name}}]]"
---

## Sobre

{{Só quando `tracked: true`. Escopo do acompanhamento: o que esta pessoa lidera ou responde por, o que você quer enxergar nos reports dela.}}

## Topics

| Nome | Link | Descrição |
| --- | --- | --- |
| {{Topic Name}} | [[Topic - {{Topic Name}}]] | {{Uma linha sobre o tópico}} |

## Fontes relacionadas

Fontes consultadas pelo `mgr-status-report` em todo report desta pessoa, além das fontes de cada tópico. Edite à mão ou use `/mgr-setup --source`. Mensagens diretas nunca são lidas; suas notas de 1:1 entram por `Arquivos e assets`.

| Nome | URL/Link | Tipo |
| --- | --- | --- |
| {{nome do canal do messenger, título do 1:1, etc}} | {{link local para arquivo, nota, canal do messenger, url etc}} | {{nome da fonte/referência usada. Slack, Granola, Reunião, etc}} |

## Arquivos e assets

{{listagem de arquivos, links, urls, repositórios e outros assets e materiais que podem ser úteis para consulta e análise}}

- [Nome do arquivo, título, etc](url/link/path da fonte)

Arquivos, notas ou links locais e privados:

- [Nome do arquivo, título, etc](path/local/do/arquivo)
