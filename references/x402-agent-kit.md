# Solana Agent Kit & LangChain Integration

This manual details how to hook x402 micropayments into the **Solana Agent Kit** and standard LLM orchestration frameworks like LangChain.

---

## 1. Creating an x402 LangChain Tool

You can expose x402 capabilities to LangChain agents as tools. This allows the LLM to decide when to make paid requests and manage its own budgets.

```typescript
import { Tool } from "@langchain/core/tools";
import { wrapFetchWithPaymentFromConfig } from "@x402/fetch";
import { ExactSvmScheme } from "@x402/svm";
import { Keypair } from "@solana/web3.js";

export class PaidAnalyticsTool extends Tool {
  name = "paid_analytics_provider";
  description = "Use this tool to fetch premium market analytics. Note: This tool consumes real USDC funds via Solana HTTP 402.";

  private fetchWithPayment: typeof fetch;

  constructor(agentKeypair: Keypair) {
    super();
    this.fetchWithPayment = wrapFetchWithPaymentFromConfig(fetch, {
      schemes: [{
        network: "solana:mainnet",
        client: new ExactSvmScheme(agentKeypair),
      }],
    });
  }

  async _call(input: string): Promise<string> {
    try {
      const response = await this.fetchWithPayment(
        `https://api.analytics-provider.com/query?q=${encodeURIComponent(input)}`
      );
      const data = await response.json();
      return JSON.stringify(data);
    } catch (error: any) {
      return `Failed to execute paid tool query: ${error.message}`;
    }
  }
}
```

---

## 2. Integrating with Solana Agent Kit

If you are using the official `solana-agent-kit` package, you can register x402 as an execution action.

```typescript
import { SolanaAgentKit, createSolanaTools } from "solana-agent-kit";
import { PaidAnalyticsTool } from "./PaidAnalyticsTool";

// Initialize the core agent kit
const agentKit = new SolanaAgentKit(
  process.env.SOLANA_PRIVATE_KEY!,
  process.env.SOLANA_RPC_URL!,
  { OPENAI_API_KEY: process.env.OPENAI_API_KEY }
);

// Instantiate standard tools
const tools = createSolanaTools(agentKit);

// Inject the x402 paid tool using the agent's keypair
const agentKeypair = agentKit.keypair;
tools.push(new PaidAnalyticsTool(agentKeypair));
```

This registers the paid tool directly into the agent's action space, allowing the planner to pull analytics data dynamically by submitting USDC micropayments when prompted.
