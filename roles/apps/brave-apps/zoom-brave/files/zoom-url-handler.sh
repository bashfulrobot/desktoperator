#!/usr/bin/env bash
set -euo pipefail

URL="${1:-}"
LOGFILE="${XDG_DATA_HOME:-$HOME/.local/share}/zoom-url-handler.log"

# Log function
log() {
  mkdir -p "$(dirname "$LOGFILE")"
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$LOGFILE"
}

log "=== Zoom URL Handler invoked ==="
log "Input URL: $URL"

# Validate we got a URL
if [[ -z "$URL" ]]; then
  log "ERROR: No URL provided"
  echo "Error: No URL provided" >&2
  exit 1
fi

# Function to extract meeting details from zoommtg:// protocol
parse_zoommtg_url() {
  local url="$1"

  if [[ "$url" =~ confno=([0-9]+) ]]; then
    local meeting_id="${BASH_REMATCH[1]}"
    local host="zoom.us"

    # Extract host if present (e.g., zoommtg://konghq.zoom.us/...)
    if [[ "$url" =~ zoommtg://([^/\?]+) ]]; then
      host="${BASH_REMATCH[1]}"
    fi

    # Extract password if present
    local pwd=""
    if [[ "$url" =~ pwd=([^&]+) ]]; then
      pwd="${BASH_REMATCH[1]}"
    fi

    # Build web client URL
    if [[ -n "$pwd" ]]; then
      echo "https://${host}/wc/join/${meeting_id}?pwd=${pwd}"
    else
      echo "https://${host}/wc/join/${meeting_id}"
    fi
  else
    log "ERROR: Could not parse zoommtg:// URL"
    echo "Error: Could not parse zoommtg:// URL: $url" >&2
    return 1
  fi
}

# Function to transform HTTP(S) Zoom URLs
transform_zoom_url() {
  local url="$1"

  # Already in web client format (/wc/join/) - pass through
  if [[ "$url" =~ /wc/join/ ]]; then
    log "URL already in /wc/join/ format, passing through"
    echo "$url"
    return 0
  fi

  # Transform /j/ format to /wc/join/ format
  if [[ "$url" =~ /j/ ]]; then
    local transformed=$(echo "$url" | sed -E 's|(.*//)([^/]+\.zoom\.us)/j/(.*)|\1\2/wc/join/\3|')
    log "Transformed /j/ URL to /wc/join/: $transformed"
    echo "$transformed"
    return 0
  fi

  # Already a zoom.us URL but not in known format - pass through as-is
  # (e.g., https://zoom.us/wc/home, https://zoom.us/profile, etc.)
  if [[ "$url" =~ zoom\.us ]]; then
    log "Zoom URL in unknown format, passing through: $url"
    echo "$url"
    return 0
  fi

  # Not a Zoom URL at all
  return 1
}

# Main routing logic
case "$URL" in
  zoommtg://*)
    log "Detected zoommtg:// protocol"
    TRANSFORMED_URL=$(parse_zoommtg_url "$URL")
    if [[ $? -eq 0 ]]; then
      log "Launching brave-Zoom with: $TRANSFORMED_URL"
      exec /usr/local/bin/brave-Zoom "$TRANSFORMED_URL"
    else
      log "ERROR: Failed to parse zoommtg:// URL"
      exit 1
    fi
    ;;

  *zoom.us*)
    log "Detected zoom.us HTTPS URL"
    TRANSFORMED_URL=$(transform_zoom_url "$URL")
    if [[ $? -eq 0 ]]; then
      log "Launching brave-Zoom with: $TRANSFORMED_URL"
      exec /usr/local/bin/brave-Zoom "$TRANSFORMED_URL"
    else
      log "WARNING: Not a recognized Zoom URL, passing to default browser"
      exec brave-browser "$URL"
    fi
    ;;

  *)
    log "WARNING: Non-Zoom URL passed to handler: $URL"
    echo "Warning: Non-Zoom URL passed to Zoom handler, opening in default browser: $URL" >&2
    exec brave-browser "$URL"
    ;;
esac
