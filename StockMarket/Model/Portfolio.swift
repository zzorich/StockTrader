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
    let stockSymbol: String
    let currentPrice: Double
    let change: Double
    let changeInPercent: Double
    let highPrice: Double
    let lowPrice: Double
    let openPrice: Double
    let previousClosePrice: Double

    enum CodingKeys: String, CodingKey {
        case stockSymbol = "stock_symbol"
        case currentPrice = "c"
        case change = "d"
        case changeInPercent = "dp"
        case highPrice = "h"
        case lowPrice = "l"
        case openPrice = "o"
        case previousClosePrice = "pc"
    }
}


struct InitialData: POD {
    struct UserInfo: POD {
        let balance: Double

        enum CodingKeys: String, CodingKey {
            case balance = "sum"
        }
    }
    struct Favorite: POD {
        let stockSymbol: String

        enum CodingKeys: String, CodingKey {
            case stockSymbol = "symbol"
        }
    }
    struct OwnedStock: POD {
        let stockSymbol: String
        let companyName: String
        let cost: Double
        let quantity: Int

        enum CodingKeys: String, CodingKey {
            case stockSymbol = "ticker"
            case companyName = "company"
            case cost
            case quantity
        }
    }

    let user: UserInfo
    let favorite: [Favorite]
    let ownedStock: [OwnedStock]


    enum CodingKeys: String, CodingKey {
        case user
        case favorite
        case ownedStock = "portfolio"
    }
}
struct CompanyProfile: POD {
    let name: String
    let ticker: String
}


struct StockIdentifier: Identifiable, Hashable, Equatable, Comparable {
    static func < (lhs: StockIdentifier, rhs: StockIdentifier) -> Bool {
        lhs.symbol < rhs.symbol
    }
    
    let symbol: String
    var id: String { symbol }
    static let test: Self = .init(symbol: "test")


}

@Observable
class PortfolioViewModel {
    @MainActor
    init() {
        fetchIntialData()
    }

    enum LoadingState {
        case isLoading
        case loaded
        case failed(error: Error)
    }

    @MainActor var loadingState = LoadingState.isLoading
    @MainActor var isDataDirty = false {
        didSet {
            if isDataDirty {
                fetchIntialData()
            }
        }
    }

    @ObservationIgnored private var allStocks: [StockIdentifier: StockQuote] = [:]
    @MainActor private(set) var stocksOwned: [StockIdentifier: InitialData.OwnedStock] = [:]
    @MainActor private(set) var favorites: [InitialData.Favorite] = []
    @MainActor var cashBalance: Double = 25000
    @MainActor var netWorth: Double {
        stocksOwned.reduce(into: cashBalance) { partialResult, stock in
            guard let quote = quote(of: stock.key) else { return }
            partialResult += quote.currentPrice * Double(stock.value.quantity)
        }
    }

}


private let mainInfoURL: URL? = {
    client.endPointInDataBase("/main_info")
}()

private let getQuoteURL: URL? = {
    client.endPoint("/detailed_stock_info/quote")
}()

private let addFavoriteURL: URL? = {
    client.endPointInDataBase("/favoriteCreate")
}()

private let removeFavoriteURL: URL? = {
    client.endPointInDataBase("/favoriteDeleteOne")
}()

private let buyURL: URL? = {
    client.endPointInDataBase("/portfolioBuy")
}()

private let sellURL: URL? = {
    client.endPointInDataBase("/portfolioSell")
}()

private func fetchQuote(of stock: String) async throws -> StockQuote {
    let response = await AF.request(getQuoteURL!, method: .get, parameters: ["symbol": stock])
        .serializingDecodable(StockQuote.self)
        .response

    switch response.result {
    case .success(let stockQuote):
        return stockQuote
    case .failure(let error):
        throw error
    }
}

// API Requests
@MainActor
extension PortfolioViewModel {


    func reloadDataIfNeeded() {
        guard isDataDirty else { return }
        loadingState = .isLoading
        fetchIntialData()
        isDataDirty = false
    }

    func fetchIntialData() {
        print("Start loading")
        Task(priority: .high) {
            let response = await AF.request(mainInfoURL!, method: .get)
                .serializingDecodable(InitialData.self, automaticallyCancelling: true)
                .response

            var mainInfo: InitialData?
            switch response.result {
            case .success(let _mainInfo):
                mainInfo = _mainInfo
            case .failure(let failure):
                loadingState = .failed(error: failure)
                debugPrint(String(data: response.data ?? Data(), encoding: .utf8))
            }

            guard let mainInfo else { return }

            let allStocks =
            Set(
                mainInfo.favorite.map ({ favorite in
                    favorite.stockSymbol
                })
                +
                mainInfo.ownedStock.map({ stock in
                    stock.stockSymbol
                })
            )

            do {
                try await withThrowingTaskGroup(of: StockQuote.self) { group in
                    allStocks.forEach { stock in
                        group.addTask {
                            try await fetchQuote(of: stock)
                        }

                    }

                    for try await quote in group {
                        self.allStocks[StockIdentifier(symbol: quote.stockSymbol)] = quote
                    }

                    self.favorites = mainInfo.favorite
                    self.stocksOwned = mainInfo.ownedStock.reduce(into: .init(), { partialResult, stock in
                        let id = StockIdentifier(symbol: stock.stockSymbol)
                        partialResult[id] = stock
                    })

                    cashBalance = mainInfo.user.balance
                }
            } catch {
                loadingState = .failed(error: error)
            }

            loadingState = .loaded
        }
    }

    struct PlainData: POD {
        let symbol: String
    }


    func addFavorite(stockSymbol: String) {
        Task {
            guard let data = try? JSONEncoder().encode(PlainData(symbol: stockSymbol)) else { return }
            guard let code = await AF.request(addFavoriteURL!, method: .post, parameters: data, encoder: JSONParameterEncoder.default).serializingData().response.response?.statusCode else { return }

            if code != 200 {
                isDataDirty = true
            }
        }
    }

    func postRemoveFavorite(stock: StockIdentifier) {
        Task {
            guard let data = try? JSONEncoder().encode(PlainData(symbol: stock.symbol)) else { return }
            guard let code = await AF.request(removeFavoriteURL!, method: .post, parameters: data, encoder: JSONParameterEncoder.default).serializingData().response.response?.statusCode else { return }

            if code != 200 {
                isDataDirty = true
            }
        }
    }

    func removeFavoriteStocks(at indexSet: IndexSet) {
        favorites.remove(atOffsets: indexSet)

        indexSet
            .map { index in
                favorites[index]
            }
            .map { favorite in
                favorite.stockSymbol
            }
            .map(StockIdentifier.init(symbol: ))
            .forEach(postRemoveFavorite(stock:))
    }

    func removeFavorites(from oldIndexSet: IndexSet, to newIndex: Int) {
        favorites.move(fromOffsets: oldIndexSet, toOffset: newIndex)
    }

    func quote(of stock: StockIdentifier) -> StockQuote? { allStocks[stock] }



    func canBuy(stockPrice: Double, numberOfShares: Int) -> Bool {
        numberOfShares > 0 && Double(numberOfShares) * stockPrice <= cashBalance

    }

    func buy(stock: String, stockPrice: Double, numberOfShares: Int, companyName: String) {
        guard canBuy(stockPrice: stockPrice, numberOfShares: numberOfShares) else { return }
        cashBalance -= Double(numberOfShares) * stockPrice
        assert(cashBalance >= 0)

        let info = InitialData.OwnedStock(stockSymbol: stock, companyName: companyName, cost: stockPrice, quantity: numberOfShares)
        guard let data = try? JSONEncoder().encode(info) else { return }

        Task(priority: .high) {
            let response = await AF.request(buyURL!, method: .post,
                                                        parameters: data,
                                                        encoder: JSONParameterEncoder.default).serializingData().response
            switch response.result {
            case.success(_):
                isDataDirty = true
            case .failure(let error):
                return
            }
        }
    }

    func canSell(stock: String, numberOfShares: Int) -> Bool {
        let id = StockIdentifier(symbol: stock)
        if let quantity = stocksOwned[id]?.quantity, quantity >= numberOfShares {
            return true
        } else {
            return false
        }
    }

    func sell(stock: String, stockPrice: Double, numberOfShares: Int, companyName: String) {
        guard canBuy(stockPrice: stockPrice, numberOfShares: numberOfShares) else { return }
        cashBalance += Double(numberOfShares) * stockPrice
        assert(cashBalance >= 0)

        let info = InitialData.OwnedStock(stockSymbol: stock, companyName: companyName, cost: stockPrice, quantity: numberOfShares)
        guard let data = try? JSONEncoder().encode(info) else { return }

        Task(priority: .high) {
            let response = await AF.request(buyURL!, method: .post,
                                                        parameters: data,
                                                        encoder: JSONParameterEncoder.default).serializingData().response

            switch response.result {
            case.success(_):
                isDataDirty = true
            case .failure(let error):
                return
            }
        }
    }
}

@MainActor
extension PortfolioViewModel {

}
