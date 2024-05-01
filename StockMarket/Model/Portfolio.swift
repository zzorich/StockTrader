//
//  Portfolio.swift
//  StockMarket
//
//  Created by lingji zhou on 3/30/24.
//

import Foundation
import Observation
import Alamofire
import Combine



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
        let companyName: String

        enum CodingKeys: String, CodingKey {
            case stockSymbol = "symbol"
            case companyName = "company"
        }
    }

    struct OwnedStock: POD {
        let stockSymbol: String
        let companyName: String
        let cost: Double
        var quantity: Int

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
}

@Observable
class PortfolioViewModel {
    private var subscriptions = Set<AnyCancellable>()

    @MainActor
    init() {
        fetchIntialData()
        Timer.publish(every: 15, on: .main, in: .common).autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                isDataDirty = true
                updateData()
            }
            .store(in: &subscriptions)
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
                Task {
                    try? await Task.sleep(nanoseconds: 1000000)
                    fetchIntialData()
                }
            }
        }
    }

    @ObservationIgnored private var allStocks: [StockIdentifier: StockQuote] = [:]
    @MainActor var stocksOwned: [InitialData.OwnedStock] = []
    @MainActor var favorites: [InitialData.Favorite] = []
    @MainActor var cashBalance: Double = 25000
    @MainActor var netWorth: Double {
        stocksOwned.reduce(into: cashBalance) { partialResult, stock in
            guard let quote = quote(of: stock.stockSymbol) else { return }
            partialResult += quote.currentPrice * Double(stock.quantity)
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

struct ReloadParameter: POD {
    let favorites: [String]
    let portfolios: [String]
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

    func updateData() {
        loadingState = .isLoading
        Task(priority: .high) {
            let reloadParameters = ReloadParameter(favorites: favorites.map({$0.stockSymbol}), portfolios: stocksOwned.map({$0.stockSymbol}))
            let response = await AF.request(mainInfoURL!, method: .get, parameters: reloadParameters, encoder: JSONParameterEncoder.default)
                .serializingDecodable(InitialData.self, automaticallyCancelling: true)
                .response

            var mainInfo: InitialData?
            switch response.result {
            case .success(let _mainInfo):
                mainInfo = _mainInfo
            case .failure(let failure):
                loadingState = .failed(error: failure)
                debugPrint(String(data: response.data ?? Data(), encoding: .utf8) ?? "")
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
                    self.stocksOwned = mainInfo.ownedStock

                    cashBalance = mainInfo.user.balance
                }
            } catch {
                loadingState = .failed(error: error)
            }

            loadingState = .loaded
        }
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
                debugPrint(String(data: response.data ?? Data(), encoding: .utf8) ?? "")
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
                    self.stocksOwned = mainInfo.ownedStock

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


    func addFavorite(stockSymbol: String) async -> Bool {
        guard let code = await AF.request(addFavoriteURL!, method: .post, parameters: ["symbol": stockSymbol], encoder: JSONParameterEncoder.default).serializingData().response.response?.statusCode else { return false }

        if code == 200 {
            isDataDirty = true
            return true
        } else {
            return false
        }
    }

    func postRemoveFavorite(stockSymbol: String) {
        Task {
            guard let code = await AF.request(removeFavoriteURL!, method: .post, parameters: ["symbol": stockSymbol], encoder: JSONParameterEncoder.default).serializingData().response.response?.statusCode else { return }

            if code != 200 {
                isDataDirty = true
            }
        }
    }

    func removeFavoriteStocks(at indexSet: IndexSet) {

        indexSet
            .map { index in
                favorites[index]
            }
            .map { favorite in
                favorite.stockSymbol
            }
            .forEach(postRemoveFavorite(stockSymbol:))
        favorites.remove(atOffsets: indexSet)
    }

    @inlinable
    func quote(of stock: StockIdentifier) -> StockQuote? { allStocks[stock] }

    func quote(of stockSymbol: String) -> StockQuote? {
        let id = StockIdentifier(symbol: stockSymbol)
        return quote(of: id)
    }


    func canBuy(stockPrice: Double, numberOfShares: Int) -> Bool {
        numberOfShares > 0 && Double(numberOfShares) * stockPrice <= cashBalance
    }


    struct BuyStockResponse: POD {
        let quote: StockQuote
        let portfolio: InitialData.OwnedStock
    }

    func buy(stockSymbol: String, stockPrice: Double, numberOfShares: Int, companyName: String) async -> Bool {
        guard canBuy(stockPrice: stockPrice, numberOfShares: numberOfShares) else { return false }
        let info = InitialData.OwnedStock(stockSymbol: stockSymbol, companyName: companyName, cost: stockPrice, quantity: numberOfShares)

        let response = await AF.request(buyURL!, method: .post,
                                        parameters: info, encoder: JSONParameterEncoder.default).serializingDecodable(BuyStockResponse.self, automaticallyCancelling: true).response
        switch response.result {
        case.success(let buyStockResponse):
            let id = StockIdentifier(symbol: stockSymbol)
            allStocks[id] = buyStockResponse.quote
            if let index = stocksOwned.firstIndex(where: {$0.stockSymbol == stockSymbol}) {
                stocksOwned[index] = buyStockResponse.portfolio
            } else {
                stocksOwned.append(buyStockResponse.portfolio)
            }
            return true
        case .failure(_):
            debugPrint(String(data: response.data ?? Data(), encoding: .utf8) ?? "")
            return false
        }
    }

    func canSell(stock: String, numberOfShares: Int) -> Bool {
        if let quantity = stocksOwned.first(where: {$0.stockSymbol == stock})?.quantity, quantity >= numberOfShares {
            return true
        } else {
            return false
        }
    }

    func sell(stock: String, stockPrice: Double, numberOfShares: Int, companyName: String) async -> Bool {
        guard canSell(stock: stock, numberOfShares: numberOfShares) else { return false }
        guard let index = stocksOwned.firstIndex(where: {$0.stockSymbol == stock}) else { return false }

        let info = InitialData.OwnedStock(stockSymbol: stock, companyName: companyName, cost: stockPrice, quantity: numberOfShares)

        let response = await AF.request(sellURL!, method: .post,
                                        parameters: info, encoder: JSONParameterEncoder.default).serializingData().response

        switch response.result {
        case.success(_):
            cashBalance += Double(numberOfShares) * stockPrice
            stocksOwned[index].quantity -= numberOfShares
            if stocksOwned[index].quantity == 0 { stocksOwned.remove(at: index) }
            return true
        case .failure(_):
            debugPrint(String(data: response.data ?? Data(), encoding: .utf8) ?? "")
            return false
        }
    }
}
