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
    func testExample() throws {
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        app.launch()
        
        XCTAssertTrue(app.navigationBars["Focus Tracker"].waitForExistence(timeout: 3))
        
        let taskField = app.textFields["taskNameField"]
        XCTAssertTrue(taskField.exists)
        
        taskField.tap()
        taskField.typeText("Reading")
        XCTAssertTrue(taskField.label == "Reading")
        
        
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
    
    
    func testStartFocusTimer() {
        
        let taskField = app.textFields["taskNameField"]
        XCTAssertTrue(taskField.exists)
        
        taskField.tap()
        taskField.typeText("Study SwiftUI")
        XCUIApplication().keyboards.buttons["Return"].tap()

        let startButton = app.buttons["startButton"]
        XCTAssertTrue(startButton.exists)
        
        startButton.tap()
        
        let timerLabel = app.staticTexts["timerTimeLabel"]
        XCTAssertTrue(timerLabel.exists)
        
        // Timer should start counting down
        let initialValue = timerLabel.label
        let predicate = NSPredicate(format: "label != %@", initialValue)
        let expectation = expectation(for: predicate, evaluatedWith: timerLabel, handler: nil)
        
        wait(for: [expectation], timeout: 5) // max 5 seconds
    }
    
    //TODO: complete test
    func testBreakTimerFlow() {
        // enter task name
        let taskField = app.textFields["taskNameField"]
        XCTAssertTrue(taskField.waitForExistence(timeout: 2))
        taskField.tap()
        taskField.typeText("Break Test Task")
        
        // start focus timer
        let startButton = app.buttons["startButton"]
        XCTAssertTrue(startButton.exists)
        startButton.tap()
        
        // verify focus timer starts
        let timerLabel = app.staticTexts["timerTimeLabel"]
        XCTAssertTrue(timerLabel.waitForExistence(timeout: 3))
        
        // wait for timer to finish
        sleep(5
        )
        // verify app switches to break mode
        let breakTitle = app.staticTexts["Break Time"]
        XCTAssertTrue(
            breakTitle.waitForExistence(timeout: 3),
            "App did not enter Break Mode")
        
        let breakInitialValue = timerLabel.label
        
        sleep(2)
        XCTAssertEqual(timerLabel.label, breakInitialValue, "Break timer did not start count down")
        
        // wait for break to finish
        sleep(3)
        
        // Verify app returns to idle Focus state
        // test fails due to break time not auto starting
        // TODO: refactor timerManager to support auto start break timer
        let focusTitle = app.staticTexts["Focus Time"]
        XCTAssertTrue(focusTitle.waitForExistence(timeout: 3), "App did not return to focus time after break")
        
        // app enters idle state and makes timee pickers available
        XCTAssertTrue(app.pickers["focusPicker"].exists)
        XCTAssertTrue(app.pickers["breakPicker"].exists)
    }
    
    
    
    // tests changes to focus duration when selecting a time using the picker
    func testChangeFocusDuration() {
        let focusPicker = app.pickers["focusPicker"]
        XCTAssertTrue(focusPicker.exists)
        
        focusPicker.pickerWheels.element.adjust(toPickerWheelValue: "45 min")
        
        let timerLabel = app.staticTexts["timerTimeLabel"]
        XCTAssertEqual(timerLabel.label, "45:00")
    }
    
    func testFocusTaskIsLoggedInTaskHistory() {
        
        let taskName = "Testing UI focus task log"
        
        // 1. Enter task name
        let taskNameField = app.textFields["taskNameField"]
        XCTAssertTrue(taskNameField.waitForExistence(timeout: 2))
        taskNameField.tap()
        taskNameField.typeText(taskName)
        
        // 2. Start the timer
        app.buttons["startButton"].firstMatch.tap()
        
        // wait for 5 seconds
        sleep(5)
        
        // navigate to taskHistory view
        let historyLink = app.buttons["View Task History"]
        XCTAssertTrue(historyLink.waitForExistence(timeout: 2))
        historyLink.tap()
        
        
        // 5. Verify task appears in history
        let taskCell = app.staticTexts["taskRow_\(taskName)"]
        let existsPredicate = NSPredicate(format: "exists == true")
        expectation(for: existsPredicate, evaluatedWith: taskCell, handler: nil)
        waitForExpectations(timeout: 6)
        
        // 5. Verify
        XCTAssertTrue(taskCell.exists)
        

    }


    @MainActor
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
