//
//  BackoffSchedulerTests.swift
//  AdyenTests
//
//  Created by Mohamed Eldoheiri on 8/11/20.
//  Copyright © 2020 Adyen. All rights reserved.
//

import XCTest
@testable import Adyen

extension XCTestCase {
    func wait(for interval: DispatchTimeInterval) {
        let dummyExpectation = expectation(description: "wait for 2 seconds.")

        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .seconds(2)) {
            dummyExpectation.fulfill()
        }

        waitForExpectations(timeout: 2, handler: nil)
    }
}

class BackoffSchedulerTests: XCTestCase {

    func testScheduling() {
        var executionCounter = 0
        let closureToSchedule = {
            executionCounter += 1
        }

        let intervalCalculator = IntervalCalculatorMock { counter in
            if counter <= 100 {
                return DispatchTimeInterval.microseconds(1)
            } else  {
                return DispatchTimeInterval.never
            }
        }

        var sut = BackoffScheduler(queue: .main)
        sut.backoffIntevalCalculator = intervalCalculator

        (1...100).forEach { counter in
            XCTAssertFalse(sut.schedule(counter, closure: closureToSchedule))
        }

        XCTAssertTrue(sut.schedule(101, closure: closureToSchedule))

        wait(for: .seconds(2))

        XCTAssertEqual(executionCounter, 100)
    }

}
