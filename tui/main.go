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

	// Set global theme colors
	tview.Styles.PrimitiveBackgroundColor = tcell.ColorBlack
	tview.Styles.ContrastBackgroundColor = tcell.ColorBlack
	tview.Styles.PrimaryTextColor = tcell.ColorWhite
	tview.Styles.SecondaryTextColor = tcell.ColorWhite
	tview.Styles.TitleColor = tcell.ColorWhite

	// --- Widgets Setup ---
	pages := tview.NewPages()
	infoBox := tview.NewTextView()
	infoBox.SetDynamicColors(true).
		SetBorder(true).
		SetTitle("Info")
	infoBox.SetText("Press Tab to switch focus, Space to confirm, Enter to continue. Press 'b' to go back. Press Ctrl+C to quit.")
	infoBox.SetTextColor(tcell.ColorWhite)

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
			SetWrap(!isOverrides) // Enable wrapping for diffs (when isOverrides is false)
		textView.SetBorder(true).SetTitle(title)
		textView.SetTextColor(tcell.ColorWhite)

		// For storing the base title without item index
		baseTitle := title
		if len(items) > 0 && strings.Contains(title, " (") {
			baseTitle = title[:strings.Index(title, " (")]
		}

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
					content = "There are no state overrides for this simulation."
				} else {
					content = "There are no state diffs for this transaction."
				}
			} else {
				if appState.currentItemIndex >= 0 && appState.currentItemIndex < len(items) {
					// Update the title to reflect the current index
					newTitle := baseTitle
					if len(items) > 0 {
						newTitle += fmt.Sprintf(" (%d/%d)", appState.currentItemIndex+1, len(items))
					}
					textView.SetTitle(newTitle)

					content = fmt.Sprintf("%s", items[appState.currentItemIndex])
				} else {
					// Should not happen if logic is correct
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
	overviewText.SetTextColor(tcell.ColorWhite)

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
	multisigText := createTextViewPage("", multisigContent, "", true)
	multisigText.SetBorder(true).SetTitle("Multisig Information")
	multisigText.SetTextColor(tcell.ColorWhite)

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
	overridesTitle := "State Overrides"
	if len(overrideItems) > 0 {
		overridesTitle += fmt.Sprintf(" (1/%d)", len(overrideItems))
	}
	overridesPage := createListPageWithCheckbox(overridesTitle, overrideItems, true, pageStateDiffs)

	// State diffs
	diffsTitle := "State Changes"
	if len(diffItems) > 0 {
		diffsTitle += fmt.Sprintf(" (1/%d)", len(diffItems))
	}
	diffsPage := createStepByStepDiffPage(app, pages, appState, infoBox, diffsTitle, appState.data.Diffs, pageFinalConfirm, navigateToPage, goBack)

	// Special handling for signing page
	signingPage := tview.NewModal().
		SetText(signingContent).
		AddButtons([]string{"Cancel"}). // Only button is Cancel (or Ctrl+C)
		SetDoneFunc(func(buttonIndex int, buttonLabel string) {
			// If cancelled, maybe go back or quit? For now, just quit.
			app.Stop()
		})
	signingPage.SetTextColor(tcell.ColorWhite)

	doneModal := tview.NewModal(). // Use a modal for the final message
					AddButtons([]string{"OK"}).
					SetDoneFunc(func(buttonIndex int, buttonLabel string) {
			app.Stop()
		})
	doneModal.SetTextColor(tcell.ColorWhite)

	// Special handling for final confirmation page with checkbox
	finalConfirmText := createTextViewPage("", finalConfirmContent, "", true)
	finalConfirmText.SetBorder(true).SetTitle("Final Confirmation")
	finalConfirmText.SetTextColor(tcell.ColorWhite)

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
		govLinkLine = fmt.Sprintf("\n\n[:::%s]Click here to view the Optimism Governance approval of this transaction[:::-]", o.Governance)
	}
	return fmt.Sprintf(
		"[::b]Task ID:[-:-] %s\n[::b]Chain ID:[-:-] %d\n\n[yellow::b]%s[-:-::-]\n\n%s%s",
		o.ID,
		o.Chain,
		o.Title,       // Display title directly as a heading
		o.Description, // Show description as a paragraph
		govLinkLine,   // Modified governance link text
	)
}

// Formats the multisig data
func formatMultisig(m JSONMultisig) string {
	// Start with a narrative description of what the user is signing
	description := fmt.Sprintf(
		"[#ffffff]You are signing a transaction that will be executed by the [#ffff00]%s[-:-:-] ([#ff0000]%s[-:-:-]).[white:-:-]\n\n",
		m.Name,
		m.Address,
	)

	// Explain what type of multisig it is and what that means
	if m.Structure == "nested" {
		description += "[#ffffff]This is a [#ffffff::b]nested[-:-:-] multisig. This means that one or more multisigs need to approve this transaction before it can be executed.[white:-:-]\n\n"
		description += "[#ffffff::b]This nested multisig is composed of these child multisigs:[white:-:-]\n\n"
	} else {
		description += "[#ffffff]This is a [#ffffff::b]single[-:-:-] multisig. This means that this transaction can be executed as soon as enough signatures are collected from signers on this multisig.[white:-:-]\n\n"
	}

	// Add the components if it's a nested multisig
	if m.Structure == "nested" {
		description += formatComponentList(m.Components)
	}

	return description
}

// Formats a single ValueWithRef
func formatValueWithRef(label string, v JSONValueWithRef) string {
	var b strings.Builder
	b.WriteString(fmt.Sprintf("  [::b]%s:[-:-] %s\n", label, v.Value))
	if v.Variable != "" {
		b.WriteString(fmt.Sprintf("    [::d]Variable:[-:-] %s\n", v.Variable)) // Dim style
	}
	if v.Reference != "" {
		// Use tview link format: [URL]Text
		b.WriteString(fmt.Sprintf("    [::d]Reference:[-:-] [%s]%s\n", v.Reference, v.Reference))
	}
	if v.Command != "" {
		b.WriteString(fmt.Sprintf("    [::d]Command:[-:-] %s\n", v.Command))
	}
	if v.Note != "" {
		b.WriteString(fmt.Sprintf("    [::d]Note:[-:-] %s\n", v.Note))
	}
	return b.String()
}

// Formats all overrides into a list of strings
func formatOverrides(overrides []JSONOverride) []string {
	items := make([]string, len(overrides))
	for i, o := range overrides {
		var b strings.Builder
		b.WriteString(fmt.Sprintf("[::b]Contract:[-:-] %s\n", o.Contract))
		b.WriteString(formatValueWithRef("Address", o.Address))
		b.WriteString(formatValueWithRef("Key", o.Key))
		b.WriteString(formatValueWithRef("Value", o.Val))
		b.WriteString(fmt.Sprintf("[::b]Summary:[-:-] %s\n", o.Summary))
		items[i] = b.String()
	}
	return items
}

// Formats all diffs into a list of strings
func formatDiffs(diffs []JSONStateDiff) []string {
	items := make([]string, len(diffs))
	for i, d := range diffs {
		var b strings.Builder

		// Opening paragraph about the contract
		b.WriteString(fmt.Sprintf("[#ffffff]This is a diff in the [#ffff00]%s[white:-:-] contract ([#ff0000]%s[white:-:-]).\n",
			d.Contract, d.Address.Value))

		// Clickable reference for address verification - use proper hyperlink format
		if d.Address.Reference != "" {
			b.WriteString(fmt.Sprintf("[::u][:::%s]You can verify the address of this contract by clicking here.[:::-][::-]\n\n",
				d.Address.Reference))
		}

		// Summary of what's happening
		b.WriteString(fmt.Sprintf("[#ffffff]%s[white:-:-]\n\n", d.Summary))

		// Storage slot info
		b.WriteString(fmt.Sprintf("[#ffffff]The storage slot being modified is [#ff0000]%s[white:-:-]", d.Key.Value))

		// Variable name if available
		if d.Key.Variable != "" {
			b.WriteString(fmt.Sprintf(" and corresponds to the [#ffff00]%s[white:-:-] variable", d.Key.Variable))
		}
		b.WriteString(".\n\n")

		// Key reference for verification - use proper hyperlink format
		if d.Key.Reference != "" {
			b.WriteString(fmt.Sprintf("[::u][:::%s]You can verify this storage slot by clicking here.[:::-][::-]\n",
				d.Key.Reference))
		}

		// Command for verification if available
		if d.Key.Command != "" {
			b.WriteString(fmt.Sprintf("[::u][#8888ff]You can run this command to verify this storage slot is computed correctly:[white:-:-][::-]\n[#8888ff]%s[white:-:-]\n\n",
				d.Key.Command))
		}

		// Value information
		b.WriteString(fmt.Sprintf("[#ffffff]This storage slot is being set to the following value: [#ff0000]%s[white:-:-]\n\n", d.Val.Value))

		// Value reference if available - use proper hyperlink format
		if d.Val.Reference != "" {
			b.WriteString(fmt.Sprintf("[::u][:::%s]You can verify this value by clicking here.[:::-][::-]\n",
				d.Val.Reference))
		}

		// Additional notes if available
		if d.Val.Note != "" {
			b.WriteString(fmt.Sprintf("[#ffffff]Note: %s[white:-:-]\n", d.Val.Note))
		}

		items[i] = b.String()
	}
	return items
}

// Formats the final confirmation text
func formatFinalConfirm() string {
	return "[::b]Prepare your hardware wallet[-:-]\n\n" +
		"You are about to sign the transaction.\n" +
		"Please confirm that you have:\n\n" +
		"  [green]✅[-:-] Verified the transaction details (Overview, Multisig).\n" +
		"  [green]✅[-:-] Understood the state overrides.\n" +
		"  [green]✅[-:-] Understood the state diffs.\n" +
		"  (Hash verification step omitted for now).\n\n" +
		"[yellow]Check the box below and press Enter to continue...[-:-]\n" +
		"[gray]Press Ctrl+C to abort.[-:-]"
}

// Helper to format lists for display
func formatComponentList(items []MultisigComponent) string {
	var s string
	for _, item := range items {
		s += fmt.Sprintf("  • [#ffff00]%s[white:-:-]\n    [#ff0000]%s[white:-:-]\n\n", item.Name, item.Address)
	}
	return s
}

// Function to create a step-by-step state diff page
func createStepByStepDiffPage(
	app *tview.Application,
	pages *tview.Pages,
	appState *AppState,
	infoBox *tview.TextView,
	title string,
	diffs []JSONStateDiff,
	nextPage string,
	navigateToPage func(string),
	goBack func(),
) *tview.Flex {
	// Main flex container for the whole page
	mainFlex := tview.NewFlex().SetDirection(tview.FlexRow)

	// Content area for the current step
	contentView := tview.NewTextView().
		SetDynamicColors(true).
		SetScrollable(true).
		SetWrap(true)
	contentView.SetBorder(true).SetTitle(title)
	contentView.SetTextColor(tcell.ColorWhite)

	// Confirmation checkbox
	checkbox := tview.NewCheckbox().
		SetLabel("Confirm ").
		SetChecked(false)

	// Create container for checkbox
	checkboxContainer := tview.NewFlex().
		AddItem(checkbox, 0, 8, true).
		AddItem(nil, 0, 2, false)
	checkboxContainer.SetBorder(true).SetTitle("Confirmation")

	// Add components to the main flex
	mainFlex.AddItem(contentView, 0, 1, true).
		AddItem(checkboxContainer, 3, 0, false)

	// Current state tracking
	currentDiffIndex := 0
	currentStep := 0

	// Define the steps for each diff
	const (
		stepExplanation = 0
		stepAddress     = 1
		stepKey         = 2
		stepValue       = 3
		stepTenderly    = 4
		stepCount       = 5
	)

	// Function to update content based on current diff and step
	updateContent := func() {
		// Reset checkbox for each new step
		checkbox.SetChecked(false)

		// If no diffs, show a message and allow skipping
		if len(diffs) == 0 {
			contentView.SetText("There are no state diffs for this transaction.")
			return
		}

		// Get current diff
		diff := diffs[currentDiffIndex]

		// Update title
		newTitle := fmt.Sprintf("%s (%d/%d) - Step %d/%d",
			"State Changes", currentDiffIndex+1, len(diffs), currentStep+1, stepCount)
		contentView.SetTitle(newTitle)

		var content strings.Builder

		// Add consistent header for all steps
		content.WriteString(fmt.Sprintf("[#ffffff::b]Verification for State Diff %d of %d[white:-:-]\n\n",
			currentDiffIndex+1, len(diffs)))

		// Add context header for all steps
		content.WriteString(fmt.Sprintf("[#ffffff::b]Contract:[white:-:-] [#ffff00]%s[white:-:-] ([#ff0000]%s[white:-:-])\n",
			diff.Contract, diff.Address.Value))
		content.WriteString(fmt.Sprintf("[#ffffff::b]Summary:[white:-:-] %s\n\n", diff.Summary))

		// Generate content based on the current step
		switch currentStep {
		case stepExplanation:
			content.WriteString(fmt.Sprintf("[#ffffff::b]Step %d/%d: Explanation[white:-:-]\n\n",
				currentStep+1, stepCount))

			// Just show a simple explanation without technical details
			content.WriteString(fmt.Sprintf("[#ffffff]%s[white:-:-]\n\n", diff.Summary))

			content.WriteString("[yellow]Please confirm that you understand what this state diff is doing.[white]\n")

		case stepAddress:
			content.WriteString(fmt.Sprintf("[#ffffff::b]Step %d/%d: Contract Address Validation[white:-:-]\n\n",
				currentStep+1, stepCount))
			content.WriteString(fmt.Sprintf("[#ffffff]Address: [#ff0000]%s[white:-:-]\n\n", diff.Address.Value))

			if diff.Address.Reference != "" {
				content.WriteString(fmt.Sprintf("[::u][:::%s]Click here to verify the contract address.[:::-][::-]\n\n", diff.Address.Reference))
			}

			content.WriteString("[yellow]Please confirm that you have validated the contract address.[white]\n")

		case stepKey:
			content.WriteString(fmt.Sprintf("[#ffffff::b]Step %d/%d: Storage Key Validation[white:-:-]\n\n",
				currentStep+1, stepCount))
			content.WriteString(fmt.Sprintf("[#ffffff]The storage slot being modified is: [#ff0000]%s[white:-:-]\n", diff.Key.Value))

			if diff.Key.Variable != "" {
				content.WriteString(fmt.Sprintf("[#ffffff]This corresponds to the [#ffff00]%s[white:-:-] variable.\n\n", diff.Key.Variable))
			}

			if diff.Key.Reference != "" {
				content.WriteString(fmt.Sprintf("[::u][:::%s]Click here to verify this storage slot.[:::-][::-]\n\n", diff.Key.Reference))
			}

			if diff.Key.Command != "" {
				content.WriteString(fmt.Sprintf("[#8888ff]Run this command to verify the storage slot:[white:-:-]\n[#8888ff]%s[white:-:-]\n\n", diff.Key.Command))
			}

			content.WriteString("[yellow]Please confirm that you have validated the storage key.[white]\n")

		case stepValue:
			content.WriteString(fmt.Sprintf("[#ffffff::b]Step %d/%d: New Value Validation[white:-:-]\n\n",
				currentStep+1, stepCount))
			content.WriteString(fmt.Sprintf("[#ffffff]The storage slot will be set to: [#ff0000]%s[white:-:-]\n\n", diff.Val.Value))

			if diff.Val.Reference != "" {
				content.WriteString(fmt.Sprintf("[::u][:::%s]Click here to verify this value.[:::-][::-]\n\n", diff.Val.Reference))
			}

			if diff.Val.Note != "" {
				content.WriteString(fmt.Sprintf("[#ffffff]Note: %s[white:-:-]\n\n", diff.Val.Note))
			}

			content.WriteString("[yellow]Please confirm that you have validated the new value.[white]\n")

		case stepTenderly:
			content.WriteString(fmt.Sprintf("[#ffffff::b]Step %d/%d: Tenderly Verification[white:-:-]\n\n",
				currentStep+1, stepCount))
			content.WriteString("[#ffffff]Please verify that you see this same state diff in Tenderly:[white:-:-]\n\n")
			content.WriteString(fmt.Sprintf("[#ffffff]Contract: [#ffff00]%s[white:-:-]\n", diff.Contract))
			content.WriteString(fmt.Sprintf("[#ffffff]Address: [#ff0000]%s[white:-:-]\n", diff.Address.Value))
			content.WriteString(fmt.Sprintf("[#ffffff]Storage Key: [#ff0000]%s[white:-:-]\n", diff.Key.Value))
			content.WriteString(fmt.Sprintf("[#ffffff]New Value: [#ff0000]%s[white:-:-]\n\n", diff.Val.Value))

			content.WriteString("[yellow]Please confirm that you see an identical diff in Tenderly.[white]\n")
		}

		contentView.SetText(content.String())
		contentView.ScrollToBeginning()
	}

	// Function to go to the next step or diff
	goToNextStep := func() {
		currentStep++
		if currentStep >= stepCount {
			// Move to the next diff or to the next page
			currentStep = 0
			currentDiffIndex++

			if currentDiffIndex >= len(diffs) {
				// We've gone through all diffs, move to the next page
				currentDiffIndex = 0          // Reset for next time
				appState.currentItemIndex = 0 // Reset the global index
				navigateToPage(nextPage)
				return
			}
		}
		updateContent()
	}

	// Input handler for the flex
	mainFlex.SetInputCapture(func(event *tcell.EventKey) *tcell.EventKey {
		// Tab to switch focus
		if event.Key() == tcell.KeyTab {
			if app.GetFocus() == contentView {
				app.SetFocus(checkbox)
			} else {
				app.SetFocus(contentView)
			}
			return nil
		}

		// If no diffs, allow skipping directly
		if len(diffs) == 0 {
			if event.Key() == tcell.KeyEnter {
				navigateToPage(nextPage)
				return nil
			} else if event.Key() == tcell.KeyRune && event.Rune() == 'b' {
				goBack()
				return nil
			}
		} else {
			// Handle navigation for diffs
			if event.Key() == tcell.KeyEnter {
				if checkbox.IsChecked() {
					goToNextStep()
					return nil
				} else {
					infoBox.SetText("Please check the confirmation box to continue.")
					return nil
				}
			} else if event.Key() == tcell.KeyRune && event.Rune() == 'b' {
				// Refined back navigation logic
				if currentStep > 0 {
					// If not at the first step of current diff, go back one step
					currentStep--
					updateContent()
				} else if currentDiffIndex > 0 {
					// If at first step but not first diff, go to last step of previous diff
					currentDiffIndex--
					currentStep = stepCount - 1
					updateContent()
				} else {
					// Only go back to previous page if at first step of first diff
					goBack()
				}
				return nil
			}
		}

		return event
	})

	// Initialize content
	updateContent()

	return mainFlex
}
