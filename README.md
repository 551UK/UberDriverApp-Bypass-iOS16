# UberDriverApp Bypass iOS 16

Rootless compatibility candidate **0.3.1** for Uber Driver **4.527.10000** on **iOS 16.2+** (Dopamine).

## What changed in 0.3.1

The force-update shown in testing is specifically a **Go Online / Required Actions blocker**, not an app-launch update screen. This build therefore targets the online-blocker path instead of treating it as a startup version check.

Static comparison of the supplied 4.527.10000 and 4.584.10000 IPAs shows the older binary contains:

- `drivers/v2/fetch-online-blockers`
- `DriverGoOnlineV2Request` / `DriverGoOnlineV2Response`
- `DriverChecksErrorData.issues` and `futureBlockers`
- `ForceUpgradeOnlineBlockerPluginFactory`
- `ForceUpgradeBlockerAdapter`
- `FORCE_UPGRADE` / `FORCE_APP_UPGRADE`
- `DriverRequestError1Exception` fields `minVersionUrl` and `storeUrl`

That matches the UI appearing only when the driver attempts to go online.

### New targeted behavior

- Filters only decoded **force-upgrade online blocker** entries from blocker/issue arrays.
- Recognizes `FORCE_UPGRADE`, `FORCE_APP_UPGRADE`, `APP_UPGRADE` and the old go-online version-error shape containing both `minVersionUrl` and `storeUrl`.
- Preserves document, identity, vehicle, safety and other Required Actions.
- Disables explicit `forceAppUpgrade` / `forceUpgrade` booleans when present in decoded online-blocker data.
- Keeps the existing iOS/app-version compatibility metadata rewrite as a fallback for the actual Go Online request.

## Test

Install **v0.3.1**, respring, fully kill Uber Driver, reopen it and press **Go Online**.

The log is at:

`Documents/UberDriverBypass.log`

inside Uber Driver's data container. It is capped and contains only hook/rewrite status. Useful v0.3.0 lines include:

- `go-online force-upgrade blocker entries removed...`
- `ForceUpgrade... applicability hooks: ...`
- `Uber NSURLSession request updated`

If the same blocker remains and none of the decoded-response lines appear, the live path is likely Uber's protobuf/gRPC/Cronet path rather than Foundation JSON. That would narrow the next patch to the generated `DriverGoOnlineV2Request.deviceData` / blocker response model instead of adding more generic spoofing.

## IPA comparison

| Field | Old app | Comparison app |
|---|---|---|
| App version | 4.527.10000 | 4.584.10000 |
| Minimum iOS | 16.2 | 17.0 |
| UBContinuousVersion | 273504.1 | 326106.1 |

Target: `com.ubercab.UberPartner`, process `Carbon`; arm64 + arm64e rootless.

## 0.3.1 launch-crash fix

v0.3.0 added a runtime scan that replaced Objective-C method implementations on Uber's force-upgrade classes. On the test device Uber Driver then opened and immediately closed. v0.3.1 removes that unsafe runtime method patch entirely. The targeted decoded blocker filtering and request metadata rewrites remain.
