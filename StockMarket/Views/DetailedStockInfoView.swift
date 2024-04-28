//
//  DetailedStockInfoView.swift
//  StockMarket
//
//  Created by lingji zhou on 4/18/24.
//

import Foundation
import SwiftUI




typealias VM = DetailedStockInfoViewModel
struct DetailedStockInfoContainer: View {
    private let detailStockInfoViewModel: DetailedStockInfoViewModel
    init(stockIdentifier: String) {
        detailStockInfoViewModel = .init(stockSymbol: stockIdentifier)
    }

    var body: some View {
        switch detailStockInfoViewModel.loadingState {
        case .loaded(let stockInfo):
            DetailStockInfoView(stockInfo: stockInfo)
        case .failed(let error):
            Text(error.localizedDescription)
        case .isLoading:
            ProgressView()
        }
    }
}

struct DetailStockInfoView: View {
    let stockInfo: VM.StockInfo
    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading) {
                BasicInfoHeader(info: stockInfo.basicInfo)
                Color.clear
                    .frame(minHeight: 400)
                    .overlay {
                        TabCharts(stockInfo: stockInfo)
                    }
                Spacer(minLength: 20)
                HStack {
                    PortfolioSection(stockInfo: stockInfo)
                    Spacer()
                    Button {

                    } label: {
                        ZStack {
                            Capsule(style: .continuous)
                                .fill(Color.green)
                            Text("Trade")
                                .foregroundStyle(.white)
                        }
                        .frame(maxWidth: 150)
                        .frame(height: 60)
                    }
                }

                Spacer(minLength: 20)
                StatsSection(stats: stockInfo.stats)

                Spacer(minLength: 20)
                AboutSection(aboutInfo: stockInfo.about)
            }
            .padding([.leading, .trailing])

        }
        .toolbar(content: {
            Button("Add to faveroites", systemImage: "plus.circle.fill") {

            }
        })
    }
}

private struct BasicInfoHeader: View {
    let info: DetailedStockInfoViewModel.BasicInfo
    var body: some View {
        VStack(alignment: .leading) {
            Text(info.stockSymbol)
                .bold()
                .font(.title)
            Text(info.companyName)
                .font(.footnote)
                .foregroundStyle(.secondary)

            HStack {
                Text(info.currentPrice.currencyFormated)
                    .font(.title2)
                PriceChangeLabel(changeInPrice: info.changePrice, changeInPercent: info.changePercent)
            }

        }
    }
}

private struct TabCharts: View {
    let stockInfo: DetailedStockInfoViewModel.StockInfo
    var body: some View {
        TabView {
            WebView(url: stockInfo.charts.hourlyPriceChart)
                .tabItem {
                    Label("Hourly", systemImage: "chart.xyaxis.line")
                }
            WebView(url: stockInfo.charts.historicalMarketChart)
                .tabItem {
                    Label("historical", systemImage: "clock.fill")
                }
        }
    }
}

private struct StatsSection: View {
    let stats: VM.Stats
    var body: some View {
        Grid(alignment: .leading) {
            GridRow {
                Text("Stats").bold()
                    .font(.title2)
            }
            GridRow {
                Text("High Price ").bold() + Text("\(stats.highPrice.currencyFormated)")
                    .font(.callout)
                Text("Low Price ").bold() + Text("\(stats.lowPrice.currencyFormated)")
                    .font(.callout)
            }

            GridRow {
                Text("Open Price ").bold() + Text("\(stats.openPrice.currencyFormated)")
                    .font(.callout)
                Text("Prev. Close").bold() + Text("\(stats.previousClosePrice.currencyFormated)")
                    .font(.callout)
            }
        }
    }
}


private struct InsightsSection: View {
    let insights: VM.Insights

    var body: some View {
        Grid {
            GridRow {

            }

            GridRow {

            }
        }
    }
}


private struct AboutSection: View {
    let aboutInfo: VM.AboutInfo
    var body: some View {
        Grid(alignment: .leading) {
            GridRow {
                Text("About").bold()
                    .font(.title2)
            }
            GridRow {
                Text("IPO Start Date:")
                    .bold()
                Text(DateFormatter.yyyyMMdd.string(from: aboutInfo.ipoStartDate))
            }

            GridRow {
                Text("Industry:")
                    .bold()
                Text(aboutInfo.industry)
            }

            GridRow {
                Text("WebPage:")
                    .bold()
                Link(aboutInfo.webpageLink.absoluteString, destination: aboutInfo.webpageLink)
                    .lineLimit(1)
            }

            GridRow {
                Text("Company Peers:")
                    .bold()
                ScrollView(.horizontal) {
                    HStack {
                        ForEach(aboutInfo.companyPeersSymbols, id: \.self) { symbol in
                            NavigationLink("\(symbol), ", value: DetailStockItem(symbol: symbol))
                        }
                    }
                }
            }
        }
    }
}


private struct PortfolioSection: View {
    let stockInfo: DetailedStockInfoViewModel.StockInfo

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Portfolio").bold()
                .font(.title2)
            if let portfolio = stockInfo.portfolio {

                let marketValue = stockInfo.basicInfo.currentPrice * Double(portfolio.sharedOwned)
                let totalCost = portfolio.averageCost * Double(portfolio.sharedOwned)
                let change = totalCost - marketValue

                Text("Shares Owned:  ").bold()
                + Text("\(portfolio.sharedOwned)")

                Text("Avg Cost/Share:  ").bold()
                + Text("\(portfolio.averageCost.currencyFormated)")

                Text("Total Cost:  ").bold()
                + Text("\((totalCost).currencyFormated)")

                Text("Change:  ").bold()
                + Text(change.currencyFormated)
                    .foregroundStyle(Color.priceTextColor(for: change))

                Text("Market Value:  ").bold()
                + Text(marketValue.currencyFormated)
                    .foregroundStyle(Color.priceTextColor(for: change))
            } else {
                Text("You have 0 shares of \(stockInfo.basicInfo.stockSymbol).\nStart trading!")
            }
        }
    }
}
#Preview {
    DetailedStockInfoContainer(stockIdentifier: "AAPL")
}

//"""
//stock_symbol: "AAPL"
//company_description: "AAPL INCL"
//"""
