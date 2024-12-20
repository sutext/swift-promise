//
//  Promise.swift
//  swift-promise
//
//  Created by supertext on 2024/12/19.
//

///
/// A pattern of asynchronous programming
/// Look at `Javascript` `Promise`  for design ideas
/// It is mainly used when an asynchronous return value is required
///
public final class Promise<Value:Sendable>:@unchecked Sendable{
    private var result:Result<Value,Error>?
    var callbacks:Callbacks = Callbacks()
    
    ///
    /// Create a promise with no resolver or reject
    ///
    /// - Important: The `done(_ :)` method must to be called manually
    ///
    public init(){}
    
    ///
    /// Create a promise and call `done(value)` immediately
    ///
    public init(_ value:Value){
        self.done(value)
    }
    
    ///
    /// Create a promise and call `done(error)` immediately
    ///
    public init(_ error:Error){
        self.done(error)
    }
    
    /// This is the recommended constructor
    ///
    /// - Parameters:
    ///    - initFunc: The init func which well be call immediately
    ///
    /// - Examples:
    ///
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
    public init(_ initFunc:@escaping @Sendable (@escaping @Sendable (Value)->Void,@escaping @Sendable (Error)->Void)->Void){
        initFunc ({ v in
            self.done(v)
        },{ e in
            self.done(e)
        })
    }
    ///
    /// Issue a completion signal indicating that the Promise has been completed with an error
    ///
    public func done(_ error:Error){
        self.done(.failure(error))
    }
    ///
    /// Issue a completion signal indicating that the Promise has been completed with an value
    ///
    public func done(_ value:Value){
        self.done(.success(value))
    }
    
    private func done(_ result:Result<Value,Error>?){
        if self.result == nil{
            self.result = result
            self.callbacks.run()
            self.callbacks = Callbacks()
        }
    }
    private func withFinish(callback:@escaping Callbacks.Element){
        self.addCallback(callback).run()
    }
    private func addCallback(_ callback:@escaping Callbacks.Element)->Callbacks{
        if self.result == nil{
            self.callbacks.append(callback)
            return .empty()
        }
        return callback()
    }
}

extension Promise{
    ///
    /// Process success value or failure error after promise comleted
    ///
    /// - Returns: A new value type promise
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
    @discardableResult
    public func map<Other:Sendable>(_ block:@escaping @Sendable (Result<Value,Error>)->Result<Other,Error> )->Promise<Other>{
        let next = Promise<Other>()
        self.withFinish {
            next.done(block(self.result!))
            return .empty()
        }
        return next
    }
    
    ///
    /// Process success value after promise comleted
    /// Like `map(_:)` but only process success value only
    ///
    /// - Returns: A new value type promise
    ///
    ///     let promise = Promise<Int>()
    ///     promise..then{ v in
    ///         print(v)
    ///         return v*v
    ///     }.catch{ err in
    ///         print(err)
    ///     }
    ///
    @discardableResult
    public func then<Other:Sendable>(_ block:@escaping @Sendable (Value) throws -> Other ) -> Promise<Other>{
        self.map { r in
            switch r {
            case .success(let v):
                do {
                    return .success(try block(v))
                }catch{
                    return .failure(error)
                }
            case .failure(let err):
                return .failure(err)
            }
        }
    }
    
    ///
    /// Process failure error after promise comleted
    /// Like `map(_:)` but only process failure error only
    ///
    /// - Returns: A new value type promise
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
    @discardableResult
    public func `catch`(_ block:@escaping @Sendable (Error)throws -> Any? ) -> Promise<Value>{
        self.map { r in
            switch r {
            case .success(let v):
                return .success(v)
            case .failure(let err):
                do {
                    if let value = try block(err){
                        switch value{
                        case let v as Value:      // got new value, resolve it
                            return .success(v)
                        case let error as Error:  // got new error, trhow it
                            return .failure(error)
                        case _ as Void:           // got void, keep orginal error
                            return .failure(err)
                        default:                  // got other value rethrow UnexpectType error
                            return .failure(UnexpectType(type(of: value)))
                        }
                    }
                    return .failure(err)
                }catch{
                    return .failure(error)
                }
            }
        }
    }
    
    ///
    /// This is where all the call chains end up
    ///
    ///     let promise = Promise<Int>()
    ///     promise.then{v in
    ///
    ///     }.then{ v in
    ///
    ///     }.finally{ result in
    ///
    ///     }
    ///
    ///
    public func finally(_ block:@escaping @Sendable (Result<Value,Error>)->Void ){
        self.withFinish {
            block(self.result!)
            return .empty()
        }
    }
    
    ///
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
    ///
    public func wait() async throws ->Value{
        return try await withUnsafeThrowingContinuation { cont in
            self.finally { r in
                cont.resume(with: r)
            }
        }
    }
}
extension Promise{
    
    ///
    /// Occurs when an error is caught in `catch(_:)`
    ///
    /// - Important: Such a error should neve be happened
    ///
    public struct UnexpectType:Error,CustomStringConvertible{
        private let type:Any.Type
        internal init(_ type:Any.Type){
            self.type = type
        }
        public var description: String{
            "UnexpectType(\(type),expect:\(Value.self))"
        }
    }
}

