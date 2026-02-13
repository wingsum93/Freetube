import Foundation

enum AppError: Error {
    case runtime(RuntimeError)
    case download(DownloadError)
    case persistence(String)
    case invalidInput(String)
}
