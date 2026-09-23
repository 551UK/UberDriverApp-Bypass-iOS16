# UberDriverApp Bypass iOS 16

Rootless diagnostic candidate **0.18.0** for Uber Driver **4.527.10000** on **iOS 16.2+**.

## What v0.17.0 proved

The outgoing Go Online request already carries the expected ordinary compatibility identity:

- iOS 18.0
- OS build 22A3354
- client version 4.584.10000
- request deviceData version 4.584.10000

The server still returns HTTP 423 with the ForceUpgrade issue.

## v0.18.0

v0.18.0 keeps the existing ForceUpgrade UI filter and adds read-only diagnostics for remaining non-sensitive compatibility fields.

It logs values for fields such as:

- sourceApp
- specVersion
- appVariant
- buildUuid / buildType
- commitHash
- OS/version fields
- x-uber-client-name / x-uber-client-id

For versionChecksum and envChecksum it logs only the field type, length and whether the format looks UUID/hex/other. It does not modify those fields.

## Test

Install **v0.18.0**, respring, fully kill Uber Driver, reopen it and press **Go Online once**, then send:

`Documents/UberDriverBypass.log`
