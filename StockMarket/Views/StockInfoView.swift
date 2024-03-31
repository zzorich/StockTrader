//
//  StockInfoView.swift
//  StockMarket
//
//  Created by lingji zhou on 3/30/24.
//

import SwiftUI

struct OwnedStockInfoView: View {
    let stock: OwnedStockInfo
    let stockQuote: StockQuote
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(stock.id.symbol)
                    .bold()
                    .font(.largeTitle)
                Text("\(stock.numberOfSharesOwned) shares")
                    .font(.subheadline)
                    .foregroundStyle(.gray)
            }
            Spacer()
            VStack(alignment: .trailing) {
                Text(stockQuote.currentPrice.formatted(.currency(code: "USD")))
                HStack {
                    switch stockQuote.change {
                    case ..<0:
                        Image(systemName: "circle")
                            .foregroundStyle(.red)
                    case 0:
                        Image(systemName: "circle")
                            .foregroundStyle(.gray)
                    default:
                        Image(systemName: "circle")
                            .foregroundStyle(.green)
                    }
                    Text("\(stockQuote.change.formatted(.currency(code: "USD"))) (\(stockQuote.changeInPercent.formatted(.percent)))")
                }
            }
        }
    }
}

struct FavoriteStockView: View {
    let stock: StockIdentifier
    let quote: StockQuote

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(stock.symbol)
                    .bold()
                    .font(.largeTitle)
                Text(stock.symbol)
                    .font(.subheadline)
                    .foregroundStyle(.gray)
            }
            Spacer()
            VStack(alignment: .trailing) {
                Text(quote.currentPrice.formatted(.currency(code: "USD")))
                HStack {
                    switch quote.change {
                    case ..<0:
                        Image(systemName: "circle")
                            .foregroundStyle(.red)
                    case 0:
                        Image(systemName: "circle")
                            .foregroundStyle(.gray)
                    default:
                        Image(systemName: "circle")
                            .foregroundStyle(.green)
                    }
                    Text("\(quote.change.formatted(.currency(code: "USD"))) (\(quote.changeInPercent.formatted(.percent)))")
                }
            }
        }
    }
}
