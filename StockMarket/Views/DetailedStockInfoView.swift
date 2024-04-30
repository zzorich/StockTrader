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
    @Environment(PortfolioViewModel.self) private var vm
    @State private var tappedNew: VM.New? = nil
    let stockInfo: VM.StockInfo
    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 10) {
                BasicInfoHeader(info: stockInfo.basicInfo)
                Color.clear
                    .frame(minHeight: 400)
                    .overlay {
                        TabCharts(stockInfo: stockInfo)
                    }
                HStack {
                    PortfolioSection(stockInfo: stockInfo)
                    Spacer()
                    if stockInfo.basicInfo.isMarketOpen {
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
                }

                StatsSection(stats: stockInfo.stats)

                AboutSection(aboutInfo: stockInfo.about)

                InsightsSection(insights: stockInfo.insights)

                WebView(url: stockInfo.charts.recommendationChart)
                    .frame(minHeight: 400)

                WebView(url: stockInfo.charts.historicalEpsChart)
                    .frame(minHeight: 400)

                Text("News")
                    .bold()
                if let firstNew = stockInfo.news.first, let imageURL = firstNew.imageUrl {
                    VStack(alignment: .leading) {
                        AsyncImage(url: imageURL) { image in
                            image.resizable()
                                .scaledToFit()
                                .clipShape(RoundedRectangle(cornerRadius: /*@START_MENU_TOKEN@*/25.0/*@END_MENU_TOKEN@*/))
                        } placeholder: {
                            ProgressView("loading")
                        }
                        NewCellView(new: firstNew)
                    }
                    .onTapGesture {
                        tappedNew = firstNew
                    }
                }
                Divider()

                ForEach(stockInfo.news.dropFirst()) { new in
                    NewCellView(new: new)
                        .onTapGesture {
                            tappedNew = new
                        }
                }
            }
            .padding([.leading, .trailing])

        }
        .toolbar(content: {
            let canAdd = !vm.favorites.map({$0.stockSymbol}).contains(stockInfo.basicInfo.stockSymbol)
            Button("Add to faveroites", systemImage: canAdd ? "plus.circle" : "plus.circle.fill") {
                guard canAdd else { return }
                Task {
                    vm.addFavorite(stockSymbol: stockInfo.basicInfo.stockSymbol)
                }
            }
        })
        .sheet(item: $tappedNew) { new in
            NewDetailView(new: new)
        }
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
        Grid(verticalSpacing: 10) {
            GridRow {
                Text("Insights")
                    .gridCellColumns(3)
                    .frame(maxWidth: /*@START_MENU_TOKEN@*/.infinity/*@END_MENU_TOKEN@*/, alignment: .leading)
            }

            GridRow {
                Text("Insider Sentiments")
                    .gridCellColumns(3)
            }

            GridRow {
                Text(insights.companyName)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("MSPR")
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("Change")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .bold()

            GridRow {
                Text("Total")
                    .bold()
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text((insights.positiveMSPR+insights.negativeChange).currencyFormated)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text((insights.positiveChange+insights.negativeChange).currencyFormated)
                    .frame(maxWidth: .infinity, alignment: .leading)

            }

            GridRow {
                Text("Positive")
                    .bold()
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text(insights.positiveMSPR.currencyFormated)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(insights.positiveChange.currencyFormated)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            GridRow {
                Text("Negative")
                    .bold()
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text(insights.negativeChange.currencyFormated)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(insights.negativeChange.currencyFormated)
                    .frame(maxWidth: .infinity, alignment: .leading)
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

private struct NewCellView: View {
    let new: VM.New

    var body: some View {
        VStack(alignment: .leading) {
            Text("\(new.source),  \(new.date.timeIntervalSinceNowDescription)")
                .font(.footnote)
                .foregroundStyle(.gray)
            Text(new.headline)
                .font(.headline)
            Text("")
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
