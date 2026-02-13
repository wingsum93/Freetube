import Foundation

enum RuntimeError: Error {
    case missingExecutable(path: String)
    case nonExecutable(path: String)
    case invalidConfiguration(String)
    case commandFailed(command: String, status: Int32, error: String)
    case outputDecodeFailed
}
