package main

import (
	"flag"
	"fmt"
	"os"
	"strings"
	"time"

	"github.com/gdamore/tcell/v2"
	"github.com/rivo/tview"
)

const (
	pageOverview     = "overview"
	pageMultisig     = "multisig"
	pageOverrides    = "overrides"
	pageStateDiffs   = "statediffs"
	pageFinalConfirm = "finalconfirm"
	pageSigning      = "signing"
	pageDone         = "done"
)

// Shared application state
type AppState struct {
	data             ValidationData
	currentItemIndex int
	signature        string
	pageHistory      []string // Add page history for back navigation
}

func main() {
	// --- Setup: Flags and Data Loading ---
	jsonPath := flag.String("json", "../tui/validation.json", "Path to the validation JSON file") // Adjust default path
	flag.Parse()

	appState := &AppState{
		pageHistory: []string{pageOverview}, // Initialize with the first page
	}
	var err error
	appState.data, err = loadValidationData(*jsonPath)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error loading validation data: %v\n", err)
		os.Exit(1)
	}

	// --- tview Application Setup ---
	app := tview.NewApplication()

	// --- Widgets Setup ---
	pages := tview.NewPages()
	infoBox := tview.NewTextView()
	infoBox.SetDynamicColors(true).
		SetBorder(true).
		SetTitle("Info")
	infoBox.SetText("Press Tab to switch focus, Space to confirm, Enter to continue. Press 'b' to go back. Press Ctrl+C to quit.")

	// --- Helper function for page navigation ---
	// Function to navigate to a page, tracking history
	navigateToPage := func(nextPage string) {
		currentPage, _ := pages.GetFrontPage()
		if currentPage != nextPage {
			appState.pageHistory = append(appState.pageHistory, nextPage)
			pages.SwitchToPage(nextPage)
			// Update info box with initial instruction
			infoBox.SetText("Press Tab to switch focus, Space to confirm, Enter to continue. Press 'b' to go back. Press Ctrl+C to quit.")
		}
	}

	// Function to go back to the previous page
	goBack := func() {
		// Need at least 2 items in history to go back
		if len(appState.pageHistory) > 1 {
			// Remove the current page from history
			appState.pageHistory = appState.pageHistory[:len(appState.pageHistory)-1]
			// Get the previous page
			previousPage := appState.pageHistory[len(appState.pageHistory)-1]
			pages.SwitchToPage(previousPage)
		}
	}

	// --- Page Creation Functions (using closures to capture appState) ---
	createTextViewPage := func(title, content string, nextPage string, wrapText bool) *tview.TextView {
		textView := tview.NewTextView().
			SetDynamicColors(true). // Enable tview's color tags
			SetScrollable(true).
			SetWrap(wrapText).
			SetText(content)

		// Remove the border and title from individual text views
		// as these will be contained in flex layouts with their own borders

		// When Enter is pressed, move to the next page
		textView.SetDoneFunc(func(key tcell.Key) {
			if key == tcell.KeyEnter {
				pages.SwitchToPage(nextPage)
			}
		})

		return textView
	}

	// Modify createListPage function to include a checkbox
	createListPageWithCheckbox := func(title string, items []string, isOverrides bool, nextPage string) *tview.Flex {
		textView := tview.NewTextView().
			SetDynamicColors(true).
			SetScrollable(true).
			SetWrap(false) // Disable wrap for list items initially
		textView.SetBorder(true).SetTitle(title)

		// Add checkbox in its own container
		checkboxLabel := "Confirm "
		checkbox := tview.NewCheckbox().
			SetLabel(checkboxLabel).
			SetChecked(false)

		// Create a container for the checkbox with padding
		checkboxContainer := tview.NewFlex().
			AddItem(checkbox, 0, 8, true).
			AddItem(nil, 0, 2, false)
		checkboxContainer.SetBorder(true).SetTitle("Confirmation")

		// Create parent flex for layout
		flex := tview.NewFlex().
			SetDirection(tview.FlexRow).
			AddItem(textView, 0, 1, true).
			AddItem(checkboxContainer, 3, 0, false)

		updateContent := func() {
			var content string
			if len(items) == 0 {
				if isOverrides {
					content = "No state overrides for this simulation."
				} else {
					content = "No state diffs detected in JSON."
				}
			} else {
				if appState.currentItemIndex >= 0 && appState.currentItemIndex < len(items) {
					itemType := "State Diff"
					if isOverrides {
						itemType = "Override"
					}
					content = fmt.Sprintf("[%s](fg:magenta,mod:bold)Item %d/%d:[-:-]\n%s",
						itemType,
						appState.currentItemIndex+1,
						len(items),
						items[appState.currentItemIndex])
				} else {
					// Should not happen if logic is correct
					content = "Invalid item index."
				}
			}
			textView.SetText(content).ScrollToBeginning()
			checkbox.SetChecked(false) // Reset checkbox when content changes
		}

		flex.SetInputCapture(func(event *tcell.EventKey) *tcell.EventKey {
			// Add Tab key to switch focus between text view and checkbox
			if event.Key() == tcell.KeyTab {
				// Get current focus and switch
				if app.GetFocus() == textView {
					app.SetFocus(checkbox)
				} else {
					app.SetFocus(textView)
				}
				return nil
			}
			if len(items) == 0 {
				if event.Key() == tcell.KeyEnter {
					navigateToPage(nextPage)
					return nil
				} else if event.Key() == tcell.KeyRune && event.Rune() == 'b' {
					goBack()
					return nil
				}
			} else {
				if event.Key() == tcell.KeyEnter {
					// Only proceed if checkbox is checked
					if checkbox.IsChecked() {
						appState.currentItemIndex++
						if appState.currentItemIndex >= len(items) {
							appState.currentItemIndex = 0 // Reset for next list page
							navigateToPage(nextPage)
						} else {
							updateContent()
						}
						return nil
					} else {
						infoBox.SetText("Please check the confirmation box to continue.")
						return nil
					}
				} else if event.Key() == tcell.KeyRune && event.Modifiers() == tcell.ModShift && event.Rune() == ' ' { // Shift+Enter equivalent
					// Only proceed if checkbox is checked
					if checkbox.IsChecked() {
						appState.currentItemIndex = 0 // Reset for next list page
						navigateToPage(nextPage)
						return nil
					} else {
						infoBox.SetText("Please check the confirmation box to continue.")
						return nil
					}
				} else if event.Key() == tcell.KeyRune && event.Rune() == 'b' {
					goBack()
					return nil
				}
			}
			return event
		})

		appState.currentItemIndex = 0 // Ensure index is reset when page is created
		updateContent()               // Initial content
		return flex
	}

	// --- Format Data for Views ---
	overviewContent := formatOverview(appState.data.Overview)
	multisigContent := formatMultisig(appState.data.Multisig)
	overrideItems := formatOverrides(appState.data.Overrides)
	diffItems := formatDiffs(appState.data.Diffs)
	finalConfirmContent := formatFinalConfirm()
	signingContent := "[::b]Interacting with hardware wallet...[-:-]\n\n(This is a simulation, no actual signing is happening yet.)"
	// doneContent needs signature, set later

	// --- Create Pages ---
	// Create the overview page with content and checkbox in separate boxes
	overviewText := createTextViewPage("", overviewContent, "", true)
	overviewText.SetBorder(true).SetTitle("Transaction Overview")

	// Put the checkbox in its own box
	overviewCheckbox := tview.NewCheckbox().
		SetLabel("Confirm ").
		SetChecked(false)
	checkboxContainer := tview.NewFlex().
		AddItem(overviewCheckbox, 0, 8, true).
		AddItem(nil, 0, 2, false)
	checkboxContainer.SetBorder(true).SetTitle("Confirmation")

	// Create a parent flex to hold both boxes
	overviewFlex := tview.NewFlex().
		SetDirection(tview.FlexRow).
		AddItem(overviewText, 0, 1, true).
		AddItem(checkboxContainer, 3, 0, false)

	// Update overviewFlex input handler with back navigation
	overviewFlex.SetInputCapture(func(event *tcell.EventKey) *tcell.EventKey {
		// Add Tab key to switch focus between text view and checkbox
		if event.Key() == tcell.KeyTab {
			if app.GetFocus() == overviewText {
				app.SetFocus(overviewCheckbox)
			} else {
				app.SetFocus(overviewText)
			}
			return nil
		}
		if event.Key() == tcell.KeyEnter {
			if overviewCheckbox.IsChecked() {
				navigateToPage(pageMultisig)
				return nil
			} else {
				infoBox.SetText("Please check the confirmation box to continue.")
				return nil
			}
		} else if event.Key() == tcell.KeyRune && event.Rune() == 'b' {
			goBack()
			return nil
		}
		return event
	})

	// Create the multisig page with content and checkbox in separate boxes
	multisigText := createTextViewPage("", multisigContent, "", false)
	multisigText.SetBorder(true).SetTitle("Multisig Information")

	// Put the checkbox in its own box
	multisigCheckbox := tview.NewCheckbox().
		SetLabel("Confirm ").
		SetChecked(false)
	multisigCheckboxContainer := tview.NewFlex().
		AddItem(multisigCheckbox, 0, 8, true).
		AddItem(nil, 0, 2, false)
	multisigCheckboxContainer.SetBorder(true).SetTitle("Confirmation")

	// Create a parent flex to hold both boxes
	multisigFlex := tview.NewFlex().
		SetDirection(tview.FlexRow).
		AddItem(multisigText, 0, 1, true).
		AddItem(multisigCheckboxContainer, 3, 0, false)

	// Update multisigFlex input handler with back navigation
	multisigFlex.SetInputCapture(func(event *tcell.EventKey) *tcell.EventKey {
		// Add Tab key to switch focus between text view and checkbox
		if event.Key() == tcell.KeyTab {
			if app.GetFocus() == multisigText {
				app.SetFocus(multisigCheckbox)
			} else {
				app.SetFocus(multisigText)
			}
			return nil
		}
		if event.Key() == tcell.KeyEnter {
			if multisigCheckbox.IsChecked() {
				navigateToPage(pageOverrides)
				return nil
			} else {
				infoBox.SetText("Please check the confirmation box to continue.")
				return nil
			}
		} else if event.Key() == tcell.KeyRune && event.Rune() == 'b' {
			goBack()
			return nil
		}
		return event
	})

	// Create the list pages with checkboxes
	overridesPage := createListPageWithCheckbox("State Overrides", overrideItems, true, pageStateDiffs)
	diffsPage := createListPageWithCheckbox("State Diffs", diffItems, false, pageFinalConfirm)

	// Special handling for signing page
	signingPage := tview.NewModal().
		SetText(signingContent).
		AddButtons([]string{"Cancel"}). // Only button is Cancel (or Ctrl+C)
		SetDoneFunc(func(buttonIndex int, buttonLabel string) {
			// If cancelled, maybe go back or quit? For now, just quit.
			app.Stop()
		})

	doneModal := tview.NewModal(). // Use a modal for the final message
					AddButtons([]string{"OK"}).
					SetDoneFunc(func(buttonIndex int, buttonLabel string) {
			app.Stop()
		})

	// Special handling for final confirmation page with checkbox
	finalConfirmText := createTextViewPage("", finalConfirmContent, "", true)
	finalConfirmText.SetBorder(true).SetTitle("Final Confirmation")

	// Add checkbox in its own box
	checkbox := tview.NewCheckbox().
		SetLabel("Confirm ").
		SetChecked(false)
	finalCheckboxContainer := tview.NewFlex().
		AddItem(checkbox, 0, 8, true).
		AddItem(nil, 0, 2, false)
	finalCheckboxContainer.SetBorder(true).SetTitle("Confirmation")

	// Create a flex layout for the final confirmation page
	finalConfirmFlex := tview.NewFlex().
		SetDirection(tview.FlexRow).
		AddItem(finalConfirmText, 0, 1, true).
		AddItem(finalCheckboxContainer, 3, 0, false)

	// Update finalConfirmFlex input handler with back navigation
	finalConfirmFlex.SetInputCapture(func(event *tcell.EventKey) *tcell.EventKey {
		// Add Tab key to switch focus between text view and checkbox
		if event.Key() == tcell.KeyTab {
			if app.GetFocus() == finalConfirmText {
				app.SetFocus(checkbox)
			} else {
				app.SetFocus(finalConfirmText)
			}
			return nil
		}
		if event.Key() == tcell.KeyEnter {
			// Only proceed if checkbox is checked
			if checkbox.IsChecked() {
				navigateToPage(pageSigning)
				return nil
			} else {
				// Update info box to indicate checkbox must be checked
				infoBox.SetText("Please check the confirmation box to continue.")
				return nil
			}
		} else if event.Key() == tcell.KeyRune && event.Rune() == 'b' {
			goBack()
			return nil
		}
		return event
	})

	// --- Add Pages to PageManager ---
	pages.AddPage(pageOverview, overviewFlex, true, true)
	pages.AddPage(pageMultisig, multisigFlex, true, false)
	pages.AddPage(pageOverrides, overridesPage, true, false)
	pages.AddPage(pageStateDiffs, diffsPage, true, false)
	pages.AddPage(pageFinalConfirm, finalConfirmFlex, true, false)
	pages.AddPage(pageSigning, signingPage, true, false)
	pages.AddPage(pageDone, doneModal, true, false)

	// --- Global Input Capture ---
	app.SetInputCapture(func(event *tcell.EventKey) *tcell.EventKey {
		currentPage, _ := pages.GetFrontPage()
		if currentPage == pageFinalConfirm {
			if event.Key() == tcell.KeyRune && event.Rune() == 's' {
				// Only proceed if checkbox is checked
				if checkbox.IsChecked() {
					navigateToPage(pageSigning)
					// Simulate signing and switch to done page
					go func() {
						time.Sleep(2 * time.Second) // Simulate signing delay
						appState.signature = "0xmockTviewSignature67890"
						doneText := fmt.Sprintf("Transaction signing process simulated successfully!\nSignature: %s", appState.signature)
						app.QueueUpdateDraw(func() { // Important: UI updates must be in the main goroutine
							doneModal.SetText(doneText)
							navigateToPage(pageDone)
						})
					}()
					return nil // Event handled
				} else {
					// Update info box to indicate checkbox must be checked
					infoBox.SetText("Please check the confirmation box to continue.")
					return nil
				}
			}
		} else if currentPage == pageDone {
			// Allow going back from the done page
			if event.Key() == tcell.KeyRune && event.Rune() == 'b' {
				goBack()
				return nil
			}
		}
		return event // Event not handled, pass through
	})

	// --- Layout ---
	// Use a Flex layout to put pages and the info box together
	flex := tview.NewFlex().SetDirection(tview.FlexRow).
		AddItem(pages, 0, 1, true).   // Pages take up most space, have focus
		AddItem(infoBox, 3, 0, false) // Info box is fixed size at the bottom

	// --- Run Application ---
	if err := app.SetRoot(flex, true).Run(); err != nil {
		panic(err)
	}
}

// --- Helper Functions for Formatting Content ---

// Formats the overview data into a string for tview.TextView
func formatOverview(o JSONOverview) string {
	govLinkLine := ""
	if o.Governance != "" {
		// Use tview's proper hyperlink format: [::URL]Text[::-]
		govLinkLine = fmt.Sprintf("\n\nGovernance Approval:\n[:::%s]Click here to validate[:::-]", o.Governance)
	}
	return fmt.Sprintf(
		"[%s::b]%s[-:-]\n\nTask ID: %s\nChain ID: %d\nTitle:\n%s\n\nDescription:\n%s%s",
		tview.Styles.TitleColor.String(), // Use tview's theme color
		"Transaction Overview",
		o.ID,
		o.Chain,
		o.Title,       // tview TextView handles wrapping
		o.Description, // tview TextView handles wrapping
		govLinkLine,   // Use the modified variable
	)
}

// Formats the multisig data
func formatMultisig(m JSONMultisig) string {
	return fmt.Sprintf(
		"[%s::b]%s[-:-]\n\nStructure Type: %s\nComponents:\n%s",
		tview.Styles.TitleColor.String(),
		"Multisig Information",
		m.Structure,
		formatComponentList(m.Components), // Uses helper from data.go
	)
}

// Formats a single ValueWithRef
func formatValueWithRef(label string, v JSONValueWithRef) string {
	var b strings.Builder
	b.WriteString(fmt.Sprintf("  %s: %s\n", label, v.Value))
	if v.Variable != "" {
		b.WriteString(fmt.Sprintf("    [::d]Variable: %s[::-]\n", v.Variable)) // Dim style
	}
	if v.Reference != "" {
		// Use tview link format: [URL]Text
		b.WriteString(fmt.Sprintf("    [::d]Reference: [%s]%s[::-]\n", v.Reference, v.Reference))
	}
	if v.Command != "" {
		b.WriteString(fmt.Sprintf("    [::d]Command: %s[::-]\n", v.Command))
	}
	if v.Note != "" {
		b.WriteString(fmt.Sprintf("    [::d]Note: %s[::-]\n", v.Note))
	}
	return b.String()
}

// Formats all overrides into a list of strings
func formatOverrides(overrides []JSONOverride) []string {
	items := make([]string, len(overrides))
	for i, o := range overrides {
		var b strings.Builder
		b.WriteString(fmt.Sprintf("Contract: %s\n", o.Contract))
		b.WriteString(formatValueWithRef("Address", o.Address))
		b.WriteString(formatValueWithRef("Key", o.Key))
		b.WriteString(formatValueWithRef("Value", o.Val))
		b.WriteString(fmt.Sprintf("Summary: %s\n", o.Summary))
		items[i] = b.String()
	}
	return items
}

// Formats all diffs into a list of strings
func formatDiffs(diffs []JSONStateDiff) []string {
	items := make([]string, len(diffs))
	for i, d := range diffs {
		var b strings.Builder
		b.WriteString(fmt.Sprintf("Contract: %s\n", d.Contract))
		b.WriteString(formatValueWithRef("Address", d.Address))
		b.WriteString(formatValueWithRef("Key", d.Key))
		b.WriteString(formatValueWithRef("Value", d.Val))
		b.WriteString(fmt.Sprintf("Summary: %s\n", d.Summary))
		items[i] = b.String()
	}
	return items
}

// Formats the final confirmation text
func formatFinalConfirm() string {
	return "[::b]Prepare your hardware wallet.[-:-]\n\n" +
		"You are about to sign the transaction.\n" +
		"Please confirm that you have:\n" +
		"  ✅ Verified the transaction details (Overview, Multisig).\n" +
		"  ✅ Understood the state overrides.\n" +
		"  ✅ Understood the state diffs.\n" +
		"  (Hash verification step omitted for now).\n\n" +
		"[::d]Check the box below and press Enter to continue...[::-]\n" +
		"[::d]Press Ctrl+C to abort.[-:-]"
}
