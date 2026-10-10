---
name: "{{Subject Name}} - {{YYYY-MM-DD}}"
type: report
owner: "[[{{Subject Name}}]]"
periodStart: {{YYYY-MM-DD}}
periodEnd: {{YYYY-MM-DD}}
created: {{YYYY-MM-DD}}
topics:
  - "[[{{Topic Name}}]]"
previousReport: "[[Report - {{Subject Name}} - {{YYYY-MM-DD}}]]"
---

# Status report - {{Subject Name}} - {{YYYY-MM-DD}}

Período: {{YYYY-MM-DD}} a {{YYYY-MM-DD}}.

## Resumo executivo

{{Com no máximo 100 palavras no total, divida em até 10 itens numa lista os pontos e temas que a liderança precisa saber: onde o time avançou, o que ameaça o período, o que precisa de decisão. Cada afirmação factual carrega a referência da fonte inline como link markdown, ex.: "ABC-123 entregue conforme [issue no Jira](https://...)" ou "decisão tomada na [reunião de sync do dia 12/09](https://...)". Nomes de pessoas responsáveis aparecem linkados ao arquivo Person correspondente, ex.: [Fulano de Tal](../../people/Fulano de Tal.md).}}

## Farol por tópico

| Tópico | Farol | Por quê |
| --- | --- | --- |
| [[{{Topic Name}}]] | {{on_track | in_risk | problem | TBD (só quando não houve evidência)}} | {{Uma frase com a fonte linkada inline, ou "sem evidência no período". No --update, a frase é substituída, nunca acumulada}} |

## Tópicos e temas

### {{Topic Name}}

{Em Avanços, Riscos e bloqueios e Próximos passos, os itens são agrupados pela data da evidência (`date`), num sub-bullet `**YYYY-MM-DD**` por dia, do dia mais recente para o mais antigo; dentro do dia, também do mais recente para o mais antigo. Dias sem itens não aparecem. Quando o período tem um único dia (`periodStart` igual a `periodEnd`), não há agrupamento: os itens ficam direto sob o rótulo.}

- **Farol:** {{on_track | in_risk | problem}}
- **Avanços:**
  - **{{YYYY-MM-DD}}**
    - {{itens entregues ou movidos nesse dia, cada um com a fonte linkada inline; nomes de pessoas linkados como [Nome](../../people/Nome.md). Quando o fato é de pessoa de outro time que compartilha este tópico, acrescente o sufixo "(via {{Outro Time}})" no fim da linha}}
- **Riscos e bloqueios:**
  - **{{YYYY-MM-DD}}**
    - {{o que ameaça o tópico, registrado nesse dia, com a fonte linkada inline. Inclui itens do tracker bloqueados ou vencidos que não viraram ação. Nunca "segue sem mudança"; alertas automáticos somados numa linha só}}
  - {{sem nada no período: um único item "Nenhum identificado nas fontes consultadas", sem data}}
- **Próximos passos:**
  - **{{YYYY-MM-DD}}**
    - {{o que as fontes desse dia indicam como próximo, com a fonte linkada inline; nunca inventar. Responsável linkado como [Nome](../../people/Nome.md); sem citação, "[{{responsável padrão}}](../../people/{{responsável padrão}}.md) (padrão)"}}

#### Ações e Pendências

{Poucos itens, cada um algo que uma pessoa tem de entregar. Só entra o que passa no teste do Step 4 da skill: dono citado pela fonte (nunca "(padrão)"), entregável concreto, pessoa do próprio sujeito, e nada de manutenção do tracker, comunicar/responder/alinhar, mensagem solta de thread, decisão ou alerta. Item do tracker só entra se estiver em execução (nunca Ready to Dev, backlog ou espera), com responsável, e se ele (ou o pai/item que ele bloqueia) for High ou acima e vencer nos próximos 3 dias. Itens bloqueados viram uma linha só por tópico: "Hoje existem N tasks bloqueadas", com os links. O resto vai para Riscos e bloqueios, Decisões ou Próximos passos.}

{Inclui: (a) itens abertos herdados do report anterior que ainda passam no teste, com a data ➕ original e o link de origem; (b) itens novos do período. Mesma fonte ou mesmo entregável é o mesmo item: a novidade vira sub-bullet datado, nunca item novo e nunca texto dentro da linha. Nunca inclua itens [x] ou [-] de reports anteriores.}

{Itens herdados cuja fonte é um link são reverificados na própria fonte: resolvido vira [x] com ✅ e sub-bullet datado; novidade sem fechamento continua [ ] com sub-bullet datado; fonte inacessível continua [ ] com sub-bullet de não verificado. Linhas começam na coluna 0, sem espaços antes do "-".}

- [ ] [{{Tech Lead}}](../../people/{{Tech Lead}}.md) - Hoje existem {{N}} tasks bloqueadas: [{{ABC-123}}]({{url}}), [{{ABC-456}}]({{url}}) ➕ {{YYYY-MM-DD}}
- [ ] [{{Nome do Responsável}}](../../people/{{Nome do Responsável}}.md) - {{Descrição do entregável}} ([fonte]({{url}})) ➕ {{YYYY-MM-DD}}
- [ ] [{{Nome do Responsável}}](../../people/{{Nome do Responsável}}.md) - {{Descrição do item herdado, sem mudar o texto}} ([fonte]({{url}})) - [origem](../{{YYYY-MM}}/Report - {{Subject Name}} - {{YYYY-MM-DD}}.md) ➕ {{YYYY-MM-DD}}
  - {{YYYY-MM-DD}}: {{o que a fonte diz de novo, sem fechar o item}} ([fonte]({{url}}))
- [x] [{{Nome do Responsável}}](../../people/{{Nome do Responsável}}.md) - {{Descrição do item concluído}} ([fonte]({{url}})) - [origem](../{{YYYY-MM}}/Report - {{Subject Name}} - {{YYYY-MM-DD}}.md) ➕ {{YYYY-MM-DD}} ✅ {{YYYY-MM-DD}}
  - {{YYYY-MM-DD}}: {{a resposta na fonte que resolveu o item}} ([fonte]({{url}}))


## Entregas no período

| Item               | Tópico                     | Concluído em   | Fonte    |
| ------------------ | -------------------------- | -------------- | -------- |
| [{{ABC-123}}]({{url-da-issue-no-tracker}}) {{Título}} | [[{{Topic Name}}]] | {{YYYY-MM-DD}} | [{{descrição da fonte}}]({{url}}) |

## Riscos e pontos de atenção

- {{Risco, impacto esperado, tópico afetado, responsável linkado como [Nome](../../people/Nome.md) (citado, ou responsável padrão do sujeito), com a fonte linkada inline}}

## Decisões e pendências

- {{Decisão tomada ou pendente, quem decide linkado como [Nome](../../people/Nome.md) (citado, ou responsável padrão do sujeito), prazo se citado, com a fonte linkada inline}}

## Fontes consultadas

Lista das fontes consultadas neste período (referenciadas inline ao longo do report):

- [{{descrição curta}}]({{link ou identificador}}) - {{tracker | messenger | meeting | file}} - {{YYYY-MM-DD}}

Fontes não consultadas: {{lista com o motivo (conector indisponível, fonte não cadastrada, sem resultado) ou "nenhuma"}}.

## Não verificado

- {{Afirmações relevantes que apareceram sem fonte rastreável ou que o usuário forneceu sem referência. Vazio quando não houver.}}
