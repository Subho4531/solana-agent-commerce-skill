# DeFi Agent Skills

This guide details the integration patterns for DeFi actions using **`sendaifun/skills`** and **`jup-ag/agent-skills`**, emphasizing risk-managed execution and programmatic spend policies.

---

## 1. Jupiter Agent Skills (`jup-ag/agent-skills`)

The **`jup-ag/agent-skills`** bundle gives agents access to Jupiter’s full API surface, enabling swap execution, dollar-cost averaging (DCA), limit orders, and lending.

### Executing a Swap with Jupiter Quote API

Below is an implementation of a Node.js utility utilizing `@jup-ag/api` to fetch a quote and execute a token swap.

```typescript
import { Connection, Keypair, VersionedTransaction } from '@solana/web3.js';
import fetch from 'cross-fetch';

const JUPITER_API_BASE = 'https://quote-api.jup.ag/v6';
const connection = new Connection('https://api.mainnet-beta.solana.com');

interface SwapParams {
  inputMint: string;
  outputMint: string;
  amount: number; // raw amount (e.g. 1000000 for 1 USDC)
  slippageBps: number;
  userPublicKey: string;
}

export async function executeJupiterSwap(params: SwapParams, keypair: Keypair): Promise<string> {
  // 1. Fetch swap quote
  const quoteResponse = await fetch(
    `${JUPITER_API_BASE}/quote?inputMint=${params.inputMint}&outputMint=${params.outputMint}&amount=${params.amount}&slippageBps=${params.slippageBps}`
  );
  const quoteData = await quoteResponse.json();

  if (!quoteData || quoteData.error) {
    throw new Error(`Failed to fetch swap quote: ${quoteData?.error || 'Unknown error'}`);
  }

  // 2. Request swap transaction from Jupiter API
  const swapResponse = await fetch(`${JUPITER_API_BASE}/swap`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      quoteResponse: quoteData,
      userPublicKey: params.userPublicKey,
      wrapAndUnwrapSol: true
    })
  });
  const { swapTransaction } = await swapResponse.json();

  // 3. Deserialize and Sign the Versioned Transaction
  const swapTransactionBuf = Buffer.from(swapTransaction, 'base64');
  const transaction = VersionedTransaction.deserialize(swapTransactionBuf);
  transaction.sign([keypair]);

  // 4. Send and Confirm transaction on Solana
  const rawTransaction = transaction.serialize();
  const txid = await connection.sendRawTransaction(rawTransaction, {
    skipPreflight: true,
    maxRetries: 2
  });

  await connection.confirmTransaction(txid);
  return txid;
}
```

---

## 2. On-Chain Protocol Orchestration (`sendaifun/skills`)

The **`sendaifun/skills`** library provides modular actions to interact with various protocols (Kamino, Orca, Switchboard, Drift).

### Kamino Lend Deposit Example
Depositing assets into Kamino’s lending vaults to earn yield:

```typescript
import { KaminoMarket } from '@kamino-finance/klend-sdk';
import { Connection, PublicKey, Keypair } from '@solana/web3.js';

export async function depositToKamino(
  connection: Connection,
  wallet: Keypair,
  mint: PublicKey,
  amount: number
) {
  const market = await KaminoMarket.load(
    connection,
    new PublicKey('MainMarketProgramId111111111111111111111')
  );

  const reserve = market.getReserveByMint(mint);
  if (!reserve) {
    throw new Error(`Reserve for mint ${mint.toBase58()} not found on Kamino`);
  }

  // Generate deposit instruction
  const ix = await market.deposit(
    wallet.publicKey,
    mint,
    amount,
    reserve
  );

  // Package instruction into transaction and sign/send
  return ix;
}
```

---

## 3. Local Spending Policy & Receipt Logger

To prevent a compromised or runaway agent from draining wallets, you must enforce a local spend policy before transaction execution.

### Spend Policy Implementation

```typescript
import * as fs from 'fs';
import * as path from 'path';

export interface SpendPolicy {
  maxPerRequest: number; // in USD (or USDC equivalent)
  maxPerDay: number;
}

export class AgentSpendSafetyManager {
  private policy: SpendPolicy;
  private receiptLogPath: string;

  constructor(policy: SpendPolicy, logDir: string = './logs') {
    this.policy = policy;
    this.receiptLogPath = path.join(logDir, 'spend_receipts.jsonl');
    if (!fs.existsSync(logDir)) {
      fs.mkdirSync(logDir, { recursive: true });
    }
  }

  // Evaluates if the current request exceeds single/daily limits
  public authorizeSpend(requestAmountUsd: number): boolean {
    if (requestAmountUsd > this.policy.maxPerRequest) {
      console.warn(`[SPEND DENIED] Request amount $${requestAmountUsd} exceeds limit of $${this.policy.maxPerRequest}`);
      return false;
    }

    const dailyTotal = this.calculateDailySpendTotal();
    if (dailyTotal + requestAmountUsd > this.policy.maxPerDay) {
      console.warn(`[SPEND DENIED] Daily limit of $${this.policy.maxPerDay} reached. Current: $${dailyTotal}, Request: $${requestAmountUsd}`);
      return false;
    }

    return true;
  }

  // Logs the transaction receipt to JSONL file
  public logReceipt(txid: string, amountUsd: number, purpose: string) {
    const entry = {
      timestamp: new Date().toISOString(),
      txid,
      amountUsd,
      purpose
    };
    fs.appendFileSync(this.receiptLogPath, JSON.stringify(entry) + '\n');
  }

  private calculateDailySpendTotal(): number {
    if (!fs.existsSync(this.receiptLogPath)) return 0;
    
    const lines = fs.readFileSync(this.receiptLogPath, 'utf-8').trim().split('\n');
    const today = new Date().toISOString().split('T')[0];
    let total = 0;

    for (const line of lines) {
      if (!line) continue;
      const entry = JSON.parse(line);
      if (entry.timestamp.startsWith(today)) {
        total += entry.amountUsd;
      }
    }
    return total;
  }
}
```
