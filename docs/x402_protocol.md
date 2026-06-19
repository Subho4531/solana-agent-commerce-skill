# x402 Protocol Specification & Solana Integration

This document describes the technical flow of the x402 Protocol and its direct integration with Solana using the `@x402/svm` package.

---

## 1. Technical Flow

The x402 flow integrates directly into standard HTTP request-response cycles:

1. **Initial Request**:
   The client makes a standard HTTP request to a protected API route (e.g., `GET /api/v1/analytics`).

2. **Payment Challenge (HTTP 402)**:
   The server intercepts the request, determines that it requires payment, and returns an `HTTP 402 Payment Required` response containing the `PAYMENT-REQUIRED` header:
   ```http
   HTTP/1.1 402 Payment Required
   PAYMENT-REQUIRED: scheme=solana-usdc, amount=0.01, address=YOUR_USDC_WALLET_ADDRESS, network=solana:mainnet
   ```

3. **Payment Settlement**:
   The client (or its integrated wallet library) parses the header, constructs an SPL Token transfer transaction for the specified USDC amount, signs it, and broadcasts/submits it to the network.

4. **Retry with Proof**:
   The client retries the original HTTP request, appending the payment signature to the header:
   ```http
   GET /api/v1/analytics HTTP/1.1
   X-PAYMENT: signature=TRANSACTION_SIGNATURE_HERE, scheme=solana-usdc
   ```

5. **Access Granted**:
   The server verifies the signature on-chain (or queries a Facilitator) to confirm payment, and returns `HTTP 200 OK` with the requested data.

---

## 2. official SDK packages

The `@x402` package ecosystem spans core client, server, and chain-specific plugins:

* **`@x402/core`**: Common types, serialization, and schema validation.
* **`@x402/svm`**: Solana Virtual Machine plugin; implements transaction construction and verification for Solana.
* **`@x402/fetch`**: Intercepts `402` responses in standard fetch calls, auto-signs, and retries.
* **`@x402/express` / `@x402/hono` / `@x402/next`**: Middleware to easily guard endpoints.

---

## 3. Solana Code Patterns

### Client-Side (Agent Consuming Gated API)

```typescript
import { wrapFetchWithPaymentFromConfig } from "@x402/fetch";
import { ExactSvmScheme } from "@x402/svm";
import { Keypair } from "@solana/web3.js";

// Load agent's wallet keypair
const agentKeypair = Keypair.fromSecretKey(...);

// Wrap fetch to automatically resolve 402s on Solana
const fetchWithPayment = wrapFetchWithPaymentFromConfig(fetch, {
  schemes: [{
    network: "solana:mainnet",
    client: new ExactSvmScheme(agentKeypair),
  }],
});

// The request below automatically settles payment on-chain if gated
const response = await fetchWithPayment("https://api.solana-service.com/gated-route");
const data = await response.json();
```

### Server-Side (Monetizing API)

```typescript
import express from "express";
import { paymentMiddleware } from "@x402/express";
import { ExactSvmScheme } from "@x402/svm";

const app = express();

app.use(
  paymentMiddleware({
    "GET /api/v1/analytics": {
      accepts: [{
        scheme: ExactSvmScheme.scheme,
        network: "solana:mainnet",
        maxAmountRequired: "0.005", // $0.005 USDC per query
        resource: "solana:mainnet:USDC_RECEIVER_WALLET_ADDRESS",
      }],
      description: "Get premium Solana analytics data.",
    },
  })
);

app.get("/api/v1/analytics", (req, res) => {
  res.json({ data: "Highly valuable analytics results" });
});
```
