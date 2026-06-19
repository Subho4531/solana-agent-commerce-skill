---
name: x402-scaffold
description: Interactive wizard that helps developers scaffold paid x402 architectures on Solana. Directs builders to seller APIs, buyer agents, or monetized MCP tools.
---

# /x402-scaffold

This command acts as an orchestrator and entry point for x402 scaffolding workflows.

## Execution Steps

1.  **Determine Project Goal**: Ask the user what kind of x402 architecture they want to scaffold:
    *   **Option A**: Paid API Route (Seller) -> Gates a route using x402 middleware.
    *   **Option B**: Autonomous Agent Client (Buyer) -> Automatically signs and settles x402 payment requirements.
    *   **Option C**: Monetized Model Context Protocol (MCP) tool gateway.

2.  **Route to Sub-commands**:
    *   If **Option A**, execute or direct the user to the [`/scaffold-seller`](scaffold-seller.md) command.
    *   If **Option B**, execute or direct the user to the [`/scaffold-buyer`](scaffold-buyer.md) command.
    *   If **Option C**, provide the template code and routing patterns for monetizing MCP tools using Hono and SSE, referencing `skill/references/x402-mcp-monetization.md`.

3.  **Validate Code Generation Rules**:
    *   Ensure all generated templates use modern `@solana/kit` and `@x402/*` v2 libraries.
    *   Assert that no generated code hardcodes base58 private keys or seed phrases.
    *   Enforce spending safety parameters (budgets, limits, allowances) in atomic USDC units.

## Prompt Template

*To invoke the scaffolding wizard:*

```markdown
Please run the `/x402-scaffold` command to guide my project setup.
```
