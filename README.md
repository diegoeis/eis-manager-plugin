# eis-manager-assistant

Plugin para Claude (Claude Code e Cowork) que ajuda Heads, Leads, PMs e Tech Leads a acompanhar a camada tática e de execução de vários times, fóruns, liderados e projetos ao mesmo tempo.

Ele junta o que está espalhado entre project tracker, messenger, reuniões e as suas próprias notas, e gera status reports em que toda afirmação tem fonte. O que não tem fonte fica marcado como não verificado ou fica de fora.

> Versão atual: `0.3.0` (ver [`plugin/.claude-plugin/plugin.json`](plugin/.claude-plugin/plugin.json)).

## O problema

Quem lidera vários times gasta tempo demais reconstruindo contexto: o que foi entregue, o que travou, o que foi decidido em qual reunião, qual tópico está em risco. A informação existe, só que está em dez lugares diferentes e ninguém tem tempo de ler tudo toda semana.

Este plugin acompanha **sujeitos** (times, fóruns, pessoas) e os **tópicos** de cada um, lê as fontes pelo período pedido e entrega um report com farol por tópico, entregas, riscos, decisões e pendências, cada item com link para a origem.

### O que ele não faz

- Não cria histórias, tarefas nem especificações técnicas ou de produto.
- Não faz gestão de pessoas. Report de uma pessoa é sobre o trabalho que ela responde por, nunca sobre conduta, tom ou disponibilidade.
- Não lê mensagens diretas, em nenhum caso.
- Não escreve em tracker nem em messenger. Toda leitura de fonte externa é somente leitura.

## Conceitos

| Conceito | O que é |
| --- | --- |
| **Workspace** | Uma empresa ou frente de atuação. Guarda a narrativa (`AGENTS.md`) e todas as notas. |
| **Sujeito** | O que recebe report: um **time** (`Team`), um **fórum** (`Forum`, reunião recorrente de decisão, como um comitê de produto) ou uma **pessoa** acompanhada individualmente (`Person` com `tracked: true`). Os três funcionam do mesmo jeito. |
| **Tópico** | Uma iniciativa, projeto ou tema com farol (`on_track`, `in_risk`, `problem`). Não tem dono único: vários sujeitos podem apontar para o mesmo tópico. |
| **Fontes** | Canais, reuniões, boards e pastas registrados em cada sujeito e tópico. O plugin aprende novas fontes enquanto trabalha e as grava sozinho. |
| **Report** | `reports/<AAAA-MM>/Report - <Sujeito> - <data>.md`, gerado a partir de evidências e nunca regerado; `--update` acrescenta informações novas no próprio arquivo. |

As relações entre notas vivem no frontmatter YAML, como wikilinks no estilo Obsidian (`[[Squad X]]`). As pastas só separam as notas por tipo (`teams/`, `forums/`, `people/`, `topics/`, `reports/<AAAA-MM>/`); nenhuma relação depende delas.

## Skills

| Skill | O que faz |
| --- | --- |
| `/mgr-setup` | Cria a pasta de dados, o `config.json`, o workspace e as notas de times, fóruns, pessoas e tópicos. Modos: `--workspace`, `--team`, `--forum`, `--person`, `--topic`, `--source <frase>`. |
| `/mgr-topic` | Único ponto de criação e manutenção de tópicos: `--list-topics`, `--add`, `--remove <Nome>`, `--archive <Nome>`. |
| `/mgr-status-report` | Gera o report de um sujeito para um período, com fatos citados, e atualiza o farol dos tópicos. Flags: `--period`, `--sources`, `--data-root`, `--interactive`, `--update`. |

Flags e prosa valem igual: `/mgr-status-report Squad X últimas duas semanas` funciona.

## Sub-agentes

Invocados só pelas skills, nunca diretamente pelo usuário.

| Agente | Papel |
| --- | --- |
| `source-tracker` | Lê o board do sujeito (Jira, Linear, Trello, Asana ou o que a sessão tiver) e devolve entregas, bloqueios e atrasos. |
| `source-messenger` | Lê os canais do sujeito e dos tópicos (Slack, Teams, Discord, Google Chat). Nunca posta, nunca abre DMs. |
| `source-meetings` | Busca reuniões do período em Granola, Tactiq, transcrições no Drive ou notas locais. |
| `link-keeper` | Mantém os wikilinks consistentes quando um tópico é arquivado ou removido. |

Os três `source-*` devolvem evidências num formato fixo ([`plugin/references/evidence.md`](plugin/references/evidence.md)). Assim a skill de report nunca vê mensagens brutas, a citação fica padronizada e dá para trocar a ferramenta de uma fonte sem mexer na skill. Se o conector de uma fonte não existir na sessão, a fonte sai como "não consultada" e o report segue.

## Instalação

### Requisitos

- Claude Code ou Cowork (Claude desktop).
- Conectores das fontes que você quer usar (tracker, messenger, ferramenta de reuniões). Nenhum é obrigatório: o plugin trabalha com o que estiver disponível e diz o que faltou.

### Desenvolvimento local (Claude Code)

```bash
git clone git@github.com:diegoeis/eis-manager-plugin.git
```

```bash
claude --plugin-dir ./eis-manager-plugin/plugin
```

### Pacote

```bash
./maintainers/scripts/pack.sh
```

Gera `maintainers/eis-manager-assistant-v<versão>.zip` com o conteúdo de `plugin/` (use `--tar` para `.tar.gz`). Antes de zipar, o script valida o frontmatter de skills e agentes (campos `name`/`description`, `description` com até 1024 caracteres e sem `<...>`). O zip pode ser instalado pelo fluxo de upload de plugins do seu host.

## Primeiros passos

1. Conecte à sessão a pasta onde você já guarda notas (vault do Obsidian, pasta de projetos).
2. Rode o setup:

   ```
   /mgr-setup
   ```

   Ele lê só nomes de arquivo e frontmatter dessa pasta para sugerir times, pessoas e projetos, pergunta onde gravar o estado (padrão: `<pasta conectada>/manager-assistant/`), cria o workspace e encadeia o cadastro do primeiro time e dos tópicos.

3. Registre as fontes do time, se quiser, em prosa:

   ```
   /mgr-setup --source canal #squad-x https://acme.slack.com/archives/C0123
   /mgr-setup --source adicione a reunião "Weekly Squad X" do Granola
   ```

4. Gere o primeiro report:

   ```
   /mgr-status-report Squad X
   ```

Sem `--period`, o report cobre os últimos 7 dias. A saída no chat é só a linha `STATUS: OK | WARN | BLOCKED` e um resumo com o caminho do arquivo, as fontes consultadas e puladas e os faróis alterados. O conteúdo fica no arquivo.

### Casos de uso

- Report semanal antes da reunião de liderança: `/mgr-status-report Squad X`.
- Fechamento de sprint: `/mgr-status-report Squad X --period 14d`.
- Preparar o próximo comitê: `/mgr-status-report fórum Comitê de Produto --period 14d`.
- Antes do 1:1, o que a pessoa entregou e o que está travado: `/mgr-status-report pessoa Ana Souza`.
- Revisar o farol antes de aplicar: `/mgr-status-report Squad X --interactive`.
- Conector do messenger fora: `/mgr-status-report Squad X --sources tracker,meetings`.
- Agendamento sem pasta conectada: `/mgr-status-report Squad X --data-root /caminho/para/manager-assistant`.
- Reunião depois do report: `/mgr-status-report --update o report do Squad X com o transcript /caminho/sync.md`.

A referência completa de comandos, flags e formato das fontes está em [`plugin/README.md`](plugin/README.md).

## Onde vive o estado

O plugin nunca grava na própria pasta de instalação. O estado fica numa pasta escolhida no `/mgr-setup`:

```
<raiz de dados>/                   padrão: <pasta conectada>/manager-assistant/
  config.json                      workspace ativo, pastas de referência, URLs das ferramentas, fontes aprendidas
  workspaces/
    <workspace-slug>/
      AGENTS.md                    narrativa do workspace
      CLAUDE.md                    aponta para AGENTS.md
      teams/
        <Nome>.md
      forums/
        <Nome>.md
      people/
        <Nome>.md
      topics/
        <Nome>.md
      reports/
        <AAAA-MM>/                 uma pasta por mês, pelo mês em que o report foi gerado
          Report - <Sujeito> - <AAAA-MM-DD>.md
```

Cada tipo de nota tem a sua pasta, e só `reports/` tem subpastas. O nome do arquivo é só o nome da nota, igual ao título, sem prefixo de tipo: a pasta já diz o tipo. Só os reports mantêm o prefixo `Report - `. Os wikilinks (`[[Squad X]]`) não levam pasta e funcionam igual no Obsidian; por isso um nome não pode se repetir entre times, fóruns, pessoas e tópicos. Workspaces criados antes da versão 0.3.0 têm as notas soltas na raiz, com prefixo: rode `/mgr-setup` uma vez e ele move cada nota para a sua pasta, tira o prefixo e reescreve os links (as outras skills param com `BLOCKED` até isso acontecer).

Tudo é texto simples: JSON só no `config.json`, o resto é Markdown com frontmatter YAML, legível por você, pelo Obsidian, por outros agentes e por scripts.

Para reencontrar o estado, toda skill segue a mesma ordem: (1) caminho passado no pedido (`--data-root` ou em prosa); (2) `config.json` na pasta conectada, em `manager-assistant/` dentro dela ou um nível abaixo. Sem nenhum dos dois, em modo silencioso a skill para com `STATUS: BLOCKED`. Detalhes em [`plugin/references/data-root.md`](plugin/references/data-root.md) e [`plugin/references/data-model.md`](plugin/references/data-model.md).

## Princípios

- **Fato com fonte.** Toda frase factual do report tem link para a issue, a mensagem, a reunião ou o arquivo de onde veio. Sem fonte, vai para `## Não verificado` ou sai.
- **Farol por evidência.** O farol de cada tópico segue uma regra fixa ([`evidence.md`](plugin/references/evidence.md#farol-rule)). Sem evidência no período, mantém o valor anterior e o tópico aparece como não verificado.
- **Silencioso por padrão.** Nenhuma skill pergunta nada sem `--interactive` (exceto o `mgr-setup`, interativo por natureza). Isso permite rodar em agendamentos e por outros agentes. Quando falta algo essencial, a skill falha rápido com `STATUS: BLOCKED` e diz o que fazer.
- **Aprende com o uso.** Canais, reuniões, pastas e convenções de board descobertos durante um report são gravados na nota certa, sem perguntar. Você não precisa informar a mesma fonte duas vezes.
- **Privacidade.** Nada de nomes de clientes, documentos ou dados pessoais além de nome e papel das pessoas do time. Credenciais e tokens nunca são guardados.
- **Idioma.** O plugin responde no idioma em que você escreve. Os headings das notas ficam em português porque funcionam como identificadores estáveis.

## Estrutura do repositório

```
plugin/                          o plugin; só isto é empacotado
  .claude-plugin/plugin.json     manifesto
  skills/
    mgr-setup/                   SKILL.md + templates de workspace, Team, Forum, Person
    mgr-topic/                   SKILL.md + template de Topic
    mgr-status-report/           SKILL.md + template de Report
  agents/                        source-tracker, source-messenger, source-meetings, link-keeper
  references/                    data-root.md, data-model.md, evidence.md
  README.md                      referência de uso
maintainers/                     manutenção do projeto (não empacotado)
  docs/                          PRD e backlog
  scripts/                       pack.sh e scripts de teste
.claude/rules.md                 regras de implementação do plugin
AGENTS.md, CLAUDE.md             instruções para agentes que trabalham neste repo
```

## Contribuindo

1. Leia [`.claude/rules.md`](.claude/rules.md): é o contrato de implementação (layout, convenções de skill, onde vive o estado, formato das notas).
2. Siga a [documentação oficial de plugins do Claude Code](https://code.claude.com/docs/en/plugins-reference).
3. Comece pela solução mais simples. O que ficou de fora está em [`maintainers/docs/backlog.md`](maintainers/docs/backlog.md).
4. Mudou comportamento? Atualize os docs e references relacionados e faça bump de versão em `plugin.json` (semver).
5. Rode `./maintainers/scripts/pack.sh` antes de publicar para validar o frontmatter.

## Roadmap

Próximos passos previstos no [backlog](maintainers/docs/backlog.md): report consolidado de vários sujeitos para C-level, métricas de fluxo (throughput e leadtime), análise entrega × OKR/KPI, memória do workspace, report focado num tópico e troca de workspace ativo.

## Licença

MIT. Autor: Diego Eis.
