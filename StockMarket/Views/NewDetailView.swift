//
//  NewDetailView.swift
//  StockMarket
//
//  Created by lingji zhou on 4/28/24.
//

import SwiftUI
private let twitterBaseURL: String = "https://twitter.com/intent/tweet?"
private let facebookBaseURL: String = "https://www.facebook.com/sharer/sharer.php?"

struct NewDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let new: VM.New
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Spacer()
                Button(action: { dismiss() }, label: {
                    Image(systemName: "xmark.circle")
                })
            }
            Text(new.source)
                .font(.title)
                .bold()
            Text(new.date.formatted(.dateTime))
                .foregroundStyle(.secondary)

            Divider()
            Text(new.headline)
                .font(.headline)
            Text("")
            Text(new.summary)

            Text("")
            HStack {
                Text("For more details click ")
                    .foregroundStyle(.secondary)
                Link("here", destination: new.link)
            }
            .font(.footnote)

            HStack {

                if let facebookURL, let twitterURL {
                    Link(destination: twitterURL, label: {
                        Image(.tw)
                            .resizable()
                            .frame(width: 50, height: 50)
                    })
                    Link(destination: facebookURL, label: {
                        Image(.facebook)
                            .resizable()
                            .frame(width: 50, height: 50)
                    })
                } else {
                    Text("error")
                }


            }

            Spacer()
        }
        .padding()
    }
}


extension NewDetailView {
    var facebookURL: URL? {
        var components = URLComponents(string: facebookBaseURL)

        let text = "\(new.summary) \(new.link.absoluteString)"
        components?.queryItems = [
            URLQueryItem(name: "u", value: new.link.absoluteString)
        ]

        return components?.url
    }

    var twitterURL: URL? {
        var components = URLComponents(string: twitterBaseURL)

        let text = "\(new.summary) \(new.link.absoluteString)"
        components?.queryItems = [
            URLQueryItem(name: "text", value: text)
        ]

        return components?.url
    }
}
