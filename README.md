# UberDriverApp Bypass iOS 16

Rootless diagnostic candidate **0.11.0** for Uber Driver **4.527.10000** on **iOS 16.2+**.

## What v0.10.0 proved

The exact ForceUpgrade factory and adapter are Swift-native from the Objective-C runtime's perspective. Their own method lists are empty, the Presidio generic factory superclass layers are also empty, and the first superclass with Objective-C methods is only `_SwiftObject`.

The v0.10.0 test also produced no `Cronet request host=` lines.

## v0.11.0

v0.11.0 leaves the existing compatibility behavior in place and adds targeted Foundation networking diagnostics.

For Uber NSURLSession requests it logs only:

- host
- path

For the known `drivers/v2/go-online` and `drivers/v2/fetch-online-blockers` completion path it additionally logs:

- response byte count
- MIME type
- whether an NSError was present
- whether readable response text contains an explicit `ForceUpgrade`, `minVersionUrl`, or `storeUrl` marker

It does not log query strings, headers, authentication data, or response contents.

## Test

Install **v0.11.0**, respring, fully kill Uber Driver, reopen it and press **Go Online once**.

Then send:

`Documents/UberDriverBypass.log`

Useful new lines begin with:

`Foundation request host=`

or

`go-online Foundation response`
