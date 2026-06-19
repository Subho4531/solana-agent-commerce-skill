---
name: scaffold-buyer
description: Scaffolds a complete buyer agent fetch wrapper with a secure spend policy and receipt logger. Prompts the user for daily budget, max per request, and allowlisted domains, then generates the TypeScript code to intercept 402s, sign transactions, and log receipts.
---

# /scaffold-buyer

This command generates a secure, policy-constrained fetch client for buyer agents.

## Execution Steps

1.  **Ask the user:**
    *   What is the `maxPerRequest` budget in USDC? (e.g., `0.10`)
    *   What is the `dailyBudget` in USDC? (e.g., `5.00`)
    *   What are the allowed domains? (e.g., `["api.trusted.com"]`)
    *   What network? (Mainnet or Devnet)

2.  **Generate the Code:**
    *   Use the templates found in `skill/client-patterns.md`.
    *   Include the secure keypair loading snippet from `skill/solana-integration.md` (reading from `process.env.AGENT_SECRET_KEY`).
    *   Implement the `onPaymentRequired` hook enforcing the requested spend policy.
    *   Implement the receipt logging block.

3.  **Explain the output:**
    *   Show the code.
    *   Remind the user they need SOL for gas and USDC for payments.
    *   Provide the shell command to generate a devnet keypair.
