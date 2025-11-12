//
//  Logger.swift
//  snow-buddy
//
//  Simple structured logging for development debugging
//

import Foundation

// MARK: - Log Level

enum LogLevel: Int, Comparable {
    case debug = 0
    case info = 1
    case warning = 2
    case error = 3
    case success = 4

    var emoji: String {
        switch self {
        case .debug: return "🔍"
        case .info: return "ℹ️"
        case .warning: return "⚠️"
        case .error: return "❌"
        case .success: return "✅"
        }
    }

    static func < (lhs: LogLevel, rhs: LogLevel) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}

// MARK: - Logger Protocol

protocol Logger {
    var isEnabled: Bool { get set }
    var minimumLevel: LogLevel { get set }

    func log(_ level: LogLevel, _ category: String, _ message: String, metadata: [String: Any]?)
}

extension Logger {
    func debug(_ category: String, _ message: String, metadata: [String: Any]? = nil) {
        log(.debug, category, message, metadata: metadata)
    }

    func info(_ category: String, _ message: String, metadata: [String: Any]? = nil) {
        log(.info, category, message, metadata: metadata)
    }

    func warning(_ category: String, _ message: String, metadata: [String: Any]? = nil) {
        log(.warning, category, message, metadata: metadata)
    }

    func error(_ category: String, _ message: String, metadata: [String: Any]? = nil) {
        log(.error, category, message, metadata: metadata)
    }

    func success(_ category: String, _ message: String, metadata: [String: Any]? = nil) {
        log(.success, category, message, metadata: metadata)
    }
}

// MARK: - Console Logger

class ConsoleLogger: Logger {
    var isEnabled: Bool
    var minimumLevel: LogLevel
    var includeMetadata: Bool
    var includeTimestamp: Bool

    init(
        isEnabled: Bool = true,
        minimumLevel: LogLevel = .debug,
        includeMetadata: Bool = true,
        includeTimestamp: Bool = false
    ) {
        self.isEnabled = isEnabled
        self.minimumLevel = minimumLevel
        self.includeMetadata = includeMetadata
        self.includeTimestamp = includeTimestamp
    }

    func log(_ level: LogLevel, _ category: String, _ message: String, metadata: [String: Any]?) {
        guard isEnabled && level >= minimumLevel else { return }

        var logMessage = "\(level.emoji) [\(category)] \(message)"

        // Add metadata if present and enabled
        if includeMetadata, let metadata = metadata, !metadata.isEmpty {
            let metadataString = formatMetadata(metadata)
            logMessage += " | \(metadataString)"
        }

        // Add timestamp if enabled
        if includeTimestamp {
            let timestamp = formatTimestamp(Date())
            logMessage = "\(timestamp) \(logMessage)"
        }

        print(logMessage)
    }

    private func formatMetadata(_ metadata: [String: Any]) -> String {
        return metadata.map { key, value in
            "\(key): \(formatValue(value))"
        }.joined(separator: ", ")
    }

    private func formatValue(_ value: Any) -> String {
        switch value {
        case let double as Double:
            return String(format: "%.1f", double)
        case let int as Int:
            return "\(int)"
        case let string as String:
            return string
        case let bool as Bool:
            return bool ? "true" : "false"
        default:
            return "\(value)"
        }
    }

    private func formatTimestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter.string(from: date)
    }
}

// MARK: - Shared Logger Instance

class LoggerContainer {
    static var shared: Logger = ConsoleLogger()
}
