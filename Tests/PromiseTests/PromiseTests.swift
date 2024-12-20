import Testing
import Dispatch
@testable import Promise

enum E:Error{
    case message(String)
}

@Test func example() async throws {

    let promise = Promise { resolve, reject in
        DispatchQueue.global().asyncAfter(deadline: .now()+5){
            resolve(200)
        }
    }
    let v = try await promise
        .then { i in
            if i%2 == 0{
                return "\(i*i)"
            }
            throw E.message("Some truble")
        }
        .then({ s in
            return "\(s)\(s)"
        })
        .then({ str in
            if let i = Int(str){
                return i
            }
            throw E.message("Transfer Error")
        })
        .then({ i in
            return i + 1
        })
        .catch({ err in // print err and keep error
            print(err)
        })
        .catch({ err in // throw other
            throw E.message("some other error")
        })
        .catch({ err in
            return 100
        })
        .wait()
    print("value:",v)
}
