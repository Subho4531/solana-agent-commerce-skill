# Monetizing MCP Servers with HTTP 402

This manual describes how developers can monetize custom Model Context Protocol (MCP) servers using Solana micropayments.

---

## 1. The MCP Gateway Proxy Pattern

Standard MCP servers communicate via JSON-RPC over stdio or SSE. Gating an MCP server requires putting an HTTP 402 gateway proxy in front of the SSE transport layer:

```
+------------+       HTTP JSON-RPC       +-------------+        Local STDIO        +------------+
|            | ------------------------> |   x402 SSE  | ------------------------> |            |
| LLM Client |                           |  MCP Proxy  |                           | Target MCP |
|   (User)   | <--- 402 Pay Challenge -- |   Gateway   | <--- JSON-RPC Response -- |   Server   |
+------------+                           +-------------+                           +------------+
```

---

## 2. Gating an SSE MCP Server

Below is an implementation pattern wrapping an SSE MCP Server using Hono and `@x402/hono`.

```typescript
import { Hono } from "hono";
import { paymentMiddleware } from "@x402/hono";
import { ExactSvmScheme } from "@x402/svm";
import { Client } from "@modelcontextprotocol/sdk/client/index.js";
import { SSEClientTransport } from "@modelcontextprotocol/sdk/client/sse.js";

const app = new Hono();

// Gate the MCP Tool call endpoint
app.use(
  "/mcp/v1/tools/call",
  paymentMiddleware({
    accepts: [{
      scheme: ExactSvmScheme.scheme,
      network: "solana:mainnet",
      maxAmountRequired: "0.02", // $0.02 USDC per tool execution
      resource: "solana:mainnet:USDC_RECEIVER_WALLET",
    }],
    description: "Paid access to MCP Tool execution.",
  })
);

// Proxy tool calls to the downstream MCP server
app.post("/mcp/v1/tools/call", async (c) => {
  const body = await c.req.json();
  
  // Forward request to local/downstream MCP Server
  const client = new Client({ name: "gateway-proxy", version: "1.0.0" }, {});
  const transport = new SSEClientTransport(new URL("http://localhost:8080/sse"));
  await client.connect(transport);

  const result = await client.callTool({
    name: body.name,
    arguments: body.arguments,
  });

  return c.json(result);
});
```

---

## 3. Consuming Gated MCP Tools (Client Side)

When an agent wants to call an MCP tool gated by a proxy, the agent's MCP client must intercept the SSE connection and provide the `X-PAYMENT` signature in the request headers:

```typescript
import { SSEClientTransport } from "@modelcontextprotocol/sdk/client/sse.js";
import { wrapFetchWithPaymentFromConfig } from "@x402/fetch";
import { ExactSvmScheme } from "@x402/svm";
import { Keypair } from "@solana/web3.js";

const keypair = Keypair.fromSecretKey(/* ... */);

// 1. Wrap the fetch client that the transport uses
const fetchWithPayment = wrapFetchWithPaymentFromConfig(fetch, {
  schemes: [{
    network: "solana:mainnet",
    client: new ExactSvmScheme(keypair),
  }],
});

// 2. Pass the wrapped fetch into the SSE Client Transport
const transport = new SSEClientTransport(
  new URL("https://mcp-gateway.provider.com/sse"),
  {
    eventSourceInitDict: {
      // Support fetch-based SSE wrappers if needed
    },
    // Intercept client HTTP calls
    requestInit: {
      headers: {
        // Additional authentication or connection info
      }
    }
  }
);
```
