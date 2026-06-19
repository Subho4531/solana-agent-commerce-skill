# Testing & Mocking x402 Integrations

Testing paid agent actions requires careful simulation to avoid spending real mainnet assets during development.

---

## 1. Local Mocking of Facilitator Challenges

Instead of conducting real Solana transfers on-chain, use a local mock verifier in your test harness:

```typescript
import { wrapFetchWithPaymentFromConfig } from "@x402/fetch";
import { ExactSvmScheme } from "@x402/svm";
import { Keypair } from "@solana/web3.js";

// Local Mock Scheme
class MockSvmScheme extends ExactSvmScheme {
  async pay(details: any): Promise<string> {
    console.log(`[Mock Pay] Simulating payment of ${details.amount} USDC to ${details.recipient}`);
    // Return a dummy Solana transaction signature
    return "MOCK_SIGNATURE_" + Math.random().toString(36).substring(7);
  }
}

const testKeypair = Keypair.generate();
const testFetch = wrapFetchWithPaymentFromConfig(fetch, {
  schemes: [{
    network: "solana:testnet",
    client: new MockSvmScheme(testKeypair),
  }],
});
```

---

## 2. Devnet Test Setup

To run integration tests against the live Solana Devnet:

1. **Airdrop Devnet SOL**:
   ```bash
   solana airdrop 2 -u devnet
   ```
2. **Airdrop Devnet USDC**:
   Use a public faucet or a custom token helper script to mint SPL USDC tokens to your test keypair (`4zMMC9zPy429a3KAeA5NDXv56A5xstVeWCntmdewWY6`).
3. **Configure the SVM Scheme**:
   Ensure you initialize your `ExactSvmScheme` pointing to the devnet RPC endpoint:

```typescript
import { Connection } from "@solana/web3.js";

const devnetConnection = new Connection("https://api.devnet.solana.com", "confirmed");
const devnetScheme = new ExactSvmScheme(testKeypair, {
  connection: devnetConnection,
  usdcMint: new PublicKey("4zMMC9zPy429a3KAeA5NDXv56A5xstVeWCntmdewWY6"),
});
```

---

## 3. Asserting Payment Success in Unit Tests

Verify that your protected API endpoints correctly handle 402 challenge cycles.

```typescript
import { expect } from "chai";
import request from "supertest";
import { app } from "../src/app"; // Express app

describe("Gated API Endpoints", () => {
  it("should return 402 challenge on first request", async () => {
    const res = await request(app).get("/api/v1/premium-data");
    
    expect(res.status).to.equal(402);
    expect(res.headers).to.have.property("payment-required");
    expect(res.headers["payment-required"]).to.include("scheme=solana-usdc");
  });

  it("should return 200 after sending valid payment header", async () => {
    // 1. Get challenge
    const res1 = await request(app).get("/api/v1/premium-data");
    
    // 2. Simulate signing / paying to get signature
    const signature = "VALID_TX_SIGNATURE"; // mock or devnet verified

    // 3. Retry request with signature
    const res2 = await request(app)
      .get("/api/v1/premium-data")
      .set("X-PAYMENT", `signature=${signature}, scheme=solana-usdc`);

    expect(res2.status).to.equal(200);
    expect(res2.body).to.have.property("data");
  });
});
```
