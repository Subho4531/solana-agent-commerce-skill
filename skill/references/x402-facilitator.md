# x402 Facilitators & Verification Networks

Facilitators verify and settle x402 payment payloads, relieving sellers of the need to parse raw Solana transaction logs or query RPC node validation manually. Use this reference to configure, integrate, and deploy hosted or self-hosted x402 facilitators.

---

## 1. Protocol Architecture & Flow

The facilitator acts as a trusted verification middleware or settlement oracle between the client, the seller server, and the blockchain network.

```text
Client -> Server: request protected resource
Server -> Client: 402 payment requirements
Client -> Solana: sign/broadcast payment transaction
Client -> Server: retry request with x402 payment headers (X-Payment-Txid, etc.)
Server -> Facilitator: verify payment (checks tx exists, paid to payee, correct USDC/asset/amount)
Facilitator -> Server: returns verified payload
Server -> Client: resource + PAYMENT-RESPONSE receipt header
```

For Solana, the facilitator operates using the `exact` payment scheme via the `@x402/svm` engine.

---

## 2. Hosted Facilitator Integration

The official hosted facilitator handles settlement verification dynamically. Keep the endpoints configurable via environment variables.

### Environment Configuration
```env
X402_FACILITATOR_URL=https://x402.org/facilitator
X402_FACILITATOR_API_KEY=your_secured_api_key
```

### Manual Verification via REST (Fallback Pattern)
If you are not using framework-specific x402 middleware, you can verify payments manually by making a POST request to the facilitator endpoint:

```typescript
interface FacilitatorVerifyResponse {
  verified: boolean;
  network: string;
  txid: string;
  payee: string;
  amountAtomic: string;
  asset: string;
  timestamp: number;
}

/**
 * Manually queries the facilitator to verify an x402 payment
 */
export async function verifyPaymentWithFacilitator(
  txid: string,
  expectedAmount: bigint,
  expectedPayee: string,
  expectedAsset: string
): Promise<boolean> {
  const url = `${process.env.X402_FACILITATOR_URL || "https://x402.org/facilitator"}/verify`;
  const apiKey = process.env.X402_FACILITATOR_API_KEY;

  try {
    const response = await fetch(url, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        ...(apiKey ? { "Authorization": `Bearer ${apiKey}` } : {})
      },
      body: JSON.stringify({
        txid,
        expectedAmount: expectedAmount.toString(),
        expectedPayee,
        expectedAsset
      })
    });

    if (!response.ok) {
      console.error(`Facilitator verification returned status ${response.status}`);
      return false;
    }

    const data = (await response.json()) as FacilitatorVerifyResponse;
    return data.verified;
  } catch (error) {
    console.error("Facilitator query failed:", error);
    return false;
  }
}
```

---

## 3. Self-Hosted Facilitator Configuration

For high-volume production use cases or applications with strict privacy compliance, you should self-host the facilitator service.

### Checklist:
- **Private Solana RPC**: Avoid public RPC endpoints which can fail under load or rate limits.
- **Dedicated Fee Payer Signer**: Isolated keypair with a small SOL balance to pay for transaction polling or signature confirmation queries.
- **Settlement Receipt Caching**: Store payment status in a high-speed database or Redis to prevent double-spending checks from overloading the Solana RPC.
- **Network Rate Limits**: Implement API rate limits to prevent denial-of-service (DoS) attacks on verification endpoints.

### Self-Hosted Express/Hono Setup with Redis Caching
Below is an implementation of a basic self-hosted verification handler with Redis caching to avoid repeating RPC queries.

```typescript
import { Hono } from "hono";
import { createSolanaRpc, Address } from "@solana/kit";
import { createClient } from "redis";

const app = new Hono();
const rpc = createSolanaRpc(process.env.SOLANA_RPC_URL || "https://api.mainnet-beta.solana.com");
const redis = createClient({ url: process.env.REDIS_URL || "redis://localhost:6379" });

await redis.connect();

app.post("/verify", async (c) => {
  const { txid, expectedAmount, expectedPayee, expectedAsset } = await c.req.json();

  if (!txid || !expectedAmount || !expectedPayee || !expectedAsset) {
    return c.json({ error: "Missing required fields" }, 400);
  }

  // 1. Check Redis Cache
  const cachedStatus = await redis.get(`tx:${txid}`);
  if (cachedStatus === "verified") {
    return c.json({ verified: true, source: "cache" });
  }

  try {
    // 2. Query Solana blockchain for transaction details
    const txInfo = await rpc.getTransaction(txid, {
      maxSupportedTransactionVersion: 0,
      encoding: "jsonParsed"
    }).send();

    if (!txInfo || !txInfo.value || txInfo.value.meta?.err) {
      return c.json({ verified: false, error: "Transaction not found or failed on-chain" });
    }

    // 3. Verify transfer amounts (Token Balance Change Analysis)
    // Simple mock logic: in production, parse the innerInstructions or balance changes
    const isValid = await validateBalanceChanges(txInfo.value, expectedAmount, expectedPayee, expectedAsset);

    if (isValid) {
      // Cache the result for 24 hours to prevent replay checks
      await redis.setEx(`tx:${txid}`, 86400, "verified");
      return c.json({ verified: true, source: "rpc" });
    }

    return c.json({ verified: false, error: "Payment details mismatch" });
  } catch (error: any) {
    return c.json({ verified: false, error: error.message }, 500);
  }
});

async function validateBalanceChanges(
  tx: any,
  amount: string,
  payee: string,
  asset: string
): Promise<boolean> {
  // Parsing instructions and balance adjustments for exact payment verification
  return true;
}
```

---

## 4. Operational Best Practices & Troubleshooting

### RPC Load Balancing
Always configure fallback RPC endpoints. If your facilitator experiences rate limiting, it will fail to verify valid user transactions, causing request drops.

### Signer Key Rotation
When self-hosting a facilitator with transaction writing capabilities (e.g. batching or auto-renewing leases), rotate fee-payer keys quarterly and monitor gas depletion.

### Resolution Timeouts
Set connection timeouts on facilitator requests to 3000ms. If the facilitator is unresponsive, fall back to checking on-chain RPC logs directly (or fail open/close based on risk policy).
