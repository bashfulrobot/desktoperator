#!/usr/bin/env bash

set -e

echo "Starting Kong documentation cache refresh..."

# Note: Each product uses isolated cache directories via XDG_CACHE_HOME
# to ensure separate cache files and prevent token limit issues.
# We use timeout to kill the MCP server after cache is built since
# sitemcp doesn't have a cache-only mode.

MCP_BASE_DIR="$HOME/Documents/Kong/My-drive/Docs/Mcp"

# Gateway
echo "Caching Kong Gateway docs..."
timeout 600 env XDG_CACHE_HOME="$MCP_BASE_DIR/gateway/.cache" \
  sitemcp https://developer.konghq.com/ -m "/gateway/**" --concurrency 20 || true

# Konnect Platform
echo "Caching Konnect Platform docs..."
timeout 600 env XDG_CACHE_HOME="$MCP_BASE_DIR/konnect/.cache" \
  sitemcp https://developer.konghq.com/ -m "/konnect/**" -m "/konnect-platform/**" --concurrency 20 || true

# AI Gateway
echo "Caching AI Gateway docs..."
timeout 600 env XDG_CACHE_HOME="$MCP_BASE_DIR/ai-gateway/.cache" \
  sitemcp https://developer.konghq.com/ -m "/ai-gateway/**" --concurrency 20 || true

# Kong Mesh
echo "Caching Kong Mesh docs..."
timeout 600 env XDG_CACHE_HOME="$MCP_BASE_DIR/mesh/.cache" \
  sitemcp https://developer.konghq.com/ -m "/mesh/**" -m "/mesh-manager/**" --concurrency 20 || true

# Plugins
echo "Caching Kong Plugins docs..."
timeout 600 env XDG_CACHE_HOME="$MCP_BASE_DIR/plugins/.cache" \
  sitemcp https://developer.konghq.com/ -m "/plugins/**" --concurrency 20 || true

# decK
echo "Caching decK docs..."
timeout 600 env XDG_CACHE_HOME="$MCP_BASE_DIR/deck/.cache" \
  sitemcp https://developer.konghq.com/ -m "/deck/**" --concurrency 20 || true

# Kubernetes (KIC + Operator)
echo "Caching Kubernetes docs..."
timeout 600 env XDG_CACHE_HOME="$MCP_BASE_DIR/kubernetes/.cache" \
  sitemcp https://developer.konghq.com/ -m "/kubernetes-ingress-controller/**" -m "/operator/**" --concurrency 20 || true

echo "Kong docs cache refresh complete."

exit 0
