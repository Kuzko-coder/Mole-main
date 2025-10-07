#!/bin/bash
# Lightweight alias to run Mole via `mo`
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec "$SCRIPT_DIR/mole" "$@"
