import Foundation

struct ImportSubscriptionsUseCase {
    let repository: SubscriptionRepository
    let service: SubscriptionImportExporting

    @discardableResult
    func execute(data: Data, format: ImportExportFormat = .newPipeJSON) throws -> Int {
        let subscriptions = try service.importSubscriptions(from: data, format: format)
        for subscription in subscriptions {
            try repository.save(subscription)
        }
        return subscriptions.count
    }
}
