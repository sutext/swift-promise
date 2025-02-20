//
//  Promise.swift
//  swift-promise
//
//  Created by supertext on 2024/12/19.
//

import Foundation

///  A pattern of asynchronous programming
///
/// - Look at `Javascript` `Promise`  for design ideas
/// - It is mainly used when an asynchronous return value is required
/// - Internally, we make it thread-safe, so we mark it  `@unchecked Sendable`
/// - The thread of the callback function depends on the thread of the `done(_:)` method call
public final class Promise<Value:Sendable>: @unchecked Sendable{
    @Safely private var result:Result<Value,Error>?
    private var callbacks:Callbacks = Callbacks()
    /// The promise has been done or not
    public var isDone:Bool {
        $result.read { $0 != nil }
    }
    
    /// Create a promise with no resolver or reject
    /// - Important: The `done(_ :)` method must to be called manually
    public init(){ }
    
    /// Create a promise and call `done(value)` immediately
    /// - Parameters:
    ///   - value: The success value to be return
    public init(_ value:Value){
        self.done(value)
    }
    
    /// Create a promise and call `done(error)` immediately
    /// - Parameters:
    ///   - error: The failure error to be return
    public init(_ error:Error){
        self.done(error)
    }
    /// Create a promise and call `done(result)` immediately
    /// - Parameters:
    ///   - result: The result to be return
    public init(_ result:Result<Value,Error>){
        self.done(result)
    }
    /// This is the recommended constructor
    ///
    ///     func someAsyncMethod(value:Int)->Promise<Int>{
    ///        return Promise { resolve, reject in
    ///            DispatchQueue.global().asyncAfter(deadline: .now()+5){
    ///                if value%2 == 0 {
    ///                    resolve(value/2)
    ///                }else{
    ///                    reject(NSError(domain: "bad error", code: 0))
    ///                }
    ///            }
    ///        }
    ///     }
    ///     
    ///     someAsyncMethod(2)
    ///         .then{value in
    ///             print(value)
    ///         }
    ///         .catch{error
    ///             print(error)
    ///         }
    ///     /// use async method
    ///     let value = try await someAsyncMethod(5).wait()
    ///     print(value)
    ///
    /// - Parameters:
    ///    - initializer: The init func which well be call immediately
    public init(initializer:@escaping @Sendable (@escaping @Sendable (Value) -> Void,@escaping @Sendable (Error) -> Void) -> Void){
        initializer ({ self.done($0) }, { self.done($0) })
    }
    
    /// Issue a completion signal indicating that the Promise has been completed with an error
    /// It has no effect when repeated
    ///
    /// - Parameters:
    ///    - error: done with the failure error result
    ///    - queue: The callback queue if specified, Otherwise depends on the thread of the `done(_:)` method call
    public func done(_ error:Error,in queue:DispatchQueue? = nil){
        if let queue{
            queue.async { self._done(.failure(error)) }
        }else{
            self._done(.failure(error))
        }
    }
    
    /// Issue a completion signal indicating that the Promise has been completed with an value
    /// It has no effect when repeated
    /// - Parameters:
    ///    - value: done with the success value result
    ///    - queue: The callback queue if specified, Otherwise depends on the thread of the `done(_:)` method call
    public func done(_ value:Value,in queue:DispatchQueue? = nil){
        if let queue{
            queue.async { self._done(.success(value)) }
        }else{
            self._done(.success(value))
        }
    }
    
    /// It has no effect when repeated calls.
    /// - Parameters:
    ///    - result: done with the result
    ///    - queue: The callback queue if specified, Otherwise depends on the thread of the `done(_:)` method call
    public func done(_ result:Result<Value,Error>,in queue:DispatchQueue? = nil){
        if let queue{
            queue.async { self._done(result) }
        }else{
            self._done(result)
        }
    }
    private func _done(_ result:Result<Value,Error>){
        $result.write {
            if $0 == nil{
                $0 = result
                self.callbacks.run()
                self.callbacks = Callbacks()
            }
        }
    }
    /// Add finish callback
    /// - Parameters:
    ///    - callback: done with the result
    private func withFinish(callback:@escaping Callbacks.Element){
        $result.read {
            if $0 == nil{
                self.callbacks.append(callback)
            }else{
                callback().run()
            }
        }
    }
}

extension Promise{
    /// This is where all the call chains end up
    ///
    ///     let promise = Promise<Int>()
    ///     promise.then{v in
    ///         return v.map { other v }
    ///     }.then{ v in
    ///         print(v)
    ///     }.finally{ result in
    ///         print(result)
    ///     }
    ///
    /// - Parameters:
    ///   - handler: The  finally handler  after some  result returned. Both success and failure are included.The thread of the handler  depends on the thread of the `done(_:)` method call
    public func finally(_ handler:@escaping @Sendable (Result<Value,Error>)->Void ){
        self.withFinish {
            handler(self.result!)
            return .init()
        }
    }
    /// Process success value or failure error after promise comleted
    ///
    ///     let promise = Promise<Int>()
    ///     promise.map{v in
    ///         if _ {
    ///             return .success("\(v*v*v)")
    ///         }else{
    ///             return .failure(some error)
    ///         }
    ///     }.then{ v in
    ///         print(v)
    ///     }.catch{ err in
    ///         print(err)
    ///     }
    ///
    /// - Parameters:
    ///    - onresult: The  handler  after some  result returned. Both success and failure are included.The thread of the handler  depends on the thread of the `done(_:)` method call
    /// - Returns: The next promise in the chain
    @discardableResult
    public func map<Other:Sendable>(_ onresult:@escaping @Sendable (Result<Value,Error>) -> Result<Other,Error> ) -> Promise<Other>{
        let next = Promise<Other>()
        self.withFinish {
            next.done(onresult(self.result!))
            return .init()
        }
        return next
    }
    
    /// Process success value or failure error after promise comleted
    ///
    ///     let promise = Promise<Int>()
    ///     promise.map{v in
    ///         if _ {
    ///             return .success("\(v*v*v)")
    ///         }else{
    ///             return .failure(some error)
    ///         }
    ///     }.then{ v in
    ///         print(v)
    ///     }.catch{ err in
    ///         print(err)
    ///     }
    ///
    /// - Parameters:
    ///    - onresult: The  handler  after some  result returned. Both success and failure are included.The thread of the handler  depends on the thread of the `done(_:)` method call
    /// - Returns: The next promise in the chain
    @discardableResult
    public func map<Other:Sendable>(_ onresult:@escaping @Sendable (Result<Value,Error>) -> Promise<Other>) -> Promise<Other>{
        let next = Promise<Other>()
        self.withFinish {
            onresult(self.result!).map { r in
                next.done(r)
                return r
            }
            return .init()
        }
        return next
    }
    
    /// Process success value after promise comleted
    /// Be akin to `map(_:)` but process success value only
    ///
    ///     let promise = Promise<Int>()
    ///     promise..then{ v in
    ///         print(v)
    ///         return v*v
    ///     }.catch{ err in
    ///         print(err)
    ///     }
    ///
    /// - Parameters:
    ///    - onresolved: The  value handler  after success value and retrun an other value.The thread of the handler  depends on the thread of the `done(_:)` method call
    /// - Returns: The next promise in the chain
    @discardableResult
    public func then<Other:Sendable>(_ onresolved:@escaping @Sendable (Value) throws -> Other ) -> Promise<Other>{
        self.map { r in
            switch r {
            case .success(let v):
                do {
                    return .success(try onresolved(v))
                }catch{
                    return .failure(error)
                }
            case .failure(let err):
                return .failure(err)
            }
        }
    }
    
    /// Process success value after promise comleted
    /// Be akin to `map(_:)` but process success value only
    ///
    ///     let promise = Promise<Int>()
    ///     promise..then{ v in
    ///         print(v)
    ///         return Promise(v*v)
    ///     }.catch{ err in
    ///         print(err)
    ///     }
    ///
    /// - Parameters:
    ///    - onresolved: The  value handler  after success value and retrun an other promise.The thread of the handler  depends on the thread of the `done(_:)` method call
    /// - Returns: The next promise in the chain
    @discardableResult
    public func then<Other:Sendable>(_ onresolved:@escaping @Sendable (Value)throws -> Promise<Other> ) -> Promise<Other>{
        self.map { r in
            switch r {
            case .success(let v):
                do{
                    return try onresolved(v)
                }catch{
                    return Promise<Other>(error)
                }
            case .failure(let err):
                return Promise<Other>(err)
            }
        }
    }
    
    /// Process failure error after promise comleted.
    /// Be akin to `map(_:)` but process failure error only
    ///
    ///     let promise = Promise<Int>().then{ v in
    ///         print(v)
    ///         return v*v
    ///     }.catch{ err in // print err and keep error
    ///         print(err)
    ///     }.catch{ err in // throw other eror
    ///         throw E.message("some other error")
    ///     }.catch{ err in // resolve error as new success value
    ///         return 100
    ///     }
    ///
    ///     let value = try await promise.wait()
    ///     print(value) // 100
    ///
    ///     ///after some time
    ///     DispatchQueue.global().async{
    ///         promise.done(some error)
    ///     }
    ///
    /// - Parameters:
    ///    - onrejected: The error handler when some error.The thread of the handler  depends on the thread of the `done(_:)` method call
    ///
    /// - Returns: The next promise in the chain
    ///
    /// - Important: `Catch` is designed differently from `Javascript`.
    /// Here we keep the original value type forever so that we can pass the value further down.
    /// We are not allowed to catch an exception and return a new  `type` of `value` at the same time.(At most cases we do not need to)
    /// If you want to return a `value` of a new `type`, use `then(:)` or `map(:)` method before `catch`.
    ///
    /// Then return type of the handler as below:
    /// - `Value`: resolve the error to a new value for same type.
    /// - `Promise<Value>`:  resolve the error to a new value for same type.
    /// - `Error`: map the error to an other.
    /// - `Void`: keep original error.
    /// - `throws`: map the error to an other.
    @discardableResult
    public func `catch`(_ onrejected:@escaping @Sendable (Error)throws -> Any? ) -> Promise<Value>{
        self.map { r in
            switch r {
            case .success(let value):
                return Promise<Value>(value)
            case .failure(let err):
                do {
                    if let v = try onrejected(err){
                        switch v{
                        case let value as Value:// got new value, resolve it
                            return Promise<Value>(value)
                        case let promise as Promise<Value>: // got other promise return it
                            return promise
                        case let newerr as Error:// got new error, trhow it
                            return Promise<Value>(newerr)
                        case _ as Void:// got void, keep orginal error
                            return Promise<Value>(err)
                        default:// got other value, that's fatal error!!.
                            fatalError("Return other type:[\(type(of:v))] not be allowed!! Expect [\(Value.self)] or [\(type(of:self))].")
                        }
                    }
                    return Promise<Value>(err)
                }catch{ // got new error, trhow it
                    return Promise<Value>(error)
                }
            }
        }
    }
    /// Wait for the promise to complete and return the  success value or throw an error
    ///
    ///     func someAsyncMethod(value:Int)->Promise<Int>{
    ///        return Promise { resolve, reject in
    ///            DispatchQueue.global().asyncAfter(deadline: .now()+5){
    ///                if value%2 == 0 {
    ///                    resolve(value/2)
    ///                }else{
    ///                    reject(NSError(domain: "bad error", code: 0))
    ///                }
    ///            }
    ///        }
    ///     }
    ///     /// use async method
    ///     let value = try await someAsyncMethod(5).wait()
    ///     print(value)
    ///
    /// - Returns: A success value
    /// - Throws: A failure error from anywhre
    ///
    @discardableResult
    public func wait() async throws -> Value{
        return try await withUnsafeThrowingContinuation { cont in
            self.finally { r in
                cont.resume(with: r)
            }
        }
    }
}



