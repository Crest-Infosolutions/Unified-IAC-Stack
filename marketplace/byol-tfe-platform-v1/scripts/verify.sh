#!/usr/bin/env bash

set -euo pipefail

# shellcheck source=./common.sh
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/common.sh"

usage() {
  cat <<'EOF'
Usage: ./scripts/verify.sh [--with-cpa]

Runs Marketplace package preflight validation for the BYOL TFE v1 offer.

Options:
  --with-cpa   Also run cpa verify through the Microsoft packaging container.
  -h, --help   Show this help text.
EOF
}

run_cpa_verify=false

while (( $# > 0 )); do
  case "$1" in
    --with-cpa)
      run_cpa_verify=true
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

if [[ "$run_cpa_verify" == "true" ]]; then
  run_cpa verify
else
  info "Local preflight verification completed. Re-run with --with-cpa on a supported CPA host to invoke cpa verify."
fi