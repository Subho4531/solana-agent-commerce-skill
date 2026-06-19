---
name: request-faucet
description: Automates or guides requesting devnet SOL and minting devnet USDC to a test agent wallet. Runs the bootstrapping script to fund developer wallets.
---

# /request-faucet

This command bootstraps test wallets with Devnet SOL and USDC tokens.

## Execution Steps

1.  **Read Target Wallet**: Retrieve the target public address from the user's input or local configuration.
2.  **Verify Devnet Connection**: Set connection to `solana:EtWTRABZaYq6iMfeYKouRu166VU2xqa1` (Devnet).
3.  **Execute Airdrop**:
    *   Airdrop 2 SOL for transaction gas fees.
    *   Initialize the Associated Token Account (ATA) for Devnet USDC (`4zMMC9srt5Ri5X14GAgXhaHii3GnPAEERYPJgZJDncDU`).
    *   Mint or request test USDC from the public Devnet faucet.
4.  **Confirm Balances**: Poll the RPC and print final funded wallet balances.

## Prompt Template

*To request devnet funding for an agent:*

```markdown
Please use the `/request-faucet` command to fund my wallet.
- **Wallet Address**: Address11111111111111111111111111111111
- **SOL Amount**: 2
- **USDC Amount**: 100
```
