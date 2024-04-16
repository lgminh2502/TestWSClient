//
//  ContentView.swift
//  TestWSClient
//
//  Created by Admin on 12/04/2024.
//

import SwiftUI

struct ContentView: View {
    @StateObject var viewModel = ViewModel()
    //    @State var address = "ws://172.20.10.1:4000/echo"
    @State var address = "ws://localhost:4000/echo"
    @State var sendingText = ""
    var body: some View {
        VStack {
            HStack {
                TextField("IP", text: $address)
                if viewModel.isConnected {
                    Button("Disconnect") {
                        viewModel.disconnect()
                    }
                } else {
                    Button("Connect") {
                        viewModel.execute(address: address)
                    }
                }
            }
            HStack {
                TextField("Text", text: $sendingText)
                Button("Send") {
                    viewModel.send(text: sendingText)
                }.disabled(!viewModel.isConnected || sendingText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                Button("Clear logs") {
                    viewModel.messageList = []
                }
            }
            ScrollView {
                VStack { // <---
                    ForEach(viewModel.messageList, id: \.id) { item in
                        VStack {
                            switch item.type {
                            case .text(let msg):
                                Text(msg)
                                    .multilineTextAlignment(getHorizontalTextAlignment(with: item.sender))
                                    .padding(6)
                                    .background(getBackgroundColor(with: item.sender))
                                    .cornerRadius(10)
                            case .data(let data):
                                if let data = UIImage(data: data) {
                                    Image(uiImage: data)
                                        .resizable()
                                        .border(.blue)
                                        .frame(width: 60, height: 60)
                                        .cornerRadius(10)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity,
                               alignment: getHorizontalItemAlignment(with: item.sender))
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding()
    }
    
    private func getHorizontalAlignment(with sender: SenderType) -> HorizontalAlignment {
        switch sender {
        case .sender:
            return .trailing
        case .receiver:
            return .leading
        case .system:
            return .center
        }
    }
    
    private func getHorizontalItemAlignment(with sender: SenderType) -> Alignment {
        switch sender {
        case .sender:
            return .trailing
        case .receiver:
            return .leading
        case .system:
            return .center
        }
    }
    
    private func getHorizontalTextAlignment(with sender: SenderType) -> TextAlignment {
        switch sender {
        case .sender:
            return .trailing
        case .receiver:
            return .leading
        case .system:
            return .center
        }
    }
    
    private func getBackgroundColor(with sender: SenderType) -> Color {
        switch sender {
        case .sender:
            return .blue
        case .receiver:
            return .gray
        case .system:
            return .clear
        }
    }
}

#Preview {
    ContentView()
}
