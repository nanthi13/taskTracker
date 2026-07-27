// Created by: nanthi13 on 20/01/2026

import XCTest
@testable import FocusTracker

/// End-to-end UI tests validating core user flows:
/// - Naming a task
/// - Starting a timer and verifying countdown
/// - Automatic transition from Focus to Break and back
/// - Persisting tasks into history and clearing them
/// - Adjusting focus/break durations via pickers
///
/// Notes:
/// - The app honors a "UI_TESTING" launch argument. When present, TimerManager.currentDuration
///   is shortened (6 seconds) to make mode transitions fast and deterministic in tests.
/// - All UI elements used here expose accessibility identifiers (see HomeView/TaskHistoryView).
final class FocusTrackerUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments.append("UI_TESTING")
        app.launch()
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
        // No-op: tests leave the app in a valid state for the next test.
    }

    /// Verifies that the user can type a task name into the text field.
    @MainActor
    func testNamingTask() throws {
        let taskField = app.textFields["taskNameField"]
        XCTAssertTrue(taskField.exists)

        taskField.tap()
        taskField.typeText("Reading")
        XCTAssertEqual(taskField.value as? String, "Reading")
    }

    // MARK: - Helpers

    /// Types a task name and dismisses the keyboard.
    func enterTask(name: String) {
        let taskField = app.textFields["taskNameField"]
        XCTAssertTrue(taskField.waitForExistence(timeout: 2))
        taskField.tap()
        taskField.typeText(name)
        XCUIApplication().keyboards.buttons["Return"].tap()
    }

    /// Taps the Start button.
    func startTimer() {
        let startButton = app.buttons["startButton"]
        XCTAssertTrue(startButton.waitForExistence(timeout: 2))
        startButton.tap()
    }

    /// Waits for the timer mode label to equal the provided mode string.
    func waitForMode(_ mode: String, timeout: TimeInterval = 10) {
        let modeLabel = app.staticTexts["timerModeLabel"]
        XCTAssertTrue(modeLabel.waitForExistence(timeout: 2))

        let predicate = NSPredicate(format: "label == %@", mode)
        expectation(for: predicate, evaluatedWith: modeLabel)
        waitForExpectations(timeout: timeout)
    }

    /// Navigates to the History tab and clears all tasks if present.
    func clearAllTasks() {
        let historyTab = app.tabBars.buttons["History"]
        guard historyTab.exists else { return }

        historyTab.tap()

        let clearButton = app.buttons["clearAllButton"]
        guard clearButton.exists else { return }

        clearButton.tap()
        app.alerts.buttons["Delete All"].tap()
    }

    // MARK: - Tests

    /// Ensures that the app survives a background/foreground cycle during a break,
    /// and returns to Focus (idle) automatically after the (shortened) break ends.
    func testBreakTimerAfterGoingHome() {
        // Arrange: start a focus session.
        enterTask(name: "Break Timer Test")
        startTimer()
        waitForMode("Focus Time")

        // Wait for transition into Break Time.
        waitForMode("Break Time", timeout: 20)

        // Immediately background the app so the break completes while in background.
        XCUIDevice.shared.press(.home)

        // Sleep slightly longer than the shortened break duration (6s).
        sleep(7)

        // Foreground the app.
        app.activate()

        // Assert: we should be back to idle focus state with pickers visible.
        let focusPicker = app.pickers["focusPicker"]
        let breakPicker = app.pickers["breakPicker"]
        XCTAssertTrue(focusPicker.waitForExistence(timeout: 5))
        XCTAssertTrue(breakPicker.waitForExistence(timeout: 2))

        // Optionally, verify we can start a fresh focus session now.
        enterTask(name: "New Session After Break")
        startTimer()
        waitForMode("Focus Time", timeout: 10)
    }

    /// Verifies the focus timer starts counting down after tapping Start.
    func testStartFocusTimer() {
        enterTask(name: "testing focus timer")
        startTimer()

        let timerLabel = app.staticTexts["timerTimeLabel"]
        XCTAssertTrue(timerLabel.waitForExistence(timeout: 2))

        // Expect the time label to change within 5 seconds.
        let initialValue = timerLabel.label
        let predicate = NSPredicate(format: "label != %@", initialValue)
        expectation(for: predicate, evaluatedWith: timerLabel, handler: nil)
        waitForExpectations(timeout: 5)
    }

    /// Confirms that a completed session appears in Task History.
    func testTaskIsSavedToHistory() {
        clearAllTasks()

        let homeTab = app.tabBars.buttons["Home"]
        homeTab.tap()

        let taskName = "UI Test History Task"
        enterTask(name: taskName)
        startTimer()

        // Allow a short run then navigate to History.
        sleep(5)
        let historyTab = app.tabBars.buttons["History"]
        XCTAssertTrue(historyTab.waitForExistence(timeout: 2))
        historyTab.tap()

        let taskCell = app.staticTexts["taskRow_\(taskName)"]
        XCTAssertTrue(taskCell.waitForExistence(timeout: 5))
    }

    /// Ensures the focus mode transitions into break mode (shortened duration in UI tests).
    func testFocusTransitionToBreak() {
        enterTask(name: "Mode Transition Test")
        startTimer()

        waitForMode("Focus Time")
        waitForMode("Break Time", timeout: 5)
    }

    /// Ensures the break mode becomes idle and the pickers are visible again.
    func testBreakTransitiontoIdle() {
        enterTask(name: "Break Completion Test")
        startTimer()

        waitForMode("Focus Time")
        waitForMode("Break Time", timeout: 5)

        XCTAssertTrue(app.pickers["focusPicker"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.pickers["breakPicker"].waitForExistence(timeout: 2))
    }

    /// Changes focus duration via the picker and validates the timer label updates.
    /// Note: Occasionally flakey on slow simulators due to wheel settling.
    func testChangeFocusDuration() {
        let focusPicker = app.pickers["focusPicker"]
        XCTAssertTrue(focusPicker.waitForExistence(timeout: 2))

        focusPicker.pickerWheels.element.adjust(toPickerWheelValue: "45 min")

        let timerLabel = app.staticTexts["timerTimeLabel"]
        let predicate = NSPredicate(format: "label == %@", "45:00")
        expectation(for: predicate, evaluatedWith: timerLabel)
        waitForExpectations(timeout: 10)
    }

    /// Clears all tasks from history and verifies the empty state label.
    func testDeleteTasks() {
        let historyTab = app.tabBars.buttons["History"]
        XCTAssertTrue(historyTab.waitForExistence(timeout: 2))
        historyTab.tap()

        let clearButton = app.buttons["clearAllButton"]
        XCTAssertTrue(clearButton.waitForExistence(timeout: 3))
        clearButton.tap()

        let deleteAllButton = app.alerts.buttons["Delete All"]
        XCTAssertTrue(deleteAllButton.waitForExistence(timeout: 3))
        deleteAllButton.tap()

        let emptyLabel = app.staticTexts["Adjust your filters or try a different search."]
        XCTAssertTrue(emptyLabel.waitForExistence(timeout: 3))
    }

    /// Smoke test for adding a task and navigating to history.
    func testAddTask() {
        let taskName = "testing print statement"

        let taskNameField = app.textFields["taskNameField"]
        XCTAssertTrue(taskNameField.waitForExistence(timeout: 2))
        taskNameField.tap()
        taskNameField.typeText(taskName)

        app.buttons["startButton"].firstMatch.tap()

        sleep(5)

        let historyTab = app.tabBars.buttons["History"]
        XCTAssertTrue(historyTab.waitForExistence(timeout: 2))
        historyTab.tap()
    }
}

