package cmd

import (
	"context"
	"fmt"
	"os"
	"path/filepath"
	"strings"

	"github.com/ethereum-optimism/superchain-ops/cli/pkg/config"
	"github.com/ethereum-optimism/superchain-ops/cli/pkg/forge"
	"github.com/ethereum-optimism/superchain-ops/cli/pkg/safe"
	"github.com/spf13/cobra"
)

var (
	simulateSafeName string
	simulateTask     string
	simulateNetwork  string
	simulateRPC      string
	simulateLedger   bool
	simulateHDPath   int
)

var simulateCmd = &cobra.Command{
	Use:   "simulate [task-path]",
	Short: "Simulate a task transaction",
	Long: `Simulate a Safe transaction for a task.

This command will:
  1. Load the task configuration
  2. Query the Safe nonce on-chain
  3. Generate state overrides for simulation
  4. Run the forge script to simulate the transaction
  5. Display Tenderly simulation link and hashes to verify

Examples:
  # Simulate with auto-detected network
  sops simulate src/tasks/eth/004-opcm-upgrade-v300-base --safe foundation-operations

  # Simulate specific safe on specific network
  sops simulate src/tasks/eth/004-opcm-upgrade-v300-base --safe base-operations --network mainnet

  # Simulate without ledger (for testing)
  sops simulate src/tasks/sep/001-test --safe fake-foundation-upgrade --no-ledger`,
	Args: cobra.ExactArgs(1),
	RunE: runSimulate,
}

func init() {
	rootCmd.AddCommand(simulateCmd)

	simulateCmd.Flags().StringVar(&simulateSafeName, "safe", "", "Safe name to simulate for (e.g., foundation-operations)")
	simulateCmd.Flags().StringVar(&simulateNetwork, "network", "", "Network (eth, sep) - auto-detected from path if not specified")
	simulateCmd.Flags().StringVar(&simulateRPC, "rpc", "", "RPC URL (defaults to env var ETH_RPC_URL)")
	simulateCmd.Flags().BoolVar(&simulateLedger, "no-ledger", false, "Simulate without ledger connected")
	simulateCmd.Flags().IntVar(&simulateHDPath, "hd-path", 0, "HD derivation path index (default 0 = m/44'/60'/0'/0/0)")

	simulateCmd.MarkFlagRequired("safe")
}

func runSimulate(cmd *cobra.Command, args []string) error {
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
	if simulateNetwork == "" {
		if strings.Contains(taskPath, "/eth/") {
			simulateNetwork = "mainnet"
		} else if strings.Contains(taskPath, "/sep/") {
			simulateNetwork = "sepolia"
		} else {
			return fmt.Errorf("could not auto-detect network from path, please specify --network")
		}
	}

	// Get RPC URL
	rpcURL := simulateRPC
	if rpcURL == "" {
		rpcURL = os.Getenv("ETH_RPC_URL")
		if rpcURL == "" {
			return fmt.Errorf("RPC URL not provided (use --rpc or set ETH_RPC_URL)")
		}
	}

	fmt.Printf("🔍 Simulating task: %s\n", filepath.Base(taskPath))
	fmt.Printf("📍 Network: %s\n", simulateNetwork)
	fmt.Printf("🔐 Safe: %s\n\n", simulateSafeName)

	// Load task configuration
	cfg, err := config.LoadTaskConfig(taskPath)
	if err != nil {
		return fmt.Errorf("failed to load task config: %w", err)
	}

	fmt.Printf("📄 Template: %s\n", cfg.TemplateName)

	// Resolve safe address
	safeAddr, err := safe.GetSafeAddress(simulateNetwork, simulateSafeName)
	if err != nil {
		return fmt.Errorf("failed to resolve safe address: %w", err)
	}

	fmt.Printf("📫 Safe Address: %s\n\n", safeAddr.Hex())

	// Get Safe nonce
	fmt.Println("🔢 Querying Safe nonce...")
	nonceManager, err := safe.NewNonceManager(rpcURL)
	if err != nil {
		return fmt.Errorf("failed to create nonce manager: %w", err)
	}
	defer nonceManager.Close()

	safeInfo, err := nonceManager.GetSafeInfo(ctx, safeAddr)
	if err != nil {
		return fmt.Errorf("failed to get safe info: %w", err)
	}

	fmt.Printf("   Current nonce: %s\n", safeInfo.Nonce.String())
	fmt.Printf("   Threshold: %s\n\n", safeInfo.Threshold.String())

	// Check if this is an OPCM task
	_ = strings.Contains(cfg.TemplateName, "OPCM")

	// Generate state overrides
	fmt.Println("⚙️  Generating state overrides...")
	stateOverrides := safe.GenerateStateOverrides(safeAddr, safeInfo.Nonce, true)

	// Add task-specific state overrides from config
	for _, _ = range cfg.StateOverrides {
		// Convert to proper format
		// This would merge with generated overrides
	}

	// Get template path
	repoRoot, err := forge.GetRepoRoot()
	if err != nil {
		return fmt.Errorf("failed to get repo root: %w", err)
	}

	templatePath := filepath.Join(repoRoot, "src", "template", cfg.TemplateName+".sol")

	// Setup forge runner
	forgeRunner := forge.NewForgeRunner(repoRoot, rpcURL)
	forgeRunner.SetVerbose(verbose)

	// Set working directory to task path for config access
	taskConfigPath, err := filepath.Abs(filepath.Join(taskPath, "config.toml"))
	if err != nil {
		return err
	}

	// Run simulation
	fmt.Println("🚀 Running forge script simulation...")
	fmt.Println("   This may take a minute...")

	output, err := forgeRunner.RunScript(
		ctx,
		templatePath,
		"run(string)",
		[]string{taskConfigPath},
		stateOverrides,
	)

	if err != nil {
		fmt.Fprintf(os.Stderr, "❌ Simulation failed:\n%s\n", output)
		return err
	}

	// Extract and display results
	fmt.Println("✅ Simulation successful!")

	tenderlyURL := forge.ExtractTenderlyURL(output)
	if tenderlyURL != "" {
		fmt.Printf("🌐 Tenderly Simulation:\n   %s\n\n", tenderlyURL)
	}

	domainHash, messageHash := forge.ExtractHashes(output)
	if domainHash != "" && messageHash != "" {
		fmt.Println("🔑 Hashes to verify on Ledger:")
		fmt.Printf("   Domain Hash:  %s\n", domainHash)
		fmt.Printf("   Message Hash: %s\n\n", messageHash)
	}

	// Print next steps
	fmt.Println("📋 Next Steps:")
	fmt.Println("   1. Open the Tenderly simulation and review all state changes")
	fmt.Println("   2. Verify the changes match the task's VALIDATION.md")
	fmt.Println("   3. If everything looks correct, proceed to sign:")
	fmt.Printf("      sops sign %s --safe %s\n\n", taskPath, simulateSafeName)

	// Print verbose output if requested
	if verbose {
		fmt.Println("📄 Full Output:")
		fmt.Println(strings.Repeat("-", 80))
		fmt.Println(output)
		fmt.Println(strings.Repeat("-", 80))
	}

	return nil
}
