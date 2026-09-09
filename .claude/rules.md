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
- Setup cadastra identidade e relações (workspace, times, pessoas, tópicos com owner e descrição). Status, prazo, estado atual e fontes de um tópico não são perguntados no setup; entram pelas skills de report ou por edição manual.
- Fontes adicionais (vault do Obsidian, pasta do Drive, reuniões) não são perguntadas no setup. Quando o usuário citar um path ou URL numa conversa, qualquer skill grava em `config.json` → `sources`. Se uma skill precisar de uma fonte não registrada, pergunta uma vez e grava.
- Toda pergunta, formulário ou seletor de pasta vem precedido de uma ou duas frases dizendo por que está sendo pedido e o que será feito com a resposta. Seletor ou formulário sem contexto é defeito. No Cowork, texto escrito entre chamadas de ferramenta não aparece (vira resumo); contexto antes de um seletor tem que ir pela ferramenta de mensagem ao usuário (`send_user_message`).
- No Cowork, pasta se obtém pelo seletor nativo (pedido de conexão de pasta), não por path digitado; path digitado é o fallback para hosts sem seletor.
- Primeira rodada do setup tem dois campos: onde procurar (pastas de referência; omitido se já há pasta conectada) e onde gravar (raiz de dados, com default na pasta conectada). Rodadas seguintes agrupam no máximo cinco campos relacionados.

## Modelo de dados: associativo, não estrutural

As relações entre workspace, times, tópicos e pessoas vivem no frontmatter, via wikilinks `[[Nome]]`. Pastas não carregam significado além de separar workspaces. Nunca criar hierarquias como `team/topic/`.

```
<raiz>/                              # pasta nomeada pelo usuário; default <conectada>/manager-assistant/
  config.json                        # workspace ativo, pastas de referência, ferramentas (URLs), fontes registradas
  workspaces/
    <workspace-slug>/                # kebab-case
      AGENTS.md                      # narrativa do workspace (empresa, contexto, o que importa)
      CLAUDE.md                      # só aponta para AGENTS.md
      Team - <Team Name>.md
      Topic - <Topic Name> - <Team Name>.md   # team = teamOwner; evita colisão de tópicos homônimos entre times
      Person - <Person Name>.md
      Report - <Team Name> - <YYYY-MM-DD>.md   # gerado por mgr-status-report; nunca sobrescrito
      memory/                        # Fatia 3
```

Templates customizados por workspace ficam no backlog; hoje só existem os de `plugin/skills/<nome>/templates/`.

Nomes de pasta em kebab-case. Nomes de arquivo em Title Case com prefixo do tipo: `<Type> - <Name>.md`.

### Resolução de wikilinks

Como no Obsidian: `[[X]]` resolve para o arquivo `X.md`, e só isso. O link carrega sempre o nome completo do arquivo, com prefixo: `teamOwner: "[[Team - Squad X]]"`, `maintainer: "[[Person - Nome]]"`. Nunca resolver pelo campo `name`, nunca inferir prefixo. Se o arquivo não existir, o link é um rótulo e a skill segue sem erro. Exceção: `isPartOf` de um time aponta para o workspace, que não tem nota; é só rótulo.

### Inferências que o modelo permite

- Tópicos de um time: todos os `Topic - * - <Team Name>.md`; `teamOwner` deve bater com o sufixo.
- Pessoas de um time: todos os `Person - *.md` com `isPartOf` apontando pra ele.
- Times envolvidos num tópico: `teamOwner` mais `relatedTeam`.
- Árvore de projetos: `isPartOf` entre tópicos.

### Frontmatter mínimo

Templates completos em `plugin/skills/mgr-setup/templates/`. Campos obrigatórios:

- **Person**: `name`, `type: person`, `role`, `isPartOf`, `description`.
- **Team**: `name`, `type: team`, `productManager`, `techLead`, `isPartOf`, `description`, `trackerBoardKey`, `trackerBoardUrl`.
- **Topic**: `name`, `type: topic`, `status` (`on_track | in_risk | problem`), `teamOwner`, `maintainer`, `isPartOf`, `description`, `relatedTeam`, `created`, `dueDate`.
- **Report**: `name`, `type: report`, `reportType` (`team-status`), `team`, `periodStart`, `periodEnd`, `generated`, `topics`, `sourcesConsulted`, `sourcesSkipped`, `previousReport` (omitido no primeiro).

`description` tem até 350 caracteres. Campos que não são identificadores (canais, reuniões, docs, links) vão no corpo, em seções fixas.

### Corpo dos markdowns

Seções H2 fixas, na ordem, para extração por heading:

- **Team**: Sobre; Pessoas e papéis (tabela: nome, role, descrição); Topics (tabela: nome, link, descrição dos tópicos que é owner); Fontes (Canais; Reuniões e transcrições como lista: uma reunião por item e, aninhados, os lugares onde ela pode estar — Granola, Tactiq, Drive, pasta local, Obsidian — com path ou link; Arquivos — mesmas subseções do Topic; o status-report consulta em todo report do time e grava ali o que aprender sobre o time).
- **Topic**: Contexto; Status atual (farol, descrição de até 100 palavras, link do último report); Fontes (canais com nome e URL, reuniões/transcrições, arquivos); Reports (links dos reports gerados).
- **Report**: Resumo executivo; Farol por tópico; Por tópico; Entregas no período; Riscos e pontos de atenção; Decisões e pendências; Fontes consultadas; Não verificado. Toda frase factual termina com `[Fn]` apontando para uma linha de Fontes consultadas.

Skills que gravam nessas notas editam só a seção alvo, nunca reescrevem o arquivo.

## Leitura de fontes externas

Skills nunca leem tracker, messenger ou reuniões diretamente. A leitura é feita pelos sub-agentes `plugin/agents/source-*.md` (um por tipo de fonte), que recebem um brief e devolvem evidências no formato de `plugin/references/evidence.md`. Motivo: isolar o contexto (o report não vê mensagens brutas), padronizar a citação e permitir trocar a ferramenta de uma fonte sem tocar na skill.

Sub-agentes de plugin ignoram `mcpServers`, `permissionMode` e `hooks` (doc oficial de sub-agentes). No Cowork os servidores MCP têm nome UUID, então os sub-agentes não listam `tools`; herdam os da sessão e ficam somente-leitura via `disallowedTools`. Se o conector da fonte não existir na sessão, o sub-agente devolve evidência vazia com `coverage.failed` e a skill marca a fonte como não consultada — nunca bloqueia.

Farol de tópico é decidido só por evidência, com a regra de `evidence.md`. Sem evidência, mantém o farol anterior e o tópico entra em Não verificado.

## Versionamento e empacotamento

- Versão em `plugin/.claude-plugin/plugin.json`; bump semver a cada entrega.
- `./maintainers/scripts/pack.sh` zipa o conteúdo de `plugin/` para `maintainers/`.
