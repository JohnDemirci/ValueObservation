import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import SwiftSyntaxMacroExpansion
import SwiftParser
import XCTest

#if canImport(ValueObservationMacros)
import ValueObservationMacros

@MainActor
let testMacros: [String: Macro.Type] = [
    "ObservableValue": ObservableValueMacro.self,
    "Ignoring": IgnoringMacro.self,
    "Observing": ObservingMacro.self
]

let observableValueMacroSpecs: [String: MacroSpec] = [
    "ObservableValue": MacroSpec(
        type: ObservableValueMacro.self,
        conformances: [TypeSyntax("ObservableValue")]
    )
]
#endif

@MainActor
final class ValueObservationTests: XCTestCase {
    func testObservableValueAddsMembersAndObservingAttributes() {
        assertMacroExpansion(
            """
            @ObservableValue
            public struct Model {
                var count: Int = 0
                let constant: Int = 1
                @Ignoring var ignored: Int = 2
                @Observing var already: String = ""
                var computed: Int { count }
            }
            """,
            expandedSource: """
            public struct Model {
                @Observing
                var count: Int = 0
                let constant: Int = 1
                @Ignoring var ignored: Int = 2
                @Observing var already: String = ""
                var computed: Int { count }

                public private(set) var _$id = UUID()

                @Ignoring private var _$observationRegistrar = Observation.ObservationRegistrar()

                public func copy() -> Self {
                  var copy = self
                  copy._$id = UUID()
                  copy._$observationRegistrar = Observation.ObservationRegistrar()
                  return copy
                }

                internal nonisolated func access<__macro_local_6MemberfMu_>(
                  keyPath: KeyPath<Model, __macro_local_6MemberfMu_>
                ) {
                  _$observationRegistrar.access(self, keyPath: keyPath)
                }

                internal nonisolated func withMutation<__macro_local_6MemberfMu0_, __macro_local_14MutationResultfMu_>(
                  keyPath: KeyPath<Model, __macro_local_6MemberfMu0_>,
                  _ mutation: () throws -> __macro_local_14MutationResultfMu_
                ) rethrows -> __macro_local_14MutationResultfMu_ {
                  try _$observationRegistrar.withMutation(of: self, keyPath: keyPath, mutation)
                }

                private nonisolated func shouldNotifyObservers<__macro_local_6MemberfMu1_>(_ lhs: __macro_local_6MemberfMu1_, _ rhs: __macro_local_6MemberfMu1_) -> Bool {
                    true
                }

                private nonisolated func shouldNotifyObservers<__macro_local_6MemberfMu2_: Equatable>(_ lhs: __macro_local_6MemberfMu2_, _ rhs: __macro_local_6MemberfMu2_) -> Bool {
                    lhs != rhs
                }

                private nonisolated func shouldNotifyObservers<__macro_local_6MemberfMu3_: AnyObject>(_ lhs: __macro_local_6MemberfMu3_, _ rhs: __macro_local_6MemberfMu3_) -> Bool {
                    lhs !== rhs
                }

                private nonisolated func shouldNotifyObservers<__macro_local_6MemberfMu4_: Equatable & AnyObject>(_ lhs: __macro_local_6MemberfMu4_, _ rhs: __macro_local_6MemberfMu4_) -> Bool {
                    lhs != rhs
                }
            }

            extension Model: ValueObservation.ObservableValue {
            }
            """,
            macroSpecs: observableValueMacroSpecs
        )
    }

    func testObservableValueOnEnumEmitsDiagnostic() {
        assertMacroExpansion(
            """
            @ObservableValue
            enum Flavor {
                case vanilla
            }
            """,
            expandedSource: """
            enum Flavor {
                case vanilla
            }

            extension Flavor: ValueObservation.ObservableValue {
            }
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "'@ObservableValue' cannot be applied to enumeration type 'Flavor'",
                    line: 1,
                    column: 1,
                    severity: .error
                )
            ],
            macroSpecs: observableValueMacroSpecs
        )
    }

    func testObservingAddsAccessorsAndBackingStorage() {
        assertMacroExpansion(
            """
            struct Model {
                @Observing var name: String = ""
            }
            """,
            expandedSource: """
            struct Model {
                var name: String {
                    @storageRestrictions(initializes: _name)
                    init(initialValue) {
                      _name = initialValue
                    }
                    get {
                      access(keyPath: \\.name)
                      return _name
                    }
                    set {
                      if let oldObs = _name as? ObservableValue,
                         let newObs = newValue as? ObservableValue,
                         oldObs._$id == newObs._$id {
                        _name = newValue
                        return
                      }

                      guard shouldNotifyObservers(_name, newValue) else {
                        _name = newValue
                        return
                      }

                      withMutation(keyPath: \\.name) {
                        _name = newValue
                      }
                    }
                    _modify {
                      access(keyPath: \\.name)

                      if _name is ObservableValue {
                        yield &_name
                      } else {
                        _$observationRegistrar.willSet(self, keyPath: \\.name)
                        defer {
                            _$observationRegistrar.didSet(self, keyPath: \\.name)
                        }
                        yield &_name
                      }
                    }
                }
                private  var _name: String = ""
            }
            """,
            macros: testMacros
        )
    }

    func testObservingNoExpansionOutsideType() {
        assertMacroExpansion(
            """
            @Observing var topLevel: Int = 0
            """,
            expandedSource: """
            var topLevel: Int = 0
            """,
            macros: testMacros
        )
    }
}
