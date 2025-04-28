package main

import (
	"encoding/json"
	"fmt"
	"os"
)

// --- JSON Structures ---

// Represents a value that might have a reference URL, variable name, note, or command.
// Used for address, key, and val within state diffs.
type JSONValueWithRef struct {
	Value     string `json:"value"`
	Reference string `json:"reference,omitempty"`
	Variable  string `json:"variable,omitempty"` // Specific to 'key'
	Note      string `json:"note,omitempty"`
	Command   string `json:"command,omitempty"` // Specific to 'key'
}

// Represents a single state diff from the JSON
type JSONStateDiff struct {
	Contract string           `json:"contract"`
	Address  JSONValueWithRef `json:"address"`
	Key      JSONValueWithRef `json:"key"`
	Val      JSONValueWithRef `json:"val"` // Note: JSON uses "val", Go struct uses "Val"
	Summary  string           `json:"summary"`
}

// Represents a single override (structure assumed similar to diffs for now)
type JSONOverride struct {
	Contract string           `json:"contract"`
	Address  JSONValueWithRef `json:"address"`
	Key      JSONValueWithRef `json:"key"`
	Val      JSONValueWithRef `json:"val"`
	Summary  string           `json:"summary"`
}

// Represents a component multisig in a nested structure
type MultisigComponent struct {
	Name    string `json:"name"`
	Address string `json:"address"`
}

// Represents the multisig section of the JSON
type JSONMultisig struct {
	Structure  string              `json:"structure"` // "single" or "nested"
	Components []MultisigComponent `json:"components"`
}

// Represents the overview section of the JSON
type JSONOverview struct {
	ID          string `json:"id"`
	Title       string `json:"title"`
	Chain       int    `json:"chain"`
	Description string `json:"description"`
	Governance  string `json:"governance,omitempty"` // Optional governance link
}

// Top-level structure matching the validation.json file
type ValidationData struct {
	Overview  JSONOverview    `json:"overview"`
	Multisig  JSONMultisig    `json:"multisig"`
	Overrides []JSONOverride  `json:"overrides"`
	Diffs     []JSONStateDiff `json:"diffs"`
}

// --- Data Loading ---

// loadValidationData reads and parses the specified JSON file.
func loadValidationData(filePath string) (ValidationData, error) {
	var data ValidationData

	// Read the file content
	bytes, err := os.ReadFile(filePath)
	if err != nil {
		return data, fmt.Errorf("failed to read validation file '%s': %w", filePath, err)
	}

	// Unmarshal the JSON
	err = json.Unmarshal(bytes, &data)
	if err != nil {
		return data, fmt.Errorf("failed to parse validation JSON from '%s': %w", filePath, err)
	}

	return data, nil
}

// Helper to format lists for display
func formatComponentList(items []MultisigComponent) string {
	var s string
	for _, item := range items {
		s += fmt.Sprintf("  - %s (%s)\n", item.Name, item.Address)
	}
	return s
}
