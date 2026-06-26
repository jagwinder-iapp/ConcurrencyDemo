//
//  WorkService.swift
//  ConcurrencyDemo
//
//  A tiny, self-contained "backend" that simulates latency with
//  Task.sleep so every demo runs offline and deterministically.
//

import Foundation

/// Simulated units of work shared across the demos.
///
/// `nonisolated` keeps this off the main actor (this SDK defaults to
/// main-actor isolation), so the prime-counting genuinely runs on the
/// cooperative thread pool instead of blocking the UI.
nonisolated enum WorkService {

    /// Pretend to fetch a thumbnail. Returns after a randomized delay.
    static func loadImage(id: Int) async throws -> ImageTile {
        let millis = UInt64.random(in: 350...1_400)
        try await Task.sleep(for: .milliseconds(millis))
        return ImageTile(id: id, latencyMillis: millis)
    }

    /// A CPU-ish task: count primes up to `limit`. Cooperatively cancellable.
    static func countPrimes(upTo limit: Int) async throws -> Int {
        var count = 0
        for n in 2...max(2, limit) {
            try Task.checkCancellation()
            if isPrime(n) { count += 1 }
            // Yield occasionally so cancellation stays responsive.
            if n % 2_000 == 0 { await Task.yield() }
        }
        return count
    }

    private static func isPrime(_ n: Int) -> Bool {
        if n < 2 { return false }
        if n % 2 == 0 { return n == 2 }
        var i = 3
        while i * i <= n {
            if n % i == 0 { return false }
            i += 2
        }
        return true
    }
}

/// Result of a simulated image load.
struct ImageTile: Identifiable, Hashable {
    let id: Int
    let latencyMillis: UInt64

    /// A stable color derived from the id, just for visual variety.
    var hue: Double { Double((id * 47) % 360) / 360.0 }
}
