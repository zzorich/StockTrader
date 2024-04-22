//
//  Router.swift
//  StockMarket
//
//  Created by lingji zhou on 4/21/24.
//

import Foundation
import SwiftUI

struct DetailStockItem: Hashable {
    let symbol: String
}
@Observable
class Router {
    var path: NavigationPath = .init()

}
