package safe

import (
	"context"
	"fmt"
	"math/big"

	"github.com/ethereum/go-ethereum"
	"github.com/ethereum/go-ethereum/accounts/abi/bind"
	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/ethclient"
)

// SafeInfo represents information about a Gnosis Safe
type SafeInfo struct {
	Address   common.Address
	Nonce     *big.Int
	Threshold *big.Int
	Owners    []common.Address
}

// NonceManager handles Safe nonce coordination
type NonceManager struct {
	client *ethclient.Client
}

// NewNonceManager creates a new nonce manager
func NewNonceManager(rpcURL string) (*NonceManager, error) {
	client, err := ethclient.Dial(rpcURL)
	if err != nil {
		return nil, fmt.Errorf("failed to connect to RPC: %w", err)
	}

	return &NonceManager{
		client: client,
	}, nil
}

// GetSafeNonce queries the current nonce for a Safe
func (nm *NonceManager) GetSafeNonce(ctx context.Context, safeAddr common.Address) (*big.Int, error) {
	// Storage slot 5 contains the nonce for Gnosis Safe v1.3.0+
	nonceSlot := common.BigToHash(big.NewInt(5))

	nonce, err := nm.client.StorageAt(ctx, safeAddr, nonceSlot, nil)
	if err != nil {
		return nil, fmt.Errorf("failed to get nonce from storage: %w", err)
	}

	return new(big.Int).SetBytes(nonce), nil
}

// GetSafeInfo retrieves comprehensive information about a Safe
func (nm *NonceManager) GetSafeInfo(ctx context.Context, safeAddr common.Address) (*SafeInfo, error) {
	nonce, err := nm.GetSafeNonce(ctx, safeAddr)
	if err != nil {
		return nil, err
	}

	// Storage slot 4 contains the threshold
	thresholdSlot := common.BigToHash(big.NewInt(4))
	thresholdBytes, err := nm.client.StorageAt(ctx, safeAddr, thresholdSlot, nil)
	if err != nil {
		return nil, fmt.Errorf("failed to get threshold: %w", err)
	}
	threshold := new(big.Int).SetBytes(thresholdBytes)

	// Storage slot 3 contains the owner count
	ownerCountSlot := common.BigToHash(big.NewInt(3))
	ownerCountBytes, err := nm.client.StorageAt(ctx, safeAddr, ownerCountSlot, nil)
	if err != nil {
		return nil, fmt.Errorf("failed to get owner count: %w", err)
	}
	ownerCount := new(big.Int).SetBytes(ownerCountBytes)

	// TODO: Implement owner iteration from linked list
	// For now, return basic info
	owners := make([]common.Address, 0, ownerCount.Int64())

	return &SafeInfo{
		Address:   safeAddr,
		Nonce:     nonce,
		Threshold: threshold,
		Owners:    owners,
	}, nil
}

// CallContract makes a contract call
func (nm *NonceManager) CallContract(ctx context.Context, to common.Address, data []byte) ([]byte, error) {
	msg := ethereum.CallMsg{
		To:   &to,
		Data: data,
	}
	return nm.client.CallContract(ctx, msg, nil)
}

// Close closes the RPC connection
func (nm *NonceManager) Close() {
	if nm.client != nil {
		nm.client.Close()
	}
}

// WellKnownSafes contains addresses of known safes on different networks
var WellKnownSafes = map[string]map[string]common.Address{
	"mainnet": {
		"security-council":      common.HexToAddress("0xc2819DC788505Aac350142A7A707BF9D03E3Bd03"),
		"foundation-upgrade":    common.HexToAddress("0x847B5c174615B1B7fDF770882256e2D3E95b9D92"),
		"foundation-operations": common.HexToAddress("0x9BA6e03D8B90dE867373Db8cF1A58d2F7F006b3A"),
		"base-operations":       common.HexToAddress("0x9855054731540A48b28990B63DcF4f33d8AE46A1"),
		"uni-operations":        common.HexToAddress("0xb0c4C487C5cf6d67807Bc2008c66fa7e2cE744EC"),
		"l1-proxy-admin-owner":  common.HexToAddress("0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A"),
		"base-l1-proxy-admin":   common.HexToAddress("0x7bB41C3008B3f03FE483B28b8DB90e19Cf07595c"),
		"uni-l1-proxy-admin":    common.HexToAddress("0x6d5B183F538ABB8572F5cD17109c617b994D5833"),
	},
	"sepolia": {
		"fake-security-council":   common.HexToAddress("0xf64bc17485f0B4Ea5F06A96514182FC4cB561977"),
		"fake-foundation-upgrade": common.HexToAddress("0xDEe57160aAfCF04c34C887B5962D0a69676d3C8B"),
		"fake-l1-proxy-admin":     common.HexToAddress("0x1Eb2fFc903729a0F03966B917003800b145F56E2"),
	},
}

// GetSafeAddress resolves a safe name to an address
func GetSafeAddress(network, safeName string) (common.Address, error) {
	networkSafes, ok := WellKnownSafes[network]
	if !ok {
		return common.Address{}, fmt.Errorf("unknown network: %s", network)
	}

	safeAddr, ok := networkSafes[safeName]
	if !ok {
		return common.Address{}, fmt.Errorf("unknown safe: %s on network %s", safeName, network)
	}

	return safeAddr, nil
}

// GenerateStateOverrides generates state overrides for simulation
func GenerateStateOverrides(safeAddr common.Address, nonce *big.Int, makeSingleOwner bool) map[string]interface{} {
	overrides := make(map[string]interface{})
	stateDiff := make(map[string]string)

	// Set nonce (slot 5)
	nonceSlot := fmt.Sprintf("0x%064x", 5)
	nonceValue := fmt.Sprintf("0x%064x", nonce)
	stateDiff[nonceSlot] = nonceValue

	if makeSingleOwner {
		// Set threshold to 1 (slot 4)
		thresholdSlot := fmt.Sprintf("0x%064x", 4)
		stateDiff[thresholdSlot] = "0x0000000000000000000000000000000000000000000000000000000000000001"

		// Set owner count to 1 (slot 3)
		ownerCountSlot := fmt.Sprintf("0x%064x", 3)
		stateDiff[ownerCountSlot] = "0x0000000000000000000000000000000000000000000000000000000000000001"

		// Set Multicall3 as sole owner in the linked list (slot 2 mapping)
		// owners[1] = 0xca11bde05977b3631167028862be2a173976ca11
		multicall3 := common.HexToAddress("0xcA11bde05977b3631167028862bE2a173976CA11")
		slot1Key := "0xe90b7bceb6e7df5418fb78d8ee546e97c83a08bbccc01a0644d599ccd2a7c2e0"
		stateDiff[slot1Key] = fmt.Sprintf("0x000000000000000000000000%s", multicall3.Hex()[2:])

		// owners[multicall3] = 1
		multicall3Key := "0x316a0aac0d94f5824f0b66f5bbe94a8c360a17699a1d3a233aafcf7146e9f11c"
		stateDiff[multicall3Key] = "0x0000000000000000000000000000000000000000000000000000000000000001"
	}

	overrides[safeAddr.Hex()] = map[string]interface{}{
		"stateDiff": stateDiff,
	}

	return overrides
}

// Multicall3 address (same on mainnet and most L1s)
var Multicall3Address = common.HexToAddress("0xcA11bde05977b3631167028862bE2a173976CA11")

// Multicall3DelegateCall address for OPCM tasks
var Multicall3DelegateCallAddress = common.HexToAddress("0x93dc480940585D9961bfcEab58124fFD3d60f76a")

// GetMulticallAddress returns the appropriate multicall address for a task type
func GetMulticallAddress(isOPCMTask bool) common.Address {
	if isOPCMTask {
		return Multicall3DelegateCallAddress
	}
	return Multicall3Address
}

var _ bind.ContractBackend = (*ethclient.Client)(nil)
