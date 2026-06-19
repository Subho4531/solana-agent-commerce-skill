# x402 Developer Security Rules

When developing and running agentic systems equipped with the `solana-agent-commerce-skill`, you must adhere to the following security rules:

---

## 1. Secret Key Management
- **Rule 1.1**: NEVER save Solana private keys or mnemonic phrases in plain-text source files, code blocks, or commit history.
- **Rule 1.2**: Use environment variables (`process.env`) loaded from isolated `.env` files (which must be added to `.gitignore`).
- **Rule 1.3**: For production environments, utilize secure KMS vault signers (AWS KMS, Google Cloud KMS, HashiCorp Vault) instead of keeping hot keys directly in the agent execution runtime.

---

## 2. Spending Thresholds
- **Rule 2.1**: Set a hard daily spending limit (in USDC) for each running agent.
- **Rule 2.2**: Reject any 402 challenge that requests more than the configured per-transaction cap (default: $0.50 USDC).
- **Rule 2.3**: Require explicit human-in-the-loop confirmation for any payment transaction exceeding $1.00 USDC.

---

## 3. Concurrency and Rate Limits
- **Rule 3.1**: Enforce a cooldown between automatic 402 resolutions (e.g., minimum 5 seconds between consecutive signature broadcasts).
- **Rule 3.2**: Implement transactional queues or durable nonce accounts if the agent makes highly concurrent API requests to prevent double-spending or signature conflicts.

---

## 4. Network Operations & Reliability
- **Rule 4.1**: Never rely solely on public RPC endpoints for production applications. Configure private RPCs (e.g., Helius, Triton, QuickNode).
- **Rule 4.2**: Implement exponential backoff and retry mechanisms for all RPC calls.
- **Rule 4.3**: Dynamically calculate priority fees to ensure transaction inclusion during network congestion, especially for time-sensitive payments. Do not use static priority fees.

---

## 5. Strict x402 Validation
- **Rule 5.1**: The client MUST strictly validate the payee address in the `402 Payment Required` challenge against an expected value or a trusted directory before sending funds.
- **Rule 5.2**: The client MUST validate the `asset` field (e.g., ensuring it's the correct USDC mint) and the `network` CAIP-2 ID (e.g., ensuring it's Mainnet, not Devnet, when expecting production).
- **Rule 5.3**: The server MUST configure a short `maxAgeSeconds` (e.g., 60 seconds) to prevent replay attacks with stale price quotes.

---

## 6. Idempotency
- **Rule 6.1**: All state-changing endpoints (e.g., POST, PUT, DELETE) gated by x402 MUST require and validate an `Idempotency-Key` header from the client.
- **Rule 6.2**: The server MUST store idempotency keys alongside payment receipts to ensure that a client is not charged twice for retrying a failed or timed-out request.
