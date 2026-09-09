#!/usr/bin/env python3
"""
init_data_root.py — cria ~/.claude/manager-assistant/ e um config.json inicial.

Teste de alcance: verifica se um script executado pela skill consegue gravar
fora da pasta conectada à sessão (Cowork) ou do diretório de trabalho (Claude Code).

Uso:
  python3 init_data_root.py            # cria se não existir; não sobrescreve
  python3 init_data_root.py --force    # sobrescreve o config.json
  python3 init_data_root.py --path /outro/caminho

Saída: uma linha JSON com o resultado, e exit code 0 (ok) ou 1 (falha).
"""

import argparse
import datetime as dt
import json
import os
import sys
from pathlib import Path

DEFAULT_ROOT = Path.home() / ".claude" / "manager-assistant"


def build_config(root: Path) -> dict:
    return {
        "plugin": "eis-manager-assistant",
        "version": 1,
        "dataRoot": str(root),
        "activeWorkspace": None,
        "workspaces": {},
        "createdAt": dt.date.today().isoformat(),
        "createdBy": "init_data_root.py",
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--path", type=Path, default=DEFAULT_ROOT, help="raiz de dados (padrão: ~/.claude/manager-assistant)")
    parser.add_argument("--force", action="store_true", help="sobrescreve config.json se existir")
    args = parser.parse_args()

    root: Path = args.path.expanduser().resolve()
    config_path = root / "config.json"
    result = {
        "dataRoot": str(root),
        "configPath": str(config_path),
        "home": str(Path.home()),
        "user": os.environ.get("USER") or os.environ.get("USERNAME"),
        "cwd": os.getcwd(),
    }

    try:
        root.mkdir(parents=True, exist_ok=True)
        (root / "workspaces").mkdir(exist_ok=True)
        result["dirCreated"] = True
    except Exception as e:  # noqa: BLE001
        result.update(status="error", step="mkdir", error=f"{type(e).__name__}: {e}")
        print(json.dumps(result, ensure_ascii=False))
        return 1

    if config_path.exists() and not args.force:
        result.update(status="exists", configWritten=False)
        try:
            result["existing"] = json.loads(config_path.read_text(encoding="utf-8"))
        except Exception as e:  # noqa: BLE001
            result["existingReadError"] = f"{type(e).__name__}: {e}"
        print(json.dumps(result, ensure_ascii=False))
        return 0

    try:
        config_path.write_text(json.dumps(build_config(root), ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        # Relê para confirmar que a gravação chegou no disco.
        json.loads(config_path.read_text(encoding="utf-8"))
        result.update(status="created", configWritten=True)
        print(json.dumps(result, ensure_ascii=False))
        return 0
    except Exception as e:  # noqa: BLE001
        result.update(status="error", step="write", error=f"{type(e).__name__}: {e}")
        print(json.dumps(result, ensure_ascii=False))
        return 1


if __name__ == "__main__":
    sys.exit(main())
