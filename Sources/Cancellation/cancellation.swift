import Foundation
import IDisposable

public enum OperationCanceledException : Error
{
	case OperationCanceled
}

public class CancellationTokenSource : IDisposable
{
	public var isCancellationRequested: Bool
	{
		if (_isCancellationRequested) {
			return true
		}

		defer { _lock.unlock() }
		_lock.lock()
		return _isCancellationRequested
	}

	public var token: CancellationToken
	{
		return CancellationToken(source: self)
	}

	public init()
	{
	}

	public func dispose()
	{
		if (_isDisposed) {
			return
		}

		defer { _lock.unlock() }
		_lock.lock()
		if (_isDisposed) {
			return
		}

		_isDisposed = true
	}

	public func cancel() {
		var notify = false
		synced(_lock) {
			notify = !_isCancellationRequested
			_isCancellationRequested = true
		}
		if (notify) {
			notifySubscribers()
		}
	}

	internal func register(_ action: @escaping () -> ()) throws -> CancellationTokenRegistration {
		let subscriber = Subscriber(action)
		var shouldThrow = false
		var shouldNotify = false
		synced(_lock) {
			shouldThrow = _isDisposed
			shouldNotify = !_isDisposed && _isCancellationRequested
			if (!shouldThrow && !shouldNotify) {
				self.addSubscriber(subscriber)
			}
		}
		if (shouldThrow) {
			throw ObjectDisposedException.ObjectDisposed
		}
		if (shouldNotify) {
			subscriber.notify()
		}

		return shouldNotify ?
			CancellationTokenRegistration {} :
			CancellationTokenRegistration {
				self.removeSubscriber(subscriber)
			}
	}

	private func addSubscriber(_ subscriber: Subscriber) {
		synced(_lock) {
			_subscribers.append(subscriber)
		}
	}

	private func removeSubscriber(_ subscriber: Subscriber) {
		synced(_lock) {
			let index = _subscribers.firstIndex { s in
				return s === subscriber
			};
			_subscribers.remove(at: index!)
		}
	}

	private func notifySubscribers() {
		synced(_lock) {
			for subscriber in _subscribers {
				subscriber.notify()
			}
		}
	}

	private var _isCancellationRequested: Bool = false
	private var _isDisposed: Bool = false
	private var _subscribers: Array = Array<Subscriber>()
	private var _lock = NSLock()
}

public class CancellationToken
{
	public static var None: CancellationToken {
		return CancellationToken.init(isCanceled: false)
	}

	public var canBeCanceled: Bool {
		return _canBeCanceled()
	}

	public var isCancellationRequested: Bool {
		return _isCancellationRequested()
	}

	public func register(_ action: @escaping () -> ()) throws -> CancellationTokenRegistration {
		if (_source == nil) {
			action()
			return CancellationTokenRegistration {}
		} else {
			return try _source!.register(action)
		}
	}

	public func throwIfCancellationIsRequested() throws {
		if (_isCancellationRequested()) {
			throw OperationCanceledException.OperationCanceled
		}
	}

	public init(isCanceled: Bool) {
		_canBeCanceled = { return isCanceled }
		_isCancellationRequested = { return isCanceled }
	}

	internal init(source: CancellationTokenSource) {
		_canBeCanceled = { return !source.isCancellationRequested }
		_isCancellationRequested = { return source.isCancellationRequested }
		_source = source
	}

	private var _canBeCanceled: () -> Bool
	private var _isCancellationRequested: () -> Bool
	private var _source: CancellationTokenSource? = nil
}

internal typealias DisposeRegistrationDelegate = () -> ()

public class CancellationTokenRegistration : IDisposable
{
	public func dispose() {
		if _onDispose == nil {
			return
		}

		defer { _lock.unlock() }
		_lock.lock()
		_onDispose?()
		_onDispose = nil
	}

	internal init (_ onDispose: @escaping DisposeRegistrationDelegate) {
		_onDispose = onDispose
	}

	private var _onDispose: DisposeRegistrationDelegate?
	private var _lock = NSLock()
}

private func synced(_ lock: NSLock, _ closure: () -> ()) {
	defer { lock.unlock() }
	lock.lock()
	closure()
}

private class Subscriber
{
	init(_ callback: @escaping () -> ()) {
		_callback = callback
	}

	public func notify() {
		_callback()
	}

	private var _callback: () -> ()
}
