# UberDriverApp Bypass iOS 16

Rootless compatibility candidate **0.2.0** for Uber Driver **4.527.10000** on **iOS 16.2+** (Dopamine).

## Why v0.1.0 was insufficient

The user reported the same iOS 17 blocker. The previous build changed bundle/OS strings, individual HTTP headers and mutable Objective-C dictionary setters. That did not cover immutable dictionaries, nested serialized JSON, bulk HTTP headers or already-encoded request bodies. It also missed `deviceOSVersion` and the plain `version` key.

Both supplied Carbon binaries contain `deviceOS`, `deviceOSVersion` and the `goOnline(context:driverUUID:latitude:longitude:epoch:language:device:deviceId:deviceIds:deviceModel:deviceOS:deviceSerialNumber:version:...)` signature. The old binary also references JSON serialization, request body setters, NSURLSession and Cronet. These establish metadata/transport paths to cover; they do not prove which path the live server rejection uses.

## Changes in 0.2.0

- Rewrites known compatibility fields when JSON is serialized, including nested immutable/Swift-bridged collections.
- Checks uncompressed JSON bodies on Uber-domain URL requests, including data-task and in-memory upload-task entry points.
- Covers bulk header assignment and HTTP body assignment before transport.
- Adds `deviceOSVersion` and exact old-app `version` handling; preserves platform-only `iOS` strings and numeric JSON types.
- Removes process-wide mutable dictionary setter hooks.
- Retains the existing version identity: iOS 17.0 / 21A329, app 4.584.10000, continuous version 326106.1.
- Does not alter server responses, account status, documents, trip results or online-blocker lists.

## Install and test

Install the DEB from Releases over the old package, respring, then fully close and reopen Uber Driver. If using Choicy, allow UberDriverBypass for Uber Driver.

This is a build-validated candidate, **not yet confirmed to pass Uber's live compatibility check**. If the iOS message remains, send `Documents/UberDriverBypass.log` from the Uber Driver data container (Filza → Apps Manager → Uber Driver → data container). The log resets at launch, is capped at 80 lines and contains only injection/rewrite status and counts. It excludes URLs, account/device identifiers, credentials, location and request/response contents. No log indicates injection or file-write failure; do not assume a server issue from that alone.

Binary/protobuf, streamed, file-backed and compressed request bodies are not decoded. Server-side cached device state or other transport paths may require further diagnosis. The separate documents warning must be resolved normally.

## IPA comparison

| Field | Old app | Comparison app |
|---|---|---|
| App version | 4.527.10000 | 4.584.10000 |
| Minimum iOS | 16.2 | 17.0 |
| UBContinuousVersion | 273504.1 | 326106.1 |

Target: `com.ubercab.UberPartner`, process `Carbon`; arm64 + arm64e rootless.
