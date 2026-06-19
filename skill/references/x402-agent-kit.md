# Agent Frameworks (LangChain, LangGraph, and Vercel AI SDK)

Use this reference to integrate paid x402 actions as tools inside modern agent frameworks, including LangChain, LangGraph, and the Vercel AI SDK.

---

## 1. Vercel AI SDK `tool()` Integration

The Vercel AI SDK uses the `tool` function to define agent actions. The implementation below registers a gated x402 tool with a local spending guardrail.

```typescript
import { tool } from "ai";
import { z } from "zod";
import { wrapFetchWithPayment } from "@x402/fetch";
import { createSvmClient } from "@x402/svm/client";
import { toClientSvmSigner } from "@x402/svm";
import { createKeyPairSignerFromBytes } from "@solana/kit";
import { base58 } from "@scure/base";

// 1. Initialize the paid fetch client
const keypair = await createKeyPairSignerFromBytes(
  base58.decode(process.env.SVM_PRIVATE_KEY!)
);

const svmClient = createSvmClient({
  signer: toClientSvmSigner(keypair),
  rpcUrl: process.env.SOLANA_RPC_URL!,
});

const paidFetch = wrapFetchWithPayment(fetch, svmClient);

// 2. Define the spend cap and policy
const MAX_USDC_BUDGET_ATOMIC = 100_000n; // 0.10 USDC per call
let sessionSpendAtomic = 0n;
const MAX_SESSION_SPEND_ATOMIC = 1_000_000n; // 1.00 USDC total budget

/**
 * Paid tool for Vercel AI SDK
 */
export const paidMarketDataTool = tool({
  description: "Queries high-value market intelligence data. Costs up to 0.10 USDC.",
  parameters: z.object({
    tokenSymbol: z.string().describe("The token symbol to fetch analytics for (e.g. SOL, JUP)"),
  }),
  execute: async ({ tokenSymbol }) => {
    // Enforce pre-execution spend limits
    if (sessionSpendAtomic + MAX_USDC_BUDGET_ATOMIC > MAX_SESSION_SPEND_ATOMIC) {
      throw new Error("AGENT_BUDGET_EXHAUSTED: Tool call blocked to prevent exceeding session budget.");
    }

    const targetUrl = `https://api.alpha-signals.com/v1/market-data?symbol=${tokenSymbol}`;
    
    try {
      const response = await paidFetch(targetUrl, {
        headers: {
          "Idempotency-Key": crypto.randomUUID(),
        },
      });

      if (!response.ok) {
        throw new Error(`Market data provider returned HTTP ${response.status}`);
      }

      // Track paid amount from payment receipt headers
      const receiptRaw = response.headers.get("PAYMENT-RESPONSE");
      if (receiptRaw) {
        const receipt = JSON.parse(receiptRaw);
        const amountSpent = BigInt(receipt.amountAtomic || 0);
        sessionSpendAtomic += amountSpent;
        console.log(`[Spend Update] Spent ${amountSpent} atomic USDC. Session total: ${sessionSpendAtomic}`);
      }

      const data = await response.json();
      return { success: true, data };
    } catch (error: any) {
      return { success: false, error: error.message };
    }
  },
});
```

---

## 2. LangGraph Stateful Agent Integration

In stateful agent frameworks like LangGraph, the agent's total spend and billing receipts should be stored in the graph's global state. This prevents state loss across multi-turn LLM reasoning loops.

```typescript
import { StateGraph, Annotation } from "@langchain/langgraph";
import { wrapFetchWithPayment } from "@x402/fetch";

// 1. Define Graph State including the payment ledger
const AgentState = Annotation.Root({
  messages: Annotation<any[]>({
    reducer: (x, y) => x.concat(y),
    default: () => [],
  }),
  totalSpentAtomicUsdc: Annotation<bigint>({
    reducer: (x, y) => x + y,
    default: () => 0n,
  }),
  paymentReceipts: Annotation<string[]>({
    reducer: (x, y) => x.concat(y),
    default: () => [],
  }),
});

// 2. Define the paid node
async function callPaidTranslationNode(state: typeof AgentState.State) {
  const lastMessage = state.messages[state.messages.length - 1];
  const textToTranslate = lastMessage.content;

  // Enforce graph-level budget protection
  const BUDGET_LIMIT = 500_000n; // 0.50 USDC
  if (state.totalSpentAtomicUsdc >= BUDGET_LIMIT) {
    return {
      messages: [{ role: "assistant", content: "I have reached my maximum translation budget limit." }]
    };
  }

  // Execute x402 call
  const targetUrl = "https://paid.translator.agent/translate";
  const client = getGlobalSvmPaymentClient(); // Returns wrapped svm client
  const paidFetch = wrapFetchWithPayment(fetch, client);

  const response = await paidFetch(targetUrl, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ text: textToTranslate, targetLang: "es" })
  });

  const receipt = response.headers.get("PAYMENT-RESPONSE") || "";
  const result = await response.json();

  // Extract payment details to return state updates
  let txSpent = 0n;
  if (receipt) {
    const parsedReceipt = JSON.parse(receipt);
    txSpent = BigInt(parsedReceipt.amountAtomic || 0);
  }

  return {
    messages: [{ role: "assistant", content: `Translation: ${result.translatedText}` }],
    totalSpentAtomicUsdc: txSpent,
    paymentReceipts: [receipt]
  };
}
```

---

## 3. Solana Agent Kit v2 Integration

When integrating with the `solana-agent-kit`, inspect the version pattern to safely extract keypairs/signers. Avoid assuming `.keypair` exists directly on the agent class.

```typescript
import { SolanaAgentKit } from "solana-agent-kit";
import { createKeyPairSignerFromBytes } from "@solana/kit";
import { toClientSvmSigner } from "@x402/svm";

/**
 * Safely extracts signer from SolanaAgentKit instance
 */
export async function getSignerFromAgentKit(
  agent: SolanaAgentKit
): Promise<ReturnType<typeof toClientSvmSigner>> {
  // 1. Detect and extract secret key bytes safely
  let secretKeyBytes: Uint8Array;
  
  if (typeof agent.wallet?.secretKey === "object") {
    secretKeyBytes = new Uint8Array(Object.values(agent.wallet.secretKey));
  } else if (agent.wallet instanceof Uint8Array) {
    secretKeyBytes = agent.wallet;
  } else if (typeof agent.wallet === "string") {
    // If wallet is stored as base58 string
    const { base58 } = await import("@scure/base");
    secretKeyBytes = base58.decode(agent.wallet);
  } else {
    throw new Error("Unable to resolve private key bytes from SolanaAgentKit wallet instance");
  }

  // 2. Create the @solana/kit signer
  const keypairSigner = await createKeyPairSignerFromBytes(secretKeyBytes);
  return toClientSvmSigner(keypairSigner);
}
```

---

## 4. Budget Exhaustion & User Handover

If an agent exhausts its allocated budget, it must gracefully pause, format a summary of its spending, and hand control back to the user.

```typescript
export class BudgetExhaustedError extends Error {
  public totalSpent: bigint;
  public budgetLimit: bigint;

  constructor(message: string, totalSpent: bigint, budgetLimit: bigint) {
    super(message);
    this.name = "BudgetExhaustedError";
    this.totalSpent = totalSpent;
    this.budgetLimit = budgetLimit;
  }
}

/**
 * Executes a paid action and handles budget exhaustion
 */
export async function executeGatedActionWithFallback(
  actionFn: () => Promise<any>,
  currentSpend: bigint,
  budgetLimit: bigint
): Promise<any> {
  if (currentSpend >= budgetLimit) {
    throw new BudgetExhaustedError(
      "Agent budget exhausted. Awaiting manual user top-up or budget increase.",
      currentSpend,
      budgetLimit
    );
  }

  try {
    return await actionFn();
  } catch (error: any) {
    if (error.message?.includes("BUDGET_EXHAUSTED")) {
      // Format manual intervention report for user UI
      console.warn(`[BUDGET PAUSE] Agent paused. Spent: ${currentSpend} / Limit: ${budgetLimit}`);
    }
    throw error;
  }
}
```
