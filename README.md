# UberDriverApp Bypass iOS 16

Rootless compatibility tweak for **Uber Driver 4.527.10000** on **iOS 16.2+**.

The comparison target is **Uber Driver 4.584.10000**. That newer IPA has a minimum OS of **iOS 17.0**, while 4.527.10000 still launches on iOS 16.

## What this build does

- Presents iOS **17.0** and build **21A329** to Uber's OS-version checks and device metadata.
- Presents Uber Driver **4.584.10000** to version checks that read the main bundle or Uber version headers.
- Presents Uber continuous version **326106.1** where that version is queried.
- Rewrites Uber-specific request/header keys such as `x-uber-als-device-os-version`, `x-uber-device-os-build`, `x-uber-client-version`, `device_os_version`, `os_version`, `app_version` and their camel-case equivalents.
- Does **not** disable the Required Actions system or hide document/account blockers. The aim is to remove only the obsolete OS/app-version identity that causes the compatibility blocker.

## IPA comparison used

- Older iOS 16 build: **4.527.10000**, `MinimumOSVersion = 16.2`, continuous version **273504.1**.
- New comparison build: **4.584.10000**, `MinimumOSVersion = 17.0`, continuous version **326106.1**.
- Both binaries contain Uber device/app-version telemetry keys and the Driver online-blocker framework.
- The exact “Update your device's iOS version / You need iOS 17.0 or higher to receive trip requests” copy is not stored in either IPA's English localization resources, which is consistent with that blocker being delivered/configured by Uber's backend rather than being a simple local alert.

## Package

- Dopamine/rootless
- iOS 16.2+
- arm64 + arm64e
- Target bundle: `com.ubercab.UberPartner`
- Target process: `Carbon`

This cannot add code or APIs that only exist in 4.584.10000. If Uber changes the server protocol in a way that the older client cannot understand, that requires a separate compatibility patch rather than another version string.
