//
//  ActorDemo.swift
//  ConcurrencyDemo
//
//  Demonstrates how an `actor` serializes access to mutable state and
//  eliminates data races — contrasted with an unprotected counter that
//  loses increments under concurrent mutation.
//

import SwiftUI

/// Thread-safe: the actor guarantees one mutation at a time.
actor SafeCounter {
    private(set) var value = 0
    func increment() { value += 1 }
}

/// Deliberately unsafe: a class mutated from many tasks at once.
/// `nonisolated` keeps it off the main actor and `nonisolated(unsafe)`
/// opts out of the compiler's protection so we can *show* the race.
/// Never do this in real code.
nonisolated final class UnsafeCounter: @unchecked Sendable {
    nonisolated(unsafe) var value = 0
    func increment() { value += 1 }
}

@MainActor
@Observable
final class ActorModel {
    let target = 100_000
    var safeResult: Int?
    var unsafeResult: Int?
    var isRunning = false

    func run() async {
        isRunning = true
        safeResult = nil
        unsafeResult = nil

        let safe = SafeCounter()
        let unsafe = UnsafeCounter()

        // Hammer both counters from many concurrent child tasks.
        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<target {
                group.addTask { await safe.increment() }
                group.addTask { unsafe.increment() }
            }
        }

        safeResult = await safe.value
        unsafeResult = unsafe.value
        isRunning = false
    }
}

struct ActorDemo: View {
    @State private var model = ActorModel()
    @State private var task: Task<Void, Never>?

    var body: some View {
        VStack(spacing: 20) {
            counterCard(title: "actor SafeCounter",
                        subtitle: "serialized access",
                        value: model.safeResult,
                        expected: model.target,
                        tint: .green)

            counterCard(title: "Unprotected class",
                        subtitle: "data race — increments lost",
                        value: model.unsafeResult,
                        expected: model.target,
                        tint: .red)

            Button(model.isRunning ? "Racing…" : "Increment \(model.target.formatted())× each") {
                task = Task { await model.run() }
            }
            .buttonStyle(.borderedProminent)
            .disabled(model.isRunning)

            Text("Both counters are incremented \(model.target.formatted()) times from concurrent tasks. The actor always lands on the exact total; the unprotected counter loses writes to the race and ends up short.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .padding()
        .navigationTitle("Actors")
        .onDisappear { task?.cancel() }
    }

    private func counterCard(title: String, subtitle: String, value: Int?, expected: Int, tint: Color) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.headline.monospaced())
                Text(subtitle).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing) {
                Text(value?.formatted() ?? "—")
                    .font(.system(.title, design: .monospaced).bold())
                    .contentTransition(.numericText())
                    .foregroundStyle(value == nil ? Color.secondary : (value == expected ? Color.green : Color.red))
                if let value, value != expected {
                    Text("\(value - expected)").font(.caption2.monospaced()).foregroundStyle(.red)
                }
            }
        }
        .padding()
        .background(tint.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(tint.opacity(0.25)))
    }
}

#Preview { NavigationStack { ActorDemo() } }
