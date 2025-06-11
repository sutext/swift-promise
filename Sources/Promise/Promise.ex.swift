//
//  Promise.ex.swift
//  swift-promise
//
//  Created by supertext on 2025/4/17.
//

extension Promise{
    /// A recommended constructor of async function to Promise
    ///
    ///     func asyncFunc(_ value:Int)->Promise<Int>{
    ///        return Promise {
    ///             let v1 = try await asyncFunc1()
    ///             let v2 = try await asyncFunc2()
    ///             return((v1,v2))
    ///        }
    ///     }
    ///     func asyncFunc1()async throws->Int{
    ///         return 1
    ///     }
    ///     func asyncFunc2()async throws->Int{
    ///         return 1
    ///     }
    ///     /// use callback
    ///     asyncFunc(2)
    ///         .then{value in
    ///             print(value)
    ///         }
    ///         .catch{err in
    ///             print(err)
    ///         }
    ///     /// use async method
    ///     let value = try await asyncFunc(5).wait()
    ///     print(value)
    ///
    /// - Parameters:
    ///    - initializer: The init func which well be call asynchronous  immediately
    public convenience init(initializer:@escaping @Sendable () async throws -> Value){
        self.init()
        Task{
            do {
                self.done(try await initializer())
            }catch{
                self.done(error)
            }
        }
    }
    /// A recommended constructor of callback function to Promise
    ///
    ///     func asyncFunc(_ value:Int)->Promise<Int>{
    ///        return Promise {done in
    ///            DispatchQueue.global().asyncAfter(deadline: .now()+5){
    ///                if value%2 == 0 {
    ///                    done(.success(value/2))
    ///                }else{
    ///                    done(.failure(NSError()))
    ///                }
    ///            }
    ///        }
    ///     }
    ///
    ///     asyncFunc(2)
    ///         .then{value in
    ///             print(value)
    ///         }
    ///         .catch{err in
    ///             print(err)
    ///         }
    ///     /// use async method
    ///     let value = try await asyncFunc(5).wait()
    ///     print(value)
    ///
    /// - Parameters:
    ///    - initializer: The init func which well be call asynchronous immediately
    public convenience init(initializer:@escaping @Sendable (@escaping @Sendable (Result<Value,Error>) -> Void) async throws -> Void){
        self.init()
        Task{
            do {
                try await initializer ({ self.done($0) })
            }catch{
                self.done(error)
            }
        }
    }
}
/// Create a new promise from the existing promise tuple, which will wait until all the promises are complete
/// All children promises are executed concurrently
///
///     @Sendable func request(_ value:Int)->Promise<Int>{
///         Promise{ done in
///             DispatchQueue(label: "async task").asyncAfter(deadline: .now()+0.5){
///                 done(.success(value))
///             }
///         }
///     }
///     let p1 = request(1)
///     let p2 = reqiest(2)
///     let p3 = request(3)
///     let values = try await Promises(p1,p2,p3).wait() // tuple value (1,2,3)
///
/// - Parameters:
///   - ps:The promses
/// - Returns: Promise of tuple value
public func Promises<each Value>(_ ps:repeat Promise<each Value>)->Promise<(repeat each Value)>{
    Promise{
        (repeat try await (each ps).wait())
    }
}
/// Create a new promise from the existing promise array, which will wait until all the promises are complete
/// All children promises are executed concurrently
///
///     @Sendable func request(_ value:Int)->Promise<Int>{
///         Promise{ done in
///             DispatchQueue(label: "async task").asyncAfter(deadline: .now()+0.5){
///                 done(.success(value))
///             }
///         }
///     }
///     let p1 = request(1)
///     let p2 = reqiest(2)
///     let p3 = request(3)
///     let values = try await Promises([p1,p2,p3]).wait() // array value [1,2,3]
////// - Parameters:
///   - ps:The promse array
/// - Returns: Promise of array value
public func Promises<Value>(_ ps:[Promise<Value>])->Promise<[Value]>{
    Promise{
        var values:[Value] = []
        for p in ps {
            let v = try await p.wait()
            values.append(v)
        }
        return values
    }
}
