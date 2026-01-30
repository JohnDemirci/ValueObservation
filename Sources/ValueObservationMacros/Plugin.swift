//
//  Plugin.swift
//  ValueObservation
//
//  Created by John Demirci on 1/26/26.
//

import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

@main
struct ValueObservationPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        ObservingMacro.self,
        IgnoringMacro.self,
        ObservableValueMacro.self
    ]
}
