//
//  ContentView.swift
//  ConcurrencyDemo
//
//  Home screen — a menu into each Swift Concurrency demo.
//

import SwiftUI

struct ContentView: View {
    private struct Demo: Identifiable {
        let id = UUID()
        let title: String
        let subtitle: String
        let symbol: String
        let tint: Color
        @ViewBuilder let destination: () -> AnyView
    }

    private let demos: [Demo] = [
        Demo(title: "async / await",
             subtitle: "Sequential vs. concurrent loading",
             symbol: "arrow.triangle.branch", tint: .purple,
             destination: { AnyView(AsyncAwaitDemo()) }),
        Demo(title: "TaskGroup",
             subtitle: "Fan-out work & cancellation",
             symbol: "square.grid.3x3.fill", tint: .orange,
             destination: { AnyView(TaskGroupDemo()) }),
        Demo(title: "Actors",
             subtitle: "Data-race-free shared state",
             symbol: "lock.shield.fill", tint: .green,
             destination: { AnyView(ActorDemo()) }),
        Demo(title: "AsyncStream",
             subtitle: "Live values with for-await",
             symbol: "waveform.path.ecg", tint: .blue,
             destination: { AnyView(AsyncStreamDemo()) }),
    ]

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(demos) { demo in
                        NavigationLink {
                            demo.destination()
                        } label: {
                            HStack(spacing: 14) {
                                Image(systemName: demo.symbol)
                                    .font(.title2)
                                    .foregroundStyle(.white)
                                    .frame(width: 44, height: 44)
                                    .background(demo.tint.gradient, in: RoundedRectangle(cornerRadius: 11))
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(demo.title).font(.headline)
                                    Text(demo.subtitle).font(.subheadline).foregroundStyle(.secondary)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                } header: {
                    Text("Tap a demo — each runs offline with simulated work.")
                        .textCase(nil)
                        .font(.footnote)
                }
            }
            .navigationTitle("Swift Concurrency")
        }
    }
}

#Preview { ContentView() }
