//
//  PromiseAll.swift
//  swift-promise
//
//  Created by supertext on 2024/12/24.
//

import Foundation

/// Create a new promise from the existing promise list, which will wait until all the promises are complete
/// - Parameters:
///   - p1:The first promise
///   - p2:The second promise
///   - p3:The third promise and so on ...
///   - queue: The callback queue if specified. Otherwise it will be executed on the global queue
public func PromiseAll<V1,V2>(
    _ p1:Promise<V1>,
    _ p2:Promise<V2>,
    in queue:DispatchQueue? = nil)->Promise<(V1,V2)>{
    let next = Promise<(V1,V2)>()
    Task{
        do{
            let v1 = try await p1.wait()
            let v2 = try await p2.wait()
            next.done((v1,v2),in: queue)
        }catch{
            next.done(error,in: queue)
        }
    }
    return next
}

/// Create a new promise from the existing promise list, which will wait until all the promises are complete
/// - Parameters:
///   - p1:The first promise
///   - p2:The second promise and so on ...
///   - queue: The callback queue if specified. Otherwise it will be executed on the global queue
public func PromiseAll<V1,V2,V3>(
    _ p1:Promise<V1>,
    _ p2:Promise<V2>,
    _ p3:Promise<V3>,
    in queue:DispatchQueue? = nil)->Promise<(V1,V2,V3)>{
    let next = Promise<(V1,V2,V3)>()
    Task{
        do{
            let v1 = try await p1.wait()
            let v2 = try await p2.wait()
            let v3 = try await p3.wait()
            next.done((v1,v2,v3),in: queue)
        }catch{
            next.done(error,in: queue)
        }
    }
    return next
}

/// Create a new promise from the existing promise list, which will wait until all the promises are complete
/// - Parameters:
///   - p1:The first promise
///   - p2:The second promise
///   - p3:The third promise and so on ...
///   - queue: The callback queue if specified. Otherwise it will be executed on the global queue
public func PromiseAll<V1,V2,V3,V4>(
    _ p1:Promise<V1>,
    _ p2:Promise<V2>,
    _ p3:Promise<V3>,
    _ p4:Promise<V4>,
    in queue:DispatchQueue? = nil)->Promise<(V1,V2,V3,V4)>{
    let next = Promise<(V1,V2,V3,V4)>()
    Task{
        do{
            let v1 = try await p1.wait()
            let v2 = try await p2.wait()
            let v3 = try await p3.wait()
            let v4 = try await p4.wait()
            next.done((v1,v2,v3,v4),in: queue)
        }catch{
            next.done(error,in: queue)
        }
    }
    return next
}

/// Create a new promise from the existing promise list, which will wait until all the promises are complete
/// - Parameters:
///   - p1:The first promise
///   - p2:The second promise
///   - p3:The third promise and so on ...
///   - queue: The callback queue if specified. Otherwise it will be executed on the global queue
public func PromiseAll<V1,V2,V3,V4,V5>(
    _ p1:Promise<V1>,
    _ p2:Promise<V2>,
    _ p3:Promise<V3>,
    _ p4:Promise<V4>,
    _ p5:Promise<V5>,
    in queue:DispatchQueue? = nil)->Promise<(V1,V2,V3,V4,V5)>{
    let next = Promise<(V1,V2,V3,V4,V5)>()
    Task{
        do{
            let v1 = try await p1.wait()
            let v2 = try await p2.wait()
            let v3 = try await p3.wait()
            let v4 = try await p4.wait()
            let v5 = try await p5.wait()
            next.done((v1,v2,v3,v4,v5),in: queue)
        }catch{
            next.done(error,in: queue)
        }
    }
    return next
}

/// Create a new promise from the existing promise list, which will wait until all the promises are complete
/// - Parameters:
///   - p1:The first promise
///   - p2:The second promise
///   - p3:The third promise and so on ...
///   - queue: The callback queue if specified. Otherwise it will be executed on the global queue
public func PromiseAll<V1,V2,V3,V4,V5,V6>(
    _ p1:Promise<V1>,
    _ p2:Promise<V2>,
    _ p3:Promise<V3>,
    _ p4:Promise<V4>,
    _ p5:Promise<V5>,
    _ p6:Promise<V6>,
    in queue:DispatchQueue? = nil)->Promise<(V1,V2,V3,V4,V5,V6)>{
    let next = Promise<(V1,V2,V3,V4,V5,V6)>()
    Task{
        do{
            let v1 = try await p1.wait()
            let v2 = try await p2.wait()
            let v3 = try await p3.wait()
            let v4 = try await p4.wait()
            let v5 = try await p5.wait()
            let v6 = try await p6.wait()
            next.done((v1,v2,v3,v4,v5,v6),in: queue)
        }catch{
            next.done(error,in: queue)
        }
    }
    return next
}

/// Create a new promise from the existing promise list, which will wait until all the promises are complete
/// - Parameters:
///   - p1:The first promise
///   - p2:The second promise
///   - p3:The third promise and so on ...
///   - queue: The callback queue if specified. Otherwise it will be executed on the global queue
public func PromiseAll<V1,V2,V3,V4,V5,V6,V7>(
    _ p1:Promise<V1>,
    _ p2:Promise<V2>,
    _ p3:Promise<V3>,
    _ p4:Promise<V4>,
    _ p5:Promise<V5>,
    _ p6:Promise<V6>,
    _ p7:Promise<V7>,
    in queue:DispatchQueue? = nil)->Promise<(V1,V2,V3,V4,V5,V6,V7)>{
    let next = Promise<(V1,V2,V3,V4,V5,V6,V7)>()
    Task{
        do{
            let v1 = try await p1.wait()
            let v2 = try await p2.wait()
            let v3 = try await p3.wait()
            let v4 = try await p4.wait()
            let v5 = try await p5.wait()
            let v6 = try await p6.wait()
            let v7 = try await p7.wait()
            next.done((v1,v2,v3,v4,v5,v6,v7),in: queue)
        }catch{
            next.done(error,in: queue)
        }
    }
    return next
}

/// Create a new promise from the existing promise list, which will wait until all the promises are complete
/// - Parameters:
///   - p1:The first promise
///   - p2:The second promise
///   - p3:The third promise and so on ...
///   - queue: The callback queue if specified. Otherwise it will be executed on the global queue
public func PromiseAll<V1,V2,V3,V4,V5,V6,V7,V8>(
    _ p1:Promise<V1>,
    _ p2:Promise<V2>,
    _ p3:Promise<V3>,
    _ p4:Promise<V4>,
    _ p5:Promise<V5>,
    _ p6:Promise<V6>,
    _ p7:Promise<V7>,
    _ p8:Promise<V8>,
    in queue:DispatchQueue? = nil)->Promise<(V1,V2,V3,V4,V5,V6,V7,V8)>{
    let next = Promise<(V1,V2,V3,V4,V5,V6,V7,V8)>()
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
            next.done((v1,v2,v3,v4,v5,v6,v7,v8),in: queue)
        }catch{
            next.done(error,in: queue)
        }
    }
    return next
}
