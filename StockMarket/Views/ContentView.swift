//
//  ContentView.swift
//  StockMarket
//
//  Created by lingji zhou on 3/30/24.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var searchViewModel = SearchViewModel()
    @State private var path: NavigationPath = .init()
    var body: some View {
        NavigationStack(path: $path) {
            PortfolioView()
                .environmentObject(searchViewModel)        
                .navigationDestination(for: SearchItem.self) { searchItem in
                    DetailedStockInfoView(stockIdentifier: searchItem.companySymbol)
                }
        }
        .searchable(text: $searchViewModel.searchKeyWord)

    }
}

