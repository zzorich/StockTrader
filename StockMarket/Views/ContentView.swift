//
//  ContentView.swift
//  StockMarket
//
//  Created by lingji zhou on 3/30/24.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var searchViewModel = SearchViewModel()
    @Bindable private var router: Router = .init()
    var body: some View {
        NavigationStack(path: $router.path) {
            PortfolioView()
                .environmentObject(searchViewModel)        
                .environment(router)
                .navigationDestination(for: SearchItem.self) { searchItem in
                    DetailedStockInfoContainer(stockIdentifier: searchItem.companySymbol)
                        .navigationBarTitleDisplayMode(.inline)
                }
                .navigationDestination(for: DetailStockItem.self) { item in
                    DetailedStockInfoContainer(stockIdentifier: item.symbol)
                        .navigationBarTitleDisplayMode(.inline)
                }
        }
        .searchable(text: $searchViewModel.searchKeyWord)

    }
}

