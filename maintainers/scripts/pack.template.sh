#!/usr/bin/env bash
#
# pack.template.sh — Template do script de empacotamento do plugin
#
# COMO USAR ESTE TEMPLATE:
# Este arquivo NAO deve ser executado diretamente. Ele serve como base para a IA
# gerar um `pack.sh` customizado numa nova instalacao/plugin. Peca a IA para:
#
#   "Leia maintainers/scripts/pack.template.sh e gere um maintainers/scripts/pack.sh
#    para este plugin, substituindo os marcadores {{...}} pelos valores corretos."
#
# MARCADORES A SUBSTITUIR:
#   {{PLUGIN_NAME}}          Nome do plugin (ex: "spoiler-framework-plugin")
#                            Deve bater com o "name" em .claude-plugin/plugin.json
#   {{PLUGIN_JSON_PATH}}     Caminho do plugin.json relativo a raiz do plugin
#                            (padrao: ".claude-plugin/plugin.json")
#   {{EXTRA_EXCLUDES}}       Padroes adicionais a excluir do pacote, um por linha,
#                            no mesmo formato dos outros itens do array EXCLUDE.
#                            Deixe vazio se nao houver.
#
# O QUE O SCRIPT GERADO FAZ:
# Cria um .zip (ou .tar.gz) pronto para instalacao, excluindo .git, .DS_Store,
# a pasta maintainers/ e outros arquivos que nao fazem parte do plugin.
# O pacote final eh gerado em maintainers/.
#
# Uso (a partir da raiz do plugin ou de maintainers/scripts/):
#   ./maintainers/scripts/pack.sh           → gera maintainers/<name>-v<version>.zip
#   ./maintainers/scripts/pack.sh --tar     → gera maintainers/<name>-v<version>.tar.gz

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
MAINTAINERS_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PLUGIN_DIR="$(cd "$MAINTAINERS_DIR/.." && pwd)"
PLUGIN_NAME="{{PLUGIN_NAME}}"
VERSION=$(grep -o '"version": "[^"]*"' "$PLUGIN_DIR/{{PLUGIN_JSON_PATH}}" | cut -d'"' -f4)
PACK_NAME="${PLUGIN_NAME}-v${VERSION}"

EXCLUDE=(
  ".git"
  ".git/**"
  ".git*"
  ".DS_Store"
  "**/.DS_Store"
  "maintainers/*"
  "maintainers"
  "${PLUGIN_NAME}"
  "*.zip"
  "*.tar.gz"
  ".claude/plans/**"
  "node_modules"
  "*.local.json"
  {{EXTRA_EXCLUDES}}
)

cd "$PLUGIN_DIR"

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
