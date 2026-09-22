# UberDriverApp Bypass iOS 16

Rootless compatibility candidate **0.14.0** for Uber Driver **4.527.10000** on **iOS 16.2+**.

## What v0.13.0 proved

The live Go Online response still reaches:

`$.data.issues[0].data.subtypeString`

but v0.13.0 reports that the parent issue is not removable.

That means the nested subtype is a longer ForceUpgrade/min-version style identifier rather than one of the short exact marker strings previously accepted.

## v0.14.0

v0.14.0 keeps the filter scoped to the already-confirmed nested `issue.data` object.

Within only these fields:

- `typeString`
- `subtypeString`
- `issueType`
- `type`
- `subtype`

the matcher now accepts either the existing exact ForceUpgrade marker or a normalized value containing:

- `forceupgrade`
- `forceappupgrade`
- `minversion`

The parent issue is then removed before Uber receives the Go Online JSON.

Other issue entries and required actions remain unchanged.

A regression test covers the nested live-response shape.

## Test

Install **v0.14.0**, respring, fully kill Uber Driver, reopen it and press **Go Online once**.

A successful match should log:

`go-online Foundation response force-upgrade entries removed=`

If the update requirement still appears, send:

`Documents/UberDriverBypass.log`
