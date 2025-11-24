# Kong Documentation RAG Pipeline

Complete workflow for creating a Retrieval Augmented Generation (RAG) system from Kong's Jekyll documentation and exposing it via MCP (Model Context Protocol) for Claude Code.

## Overview

This pipeline enables Claude Code to semantically search and reference Kong documentation by:

1. **Cloning** the Kong developer documentation repository
2. **Processing** markdown files with docling (IBM's document understanding tool)
3. **Creating** a vector database with ramalama
4. **Exposing** the database via Qdrant MCP server for Claude Code

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         Kong Docs RAG Pipeline                           │
└─────────────────────────────────────────────────────────────────────────┘

   ┌─────────────────┐
   │  Jekyll Docs    │
   │  Repository     │
   │  (GitHub)       │
   └────────┬────────┘
            │ git clone
            ▼
   ┌─────────────────┐
   │  build-kong-    │
   │  docs-rag       │◄──────── Script (installed to ~/.local/bin)
   │  script         │
   └────────┬────────┘
            │
            ├──► Scans for .md files
            │
            ▼
   ┌─────────────────┐
   │   docling       │◄──────── Document parsing
   │   (via ramalama)│
   └────────┬────────┘
            │
            ├──► Converts to structured JSON
            │
            ▼
   ┌─────────────────┐
   │   ramalama      │◄──────── Creates embeddings
   │   rag command   │
   └────────┬────────┘
            │
            ├──► Generates vector.db
            │
            ▼
   ┌─────────────────┐
   │  Vector DB      │
   │  (Qdrant)       │
   │  ~/.local/share/│
   │  ramalama/      │
   └────────┬────────┘
            │
            ├──► Stored locally
            │
            ▼
   ┌─────────────────┐
   │  Qdrant MCP     │◄──────── Exposes to Claude Code
   │  Server         │
   └────────┬────────┘
            │
            ├──► Semantic search
            │
            ▼
   ┌─────────────────┐
   │  Claude Code    │◄──────── Query documentation
   │                 │
   └─────────────────┘
```

## Prerequisites

### System Requirements
- Ubuntu 24.04+ (or compatible Linux distribution)
- Python 3.12+
- Node.js 18+
- Git
- 8GB+ RAM (for processing large documentation sets)
- 5GB+ disk space for vector databases

### Required Ansible Roles

Enable in your host's `app_states` configuration (`inventory/host_vars/<hostname>.yml`):

```yaml
app_states:
  docling: present          # Document parsing library
  ramalama: present         # RAG creation tool
  build-kong-docs-rag: present  # Pipeline script
```

### Optional Dependencies
- Docker or Podman (for containerized deployment)
- Tesseract OCR (for PDF processing with docling)

## Installation

### 1. Deploy via Ansible

```bash
# Install all RAG pipeline components
ansible-playbook desktop.yml --tags dev,docling,ramalama,build-kong-docs-rag

# Or install individually
ansible-playbook desktop.yml --tags docling
ansible-playbook desktop.yml --tags ramalama
ansible-playbook desktop.yml --tags build-kong-docs-rag
```

### 2. Verify Installation

```bash
# Check docling
docling --version

# Check ramalama
ramalama --version

# Check pipeline script
build-kong-docs-rag --help
```

## Quick Start

### Step 1: Build RAG Database

```bash
# Build Kong docs RAG with defaults
build-kong-docs-rag

# This will:
# - Clone github.com/Kong/developer.konghq.com
# - Process all markdown files
# - Create vector database at ~/.local/share/ramalama/vector-dbs/kong-docs
```

**Processing time:** 10-30 minutes depending on documentation size and system resources.

### Step 2: Configure MCP Server

Install Qdrant MCP server:

```bash
npm install -g @qdrant/mcp-server-qdrant
```

Add to Claude Code config (`~/.config/claude-code/claude_desktop_config.json`):

```json
{
  "mcpServers": {
    "kong-docs": {
      "command": "npx",
      "args": ["@qdrant/mcp-server-qdrant"],
      "env": {
        "QDRANT_URL": "file://~/.local/share/ramalama/vector-dbs/kong-docs",
        "COLLECTION_NAME": "kong-docs"
      }
    }
  }
}
```

### Step 3: Test with Claude Code

Restart Claude Code and test:

```bash
# In Claude Code conversation:
"Search the Kong documentation for rate limiting examples"
```

Claude should now be able to semantically search and reference Kong documentation.

## Detailed Usage

### Building RAG Databases

#### Default Kong Documentation

```bash
build-kong-docs-rag
```

#### Custom Jekyll Repository

```bash
build-kong-docs-rag --repo https://github.com/other/docs-repo \
                    --output ~/.local/share/ramalama/vector-dbs/other-docs
```

#### Rebuild from Scratch

```bash
# Clean existing clone and rebuild
build-kong-docs-rag --clean
```

#### Container Registry Export

```bash
# Build and prepare for pushing to registry
build-kong-docs-rag --registry quay.io/myuser/kong-docs-rag

# Then push
podman push quay.io/myuser/kong-docs-rag
```

### Script Options

| Option | Description | Default |
|--------|-------------|---------|
| `-r, --repo` | Jekyll repository URL | Kong developer docs |
| `-d, --work-dir` | Working directory for clone | `~/.local/share/rag-sources` |
| `-o, --output` | Output vector database path | `~/.local/share/ramalama/vector-dbs/kong-docs` |
| `-t, --registry` | Container registry tag | None (local only) |
| `-c, --clean` | Clean existing clone | false |
| `-h, --help` | Show help message | - |

## MCP Server Configuration

### Local Vector Database (Recommended for Development)

**Pros:**
- Fast and private
- No external API calls
- Free

**Cons:**
- Manual updates required
- Single machine access

```json
{
  "mcpServers": {
    "kong-docs": {
      "command": "npx",
      "args": ["@qdrant/mcp-server-qdrant"],
      "env": {
        "QDRANT_URL": "file://~/.local/share/ramalama/vector-dbs/kong-docs",
        "COLLECTION_NAME": "kong-docs"
      }
    }
  }
}
```

### Hosted Qdrant Cloud (Recommended for Production)

**Pros:**
- Centralized access
- Automatic scaling
- Better performance for large teams

**Cons:**
- Requires API key
- External dependency
- Potential cost

```json
{
  "mcpServers": {
    "kong-docs": {
      "command": "npx",
      "args": ["@qdrant/mcp-server-qdrant"],
      "env": {
        "QDRANT_URL": "https://your-cluster.qdrant.io",
        "QDRANT_API_KEY": "your-api-key",
        "COLLECTION_NAME": "kong-docs"
      }
    }
  }
}
```

### Multiple Documentation Sources

```json
{
  "mcpServers": {
    "kong-docs": {
      "command": "npx",
      "args": ["@qdrant/mcp-server-qdrant"],
      "env": {
        "QDRANT_URL": "file://~/.local/share/ramalama/vector-dbs/kong-docs",
        "COLLECTION_NAME": "kong-docs"
      }
    },
    "internal-docs": {
      "command": "npx",
      "args": ["@qdrant/mcp-server-qdrant"],
      "env": {
        "QDRANT_URL": "file://~/.local/share/ramalama/vector-dbs/internal",
        "COLLECTION_NAME": "internal"
      }
    }
  }
}
```

## Maintenance

### Updating Documentation

Kong documentation updates periodically. Rebuild to sync:

```bash
# Quick update (git pull + rebuild)
build-kong-docs-rag

# Full rebuild from scratch
build-kong-docs-rag --clean
```

### Automated Updates

Create a systemd timer for automatic weekly updates:

**Service:** `~/.config/systemd/user/kong-docs-rag-update.service`
```ini
[Unit]
Description=Update Kong Docs RAG Database

[Service]
Type=oneshot
ExecStart=%h/.local/bin/build-kong-docs-rag --clean
```

**Timer:** `~/.config/systemd/user/kong-docs-rag-update.timer`
```ini
[Unit]
Description=Update Kong Docs RAG Weekly

[Timer]
OnCalendar=weekly
Persistent=true

[Install]
WantedBy=timers.target
```

**Enable:**
```bash
systemctl --user daemon-reload
systemctl --user enable --now kong-docs-rag-update.timer

# Check status
systemctl --user status kong-docs-rag-update.timer
```

### Monitoring

#### Check Vector Database Size
```bash
du -sh ~/.local/share/ramalama/vector-dbs/kong-docs
```

#### View Logs
```bash
# MCP server logs
tail -f ~/.config/claude-code/logs/mcp-kong-docs.log

# Systemd timer logs (if using automated updates)
journalctl --user -u kong-docs-rag-update.service -f
```

#### Test RAG Quality
```bash
# Use ramalama to test queries directly
ramalama run --rag dir:~/.local/share/ramalama/vector-dbs/kong-docs llama3

# Then ask: "What is Kong Gateway rate limiting?"
```

## Troubleshooting

### Build Failures

**Issue:** Script fails during docling processing

**Solutions:**
```bash
# Ensure dependencies are installed
ansible-playbook desktop.yml --tags docling

# Check Tesseract OCR
tesseract --version

# Try with verbose logging
bash -x build-kong-docs-rag
```

**Issue:** Out of memory during processing

**Solutions:**
- Reduce parallelism in ramalama config
- Process in batches (modify script)
- Increase system RAM or swap

### MCP Server Issues

**Issue:** Claude Code can't connect to MCP server

**Solutions:**
```bash
# Test MCP server directly
npx @qdrant/mcp-server-qdrant

# Check configuration path
cat ~/.config/claude-code/claude_desktop_config.json

# Verify vector database exists
ls -lh ~/.local/share/ramalama/vector-dbs/kong-docs/vector.db
```

**Issue:** Empty or irrelevant results

**Solutions:**
- Rebuild database: `build-kong-docs-rag --clean`
- Verify source repository has content
- Check embedding model compatibility

### Performance Issues

**Issue:** Slow query responses

**Solutions:**
- Use Qdrant Cloud for better performance
- Optimize vector database settings in ramalama
- Reduce context window size
- Consider using smaller embedding models

## Advanced Configuration

### Custom Embedding Models

Modify ramalama configuration (`~/.config/ramalama/ramalama.conf`):

```toml
[embedding]
model = "sentence-transformers/all-MiniLM-L6-v2"
```

Then rebuild:
```bash
build-kong-docs-rag --clean
```

### Kubernetes Deployment

Deploy MCP server in Kubernetes:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: kong-docs-mcp
spec:
  replicas: 1
  selector:
    matchLabels:
      app: kong-docs-mcp
  template:
    metadata:
      labels:
        app: kong-docs-mcp
    spec:
      containers:
      - name: mcp-server
        image: node:18-alpine
        command: ["npx", "@qdrant/mcp-server-qdrant"]
        env:
        - name: QDRANT_URL
          value: "https://qdrant-cluster.namespace.svc.cluster.local:6333"
        - name: COLLECTION_NAME
          value: "kong-docs"
        - name: QDRANT_API_KEY
          valueFrom:
            secretKeyRef:
              name: qdrant-credentials
              key: api-key
```

### Docker Compose

```yaml
version: '3.8'
services:
  qdrant:
    image: qdrant/qdrant:latest
    ports:
      - "6333:6333"
    volumes:
      - ./kong-docs-vector.db:/qdrant/storage

  mcp-server:
    image: node:18-alpine
    command: npx @qdrant/mcp-server-qdrant
    environment:
      QDRANT_URL: http://qdrant:6333
      COLLECTION_NAME: kong-docs
    depends_on:
      - qdrant
```

## Best Practices

### 1. Regular Updates
- Schedule weekly updates via systemd timer
- Monitor Kong docs repository for changes
- Test queries after updates

### 2. Version Control
- Tag vector databases with dates
- Keep previous versions for rollback
- Document breaking changes

### 3. Security
- Use API keys for hosted Qdrant
- Restrict MCP server network access
- Audit query logs for sensitive data

### 4. Performance
- Use SSD storage for vector databases
- Allocate sufficient RAM (8GB+)
- Consider GPU acceleration for large sets

### 5. Team Collaboration
- Share MCP configurations via git
- Document custom queries and use cases
- Centralize vector databases for consistency

## Resources

### Documentation
- [build-kong-docs-rag Role README](../roles/dev/build-kong-docs-rag/README.md)
- [MCP Server Setup Guide](../roles/dev/build-kong-docs-rag/MCP_SETUP.md)
- [Docling Role](../roles/dev/docling/)
- [RamaLama Role](../roles/dev/ramalama/)

### External Links
- [Kong Developer Documentation](https://github.com/Kong/developer.konghq.com)
- [RamaLama RAG Tutorial](https://developers.redhat.com/articles/2025/04/03/simplify-ai-data-integration-ramalama-and-rag)
- [Qdrant MCP Server](https://github.com/qdrant/mcp-server-qdrant)
- [Model Context Protocol](https://modelcontextprotocol.io/)
- [Docling Project](https://github.com/docling-project/docling)

### Community
- Report issues: GitHub Issues for this repository
- Kong Community: [Kong Nation Forums](https://discuss.konghq.com/)
- MCP Discord: [Anthropic Discord](https://discord.gg/anthropic)

## License

This pipeline and associated scripts are part of the desktoperator IaC repository and follow its licensing terms.

