# Kong Docs RAG - Zero to MCP

## 1. Install

```bash
ansible-playbook site.yml --tags build-kong-docs-rag
```

## 2. Build RAG

```bash
cd ~/dev/kong/docs-rag
just build
```

**Wait:** 10-30 minutes.

## 3. Install MCP

```bash
cd ~/dev/kong/docs-rag
just install-mcp
```

## 4. Configure Claude Code

Edit `~/.config/claude-code/claude_desktop_config.json`:

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

## 5. Restart Claude Code

```bash
pkill claude-code
claude-code
```

## 6. Test

Ask Claude:
```
"Search Kong docs for rate limiting"
```

Done.

---

## Daily Updates

```bash
cd ~/dev/kong/docs-rag
just update
```

## All Commands

```bash
cd ~/dev/kong/docs-rag
just
```

