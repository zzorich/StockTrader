//
//  Portfolio.swift
//  StockMarket
//
//  Created by lingji zhou on 3/30/24.
//

import Foundation
import Observation
import Alamofire



typealias POD = Codable & Equatable & Hashable

struct StockQuote: POD {
    let currentPrice: Double
    let change: Double
    let changeInPercent: Double
    let highPrice: Double
    let lowPrice: Double
    let openPrice: Double
    let previousClosePrice: Double

    enum CodingKeys: String, CodingKey {
        case currentPrice = "c"
        case change = "d"
        case changeInPercent = "dp"
        case highPrice = "h"
        case lowPrice = "l"
        case openPrice = "o"
        case previousClosePrice = "pc"
    }

    static let test: Self = .init(currentPrice: 1, change: 1, changeInPercent: 1, highPrice: 1, lowPrice: 1, openPrice: 1, previousClosePrice: 1)
}

struct CompanyProfile: POD {
    let name: String
    let ticker: String
}


struct StockIdentifier: Identifiable, Hashable, Equatable {
    let symbol: String
    var id: String { symbol }
    static let test: Self = .init(symbol: "test")
}

@Observable
class PortfolioViewModel {
    @ObservationIgnored private var allStocks: [StockIdentifier: StockQuote] = [:]
    @MainActor private(set) var stocksOwned: [OwnedStockInfo] = []
    @MainActor private(set) var favorites: [StockIdentifier] = []
    @MainActor var cashBalance: Double = 25000
    @MainActor var netWorth: Double {
        stocksOwned.reduce(into: cashBalance) { partialResult, stock in
            guard let quote = quote(of: stock.id) else { return }
            partialResult += quote.currentPrice * Double(stock.numberOfSharesOwned)
        }
    }


}

struct OwnedStockInfo: Identifiable {
    let id: StockIdentifier
    let numberOfSharesOwned = 1
}
// API Requests
@MainActor
extension PortfolioViewModel {
    func addFavorite(stock: StockIdentifier) async throws {
        guard !favorites.contains(stock) else { return }
        guard !allStocks.keys.contains(stock) else { 
            favorites.append(stock)
            return
        }

        let quote = try await fetchQuote(of: stock)
        allStocks[stock] = quote
        favorites.append(stock)
    }

    func removeFavorite(stock: StockIdentifier) {
        favorites.removeAll { stockInList in
            stockInList.id == stock.id
        }
    }

    func removeFavoriteStocks(at indexSet: IndexSet) {
        favorites.remove(atOffsets: indexSet)
    }

    func removeFavorites(from oldIndexSet: IndexSet, to newIndex: Int) {
        favorites.move(fromOffsets: oldIndexSet, toOffset: newIndex)
    }

    func quote(of stock: StockIdentifier) -> StockQuote? { allStocks[stock] }

    static let test: PortfolioViewModel = {
        let model = PortfolioViewModel()
        model.stocksOwned.append(.init(id: .test))
        model.favorites.append(.test)
        model.allStocks[.test] = .test
        let test2 = StockIdentifier(symbol: "Test2")
        model.stocksOwned.append(.init(id: test2))
        model.favorites.append(test2)
        model.allStocks[test2] = .test
        return model
    }()

    func fetchQuote(of stock: StockIdentifier) async throws -> StockQuote {
        return .test
    }
}
