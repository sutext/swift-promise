import Testing
import Dispatch
import Foundation
@testable import Promise

enum E:Error{
    case message(String)
}

@Test func test1() async throws {
    let t1:TimeInterval = Date.now.timeIntervalSince1970
    let v = try await Promise<Int>(4)
        .then { i in
            if i%2 == 0{
                return "\(i*i)"
            }
            throw E.message("Some truble")
        }
        .then{ s in
            return Promise{resolve,reject in
                DispatchQueue(label: "q3").asyncAfter(deadline: .now()+5){
                    resolve("\(s)\(s)")
                }
            }
        }
        .then{ str in
            if let i = Int(str){
                return i
            }
            throw E.message("Transfer Error")
        }
        .then{ i in
            ///
            return 100
        }
        .catch{ err in // print err and keep error
            return Promise{resolve,reject in
                DispatchQueue(label: "q4").asyncAfter(deadline: .now()+5){
                    resolve(100)
                }
                DispatchQueue(label: "q5").asyncAfter(deadline: .now()+5){
                    reject(err)
                }
            }
        }
        .catch{ err in // throw other
            print("Last pre: \(err)")
            throw E.message("some other error")
        }
        .catch{ err in
            print("Last: \(err)")
            return 100
        }
        .wait()
    let t2:TimeInterval = Date.now.timeIntervalSince1970
    print("value:",v,"cost:",(t2-t1))
    assert(v == 100)
}

@MainActor func updateUI(_ i:Int){
    print("update some ui in main")
}
@Test func uiTest() async throws {
    let promise = Promise { resolve, reject in
        DispatchQueue(label: "q1").asyncAfter(deadline: .now()+5){
            resolve(205)
        }
        DispatchQueue.global().asyncAfter(deadline: .now()+5){
            reject(E.message("global rejected"))
        }
        DispatchQueue.main.asyncAfter(deadline: .now()+5){
            resolve(203)
        }
        DispatchQueue(label: "q2").asyncAfter(deadline: .now()+5){
            resolve(207)
        }
    }
    
    promise.then { i in
        return i * i
    }.then { i in
        await updateUI(i)
    }
    try await Task.sleep(nanoseconds: 6_000_000_000)
}
@Test func test2()async throws{
    let promise = Promise { resolve, reject in
        DispatchQueue(label: "q1").asyncAfter(deadline: .now()+5){
            resolve(205)
        }
    }
    let v = try await promise.wait()
    print(v)
}
@Test func request()async throws{
    let p0 = request0()
    let v0 = try await p0.then(request1).wait()
    let v1 = try await p0.then(request1).then(request2).wait()
    let v2 = try await p0.then(request1).then(request2).then(request3).wait()
    print("v0=",v0,"v1=",v1,"v2=",v2)
    assert(v2 == 103)
}

@Sendable func request0()->Promise<Int>{
    Promise{ resolve,reject in
        DispatchQueue(label: "async task").asyncAfter(deadline: .now()+0.5){
            resolve(100)
        }
    }
}
@Sendable func request1(_ p:Int)->Promise<Int>{
    return Promise{ resolve,reject in
        DispatchQueue(label: "async task").asyncAfter(deadline: .now()+1){
            if p == 100{
                resolve(101)
            }else{
                reject(E.message("parameter error"))
            }
        }
    }
}
@Sendable func request2(_ p:Int)->Promise<Int>{
    return Promise{ resolve,reject in
        DispatchQueue(label: "async task").asyncAfter(deadline: .now()+2){
            if p == 101{
                resolve(102)
            }else{
                reject(E.message("parameter error"))
            }
        }
    }
}
@Sendable func request3(_ p:Int)->Promise<Int>{
    return Promise{ resolve,reject in
        DispatchQueue(label: "async task").asyncAfter(deadline: .now()+3){
            if p == 102{
                resolve(103)
            }else{
                reject(E.message("parameter error"))
            }
        }
    }
}
@Test func requestAll()async throws{
    let values = try await PromiseAll(request0(), request0(), request0(), request0(), request0()).wait()
    print(values)
    assert(values == (100,100,100,100,100))
}

struct TestSafely{
    var v1:String
    var v2:String
}
struct TestSafely2{
    var v1:String
    var v2:String
    var v3:TestSafely
}

@Test func testSafely(){
    let t1 = TestSafely(v1: "1", v2: "2")
    let safe1 = Safely<Dictionary<String,String>>(wrappedValue: [:])
    let safe2 = Safely<TestSafely2>(wrappedValue: .init(v1: "1", v2: "2",v3: t1))
    print(safe1["test"] == nil)
    assert(safe2.v3.v1 == "1")
}
