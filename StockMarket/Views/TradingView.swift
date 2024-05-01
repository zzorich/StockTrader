//
//  TradingView.swift
//  StockMarket
//
//  Created by lingji zhou on 4/30/24.
//

import SwiftUI

struct TradingSuccessState {
    enum TradingInfo: String {
        case buy = "bought"
        case sold
    }
    let info: TradingInfo
    let numberOfSharesTraded: Int
}

enum TradingState {
    case trading, success(info: TradingSuccessState)
}

struct TradingView: View {
    @State private var tradingState: TradingState = .trading
    @State private var showingToast: Bool = false
    @State private var toastMessage: String = ""

    @EnvironmentObject private var router: Router
    @Environment(\.dismiss) private var dismiss
    let stockInfo: VM.BasicInfo
    @State private var selectedNumberOfShares: UInt? = nil
    @Environment(PortfolioViewModel.self) private var portfolio
    private var totalPrice: Double {
        Double(selectedNumberOfShares ?? 0) * stockInfo.currentPrice
    }

    @MainActor
    private var tradingBody: some View {
      VStack {
            Text("Trade \(stockInfo.companyName) shares")
                .font(.title)
                .bold()
            Spacer()
            HStack(alignment: .lastTextBaseline) {
                TextField("0", value: $selectedNumberOfShares, format: .number)
                    .font(.system(size: 80))
                    .keyboardType(.numberPad)
                Text("Shares")
                    .font(.title)
                    .bold()
            }
            Text("x\(stockInfo.currentPrice.currencyFormated) = \(totalPrice.currencyFormated)")
                .frame(maxWidth: .infinity, alignment: .trailing)

            Spacer()
            Text("\(portfolio.cashBalance.currencyFormated) avaliable to buy \(stockInfo.stockSymbol)")
                .font(.footnote)
                .foregroundStyle(.secondary)

            HStack {
                Button {
                    if let selectedNumberOfShares, portfolio.canBuy(stockPrice: stockInfo.currentPrice, numberOfShares: Int(selectedNumberOfShares)) {
                        Task {
                            let buySuccess = await portfolio.buy(stockSymbol: stockInfo.stockSymbol, stockPrice: stockInfo.currentPrice, numberOfShares: Int(selectedNumberOfShares), companyName: stockInfo.companyName)
                            if buySuccess {
                                withAnimation {
                                    tradingState = .success(info: .init(info: .buy, numberOfSharesTraded: Int(selectedNumberOfShares)))
                                }
                            }
                        }
                    } else {
                        toastAnimation(message: "Please enter a valid amount")
                    }
                } label: {
                    Capsule()
                        .foregroundStyle(.green)
                        .overlay {
                            Text("Buy")
                                .foregroundStyle(.white)
                        }
                }

                Button {
                    let selectedNumberOfShares = selectedNumberOfShares ?? 0
                    if selectedNumberOfShares > 0, portfolio.canSell(stock: stockInfo.stockSymbol, numberOfShares: Int(selectedNumberOfShares)) {
                        Task {
                            let isSold = await portfolio.sell(stock: stockInfo.stockSymbol, stockPrice: stockInfo.currentPrice, numberOfShares: Int(selectedNumberOfShares), companyName: stockInfo.companyName)

                            if isSold {
                                withAnimation {
                                    tradingState = .success(info: .init(info: .sold, numberOfSharesTraded: Int(selectedNumberOfShares)))
                                }
                            }
                        }
                    } else if selectedNumberOfShares == 0{
                        toastAnimation(message: "Please enter a valid amount")
                    } else {
                        toastAnimation(message: "Not enought amount to sell")
                    }

                } label: {
                    Capsule()
                        .foregroundStyle(.green)
                        .overlay {
                            Text("Sell")
                                .foregroundStyle(.white)
                        }
                }
            }
            .frame(height: 80)
        }
        .toasted(isShowingToast: $showingToast, message: toastMessage)
        .padding()
    }

    private func toastAnimation(message: String) {
        withAnimation {
            toastMessage = message
            showingToast = true
        } completion: {
            DispatchQueue.main.asyncAfter(deadline: .now()+1) {
                withAnimation {
                    showingToast = false
                }
            }
        }
    }

    func successfulBody(info: TradingSuccessState) -> some View {
        ZStack {
            Color.green
                .ignoresSafeArea()
            VStack {
                Spacer()
                Text("Congratulations!")
                    .bold()
                    .font(.largeTitle)
                Text("You have successfully \(info.info.rawValue) shares of \(stockInfo.stockSymbol)")
                    .lineLimit(1)
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Capsule()
                        .frame(height: 60)
                        .foregroundStyle(.white)
                        .overlay {
                            Text("Done")
                                .foregroundStyle(.green)
                        }
                }
                .padding()
            }
            .foregroundStyle(.white)
        }
    }

    var body: some View {
        switch tradingState {
        case .trading:
            tradingBody
        case .success(let info):
            successfulBody(info: info)
        }
    }
}

