//
// Copyright (c) 2023 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

@_spi(AdyenInternal) import Adyen
import Adyen3DS2
import Foundation
#if canImport(AdyenAuthentication)
    import AdyenAuthentication
#endif

extension ThreeDS2ClassicActionHandler {
    
    /// Initializes the 3D Secure 2 action handler.
    internal convenience init(context: AdyenContext,
                              appearanceConfiguration: ADYAppearanceConfiguration,
                              delegatedAuthenticationConfiguration: ThreeDS2Component.Configuration.DelegatedAuthentication?,
                              presentationDelegate: PresentationDelegate?) {
        let defaultHandler = createDefaultThreeDS2CoreActionHandler(
            context: context,
            appearanceConfiguration: appearanceConfiguration,
            delegatedAuthenticationConfiguration: delegatedAuthenticationConfiguration,
            presentationDelegate: presentationDelegate
        )
        self.init(
            context: context,
            appearanceConfiguration: appearanceConfiguration,
            coreActionHandler: defaultHandler,
            delegatedAuthenticationConfiguration: delegatedAuthenticationConfiguration
        )
    }
}
