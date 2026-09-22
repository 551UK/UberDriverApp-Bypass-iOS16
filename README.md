# UberDriverApp Bypass iOS 16

Rootless compatibility candidate **0.9.0** for Uber Driver **4.527.10000** on **iOS 16.2+**.

## What the v0.8.0 log proved

The tweak loads and the native Cronet request/upload hooks install, but the exact Objective-C-visible local blocker hooks report:

`DriverChecks exact hooks installed issues=0 futureBlockers=0`

`local ForceUpgrade BOOL decision hooks installed=0`

That means the remaining **Update your app to receive requests** Go Online blocker is not exposed through those Objective-C selectors.

## v0.9.0 change

v0.9.0 adds a targeted native Cronet **response** hook for only:

- `drivers/v2/go-online`
- `drivers/v2/fetch-online-blockers`

If a returned Cronet chunk is complete JSON, the tweak removes only explicit ForceUpgrade blocker entries and force-upgrade boolean gates. It then pads the shortened JSON with trailing whitespace so the original Cronet byte count is unchanged.

If the response is protobuf, compressed, split across chunks, or otherwise not JSON, v0.9.0 does **not** corrupt or replace it. It only records a diagnostic when recognizable `ForceUpgrade`, `minVersionUrl`, or `storeUrl` text appears.

Existing iOS 18 identity, request/header, upload-body, JSON and local blocker hooks remain enabled.

## Test

Install **v0.9.0**, respring, fully kill Uber Driver, reopen it, and attempt **Go Online**.

If the blocker remains, send:

`Documents/UberDriverBypass.log`

Useful new log lines start with:

`Cronet go-online response ...`

or

`Cronet fetch-online-blockers response ...`
