//
//  Search.swift
//  OctoKit
//
//  Created by Cristian Kocza on 14/02/2021.
//  Copyright © 2021 nerdish by nature. All rights reserved.
//

import Foundation
import RequestKit
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public class SearchResults<T: Codable>: Codable {
    open var totalCount: Int
    open var incompleteResults: Bool
    open var items: [T]
    
    enum CodingKeys: String, CodingKey {
        case totalCount = "total_count"
        case incompleteResults = "incomplete_results"
        case items
    }
}

public extension Octokit {
    
    @discardableResult
    func searchIssues(_ session: RequestKitURLSession = URLSession.shared,
                      repo: String? = nil,
                      type: String? = "issue",
                      openess: Openness = .open,
                      involves: String? = nil,
                      author: String? = nil,
                      archived: Bool = false,
                      completion: @escaping (_ response: Response<SearchResults<Issue>>) -> Void) -> URLSessionDataTaskProtocol? {
        let router = SearchRouter.searchIssues(config: configuration, repo: repo, type: type, openess: openess, involves: involves, author: author, archived: archived)
        return router.load(session, dateDecodingStrategy: .formatted(Time.rfc3339DateFormatter), expectedResultType: SearchResults<Issue>.self) { issues, error in
            if let error = error {
                completion(Response.failure(error))
            } else {
                if let issues = issues {
                    completion(Response.success(issues))
                }
            }
        }
    }
}
enum SearchRouter: JSONPostRouter {
    case searchIssues(config: Configuration, repo: String?, type: String?, openess: Openness, involves: String?, author: String?, archived: Bool)
    
    var method: HTTPMethod { .GET }
    
    var encoding: HTTPEncoding { .url }
    
    var configuration: Configuration {
        switch self {
        case let .searchIssues(config, _, _, _, _, _, _): return config
        }
    }
    
    var params: [String: Any] {
        switch self {
        case let .searchIssues(_, repo, type, openess, involves, author, archived):
            return ["q": [("repo", repo),
                     ("type", type),
                     ("is", openess.rawValue),
                     ("involves", involves),
                     ("author", author),
                     ("archived", archived.description)]
                        .compactMap { $1 == nil ? nil : "\($0):\($1!)"}
                        .joined(separator: "+")]
        }
    }
    
    var path: String {
        switch self {
        case .searchIssues:
            return "search/issues"
        }
    }
    
    func urlQuery(_ parameters: [String : Any]) -> [URLQueryItem]? {
        parameters.map { URLQueryItem(name: $0, value: "\($1)")}
    }
}
