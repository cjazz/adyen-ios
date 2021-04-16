//
// Copyright (c) 2020 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

import Adyen

/// A form item into which a card's security code (CVC/CVV) is entered.
internal final class FormCardSecurityCodeItem: FormTextItem {
    
    /// :nodoc:
    internal var localizationParameters: LocalizationParameters?
    
    /// :nodoc:
    @Observable(nil) internal var selectedCard: CardType?

    /// :nodoc:
    @Observable(nil) internal var dynamicTitle: String? {
        didSet {
            title = dynamicTitle
        }
    }

    /// :nodoc:
    @Observable(false) internal var isCVCOptional: Bool
    
    /// Initializes the form card number item.
    internal init(style: FormTextItemStyle = FormTextItemStyle(),
                  localizationParameters: LocalizationParameters? = nil) {
        self.localizationParameters = localizationParameters
        super.init(style: style)
        
        dynamicTitle = ADYLocalizedString("adyen.card.cvcItem.title", localizationParameters)
        validator = securityCodeValidator
        formatter = securityCodeFormatter
        
        validationFailureMessage = ADYLocalizedString("adyen.card.cvcItem.invalid", localizationParameters)
        keyboardType = .numberPad
    }

    internal func update(cardBrands: [CardBrand]) {
        let isCVCOptional = cardBrands.isCVCOptional

        let titleFailureMessageKey = isCVCOptional ? "adyen.card.cvcItem.title.optional" : "adyen.card.cvcItem.title"
        dynamicTitle = ADYLocalizedString(titleFailureMessageKey, localizationParameters)
        validator = isCVCOptional ? nil : securityCodeValidator

        self.isCVCOptional = isCVCOptional
    }
    
    override internal func build(with builder: FormItemViewBuilder) -> AnyFormItemView {
        builder.build(with: self)
    }
    
    private lazy var securityCodeFormatter = CardSecurityCodeFormatter(publisher: $selectedCard)
    private lazy var securityCodeValidator = CardSecurityCodeValidator(publisher: $selectedCard)
}

extension FormItemViewBuilder {
    internal func build(with item: FormCardSecurityCodeItem) -> FormItemView<FormCardSecurityCodeItem> {
        FormCardSecurityCodeItemView(item: item)
    }
}

extension Array where Element == CardBrand {
    var isCVCOptional: Bool {
        guard !isEmpty else { return false }
        return allSatisfy { brand in
            switch brand.cvcPolicy {
            case .optional, .hidden:
                return true
            default:
                return false
            }
        }
    }
}
