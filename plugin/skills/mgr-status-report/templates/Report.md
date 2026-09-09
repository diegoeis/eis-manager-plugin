---
name: "{{Team Name}} - {{YYYY-MM-DD}}"
type: report
reportType: team-status
team: "[[Team - {{Team Name}}]]"
periodStart: {{YYYY-MM-DD}}
periodEnd: {{YYYY-MM-DD}}
generated: {{YYYY-MM-DD}}
topics:
  - "[[Topic - {{Topic Name}} - {{Team Name}}]]"
sourcesConsulted:
  - {{tracker | messenger | meetings}}
sourcesSkipped:
  - {{tracker | messenger | meetings}}
previousReport: "[[Report - {{Team Name}} - {{YYYY-MM-DD}}]]"
---

# Status report - {{Team Name}} - {{YYYY-MM-DD}}

Período: {{YYYY-MM-DD}} a {{YYYY-MM-DD}}. Gerado em {{YYYY-MM-DD}} a partir das fontes listadas em [[#Fontes consultadas]].

## Resumo executivo

{{Com no máximo 100 palavras no total, divida em até 10 itens numa lista os pontos e temas que a liderança precisa saber: onde o time avançou, o que ameaça o período, o que precisa de decisão. Cada afirmação factual carrega a referência da fonte entre colchetes, ex.: [F3].}}

## Farol por tópico

| Tópico                     | Farol anterior | Farol atual | Por quê |
| -------------------------- | -------------- | ----------- | ------- |
| [{{Topic Name}}](topic-file.md) | {{on_track     | in_risk     | problem | TBD}} | {{on_track | in_risk | problem | TBD (só quando não houve evidência)}} | {{Uma frase com referência [Fn], ou "sem evidência no período"}} |

## Tópicos e temas

### {{Topic Name}}

- Farol: {{on_track | in_risk | problem}}
- Avanços:
  - {{itens entregues ou movidos no período, cada um com [Fn](url-do-fn-se-houver)}}
- Riscos e bloqueios:
  - {{o que ameaça o tópico, com [Fn](url-do-fn-se-houver); "Nenhum identificado nas fontes consultadas" quando não houver}}
- Próximos passos: 
  - {{o que as fontes indicam como próximo, com [Fn](url-do-fn-se-houver); nunca inventar. Responsável: quem a fonte cita; sem citação, "PM e Tech Lead (padrão)"}}

#### Ações e Pendências

{Coloque aqui a lista de ações e pendências que ficaram no último report para serem revisitadas e as novas adicionadas que foram identificadas para esse report. A url do report original deve ser incluída para referência quando o item vem de reports anteriores. Não inclua os itens que já foram marcados com [x] nos reports anteriores.}

  - [ ] {{Nome do Responsável citado pela fonte; sem citação, "<PM> e <Tech Lead> (padrão)"}} - {{Descrição da ação ou pendência que aguarda decisão, com [Fn](url-do-fn-se-houver) quando houver}} - {{[YYYY-MM-DD](arquivo-do-report-original)}}
  - [x] {{Nome do Responsável}} - {{decisões tomadas e o que aguarda decisão, com [Fn](url-do-fn-se-houver) quando houver}} - {{[YYYY-MM-DD](arquivo-do-report-original)}}


## Entregas no período

| Item               | Tópico                     | Concluído em   | Fonte    |
| ------------------ | -------------------------- | -------------- | -------- |
| {{ABC-123 Título}} | [[Topic - {{Topic Name}} - {{Team Name}}]] | {{YYYY-MM-DD}} | [F{{n}}] |

## Riscos e pontos de atenção

- {{Risco, impacto esperado, tópico afetado, responsável (citado, ou PM e Tech Lead como padrão), [Fn]}}

## Decisões e pendências

- {{Decisão tomada ou pendente, quem decide (citado, ou PM e Tech Lead como padrão), prazo se citado, [Fn]}}

## Fontes consultadas

| Ref | Tipo      | Fonte     | Data    |
| --- | --------- | --------- | ------- |
| F1  | {{tracker | messenger | meeting | file}} | {{link ou identificador}} | {{YYYY-MM-DD}} |

Fontes não consultadas: {{lista com o motivo (conector indisponível, fonte não cadastrada, sem resultado) ou "nenhuma"}}.

## Não verificado

- {{Afirmações relevantes que apareceram sem fonte rastreável ou que o usuário forneceu sem referência. Vazio quando não houver.}}
