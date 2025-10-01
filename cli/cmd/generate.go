package cmd

import (
	"context"
	"encoding/json"
	"fmt"
	"math/big"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"sync"
	"time"

	"github.com/BurntSushi/toml"
	"github.com/ethereum-optimism/superchain-ops/cli/pkg/config"
	"github.com/ethereum-optimism/superchain-ops/cli/pkg/registry"
	"github.com/ethereum-optimism/superchain-ops/cli/pkg/safe"
	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/crypto"
	"github.com/spf13/cobra"
)

var generateCmd = &cobra.Command{
	Use:   "generate [release-version] [chains...]",
	Short: "Generate signing artifacts for OPCM upgrades",
	Long: `Generate signing artifacts for OPCM upgrades using superchain-registry and monorepo submodule.

This command is triggered manually after a new op-contracts release is created and added to the
superchain-registry. It pulls all necessary information from the registry and generates signing
data artifacts for the specified chains.

Workflow:
  1. Create op-contracts release (e.g., op-contracts/v3.0.0)
  2. Deploy OPCM and StandardValidator
  3. Add OPCM, StandardValidator, and prestate to superchain-registry
  4. Run: sops generate v3.0.0 base op
  5. Review generated artifacts
  6. Sign: sops sign v3.0.0 --l2 base

Examples:
  # Generate for Base on mainnet (auto-uses ETH_RPC_URL or public RPC)
  sops generate v3.0.0 base

  # Generate for multiple chains with custom RPC
  sops generate v3.0.0 base op mode --rpc $ETH_RPC_URL

  # Generate for testnet
  sops generate v3.0.0-rc.1 base --l1 sepolia

Nested Safe Discovery & Hash Pre-calculation:
  The command automatically discovers the chain of nested Safes starting from ProxyAdmin
  by following owner() calls and checking for Safe contracts. Once discovered, it calculates
  EIP-712 domain and message hashes for each Safe in the chain.

  RPC selection priority:
    1. --rpc flag value
    2. ETH_RPC_URL environment variable
    3. Default public RPC (ethereum.publicnode.com)

  Discovered Safes are stored in the artifact as safe-0, safe-1, etc. (by nesting depth)
  with their respective hashes. See NESTED_SAFE_DISCOVERY.md and SAFE_HASHES.md for details.
`,
	Args: cobra.MinimumNArgs(2),
	RunE: runGenerate,
}

var (
	generateL1     string
	generateOutput string
	generateRPC    string
)

// SafeLabels holds the loaded Safe address labels
type SafeLabels struct {
	Labels map[string]map[string]string
}

var (
	safeLabels     *SafeLabels
	safeLabelsOnce sync.Once
)

// loadSafeLabels loads Safe addresses from src/addresses.toml
func loadSafeLabels() *SafeLabels {
	safeLabelsOnce.Do(func() {
		labels := &SafeLabels{
			Labels: make(map[string]map[string]string),
		}

		// Try to load from src/addresses.toml (relative to repo root or CLI dir)
		paths := []string{
			filepath.Join("..", "src", "addresses.toml"),  // From cli/ directory
			filepath.Join("src", "addresses.toml"),         // From repo root
		}

		for _, path := range paths {
			if _, err := os.Stat(path); err == nil {
				// Load the TOML file
				var addresses map[string]map[string]string
				if _, err := toml.DecodeFile(path, &addresses); err == nil {
					// Convert the addresses to our label format
					// The file uses network keys "eth" and "sep"
					labels.Labels["mainnet"] = invertAddressMap(addresses["eth"])
					labels.Labels["sepolia"] = invertAddressMap(addresses["sep"])
					safeLabels = labels
					return
				}
			}
		}

		// No labels file found, use empty labels
		safeLabels = labels
	})
	return safeLabels
}

// invertAddressMap converts {name: address} to {address: name}
func invertAddressMap(addresses map[string]string) map[string]string {
	inverted := make(map[string]string)
	for name, addr := range addresses {
		// Convert camelCase to "Title Case"
		label := camelToTitle(name)
		inverted[addr] = label
	}
	return inverted
}

// camelToTitle converts camelCase to "Title Case With Spaces"
func camelToTitle(s string) string {
	var result strings.Builder
	for i, r := range s {
		if i > 0 && r >= 'A' && r <= 'Z' {
			result.WriteRune(' ')
		}
		if i == 0 {
			result.WriteRune(r)
		} else {
			result.WriteRune(r)
		}
	}
	return result.String()
}

// getSafeLabel returns a human-readable label for a Safe address
func getSafeLabel(address, network string) string {
	labels := loadSafeLabels()
	if networkLabels, ok := labels.Labels[network]; ok {
		// Normalize address (lowercase)
		normalizedAddr := strings.ToLower(address)
		for addr, label := range networkLabels {
			if strings.ToLower(addr) == normalizedAddr {
				return label
			}
		}
	}
	return ""
}

func init() {
	rootCmd.AddCommand(generateCmd)

	generateCmd.Flags().StringVar(&generateL1, "l1", "mainnet", "L1 network (mainnet, sepolia)")
	generateCmd.Flags().StringVar(&generateOutput, "output", "./artifacts", "Output directory for signing data")
	generateCmd.Flags().StringVar(&generateRPC, "rpc", "", "RPC URL for querying Safe nonces and calculating hashes (uses ETH_RPC_URL env var or public RPC if not specified)")
}

// SigningArtifact represents the complete signing data for a chain upgrade
type SigningArtifact struct {
	Chain                string                 `json:"chain"`
	ChainID              uint64                 `json:"chainId"`
	Version              string                 `json:"version"`
	CommitHash           string                 `json:"commitHash"`
	Timestamp            string                 `json:"timestamp"`
	OPCM                 string                 `json:"opcm"`
	Calldata             CalldataInfo           `json:"calldata"`
	Hashes               HashInfo               `json:"hashes"`
	TenderlySimulation   TenderlyInfo           `json:"tenderlySimulation"`
	OpChainConfig        OpChainConfigInfo      `json:"opChainConfig"`
}

type CalldataInfo struct {
	OPCMUpgrade string `json:"opcmUpgrade"`
	Multicall3  string `json:"multicall3"`
}

type HashInfo struct {
	DomainHash  string            `json:"domainHash"`
	MessageHash string            `json:"messageHash"`
	Safes       map[string]SafeHashes `json:"safes,omitempty"`
}

type SafeHashes struct {
	Address     string `json:"address"`
	Nonce       string `json:"nonce"`
	DomainHash  string `json:"domainHash"`
	MessageHash string `json:"messageHash"`
}

type TenderlyInfo struct {
	URL            string                 `json:"url"`
	StateOverrides map[string]interface{} `json:"stateOverrides"`
}

type OpChainConfigInfo struct {
	SystemConfigProxy string `json:"systemConfigProxy"`
	ProxyAdmin        string `json:"proxyAdmin"`
	AbsolutePrestate  string `json:"absolutePrestate"`
}

func runGenerate(cmd *cobra.Command, args []string) error {
	version := args[0]
	chains := args[1:]

	// Normalize version (add op-contracts/ prefix if not present)
	if !strings.HasPrefix(version, "op-contracts/") {
		version = "op-contracts/" + version
	}

	fmt.Printf("🚀 Generating signing artifacts for %s\n", version)
	fmt.Printf("📋 Chains: %s\n", strings.Join(chains, ", "))
	fmt.Printf("🌐 L1 Network: %s\n", generateL1)

	// Load superchain-registry
	registryPath, err := registry.GetDefaultRegistryPath()
	if err != nil {
		return fmt.Errorf("failed to find superchain-registry: %w", err)
	}
	fmt.Printf("📚 Using registry at: %s\n", registryPath)

	// Update superchain-registry submodule to latest
	fmt.Println("🔄 Updating superchain-registry submodule...")
	if err := updateRegistrySubmodule(registryPath); err != nil {
		fmt.Printf("⚠️  Warning: Failed to update registry submodule: %v\n", err)
		fmt.Println("   Continuing with current registry state...")
	} else {
		fmt.Println("✅ Registry updated to latest")
	}

	reg := registry.NewRegistry(registryPath)

	// Get OPCM address for this release
	opcmAddress, err := reg.GetOPCMAddress(generateL1, version)
	if err != nil {
		return fmt.Errorf("failed to get OPCM address: %w\nMake sure %s is added to standard-versions-%s.toml", err, version, generateL1)
	}
	fmt.Printf("📝 OPCM address: %s\n", opcmAddress)

	// Get commit hash from the release tag in monorepo
	commitHash, err := getCommitHashFromTag(version)
	if err != nil {
		return fmt.Errorf("failed to get commit hash from tag %s: %w", version, err)
	}
	fmt.Printf("📌 Commit hash: %s (from tag %s)\n", commitHash[:8], version)

	// Create output directory
	if err := os.MkdirAll(generateOutput, 0755); err != nil {
		return fmt.Errorf("failed to create output directory: %w", err)
	}

	// Generate artifacts for each chain
	for _, chain := range chains {
		fmt.Printf("\n📝 Generating artifact for %s...\n", chain)

		artifact, err := generateArtifact(reg, generateL1, chain, version, opcmAddress, commitHash)
		if err != nil {
			return fmt.Errorf("failed to generate artifact for %s: %w", chain, err)
		}

		// Write artifact to file
		outputPath := filepath.Join(generateOutput, fmt.Sprintf("%s-%s.json", chain, strings.TrimPrefix(version, "op-contracts/")))
		if err := writeArtifact(artifact, outputPath); err != nil {
			return fmt.Errorf("failed to write artifact: %w", err)
		}

		fmt.Printf("✅ Generated: %s\n", outputPath)
	}

	fmt.Printf("\n✨ All artifacts generated successfully!\n")
	fmt.Printf("\n📋 Next steps:\n")
	fmt.Printf("  1. Review the generated JSON files in %s\n", generateOutput)
	fmt.Printf("  2. Simulate: sops simulate %s --<chain>\n", strings.TrimPrefix(version, "op-contracts/"))
	fmt.Printf("  3. Sign: sops sign %s --<chain>\n", strings.TrimPrefix(version, "op-contracts/"))

	return nil
}

func generateArtifact(
	reg *registry.Registry,
	network, chain, version, opcmAddress, commitHash string,
) (*SigningArtifact, error) {
	// Load chain config from registry
	chainConfig, err := reg.LoadChainConfig(network, chain)
	if err != nil {
		return nil, fmt.Errorf("failed to load chain config: %w", err)
	}

	// Determine prestate type based on chain configuration
	prestateType, err := reg.DeterminePrestateType(network, chain)
	if err != nil {
		return nil, fmt.Errorf("failed to determine prestate type: %w", err)
	}
	fmt.Printf("  Prestate type: %s\n", prestateType)

	// Get prestate for this version
	// Strip "op-contracts/" prefix and get op-node version (simplified mapping)
	nodeVersion := mapContractVersionToNodeVersion(version)
	prestate, err := reg.GetPrestate(nodeVersion, prestateType)
	if err != nil {
		return nil, fmt.Errorf("failed to get prestate: %w", err)
	}

	// Get ProxyAdmin address from extra/addresses/addresses.json
	proxyAdmin, err := reg.GetProxyAdmin(chainConfig.ChainID)
	if err != nil {
		fmt.Printf("  ⚠️  Warning: Failed to get ProxyAdmin: %v\n", err)
		fmt.Println("     Using zero address - you'll need to manually update the artifact")
		proxyAdmin = "0x0000000000000000000000000000000000000000"
	} else {
		fmt.Printf("  ProxyAdmin: %s\n", proxyAdmin)

		// Try to get and display ProxyAdminOwner immediately
		rpcURL := config.GetRPCURL(network, generateRPC)
		if rpcURL != "" {
			ctx := context.Background()
			nonceManager, err := safe.NewNonceManager(rpcURL)
			if err == nil {
				proxyAdminAddr := common.HexToAddress(proxyAdmin)
				ownerAddr, err := getOwner(ctx, nonceManager, proxyAdminAddr)
				nonceManager.Close()
				if err == nil {
					label := getSafeLabel(ownerAddr.Hex(), network)
					if label != "" {
						fmt.Printf("    └─ ProxyAdminOwner: %s (%s)\n", ownerAddr.Hex(), label)
					} else {
						fmt.Printf("    └─ ProxyAdminOwner: %s\n", ownerAddr.Hex())
					}
				}
			}
		}
	}

	// Generate calldata using cast for proper ABI encoding
	fmt.Println("  Generating calldata...")
	opcmUpgradeCalldata, err := generateOPCMUpgradeCalldata(
		opcmAddress,
		chainConfig.Addresses.SystemConfigProxy,
		proxyAdmin,
		prestate,
	)
	if err != nil {
		return nil, fmt.Errorf("failed to generate OPCM upgrade calldata: %w", err)
	}

	multicall3Calldata, err := generateMulticall3Calldata(opcmAddress, opcmUpgradeCalldata)
	if err != nil {
		return nil, fmt.Errorf("failed to generate multicall3 calldata: %w", err)
	}

	// Get RPC URL with fallback to defaults
	rpcURL := config.GetRPCURL(network, generateRPC)

	// Discover nested Safe chain and calculate hashes if RPC is available
	var safeHashes map[string]SafeHashes
	if rpcURL != "" {
		fmt.Printf("  Discovering nested Safe chain from ProxyAdmin...\n")
		safeChain, owner, err := discoverNestedSafes(rpcURL, proxyAdmin)
		if err != nil {
			fmt.Printf("  ⚠️  Warning: Failed to discover Safe chain: %v\n", err)
		} else {
			fmt.Printf("  ✅ Discovered %d Safes in chain\n", len(safeChain))
			for i, safeAddr := range safeChain {
				label := getSafeLabel(safeAddr.Hex(), network)
				if label != "" {
					fmt.Printf("    [%d] %s (%s)\n", i, safeAddr.Hex(), label)
				} else {
					fmt.Printf("    [%d] %s\n", i, safeAddr.Hex())
				}
			}
		}

		// Check if ProxyAdminOwner is a Safe and build list for nonce wizard
		var proxyAdminOwnerAddr common.Address
		var isProxyAdminOwnerSafe bool
		var allSafes []common.Address

		if owner != "" {
			proxyAdminOwnerAddr = common.HexToAddress(owner)
			// Check if ProxyAdminOwner is a Safe
			ctx := context.Background()
			nonceManager, err := safe.NewNonceManager(rpcURL)
			if err == nil {
				_, checkErr := nonceManager.GetSafeInfo(ctx, proxyAdminOwnerAddr)
				nonceManager.Close()
				if checkErr == nil {
					// It's a Safe, include it in the wizard
					isProxyAdminOwnerSafe = true
					allSafes = append(allSafes, proxyAdminOwnerAddr)
				}
			}
		}
		allSafes = append(allSafes, safeChain...)

		if len(allSafes) > 0 {
			// Run nonce wizard to allow manual nonce override
			var proxyAdminOwnerForWizard *common.Address
			if isProxyAdminOwnerSafe {
				proxyAdminOwnerForWizard = &proxyAdminOwnerAddr
			}
			nonceOverrides, err := runNonceWizard(rpcURL, allSafes, network, proxyAdminOwnerForWizard)
			if err != nil {
				return nil, fmt.Errorf("nonce wizard failed: %w", err)
			}

			fmt.Println("  Calculating hashes for discovered Safes...")
			safeHashes, err = calculateSafeHashesForAddresses(
				rpcURL,
				safeChain,
				chainConfig.ChainID,
				multicall3Calldata,
				network,
				nonceOverrides,
				isProxyAdminOwnerSafe,
				proxyAdminOwnerAddr,
			)
			if err != nil {
				fmt.Printf("  ⚠️  Warning: Failed to calculate Safe hashes: %v\n", err)
				fmt.Println("     Hashes will need to be calculated at signing time")
				safeHashes = nil
			} else {
				fmt.Printf("  ✅ Calculated hashes for %d Safes\n", len(safeHashes))
			}
		}
	} else {
		fmt.Println("  ℹ️  No RPC available, skipping Safe discovery and hash calculation")
		fmt.Println("     Hashes will be calculated at signing time")
	}

	artifact := &SigningArtifact{
		Chain:      chainConfig.Name,
		ChainID:    chainConfig.ChainID,
		Version:    version,
		CommitHash: commitHash,
		Timestamp:  time.Now().UTC().Format(time.RFC3339),
		OPCM:       opcmAddress,
		Calldata: CalldataInfo{
			OPCMUpgrade: opcmUpgradeCalldata,
			Multicall3:  multicall3Calldata,
		},
		Hashes: HashInfo{
			DomainHash:  "0x", // Populated per-Safe in Safes map
			MessageHash: "0x", // Populated per-Safe in Safes map
			Safes:       safeHashes,
		},
		TenderlySimulation: TenderlyInfo{
			URL:            "", // Will be populated after simulation
			StateOverrides: make(map[string]interface{}),
		},
		OpChainConfig: OpChainConfigInfo{
			SystemConfigProxy: chainConfig.Addresses.SystemConfigProxy,
			ProxyAdmin:        proxyAdmin,
			AbsolutePrestate:  prestate,
		},
	}

	return artifact, nil
}

func generateOPCMUpgradeCalldata(opcmAddress, systemConfigProxy, proxyAdmin, absolutePrestate string) (string, error) {
	// Use cast to properly ABI-encode the upgrade call
	// Function signature: upgrade((address,address,bytes32)[])
	// The tuple contains: (SystemConfigProxy, ProxyAdmin, AbsolutePrestate)

	upgradeTuple := fmt.Sprintf("[(%s,%s,%s)]", systemConfigProxy, proxyAdmin, absolutePrestate)
	cmd := exec.Command("cast", "calldata", "upgrade((address,address,bytes32)[])", upgradeTuple)

	output, err := cmd.Output()
	if err != nil {
		return "", fmt.Errorf("cast calldata failed: %w", err)
	}

	calldata := strings.TrimSpace(string(output))
	if calldata == "" || !strings.HasPrefix(calldata, "0x") {
		return "", fmt.Errorf("invalid calldata generated: %s", calldata)
	}

	return calldata, nil
}

func generateMulticall3Calldata(opcmAddress, opcmUpgradeCalldata string) (string, error) {
	// Generate Multicall3DelegateCall.aggregate3 calldata
	// This batches the OPCM upgrade call into a single multicall transaction

	// Multicall3.Call3 struct:
	// struct Call3 {
	//     address target;
	//     bool allowFailure;
	//     bytes callData;
	// }

	// Build the Call3 struct as a tuple: (address,bool,bytes)
	call3Tuple := fmt.Sprintf("[(%s,false,%s)]", opcmAddress, opcmUpgradeCalldata)

	// Encode aggregate3((address,bool,bytes)[])
	cmd := exec.Command("cast", "calldata", "aggregate3((address,bool,bytes)[])", call3Tuple)

	output, err := cmd.Output()
	if err != nil {
		// If multicall3 encoding fails, return empty - it's optional
		return "0x", nil
	}

	calldata := strings.TrimSpace(string(output))
	if calldata == "" || !strings.HasPrefix(calldata, "0x") {
		return "0x", nil
	}

	return calldata, nil
}

func getCommitHashFromTag(version string) (string, error) {
	// Get the monorepo path
	monorepoPath := filepath.Join("..", "lib", "optimism")

	// Fetch tags to ensure we have the latest
	fetchCmd := exec.Command("git", "fetch", "--tags", "origin")
	fetchCmd.Dir = monorepoPath
	if err := fetchCmd.Run(); err != nil {
		// Continue even if fetch fails - tag might already exist locally
		fmt.Printf("   Warning: Failed to fetch tags: %v\n", err)
	}

	// Get the commit hash for the tag
	// The tag name matches the version exactly (e.g., "op-contracts/v3.0.0")
	cmd := exec.Command("git", "rev-list", "-n", "1", version)
	cmd.Dir = monorepoPath

	output, err := cmd.Output()
	if err != nil {
		return "", fmt.Errorf("tag %s not found in monorepo: %w\nMake sure the tag exists in lib/optimism", version, err)
	}

	commitHash := strings.TrimSpace(string(output))
	if commitHash == "" {
		return "", fmt.Errorf("empty commit hash for tag %s", version)
	}

	return commitHash, nil
}

func mapContractVersionToNodeVersion(contractVersion string) string {
	// Map op-contracts version to op-node version
	// This is a simplified mapping - real implementation should use a proper mapping table
	mapping := map[string]string{
		"op-contracts/v4.0.0":    "1.6.0",
		"op-contracts/v3.0.0":    "1.5.0",
		"op-contracts/v2.2.0":    "1.4.1",
		"op-contracts/v2.0.0":    "1.4.0",
		"op-contracts/v1.8.0":    "1.3.1",
		"op-contracts/v1.6.0":    "1.3.0",
	}

	if nodeVersion, ok := mapping[contractVersion]; ok {
		return nodeVersion
	}

	// Default fallback
	return "1.6.0"
}

func writeArtifact(artifact *SigningArtifact, outputPath string) error {
	data, err := json.MarshalIndent(artifact, "", "  ")
	if err != nil {
		return fmt.Errorf("failed to marshal artifact: %w", err)
	}

	if err := os.WriteFile(outputPath, data, 0644); err != nil {
		return fmt.Errorf("failed to write file: %w", err)
	}

	return nil
}

// discoverNestedSafes discovers the chain of nested Safes starting from ProxyAdmin
// Returns: (discovered Safes, ProxyAdminOwner address, error)
func discoverNestedSafes(rpcURL, proxyAdminAddr string) ([]common.Address, string, error) {
	ctx := context.Background()

	// Create nonce manager for RPC access
	nonceManager, err := safe.NewNonceManager(rpcURL)
	if err != nil {
		return nil, "", fmt.Errorf("failed to create RPC client: %w", err)
	}
	defer nonceManager.Close()

	// Get ProxyAdmin's owner
	proxyAdminOwner, err := getOwner(ctx, nonceManager, common.HexToAddress(proxyAdminAddr))
	if err != nil {
		return nil, "", fmt.Errorf("failed to get ProxyAdmin owner: %w", err)
	}

	// Check if ProxyAdmin's owner is a Safe
	rootOwners, err := getSafeOwners(ctx, nonceManager, proxyAdminOwner)
	if err != nil {
		// ProxyAdmin's owner is not a Safe (EOA or regular contract), no nested multisigs
		return nil, proxyAdminOwner.Hex(), nil
	}

	// Discover all nested Safes recursively from the root Safe's owners
	// We skip the root Safe (ProxyAdminOwner) and only return its Safe owners
	allSafes := discoverSafesRecursive(ctx, nonceManager, rootOwners, make(map[common.Address]bool))

	// Return the nested Safes and the ProxyAdminOwner address
	return allSafes, proxyAdminOwner.Hex(), nil
}

// discoverSafesRecursive recursively discovers all Safes in a set of addresses
// RULE: If a Safe has any EOA owner, we skip ALL of its owners (including other Safes)
func discoverSafesRecursive(ctx context.Context, nm *safe.NonceManager, addresses []common.Address, visited map[common.Address]bool) []common.Address {
	var safes []common.Address

	for _, addr := range addresses {
		// Skip if already visited (cycle prevention)
		if visited[addr] {
			continue
		}
		visited[addr] = true

		// Check if this address is a Safe
		owners, err := getSafeOwners(ctx, nm, addr)
		if err != nil {
			// Not a Safe (EOA or regular contract)
			continue
		}

		// It's a Safe! Add it to the list
		safes = append(safes, addr)

		// Check if this Safe has any EOA owners
		hasEOA := false
		for _, owner := range owners {
			// Try to call getOwners() on the owner
			_, err := getSafeOwners(ctx, nm, owner)
			if err != nil {
				// This owner is not a Safe (it's an EOA or regular contract)
				hasEOA = true
				break
			}
		}

		// If this Safe has any EOA owner, skip ALL of its owners
		if hasEOA {
			continue
		}

		// All owners are Safes - recursively discover them
		nestedSafes := discoverSafesRecursive(ctx, nm, owners, visited)
		safes = append(safes, nestedSafes...)
	}

	return safes
}

// getOwner calls owner() on a contract
func getOwner(ctx context.Context, nm *safe.NonceManager, addr common.Address) (common.Address, error) {
	// owner() function signature: 0x8da5cb5b
	ownerSig := common.Hex2Bytes("8da5cb5b")

	result, err := nm.CallContract(ctx, addr, ownerSig)
	if err != nil {
		return common.Address{}, err
	}

	if len(result) < 32 {
		return common.Address{}, fmt.Errorf("invalid owner() result length")
	}

	return common.BytesToAddress(result[12:32]), nil
}

// getSafeOwners retrieves the list of owners for a Safe
func getSafeOwners(ctx context.Context, nm *safe.NonceManager, safeAddr common.Address) ([]common.Address, error) {
	// getOwners() function signature: 0xa0e67e2b
	getOwnersSig := common.Hex2Bytes("a0e67e2b")

	result, err := nm.CallContract(ctx, safeAddr, getOwnersSig)
	if err != nil {
		return nil, err
	}

	// Parse ABI-encoded address array
	// Format: offset(32) + length(32) + addresses(32*n)
	if len(result) < 64 {
		return nil, fmt.Errorf("invalid getOwners() result length")
	}

	// Get array length
	length := new(big.Int).SetBytes(result[32:64]).Uint64()
	if length == 0 {
		return nil, nil
	}

	// Sanity check: prevent panic from invalid length
	if length > 1000 {
		return nil, fmt.Errorf("unreasonable number of owners: %d", length)
	}

	owners := make([]common.Address, 0, length)
	for i := uint64(0); i < length; i++ {
		offset := 64 + (i * 32)
		if offset+32 > uint64(len(result)) {
			break
		}
		addr := common.BytesToAddress(result[offset+12 : offset+32])
		owners = append(owners, addr)
	}

	return owners, nil
}

// runNonceWizard presents an interactive wizard to adjust Safe nonces
func runNonceWizard(rpcURL string, safeAddresses []common.Address, network string, proxyAdminOwner *common.Address) (map[common.Address]*big.Int, error) {
	ctx := context.Background()

	// Create nonce manager to query current nonces
	nonceManager, err := safe.NewNonceManager(rpcURL)
	if err != nil {
		return nil, fmt.Errorf("failed to create RPC client: %w", err)
	}
	defer nonceManager.Close()

	nonceOverrides := make(map[common.Address]*big.Int)

	fmt.Println("\n📝 Nonce Configuration Wizard")
	fmt.Println("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

	for i, safeAddr := range safeAddresses {
		// Get current nonce from RPC
		safeInfo, err := nonceManager.GetSafeInfo(ctx, safeAddr)
		if err != nil {
			fmt.Printf("⚠️  Failed to get nonce for Safe %d: %v\n", i, err)
			continue
		}

		// Get Safe label if available, or check if it's ProxyAdminOwner
		var safeName string
		if proxyAdminOwner != nil && safeAddr == *proxyAdminOwner {
			safeName = "ProxyAdminOwner"
			label := getSafeLabel(safeAddr.Hex(), network)
			if label != "" {
				safeName = fmt.Sprintf("ProxyAdminOwner (%s)", label)
			}
		} else {
			label := getSafeLabel(safeAddr.Hex(), network)
			safeName = label
			if safeName == "" {
				safeName = safeAddr.Hex()
			}
		}

		fmt.Printf("\n[%d] %s\n", i, safeName)
		fmt.Printf("    Address: %s\n", safeAddr.Hex())
		fmt.Printf("    Current nonce: %s\n", safeInfo.Nonce.String())
		fmt.Print("    Change nonce? (y/N): ")

		var response string
		fmt.Scanln(&response)
		response = strings.TrimSpace(strings.ToLower(response))

		if response == "y" || response == "yes" {
			fmt.Print("    Enter new nonce: ")
			var nonceStr string
			fmt.Scanln(&nonceStr)
			nonceStr = strings.TrimSpace(nonceStr)

			newNonce, ok := new(big.Int).SetString(nonceStr, 10)
			if !ok {
				fmt.Printf("    ⚠️  Invalid nonce '%s', keeping current nonce %s\n", nonceStr, safeInfo.Nonce.String())
			} else {
				nonceOverrides[safeAddr] = newNonce
				fmt.Printf("    ✅ Nonce set to %s (was %s)\n", newNonce.String(), safeInfo.Nonce.String())
			}
		} else {
			fmt.Printf("    ✅ Using current nonce: %s\n", safeInfo.Nonce.String())
		}
	}

	fmt.Println("\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
	if len(nonceOverrides) > 0 {
		fmt.Printf("✅ %d nonce override(s) configured\n", len(nonceOverrides))
	} else {
		fmt.Println("✅ Using current nonces for all Safes")
	}
	fmt.Println()

	return nonceOverrides, nil
}

func calculateSafeHashesForAddresses(
	rpcURL string,
	safeAddresses []common.Address,
	chainID uint64,
	multicall3Calldata string,
	network string,
	nonceOverrides map[common.Address]*big.Int,
	includeProxyAdminOwner bool,
	proxyAdminOwner common.Address,
) (map[string]SafeHashes, error) {
	ctx := context.Background()

	// Create nonce manager
	nonceManager, err := safe.NewNonceManager(rpcURL)
	if err != nil {
		return nil, fmt.Errorf("failed to create nonce manager: %w", err)
	}
	defer nonceManager.Close()

	// Multicall3DelegateCall address (constant across chains)
	multicall3Address := common.HexToAddress("0xcA11bde05977b3631167028862bE2a173976CA11")

	result := make(map[string]SafeHashes)

	// Add ProxyAdminOwner if it's a Safe (nonce only, no hashes)
	if includeProxyAdminOwner {
		var nonce *big.Int
		if overrideNonce, hasOverride := nonceOverrides[proxyAdminOwner]; hasOverride {
			nonce = overrideNonce
		} else {
			// Get current nonce from RPC
			safeInfo, err := nonceManager.GetSafeInfo(ctx, proxyAdminOwner)
			if err != nil {
				fmt.Printf("    ⚠️  Failed to get info for ProxyAdminOwner: %v\n", err)
			} else {
				nonce = safeInfo.Nonce
			}
		}

		if nonce != nil {
			result["proxyadminowner"] = SafeHashes{
				Address:     proxyAdminOwner.Hex(),
				Nonce:       nonce.String(),
				DomainHash:  "", // No hash calculation for ProxyAdminOwner
				MessageHash: "", // No hash calculation for ProxyAdminOwner
			}
		}
	}

	// Process nested Safes (with full hash calculation)
	for depth, safeAddr := range safeAddresses {
		// Determine nonce to use (override or current)
		var nonce *big.Int
		if overrideNonce, hasOverride := nonceOverrides[safeAddr]; hasOverride {
			nonce = overrideNonce
		} else {
			// Get current nonce from RPC
			safeInfo, err := nonceManager.GetSafeInfo(ctx, safeAddr)
			if err != nil {
				fmt.Printf("    ⚠️  Failed to get info for Safe at depth %d: %v\n", depth, err)
				continue
			}
			nonce = safeInfo.Nonce
		}

		// Calculate EIP-712 domain hash
		domainHash := calculateDomainHash(safeAddr, chainID)

		// Calculate message hash
		messageHash := calculateMessageHash(
			domainHash,
			multicall3Address,
			multicall3Calldata,
			nonce,
		)

		// Use label as key if available, otherwise use safe-N
		label := getSafeLabel(safeAddr.Hex(), network)
		var safeName string
		if label != "" {
			// Normalize label for use as JSON key (replace spaces with hyphens, lowercase)
			safeName = strings.ToLower(strings.ReplaceAll(label, " ", "-"))
		} else {
			// Fallback to safe-0, safe-1, etc.
			safeName = fmt.Sprintf("safe-%d", depth)
		}

		result[safeName] = SafeHashes{
			Address:     safeAddr.Hex(),
			Nonce:       nonce.String(),
			DomainHash:  domainHash,
			MessageHash: messageHash,
		}
	}

	return result, nil
}

// calculateDomainHash computes the EIP-712 domain separator for a Safe
func calculateDomainHash(safeAddr common.Address, chainID uint64) string {
	// EIP-712 Domain for Gnosis Safe
	// keccak256("EIP712Domain(uint256 chainId,address verifyingContract)")
	domainTypeHash := crypto.Keccak256Hash([]byte("EIP712Domain(uint256 chainId,address verifyingContract)"))

	// Encode: domainTypeHash || chainId || safeAddress
	encoded := make([]byte, 0, 96)
	encoded = append(encoded, domainTypeHash.Bytes()...)

	chainIDBytes := make([]byte, 32)
	new(big.Int).SetUint64(chainID).FillBytes(chainIDBytes)
	encoded = append(encoded, chainIDBytes...)

	safeAddrBytes := make([]byte, 32)
	copy(safeAddrBytes[12:], safeAddr.Bytes())
	encoded = append(encoded, safeAddrBytes...)

	domainSeparator := crypto.Keccak256Hash(encoded)
	return domainSeparator.Hex()
}

// calculateMessageHash computes the Safe transaction hash
func calculateMessageHash(domainHash string, to common.Address, data string, nonce *big.Int) string {
	// Safe transaction typehash
	// keccak256("SafeTx(address to,uint256 value,bytes data,uint8 operation,uint256 safeTxGas,uint256 baseGas,uint256 gasPrice,address gasToken,address refundReceiver,uint256 nonce)")
	safeTxTypeHash := crypto.Keccak256Hash([]byte("SafeTx(address to,uint256 value,bytes data,uint8 operation,uint256 safeTxGas,uint256 baseGas,uint256 gasPrice,address gasToken,address refundReceiver,uint256 nonce)"))

	// Decode calldata
	dataBytes := common.FromHex(data)
	dataHash := crypto.Keccak256Hash(dataBytes)

	// Encode Safe transaction
	// SafeTx(to, value=0, data, operation=1 (delegatecall), safeTxGas=0, baseGas=0, gasPrice=0, gasToken=0, refundReceiver=0, nonce)
	encoded := make([]byte, 0, 320)
	encoded = append(encoded, safeTxTypeHash.Bytes()...)

	// to address (32 bytes)
	toBytes := make([]byte, 32)
	copy(toBytes[12:], to.Bytes())
	encoded = append(encoded, toBytes...)

	// value (32 bytes) - always 0
	encoded = append(encoded, make([]byte, 32)...)

	// data hash (32 bytes)
	encoded = append(encoded, dataHash.Bytes()...)

	// operation (32 bytes) - 1 for delegatecall
	opBytes := make([]byte, 32)
	opBytes[31] = 1
	encoded = append(encoded, opBytes...)

	// safeTxGas (32 bytes) - 0
	encoded = append(encoded, make([]byte, 32)...)

	// baseGas (32 bytes) - 0
	encoded = append(encoded, make([]byte, 32)...)

	// gasPrice (32 bytes) - 0
	encoded = append(encoded, make([]byte, 32)...)

	// gasToken (32 bytes) - 0x0
	encoded = append(encoded, make([]byte, 32)...)

	// refundReceiver (32 bytes) - 0x0
	encoded = append(encoded, make([]byte, 32)...)

	// nonce (32 bytes)
	nonceBytes := make([]byte, 32)
	nonce.FillBytes(nonceBytes)
	encoded = append(encoded, nonceBytes...)

	safeTxHash := crypto.Keccak256Hash(encoded)

	// Final EIP-712 hash: keccak256("\x19\x01" || domainSeparator || safeTxHash)
	domainBytes := common.FromHex(domainHash)
	finalEncoded := make([]byte, 0, 66)
	finalEncoded = append(finalEncoded, 0x19, 0x01)
	finalEncoded = append(finalEncoded, domainBytes...)
	finalEncoded = append(finalEncoded, safeTxHash.Bytes()...)

	messageHash := crypto.Keccak256Hash(finalEncoded)
	return messageHash.Hex()
}

func updateRegistrySubmodule(registryPath string) error {
	// Check if this is a git submodule
	gitDir := filepath.Join(registryPath, ".git")
	if _, err := os.Stat(gitDir); err != nil {
		return fmt.Errorf("not a git repository")
	}

	// Fetch latest changes
	fetchCmd := exec.Command("git", "fetch", "origin")
	fetchCmd.Dir = registryPath
	if output, err := fetchCmd.CombinedOutput(); err != nil {
		return fmt.Errorf("git fetch failed: %w\nOutput: %s", err, string(output))
	}

	// Get the default branch (usually main or master)
	defaultBranchCmd := exec.Command("git", "rev-parse", "--abbrev-ref", "origin/HEAD")
	defaultBranchCmd.Dir = registryPath
	defaultBranchOutput, err := defaultBranchCmd.Output()
	if err != nil {
		// Fallback to main if we can't determine the default branch
		defaultBranchOutput = []byte("origin/main")
	}
	defaultBranch := strings.TrimSpace(string(defaultBranchOutput))
	defaultBranch = strings.TrimPrefix(defaultBranch, "origin/")

	// Pull latest from default branch
	pullCmd := exec.Command("git", "pull", "origin", defaultBranch)
	pullCmd.Dir = registryPath
	if output, err := pullCmd.CombinedOutput(); err != nil {
		return fmt.Errorf("git pull failed: %w\nOutput: %s", err, string(output))
	}

	return nil
}
