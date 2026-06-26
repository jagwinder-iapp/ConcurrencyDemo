# Swift Concurrency Demo

A small, self-contained SwiftUI app that demonstrates the core pieces of **Swift's modern concurrency model** — `async`/`await`, structured concurrency, actors, and async sequences. Every demo runs **offline** with simulated work, so you can clone, run, and watch concurrency behave without any backend.

> Built with SwiftUI + Swift Concurrency · iOS 26 · Xcode 26

## Demos

| Demo | What it shows |
| --- | --- |
| **async / await** | Loads four tiles **sequentially** vs. concurrently with `async let`, with a live stopwatch so the speedup is obvious. |
| **TaskGroup** | Fans eight prime-counting jobs across a `ThrowingTaskGroup`, streams results back in completion order, and tears the whole group down with a single cooperative **cancel**. |
| **Actors** | Hammers an `actor`-protected counter and an unprotected class with 100k concurrent increments — the actor lands on the exact total, the unprotected counter **loses writes to the data race**. |
| **AsyncStream** | Bridges a timer-style producer into `for await` consumption, driving a live Swift Charts graph; cancelling tears down the producer via `onTermination`. |

## Concepts covered

- `async` / `await` and suspension points
- `async let` for concurrent child tasks
- `ThrowingTaskGroup` — fan-out / fan-in and cooperative cancellation
- `actor` isolation and data-race safety
- `nonisolated` to opt work off the main actor (this SDK defaults to main-actor isolation)
- `AsyncStream` with `onTermination` cleanup
- `@MainActor` + `@Observable` view models driving SwiftUI

## Project layout

```
ConcurrencyDemo/
├── ConcurrencyDemoApp.swift     # @main entry point
├── ContentView.swift            # Menu into each demo
├── Support/
│   └── WorkService.swift        # Simulated, cancellable "backend"
└── Demos/
    ├── AsyncAwaitDemo.swift
    ├── TaskGroupDemo.swift
    ├── ActorDemo.swift
    └── AsyncStreamDemo.swift
```

## Running

```bash
open ConcurrencyDemo.xcodeproj
```

Then pick an iOS Simulator and hit **Run** (⌘R). Or from the command line:

```bash
xcodebuild -project ConcurrencyDemo.xcodeproj \
  -scheme ConcurrencyDemo \
  -destination 'generic/platform=iOS Simulator' build
```
