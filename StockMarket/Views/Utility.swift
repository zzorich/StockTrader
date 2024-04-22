//
//  Utility.swift
//  StockMarket
//
//  Created by lingji zhou on 4/21/24.
//

import Foundation
import SwiftUI


extension Double {
    var currencyFormated: String {
        self.formatted(.currency(code: "USD").precision(.fractionLength(0...2)))
    }

    var percentFormated: String {
        self.formatted(.percent.precision(.fractionLength(0...2)))
    }
}

extension Color {
    static func priceTextColor(for changeInPrice: Double) -> Self {
        if changeInPrice > 0 {
            .green
        } else if changeInPrice < 0 {
            .red
        } else {
            .gray
        }
    }
}

extension String {
    static func priceLabelName(for changeInPrice: Double) -> Self {
        if changeInPrice > 0 {
            "arrow.up.right"
        } else if changeInPrice < 0 {
            "arrow.down.right"
        } else {
            "minus"
        }
    }
}
struct PriceChangeLabel: View {
    let changeInPrice: Double
    let changeInPercent: Double

    private var labelName: String {
        .priceLabelName(for: changeInPrice)
    }

    private var color: Color {
        .priceTextColor(for: changeInPrice)
    }

    private var priceChangeText: String {
        changeInPrice.currencyFormated
    }

    private var priceChangePercentText: String {
        (changeInPercent / 100).percentFormated
    }

    var body: some View {
        Label("\(priceChangeText) (\(priceChangePercentText))", systemImage: labelName)
            .foregroundStyle(self.color)
    }
}

