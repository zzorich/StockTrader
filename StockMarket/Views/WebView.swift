//
//  WebView.swift
//  StockMarket
//
//  Created by lingji zhou on 4/18/24.
//

import SwiftUI
import WebKit

struct WebView: UIViewRepresentable {

    let url: URL?

    func makeUIView(context: Context) -> WKWebView {
        return WKWebView()
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        guard let url else { return }
        let request = URLRequest(url: url)
        uiView.load(request)
    }
}

#Preview {
    WebView(url: URL(string: "https://durable-melody-413101.nn.r.appspot.com/charts/hourly-price/AAPL"))
}
