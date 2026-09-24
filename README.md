# UberDriverApp Bypass iOS 16

Rootless test build **0.19.0** for Uber Driver **4.527.10000** on **iOS 16.2+**.

## What v0.18.0 proved

The outgoing **Go Online** request already carries the spoofed compatibility identity:

- iOS 18.0
- OS build 22A3354
- client version 4.584.10000
- request deviceData version 4.584.10000
- sourceApp carbon

Uber still returns **HTTP 423** with the ForceUpgrade issue.

The same request also contains two remaining build/environment fields immediately before the rejection:

- versionChecksum
- envChecksum

## v0.19.0

v0.19.0 keeps the existing version/OS spoof and ForceUpgrade UI filtering.

For **Go Online requests only**, it removes:

- `request.deviceData.versionChecksum`
- `request.deviceData.envChecksum`

No replacement checksum values are guessed or forged. This build is intended to test whether those old-build fingerprints are what the backend is still using to identify the unsupported client.

## Test

Install **v0.19.0**, respring, fully kill Uber Driver, reopen it and press **Go Online once**, then send:

`Documents/UberDriverBypass.log`
