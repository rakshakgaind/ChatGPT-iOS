//
//  ChatGPTDemoApp.swift
//  ChatGPTDemo
//
//  Created by SHIVAM GAIND on 12/04/23.
//

import SwiftUI

@available(iOS 16.0, *)
@main
struct XCAChatGPTApp: App {
    /// use your API Token Key
    /// Link for API Token Key  - https://beta.openai.com/account/api-keys
    /// Replace Token with Your unique Key

    @StateObject var vm = ViewModel(api: ChatGPTAPI(apiKey: "YOUR_KEY"))
    @State var isShowingTokenizer = false

    @available(iOS 16.0, *)
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                ContentView(vm: vm)
                    .toolbar {
                        ToolbarItem {
                            Button("Clear") {
                                vm.clearMessages()
                            }
                            .disabled(vm.isInteractingWithChatGPT)
                        }

                        ToolbarItem(placement: .navigationBarLeading) {
//                            Button("Tokenizer") {
//                                self.isShowingTokenizer = true
//                            }
                            //.disabled(vm.isInteractingWithChatGPT)
                        }
                    }
            }
            .fullScreenCover(isPresented: $isShowingTokenizer) {
                NavigationTokenView()
            }
        }
    }
}

@available(iOS 16.0, *)
struct NavigationTokenView: View {
    
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            TokenizerView()
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Close") {
                            dismiss()
                        }
                    }
                }
        }
        .interactiveDismissDisabled()
    }
}


