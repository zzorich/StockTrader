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
        let webView = WKWebView()
        guard let url else { return webView }
        let request = URLRequest(url: url)
        webView.load(request)
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        uiView.reload()
    }
}

#Preview {
    WebView(url: URL(string: "https://durable-melody-413101.nn.r.appspot.com/charts/hourly-price/AAPL"))
}
