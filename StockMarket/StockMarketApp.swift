//
//  StockMarketApp.swift
//  StockMarket
//
//  Created by lingji zhou on 3/30/24.
//

import SwiftUI

@main
@MainActor
struct StockMarketApp: App {

    private var portfolio = PortfolioViewModel()
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(portfolio)

        }
    }
}
