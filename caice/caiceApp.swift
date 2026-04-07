//
//  caiceApp.swift
//  caice
//
//  Created by Christopher Gibson on 4/5/26.
//

import SwiftUI

@main
struct caiceApp: App {
    var body: some Scene {
        WindowGroup {
            let resolution = ChatServiceFactory.resolveDefaultService()

            ContentView(
                viewModel: ChatViewModel(service: resolution.service),
                runtime: resolution.runtime
            )
            .frame(minWidth: 980, minHeight: 640)
        }
#if os(macOS)
        .defaultSize(width: 1220, height: 780)
#endif
    }
}
