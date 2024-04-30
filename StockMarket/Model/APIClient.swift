//
//  APIClient.swift
//  StockMarket
//
//  Created by lingji zhou on 4/30/24.
//

import Foundation

let client = APIClient.shared
class APIClient {
    static let shared = APIClient()
    private var baseComponent: URLComponents = {
        var component = URLComponents()
        component.scheme = "https"
        component.host = "durable-melody-413101.nn.r.appspot.com"

        return component
    }()

    func endPoint(_ destination: String) -> URL? {
        baseComponent.path = destination
        return baseComponent.url
    }

    func endPointInDataBase(_ destination: String) -> URL? {
        baseComponent.path = "/database" + destination
        return baseComponent.url
    }
}
