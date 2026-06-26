//
//  AsyncAwaitDemo.swift
//  ConcurrencyDemo
//
//  Demonstrates `async`/`await` and how `async let` turns a slow
//  sequential pipeline into concurrent work — with a live stopwatch
//  so the speedup is visible.
//

import SwiftUI

@MainActor
@Observable
final class AsyncAwaitModel {
    enum Mode: String, CaseIterable { case sequential = "Sequential", concurrent = "Concurrent (async let)" }

    var tiles: [ImageTile] = []
    var elapsed: Duration = .zero
    var isRunning = false

    /// Loads four tiles either one-after-another or all at once.
    func run(_ mode: Mode) async {
        isRunning = true
        tiles = []
        elapsed = .zero
        let clock = ContinuousClock()
        let start = clock.now

        do {
            switch mode {
            case .sequential:
                // Each `await` suspends until the previous finishes.
                for id in 1...4 {
                    tiles.append(try await WorkService.loadImage(id: id))
                    elapsed = clock.now - start
                }
            case .concurrent:
                // `async let` starts all four immediately; we await together.
                async let a = WorkService.loadImage(id: 1)
                async let b = WorkService.loadImage(id: 2)
                async let c = WorkService.loadImage(id: 3)
                async let d = WorkService.loadImage(id: 4)
                tiles = try await [a, b, c, d]
                elapsed = clock.now - start
            }
        } catch {
            // Cancelled mid-flight — leave whatever we gathered.
        }
        isRunning = false
    }
}

struct AsyncAwaitDemo: View {
    @State private var model = AsyncAwaitModel()
    @State private var mode: AsyncAwaitModel.Mode = .concurrent
    @State private var task: Task<Void, Never>?

    var body: some View {
        VStack(spacing: 20) {
            Picker("Mode", selection: $mode) {
                ForEach(AsyncAwaitModel.Mode.allCases, id: \.self) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)
            .disabled(model.isRunning)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
                ForEach(1...4, id: \.self) { id in
                    tileSlot(for: id)
                }
            }

            Text(model.elapsed.formatted(.units(allowed: [.seconds], fractionalPart: .show(length: 2))))
                .font(.system(.largeTitle, design: .monospaced))
                .contentTransition(.numericText())
                .foregroundStyle(model.isRunning ? .secondary : .primary)

            Button(model.isRunning ? "Loading…" : "Load 4 tiles") {
                task = Task { await model.run(mode) }
            }
            .buttonStyle(.borderedProminent)
            .disabled(model.isRunning)

            explainer
            Spacer()
        }
        .padding()
        .navigationTitle("async / await")
        .onDisappear { task?.cancel() }
    }

    @ViewBuilder
    private func tileSlot(for id: Int) -> some View {
        let tile = model.tiles.first { $0.id == id }
        RoundedRectangle(cornerRadius: 14)
            .fill(tile.map { Color(hue: $0.hue, saturation: 0.6, brightness: 0.9) } ?? Color.secondary.opacity(0.15))
            .aspectRatio(1, contentMode: .fit)
            .overlay {
                if let tile {
                    Text("\(tile.latencyMillis)ms")
                        .font(.caption2.monospaced())
                        .foregroundStyle(.white)
                } else if model.isRunning {
                    ProgressView()
                }
            }
            .animation(.snappy, value: tile)
    }

    private var explainer: some View {
        Text("Sequential awaits four loads back-to-back (~sum of latencies). `async let` launches all four at once, so total time ≈ the slowest single load.")
            .font(.footnote)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
    }
}

#Preview { NavigationStack { AsyncAwaitDemo() } }
