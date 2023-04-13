//
//  ContentView.swift
//  ChatGPTDemo
//
//  Created by SHIVAM GAIND on 12/04/23.
//

import SwiftUI
import AVKit
import OpenAIKit

//  MARK: Image Generator Modal
final class ViewModal: ObservableObject {
    private var openai: OpenAI?
    func setup(){
         openai = OpenAI(Configuration(organizationId: "Personal", apiKey: "YOUR_KEY"))
    }
    func generatorImage(prompt:String) async -> UIImage? {
        guard let openai = openai else {
            return nil
        }
        do {
            let params = ImageParameters(prompt: prompt, resolution: .medium, responseFormat: .base64Json)
            let result =  try await  openai.createImage(parameters: params)
            let data = result.data[0].image
            let image = try openai.decodeBase64Image(data)
            return image
        }
        catch {
            print(String(describing: error))
            return nil
        }
    }
}

@available(iOS 16.0, *)
struct ContentView: View {
    enum Tab {
        case chat
        case settings
 }
    // MARK: Variables
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var vm: ViewModel
    @FocusState var isTextFieldFocused: Bool
    @State private var selectedTab: Tab = .chat
    @State var selection = 1
    
    // tab bar items
    var body: some View {
            TabView(selection: $selectedTab) {
                chatListView
                 .navigationTitle("ChatGPT")
                    .tabItem {
                        Label("Chat", systemImage: "message.fill")
                    }
                    .tag(Tab.chat)
                
                Imagegen()
                .navigationTitle("Image")
                    .tabItem {
                        Label("Image", systemImage: "ellipsis.circle.fill")
                    }
                    .tag(Tab.settings)
            }
        .navigationTitle(selectedTab == .chat ? "Chat GPT" : "Image Generator")
    }
    
    var chatListView: some View {
        ScrollViewReader { proxy in
            VStack(spacing: 0) {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(vm.messages) { message in
                            MessageRowView(message: message) { message in
                                Task { @MainActor in
                                    await vm.retry(message: message)
                                }
                            }
                        }
                    }
                    .onTapGesture {
                        isTextFieldFocused = false
                    }
                }
#if os(iOS) || os(macOS)
                Divider()
                bottomView(image: "profile", proxy: proxy)
                Spacer()
#endif
            }
            .onChange(of: vm.messages.last?.responseText) { _ in  scrollToBottom(proxy: proxy)
            }
        }
        .background(colorScheme == .light ? .white : Color(red: 52/255, green: 53/255, blue: 65/255, opacity: 0.5))
    }
    // MARK: Response Handle Bottom View
    func bottomView(image: String, proxy: ScrollViewProxy) -> some View {
        HStack(alignment: .top, spacing: 8) {
            if image.hasPrefix("http"), let url = URL(string: image) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .frame(width: 30, height: 30)
                } placeholder: {
                    ProgressView()
                }
                
            } else {
                Image(image)
                    .resizable()
                    .frame(width: 30, height: 30)
            }
            
            TextField("Send message", text: $vm.inputMessage, axis: .vertical)
#if os(iOS) || os(macOS)
                .textFieldStyle(.roundedBorder)
#endif
                .focused($isTextFieldFocused)
                .disabled(vm.isInteractingWithChatGPT)
            
            if vm.isInteractingWithChatGPT {
                DotLoadingView().frame(width: 60, height: 30)
            } else {
                Button {
                    Task { @MainActor in
                        isTextFieldFocused = false
                        scrollToBottom(proxy: proxy)
                        await vm.sendTapped()
                    }
                } label: {
                    Image(systemName: "paperplane.circle.fill")
                        .rotationEffect(.degrees(45))
                        .font(.system(size: 30))
                }
#if os(macOS)
                .buttonStyle(.borderless)
                .keyboardShortcut(.defaultAction)
                .foregroundColor(.accentColor)
#endif
                .disabled(vm.inputMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
    }
    func scrollToBottom(proxy: ScrollViewProxy) {
        guard let id = vm.messages.last?.id else { return }
        proxy.scrollTo(id, anchor: .bottomTrailing)
    }
    // MARK: Image Generator responose handle
    struct Imagegen: View {
        @ObservedObject var viewModal = ViewModal()
        @State var text  = ""
        @State var image: UIImage?
        @State private var isLoading = false // Add this state variable
    
        var body: some View {
            NavigationView{
                VStack {
                    if let image = image {
                        Image(uiImage:image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 250,height: 250)
                    } else {
                        Text("type prompt to generate image")
                    }
                    Spacer()
                    TextField("type prompt here...", text: $text)
                        .padding()
                    Button("Generate!"){
                        if !text.trimmingCharacters(in: .whitespaces).isEmpty {
                            Task {
                                isLoading = true // Set isLoading to true before generating image
                                let result = await viewModal.generatorImage(prompt: text )
                                isLoading = false // Set isLoading to false after image is generated
                                if result == nil {
                                    print("Faild to get Image ")
                                }
                                self.image = result
                            }
                        }
                    }
                    if isLoading { // Show ProgressView if isLoading is true
                        ProgressView()
                    }
                }
               // .navigationTitle("Image Generator")
                .onAppear{
                    viewModal.setup()
                }
                .padding()
            }
        }
    }
}

@available(iOS 16.0, *)
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            ContentView(vm: ViewModel(api: ChatGPTAPI(apiKey: "YOUR_KEY")))
        }
    }
}

