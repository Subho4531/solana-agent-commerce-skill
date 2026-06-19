# Gating DeFi Protocol Data with x402

Use this reference to build paid API endpoints that sell DeFi protocol data (Orca Whirlpools positions, Raydium farm APYs, Meteora DLMM analytics, and Drift perp PnL) to consumer agents.

---

## 1. Design & Pricing Models

DeFi protocol data is highly time-sensitive. Agents querying this data for arbitrage or yield optimization require high availability and low latency. You can monetize these endpoints by setting up two pricing tiers:

1. **Real-time Tier (Premium)**: Hits the Solana RPC directly to fetch live state. Gated with a higher x402 payment fee.
2. **Cached Tier (Standard)**: Serves data cached in memory or Redis (updated every 30-60 seconds). Gated with a lower x402 payment fee.

---

## 2. Server setup with Hono Middleware

The following Hono server sets up paid endpoints for Orca, Raydium, Meteora, and Drift analytics.

```typescript
import { Hono } from "hono";
import { paymentMiddleware } from "@x402/hono";
import { ExactSvmScheme } from "@x402/svm";
import { createSolanaRpc, Address } from "@solana/kit";

// Setup Hono app
const app = new Hono();

// Connect to Solana RPC
const SOLANA_RPC_URL = process.env.SOLANA_RPC_URL || "https://api.mainnet-beta.solana.com";
const rpc = createSolanaRpc(SOLANA_RPC_URL);

// Devnet / Mainnet USDC configurations
const DEVNET_USDC = "4zMMC9srt5Ri5X14GAgXhaHii3GnPAEERYPJgZJDncDU";
const MAINNET_USDC = "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v";

// Register x402 routes
app.use(
  "/api/v1/defi/*",
  paymentMiddleware({
    // Orca Whirlpools position analytics
    "GET /api/v1/defi/orca/position": {
      accepts: [
        {
          scheme: ExactSvmScheme.scheme,
          network: "solana:5eykt4UsFv8P8NJdTREpY1vzqKqZKvdp", // Mainnet
          maxAmountRequired: "10000", // 0.01 USDC (6 decimals)
          payTo: process.env.PAYEE_WALLET!,
          asset: MAINNET_USDC,
          maxAgeSeconds: 60,
        },
      ],
      description: "Retrieve real-time liquidity position analytics for Orca Whirlpool.",
    },
    // Raydium APY data
    "GET /api/v1/defi/raydium/yields": {
      accepts: [
        {
          scheme: ExactSvmScheme.scheme,
          network: "solana:5eykt4UsFv8P8NJdTREpY1vzqKqZKvdp",
          maxAmountRequired: "5000", // 0.005 USDC
          payTo: process.env.PAYEE_WALLET!,
          asset: MAINNET_USDC,
          maxAgeSeconds: 60,
        },
      ],
      description: "Cached yield and farm APY data for Raydium pools.",
    },
    // Meteora Bin analysis
    "GET /api/v1/defi/meteora/bins": {
      accepts: [
        {
          scheme: ExactSvmScheme.scheme,
          network: "solana:5eykt4UsFv8P8NJdTREpY1vzqKqZKvdp",
          maxAmountRequired: "15000", // 0.015 USDC
          payTo: process.env.PAYEE_WALLET!,
          asset: MAINNET_USDC,
          maxAgeSeconds: 60,
        },
      ],
      description: "Retrieve Meteora DLMM active bins and price distributions.",
    },
    // Drift Perp analytics
    "GET /api/v1/defi/drift/perp-pnl": {
      accepts: [
        {
          scheme: ExactSvmScheme.scheme,
          network: "solana:5eykt4UsFv8P8NJdTREpY1vzqKqZKvdp",
          maxAmountRequired: "20000", // 0.02 USDC
          payTo: process.env.PAYEE_WALLET!,
          asset: MAINNET_USDC,
          maxAgeSeconds: 60,
        },
      ],
      description: "Drift perpetual position and unrealized PnL data.",
    },
  })
);
```

---

## 3. Orca Whirlpools Gated Endpoint

Fetches real-time position metadata using `@orca-so/whirlpools-sdk` pattern, returning active liquidity.

```typescript
import { WhirlpoolContext, ORCA_WHIRLPOOL_PROGRAM_ID } from "@orca-so/whirlpools-sdk";
import { PublicKey } from "@solana/web3.js"; // Standard for current Orca SDK integrations

app.get("/api/v1/defi/orca/position", async (c) => {
  const positionAddress = c.req.query("address");
  if (!positionAddress) {
    return c.json({ error: "Missing 'address' query parameter" }, 400);
  }

  try {
    // For legacy SDK compatibility, wrap RPC connection
    const connection = new (await import("@solana/web3.js")).Connection(SOLANA_RPC_URL);
    const mockWallet = {
      publicKey: PublicKey.default,
      signTransaction: async (tx: any) => tx,
      signAllTransactions: async (txs: any) => txs,
    };
    
    const context = WhirlpoolContext.from(
      connection,
      mockWallet,
      ORCA_WHIRLPOOL_PROGRAM_ID
    );

    // Fetch position account data
    const positionPubKey = new PublicKey(positionAddress);
    const position = await context.client.getPosition(positionPubKey);
    const positionData = position.getData();

    return c.json({
      positionAddress,
      whirlpool: positionData.whirlpool.toBase58(),
      liquidity: positionData.liquidity.toString(),
      tickLowerIndex: positionData.tickLowerIndex,
      tickUpperIndex: positionData.tickUpperIndex,
    });
  } catch (error: any) {
    return c.json({ error: `Failed to fetch Orca position: ${error.message}` }, 500);
  }
});
```

---

## 4. Raydium Yields Gated Endpoint

Returns yield farm calculations. To keep API response times low, use a cached data source updated out-of-band.

```typescript
// Local in-memory cache representation
let raydiumCache = {
  lastUpdated: 0,
  data: [] as any[]
};

// Out-of-band fetcher (e.g. cron job or background runner)
async function updateRaydiumCache() {
  try {
    const response = await fetch("https://api.raydium.io/v2/main/pairs");
    if (response.ok) {
      const data = await response.json();
      raydiumCache = {
        lastUpdated: Date.now(),
        data: data.slice(0, 50) // Cache top 50 pools
      };
    }
  } catch (err) {
    console.error("Failed to update Raydium cache:", err);
  }
}

app.get("/api/v1/defi/raydium/yields", async (c) => {
  // Update cache if older than 60 seconds
  if (Date.now() - raydiumCache.lastUpdated > 60_000) {
    await updateRaydiumCache();
  }

  return c.json({
    source: "raydium-cache",
    lastUpdated: new Date(raydiumCache.lastUpdated).toISOString(),
    pools: raydiumCache.data
  });
});
```

---

## 5. Meteora DLMM Active Bins Endpoint

Monetizes Meteora DLMM pool bin details. Bin distributions represent highly valuable execution path data for routing engines.

```typescript
import { DLMM } from "@meteora-ag/dlmm";

app.get("/api/v1/defi/meteora/bins", async (c) => {
  const poolAddress = c.req.query("pool");
  if (!poolAddress) {
    return c.json({ error: "Missing 'pool' parameter" }, 400);
  }

  try {
    const connection = new (await import("@solana/web3.js")).Connection(SOLANA_RPC_URL);
    const poolPubKey = new PublicKey(poolAddress);
    
    // Load DLMM Pool
    const dlmmPool = await DLMM.create(connection, poolPubKey);
    const activeBin = await dlmmPool.getActiveBin();
    
    // Fetch bins around the active bin
    const bins = await dlmmPool.getBinsAroundActiveBin(10, 10);

    return c.json({
      poolAddress,
      activeBinId: activeBin.binId,
      activePrice: activeBin.price,
      bins: bins.map(b => ({
        binId: b.binId,
        xAmount: b.xAmount.toString(),
        yAmount: b.yAmount.toString(),
        price: b.price
      }))
    });
  } catch (error: any) {
    return c.json({ error: `DLMM bin fetch failed: ${error.message}` }, 500);
  }
});
```

---

## 6. Drift Perp Position & PnL Gated Endpoint

Integrates `@drift-labs/sdk` to fetch perpetual market position metrics for specific wallets behind an x402 barrier.

```typescript
import { DriftClient, Wallet, BulkAccountLoader } from "@drift-labs/sdk";

app.get("/api/v1/defi/drift/perp-pnl", async (c) => {
  const userAddress = c.req.query("user");
  if (!userAddress) {
    return c.json({ error: "Missing 'user' query parameter" }, 400);
  }

  try {
    const connection = new (await import("@solana/web3.js")).Connection(SOLANA_RPC_URL);
    const userPubKey = new PublicKey(userAddress);
    
    // Initialize read-only Drift client
    const driftClient = new DriftClient({
      connection,
      wallet: new Wallet(new (await import("@solana/web3.js")).Keypair()), // Dummy keypair
      env: "mainnet-beta"
    });
    
    await driftClient.subscribe();
    
    // Fetch user account and positions
    const user = driftClient.getUser(userPubKey);
    await user.subscribe();
    
    const activePositions = user.getActivePerpPositions();
    const unrealizedPnL = user.getUnrealizedPNL();

    // Cleanup subscription
    await user.unsubscribe();
    await driftClient.unsubscribe();

    return c.json({
      userAddress,
      unrealizedPnL: unrealizedPnL.toString(),
      positions: activePositions.map(p => ({
        marketIndex: p.marketIndex,
        baseAssetAmount: p.baseAssetAmount.toString(),
        quoteAssetAmount: p.quoteAssetAmount.toString(),
        quoteEntryAmount: p.quoteEntryAmount.toString(),
      }))
    });
  } catch (error: any) {
    return c.json({ error: `Drift fetch failed: ${error.message}` }, 500);
  }
});
```
