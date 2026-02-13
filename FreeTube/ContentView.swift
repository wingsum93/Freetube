//
//  ContentView.swift
//  FreeTube
//
//  Created by eric ho on 13/2/2026.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("FreeTube")
                .font(.largeTitle)
                .bold()

            Text("Model architecture is set up with Domain, Application, and Infrastructure layers.")
                .font(.headline)

            Text("Next step: connect these use cases and repositories to the macOS UI screens.")
                .foregroundStyle(.secondary)
        }
        .padding(24)
    }
}

#Preview {
    ContentView()
}
