//
//  ContentView.swift
//  StockMarket
//
//  Created by lingji zhou on 3/30/24.
//

import SwiftUI

@MainActor
struct ContentView: View {
    @State private var searchKeyword: String = ""
    @Bindable private var searchViewModel = SearchViewModel()
    var body: some View {
        NavigationStack {
            PortfolioView()
                .environment(searchViewModel)
        }
        .searchable(text: $searchViewModel.searchKeyword)
    }
}

