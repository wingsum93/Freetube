import Foundation
import SwiftData

@Model
final class ChannelSubscription {
    @Attribute(.unique) var channelID: String
    var title: String
    var channelURLString: String
    var subscribedAt: Date

    init(
        channelID: String,
        title: String,
        channelURLString: String,
        subscribedAt: Date = .now
    ) {
        self.channelID = channelID
        self.title = title
        self.channelURLString = channelURLString
        self.subscribedAt = subscribedAt
    }
}
