#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CoreFoundation/CoreFoundation.h>
#import <objc/runtime.h>
#import <objc/message.h>
#import <substrate.h>
#import <sys/sysctl.h>
#import <errno.h>
#import <string.h>
#import <stdlib.h>
#import <dlfcn.h>
#import <strings.h>

static NSString * const UBTargetOSVersion = @"18.0";
static NSString * const UBTargetOSLongVersion = @"18.0.0";
static NSString * const UBTargetOSMajor = @"18";
static NSString * const UBTargetOSBuild = @"22A3354";
static NSString * const UBOldAppVersion = @"4.527.10000";
static NSString * const UBTargetAppVersion = @"4.584.10000";
static NSString * const UBOldContinuousVersion = @"273504.1";
static NSString * const UBTargetContinuousVersion = @"326106.1";
static NSString * const UBTargetBuildUUID = @"7a058960-ab07-11f1-8af6-ebef13f4ae76";
static NSString *UBActualOSVersion = nil;
static __thread BOOL UBSkipJSONHooks = NO;

static BOOL UBIsMainBundle(NSBundle *bundle) {
    return bundle && bundle == NSBundle.mainBundle;
}

// Compatibility metadata is changed and only explicit force-upgrade online blockers
// are filtered. Account, document and unrelated Required Actions remain untouched.
static void UBDiagnostic(NSString *event) {
    static NSUInteger count = 0;
    @synchronized (UBTargetAppVersion) {
        if (count++ >= 200) return;
        NSString *path = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/UberDriverBypass.log"];
        NSString *line = [NSString stringWithFormat:@"%@ %@\n", NSDate.date, event];
        NSFileHandle *file = [NSFileHandle fileHandleForWritingAtPath:path];
        if (!file) { [line writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:nil]; return; }
        @try { [file seekToEndOfFile]; [file writeData:[line dataUsingEncoding:NSUTF8StringEncoding]]; }
        @catch (NSException *exception) { (void)exception; }
        @finally { [file closeFile]; }
    }
}

static NSString *UBNormalizedKey(NSString *key) {
    return [[key.lowercaseString stringByReplacingOccurrencesOfString:@"_" withString:@""]
            stringByReplacingOccurrencesOfString:@"-" withString:@""];
}

static NSString *UBTargetVersionForEqualLength(NSString *actual) {
    if (![actual isKindOfClass:NSString.class]) return nil;
    if (actual.length == UBTargetOSVersion.length) return UBTargetOSVersion;
    if (actual.length == UBTargetOSLongVersion.length) return UBTargetOSLongVersion;
    return nil;
}

static NSData *UBReplaceEqualLengthBytes(NSData *input, NSString *from, NSString *to) {
    if (!input.length || !from.length || !to.length) return input;
    NSData *needle = [from dataUsingEncoding:NSUTF8StringEncoding];
    NSData *replacement = [to dataUsingEncoding:NSUTF8StringEncoding];
    if (!needle.length || needle.length != replacement.length || needle.length > input.length) return input;

    NSMutableData *out = [input mutableCopy];
    uint8_t *bytes = (uint8_t *)out.mutableBytes;
    const uint8_t *findBytes = (const uint8_t *)needle.bytes;
    const uint8_t *replaceBytes = (const uint8_t *)replacement.bytes;
    NSUInteger total = out.length;
    NSUInteger n = needle.length;

    for (NSUInteger i = 0; i + n <= total; ) {
        if (memcmp(bytes + i, findBytes, n) == 0) {
            memcpy(bytes + i, replaceBytes, n);
            i += n;
        } else {
            i++;
        }
    }
    return out;
}

static NSData *UBRewriteOpaqueDeviceIdentityData(NSData *body) {
    if (!body.length) return body;

    NSData *out = body;
    out = UBReplaceEqualLengthBytes(out, UBOldAppVersion, UBTargetAppVersion);
    out = UBReplaceEqualLengthBytes(out, UBOldContinuousVersion, UBTargetContinuousVersion);

    NSString *actualTarget = UBTargetVersionForEqualLength(UBActualOSVersion);
    if (actualTarget.length) out = UBReplaceEqualLengthBytes(out, UBActualOSVersion, actualTarget);

    for (NSString *version in @[@"16.0.0", @"16.1.0", @"16.2.0", @"16.3.0", @"16.3.1", @"16.4.0", @"16.5.0", @"16.6.0", @"16.7.0"]) {
        out = UBReplaceEqualLengthBytes(out, version, UBTargetOSLongVersion);
    }
    for (NSString *version in @[@"16.0", @"16.1", @"16.2", @"16.3", @"16.4", @"16.5", @"16.6", @"16.7"]) {
        out = UBReplaceEqualLengthBytes(out, version, UBTargetOSVersion);
    }
    return out;
}

static NSString *UBRewriteDeviceDataHeader(NSString *value) {
    if (![value isKindOfClass:NSString.class] || !value.length) return value;

    NSString *out = value;
    out = [out stringByReplacingOccurrencesOfString:UBOldAppVersion withString:UBTargetAppVersion];
    out = [out stringByReplacingOccurrencesOfString:UBOldContinuousVersion withString:UBTargetContinuousVersion];

    NSString *actualTarget = UBTargetVersionForEqualLength(UBActualOSVersion);
    if (actualTarget.length) {
        out = [out stringByReplacingOccurrencesOfString:UBActualOSVersion withString:actualTarget];
    }

    for (NSString *version in @[@"16.0.0", @"16.1.0", @"16.2.0", @"16.3.0", @"16.3.1", @"16.4.0", @"16.5.0", @"16.6.0", @"16.7.0"]) {
        out = [out stringByReplacingOccurrencesOfString:version withString:UBTargetOSLongVersion];
    }
    for (NSString *version in @[@"16.0", @"16.1", @"16.2", @"16.3", @"16.4", @"16.5", @"16.6", @"16.7"]) {
        out = [out stringByReplacingOccurrencesOfString:version withString:UBTargetOSVersion];
    }
    if (![out isEqualToString:value]) {
        UBDiagnostic(@"x-uber-device-data text rewritten");
        return out;
    }

    BOOL urlSafe = [value containsString:@"-"] || [value containsString:@"_"];
    BOOL hadPadding = [value hasSuffix:@"="];
    NSString *normalized = [value stringByReplacingOccurrencesOfString:@"-" withString:@"+"];
    normalized = [normalized stringByReplacingOccurrencesOfString:@"_" withString:@"/"];
    NSUInteger remainder = normalized.length % 4;
    if (remainder) {
        normalized = [normalized stringByPaddingToLength:normalized.length + (4 - remainder)
                                              withString:@"="
                                         startingAtIndex:0];
    }

    NSData *decoded = [[NSData alloc] initWithBase64EncodedString:normalized
                                                          options:NSDataBase64DecodingIgnoreUnknownCharacters];
    if (!decoded.length) return value;
    NSData *rewritten = UBRewriteOpaqueDeviceIdentityData(decoded);
    if ([rewritten isEqualToData:decoded]) return value;

    NSString *encoded = [rewritten base64EncodedStringWithOptions:0];
    if (urlSafe) {
        encoded = [encoded stringByReplacingOccurrencesOfString:@"+" withString:@"-"];
        encoded = [encoded stringByReplacingOccurrencesOfString:@"/" withString:@"_"];
    }
    if (!hadPadding) {
        encoded = [encoded stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"="]];
    }
    UBDiagnostic(@"x-uber-device-data base64 rewritten");
    return encoded ?: value;
}

static id UBRewriteValueForKey(id value, NSString *key) {
    if (![key isKindOfClass:NSString.class]) return value;
    NSString *k = UBNormalizedKey(key);
    if ([k isEqualToString:@"xuberdevicedata"] && [value isKindOfClass:NSString.class]) {
        return UBRewriteDeviceDataHeader(value);
    }
    BOOL numeric = [value isKindOfClass:NSNumber.class];
    if (![value isKindOfClass:NSString.class] && !numeric) return value;
    NSString *v = numeric ? [value stringValue] : value;
    if ([@[@"deviceosversion", @"deviceosversionstring", @"osversion", @"osfullversion", @"iosversion",
           @"currentosversion", @"previousosversion", @"prevosversion", @"minimumosversion",
           @"appminosversion", @"apptargetosversion", @"xuberalsdeviceosversion"] containsObject:k])
        return numeric ? @18 : UBTargetOSVersion;
    if ([k isEqualToString:@"osmajorversion"]) return numeric ? @18 : UBTargetOSMajor;
    if ([@[@"xuberdeviceosbuild", @"osversionbuild", @"osbuildversion"] containsObject:k])
        return UBTargetOSBuild;
    if ([@[@"deviceos", @"xuberdeviceos", @"xuberalsdeviceos", @"backenddeviceos"] containsObject:k]) {
        NSRange digit = [v rangeOfCharacterFromSet:NSCharacterSet.decimalDigitCharacterSet];
        // Preserve platform-only strings (e.g. iOS), and the original prefix.
        if (digit.location == NSNotFound) return value;
        NSString *prefix = [v substringToIndex:digit.location];
        return numeric ? @18 : [prefix stringByAppendingString:UBTargetOSVersion];
    }
    if ([@[@"xuberclientversion", @"xuberalsappversion", @"xuberappversion",
           @"xuberbuildversion", @"xuberclientbuild", @"xuberclientbuildnumber",
           @"appversion", @"clientversion", @"version",
           @"cfbundleversion", @"cfbundleshortversionstring"] containsObject:k]) {
        if ([v containsString:UBOldAppVersion]) {
            return [v stringByReplacingOccurrencesOfString:UBOldAppVersion
                                                withString:UBTargetAppVersion];
        }
        if ([k isEqualToString:@"xuberclientversion"] ||
            [k isEqualToString:@"xuberalsappversion"] ||
            [k isEqualToString:@"xuberappversion"]) {
            // At the final network boundary these are application identity
            // headers, so use the comparison build even if an intermediate
            // layer formatted the old value differently.
            return UBTargetAppVersion;
        }
    }
    if ([@[@"ubcontinuousversion", @"continuousversion"] containsObject:k] &&
        [v isEqualToString:@"273504.1"]) return UBTargetContinuousVersion;
    return value;
}

static id UBRewriteJSON(id object, NSUInteger depth, NSUInteger *changes) {
    if (depth > 64) return object;
    if ([object isKindOfClass:NSDictionary.class]) {
        NSMutableDictionary *copy = nil;
        for (id key in object) {
            id before = object[key];
            id after = UBRewriteValueForKey(before, key);
            if (![after isEqual:before]) (*changes)++;
            after = UBRewriteJSON(after, depth + 1, changes);
            if (after != before) {
                if (!copy) copy = [object mutableCopy];
                copy[key] = after;
            }
        }
        return copy ?: object;
    }
    if ([object isKindOfClass:NSArray.class]) {
        NSMutableArray *copy = nil;
        for (NSUInteger i = 0; i < [object count]; i++) {
            id before = object[i];
            id after = UBRewriteJSON(before, depth + 1, changes);
            if (after != before) {
                if (!copy) copy = [object mutableCopy];
                copy[i] = after;
            }
        }
        return copy ?: object;
    }
    return object;
}


static NSString *UBForceUpgradeNormalizedString(id value) {
    if (![value isKindOfClass:NSString.class]) return nil;
    NSString *s = [(NSString *)value lowercaseString];
    NSCharacterSet *drop = [NSCharacterSet characterSetWithCharactersInString:@"_- .:/"];
    return [[s componentsSeparatedByCharactersInSet:drop] componentsJoinedByString:@""];
}

static BOOL UBIsForceUpgradeMarker(id value) {
    NSString *s = UBForceUpgradeNormalizedString(value);
    if (!s.length) return NO;
    return [s isEqualToString:@"forceupgrade"] ||
           [s isEqualToString:@"forceappupgrade"] ||
           [s isEqualToString:@"appupgrade"] ||
           [s isEqualToString:@"upgradeapp"] ||
           [s isEqualToString:@"minappversion"] ||
           [s isEqualToString:@"minimumappversion"];
}

static BOOL UBIsForceUpgradeBlockerDictionary(NSDictionary *dictionary) {
    if (![dictionary isKindOfClass:NSDictionary.class]) return NO;

    for (NSString *key in @[
        @"type", @"typeString", @"subtype", @"subtypeString",
        @"issueType", @"issue_type", @"category", @"blockerType",
        @"blocker_type", @"reason", @"name", @"code", @"actionType"
    ]) {
        id value = dictionary[key];
        if (UBIsForceUpgradeMarker(value)) return YES;
    }

    // The old Uber Driver binary's DriverRequestError1Exception contains
    // minVersionUrl/storeUrl for the go-online version rejection. Treat that
    // shape as the upgrade blocker, but only when both pieces are present.
    BOOL hasMinVersionURL =
        dictionary[@"minVersionUrl"] != nil ||
        dictionary[@"min_version_url"] != nil ||
        dictionary[@"minimumVersionUrl"] != nil;
    BOOL hasStoreURL =
        dictionary[@"storeUrl"] != nil ||
        dictionary[@"store_url"] != nil ||
        dictionary[@"minVersionStoreUrl"] != nil;
    if (hasMinVersionURL && hasStoreURL) return YES;

    // v0.12.0 diagnostics showed the live /rt/drivers/v2/go-online response
    // wraps the actual ForceUpgrade subtype under issue.data.subtypeString.
    // Match only that exact nested issue-data shape so unrelated issue
    // dictionaries remain untouched.
    id nestedData = dictionary[@"data"];
    if ([nestedData isKindOfClass:NSDictionary.class]) {
        NSDictionary *dataDictionary = (NSDictionary *)nestedData;
        for (NSString *key in @[@"typeString", @"subtypeString", @"issueType", @"type", @"subtype"]) {
            id value = dataDictionary[key];
            if (UBIsForceUpgradeMarker(value)) return YES;

            // The live response can use a longer Swift/backend subtype such as
            // a value containing "ForceUpgrade" rather than the exact token.
            NSString *normalized = UBForceUpgradeNormalizedString(value);
            if ([normalized containsString:@"forceupgrade"] ||
                [normalized containsString:@"forceappupgrade"] ||
                [normalized containsString:@"minversion"]) {
                return YES;
            }
        }
    }

    return NO;
}

static id UBFilterForceUpgradeOnlineBlockers(id object, NSUInteger depth, NSUInteger *removed) {
    if (!object || depth > 64) return object;

    if ([object isKindOfClass:NSArray.class]) {
        NSArray *array = (NSArray *)object;
        NSMutableArray *copy = [NSMutableArray arrayWithCapacity:array.count];
        BOOL changed = NO;

        for (id item in array) {
            if ([item isKindOfClass:NSDictionary.class] &&
                UBIsForceUpgradeBlockerDictionary((NSDictionary *)item)) {
                if (removed) (*removed)++;
                changed = YES;
                continue;
            }

            id filtered = UBFilterForceUpgradeOnlineBlockers(item, depth + 1, removed);
            [copy addObject:filtered ?: NSNull.null];
            if (filtered != item) changed = YES;
        }
        return changed ? copy : object;
    }

    if ([object isKindOfClass:NSDictionary.class]) {
        NSDictionary *dictionary = (NSDictionary *)object;
        NSMutableDictionary *copy = nil;

        for (id key in dictionary) {
            id before = dictionary[key];
            id after = UBFilterForceUpgradeOnlineBlockers(before, depth + 1, removed);
            if (after != before) {
                if (!copy) copy = [dictionary mutableCopy];
                copy[key] = after ?: NSNull.null;
            }
        }

        // Some responses expose the go-online gate as a boolean rather than
        // an item in the blocker array. Flip only explicit force-upgrade keys.
        for (NSString *key in @[@"forceAppUpgrade", @"force_app_upgrade", @"forceUpgrade", @"force_upgrade"]) {
            id value = dictionary[key];
            if ([value respondsToSelector:@selector(boolValue)] && [value boolValue]) {
                if (!copy) copy = [dictionary mutableCopy];
                copy[key] = @NO;
                if (removed) (*removed)++;
            }
        }

        return copy ?: object;
    }

    return object;
}


typedef id (*UBObjectGetterIMP)(id, SEL);
static UBObjectGetterIMP UBOrigDriverChecksIssues = NULL;
static UBObjectGetterIMP UBOrigDriverChecksFutureBlockers = NULL;

static NSString *UBSafeObjectStringGetter(id object, NSString *selectorName) {
    if (!object || !selectorName.length) return nil;
    SEL selector = NSSelectorFromString(selectorName);
    if (![object respondsToSelector:selector]) return nil;
    id value = ((id(*)(id,SEL))objc_msgSend)(object, selector);
    return [value isKindOfClass:NSString.class] ? value : nil;
}

static BOOL UBIsForceUpgradeIssueObject(id issue) {
    if (!issue) return NO;

    NSString *className = NSStringFromClass([issue class]);
    if ([className.lowercaseString containsString:@"forceupgrade"]) return YES;

    for (NSString *selectorName in @[@"typeString", @"subtypeString", @"issueType", @"type", @"subtype"]) {
        NSString *value = UBSafeObjectStringGetter(issue, selectorName);
        NSString *normalized = UBForceUpgradeNormalizedString(value);
        if ([normalized containsString:@"forceupgrade"] ||
            [normalized containsString:@"forceappupgrade"] ||
            [normalized isEqualToString:@"appupgrade"] ||
            [normalized isEqualToString:@"upgradeapp"]) {
            return YES;
        }
    }

    return NO;
}

static id UBFilterForceUpgradeIssueObjects(id value, NSString *source) {
    if (![value isKindOfClass:NSArray.class]) return value;

    NSArray *array = (NSArray *)value;
    NSMutableArray *filtered = [NSMutableArray arrayWithCapacity:array.count];
    NSUInteger removed = 0;

    for (id item in array) {
        if (UBIsForceUpgradeIssueObject(item)) {
            removed++;
            continue;
        }
        [filtered addObject:item];
    }

    if (removed) {
        UBDiagnostic([NSString stringWithFormat:@"%@ removed force-app-upgrade issue objects: %lu",
                      source, (unsigned long)removed]);
        return filtered;
    }
    return value;
}

static id UBDriverChecksIssuesHook(id self, SEL _cmd) {
    id original = UBOrigDriverChecksIssues ? UBOrigDriverChecksIssues(self, _cmd) : nil;
    return UBFilterForceUpgradeIssueObjects(original, @"DriverChecksErrorData.issues");
}

static id UBDriverChecksFutureBlockersHook(id self, SEL _cmd) {
    id original = UBOrigDriverChecksFutureBlockers ? UBOrigDriverChecksFutureBlockers(self, _cmd) : nil;
    return UBFilterForceUpgradeIssueObjects(original, @"DriverChecksErrorData.futureBlockers");
}

static BOOL UBInstallExactGetterHook(Class cls,
                                     NSString *selectorName,
                                     IMP replacement,
                                     IMP *originalOut) {
    if (!cls || !selectorName.length || !replacement || !originalOut) return NO;
    SEL selector = NSSelectorFromString(selectorName);
    Method method = class_getInstanceMethod(cls, selector);
    if (!method) return NO;

    char returnType[16] = {0};
    method_getReturnType(method, returnType, sizeof(returnType));
    if (returnType[0] != '@') return NO;

    MSHookMessageEx(cls, selector, replacement, originalOut);
    return *originalOut != NULL;
}

static void UBInstallDriverChecksModelHooks(void) {
    Class cls = objc_getClass("_TtC14RealtimeDriver21DriverChecksErrorData");
    if (!cls) {
        UBDiagnostic(@"DriverChecksErrorData class not available yet");
        return;
    }

    BOOL issues = UBInstallExactGetterHook(cls,
                                          @"issues",
                                          (IMP)UBDriverChecksIssuesHook,
                                          (IMP *)&UBOrigDriverChecksIssues);
    BOOL future = UBInstallExactGetterHook(cls,
                                          @"futureBlockers",
                                          (IMP)UBDriverChecksFutureBlockersHook,
                                          (IMP *)&UBOrigDriverChecksFutureBlockers);

    UBDiagnostic([NSString stringWithFormat:@"DriverChecks exact hooks installed issues=%d futureBlockers=%d",
                  issues, future]);
}


static BOOL UBForceUpgradeReturnNO0(id self, SEL _cmd) {
    (void)self;
    UBDiagnostic([NSString stringWithFormat:@"local ForceUpgrade decision forced NO: %@", NSStringFromSelector(_cmd)]);
    return NO;
}

static BOOL UBForceUpgradeReturnNO1(id self, SEL _cmd, id arg) {
    (void)self;
    (void)arg;
    UBDiagnostic([NSString stringWithFormat:@"local ForceUpgrade decision forced NO: %@", NSStringFromSelector(_cmd)]);
    return NO;
}

static BOOL UBForceUpgradeSelectorLooksLikeDecision(SEL selector) {
    NSString *name = NSStringFromSelector(selector).lowercaseString;
    return [name containsString:@"applic"] ||
           [name containsString:@"eligible"] ||
           [name containsString:@"enabled"] ||
           [name containsString:@"handle"] ||
           [name containsString:@"support"] ||
           [name containsString:@"should"] ||
           [name containsString:@"can"] ||
           [name containsString:@"block"] ||
           [name containsString:@"forceupgrade"];
}

static NSUInteger UBInspectAndDisableForceUpgradeMethodsOnClass(Class cls, NSString *label) {
    if (!cls) {
        UBDiagnostic([NSString stringWithFormat:@"%@ class unavailable", label]);
        return 0;
    }

    NSUInteger hooked = 0;
    unsigned int count = 0;
    Method *methods = class_copyMethodList(cls, &count);

    for (unsigned int i = 0; i < count; i++) {
        Method method = methods[i];
        SEL selector = method_getName(method);
        const char *encoding = method_getTypeEncoding(method);
        unsigned int argc = method_getNumberOfArguments(method);

        UBDiagnostic([NSString stringWithFormat:@"%@ method %@ argc=%u encoding=%s",
                      label, NSStringFromSelector(selector), argc, encoding ?: "?"]);

        if (!UBForceUpgradeSelectorLooksLikeDecision(selector) || !encoding) continue;

        char returnType[16] = {0};
        method_getReturnType(method, returnType, sizeof(returnType));
        if (returnType[0] != 'B' && returnType[0] != 'c') continue;

        IMP replacement = NULL;
        if (argc == 2) {
            replacement = (IMP)UBForceUpgradeReturnNO0;
        } else if (argc == 3) {
            char argType[16] = {0};
            method_getArgumentType(method, 2, argType, sizeof(argType));
            if (argType[0] == '@' || argType[0] == '#') {
                replacement = (IMP)UBForceUpgradeReturnNO1;
            }
        }

        if (replacement) {
            IMP original = NULL;
            MSHookMessageEx(cls, selector, replacement, &original);
            if (original) {
                hooked++;
                UBDiagnostic([NSString stringWithFormat:@"%@ hooked BOOL decision %@", label,
                              NSStringFromSelector(selector)]);
            }
        }
    }

    free(methods);
    return hooked;
}

static void UBDiagnoseForceUpgradeInheritance(Class cls, NSString *label) {
    if (!cls) return;

    NSUInteger depth = 0;
    for (Class current = cls; current && depth < 5; current = class_getSuperclass(current), depth++) {
        unsigned int count = 0;
        Method *methods = class_copyMethodList(current, &count);
        UBDiagnostic([NSString stringWithFormat:@"%@ hierarchy depth=%lu class=%@ ownMethods=%u",
                      label, (unsigned long)depth, NSStringFromClass(current), count]);

        for (unsigned int i = 0; i < count; i++) {
            Method method = methods[i];
            SEL selector = method_getName(method);
            if (!UBForceUpgradeSelectorLooksLikeDecision(selector)) continue;

            const char *encoding = method_getTypeEncoding(method);
            UBDiagnostic([NSString stringWithFormat:@"%@ inherited-candidate %@ on %@ encoding=%s",
                          label, NSStringFromSelector(selector), NSStringFromClass(current),
                          encoding ?: "?"]);
        }
        free(methods);
    }
}

static void UBInstallLocalForceUpgradeHooks(void) {
    NSArray<NSString *> *classNames = @[
        @"_TtC17DriverIntegration38ForceUpgradeOnlineBlockerPluginFactory",
        @"_TtC17DriverIntegration26ForceUpgradeBlockerAdapter"
    ];

    NSUInteger total = 0;
    for (NSString *className in classNames) {
        Class cls = objc_getClass(className.UTF8String);
        UBDiagnoseForceUpgradeInheritance(cls, className);
        total += UBInspectAndDisableForceUpgradeMethodsOnClass(cls, className);

        if (cls) {
            Class meta = object_getClass(cls);
            total += UBInspectAndDisableForceUpgradeMethodsOnClass(meta,
                [className stringByAppendingString:@" +class"]);
        }
    }

    UBDiagnostic([NSString stringWithFormat:@"local ForceUpgrade BOOL decision hooks installed=%lu",
                  (unsigned long)total]);
}

static BOOL UBIsUberURL(NSURL *url) {
    NSString *host = url.host.lowercaseString;
    return [host isEqualToString:@"uber.com"] || [host hasSuffix:@".uber.com"];
}

static BOOL UBIsGoOnlinePath(NSURL *url) {
    NSString *path = url.path.lowercaseString ?: @"";
    return [path containsString:@"drivers/v2/go-online"] ||
           [path containsString:@"drivers/v2/fetch-online-blockers"];
}

static NSString *UBTargetPathLabel(NSURL *url) {
    NSString *path = url.path.lowercaseString ?: @"";
    if ([path containsString:@"drivers/v2/go-online"]) return @"go-online";
    if ([path containsString:@"drivers/v2/fetch-online-blockers"]) return @"fetch-online-blockers";
    return nil;
}

static NSData *UBRewriteBody(NSData *body) {
    // Never decode compressed bodies, streams, protobuf or file uploads as text.
    if (!body.length || body.length > 2 * 1024 * 1024) return body;
    id json = [NSJSONSerialization JSONObjectWithData:body options:0 error:nil];
    if (!json) return body;
    NSUInteger changes = 0;
    id updated = UBRewriteJSON(json, 0, &changes);
    if (!changes) return body;
    NSData *encoded = [NSJSONSerialization dataWithJSONObject:updated options:0 error:nil];
    if (!encoded) return body;
    UBDiagnostic([NSString stringWithFormat:@"request JSON compatibility fields changed: %lu", (unsigned long)changes]);
    return encoded;
}

static NSURLRequest *UBRewriteRequest(NSURLRequest *request, BOOL rewriteBody) {
    if (!UBIsUberURL(request.URL)) return request;

    static NSUInteger foundationRequestLogCount = 0;
    if (foundationRequestLogCount < 80) {
        @synchronized (UBTargetAppVersion) {
            if (foundationRequestLogCount < 80) {
                foundationRequestLogCount++;
                UBDiagnostic([NSString stringWithFormat:@"Foundation request host=%@ path=%@",
                              request.URL.host ?: @"", request.URL.path ?: @""]);
            }
        }
    }

    NSMutableURLRequest *copy = [request mutableCopy];
    BOOL changed = NO;
    for (NSString *key in request.allHTTPHeaderFields) {
        NSString *before = request.allHTTPHeaderFields[key];
        id after = UBRewriteValueForKey(before, key);
        if (![after isEqual:before]) { [copy setValue:after forHTTPHeaderField:key]; changed = YES; }
    }
    if (rewriteBody && !request.HTTPBodyStream &&
        ![request valueForHTTPHeaderField:@"Content-Encoding"].length) {
        NSData *before = request.HTTPBody;
        NSData *after = UBRewriteBody(before);
        if (after == before && before.length) {
            after = UBRewriteOpaqueDeviceIdentityData(before);
        }
        if (after != before && ![after isEqualToData:before]) {
            copy.HTTPBody = after;
            [copy setValue:nil forHTTPHeaderField:@"Content-Length"];
            changed = YES;
            NSString *label = UBTargetPathLabel(request.URL);
            if (label.length) {
                UBDiagnostic([NSString stringWithFormat:@"%@ Foundation request body compatibility bytes rewritten", label]);
            }
        }
    }
    if (changed) {
        NSString *label = UBTargetPathLabel(request.URL);
        if (label.length) UBDiagnostic([NSString stringWithFormat:@"%@ Foundation request updated", label]);
    }
    return changed ? copy : request;
}

%hook NSJSONSerialization
+ (NSData *)dataWithJSONObject:(id)object options:(NSJSONWritingOptions)options error:(NSError **)error {
    if (UBSkipJSONHooks) return %orig(object, options, error);
    NSUInteger changes = 0;
    id updated = UBRewriteJSON(object, 0, &changes);
    return %orig(updated, options, error);
}

+ (id)JSONObjectWithData:(NSData *)data options:(NSJSONReadingOptions)options error:(NSError **)error {
    if (UBSkipJSONHooks) return %orig(data, options, error);
    id result = %orig(data, options, error);
    NSUInteger removed = 0;
    id filtered = UBFilterForceUpgradeOnlineBlockers(result, 0, &removed);
    if (removed) {
        UBDiagnostic([NSString stringWithFormat:@"go-online force-upgrade blocker entries removed from decoded response: %lu",
                      (unsigned long)removed]);
    }
    return filtered;
}

+ (id)JSONObjectWithStream:(NSInputStream *)stream options:(NSJSONReadingOptions)options error:(NSError **)error {
    if (UBSkipJSONHooks) return %orig(stream, options, error);
    id result = %orig(stream, options, error);
    NSUInteger removed = 0;
    id filtered = UBFilterForceUpgradeOnlineBlockers(result, 0, &removed);
    if (removed) {
        UBDiagnostic([NSString stringWithFormat:@"go-online force-upgrade blocker entries removed from streamed response: %lu",
                      (unsigned long)removed]);
    }
    return filtered;
}
%end

static void UBLogSuspiciousForceUpgradeJSONPaths(id object, NSString *path, NSUInteger depth, NSUInteger *count) {
    if (!object || depth > 12 || !count || *count >= 20) return;

    if ([object isKindOfClass:NSDictionary.class]) {
        NSDictionary *dictionary = (NSDictionary *)object;
        for (id keyObject in dictionary) {
            if (*count >= 20) break;
            NSString *key = [keyObject isKindOfClass:NSString.class] ? keyObject : [keyObject description];
            id value = dictionary[keyObject];
            NSString *nextPath = path.length ? [path stringByAppendingFormat:@".%@", key] : key;

            NSString *normalizedKey = UBForceUpgradeNormalizedString(key);
            BOOL suspiciousKey =
                [normalizedKey containsString:@"forceupgrade"] ||
                [normalizedKey containsString:@"minversion"] ||
                [normalizedKey containsString:@"storeurl"];

            BOOL suspiciousValue = NO;
            if ([value isKindOfClass:NSString.class]) {
                NSString *normalizedValue = UBForceUpgradeNormalizedString(value);
                suspiciousValue =
                    [normalizedValue containsString:@"forceupgrade"] ||
                    [normalizedValue containsString:@"minversion"];
            }

            if (suspiciousKey || suspiciousValue) {
                (*count)++;
                UBDiagnostic([NSString stringWithFormat:@"go-online suspicious JSON path=%@ valueType=%@",
                              nextPath, NSStringFromClass([value class])]);
            }

            UBLogSuspiciousForceUpgradeJSONPaths(value, nextPath, depth + 1, count);
        }
        return;
    }

    if ([object isKindOfClass:NSArray.class]) {
        NSArray *array = (NSArray *)object;
        NSUInteger limit = MIN(array.count, (NSUInteger)50);
        for (NSUInteger i = 0; i < limit && *count < 20; i++) {
            NSString *nextPath = [path stringByAppendingFormat:@"[%lu]", (unsigned long)i];
            UBLogSuspiciousForceUpgradeJSONPaths(array[i], nextPath, depth + 1, count);
        }
    }
}

static NSData *UBFilterFoundationGoOnlineResponseData(NSData *data, NSString *label) {
    if (!data.length || data.length > 2 * 1024 * 1024 || !label.length) return data;

    BOOL previousSkip = UBSkipJSONHooks;
    UBSkipJSONHooks = YES;

    id json = nil;
    NSData *encoded = nil;
    NSUInteger removed = 0;

    @try {
        json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        if (json) {
            id filtered = UBFilterForceUpgradeOnlineBlockers(json, 0, &removed);
            if (removed && [NSJSONSerialization isValidJSONObject:filtered]) {
                encoded = [NSJSONSerialization dataWithJSONObject:filtered options:0 error:nil];
            }
        }
    } @finally {
        UBSkipJSONHooks = previousSkip;
    }

    if (removed && encoded.length) {
        UBDiagnostic([NSString stringWithFormat:@"%@ Foundation response force-upgrade entries removed=%lu bytes=%lu->%lu",
                      label, (unsigned long)removed, (unsigned long)data.length, (unsigned long)encoded.length]);
        return encoded;
    }

    if (json) {
        NSUInteger suspicious = 0;
        UBLogSuspiciousForceUpgradeJSONPaths(json, @"$", 0, &suspicious);
        if (suspicious) {
            UBDiagnostic([NSString stringWithFormat:@"%@ Foundation response had suspicious ForceUpgrade JSON but no removable blocker count=%lu",
                          label, (unsigned long)suspicious]);
        }
    }

    return data;
}

%hook NSURLSession
- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request {
    return %orig(UBRewriteRequest(request, YES));
}
- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request completionHandler:(void (^)(NSData *, NSURLResponse *, NSError *))handler {
    NSURLRequest *updatedRequest = UBRewriteRequest(request, YES);
    BOOL uberRequest = UBIsUberURL(request.URL);
    NSString *label = UBTargetPathLabel(request.URL);
    void (^wrapped)(NSData *, NSURLResponse *, NSError *) = handler;

    if (uberRequest && handler) {
        wrapped = ^(NSData *data, NSURLResponse *response, NSError *error) {
            if (label.length) {
                NSString *mime = response.MIMEType ?: @"";
                NSInteger status = [response isKindOfClass:NSHTTPURLResponse.class]
                    ? ((NSHTTPURLResponse *)response).statusCode : 0;
                UBDiagnostic([NSString stringWithFormat:@"%@ Foundation response status=%ld bytes=%lu mime=%@ error=%d",
                              label, (long)status, (unsigned long)data.length, mime, error ? 1 : 0]);

                if (data.length && data.length <= 2 * 1024 * 1024) {
                    NSString *text = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                    NSString *lower = text.lowercaseString;
                    if ([lower containsString:@"forceupgrade"] ||
                        [lower containsString:@"force_upgrade"] ||
                        [lower containsString:@"minversionurl"] ||
                        [lower containsString:@"storeurl"]) {
                        UBDiagnostic([NSString stringWithFormat:@"%@ Foundation response contains force-upgrade text marker",
                                      label]);
                    }
                }
            }
            NSData *deliveredData = data;
            if (label.length && !error) {
                deliveredData = UBFilterFoundationGoOnlineResponseData(data, label);

                BOOL previousSkip = UBSkipJSONHooks;
                UBSkipJSONHooks = YES;
                id deliveredJSON = nil;
                @try {
                    deliveredJSON = [NSJSONSerialization JSONObjectWithData:deliveredData options:0 error:nil];
                } @finally {
                    UBSkipJSONHooks = previousSkip;
                }

                if ([deliveredJSON isKindOfClass:NSDictionary.class]) {
                    NSArray *keys = [[(NSDictionary *)deliveredJSON allKeys] sortedArrayUsingSelector:@selector(compare:)];
                    UBDiagnostic([NSString stringWithFormat:@"%@ delivered top-level keys=%@",
                                  label, [keys componentsJoinedByString:@","]]);

                    id dataObject = ((NSDictionary *)deliveredJSON)[@"data"];
                    if ([dataObject isKindOfClass:NSDictionary.class]) {
                        NSArray *dataKeys = [[(NSDictionary *)dataObject allKeys] sortedArrayUsingSelector:@selector(compare:)];
                        UBDiagnostic([NSString stringWithFormat:@"%@ delivered data keys=%@",
                                      label, [dataKeys componentsJoinedByString:@","]]);
                    }
                }
            }
            handler(deliveredData, response, error);
        };
    }

    return %orig(updatedRequest, wrapped);
}
- (NSURLSessionUploadTask *)uploadTaskWithRequest:(NSURLRequest *)request fromData:(NSData *)body {
    NSData *updated = UBIsUberURL(request.URL) && ![request valueForHTTPHeaderField:@"Content-Encoding"].length ? UBRewriteBody(body) : body;
    if (UBIsUberURL(request.URL) && updated == body && body.length) {
        updated = UBRewriteOpaqueDeviceIdentityData(body);
        if (![updated isEqualToData:body] && UBIsGoOnlinePath(request.URL)) {
            UBDiagnostic([NSString stringWithFormat:@"%@ NSURLSession upload body compatibility bytes rewritten",
                          UBTargetPathLabel(request.URL)]);
        }
    }
    NSMutableURLRequest *copy = [UBRewriteRequest(request, NO) mutableCopy];
    if (updated != body && ![updated isEqualToData:body]) [copy setValue:nil forHTTPHeaderField:@"Content-Length"];
    return %orig(copy, updated);
}
- (NSURLSessionUploadTask *)uploadTaskWithRequest:(NSURLRequest *)request fromData:(NSData *)body completionHandler:(void (^)(NSData *, NSURLResponse *, NSError *))handler {
    NSData *updated = UBIsUberURL(request.URL) && ![request valueForHTTPHeaderField:@"Content-Encoding"].length ? UBRewriteBody(body) : body;
    if (UBIsUberURL(request.URL) && updated == body && body.length) {
        updated = UBRewriteOpaqueDeviceIdentityData(body);
        if (![updated isEqualToData:body] && UBIsGoOnlinePath(request.URL)) {
            UBDiagnostic([NSString stringWithFormat:@"%@ NSURLSession upload body compatibility bytes rewritten",
                          UBTargetPathLabel(request.URL)]);
        }
    }
    NSMutableURLRequest *copy = [UBRewriteRequest(request, NO) mutableCopy];
    if (updated != body && ![updated isEqualToData:body]) [copy setValue:nil forHTTPHeaderField:@"Content-Length"];
    return %orig(copy, updated, handler);
}
%end

%hook UIDevice
- (NSString *)systemVersion {
    return UBTargetOSVersion;
}
%end

%hook NSProcessInfo
- (NSString *)operatingSystemVersionString {
    return @"Version 18.0 (Build 22A3354)";
}

- (NSOperatingSystemVersion)operatingSystemVersion {
    NSOperatingSystemVersion version;
    version.majorVersion = 18;
    version.minorVersion = 0;
    version.patchVersion = 0;
    return version;
}

- (BOOL)isOperatingSystemAtLeastVersion:(NSOperatingSystemVersion)version {
    if (version.majorVersion < 18) return YES;
    if (version.majorVersion > 18) return NO;
    if (version.minorVersion < 0) return YES;
    if (version.minorVersion > 0) return NO;
    return version.patchVersion <= 0;
}
%end

%hook NSBundle
- (id)objectForInfoDictionaryKey:(NSString *)key {
    if (UBIsMainBundle(self)) {
        if ([key isEqualToString:@"CFBundleShortVersionString"] || [key isEqualToString:@"CFBundleVersion"]) {
            return UBTargetAppVersion;
        }
        if ([key isEqualToString:@"MinimumOSVersion"]) {
            return UBTargetOSVersion;
        }
        if ([key isEqualToString:@"UBContinuousVersion"]) {
            return UBTargetContinuousVersion;
        }
        if ([key isEqualToString:@"UBBuildUUID"]) {
            return UBTargetBuildUUID;
        }
    }
    return %orig;
}

- (NSDictionary *)localizedInfoDictionary {
    NSDictionary *original = %orig;
    if (!UBIsMainBundle(self)) return original;
    NSMutableDictionary *copy = original ? [original mutableCopy] : [NSMutableDictionary dictionary];
    copy[@"CFBundleShortVersionString"] = UBTargetAppVersion;
    copy[@"CFBundleVersion"] = UBTargetAppVersion;
    copy[@"MinimumOSVersion"] = UBTargetOSVersion;
    copy[@"UBContinuousVersion"] = UBTargetContinuousVersion;
    copy[@"UBBuildUUID"] = UBTargetBuildUUID;
    return copy;
}

- (NSDictionary *)infoDictionary {
    NSDictionary *original = %orig;
    if (!UBIsMainBundle(self) || !original) return original;

    NSMutableDictionary *copy = [original mutableCopy];
    copy[@"CFBundleShortVersionString"] = UBTargetAppVersion;
    copy[@"CFBundleVersion"] = UBTargetAppVersion;
    copy[@"MinimumOSVersion"] = UBTargetOSVersion;
    copy[@"UBContinuousVersion"] = UBTargetContinuousVersion;
    copy[@"UBBuildUUID"] = UBTargetBuildUUID;
    return copy;
}
%end

%hook NSMutableURLRequest
- (void)setHTTPBody:(NSData *)body {
    NSData *updated = UBIsUberURL(self.URL) && ![self valueForHTTPHeaderField:@"Content-Encoding"].length ? UBRewriteBody(body) : body;
    if (UBIsUberURL(self.URL) && updated == body && body.length) {
        updated = UBRewriteOpaqueDeviceIdentityData(body);
    }
    if (updated != body && ![updated isEqualToData:body] && UBIsGoOnlinePath(self.URL)) {
        UBDiagnostic([NSString stringWithFormat:@"%@ NSMutableURLRequest body compatibility bytes rewritten",
                      UBTargetPathLabel(self.URL)]);
    }
    %orig(updated);
    if (updated != body && ![updated isEqualToData:body]) [self setValue:nil forHTTPHeaderField:@"Content-Length"];
}

- (void)setAllHTTPHeaderFields:(NSDictionary *)headers {
    NSMutableDictionary *updated = [headers mutableCopy];
    for (NSString *key in headers) updated[key] = UBRewriteValueForKey(headers[key], key);
    %orig(updated);
}

- (void)setValue:(NSString *)value forHTTPHeaderField:(NSString *)field {
    %orig(UBRewriteValueForKey(value, field), field);
}

- (void)addValue:(NSString *)value forHTTPHeaderField:(NSString *)field {
    %orig(UBRewriteValueForKey(value, field), field);
}
%end


typedef const char *(*UBCronetHeaderStringGetter)(void *);
typedef void (*UBCronetHeaderStringSetter)(void *, const char *);
typedef void (*UBCronetHeadersAddIMP)(void *, void *);
typedef size_t (*UBCronetHeadersSizeIMP)(void *);
typedef void *(*UBCronetHeadersAtIMP)(void *, size_t);
typedef void *(*UBCronetUploadProviderGetIMP)(void *);
typedef int64_t (*UBCronetUploadGetLengthFunc)(void *);
typedef void (*UBCronetUploadReadFunc)(void *, void *, void *);
typedef void (*UBCronetUploadRewindFunc)(void *, void *);
typedef void (*UBCronetUploadCloseFunc)(void *);
typedef void *(*UBCronetUploadProviderCreateWithIMP)(UBCronetUploadGetLengthFunc,
                                                     UBCronetUploadReadFunc,
                                                     UBCronetUploadRewindFunc,
                                                     UBCronetUploadCloseFunc);
typedef void (*UBCronetUploadSinkOnReadSucceededIMP)(void *, uint64_t, bool);
typedef uint64_t (*UBCronetBufferGetSizeIMP)(void *);
typedef void *(*UBCronetBufferGetDataIMP)(void *);
typedef int (*UBCronetUrlRequestInitIMP)(void *, void *, const char *, void *, void *, void *);
typedef void (*UBCronetOnReadCompletedIMP)(void *, void *, void *, void *, uint64_t);

static UBCronetHeaderStringGetter UBCronetHeaderNameGet = NULL;
static UBCronetHeaderStringGetter UBCronetHeaderValueGet = NULL;
static UBCronetHeaderStringSetter UBCronetHeaderValueSet = NULL;
static UBCronetHeadersAddIMP UBOrigCronetHeadersAdd = NULL;
static UBCronetHeadersSizeIMP UBCronetHeadersSize = NULL;
static UBCronetHeadersAtIMP UBCronetHeadersAt = NULL;
static UBCronetUploadProviderGetIMP UBCronetUploadProviderGet = NULL;
static UBCronetUploadProviderCreateWithIMP UBOrigCronetUploadProviderCreateWith = NULL;
static UBCronetUploadSinkOnReadSucceededIMP UBOrigCronetUploadSinkOnReadSucceeded = NULL;
static UBCronetBufferGetSizeIMP UBCronetBufferGetSize = NULL;
static UBCronetBufferGetDataIMP UBCronetBufferGetData = NULL;
static UBCronetUrlRequestInitIMP UBOrigCronetUrlRequestInit = NULL;
static UBCronetOnReadCompletedIMP UBOrigCronetOnReadCompleted = NULL;

static NSMutableDictionary<NSValue *, NSValue *> *UBCronetProviderReadCallbacks = nil;
static NSMutableDictionary<NSValue *, NSValue *> *UBCronetSinkBuffers = nil;
static NSMutableDictionary<NSValue *, NSString *> *UBCronetRequestURLs = nil;
static NSObject *UBCronetUploadLock = nil;

static void UBEnsureCronetUploadState(void) {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        UBCronetProviderReadCallbacks = [NSMutableDictionary dictionary];
        UBCronetSinkBuffers = [NSMutableDictionary dictionary];
        UBCronetRequestURLs = [NSMutableDictionary dictionary];
        UBCronetUploadLock = [NSObject new];
    });
}

static void UBRememberCronetRequestURL(void *request, NSURL *url) {
    if (!request || !UBIsGoOnlinePath(url)) return;
    UBEnsureCronetUploadState();
    @synchronized (UBCronetUploadLock) {
        UBCronetRequestURLs[[NSValue valueWithPointer:request]] = url.absoluteString ?: @"";
    }
}

static NSString *UBCronetURLForRequest(void *request) {
    if (!request) return nil;
    UBEnsureCronetUploadState();
    @synchronized (UBCronetUploadLock) {
        return UBCronetRequestURLs[[NSValue valueWithPointer:request]];
    }
}

static UBCronetUploadReadFunc UBOriginalReadCallbackForProvider(void *provider) {
    if (!provider) return NULL;
    UBEnsureCronetUploadState();
    @synchronized (UBCronetUploadLock) {
        NSValue *value = UBCronetProviderReadCallbacks[[NSValue valueWithPointer:provider]];
        return value ? (UBCronetUploadReadFunc)value.pointerValue : NULL;
    }
}

static void UBRememberSinkBuffer(void *sink, void *buffer) {
    if (!sink || !buffer) return;
    UBEnsureCronetUploadState();
    @synchronized (UBCronetUploadLock) {
        UBCronetSinkBuffers[[NSValue valueWithPointer:sink]] = [NSValue valueWithPointer:buffer];
    }
}

static void *UBBufferForSink(void *sink, BOOL remove) {
    if (!sink) return NULL;
    UBEnsureCronetUploadState();
    @synchronized (UBCronetUploadLock) {
        NSValue *key = [NSValue valueWithPointer:sink];
        NSValue *value = UBCronetSinkBuffers[key];
        if (remove) [UBCronetSinkBuffers removeObjectForKey:key];
        return value.pointerValue;
    }
}

static void UBHookCronetUploadReadCallback(void *provider, void *sink, void *buffer) {
    UBRememberSinkBuffer(sink, buffer);
    UBCronetUploadReadFunc original = UBOriginalReadCallbackForProvider(provider);
    if (original) {
        original(provider, sink, buffer);
    }
}

static void *UBHookCronetUploadProviderCreateWith(UBCronetUploadGetLengthFunc getLength,
                                                   UBCronetUploadReadFunc read,
                                                   UBCronetUploadRewindFunc rewind,
                                                   UBCronetUploadCloseFunc close) {
    if (!UBOrigCronetUploadProviderCreateWith) return NULL;

    UBEnsureCronetUploadState();
    void *provider = UBOrigCronetUploadProviderCreateWith(getLength,
                                                          read ? &UBHookCronetUploadReadCallback : NULL,
                                                          rewind,
                                                          close);
    if (provider && read) {
        @synchronized (UBCronetUploadLock) {
            UBCronetProviderReadCallbacks[[NSValue valueWithPointer:provider]] =
                [NSValue valueWithPointer:(void *)read];
        }
    }
    return provider;
}

static void UBHookCronetUploadSinkOnReadSucceeded(void *sink,
                                                   uint64_t bytesRead,
                                                   bool finalChunk) {
    void *buffer = UBBufferForSink(sink, YES);
    if (buffer && bytesRead > 0 && UBCronetBufferGetSize && UBCronetBufferGetData) {
        uint64_t capacity = UBCronetBufferGetSize(buffer);
        uint64_t count = bytesRead < capacity ? bytesRead : capacity;
        void *raw = UBCronetBufferGetData(buffer);

        if (raw && count > 0 && count <= NSUIntegerMax) {
            NSData *before = [NSData dataWithBytes:raw length:(NSUInteger)count];
            NSData *after = UBRewriteOpaqueDeviceIdentityData(before);
            if (after.length == before.length && ![after isEqualToData:before]) {
                memcpy(raw, after.bytes, (size_t)after.length);
                UBDiagnostic([NSString stringWithFormat:
                    @"Cronet upload body compatibility bytes rewritten bytes=%llu final=%d",
                    (unsigned long long)count, finalChunk ? 1 : 0]);
            }
        }
    }

    if (UBOrigCronetUploadSinkOnReadSucceeded) {
        UBOrigCronetUploadSinkOnReadSucceeded(sink, bytesRead, finalChunk);
    }
}

static BOOL UBCronetIsAppVersionHeader(const char *name) {
    if (!name) return NO;
    return strcasecmp(name, "x-uber-client-version") == 0 ||
           strcasecmp(name, "x-uber-als-app-version") == 0 ||
           strcasecmp(name, "x-uber-app-version") == 0 ||
           strcasecmp(name, "x-uber-build-version") == 0 ||
           strcasecmp(name, "x-uber-client-build") == 0 ||
           strcasecmp(name, "x-uber-client-build-number") == 0;
}

static BOOL UBCronetIsDeviceDataHeader(const char *name) {
    return name && strcasecmp(name, "x-uber-device-data") == 0;
}

static BOOL UBCronetRewriteHeader(void *header, BOOL *sawAppVersion, BOOL *sawDeviceData) {
    if (!header || !UBCronetHeaderNameGet || !UBCronetHeaderValueGet || !UBCronetHeaderValueSet) return NO;
    const char *name = UBCronetHeaderNameGet(header);
    const char *raw = UBCronetHeaderValueGet(header);
    if (!name || !raw) return NO;

    NSString *value = [NSString stringWithUTF8String:raw];
    if (!value) return NO;
    NSString *updated = value;

    if (UBCronetIsAppVersionHeader(name)) {
        if (sawAppVersion) *sawAppVersion = YES;
        updated = UBTargetAppVersion;
    } else {
        updated = [updated stringByReplacingOccurrencesOfString:UBOldAppVersion
                                                     withString:UBTargetAppVersion];
        updated = [updated stringByReplacingOccurrencesOfString:UBOldContinuousVersion
                                                     withString:UBTargetContinuousVersion];
    }

    if (UBCronetIsDeviceDataHeader(name)) {
        if (sawDeviceData) *sawDeviceData = YES;
        updated = UBRewriteDeviceDataHeader(updated);
    }

    if (![updated isEqualToString:value]) {
        UBCronetHeaderValueSet(header, updated.UTF8String);
        return YES;
    }
    return NO;
}

static void UBHookCronetHeadersAdd(void *params, void *header) {
    BOOL sawApp = NO, sawDevice = NO;
    if (UBCronetRewriteHeader(header, &sawApp, &sawDevice)) {
        UBDiagnostic(@"native Cronet header compatibility value rewritten");
    }
    if (UBOrigCronetHeadersAdd) UBOrigCronetHeadersAdd(params, header);
}

static int UBHookCronetUrlRequestInit(void *request,
                                      void *engine,
                                      const char *url,
                                      void *params,
                                      void *callback,
                                      void *executor) {
    BOOL sawApp = NO;
    BOOL sawDevice = NO;
    NSUInteger rewrites = 0;

    if (params && UBCronetHeadersSize && UBCronetHeadersAt) {
        size_t count = UBCronetHeadersSize(params);
        for (size_t i = 0; i < count; i++) {
            void *header = UBCronetHeadersAt(params, i);
            if (UBCronetRewriteHeader(header, &sawApp, &sawDevice)) rewrites++;
        }
    }

    NSString *urlString = url ? [NSString stringWithUTF8String:url] : nil;
    NSURL *nsURL = urlString.length ? [NSURL URLWithString:urlString] : nil;

    static NSUInteger requestPathLogCount = 0;
    if (nsURL && requestPathLogCount < 80) {
        @synchronized (UBTargetAppVersion) {
            if (requestPathLogCount < 80) {
                requestPathLogCount++;
                UBDiagnostic([NSString stringWithFormat:@"Cronet request host=%@ path=%@",
                              nsURL.host ?: @"", nsURL.path ?: @""]);
            }
        }
    }

    if (UBIsGoOnlinePath(nsURL)) {
        UBRememberCronetRequestURL(request, nsURL);
        BOOL hasUploadProvider = params && UBCronetUploadProviderGet && UBCronetUploadProviderGet(params) != NULL;
        UBDiagnostic([NSString stringWithFormat:
            @"Cronet %@ final request headers inspected appVersionHeader=%d deviceDataHeader=%d rewrites=%lu uploadProvider=%d",
            UBTargetPathLabel(nsURL), sawApp, sawDevice, (unsigned long)rewrites, hasUploadProvider]);
    }

    return UBOrigCronetUrlRequestInit
        ? UBOrigCronetUrlRequestInit(request, engine, url, params, callback, executor)
        : 0;
}

static void UBHookCronetUrlRequestCallbackOnReadCompleted(void *callback,
                                                           void *request,
                                                           void *info,
                                                           void *buffer,
                                                           uint64_t bytesRead) {
    (void)info;
    NSString *urlString = UBCronetURLForRequest(request);
    NSURL *url = urlString.length ? [NSURL URLWithString:urlString] : nil;

    if (url && buffer && bytesRead > 0 && UBCronetBufferGetSize && UBCronetBufferGetData) {
        uint64_t capacity = UBCronetBufferGetSize(buffer);
        uint64_t count = bytesRead < capacity ? bytesRead : capacity;
        void *raw = UBCronetBufferGetData(buffer);

        if (raw && count > 0 && count <= NSUIntegerMax) {
            NSData *before = [NSData dataWithBytes:raw length:(NSUInteger)count];
            __block NSUInteger removed = 0;
            __block NSData *encoded = nil;
            __block BOOL parsedJSON = NO;

            BOOL previousSkip = UBSkipJSONHooks;
            UBSkipJSONHooks = YES;
            @try {
                id json = [NSJSONSerialization JSONObjectWithData:before options:0 error:nil];
                if (json) {
                    parsedJSON = YES;
                    id filtered = UBFilterForceUpgradeOnlineBlockers(json, 0, &removed);
                    if (removed && [NSJSONSerialization isValidJSONObject:filtered]) {
                        encoded = [NSJSONSerialization dataWithJSONObject:filtered options:0 error:nil];
                    }
                }
            } @finally {
                UBSkipJSONHooks = previousSkip;
            }

            if (removed && encoded.length && encoded.length <= (NSUInteger)count) {
                memset(raw, ' ', (size_t)count);
                memcpy(raw, encoded.bytes, encoded.length);
                UBDiagnostic([NSString stringWithFormat:
                    @"Cronet %@ response force-upgrade JSON filtered entries=%lu bytes=%llu->%lu",
                    UBTargetPathLabel(url), (unsigned long)removed,
                    (unsigned long long)count, (unsigned long)encoded.length]);
            } else if (removed && encoded.length > (NSUInteger)count) {
                UBDiagnostic([NSString stringWithFormat:
                    @"Cronet %@ response filter skipped because encoded JSON grew bytes=%llu->%lu",
                    UBTargetPathLabel(url), (unsigned long long)count, (unsigned long)encoded.length]);
            } else if (!parsedJSON) {
                NSString *text = [[NSString alloc] initWithData:before encoding:NSUTF8StringEncoding];
                NSString *lower = text.lowercaseString;
                if ([lower containsString:@"force_upgrade"] ||
                    [lower containsString:@"forceupgrade"] ||
                    [lower containsString:@"minversionurl"] ||
                    [lower containsString:@"storeurl"]) {
                    UBDiagnostic([NSString stringWithFormat:
                        @"Cronet %@ response contains force-upgrade marker in non-JSON chunk bytes=%llu",
                        UBTargetPathLabel(url), (unsigned long long)count]);
                }
            }
        }
    }

    if (UBOrigCronetOnReadCompleted) {
        UBOrigCronetOnReadCompleted(callback, request, info, buffer, bytesRead);
    }
}

static void UBInstallNativeCronetHooks(void) {
    NSString *frameworks = NSBundle.mainBundle.privateFrameworksPath;
    NSString *path = [frameworks stringByAppendingPathComponent:@"Cronet.framework/Cronet"];
    void *handle = dlopen(path.fileSystemRepresentation, RTLD_LAZY | RTLD_LOCAL);
    if (!handle) {
        UBDiagnostic(@"Cronet.framework not loaded; native Cronet hooks unavailable");
        return;
    }

    UBCronetHeaderNameGet = (UBCronetHeaderStringGetter)dlsym(handle, "Cronet_HttpHeader_name_get");
    UBCronetHeaderValueGet = (UBCronetHeaderStringGetter)dlsym(handle, "Cronet_HttpHeader_value_get");
    UBCronetHeaderValueSet = (UBCronetHeaderStringSetter)dlsym(handle, "Cronet_HttpHeader_value_set");
    UBCronetHeadersSize = (UBCronetHeadersSizeIMP)dlsym(handle, "Cronet_UrlRequestParams_request_headers_size");
    UBCronetHeadersAt = (UBCronetHeadersAtIMP)dlsym(handle, "Cronet_UrlRequestParams_request_headers_at");
    UBCronetUploadProviderGet = (UBCronetUploadProviderGetIMP)dlsym(handle, "Cronet_UrlRequestParams_upload_data_provider_get");
    UBCronetBufferGetSize = (UBCronetBufferGetSizeIMP)dlsym(handle, "Cronet_Buffer_GetSize");
    UBCronetBufferGetData = (UBCronetBufferGetDataIMP)dlsym(handle, "Cronet_Buffer_GetData");

    void *headersAdd = dlsym(handle, "Cronet_UrlRequestParams_request_headers_add");
    void *requestInit = dlsym(handle, "Cronet_UrlRequest_InitWithParams");
    void *uploadProviderCreateWith = dlsym(handle, "Cronet_UploadDataProvider_CreateWith");
    void *uploadSinkOnReadSucceeded = dlsym(handle, "Cronet_UploadDataSink_OnReadSucceeded");
    void *onReadCompleted = dlsym(handle, "Cronet_UrlRequestCallback_OnReadCompleted");

    if (!UBCronetHeaderNameGet || !UBCronetHeaderValueGet || !UBCronetHeaderValueSet ||
        !UBCronetHeadersSize || !UBCronetHeadersAt || !headersAdd || !requestInit) {
        UBDiagnostic(@"Cronet native symbols missing; final request hook not installed");
        return;
    }

    MSHookFunction(headersAdd,
                   (void *)&UBHookCronetHeadersAdd,
                   (void **)&UBOrigCronetHeadersAdd);
    MSHookFunction(requestInit,
                   (void *)&UBHookCronetUrlRequestInit,
                   (void **)&UBOrigCronetUrlRequestInit);

    if (uploadProviderCreateWith && uploadSinkOnReadSucceeded &&
        UBCronetBufferGetSize && UBCronetBufferGetData) {
        UBEnsureCronetUploadState();
        MSHookFunction(uploadProviderCreateWith,
                       (void *)&UBHookCronetUploadProviderCreateWith,
                       (void **)&UBOrigCronetUploadProviderCreateWith);
        MSHookFunction(uploadSinkOnReadSucceeded,
                       (void *)&UBHookCronetUploadSinkOnReadSucceeded,
                       (void **)&UBOrigCronetUploadSinkOnReadSucceeded);
    }

    if (onReadCompleted && UBCronetBufferGetSize && UBCronetBufferGetData) {
        UBEnsureCronetUploadState();
        MSHookFunction(onReadCompleted,
                       (void *)&UBHookCronetUrlRequestCallbackOnReadCompleted,
                       (void **)&UBOrigCronetOnReadCompleted);
    }

    if (UBOrigCronetHeadersAdd && UBOrigCronetUrlRequestInit) {
        if (UBOrigCronetUploadProviderCreateWith && UBOrigCronetUploadSinkOnReadSucceeded &&
            UBOrigCronetOnReadCompleted) {
            UBDiagnostic(@"native Cronet add+final-request+upload-body+response hooks installed");
        } else if (UBOrigCronetUploadProviderCreateWith && UBOrigCronetUploadSinkOnReadSucceeded) {
            UBDiagnostic(@"native Cronet add+final-request+upload-body hooks installed; response hook unavailable");
        } else {
            UBDiagnostic(@"native Cronet add+final-request hooks installed; upload-body/response hooks unavailable");
        }
    } else {
        UBDiagnostic(@"native Cronet hook installation incomplete");
    }
}

static CFTypeRef (*UBOrigCFBundleGetValueForInfoDictionaryKey)(CFBundleRef bundle, CFStringRef key) = NULL;
static CFTypeRef UBHookCFBundleGetValueForInfoDictionaryKey(CFBundleRef bundle, CFStringRef key) {
    if (bundle == CFBundleGetMainBundle() && key && CFGetTypeID(key) == CFStringGetTypeID()) {
        if (CFEqual(key, CFSTR("CFBundleShortVersionString")) || CFEqual(key, CFSTR("CFBundleVersion"))) {
            return CFSTR("4.584.10000");
        }
        if (CFEqual(key, CFSTR("MinimumOSVersion"))) {
            return CFSTR("18.0");
        }
        if (CFEqual(key, CFSTR("UBContinuousVersion"))) {
            return CFSTR("326106.1");
        }
        if (CFEqual(key, CFSTR("UBBuildUUID"))) {
            return CFSTR("7a058960-ab07-11f1-8af6-ebef13f4ae76");
        }
    }
    return UBOrigCFBundleGetValueForInfoDictionaryKey(bundle, key);
}

static int (*UBOrigSysctlByName)(const char *, void *, size_t *, const void *, size_t) = NULL;
static int UBCopySysctlString(const char *spoof, void *oldp, size_t *oldlenp) {
    if (!oldlenp) {
        errno = EINVAL;
        return -1;
    }

    size_t required = strlen(spoof) + 1;
    if (!oldp) {
        *oldlenp = required;
        return 0;
    }

    if (*oldlenp < required) {
        *oldlenp = required;
        errno = ENOMEM;
        return -1;
    }

    memcpy(oldp, spoof, required);
    *oldlenp = required;
    return 0;
}

static int UBHookSysctlByName(const char *name, void *oldp, size_t *oldlenp, const void *newp, size_t newlen) {
    if (name && !newp) {
        if (strcmp(name, "kern.osproductversion") == 0) {
            return UBCopySysctlString("18.0", oldp, oldlenp);
        }
        if (strcmp(name, "kern.osversion") == 0) {
            return UBCopySysctlString("22A3354", oldp, oldlenp);
        }
        if (strcmp(name, "kern.osrelease") == 0) {
            return UBCopySysctlString("24.0.0", oldp, oldlenp);
        }
    }
    return UBOrigSysctlByName(name, oldp, oldlenp, newp, newlen);
}

%ctor {
    @autoreleasepool {
        if (![NSBundle.mainBundle.bundleIdentifier isEqualToString:@"com.ubercab.UberPartner"]) return;

        UBActualOSVersion = UIDevice.currentDevice.systemVersion;

        MSHookFunction((void *)&CFBundleGetValueForInfoDictionaryKey,
                       (void *)&UBHookCFBundleGetValueForInfoDictionaryKey,
                       (void **)&UBOrigCFBundleGetValueForInfoDictionaryKey);

        MSHookFunction((void *)&sysctlbyname,
                       (void *)&UBHookSysctlByName,
                       (void **)&UBOrigSysctlByName);

        [[NSFileManager defaultManager] removeItemAtPath:[NSHomeDirectory() stringByAppendingPathComponent:@"Documents/UberDriverBypass.log"] error:nil];
        UBDiagnostic(@"UberDriverBypass 0.15.0 loaded; Go Online response-shape diagnostics active");
        UBInstallNativeCronetHooks();
        %init;
        UBInstallDriverChecksModelHooks();
        UBInstallLocalForceUpgradeHooks();
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)),
                       dispatch_get_main_queue(), ^{
            if (!UBOrigDriverChecksIssues && !UBOrigDriverChecksFutureBlockers) {
                UBInstallDriverChecksModelHooks();
            }
            UBInstallLocalForceUpgradeHooks();
        });
    }
}
