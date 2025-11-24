# build-kong-docs-rag Role

Installs the `build-kong-docs-rag` script to the user's local binary directory for creating RAG vector databases from Jekyll documentation sites.

## Description

This role installs a script that automates the complete workflow for building a Retrieval Augmented Generation (RAG) system from Jekyll-based documentation sites. The script:

1. Clones a Jekyll repository (defaults to Kong developer documentation)
2. Processes all markdown files using docling for document understanding
3. Creates a vector database using ramalama
4. Outputs a vector database ready for use with MCP (Model Context Protocol) servers

The installed script integrates with the docling and ramalama tools to provide end-to-end RAG creation.

## Requirements

This script depends on:
- `ramalama` (installed via roles/dev/ramalama)
- `docling` (installed via roles/dev/docling)
- `git` (for cloning repositories)

These dependencies are not automatically installed by this role. Ensure they are enabled in your host configuration.

## Installation

Add to your host's `app_states` in `inventory/host_vars/<hostname>.yml`:

```yaml
app_states:
  build-kong-docs-rag: present
  docling: present          # Required dependency
  ramalama: present         # Required dependency
```

Run the playbook:

```bash
ansible-playbook desktop.yml --tags build-kong-docs-rag
```

## What Gets Installed

This role installs:
1. **Script:** `~/.local/bin/build-kong-docs-rag` - Core RAG builder script
2. **Justfile:** `~/dev/kong/docs-rag/justfile` - Task runner for managing RAG operations
3. **Work Directory:** `~/dev/kong/docs-rag/` - Base directory for all RAG operations

## Usage

### Using the Script Directly

After installation, the script is available in your PATH:

```bash
# Build Kong docs RAG with defaults
build-kong-docs-rag

# Show help and options
build-kong-docs-rag --help

# Build with custom output directory
build-kong-docs-rag --output ~/.local/share/ramalama/kong-docs-custom

# Build different Jekyll repo
build-kong-docs-rag --repo https://github.com/other/docs-repo

# Clean existing clone and rebuild
build-kong-docs-rag --clean

# Build and prepare for container registry
build-kong-docs-rag --registry quay.io/myuser/kong-docs-rag
```

### Using the Justfile (Recommended)

A justfile is deployed to `~/dev/kong/docs-rag/justfile` for easy management:

```bash
# Navigate to the work directory
cd ~/dev/kong/docs-rag

# Show available commands
just

# Build RAG database
just build

# Rebuild from scratch
just rebuild

# Update docs (incremental)
just update

# Check status
just status

# Test RAG
just test "What is Kong rate limiting?"

# Quick setup (install MCP + build)
just setup

# See all commands
just --list
```

**Available Just Commands:**
- `build` - Build RAG database
- `rebuild` - Clean rebuild
- `update` - Incremental update
- `status` - Show system status
- `test` - Test RAG with query
- `install-mcp` - Install Qdrant MCP server
- `configure-mcp` - Show MCP configuration
- `setup` - Complete setup workflow
- `clean` - Clean vector database
- `clean-all` - Clean everything
- `pull` - Pull latest docs
- `check-updates` - Check for updates
- `repo-info` - Show repository info
- `verify` - Run quality tests
- `export` - Export as container
- `watch` - Auto-rebuild on changes

### Script Options

- `-r, --repo URL` - Jekyll repository URL (default: Kong developer docs)
- `-d, --work-dir PATH` - Working directory for cloning (default: `~/dev/kong/docs-rag/source`)
- `-o, --output PATH` - Output vector database path (default: `~/dev/kong/docs-rag/vector-db`)
- `-t, --registry TAG` - Container registry tag for RAG image (optional)
- `-c, --clean` - Clean existing clone before starting
- `-h, --help` - Show help message

## Integration with MCP

The generated vector database can be exposed via the Qdrant MCP server for use with Claude and other AI assistants.

See the [Qdrant MCP server documentation](https://github.com/qdrant/mcp-server-qdrant) for configuration details.

Example workflow:
```bash
# 1. Build the RAG database
build-kong-docs-rag

# 2. Configure Qdrant MCP server to use the vector database
# (Add to Claude Code's MCP configuration)

# 3. Query the docs through Claude
# Claude can now access Kong documentation contextually
```

## Implementation Details

- Script source: `scripts/build-kong-docs-rag`
- Installation target: `~/.local/bin/build-kong-docs-rag`
- Script is copied with executable permissions (0755)
- Supports both present/absent states for installation/removal

## References

- [RamaLaMA Documentation](https://github.com/containers/ramalama)
- [Docling Project](https://github.com/docling-project/docling)
- [Qdrant MCP Server](https://github.com/qdrant/mcp-server-qdrant)
- [Red Hat RAG Tutorial](https://developers.redhat.com/articles/2025/04/03/simplify-ai-data-integration-ramalama-and-rag)
- [Kong Developer Documentation](https://github.com/Kong/developer.konghq.com)

