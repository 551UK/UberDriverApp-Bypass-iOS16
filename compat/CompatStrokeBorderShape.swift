import SwiftUI

// iOS 17+ SwiftUI.StrokeBorderShapeView ABI backport.
//
// The iOS 17 SwiftUI interface declares this as @frozen with two stored
// properties:
//   1. the original InsettableShape
//   2. the nested ModifiedContent view representing its inset stroke.
//
// iOS 16 already contains the component types used by that nested view, so we
// reproduce the same public/frozen storage shape and render through the older
// SwiftUI primitives.
@frozen
public struct UBStrokeBorderShapeView<
    Content: InsettableShape,
    Style: ShapeStyle,
    Background: View
>: View {
    public var shape: Content

    @usableFromInline
    var view: ModifiedContent<
        _ShapeView<_StrokedShape<Content.InsetShape>, Style>,
        _BackgroundModifier<Background>
    >

    public typealias Body = ModifiedContent<
        _ShapeView<_StrokedShape<Content.InsetShape>, Style>,
        _BackgroundModifier<Background>
    >

    public init(
        shape: Content,
        style: Style,
        strokeStyle: StrokeStyle,
        isAntialiased: Bool,
        background: Background
    ) {
        self.shape = shape
        self.view = .init(
            content: _ShapeView(
                shape: _StrokedShape(
                    shape: shape.inset(by: strokeStyle.lineWidth * 0.5),
                    style: strokeStyle
                ),
                style: style,
                fillStyle: FillStyle(antialiased: isAntialiased)
            ),
            modifier: _BackgroundModifier(background: background)
        )
    }

    public var body: Body {
        view
    }
}
