# Solana Integration & SPL USDC Settlement

This manual covers the Solana blockchain specifics for the x402 Protocol, detailing USDC Mint addresses, SVM schemes, and connection details.

---

## 1. USDC Mint Addresses

Micropayments are settled in USDC to ensure price stability for APIs and tools.

| Network | USDC Mint Address | Decimals |
| :--- | :--- | :--- |
| **Mainnet-Beta** | `EPjFW31aGw91sgEQ1DfujZbn1frMH915vc785uYL21t` | 6 |
| **Devnet** | `4zMMC9zPy429a3KAeA5NDXv56A5xstVeWCntmdewWY6` | 6 |

---

## 2. Using ExactSvmScheme

The `ExactSvmScheme` handles constructing standard Solana SPL Token transfer transactions, signing them with the agent keypair, and submitting them.

```typescript
import { Connection, Keypair, PublicKey } from "@solana/web3.js";
import { ExactSvmScheme } from "@x402/svm";

const connection = new Connection("https://api.mainnet-beta.solana.com", "confirmed");
const keypair = Keypair.fromSecretKey(Uint8Array.from([/* ... */]));

const scheme = new ExactSvmScheme(keypair, {
  connection,
  commitment: "confirmed",
  // Optional custom USDC mint
  usdcMint: new PublicKey("EPjFW31aGw91sgEQ1DfujZbn1frMH915vc785uYL21t"),
});
```

---

## 3. Server-Side Payment Verification

When a client retries a request with the header `X-PAYMENT: signature=SIGNATURE, scheme=solana-usdc`, the server must verify it.

```typescript
import { Connection } from "@solana/web3.js";
import { verifySvmTransfer } from "@x402/svm";

const connection = new Connection("https://api.mainnet-beta.solana.com", "confirmed");

async function checkPayment(signature: string, expectedAmount: number, receiverWallet: string) {
  try {
    const status = await verifySvmTransfer(connection, {
      signature,
      amount: expectedAmount,
      receiver: receiverWallet,
      mint: "EPjFW31aGw91sgEQ1DfujZbn1frMH915vc785uYL21t",
    });

    return status.verified; // boolean
  } catch (error) {
    console.error("Payment verification failed:", error);
    return false;
  }
}
```

---

## 4. Concurrency & Blockhash Management

Under high throughput (e.g., an agent executing 10 calls per second), transactions can fail due to blockhash collisions or duplicate transaction signatures.

### Best Practices:
1. **Nonce Accounts**: For highly concurrent agents, use Solana Durable Nonces to sign transactions asynchronously without worrying about 150-blockhash expirations.
2. **Signature Buffering**: Queue outbound HTTP 402 completions and execute payments sequentially, or use separate fee payers and keypair channels.
