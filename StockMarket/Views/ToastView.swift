//
//  ToastView.swift
//  StockMarket
//
//  Created by lingji zhou on 4/18/24.
//

import SwiftUI

struct ErrorToast: ViewModifier {
    @Binding var isShowingToast: (Bool, (any Error)?)
    let animated: Bool = true

    func body(content: Content) -> some View {
        ZStack {
            content
            if case (true, .some(let error)) = isShowingToast {
                ToastView(message: error.localizedDescription)
                    .transition(.move(edge: .top).combined(with: .opacity))
                                        .zIndex(1)
            }
        }
    }

}

extension View {
    func errorToasted(isShowingToast: Binding<(Bool, (any Error)?)>) -> some View {
        self.modifier(ErrorToast(isShowingToast: isShowingToast))
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

