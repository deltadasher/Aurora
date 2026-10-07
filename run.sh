#!/usr/bin/env bash
set -euo pipefail
AURORA_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
if [[ -x "$AURORA_DIR/bin/aurora-notes" ]]; then
    exec "$AURORA_DIR/bin/aurora-notes" "$@"
fi
cmake -S "$AURORA_DIR" -B "$AURORA_DIR/build" -DBUILD_TESTING=OFF
cmake --build "$AURORA_DIR/build" --parallel 2
exec "$AURORA_DIR/build/aurora-notes" "$@"
