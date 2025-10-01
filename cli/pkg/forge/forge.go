package forge

import (
	"context"
	"encoding/json"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
)

// ForgeRunner handles execution of forge commands
type ForgeRunner struct {
	workingDir string
	rpcURL     string
	forkBlock  uint64
	verbose    bool
}

// NewForgeRunner creates a new forge runner
func NewForgeRunner(workingDir, rpcURL string) *ForgeRunner {
	return &ForgeRunner{
		workingDir: workingDir,
		rpcURL:     rpcURL,
	}
}

// SetVerbose enables verbose output
func (f *ForgeRunner) SetVerbose(v bool) {
	f.verbose = v
}

// SetForkBlock sets the block number to fork from
func (f *ForgeRunner) SetForkBlock(block uint64) {
	f.forkBlock = block
}

// RunScript executes a forge script with the given parameters
func (f *ForgeRunner) RunScript(ctx context.Context, scriptPath, sig string, args []string, stateOverrides map[string]interface{}) (string, error) {
	forgeArgs := []string{"script", scriptPath}

	if sig != "" {
		forgeArgs = append(forgeArgs, "--sig", sig)
	}

	// Add function arguments
	forgeArgs = append(forgeArgs, args...)

	// Add RPC URL
	if f.rpcURL != "" {
		forgeArgs = append(forgeArgs, "--fork-url", f.rpcURL)
	}

	// Add fork block if specified
	if f.forkBlock > 0 {
		forgeArgs = append(forgeArgs, "--fork-block-number", fmt.Sprintf("%d", f.forkBlock))
	}

	// Add state overrides if provided
	if len(stateOverrides) > 0 {
		overridesJSON, err := json.Marshal(stateOverrides)
		if err != nil {
			return "", fmt.Errorf("failed to marshal state overrides: %w", err)
		}

		// Write to temp file
		tmpFile, err := os.CreateTemp("", "state-overrides-*.json")
		if err != nil {
			return "", fmt.Errorf("failed to create temp file: %w", err)
		}
		defer os.Remove(tmpFile.Name())

		if _, err := tmpFile.Write(overridesJSON); err != nil {
			return "", fmt.Errorf("failed to write state overrides: %w", err)
		}
		tmpFile.Close()

		forgeArgs = append(forgeArgs, "--state-override", tmpFile.Name())
	}

	// Add verbosity
	if f.verbose {
		forgeArgs = append(forgeArgs, "-vvv")
	}

	// Enable FFI
	forgeArgs = append(forgeArgs, "--ffi")

	cmd := exec.CommandContext(ctx, "forge", forgeArgs...)
	cmd.Dir = f.workingDir

	// Set environment variables
	cmd.Env = append(os.Environ(),
		"FOUNDRY_PROFILE=default",
	)

	output, err := cmd.CombinedOutput()
	if err != nil {
		return string(output), fmt.Errorf("forge script failed: %w\nOutput: %s", err, string(output))
	}

	return string(output), nil
}

// Build runs forge build
func (f *ForgeRunner) Build(ctx context.Context) error {
	cmd := exec.CommandContext(ctx, "forge", "build")
	cmd.Dir = f.workingDir
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr

	if err := cmd.Run(); err != nil {
		return fmt.Errorf("forge build failed: %w", err)
	}

	return nil
}

// Test runs forge test
func (f *ForgeRunner) Test(ctx context.Context, matchPath string) error {
	args := []string{"test"}
	if matchPath != "" {
		args = append(args, "--match-path", matchPath)
	}

	if f.verbose {
		args = append(args, "-vvv")
	}

	cmd := exec.CommandContext(ctx, "forge", args...)
	cmd.Dir = f.workingDir
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr

	if err := cmd.Run(); err != nil {
		return fmt.Errorf("forge test failed: %w", err)
	}

	return nil
}

// ExtractTenderlyURL extracts Tenderly simulation URL from forge output
func ExtractTenderlyURL(output string) string {
	lines := strings.Split(output, "\n")
	for _, line := range lines {
		if strings.Contains(line, "tenderly.co") || strings.Contains(line, "dashboard.tenderly") {
			// Extract URL
			parts := strings.Fields(line)
			for _, part := range parts {
				if strings.HasPrefix(part, "http") {
					return part
				}
			}
		}
	}
	return ""
}

// ExtractHashes extracts domain and message hashes from forge output
func ExtractHashes(output string) (domainHash, messageHash string) {
	lines := strings.Split(output, "\n")
	for _, line := range lines {
		if strings.Contains(line, "Domain Hash:") || strings.Contains(line, "domain hash:") {
			parts := strings.Fields(line)
			for _, part := range parts {
				if strings.HasPrefix(part, "0x") && len(part) == 66 {
					domainHash = part
					break
				}
			}
		}
		if strings.Contains(line, "Message Hash:") || strings.Contains(line, "message hash:") {
			parts := strings.Fields(line)
			for _, part := range parts {
				if strings.HasPrefix(part, "0x") && len(part) == 66 {
					messageHash = part
					break
				}
			}
		}
	}
	return
}

// GetRepoRoot returns the git repository root
func GetRepoRoot() (string, error) {
	cmd := exec.Command("git", "rev-parse", "--show-toplevel")
	output, err := cmd.Output()
	if err != nil {
		return "", fmt.Errorf("failed to get repo root: %w", err)
	}

	return strings.TrimSpace(string(output)), nil
}

// GetTaskTemplatePath returns the path to a template
func GetTaskTemplatePath(templateName string) (string, error) {
	repoRoot, err := GetRepoRoot()
	if err != nil {
		return "", err
	}

	templatePath := filepath.Join(repoRoot, "src", "template", templateName+".sol")
	if _, err := os.Stat(templatePath); os.IsNotExist(err) {
		return "", fmt.Errorf("template not found: %s", templateName)
	}

	return templatePath, nil
}
