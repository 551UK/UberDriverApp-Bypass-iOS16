// Back-deploy the Swift 5.9 AsyncStream factory APIs onto the iOS 16
// Swift 5.8 concurrency runtime. The implementation matches Swift's
// open-source standard-library implementation.

@_silgen_name("$sScS10makeStream2of15bufferingPolicyScSyxG6stream_ScS12ContinuationVyx_G12continuationtxm_AG09BufferingE0Oyx__GtFZ")
public func UBAsyncStreamMakeStream<Element>(
    of elementType: Element.Type,
    bufferingPolicy limit: AsyncStream<Element>.Continuation.BufferingPolicy
) -> (
    stream: AsyncStream<Element>,
    continuation: AsyncStream<Element>.Continuation
) {
    var continuation: AsyncStream<Element>.Continuation!
    let stream = AsyncStream<Element>(bufferingPolicy: limit) {
        continuation = $0
    }
    return (stream: stream, continuation: continuation!)
}

@_silgen_name("$sScs10makeStream2of8throwing15bufferingPolicyScsyxs5Error_pG6stream_Scs12ContinuationVyxsAE_p_G12continuationtxm_sAE_pmAI09BufferingF0OyxsAE_p__GtsAE_pRs_rlFZ")
public func UBAsyncThrowingStreamMakeStream<Element>(
    of elementType: Element.Type,
    throwing failureType: Error.Type,
    bufferingPolicy limit: AsyncThrowingStream<Element, Error>.Continuation.BufferingPolicy
) -> (
    stream: AsyncThrowingStream<Element, Error>,
    continuation: AsyncThrowingStream<Element, Error>.Continuation
) {
    var continuation: AsyncThrowingStream<Element, Error>.Continuation!
    let stream = AsyncThrowingStream<Element, Error>(bufferingPolicy: limit) {
        continuation = $0
    }
    return (stream: stream, continuation: continuation!)
}
