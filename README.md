# UberDriverApp Bypass iOS 16

Rootless compatibility candidate **0.5.0** for Uber Driver **4.527.10000** on **iOS 16.2+**.

## Why v0.5.0 is different

The current blocker has narrowed to:

**“Update your app to receive trip requests”**

The older app ships **Cronet.framework**, and static inspection shows it exports the native C request API used to build request headers:

- `Cronet_UrlRequestParams_request_headers_add`
- `Cronet_HttpHeader_name_get`
- `Cronet_HttpHeader_value_get`
- `Cronet_HttpHeader_value_set`

Previous builds mainly covered Foundation request paths such as `NSURLSession` / `NSMutableURLRequest`. A native Cronet request can bypass those hooks completely.

## v0.5.0 changes

- Hooks Cronet's **native C request-header boundary**.
- Forces these Uber application-version headers to **4.584.10000** immediately before Cronet adds them to the native request:
  - `x-uber-client-version`
  - `x-uber-als-app-version`
  - `x-uber-app-version`
  - related Uber build/client-version keys
- Broadens the existing Foundation rewrite so an old version embedded in a formatted header is replaced rather than requiring an exact-value match.
- Keeps the working iOS **17.0 / 21A329** identity.
- Keeps **UBContinuousVersion 326106.1** and the newer **UBBuildUUID**.
- Keeps the targeted DriverChecks force-upgrade filtering from v0.4.0.
- Does not remove document, identity, vehicle or safety Required Actions.

## Test

Install **v0.5.0**, respring, fully kill Uber Driver, reopen it and press **Go Online**.

In `Documents/UberDriverBypass.log`, the most useful new lines are:

- `native Cronet request-header hook installed`
- `native Cronet app-version header forced to 4.584.10000`
- `native Cronet app-version header already 4.584.10000`

If the same blocker remains, that log tells us whether the live Go Online request actually passes through Cronet and whether the server was sent the newer app version at the final native boundary.
