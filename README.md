# UberDriverApp Bypass iOS 16

Rootless compatibility candidate **0.6.1** for Uber Driver **4.527.10000** on **iOS 16.2+**.

## What the v0.5.0 log proved

The v0.5.0 hook loaded and the native Cronet hook installed. However, the log also showed the attempted Objective-C hooks for `DriverChecksErrorData.issues` and `futureBlockers` both returned **0**, so that generated Swift model is not exposed through the Objective-C runtime in this build.

The old app's generated Go Online service has a direct `version` argument and a `DriverGoOnlineV2Request.deviceData` field. That means the app version can be inside the serialized Go Online payload rather than a standalone HTTP header.

## v0.6.1 changes

- Hooks `Cronet_UrlRequest_InitWithParams`, not just header-add calls, so headers are inspected and rewritten at the **final native request boundary**.
- Rewrites **any Cronet header value** containing:
  - `4.527.10000` → `4.584.10000`
  - `273504.1` → `326106.1`
- Rewrites `x-uber-device-data` at that final boundary too.
- Applies equal-length compatibility replacement to **opaque Uber request bodies**, not only device-registration bodies. This specifically covers serialized Thrift/protobuf-style Go Online payloads where the old version string may be embedded in `deviceData`.
- Adds focused diagnostics for:
  - `drivers/v2/go-online`
  - `drivers/v2/fetch-online-blockers`
- Removes the noisy “request observed” and repeated JSON-change log spam so the useful Go Online diagnostics are not exhausted immediately after launch.
- Spoofs iOS **18.0 / 22A3354** across every OS identity path, including UIDevice, NSProcessInfo, bundle metadata, request metadata, x-uber-device-data, opaque bodies and sysctl. `kern.osrelease` is spoofed as **24.0.0**.

## Test

Install **v0.6.1**, respring, fully kill Uber Driver, reopen it and attempt **Go Online**.

Then send `Documents/UberDriverBypass.log`.

The most useful new line is:

`Cronet go-online final request headers inspected appVersionHeader=... deviceDataHeader=... rewrites=... uploadProvider=...`

That tells us whether the actual Go Online request has its version in a header/device-data header or whether the request is carrying it in Cronet's upload body.
