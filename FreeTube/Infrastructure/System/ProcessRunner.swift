import Foundation

struct ProcessOutput {
    let terminationStatus: Int32
    let stdout: String
    let stderr: String
}

protocol ProcessRunning {
    func run(executablePath: String, arguments: [String], timeout: TimeInterval?) async throws -> ProcessOutput
}

final class ProcessRunner: ProcessRunning {
    func run(executablePath: String, arguments: [String], timeout: TimeInterval? = nil) async throws -> ProcessOutput {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executablePath)
        process.arguments = arguments

        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        try process.run()

        let command = ([executablePath] + arguments).joined(separator: " ")
        let startTime = Date()

        while process.isRunning {
            if Task.isCancelled {
                process.terminate()
                throw CancellationError()
            }

            if let timeout, Date().timeIntervalSince(startTime) > timeout {
                process.terminate()
                throw RuntimeError.commandFailed(
                    command: command,
                    status: -1,
                    error: "Command timed out"
                )
            }

            try await Task.sleep(for: .milliseconds(100))
        }

        let stdoutData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
        let stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()

        let stdout = String(data: stdoutData, encoding: .utf8) ?? ""
        let stderr = String(data: stderrData, encoding: .utf8) ?? ""

        return ProcessOutput(
            terminationStatus: process.terminationStatus,
            stdout: stdout,
            stderr: stderr
        )
    }
}
