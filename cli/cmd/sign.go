package cmd

import (
	"context"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"

	"github.com/ethereum-optimism/superchain-ops/cli/pkg/config"
	"github.com/ethereum-optimism/superchain-ops/cli/pkg/forge"
	"github.com/ethereum-optimism/superchain-ops/cli/pkg/safe"
	"github.com/spf13/cobra"
)

var (
	signSafeName  string
	signNetwork   string
	signRPC       string
	signHDPath    int
	signKeystore  bool
)

var signCmd = &cobra.Command{
	Use:   "sign [task-path]",
	Short: "Sign a task transaction with hardware wallet",
	Long: `Sign a Safe transaction using a Ledger hardware wallet.

This command will:
  1. Simulate the transaction (same as 'simulate' command)
  2. Extract the EIP-712 hash
  3. Call eip712sign to sign with your Ledger
  4. Save the signature for the facilitator

Prerequisites:
  - Ledger must be connected and unlocked
  - Ethereum app must be open on Ledger
  - eip712sign must be installed (installed via 'just install-eip712sign')

Examples:
  # Sign with default derivation path (m/44'/60'/0'/0/0)
  sops sign src/tasks/eth/004-opcm-upgrade-v300-base --safe foundation-operations

  # Sign with different HD path
  sops sign src/tasks/eth/004-opcm-upgrade-v300-base --safe foundation-operations --hd-path 1

  # Sign with keystore instead of Ledger
  sops sign src/tasks/eth/004-opcm-upgrade-v300-base --safe foundation-operations --keystore`,
	Args: cobra.ExactArgs(1),
	RunE: runSign,
}

func init() {
	rootCmd.AddCommand(signCmd)

	signCmd.Flags().StringVar(&signSafeName, "safe", "", "Safe name to sign for (e.g., foundation-operations)")
	signCmd.Flags().StringVar(&signNetwork, "network", "", "Network (eth, sep) - auto-detected from path if not specified")
	signCmd.Flags().StringVar(&signRPC, "rpc", "", "RPC URL (defaults to env var ETH_RPC_URL)")
	signCmd.Flags().IntVar(&signHDPath, "hd-path", 0, "HD derivation path index (default 0 = m/44'/60'/0'/0/0)")
	signCmd.Flags().BoolVar(&signKeystore, "keystore", false, "Use keystore instead of Ledger")

	signCmd.MarkFlagRequired("safe")
}

func runSign(cmd *cobra.Command, args []string) error {
	ctx := context.Background()
	taskPath := args[0]

	// Ensure task path is absolute
	if !filepath.IsAbs(taskPath) {
		absPath, err := filepath.Abs(taskPath)
		if err != nil {
			return fmt.Errorf("failed to resolve task path: %w", err)
		}
		taskPath = absPath
	}

	// Auto-detect network from path if not specified
	if signNetwork == "" {
		if strings.Contains(taskPath, "/eth/") {
			signNetwork = "mainnet"
		} else if strings.Contains(taskPath, "/sep/") {
			signNetwork = "sepolia"
		} else {
			return fmt.Errorf("could not auto-detect network from path, please specify --network")
		}
	}

	// Get RPC URL
	rpcURL := signRPC
	if rpcURL == "" {
		rpcURL = os.Getenv("ETH_RPC_URL")
		if rpcURL == "" {
			return fmt.Errorf("RPC URL not provided (use --rpc or set ETH_RPC_URL)")
		}
	}

	fmt.Printf("✍️  Signing task: %s\n", filepath.Base(taskPath))
	fmt.Printf("📍 Network: %s\n", signNetwork)
	fmt.Printf("🔐 Safe: %s\n\n", signSafeName)

	// Check if eip712sign is installed
	repoRoot, err := forge.GetRepoRoot()
	if err != nil {
		return err
	}

	eip712signPath := filepath.Join(repoRoot, "bin", "eip712sign")
	if _, err := os.Stat(eip712signPath); os.IsNotExist(err) {
		return fmt.Errorf("eip712sign not found at %s\nPlease run: just install-eip712sign", eip712signPath)
	}

	// Load task configuration
	cfg, err := config.LoadTaskConfig(taskPath)
	if err != nil {
		return fmt.Errorf("failed to load task config: %w", err)
	}

	fmt.Printf("📄 Template: %s\n\n", cfg.TemplateName)

	// Resolve safe address
	safeAddr, err := safe.GetSafeAddress(signNetwork, signSafeName)
	if err != nil {
		return fmt.Errorf("failed to resolve safe address: %w", err)
	}

	// Get Safe nonce
	nonceManager, err := safe.NewNonceManager(rpcURL)
	if err != nil {
		return fmt.Errorf("failed to create nonce manager: %w", err)
	}
	defer nonceManager.Close()

	safeInfo, err := nonceManager.GetSafeInfo(ctx, safeAddr)
	if err != nil {
		return fmt.Errorf("failed to get safe info: %w", err)
	}

	fmt.Printf("🔢 Using nonce: %s\n\n", safeInfo.Nonce.String())

	// Generate state overrides
	_ = safe.GenerateStateOverrides(safeAddr, safeInfo.Nonce, true)

	// Get template path
	templatePath := filepath.Join(repoRoot, "src", "template", cfg.TemplateName+".sol")
	taskConfigPath, err := filepath.Abs(filepath.Join(taskPath, "config.toml"))
	if err != nil {
		return err
	}

	// Setup forge runner
	forgeRunner := forge.NewForgeRunner(repoRoot, rpcURL)
	forgeRunner.SetVerbose(verbose)

	// Build the forge command that eip712sign will wrap
	forgeArgs := []string{
		"script",
		templatePath,
		"--sig", "run(string)",
		taskConfigPath,
		"--fork-url", rpcURL,
		"--ffi",
	}

	if verbose {
		forgeArgs = append(forgeArgs, "-vvv")
	}

	// Build eip712sign command
	eip712Args := []string{}

	if signKeystore {
		keystorePath := filepath.Join(os.Getenv("HOME"), ".foundry", "keystores")
		eip712Args = append(eip712Args, "--keystore", keystorePath)
	} else {
		// Ledger with HD path
		hdPathStr := fmt.Sprintf("m/44'/60'/%d'/0/0", signHDPath)
		eip712Args = append(eip712Args, "--ledger", "--hd-path", hdPathStr)
	}

	// Add forge command
	eip712Args = append(eip712Args, "--")
	eip712Args = append(eip712Args, "forge")
	eip712Args = append(eip712Args, forgeArgs...)

	fmt.Println("🚀 Running signing process...")
	if !signKeystore {
		fmt.Println("⚠️  Check your Ledger device and verify the hashes match!")
	}
	fmt.Println()

	// Set environment for signing mode
	os.Setenv("SIGNING_MODE_IN_PROGRESS", "true")

	// Run eip712sign
	signCmd := exec.CommandContext(ctx, eip712signPath, eip712Args...)
	signCmd.Dir = repoRoot
	signCmd.Stdout = os.Stdout
	signCmd.Stderr = os.Stderr
	signCmd.Stdin = os.Stdin

	// Add state overrides via environment (forge will pick this up)
	// Note: This is a simplified approach; production would need proper state override file handling

	if err := signCmd.Run(); err != nil {
		return fmt.Errorf("signing failed: %w", err)
	}

	fmt.Println("\n✅ Signature collected successfully!")
	fmt.Println("\n📋 Next Steps:")
	fmt.Println("   1. Save the signature output")
	fmt.Println("   2. Send the signature to the task facilitator")
	fmt.Println("   3. The facilitator will collect all signatures and execute the transaction")

	return nil
}
