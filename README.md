# UberDriverApp Bypass iOS 16

Rootless diagnostic candidate **0.10.0** for Uber Driver **4.527.10000** on **iOS 16.2+**.

## What the v0.9.0 log proved

v0.9.0 loads and installs the native Cronet request, upload-body and response hooks, but the test log contains no targeted Go Online request/response event.

It also still reports:

`DriverChecks exact hooks installed issues=0 futureBlockers=0`

`local ForceUpgrade BOOL decision hooks installed=0`

So the next useful step is identifying the exact request path and whether the two ForceUpgrade classes inherit any Objective-C-visible decision methods.

## v0.10.0 diagnostics

v0.10.0 keeps the existing compatibility behavior unchanged and adds two narrow diagnostics:

- Cronet final requests log only the **host and path**. Query strings are not logged.
- The exact ForceUpgrade classes log their superclass chain and only inherited selectors whose names look like applicability/eligibility/blocking decisions.

## Test

Install **v0.10.0**, respring, fully kill Uber Driver, reopen it, then press **Go Online once**.

Send:

`Documents/UberDriverBypass.log`

The useful new lines begin with:

`Cronet request host=`

and

`hierarchy depth=` / `inherited-candidate`
