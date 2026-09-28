import SwiftUI

// iOS 17 SwiftUI.Bindable backport used by Carbon's Observation-based views.
// Apple's Bindable stores only the wrapped object. On iOS 16 we reproduce that
// storage and create ordinary SwiftUI.Binding values with get/set closures.

@dynamicMemberLookup
@propertyWrapper
public struct UBBindable<Value>: DynamicProperty {
    public var wrappedValue: Value

    public init(rawWrappedValue: Value) {
        self.wrappedValue = rawWrappedValue
    }

    @_silgen_name("$s7SwiftUI8BindableV12wrappedValuexvg")
    public func ub_wrappedValue() -> Value {
        wrappedValue
    }

    @_silgen_name("$s7SwiftUI8BindableV14projectedValueACyxGvg")
    public func ub_projectedValue() -> UBBindable<Value> {
        self
    }
}

@_silgen_name("$s7SwiftUI8BindableVAARlzC11Observation10ObservableRzlE12wrappedValueACyxGx_tcfC")
public func UBBindableInit<Value: AnyObject & UBObservable>(
    wrappedValue: Value
) -> UBBindable<Value> {
    UBBindable(rawWrappedValue: wrappedValue)
}

public extension UBBindable where Value: AnyObject {
    @_silgen_name("$s7SwiftUI8BindableVAARlzClE13dynamicMemberAA7BindingVyqd__Gs24ReferenceWritableKeyPathCyxqd__G_tcluig")
    func ub_dynamicMember<Subject>(
        _ keyPath: ReferenceWritableKeyPath<Value, Subject>
    ) -> Binding<Subject> {
        Binding(
            get: { self.wrappedValue[keyPath: keyPath] },
            set: { self.wrappedValue[keyPath: keyPath] = $0 }
        )
    }
}
