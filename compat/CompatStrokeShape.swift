import SwiftUI

// iOS 17+ SwiftUI.StrokeShapeView ABI backport.
//
// Carbon constructs StrokeShapeView inline. The frozen layout used by newer
// SwiftUI is one stored value: the nested ModifiedContent tree below. iOS 16
// already contains every component of that tree, so this local type can use
// the same memory layout while its View conformance renders through the older
// SwiftUI implementation.
@frozen
public struct UBStrokeShapeView<
    Content: Shape,
    Style: ShapeStyle,
    Background: View
>: View {
    @usableFromInline
    var view: ModifiedContent<
        _ShapeView<_StrokedShape<Content>, Style>,
        _BackgroundModifier<Background>
    >

    public typealias Body = ModifiedContent<
        _ShapeView<_StrokedShape<Content>, Style>,
        _BackgroundModifier<Background>
    >

    public var body: Body {
        view
    }
}
