---
name: scaffold-mcp
description: Scaffolds a monetized Model Context Protocol (MCP) tool gateway. Generates an HTTP server wrapping an MCP SDK client, using Hono and @x402/hono middleware.
---

# /scaffold-mcp

This command scaffolds a pay-per-call proxy gateway for Model Context Protocol (MCP) tools.

## Execution Steps

1.  **Gather Requirements**: Ask the user or read from environment:
    *   Target MCP Server endpoint (e.g. `http://localhost:8080/sse` or local command path)
    *   Pricing Map (USDC charge per tool name)
    *   Payee Solana wallet address (Base58)
    *   Network (Mainnet or Devnet)

2.  **Generate the Code**:
    *   Adopt the `x402-builder` persona.
    *   Reference routing patterns from `skill/references/x402-mcp-monetization.md`.
    *   Implement Hono middleware gating the `/mcp/v1/tools/call` endpoint.
    *   Enforce `Idempotency-Key` headers on all execution calls.
    *   Integrate proper Model Context Protocol SDK client connectors.

3.  **Explain the output**:
    *   Present the server proxy script.
    *   Highlight how client agents will parse tool price tags from the updated `tools/list` schema.

## Prompt Template

*To scaffold a monetized MCP gateway:*

```markdown
Please use the `/scaffold-mcp` command to create a paid gateway.
- **Target MCP**: `http://localhost:8080/sse`
- **USDC Payee**: (Read from process.env.PAYEE_WALLET)
- **Network**: Devnet
- **Tool Prices**: 
  - summarize: 0.01 USDC
  - research: 0.05 USDC
```
