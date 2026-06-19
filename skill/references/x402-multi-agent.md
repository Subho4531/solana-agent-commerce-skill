# Multi-Agent Commerce & Trust Delegation

Use this reference to implement agent-to-agent (M2M) payment architectures, including service registries, orchestrator-worker patterns, spend delegation, and cost accounting.

---

## 1. Service Registry & Discovery

To pay each other, agents need to discover what services exist and their pricing. A service registry publishes a JSON manifest containing the agent endpoint, description, capabilities, network, asset, and pricing details.

### JSON Manifest Schema (`agent-service.json`)
```json
{
  "agentId": "solana-translator-agent",
  "endpoint": "https://translate.agent.network",
  "version": "1.0.0",
  "payment": {
    "network": "solana:5eykt4UsFv8P8NJdTREpY1vzqKqZKvdp",
    "asset": "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v",
    "payee": "Merch1111111111111111111111111111111111111",
    "pricing": {
      "GET /translate": {
        "scheme": "exact",
        "amount": "5000" 
      }
    }
  }
}
```

---

## 2. Orchestrator-Worker Payment Flow

In this pattern, an **Orchestrator Agent** acts as a client that delegates subtasks to specialized **Worker Agents**. The Worker Agents gate their API routes behind x402, requiring the Orchestrator to pay in USDC.

```typescript
import { wrapFetchWithPayment } from "@x402/fetch";
import { createSvmClient } from "@x402/svm/client";
import { toClientSvmSigner } from "@x402/svm";
import { createKeyPairSignerFromBytes } from "@solana/kit";
import { base58 } from "@scure/base";

/**
 * Orchestrator calls a paid worker agent using the x402 fetch wrapper
 */
export async function callWorkerAgent(
  workerUrl: string,
  payload: any,
  orchestratorPrivateKey: string,
  rpcUrl: string
): Promise<any> {
  const keypair = await createKeyPairSignerFromBytes(
    base58.decode(orchestratorPrivateKey)
  );

  const client = createSvmClient({
    signer: toClientSvmSigner(keypair),
    rpcUrl
  });

  const paidFetch = wrapFetchWithPayment(fetch, client);

  console.log(`[Orchestrator] Calling paid worker agent at: ${workerUrl}`);
  const response = await paidFetch(workerUrl, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "Idempotency-Key": crypto.randomUUID()
    },
    body: JSON.stringify(payload)
  });

  if (!response.ok) {
    throw new Error(`Worker agent rejected request with status ${response.status}`);
  }

  const receiptHeader = response.headers.get("PAYMENT-RESPONSE");
  console.log(`[Orchestrator] Received payment confirmation receipt: ${receiptHeader}`);

  return response.json();
}
```

---

## 3. Trust & Spend Delegation

When an Orchestrator spawns a Sub-Agent, it should never share its primary private key. Instead, the Orchestrator delegates a limited spending policy to the Sub-Agent.

### Spending Policy Schema for Sub-Agents

```typescript
export interface SubAgentSpendPolicy {
  subAgentPublicKey: string;
  maxAtomicUsdcPerCall: bigint;
  totalSessionBudgetAtomicUsdc: bigint;
  expirationTimestamp: number;
}

export class SpendDelegationGuard {
  private policy: SubAgentSpendPolicy;
  private currentSpent: bigint = 0n;

  constructor(policy: SubAgentSpendPolicy) {
    this.policy = policy;
  }

  /**
   * Asserts if the sub-agent is authorized to spend the requested amount
   */
  public checkSpendAuthorization(requestedAmount: bigint): void {
    if (Date.now() > this.policy.expirationTimestamp) {
      throw new Error("[SPEND DENIED] Spend delegation session has expired.");
    }

    if (requestedAmount > this.policy.maxAtomicUsdcPerCall) {
      throw new Error(`[SPEND DENIED] Requested amount ${requestedAmount} exceeds per-call cap of ${this.policy.maxAtomicUsdcPerCall}`);
    }

    if (this.currentSpent + requestedAmount > this.policy.totalSessionBudgetAtomicUsdc) {
      throw new Error(`[SPEND DENIED] Session budget exceeded. Spent: ${this.currentSpent}, Requested: ${requestedAmount}, Budget: ${this.policy.totalSessionBudgetAtomicUsdc}`);
    }
  }

  /**
   * Commits the spent amount after a successful payment
   */
  public recordSpend(amount: bigint): void {
    this.currentSpent += amount;
  }
}
```

---

## 4. Multi-Hop Cost Accounting

In a multi-hop pipeline (e.g. Orchestrator -> Researcher Agent -> Translator Agent), the total budget must be tracked across the entire chain to prevent budget exhaustion.

To achieve this, the Orchestrator passes a tracking header (`X-Session-Budget-Trace`) that lists the remaining budget and the spending chain.

```typescript
interface BudgetTrace {
  sessionId: string;
  originalBudgetAtomic: string;
  remainingBudgetAtomic: string;
  hopCount: number;
}

/**
 * Middleware for Worker Agents to parse and enforce multi-hop budget headers
 */
export function enforceTraceBudget(maxHopLimit = 5) {
  return async (c: any, next: any) => {
    const traceHeader = c.req.header("X-Session-Budget-Trace");
    
    if (traceHeader) {
      const trace = JSON.parse(traceHeader) as BudgetTrace;
      
      if (trace.hopCount >= maxHopLimit) {
        return c.json({ error: "Max multi-hop limit exceeded" }, 400);
      }

      const remaining = BigInt(trace.remainingBudgetAtomic);
      if (remaining <= 0n) {
        return c.json({ error: "Distributed session budget fully exhausted" }, 403);
      }
    }
    
    await next();
  };
}
```

---

## 5. Bidding & Competing Marketplaces

Orchestrator agents can query multiple workers offering the same capability to find the cheapest service.

```typescript
interface Bid {
  agentEndpoint: string;
  priceAtomicUsdc: bigint;
  estimatedLatencyMs: number;
}

export async function queryBidsForTask(
  candidateEndpoints: string[]
): Promise<Bid | null> {
  const bids: Bid[] = [];

  for (const endpoint of candidateEndpoints) {
    try {
      const startTime = Date.now();
      // Fetch the manifest or query the price of the endpoint
      const response = await fetch(`${endpoint}/manifest`);
      if (response.ok) {
        const manifest = await response.json();
        const price = BigInt(manifest.payment.pricing["POST /task"].amount);
        
        bids.push({
          agentEndpoint: endpoint,
          priceAtomicUsdc: price,
          estimatedLatencyMs: Date.now() - startTime
        });
      }
    } catch (err) {
      console.warn(`Failed to retrieve bid from: ${endpoint}`);
    }
  }

  if (bids.length === 0) return null;

  // Sort by price ascending, then latency ascending
  bids.sort((a, b) => {
    if (a.priceAtomicUsdc !== b.priceAtomicUsdc) {
      return a.priceAtomicUsdc < b.priceAtomicUsdc ? -1 : 1;
    }
    return a.estimatedLatencyMs - b.estimatedLatencyMs;
  });

  return bids[0]; // Returns the cheapest, lowest latency bid
}
```

---

## 6. Price-Inflation & Sybil Attack Defenses

To prevent malicious sub-agents or worker proxies from artificially inflating transaction pricing:

1. **Signed Price Quotes**: Workers must sign their payment challenges. The buyer agent verifies that the price was signed by the registered provider public key within the last `maxAgeSeconds`.
2. **Replay Cache**: Buyer agents must cache the transaction IDs of settled payments locally to avoid double-paying for the same challenge.
3. **Payee Allowlist**: Buyer agents must verify the payee's public key against a list of known service providers before signing the transaction payload.
