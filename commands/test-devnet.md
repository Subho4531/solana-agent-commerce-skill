---
name: test-devnet
description: A step-by-step interactive runner for testing x402 payment flows on Solana Devnet. Guides the user through airdropping devnet SOL, funding USDC, starting a mock seller server, running a test suite, and asserting receipts.
---

# /test-devnet

This command orchestrates a full end-to-end devnet test of the x402 payment flow.

## Execution Steps

1.  **Prerequisites Check:**
    *   Check if `solana` CLI is installed.
    *   Check if the user has a devnet keypair (or prompt to generate one).

2.  **Airdrop & Funding:**
    *   Provide the command to airdrop Devnet SOL: `solana airdrop 2 <ADDRESS> --url devnet`.
    *   Instruct the user on how to obtain Devnet USDC (Mint: `4zMMC9srt5Ri5X14GAgXhaHii3GnPAEERYPJgZJDncDU`).

3.  **Server Startup:**
    *   Instruct the user to start their seller server locally, pointing its `network` configuration to the Devnet CAIP-2 ID (`solana:EtWTRABZaYq6iMfeYKouRu166VU2xqa1`).
    *   Instruct the server to use the public facilitator: `https://x402.org/facilitator`.

4.  **Client Execution:**
    *   Provide a dummy script (or ask the user to run their buyer agent) that fetches the gated endpoint.
    *   Monitor the output for the 402 challenge, the local signing of the devnet transaction, and the final 200 OK response.

5.  **Receipt Verification:**
    *   Check the generated `receipts.jsonl` file to verify the payment was recorded correctly.
