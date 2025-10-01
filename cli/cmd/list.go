package cmd

import (
	"fmt"
	"os"
	"path/filepath"
	"sort"
	"strings"

	"github.com/ethereum-optimism/superchain-ops/cli/pkg/config"
	"github.com/ethereum-optimism/superchain-ops/cli/pkg/forge"
	"github.com/spf13/cobra"
)

var (
	listNetwork string
)

var listCmd = &cobra.Command{
	Use:   "list [network]",
	Short: "List all tasks for a network",
	Long: `List all available tasks for a specific network.

This helps you discover tasks and see their current status.

Examples:
  # List all mainnet tasks
  sops list eth

  # List all sepolia tasks
  sops list sep`,
	Args: cobra.MaximumNArgs(1),
	RunE: runList,
}

func init() {
	rootCmd.AddCommand(listCmd)
}

func runList(cmd *cobra.Command, args []string) error {
	network := "eth"
	if len(args) > 0 {
		network = args[0]
	}

	// Map short names to full names
	networkMap := map[string]string{
		"eth":     "eth",
		"mainnet": "eth",
		"sep":     "sep",
		"sepolia": "sep",
	}

	networkDir, ok := networkMap[network]
	if !ok {
		return fmt.Errorf("unknown network: %s (use: eth, sep)", network)
	}

	repoRoot, err := forge.GetRepoRoot()
	if err != nil {
		return err
	}

	tasksPath := filepath.Join(repoRoot, "src", "tasks", networkDir)

	// Check if tasks directory exists
	if _, err := os.Stat(tasksPath); os.IsNotExist(err) {
		return fmt.Errorf("tasks directory not found: %s", tasksPath)
	}

	// Read all task directories
	entries, err := os.ReadDir(tasksPath)
	if err != nil {
		return fmt.Errorf("failed to read tasks directory: %w", err)
	}

	// Collect task information
	type taskInfo struct {
		Name     string
		Template string
		Chains   []string
		Path     string
	}

	var tasks []taskInfo

	for _, entry := range entries {
		if !entry.IsDir() {
			continue
		}

		taskPath := filepath.Join(tasksPath, entry.Name())

		// Try to load config
		cfg, err := config.LoadTaskConfig(taskPath)
		if err != nil {
			// Skip if config can't be loaded
			continue
		}

		chains := make([]string, len(cfg.L2Chains))
		for i, chain := range cfg.L2Chains {
			chains[i] = chain.Name
		}

		tasks = append(tasks, taskInfo{
			Name:     entry.Name(),
			Template: cfg.TemplateName,
			Chains:   chains,
			Path:     taskPath,
		})
	}

	// Sort tasks by name
	sort.Slice(tasks, func(i, j int) bool {
		return tasks[i].Name < tasks[j].Name
	})

	// Display tasks
	networkName := map[string]string{
		"eth": "Ethereum Mainnet",
		"sep": "Sepolia Testnet",
	}[networkDir]

	fmt.Printf("📋 Tasks for %s (%d total)\n\n", networkName, len(tasks))

	if len(tasks) == 0 {
		fmt.Println("   No tasks found.")
		return nil
	}

	for _, task := range tasks {
		fmt.Printf("📦 %s\n", task.Name)
		fmt.Printf("   Template: %s\n", task.Template)
		if len(task.Chains) > 0 {
			fmt.Printf("   Chains: %s\n", strings.Join(task.Chains, ", "))
		}
		fmt.Printf("   Path: %s\n", task.Path)
		fmt.Println()
	}

	fmt.Printf("💡 To simulate a task:\n")
	if len(tasks) > 0 {
		fmt.Printf("   sops simulate %s --safe <safe-name>\n", tasks[0].Path)
	}

	return nil
}
