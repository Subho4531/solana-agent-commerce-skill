# Solana Agent Kit, LangChain, and AI SDK Integration

Use this reference when exposing paid x402 calls as tools inside agent frameworks.

## 1. LangChain paid tool

Keep payment execution behind a narrow tool with explicit spend policy. Do not let the LLM choose arbitrary paid URLs.

```typescript
import { Tool } from "@langchain/core/tools";
import { wrapFetchWithPayment } from "@x402/fetch";
import { createSvmClient } from "@x402/svm/client";
import { toClientSvmSigner } from "@x402/svm";
import type { TransactionSigner } from "@solana/kit";

export class PaidAnalyticsTool extends Tool {
  name = "paid_analytics_provider";
  description = "Fetch premium analytics. Costs at most 0.10 USDC per call.";

  private paidFetch: typeof fetch;

  constructor(signer: TransactionSigner) {
    super();

    const client = createSvmClient({
      signer: toClientSvmSigner(signer),
      rpcUrl: process.env.SOLANA_RPC_URL,
    });

    this.paidFetch = wrapFetchWithPayment(fetch, client);
  }

  async _call(input: string): Promise<string> {
    const url = new URL("https://api.analytics-provider.com/query");
    url.searchParams.set("q", input);

    if (url.host !== "api.analytics-provider.com") {
      throw new Error("Blocked untrusted paid analytics host");
    }

    const response = await this.paidFetch(url, {
      headers: {
        "Idempotency-Key": crypto.randomUUID(),
      },
    });

    const receipt = response.headers.get("PAYMENT-RESPONSE");
    const data = await response.json();

    return JSON.stringify({ receipt, data });
  }
}
```

## 2. Solana Agent Kit

Solana Agent Kit APIs change frequently. Before generating final code, inspect the installed package version and adapt signer extraction to that version.

Integration pattern:

1. Create or obtain a Solana Kit-compatible signer for the agent wallet.
2. Convert it with `toClientSvmSigner`.
3. Wrap `fetch` with `@x402/fetch`.
4. Register a narrow paid tool/action with fixed provider URL and budget limits.

Do not assume `agentKit.keypair` exists unless the installed package exposes it.

## 3. Agent policy

Any paid tool exposed to an LLM planner must enforce:

- fixed provider domain
- max price per call
- daily/session budget
- expected Solana CAIP-2 network
- expected USDC mint
- expected payee allowlist when known
- receipt logging
- idempotency key for mutating or expensive calls
