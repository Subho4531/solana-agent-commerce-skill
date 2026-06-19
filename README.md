# Solana Agent Commerce Skill (x402)

The **Solana Agent Commerce Skill** is a developer integration toolkit for building Solana x402 paid APIs, paid MCP gateways, and buyer agents with strict USDC spend policies.

By leveraging the HTTP `402 Payment Required` status code, the x402 protocol enables machine-to-machine payment flows where agents can pay for resources and receive auditable payment receipts.

---

## 🌟 Key Features

- **Standard HTTP 402 Workflows**: Automatic generation and resolution of payment challenges via Express, Hono, and Next.js.
- **Solana x402 Defaults**: x402 v2, `exact` SVM scheme, CAIP-2 network IDs, and SPL USDC mint checks.
- **Autonomous Buyer Safety**: Domain allowlists, payee allowlists, atomic-unit spend caps, receipt logs, and idempotency.
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
│       ├── x402-server-patterns.md    # Express, Hono, and Next.js middleware setups
│       ├── x402-client-patterns.md    # Fetch wrappers, wallet configs, and spending caps
│       ├── x402-solana-integration.md # CAIP-2 IDs, USDC mints, signer setup
│       ├── x402-facilitator.md        # Verifier/facilitator configurations
│       ├── x402-agent-kit.md          # LangChain and Solana Agent Kit patterns
│       ├── x402-mcp-monetization.md   # Wrapping and monetizing MCP servers
│       ├── x402-security.md           # Key management, spending caps, and safety rules
│       └── x402-testing.md            # Devnet and local test patterns
├── agents/
│   ├── x402-architect.md              # System design & architecture helper agent
│   ├── x402-builder.md                # Node.js/TypeScript developer helper agent
│   └── x402-auditor.md                # Security review helper agent
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

To install this skill into Codex, clone the repository and run the install script:

```bash
git clone https://github.com/solanabr/solana-agent-commerce-skill
cd solana-agent-commerce-skill
./install.sh --agents --rules --commands
```

### Installation Flags

- `--agents`: Installs the `x402-architect`, `x402-builder`, and `x402-auditor` system agents to `.agents/`.
- `--rules`: Copies the custom developer safety guidelines (`x402-security-rules.md`) to the target configuration.
- `--commands`: Installs command prompts.
- `--target claude`: Installs to Claude-style paths instead of Codex paths.

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
        network: "solana:EtWTRABZaYq6iMfeYKouRu166VU2xqa1",
        maxAmountRequired: "10000",
        payTo: process.env.PAYEE_WALLET!,
        asset: "4zMMC9srt5Ri5X14GAgXhaHii3GnPAEERYPJgZJDncDU",
        maxAgeSeconds: 60,
      }],
      description: "Access gated premium data.",
    },
  })
);
```

### 2. Auto-Resolving Gated APIs (Client Side / Agent)

Wrap `fetch` to automatically settle challenges:

```typescript
import { wrapFetchWithPayment } from "@x402/fetch";
import { createSvmClient } from "@x402/svm/client";
import { toClientSvmSigner } from "@x402/svm";
import { createKeyPairSignerFromBytes } from "@solana/kit";
import { base58 } from "@scure/base";

const keypair = await createKeyPairSignerFromBytes(
  base58.decode(process.env.SVM_PRIVATE_KEY!)
);

const client = createSvmClient({
  signer: toClientSvmSigner(keypair),
  rpcUrl: process.env.SOLANA_RPC_URL,
});

const fetchWithPayment = wrapFetchWithPayment(fetch, client);
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
