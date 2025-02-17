//
// Copyright (c) 2023 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

import AdyenNetworking
import Foundation

internal struct AnalyticsResponse: Response { /* Empty response */ }

internal struct AnalyticsRequest: APIRequest {
    
    internal typealias ResponseType = AnalyticsResponse

    internal let path: String
    
    internal var counter: UInt = 0
    
    internal let headers: [String: String] = [:]

    internal let queryParameters: [URLQueryItem] = []

    internal let method: HTTPMethod = .post
    
    internal var channel: String = "iOS"
    
    internal var infos: [AnalyticsEventInfo] = []
    
    internal var logs: [AnalyticsEventLog] = []
    
    internal var errors: [AnalyticsEventError] = []
    
    internal init(checkoutAttemptId: String) {
        self.path = "checkoutanalytics/v3/analytics/\(checkoutAttemptId)"
    }
    
    private enum CodingKeys: String, CodingKey {
        case channel
        case infos = "info"
        case logs
        case errors
        
    }
}
