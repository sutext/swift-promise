//
//  Safely.swift
//  swift-promise
//
//  Created by supertext on 2025/2/18.
//

import Foundation

///A thread-safe roperty wrapper around a value.
///When the Value is Void, it can be used directly as a lock
///
///      let safe = Safely()
///
///      //lock
///      safe.lock()
///      defer{ safe.unlock() }
///
///      //around
///      safe.around{
///         // something need lock
///      }
///
@propertyWrapper
public final class Safely<Value> : @unchecked Sendable{
#if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
    ///Use a more efficient temporary sync lock on the darwin platform instead of using `NSLock` directly
    private var _lock = os_unfair_lock()
    public func lock(){
        os_unfair_lock_lock(&_lock)
    }
    public func unlock(){
        os_unfair_lock_unlock(&_lock)
    }
#else
    private var _lock = NSLock()
    public func lock(){
        _lock.lock()
    }
    public func unlock(){
        _lock.unlock()
    }
#endif
    private var value: Value
    public var projectedValue: Safely<Value> { self }
    public init(wrappedValue: Value) {
        self.value = wrappedValue
    }
    public var wrappedValue: Value {
        get { around { value } }
        set { around { value = newValue } }
    }
    /// around some safer codes and retrun a new value of type T
    public func around<T>(_ closure: () throws -> T) rethrows -> T {
        lock()
        defer { unlock() }
        return try closure()
    }
    /// Access wrapped  value and retrun a new value of type T
    public func read<T>(_ closure: (Value) throws -> T) rethrows -> T {
        try around { try closure(self.value) }
    }
    /// Modify wrapped  value and retrun a new value of type T
    public func write<T>(_ closure: (inout Value) throws -> T) rethrows -> T {
        try around { try closure(&self.value) }
    }
}

extension Safely where Value == Void{
    public convenience init(){
        self.init(wrappedValue: ())
    }
}
