//
// Copyright (c) 2020 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

import Adyen
import AdyenActions
import AdyenCard
import AdyenDropIn
import AdyenComponents
import UIKit

internal protocol Presenter: AnyObject {

    func present(viewController: UIViewController, completion: (() -> Void)?)

    func dismiss(completion: (() -> Void)?)

    func presentAlert(withTitle title: String)

    func presentAlert(with error: Error, retryHandler: (() -> Void)?)
}

internal final class PaymentsController {
    internal let payment = Payment(amount: Configuration.amount, countryCode: Configuration.countryCode)
    internal let environment = Configuration.componentsEnvironment

    internal var paymentMethods: PaymentMethods?
    internal var currentComponent: PresentableComponent?
    internal var paymentInProgress: Bool = false

    internal weak var presenter: Presenter?

    // MARK: - Action Handling

    private lazy var actionComponent: AdyenActionComponent = {
        let handler = AdyenActionComponent()
        handler.redirectComponentStyle = RedirectComponentStyle()
        handler.delegate = self
        handler.presentationDelegate = self
        handler.environment = environment
        handler.clientKey = Configuration.clientKey
        return handler
    }()

    private func handle(_ action: Action) {
        guard paymentInProgress else { return }
        if let dropInComponent = currentComponent as? DropInComponent {
            return dropInComponent.handle(action)
        }

        actionComponent.perform(action)
    }

    // MARK: - Networking

    // swiftlint:disable:enable force_try
    private lazy var apiClient: APIClientProtocol = {
        if CommandLine.arguments.contains("-UITests") {
            let apiClient = APIClientMock()
            let data = try! Data(contentsOf: Bundle.main.url(forResource: "payment_methods_response", withExtension: "json")!)
            let response = try! JSONDecoder().decode(PaymentMethodsResponse.self, from: data)
            apiClient.mockedResults = [.success(response)]
            return apiClient
        } else {
            return DefaultAPIClient()
        }
    }()
    // swiftlint:disable:disable force_try

    internal func requestPaymentMethods() {
        let request = PaymentMethodsRequest()
        apiClient.perform(request) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case let .success(response):
                self.paymentMethods = response.paymentMethods
            case let .failure(error):
                self.presentAlert(with: error, retryHandler: self.requestPaymentMethods)
            }
        }
    }

    internal func performPayment(with data: PaymentComponentData) {
        let request = PaymentsRequest(data: data)
        apiClient.perform(request, completionHandler: paymentResponseHandler)
    }

    internal func performPaymentDetails(with data: ActionComponentData) {
        let request = PaymentDetailsRequest(details: data.details,
                                            paymentData: data.paymentData,
                                            merchantAccount: Configuration.merchantAccount)
        apiClient.perform(request, completionHandler: paymentResponseHandler)
    }

    private func paymentResponseHandler(result: Result<PaymentsResponse, Error>) {
        switch result {
        case let .success(response):
            if let action = response.action {
                handle(action)
            } else {
                finish(with: response.resultCode)
            }
        case let .failure(error):
            currentComponent?.stopLoading(withSuccess: false) { [weak self] in
                self?.presenter?.dismiss(completion: nil)
                self?.presentAlert(with: error)
            }
        }
    }

    internal func finish(with resultCode: PaymentsResponse.ResultCode) {
        let success = resultCode == .authorised || resultCode == .received || resultCode == .pending

        currentComponent?.stopLoading(withSuccess: success) { [weak self] in
            self?.presenter?.dismiss(completion: nil)
            self?.presentAlert(withTitle: resultCode.rawValue)
        }
    }

    internal func finish(with error: Error) {
        let isCancelled = ((error as? ComponentError) == .cancelled)

        presenter?.dismiss { [weak self] in
            if !isCancelled {
                self?.presentAlert(with: error)
            }
        }
    }

    private func presentAlert(with error: Error, retryHandler: (() -> Void)? = nil) {
        presenter?.presentAlert(with: error, retryHandler: retryHandler)
    }

    private func presentAlert(withTitle title: String) {
        presenter?.presentAlert(withTitle: title)
    }
}
