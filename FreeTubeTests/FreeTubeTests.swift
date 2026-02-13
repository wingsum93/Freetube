//
//  FreeTubeTests.swift
//  FreeTubeTests
//
//  Created by eric ho on 13/2/2026.
//

import Foundation
import Testing
@testable import FreeTube

struct FreeTubeTests {

    @Test func commandBuilderUsesExpectedPresetSelector() async throws {
        let builder = YTDLPCommandBuilder()
        let request = DownloadRequest(
            sourceURL: URL(string: "https://youtube.com/watch?v=abc123")!,
            title: "Sample Video",
            preset: .video720pMP4,
            outputDirectory: URL(fileURLWithPath: "/tmp")
        )

        let outputFile = builder.outputFileURL(for: request)
        let arguments = builder.downloadArguments(request: request, outputFile: outputFile)

        #expect(arguments.contains("-f"))
        #expect(arguments.contains("bestvideo[height<=720]+bestaudio/best[height<=720]"))
        #expect(arguments.contains("-o"))
        #expect(arguments.contains(outputFile.path))
    }

    @Test func ytDLPMetadataDTOCanDecodeDumpSingleJSON() async throws {
        let json = """
        {
          "id": "abc123",
          "title": "Test Video",
          "uploader": "Demo Channel",
          "thumbnail": "https://i.ytimg.com/vi/abc123/maxresdefault.jpg",
          "duration": 123.0,
          "webpage_url": "https://www.youtube.com/watch?v=abc123"
        }
        """

        let data = Data(json.utf8)
        let dto = try JSONDecoder().decode(VideoMetadataDTO.self, from: data)

        #expect(dto.id == "abc123")
        #expect(dto.title == "Test Video")
        #expect(dto.uploader == "Demo Channel")
        #expect(dto.duration == 123.0)
    }

}
