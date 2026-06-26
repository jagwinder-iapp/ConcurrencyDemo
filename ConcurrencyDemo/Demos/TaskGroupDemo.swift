//
//  TaskGroupDemo.swift
//  ConcurrencyDemo
//
//  Demonstrates a `ThrowingTaskGroup` fanning out a batch of CPU-style
//  jobs across the cooperative thread pool, with a single "Cancel"
//  that cooperatively tears the whole group down.
//

import SwiftUI

@MainActor
@Observable
final class TaskGroupModel {
    struct Job: Identifiable { let id: Int; var primes: Int?; var done: Bool = false }

    var jobs: [Job] = (0..<8).map { Job(id: $0) }
    var totalPrimes = 0
    var isRunning = false

    func run() async {
        isRunning = true
        totalPrimes = 0
        jobs = (0..<8).map { Job(id: $0) }

        // Each job counts primes in a different range so they take varying time.
        let limits = jobs.map { 60_000 + $0.id * 30_000 }

        do {
            try await withThrowingTaskGroup(of: (Int, Int).self) { group in
                for (index, limit) in limits.enumerated() {
                    group.addTask { (index, try await WorkService.countPrimes(upTo: limit)) }
                }
                // Results arrive in completion order, not submission order.
                for try await (index, primes) in group {
                    jobs[index].primes = primes
                    jobs[index].done = true
                    totalPrimes += primes
                }
            }
        } catch {
            // Group cancelled — child tasks already torn down.
        }
        isRunning = false
    }
}

struct TaskGroupDemo: View {
    @State private var model = TaskGroupModel()
    @State private var task: Task<Void, Never>?

    var body: some View {
        VStack(spacing: 18) {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
                ForEach(model.jobs) { job in
                    VStack(spacing: 6) {
                        ZStack {
                            Circle().fill(.secondary.opacity(0.15))
                            if job.done {
                                Image(systemName: "checkmark")
                                    .font(.headline.bold())
                                    .foregroundStyle(.green)
                                    .transition(.scale.combined(with: .opacity))
                            } else if model.isRunning {
                                ProgressView()
                            } else {
                                Text("\(job.id)").foregroundStyle(.secondary)
                            }
                        }
                        .frame(height: 56)
                        Text(job.primes.map { "\($0)" } ?? "—")
                            .font(.caption2.monospaced())
                            .foregroundStyle(.secondary)
                    }
                    .animation(.snappy, value: job.done)
                }
            }

            VStack(spacing: 2) {
                Text("\(model.totalPrimes)")
                    .font(.system(.largeTitle, design: .monospaced).bold())
                    .contentTransition(.numericText())
                Text("primes found").font(.caption).foregroundStyle(.secondary)
            }

            HStack {
                Button("Run 8 jobs") { task = Task { await model.run() } }
                    .buttonStyle(.borderedProminent)
                    .disabled(model.isRunning)
                Button("Cancel", role: .destructive) { task?.cancel() }
                    .buttonStyle(.bordered)
                    .disabled(!model.isRunning)
            }

            Text("Eight prime-counting jobs run concurrently in one task group. Results stream back in completion order. Cancelling the group propagates cancellation to every child via `Task.checkCancellation()`.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .padding()
        .navigationTitle("TaskGroup")
        .onDisappear { task?.cancel() }
    }
}

#Preview { NavigationStack { TaskGroupDemo() } }
