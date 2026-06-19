# Jupiter SOL-to-USDC Swap & Auto-Topup Pattern

Use this reference to implement automated SOL-to-USDC swaps for buyer agents. This pattern, referred to as **Pattern B (Auto-Topup on 402)**, ensures that if an agent's USDC balance is insufficient to satisfy an x402 payment challenge, the agent automatically executes a Jupiter swap to convert SOL to USDC before retrying the paid request.

---

## 1. Network & Mint Constants

For all Jupiter interactions, ensure you use the correct USDC mint and CAIP-2 network IDs. Do not hardcode private keys.

| Network | CAIP-2 ID | USDC Mint Address | Decimals |
| :--- | :--- | :--- | :--- |
| **Mainnet-Beta** | `solana:5eykt4UsFv8P8NJdTREpY1vzqKqZKvdp` | `EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v` | 6 |
| **Devnet** | `solana:EtWTRABZaYq6iMfeYKouRu166VU2xqa1` | `4zMMC9srt5Ri5X14GAgXhaHii3GnPAEERYPJgZJDncDU` | 6 |

---

## 2. Implementing the Jupiter Swap Utility

This implementation uses the modern `@solana/kit` and standard `fetch` API to interact with Jupiter v6.

```typescript
import { 
  createSolanaRpc, 
  createKeyPairSignerFromBytes,
  getBase64Decoder,
  getBase64Encoder,
  signTransaction
} from "@solana/kit";
import { base58 } from "@scure/base";

const JUPITER_QUOTE_API = "https://quote-api.jup.ag/v6";
const SOL_MINT = "So11111111111111111111111111111111111111112";
const USDC_MINT = "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v"; // Mainnet default

interface JupiterQuoteResponse {
  inputMint: string;
  inAmount: string;
  outputMint: string;
  outAmount: string;
  otherAmountThreshold: string;
  swapMode: string;
  slippageBps: number;
  platformFee?: null | { feeBps: number };
  priceImpactPct: string;
  routePlan: Array<any>;
  contextSlot: number;
  timeTaken: number;
}

interface SwapRequest {
  quoteResponse: JupiterQuoteResponse;
  userPublicKey: string;
  wrapAndUnwrapSol: boolean;
  prioritizationFeeLamports?: number;
}

interface SwapResponse {
  swapTransaction: string; // Base64 serialized transaction
  lastValidBlockHeight: number;
  prioritizationFeeLamports: number;
}

/**
 * Fetches a quote from Jupiter for SOL -> USDC swap
 */
export async function getJupiterQuote(
  amountLamports: bigint,
  slippageBps = 50 // 0.5%
): Promise<JupiterQuoteResponse> {
  const url = `${JUPITER_QUOTE_API}/quote?inputMint=${SOL_MINT}&outputMint=${USDC_MINT}&amount=${amountLamports.toString()}&slippageBps=${slippageBps}`;
  
  const response = await fetch(url);
  if (!response.ok) {
    const errorText = await response.text();
    throw new Error(`Jupiter quote failed: ${response.status} - ${errorText}`);
  }
  
  const data = (await response.json()) as JupiterQuoteResponse;
  return data;
}

/**
 * Executes a Jupiter swap using @solana/kit transaction signing and broadcasting
 */
export async function executeJupiterSwap(
  quote: JupiterQuoteResponse,
  signer: ReturnType<typeof createKeyPairSignerFromBytes>,
  rpcUrl: string
): Promise<string> {
  const rpc = createSolanaRpc(rpcUrl);
  
  // 1. Request swap transaction from Jupiter
  const swapRequest: SwapRequest = {
    quoteResponse: quote,
    userPublicKey: signer.address,
    wrapAndUnwrapSol: true,
  };

  const response = await fetch(`${JUPITER_QUOTE_API}/swap`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(swapRequest),
  });

  if (!response.ok) {
    const errorText = await response.text();
    throw new Error(`Jupiter swap request failed: ${response.status} - ${errorText}`);
  }

  const { swapTransaction } = (await response.json()) as SwapResponse;

  // 2. Deserialize base64 transaction bytes
  const transactionBytes = getBase64Decoder().decode(swapTransaction);
  
  // In @solana/kit, raw transaction bytes can be signed and sent.
  // Note: For versioned transactions, sign using signTransaction.
  // First, reconstruct the transaction model or sign the raw bytes.
  // If the SDK returns a fully formed transaction, sign it using the signer:
  const txToSign = {
    messageBytes: transactionBytes,
    signatures: {}
  };
  
  const signedTx = await signTransaction([signer], txToSign as any);
  const serializedSignedTx = getBase64Encoder().encode(signedTx.messageBytes);

  // 3. Send and confirm transaction
  const txid = await rpc.sendTransaction(serializedSignedTx, {
    encoding: "base64",
    skipPreflight: true,
  }).send();

  return txid;
}
```

---

## 3. Pattern B: Auto-Topup Implementation

A buyer agent should monitor its local USDC balance before initiating paid requests. If the required amount exceeds the balance, it initiates a top-up swap using the utility function.

### Safeguard: Price Impact Guardrail
Always inspect the `priceImpactPct` parameter in the quote response. To protect the agent from sandwich attacks and severe slippage, **reject quotes where the price impact exceeds 1.0% (0.01)**.

```typescript
import { getJupiterQuote, executeJupiterSwap } from "./jupiter-swap";
import { createKeyPairSignerFromBytes, createSolanaRpc } from "@solana/kit";

const MAX_PRICE_IMPACT_PCT = 1.0; // 1%

/**
 * Top up the agent's USDC wallet by swapping SOL -> USDC
 */
export async function topUpUsdcWallet(
  targetUsdcAtomic: bigint,
  signer: ReturnType<typeof createKeyPairSignerFromBytes>,
  rpcUrl: string
): Promise<void> {
  // Estimate SOL amount required for target USDC. Use 1000 lamports per 0.0006 USDC as a safe buffer.
  // Fetch a reverse quote or a quote with a buffer:
  // For simplicity, we query a quote for 0.05 SOL and scale it, or perform a direct SOL quote.
  const estimatedSolLamports = 50_000_000n; // 0.05 SOL estimate
  const quote = await getJupiterQuote(estimatedSolLamports);
  
  const priceImpact = parseFloat(quote.priceImpactPct);
  if (priceImpact > MAX_PRICE_IMPACT_PCT) {
    throw new Error(`Jupiter swap rejected: high price impact of ${priceImpact}%`);
  }

  // Calculate actual SOL required to meet target USDC based on quote rate
  const outAmountUsdc = BigInt(quote.outAmount);
  if (outAmountUsdc === 0n) throw new Error("Zero output amount from Jupiter quote");
  
  const exactSolNeeded = (targetUsdcAtomic * estimatedSolLamports) / outAmountUsdc;
  const solWithBuffer = (exactSolNeeded * 105n) / 100n; // Add 5% buffer for slippage

  console.log(`[Top-up] Swapping ${solWithBuffer} lamports for target ${targetUsdcAtomic} atomic USDC`);
  
  const finalQuote = await getJupiterQuote(solWithBuffer);
  const txid = await executeJupiterSwap(finalQuote, signer, rpcUrl);
  console.log(`[Top-up] Auto-swap transaction executed successfully. Tx ID: ${txid}`);
}
```

---

## 4. Hooking Into Client Spend Verification

Integrate the auto-topup step directly into your agent's payment client logic:

```typescript
import { getAssociatedTokenAddress } from "@solana/spl-token";
import { createSolanaRpc, Address } from "@solana/kit";

export async function assertAndTopUpSpend(
  url: string,
  requestedAtomicUsdc: bigint,
  signer: any,
  rpcUrl: string
) {
  const rpc = createSolanaRpc(rpcUrl);
  
  // 1. Get associated token account for USDC
  const usdcMint = "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v" as Address;
  const usdcAta = await getAssociatedTokenAddress(
    new PublicKey(usdcMint), // Using spl-token helper
    new PublicKey(signer.address)
  );

  // 2. Fetch current balance
  let currentBalance = 0n;
  try {
    const balanceResponse = await rpc.getTokenAccountBalance(usdcAta.toBase58() as Address).send();
    currentBalance = BigInt(balanceResponse.value.amount);
  } catch (error) {
    console.warn("USDC ATA does not exist or has zero balance. Creating account may be required.");
  }

  // 3. Check if balance is sufficient
  if (currentBalance < requestedAtomicUsdc) {
    const deficit = requestedAtomicUsdc - currentBalance;
    console.log(`[Auto-Topup] Deficit of ${deficit} USDC detected. Initiating Jupiter auto-swap...`);
    await topUpUsdcWallet(deficit, signer, rpcUrl);
  }
}
```

---

## 5. Devnet Mock Setup for Tests

Since Jupiter v6 mainnet route API requires mainnet liquidity, testing on Devnet requires either a custom mock route API or bypassing the swap request by calling a mock token exchange program on Devnet.

### Devnet USDC Mint
Devnet USDC Mint: `4zMMC9srt5Ri5X14GAgXhaHii3GnPAEERYPJgZJDncDU`

### Mocking Jupiter in Vitest
```typescript
import { vi, describe, it, expect } from "vitest";

describe("Pattern B Auto-Topup Mock Test", () => {
  it("should intercept low balance and execute mock swap", async () => {
    const mockTopUp = vi.fn().mockImplementation(async (amount: bigint) => {
      console.log(`[Mock Swap] Swapped SOL for ${amount} Devnet USDC`);
      return "mock-tx-id";
    });

    const balance = 10_000n; // 0.01 USDC
    const required = 50_000n; // 0.05 USDC

    if (balance < required) {
      await mockTopUp(required - balance);
    }

    expect(mockTopUp).toHaveBeenCalledWith(40_000n);
  });
});
```
