//
// Copyright (c) 2020 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

import Foundation

// swiftlint:disable explicit_acl

internal extension CardComponent {
    
    func isPublicKeyValid(key: String) -> Bool {
        let validator = CardPublicKeyValidator()
        return validator.isValid(key)
    }
    
    private func getEncryptedCard(publicKey: String) throws -> CardEncryptor.EncryptedCard {
        let card = CardEncryptor.Card(number: numberItem.value,
                                      securityCode: securityCodeItem.value,
                                      expiryMonth: expiryDateItem.value[0...1],
                                      expiryYear: "20" + expiryDateItem.value[2...3])
        return try CardEncryptor.encryptedCard(for: card, publicKey: publicKey)
    }
    
    func didSelectSubmitButton() {
        guard formViewController.validate() else {
            return
        }
        
        footerItem.showsActivityIndicator = true
        formViewController.view.isUserInteractionEnabled = false
        
        fetchCardPublicKey { [weak self] in
            self?.submitEncryptedCardData(cardPublicKey: $0)
        }
    }
    
    private func submitEncryptedCardData(cardPublicKey: String) {
        do {
            let encryptedCard = try getEncryptedCard(publicKey: cardPublicKey)
            let details = CardDetails(paymentMethod: paymentMethod as! AnyCardPaymentMethod, // swiftlint:disable:this force_cast
                                      encryptedCard: encryptedCard,
                                      holderName: showsHolderNameField ? holderNameItem.value : nil)
            
            let data = PaymentComponentData(paymentMethodDetails: details,
                                            storePaymentMethod: showsStorePaymentMethodField ? storeDetailsItem.value : false)
            
            submit(data: data)
        } catch {
            delegate?.didFail(with: error, from: self)
        }
    }
}

internal extension CardComponent {
    private typealias CardKeyCompletion = (_ cardPublicKey: String) -> Void
    
    private func fetchCardPublicKey(completion: @escaping CardKeyCompletion) {
        do {
            try cardPublicKeyProvider.fetch { [weak self] in
                self?.handle(result: $0, completion: completion)
            }
        } catch {
            delegate?.didFail(with: error, from: self)
        }
    }
    
    private func handle(result: Result<String, Swift.Error>, completion: CardKeyCompletion) {
        switch result {
        case let .success(key):
            completion(key)
        case let .failure(error):
            delegate?.didFail(with: error, from: self)
        }
    }
}

public extension CardComponent {
    
    /// :nodoc:
    @available(*, deprecated, renamed: "showsHolderNameField")
    var showsHolderName: Bool {
        set {
            showsHolderNameField = newValue
        }
        get {
            return showsHolderNameField
        }
    }
}

// swiftlint:enable explicit_acl
