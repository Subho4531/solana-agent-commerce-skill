---
name: scaffold-buyer
description: Scaffolds a client agent or script that autonomously pays x402 challenges using @x402/fetch. Generates the wallet setup, client configuration, and spend policy limits.
---

# /scaffold-buyer

This command generates a secure client capable of autonomously paying 402s.

## Execution Steps

1.  **Gather Requirements:**
    *   Target API URL (e.g., `https://api.example.com/data`)
    *   Maximum allowed price per request in atomic USDC and display USDC (e.g., `250000` = 0.25 USDC)
    *   Daily/session budget in atomic USDC
    *   Trusted domain allowlist
    *   Expected network, USDC mint, and payee allowlist when known
    *   Wallet source (KMS/HSM for production, base58 env secret only for local development)
    *   Network (Mainnet or Devnet)

2.  **Generate the Code:**
    *   Adopt the `x402-builder` persona.
    *   Use the patterns found in `skill/references/x402-client-patterns.md`.
    *   Use an `@solana/kit` signer plus `toClientSvmSigner`; do not use raw `@solana/web3.js` `Keypair` examples.
    *   Configure the correct RPC URL and remind the user to use a private RPC in production.
    *   Wrap standard `fetch` using `wrapFetchWithPayment` or `wrapFetchWithPaymentFromConfig`.
    *   **CRITICAL**: Implement per-request and daily spending caps in atomic USDC units to prevent drain attacks.
    *   Log `PAYMENT-RESPONSE` receipts for reconciliation.

3.  **Explain the output:**
    *   Present the code clearly.
    *   Remind the user to install `@x402/core`, `@x402/svm`, `@x402/fetch`, `@solana/kit`, and `@scure/base`.
    *   Point them to `rules/x402-security-rules.md` regarding private key management.

## Prompt Template

*You can copy and paste this template to quickly scaffold a buyer client:*

```markdown
Please use the `/scaffold-buyer` command to create an autonomous agent client.
- **Target API**: `https://paid-api.com/v1/run-task`
- **Max Price**: 0.25 USDC per request
- **Wallet**: Load base58 local dev secret from `process.env.SVM_PRIVATE_KEY`
- **Network**: Devnet
- **RPC**: Load from `process.env.HELIUS_RPC_URL`
- **Trusted Domains**: `paid-api.com`
- **Daily Budget**: 5 USDC

Ensure the fetch call includes an Idempotency-Key header.
```
