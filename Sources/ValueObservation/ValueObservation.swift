// The Swift Programming Language
// https://docs.swift.org/swift-book

@_exported import Observation
@_exported import Foundation

#if $Macros && hasAttribute(attached)

public protocol ObservableValue: Observable {
    /// ID used to calculate whether system should send observation notifications
    var _$id: UUID { get }

    /// Use this function to create a detached copy of the value if you do not want to trigger notifications being sent by the copy.
    ///
    /// ```swift
    /// // does not trigger notifications
    /// var copy = foo.copy()
    /// copy.bar = baz
    ///
    /// // triggers notifications
    /// var copy = foo
    /// copy.bar = baz
    /// ```
    func copy() -> Self
}

@inlinable
public func _$idEqual<T: ObservableValue>(_ lhs: T, _ rhs: T) -> Bool {
    lhs._$id == rhs._$id
}

@inlinable
public func _$idEqual<T>(_ lhs: T, _ rhs: T) -> Bool {
    guard
        let lhs = lhs as? ObservableValue,
        let rhs = rhs as? ObservableValue
    else {
        return false
    }

    return lhs._$id == rhs._$id
}

@inlinable
public func _$isObservable<T: ObservableValue>(_ value: T) -> Bool {
    return true
}

@inlinable
public func _$isObservable<T>(_ value: T) -> Bool {
    value is any ObservableValue
}

@attached(
    member,
    names: named(_$id),
    named(_$observationRegistrar),
    named(copy),
    named(access),
    named(withMutation),
    named(shouldNotifyObservers)
)
@attached(memberAttribute)
@attached(extension, conformances: ObservableValue)
public macro ObservableValue() =
  #externalMacro(module: "ValueObservationMacros", type: "ObservableValueMacro")

@attached(accessor, names: named(init), named(get), named(set), named(_modify))
@attached(peer, names: prefixed(_))
public macro Observing() =
  #externalMacro(module: "ValueObservationMacros", type: "ObservingMacro")

@attached(peer, names: arbitrary)
public macro Ignoring() =
  #externalMacro(module: "ValueObservationMacros", type: "IgnoringMacro")

#endif
