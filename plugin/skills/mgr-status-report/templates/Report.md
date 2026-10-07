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

Período: {{YYYY-MM-DD}} a {{YYYY-MM-DD}}. Gerado em {{YYYY-MM-DD}} a partir das fontes listadas em [[#Fontes consultadas]].

## Resumo executivo

{{Com no máximo 100 palavras no total, divida em até 10 itens numa lista os pontos e temas que a liderança precisa saber: onde o time avançou, o que ameaça o período, o que precisa de decisão. Cada afirmação factual carrega a referência da fonte inline como link markdown, ex.: "ABC-123 entregue conforme [issue no Jira](https://...)" ou "decisão tomada na [reunião de sync do dia 12/09](https://...)". Nomes de pessoas responsáveis aparecem linkados ao arquivo Person correspondente, ex.: [Fulano de Tal](../../people/Fulano de Tal.md).}}

## Farol por tópico

| Tópico                     | Farol anterior | Farol atual | Por quê |
| -------------------------- | -------------- | ----------- | ------- |
| [[{{Topic Name}}]] | {{on_track | in_risk | problem | TBD}} | {{on_track | in_risk | problem | TBD (só quando não houve evidência)}} | {{Uma frase com a fonte linkada inline, ou "sem evidência no período"}} |

## Tópicos e temas

### {{Topic Name}}

{Em Avanços, Riscos e bloqueios e Próximos passos, os itens são agrupados pela data da evidência (`date`), num sub-bullet `**MM-DD**` por dia, do dia mais recente para o mais antigo; dentro do dia, também do mais recente para o mais antigo. Dias sem itens não aparecem. Quando o período tem um único dia (`periodStart` igual a `periodEnd`), não há agrupamento: os itens ficam direto sob o rótulo.}

- Farol: {{on_track | in_risk | problem}}
- **Avanços:**
  - **{{MM-DD}}**
    - {{itens entregues ou movidos nesse dia, cada um com a fonte linkada inline; nomes de pessoas linkados como [Nome](../../people/Nome.md). Quando o fato é de pessoa de outro time que compartilha este tópico, acrescente o sufixo "(via {{Outro Time}})" no fim da linha}}
- **Riscos e bloqueios:**
  - **{{MM-DD}}**
    - {{o que ameaça o tópico, registrado nesse dia, com a fonte linkada inline}}
  - {{sem nada no período: um único item "Nenhum identificado nas fontes consultadas", sem data}}
- **Próximos passos:**
  - **{{MM-DD}}**
    - {{o que as fontes desse dia indicam como próximo, com a fonte linkada inline; nunca inventar. Responsável linkado como [Nome](../../people/Nome.md); sem citação, "[{{responsável padrão}}](../../people/{{responsável padrão}}.md) (padrão)"}}

#### Ações e Pendências

{Lista consolidada das ações e pendências. Inclui: (a) itens abertos ([ ]) herdados dos reports anteriores que ainda não foram marcados como concluídos, mantendo a data original e o link para o report onde surgiram; (b) itens novos identificados neste período. Nunca inclua itens já marcados com [x] em reports anteriores. Nomes dos responsáveis sempre linkados ao arquivo Person correspondente.}

{Só entram itens de pessoas do próprio sujeito deste report. Fato de pessoa de outro time, num tópico compartilhado, fica como contexto em **Avanços** ou **Riscos e bloqueios** com o sufixo "(via {{Outro Time}})" e nunca vira item aqui.}

{Itens herdados cuja fonte é um link (mensagem no messenger, issue, reunião) são reverificados na própria fonte: resolvido vira [x] com sub-bullet "Resolvido em"; novidade sem fechamento continua [ ] com sub-bullet "Atualização em"; fonte inacessível continua [ ] com sub-bullet de não verificado.}

  - [ ] [{{Nome do Responsável}}](../../people/{{Nome do Responsável}}.md) - {{Descrição da ação ou pendência, com a fonte linkada inline quando houver}} - [{{YYYY-MM-DD}}](../{{YYYY-MM}}/Report - {{Subject Name}} - {{YYYY-MM-DD}}.md)
    - Atualização em {{YYYY-MM-DD}}: {{o que a fonte original diz de novo, sem fechar o item}} ([fonte]({{url}}))
  - [x] [{{Nome do Responsável}}](../../people/{{Nome do Responsável}}.md) - {{Decisão tomada ou item concluído neste período, com a fonte linkada inline quando houver}} - [{{YYYY-MM-DD}}](../{{YYYY-MM}}/Report - {{Subject Name}} - {{YYYY-MM-DD}}.md)
    - Resolvido em {{YYYY-MM-DD}}: {{a resposta na fonte que resolveu o item}} ([fonte]({{url}}))


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
