# x402 Security, Key Vaulting, and Spending Caps

Security is paramount in agentic workflows. Because agents sign transactions using private keys, builders must enforce strict security boundaries. Use this reference to implement robust security checks, OFAC compliance, gas drain mitigations, Token-2022 validations, durable nonces, and prompt injection defenses.

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

### Spending Safety Manager Checklist:
- **Per-Transaction Cap**: Maximum USDC amount allowed for a single 402 challenge.
- **Daily/Weekly Budget**: Global limits across all transactions in a rolling window.
- **Rate Limiting (Cooldowns)**: Enforce a minimum interval between payments (e.g., maximum 1 payment every 10 seconds).
- **Manual Approval Threshold**: Any transaction above a certain amount (e.g., $1.00 USDC) requires human-in-the-loop approval.
- **Domain Allowlist**: Only pay hosts that the user or application explicitly trusts.
- **Network Allowlist**: Only pay expected CAIP-2 IDs such as `solana:EtWTRABZaYq6iMfeYKouRu166VU2xqa1` for devnet.
- **Payee Allowlist**: Match the seller wallet against a known allowlist when possible.
- **Receipt Log**: Persist `PAYMENT-RESPONSE` with request ID, route, amount, payee, network, and timestamp.

---

## 3. OFAC Screening Compliance

Autonomous agents must comply with financial regulations, including OFAC sanctions. Check target wallets against known sanctioned addresses before signing.

```typescript
import { Address } from "@solana/kit";

// Hardcoded sample list of prohibited/sanctioned wallets (e.g. OFAC SDN list entries)
const SANCTIONED_WALLETS = new Set<string>([
  "11111111111111111111111111111111", // Prohibited
  "9w8P358E2Ugz74Kx1B2n7zZ27H2K3Wv4", // Mock Sanctioned Address
]);

/**
 * Validates payee wallet address against sanction lists
 */
export function assertOfacCompliance(payeeAddress: string): void {
  if (SANCTIONED_WALLETS.has(payeeAddress)) {
    throw new Error(`[OFAC BLOCKED] Transfer to sanctioned address is prohibited: ${payeeAddress}`);
  }
}
```

---

## 4. Gas Fee Drain Attack Prevention

Malicious actors or buggy sellers can exploit an agent by requesting transactions that specify exorbitant priority fees, draining the agent's SOL balance.

### Defense: Enforce Compute Budget Caps
When signing or sending transactions, inspect and override the transaction's compute budget instructions:

```typescript
import { 
  addTransactionInstruction, 
  createDefaultTransaction,
  signTransaction
} from "@solana/kit";

// Gas Guardrail Limits
const MAX_PRIORITY_FEE_LAMPORTS = 100_000n; // Cap priority fee per tx at 0.0001 SOL
const MAX_COMPUTE_UNIT_PRICE = 500_000n; // Micro-lamports per CU limit

/**
 * Safely adds priority fee instructions with a strict upper cap
 */
export function enforceComputeBudgetCaps(
  transaction: any,
  computeUnits: number,
  microLamportsPerCU: bigint
): any {
  const safeCUPrice = microLamportsPerCU > MAX_COMPUTE_UNIT_PRICE 
    ? MAX_COMPUTE_UNIT_PRICE 
    : microLamportsPerCU;

  // Add standard ComputeBudget instructions to override transaction fees
  const setCuLimitIx = {
    programId: "ComputeBudget111111111111111111111111111111" as any,
    keys: [],
    data: Buffer.from([0, ...writeInt(computeUnits)]) // SetComputeUnitLimit
  };

  const setCuPriceIx = {
    programId: "ComputeBudget111111111111111111111111111111" as any,
    keys: [],
    data: Buffer.from([3, ...writeBigInt(safeCUPrice)]) // SetComputeUnitPrice
  };

  let updatedTx = addTransactionInstruction(setCuLimitIx, transaction);
  updatedTx = addTransactionInstruction(setCuPriceIx, updatedTx);
  return updatedTx;
}

function writeInt(val: number): Uint8Array {
  const buf = new ArrayBuffer(4);
  new DataView(buf).setUint32(0, val, true);
  return new Uint8Array(buf);
}

function writeBigInt(val: bigint): Uint8Array {
  const buf = new ArrayBuffer(8);
  new DataView(buf).setBigUint64(0, val, true);
  return new Uint8Array(buf);
}
```

---

## 5. Token-2022 Transfer Fee Validation

Some SPL Token-2022 mints employ a **Transfer Fee** extension. If an agent pays with a Token-2022 token, it must calculate the net transfer output to ensure the seller receives the exact requested amount *after* fees, without exceeding the agent's absolute spending cap.

```typescript
import { Address } from "@solana/kit";

interface Token2022TransferFeeConfig {
  feeBasisPoints: number;
  maximumFee: bigint;
}

/**
 * Calculates total gross amount required to ensure recipient receives expectedAmount
 */
export function calculateToken2022GrossAmount(
  expectedAmount: bigint,
  feeConfig: Token2022TransferFeeConfig
): bigint {
  const bps = BigInt(feeConfig.feeBasisPoints);
  const maxFee = feeConfig.maximumFee;

  // Expected fee = expectedAmount * bps / 10000
  let calculatedFee = (expectedAmount * bps) / 10000n;
  if (calculatedFee > maxFee) {
    calculatedFee = maxFee;
  }

  const grossAmount = expectedAmount + calculatedFee;
  return grossAmount;
}
```

---

## 6. Durable Nonces for Network Congestion

When the Solana network experiences heavy congestion, transactions signed using standard recent blockhashes can expire before confirmation (approx. 60-90 seconds). This leads to a race condition where the agent might retry and double-pay.

**Solution**: High-frequency agents should create a **Durable Nonce Account**. A transaction signed with a durable nonce has an indefinite lifespan, allowing safe retries without the risk of double-spending.

```typescript
// Durable Nonce instruction pattern using @solana/kit
import { Address } from "@solana/kit";

interface NonceTxParams {
  nonceAccount: Address;
  nonceValue: string; // From getAccountInfo for nonce account
  authorizedSigner: Address;
}

export function buildNonceInstruction(params: NonceTxParams) {
  return {
    programId: "11111111111111111111111111111111" as Address, // System Program
    keys: [
      { pubkey: params.nonceAccount, isSigner: false, isWritable: true },
      { pubkey: "SysvarRecentBlockHashes11111111111111111111" as Address, isSigner: false, isWritable: false },
      { pubkey: params.authorizedSigner, isSigner: true, isWritable: false }
    ],
    data: Buffer.from([4]) // AdvanceNonceAccount instruction discriminator
  };
}
```

---

## 7. LLM Prompt Injection Defenses

If your agent takes user prompts directly, malicious inputs might attempt to trick the agent into paying arbitrary wallets or increasing spending limits.

### Hardening Strategies:
1. **Payee Allowlist Enforcement**: Perform check validation outside the LLM execution context. The runtime code must intercept all `paidFetch` calls and validate the payee's Address against a static/verified database.
2. **Strict Parser Validation**: Never allow the LLM to write base58 private keys or call signing methods directly. Gated actions must go through the spending manager.
3. **Structured Outputs**: Require the LLM to output a structured JSON plan (rather than running raw scripts). The plan is validated by a secure schema parser before executing on-chain actions.
