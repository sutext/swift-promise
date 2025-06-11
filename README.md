# swift-promise
![Platform](https://img.shields.io/badge/platforms-iOS%2013.0%20%7C%20macOS%2010.15%20%7C%20tvOS%2013.0%20%7C%20watchOS%206.0-F28D00.svg)
- A pattern of asynchronous programming
- Look at `Javascript` `Promise`  for design ideas
- It is mainly used when an asynchronous return value is required

## Requirements

- iOS 13.0+ | macOS 10.15+ | tvOS 13.0+ | watchOS 6.0+
- Xcode 8

## Integration

#### Swift Package Manager

You can use [The Swift Package Manager](https://swift.org/package-manager) to install `swift-promise` by adding the proper description to your `Package.swift` file:

```swift
// swift-tools-version:5.8
import PackageDescription

let package = Package(
    name: "YOUR_PROJECT_NAME",
    dependencies: [
        .package(url: "https://github.com/sutext/swift-promise.git", from: "2.1.0"),
    ]
)
```

### Usage

```swift

    let promise = Promise { done in
        DispatchQueue.global().asyncAfter(deadline: .now()+5){
            done(.success(200))
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
### Perform async opration and update UI Interface
```swift

import UIKit
import Promise

class ViewController:UIViewController{
    override func viewDidLoad(){
        super.viewDidLoad()
        requestData().then{
            try await self.updateUI($0)
        }
    }
    func requestData()->Promise<Data>{
        Promise{done
            DispatchQueue.global().async{
                ///got network data
                done(.success(data))
            }
        }
    }
    @MainActor func updateUI(_ data:Data){
    
    }
}

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

    let values = try await Promises(request0(), request0(), request0(), request0(), request0(),queue: .main).wait()
    print(values)
    assert(values == (100,100,100,100,100))

```
