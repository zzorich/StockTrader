//
//  SearchViewModel.swift
//  StockMarket
//
//  Created by lingji zhou on 3/31/24.
//

import Foundation
import Alamofire
import Combine

private let requestHeader = client.endPoint("/search/autocomplete")

struct AutoSuggestionsResponse: POD {
    let searchKeyword: String?
    let searchResults: [SearchItem]

    enum CodingKeys: String, CodingKey {
        case searchKeyword = "search_keyword"
        case searchResults = "symbol_list"
    }
}

struct SearchItem: POD {
    let companySymbol: String
    let companyDescription: String

    enum CodingKeys: String, CodingKey {
        case companySymbol = "symbol"
        case companyDescription = "description"
    }
}

class SearchViewModel: ObservableObject {
    enum LoadingState {
        case isLoading
        case failed(error: any Error)
        case success([SearchItem])
    }
    @Published var searchKeyWord: String = ""
    private var cancellables = Set<AnyCancellable>()
    private var searchTask: Task<(), Never>?
    @Published var state: LoadingState = .isLoading

    init() {
        $searchKeyWord.debounce(for: 0.02, scheduler: RunLoop.main)
            .sink { [weak self] value in
                guard let self, value == searchKeyWord else { return }
                search(with: searchKeyWord)
            }
            .store(in: &cancellables)
    }

    func search(with query: String) {
        state = .isLoading
        guard !query.isEmpty else {
            state = .success([])
            return
        }

        searchTask = Task { @MainActor in
            let response =  await AF.request(requestHeader!, method: .get, parameters: ["search_keyword": query])
                .serializingDecodable(AutoSuggestionsResponse.self, automaticallyCancelling: true)
                .response.map { response in
                    response.searchResults
                }

            guard query == searchKeyWord else { return }
            switch response.result {
            case .failure(let error):
                state = .failed(error: error)
            case .success(let items):
                state = .success(items)
            }
        }
    }

}

