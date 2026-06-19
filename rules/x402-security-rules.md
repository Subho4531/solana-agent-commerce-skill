# x402 Developer Security Rules

When developing and running agentic systems equipped with the `solana-agent-commerce-skill`, you must adhere to the following security rules:

---

## 1. Secret Key Management
- **Rule 1.1**: NEVER save Solana private keys or mnemonic phrases in plain-text source files, code blocks, or commit history.
- **Rule 1.2**: Use environment variables (`process.env`) loaded from isolated `.env` files (which must be added to `.gitignore`).
- **Rule 1.3**: For production environments, utilize secure KMS vault signers instead of keeping hot keys directly in the agent execution runtime.

---

## 2. Spending Thresholds
- **Rule 2.1**: Set a hard daily spending limit (in USDC) for each running agent.
- **Rule 2.2**: Reject any 402 challenge that requests more than the configured per-transaction cap (default: $0.50 USDC).
- **Rule 2.3**: Require explicit human-in-the-loop confirmation for any payment transaction exceeding $1.00 USDC.

---

## 3. Concurrency and Rate Limits
- **Rule 3.1**: Enforce a cooldown between automatic 402 resolutions (e.g., minimum 5 seconds between consecutive signature broadcasts).
- **Rule 3.2**: Implement transactional queues or durable nonce accounts if the agent makes highly concurrent API requests to prevent double-spending or signature conflicts.
