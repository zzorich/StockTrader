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
            searchQueryPublisher.send(searchKeyword)
        }
    }
    private var searchTask: DataTask<SearchResponse>?
    private var searchQueryPublisher = PassthroughSubject<String, Never>()
    private var cancellables = Set<AnyCancellable>()
    var searchItems: [String] = []

    init() {
        searchQueryPublisher
            .debounce(for: .seconds(0.005), scheduler: RunLoop.main)
                    .removeDuplicates()
                    .sink { [weak self] query in
                        if !query.isEmpty {
                            self?.search(with: query)
                        }
                    }
                    .store(in: &cancellables)
    }

    func search(with query: String) {
        searchTask?.cancel()
        searchTask = AF.request(requestHeader, method: .get, parameters: ["search_keyword": query])
            .serializingDecodable(SearchResponse.self, automaticallyCancelling: true)

        searchTask?.resume()
        Task(priority: .high) {
            try await fetchSearchResults(query: query)
        }
    }

    func fetchSearchResults(query: String) async throws {
        guard let response = await searchTask?.response else { return }
        guard query == searchKeyword else { return }
        switch response.result {
        case .success(let response):
            self.searchItems = response.searchResults
        case .failure(let error):
            debugPrint(error)
            throw error
        }
    }
}

