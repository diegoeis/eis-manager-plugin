# Backlog

Itens deliberadamente fora das fatias atuais. Cada item tem até 300 caracteres. Quando um entra numa fatia, remover daqui.

## Setup e estrutura

- [ ] **Multi-workspace ativo**: `config.json` já guarda `activeWorkspace`; falta skill para trocar de workspace e resolução de contexto quando o usuário cita um workspace que não é o ativo.
- [ ] **Perfil do usuário no config**: nome e papel do gestor, para assinar reports e ajustar o tom. Removido do setup para reduzir perguntas; entra quando um report precisar.
- [ ] **Idioma de saída fixo**: opção de forçar um idioma nos reports diferente do da conversa (ex.: reports em inglês para C-level global). Hoje o idioma segue a interação.
- [ ] **Outras ferramentas no setup**: reuniões/transcrições, documentos e email como fontes declaradas. Hoje só tracker e messenger; o resto entra em `sources` conforme o usuário cita.
- [ ] **`mgr-setup --from arquivo.md`**: ler respostas do setup de um arquivo para refazer sem entrevista e permitir setup por agentes sem chat interativo.
- [ ] **Ponteiro global para a raiz de dados**: reabrir quando o Cowork expuser um diretório persistente do plugin. Hoje o estado só é encontrado pela pasta conectada ou perguntando. Testado em 2026-09-08: nem ferramentas de arquivo nem script Python via Bash alcançam `~/.claude` no Cowork (o Bash roda em sandbox com outro home). Script do teste em `maintainers/scripts/test_init_data_root.py`.
- [ ] **Fontes por tópico no setup**: removido para encurtar o setup; canais, reuniões e arquivos de um tópico entram pelas skills de report ou por edição manual.
- [ ] **Detecção de conectores**: registrar no AGENTS.md do workspace quais conectores (Slack, Jira, Granola, Drive, Gmail, Calendar) respondem na sessão, para as skills saberem o que podem consultar. Hoje cada sub-agente `source-*` descobre na hora e reporta em `coverage.failed`.
- [ ] **Inferência a partir de tracker e messenger no setup**: listar boards do Jira e canais do Slack para sugerir times e fontes em vez de pedir ao usuário.
- [ ] **Templates customizados por workspace**: pasta `workspace/templates/` que sobrescreve os templates de `plugin/skills/<nome>/templates/`, com skill para o plugin sugerir e criar templates novos. Inclui o comportamento do PRD "se não existir template, propor e salvar" — hoje a skill para com `BLOCKED` porque não há onde gravar.
- [ ] **Validação de wikilinks**: skill ou passo que aponta links `[[X]]` sem arquivo correspondente e frontmatter fora do mínimo.
- [ ] **Update guiado de notas**: `mgr-setup --update` para alterar time, tópico ou pessoa via conversa em vez de editar o markdown na mão.

## Contexto e memória

- [ ] **OKRs e KPIs do período no workspace**: nota `OKR - <período>.md` com objetivos e indicadores, referenciável pelos tópicos via `indicators`.
- [ ] **Memória do workspace** (Fatia 3): pasta `memory/` com notas de frontmatter `about: [[X]]`, consultada antes de qualquer busca externa e atualizada pelas skills.
- [ ] **Leitura de memória da plataforma e externas** (Supermemory, memória do Claude) para enriquecer contexto sem perguntar de novo.

## Reports e análises

- [ ] **Report consolidado multi-sujeito** (Fatia 4): um status report que agrega vários times, fóruns ou pessoas num período, com visão para C-level.
- [ ] **Análise entrega × objetivo**: avaliar se o que foi priorizado tem chance real de mover os OKRs/KPIs definidos.
- [ ] **Detecção de tópicos urgentes**: varrer fontes e apontar o que ameaça entregas ou indicadores do período.
- [ ] **Avaliação da quebra de backlog**: medir se as tarefas foram fatiadas pequenas o suficiente para entregas rápidas de valor.
- [ ] **Métricas de fluxo**: throughput (itens em DONE no período) e leadtime (média em dias úteis do primeiro in-progress até DONE), conforme bases canônicas do PRD. A tabela "Entregas no período" do report já lista os itens DONE; falta o cálculo e a comparação com períodos anteriores.
- [ ] **Report de um tópico**: `mgr-status-report --topic X` para um report focado num tópico só, com as mesmas fontes. Hoje o report é por sujeito (time, fórum, pessoa).
- [ ] **Período incremental**: default "desde o último report do time" em vez de 7 dias fixos.
- [ ] **Fontes por tópico via conversa**: quando o usuário citar canal ou reunião de um tópico durante o report, gravar em `## Fontes` da nota do tópico (hoje só edição manual).
- [ ] **Palavras-chave por tópico**: campo ou seção com aliases e epic keys para o mapeamento evidência → tópico; hoje os sub-agentes só usam nome e descrição.
- [ ] **Segunda passada de evidência**: permitir que a skill peça ao sub-agente mais detalhe sobre um item (ex.: comentários de um bloqueio). Hoje é uma passada só.
