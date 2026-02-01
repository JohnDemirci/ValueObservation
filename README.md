# ValueObservation

Macros that add Observation-style reactivity to structs.

## Motivation
ValueObservation targets architectures where application state lives in value types but is owned by a reference-type store/view-model. The owner provides stable identity, while the state remains copyable. The macro adds per-property observation wiring so UI can invalidate only for the properties it reads.

Swift's Observation currently focuses on reference types; struct semantics are still evolving. This macro defines explicit copying/observation behavior so value-type state can participate in Observation today.

## When to use
- You keep application state in structs but still want Observation-driven updates.
- You want fine-grained invalidation on struct properties without converting state to classes.

## Limitations
- Only structs are supported (classes/actors/enums are rejected).
- This is an opt-in trade-off, not a general replacement for `@Observable` classes.

## Add the Package
In `Package.swift`:

```swift
.package(url: "https://github.com/JohnDemirci/ValueObservation.git", .upToNextMajor(from: "1.0.2")),
```

## Basic Usage
```swift
import Observation
import ValueObservation

@ObservableValue
struct Counter {
    var count: Int = 0
}

var counter = Counter()

withObservationTracking {
    _ = counter.count
} onChange: {
    print("Counter changed")
}

counter.count += 1
```

## SwiftUI ##
```swift
@Observable
private final class ViewModel {
    @ObservableValue
    struct User {
        var name: String = ""
        var lastName: String = ""
    }
    
    @ObservationIgnored
    var user = User()
    
    func setLastName(to newLastName: String) {
        user.lastName = newLastName
    }
}

struct ContentView: View {
    @State private var viewModel = ViewModel()
    var body: some View {
        let _ = Self._printChanges()
        VStack {
            Text("name: \(viewModel.user.name)")
            TextField(
                "name",
                text: $viewModel.user.name
            )
            
            Button("Change Last name") {
                viewModel.setLastName(
                    to: String(Int.random(in: 0..<1000))
                )
            }
        }
    }
}
```
### Notes
- Mark the `ObservableValue` property with `@ObservationIgnored` so the value type drives its own notifications; otherwise the owner emits updates for any change and you lose fine-grained invalidation.
- If a property is not read by the view, changes to it do not trigger updates.

## Property Control
Use `@Observing` to explicitly make a stored property observable, and `@Ignoring` to opt out.

```swift
@ObservableValue
struct Model {
    var name: String = ""
    @Ignoring var cacheKey: String = ""
    var count: Int = 0   // auto-observed unless ignored
}
```

## Observation Lineage (Copying)
`@ObservableValue` stores an internal observation registrar in the value itself. Regular assignment preserves that registrar, so observers are shared across copies. This is observation lineage, not object identity:

```swift
var counter = Counter()
var copy = counter

withObservationTracking {
    _ = counter.count
} onChange: {
    print("counter observed change")
}

copy.count += 1 // invalidates observers of counter
```

If you need per-copy isolation, use `copy()` to reset the registrar and create a detached snapshot:

```swift
let isolated = counter.copy()
```

## Macro Inventory
- `@ObservableValue` — adds observation plumbing to structs and auto-tags stored properties with `@Observing`.
- `@Observing` — rewrites a stored property into tracked accessors with a private backing store.
- `@Ignoring` — excludes a property from tracking.

## License
BSD Zero Clause for this repository, except for Swift.org-derived files under Apache-2.0 with the Swift Runtime Library Exception. See `LICENSE`, `LICENSES/`, and `THIRD_PARTY_NOTICES.md`.
