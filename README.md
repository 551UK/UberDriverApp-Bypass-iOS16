# UberDriverApp Bypass iOS 16

Rootless compatibility candidate **0.7.0** for Uber Driver **4.527.10000** on **iOS 16.2+**.

## What the v0.6.1 log proved

The tweak loaded with the iOS 18 spoof and the native Cronet final-request hooks installed, but there were **no Go Online/fetch-online-blockers request diagnostics**. The exact Swift DriverChecks hooks also reported `issues=0 futureBlockers=0`.

That means repeatedly changing Foundation headers or the visible iOS version is not addressing the remaining app-version blocker.

## v0.7.0 change

The old app bundles Chromium **Cronet 100.0.4863.0**. Its native upload API supplies request bodies through `Cronet_UploadDataProvider` into a `Cronet_Buffer`, then calls `Cronet_UploadDataSink_OnReadSucceeded`.

v0.7.0 hooks that upload-provider path. For each completed upload chunk it performs only **equal-length** substitutions before Cronet sends the bytes:

- `4.527.10000` → `4.584.10000`
- `273504.1` → `326106.1`
- iOS 16.x strings → the existing **iOS 18.0** identity where the byte lengths match

Equal-length replacement is intentional so serialized protobuf/Thrift field lengths are not changed.

The existing iOS 18 spoof, bundle/request identity hooks, Cronet header hooks and force-upgrade JSON filtering remain.

## Test

Install **v0.7.0**, respring, fully kill Uber Driver, reopen it and attempt **Go Online**.

Then send `Documents/UberDriverBypass.log`.

The key new line is:

`Cronet upload body compatibility bytes rewritten bytes=... final=...`

If that appears, we know the old app identity was found inside a native Cronet upload body and changed immediately before transmission.
