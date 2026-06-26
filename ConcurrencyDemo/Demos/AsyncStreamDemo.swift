//
//  AsyncStreamDemo.swift
//  ConcurrencyDemo
//
//  Demonstrates `AsyncStream` as a bridge from a timer-style producer
//  into structured `for await` consumption, driving a live SwiftUI chart.
//

import SwiftUI
import Charts

struct Sample: Identifiable { let id: Int; let value: Double }

/// Produces a noisy sine wave, one sample every 120ms, until cancelled.
func sensorStream() -> AsyncStream<Double> {
    AsyncStream { continuation in
        let task = Task {
            var t = 0.0
            while !Task.isCancelled {
                let value = sin(t) * 0.5 + 0.5 + Double.random(in: -0.06...0.06)
                continuation.yield(value)
                t += 0.25
                try? await Task.sleep(for: .milliseconds(120))
            }
            continuation.finish()
        }
        continuation.onTermination = { _ in task.cancel() }
    }
}

@MainActor
@Observable
final class StreamModel {
    var samples: [Sample] = []
    var latest: Double = 0
    var isStreaming = false

    func start() async {
        isStreaming = true
        var index = 0
        // `for await` consumes the stream until it finishes or the task is cancelled.
        for await value in sensorStream() {
            latest = value
            samples.append(Sample(id: index, value: value))
            if samples.count > 50 { samples.removeFirst() }
            index += 1
        }
        isStreaming = false
    }
}

struct AsyncStreamDemo: View {
    @State private var model = StreamModel()
    @State private var task: Task<Void, Never>?

    var body: some View {
        VStack(spacing: 20) {
            Chart(model.samples) { sample in
                AreaMark(x: .value("t", sample.id), y: .value("v", sample.value))
                    .foregroundStyle(.linearGradient(colors: [.blue.opacity(0.5), .blue.opacity(0.05)],
                                                     startPoint: .top, endPoint: .bottom))
                LineMark(x: .value("t", sample.id), y: .value("v", sample.value))
                    .foregroundStyle(.blue)
                    .interpolationMethod(.catmullRom)
            }
            .chartYScale(domain: 0...1)
            .chartXAxis(.hidden)
            .frame(height: 220)
            .animation(.linear(duration: 0.12), value: model.samples.map(\.id))

            Text(model.latest.formatted(.number.precision(.fractionLength(3))))
                .font(.system(.largeTitle, design: .monospaced))
                .contentTransition(.numericText())

            Button(model.isStreaming ? "Stop" : "Start stream") {
                if model.isStreaming {
                    task?.cancel()
                } else {
                    task = Task { await model.start() }
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(model.isStreaming ? .red : .blue)

            Text("A producer yields sensor samples into an `AsyncStream`. The view consumes them with `for await`, and cancelling the task tears the producer down via `onTermination`.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .padding()
        .navigationTitle("AsyncStream")
        .onDisappear { task?.cancel() }
    }
}

#Preview { NavigationStack { AsyncStreamDemo() } }
