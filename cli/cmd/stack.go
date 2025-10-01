package cmd

import (
	"context"
	"fmt"
	"os"
	"path/filepath"
	"sort"
	"strings"

	"github.com/ethereum-optimism/superchain-ops/cli/pkg/config"
	"github.com/ethereum-optimism/superchain-ops/cli/pkg/forge"
	"github.com/spf13/cobra"
)

var stackCmd = &cobra.Command{
	Use:   "stack",
	Short: "Manage stacked task simulations",
	Long: `Commands for working with stacked tasks.

Stacked tasks allow simulating multiple sequential transactions
that build upon each other's state changes.`,
}

var stackSimulateCmd = &cobra.Command{
	Use:   "simulate [network] [task]",
	Short: "Simulate stacked tasks",
	Long: `Simulate all tasks in sequence up to and including the specified task.

This simulates the cumulative state changes from executing multiple
tasks in order, which is useful for:
  - Testing task dependencies
  - Validating nonce sequencing
  - Reviewing cumulative state changes

Examples:
  # Simulate all tasks up to and including task 004
  sops stack simulate eth 004-opcm-upgrade-v300-base

  # Simulate all tasks for a network
  sops stack simulate eth`,
	Args: cobra.RangeArgs(1, 2),
	RunE: runStackSimulate,
}

var stackListCmd = &cobra.Command{
	Use:   "list [network]",
	Short: "List tasks in simulation order",
	Long: `List all tasks for a network in the order they would be simulated.

This shows the dependency order and helps plan task execution.

Examples:
  # List mainnet task stack
  sops stack list eth

  # List sepolia task stack
  sops stack list sep`,
	Args: cobra.ExactArgs(1),
	RunE: runStackList,
}

func init() {
	rootCmd.AddCommand(stackCmd)
	stackCmd.AddCommand(stackSimulateCmd)
	stackCmd.AddCommand(stackListCmd)

	stackSimulateCmd.Flags().String("rpc", "", "RPC URL (defaults to env var ETH_RPC_URL)")
	stackSimulateCmd.Flags().String("safe", "", "Safe name to simulate for")
}

func runStackSimulate(cmd *cobra.Command, args []string) error {
	_ = context.Background()
	network := args[0]

	var targetTask string
	if len(args) > 1 {
		targetTask = args[1]
	}

	rpcURL, _ := cmd.Flags().GetString("rpc")
	if rpcURL == "" {
		rpcURL = os.Getenv("ETH_RPC_URL")
		if rpcURL == "" {
			return fmt.Errorf("RPC URL not provided (use --rpc or set ETH_RPC_URL)")
		}
	}

	safeName, _ := cmd.Flags().GetString("safe")

	networkDir := network
	if network == "mainnet" {
		networkDir = "eth"
	} else if network == "sepolia" {
		networkDir = "sep"
	}

	repoRoot, err := forge.GetRepoRoot()
	if err != nil {
		return err
	}

	tasksPath := filepath.Join(repoRoot, "src", "tasks", networkDir)

	// Get all tasks
	tasks, err := getTasksInOrder(tasksPath, targetTask)
	if err != nil {
		return err
	}

	if len(tasks) == 0 {
		fmt.Println("No tasks found.")
		return nil
	}

	fmt.Printf("🔗 Simulating stacked tasks for %s\n", network)
	fmt.Printf("📊 Total tasks: %d\n\n", len(tasks))

	// List tasks that will be simulated
	fmt.Println("Tasks in stack:")
	for i, task := range tasks {
		fmt.Printf("   %d. %s\n", i+1, filepath.Base(task))
	}
	fmt.Println()

	// For stack simulation, we need to use forge's StackedSimulator
	// This is a simplified version - full implementation would call the StackedSimulator.sol

	fmt.Println("🚀 Running stacked simulation...")
	fmt.Println("   This may take several minutes...\n")

	// TODO: Implement actual stacked simulation
	// This would call: forge script StackedSimulator.sol:StackedSimulator --sig "simulateStack(string,string)" network task

	fmt.Println("⚠️  Note: Full stack simulation implementation pending.")
	fmt.Println("   For now, you can simulate tasks individually.\n")

	fmt.Println("💡 To simulate tasks individually:")
	for _, task := range tasks {
		if safeName != "" {
			fmt.Printf("   sops simulate %s --safe %s\n", task, safeName)
		} else {
			fmt.Printf("   sops simulate %s --safe <safe-name>\n", task)
		}
	}

	return nil
}

func runStackList(cmd *cobra.Command, args []string) error {
	network := args[0]

	networkDir := network
	if network == "mainnet" {
		networkDir = "eth"
	} else if network == "sepolia" {
		networkDir = "sep"
	}

	repoRoot, err := forge.GetRepoRoot()
	if err != nil {
		return err
	}

	tasksPath := filepath.Join(repoRoot, "src", "tasks", networkDir)

	tasks, err := getTasksInOrder(tasksPath, "")
	if err != nil {
		return err
	}

	fmt.Printf("📋 Task Stack for %s (%d tasks)\n\n", network, len(tasks))

	if len(tasks) == 0 {
		fmt.Println("   No tasks found.")
		return nil
	}

	for i, taskPath := range tasks {
		taskName := filepath.Base(taskPath)

		// Load config to get template info
		cfg, err := config.LoadTaskConfig(taskPath)
		if err != nil {
			fmt.Printf("   %d. %s\n", i+1, taskName)
			continue
		}

		chains := make([]string, len(cfg.L2Chains))
		for j, chain := range cfg.L2Chains {
			chains[j] = chain.Name
		}

		fmt.Printf("   %d. %s\n", i+1, taskName)
		fmt.Printf("      Template: %s\n", cfg.TemplateName)
		if len(chains) > 0 {
			fmt.Printf("      Chains: %s\n", strings.Join(chains, ", "))
		}
		fmt.Println()
	}

	return nil
}

// getTasksInOrder returns tasks sorted by their numeric prefix
func getTasksInOrder(tasksPath, upToTask string) ([]string, error) {
	entries, err := os.ReadDir(tasksPath)
	if err != nil {
		return nil, fmt.Errorf("failed to read tasks directory: %w", err)
	}

	var taskPaths []string

	for _, entry := range entries {
		if !entry.IsDir() {
			continue
		}

		taskName := entry.Name()

		// Check if we should include this task
		if upToTask != "" {
			// Include tasks up to and including the target
			taskPaths = append(taskPaths, filepath.Join(tasksPath, taskName))

			// Stop if we've reached the target task
			if strings.Contains(taskName, upToTask) || taskName == upToTask {
				break
			}
		} else {
			taskPaths = append(taskPaths, filepath.Join(tasksPath, taskName))
		}
	}

	// Sort by task number prefix
	sort.Slice(taskPaths, func(i, j int) bool {
		return filepath.Base(taskPaths[i]) < filepath.Base(taskPaths[j])
	})

	return taskPaths, nil
}
