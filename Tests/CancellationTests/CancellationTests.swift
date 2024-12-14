import XCTest

@testable import Cancellation

class CancellationTests: XCTestCase {
	func test() {
		let source = CancellationTokenSource()
		let token = source.token

		XCTAssertFalse(source.isCancellationRequested)
		XCTAssertFalse(token.isCancellationRequested)
		XCTAssertTrue(token.canBeCanceled)

		var callbackHappenedCount = 0
		let registration = try? source.register {
			callbackHappenedCount += 1
		}
		XCTAssertNotNil(registration)

		source.cancel()

		XCTAssertTrue(source.isCancellationRequested)
		XCTAssertTrue(token.isCancellationRequested)
		XCTAssertEqual(callbackHappenedCount, 1)

		var threwException = false
		do {
			try token.throwIfCancellationIsRequested()
		} catch OperationCanceledException.operationCanceled {
			threwException = true
		} catch {
			XCTFail("Unexpected error: \(error)")
		}

		XCTAssertTrue(threwException)

		source.dispose()
	}
}
