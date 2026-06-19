---
name: scaffold-seller
description: Scaffolds a complete paid API route with x402 middleware using Express, Hono, or Next.js. Prompts the user for the framework, requested price, payee address, and route path, then generates the necessary server-side code including the ExactSvmScheme config and route handler.
---

# /scaffold-seller

This command generates a complete, secure seller route.

## Execution Steps

1.  **Ask the user:**
    *   Which framework? (Express, Hono, or Next.js)
    *   What is the route path? (e.g., `/api/v1/generate`)
    *   What is the price in USDC? (e.g., `0.05`)
    *   What is the payee Solana wallet address? (Must be a base58 public key)
    *   What network? (Mainnet or Devnet)

2.  **Generate the Code:**
    *   Use the templates found in `skill/server-patterns.md`.
    *   Ensure the `paymentMiddleware` is tightly bound to the exact URL and Method.
    *   Set `maxAgeSeconds: 60` for quote expiry.
    *   Set the `resource` field to `solana:<NETWORK_CAIP_2>:<PAYEE_ADDRESS>`.
    *   Read the payee address from `process.env.PAYEE_WALLET` if the user didn't provide a hardcoded one.

3.  **Explain the output:**
    *   Show the code.
    *   Remind the user to install `@x402/svm` and the framework-specific `@x402/*` package.
    *   Point them to `skill/security.md` for idempotency implementations.
