//
//  DetailedStockInfoViewModel.swift
//  StockMarket
//
//  Created by lingji zhou on 4/18/24.
//

import Foundation
import Alamofire

private let requestHeader = "https://durable-melody-413101.nn.r.appspot.com/detailed_stock_info/details"

@Observable
class DetailedStockInfoViewModel {

    enum LoadingState {
        case isLoading, loaded(stockInfo: StockInfo), failed(error: Error)
    }

    @MainActor
    var loadingState: LoadingState = .isLoading

    private var task: Task<(), Never>!

    init(stockSymbol: String) {
        task = Task { @MainActor in
            let response = await AF.request(requestHeader, method: .get, parameters: ["symbol": "AAPL"])
                .serializingDecodable(StockInfo.self, automaticallyCancelling: true)
                .response

            switch response.result {
            case .success(let stockInfo):
                loadingState = .loaded(stockInfo: stockInfo)
                print(stockInfo.about.ipoStartDate)
            case .failure(let error):
                loadingState = .failed(error: error)
            }
        }
    }

    deinit { task.cancel() }
}

extension DetailedStockInfoViewModel {
    struct StockInfo: POD {
        let basicInfo: BasicInfo
        let charts: Charts
        let portfolio: Portfolio?
        let stats: Stats
        let insights: Insights
        let about: AboutInfo
        let news: [New]
        
        enum CodingKeys:String, CodingKey {
            case basicInfo = "basic_info"
            case charts
            case portfolio
            case stats
            case insights
            case about = "about_info"
            case news
        }
    }
}

extension DetailedStockInfoViewModel {
    struct BasicInfo: POD {
        let stockSymbol: String
        let companyName: String
        let currentPrice: Double
        let changePrice: Double
        let changePercent: Double
        
        enum CodingKeys: String, CodingKey {
            case stockSymbol = "symbol"
            case companyName = "company_name"
            case currentPrice = "current_price"
            case changePrice = "change_price"
            case changePercent = "change_percent"
        }
    }
    
    struct Charts: POD {
        let hourlyPriceChart: URL
        let historicalMarketChart: URL
        let historicalEpsChart: URL
        let recommendationChart: URL
        
        enum CodingKeys: String, CodingKey {
            case hourlyPriceChart = "hourly_price_chart"
            case historicalMarketChart = "historical_market_chart"
            case historicalEpsChart = "historical_eps_chart"
            case recommendationChart = "recommendation_chart"
        }
    }
    
    struct Portfolio: POD {
        let sharedOwned: Int
        let averageCost: Double
        
        enum CodingKeys: String, CodingKey {
            case sharedOwned = "shared_owned"
            case averageCost = "average_cost"
        }
    }
    
    struct Stats: POD {
        let highPrice: Double
        let lowPrice: Double
        let openPrice: Double
        let previousClosePrice: Double
        
        enum CodingKeys: String, CodingKey {
            case highPrice = "high_price"
            case lowPrice = "low_price"
            case openPrice = "open_price"
            case previousClosePrice = "previous_close_price"
        }
    }
    
    struct Insights: POD {
        let totalMSPR: Double
        let positiveMSPR: Double
        let negativeMSPR: Double
        let totalChange: Double
        let positiveChange: Double
        let negativeChange: Double
        
        enum CodingKeys: String, CodingKey {
            case totalMSPR = "total_mspr"
            case positiveMSPR = "positive_mspr"
            case negativeMSPR = "negative_mspr"
            case totalChange = "total_change"
            case positiveChange = "positive_change"
            case negativeChange = "negative_change"
        }
    }
    
    struct AboutInfo: POD {
        let ipoStartDate: Date
        let industry: String
        let webpageLink: URL
        let companyPeersSymbols: [String]
        
        enum CodingKeys: String, CodingKey {
            case ipoStartDate = "ipo_start_date"
            case industry = "industry"
            case webpageLink = "webpage_link"
            case companyPeersSymbols = "company_peers_symbols"
        }

        init(from decoder: any Decoder) throws {
            let container: KeyedDecodingContainer<DetailedStockInfoViewModel.AboutInfo.CodingKeys> = try decoder.container(keyedBy: DetailedStockInfoViewModel.AboutInfo.CodingKeys.self)
            let ipoStartDateString = try container.decode(String.self, forKey: DetailedStockInfoViewModel.AboutInfo.CodingKeys.ipoStartDate)
            guard let date = DateFormatter.yyyyMMdd.date(from: ipoStartDateString) else {
                throw DecodingError.dataCorruptedError(forKey: .ipoStartDate,
                                                             in: container,
                                                             debugDescription: "Date string does not match format expected by formatter.")
            }
            self.ipoStartDate = date
            self.industry = try container.decode(String.self, forKey: DetailedStockInfoViewModel.AboutInfo.CodingKeys.industry)
            self.webpageLink = try container.decode(URL.self, forKey: DetailedStockInfoViewModel.AboutInfo.CodingKeys.webpageLink)
            self.companyPeersSymbols = try container.decode([String].self, forKey: DetailedStockInfoViewModel.AboutInfo.CodingKeys.companyPeersSymbols)
        }
    }
    
    struct New: POD, Identifiable {
        let id: Int
        let datetime: Date
        let headline: String
        let imageUrl: URL?
        let related: String
        let source: String
        let summary: String
        let link: URL
        
        
        enum CodingKeys: String, CodingKey {
            case id
            case datetime
            case headline
            case imageUrl = "image"
            case related
            case source
            case summary
            case link = "url"
        }
    }
}

extension DateFormatter {
    static let yyyyMMdd: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }()
}
