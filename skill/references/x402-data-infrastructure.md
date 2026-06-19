# Gating Data Infrastructure with x402

Use this reference to implement paid APIs proxying high-value data infrastructure on Solana, including Helius RPCs (DAS API, priority fees), Pyth Network oracles, and deployments via Cloudflare Workers.

---

## 1. Helius RPC Paid Proxy Pattern

This pattern gates access to expensive RPC operations (like DAS indexer queries or live priority fee estimates) with x402 payment requirements.

```typescript
import { Hono } from "hono";
import { paymentMiddleware } from "@x402/hono";
import { ExactSvmScheme } from "@x402/svm";

const app = new Hono();
const HELIUS_RPC_URL = `https://mainnet.helius-rpc.com/?api-key=${process.env.HELIUS_API_KEY}`;

// Define paid gating middleware
app.use(
  "/api/v1/infra/*",
  paymentMiddleware({
    "POST /api/v1/infra/das/assets": {
      accepts: [
        {
          scheme: ExactSvmScheme.scheme,
          network: "solana:5eykt4UsFv8P8NJdTREpY1vzqKqZKvdp",
          maxAmountRequired: "20000", // 0.02 USDC
          payTo: process.env.PAYEE_WALLET!,
          asset: "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v",
          maxAgeSeconds: 60,
        },
      ],
      description: "DAS indexer asset lookup (getAssetsByOwner).",
    },
    "POST /api/v1/infra/priority-fee": {
      accepts: [
        {
          scheme: ExactSvmScheme.scheme,
          network: "solana:5eykt4UsFv8P8NJdTREpY1vzqKqZKvdp",
          maxAmountRequired: "5000", // 0.005 USDC
          payTo: process.env.PAYEE_WALLET!,
          asset: "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v",
          maxAgeSeconds: 60,
        },
      ],
      description: "Get real-time optimal priority fee recommendations.",
    },
  })
);

/**
 * Endpoint: DAS Asset Search
 */
app.post("/api/v1/infra/das/assets", async (c) => {
  const { ownerAddress, page = 1, limit = 10 } = await c.req.json();

  if (!ownerAddress) {
    return c.json({ error: "Missing 'ownerAddress'" }, 400);
  }

  try {
    const response = await fetch(HELIUS_RPC_URL, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        jsonrpc: "2.0",
        id: "das-assets",
        method: "getAssetsByOwner",
        params: {
          ownerAddress,
          page,
          limit,
          displayOptions: { showFungible: true },
        },
      }),
    });

    const data = await response.json();
    return c.json(data);
  } catch (error: any) {
    return c.json({ error: `DAS proxy request failed: ${error.message}` }, 500);
  }
});

/**
 * Endpoint: Priority Fee Estimator
 */
app.post("/api/v1/infra/priority-fee", async (c) => {
  const { accountKeys } = await c.req.json();

  if (!accountKeys || !Array.isArray(accountKeys)) {
    return c.json({ error: "Missing or invalid 'accountKeys'" }, 400);
  }

  try {
    const response = await fetch(HELIUS_RPC_URL, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        jsonrpc: "2.0",
        id: "priority-fee",
        method: "getPriorityFeeEstimate",
        params: {
          accountKeys,
          options: { recommended: true },
        },
      }),
    });

    const data = await response.json();
    return c.json(data);
  } catch (error: any) {
    return c.json({ error: `Priority fee proxy failed: ${error.message}` }, 500);
  }
});
```

---

## 2. Gating Pyth Network Oracles

Monetizes price feeds fetched via Pyth's Hermes API. Consumers pay a micro-fee for the latest verified price update payload.

```typescript
const PYTH_HERMES_API = "https://hermes.pyth.network/v2/updates/price/latest";

app.use(
  "/api/v1/infra/pyth/price",
  paymentMiddleware({
    "GET /api/v1/infra/pyth/price": {
      accepts: [
        {
          scheme: ExactSvmScheme.scheme,
          network: "solana:5eykt4UsFv8P8NJdTREpY1vzqKqZKvdp",
          maxAmountRequired: "2000", // 0.002 USDC
          payTo: process.env.PAYEE_WALLET!,
          asset: "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v",
          maxAgeSeconds: 30,
        },
      ],
      description: "Fetch premium Pyth price feed payload with cryptographic signature.",
    },
  })
);

app.get("/api/v1/infra/pyth/price", async (c) => {
  const feedId = c.req.query("feedId");
  if (!feedId) {
    return c.json({ error: "Missing 'feedId' query parameter" }, 400);
  }

  try {
    const url = `${PYTH_HERMES_API}?ids[]=${feedId}`;
    const response = await fetch(url);
    if (!response.ok) {
      throw new Error(`Hermes API error: ${response.status}`);
    }

    const priceData = await response.json();
    return c.json(priceData);
  } catch (error: any) {
    return c.json({ error: `Failed to fetch Pyth oracle payload: ${error.message}` }, 500);
  }
});
```

---

## 3. Cloudflare Worker Deployment Pattern

A serverless implementation of an x402 gateway using a Cloudflare Worker.

### `wrangler.toml` Configuration
```toml
name = "x402-gateway-worker"
main = "src/index.ts"
compatibility_date = "2026-06-19"

[vars]
EXPECTED_NETWORK = "solana:EtWTRABZaYq6iMfeYKouRu166VU2xqa1"
PAYEE_WALLET = "Merch1111111111111111111111111111111111111"
USDC_MINT = "4zMMC9srt5Ri5X14GAgXhaHii3GnPAEERYPJgZJDncDU" # Devnet

# Bind secret keys securely in the dashboard using wrangler secret put HELIUS_API_KEY
```

### `src/index.ts` Cloudflare Worker Implementation
```typescript
export interface Env {
  HELIUS_API_KEY: string;
  EXPECTED_NETWORK: string;
  PAYEE_WALLET: string;
  USDC_MINT: string;
}

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    const url = new URL(request.url);

    // Bypass payment check for health status
    if (url.pathname === "/health") {
      return new Response("OK", { status: 200 });
    }

    // 1. Inspect payment header
    const paymentTxid = request.headers.get("x-payment-txid");
    const requiredAmountUsdc = 0.05; // $0.05 USDC

    if (!paymentTxid) {
      // Return HTTP 402 challenge if header is missing
      return new Response(
        JSON.stringify({
          error: "Payment Required",
          payTo: env.PAYEE_WALLET,
          amount: requiredAmountUsdc,
          network: env.EXPECTED_NETWORK,
          asset: env.USDC_MINT,
        }),
        {
          status: 402,
          headers: {
            "Content-Type": "application/json",
            "WWW-Authenticate": `x402 scheme="exact", recipient="${env.PAYEE_WALLET}", amount="${requiredAmountUsdc}", asset="${env.USDC_MINT}"`,
          },
        }
      );
    }

    // 2. Validate the payment txid via Helius transaction parsing endpoint
    try {
      const isPaid = await verifyHeliusPayment(paymentTxid, requiredAmountUsdc, env);
      if (!isPaid) {
        return new Response(JSON.stringify({ error: "Invalid payment transaction" }), {
          status: 403,
          headers: { "Content-Type": "application/json" },
        });
      }
    } catch (err: any) {
      return new Response(JSON.stringify({ error: `Verification failed: ${err.message}` }), {
        status: 500,
        headers: { "Content-Type": "application/json" },
      });
    }

    // 3. Payment Verified: Forward the request or return high-value data
    return new Response(
      JSON.stringify({
        success: true,
        data: "Premium data-infrastructure payload delivered successfully.",
      }),
      {
        status: 200,
        headers: {
          "Content-Type": "application/json",
          "PAYMENT-RESPONSE": JSON.stringify({ txid: paymentTxid, status: "settled" }),
        },
      }
    );
  },
};

/**
 * Verification helper using Helius Transaction API
 */
async function verifyHeliusPayment(txid: string, expectedAmount: number, env: Env): Promise<boolean> {
  const heliusUrl = `https://api.helius.xyz/v0/transactions/?api-key=${env.HELIUS_API_KEY}`;
  
  const response = await fetch(heliusUrl, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ transactions: [txid] }),
  });

  if (!response.ok) return false;

  const txData = (await response.json()) as any[];
  const tx = txData[0];

  if (!tx || !tx.tokenTransfers) return false;

  // Validate the payment transfer details
  return tx.tokenTransfers.some((transfer: any) => {
    return (
      transfer.toUserAccount === env.PAYEE_WALLET &&
      transfer.tokenMint === env.USDC_MINT &&
      parseFloat(transfer.tokenAmount) >= expectedAmount
    );
  });
}
```

---

## 4. Webhook Async Payment Verification Flow

For high-throughput systems, verifying payments synchronously via raw RPC/DAS requests can result in performance bottlenecks. Instead, use an asynchronous webhook model:

1. **Client requests service** with a transaction ID.
2. **Server enqueues job** and immediately returns `202 Accepted`.
3. **Webhook endpoint** receives confirmation from Helius/Validator when transaction finality is reached.
4. **Server updates local database** state (e.g. Postgres / Redis cache).
5. **Client pulls results** or receives push via WebSockets once payment is marked `settled`.
