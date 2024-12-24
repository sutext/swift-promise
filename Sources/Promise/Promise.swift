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
final public class Promise<Value:Sendable>: @unchecked Sendable{
    
    private let lock = NSLock()
    private var result:Result<Value,Error>?
    private var callbacks:Callbacks = Callbacks()
    /// The promise has been done or not
    public var isDone:Bool {
        lock.lock()
        defer { lock.unlock() }
        return self.result != nil
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
    ///    - initFunc: The init func which well be call immediately
    public init(initFunc:@escaping @Sendable (@escaping @Sendable (Value) -> Void,@escaping @Sendable (Error) -> Void) -> Void){
        initFunc ({ self.done($0) }, { self.done($0) })
    }
    
    /// Issue a completion signal indicating that the Promise has been completed with an error
    /// It has no effect when repeated
    ///
    /// - Parameters:
    ///    - error: done with the failure error result
    ///    - queue: The callback queue if specified, Otherwise depends on the thread of the `done(_:)` method call
    public func done(_ error:Error,in queue:DispatchQueue? = nil){
        if let queue{
            queue.async { self.done(.failure(error)) }
        }else{
            self.done(.failure(error))
        }
    }
    
    /// Issue a completion signal indicating that the Promise has been completed with an value
    /// It has no effect when repeated
    /// - Parameters:
    ///    - value: done with the success value result
    ///    - queue: The callback queue if specified, Otherwise depends on the thread of the `done(_:)` method call
    public func done(_ value:Value,in queue:DispatchQueue? = nil){
        if let queue{
            queue.async { self.done(.success(value)) }
        }else{
            self.done(.success(value))
        }
    }
    
    /// It has no effect when repeated calls.
    /// - Parameters:
    ///    - result: done with the result
    public func done(_ result:Result<Value,Error>){
        lock.lock()
        defer { lock.unlock() }
        if self.result == nil{
            self.result = result
            self.callbacks.run()
            self.callbacks = Callbacks()
        }
    }
    /// Add finish callback
    /// - Parameters:
    ///    - callback: done with the result
    private func withFinish(callback:@escaping Callbacks.Element){
        lock.lock()
        defer { lock.unlock() }
        if self.result == nil{
            self.callbacks.append(callback)
        }else{
            callback().run()
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
    ///    - handler: The  handler  after some  result returned. Both success and failure are included.The thread of the handler  depends on the thread of the `done(_:)` method call
    /// - Returns: The next promise in the chain
    @discardableResult
    public func map<Other:Sendable>(_ handler:@escaping @Sendable (Result<Value,Error>) -> Result<Other,Error> ) -> Promise<Other>{
        let next = Promise<Other>()
        self.withFinish {
            next.done(handler(self.result!))
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
    ///    - handler: The  handler  after some  result returned. Both success and failure are included.The thread of the handler  depends on the thread of the `done(_:)` method call
    /// - Returns: The next promise in the chain
    @discardableResult
    public func map<Other:Sendable>(_ handler:@escaping @Sendable (Result<Value,Error>) -> Promise<Other>) -> Promise<Other>{
        let next = Promise<Other>()
        self.withFinish {
            handler(self.result!).map { r in
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
    ///    - handler: The  value handler  after success value and retrun an other value.The thread of the handler  depends on the thread of the `done(_:)` method call
    /// - Returns: The next promise in the chain
    @discardableResult
    public func then<Other:Sendable>(_ handler:@escaping @Sendable (Value) throws -> Other ) -> Promise<Other>{
        self.map { r in
            switch r {
            case .success(let v):
                do {
                    return .success(try handler(v))
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
    ///    - handler: The  value handler  after success value and retrun an other promise.The thread of the handler  depends on the thread of the `done(_:)` method call
    /// - Returns: The next promise in the chain
    @discardableResult
    public func then<Other:Sendable>(_ handler:@escaping @Sendable (Value)throws -> Promise<Other> ) -> Promise<Other>{
        self.map { r in
            switch r {
            case .success(let v):
                do{
                    return try handler(v)
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
    ///     ///after some time
    ///     promise.done(some error)
    ///
    /// - Parameters:
    ///    - handler: The error handler when some error.The thread of the handler  depends on the thread of the `done(_:)` method call
    ///
    /// Then return type of the handler can be
    /// - `Value`: resolve the error to a new value.
    /// - `Promise<Value>`: resolve the error to a new async promise
    /// - `Error`: map the error to an other
    /// - `throws`: map the error to an other
    /// - `Void`: keep original error
    ///
    /// - Returns: The next promise in the chain
    @discardableResult
       public func `catch`(_ handler:@escaping @Sendable (Error)throws -> Any? ) -> Promise<Value>{
           self.map { r in
               switch r {
               case .success(let v):
                   return Promise<Value>(v)
               case .failure(let err):
                   do {
                       if let value = try handler(err){
                           switch value{
                           case let v as Value:      // got new value, resolve it
                               return Promise<Value>(v)
                           case let pro as Promise<Value>: // got other promise return it
                               return pro
                           case let error as Error:  // got new error, trhow it
                               return Promise<Value>(error)
                           case _ as Void:           // got void, keep orginal error
                               return Promise<Value>(err)
                           default:                  // got other value rethrow UnexpectType error
                               return Promise<Value>(UnexpectType(type(of: value)))
                           }
                       }
                       return Promise<Value>(err)
                   }catch{
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
    public func wait() async throws -> Value{
        return try await withUnsafeThrowingContinuation { cont in
            self.finally { r in
                cont.resume(with: r)
            }
        }
    }
    
}
extension Promise{
    
    /// Occurs when an error is caught in `catch(_:)`
    ///
    /// - Important: In theory, such errors should not exist
    /// - Important: The developers need to ensure that the correct data type is returned in `catch(_:)`
    public struct UnexpectType:Error,CustomStringConvertible{
        private let type:Any.Type
        internal init(_ type:Any.Type){
            self.type = type
        }
        public var description: String{
            "UnexpectType(\(type),expect:\(Value.self) or \(Promise<Value>.self)"
        }
    }
}




