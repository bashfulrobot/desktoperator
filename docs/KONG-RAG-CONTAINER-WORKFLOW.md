# Kong Docs RAG - Container-Based Workflow

Share pre-built Kong documentation RAG with your team via container registry.

## Overview

**Publisher Workflow** (You):
1. Build vector database
2. Push to container registry
3. Share registry tag with team

**Consumer Workflow** (Team):
1. Pull container image
2. Configure MCP
3. Use immediately (no build required)

## For Publishers (Building & Sharing)

### 1. Set Your Registry

```bash
cd ~/dev/kong/docs-rag

# Set registry (choose one):
export KONG_DOCS_REGISTRY="ghcr.io/YOUR_USERNAME/kong-docs-rag:latest"
export KONG_DOCS_REGISTRY="quay.io/YOUR_USERNAME/kong-docs-rag:latest"
export KONG_DOCS_REGISTRY="docker.io/YOUR_USERNAME/kong-docs-rag:latest"
```

Or edit `~/dev/kong/docs-rag/justfile` directly:
```just
registry_tag := "ghcr.io/YOUR_USERNAME/kong-docs-rag:latest"
```

### 2. Initial Setup & Publish

```bash
cd ~/dev/kong/docs-rag

# One-time setup (builds, publishes, configures MCP)
just setup-container
```

**What this does:**
- Installs Qdrant MCP server
- Builds vector database from Kong docs
- Creates container image
- Pushes to registry
- Configures MCP for container-based access

**Time:** 15-30 minutes (first build)

### 3. Daily Updates & Republish

```bash
cd ~/dev/kong/docs-rag

# Pull latest docs, rebuild, and republish
just update-publish
```

**Or separately:**
```bash
# Pull latest docs and rebuild locally
just update

# Publish to registry
just publish
```

### 4. Share with Team

After publishing, share the registry tag:

```
Registry: ghcr.io/YOUR_USERNAME/kong-docs-rag:latest

Setup:
1. Install: ansible-playbook site.yml --tags build-kong-docs-rag
2. Pull: cd ~/dev/kong/docs-rag && just pull-image
3. Setup: just setup-from-image
4. Restart Claude Code
```

### 5. Registry Authentication

**GitHub Container Registry (GHCR):**
```bash
echo $GITHUB_TOKEN | docker login ghcr.io -u YOUR_USERNAME --password-stdin
```

**Quay.io:**
```bash
docker login quay.io
```

**Docker Hub:**
```bash
docker login
```

## For Consumers (Using Shared Image)

### Quick Setup (No Build Required)

```bash
# 1. Install build-kong-docs-rag role
ansible-playbook site.yml --tags build-kong-docs-rag

# 2. Set registry (provided by publisher)
cd ~/dev/kong/docs-rag
export KONG_DOCS_REGISTRY="ghcr.io/PUBLISHER_USERNAME/kong-docs-rag:latest"

# 3. Pull and setup
just setup-from-image

# 4. Restart Claude Code
pkill claude-code
claude-code
```

**That's it!** No 30-minute build, no dependencies besides Docker and npm.

### Manual Setup

If you prefer manual steps:

```bash
cd ~/dev/kong/docs-rag

# Pull image
just pull-image

# Install MCP server
just install-mcp

# Configure MCP for container
just configure-mcp-container

# Restart Claude Code
pkill claude-code && claude-code
```

### Update to Latest

When the publisher updates the docs:

```bash
cd ~/dev/kong/docs-rag
just pull-image
# Restart Claude Code
```

## MCP Configuration Comparison

### Local Files (Default)
```json
{
  "mcpServers": {
    "kong-docs": {
      "command": "npx",
      "args": ["@qdrant/mcp-server-qdrant"],
      "env": {
        "QDRANT_URL": "file://~/dev/kong/docs-rag/vector-db",
        "COLLECTION_NAME": "kong-docs"
      }
    }
  }
}
```

### Container-Based (Shareable)
```json
{
  "mcpServers": {
    "kong-docs": {
      "command": "docker",
      "args": [
        "run", "--rm", "-i",
        "--mount", "type=bind,source=~/dev/kong/docs-rag/vector-db,target=/data",
        "ghcr.io/YOUR_USERNAME/kong-docs-rag:latest",
        "npx", "@qdrant/mcp-server-qdrant"
      ],
      "env": {
        "QDRANT_URL": "file:///data",
        "COLLECTION_NAME": "kong-docs"
      }
    }
  }
}
```

## Justfile Commands

### Publisher Commands

| Command | Description |
|---------|-------------|
| `just publish` | Build and push to registry |
| `just republish` | Clean rebuild and republish |
| `just update-publish` | Pull docs, rebuild, republish |
| `just setup-container` | Complete setup for publishing |

### Consumer Commands

| Command | Description |
|---------|-------------|
| `just setup-from-image` | Complete setup (no build) |
| `just pull-image` | Pull latest image from registry |
| `just configure-mcp-container` | Show container MCP config |

### Shared Commands

| Command | Description |
|---------|-------------|
| `just status` | Show current configuration |
| `just install-mcp` | Install Qdrant MCP server |

## Workflow Scenarios

### Scenario 1: Weekly Doc Updates (Publisher)

**Monday morning:**
```bash
cd ~/dev/kong/docs-rag
just update-publish
```

**Team notification:**
```
Kong docs updated! Pull latest:
cd ~/dev/kong/docs-rag && just pull-image
Restart Claude Code.
```

### Scenario 2: New Team Member (Consumer)

```bash
# Day 1 setup
ansible-playbook site.yml --tags build-kong-docs-rag
cd ~/dev/kong/docs-rag
export KONG_DOCS_REGISTRY="ghcr.io/team/kong-docs-rag:latest"
just setup-from-image

# Done! No 30-minute build.
```

### Scenario 3: Testing New Docs Version (Publisher)

```bash
cd ~/dev/kong/docs-rag

# Build with version tag
export KONG_DOCS_REGISTRY="ghcr.io/you/kong-docs-rag:v2.0.0-beta"
just publish

# Share beta tag with testers
```

### Scenario 4: Multiple Doc Versions

```bash
# Production
export KONG_DOCS_REGISTRY="ghcr.io/you/kong-docs-rag:latest"
just publish

# Staging
export KONG_DOCS_REGISTRY="ghcr.io/you/kong-docs-rag:staging"
just publish

# Teams use different tags in MCP config
```

## Registry Options

### GitHub Container Registry (Recommended)

**Pros:**
- Free for public repos
- Integrated with GitHub
- Generous limits

**Setup:**
```bash
# Create token: https://github.com/settings/tokens
# Permissions: write:packages, read:packages
echo $GITHUB_TOKEN | docker login ghcr.io -u USERNAME --password-stdin
```

**Tag format:**
```
ghcr.io/USERNAME/kong-docs-rag:latest
```

### Quay.io

**Pros:**
- Free for public repos
- Great UI
- Robot accounts for teams

**Setup:**
```bash
docker login quay.io
```

**Tag format:**
```
quay.io/USERNAME/kong-docs-rag:latest
```

### Docker Hub

**Pros:**
- Most popular
- Free tier available

**Cons:**
- Rate limits on pulls

**Setup:**
```bash
docker login
```

**Tag format:**
```
docker.io/USERNAME/kong-docs-rag:latest
# or just: USERNAME/kong-docs-rag:latest
```

### Private Registry

**For enterprise:**
```bash
docker login registry.company.com
export KONG_DOCS_REGISTRY="registry.company.com/kong-docs-rag:latest"
```

## Troubleshooting

### Push Fails: Authentication Required

```bash
# Login to registry first
docker login ghcr.io
# or
docker login quay.io
# or
docker login
```

### Pull Fails: Not Found

Check registry tag:
```bash
echo $KONG_DOCS_REGISTRY
# Should match what publisher shared
```

### MCP Can't Find Container

Ensure Docker is running:
```bash
docker ps
```

Pull image manually:
```bash
docker pull $KONG_DOCS_REGISTRY
```

### Container Permission Issues

Check mount point:
```bash
ls -la ~/dev/kong/docs-rag/vector-db
# Should be readable
```

## Performance

**Container-based vs Local:**
- Container: +50ms overhead per query (negligible)
- Benefit: Share once, use everywhere
- Trade-off: Worth it for team sharing

**Image Size:**
- Typical: 500 MB - 2 GB
- Depends on docs size and embedding model
- One-time download per update

## Security

**Public vs Private Registries:**
- Kong docs are public → public registry OK
- Internal docs → use private registry
- Use authentication tokens, not passwords

**Container Security:**
- Images are read-only vector databases
- No code execution in images
- MCP server runs from base system

## Best Practices

**For Publishers:**
1. Use semantic versioning tags (`:v1.0.0`, `:v1.1.0`)
2. Keep `:latest` for production
3. Tag experiments/tests separately
4. Update weekly or when docs change significantly
5. Notify team after updates

**For Consumers:**
1. Pin to specific versions for stability
2. Use `:latest` for auto-updates
3. Test new versions before switching
4. Pull updates regularly

**For Teams:**
1. Designate one publisher
2. Automate weekly updates (cron/GitHub Actions)
3. Document registry URL in team wiki
4. Use private registry for internal docs

## Automation

### GitHub Actions (Auto-Publish)

```yaml
name: Update Kong Docs RAG
on:
  schedule:
    - cron: '0 9 * * MON'  # Weekly Monday 9am
  workflow_dispatch:  # Manual trigger

jobs:
  publish:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Login to GHCR
        run: echo "${{ secrets.GITHUB_TOKEN }}" | docker login ghcr.io -u ${{ github.actor }} --password-stdin
      - name: Build and publish
        run: |
          cd ~/dev/kong/docs-rag
          export KONG_DOCS_REGISTRY="ghcr.io/${{ github.repository_owner }}/kong-docs-rag:latest"
          just update-publish
```

### Cron Job (Local)

```bash
# Add to crontab
0 9 * * 1 cd ~/dev/kong/docs-rag && just update-publish
```

## Next Steps

**As Publisher:**
1. Choose a registry (GitHub, Quay.io, Docker Hub)
2. Set `KONG_DOCS_REGISTRY` in justfile
3. Run `just setup-container`
4. Share registry tag with team

**As Consumer:**
1. Get registry tag from publisher
2. Run `just setup-from-image`
3. Restart Claude Code
4. Start querying Kong docs!

