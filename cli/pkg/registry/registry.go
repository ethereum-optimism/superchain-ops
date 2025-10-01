package registry

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"

	"github.com/BurntSushi/toml"
)

// StandardVersions represents the standard-versions-mainnet.toml structure
type StandardVersions map[string]ContractVersions

// ContractVersions holds version info for all contracts in a release
type ContractVersions struct {
	SystemConfig                  *ContractVersion `toml:"system_config"`
	FaultDisputeGame              *ContractVersion `toml:"fault_dispute_game"`
	PermissionedDisputeGame       *ContractVersion `toml:"permissioned_dispute_game"`
	MIPS                          *ContractVersion `toml:"mips"`
	OptimismPortal                *ContractVersion `toml:"optimism_portal"`
	AnchorStateRegistry           *ContractVersion `toml:"anchor_state_registry"`
	DelayedWETH                   *ContractVersion `toml:"delayed_weth"`
	DisputeGameFactory            *ContractVersion `toml:"dispute_game_factory"`
	PreimageOracle                *ContractVersion `toml:"preimage_oracle"`
	L1CrossDomainMessenger        *ContractVersion `toml:"l1_cross_domain_messenger"`
	L1ERC721Bridge                *ContractVersion `toml:"l1_erc721_bridge"`
	L1StandardBridge              *ContractVersion `toml:"l1_standard_bridge"`
	OptimismMintableERC20Factory  *ContractVersion `toml:"optimism_mintable_erc20_factory"`
	OPContractsManager            *ContractVersion `toml:"op_contracts_manager"`
	SuperchainConfig              *ContractVersion `toml:"superchain_config"`
	ProtocolVersions              *ContractVersion `toml:"protocol_versions"`
	EthLockbox                    *ContractVersion `toml:"eth_lockbox"`
}

// ContractVersion holds version and address info for a contract
type ContractVersion struct {
	Version               string `toml:"version"`
	Address               string `toml:"address"`
	ImplementationAddress string `toml:"implementation_address"`
}

// Prestates represents the standard-prestates.toml structure
type Prestates struct {
	LatestStable string                          `toml:"latest_stable"`
	LatestRC     string                          `toml:"latest_rc"`
	Prestates    map[string][]PrestateDefinition `toml:"prestates"`
}

// PrestateDefinition holds a prestate hash for a specific type
type PrestateDefinition struct {
	Type string `toml:"type"`
	Hash string `toml:"hash"`
}

// ChainConfig represents a chain's TOML configuration
type ChainConfig struct {
	Name                 string               `toml:"name"`
	ChainID              uint64               `toml:"chain_id"`
	PublicRPC            string               `toml:"public_rpc"`
	SequencerRPC         string               `toml:"sequencer_rpc"`
	Explorer             string               `toml:"explorer"`
	SuperchainLevel      int                  `toml:"superchain_level"`
	GovernedByOptimism   bool                 `toml:"governed_by_optimism"`
	SuperchainTime       uint64               `toml:"superchain_time"`
	DataAvailabilityType string               `toml:"data_availability_type"`
	BatchInboxAddr       string               `toml:"batch_inbox_addr"`
	BlockTime            uint64               `toml:"block_time"`
	SeqWindowSize        uint64               `toml:"seq_window_size"`
	MaxSequencerDrift    uint64               `toml:"max_sequencer_drift"`
	Roles                ChainRoles           `toml:"roles"`
	Addresses            ChainAddresses       `toml:"addresses"`
	Hardforks            ChainHardforks       `toml:"hardforks"`
	Genesis              ChainGenesis         `toml:"genesis"`
	Optimism             ChainOptimismConfig  `toml:"optimism"`
}

// ChainRoles holds role addresses
type ChainRoles struct {
	SystemConfigOwner   string `toml:"SystemConfigOwner"`
	ProxyAdminOwner     string `toml:"ProxyAdminOwner"`
	Guardian            string `toml:"Guardian"`
	Challenger          string `toml:"Challenger"`
	Proposer            string `toml:"Proposer"`
	UnsafeBlockSigner   string `toml:"UnsafeBlockSigner"`
	BatchSubmitter      string `toml:"BatchSubmitter"`
}

// ChainAddresses holds deployed contract addresses
type ChainAddresses struct {
	AddressManager                    string `toml:"AddressManager"`
	L1CrossDomainMessengerProxy       string `toml:"L1CrossDomainMessengerProxy"`
	L1ERC721BridgeProxy               string `toml:"L1ERC721BridgeProxy"`
	L1StandardBridgeProxy             string `toml:"L1StandardBridgeProxy"`
	L2OutputOracleProxy               string `toml:"L2OutputOracleProxy"`
	OptimismMintableERC20FactoryProxy string `toml:"OptimismMintableERC20FactoryProxy"`
	OptimismPortalProxy               string `toml:"OptimismPortalProxy"`
	SystemConfigProxy                 string `toml:"SystemConfigProxy"`
	ProxyAdmin                        string `toml:"ProxyAdmin"`
	AnchorStateRegistryProxy          string `toml:"AnchorStateRegistryProxy"`
	DelayedWETHProxy                  string `toml:"DelayedWETHProxy"`
	DisputeGameFactoryProxy           string `toml:"DisputeGameFactoryProxy"`
	FaultDisputeGame                  string `toml:"FaultDisputeGame"`
	MIPS                              string `toml:"MIPS"`
	PermissionedDisputeGame           string `toml:"PermissionedDisputeGame"`
	PreimageOracle                    string `toml:"PreimageOracle"`
}

// ChainHardforks holds hardfork activation times
type ChainHardforks struct {
	CanyonTime   uint64 `toml:"canyon_time"`
	DeltaTime    uint64 `toml:"delta_time"`
	EcotoneTime  uint64 `toml:"ecotone_time"`
	FjordTime    uint64 `toml:"fjord_time"`
	GraniteTime  uint64 `toml:"granite_time"`
	HoloceneTime uint64 `toml:"holocene_time"`
	IsthmusTime  uint64 `toml:"isthmus_time"`
	InteropTime  uint64 `toml:"interop_time"`
}

// ChainGenesis holds genesis information
type ChainGenesis struct {
	L2Time       uint64                  `toml:"l2_time"`
	L1           GenesisL1               `toml:"l1"`
	L2           GenesisL2               `toml:"l2"`
	SystemConfig GenesisSystemConfig     `toml:"system_config"`
}

type GenesisL1 struct {
	Hash   string `toml:"hash"`
	Number uint64 `toml:"number"`
}

type GenesisL2 struct {
	Hash   string `toml:"hash"`
	Number uint64 `toml:"number"`
}

type GenesisSystemConfig struct {
	BatcherAddress string `toml:"batcherAddress"`
	Overhead       string `toml:"overhead"`
	Scalar         string `toml:"scalar"`
	GasLimit       uint64 `toml:"gasLimit"`
}

// ChainOptimismConfig holds Optimism-specific config
type ChainOptimismConfig struct {
	EIP1559Elasticity        uint64 `toml:"eip1559_elasticity"`
	EIP1559Denominator       uint64 `toml:"eip1559_denominator"`
	EIP1559DenominatorCanyon uint64 `toml:"eip1559_denominator_canyon"`
}

// Registry provides access to superchain-registry data
type Registry struct {
	basePath string
}

// NewRegistry creates a new registry instance
func NewRegistry(basePath string) *Registry {
	return &Registry{basePath: basePath}
}

// LoadStandardVersions loads the standard versions for a network
func (r *Registry) LoadStandardVersions(network string) (StandardVersions, error) {
	path := filepath.Join(r.basePath, "validation", "standard", fmt.Sprintf("standard-versions-%s.toml", network))

	var versions StandardVersions
	if _, err := toml.DecodeFile(path, &versions); err != nil {
		return nil, fmt.Errorf("failed to decode standard versions: %w", err)
	}

	return versions, nil
}

// LoadPrestates loads the prestate configurations
func (r *Registry) LoadPrestates() (*Prestates, error) {
	path := filepath.Join(r.basePath, "validation", "standard", "standard-prestates.toml")

	var prestates Prestates
	if _, err := toml.DecodeFile(path, &prestates); err != nil {
		return nil, fmt.Errorf("failed to decode prestates: %w", err)
	}

	return &prestates, nil
}

// LoadChainConfig loads a chain's configuration
func (r *Registry) LoadChainConfig(network, chain string) (*ChainConfig, error) {
	path := filepath.Join(r.basePath, "superchain", "configs", network, fmt.Sprintf("%s.toml", chain))

	var config ChainConfig
	if _, err := toml.DecodeFile(path, &config); err != nil {
		return nil, fmt.Errorf("failed to decode chain config: %w", err)
	}

	return &config, nil
}

// GetOPCMAddress returns the OPCM address for a given release
func (r *Registry) GetOPCMAddress(network, release string) (string, error) {
	versions, err := r.LoadStandardVersions(network)
	if err != nil {
		return "", err
	}

	contractVersions, ok := versions[release]
	if !ok {
		return "", fmt.Errorf("release %s not found in standard versions", release)
	}

	if contractVersions.OPContractsManager == nil {
		return "", fmt.Errorf("OPCM not defined for release %s", release)
	}

	if contractVersions.OPContractsManager.Address != "" {
		return contractVersions.OPContractsManager.Address, nil
	}

	return "", fmt.Errorf("OPCM address not set for release %s", release)
}

// GetPrestate returns the prestate hash for a given version and type
func (r *Registry) GetPrestate(version, prestateType string) (string, error) {
	prestates, err := r.LoadPrestates()
	if err != nil {
		return "", err
	}

	versionPrestates, ok := prestates.Prestates[version]
	if !ok {
		return "", fmt.Errorf("prestate version %s not found", version)
	}

	for _, p := range versionPrestates {
		if p.Type == prestateType {
			return p.Hash, nil
		}
	}

	return "", fmt.Errorf("prestate type %s not found for version %s", prestateType, version)
}

// DeterminePrestateType determines the prestate type for a chain based on its configuration
func (r *Registry) DeterminePrestateType(network, chain string) (string, error) {
	chainConfig, err := r.LoadChainConfig(network, chain)
	if err != nil {
		return "", err
	}

	// Check if interop is activated
	if chainConfig.Hardforks.InteropTime > 0 {
		// Note: In production, you might want to check if interop_time < current_time
		// For now, we assume if it's set and non-zero, interop is planned/active
		return "interop", nil
	}

	// Check MIPS address to determine cannon32 vs cannon64
	// If MIPS is deployed, it's likely cannon64 (MIPS64)
	// Modern chains use cannon64
	if chainConfig.Addresses.MIPS != "" {
		// Check if it's a known cannon64 MIPS address
		// MIPS 1.0.0+ indicates MIPS64 (cannon64)
		// For simplicity, assume any MIPS deployment is cannon64 unless it's a known cannon32 address
		return "cannon64", nil
	}

	// Default to cannon64 for modern chains
	// cannon32 is legacy and rarely used
	return "cannon64", nil
}

// GetProxyAdmin returns the ProxyAdmin address for a given chain ID
func (r *Registry) GetProxyAdmin(chainID uint64) (string, error) {
	addressesPath := filepath.Join(r.basePath, "superchain", "extra", "addresses", "addresses.json")

	data, err := os.ReadFile(addressesPath)
	if err != nil {
		return "", fmt.Errorf("failed to read addresses.json: %w", err)
	}

	var addresses map[string]map[string]string
	if err := json.Unmarshal(data, &addresses); err != nil {
		return "", fmt.Errorf("failed to parse addresses.json: %w", err)
	}

	chainIDStr := fmt.Sprintf("%d", chainID)
	chainAddresses, ok := addresses[chainIDStr]
	if !ok {
		return "", fmt.Errorf("chain ID %d not found in addresses.json", chainID)
	}

	proxyAdmin, ok := chainAddresses["ProxyAdmin"]
	if !ok {
		return "", fmt.Errorf("ProxyAdmin not found for chain ID %d", chainID)
	}

	return proxyAdmin, nil
}

// GetDefaultRegistryPath returns the default path to the superchain-registry
func GetDefaultRegistryPath() (string, error) {
	// Assume we're in superchain-ops/cli, registry is at ../../lib/superchain-registry
	cwd, err := os.Getwd()
	if err != nil {
		return "", err
	}

	// Try relative path from CLI directory
	registryPath := filepath.Join(cwd, "..", "lib", "superchain-registry")
	if _, err := os.Stat(registryPath); err == nil {
		return registryPath, nil
	}

	// Try from superchain-ops root
	registryPath = filepath.Join(cwd, "lib", "superchain-registry")
	if _, err := os.Stat(registryPath); err == nil {
		return registryPath, nil
	}

	return "", fmt.Errorf("could not find superchain-registry")
}
