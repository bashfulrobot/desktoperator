#!/usr/bin/env bash

set -euo pipefail

# Shared configuration with the Codex CLI role lives under roles/apps/codex-cli/.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
CODEX_ROLE_DIR="${REPO_ROOT}/roles/apps/codex-cli"
MCP_SITES_FILE="${CODEX_ROLE_DIR}/files/mcp-sites.json"

declare -a DEFAULT_URLS=()

# Tuning knobs (override via environment variables when needed).
DEFAULT_CONCURRENCY="${SITEMCP_CONCURRENCY:-10}"
DEFAULT_TOOL_STRATEGY="${SITEMCP_TOOL_STRATEGY:-pathname}"
SITEMCP_BIN="${SITEMCP_BIN:-sitemcp}"
CACHE_LOG_FILE="${MCP_CACHE_LOG_FILE:-/var/log/mcp-cache/mcp-cache.log}"

declare -a URL_SELECTION=()

trim_string() {
  local input=$1
  input=${input//$'\r'/}
  input="${input#"${input%%[![:space:]]*}"}"
  input="${input%"${input##*[![:space:]]}"}"
  printf '%s' "$input"
}

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    printf 'Required command "%s" not found in PATH.\n' "$1" >&2
    exit 1
  fi
}

log_to_file() {
  local level=$1
  shift
  local msg="$*"
  local timestamp
  timestamp=$(date '+%Y-%m-%d %H:%M:%S')

  if [[ -n ${CACHE_LOG_FILE:-} ]] && [[ -w ${CACHE_LOG_FILE} || -w $(dirname "${CACHE_LOG_FILE}") ]]; then
    printf '[%s] %s: %s\n' "$timestamp" "$level" "$msg" >> "$CACHE_LOG_FILE" 2>/dev/null || true
  fi
}

log_info() {
  gum log --level info "$@"
  log_to_file "INFO" "$@"
}

log_warn() {
  gum log --level warn "$@"
  log_to_file "WARN" "$@"
}

log_error() {
  gum log --level error "$@"
  log_to_file "ERROR" "$@"
}

load_default_urls() {
  local -a urls=()

  if [[ -f $MCP_SITES_FILE ]]; then
    mapfile -t urls < <(python3 - "$MCP_SITES_FILE" <<'PY'
import json
import sys
from pathlib import Path

path = Path(sys.argv[1])
with path.open(encoding="utf-8") as handle:
    data = json.load(handle)

for entry in data:
    url = (entry.get("url") or "").strip()
    if url:
        print(url)
PY
    )

    if ((${#urls[@]} == 0)); then
      log_warn "No URLs discovered in ${MCP_SITES_FILE}, falling back to builtin defaults."
    fi
  else
    log_warn "Unable to locate ${MCP_SITES_FILE}, falling back to builtin defaults."
  fi

  if ((${#urls[@]} == 0)); then
    urls=(
      "https://developer.konghq.com/index/mesh/"
      "https://developer.konghq.com/index/dev-portal/"
      "https://developer.konghq.com/index/advanced-analytics/"
      "https://developer.konghq.com/index/catalog/"
      "https://developer.konghq.com/index/gateway/#gateway-manager"
      "https://developer.konghq.com/index/insomnia"
      "https://developer.konghq.com/index/gateway/"
      "https://developer.konghq.com/index/ai-gateway/"
      "https://developer.konghq.com/index/kubernetes-ingress-controller/"
      "https://developer.konghq.com/index/operator/"
      "https://developer.konghq.com/index/event-gateway/"
      "https://developer.konghq.com/konnect-platform/authentication/"
      "https://developer.konghq.com/konnect-platform/sso/"
      "https://developer.konghq.com/konnect-platform/teams-and-roles/"
      "https://developer.konghq.com/konnect-platform/account/"
      "https://developer.konghq.com/konnect-platform/geos/"
      "https://developer.konghq.com/index/konnect-platform/#org-management"
      "https://developer.konghq.com/how-to/collect-audit-logs/"
      "https://developer.konghq.com/how-to/collect-dev-portal-audit-logs/"
      "https://developer.konghq.com/konnect-platform/audit-logs/"
      "https://developer.konghq.com/how-to/"
    )
  fi

  DEFAULT_URLS=("${urls[@]}")
}

sanitise_url() {
  local url=$1
  local no_proto=$url

  if [[ $no_proto == *"://"* ]]; then
    no_proto=${no_proto#*://}
  fi
  no_proto=${no_proto#//}

  # Replace non-alphanumeric characters with a single dash and trim the edges.
  local sanitized
  sanitized=$(printf '%s' "$no_proto" | sed -E 's/[^[:alnum:]]/-/g; s/-+/-/g; s/^-+//; s/-+$//')
  printf '%s' "$sanitized"
}

format_sitemcp_line() {
  local line=$1
  case $line in
    INFO\ *)
      log_info "${line#INFO }"
      ;;
    WARN\ *)
      log_warn "${line#WARN }"
      ;;
    ERROR\ *)
      log_error "${line#ERROR }"
      ;;
    *)
      printf '%s\n' "$line"
      ;;
  esac
}

select_urls() {
  if (($# > 0)); then
    # Special case: --all flag processes all default URLs non-interactively
    if [[ $1 == "--all" ]]; then
      URL_SELECTION=("${DEFAULT_URLS[@]}")
      if ((${#URL_SELECTION[@]} == 0)); then
        log_warn "No default URLs available, exiting."
        exit 0
      fi
      return
    fi

    URL_SELECTION=()
    local arg trimmed
    for arg in "$@"; do
      trimmed=$(trim_string "$arg")
      [[ -z $trimmed ]] && continue
      URL_SELECTION+=("$trimmed")
    done
    if ((${#URL_SELECTION[@]} == 0)); then
      log_warn "No usable URLs provided, exiting."
      exit 0
    fi
    return
  fi

  local -a options=("${DEFAULT_URLS[@]}" "[Add custom URL]")

  local selection
  selection=$(printf '%s\n' "${options[@]}" | gum choose --no-limit --header "Select site(s) to refresh cache (Tab/Ctrl+Space to select, Enter to confirm)")
  local exit_code=$?

  if ((exit_code != 0)); then
    log_warn "Selection cancelled, exiting."
    exit 0
  fi

  if [[ -z $selection ]]; then
    log_warn "No items selected. Remember to press Tab or Ctrl+Space to select items before pressing Enter."
    exit 0
  fi

  readarray -t selections <<<"$selection"
  if ((${#selections[@]} == 0)); then
    log_warn "No URLs selected, exiting."
    exit 0
  fi

  local -a chosen=()
  for entry in "${selections[@]}"; do
    local trimmed_entry
    trimmed_entry=$(trim_string "$entry")
    [[ -z $trimmed_entry ]] && continue
    if [[ $trimmed_entry == "[Add custom URL]" ]]; then
      local input
      if ! input=$(gum input --prompt "Enter URL: " --placeholder "https://example.com/docs"); then
        log_warn "Cancelled adding custom URL, skipping."
        continue
      fi
      input=$(trim_string "$input")
      if [[ -z $input ]]; then
        log_warn "Empty URL skipped."
        continue
      fi
      chosen+=("$input")
    else
      chosen+=("$trimmed_entry")
    fi
  done

  if ((${#chosen[@]} == 0)); then
    log_warn "No URLs selected after filtering, exiting."
    exit 0
  fi

  URL_SELECTION=("${chosen[@]}")
}

cache_site() {
  local url=$1
  url=$(trim_string "$url")
  if [[ -z $url ]]; then
    log_warn "Skipping empty URL entry."
    return 1
  fi
  log_info "Caching ${url}"

  local sanitized
  sanitized=$(sanitise_url "$url")
  if [[ -z $sanitized ]]; then
    log_error "Unable to derive cache filename for ${url}"
    return 1
  fi

  local cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/sitemcp"
  local expected_cache="${cache_dir}/${sanitized}.json"
  log_info "Expected cache path ${expected_cache}"

  local -a cmd=("stdbuf" "-oL" "-eL" "$SITEMCP_BIN" "$url" "--concurrency" "$DEFAULT_CONCURRENCY" "-t" "$DEFAULT_TOOL_STRATEGY")
  if [[ -n ${SITEMCP_EXTRA_FLAGS:-} ]]; then
    # shellcheck disable=SC2206 # deliberate word splitting to honour provided flags.
    local -a extra_flags=(${SITEMCP_EXTRA_FLAGS})
    cmd+=("${extra_flags[@]}")
  fi

  local cache_path=""
  local killed=0
  local exit_status=0

  coproc SITEMCP_PROCESS { "${cmd[@]}" 2>&1; }
  local pid=$SITEMCP_PROCESS_PID
  local coproc_stdout_fd="${SITEMCP_PROCESS[0]}"
  local coproc_stdin_fd="${SITEMCP_PROCESS[1]}"
  exec {coproc_stdin_fd}>&-

  while IFS= read -r line <&"$coproc_stdout_fd"; do
    [[ -z $line ]] && continue
    format_sitemcp_line "$line"
    if [[ $line == *"Cache file written to"* ]]; then
      cache_path=${line#*Cache file written to }
      cache_path=$(trim_string "$cache_path")
      # Brief pause to ensure cache file is fully written to disk
      sleep 0.2
      killed=1
      kill -TERM "$pid" 2>/dev/null || true
      break
    fi
  done

  while IFS= read -r -t 0.1 line <&"$coproc_stdout_fd"; do
    [[ -z $line ]] && continue
    format_sitemcp_line "$line"
  done 2>/dev/null || true

  exec {coproc_stdout_fd}>&-

  if ! wait "$pid"; then
    exit_status=$?
  fi
  if ((killed)) && ((exit_status == 143)); then
    exit_status=0
  fi

  if ((exit_status != 0)); then
    log_error "sitemcp exited with status ${exit_status} for ${url}"
    return "$exit_status"
  fi

  if [[ -z $cache_path ]]; then
    if [[ -f $expected_cache ]]; then
      cache_path=$expected_cache
    else
      log_warn "Cache file not detected for ${url}"
      return 1
    fi
  fi

  log_info "Cache ready at ${cache_path}"
}

main() {
  require_cmd gum
  require_cmd "$SITEMCP_BIN"
  require_cmd stdbuf
  require_cmd python3

  log_info "========================================"
  log_info "MCP Cache Update Started"
  log_info "========================================"

  load_default_urls
  select_urls "$@"

  log_info "Processing ${#URL_SELECTION[@]} site(s)."

  local failures=0
  local url
  for url in "${URL_SELECTION[@]}"; do
    if ! cache_site "$url"; then
      ((failures++))
    fi
  done

  if ((failures > 0)); then
    log_error "Failed to update ${failures} site(s)."
    log_info "========================================"
    log_info "MCP Cache Update Completed (WITH ERRORS)"
    log_info "========================================"
    exit 1
  fi

  log_info "All caches refreshed."
  log_info "========================================"
  log_info "MCP Cache Update Completed Successfully"
  log_info "========================================"
}

main "$@"
