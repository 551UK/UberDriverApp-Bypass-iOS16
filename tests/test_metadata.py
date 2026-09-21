"""Run the metadata transformation with macOS Foundation before packaging."""
from pathlib import Path
import subprocess
import tempfile

source = (Path(__file__).resolve().parents[1] / "Tweak.xm").read_text()
constants = source[
    source.index("static NSString * const UBTargetOSVersion"):
    source.index("static BOOL UBIsMainBundle")
]
functions = source[
    source.index("static NSString *UBNormalizedKey"):
    source.index("static BOOL UBIsUberURL")
]

harness = r"""
static void check(BOOL ok, NSString *name) {
    if (!ok) {
        NSLog(@"FAIL: %@", name);
        exit(1);
    }
}

int main(void) {
    @autoreleasepool {
        UBActualOSVersion = @"16.2";

        NSDictionary *documents = @{
            @"required": @YES,
            @"status": @"blocked",
            @"reason": @"documents",
            @"version": @"2"
        };

        NSDictionary *input = @{
            @"payload": @[@{
                @"deviceOSVersion": @"16.2",
                @"deviceOS": @"iOS 16.2",
                @"version": @"4.527.10000",
                @"osMajorVersion": @16
            }],
            @"documents": documents,
            @"token": @"secret-placeholder"
        };

        NSUInteger changes = 0;
        NSDictionary *output = UBRewriteJSON(input, 0, &changes);
        NSDictionary *payload = output[@"payload"][0];

        check(changes == 4, @"immutable nested request changes all four metadata values");
        check([payload[@"deviceOSVersion"] isEqual:@"17.0"], @"deviceOSVersion");
        check([payload[@"deviceOS"] isEqual:@"iOS 17.0"], @"deviceOS prefix");
        check([payload[@"version"] isEqual:@"4.584.10000"], @"plain app version");
        check([payload[@"osMajorVersion"] isEqual:@17], @"numeric type retained");
        check(output[@"documents"] == documents, @"documents object unchanged");
        check([output[@"token"] isEqual:input[@"token"]], @"unrelated fields unchanged");
        check([input[@"payload"][0][@"deviceOSVersion"] isEqual:@"16.2"], @"input not mutated");

        changes = 0;
        check([UBRewriteJSON(output, 0, &changes) isEqual:output] && changes == 0, @"idempotent");
        check([UBRewriteValueForKey(@"iOS", @"deviceOS") isEqual:@"iOS"], @"platform-only value retained");
        check([UBRewriteValueForKey(@"16.2", @"x-uber-als-device-os-version") isEqual:@"17.0"], @"Uber OS header");
        check([UBRewriteValueForKey(@"4.527.10000", @"unrelated") isEqual:@"4.527.10000"], @"unrelated string");
        check(UBRewriteValueForKey(NSNull.null, @"deviceOSVersion") == NSNull.null, @"null preserved");

        NSDictionary *onlineBlockers = @{
            @"issues": @[
                @{@"typeString": @"FORCE_UPGRADE", @"minVersionUrl": @"x", @"storeUrl": @"y"},
                @{@"typeString": @"DOCUMENTS", @"title": @"Documents"}
            ],
            @"forceAppUpgrade": @YES
        };
        NSUInteger removed = 0;
        NSDictionary *filteredBlockers = UBFilterForceUpgradeOnlineBlockers(onlineBlockers, 0, &removed);
        check(removed == 2, @"force upgrade blocker and boolean removed");
        check([filteredBlockers[@"issues"] count] == 1, @"only one blocker remains");
        check([filteredBlockers[@"issues"][0][@"typeString"] isEqual:@"DOCUMENTS"], @"document blocker preserved");
        check([filteredBlockers[@"forceAppUpgrade"] isEqual:@NO], @"forceAppUpgrade disabled");

        NSString *deviceHeader =
            @"{\\\"device_os_version\\\":\\\"16.2\\\",\\\"app_version\\\":\\\"4.527.10000\\\"}";
        NSString *rewrittenHeader = UBRewriteValueForKey(deviceHeader, @"x-uber-device-data");
        check([rewrittenHeader containsString:@"17.0"], @"x-uber-device-data OS rewrite");
        check([rewrittenHeader containsString:@"4.584.10000"], @"x-uber-device-data app rewrite");

        NSData *opaque =
            [@"xx16.2yy4.527.10000zz273504.1" dataUsingEncoding:NSUTF8StringEncoding];
        NSData *opaqueOut = UBRewriteOpaqueDeviceIdentityData(opaque);
        NSString *opaqueString =
            [[NSString alloc] initWithData:opaqueOut encoding:NSUTF8StringEncoding];

        check([opaqueString containsString:@"17.0"], @"opaque device payload OS rewrite");
        check([opaqueString containsString:@"4.584.10000"], @"opaque device payload app rewrite");
        check([opaqueString containsString:@"326106.1"], @"opaque continuous version rewrite");

        NSLog(@"Metadata regression tests passed");
    }
    return 0;
}
"""

with tempfile.TemporaryDirectory() as temp:
    src = Path(temp) / "metadata.m"
    binary = Path(temp) / "metadata"
    src.write_text(
        "#import <Foundation/Foundation.h>\n"
        "#include <string.h>\n"
        "static void UBDiagnostic(NSString *event) { (void)event; }\n"
        + constants
        + functions
        + harness
    )
    subprocess.run(
        ["xcrun", "clang", "-fobjc-arc", "-framework", "Foundation", str(src), "-o", str(binary)],
        check=True,
    )
    subprocess.run([str(binary)], check=True)
