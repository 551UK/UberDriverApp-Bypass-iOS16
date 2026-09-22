# UberDriverApp Bypass iOS 16

Rootless compatibility candidate **0.12.0** for Uber Driver **4.527.10000** on **iOS 16.2+**.

## What v0.11.0 proved

The remaining update gate is now on a confirmed network path:

- `/rt/drivers/v2/go-online`
- Foundation / `NSURLSession`
- response size: **488 bytes**
- MIME type: **application/json**
- no transport error
- response contains an explicit ForceUpgrade / minimum-version / store-URL marker

So the Go Online request is not using the native Cronet path targeted by the earlier builds.

## v0.12.0

v0.12.0 runs the existing narrow ForceUpgrade JSON filter directly on the completed Foundation response **before the original Uber completion handler receives it**.

It removes only:

- explicit ForceUpgrade blocker objects already recognized by the tweak
- explicit force-upgrade boolean gates

Other required actions are left unchanged.

If the response contains a ForceUpgrade-shaped JSON structure the current filter does not yet recognize, the tweak logs only suspicious JSON **paths and value types**. It does not log response values, tokens or authentication data.

## Test

Install **v0.12.0**, respring, fully kill Uber Driver, reopen it and press **Go Online once**.

If it still shows the update requirement, send:

`Documents/UberDriverBypass.log`

The key new lines are:

`go-online Foundation response force-upgrade entries removed=`

or

`go-online suspicious JSON path=`
