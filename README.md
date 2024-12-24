# swift-promise

### Introduce

- A pattern of asynchronous programming
- Look at `Javascript` `Promise`  for design ideas
- It is mainly used when an asynchronous return value is required

### Usage

```swift

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

```

### Simulate a sequential request network

```swift 

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

    let v = try await request1(100).then(request2).then(request3).wait()
    print("value:",v)
    assert(v == 103)

    let values = try await PromiseAll(request0(), request0(), request0(), request0(), request0(),queue: .main).wait()
    print(values)
    assert(values == (100,100,100,100,100))

```
