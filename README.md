# ValueObservation

Macro that add @Observable style observation to **structs** especially when the struct is **owned by an class**.

> **TL;DR**  
> If you keep feature/app state in a `struct` inside a store/view-model class, `@ObservableValue` helps that nested value type participate in Observation with **per-field tracking**, so reading `state.count` can depend on `\.count` instead of collapsing into “`state` changed”.

---

## Why this exists

ValueObservation targets architectures where application state lives in value types but is owned by a reference-type store/view-model:

- The **owner** provides stable identity & lifecycle.
- The **state** remains a value type (copyable, comparable, predictable).
- The macro adds **per-property observation wiring** so UI can invalidate only for the properties it reads.

Swift’s @Observable macro currently focuses on reference types struct semantics are still evolving. This library defines explicit copying/observation behavior so value-type state can participate in Observation today.

---

## Quick start (the pattern this library is for)

```swift
import Observation
import ValueObservation

final class ViewModel {
    @ObservableValue
    struct State {
        var count = 0
        var title = ""
    }

    var state = State()

    func increment() { state.count += 1 }
    func rename(_ value: String) { state.title = value }
}
```

---

## When to use
- You keep application state in structs but still want Observation-driven updates.
- You want fine-grained invalidation on struct properties without converting state to classes.
- You want nested value-type state to remain ergonomic even when views read from the store/view-model.

### Limitations
- Only structs are supported (classes/actors/enums are rejected).
- This is an opt-in trade-off, not a general replacement for @Observable classes.

---

## Installation

```swift
dependencies: [
    .package(
        url: "https://github.com/JohnDemirci/ValueObservation.git",
        .upToNextMajor(from: "1.0.2")
    )
],
targets: [
    .target(
        name: "YourTarget",
        dependencies: [
            .product(name: "ValueObservation", package: "ValueObservation")
        ]
    )
]
```

---

## Property Control

> Similar to the ObservationTracked and ObservationIgnored, you can use **@Observing** and **@Ignoring** to explicitly state your observation intent.

```swift
@ObservableValue
struct Model {
    var name: String = ""

    @Ignoring
    var cacheKey: String = ""

    var count: Int = 0   // auto-observed unless ignored
}
```

## Copying
@ObservableValue stores an internal observation registrar in the value itself.

> By design, regular assignment preserves that registrar, so observers are shared across copies. This is observation lineage, not object identity.


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

**If you need per-copy isolation, use copy() to reset the registrar and create a detached snapshot**

`let isolated = counter.copy()`

## FAQ
### Why not just pass scalars to subviews?
That tactic is from the ObservableObject era. Passing only the values each subview needs can help reduce downstream updates. It’s a valid SwiftUI pattern. However, it also relies on consistently “threading” scalars through the view tree and not passing the store/model around. ValueObservation’s goal is to make nested value-type state observation robust even when views read fields from a store/view-model directly.

### Does this give structs identity?
The intended identity is still the reference-type owner (store/view-model). The registrar in the struct is observation wiring. If you need a true detached snapshot, use copy().
### Why is @ObservationIgnored required on the owner’s property if I the owner class is marked with @Observable?
Because otherwise observation can collapse to the owner’s state property boundary (coarse updates). Marking it ignored allows the nested struct’s generated access/mutation tracking to be the unit of observation.

## Macro inventory
- @ObservableValue — adds observation plumbing to structs and auto-tags stored properties with @Observing.
- @Observing — rewrites a stored property into tracked accessors with a private backing store.
- @Ignoring — excludes a property from tracking.

## License
BSD Zero Clause for this repository, except for Swift.org-derived files under Apache-2.0 with the Swift Runtime Library Exception.
See `LICENSE`, `LICENSES/`, and `THIRD_PARTY_NOTICES.md`.
