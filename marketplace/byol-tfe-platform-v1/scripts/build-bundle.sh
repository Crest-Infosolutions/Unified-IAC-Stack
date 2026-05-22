#!/usr/bin/env bash

set -euo pipefail

# shellcheck source=./common.sh
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/common.sh"

usage() {
  cat <<'EOF'
Usage: ./scripts/build-bundle.sh [--force]

Runs the BYOL TFE v1 Marketplace preflight checks and then executes cpa buildbundle.

Options:
  --force      Pass --force to cpa buildbundle.
  -h, --help   Show this help text.
EOF
}

force_bundle=false

while (( $# > 0 )); do
  case "$1" in
    --force)
      force_bundle=true
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      fail "Unknown argument: $1"
      ;;
  esac
  shift
done

init_package_context
run_local_preflight

if [[ "$force_bundle" == "true" ]]; then
  run_cpa buildbundle --force
else
  run_cpa buildbundle
fi