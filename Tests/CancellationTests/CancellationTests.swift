import XCTest

@testable import Cancellation

class CancellationTests: XCTestCase {
	func test() {
		let source = CancellationTokenSource()
		let token = source.token

		XCTAssertFalse(source.isCancellationRequested)
		XCTAssertFalse(token.isCancellationRequested)
		XCTAssertTrue(token.canBeCanceled)

		source.cancel()

		XCTAssertTrue(source.isCancellationRequested)
		XCTAssertTrue(token.isCancellationRequested)
	}
}
