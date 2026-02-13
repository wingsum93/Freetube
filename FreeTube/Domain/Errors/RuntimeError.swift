import Foundation

enum RuntimeError: Error, LocalizedError {
    case missingExecutable(path: String)
    case nonExecutable(path: String)
    case invalidConfiguration(String)
    case commandFailed(command: String, status: Int32, error: String)
    case outputDecodeFailed

    var errorDescription: String? {
        switch self {
        case .missingExecutable(let path):
            return "Missing executable at path: \(path)"
        case .nonExecutable(let path):
            return "File is not executable: \(path)"
        case .invalidConfiguration(let reason):
            return reason
        case .commandFailed(let command, let status, let error):
            let trimmedError = error.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmedError.isEmpty {
                return "\(command) failed with status \(status)."
            }
            return "\(command) failed with status \(status): \(trimmedError)"
        case .outputDecodeFailed:
            return "Failed to decode command output."
        }
    }
}
