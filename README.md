# Solana Agent Commerce Skill (x402)

The **Solana Agent Commerce Skill** is a production-grade developer integration toolkit designed for the **Solana AI Kit**. It enables AI agents to monetize services (APIs, content, and MCP tools) and pay for resources dynamically using the **x402 Protocol** over the Solana network.

By leveraging the long-dormant HTTP `402 Payment Required` status code, the x402 protocol facilitates frictionless machine-to-machine payments. Settling in stablecoins like USDC on Solana ensures transaction costs stay under $0.001 and settle in less than 500ms.

---

## Key Features

- **Standard HTTP 402 Workflows**: Automatic generation and resolution of payment challenges.
- **Node.js/TypeScript Support**: Preconfigured middlewares for Express, Hono, and Next.js.
- **Client Auto-Settlement**: Seamless client wrappers (`@x402/fetch` and `@x402/svm`) that sign, broadcast, and retry gated requests autonomously.
- **MCP Server Monetization**: Wrap any standard Model Context Protocol (MCP) server behind Solana micropayments.
- **Agent Safety Controls**: Built-in spending limits, KMS key vaulting, and transaction concurrency guardrails.

---

## Directory Structure

```
├── README.md                          # Project overview and specifications
├── LICENSE                            # MIT License
├── install.sh                         # Developer installation script
├── SKILL.md                           # Routing entry point & progressive load hub
├── references/
│   ├── x402-server-patterns.md    # Express, Hono, and Next.js middleware setups
│   ├── x402-client-patterns.md    # Fetch wrappers, wallet configs, and spending caps
│   ├── x402-solana-integration.md # USDC SPL Token transfer & verification
│   ├── x402-facilitator.md        # Verifier/Facilitator configurations
│   ├── x402-agent-kit.md          # LangChain and Solana Agent Kit integrations
│   ├── x402-mcp-monetization.md   # Wrapping & monetizing MCP servers
│   ├── x402-security.md           # Key management, spending caps, and safety rules
│   └── x402-testing.md            # Mocking payment challenges, local testing
├── agents/
│   ├── x402-architect.md              # System design & architecture helper agent
│   └── x402-builder.md                # Node.js/TypeScript developer helper agent
├── commands/
│   └── x402-scaffold.md               # Scaffolding helper script
└── rules/
    └── x402-security-rules.md         # Custom guidelines for safe agent commerce
```

---

## Quick Start & Installation

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

## Integration Overview

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

---

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
