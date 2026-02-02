//CREATED  BY: nanthi13ON 20/01/2026

import XCTest
@testable import FocusTracker

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
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        
        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }
    
    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    @MainActor
    func testNamingTask() throws {
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        app.launch()
        
        let taskField = app.textFields["taskNameField"]
        XCTAssertTrue(taskField.exists)
        
        taskField.tap()
        taskField.typeText("Reading")
        XCTAssertEqual(taskField.value as? String, "Reading")
    }
    
    // helpers
    
    // create a task
    func enterTask(name: String ) {
        let taskField = app.textFields["taskNameField"]
        XCTAssertTrue(taskField.waitForExistence(timeout: 2))
        taskField.tap()
        taskField.typeText(name)
        XCUIApplication().keyboards.buttons["Return"].tap()
    }
    
    // hit start button
    func startTimer() {
        let startButton = app.buttons["startButton"]
        XCTAssertTrue(startButton.waitForExistence(timeout: 2))
        startButton.tap()
    }
    
    func clearAllTasks() {
        let historyTab = app.tabBars.buttons["History"]
        guard historyTab.exists else { return }
        
        historyTab.tap()
        
        let clearButton = app.buttons["clearAllButton"]
        guard clearButton.exists else { return }
    
        clearButton.tap()
        app.alerts.buttons["Delete All"].tap()
        
    }
    
    func waitForMode(_ mode: String, timeout: TimeInterval = 10) {
        let modeLabel = app.staticTexts["timerModeLabel"]
        XCTAssertTrue(modeLabel.waitForExistence(timeout: 2))

        let predicate = NSPredicate(format: "label == %@", mode)
        expectation(for: predicate, evaluatedWith: modeLabel)
        waitForExpectations(timeout: timeout)
    }
    
    
    func testStartFocusTimer() {
        
        enterTask(name: "testing focus timer")
        startTimer()
        
        let timerLabel = app.staticTexts["timerTimeLabel"]
        XCTAssertTrue(timerLabel.waitForExistence(timeout: 2))
        
        // Timer should start counting down
        let initialValue = timerLabel.label
        let predicate = NSPredicate(format: "label != %@", initialValue)
        
        expectation(for: predicate, evaluatedWith: timerLabel, handler: nil)
        waitForExpectations(timeout: 5)
//        let expectation = expectation(for: predicate, evaluatedWith: timerLabel, handler: nil)
//        
//        wait(for: [expectation], timeout: 5) // max 5 seconds
    }
    
    func testTaskIsSavedToHistory() {
        clearAllTasks()
        
        // switch to home tab
        let homeTab = app.tabBars.buttons["Home"]
        homeTab.tap()
        
        let taskName = "UI Test History Task"
        enterTask(name: taskName)
        startTimer()
        
        sleep(5)
        let historyTab = app.tabBars.buttons["History"]
        XCTAssertTrue(historyTab.waitForExistence(timeout: 2))
        historyTab.tap()
        
        let taskCell = app.staticTexts["taskRow_\(taskName)"]
        XCTAssertTrue(taskCell.waitForExistence(timeout: 5))
    }
    
    
    func testBreakTimerFlow() {
        // enter task name
        let taskField = app.textFields["taskNameField"]
        XCTAssertTrue(taskField.waitForExistence(timeout: 2))
        taskField.tap()
        taskField.typeText("Break Test Task")
        
        // start focus timer transition from idle -> focus mode
        let startButton = app.buttons["startButton"]
        XCTAssertTrue(startButton.exists)
        startButton.tap()
        
        // verify focus mode starts
        // confirms app has changed to focus mode
        let modeLabel = app.staticTexts["timerModeLabel"]
        XCTAssertTrue(modeLabel.waitForExistence(timeout: 3))
        XCTAssertEqual(modeLabel.label, "Focus Time")

        // timerlabel ehould exist when the focus session has started
        let timerLabel = app.staticTexts["timerTimeLabel"]
        XCTAssertTrue(timerLabel.exists)
        
        // wait for app transition Focus -> Break mode
        let enteredBreak = NSPredicate(format: "label == %@", "Break Time")
            expectation(for: enteredBreak, evaluatedWith: modeLabel)
            waitForExpectations(timeout: 10)
        
        // capture initial breaktimerValue
        let breakTimeStart = timerLabel.label

        // Wait until the timer label changes, proving the break timer is counting down
        let timerChanged = NSPredicate { _, _ in
            timerLabel.label != breakTimeStart
        }

        expectation(for: timerChanged, evaluatedWith: timerLabel)
        waitForExpectations(timeout: 2)

        
        // Double-check that the timer value actually changed
        let breakTimeAfter = timerLabel.label
        XCTAssertNotEqual(
            breakTimeStart,
            breakTimeAfter,
            "Break timer did not start counting down"
        )
        
        // Wait for break to finish and return to focus
        // After the break finishes, the app should return to focus/idle state
        let returnedToFocus = NSPredicate(format: "label == %@", "Focus Time")
        expectation(for: returnedToFocus, evaluatedWith: modeLabel)
        waitForExpectations(timeout: 10)
        
        // app enters idle state and makes time pickers available
        XCTAssertTrue(app.pickers["focusPicker"].exists)
        XCTAssertTrue(app.pickers["breakPicker"].exists)
    }
    
    
    
    // tests changes to focus duration when selecting a time using the picker
    func testChangeFocusDuration() {
        let focusPicker = app.pickers["focusPicker"]
        XCTAssertTrue(focusPicker.exists)
        
        focusPicker.pickerWheels.element.adjust(toPickerWheelValue: "45 min")
        // TODO: Test fails sometimes
        let timerLabel = app.staticTexts["timerTimeLabel"]
        XCTAssertEqual(timerLabel.label, "45:00")
    }
    
    func testDeleteTasks() {
        // switch to history view
        let historyTab = app.tabBars.buttons["History"]
        XCTAssertTrue(historyTab.waitForExistence(timeout: 2))
        historyTab.tap()
        
        // Clear all tasks to prevent task clutter causing test to fail
        let clearButton = app.buttons["clearAllButton"]
        XCTAssertTrue(clearButton.waitForExistence(timeout: 3))
        clearButton.tap()
        
        // Confirm deletion in the alert
        let deleteAllButton = app.alerts.buttons["Delete All"]
        XCTAssertTrue(deleteAllButton.waitForExistence(timeout: 3))
        deleteAllButton.tap()

        // Verify list is empty
        let emptyLabel = app.staticTexts["No tasks yet."]
        XCTAssertTrue(emptyLabel.waitForExistence(timeout: 3))
    }
    
    func testAddTask() {
        let taskName = "testing print statement"
        // to see print statements when testing place breakpoint
    
        
        // 1. Enter task name
        
        let taskNameField = app.textFields["taskNameField"]
        XCTAssertTrue(taskNameField.waitForExistence(timeout: 2))
        taskNameField.tap()
        taskNameField.typeText(taskName)
        
        // 2. Start the timer
        app.buttons["startButton"].firstMatch.tap()
        print("SHOULD BE HERE LOGGED")
        // 3. wait for 5 seconds
        sleep(5)
        
        // 4. navigate to taskHistory view
        let historyTab = app.tabBars.buttons["History"]
        XCTAssertTrue(historyTab.waitForExistence(timeout: 2))
        historyTab.tap()
    }

//    @MainActor
//    func testLaunchPerformance() throws {
//        // This measures how long it takes to launch your application.
//        measure(metrics: [XCTApplicationLaunchMetric()]) {
//            XCUIApplication().launch()
//        }
//    }
}
