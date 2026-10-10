---
name: "{{Workspace Name}}"
type: workspace
slug: {{workspace-slug}}
description: "{{Até 350 caracteres sobre a empresa ou frente: o que faz, mercado, momento atual}}"
created: {{YYYY-MM-DD}}
---

# {{Workspace Name}}

Este arquivo é o contexto narrativo do workspace. Qualquer agente que trabalhe com este workspace deve ler este arquivo primeiro e depois as notas de cada tipo, uma pasta por tipo: `teams/`, `forums/`, `people/` e `topics/`. Os reports ficam em `reports/AAAA-MM/`. As relações entre elas estão no frontmatter, em wikilinks que apontam para o nome do arquivo.

## Sobre

{{Contexto da empresa ou frente: produto, clientes, mercado, momento atual, o que a liderança está olhando neste período.}}

## O que importa acompanhar

{{Prioridades, objetivos e indicadores do período que qualquer report deve levar em conta. Uma linha por item.}}

## Ferramentas

| Tipo | Ferramenta | URL | Observação |
| --- | --- | --- | --- |
| Project tracker | {{jira}} | {{https://...}} | {{convenções de status: qual coluna significa DONE}} |
| Messenger | {{slack}} | {{https://...}} | {{convenções de canais}} |

Outras fontes (vault, pastas de documentos, reuniões) ficam em `config.json` → `sources`, registradas conforme aparecem na conversa.

## Acompanhamentos

Times, fóruns e pessoas que recebem status report. Uma linha por sujeito.

| Tipo | Nome | Link | Descrição |
| --- | --- | --- | --- |
| {{team | forum | person}} | {{Name}} | [[{{Name}}]] | {{Uma linha}} |

## Convenções e armadilhas

{{Regras locais que um agente precisa saber para não errar: nomes ambíguos, siglas, times que mudaram de nome, canais que não devem ser lidos, etc.}}
