# eis-manager-assistant

Assistente para Heads, Leads, PMs e Tech Leads acompanharem a camada tática de vários times e projetos. Centraliza fontes dispersas (tracker, messenger, reuniões, notas do workspace), produz status reports e análises sempre com fatos verificáveis e fontes citadas.

Não cria histórias, tarefas nem especificações técnicas ou de produto.

## Skills

| Skill | O que faz |
| --- | --- |
| `/mgr-setup` | Cria a pasta de dados, o workspace e as notas de times, pessoas e tópicos. Modos `--team`, `--topic` e `--source` para estender. |
| `/mgr-status-report [time] [--period 7d] [--sources tracker,messenger,meetings] [--data-root /path] [--interactive]` | Gera `Report - <Time> - <data>.md` a partir do tracker, messenger e reuniões, com cada fato citado, e propõe o farol dos tópicos. Silencioso por padrão; sem `--period` cobre sempre os últimos 7 dias; `--interactive` confirma time e farol. |

## How to

### Primeira vez

Conecte à sessão a pasta onde você já guarda notas (vault do Obsidian, pasta de projetos) e rode:

```
/mgr-setup
```

O setup lê só nomes de arquivos e frontmatter dessa pasta para sugerir times, pessoas e projetos. Ele pergunta onde gravar o estado (padrão: `<pasta conectada>/manager-assistant/`), cria o workspace, encadeia o cadastro do primeiro time e dos seus tópicos, e termina com `STATUS: OK` ou `WARN` listando o que ficou como `TBD`.

Sem pasta conectada, ele pede um caminho antes de qualquer coisa.

### `/mgr-setup` — cadastrar times e tópicos

| Comando | O que faz |
| --- | --- |
| `/mgr-setup` ou `/mgr-setup --workspace` | Cria pasta de dados, `config.json`, workspace e encadeia time e tópicos. |
| `/mgr-setup --team` | Adiciona um time ao workspace ativo (nome, PM, Tech Lead, descrição, board) e as pessoas dele. Oferece cadastrar tópicos em seguida. |
| `/mgr-setup --topic` | Adiciona tópicos a um time existente (nome, maintainer, descrição). Vários de uma vez, um por linha. |
| `/mgr-setup --source <frase>` | Registra um canal, reunião ou pasta em `## Fontes` do time (ou do tópico, se citado) a partir de uma frase. |

O setup nunca lê tracker, messenger ou ferramentas de reunião; ele só guarda URLs. Também não pergunta status, prazo ou fontes ao cadastrar time ou tópico: status e prazo vêm do report; fontes entram por `--source` ou editando a nota.

Casos de uso:

- Entrou um squad novo sob sua gestão: `/mgr-setup --team`.
- O time começou uma iniciativa que você quer acompanhar com farol: `/mgr-setup --topic`.
- O time criou um canal novo ou você passou a gravar a weekly no Granola: `/mgr-setup --source ...`.
- Mudou de empresa ou de área: `/mgr-setup` de novo, apontando outra pasta.

### Adicionar fontes a um time ou tópico

Pelo comando, descrevendo em prosa:

```
/mgr-setup --source adicione a reunião "Sync - RPA" para pegar do Granola e das notas no meu vault /Users/voce/Vault/Reuniões
/mgr-setup --source canal #squad-xpto https://acme.slack.com/archives/C0123
/mgr-setup --source no tópico Checkout v2, a pasta /Users/voce/Vault/Checkout
```

A skill descobre o time (pergunta se houver mais de um e nenhum citado), a subseção pelo que a frase descreve, e anexa as linhas na nota certa. Um path de vault novo também é gravado em `config.json → sources`.

Ou edite à mão a seção `## Fontes` de `Team - <Time>.md` ou `Topic - <Tópico> - <Time>.md`:

```markdown
## Fontes

### Canais

| Nome | URL |
| --- | --- |
| #squad-xpto | https://acme.slack.com/archives/C0123 |

### Reuniões e transcrições

- Weekly Squad XPTO
  - Granola
  - Pasta local: /Users/voce/Vault/Reuniões/Squad XPTO/
- Planning quinzenal
  - Google Drive: https://drive.google.com/drive/folders/...

### Arquivos

- /Users/voce/Vault/Times/Squad XPTO/
```

Fontes do time valem para todo report daquele time; fontes do tópico só para ele. Uma reunião lista embaixo os lugares onde pode ser encontrada; o report procura em cada um e para no primeiro que entrega. A busca por outras reuniões do time fica restrita aos lugares listados; sem nenhum listado, usa tudo que a sessão tiver. Em `Arquivos`, uma pasta do seu vault é lida como notas suas sobre o time: qualquer nota ali com data ou modificação no período vira evidência.

O próprio report também escreve aqui: canais, reuniões e pastas que os sub-agentes descobrirem sozinhos são anexados na nota, sem perguntar.

### `/mgr-status-report` — gerar o report de um time

```
/mgr-status-report [time] [--period 14d | de 1 a 15 de setembro] [--sources tracker,messenger,meetings] [--data-root /path] [--interactive]
```

Flags e prosa valem igual: `/mgr-status-report Squad XPTO últimas duas semanas` funciona.

| Flag | Padrão | Uso |
| --- | --- | --- |
| `time` | obrigatório se houver mais de um time | Nome como está em `Team - <Time>.md`. |
| `--period` | últimos 7 dias até hoje | `14d`, `30d`, ou datas em prosa. O período resolvido aparece no resumo. |
| `--sources` | `tracker,messenger,meetings` | Restringe as fontes. Útil quando um conector está fora ou você só quer o board. |
| `--data-root` | pasta conectada | Caminho da pasta que contém `config.json`. Necessário em agendamentos e sessões sem pasta conectada. |
| `--interactive` | desligado | Pergunta qual time quando ambíguo e pede confirmação antes de mudar o farol de cada tópico. |

O que ele produz:

1. `Report - <Time> - <data fim>.md` no workspace (nunca sobrescreve; repete no mesmo dia e sai `-2`, `-3`). Resumo executivo, tabela de farol, seção por tópico, entregas, riscos, decisões, tabela de fontes `F1..Fn` e o que não pôde ser verificado. Toda frase factual carrega `[Fn]`. PRs, MRs, reviews, commits e deploys nunca entram como ação, pendência ou risco; só sustentam uma entrega do item de trabalho a que pertencem. Ações, pendências, riscos e próximos passos têm sempre um responsável: quem a fonte cita ou, sem citação, PM e Tech Lead do time marcados como padrão.
2. Atualiza cada `Topic - *.md` do time: `status` no frontmatter, `## Status atual` e uma linha em `## Reports`.
3. Anexa em `## Fontes` do time e dos tópicos o que os sub-agentes aprenderam.
4. No chat, só a primeira linha `STATUS: OK | WARN | BLOCKED` e um resumo: caminho do report, período, fontes consultadas e puladas, faróis alterados, próximo passo. O conteúdo do report não é despejado no chat.

`WARN` aparece quando uma fonte não foi consultada, um tópico ficou sem evidência, um farol mudou sem confirmação ou o board está `TBD`. `BLOCKED` quando não achou `config.json` ou o time é ambíguo em modo silencioso.

Casos de uso:

- Report semanal antes da reunião de liderança: `/mgr-status-report Squad XPTO`.
- Revisar o farol com calma antes de aplicar: `/mgr-status-report Squad XPTO --interactive`.
- Fechamento de sprint de duas semanas: `/mgr-status-report Squad XPTO --period 14d`.
- Slack fora do ar ou sem conector na sessão: `--sources tracker,meetings`.
- Rodar agendado toda segunda sem pasta conectada: `/mgr-status-report Squad XPTO --data-root /Users/voce/Vault/manager-assistant`.

Limites: um time por execução; não cria tarefas, histórias ou specs; não cadastra times ou tópicos (use `mgr-setup`); não lê fonte nenhuma diretamente, só via sub-agentes.

## Sub-agentes

`source-tracker`, `source-messenger` e `source-meetings` leem uma fonte cada, somente leitura, e devolvem evidências no formato de `references/evidence.md`. Só são invocados pelas skills. Se o conector da fonte não existir na sessão, a fonte é marcada como não consultada e o report segue.

## Estrutura

```
plugin/
  .claude-plugin/plugin.json   manifesto
  skills/                      uma pasta por skill, com SKILL.md e templates/ próprios
    mgr-setup/templates/         AGENTS.md, CLAUDE.md, Team.md, Topic.md, Person.md
    mgr-status-report/templates/ Report.md
  agents/                      sub-agentes invocados pelas skills
  references/                  conhecimento compartilhado (data-root, data-model, evidence)
```

## Onde vive o estado

O plugin não grava nada dentro de sua pasta de instalação. O estado fica numa pasta que o usuário escolhe no `/mgr-setup` (padrão: `<pasta conectada>/manager-assistant/`), com `config.json` e `workspaces/<slug>/`. Notas são Markdown com frontmatter YAML e relações por wikilinks, no estilo Obsidian. Detalhes em `references/data-root.md` e `references/data-model.md`.

## Instalação para desenvolvimento

```
claude --plugin-dir /caminho/para/plugin
```

Empacotar: `./maintainers/scripts/pack.sh` (gera `maintainers/eis-manager-assistant-v<versão>.zip`).
