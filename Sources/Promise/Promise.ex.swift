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
    ///    - initializer: The init func which well be call immediately
    public convenience init(initializer:@escaping @Sendable () async throws -> Value){
        self.init()
        Task{
            do {
                let v = try await initializer()
                self.done(v)
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
    ///    - initializer: The init func which well be call immediately
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
    /// Create a new promise from the existing promise list, which will wait until all the promises are complete
    /// All children promises are executed concurrently
    /// - Parameters:
    ///   - p1:The first promise
    ///   - p2:The second promise
    public convenience init<V1,V2>(_ p1:Promise<V1>, _ p2:Promise<V2>) where Value == (V1,V2){
        self.init()
        Task{
            do{
                let v1 = try await p1.wait()
                let v2 = try await p2.wait()
                self.done((v1,v2))
                
            }catch{
                self.done(error)
            }
        }
    }
    /// Create a new promise from the existing promise list, which will wait until all the promises are complete
    /// All children promises are executed concurrently
    /// - Parameters:
    ///   - p1:The first promise
    ///   - p2:The second promise and so on ...
    ///   - p3:The third promise and so on ...
    public convenience init<V1,V2,V3>(_ p1:Promise<V1>, _ p2:Promise<V2>,_ p3:Promise<V3>) where Value == (V1,V2,V3){
        self.init()
        Task{
            do{
                let v1 = try await p1.wait()
                let v2 = try await p2.wait()
                let v3 = try await p3.wait()
                self.done((v1,v2,v3))
            }catch{
                self.done(error)
            }
        }
    }
    /// Create a new promise from the existing promise list, which will wait until all the promises are complete
    /// All children promises are executed concurrently
    /// - Parameters:
    ///   - p1:The first promise
    ///   - p2:The second promise
    ///   - p3:The third promise and so on ...
    public convenience init<V1,V2,V3,V4>(
        _ p1:Promise<V1>,
        _ p2:Promise<V2>,
        _ p3:Promise<V3>,
        _ p4:Promise<V4>)where Value == (V1,V2,V3,V4){
        self.init()
        Task{
            do{
                let v1 = try await p1.wait()
                let v2 = try await p2.wait()
                let v3 = try await p3.wait()
                let v4 = try await p4.wait()
                self.done((v1,v2,v3,v4))
            }catch{
                self.done(error)
            }
        }
    }

    /// Create a new promise from the existing promise list, which will wait until all the promises are complete
    /// All children promises are executed concurrently
    /// - Parameters:
    ///   - p1:The first promise
    ///   - p2:The second promise
    ///   - p3:The third promise and so on ...
    public convenience init<V1,V2,V3,V4,V5>(
        _ p1:Promise<V1>,
        _ p2:Promise<V2>,
        _ p3:Promise<V3>,
        _ p4:Promise<V4>,
        _ p5:Promise<V5>)where Value == (V1,V2,V3,V4,V5){
        self.init()
        Task{
            do{
                let v1 = try await p1.wait()
                let v2 = try await p2.wait()
                let v3 = try await p3.wait()
                let v4 = try await p4.wait()
                let v5 = try await p5.wait()
                self.done((v1,v2,v3,v4,v5))
            }catch{
                self.done(error)
            }
        }
    }

    /// Create a new promise from the existing promise list, which will wait until all the promises are complete
    /// All children promises are executed concurrently
    /// - Parameters:
    ///   - p1:The first promise
    ///   - p2:The second promise
    ///   - p3:The third promise and so on ...
    public convenience init<V1,V2,V3,V4,V5,V6>(
        _ p1:Promise<V1>,
        _ p2:Promise<V2>,
        _ p3:Promise<V3>,
        _ p4:Promise<V4>,
        _ p5:Promise<V5>,
        _ p6:Promise<V6>)where Value == (V1,V2,V3,V4,V5,V6){
        self.init()
        Task{
            do{
                let v1 = try await p1.wait()
                let v2 = try await p2.wait()
                let v3 = try await p3.wait()
                let v4 = try await p4.wait()
                let v5 = try await p5.wait()
                let v6 = try await p6.wait()
                self.done((v1,v2,v3,v4,v5,v6))
            }catch{
                self.done(error)
            }
        }
    }

    /// Create a new promise from the existing promise list, which will wait until all the promises are complete
    /// All children promises are executed concurrently
    /// - Parameters:
    ///   - p1:The first promise
    ///   - p2:The second promise
    ///   - p3:The third promise and so on ...
    public convenience init<V1,V2,V3,V4,V5,V6,V7>(
        _ p1:Promise<V1>,
        _ p2:Promise<V2>,
        _ p3:Promise<V3>,
        _ p4:Promise<V4>,
        _ p5:Promise<V5>,
        _ p6:Promise<V6>,
        _ p7:Promise<V7>)where Value == (V1,V2,V3,V4,V5,V6,V7){
        self.init()
        Task{
            do{
                let v1 = try await p1.wait()
                let v2 = try await p2.wait()
                let v3 = try await p3.wait()
                let v4 = try await p4.wait()
                let v5 = try await p5.wait()
                let v6 = try await p6.wait()
                let v7 = try await p7.wait()
                self.done((v1,v2,v3,v4,v5,v6,v7))
            }catch{
                self.done(error)
            }
        }
    }

    /// Create a new promise from the existing promise list, which will wait until all the promises are complete
    /// All children promises are executed concurrently
    /// - Parameters:
    ///   - p1:The first promise
    ///   - p2:The second promise
    ///   - p3:The third promise and so on ...
    public convenience init<V1,V2,V3,V4,V5,V6,V7,V8>(
        _ p1:Promise<V1>,
        _ p2:Promise<V2>,
        _ p3:Promise<V3>,
        _ p4:Promise<V4>,
        _ p5:Promise<V5>,
        _ p6:Promise<V6>,
        _ p7:Promise<V7>,
        _ p8:Promise<V8>)where Value == (V1,V2,V3,V4,V5,V6,V7,V8){
        self.init()
        Task{
            do{
                let v1 = try await p1.wait()
                let v2 = try await p2.wait()
                let v3 = try await p3.wait()
                let v4 = try await p4.wait()
                let v5 = try await p5.wait()
                let v6 = try await p6.wait()
                let v7 = try await p7.wait()
                let v8 = try await p8.wait()
                self.done((v1,v2,v3,v4,v5,v6,v7,v8))
            }catch{
                self.done(error)
            }
        }
    }
}
