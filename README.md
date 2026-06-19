# Solana Agent Commerce Skill (x402)

The **Solana Agent Commerce Skill** is a production-grade developer integration toolkit designed for the **Solana AI Kit**. It enables AI agents to monetize services (APIs, content, and MCP tools), autonomously execute DeFi strategies, and dynamically pay for resources using the **x402 Protocol** over the Solana network.

By leveraging the long-dormant HTTP `402 Payment Required` status code, the x402 protocol facilitates frictionless machine-to-machine payments. Settling in stablecoins like USDC on Solana ensures transaction costs stay under $0.001 and settle in less than 500ms.

---

## 🌟 Key Features

- **Standard HTTP 402 Workflows**: Automatic generation and resolution of payment challenges via Express, Hono, and Next.js.
- **DeFi Integration & Autonomous Spenders**: Agents can use **Jupiter v6** to auto-convert any token to USDC to fund their x402 payments on the fly, or execute paid quantitative strategies via **Orca Whirlpools**, **Meteora DLMM**, and **Drift Protocol**.
- **Data & Infrastructure Monetization**: Wrap **Helius DAS** queries or **Pyth Network** oracle feeds behind x402 payment walls.
- **Agent Framework Integration**: Deep compatibility with **Solana Agent Kit**, **LangChain**, and **Vercel AI SDK**, including multi-agent architectures where agents pay each other for specialized microservices.
- **MCP Server Monetization**: Wrap any standard Model Context Protocol (MCP) server behind Solana micropayments using an HTTP proxy.
- **Agent Safety Controls**: Built-in spending limits, KMS key vaulting, domain allowlists, and transaction concurrency guardrails.

---

## 📁 Directory Structure

```text
├── README.md                          # Project overview and specifications
├── LICENSE                            # MIT License
├── install.sh                         # Developer installation script
├── skill/
│   ├── SKILL.md                       # Routing entry point & progressive load hub
│   └── references/
│       ├── server-patterns.md         # Express, Hono, and Next.js middleware setups
│       ├── client-patterns.md         # Fetch wrappers, wallet configs, and spending caps
│       ├── solana-integration.md      # USDC SPL Token transfer & verification
│       ├── facilitator.md             # Verifier/Facilitator configurations
│       ├── defi-jupiter.md            # Jupiter v6 auto-swaps to USDC for x402 funding
│       ├── defi-protocols.md          # Orca, Meteora, Raydium, and Drift integrations
│       ├── data-infrastructure.md     # Monetizing Helius APIs and Pyth oracle feeds
│       ├── agent-frameworks.md        # LangChain, Vercel AI SDK, and Solana Agent Kit
│       ├── multi-agent.md             # Agent-to-agent payment architectures
│       ├── mcp-monetization.md        # Wrapping & monetizing MCP servers
│       ├── security.md                # Key management, spending caps, and safety rules
│       └── testing.md                 # Mocking payment challenges, local testing
├── agents/
│   ├── x402-architect.md              # System design & architecture helper agent
│   └── x402-builder.md                # Node.js/TypeScript developer helper agent
├── commands/
│   ├── audit-routes.md                # Audit routes for x402 compliance
│   ├── scaffold-buyer.md              # Scaffold a buyer agent
│   ├── scaffold-seller.md             # Scaffold a seller service
│   ├── test-devnet.md                 # Test workflows on devnet
│   └── x402-scaffold.md               # Base scaffolding helper script
└── rules/
    └── x402-security-rules.md         # Custom guidelines for safe agent commerce
```

---

## 🚀 Quick Start & Installation

To install this skill into your local AI agent or Claude Code environment, clone the repository and run the install script:

```bash
git clone https://github.com/solanabr/solana-agent-commerce-skill
cd solana-agent-commerce-skill
./install.sh --agents --rules
```

### Installation Flags

- `--agents`: Installs the `x402-architect` and `x402-builder` system agents to `.agents/`.
- `--rules`: Copies the custom developer safety guidelines (`x402-security-rules.md`) to the target configuration.

---

## 🔌 Integration Overview

### 1. Guarding an API (Server Side)

Use the Express middleware to gate routes:

```typescript
import express from "express";
import { paymentMiddleware } from "@x402/express";
import { ExactSvmScheme } from "@x402/svm";

const app = express();

app.use(
  paymentMiddleware({
    "GET /api/v1/data": {
      accepts: [{
        scheme: ExactSvmScheme.scheme,
        network: "solana:mainnet",
        maxAmountRequired: "0.01", // $0.01 USDC
        resource: "solana:mainnet:USDC_RECEIVER_WALLET_ADDRESS",
      }],
      description: "Access gated premium data.",
    },
  })
);
```

### 2. Auto-Resolving Gated APIs (Client Side / Agent)

Wrap `fetch` to automatically settle challenges:

```typescript
import { wrapFetchWithPaymentFromConfig } from "@x402/fetch";
import { ExactSvmScheme } from "@x402/svm";
import { Keypair } from "@solana/web3.js";

const agentKeypair = Keypair.fromSecretKey(/* Secret Key Bytes */);

const fetchWithPayment = wrapFetchWithPaymentFromConfig(fetch, {
  schemes: [{
    network: "solana:mainnet",
    client: new ExactSvmScheme(agentKeypair),
  }],
});

// Sends the request, signs/submits payment on challenge, and retries automatically
const response = await fetchWithPayment("https://api.example.com/api/v1/data");
const data = await response.json();
```

### 3. Agent Frameworks & Multi-Agent Architecture

With our custom integrations, you can wire x402 directly into the **Solana Agent Kit**:

```text
┌─────────────────────────────────────────────────────────────┐
│  Orchestrator Agent (Buyer)        Worker Agent (Seller)    │
│  ┌───────────────────────┐         ┌──────────────────────┐ │
│  │ Solana Agent Kit      │         │ Hono / Express       │ │
│  │ ├─ Jupiter Auto-Swap  │ ──402─► │ ├─ x402 Middleware   │ │
│  │ ├─ @x402/fetch wrapper│ ◄──TXN─ │ ├─ Pyth / Helius     │ │
│  │ └─ Spend Limits       │ ──200─► │ └─ Specialized Task  │ │
│  └───────────────────────┘         └──────────────────────┘ │
│              │                               │              │
│              └─────► Solana Mainnet ◄────────┘              │
└─────────────────────────────────────────────────────────────┘
```

---

## ⚖️ License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
