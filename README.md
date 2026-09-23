# UberDriverApp Bypass iOS 16

Rootless diagnostic candidate **0.15.0** for Uber Driver **4.527.10000** on **iOS 16.2+**.

## What v0.14.0 proved

v0.14.0 successfully removes the ForceUpgrade issue from the live `/rt/drivers/v2/go-online` response, so the red update warning disappears.

The driver still does not transition online. The next diagnostic question is what state the remaining filtered response represents.

## v0.15.0

v0.15.0 keeps the v0.14 ForceUpgrade filter and adds:

- HTTP status for the Go Online response
- the top-level JSON keys delivered to the old app
- the keys inside the response `data` object

It does not log response values, authentication headers, tokens, IDs, coordinates or query strings.

## Test

Install **v0.15.0**, respring, fully kill Uber Driver, reopen it and press **Go Online once**.

Then send:

`Documents/UberDriverBypass.log`
