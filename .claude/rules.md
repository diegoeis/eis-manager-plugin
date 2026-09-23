# Regras do projeto

Regras para quem desenvolve o plugin `eis-manager-assistant`. O PRD em `maintainers/docs/` é o horizonte; estas regras são o contrato de implementação.

## Layout do repositório

- `plugin/` é o plugin. Só o que está aqui é empacotado. Nunca colocar docs de manutenção, planos ou arquivos locais dentro dela.
- `maintainers/` guarda PRD, docs, scripts (`pack.sh`) e o pacote gerado.
- `.claude/` guarda estas regras e configuração local de desenvolvimento (não empacotada).

## Convenções do plugin

- Skills em `plugin/skills/<nome>/SKILL.md`; sub-agentes em `plugin/agents/<nome>.md`; templates dentro da skill que os usa, em `plugin/skills/<nome>/templates/` (`mgr-setup` tem os das notas e do workspace, `mgr-status-report` tem `Report.md`) — cada skill é fechada em si mesma e nunca lê template de outra; conhecimento compartilhado entre skills em `plugin/references/` (`data-root.md`, `data-model.md`, `evidence.md`), referenciado via `${CLAUDE_PLUGIN_ROOT}/references/...`; templates via `${CLAUDE_PLUGIN_ROOT}/skills/<nome>/templates/...`. A primeira ação de toda skill é localizar o estado na pasta conectada, com a instrução inline no SKILL.md; references e templates são lidos só no passo que precisa deles, nunca todos de uma vez no início.
- Frontmatter de SKILL.md usa só os campos do spec Agent Skills (`name`, `description`, `allowed-tools`, `license`, `compatibility`, `metadata`) para funcionar também no Cowork e em outros agentes. Flags e argumentos vão descritos na `description`, não em `argument-hint`. A `description` tem no máximo 1024 caracteres e não pode conter `<...>` — o validador de instalação lê como tag XML e rejeita o plugin (limites verificados em 2026-09-08 e 2026-09-09); o `pack.sh` checa os dois antes de zipar.
- Prefixo das skills: `mgr-` (ex.: `mgr-setup`, `mgr-status-report`). Nomes em kebab-case, em inglês.
- Conteúdo das skills em inglês. O idioma de saída segue o idioma em que o usuário escreve; não há campo de idioma na config e nunca se pergunta. Headings das notas e do report ficam em português como identificadores estáveis. (Idioma fixo por config está no backlog.)
- Seguir a documentação oficial de plugins: https://docs.claude.com/en/docs/claude-code/plugins-reference. Em dúvida, consultar antes de inventar.
- Toda skill deve ser invocável sem interação (modo padrão silencioso, sem perguntas) para funcionar em agendamentos do Cowork e em outros agentes. Perguntas só com flag `--interactive`. Quando faltar informação essencial, a skill falha rápido com uma mensagem clara e uma linha `STATUS: OK | WARN | BLOCKED` no início da saída. Isso vale inclusive para a raiz de dados: o usuário conecta a pasta ou passa `--data-root <path>`; sem nenhum dos dois, o modo silencioso é `BLOCKED` e só `--interactive` pergunta o path. Exceção única: `mgr-setup`, que é interativa por natureza.
- Toda afirmação factual em report ou análise cita a fonte (link, arquivo, reunião, mensagem). Sem fonte, a informação é marcada como não verificada ou omitida. Nunca inventar dados.
- Não expor nomes de clientes, documentos pessoais ou dados sensíveis em artefatos gerados.
- Skills e sub-agentes descrevem o que precisa ser verdade no resultado (fonte em toda afirmação, leitura só, o que nunca fazer) e o mínimo de procedimento. Não prescrever queries literais, listas de extensões, caps numéricos ou tabelas de sinônimos: o modelo resolve isso melhor no contexto real. Argumentos são texto livre; flags são convenção para scripts e agendamentos, e prosa vale o mesmo.
- O plugin aprende conforme usa. Toda skill grava, na mesma execução e sem perguntar, o que descobriu e vai servir de novo: canais, reuniões, pastas de transcrições, convenções do board, palavras-chave que ligam itens a tópicos. Destino: `## Fontes` do tópico, `AGENTS.md` do workspace ou `config.json → sources`. O usuário nunca deve ter que informar a mesma fonte duas vezes.
- Reports sempre preenchem um template de `plugin/skills/mgr-status-report/templates/`. Não existe template para o tipo pedido: a skill para com `STATUS: BLOCKED` dizendo quais tipos existem. (Criar e salvar templates novos depende de templates por workspace, no backlog.)

## Escopo

O plugin acompanha a camada tática e de execução: status, riscos, relação entrega × objetivo. Não cria histórias, tarefas nem especificações técnicas ou de produto. Não faz gestão de pessoas.

## Onde vive o estado

Nunca gravar dentro de `${CLAUDE_PLUGIN_ROOT}` (muda a cada update).

A raiz de dados é uma pasta que o usuário nomeia no setup. Ela guarda `config.json` e `workspaces/`. Motivo, confirmado em teste: no Cowork o plugin só grava dentro da pasta conectada à sessão; `${CLAUDE_PLUGIN_DATA}` e `~/.claude/` não são alcançáveis. Por isso o plugin nunca assume um local escondido. Default oferecido: `<pasta conectada>/manager-assistant/`, porque assim sessões futuras com a mesma pasta encontram o estado sem perguntar.

Para reencontrar a raiz, toda skill segue `plugin/references/data-root.md`: (1) path dado pelo usuário no pedido, como flag `--data-root` ou em prosa, que vence quando presente e é o caminho para agendamentos e outros agentes sem pasta conectada; (2) `config.json` na pasta conectada, em `manager-assistant/` dentro dela ou um nível abaixo; (3) pergunta o path, só em `--interactive` ou no `mgr-setup`; em modo silencioso sem (1) nem (2), `BLOCKED`. Nada além disso: sem ponteiro, sem procurar em `~/.claude/` ou `${CLAUDE_PLUGIN_DATA}`, sem subir diretórios. Cada tentativa fora da pasta conectada é uma leitura que falha no Cowork e confunde o fluxo.

Pastas de referência (as que o usuário aponta para inferência) são só lidas, nunca recebem estado. Skills que não são `mgr-setup` param com `STATUS: BLOCKED` quando não há `config.json`.

Todo estado é texto simples: JSON só para `config.json`; tudo o mais é Markdown com frontmatter YAML, para que LLMs, agentes e scripts extraiam o YAML sem precisar interpretar o corpo.

## Perguntas ao usuário

- Idioma nunca é perguntado: a skill responde no idioma em que o usuário escreve.
- Ferramentas nunca são perguntadas por nome: pede-se a URL (board do tracker, messenger) e infere-se a ferramenta pelo domínio.
- Setup cadastra identidade e relações (workspace, times, pessoas, tópicos com os times/fóruns/pessoas relacionados e descrição). Status, prazo, estado atual e fontes de um tópico não são perguntados no setup; entram pelas skills de report ou por edição manual.
- Fontes adicionais (vault do Obsidian, pasta do Drive, reuniões) não são perguntadas no setup. Quando o usuário citar um path ou URL numa conversa, qualquer skill grava em `config.json` → `sources`. Se uma skill precisar de uma fonte não registrada, pergunta uma vez e grava.
- Toda pergunta, formulário ou seletor de pasta vem precedido de uma ou duas frases dizendo por que está sendo pedido e o que será feito com a resposta. Seletor ou formulário sem contexto é defeito. No Cowork, texto escrito entre chamadas de ferramenta não aparece (vira resumo); contexto antes de um seletor tem que ir pela ferramenta de mensagem ao usuário (`send_user_message`).
- No Cowork, pasta se obtém pelo seletor nativo (pedido de conexão de pasta), não por path digitado; path digitado é o fallback para hosts sem seletor.
- Primeira rodada do setup tem dois campos: onde procurar (pastas de referência; omitido se já há pasta conectada) e onde gravar (raiz de dados, com default na pasta conectada). Rodadas seguintes agrupam no máximo cinco campos relacionados.

## Modelo de dados: associativo, não estrutural

As relações entre workspace, times, tópicos e pessoas vivem no frontmatter, via wikilinks `[[Nome]]`. Pastas só dizem o tipo da nota: uma pasta por tipo dentro do workspace (`teams/`, `forums/`, `people/`, `topics/`, `reports/`). Só `reports/` tem subpastas, uma por mês (`reports/YYYY-MM/`, pelo mês em que o report foi gerado, não pelo período). Nunca criar outras hierarquias, como `teams/<time>/topics/` ou pastas por sujeito.

```
<raiz>/                              # pasta nomeada pelo usuário; default <conectada>/manager-assistant/
  config.json                        # workspace ativo, pastas de referência, ferramentas (URLs), fontes registradas
  workspaces/
    <workspace-slug>/                # kebab-case
      AGENTS.md                      # narrativa do workspace (empresa, contexto, o que importa)
      CLAUDE.md                      # só aponta para AGENTS.md
      teams/<Team Name>.md
      forums/<Forum Name>.md
      people/<Person Name>.md
      topics/<Topic Name>.md         # só o nome; não tem dono único, pode se relacionar com vários times, fóruns ou pessoas
      reports/<YYYY-MM>/Report - <Subject Name> - <YYYY-MM-DD>.md # gerado por mgr-status-report; nunca sobrescrito (só `--update` acrescenta, editando no lugar)
      memory/                        # Fatia 3
```

Templates customizados por workspace ficam no backlog; hoje só existem os de `plugin/skills/<nome>/templates/`.

Nomes de pasta em kebab-case. Nomes de arquivo em Title Case, iguais ao `name` e ao H1 da nota, sem prefixo de tipo: a pasta já diz o tipo. Só reports têm prefixo: `Report - <Subject Name> - <YYYY-MM-DD>.md`. Como o wikilink não leva pasta, nomes são únicos no workspace inteiro (entre times, fóruns, pessoas e tópicos); a skill que cria uma nota com nome já usado pergunta outro ou para com `BLOCKED`. Wikilink nunca leva pasta; links markdown para pessoas em reports e tópicos são relativos (`../../people/...` de um report, `../people/...` de um tópico). Workspaces anteriores à 0.3.0 têm as notas na raiz, com prefixo; o `mgr-setup` migra (move, tira o prefixo, pede ao `link-keeper` para reescrever os links, inclusive no `AGENTS.md` do workspace, e atualiza o parágrafo de estrutura do `AGENTS.md` e o `CLAUDE.md`; o mesmo acerto roda sozinho quando as notas já estão nas pastas mas o `AGENTS.md` ainda descreve o layout antigo), as outras skills param com `BLOCKED`.

### Sujeitos

**Sujeito** é o que possui tópicos, carrega fontes e recebe status report: `Team`, `Forum` (reunião recorrente de decisão ou alinhamento, com participantes; não é um time) ou `Person` com `tracked: true` (liderado acompanhado individualmente). Os três têm as mesmas seções `## Topics` e `## Fontes`; o `mgr-status-report` trata igual e só varia o que está listado por tipo em `data-model.md`: board (time; fórum e pessoa opcional), filtro de `assignee` no tracker (pessoa), e responsável padrão (time: PM e Tech Lead; fórum: facilitador; pessoa: ela mesma).

Report de pessoa é sobre os tópicos e entregas que ela responde por, nunca sobre comportamento. Mensagens diretas não são fonte em nenhum caso. O report fica no workspace do gestor e não é material de compartilhamento; a skill diz isso no resumo.

### Resolução de wikilinks

Como no Obsidian: `[[X]]` resolve para o arquivo `X.md`, e só isso. O link carrega o nome do arquivo, sem pasta e sem prefixo de tipo (exceto reports): `productManager: "[[Ana Souza]]"`, `topics: ["[[Checkout v2]]"]`, `previousReport: "[[Report - Squad X - 2026-09-08]]"`. O tipo do alvo é a pasta onde o arquivo está. Nunca resolver pelo campo `name`. Se o arquivo não existir, o link é um rótulo e a skill segue sem erro. Exceção: `isPartOf` de um time ou fórum aponta para o workspace, que não tem nota; é só rótulo.

Um tópico não tem dono único: `relatedTeam`, `relatedForum` e `relatedPerson` são três listas independentes (cada uma pode ter zero, um ou vários links) e juntas decidem em quais sujeitos o tópico aparece. `maintainer` é só a pessoa responsável no dia a dia, sem relação com essas listas.

### Inferências que o modelo permite

- Tópicos de um sujeito: todos os `topics/*.md` cujo `relatedTeam`, `relatedForum` ou `relatedPerson` aponte pra ele — sempre pelo frontmatter, nunca pelo nome do arquivo.
- Sujeitos do workspace: `teams/*.md`, `forums/*.md` e `people/*.md` com `tracked: true`.
- Pessoas de um time: todos os `people/*.md` com `isPartOf` apontando pra ele.
- Times envolvidos num tópico: sua lista `relatedTeam`.
- Árvore de projetos: `isPartOf` entre tópicos.

### Frontmatter mínimo

Templates completos em `plugin/skills/mgr-setup/templates/`. Campos obrigatórios:

- **Person**: `name`, `type: person`, `role`, `description`, `tracked`; `isPartOf` só quando o time é conhecido.
- **Forum**: `name`, `type: forum`, `facilitator`, `members`, `isPartOf`, `description`, `cadence`, `trackerBoardKey`, `trackerBoardUrl` (`TBD` quando não há board).
- **Team**: `name`, `type: team`, `productManager`, `techLead`, `isPartOf`, `description`, `trackerBoardKey`, `trackerBoardUrl`.
- **Topic**: `name`, `type: topic`, `status` (`on_track | in_risk | problem`), `maintainer`, `isPartOf`, `description`, `relatedTeam`, `relatedForum`, `relatedPerson`, `created`, `dueDate`. Sem dono único: `relatedTeam`/`relatedForum`/`relatedPerson` são listas independentes, cada uma com zero, um ou vários links.
- **Report**: `name`, `type: report`, `reportType` (`status`), `subjectType` (`team | person | forum`), `subject`, `periodStart`, `periodEnd`, `generated`, `topics`, `sourcesConsulted`, `sourcesSkipped`, `previousReport` (omitido no primeiro), `updated` (só depois de um `--update`).

`description` tem até 350 caracteres. Campos que não são identificadores (canais, reuniões, docs, links) vão no corpo, em seções fixas.

### Corpo dos markdowns

Seções H2 fixas, na ordem, para extração por heading:

- **Team**: Sobre; Pessoas e papéis (tabela: nome, role, descrição); Topics (tabela: nome, link, descrição dos tópicos cujo `relatedTeam` inclui esse time); Fontes (Canais; Reuniões e transcrições como lista: uma reunião por item e, aninhados, os lugares onde ela pode estar — Granola, Tactiq, Drive, pasta local, Obsidian — com path ou link; Arquivos — mesmas subseções do Topic; o status-report consulta em todo report do time e grava ali o que aprender sobre o time).
- **Forum**: Sobre; Participantes (tabela: nome, papel no fórum, descrição); Topics; Fontes (como Team).
- **Person** com `tracked: true`: Sobre; Topics; Fontes (como Team).
- **Topic**: Contexto; Status atual (farol, descrição de até 100 palavras, link do último report); Fontes (canais com nome e URL, reuniões/transcrições, arquivos); Reports (links dos reports gerados).
- **Report**: Resumo executivo; Farol por tópico; Por tópico; Entregas no período; Riscos e pontos de atenção; Decisões e pendências; Fontes consultadas; Não verificado. Toda frase factual termina com `[Fn]` apontando para uma linha de Fontes consultadas.

Skills que gravam nessas notas editam só a seção alvo, nunca reescrevem o arquivo. Report nunca é regerado nem sobrescrito; a exceção única é `mgr-status-report --update`, que acrescenta fatos do material entregue pelo usuário no próprio report, sem apagar nem reescrever fato que já tem fonte.

## Leitura de fontes externas

Skills nunca leem tracker, messenger ou reuniões diretamente. A leitura é feita pelos sub-agentes `plugin/agents/source-*.md` (um por tipo de fonte), que recebem um brief e devolvem evidências no formato de `plugin/references/evidence.md`. Motivo: isolar o contexto (o report não vê mensagens brutas), padronizar a citação e permitir trocar a ferramenta de uma fonte sem tocar na skill.

Sub-agentes de plugin ignoram `mcpServers`, `permissionMode` e `hooks` (doc oficial de sub-agentes). No Cowork os servidores MCP têm nome UUID, então os sub-agentes não listam `tools`; herdam os da sessão e ficam somente-leitura via `disallowedTools`. Se o conector da fonte não existir na sessão, o sub-agente devolve evidência vazia com `coverage.failed` e a skill marca a fonte como não consultada — nunca bloqueia.

Farol de tópico é decidido só por evidência, com a regra de `evidence.md`. Sem evidência, mantém o farol anterior e o tópico entra em Não verificado.

## Versionamento e empacotamento

- Versão em `plugin/.claude-plugin/plugin.json`; bump semver a cada entrega.
- `./maintainers/scripts/pack.sh` zipa o conteúdo de `plugin/` para `maintainers/`.
