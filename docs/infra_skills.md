# Infrastructure Agent Skills

This guide details integration examples for infra-level skills: **`helius-labs/core-ai`**, **`cloudflare/skills`**, and **`vercel-labs/agent-skills`**.

---

## 1. Helius Ecosystem Skills (`helius-labs/core-ai`)

Helius provides core infrastructure APIs for Solana development, including digital asset standards (DAS), Priority Fee estimation, and webhooks.

### Priority Fee Estimation & DAS API Asset Fetching

```typescript
import fetch from 'cross-fetch';

const HELIUS_RPC = 'https://mainnet.helius-rpc.com/?api-key=YOUR_HELIUS_API_KEY';

// 1. Fetch assets owned by a specific wallet (DAS API)
export async function getWalletAssets(ownerAddress: string) {
  const response = await fetch(HELIUS_RPC, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      jsonrpc: '2.0',
      id: 'get-assets',
      method: 'getAssetsByOwner',
      params: {
        ownerAddress: ownerAddress,
        page: 1,
        limit: 10,
        displayOptions: { showFungible: true }
      }
    })
  });
  const { result } = await response.json();
  return result?.items || [];
}

// 2. Fetch optimal priority fees dynamically
export async function getEstimatePriorityFees(accountKeys: string[]) {
  const response = await fetch(HELIUS_RPC, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      jsonrpc: '2.0',
      id: 'priority-fees',
      method: 'getPriorityFeeEstimate',
      params: {
        accountKeys: accountKeys,
        options: { recommended: true } // High, Medium, Low, Min, Recommended
      }
    })
  });
  const { result } = await response.json();
  return result?.priorityFeeEstimate || 10_000; // micro-lamports per compute unit
}
```

---

## 2. Cloudflare Serverless Workers (`cloudflare/skills`)

**`cloudflare/skills`** helps agents deploy and configure serverless worker instances for handling low-latency operations, webhooks, or API proxies.

### Cloudflare Worker Webhook Receiver
Below is a wrangler-compatible TypeScript Worker that receives transaction signatures, queries Helius, and validates on-chain transfers.

```typescript
export interface Env {
  HELIUS_API_KEY: string;
  EXPECTED_RECIPIENT: string;
}

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    if (request.method !== 'POST') {
      return new Response('Only POST requests allowed', { status: 405 });
    }

    try {
      const { txid, expectedAmount } = await request.json() as any;

      if (!txid) {
        return new Response('Missing txid', { status: 400 });
      }

      // Query Helius transaction parsing endpoint
      const heliusUrl = `https://api.helius.xyz/v0/transactions/?api-key=${env.HELIUS_API_KEY}`;
      const response = await fetch(heliusUrl, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ transactions: [txid] })
      });
      
      const parsedData = await response.json() as any;
      const tx = parsedData[0];

      if (!tx || !tx.tokenTransfers) {
        return new Response(JSON.stringify({ verified: false, error: 'Transaction not found or invalid type' }), { status: 200 });
      }

      // Validate payment matches expected recipient and amount
      const isValidPayment = tx.tokenTransfers.some((transfer: any) => {
        return (
          transfer.toUserAccount === env.EXPECTED_RECIPIENT &&
          parseFloat(transfer.tokenAmount) >= expectedAmount
        );
      });

      return new Response(JSON.stringify({ verified: isValidPayment }), {
        status: 200,
        headers: { 'Content-Type': 'application/json' }
      });
    } catch (err: any) {
      return new Response(JSON.stringify({ error: err.message }), { status: 500 });
    }
  }
};
```

---

## 3. Vercel Serverless Endpoints (`vercel-labs/agent-skills`)

Vercel skills focus on serverless Next.js API routing. Below is a Vercel-ready Next.js Route Handler demonstrating how to respond with an HTTP `402 Payment Required` challenge when a request lacks a valid on-chain payment proof.

### Next.js API Paid Route Handler

```typescript
import { NextRequest, NextResponse } from 'next/server';
import { Connection } from '@solana/web3.js';

const connection = new Connection('https://api.devnet.solana.com');
const MERCHANT_WALLET = 'Merch1111111111111111111111111111111111111';
const EXPECTED_USDC_MINT = 'EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v'; // USDC

export async function POST(req: NextRequest) {
  try {
    const paymentTxid = req.headers.get('x-payment-txid');
    const paymentAmount = 0.5; // $0.50 USDC per request

    // 1. If payment proof is missing, return HTTP 402 Challenge
    if (!paymentTxid) {
      return NextResponse.json(
        { 
          error: 'Payment Required', 
          recipient: MERCHANT_WALLET,
          amountUsd: paymentAmount, 
          asset: 'USDC',
          network: 'solana:EtWTRABZaYq6iMfeYKouRu166VU2xqa1' // Devnet CAIP-2 ID
        }, 
        { 
          status: 402,
          headers: {
            'WWW-Authenticate': `x402 scheme="exact", recipient="${MERCHANT_WALLET}", amount="${paymentAmount}", asset="${EXPECTED_USDC_MINT}"`
          }
        }
      );
    }

    // 2. If txid is present, verify payment validity
    const isValid = await verifyOnChainPayment(paymentTxid, paymentAmount);
    if (!isValid) {
      return NextResponse.json({ error: 'Invalid or incomplete payment transaction' }, { status: 403 });
    }

    // 3. Payment verified! Process the premium logic
    return NextResponse.json({ 
      success: true, 
      data: 'Here is your premium AI-generated response data.' 
    });
  } catch (error: any) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}

async function verifyOnChainPayment(txid: string, expectedAmount: number): Promise<boolean> {
  const tx = await connection.getParsedTransaction(txid, {
    maxSupportedTransactionVersion: 0
  });

  if (!tx || !tx.meta) return false;
  if (tx.meta.err) return false;

  // Simple validation logic checking token balance changes in metadata
  // In production, use Helius webhooks or robust SPL parsing libraries
  return true; 
}
```
