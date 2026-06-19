# Solana AI Kit & Reference Game Skill

This document provides detailed integration guides, architectures, and development examples for the **Solana AI Kit** and its reference **Solana Game Skill**.

---

## 1. Solana AI Kit (`solanabr/solana-ai-kit`)

The **Solana AI Kit** is an opinionated, AI-native configuration framework designed for AI coding agents (such as Claude Code or Cursor) to act as expert Solana developers. It structures context, rules, and commands to facilitate high-frequency developer workflows.

### Progressive Loading Context Structure
To keep context windows clean and token-efficient, the kit uses a hierarchical structure where files are loaded progressively:
*   **Layer 1 (Root `CLAUDE.md`)**: Defines developer environment settings, command mappings, and styling constraints.
*   **Layer 2 (Skill Hub `SKILL.md`)**: A routing directory mapping intent (e.g., "gate routes", "run tests") to specific reference files.
*   **Layer 3 (References folder)**: Context-specific markdown files (e.g., `security.md`, `server-patterns.md`) loaded dynamically only when matching the task.

```text
solana-ai-kit/
├── CLAUDE.md                      # Agent rules & quick commands
├── skill/
│   ├── SKILL.md                   # Routing index for progressive loading
│   └── references/
│       ├── anchor-patterns.md     # Anchor program dev guidelines
│       └── mobile-wallet.md       # Mobile Wallet Adapter (MWA) setup
```

### Installation Options

#### One-Liner Installer
Automated bootstrap script for setting up the coding agent configuration:
```bash
curl -fsSL https://aikit.superteam.codes | bash
```

#### Custom Agent Setup
Installs the kit along with specialized agent files (`.agents/`) and security rules (`.claude/rules/`):
```bash
curl -fsSL https://aikit.superteam.codes | bash -s -- --agents --rules
```

---

## 2. Reference Game Skill (`solanabr/solana-game-skill`)

The **Solana Game Skill** is a reference plugin extending the core developer skill. It focuses on game development across Unity (Magicblock / PlaySolana SDKs), C#/.NET 9, and React Native.

### Unity & Magicblock Integration Example
The following C# script shows how a Unity game client initiates an on-chain player state updates using the Magicblock SDK.

```csharp
using System;
using System.Threading.Tasks;
using UnityEngine;
using Solana.Unity.SDK;
using Solana.Unity.Wallet;
using Solana.Unity.Rpc.Models;

public class SolanaGameManager : MonoBehaviour
{
    private Web3 _web3;
    private Wallet _wallet;

    // Replace with your game program ID
    private const string ProgramId = "Game11111111111111111111111111111111111111";

    async void Start()
    {
        // 1. Initialize Web3 Client pointing to Devnet
        _web3 = new Web3(new RpcConfig
        {
            Url = "https://api.devnet.solana.com"
        });

        // 2. Load or restore local session wallet
        _wallet = await LoadOrCreateInGameWallet();
        Debug.Log($"Active Player Wallet: {_wallet.Account.PublicKey}");
    }

    public async Task<string> UpdatePlayerLevel(uint newLevel)
    {
        try
        {
            // 3. Build Instruction Data (Level Up State)
            byte[] instructionData = new byte[5];
            instructionData[0] = 1; // Discriminator for 'UpdateLevel'
            BitConverter.GetBytes(newLevel).CopyTo(instructionData, 1);

            // 4. Set up account dependencies
            var keys = new[]
            {
                new AccountMeta(_wallet.Account.PublicKey, true, true),
                new AccountMeta(new PublicKey(ProgramId), false, false)
            };

            var transaction = new Transaction
            {
                RecentBlockHash = await _web3.RpcClient.GetRecentBlockHashAsync(),
                FeePayer = _wallet.Account.PublicKey,
                Instructions = new System.Collections.Generic.List<TransactionInstruction>
                {
                    new TransactionInstruction
                    {
                        ProgramId = new PublicKey(ProgramId),
                        Keys = keys,
                        Data = instructionData
                    }
                }
            };

            // 5. Sign & Send Transaction
            string txHash = await _web3.SendTransactionAsync(transaction, _wallet.Account);
            Debug.Log($"Player Level Updated! Tx: {txHash}");
            return txHash;
        }
        catch (Exception ex)
        {
            Debug.LogError($"Failed to level up: {ex.Message}");
            return null;
        }
    }

    private Task<Wallet> LoadOrCreateInGameWallet()
    {
        // Mocking local keypair storage securely
        var mnemonic = "pulse practice dynamic control visual physical space zero fine local dynamic actual";
        return Task.FromResult(new Wallet(mnemonic));
    }
}
```

### PlaySolana SDK Mobile Setup
For mobile Unity games deploying to Android or iOS, the Mobile Wallet Adapter (MWA) is required. This ensures private keys never leave the secure hardware enclave of the user's wallet application (e.g., Phantom, Solflare).

```csharp
using Solana.Unity.SDK;
using Solana.Unity.Wallet;
using UnityEngine;

public class MobileAuthManager : MonoBehaviour
{
    public async void ConnectMobileWallet()
    {
        // MWA triggers a secure deep link handshake on Android/iOS
        var connectionResult = await Web3.Instance.LoginWalletWithMWA();
        
        if (connectionResult != null && connectionResult.Status == LoginStatus.Success)
        {
            Debug.Log($"Successfully authorized player: {connectionResult.PublicKey}");
        }
        else
        {
            Debug.LogError("Mobile Wallet connection rejected or timed out.");
        }
    }
}
```
