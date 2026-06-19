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

---

## 3. Sandboxing & Input Sanitization

Before submitting any payment transaction constructed by an agent, verify:
- **Recipient Address**: Compare the recipient wallet address against a known blocklist or check if it matches a whitelist of known service providers.
- **USDC Mint Verification**: Ensure the SPL token mint matches exactly the official USDC Mint address. A malicious 402 header could specify a fake token mint, draining custom tokens.
- **Gas Fees (Lamports)**: Set a strict cap on the Solana fee payer budget to prevent "priority fee draining" attacks where an adversary requests excessive transaction prioritization fees.
