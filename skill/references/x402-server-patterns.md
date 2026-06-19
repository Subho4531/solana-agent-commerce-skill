# x402 Server Integration Patterns

This manual describes how to protect your server endpoints using HTTP 402 Payment Required challenges, settled via Solana.

---

## Express Middleware

Use `@x402/express` to gate specific endpoints.

```typescript
import express from "express";
import { paymentMiddleware } from "@x402/express";
import { ExactSvmScheme } from "@x402/svm";

const app = express();

app.use(
  paymentMiddleware({
    "POST /api/v1/generate": {
      accepts: [{
        scheme: ExactSvmScheme.scheme,
        network: "solana:mainnet",
        maxAmountRequired: "0.05", // $0.05 USDC
        resource: "solana:mainnet:USDC_RECEIVER_WALLET_ADDRESS",
      }],
      description: "AI image generation endpoint.",
    },
  })
);

app.post("/api/v1/generate", (req, res) => {
  // Business logic here
  res.json({ image: "data:image/png;base64,..." });
});
```

---

## Hono Middleware

For edge/lightweight runtimes, use `@x402/hono`.

```typescript
import { Hono } from "hono";
import { paymentMiddleware } from "@x402/hono";
import { ExactSvmScheme } from "@x402/svm";

const app = new Hono();

app.use(
  "/api/v1/translate",
  paymentMiddleware({
    accepts: [{
      scheme: ExactSvmScheme.scheme,
      network: "solana:mainnet",
      maxAmountRequired: "0.001", // $0.001 USDC
      resource: "solana:mainnet:USDC_RECEIVER_WALLET_ADDRESS",
    }],
    description: "Premium translation service.",
  })
);

app.post("/api/v1/translate", (c) => {
  return c.json({ translatedText: "..." });
});
```

---

## Next.js API Routes (App Router)

Gate routes in Next.js Route Handlers.

```typescript
// app/api/v1/analytics/route.ts
import { NextResponse } from "next/server";
import { verifyPayment } from "@x402/next";

export async function GET(request: Request) {
  const paymentHeader = request.headers.get("X-PAYMENT");

  if (!paymentHeader) {
    return new NextResponse("Payment Required", {
      status: 402,
      headers: {
        "PAYMENT-REQUIRED": "scheme=solana-usdc, amount=0.01, address=USDC_RECEIVER_WALLET_ADDRESS, network=solana:mainnet"
      }
    });
  }

  // Verify the payment signature on-chain
  const isValid = await verifyPayment(paymentHeader, {
    amount: 0.01,
    receiver: "USDC_RECEIVER_WALLET_ADDRESS",
    network: "solana:mainnet"
  });

  if (!isValid) {
    return NextResponse.json({ error: "Invalid payment proof" }, { status: 403 });
  }

  return NextResponse.json({ data: "Highly valuable analytics results" });
}
```
