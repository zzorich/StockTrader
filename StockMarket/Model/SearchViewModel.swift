//
//  SearchViewModel.swift
//  StockMarket
//
//  Created by lingji zhou on 3/31/24.
//

import Foundation
import Alamofire
import Combine

let requestHeader = "https://durable-melody-413101.nn.r.appspot.com/search/autocomplete"
struct SearchResponse: POD {
    let searchKeyword: String?
    let searchResults: [String]

    enum CodingKeys: String, CodingKey {
        case searchKeyword = "search_keyword"
        case searchResults = "symbol_list"
    }
}

struct SearchRequest: POD {
    let searchKeyword: String
}


@Observable
@MainActor
class SearchViewModel {
    var searchKeyword: String = "" {
        didSet {
            searchPublisher.send(searchKeyword)
        }
    }
    private var searchTask: DataTask<SearchResponse>?
    private var oldSearchKeyword: String = ""
    private var searchPublisher = PassthroughSubject<String, Never>()
    private var cancellables = Set<AnyCancellable>()
    var searchItems: [String] = []
    let searchTimer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { timer in

    }

    init() {
        searchPublisher
            .debounce(for: .seconds(0.005), scheduler: RunLoop.main)
                    .removeDuplicates()
                    .sink { [weak self] query in
                        self?.search(with: query)
                    }
                    .store(in: &cancellables)
    }
    func search(with query: String) {
        searchTask?.cancel()
        searchTask = AF.request(requestHeader, method: .get, parameters: ["search_keyword": query])
            .serializingDecodable(SearchResponse.self, automaticallyCancelling: true)

        searchTask?.resume()
        Task(priority: .high) {
            try await fetchSearchResults()
        }
    }

    func fetchSearchResults() async throws {
        guard let response = await searchTask?.response else { return }
        switch response.result {
        case .success(let response):
            guard response.searchKeyword == searchKeyword else { return }
            searchItems = response.searchResults
        case .failure(let error):
            debugPrint(error)
            throw error
        }
    }
}

