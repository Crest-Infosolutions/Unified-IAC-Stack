#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PACKAGE_DIR_DEFAULT="$(cd -- "$SCRIPT_DIR/.." && pwd)"

if [[ -f "$PACKAGE_DIR_DEFAULT/.env" ]]; then
  set -a
  # shellcheck disable=SC1091
  source "$PACKAGE_DIR_DEFAULT/.env"
  set +a
fi

log() {
  printf '[%s] %s\n' "$1" "$2"
}

info() {
  log INFO "$1"
}

warn() {
  log WARN "$1" >&2
}

fail() {
  log ERROR "$1" >&2
  exit 1
}

require_command() {
  local command_name="$1"

  if ! command -v "$command_name" >/dev/null 2>&1; then
    fail "Required command not found: $command_name"
  fi
}

select_container_runtime() {
  if command -v docker >/dev/null 2>&1; then
    printf 'docker\n'
    return
  fi

  if command -v podman >/dev/null 2>&1; then
    printf 'podman\n'
    return
  fi

  fail "Required container runtime not found: docker or podman"
}

detect_container_socket() {
  if [[ -n "${CPA_CONTAINER_SOCKET:-}" && -S "${CPA_CONTAINER_SOCKET}" ]]; then
    printf '%s\n' "$CPA_CONTAINER_SOCKET"
    return
  fi

  if [[ -S /var/run/docker.sock ]]; then
    printf '/var/run/docker.sock\n'
    return
  fi

  if [[ -S /run/podman/podman.sock ]]; then
    printf '/run/podman/podman.sock\n'
    return
  fi

  if [[ -n "${XDG_RUNTIME_DIR:-}" && -S "$XDG_RUNTIME_DIR/podman/podman.sock" ]]; then
    printf '%s\n' "$XDG_RUNTIME_DIR/podman/podman.sock"
    return
  fi
}

require_env_vars() {
  local missing=()
  local var_name

  for var_name in "$@"; do
    if [[ -z "${!var_name:-}" ]]; then
      missing+=("$var_name")
    fi
  done

  if (( ${#missing[@]} > 0 )); then
    fail "Missing required environment variables: ${missing[*]}. Copy .env.example to .env and populate the values first."
  fi
}

resolve_path() {
  local path_value="$1"

  if [[ "$path_value" = /* ]]; then
    printf '%s\n' "$path_value"
    return
  fi

  printf '%s\n' "$MARKETPLACE_PACKAGE_DIR/$path_value"
}

manifest_value() {
  local key="$1"

  awk -v key="$key" '
    index($0, key ":") == 1 {
      value = substr($0, index($0, ":") + 1)
      sub(/[[:space:]]+#.*$/, "", value)
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", value)
      gsub(/^"|"$/, "", value)
      print value
      exit
    }
  ' "$MANIFEST_FILE"
}

ensure_file_exists() {
  local file_path="$1"

  if [[ ! -f "$file_path" ]]; then
    fail "Required file not found: $file_path"
  fi
}

ensure_directory_exists() {
  local dir_path="$1"

  if [[ ! -d "$dir_path" ]]; then
    fail "Required directory not found: $dir_path"
  fi
}

init_package_context() {
  require_env_vars REGISTRY_NAME REGISTRY_SERVER BUNDLE_VERSION MARKETPLACE_PACKAGE_DIR

  MARKETPLACE_PACKAGE_DIR="$(cd -- "$MARKETPLACE_PACKAGE_DIR" && pwd)"
  CHART_DIR="$MARKETPLACE_PACKAGE_DIR/chart"
  MANIFEST_FILE="$MARKETPLACE_PACKAGE_DIR/manifest.yaml"
  MAIN_TEMPLATE_FILE="$MARKETPLACE_PACKAGE_DIR/mainTemplate.json"
  UI_DEFINITION_FILE="$MARKETPLACE_PACKAGE_DIR/createUiDefinition.json"
  DEFAULT_VALUES_FILE="$MARKETPLACE_PACKAGE_DIR/examples/values.enterprise.example.yaml"
  PARTNERCENTER_VALUES_FILE="$MARKETPLACE_PACKAGE_DIR/examples/values.partnercenter.example.yaml"
  HELM_RELEASE_NAME="${HELM_RELEASE_NAME:-byol-tfe-platform}"
  VALUES_FILE="${VALUES_FILE:-examples/values.enterprise.example.yaml}"
  VALUES_FILE="$(resolve_path "$VALUES_FILE")"
  CPA_IMAGE="${CPA_IMAGE:-mcr.microsoft.com/container-package-app:latest}"
  ALLOW_UNSUPPORTED_HOST="${ALLOW_UNSUPPORTED_HOST:-false}"

  ensure_directory_exists "$MARKETPLACE_PACKAGE_DIR"
  ensure_directory_exists "$CHART_DIR"
  ensure_file_exists "$MANIFEST_FILE"
  ensure_file_exists "$MAIN_TEMPLATE_FILE"
  ensure_file_exists "$UI_DEFINITION_FILE"
  ensure_file_exists "$VALUES_FILE"
}

validate_manifest_metadata() {
  local manifest_version
  local manifest_registry_server
  local required_key

  for required_key in applicationName publisher description version helmChart clusterArmTemplate uiDefinition registryServer; do
    if [[ -z "$(manifest_value "$required_key")" ]]; then
      fail "manifest.yaml is missing a value for '$required_key'"
    fi
  done

  manifest_version="$(manifest_value version)"
  manifest_registry_server="$(manifest_value registryServer)"

  if [[ ! "$manifest_version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    fail "manifest.yaml version must use #.#.# format. Found: $manifest_version"
  fi

  if [[ "$manifest_version" != "$BUNDLE_VERSION" ]]; then
    fail "BUNDLE_VERSION ($BUNDLE_VERSION) must match manifest.yaml version ($manifest_version)."
  fi

  if [[ "$manifest_registry_server" != "$REGISTRY_SERVER" ]]; then
    fail "manifest.yaml registryServer ($manifest_registry_server) must match REGISTRY_SERVER ($REGISTRY_SERVER)."
  fi

  if [[ "$manifest_registry_server" == "youracr.azurecr.io" ]]; then
    fail "manifest.yaml registryServer still uses the placeholder youracr.azurecr.io. Set your publisher ACR before packaging."
  fi
}

validate_manifest_version_bump() {
  local repo_root
  local relative_manifest
  local head_version
  local current_version

  if ! repo_root="$(git -C "$MARKETPLACE_PACKAGE_DIR" rev-parse --show-toplevel 2>/dev/null)"; then
    warn "Skipping manifest version bump check because the package is not inside a git worktree."
    return
  fi

  relative_manifest="${MANIFEST_FILE#$repo_root/}"
  current_version="$(manifest_value version)"

  if ! git -C "$repo_root" cat-file -e "HEAD:$relative_manifest" 2>/dev/null; then
    warn "Skipping manifest version bump check because manifest.yaml is not present in HEAD yet."
    return
  fi

  if git -C "$repo_root" diff --quiet HEAD -- "$relative_manifest"; then
    info "Skipping manifest version bump check because manifest.yaml matches HEAD."
    return
  fi

  head_version="$(git -C "$repo_root" show "HEAD:$relative_manifest" | awk '
    index($0, "version:") == 1 {
      value = substr($0, index($0, ":") + 1)
      sub(/[[:space:]]+#.*$/, "", value)
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", value)
      print value
      exit
    }
  ')"

  if [[ -n "$head_version" && "$head_version" == "$current_version" ]]; then
    fail "manifest.yaml version is unchanged from HEAD ($current_version). Bump the version before packaging."
  fi
}

validate_no_blocking_placeholders() {
  local placeholder_hits

  placeholder_hits="$({
    grep -InE 'youracr\.azurecr\.io|<registry-name>|<yourACRname\.azurecr\.io>|__REPLACE_ME__|REPLACE_ME' "$MANIFEST_FILE" "$MAIN_TEMPLATE_FILE" "$UI_DEFINITION_FILE" 2>/dev/null || true
  } | grep -v 'DONOTMODIFY' || true)"

  if [[ -n "$placeholder_hits" ]]; then
    fail "Blocking placeholder content remains in Marketplace artifacts:\n$placeholder_hits"
  fi
}

validate_no_latest_tags() {
  local latest_hits

  latest_hits="$(grep -RInE 'tag:[[:space:]]*latest([[:space:]]|$)|image:[[:space:]]*[^[:space:]]+:latest([[:space:]]|$)' "$CHART_DIR" --include='*.yaml' --include='*.tpl' 2>/dev/null || true)"

  if [[ -n "$latest_hits" ]]; then
    fail "Mutable image tags remain in the chart:\n$latest_hits"
  fi
}

run_helm_validation() {
  info "Running Helm lint with $VALUES_FILE"
  helm lint "$CHART_DIR" -f "$VALUES_FILE"

  info "Rendering chart with $VALUES_FILE"
  helm template "$HELM_RELEASE_NAME" "$CHART_DIR" -f "$VALUES_FILE" >/dev/null

  if [[ -f "$PARTNERCENTER_VALUES_FILE" && "$PARTNERCENTER_VALUES_FILE" != "$VALUES_FILE" ]]; then
    info "Rendering chart with $PARTNERCENTER_VALUES_FILE"
    helm template "$HELM_RELEASE_NAME" "$CHART_DIR" -f "$PARTNERCENTER_VALUES_FILE" >/dev/null
  fi
}

run_json_validation() {
  info "Validating Marketplace JSON artifacts"
  jq empty "$MAIN_TEMPLATE_FILE"
  jq empty "$UI_DEFINITION_FILE"
}

run_local_preflight() {
  require_command helm
  require_command jq
  require_command git
  require_command grep
  require_command awk

  validate_manifest_metadata
  validate_manifest_version_bump
  validate_no_blocking_placeholders
  validate_no_latest_tags
  run_helm_validation
  run_json_validation
}

assert_supported_cpa_host() {
  local host_os
  local host_arch

  host_os="$(uname -s)"
  host_arch="$(uname -m)"

  if [[ "$host_os" == "Linux" && "$host_arch" == "x86_64" ]]; then
    return
  fi

  if [[ "$ALLOW_UNSUPPORTED_HOST" == "true" ]]; then
    warn "Continuing on unsupported CPA host $host_os/$host_arch because ALLOW_UNSUPPORTED_HOST=true. Microsoft documents CPA packaging support for Linux/Windows AMD64 hosts."
    return
  fi

  fail "CPA packaging is documented for Linux/Windows AMD64 hosts. Current host is $host_os/$host_arch. Re-run this step in Linux CI, WSL, or set ALLOW_UNSUPPORTED_HOST=true to attempt it anyway."
}

run_cpa() {
  local cpa_subcommand="$1"
  shift

  local container_runtime
  local container_socket
  local container_args=(
    --rm
    -e "REGISTRY_NAME=$REGISTRY_NAME"
    -v "$MARKETPLACE_PACKAGE_DIR:/data"
    -w /data
  )

  container_runtime="$(select_container_runtime)"
  container_socket="$(detect_container_socket || true)"

  assert_supported_cpa_host

  if [[ -n "$container_socket" ]]; then
    container_args+=(-v "$container_socket:/var/run/docker.sock")
  elif [[ "$cpa_subcommand" == "buildbundle" ]]; then
    warn "No Docker-compatible container socket detected. cpa buildbundle may fail without one."
  fi

  if [[ -d "$HOME/.docker" ]]; then
    container_args+=(-v "$HOME/.docker:/root/.docker:ro")
  elif [[ -f "$HOME/.config/containers/auth.json" ]]; then
    container_args+=(-v "$HOME/.config/containers/auth.json:/root/.docker/config.json:ro")
  fi

  if [[ -d "$HOME/.azure" ]]; then
    container_args+=(-v "$HOME/.azure:/root/.azure:ro")
  fi

  info "Using container runtime $container_runtime"
  info "Pulling CPA image $CPA_IMAGE"
  "$container_runtime" pull "$CPA_IMAGE" >/dev/null

  info "Running cpa $cpa_subcommand"
  "$container_runtime" run "${container_args[@]}" --entrypoint /bin/bash "$CPA_IMAGE" -lc "set -euo pipefail; cpa $cpa_subcommand $*"
}