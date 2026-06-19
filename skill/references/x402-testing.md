# Testing & Mocking x402 Integrations

Use this reference to test paid agent actions without accidentally spending mainnet funds.

## 1. Unit tests

Unit tests should validate server behavior and local policy without making real payments:

- protected routes return `402` when no payment is supplied
- payment requirements include the expected network, asset, payee, amount, and expiry
- mutating routes reject requests without `Idempotency-Key`
- buyer policy blocks unknown domains, unexpected networks, wrong payees, and over-budget prices
- successful paid responses log `PAYMENT-RESPONSE`

Avoid subclassing `ExactSvmScheme` with fake `.pay()` methods; that API shape is stale. Mock the transport boundary instead: use a local test server that returns deterministic 402 challenges, and mock `fetch`/SDK calls at the wrapper boundary.

## 2. Devnet integration setup

Use Solana devnet for live integration tests:

```bash
solana config set --url devnet
solana airdrop 2
```

Use these x402/Solana constants:

```text
Network: solana:EtWTRABZaYq6iMfeYKouRu166VU2xqa1
USDC mint: 4zMMC9srt5Ri5X14GAgXhaHii3GnPAEERYPJgZJDncDU
```

Client setup:

```typescript
import { wrapFetchWithPayment } from "@x402/fetch";
import { createSvmClient } from "@x402/svm/client";
import { toClientSvmSigner } from "@x402/svm";
import { createKeyPairSignerFromBytes } from "@solana/kit";
import { base58 } from "@scure/base";

const keypair = await createKeyPairSignerFromBytes(
  base58.decode(process.env.SVM_PRIVATE_KEY!)
);

const client = createSvmClient({
  signer: toClientSvmSigner(keypair),
  rpcUrl: process.env.SOLANA_RPC_URL ?? "https://api.devnet.solana.com",
});

const paidFetch = wrapFetchWithPayment(fetch, client);
```

## 3. Assertions for paid route tests

```typescript
import { describe, expect, it } from "vitest";
import request from "supertest";
import { app } from "../src/app";

describe("gated API endpoints", () => {
  it("returns a payment challenge before payment", async () => {
    const res = await request(app).get("/api/v1/premium-data");

    expect(res.status).toBe(402);
    expect(JSON.stringify(res.headers).toLowerCase()).toContain("payment");
  });

  it("requires idempotency for mutating paid routes", async () => {
    const res = await request(app).post("/api/v1/generate").send({ prompt: "cat" });

    expect([400, 402, 428]).toContain(res.status);
  });
});
```

## 4. Never run tests on mainnet by default

Fail fast if a test uses mainnet unless the user explicitly opts in:

```typescript
if (process.env.X402_NETWORK?.includes("5eykt4UsFv8P8NJdTREpY1vzqKqZKvdp")) {
  throw new Error("Refusing to run integration tests on Solana mainnet");
}
```
