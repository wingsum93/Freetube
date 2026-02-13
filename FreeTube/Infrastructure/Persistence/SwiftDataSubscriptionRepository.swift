import Foundation
import SwiftData

final class SwiftDataSubscriptionRepository: SubscriptionRepository {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func save(_ subscription: ChannelSubscription) throws {
        let channelID = subscription.channelID
        let descriptor = FetchDescriptor<ChannelSubscription>(predicate: #Predicate { $0.channelID == channelID })
        if let existing = try modelContext.fetch(descriptor).first {
            existing.title = subscription.title
            existing.channelURLString = subscription.channelURLString
        } else {
            modelContext.insert(subscription)
        }
        try modelContext.save()
    }

    func fetch(channelID: String) throws -> ChannelSubscription? {
        let descriptor = FetchDescriptor<ChannelSubscription>(predicate: #Predicate { $0.channelID == channelID })
        return try modelContext.fetch(descriptor).first
    }

    func fetchAll() throws -> [ChannelSubscription] {
        let descriptor = FetchDescriptor<ChannelSubscription>(sortBy: [SortDescriptor(\ChannelSubscription.title)])
        return try modelContext.fetch(descriptor)
    }

    func delete(channelID: String) throws {
        let descriptor = FetchDescriptor<ChannelSubscription>(predicate: #Predicate { $0.channelID == channelID })
        if let target = try modelContext.fetch(descriptor).first {
            modelContext.delete(target)
            try modelContext.save()
        }
    }
}
