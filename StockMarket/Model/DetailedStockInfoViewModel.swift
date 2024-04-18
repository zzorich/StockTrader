//
//  DetailedStockInfoViewModel.swift
//  StockMarket
//
//  Created by lingji zhou on 4/18/24.
//

import Foundation
struct BasicInfo {

}
@Observable
class DetailedStockInfoViewModel {

    struct BasicInfo: POD {
        let stockSymbol: String
        let companyName: String
    }

    enum LoadingState {
        case isLoading, loaded(basicInfo: BasicInfo), failed(error: Error)
    }

    @MainActor
    var loadingState: LoadingState = .isLoading

    private var task: Task<(), Never>

    init(stockSymbol: String) {
        
        task = Task {

        }
    }

    func fetchStockInfo(withId stockSymbol: String) async {

    }


    deinit {
        task.cancel()
    }
}
