package cmd

import (
	"context"
	"fmt"
	"os"

	"github.com/ethereum-optimism/superchain-ops/cli/pkg/safe"
	"github.com/spf13/cobra"
)

var (
	nonceNetwork string
	nonceRPC     string
)

var nonceCmd = &cobra.Command{
	Use:   "nonce [safe-name]",
	Short: "Query the current nonce of a Safe",
	Long: `Query the current nonce and information about a Gnosis Safe.

This is useful for:
  - Checking the current nonce before creating a task
  - Debugging nonce conflicts
  - Verifying Safe configuration

Examples:
  # Check Foundation Operations Safe on mainnet
  sops nonce foundation-operations --network mainnet

  # Check with custom RPC
  sops nonce base-operations --network mainnet --rpc https://eth.llamarpc.com`,
	Args: cobra.ExactArgs(1),
	RunE: runNonce,
}

func init() {
	rootCmd.AddCommand(nonceCmd)

	nonceCmd.Flags().StringVar(&nonceNetwork, "network", "mainnet", "Network (mainnet, sepolia)")
	nonceCmd.Flags().StringVar(&nonceRPC, "rpc", "", "RPC URL (defaults to env var ETH_RPC_URL)")
}

func runNonce(cmd *cobra.Command, args []string) error {
	ctx := context.Background()
	safeName := args[0]

	// Get RPC URL
	rpcURL := nonceRPC
	if rpcURL == "" {
		rpcURL = os.Getenv("ETH_RPC_URL")
		if rpcURL == "" {
			return fmt.Errorf("RPC URL not provided (use --rpc or set ETH_RPC_URL)")
		}
	}

	// Resolve safe address
	safeAddr, err := safe.GetSafeAddress(nonceNetwork, safeName)
	if err != nil {
		return fmt.Errorf("failed to resolve safe address: %w", err)
	}

	fmt.Printf("🔐 Safe: %s\n", safeName)
	fmt.Printf("📫 Address: %s\n", safeAddr.Hex())
	fmt.Printf("📍 Network: %s\n\n", nonceNetwork)

	// Get Safe info
	nonceManager, err := safe.NewNonceManager(rpcURL)
	if err != nil {
		return fmt.Errorf("failed to create nonce manager: %w", err)
	}
	defer nonceManager.Close()

	safeInfo, err := nonceManager.GetSafeInfo(ctx, safeAddr)
	if err != nil {
		return fmt.Errorf("failed to get safe info: %w", err)
	}

	fmt.Println("📊 Safe Information:")
	fmt.Printf("   Current Nonce: %s\n", safeInfo.Nonce.String())
	fmt.Printf("   Threshold: %s\n", safeInfo.Threshold.String())
	fmt.Printf("   Owner Count: %d\n", len(safeInfo.Owners))

	if len(safeInfo.Owners) > 0 {
		fmt.Println("\n   Owners:")
		for i, owner := range safeInfo.Owners {
			fmt.Printf("   %d. %s\n", i+1, owner.Hex())
		}
	}

	fmt.Println("\n💡 Tip: Use this nonce in your config.toml stateOverrides:")
	fmt.Printf("   [stateOverrides]\n")
	fmt.Printf("   %s = [\n", safeAddr.Hex())
	fmt.Printf("       {key = \"0x0000000000000000000000000000000000000000000000000000000000000005\", value = %s}\n", safeInfo.Nonce.String())
	fmt.Printf("   ]\n")

	return nil
}
