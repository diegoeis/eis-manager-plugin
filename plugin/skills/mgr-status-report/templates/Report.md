---
name: "{{Subject Name}} - {{YYYY-MM-DD}}"
type: report
reportType: status
subjectType: {{team | person | forum}}
subject: "[[{{Team | Person | Forum}} - {{Subject Name}}]]"
periodStart: {{YYYY-MM-DD}}
periodEnd: {{YYYY-MM-DD}}
generated: {{YYYY-MM-DD}}
topics:
  - "[[Topic - {{Topic Name}}]]"
sourcesConsulted:
  - {{tracker | messenger | meetings}}
sourcesSkipped:
  - {{tracker | messenger | meetings}}
previousReport: "[[Report - {{Subject Name}} - {{YYYY-MM-DD}}]]"
---

# Status report - {{Subject Name}} - {{YYYY-MM-DD}}

Período: {{YYYY-MM-DD}} a {{YYYY-MM-DD}}. Gerado em {{YYYY-MM-DD}} a partir das fontes listadas em [[#Fontes consultadas]].

## Resumo executivo

{{Com no máximo 100 palavras no total, divida em até 10 itens numa lista os pontos e temas que a liderança precisa saber: onde o time avançou, o que ameaça o período, o que precisa de decisão. Cada afirmação factual carrega a referência da fonte inline como link markdown, ex.: "ABC-123 entregue conforme [issue no Jira](https://...)" ou "decisão tomada na [reunião de sync do dia 12/09](https://...)". Nomes de pessoas responsáveis aparecem linkados ao arquivo Person correspondente, ex.: [Fulano de Tal](Person - Fulano de Tal.md).}}

## Farol por tópico

| Tópico                     | Farol anterior | Farol atual | Por quê |
| -------------------------- | -------------- | ----------- | ------- |
| [[Topic - {{Topic Name}}]] | {{on_track | in_risk | problem | TBD}} | {{on_track | in_risk | problem | TBD (só quando não houve evidência)}} | {{Uma frase com a fonte linkada inline, ou "sem evidência no período"}} |

## Tópicos e temas

### {{Topic Name}}

- Farol: {{on_track | in_risk | problem}}
- **Avanços:**
  - {{itens entregues ou movidos no período, cada um com a fonte linkada inline; nomes de pessoas linkados como [Nome](Person - Nome.md)}}
- **Riscos e bloqueios:**
  - {{o que ameaça o tópico, com a fonte linkada inline; "Nenhum identificado nas fontes consultadas" quando não houver}}
- **Próximos passos:**
  - {{o que as fontes indicam como próximo, com a fonte linkada inline; nunca inventar. Responsável linkado como [Nome](Person - Nome.md); sem citação, "[<responsável padrão>](Person - <responsável padrão>.md) (padrão)"}}

#### Ações e Pendências

{Lista consolidada das ações e pendências. Inclui: (a) itens abertos ([ ]) herdados dos reports anteriores que ainda não foram marcados como concluídos, mantendo a data original e o link para o report onde surgiram; (b) itens novos identificados neste período. Nunca inclua itens já marcados com [x] em reports anteriores. Nomes dos responsáveis sempre linkados ao arquivo Person correspondente.}

  - [ ] [{{Nome do Responsável}}](Person - {{Nome do Responsável}}.md) - {{Descrição da ação ou pendência, com a fonte linkada inline quando houver}} - [{{YYYY-MM-DD}}]({{arquivo-do-report-original}})
  - [x] [{{Nome do Responsável}}](Person - {{Nome do Responsável}}.md) - {{Decisão tomada ou item concluído neste período, com a fonte linkada inline quando houver}} - [{{YYYY-MM-DD}}]({{arquivo-do-report-original}})


## Entregas no período

| Item               | Tópico                     | Concluído em   | Fonte    |
| ------------------ | -------------------------- | -------------- | -------- |
| [{{ABC-123}}]({{url-da-issue-no-tracker}}) {{Título}} | [[Topic - {{Topic Name}}]] | {{YYYY-MM-DD}} | [{{descrição da fonte}}]({{url}}) |

## Riscos e pontos de atenção

- {{Risco, impacto esperado, tópico afetado, responsável linkado como [Nome](Person - Nome.md) (citado, ou responsável padrão do sujeito), com a fonte linkada inline}}

## Decisões e pendências

- {{Decisão tomada ou pendente, quem decide linkado como [Nome](Person - Nome.md) (citado, ou responsável padrão do sujeito), prazo se citado, com a fonte linkada inline}}

## Fontes consultadas

Lista das fontes consultadas neste período (referenciadas inline ao longo do report):

- [{{descrição curta}}]({{link ou identificador}}) - {{tracker | messenger | meeting | file}} - {{YYYY-MM-DD}}

Fontes não consultadas: {{lista com o motivo (conector indisponível, fonte não cadastrada, sem resultado) ou "nenhuma"}}.

## Não verificado

- {{Afirmações relevantes que apareceram sem fonte rastreável ou que o usuário forneceu sem referência. Vazio quando não houver.}}
