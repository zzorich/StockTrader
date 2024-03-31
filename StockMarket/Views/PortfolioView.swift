//
//  PortfolioView.swift
//  StockMarket
//
//  Created by lingji zhou on 3/30/24.
//

import SwiftUI

@MainActor
struct PortfolioView: View {
    @Environment(PortfolioViewModel.self) private var portfolio
    @Environment(\.isSearching) private var isSearching
    @Environment(SearchViewModel.self) private var searchViewModel
    var body: some View {
        List {
            if isSearching {
                SearchView(searchItems: searchViewModel.searchItems)
                    .onAppear(perform: {
                        print("Test")
                    })
            } else {
                Section {
                    Text(Date.now.formatted(.dateTime))
                        .font(.largeTitle)
                }
                Section("PORTFOLIO") {
                    assetsHeader
                    ForEach(portfolio.stocksOwned) { stock in
                        if let stockQuote = portfolio.quote(of: stock.id) {
                            OwnedStockInfoView(stock: stock, stockQuote: stockQuote)
                        }
                    }
                }

                Section("FAVORITE") {
                    ForEach(portfolio.favorites) { stock in
                        if let quote = portfolio.quote(of: stock) {
                            FavoriteStockView(stock: stock, quote: quote)
                        }
                    }
                    .onDelete(perform: portfolio.removeFavoriteStocks(at:))
                    .onMove(perform: portfolio.removeFavorites(from:to:))
                }
            }
        }
        .toolbar(content: {
            EditButton()
        })
    }

    var assetsHeader: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Net Worth")
                Text(portfolio.netWorth.formatted(.currency(code: "USD")))
                    .bold()
            }
            Spacer()
            VStack(alignment: .trailing) {
                Text("Cash balance")
                Text(portfolio.cashBalance.formatted(.currency(code: "USD")))
                    .bold()
            }
        }
    }
}

#Preview {
    PortfolioView()
        .environment(PortfolioViewModel.test)
}
