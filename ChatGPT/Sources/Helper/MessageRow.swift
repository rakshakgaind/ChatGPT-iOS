//
//  MessageRow.swift
//  ChatGPTDemo
//
//  Created by SHIVAM GAIND on 12/04/23.
//

import SwiftUI
// modal
struct MessageRow: Identifiable {
    
    let id = UUID()
    
    var isInteractingWithChatGPT: Bool
    
    let sendImage: String
    let sendText: String
    
    let responseImage: String
    var responseText: String?
    
    var responseError: String?
    
}
