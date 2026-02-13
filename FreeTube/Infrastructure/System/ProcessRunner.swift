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
        try await Task.detached(priority: .userInitiated) {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: executablePath)
            process.arguments = arguments

            let stdoutPipe = Pipe()
            let stderrPipe = Pipe()
            process.standardOutput = stdoutPipe
            process.standardError = stderrPipe

            try process.run()

            if let timeout {
                let deadline = Date().addingTimeInterval(timeout)
                while process.isRunning && Date() < deadline {
                    try await Task.sleep(for: .milliseconds(100))
                }
                if process.isRunning {
                    process.terminate()
                    throw RuntimeError.commandFailed(
                        command: ([executablePath] + arguments).joined(separator: " "),
                        status: -1,
                        error: "Command timed out"
                    )
                }
            }

            process.waitUntilExit()

            let stdoutData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
            let stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()

            let stdout = String(data: stdoutData, encoding: .utf8) ?? ""
            let stderr = String(data: stderrData, encoding: .utf8) ?? ""

            return ProcessOutput(
                terminationStatus: process.terminationStatus,
                stdout: stdout,
                stderr: stderr
            )
        }.value
    }
}
