package main

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"bufio"

	"github.com/BurntSushi/toml"
	"github.com/spf13/cobra"
)

// Result represents a search result
type Result struct {
	ChainType  string
	ChainName  string
	FieldName  string
	Address    string
	FilePath   string
	LineNumber int // Added line number
}

// Configuration
const (
	repoBasePath   = "lib/superchain-registry"
	configsPath    = repoBasePath + "/superchain/configs"
	validationPath = repoBasePath + "/validation/standard"
	repoURL        = "https://github.com/ethereum-optimism/superchain-registry"
)

// Paths to search in
var searchPaths = []string{configsPath, validationPath}

var rootCmd = &cobra.Command{
	Use:   "op-whois",
	Short: "Search for Ethereum addresses in superchain config files",
}

var guessCmd = &cobra.Command{
	Use:   "guess [address]",
	Short: "Guess the chain and field for an address",
	Args:  cobra.ExactArgs(1),
	Run: func(cmd *cobra.Command, args []string) {
		address := strings.ToLower(args[0])
		results := searchAddress(address)
		if len(results) > 0 {
			result := results[0] // Take the first match
			fmt.Printf("%s %s %s\n", result.ChainType, result.ChainName, result.FieldName)
		} else {
			fmt.Println("Address not found in any config file")
		}
	},
}

var linkCmd = &cobra.Command{
	Use:   "link [address]",
	Short: "Generate a markdown link for an address",
	Args:  cobra.ExactArgs(1),
	Run: func(cmd *cobra.Command, args []string) {
		address := strings.ToLower(args[0])
		results := searchAddress(address)
		if len(results) > 0 {
			result := results[0] // Take the first match

			// Get the current commit hash of the repository
			commitHash := getRepoCommitHash()

			// Create the GitHub URL with the commit hash
			// Remove the lib/superchain-registry prefix from the file path
			relPath := strings.TrimPrefix(result.FilePath, repoBasePath+"/")

			repoPath := fmt.Sprintf("%s/blob/%s/%s", repoURL, commitHash, relPath)

			// Add line number if available
			if result.LineNumber > 0 {
				repoPath = fmt.Sprintf("%s#L%d", repoPath, result.LineNumber)
			}

			// Format the output with markdown code blocks for the address
			fmt.Printf("[`%s`](%s)\n", result.Address, repoPath)
		} else {
			fmt.Println("Address not found in any config file")
		}
	},
}

var reverseCmd = &cobra.Command{
	Use:   "reverse [chain-type] [chain-name] [field-name]",
	Short: "Find an address by chain type, chain name, and field name",
	Args:  cobra.MinimumNArgs(1),
	Run: func(cmd *cobra.Command, args []string) {
		// Handle different input formats
		var chainType, chainName, fieldName string

		if len(args) == 1 {
			// Input format: "mainnet Metal L2 SystemConfigProxy"
			parts := strings.SplitN(args[0], " ", 3)
			if len(parts) == 3 {
				chainType = parts[0]
				chainName = parts[1]
				fieldName = parts[2]
			} else {
				fmt.Println("Invalid input format. Expected: 'chain-type chain-name field-name'")
				return
			}
		} else if len(args) >= 3 {
			// Input format: mainnet "Metal L2" SystemConfigProxy
			chainType = args[0]
			chainName = args[1]
			fieldName = args[2]
		} else {
			fmt.Println("Invalid number of arguments")
			return
		}

		// Search for the matching field
		result := searchByField(chainType, chainName, fieldName)
		if result != nil {
			fmt.Println(result.Address)
		} else {
			fmt.Printf("No address found for %s %s %s\n", chainType, chainName, fieldName)
		}
	},
}

func init() {
	rootCmd.AddCommand(guessCmd)
	rootCmd.AddCommand(linkCmd)
	rootCmd.AddCommand(reverseCmd)
}

// getRepoCommitHash returns the current commit hash of the superchain-registry repo
func getRepoCommitHash() string {
	// Default to "main" if we can't get the commit hash
	defaultHash := "main"

	// Change to the repository directory
	cmd := exec.Command("git", "-C", repoBasePath, "rev-parse", "HEAD")
	output, err := cmd.Output()
	if err != nil {
		fmt.Fprintf(os.Stderr, "Warning: Failed to get commit hash: %v\n", err)
		return defaultHash
	}

	commitHash := strings.TrimSpace(string(output))
	if commitHash == "" {
		return defaultHash
	}

	return commitHash
}

// findLineNumber finds the line number where the field and address appear in the file
func findLineNumber(filePath, fieldName, address string) int {
	file, err := os.Open(filePath)
	if err != nil {
		return 0
	}
	defer file.Close()

	scanner := bufio.NewScanner(file)
	lineNum := 0

	// For addresses section, we look for the format: FieldName = "address"
	fieldPattern := fmt.Sprintf("%s = \"%s\"", fieldName, address)

	// For roles section, we also check another common format
	rolePattern := fmt.Sprintf("%s = \"%s\"", fieldName, address)

	for scanner.Scan() {
		lineNum++
		line := scanner.Text()

		// Check if the line contains the field and address
		if strings.Contains(line, fieldPattern) || strings.Contains(line, rolePattern) {
			return lineNum
		}
	}

	return 0
}

// extractPathInfo extracts chain type and name from the file path
func extractPathInfo(path string) (string, string) {
	parts := strings.Split(path, "/")
	if len(parts) < 2 {
		return "", ""
	}

	fileName := parts[len(parts)-1]
	chainName := strings.TrimSuffix(fileName, ".toml")
	
	// For config files in the standard paths, extract chain type from filename
	if strings.Contains(path, "/validation/standard/") {
		// Handle validation directory special naming
		if strings.HasPrefix(fileName, "standard-config-roles-") {
			chainType := strings.TrimSuffix(strings.TrimPrefix(fileName, "standard-config-roles-"), ".toml")
			return chainType, "Standard Config Roles"
		} else if strings.HasPrefix(fileName, "standard-config-params-") {
			chainType := strings.TrimSuffix(strings.TrimPrefix(fileName, "standard-config-params-"), ".toml")
			return chainType, "Standard Config Params"
		} else if strings.HasPrefix(fileName, "standard-versions-") {
			chainType := strings.TrimSuffix(strings.TrimPrefix(fileName, "standard-versions-"), ".toml")
			return chainType, "Standard Versions"
		} else {
			// Generic handling for other files
			return "standard", chainName
		}
	} else if strings.Contains(path, "/superchain/configs/") {
		// Handle the regular config path
		if len(parts) >= 4 {
			return parts[len(parts)-2], chainName
		}
	}
	
	return "", chainName
}

func searchByField(targetChainType, targetChainName, targetFieldName string) *Result {
	// Convert inputs to lowercase for case-insensitive comparison
	targetChainType = strings.ToLower(targetChainType)
	targetChainName = strings.ToLower(targetChainName)
	targetFieldName = strings.ToLower(targetFieldName)
	
	var foundResult *Result

	// Search in all defined paths
	for _, basePath := range searchPaths {
		err := filepath.Walk(basePath, func(path string, info os.FileInfo, err error) error {
			if err != nil {
				return err
			}

			if !info.IsDir() && strings.HasSuffix(path, ".toml") {
				// Extract chain type and name from the path
				chainType, chainName := extractPathInfo(path)
				
				// Skip if chain type doesn't match
				if chainType != "" && !strings.EqualFold(chainType, targetChainType) {
					return nil
				}
				
				// This is a TOML file
				var data map[string]interface{}
				content, err := os.ReadFile(path)
				if err != nil {
					return err
				}

				if _, err := toml.Decode(string(content), &data); err != nil {
					return err
				}
				
				// Update chain name if available in the TOML data
				if name, ok := data["name"].(string); ok && name != "" {
					chainName = name
				}
				
				// Check if chain name matches (case-insensitive)
				if chainName != "" && !strings.Contains(strings.ToLower(chainName), targetChainName) {
					return nil
				}
				
				// Recursive function to search for fields in nested maps
				var searchMap func(map[string]interface{}, string) (string, bool)
				searchMap = func(m map[string]interface{}, prefix string) (string, bool) {
					for k, v := range m {
						// Check if current key matches field name
						if strings.ToLower(k) == targetFieldName {
							if addrStr, ok := v.(string); ok {
								lineNumber := findLineNumber(path, k, addrStr)
								foundResult = &Result{
									ChainType:  chainType,
									ChainName:  chainName,
									FieldName:  k,
									Address:    addrStr,
									FilePath:   path,
									LineNumber: lineNumber,
								}
								return addrStr, true
							}
						}
						
						// Check nested maps
						if nestedMap, ok := v.(map[string]interface{}); ok {
							if addrStr, found := searchMap(nestedMap, prefix+k+"."); found {
								return addrStr, true
							}
						}
					}
					return "", false
				}
				
				// Search the TOML data
				if _, found := searchMap(data, ""); found {
					return filepath.SkipDir // Stop searching after finding a match
				}
			}
			return nil
		})

		if err != nil {
			fmt.Fprintf(os.Stderr, "Error searching for field: %v\n", err)
			continue
		}
		
		if foundResult != nil {
			break // Stop if we found a result
		}
	}

	return foundResult
}

func searchAddress(targetAddress string) []Result {
	targetAddress = strings.ToLower(targetAddress)
	var results []Result

	// Search in all defined paths
	for _, basePath := range searchPaths {
		err := filepath.Walk(basePath, func(path string, info os.FileInfo, err error) error {
			if err != nil {
				return err
			}

			if !info.IsDir() && strings.HasSuffix(path, ".toml") {
				// This is a TOML file
				var data map[string]interface{}
				content, err := os.ReadFile(path)
				if err != nil {
					return err
				}

				if _, err := toml.Decode(string(content), &data); err != nil {
					return err
				}

				// Extract chain type and name from the path
				chainType, chainName := extractPathInfo(path)
				
				// Update chain name if available in the TOML data
				if name, ok := data["name"].(string); ok && name != "" {
					chainName = name
				}

				// Recursive function to search for addresses in nested maps
				var searchAddressInMap func(map[string]interface{}, string)
				searchAddressInMap = func(m map[string]interface{}, prefix string) {
					for k, v := range m {
						if addrStr, ok := v.(string); ok && strings.ToLower(addrStr) == targetAddress {
							fieldName := prefix + k
							lineNumber := findLineNumber(path, k, addrStr)
							results = append(results, Result{
								ChainType:  chainType,
								ChainName:  chainName,
								FieldName:  fieldName,
								Address:    addrStr,
								FilePath:   path,
								LineNumber: lineNumber,
							})
						}
						
						// Check nested maps
						if nestedMap, ok := v.(map[string]interface{}); ok {
							searchAddressInMap(nestedMap, prefix+k+".")
						}
					}
				}
				
				// Search the TOML data
				searchAddressInMap(data, "")
			}
			return nil
		})

		if err != nil {
			fmt.Fprintf(os.Stderr, "Error searching for address in %s: %v\n", basePath, err)
			continue
		}
	}

	return results
}

func main() {
	if err := rootCmd.Execute(); err != nil {
		fmt.Println(err)
		os.Exit(1)
	}
}
