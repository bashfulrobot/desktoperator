#!/usr/bin/env bash

set -e

echo "Starting Kong documentation cache refresh..."

# Gateway
echo "Caching Kong Gateway docs..."
sitemcp https://developer.konghq.com/ -m "/gateway/**" --concurrency 20

# Konnect Platform
echo "Caching Konnect Platform docs..."
sitemcp https://developer.konghq.com/ -m "/konnect/**" -m "/konnect-platform/**" --concurrency 20

# AI Gateway
echo "Caching AI Gateway docs..."
sitemcp https://developer.konghq.com/ -m "/ai-gateway/**" --concurrency 20

# Kong Mesh
echo "Caching Kong Mesh docs..."
sitemcp https://developer.konghq.com/ -m "/mesh/**" -m "/mesh-manager/**" --concurrency 20

# Plugins
echo "Caching Kong Plugins docs..."
sitemcp https://developer.konghq.com/ -m "/plugins/**" --concurrency 20

# decK
echo "Caching decK docs..."
sitemcp https://developer.konghq.com/ -m "/deck/**" --concurrency 20

# Kubernetes (KIC + Operator)
echo "Caching Kubernetes docs..."
sitemcp https://developer.konghq.com/ -m "/kubernetes-ingress-controller/**" -m "/operator/**" --concurrency 20

echo "Kong docs cache refresh complete."

exit 0
