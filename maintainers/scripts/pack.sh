#!/usr/bin/env bash
#
# pack.sh — Empacota o plugin para distribuicao
#
# O plugin final vive inteiro dentro da pasta plugin/ na raiz do repo — tudo
# que da suporte ao desenvolvimento (maintainers/, .claude/, docs do repo) fica
# fora dela e nunca entra no pacote. Empacotar aqui significa zipar o
# CONTEUDO de plugin/ (nao a pasta em si), excluindo so lixo incidental
# (.DS_Store, arquivos locais, pacotes anteriores).
#
# Cria um .zip (ou .tar.gz) pronto para instalacao. O pacote final eh gerado
# em maintainers/.
#
# Uso (a partir da raiz do repo ou de maintainers/scripts/):
#   ./maintainers/scripts/pack.sh           → gera maintainers/<name>-v<version>.zip
#   ./maintainers/scripts/pack.sh --tar     → gera maintainers/<name>-v<version>.tar.gz

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
MAINTAINERS_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
REPO_ROOT="$(cd "$MAINTAINERS_DIR/.." && pwd)"
PLUGIN_DIR="$REPO_ROOT/plugin"
PLUGIN_NAME=$(grep -o '"name": "[^"]*"' "$PLUGIN_DIR/.claude-plugin/plugin.json" | head -1 | cut -d'"' -f4)
VERSION=$(grep -o '"version": "[^"]*"' "$PLUGIN_DIR/.claude-plugin/plugin.json" | cut -d'"' -f4)
PACK_NAME="${PLUGIN_NAME}-v${VERSION}"

if [[ ! -d "$PLUGIN_DIR" ]]; then
  echo "Erro: pasta plugin/ nao encontrada em $REPO_ROOT" >&2
  exit 1
fi

EXCLUDE=(
  ".git"
  ".git/**"
  ".git*"
  ".DS_Store"
  "**/.DS_Store"
  "*.zip"
  "*.tar.gz"
  "node_modules"
)
# Nota: sem exclude de "*.local.json" aqui de propósito — dentro de plugin/ só
# existe conteúdo-fonte do plugin (ex: templates/settings.local.json), nunca
# dado local de usuário de verdade. Excluir esse padrão já removeu um template
# real por engano quando o script ainda zipava o repo inteiro.

cd "$PLUGIN_DIR"

# Validacao minima antes de zipar (limites do validador de instalacao):
#  - description de SKILL.md e agents/*.md com no maximo 1024 caracteres e sem '<...>'
#  - todo SKILL.md e agent com frontmatter e campos name/description
FAIL=0
for f in skills/*/SKILL.md agents/*.md; do
  [[ -f "$f" ]] || continue
  if [[ "$(head -1 "$f")" != "---" ]]; then
    echo "Erro: $f sem frontmatter na primeira linha" >&2; FAIL=1; continue
  fi
  for field in name description; do
    grep -q "^${field}:" "$f" || { echo "Erro: $f sem campo '$field'" >&2; FAIL=1; }
  done
  DESC_LEN=$(grep -m1 '^description:' "$f" | sed 's/^description:[[:space:]]*//' | wc -c | tr -d ' ')
  if (( DESC_LEN > 1024 )); then
    echo "Erro: $f description com $DESC_LEN caracteres (max 1024)" >&2; FAIL=1
  fi
  if grep -m1 '^description:' "$f" | grep -q '<[^>]*>'; then
    echo "Erro: $f description contem '<...>' (o validador le como tag XML)" >&2; FAIL=1
  fi
done
(( FAIL == 0 )) || { echo "Empacotamento abortado." >&2; exit 1; }

# Remove pacotes anteriores em maintainers/
rm -f "$MAINTAINERS_DIR"/*.zip "$MAINTAINERS_DIR"/*.tar.gz

if [[ "${1:-}" == "--tar" ]]; then
  OUT="$MAINTAINERS_DIR/${PACK_NAME}.tar.gz"
  EXCLUDE_ARGS=()
  for pattern in "${EXCLUDE[@]}"; do
    EXCLUDE_ARGS+=(--exclude="$pattern")
  done
  tar czf "$OUT" "${EXCLUDE_ARGS[@]}" -C "$PLUGIN_DIR" .
else
  OUT="$MAINTAINERS_DIR/${PACK_NAME}.zip"
  EXCLUDE_ARGS=()
  for pattern in "${EXCLUDE[@]}"; do
    EXCLUDE_ARGS+=(-x "$pattern")
  done
  zip -r "$OUT" . "${EXCLUDE_ARGS[@]}" -q
fi

echo "Empacotado: $OUT ($(du -h "$OUT" | cut -f1))"
echo ""
echo "Para instalar em outro ambiente:"
echo "  1. Extraia o conteudo em uma pasta"
echo "  2. Use: claude --plugin-dir /caminho/para/a/pasta"
echo "  ou"
echo "  3. Copie para ~/.claude/plugins/ e registre no marketplace"
