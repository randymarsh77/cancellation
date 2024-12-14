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

		do {
			try token.throwIfCancellationIsRequested()
		} catch OperationCanceledException.operationCanceled {
			XCTFail("Should not throw when token is not canceled")
		} catch {
			XCTFail("Unexpected error: \(error)")
		}

		var callbackHappenedCount = 0
		let registrationFromSource = try? source.register {
			callbackHappenedCount += 1
		}
		XCTAssertNotNil(registrationFromSource)

		let registrationFromToken = try? token.register {
			callbackHappenedCount += 1
		}
		XCTAssertNotNil(registrationFromToken)

		let registrationToDispose = try? source.register {
			callbackHappenedCount += 1
		}
		XCTAssertNotNil(registrationToDispose)
		// Dispose is safe to call multiple times
		registrationToDispose!.dispose()
		registrationToDispose!.dispose()

		source.cancel()

		XCTAssertTrue(source.isCancellationRequested)
		XCTAssertTrue(token.isCancellationRequested)
		XCTAssertEqual(callbackHappenedCount, 2)

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
