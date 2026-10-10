# AGENTS.md

- As regras do projeto estão em [.claude/rules.md](.claude/rules.md). Leia, entenda e siga-as.
- Sempre que houver uma atualização ou alteração, atualize todos os docs e especificações relacionadas.
- Sempre, sempre, sempre procure seguir os padrões e boas práticas definidas e estabelecidos para construir e manter esse plugin a partir dos documentos oficiais da Anthropic. Você pode achar isso no meu vault do Obsidian, usando o CLI do obsidian, procurando pelas notas com a tag `#ai/howto-claude`, e também completo em https://code.claude.com/docs/.
- Nunca comece fazendo a solução mais complexa e completa. Sempre opitamos por começar simples, e só depois evoluir para a solução mais completa.
- A pasta `docs` guarda PRD, backlog e outros docs de gestão desse projeto; `scripts` guarda o `pack.sh` e scripts de teste.
- A pasta `src` são todos os arquivos do plugin. É o que será empacotado no final, em `dist/`.
