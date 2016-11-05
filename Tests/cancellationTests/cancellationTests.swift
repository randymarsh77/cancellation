import XCTest
@testable import Cancellation

class CancellationTests: XCTestCase
{
	func test() {
		let s = CancellationTokenSource()
		let t = s.token

		XCTAssertFalse(s.isCancellationRequested)
		XCTAssertFalse(t.isCancellationRequested)
		XCTAssertTrue(t.canBeCanceled)

		s.cancel()

		XCTAssertTrue(s.isCancellationRequested)
		XCTAssertTrue(t.isCancellationRequested)
	}

	static var allTests : [(String, (CancellationTests) -> () throws -> Void)] {
		return [
			("test", test),
		]
	}
}
