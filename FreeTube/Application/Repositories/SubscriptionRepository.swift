import Foundation

protocol SubscriptionRepository {
    func save(_ subscription: ChannelSubscription) throws
    func fetch(channelID: String) throws -> ChannelSubscription?
    func fetchAll() throws -> [ChannelSubscription]
    func delete(channelID: String) throws
}
