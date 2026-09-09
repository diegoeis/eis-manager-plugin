---
created: 2026-09-05
type: prd
tags:
  - ai
---

# PRD - new project status report

**O que resolver:**

- Gestores e líderes de times e projetos tem dificuldade de acompanhar os diversos topicos mais importantes que seus times são responsáveis.
- Acompanhameto próximo dificulta a gestão por contexto, baseado em resultado e movimento de indicadores, objetivos e KPIs.
- Muitos canais para acompanhar, muitas informações descentralizadas, falta de contexto sobre os projetos, dificultam a comunicação e a tomada de decisão para mitigar riscos e prevenir problemas

**Por que resolver:**

- Gestores precisam ter controle sobre o que importa, para aumentar a proximidade de executivos e C-Level da empresa
- Sem visão do que é importante, gestores não conseguem entender se um indicador está sendo movimentado com as entregas do time
- Sem gestão do projeto bem feito, fica difícil de antecipar e planejar mudanças de direção
- Ter facilidade de enxergar pontos de crescimento e desenvolvimento pessoal dos funcionários e liderados

**Como resolver:**

- Criar um plugin para claude completo que centraliza informações de acompanhamento para gestores e líderes que precisam lidar com muitos projetos e múltiplos times
- O plugin deve agir como um assistente eficiente e eficaz, sempre se baseando em fatos verificáveis, com fontes e referências
- Esse plugin deve ter a capacidade de se adaptar com o contexto e a realidade do gestor, de forma que o usuário possa customizar fontes de informação e detalhes importantes que devem ser priorizados
- O plugin deve ser capaz de criar documentos e artefatos de report
- Deve ser capaz de entender as relações das entregas com os objetivos e resultados, ajudando o gestor a entender se OKRs, KPIs e Indicadores específicos estão sendo ou não impactos
- O plugin deve ser capaz de entregar para o gestor informações para tomar decisões rápidas e embasadas.

## O que esse plugin é e não é

Esse plugin assistente serve para a ajudar a gerir e acompanhar a camada tática e de execução.

Não serve para definir entregas técnicas, criar histórias, tarefas. Não serve para criar específicações técnicas ou de produto. Embora, esse plugin e assistente tenham que entender profundamente essas especificações e também o escopo da empresa e do mercado que o time está atuando.

**Cenários de uso:**

- Gerar relatórios de acompanhamento de ações dos times e projetos baseada em transcrições, anotações e buscas em messengers e project trackers
- Fazer avaliações e análises para validar se priorizações de produto e tecnologia podem de fato impactar os indicadores e OKRs definidos
- Criar relatórios de entrega e status report de um ou vários times dentro de um determinado período, trazendo os impactos e percepções reais de resolução baseados em mensagens de reuniões, conversas em messengers, emails e project trackers
- Ajudar a detectar tópicos urgentes ou que merecem atenção, que se relacionam com o impacto de resultados da empresa, que possam comprometer entregas ou alcançar os indicadores e OKRs definidos no período
- Medição de eficácia das decisões de um time, ajudando a avaliar se o que foi priorizado, tem altas chances de impactar e mover indicadores e OKRs definidos
- Medição de priorização micro de backlog: se as tarefas foram bem quebradas e divididas para diminuir dúvidas e garantir entregas rápidas de valor em curto espaço de tempo
- Criar relatório de entrega e status de um time ou um relatório consolidado de vários times juntos.

**Qual o principal usuário:**

- Head de Produto e Product Lead
- Head e Gerente de Tecnologia
- PMs
- Tech Lead

**Audiência foco:**

- Alta liderança executiva da empresa
- Gestores e Liderança média de outros times

## Funcionamento

**Alguns critérios de funcionamento:**

- Plugin deve conseguir trabalhar com um workspace indicado pelo usuário, entendendo esse workspace para utilizá-lo, interpretando seus documentos, estrutura de pastas e informações disponibilizadas
- Deve ser capaz de conseguir conectar projetos, pessoas e resultados para ter contexto acurado.
- É importante que haja uma forma de guardar informações como URLs, nomes de pessoas, nomes de times, paths para arquivos importantes e informações que podem ajudar em tarefas recorrentes
- O plugin deve trabalhar como se fosse um assistente autonomo, com capacidade criar formas de ganhar eficiência para responder, preparar reports e análises, buscar dados e informações
- O plugin deve poder funcionar e saber onde estão seus arquivos de configuração e informações guardadas de memória, placeholders e outras variáveis que permita que ele possa encontrar arquivos. referências e informações de projetos, pessoas e dados mesmo não estando dentro da pasta do workspace e quando qualquer uma de suas skills forem executadas
- Para reports e relatórios, sempre preencher e utilizar os templates e arquivos já preparados. Se não houver um template criado por padrão, o assistente deve sugerir para o usuário a criação de um template e criá-lo para ser reutilizado posteriormente.

### Sobre memória e auto evolução

O assistente deve ler a memória da plataforma LLM que está usando ou memórias externas conectaas a plataformas para aumentar seu conhecimento.
Deve poder criar no lugar apropriado sua própria memória que deve ser consultada, alterada, evoluída e editada por ele ou pelo usuário sempre que necessário pra dar respostas corretas e recorrer mais rápido à informações.

Bases de cálculos canonicas que são referências:

- **Throughput**: mede quantidade de itens entregues dentro de um período
  - Quantidade de tarefas entregues (que foram para o status DONE ou equivalente de finalização), dentro do período
- **Leadtime**: mede quanto tempo um item levou para ser entregue
  - Mede a média do tempo que todas as tarefas entregues dentro de um período levaram para ser feitas
  - Dias úteis calculados entre as datas de início (start_date ou campo que indica que a tarefa entrou no primeiro status de in progress no downstream do time) até a data de entrega (resolution date ou o que o valha no time, que é a data que a tarefa foi para DONE)

## Referências

Usar com referência e consulta, não para copiar.

- [generate-status-report — openai/plugins](https://www.skills.sh/openai/plugins/generate-status-report)
- [project-status-report — mohitagw15856/pm-claude-skills](https://www.skills.sh/mohitagw15856/pm-claude-skills/project-status-report)
- [vp-session-wrapup — vdustr/skills](https://www.skills.sh/vdustr/skills/vp-session-wrapup)
- [project-state — grahama1970/agent-skills](https://www.skills.sh/grahama1970/agent-skills/project-state)
