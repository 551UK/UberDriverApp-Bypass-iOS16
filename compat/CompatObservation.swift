// Minimal iOS 16 ABI backport for the Swift Observation module used by
// Uber Driver 4.584. Observation itself is unavailable on iOS 16.
//
// This preserves the ABI surface Carbon imports. Property access tracking is
// intentionally disabled, while mutations still execute their supplied closure.

public protocol UBObservable {}

public struct UBObservationRegistrar {
    // ObservationRegistrar's public resilient value is represented here by
    // one machine word. The metadata aliases in CompatSwiftCore.s make Carbon
    // use this layout for the unavailable iOS 17 Observation type.
    private var token: UInt = 0

    public init() {}

    @_silgen_name("$s11Observation0A9RegistrarV6access_7keyPathyx_s03KeyE0Cyxq_GtAA10ObservableRzr0_lF")
    public func ub_access<Subject: UBObservable, Member>(
        _ subject: Subject,
        keyPath: KeyPath<Subject, Member>
    ) {
        // Observation tracking is unavailable on iOS 16.
    }

    @_silgen_name("$s11Observation0A9RegistrarV7willSet_7keyPathyx_s03KeyF0Cyxq_GtAA10ObservableRzr0_lF")
    public func ub_willSet<Subject: UBObservable, Member>(
        _ subject: Subject,
        keyPath: KeyPath<Subject, Member>
    ) {
        // No tracking callbacks on iOS 16.
    }

    @_silgen_name("$s11Observation0A9RegistrarV6didSet_7keyPathyx_s03KeyF0Cyxq_GtAA10ObservableRzr0_lF")
    public func ub_didSet<Subject: UBObservable, Member>(
        _ subject: Subject,
        keyPath: KeyPath<Subject, Member>
    ) {
        // No tracking callbacks on iOS 16.
    }

    @_silgen_name("$s11Observation0A9RegistrarV12withMutation2of7keyPath_q0_x_s03KeyG0Cyxq_Gq0_yKXEtKAA10ObservableRzr1_lF")
    public func ub_withMutation<Subject: UBObservable, Member, Result>(
        of subject: Subject,
        keyPath: KeyPath<Subject, Member>,
        _ mutation: () throws -> Result
    ) rethrows -> Result {
        return try mutation()
    }
}

@_silgen_name("$s11Observation0A9RegistrarVACycfC")
public func UBObservationRegistrarInit() -> UBObservationRegistrar {
    UBObservationRegistrar()
}

@_silgen_name("$s11Observation04withA8Tracking_8onChangexxyXE_yyYbcyXKtlF")
public func UBWithObservationTracking<Result>(
    _ apply: () -> Result,
    onChange: @autoclosure () -> @Sendable () -> Void
) -> Result {
    // Evaluate the tracked computation normally. The change callback is not
    // installed because iOS 16 has no Observation runtime.
    return apply()
}
