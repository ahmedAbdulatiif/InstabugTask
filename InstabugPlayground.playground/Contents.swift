import UIKit
import XCTest

class Bug {
    enum State {
        case open
        case closed
    }
    
    
    let state: State
    let timestamp: Date
    let comment: String
    
    
    init(state: State, timestamp: Date, comment: String) {
        self.state = state
        self.timestamp = timestamp
        self.comment = comment
    }
    
    init(jsonString: String) throws {
        
        guard let jsonData = jsonString.data(using: .utf8) ,
            let bugData = try JSONSerialization.jsonObject(with: jsonData, options: []) as? NSDictionary
        else { throw JsonString.notSerializable }
        
        guard let commentValue = bugData["comment"] as? String,
            let statetValue = bugData["state"] as? String,
            let timestampValue = bugData["timestamp"] as? Int
        else { throw JsonString.notValidKeys }
        
        self.comment = commentValue
        
        self.timestamp = Date(timeIntervalSince1970: TimeInterval(timestampValue))
        
        if statetValue == "open"{
            self.state = .open
        }else{ self.state = .closed }
        
    }
}
    
enum JsonString : Error {
    case notValidKeys
    case notSerializable
}
    

enum TimeRange {
    case pastDay
    case pastWeek
    case pastMonth
}

class Application {
    var bugs: [Bug]
    
    init(bugs: [Bug]) {
        self.bugs = bugs
    }
    
    func findBugs(state: Bug.State?, timeRange: TimeRange) -> [Bug] {
       var findedBugs : [Bug] = []
        for bug in bugs {
            let bugTimeRange = getTimeRange(timestamp: bug.timestamp)
            if (bug.state == state!) && (timeRange == bugTimeRange){
                findedBugs.append(bug)
            }
        }
        return findedBugs
    }
    
    func getTimeRange(timestamp : Date)-> TimeRange {
        
        let calendar = Calendar.current
        let currentDate = Date()
        let startDate = calendar.ordinality(of: .day, in: .era, for: timestamp)
        let endDate = calendar.ordinality(of: .day, in: .era, for: currentDate)
        let days = endDate! - startDate!
        
        if days == 0 {
            return TimeRange.pastDay
        }
        else if days <= 7 {
            return TimeRange.pastWeek
        }else{
            return TimeRange.pastMonth
        }
    }
}

class UnitTests : XCTestCase {
    lazy var bugs: [Bug] = {
        var date26HoursAgo = Date()
        date26HoursAgo.addTimeInterval(-1 * (26 * 60 * 60))
        
        var date2WeeksAgo = Date()
        date2WeeksAgo.addTimeInterval(-1 * (14 * 24 * 60 * 60))
        
        let bug1 = Bug(state: .open, timestamp: Date(), comment: "Bug 1")
        let bug2 = Bug(state: .open, timestamp: date26HoursAgo, comment: "Bug 2")
        let bug3 = Bug(state: .closed, timestamp: date2WeeksAgo, comment: "Bug 2")

        return [bug1, bug2, bug3]
    }()
    
    lazy var application: Application = {
        let application = Application(bugs: self.bugs)
        return application
    }()

    func testFindOpenBugsInThePastDay() {
        let bugs = application.findBugs(state: .open, timeRange: .pastDay)
        XCTAssertTrue(bugs.count == 1, "Invalid number of bugs")
        XCTAssertEqual(bugs[0].comment, "Bug 1", "Invalid bug order")
    }
    
    func testFindClosedBugsInThePastMonth() {
        let bugs = application.findBugs(state: .closed, timeRange: .pastMonth)
        
        XCTAssertTrue(bugs.count == 1, "Invalid number of bugs")
    }
    
    func testFindClosedBugsInThePastWeek() {
        let bugs = application.findBugs(state: .closed, timeRange: .pastWeek)
        
        XCTAssertTrue(bugs.count == 0, "Invalid number of bugs")
    }
    
    func testInitializeBugWithJSON() {
        do {
            let json = "{\"state\": \"open\",\"timestamp\": 1493393946,\"comment\": \"Bug via JSON\"}"

            let bug = try Bug(jsonString: json)
            
            XCTAssertEqual(bug.comment, "Bug via JSON")
            XCTAssertEqual(bug.state, .open)
            XCTAssertEqual(bug.timestamp, Date(timeIntervalSince1970: 1493393946))
        } catch {
            print(error)
        }
    }
}

class PlaygroundTestObserver : NSObject, XCTestObservation {
    @objc func testCase(_ testCase: XCTestCase, didFailWithDescription description: String, inFile filePath: String?, atLine lineNumber: UInt) {
        print("Test failed on line \(lineNumber): \(String(describing: testCase.name)), \(description)")
    }
}

let observer = PlaygroundTestObserver()
let center = XCTestObservationCenter.shared()
center.addTestObserver(observer)

TestRunner().runTests(testClass: UnitTests.self)
