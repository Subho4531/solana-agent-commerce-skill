---
name: solana-agent-commerce
description: >
  Use when implementing x402 payments on Solana, gating API/MCP routes with HTTP 402,
  building AI agents that autonomously pay for on-chain data or DeFi actions, integrating
  with Jupiter swaps, Orca Whirlpools, Raydium, Meteora, Drift Protocol, or Helius RPC,
  managing USDC/SPL token wallets for agents, multi-agent commerce flows, monetizing
  services with pay-per-request micropayments, and hardening payment flows against
  replay attacks, stale quotes, and overspending.
user-invocable: true
---

# Solana Agent Commerce Skill

> Build, test, and harden x402-powered Solana agent payments, paid APIs, paid MCP tools,
> and full DeFi-integrated autonomous agent workflows.

## What This Skill Covers

- **x402 Server**: Gate HTTP endpoints (Express, Hono, Next.js, Fastify) with USDC payment walls
- **x402 Client**: Build AI agents with autonomous USDC spending, spend policies, and receipt logging
- **DeFi Integration**: Connect x402 payments to Jupiter swaps, Orca, Raydium, Meteora, Drift
- **Agent Wallets**: Fund, manage, and secure agent USDC wallets for autonomous payments
- **Agent-to-Agent Commerce**: Multi-agent architectures where agents pay each other for services
- **MCP Monetization**: Add pay-per-call billing to any MCP tool server
- **Solana Agent Kit**: Integrate x402 with SendAI / LangChain / Vercel AI SDK agent frameworks
- **Oracle Integration**: Use Pyth / Switchboard price feeds inside paid API services
- **Security & Compliance**: Spend caps, key vaulting, OFAC checks, audit logging
- **Testing**: Devnet USDC faucets, mock facilitators, Vitest integration tests

---

## Route by Task

| Task | Read |
|---|---|
| Gate API endpoint (Express / Hono / Next.js / Fastify) | [x402-server-patterns.md](references/x402-server-patterns.md) |
| Build buyer agent that auto-pays 402s | [x402-client-patterns.md](references/x402-client-patterns.md) |
| Solana network config, USDC mints, CAIP-2, keypairs | [x402-solana-integration.md](references/x402-solana-integration.md) |
| Facilitator setup (Coinbase hosted or self-hosted) | [x402-facilitator.md](references/x402-facilitator.md) |
| Jupiter swaps → USDC for agent payments | [x402-defi-jupiter.md](references/x402-defi-jupiter.md) |
| Orca, Raydium, Meteora, Drift DeFi integrations | [x402-defi-protocols.md](references/x402-defi-protocols.md) |
| Helius RPC, DAS API, Pyth oracles for paid data APIs | [x402-data-infrastructure.md](references/x402-data-infrastructure.md) |
| Solana Agent Kit / LangChain / Vercel AI SDK | [x402-agent-kit.md](references/x402-agent-kit.md) |
| Multi-agent payment architectures | [x402-multi-agent.md](references/x402-multi-agent.md) |
| Monetize MCP tool server with x402 | [x402-mcp-monetization.md](references/x402-mcp-monetization.md) |
| Security: spend caps, key management, OFAC | [x402-security.md](references/x402-security.md) |
| Devnet testing, mock facilitator, Vitest | [x402-testing.md](references/x402-testing.md) |
| Ecosystem resources & links | [x402-resources.md](references/x402-resources.md) |

---

## Defaults (Opinionated)

| Concern | Default |
|---|---|
| **Protocol version** | x402 v2 (x402-foundation spec) |
| **Network** | Solana Mainnet (`solana:5eykt4UsFv8P8NJdTREpY1vzqKqZKvdp`) |
| **Test network** | Solana Devnet (`solana:EtWTRABZaYq6iMfeYKouRu166VU2xqa1`) |
| **Payment scheme** | `exact` via `ExactSvmScheme` from `@x402/svm` |
| **Payment token** | USDC SPL — Mainnet: `EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v` |
| **Server framework** | Hono (edge-first) or Express for Node.js |
| **Client wrapper** | `@x402/fetch` with `wrapFetchWithPaymentFromConfig` |
| **Swap router** | Jupiter v6 for any token → USDC conversion |
| **RPC provider** | Helius (mainnet), public devnet for testing |
| **Key management** | env vars only; never hardcode; KMS for production |
| **Spend controls** | Always add: max-per-request, daily-budget, domain-allowlist, receipt-log |
| **Server safety** | Always bind: method, URL, price, network, asset, payee, quote-expiry |
| **Testing** | Vitest + devnet USDC airdrop + mock facilitator |

---

## Key Package Versions (2026)

```bash
# Core x402
npm install @x402/core @x402/svm @x402/fetch

# Server middleware (pick one)
npm install @x402/express     # Express.js
npm install @x402/hono        # Hono (recommended)
npm install @x402/next        # Next.js App Router
npm install @x402/fastify     # Fastify

# Solana
npm install @solana/web3.js@1 bs58 dotenv

# DeFi (install only what you need)
npm install @jup-ag/api       # Jupiter v6 REST client
npm install @orca-so/whirlpools-sdk @orca-so/common-sdk  # Orca
npm install @raydium-io/raydium-sdk-v2  # Raydium
npm install @meteora-ag/dlmm  # Meteora DLMM
npm install @drift-labs/sdk   # Drift Protocol
npm install @pythnetwork/client  # Pyth oracles

# Agent frameworks
npm install @sendaifun/solana-agent-kit  # Solana Agent Kit
npm install langchain @langchain/community  # LangChain
```

---

## Quick Architecture Patterns

### Pattern A — Paid REST API (Seller)
```
Your Service → Express/Hono + @x402/express middleware
Client Agent → @x402/fetch wrapper auto-pays 402
Settlement  → USDC transferred on Solana, receipt returned
```

### Pattern B — DeFi-Aware Agent (Buyer)
```
Agent Wallet → holds SOL + USDC
On 402       → check USDC balance → if low, swap SOL→USDC via Jupiter
              → pay with @x402/fetch → log receipt → continue task
```

### Pattern C — MCP Tool Marketplace
```
MCP Server   → wrapped by HTTP Gateway (Express/Hono)
Tool pricing → defined in MCP_PRICING_MAP
Agent calls  → POST /mcp/call-tool → 402 → auto-pay → result
```

### Pattern D — Agent-to-Agent Commerce
```
Orchestrator Agent → discovers peer agents via service registry
                   → calls peer service → receives 402
                   → pays with its own USDC wallet
                   → forwards result to user
```

---

## Operating Procedure

1. **Classify the task** using the routing table above.
2. **Read the specific reference file** — do not load all references at once.
3. **Check the Defaults** — use opinionated defaults unless overridden by user.
4. **Apply security rules** — always include spend caps and key management.
5. **Write tests** — always include devnet test patterns.
