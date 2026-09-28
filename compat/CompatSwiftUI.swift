import SwiftUI

// Back-deploy the iOS 17 View.onChange overloads onto the iOS 16 SwiftUI
// implementation. The public Swift ABI is preserved with @_silgen_name;
// the opaque-result descriptors are exported separately from assembly.

private final class UBPreviousValue<Value> {
    var value: Value
    init(_ value: Value) { self.value = value }
}

public extension View {
    @_silgen_name("$s7SwiftUI4ViewPAAE8onChange2of7initial_Qrqd___Sbyqd___qd__tctSQRd__lF")
    func ub_onChangePair<Value: Equatable>(
        of value: Value,
        initial: Bool,
        _ action: @escaping (Value, Value) -> Void
    ) -> some View {
        let previous = UBPreviousValue(value)
        return self
            .onChange(of: value) { newValue in
                let oldValue = previous.value
                previous.value = newValue
                action(oldValue, newValue)
            }
            .onAppear {
                if initial {
                    action(value, value)
                }
            }
    }

    @_silgen_name("$s7SwiftUI4ViewPAAE8onChange2of7initial_Qrqd___SbyyctSQRd__lF")
    func ub_onChangeZero<Value: Equatable>(
        of value: Value,
        initial: Bool,
        _ action: @escaping () -> Void
    ) -> some View {
        self
            .onChange(of: value) { _ in action() }
            .onAppear {
                if initial {
                    action()
                }
            }
    }
}
