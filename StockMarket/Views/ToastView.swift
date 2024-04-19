//
//  ToastView.swift
//  StockMarket
//
//  Created by lingji zhou on 4/18/24.
//

import SwiftUI

struct Toast: ViewModifier {
    @Binding var isShowingToast: Bool
    let message: String
    let animated: Bool = true

    func body(content: Content) -> some View {
        ZStack {
            content
            if isShowingToast {
                ToastView(message: message)
                    .transition(.move(edge: .top).combined(with: .opacity))
                                        .zIndex(1)
            }
        }
    }

}

extension View {
    func toasted(isShowingToast: Binding<Bool>, message: String) -> some View {
        self.modifier(Toast(isShowingToast: isShowingToast, message: message))
    }
}

struct ToastView: View {
    var message: String

    var body: some View {
        Text(message)
            .padding()
            .background(Color.gray.opacity(0.8))
            .foregroundColor(.white)
            .cornerRadius(20)
            .shadow(radius: 10)
            .padding(20) // Padding from screen edge
    }
}

