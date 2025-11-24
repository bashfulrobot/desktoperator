# MCP Server Setup for Kong Docs RAG

This guide explains how to expose your Kong documentation RAG database through an MCP (Model Context Protocol) server for use with Claude Code.

## Overview

After building the RAG vector database with `build-kong-docs-rag`, you can expose it to Claude Code through the official [Qdrant MCP server](https://github.com/qdrant/mcp-server-qdrant). This enables Claude to semantically search and reference Kong documentation in conversations.

## Prerequisites

1. Built RAG database using `build-kong-docs-rag`
2. Node.js 18+ installed
3. Claude Code configured on your system

## Installation Steps

### 1. Install Qdrant MCP Server

The official Qdrant MCP server can be installed globally via npm:

```bash
npm install -g @qdrant/mcp-server-qdrant
```

Or use npx for on-demand execution (no installation required):

```bash
# npx will download and run the server automatically
npx @qdrant/mcp-server-qdrant
```

### 2. Locate Your Vector Database

After running `build-kong-docs-rag`, your vector database is located at:

```
~/.local/share/ramalama/vector-dbs/kong-docs/vector.db
```

This is a Qdrant-compatible vector database created by ramalama's `doc2rag` process.

### 3. Configure Claude Code MCP Settings

Claude Code's MCP configuration is stored at:

```
~/.config/claude-code/claude_desktop_config.json
```

Add the Qdrant MCP server configuration:

```json
{
  "mcpServers": {
    "kong-docs-rag": {
      "command": "npx",
      "args": [
        "@qdrant/mcp-server-qdrant"
      ],
      "env": {
        "QDRANT_URL": "file://~/.local/share/ramalama/vector-dbs/kong-docs",
        "COLLECTION_NAME": "kong-docs"
      }
    }
  }
}
```

**Configuration Options:**

- `QDRANT_URL`: Path to the vector database directory (use `file://` prefix for local paths)
- `COLLECTION_NAME`: Name of the collection in the database (default: based on source name)
- `QDRANT_API_KEY`: (Optional) API key if using hosted Qdrant

### 4. Alternative: Using Hosted Qdrant

If you prefer to use Qdrant Cloud instead of local vector database:

```json
{
  "mcpServers": {
    "kong-docs-rag": {
      "command": "npx",
      "args": [
        "@qdrant/mcp-server-qdrant"
      ],
      "env": {
        "QDRANT_URL": "https://your-cluster.qdrant.io",
        "QDRANT_API_KEY": "your-api-key",
        "COLLECTION_NAME": "kong-docs"
      }
    }
  }
}
```

### 5. Restart Claude Code

After updating the configuration, restart Claude Code to load the new MCP server:

```bash
# Kill any running Claude Code instances
pkill -f claude-code

# Start Claude Code fresh
claude-code
```

## Verification

To verify the MCP server is working:

1. Start a conversation with Claude Code
2. Ask: "Can you search the Kong documentation for information about rate limiting?"
3. Claude should be able to access and reference the Kong docs through the MCP server

## Usage Examples

Once configured, Claude Code can semantically search the Kong documentation:

### Example 1: Feature Documentation
```
You: Explain how to configure Kong Gateway rate limiting plugin

Claude will search the RAG database and provide contextual answers from the Kong docs.
```

### Example 2: API Reference
```
You: Show me the Admin API endpoints for managing services

Claude can retrieve and explain relevant API documentation.
```

### Example 3: Configuration Examples
```
You: Give me an example kong.conf for production deployment

Claude can find and present configuration examples from the docs.
```

## Troubleshooting

### MCP Server Not Loading

**Check logs:**
```bash
# Claude Code logs location
tail -f ~/.config/claude-code/logs/mcp-kong-docs-rag.log
```

**Common issues:**
- Path incorrect: Ensure `~/.local/share/ramalama/vector-dbs/kong-docs/vector.db` exists
- Permissions: Check file permissions on the vector database directory
- Node.js version: Ensure Node.js 18+ is installed

### Empty or Incorrect Results

**Rebuild the vector database:**
```bash
build-kong-docs-rag --clean
```

**Check database contents:**
```bash
# If ramalama provides inspection tools
ramalama info dir:~/.local/share/ramalama/vector-dbs/kong-docs
```

### Performance Issues

**Optimize vector database:**
- Reduce context size in ramalama config
- Use more selective document filtering when building
- Consider using hosted Qdrant for better performance

**Check resource usage:**
```bash
# Monitor during queries
htop  # or top
```

## Advanced Configuration

### Multiple Documentation Sources

You can configure multiple RAG sources by creating separate MCP server entries:

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
    "other-docs": {
      "command": "npx",
      "args": ["@qdrant/mcp-server-qdrant"],
      "env": {
        "QDRANT_URL": "file://~/.local/share/ramalama/vector-dbs/other-docs",
        "COLLECTION_NAME": "other-docs"
      }
    }
  }
}
```

### Custom Embeddings Model

The Qdrant MCP server supports custom embedding models. Configure in the environment:

```json
{
  "env": {
    "QDRANT_URL": "file://~/.local/share/ramalama/vector-dbs/kong-docs",
    "COLLECTION_NAME": "kong-docs",
    "EMBEDDING_MODEL": "sentence-transformers/all-MiniLM-L6-v2"
  }
}
```

**Note:** The embedding model should match what was used during RAG creation with ramalama.

## Deployment Options

### Local Development
- Use `file://` paths for local vector databases
- Fast and private (no external API calls)
- Requires rebuilding when docs update

### Kubernetes/Docker
If deploying the MCP server in a container:

```dockerfile
FROM node:18-alpine

RUN npm install -g @qdrant/mcp-server-qdrant

# Copy vector database
COPY kong-docs-vector.db /data/vector.db

ENV QDRANT_URL=file:///data
ENV COLLECTION_NAME=kong-docs

ENTRYPOINT ["mcp-server-qdrant"]
```

### Hosted Qdrant Cloud
- Push vector database to Qdrant Cloud
- Configure `QDRANT_URL` to cloud endpoint
- Requires API key but enables multi-user access

## Automation

### Automated RAG Updates

Create a systemd timer or cron job to rebuild the RAG periodically:

**Systemd timer example:**

`~/.config/systemd/user/kong-docs-rag-update.service`
```ini
[Unit]
Description=Update Kong Docs RAG Database

[Service]
Type=oneshot
ExecStart=/home/%u/.local/bin/build-kong-docs-rag --clean

[Install]
WantedBy=default.target
```

`~/.config/systemd/user/kong-docs-rag-update.timer`
```ini
[Unit]
Description=Update Kong Docs RAG Database Weekly

[Timer]
OnCalendar=weekly
Persistent=true

[Install]
WantedBy=timers.target
```

Enable:
```bash
systemctl --user daemon-reload
systemctl --user enable --now kong-docs-rag-update.timer
```

## Resources

- [Qdrant MCP Server Documentation](https://github.com/qdrant/mcp-server-qdrant)
- [Model Context Protocol Specification](https://modelcontextprotocol.io/)
- [RamaLama RAG Documentation](https://github.com/containers/ramalama/blob/main/docs/rag.md)
- [Claude Code MCP Guide](https://docs.anthropic.com/claude/docs/model-context-protocol)
- [Qdrant Vector Database Docs](https://qdrant.tech/documentation/)

## Next Steps

After completing this setup:

1. Test queries with Claude Code to verify RAG access
2. Consider setting up automated updates for the vector database
3. Explore adding additional documentation sources
4. Share your MCP server configuration with team members
5. Monitor performance and optimize as needed

