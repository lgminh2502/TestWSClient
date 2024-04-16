//
//  ViewModel.swift
//  TestWSClient
//
//  Created by Admin on 12/04/2024.
//

import Foundation
import Vapor
import UIKit

enum ItemType {
    case text(String)
    case data(Data)
}

enum SenderType {
    case sender
    case receiver
    case system
}

struct Message: Identifiable {
    let id: UUID = UUID()
    var type: ItemType
    let sender: SenderType
}

class ViewModel: ObservableObject {
    
    weak var ws: WebSocket?
    
    @Published var isConnected = false
        
    @Published var messageList: [Message] = []
    var elg: EventLoopGroup!
    
    init() {
        // needs to be at least two to avoid client / server on same EL timing issues
        self.elg = MultiThreadedEventLoopGroup(numberOfThreads: 2)
    }

    func execute(address: String) {
////        Task {
//                let promise = elg.any().makePromise(of: String.self)
//                let closePromise = elg.any().makePromise(of: Void.self)
//                WebSocket.connect(to: address, on: elg) { ws in
//                    ws.onText { ws, string in
//                        ws.close(promise: closePromise)
//                        promise.succeed(string)
//                    }
//                    ws.send("hello")
//                }.cascadeFailure(to: promise)
//           
////        }
//        
        Task {
            do {
                try await WebSocket.connect(to: address, configuration: WebSocketClient.Configuration(maxFrameSize: 30_000_000)) { [weak self] ws in
                    guard let self else { return }
//                    ws.pingInterval = .minutes(1)
                    DispatchQueue.main.async {
                        self.isConnected = true
                    }
                    // Connected WebSocket.
                    self.printText("Connected to \(address)", senderType: .system)
                    self.ws = ws
                    ws.onText { ws, text in
//                        self.printText("received \(text) from \(address)", senderType: .receiver)
                        self.printText("\(text)", senderType: .receiver)
                    }
                    ws.onBinary { ws, buffer in
                        var data: Data = Data()
                        data.append(contentsOf: buffer.readableBytesView)
                        self.printData(data, ws: ws, senderType: .receiver)
                    }
                    ws.onPong { ws, buffer in
//                        self.printText("onPong at \(Date()) from \(address)")
                    }
                    ws.onPing { ws, buffer in
//                        self.printText("onPing from \(ws)")
                    }
                    ws.onClose
                        .whenComplete { result in
                            self.printText("Disconnected \(address)", senderType: .system)
                            switch result {
                            case .success(_):
                                Swift.print("onClose success from \(address)")
                            case .failure(let error):
                                Swift.print("onClose failure \(error) from \(address)")
                            }
                            DispatchQueue.main.async {
                                self.isConnected = false
                            }
                        }
                }
            } catch {
                // host die
                printText("error \(error)", senderType: .system)
                DispatchQueue.main.async {
                    self.isConnected = false
                }
            }
        }
    }
    
    func disconnect() {
        ws?.close().whenComplete({ result in
            Swift.print("Disconnect with result \(result) from \(String(describing: self.ws))")
            DispatchQueue.main.async {
                self.isConnected = false
            }
        })
    }
    
    private func printText(_ items: String, senderType: SenderType) {
        DispatchQueue.main.async {
            Swift.print(items)
            self.messageList.append(Message(type: .text("\(items)"), sender: senderType))
        }
    }
    
    private func printData(_ data: Data, ws: WebSocket?, senderType: SenderType) {
        DispatchQueue.main.async {
            Swift.print("received \(data) from \(String(describing: ws))")
            self.messageList.append(Message(type: .data(data), sender: senderType))
        }
    }
    
    func send(text: String) {
        ws?.send(text)
        self.printText("\(text)", senderType: .sender)
    }
}
