# x402 Client Integration Patterns

Use this reference when building buyer agents that call paid HTTP APIs and automatically satisfy x402 `402 Payment Required` challenges.

## 1. Preferred fetch wrapper

Use `@x402/fetch` instead of parsing payment headers yourself. For Solana/SVM v2, create an `@solana/kit` signer, convert it with `toClientSvmSigner`, then register it with the x402 fetch wrapper.

```typescript
import { wrapFetchWithPayment } from "@x402/fetch";
import { createSvmClient } from "@x402/svm/client";
import { toClientSvmSigner } from "@x402/svm";
import { createKeyPairSignerFromBytes } from "@solana/kit";
import { base58 } from "@scure/base";

const keypair = await createKeyPairSignerFromBytes(
  base58.decode(process.env.SVM_PRIVATE_KEY!)
);

const signer = toClientSvmSigner(keypair);
const client = createSvmClient({
  signer,
  rpcUrl: process.env.SOLANA_RPC_URL,
});

const paidFetch = wrapFetchWithPayment(fetch, client);

const response = await paidFetch("https://api.provider.com/gated-endpoint", {
  headers: {
    "Idempotency-Key": crypto.randomUUID(),
  },
});

if (!response.ok) {
  throw new Error(`Paid request failed: ${response.status}`);
}

const paymentReceipt = response.headers.get("PAYMENT-RESPONSE");
const data = await response.json();
```

## 2. Config-driven fetch wrapper

If using `wrapFetchWithPaymentFromConfig`, keep the network as a v2 CAIP-2 ID:

```typescript
import { wrapFetchWithPaymentFromConfig } from "@x402/fetch";
import { ExactSvmScheme, toClientSvmSigner } from "@x402/svm";
import { createKeyPairSignerFromBytes } from "@solana/kit";
import { base58 } from "@scure/base";

const keypair = await createKeyPairSignerFromBytes(
  base58.decode(process.env.SVM_PRIVATE_KEY!)
);

const paidFetch = wrapFetchWithPaymentFromConfig(fetch, {
  schemes: [
    {
      network: "solana:EtWTRABZaYq6iMfeYKouRu166VU2xqa1",
      client: new ExactSvmScheme(toClientSvmSigner(keypair), {
        rpcUrl: process.env.SOLANA_RPC_URL,
      }),
    },
  ],
});
```

## 3. Spend policy guardrail

Do not rely on the remote server's price claim. Add local policy before using a paid fetch wrapper:

```typescript
const allowedDomains = new Set(["api.provider.com"]);
const maxAtomicUsdcPerRequest = 250_000n; // 0.25 USDC, 6 decimals
let spentTodayAtomicUsdc = 0n;
const dailyLimitAtomicUsdc = 5_000_000n; // 5 USDC

function assertSpendAllowed(url: string, requestedAtomicUsdc: bigint) {
  const host = new URL(url).host;
  if (!allowedDomains.has(host)) {
    throw new Error(`Blocked paid request to untrusted domain: ${host}`);
  }
  if (requestedAtomicUsdc > maxAtomicUsdcPerRequest) {
    throw new Error("Blocked paid request over per-request cap");
  }
  if (spentTodayAtomicUsdc + requestedAtomicUsdc > dailyLimitAtomicUsdc) {
    throw new Error("Blocked paid request over daily cap");
  }
}
```

When the SDK exposes payment-selection hooks, enforce:

- trusted domain
- expected CAIP-2 network
- expected USDC mint
- expected payee or payee allowlist
- max amount in atomic USDC units
- quote expiry
- daily/session budget

## 4. Avoid manual header flows

Avoid Axios interceptors or custom logic that parses `PAYMENT-REQUIRED` / `X-PAYMENT` by hand. Only use a manual flow when the SDK wrapper cannot be used, and then treat it as security-critical protocol code.

Always log `PAYMENT-RESPONSE` after successful paid calls for reconciliation.
