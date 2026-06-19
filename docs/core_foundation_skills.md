# Core & Foundation Skills

This guide covers the core development and migration skills: **`solana-dev-skill`** and **`eth-to-sol-skill`**.

---

## 1. Solana Development Skill (`solana-dev-skill`)

The **`solana-dev-skill`** is maintained by the Solana Foundation. It guides agents to build secure programs using modern frameworks (Anchor, Pinocchio) and perform high-speed testing with local VM runners (LiteSVM, Mollusk).

### Modern Testing with LiteSVM

Rather than firing up a heavy local validator via `solana-test-validator`, LiteSVM allows developers to run tests directly inside memory, accelerating execution speeds by up to 100x.

Here is a TypeScript test file setting up a transaction test using the modern `@solana/kit` and a mock SVM runner.

```typescript
import { 
  createDefaultTransaction,
  addTransactionInstruction,
  signTransaction,
  getSignatureFromTransaction
} from '@solana/kit';
import { LiteSVM } from 'litesvm-node'; // High-performance VM emulator
import { expect } from 'chai';

describe('LiteSVM Program Test Suite', () => {
  let svm: LiteSVM;
  let programId: string;
  let payer: any;

  beforeEach(() => {
    svm = new LiteSVM();
    programId = 'Ctrt111111111111111111111111111111111111111';
    
    // Add compiled program binary (.so) directly to memory
    svm.addProgramFromFile(programId, './target/deploy/my_program.so');

    // Create and fund test account
    payer = svm.createFundedAccount(1_000_000_000n); // 1 SOL
  });

  it('Executes program instruction successfully', async () => {
    // 1. Build instruction payload (discriminator + data)
    const instructionData = Buffer.from([0, 1, 2, 3]); // Example payload

    // 2. Formulate Transaction
    let transaction = createDefaultTransaction({
      feePayer: payer.publicKey,
      recentBlockhash: svm.getLatestBlockhash()
    });

    transaction = addTransactionInstruction({
      programId: programId,
      keys: [
        { pubkey: payer.publicKey, isSigner: true, isWritable: true }
      ],
      data: instructionData
    }, transaction);

    // 3. Sign transaction
    const signedTx = await signTransaction([payer.keypair], transaction);

    // 4. Send transaction to memory VM
    const txResult = svm.sendTransaction(signedTx);

    // 5. Verify outcome
    expect(txResult.err).to.be.null;
    expect(txResult.logs).to.include('Program log: Instruction executed successfully');
  });
});
```

---

## 2. EVM to Solana Migration Skill (`eth-to-sol-skill`)

The **`eth-to-sol-skill`** helps developers transition Solidity/EVM design patterns to Solana's Account Model and Rust/Anchor. 

### Key Structural Differences
*   **State & Logic Separated**: In Solidity, code and storage live in the same smart contract address. In Solana, programs contain logic only, while data is stored in separate accounts owned by the program.
*   **Access Control**: EVM maps permissions to `msg.sender`. Solana passes signer flags (`is_signer: true`) on the accounts array.

### ERC-20 (Solidity) vs. SPL Token Transfer (Solana Anchor)

Below is a direct comparison showing how state-modifying logic translates.

#### Solidity (ERC-20 Transfer)
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract Token {
    mapping(address => uint256) public balances;

    event Transfer(address indexed from, address indexed to, uint256 value);

    function transfer(address to, uint256 amount) public returns (bool) {
        address owner = msg.sender;
        require(balances[owner] >= amount, "ERC20: transfer amount exceeds balance");
        
        balances[owner] -= amount;
        balances[to] += amount;
        
        emit Transfer(owner, to, amount);
        return true;
    }
}
```

#### Solana Anchor (SPL Token Transfer Instruction)
Instead of modifying internal storage variables, the Solana program invokes the Token Program via a Cross-Program Invocation (CPI), passing the source, destination, and owner accounts.

```rust
use anchor_lang::prelude::*;
use anchor_spl::token::{self, Transfer, Token};

declare_id!("TokenProg111111111111111111111111111111111");

#[program]
pub mod my_token_transfer {
    use super::*;

    pub fn transfer_tokens(ctx: Context<TransferTokens>, amount: u64) -> Result<()> {
        // 1. Build the CPI target accounts context
        let cpi_accounts = Transfer {
            from: ctx.accounts.from_ata.to_account_info(),
            to: ctx.accounts.to_ata.to_account_info(),
            authority: ctx.accounts.authority.to_account_info(),
        };

        // 2. Build the CPI program reference
        let cpi_program = ctx.accounts.token_program.to_account_info();

        // 3. Construct the CPI context
        let cpi_ctx = CpiContext::new(cpi_program, cpi_accounts);

        // 4. Perform CPI token transfer call
        token::transfer(cpi_ctx, amount)?;

        msg!("SPL Token transfer of {} successful!", amount);
        Ok(())
    }
}

#[derive(Accounts)]
pub struct TransferTokens<'info> {
    /// CHECK: The owner authorizing the transfer
    #[account(mut, signer)]
    pub authority: AccountInfo<'info>,

    /// CHECK: The source Associated Token Account (ATA)
    #[account(mut)]
    pub from_ata: AccountInfo<'info>,

    /// CHECK: The destination Associated Token Account (ATA)
    #[account(mut)]
    pub to_ata: AccountInfo<'info>,

    pub token_program: Program<'info, Token>,
}
```
