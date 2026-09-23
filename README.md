# UberDriverApp Bypass iOS 16

Rootless compatibility candidate **0.16.0** for Uber Driver **4.527.10000** on **iOS 16.2+**.

## What v0.15.0 proved

The live `/rt/drivers/v2/go-online` request receives **HTTP 423 Locked** from Uber's server.

v0.14/v0.15 remove the ForceUpgrade issue from the JSON shown to the old app, which removes the red update warning, but that does not make the server accept the online transition.

## v0.16.0

v0.16.0 keeps the working ForceUpgrade response filter but moves the compatibility work to the outgoing app identity.

It expands app-version rewriting to include:

- `source_app_version`
- `providerAppVersion`
- `originAppVersion`
- `app_version_string`

alongside the existing app/client-version fields.

The Go Online log also records only app-version-related request fields at the final Foundation boundary.

It does not fake a successful HTTP status or local online state.

## Test

Install **v0.16.0**, respring, fully kill Uber Driver, reopen it and press **Go Online once**.

Then send:

`Documents/UberDriverBypass.log`
