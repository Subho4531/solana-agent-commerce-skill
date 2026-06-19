---
name: scaffold-seller
description: Scaffolds a complete paid API route with x402 middleware using Express, Hono, or Next.js. Generates the necessary server-side code including the ExactSvmScheme config and route handler.
---

# /scaffold-seller

This command generates a complete, secure seller route.

## Execution Steps

1.  **Gather Requirements:** If the user hasn't provided the necessary details, ask them or use the Prompt Template below.
    *   Framework (Express, Hono, Next.js)
    *   Route Path (e.g., `/api/v1/generate`)
    *   Price in USDC (e.g., `0.05`)
    *   Payee Solana wallet address (Base58)
    *   Network (Mainnet or Devnet)

2.  **Generate the Code:**
    *   Adopt the `x402-builder` persona.
    *   Use the patterns found in `skill/references/x402-server-patterns.md`.
    *   Ensure `paymentMiddleware` is tightly bound to the exact URL and Method.
    *   Set `maxAgeSeconds: 60` for quote expiry.
    *   Set the payment requirement with exact `network`, `asset`/USDC mint, and `payTo`/payee wallet fields supported by the installed middleware. If the middleware uses `resource`, do not concatenate `solana:<NETWORK_CAIP_2>`; CAIP-2 IDs already include the `solana:` namespace.
    *   Read the payee address from `process.env.PAYEE_WALLET` if not provided.
    *   **CRITICAL**: Include validation for an `Idempotency-Key` header if the route is a POST/PUT/DELETE.

3.  **Explain the output:**
    *   Present the code clearly.
    *   Remind the user to install `@x402/svm`, `@x402/core`, and the framework-specific `@x402/*` package.

## Prompt Template

*You can copy and paste this template to quickly scaffold a seller route:*

```markdown
Please use the `/scaffold-seller` command to create a paid API endpoint.
- **Framework**: Hono
- **Route Path**: `/api/v1/summarize`
- **Method**: POST
- **Price**: 0.10 USDC
- **Payee Address**: (Read from process.env.PAYEE_WALLET)
- **Network**: Mainnet

Make sure to include basic idempotency key validation in the route handler.
```
