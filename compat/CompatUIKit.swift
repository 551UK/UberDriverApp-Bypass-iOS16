import UIKit

// iOS 17+ UIAction initializer backport.
//
// iOS 16 already supports title/subtitle/image/identifier/discoverabilityTitle/
// attributes/state/handler. The newer overload adds selectedImage. Preserve all
// iOS 16-supported behavior and ignore selectedImage on systems that cannot
// display a separate selected-state image.
@_silgen_name("$sSo8UIActionC5UIKitE5title8subtitle5image13selectedImage10identifier20discoverabilityTitle10attributes5state7handlerABSS_SSSgSo7UIImageCSgAPSo0A10IdentifieraSgAMSo23UIMenuElementAttributesVSo0pQ5StateVyABctcfC")
public func UBUIActionSelectedImageInit(
    title: String,
    subtitle: String?,
    image: UIImage?,
    selectedImage: UIImage?,
    identifier: UIAction.Identifier?,
    discoverabilityTitle: String?,
    attributes: UIMenuElement.Attributes,
    state: UIMenuElement.State,
    handler: @escaping (UIAction) -> Void
) -> UIAction {
    _ = selectedImage
    return UIAction(
        title: title,
        subtitle: subtitle,
        image: image,
        identifier: identifier,
        discoverabilityTitle: discoverabilityTitle,
        attributes: attributes,
        state: state,
        handler: handler
    )
}
