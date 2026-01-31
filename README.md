# ValueObservation

Macros that add Observation-style reactivity to structs.

## Add the Package
In `Package.swift`:

```swift
.package(url: "https://github.com/JohnDemirci/ValueObservation.git", .upToNextMajor(from: "1.0.1")),
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
- Mark the `ObservableValue` propert with `ObservationIgnored` to handle to observation notifications to be handled by the `ObservableValue` itself, otherwise you will see unnecessary view re-renders every time user changes as opposed to fine grained changes.
- Because the last name was not directly being observed by the Observation machinery inside SwiftUI's view, the changes to last name does not fire notifications'

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

## Identity Semantics (Important)
`@ObservableValue` stores an internal observation registrar in the value itself. Copying a value copies that registrar, so observers are shared across copies:

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

If you need per-copy isolation, use `copy()` to create a new identity while keeping the rest of the values:

```swift
let isolated = counter.copy()
```

## Macro Inventory
- `@ObservableValue` — adds observation plumbing to structs/classes and auto-tags stored properties with `@Observing`.
- `@Observing` — rewrites a stored property into tracked accessors with a private backing store.
- `@Ignoring` — excludes a property from tracking.

## License
BSD Zero Clause for this repository, except for Swift.org-derived files under Apache-2.0 with the Swift Runtime Library Exception. See `LICENSE`, `LICENSES/`, and `THIRD_PARTY_NOTICES.md`.
