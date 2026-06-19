# x402 Security, Key Vaulting, and Spending Caps

Security is paramount in agentic workflows. Because agents sign transactions using private keys, builders must enforce strict security boundaries.

---

## 1. KMS Key Management

Never store private keys in plaintext `.env` files or raw database records. Use Key Management Services (KMS) like AWS KMS, Google Cloud KMS, or HashiCorp Vault.

### Pattern: Remote Signature Requests
Instead of giving the agent a raw private key, have the agent request a signature from a secure, isolated microservice that enforces policies.

```
+------------+       1. SignRequest (Tx, Amount)       +---------------------+
|            | --------------------------------------> | Secure Sign Service |
| AI Agent   |                                         | - Checks budget     |
|            | <------ 2. Signed Transaction ---------- | - Decrypts KMS key  |
+------------+                                         +---------------------+
```

---

## 2. Spending Thresholds & Cooldowns

Implement cooldown periods and hard maximum spending thresholds to protect against runaway agent loops.

### Checklist:
- [ ] **Per-Transaction Cap**: Maximum USDC amount allowed for a single 402 challenge.
- [ ] **Daily/Weekly Budget**: Global limits across all transactions in a rolling window.
- [ ] **Rate Limiting (Cooldowns)**: Enforce a minimum interval between payments (e.g., maximum 1 payment every 10 seconds).
- [ ] **Manual Approval Threshold**: Any transaction above a certain amount (e.g., $1.00 USDC) requires human-in-the-loop approval.
- [ ] **Domain Allowlist**: Only pay hosts that the user or application explicitly trusts.
- [ ] **Network Allowlist**: Only pay expected CAIP-2 IDs such as `solana:EtWTRABZaYq6iMfeYKouRu166VU2xqa1` for devnet.
- [ ] **Payee Allowlist**: Match the seller wallet against a known allowlist when possible.
- [ ] **Receipt Log**: Persist `PAYMENT-RESPONSE` with request ID, route, amount, payee, network, and timestamp.

---

## 3. Sandboxing & Input Sanitization

Before submitting any payment transaction constructed by an agent, verify:
- **Recipient Address**: Compare the recipient wallet address against an allowlist of known service providers. Treat blocklists as supplemental only.
- **USDC Mint Verification**: Ensure the SPL token mint exactly matches the expected USDC mint for the CAIP-2 network.
- **Amount Units**: Compare limits in atomic USDC units, not floating-point dollars.
- **Quote Expiry**: Reject stale payment requirements and require short server-side `maxAgeSeconds`.
- **Gas Fees (Lamports)**: Set a strict cap on the Solana fee payer budget to prevent priority-fee draining.
- **Route Binding**: Bind payment to method, URL, network, asset, payee, and price. Never accept a payment proof for a different route.
- **Idempotency**: Require an `Idempotency-Key` on POST/PUT/PATCH/DELETE and store processed keys to avoid double execution.
