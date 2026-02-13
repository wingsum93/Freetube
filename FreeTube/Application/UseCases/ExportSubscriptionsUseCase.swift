import Foundation

struct ExportSubscriptionsUseCase {
    let repository: SubscriptionRepository
    let service: SubscriptionImportExporting

    func execute(format: ImportExportFormat = .newPipeJSON) throws -> Data {
        let subscriptions = try repository.fetchAll()
        return try service.exportSubscriptions(subscriptions, format: format)
    }
}
