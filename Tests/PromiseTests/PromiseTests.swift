import Testing
import Dispatch
import Foundation
@testable import Promise

enum E:Error{
    case message(String)
}

@Test func test1() async throws {
    let t1:TimeInterval = Date.now.timeIntervalSince1970
    let p = Promise<Int>(4)
        .then { i in
            if i%2 == 0{
                return "\(i*i)"
            }
            throw E.message("Some truble")
        }
        .then{ s in
            return Promise{done in
                DispatchQueue(label: "q3").asyncAfter(deadline: .now()+5){
                    done(.success("\(s)\(s)"))
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
            return Promise{done in
                DispatchQueue(label: "q4").asyncAfter(deadline: .now()+5){
                    done(.success(100))
                }
                DispatchQueue(label: "q5").asyncAfter(deadline: .now()+5){
                    done(.failure(err))
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
    let v = try await p.wait()
    let t2:TimeInterval = Date.now.timeIntervalSince1970
    print("value:",v,"cost:",(t2-t1))
    assert(p.isDone)
    assert(v == 100)
}

@MainActor func updateUI(_ i:Int){
    print("update some ui in main")
}
@Test func uiTest() async throws {
    let promise = Promise { done in
        DispatchQueue(label: "q1").asyncAfter(deadline: .now()+5){
            done(.success(205))
        }
        DispatchQueue.global().asyncAfter(deadline: .now()+5){
            done(.failure(E.message("parameter error")))
        }
        DispatchQueue.main.asyncAfter(deadline: .now()+5){
            done(.success(203))
        }
        DispatchQueue(label: "q2").asyncAfter(deadline: .now()+5){
            done(.success(207))
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
    let promise = Promise { done in
        DispatchQueue(label: "q1").asyncAfter(deadline: .now()+5){
            done(.success(205))
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
    Promise{ done in
        DispatchQueue(label: "async task").asyncAfter(deadline: .now()+0.5){
            done(.success(100))
        }
    }
}
@Sendable func request1(_ p:Int)->Promise<Int>{
    return Promise{ done in
        DispatchQueue(label: "async task").asyncAfter(deadline: .now()+1){
            if p == 100{
                done(.success(101))
            }else{
                done(.failure(E.message("parameter error")))
            }
        }
    }
}
@Sendable func request2(_ p:Int)->Promise<Int>{
    return Promise{ done in
        DispatchQueue(label: "async task").asyncAfter(deadline: .now()+2){
            if p == 101{
                done(.success(102))
            }else{
                done(.failure(E.message("parameter error")))
            }
        }
    }
}
@Sendable func request3(_ p:Int)->Promise<Int>{
    return Promise{ done in
        DispatchQueue(label: "async task").asyncAfter(deadline: .now()+3){
            if p == 102{
                done(.success(103))
            }else{
                done(.failure(E.message("parameter error")))
            }
        }
    }
}
func asyncFunc(fun: ()->Void){
    fun()
}
@Test func requestAll()async throws{
    let p1 = Promise{done in
        let v1 = try await request0().wait()
        let v2 = try await request0().wait()
        let v3 = try await request0().wait()
        let v4 = try await request0().wait()
        let v5 = try await request0().wait()
        asyncFunc {
            done(.success((v1,v2,v3,v4,v5)))
        }
    }
    print(try await p1.wait())//cost 5s
    let p2 = Promise{
        let v1 = try await request0().wait()
        let v2 = try await request0().wait()
        let v3 = try await request0().wait()
        let v4 = try await request0().wait()
        let v5 = try await request0().wait()
        return (v1,v2,v3,v4,v5)
    }
    print(try await p2.wait()) // cost 5ss
    let values = try await Promise(request0(), request0(), request0(), request0(), request0()).wait()
    print(values)
    assert(values == (100,100,100,100,100))//cost 0.5s
}
@Test func requestAll1()async throws{
    let p1 = request0()
    let p2 = request0()
    let p3 = request0()
    let p4 = request0()
    let p5 = request0()
    let v1 = try await Promise{done in
        let v1 =  try await p1.wait()
        let v2 =  try await p2.wait()
        let v3 =  try await p3.wait()
        let v4 =  try await p4.wait()
        let v5 =  try await p5.wait()
        asyncFunc {
            done(.success((v1,v2,v3,v4,v5)))
        }
    }.wait()
    
    print(v1)
    let v2 = try await Promise{
        let v1 =  try await p1.wait()
        let v2 =  try await p2.wait()
        let v3 =  try await p3.wait()
        let v4 =  try await p4.wait()
        let v5 =  try await p5.wait()
        return (v1,v2,v3,v4,v5)
    }.wait()
    
    print(v2)
    let values = try await Promise(p1,p2,p3,p4,p5).wait()
    print(values)
    assert(values == (100,100,100,100,100))//cost 0.5s
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
