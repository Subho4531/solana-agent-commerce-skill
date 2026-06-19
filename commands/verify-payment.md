---
name: verify-payment
description: Verifies a Solana transaction ID signature against issued x402 payment requirements. Simulates facilitator audits to ensure the transfer settled correctly.
---

# /verify-payment

This command validates that a specific transaction signature settled an issued payment requirement.

## Execution Steps

1.  **Retrieve Requirements**:
    *   Solana transaction signature (`txid`)
    *   Expected amount in atomic USDC units
    *   Expected payee public address
    *   Expected token mint address (default USDC)
2.  **Verify On-Chain**:
    *   Fetch transaction info from the configured RPC.
    *   Validate that the transaction completed successfully (no logs indicating failure/reversion).
    *   Ensure a token balance change transfer matches the payee and mint requirements.
3.  **Output Status**: Return a structured status report: `verified: true/false`, with timestamps and gas indicators.

## Prompt Template

*To verify an on-chain transaction ID:*

```markdown
Please use the `/verify-payment` command to verify this tx.
- **Tx Signature**: txid_example_hash_here
- **Expected Amount**: 50000 (0.05 USDC)
- **Payee**: Merch1111111111111111111111111111111111111
```
