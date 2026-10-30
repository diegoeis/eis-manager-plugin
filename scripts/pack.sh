#!/usr/bin/env bash
#
# pack.sh — Empacota o plugin para distribuicao
#
# O plugin final vive inteiro dentro da pasta src/ na raiz do repo — tudo
# que da suporte ao desenvolvimento (docs/, scripts/, .claude/) fica
# fora dela e nunca entra no pacote. Empacotar aqui significa zipar o
# CONTEUDO de src/ (nao a pasta em si), excluindo so lixo incidental
# (.DS_Store, arquivos locais, pacotes anteriores).
#
# Cria um .zip (ou .tar.gz) pronto para instalacao. O pacote final eh gerado
# em dist/.
#
# Uso (a partir da raiz do repo ou de scripts/):
#   ./scripts/pack.sh           → gera dist/<name>-v<version>.zip (ou <name>.zip sem version)
#   ./scripts/pack.sh --tar     → gera dist/<name>-v<version>.tar.gz

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PLUGIN_DIR="$REPO_ROOT/src"
DIST_DIR="$REPO_ROOT/dist"
PLUGIN_NAME=$(grep -o '"name": "[^"]*"' "$PLUGIN_DIR/.claude-plugin/plugin.json" | head -1 | cut -d'"' -f4)
# A versão do Claude fica em metadata.release (ou em "version", se existir) de
# src/.claude-plugin/plugin.json. src/plugin.json é o manifesto Agent Plugins v1
# (Hermes) e precisa ter a mesma versão em "version": o script recusa se divergirem.
VERSION=$(python3 -c 'import json,sys; m=json.load(open(sys.argv[1])); print(m.get("version") or m.get("metadata",{}).get("release",""))' "$PLUGIN_DIR/.claude-plugin/plugin.json")
HERMES_MANIFEST="$PLUGIN_DIR/plugin.json"
[[ -f "$HERMES_MANIFEST" ]] || { echo "Erro: src/plugin.json (manifesto Hermes) nao existe" >&2; exit 1; }
HVERSION=$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1])).get("version",""))' "$HERMES_MANIFEST")
if [[ "$HVERSION" != "$VERSION" ]]; then
  echo "Erro: versao diverge: src/plugin.json tem \"$HVERSION\", src/.claude-plugin/plugin.json tem \"$VERSION\". Suba as duas." >&2
  exit 1
fi
# ${CLAUDE_PLUGIN_ROOT} so eh expandido pelo Claude Code; no Hermes o caminho quebra.
if grep -rn --include='*.md' --include='*.json' 'CLAUDE_PLUGIN_ROOT' "$PLUGIN_DIR" >&2; then
  echo "Erro: use caminho relativo a pasta da skill em vez de \${CLAUDE_PLUGIN_ROOT}." >&2
  exit 1
fi
if [[ -n "$VERSION" ]]; then
  PACK_NAME="${PLUGIN_NAME}-v${VERSION}"
else
  PACK_NAME="${PLUGIN_NAME}"
fi

if [[ ! -d "$PLUGIN_DIR" ]]; then
  echo "Erro: pasta src/ nao encontrada em $REPO_ROOT" >&2
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
# Nota: sem exclude de "*.local.json" aqui de propósito — dentro de src/ só
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

# Remove pacotes anteriores em dist/
mkdir -p "$DIST_DIR"
rm -f "$DIST_DIR"/*.zip "$DIST_DIR"/*.tar.gz

if [[ "${1:-}" == "--tar" ]]; then
  OUT="$DIST_DIR/${PACK_NAME}.tar.gz"
  EXCLUDE_ARGS=()
  for pattern in "${EXCLUDE[@]}"; do
    EXCLUDE_ARGS+=(--exclude="$pattern")
  done
  tar czf "$OUT" "${EXCLUDE_ARGS[@]}" -C "$PLUGIN_DIR" .
else
  OUT="$DIST_DIR/${PACK_NAME}.zip"
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
