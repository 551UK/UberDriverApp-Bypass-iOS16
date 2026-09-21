# UberDriverApp Bypass iOS 16

Rootless compatibility candidate **0.4.0** for Uber Driver **4.527.10000** on **iOS 16.2+** (Dopamine).

## Why this build is different

The latest test changed from:

- **“Update your device's iOS version”**

to:

- **“Update your app to receive trip requests”**

That is useful evidence: the iOS-version side of the Go Online compatibility check is now being accepted, while the remaining blocker is specifically the **app version**.

## v0.4.0 changes

- Keeps the iOS 17.0 / 21A329 identity used by the working part of the previous build.
- Presents app version **4.584.10000**, continuous version **326106.1**, and the newer **UBBuildUUID**.
- Adds exact hooks for the old app's generated `RealtimeDriver.DriverChecksErrorData` model:
  - `issues`
  - `futureBlockers`
- Filters only issue objects whose type/subtype identifies **FORCE_UPGRADE / FORCE_APP_UPGRADE / APP_UPGRADE**.
- Leaves document, identity, vehicle, safety and unrelated Required Actions untouched.
- Keeps the decoded JSON blocker filtering and request metadata rewriting from the earlier builds.
- Does **not** use the unsafe runtime method scan that caused the v0.3.0 launch crash.

## Why the DriverChecks hook matters

The supplied 4.527.10000 binary contains all of these in the actual Go Online path:

- `drivers/v2/go-online`
- `drivers/v2/fetch-online-blockers`
- `DriverGoOnlineV2Request`
- `DriverChecksErrorData.issues`
- `DriverChecksErrorData.futureBlockers`
- `ForceUpgradeOnlineBlockerPluginFactory`
- `ForceUpgradeBlockerAdapter`
- `FORCE_UPGRADE` / `FORCE_APP_UPGRADE`

The previous Foundation JSON filter can miss this because Uber's realtime path uses generated Swift/Thrift models. v0.4.0 now targets the generated issue model after it has been decoded.

## Test

Install **v0.4.0**, respring, fully kill Uber Driver, reopen it, then press **Go Online**.

Useful lines in `Documents/UberDriverBypass.log` include:

- `DriverChecks exact hooks installed issues=1 futureBlockers=1`
- `DriverChecksErrorData.issues removed force-app-upgrade issue objects: 1`
- `DriverChecksErrorData.futureBlockers removed force-app-upgrade issue objects: 1`

If the app-version Required Action still remains and the exact-hook line shows `issues=0 futureBlockers=0`, then those Swift accessors are not Objective-C-visible in this build and the next patch needs to target the generated realtime/Thrift decode path itself.

## IPA comparison

| Field | Old app | Comparison app |
|---|---|---|
| App version | 4.527.10000 | 4.584.10000 |
| Minimum iOS | 16.2 | 17.0 |
| UBContinuousVersion | 273504.1 | 326106.1 |
| UBBuildUUID | 5ec85290-717e-11f0-b4e0-ad464ed114c6 | 7a058960-ab07-11f1-8af6-ebef13f4ae76 |

Target: `com.ubercab.UberPartner`, process `Carbon`; arm64 + arm64e rootless.
