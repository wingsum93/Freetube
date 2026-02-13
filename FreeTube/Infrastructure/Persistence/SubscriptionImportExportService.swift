import Foundation

protocol SubscriptionImportExporting {
    func importSubscriptions(from data: Data, format: ImportExportFormat) throws -> [ChannelSubscription]
    func exportSubscriptions(_ subscriptions: [ChannelSubscription], format: ImportExportFormat) throws -> Data
}

final class SubscriptionImportExportService: SubscriptionImportExporting {
    func importSubscriptions(from data: Data, format: ImportExportFormat) throws -> [ChannelSubscription] {
        switch format {
        case .newPipeJSON:
            let payload = try JSONDecoder().decode(NewPipeSubscriptionPayload.self, from: data)
            return payload.subscriptions.map {
                ChannelSubscription(
                    channelID: $0.channelID,
                    title: $0.name,
                    channelURLString: $0.url
                )
            }
        }
    }

    func exportSubscriptions(_ subscriptions: [ChannelSubscription], format: ImportExportFormat) throws -> Data {
        switch format {
        case .newPipeJSON:
            let entries = subscriptions.map {
                NewPipeSubscriptionPayload.Subscription(
                    serviceID: 0,
                    url: $0.channelURLString,
                    name: $0.title,
                    channelID: $0.channelID
                )
            }
            let payload = NewPipeSubscriptionPayload(subscriptions: entries)
            return try JSONEncoder.prettyPrinted.encode(payload)
        }
    }
}

private struct NewPipeSubscriptionPayload: Codable {
    struct Subscription: Codable {
        let serviceID: Int
        let url: String
        let name: String
        let channelID: String

        enum CodingKeys: String, CodingKey {
            case serviceID = "service_id"
            case url
            case name
            case channelID = "channel_id"
        }
    }

    let subscriptions: [Subscription]
}

private extension JSONEncoder {
    static var prettyPrinted: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }
}
