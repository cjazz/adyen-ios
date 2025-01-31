//
//  AnalyticsProviderTests.swift
//  Adyen
//
//  Created by Naufal Aros on 4/11/22.
//  Copyright © 2022 Adyen. All rights reserved.
//

import XCTest
@_spi(AdyenInternal) @testable import Adyen
@testable import AdyenNetworking

class AnalyticsProviderTests: XCTestCase {

    func testAnalyticsProviderIsInitializedWithCorrectDefaultConfigurationValues() throws {
        // Given
        let analyticsConfiguration = AnalyticsConfiguration()
        let sut = AnalyticsProvider(apiClient: APIClientMock(), configuration: analyticsConfiguration)

        // Then
        XCTAssertTrue(sut.configuration.isEnabled)
    }

    func testFetchCheckoutAttemptIdWhenAnalyticsIsEnabledShouldTriggerRequest() throws {
        // Given
        var analyticsConfiguration = AnalyticsConfiguration()
        analyticsConfiguration.isEnabled = true

        let apiClient = APIClientMock()
        let sut = AnalyticsProvider(apiClient: apiClient, configuration: analyticsConfiguration)

        let expectedCheckoutAttemptId = checkoutAttemptIdMockValue

        let initialAnalyticsResponse = InitialAnalyticsResponse(checkoutAttemptId: expectedCheckoutAttemptId)
        let checkoutAttemptIdResult: Result<Response, Error> = .success(initialAnalyticsResponse)
        apiClient.mockedResults = [checkoutAttemptIdResult]

        // When
        sut.sendInitialAnalytics(with: .components(type: .achDirectDebit), additionalFields: nil)
        
        wait(until: sut, at: \.checkoutAttemptId, is: expectedCheckoutAttemptId)
    }

    func testFetchCheckoutAttemptIdWhenAnalyticsIsDisabledShouldNotTriggerCheckoutAttemptIdRequest() throws {
        // Given
        var analyticsConfiguration = AnalyticsConfiguration()
        analyticsConfiguration.isEnabled = false
        let apiClient = APIClientMock()
        let sut = AnalyticsProvider(apiClient: apiClient, configuration: analyticsConfiguration)

        // When
        sut.sendInitialAnalytics(with: .components(type: .affirm), additionalFields: nil)
        XCTAssertEqual(sut.checkoutAttemptId, "do-not-track")
    }

    func testFetchCheckoutAttemptIdWhenRequestSucceedShouldCallCompletionWithNonNilValue() throws {
        // Given
        var analyticsConfiguration = AnalyticsConfiguration()
        analyticsConfiguration.isEnabled = true

        let apiClient = APIClientMock()
        let sut = AnalyticsProvider(apiClient: apiClient, configuration: analyticsConfiguration)

        let expectedCheckoutAttemptId = checkoutAttemptIdMockValue

        let initialAnalyticsResponse = InitialAnalyticsResponse(checkoutAttemptId: expectedCheckoutAttemptId)
        let checkoutAttemptIdResult: Result<Response, Error> = .success(initialAnalyticsResponse)
        apiClient.mockedResults = [checkoutAttemptIdResult]

        // When
        sut.sendInitialAnalytics(with: .components(type: .achDirectDebit), additionalFields: nil)
        
        // Then
        wait(until: sut, at: \.checkoutAttemptId, is: expectedCheckoutAttemptId)
    }

    func testFetchCheckoutAttemptIdWhenAnalyticsIsEnabledGivenFailureShouldCallCompletionWithNilValue() throws {
        // Given
        var analyticsConfiguration = AnalyticsConfiguration()
        analyticsConfiguration.isEnabled = true

        let apiClient = APIClientMock()
        let sut = AnalyticsProvider(apiClient: apiClient, configuration: analyticsConfiguration)

        let error = NSError(domain: "", code: 500, userInfo: [NSLocalizedDescriptionKey: "Internal Server Error"])
        let checkoutAttemptIdResult: Result<Response, Error> = .failure(error)
        apiClient.mockedResults = [checkoutAttemptIdResult]

        // When
        sut.sendInitialAnalytics(with: .components(type: .atome), additionalFields: nil)
        // Then
        XCTAssertNil(sut.checkoutAttemptId, "The checkoutAttemptId is not nil.")
    }

    func testFetchCheckoutAttemptIdWhenAnalyticsIsEnabledShouldSetCheckoutAttemptIdProperty() throws {
        // Given
        var analyticsConfiguration = AnalyticsConfiguration()
        analyticsConfiguration.isEnabled = true
        
        let apiClient = APIClientMock()
        let sut = AnalyticsProvider(apiClient: apiClient, configuration: analyticsConfiguration)

        let expectedCheckoutAttemptId = checkoutAttemptIdMockValue

        let initialAnalyticsResponse = InitialAnalyticsResponse(checkoutAttemptId: expectedCheckoutAttemptId)
        let checkoutAttemptIdResult: Result<Response, Error> = .success(initialAnalyticsResponse)
        apiClient.mockedResults = [checkoutAttemptIdResult]

        // When
        sut.sendInitialAnalytics(with: .components(type: .atome), additionalFields: nil)
        
        // Then
        wait(until: sut, at: \.checkoutAttemptId, is: expectedCheckoutAttemptId)
    }

    func testFetchCheckoutAttemptIdWhenAnalyticsIsDisabledShouldNotSetCheckoutAttemptIdProperty() throws {
        // Given
        var analyticsConfiguration = AnalyticsConfiguration()
        analyticsConfiguration.isEnabled = false
        
        let apiClient = APIClientMock()
        let sut = AnalyticsProvider(apiClient: apiClient, configuration: analyticsConfiguration)

        let initialAnalyticsResponse = InitialAnalyticsResponse(checkoutAttemptId: checkoutAttemptIdMockValue)
        let checkoutAttemptIdResult: Result<Response, Error> = .success(initialAnalyticsResponse)
        apiClient.mockedResults = [checkoutAttemptIdResult]

        // When
        sut.sendInitialAnalytics(with: .components(type: .affirm), additionalFields: nil)
        // Then
        XCTAssertEqual(sut.checkoutAttemptId, "do-not-track")
    }
    
    func testInitialRequest() throws {
        // Given
        
        let checkoutAttemptId = checkoutAttemptIdMockValue
        
        let analyticsExpectation = expectation(description: "Initial request is triggered")
        
        let apiClient = APIClientMock()
        apiClient.mockedResults = [
            .success(InitialAnalyticsResponse(checkoutAttemptId: checkoutAttemptId)),
        ]
        apiClient.onExecute = { request in
            if let initialAnalyticsdRequest = request as? InitialAnalyticsRequest {
                XCTAssertNil(initialAnalyticsdRequest.amount)
                XCTAssertEqual(initialAnalyticsdRequest.version, adyenSdkVersion)
                XCTAssertEqual(initialAnalyticsdRequest.platform, "ios")
                analyticsExpectation.fulfill()
            }
        }
        
        let analyticsProvider = AnalyticsProvider(
            apiClient: apiClient,
            configuration: AnalyticsConfiguration()
        )
        
        // When
        
        analyticsProvider.sendInitialAnalytics(with: .components(type: .achDirectDebit), additionalFields: nil)
        
        wait(for: [analyticsExpectation], timeout: 10)
    }
    
    func testAdditionalFields() throws {
     
        // Given
        
        let amount = Amount(value: 1, currencyCode: "EUR")
        let checkoutAttemptId = checkoutAttemptIdMockValue
        
        let analyticsExpectation = expectation(description: "Initial request is triggered")
        
        let apiClient = APIClientMock()
        apiClient.mockedResults = [
            .success(InitialAnalyticsResponse(checkoutAttemptId: checkoutAttemptId))
        ]
        apiClient.onExecute = { request in
            if let initialAnalyticsdRequest = request as? InitialAnalyticsRequest {
                XCTAssertEqual(initialAnalyticsdRequest.amount, amount)
                XCTAssertEqual(initialAnalyticsdRequest.version, "version")
                XCTAssertEqual(initialAnalyticsdRequest.platform, "react-native")
                analyticsExpectation.fulfill()
            }
        }
        
        var analyticsConfiguration = AnalyticsConfiguration()
        analyticsConfiguration.context = .init(version: "version", platform: .reactNative)
        
        let analyticsProvider = AnalyticsProvider(
            apiClient: apiClient,
            configuration: analyticsConfiguration
        )
        
        // When
        let additionalFields = AdditionalAnalyticsFields(amount: amount, sessionId: nil)
        analyticsProvider.sendInitialAnalytics(with: .components(type: .achDirectDebit), additionalFields: additionalFields)
        
        wait(for: [analyticsExpectation], timeout: 10)
    }
    
    func testInitialRequestEncoding() throws {
        
        let analyticsData = AnalyticsData(flavor: .components(type: .achDirectDebit),
                                          additionalFields: AdditionalAnalyticsFields(amount: .init(value: 1, currencyCode: "EUR"), sessionId: "test_session_id"),
                                          context: AnalyticsContext(version: "version", platform: .flutter))
        
        let request = InitialAnalyticsRequest(data: analyticsData)
        
        let encodedRequest = try JSONEncoder().encode(request)
        let decodedRequest = try XCTUnwrap(JSONSerialization.jsonObject(with: encodedRequest) as? [String: Any])
        
        let expectedDecodedRequest = [
            "locale": "en_US",
            "paymentMethods": analyticsData.paymentMethods,
            "platform": "flutter",
            "component": "ach",
            "flavor": "components",
            "channel": "iOS",
            "systemVersion": analyticsData.systemVersion,
            "screenWidth": analyticsData.screenWidth,
            "referrer": analyticsData.referrer,
            "deviceBrand": analyticsData.deviceBrand,
            "deviceModel": analyticsData.deviceModel,
            "amount": [
                "currency": "EUR",
                "value": 1
            ] as [String: Any],
            "sessionId": "test_session_id",
            "version": "version"
        ] as [String: Any]
        
        XCTAssertEqual(
            NSDictionary(dictionary: decodedRequest),
            NSDictionary(dictionary: expectedDecodedRequest)
        )
    }

    // MARK: - Private

    private var checkoutAttemptIdMockValue: String {
        "cb3eef98-978e-4f6f-b299-937a4450be1f1648546838056be73d8f38ee8bcc3a65ec14e41b037a59f255dcd9e83afe8c06bd3e7abcad993"
    }
}
