# x402 Client Integration Patterns

This manual describes how agents can programmatically consume HTTP 402 gated resources, sign transactions, and manage their spending budgets.

---

## 1. Wrapping Standard Fetch

Using `@x402/fetch` allows you to wrap the global `fetch` API. When a standard fetch meets a `402 Payment Required` challenge, the wrapper intercepts it, builds/signs/broadcasts the required Solana transaction, and retries the original request with the proof.

```typescript
import { wrapFetchWithPaymentFromConfig } from "@x402/fetch";
import { ExactSvmScheme } from "@x402/svm";
import { Keypair } from "@solana/web3.js";

// Load agent secret key safely
const secretKey = Uint8Array.from(JSON.parse(process.env.AGENT_SOLANA_KEYPAIR!));
const agentKeypair = Keypair.fromSecretKey(secretKey);

const fetchWithPayment = wrapFetchWithPaymentFromConfig(fetch, {
  schemes: [{
    network: "solana:mainnet",
    client: new ExactSvmScheme(agentKeypair),
  }],
});

// Accessing the gated endpoint is fully transparent to the business logic
const response = await fetchWithPayment("https://api.provider.com/gated-endpoint");
const data = await response.json();
```

---

## 2. Axios Interceptor Pattern

If your agent uses Axios, you can intercept `402` responses using an interceptor.

```typescript
import axios from "axios";
import { ExactSvmScheme } from "@x402/svm";
import { Keypair } from "@solana/web3.js";

const agentKeypair = Keypair.fromSecretKey(...);
const svmClient = new ExactSvmScheme(agentKeypair);

const api = axios.create();

api.interceptors.response.use(
  (response) => response,
  async (error) => {
    const originalRequest = error.config;

    if (error.response && error.response.status === 402 && !originalRequest._retry) {
      originalRequest._retry = true;

      const challenge = error.response.headers["payment-required"];
      // Parse: scheme=solana-usdc, amount=0.01, address=USDC_RECEIVER, network=solana:mainnet
      const { amount, address, network } = parseChallengeHeader(challenge);

      // Perform SPL Token transfer and submit to Solana
      const signature = await svmClient.pay({
        amount,
        recipient: address,
        network,
      });

      // Retry request with proof
      originalRequest.headers["X-PAYMENT"] = `signature=${signature}, scheme=solana-usdc`;
      return api(originalRequest);
    }

    return Promise.reject(error);
  }
);
```

---

## 3. Spending Caps & Budget Controls

Agents should never spend unchecked. Integrate a budget controller.

```typescript
import { BudgetController } from "@x402/core";

const budget = new BudgetController({
  dailyLimitUSDC: 5.00, // Max $5.00 USD per day
  perRequestLimitUSDC: 0.10, // Max $0.10 USD per API query
});

const svmClient = new ExactSvmScheme(agentKeypair, {
  beforePay: async (paymentDetails) => {
    const isAllowed = await budget.checkAndRecord(paymentDetails.amount);
    if (!isAllowed) {
      throw new Error(`Payment blocked: Daily spending cap exceeded or request exceeds maximum limit.`);
    }
  }
});
```
