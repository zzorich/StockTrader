//
//  SearchView.swift
//  StockMarket
//
//  Created by lingji zhou on 3/31/24.
//

import SwiftUI

struct SearchView: View {
    let searchItems: [String]
    var body: some View {
        ForEach(searchItems, id: \.self) { stock in
            Text(stock)
        }
    }
}

#Preview {
    SearchView(searchItems: ["AAPL"])
}
