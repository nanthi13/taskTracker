//CREATED  BY: nanthi13ON 20/01/2026

import XCTest
@testable import FocusTracker

final class FocusTrackerUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUp() {
            super.setUp()
            continueAfterFailure = false
            app = XCUIApplication()
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

        let startButton = app.buttons["startButton"]
        XCTAssertTrue(startButton.exists)

        startButton.tap()

        let timerLabel = app.staticTexts["timerTimeLabel"]
        XCTAssertTrue(timerLabel.exists)

        // Timer should start counting down
        let initialValue = timerLabel.label
        sleep(2)
        XCTAssertNotEqual(timerLabel.label, initialValue)
    }
    
    // tests changes to focus duration when selecting a time using the picker
    func testChangeFocusDuration() {
        let focusPicker = app.pickers["focusPicker"]
        XCTAssertTrue(focusPicker.exists)
        
        focusPicker.pickerWheels.element.adjust(toPickerWheelValue: "45 min")
        
        let timerLabel = app.staticTexts["timerTimeLabel"]
        XCTAssertEqual(timerLabel.label, "45:00")
    }


    @MainActor
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
