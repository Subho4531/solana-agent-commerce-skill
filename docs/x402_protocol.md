# x402 Protocol Specification & Solana Integration

This document describes the x402 HTTP payment flow and the Solana/SVM defaults used by this skill.

## 1. Technical flow

1. **Initial request**: the client calls a protected API route.
2. **Payment challenge**: the server returns `402 Payment Required` with structured x402 payment requirements.
3. **Payment payload**: the client SDK constructs and signs the required payment payload.
4. **Retry**: the client retries the original request using the SDK-managed payment header.
5. **Verification/settlement**: the server/facilitator verifies and settles the payment.
6. **Receipt**: the server returns the resource and a `PAYMENT-RESPONSE` receipt header.

Prefer official SDK wrappers over hand-written `PAYMENT-REQUIRED` / `X-PAYMENT` parsing.

## 2. Official SDK packages

- `@x402/core`: common types, serialization, and schema validation.
- `@x402/svm`: Solana Virtual Machine implementation.
- `@x402/fetch`: fetch wrapper that resolves 402 responses.
- `@x402/express`, `@x402/hono`, `@x402/next`: server middleware.

## 3. Solana defaults

| Network | CAIP-2 ID | USDC mint |
| :--- | :--- | :--- |
| Mainnet-Beta | `solana:5eykt4UsFv8P8NJdTREpY1vzqKqZKvdp` | `EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v` |
| Devnet | `solana:EtWTRABZaYq6iMfeYKouRu166VU2xqa1` | `4zMMC9srt5Ri5X14GAgXhaHii3GnPAEERYPJgZJDncDU` |

## 4. Client-side pattern

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
const response = await fetchWithPayment("https://api.solana-service.com/gated-route");
const receipt = response.headers.get("PAYMENT-RESPONSE");
const data = await response.json();
```

## 5. Server-side pattern

```typescript
import express from "express";
import { paymentMiddleware } from "@x402/express";
import { ExactSvmScheme } from "@x402/svm";

const app = express();

app.use(
  paymentMiddleware({
    "GET /api/v1/analytics": {
      accepts: [
        {
          scheme: ExactSvmScheme.scheme,
          network: "solana:EtWTRABZaYq6iMfeYKouRu166VU2xqa1",
          maxAmountRequired: "5000",
          payTo: process.env.PAYEE_WALLET!,
          asset: "4zMMC9srt5Ri5X14GAgXhaHii3GnPAEERYPJgZJDncDU",
          maxAgeSeconds: 60,
        },
      ],
      description: "Get premium Solana analytics data.",
    },
  })
);

app.get("/api/v1/analytics", (req, res) => {
  res.json({ data: "Highly valuable analytics results" });
});
```
