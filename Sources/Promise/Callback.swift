//
//  Callback.swift
//  swift-promise
//
//  Created by supertext on 2024/12/20.
//

/// A usefull callback chains
/// Add any callback you want, and run it some times.
@usableFromInline
struct Callbacks: Sendable {
    @usableFromInline
    typealias Element = @Sendable () -> Callbacks
    @usableFromInline
    var first: Element?
    @usableFromInline
    var furthers: [Element]?
    @inlinable
    init() {
        self.first = nil
        self.furthers = nil
    }
    @inlinable
    init(_ ele:@escaping Element) {
        self.first = ele
        self.furthers = nil
    }
    @inlinable
    mutating func append(_ callback: @escaping Element) {
        if self.first == nil {
            self.first = callback
        } else {
            if self.furthers != nil {
                self.furthers!.append(callback)
            } else {
                self.furthers = [callback]
            }
        }
    }
    @inlinable
    func all() -> ArraySlice<Element> {
        switch (self.first, self.furthers) {
        case (.none, _):
            return []
        case (.some(let only), .none):
            return [only]
        default:
            var array: ArraySlice<Element> = .init()
            self.putAll(into:&array)
            return array
        }
    }
    @inlinable
    func putAll(into array: inout ArraySlice<Element>) {
        switch (self.first, self.furthers) {
        case (.none, _):
            return
        case (.some(let only), .none):
            array.append(only)
        case (.some(let first), .some(let others)):
            array.reserveCapacity(array.count + 1 + others.count)
            array.append(first)
            array.append(contentsOf: others)
        }
    }
    @inlinable
    func run() {
        switch (self.first, self.furthers) {
        case (.none, _):
            return
        case (.some(let only), .none):
            var onlyvar = only
            loop: while true {
                let cbl = onlyvar()
                switch (cbl.first, cbl.furthers) {
                case (.none, _):
                    break loop
                case (.some(let ocb), .none):
                    onlyvar = ocb
                    continue loop
                case (.some(_), .some(_)):
                    var pending = cbl.all()
                    while let f = pending.popLast() {
                        let next = f()
                        next.putAll(into:&pending)
                    }
                    break loop
                }
            }
        default:
            var pending = self.all()
            while let f = pending.popFirst() {
                let next = f()
                next.putAll(into:&pending)
            }
        }
    }
}
