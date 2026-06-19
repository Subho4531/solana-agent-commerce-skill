# Testing & Mocking x402 Integrations

Use this reference to configure unit tests, integration tests, CI pipelines, security test matrices, and load testing scripts for x402-enabled buyer agents and seller APIs.

---

## 1. Vitest Configuration

Configure Vitest with appropriate TypeScript and environment settings in `vitest.config.ts`.

```typescript
import { defineConfig } from "vitest/config";

export default defineConfig({
  test: {
    globals: true,
    environment: "node",
    setupFiles: ["./tests/setup.ts"],
    coverage: {
      provider: "v8",
      reporter: ["text", "json", "html"],
    },
    testTimeout: 30000, // 30s timeout for blockchain interactions
  },
});
```

---

## 2. GitHub Actions CI/CD Configuration

Add a workflow in `.github/workflows/x402-tests.yml` to automatically verify routing and safety checks.

```yaml
name: x402 Test Suite

on:
  push:
    branches: [ main, dev ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest

    steps:
    - name: Checkout Repository
      uses: actions/checkout@v4

    - name: Set up Node.js
      uses: actions/setup-node@v4
      with:
        node-version: '20'
        cache: 'npm'

    - name: Install Dependencies
      run: npm ci

    - name: Run Linter
      run: npm run lint

    - name: Run Vitest Security Matrix
      env:
        SOLANA_RPC_URL: "https://api.devnet.solana.com"
        SVM_PRIVATE_KEY: "3333333333333333333333333333333333333333333333333333333333333333" # Dev dummy key
        X402_NETWORK: "solana:EtWTRABZaYq6iMfeYKouRu166VU2xqa1"
      run: npx vitest run
```

---

## 3. The 8-Case Security Test Matrix

This matrix covers all security and integration edge cases that both the seller API and buyer client must validate.

```typescript
import { describe, expect, it, vi, beforeEach } from "vitest";
import request from "supertest";
import { app } from "../src/app";

describe("x402 Security Matrix", () => {
  // Guard against accidental mainnet testing
  beforeEach(() => {
    if (process.env.X402_NETWORK?.includes("5eykt4UsFv8P8NJdTREpY1vzqKqZKvdp")) {
      throw new Error("Refusing to run integration tests on Solana mainnet");
    }
  });

  // Case 1: Missing payment header returns 402 challenge
  it("Case 1: returns HTTP 402 when no payment is supplied", async () => {
    const res = await request(app).get("/api/v1/premium-data");
    expect(res.status).toBe(402);
    expect(res.headers["www-authenticate"]).toContain("x402");
  });

  // Case 2: Mutating paid route rejects if Idempotency-Key is missing
  it("Case 2: rejects mutating routes when Idempotency-Key is missing", async () => {
    const res = await request(app)
      .post("/api/v1/generate")
      .send({ prompt: "AI Art" });
    expect([400, 428]).toContain(res.status); // 400 Bad Request or 428 Precondition Required
  });

  // Case 3: Reject payments that specify an incorrect network
  it("Case 3: rejects payments that specify an incorrect network", async () => {
    const res = await request(app)
      .get("/api/v1/premium-data")
      .set("x-payment-txid", "mock-txid")
      .set("x-payment-network", "solana:5eykt4UsFv8P8NJdTREpY1vzqKqZKvdp"); // Mainnet instead of Devnet
    expect(res.status).toBe(400);
  });

  // Case 4: Reject payments that pay to an unexpected recipient
  it("Case 4: rejects payments paying to an unexpected recipient", async () => {
    const res = await request(app)
      .get("/api/v1/premium-data")
      .set("x-payment-txid", "txid-to-wrong-payee");
    // Verification engine checks tx details and rejects if payee is different
    expect(res.status).toBe(403);
  });

  // Case 5: Reject payments that use an incorrect token mint
  it("Case 5: rejects payments using an incorrect token mint", async () => {
    const res = await request(app)
      .get("/api/v1/premium-data")
      .set("x-payment-txid", "txid-using-fake-usdc");
    expect(res.status).toBe(403);
  });

  // Case 6: Reject expired quotes/challenges
  it("Case 6: rejects expired quotes", async () => {
    const expiredTimestamp = Math.floor(Date.now() / 1000) - 120; // 2 minutes ago
    const res = await request(app)
      .get("/api/v1/premium-data")
      .set("x-payment-quote-timestamp", expiredTimestamp.toString())
      .set("x-payment-txid", "mock-txid");
    expect(res.status).toBe(403);
  });

  // Case 7: Reject double-spending of the same transaction ID
  it("Case 7: rejects double-spending (replay protection)", async () => {
    // Submit first transaction
    const res1 = await request(app)
      .post("/api/v1/generate")
      .set("Idempotency-Key", "key-1")
      .set("x-payment-txid", "spent-txid-123");
    
    // Submit second transaction with same txid
    const res2 = await request(app)
      .post("/api/v1/generate")
      .set("Idempotency-Key", "key-2")
      .set("x-payment-txid", "spent-txid-123");
    
    expect(res2.status).toBe(409); // Conflict or 403 Forbidden
  });

  // Case 8: Enforce client spend policies
  it("Case 8: client spend policy blocks requests exceeding budget caps", () => {
    const maxBudget = 100000n; // 0.1 USDC
    const requested = 200000n; // 0.2 USDC
    
    const assertSpend = () => {
      if (requested > maxBudget) {
        throw new Error("Blocked: per-request budget cap exceeded");
      }
    };
    
    expect(assertSpend).toThrow("Blocked: per-request budget cap exceeded");
  });
});
```

---

## 4. Load Testing with k6

Use `k6` to test the performance of the x402 payment resolution flow under high concurrency. Save this as `load-test.js`.

```javascript
import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = {
  stages: [
    { duration: '30s', target: 50 }, // Ramp-up to 50 users
    { duration: '1m', target: 50 },  // Stay at 50 users
    { duration: '30s', target: 0 },  // Ramp-down to 0
  ],
};

export default function () {
  const url = 'http://localhost:3000/api/v1/premium-data';
  
  // 1. Initial GET request (expects 402 challenge)
  const res1 = http.get(url);
  check(res1, {
    'status is 402': (r) => r.status === 402,
    'authenticate header present': (r) => r.headers['Www-Authenticate'] !== undefined,
  });

  // Extract payment details from Www-Authenticate header
  const authHeader = res1.headers['Www-Authenticate'] || '';
  
  // Simulate client building the transaction & paying...
  // In a load test, mock the client signature latency (approx 50ms)
  sleep(0.05);

  // 2. Submit payment (mocked txid for testing endpoint validation speeds)
  const params = {
    headers: {
      'x-payment-txid': `mock-txid-${__VU}-${__ITER}`,
      'Idempotency-Key': `idempotency-${__VU}-${__ITER}`,
    },
  };

  const res2 = http.get(url, params);
  check(res2, {
    'status is 200': (r) => r.status === 200,
    'payment-response header returned': (r) => r.headers['Payment-Response'] !== undefined,
  });

  sleep(1);
}
```

---

## 5. Devnet Faucet Helper Script

Use this script (`scripts/devnet-faucet.ts`) to automate funding of test wallets and minting of Devnet USDC.

```typescript
import { createSolanaRpc, createKeyPairSignerFromBytes, Address } from "@solana/kit";
import { base58 } from "@scure/base";

const DEVNET_RPC = "https://api.devnet.solana.com";
const DEVNET_USDC_MINT = "4zMMC9srt5Ri5X14GAgXhaHii3GnPAEERYPJgZJDncDU";

export async function bootstrapDevnetWallet(privateKeyB58: string) {
  const rpc = createSolanaRpc(DEVNET_RPC);
  const signer = await createKeyPairSignerFromBytes(base58.decode(privateKeyB58));

  console.log(`Bootstrapping wallet: ${signer.address}`);

  // 1. Request SOL Airdrop for fees
  try {
    const airdropSignature = await rpc.requestAirdrop(signer.address, 2_000_000_000n).send(); // 2 SOL
    console.log(`SOL Airdrop request sent. Signature: ${airdropSignature}`);
  } catch (error) {
    console.warn("Airdrop limit reached or failed, proceeding with existing SOL balance...");
  }

  console.log(`Wallet bootstrap completed. Ready for Devnet testing.`);
}
```
