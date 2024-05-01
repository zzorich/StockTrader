//
//  PortfolioView.swift
//  StockMarket
//
//  Created by lingji zhou on 3/30/24.
//

import SwiftUI

struct PortfolioLoadedView: View {
    @Environment(PortfolioViewModel.self) private var portfolio
    @EnvironmentObject private var searchViewModel: SearchViewModel

    @Environment(\.isSearching) private var isSearching
    @State private var isShowingErrorToast: Bool = false
    @State private var errorMessage: String = "Failed to load search result"
    let timer = Timer.publish(every: 15, on: .main, in: .common).autoconnect()

    var body: some View {
        if isSearching {
            List {
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
            }

        } else {
            List {
                Section {
                    Text(Date.now.formatted(.dateTime.day().month(.wide).year()))
                        .foregroundStyle(.secondary)
                        .font(.largeTitle)
                }

                Section("PORTFOLIO") {
                    assetsHeader
                    ForEach(portfolio.stocksOwned, id: \.stockSymbol) { ownedStockInfo in
                        if let stockQuote = portfolio.quote(of: ownedStockInfo.stockSymbol) {
                            NavigationLink(value: DetailStockItem(symbol: ownedStockInfo.stockSymbol)) {
                                OwnedStockInfoView(stock: ownedStockInfo, stockQuote: stockQuote)
                            }
                        }
                    }
                    .onMove(perform: { indices, newOffset in
                        portfolio.stocksOwned.move(fromOffsets: indices, toOffset: newOffset)
                    })
                }

                Section("FAVORITE") {
                    ForEach(portfolio.favorites, id: \.stockSymbol) { stock in
                        if let quote = portfolio.quote(of: stock.stockSymbol) {
                            NavigationLink(value: DetailStockItem(symbol: stock.stockSymbol)) {
                                FavoriteStockView(stock: stock, quote: quote)
                            }
                        }
                    }
                    .onDelete(perform: portfolio.removeFavoriteStocks(at:))
                    .onMove(perform: { indices, newOffset in
                        portfolio.favorites.move(fromOffsets: indices, toOffset: newOffset)
                    })
                }

                Section {
                    Link("Powered by Finnhub.io", destination: URL(string: "https://finnhub.io")!)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                }

            }
            .toolbar(content: {
                EditButton()
            })
            .onReceive(timer, perform: { _ in
                portfolio.updateData()
            })
        }
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

struct PortfolioView: View {
    @Environment(PortfolioViewModel.self) private var portfolio
    @EnvironmentObject private var searchViewModel: SearchViewModel

    var body: some View {
        switch portfolio.loadingState {
        case .loaded:
            PortfolioLoadedView()
                .searchable(text: $searchViewModel.searchKeyWord)
                .onAppear(perform: {
                    portfolio.reloadDataIfNeeded()
                })
        case .failed(error: let error):
            Text(error.localizedDescription)
        case .isLoading:
            ProgressView("fetching data")
        }
    }

}
