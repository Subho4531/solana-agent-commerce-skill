# Solana Integration & SPL USDC Settlement

Use this reference for Solana network IDs, USDC mints, signers, and settlement safety.

## 1. Network and USDC constants

Use x402 v2 CAIP-2 network IDs.

| Network | CAIP-2 ID | USDC mint | Decimals |
| :--- | :--- | :--- | :--- |
| Mainnet-Beta | `solana:5eykt4UsFv8P8NJdTREpY1vzqKqZKvdp` | `EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v` | 6 |
| Devnet | `solana:EtWTRABZaYq6iMfeYKouRu166VU2xqa1` | `4zMMC9srt5Ri5X14GAgXhaHii3GnPAEERYPJgZJDncDU` | 6 |
| Testnet | `solana:4uhcVJyU9pJkvQyS88uRDiswHXSCkY3z` | `4zMMC9srt5Ri5X14GAgXhaHii3GnPAEERYPJgZJDncDU` | 6 |

Do not use v1 shorthand values like `solana:mainnet` in x402 v2 examples.

## 2. Client signer setup

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

## 3. Server verification

Prefer official x402 middleware/facilitator verification over hand-rolled Solana RPC polling. The server should validate the payment requirement it issued:

- method and route
- CAIP-2 network
- USDC mint / asset
- exact payee
- max amount in atomic USDC units
- quote expiry / `maxAgeSeconds`
- idempotency key for mutating routes

Do not use obsolete helpers such as `verifySvmTransfer` unless the currently installed `@x402/svm` package exports them.

## 4. Concurrency and duplicate settlement

High-throughput agents should:

1. Use unique idempotency keys for POST/PUT/PATCH/DELETE.
2. Log the `PAYMENT-RESPONSE` receipt for every successful paid call.
3. Serialize payments per wallet when troubleshooting blockhash/nonce issues.
4. Prefer SDK/facilitator duplicate-settlement protection instead of inventing a second replay cache.
5. Use a private RPC for production traffic.
