//
//  PortfolioView.swift
//  StockMarket
//
//  Created by lingji zhou on 3/30/24.
//

import SwiftUI

struct PortfolioView: View {
    @Environment(PortfolioViewModel.self) private var portfolio
    @Environment(\.isSearching) private var isSearching
    @State private var isShowingErrorToast: Bool = false
    @State private var errorMessage: String = "Failed to load search result"

    @EnvironmentObject private var searchViewModel: SearchViewModel

    var body: some View {
        switch portfolio.loadingState {
        case .loaded:
            loadedBody
                .searchable(text: $searchViewModel.searchKeyWord)
                .onAppear(perform: {
                    portfolio.reloadDataIfNeeded()
                })
        case .failed(error: let error):
            Text(error.localizedDescription)
        case .isLoading:
            ProgressView()
        }
    }

    var loadedBody: some View {
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
                                errorMessage = error.localizedDescription
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
                if !portfolio.stocksOwned.isEmpty {
                    Section("PORTFOLIO") {
                        VStack {
                            assetsHeader
                            Divider()
                            ForEach(portfolio.stocksOwned.keys.sorted(by: <)) { stock in
                                if let stockQuote = portfolio.quote(of: stock), let ownedInfo = portfolio.stocksOwned[stock] {
                                    NavigationLink(value: DetailStockItem(symbol: stock.symbol)) {
                                        OwnedStockInfoView(stock: ownedInfo, stockQuote: stockQuote)
                                    }
                                }
                            }
                        }
                    }
                }

                if !portfolio.favorites.isEmpty {
                    Section("FAVORITE") {
                        ForEach(portfolio.favorites, id: \.stockSymbol) { stock in
                            let id = StockIdentifier(symbol: stock.stockSymbol)
                            if let quote = portfolio.quote(of: id) {
                                NavigationLink(value: DetailStockItem(symbol: stock.stockSymbol)) {
                                    FavoriteStockView(stock: id, quote: quote)
                                }
                            }
                        }
                        .onDelete(perform: portfolio.removeFavoriteStocks(at:))
                        .onMove(perform: portfolio.removeFavorites(from:to:))
                    }
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
