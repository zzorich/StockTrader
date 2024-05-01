//
//  StockInfoView.swift
//  StockMarket
//
//  Created by lingji zhou on 3/30/24.
//

import SwiftUI

struct OwnedStockInfoView: View {
    let stock: InitialData.OwnedStock
    let stockQuote: StockQuote
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(stock.stockSymbol)
                    .bold()
                    .font(.largeTitle)
                Text("\(stock.quantity) shares")
                    .font(.subheadline)
                    .foregroundStyle(.gray)
            }
            Spacer()
            VStack(alignment: .trailing) {
                Text(stockQuote.currentPrice.formatted(.currency(code: "USD")))
                PriceChangeLabel(changeInPrice: stockQuote.currentPrice - stock.cost, changeInPercent: (stockQuote.currentPrice - stock.cost) / 100)
            }
        }
    }
}

struct FavoriteStockView: View {
    let stock: InitialData.Favorite
    let quote: StockQuote

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(stock.stockSymbol)
                    .bold()
                    .font(.largeTitle)
                Text(stock.companyName)
                    .font(.subheadline)
                    .foregroundStyle(.gray)
            }
            Spacer()
            VStack(alignment: .trailing) {
                Text(quote.currentPrice.formatted(.currency(code: "USD")))
                PriceChangeLabel(changeInPrice: quote.change, changeInPercent: quote.changeInPercent)

            }
        }
    }
}
