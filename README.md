# UberDriverApp Bypass iOS 16

Rootless compatibility candidate **0.13.0** for Uber Driver **4.527.10000** on **iOS 16.2+**.

## What v0.12.0 proved

The real Go Online response is Foundation/NSURLSession JSON from:

`/rt/drivers/v2/go-online`

v0.12.0 found the exact ForceUpgrade marker at:

`$.data.issues[0].data.subtypeString`

The old filter did not remove it because it only recognized type/subtype fields on the issue dictionary itself.

## v0.13.0

v0.13.0 makes one targeted matcher change.

If an issue dictionary contains a nested `data` dictionary, it checks only:

- `typeString`
- `subtypeString`
- `issueType`
- `type`
- `subtype`

If one of those nested values is an explicit ForceUpgrade marker, the existing Foundation response filter removes that parent issue before Uber receives the JSON.

Other issue entries and required actions remain untouched.

## Test

Install **v0.13.0**, respring, fully kill Uber Driver, reopen it and press **Go Online once**.

If it still shows the update requirement, send:

`Documents/UberDriverBypass.log`

A successful match should produce:

`go-online Foundation response force-upgrade entries removed=`
