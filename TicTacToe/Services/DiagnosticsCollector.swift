//
//  DiagnosticsCollector.swift
//  TicTacToe
//
//  Receives Apple's MetricKit reports: daily performance numbers (launch time, memory, hangs) and
//  diagnostics for crashes, hangs and CPU or disk-write problems. Apple collects the same data from
//  real devices and shows it in Xcode's Organizer; this keeps a copy inside the app.
//
//  Reports arrive from real devices about once a day, so nothing shows up in the simulator.
//  Each report is saved as JSON in Application Support/Diagnostics (the newest 30 are kept) and
//  summarised in the log. Nothing leaves the device unless an analytics backend is added.
//

import Foundation
import MetricKit
import OSLog

final class DiagnosticsCollector: NSObject, MXMetricManagerSubscriber {
    static let shared = DiagnosticsCollector()
    
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "TicTacToe", category: "diagnostics")
    private let maxSavedReports = 30
    
    func start() {
        MXMetricManager.shared.add(self)
    }
    
    // MARK: MXMetricManagerSubscriber (called on a background queue)
    func didReceive(_ payloads: [MXMetricPayload]) {
        for payload in payloads {
            logger.info("MetricKit performance report received")
            store(payload.jsonRepresentation(), kind: "metrics")
        }
    }
    
    func didReceive(_ payloads: [MXDiagnosticPayload]) {
        for payload in payloads {
            let crashes = payload.crashDiagnostics?.count ?? 0
            let hangs = payload.hangDiagnostics?.count ?? 0
            let cpu = payload.cpuExceptionDiagnostics?.count ?? 0
            let disk = payload.diskWriteExceptionDiagnostics?.count ?? 0
            
            logger.error("MetricKit diagnostics: \(crashes) crashes, \(hangs) hangs, \(cpu) CPU exceptions, \(disk) disk-write exceptions")
            AppAnalytics.shared.log(AnalyticsEvent.diagnosticsReceived,
                                    ["crashes": crashes, "hangs": hangs, "cpu_exceptions": cpu, "disk_exceptions": disk])
            store(payload.jsonRepresentation(), kind: "diagnostics")
        }
    }
    
    // MARK: Saving
    private var directory: URL? {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?
            .appendingPathComponent("Diagnostics", isDirectory: true)
    }
    
    /// Writes one report to disk and deletes the oldest ones beyond the limit
    func store(_ data: Data, kind: String) {
        guard let directory else { return }
        let fileManager = FileManager.default
        try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        
        let stamp = ISO8601DateFormatter().string(from: Date()).replacingOccurrences(of: ":", with: "-")
        let file = directory.appendingPathComponent("\(kind)-\(stamp)-\(UUID().uuidString.prefix(6)).json")
        do {
            try data.write(to: file, options: .atomic)
        } catch {
            logger.error("Couldn't save a diagnostics report: \(error.localizedDescription)")
            return
        }
        
        // Oldest first, then drop everything past the limit
        let files = (try? fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: [.creationDateKey])) ?? []
        let sorted = files.sorted {
            let a = (try? $0.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? .distantPast
            let b = (try? $1.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? .distantPast
            return a < b
        }
        for old in sorted.dropLast(maxSavedReports) {
            try? fileManager.removeItem(at: old)
        }
    }
}
