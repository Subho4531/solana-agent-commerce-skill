# x402 Facilitators & Verification Networks

Facilitators act as verification nodes. Rather than requiring every server to poll RPC endpoints directly (which is slow and expensive), servers can rely on an x402 Facilitator to guarantee transaction validity and cache payment proofs.

---

## 1. What is an x402 Facilitator?

An x402 Facilitator is a decentralized or centralized agent that listens to the blockchain, monitors SPL USDC transfers, and issues cryptographically signed validation certificates.

```
+------------+                 +------------+
|            | -- 1. Challenge --> |            |
|   Client   | <--- 2. HTTP 402 -- |   Server   |
|  (Agent)   |                     |  (Provider)|
|            | --- 4. Request+ ---> |            |
|            |        Proof        |            |
+------------+                     +------------+
      |                                  |
 3. SPL Transfer                  5. Verify Proof
      |                                  |
      v                                  v
+------------+                     +------------+
|   Solana   | <--- Listen/Sync --- |    x402    |
| Blockchain |                      | Facilitator|
+------------+                      +------------+
```

---

## 2. Using a Hosted Facilitator

You can configure your server to verify payments via the public x402 verification network:

```typescript
import { paymentMiddleware } from "@x402/express";

app.use(
  paymentMiddleware({
    endpoints: {
      "GET /api/v1/data": {
        accepts: [{
          scheme: "solana-usdc",
          network: "solana:mainnet",
          amount: "0.01",
          resource: "solana:mainnet:USDC_RECEIVER",
        }]
      }
    },
    // Verify signatures via the official Facilitator REST API
    facilitatorUrl: "https://api.x402.org",
    apiKey: process.env.X402_FACILITATOR_KEY,
  })
);
```

---

## 3. Self-Hosted Facilitator Setup

For high-speed, enterprise-grade applications, host your own facilitator. A self-hosted facilitator runs a local node or high-performance RPC subscription (like Helius webhooks) to record transaction signatures.

### Steps to Run:
1. Deploy the `@x402/facilitator-node` service in your infrastructure.
2. Connect it to a dedicated Solana RPC node.
3. Configure Redis for instant memory caching of verified signatures.
4. Set the `facilitatorUrl` in your servers to point to your internal load balancer (e.g., `http://facilitator.internal.local`).

This avoids public network roundtrips, reducing verification times from ~1.5s to <50ms.
