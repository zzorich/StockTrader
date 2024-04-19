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
    @State private var isShowingErrorToast: Bool = false
    @State private var errorMessage: String = "Failed to load search result"

    @EnvironmentObject private var searchViewModel: SearchViewModel

    var body: some View {
        List {
            if isSearching {
                switch searchViewModel.state {
                case .isLoading:
                    ProgressView()
                case .failed(let error):
                    EmptyView()
                        .onAppear(perform: {
                            withAnimation {
                                isShowingErrorToast = true
                            } completion: {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    isShowingErrorToast = false
                                }
                            }
                        })
                case .success(let searchItems):
                    SearchView(searchItems: searchItems)
                }

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
        .navigationTitle("Stocks")
        .toolbar(content: {
            EditButton()
        })
        .toasted(isShowingToast: $isShowingErrorToast, message: errorMessage)
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
        .environmentObject(SearchViewModel())
}
