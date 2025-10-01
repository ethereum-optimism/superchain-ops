package config

import (
	"fmt"
	"os"
	"path/filepath"

	"github.com/BurntSushi/toml"
	"github.com/ethereum/go-ethereum/common"
)

// DefaultRPCURLs provides default RPC endpoints for common networks
var DefaultRPCURLs = map[string]string{
	"mainnet": "https://ethereum.publicnode.com",
	"sepolia": "https://ethereum-sepolia.publicnode.com",
}

// GetRPCURL returns the RPC URL for a network, with fallback priority:
// 1. Explicit rpcURL parameter (if not empty)
// 2. ETH_RPC_URL environment variable
// 3. Default public RPC for the network
func GetRPCURL(network, rpcURL string) string {
	// 1. Use explicitly provided RPC
	if rpcURL != "" {
		return rpcURL
	}

	// 2. Try environment variable
	envRPC := os.Getenv("ETH_RPC_URL")
	if envRPC != "" {
		return envRPC
	}

	// 3. Fall back to default public RPC
	if defaultRPC, ok := DefaultRPCURLs[network]; ok {
		return defaultRPC
	}

	// No default available
	return ""
}

// TaskConfig represents the config.toml structure for a task
type TaskConfig struct {
	TemplateName   string          `toml:"templateName"`
	L2Chains       []L2Chain       `toml:"l2chains"`
	OPCMUpgrades   []OPCMUpgrade   `toml:"opcmUpgrades"`
	AllowOverwrite []string        `toml:"allowOverwrite"`
	Addresses      map[string]string `toml:"addresses"`
	StateOverrides map[string][]StateOverride `toml:"stateOverrides"`
}

// L2Chain represents a chain configuration
type L2Chain struct {
	Name    string `toml:"name"`
	ChainID uint64 `toml:"chainId"`
}

// OPCMUpgrade represents OPCM upgrade parameters
type OPCMUpgrade struct {
	ChainID                  uint64 `toml:"chainId"`
	AbsolutePrestate         string `toml:"absolutePrestate"`
	ExpectedValidationErrors string `toml:"expectedValidationErrors"`
}

// StateOverride represents a single state override
type StateOverride struct {
	Key   string      `toml:"key"`
	Value interface{} `toml:"value"`
}

// TaskEnv represents the .env file for a task
type TaskEnv struct {
	TenderlyGas            string
	NestedSafeNameDepth1   string
	NestedSafeNameDepth2   string
	SimulateWithoutLedger  bool
	HDPath                 int
}

// LoadTaskConfig loads the config.toml file from a task directory
func LoadTaskConfig(taskPath string) (*TaskConfig, error) {
	configPath := filepath.Join(taskPath, "config.toml")

	data, err := os.ReadFile(configPath)
	if err != nil {
		return nil, fmt.Errorf("failed to read config.toml: %w", err)
	}

	var config TaskConfig
	if err := toml.Unmarshal(data, &config); err != nil {
		return nil, fmt.Errorf("failed to parse config.toml: %w", err)
	}

	return &config, nil
}

// LoadTaskEnv loads the .env file from a task directory
func LoadTaskEnv(taskPath string) (*TaskEnv, error) {
	envPath := filepath.Join(taskPath, ".env")

	// .env is optional
	if _, err := os.Stat(envPath); os.IsNotExist(err) {
		return &TaskEnv{}, nil
	}

	data, err := os.ReadFile(envPath)
	if err != nil {
		return nil, fmt.Errorf("failed to read .env: %w", err)
	}

	env := &TaskEnv{}
	// Simple key=value parser
	lines := splitLines(string(data))
	for _, line := range lines {
		if line == "" || line[0] == '#' {
			continue
		}

		key, value := parseEnvLine(line)
		switch key {
		case "TENDERLY_GAS":
			env.TenderlyGas = value
		case "NESTED_SAFE_NAME_DEPTH_1":
			env.NestedSafeNameDepth1 = value
		case "NESTED_SAFE_NAME_DEPTH_2":
			env.NestedSafeNameDepth2 = value
		case "SIMULATE_WITHOUT_LEDGER":
			env.SimulateWithoutLedger = value == "1" || value == "true"
		case "HD_PATH":
			fmt.Sscanf(value, "%d", &env.HDPath)
		}
	}

	return env, nil
}

// GetAddressFromConfig gets an address from the config with fallback
func (c *TaskConfig) GetAddress(name string) (common.Address, error) {
	addrStr, ok := c.Addresses[name]
	if !ok {
		return common.Address{}, fmt.Errorf("address %s not found in config", name)
	}

	if !common.IsHexAddress(addrStr) {
		return common.Address{}, fmt.Errorf("invalid address format for %s: %s", name, addrStr)
	}

	return common.HexToAddress(addrStr), nil
}

// GetStateOverrides returns state overrides for an address
func (c *TaskConfig) GetStateOverrides(addr common.Address) []StateOverride {
	return c.StateOverrides[addr.Hex()]
}

func splitLines(s string) []string {
	var lines []string
	var current string

	for _, r := range s {
		if r == '\n' {
			lines = append(lines, current)
			current = ""
		} else {
			current += string(r)
		}
	}

	if current != "" {
		lines = append(lines, current)
	}

	return lines
}

func parseEnvLine(line string) (string, string) {
	for i, r := range line {
		if r == '=' {
			return line[:i], line[i+1:]
		}
	}
	return line, ""
}
