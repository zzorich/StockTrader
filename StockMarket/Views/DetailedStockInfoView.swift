//
//  DetailedStockInfoView.swift
//  StockMarket
//
//  Created by lingji zhou on 4/18/24.
//

import Foundation
import SwiftUI

struct DetailedStockInfoView: View {
    let detailStockInfoViewModel: DetailedStockInfoViewModel
    init(stockIdentifier: String) {
        detailStockInfoViewModel = .init(stockSymbol: stockIdentifier)
    }

    var body: some View {
        List {
            Text("Hello")

        }
        .toolbar(content: {
            Button("Add to faveroites", systemImage: "plus.circle.fill") {

            }
        })
    }
}

#Preview {
    DetailedStockInfoView(stockIdentifier: "Test")
}

//"""
//stock_symbol: "AAPL"
//company_description: "AAPL INCL"
//"""
