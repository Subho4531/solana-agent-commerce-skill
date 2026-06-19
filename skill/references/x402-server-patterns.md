# x402 Server Integration Patterns

Use this reference when protecting HTTP endpoints with x402 payment requirements settled on Solana USDC.

## Defaults

```typescript
const SOLANA_MAINNET = "solana:5eykt4UsFv8P8NJdTREpY1vzqKqZKvdp";
const SOLANA_DEVNET = "solana:EtWTRABZaYq6iMfeYKouRu166VU2xqa1";
const USDC_MAINNET = "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v";
const USDC_DEVNET = "4zMMC9srt5Ri5X14GAgXhaHii3GnPAEERYPJgZJDncDU";
```

Use `exact` for Solana/SVM x402 payments. Do not use `solana-usdc` or `solana:mainnet` in v2 examples.

## Express route gate

Use the framework middleware from `@x402/express` and bind every payment requirement tightly to the route.

```typescript
import express from "express";
import { paymentMiddleware } from "@x402/express";
import { ExactSvmScheme } from "@x402/svm";

const app = express();

const network = process.env.X402_NETWORK ?? "solana:EtWTRABZaYq6iMfeYKouRu166VU2xqa1";
const payTo = process.env.PAYEE_WALLET!;

app.use(
  paymentMiddleware({
    "POST /api/v1/generate": {
      accepts: [
        {
          scheme: ExactSvmScheme.scheme,
          network,
          maxAmountRequired: "50000", // 0.05 USDC in atomic units when supported by middleware
          payTo,
          asset: process.env.USDC_MINT,
          maxAgeSeconds: 60,
        },
      ],
      description: "AI image generation endpoint.",
    },
  })
);

app.post("/api/v1/generate", (req, res) => {
  if (!req.header("Idempotency-Key")) {
    return res.status(428).json({ error: "Idempotency-Key required" });
  }

  res.json({ image: "data:image/png;base64,..." });
});
```

If your installed middleware expects a different field name such as `resource` instead of `payTo`/`asset`, map the same values without changing the security model: exact network, exact asset, exact payee, exact method/route, and short expiry.

## Hono route gate

```typescript
import { Hono } from "hono";
import { paymentMiddleware } from "@x402/hono";
import { ExactSvmScheme } from "@x402/svm";

const app = new Hono();

app.use(
  "/api/v1/translate",
  paymentMiddleware({
    accepts: [
      {
        scheme: ExactSvmScheme.scheme,
        network: process.env.X402_NETWORK ?? "solana:EtWTRABZaYq6iMfeYKouRu166VU2xqa1",
        maxAmountRequired: "1000",
        payTo: process.env.PAYEE_WALLET!,
        asset: process.env.USDC_MINT,
        maxAgeSeconds: 60,
      },
    ],
    description: "Premium translation service.",
  })
);

app.post("/api/v1/translate", (c) => {
  if (!c.req.header("Idempotency-Key")) {
    return c.json({ error: "Idempotency-Key required" }, 428);
  }

  return c.json({ translatedText: "..." });
});
```

## Next.js route handlers

Prefer official `@x402/next` helpers/middleware for Next.js. Do not hand-roll `PAYMENT-REQUIRED`, `X-PAYMENT`, or on-chain verification logic in route handlers unless the installed SDK requires it.

Minimum server checks:

- route and HTTP method are exact
- `network` is a v2 CAIP-2 ID
- `asset` is the expected USDC mint
- `payTo` is the expected wallet
- `maxAmountRequired` is in the expected unit for the installed middleware
- `maxAgeSeconds` is short, usually 60 seconds
- mutating methods require `Idempotency-Key`
