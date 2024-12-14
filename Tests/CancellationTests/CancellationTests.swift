import IDisposable
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
		let registration1 = try? source.register {
			callbackHappenedCount += 1
		}
		XCTAssertNotNil(registration1)

		let registration2 = try? source.register {
			callbackHappenedCount += 1
		}
		XCTAssertNotNil(registration2)
		// Dispose is safe to call multiple times
		registration2!.dispose()
		registration2!.dispose()

		source.cancel()

		XCTAssertTrue(source.isCancellationRequested)
		XCTAssertTrue(token.isCancellationRequested)
		XCTAssertEqual(callbackHappenedCount, 1)

		var threwOperationCanceled = false
		do {
			try token.throwIfCancellationIsRequested()
		} catch OperationCanceledException.operationCanceled {
			threwOperationCanceled = true
		} catch {
			XCTFail("Unexpected error: \(error)")
		}

		XCTAssertTrue(threwOperationCanceled)

		source.dispose()

		var threwObjectDisposed = false
		do {
			_ = try source.register {
				XCTFail("Should be throwing instead of calling back")
			}
		} catch ObjectDisposedException.objectDisposed {
			threwObjectDisposed = true
		} catch {
			XCTFail("Unexpected error: \(error)")
		}

		XCTAssertTrue(threwObjectDisposed)
	}

	func testFixedTokens() {
		let none = CancellationToken.None
		XCTAssertFalse(none.canBeCanceled)
		XCTAssertFalse(none.isCancellationRequested)

		let canceled = CancellationToken.Canceled
		XCTAssertTrue(canceled.canBeCanceled)
		XCTAssertTrue(canceled.isCancellationRequested)

		let registration1 = try? none.register {
			XCTFail("Non-cancellable token should never call back")
		}
		XCTAssertNotNil(registration1)

		var callbackHappenedCount = 0
		let registration2 = try? canceled.register {
			callbackHappenedCount += 1
		}
		XCTAssertNotNil(registration2)
		XCTAssertEqual(callbackHappenedCount, 1)
	}
}
