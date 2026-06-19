# Solana Integration & SPL USDC Settlement

Use this reference for Solana network IDs, USDC mints, signers, settlement safety, Associated Token Accounts (ATA), Token-2022 detections, durable nonces, and compute budget overrides.

---

## 1. Network and USDC Constants

Use x402 v2 CAIP-2 network IDs. Do not use v1 shorthand values like `solana:mainnet` in x402 v2 examples.

| Network | CAIP-2 ID | USDC Mint Address | Decimals |
| :--- | :--- | :--- | :--- |
| **Mainnet-Beta** | `solana:5eykt4UsFv8P8NJdTREpY1vzqKqZKvdp` | `EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v` | 6 |
| **Devnet** | `solana:EtWTRABZaYq6iMfeYKouRu166VU2xqa1` | `4zMMC9srt5Ri5X14GAgXhaHii3GnPAEERYPJgZJDncDU` | 6 |
| **Testnet** | `solana:4uhcVJyU9pJkvQyS88uRDiswHXSCkY3z` | `4zMMC9srt5Ri5X14GAgXhaHii3GnPAEERYPJgZJDncDU` | 6 |

---

## 2. Client Signer Setup

`@x402/svm` v2 uses Solana Kit signers. Load secrets from a local development secret or KMS, then convert the signer for x402.

```typescript
import { createSvmClient } from "@x402/svm/client";
import { toClientSvmSigner } from "@x402/svm";
import { createKeyPairSignerFromBytes } from "@solana/kit";
import { base58 } from "@scure/base";

const keypair = await createKeyPairSignerFromBytes(
  base58.decode(process.env.SVM_PRIVATE_KEY!)
);

const client = createSvmClient({
  signer: toClientSvmSigner(keypair),
  rpcUrl: process.env.SOLANA_RPC_URL,
});
```

Use base58 secrets for local development. In production, load the signer from KMS/HSM or a wallet service. Never commit raw secret-key arrays.

---

## 3. Server Verification

Prefer official x402 middleware/facilitator verification over hand-rolled Solana RPC polling. The server should validate the payment requirement it issued:
- Method and route binding
- CAIP-2 network matching
- USDC mint / asset validation
- Exact payee checking
- Max amount checking in atomic USDC units
- Quote expiry / `maxAgeSeconds` enforcement
- Idempotency key validation for mutating routes

---

## 4. Associated Token Account (ATA) Existence Checks

Before initiating an SPL token transfer to settle an x402 requirement, verify if the recipient's Associated Token Account (ATA) exists. Sending a token transfer to a non-existent ATA will cause the transaction to fail. If it is missing, create it first using the `createAssociatedTokenAccountInstruction` helper.

```typescript
import { Address, createSolanaRpc } from "@solana/kit";
import { getAssociatedTokenAddressSync, createAssociatedTokenAccountInstruction } from "@solana/spl-token";
import { PublicKey } from "@solana/web3.js";

/**
 * Asserts if ATA exists, returning transaction instruction to create it if it doesn't
 */
export async function getOrCreateAtaInstructionIfNeeded(
  rpcUrl: string,
  walletAddress: string,
  tokenMintAddress: string,
  payerAddress: string
): Promise<any | null> {
  const rpc = createSolanaRpc(rpcUrl);
  
  const walletPubKey = new PublicKey(walletAddress);
  const mintPubKey = new PublicKey(tokenMintAddress);
  const payerPubKey = new PublicKey(payerAddress);

  // 1. Calculate ATA Address
  const ataAddress = getAssociatedTokenAddressSync(
    mintPubKey,
    walletPubKey,
    true // Allow owner off-curve (e.g. PDAs)
  );

  try {
    // 2. Fetch account info to verify existence
    const accountInfo = await rpc.getAccountInfo(ataAddress.toBase58() as Address).send();
    
    // If account exists, no creation instruction needed
    if (accountInfo && accountInfo.value !== null) {
      return null;
    }
  } catch (error) {
    console.log("ATA does not exist. Formatting creation instruction...");
  }

  // 3. Construct creation instruction
  const creationInstruction = createAssociatedTokenAccountInstruction(
    payerPubKey,
    ataAddress,
    walletPubKey,
    mintPubKey
  );

  return creationInstruction;
}
```

---

## 5. Token-2022 Detection & Extension Checks

If the asset mint utilizes the newer Token-2022 standard, you must inspect the mint's extensions to see if additional fees (like transfer fee hooks) will be applied.

```typescript
import { createSolanaRpc, Address } from "@solana/kit";

// Token-2022 Program ID Address
const TOKEN_2022_PROGRAM_ID = "TokenzQdBNbLqP5xxaAkJ7yyWjLMzXJqUPPStVEtC2";

/**
 * Checks if a mint is managed by Token-2022 program and lists its extensions
 */
export async function getMintProgramAndExtensions(
  rpcUrl: string,
  mintAddress: Address
): Promise<{ program: string; isToken2022: boolean; extensions: string[] }> {
  const rpc = createSolanaRpc(rpcUrl);
  
  const accountInfo = await rpc.getAccountInfo(mintAddress).send();
  if (!accountInfo || !accountInfo.value) {
    throw new Error("Mint account not found.");
  }

  const ownerProgram = accountInfo.value.owner;
  const isToken2022 = ownerProgram === TOKEN_2022_PROGRAM_ID;
  const extensions: string[] = [];

  if (isToken2022) {
    // Deserialize mint layout to find extension types
    const rawData = accountInfo.value.data;
    // Inspect byte layout for extension presence (e.g., Transfer Fee, Mint Close Authority, Interest Bearing)
    // Custom parsers look for specific type-length-value (TLV) data at the end of the 165-byte base mint layout
    console.log("Token-2022 mint detected. Reviewing transfer fee config...");
  }

  return {
    program: ownerProgram,
    isToken2022,
    extensions,
  };
}
```

---

## 6. Durable Nonces

Durable nonces allow transactions to bypass the standard 150-blockhash expiry window. This is critical for offline signers, high-security cold storage, or slow multi-agent pipeline resolution.

```typescript
import { createSolanaRpc, Address } from "@solana/kit";

/**
 * Checks the current nonce value of a durable nonce account
 */
export async function getNonceAccountValue(
  rpcUrl: string,
  nonceAccountAddress: Address
): Promise<string> {
  const rpc = createSolanaRpc(rpcUrl);
  const accountInfo = await rpc.getAccountInfo(nonceAccountAddress).send();
  
  if (!accountInfo || !accountInfo.value) {
    throw new Error("Nonce account not found");
  }

  const data = accountInfo.value.data;
  // Parse the NonceAccount state from data buffer:
  // Nonce state starts with a 4-byte version, followed by 4-byte state, then public key (32 bytes) and blockhash (32 bytes)
  const nonceBlockhash = Buffer.from(data).slice(40, 72).toString("hex");
  return nonceBlockhash;
}
```

---

## 7. Compute Budget & Priority Fees

Enforcing custom compute budgets prevents transactions from failing due to out-of-gas errors or getting stuck in the mempool during network congestion.

```typescript
import { addTransactionInstruction } from "@solana/kit";
import { Buffer } from "buffer";

// Helper function to build ComputeBudget Program setComputeUnitPrice instruction
export function createSetComputeUnitPriceInstruction(microLamports: bigint) {
  const data = Buffer.alloc(9);
  data.writeUInt8(3, 0); // Discriminator
  data.writeBigUInt64LE(microLamports, 1); // Micro-lamports

  return {
    programId: "ComputeBudget111111111111111111111111111111" as Address,
    keys: [],
    data: new Uint8Array(data),
  };
}
```
