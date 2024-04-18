//
//  SearchView.swift
//  StockMarket
//
//  Created by lingji zhou on 3/31/24.
//

import SwiftUI

struct SearchView: View {
    let searchItems: [SearchItem]
    var body: some View {
        ForEach(searchItems, id: \.companySymbol) { stock in
            NavigationLink(value: stock) {
                VStack(alignment: .leading) {
                    Text(stock.companySymbol)
                    Text(stock.companyDescription)
                }
            }
        }
    }
}

#Preview {
    SearchView(searchItems: [SearchItem(companySymbol: "AAPL", companyDescription: "AAPL INC")])
}
