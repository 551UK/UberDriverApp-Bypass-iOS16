#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CoreFoundation/CoreFoundation.h>
#import <objc/runtime.h>
#import <substrate.h>
#import <sys/sysctl.h>
#import <errno.h>
#import <string.h>

static NSString * const UBTargetOSVersion = @"17.0";
static NSString * const UBTargetOSLongVersion = @"17.0.0";
static NSString * const UBTargetOSMajor = @"17";
static NSString * const UBTargetOSBuild = @"21A329";
static NSString * const UBOldAppVersion = @"4.527.10000";
static NSString * const UBTargetAppVersion = @"4.584.10000";
static NSString * const UBOldContinuousVersion = @"273504.1";
static NSString * const UBTargetContinuousVersion = @"326106.1";
static NSString *UBActualOSVersion = nil;

static BOOL UBIsMainBundle(NSBundle *bundle) {
    return bundle && bundle == NSBundle.mainBundle;
}

// Only compatibility metadata is changed. No response, account, document or
// online-blocker objects are filtered or marked successful.
static void UBDiagnostic(NSString *event) {
    static NSUInteger count = 0;
    @synchronized (UBTargetAppVersion) {
        if (count++ >= 80) return;
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
        return numeric ? @17 : UBTargetOSVersion;
    if ([k isEqualToString:@"osmajorversion"]) return numeric ? @17 : UBTargetOSMajor;
    if ([@[@"xuberdeviceosbuild", @"osversionbuild", @"osbuildversion"] containsObject:k])
        return UBTargetOSBuild;
    if ([@[@"deviceos", @"xuberdeviceos", @"xuberalsdeviceos", @"backenddeviceos"] containsObject:k]) {
        NSRange digit = [v rangeOfCharacterFromSet:NSCharacterSet.decimalDigitCharacterSet];
        // Preserve platform-only strings (e.g. iOS), and the original prefix.
        if (digit.location == NSNotFound) return value;
        NSString *prefix = [v substringToIndex:digit.location];
        return numeric ? @17 : [prefix stringByAppendingString:UBTargetOSVersion];
    }
    if ([@[@"xuberclientversion", @"xuberalsappversion", @"appversion",
           @"clientversion", @"version", @"cfbundleversion", @"cfbundleshortversionstring"] containsObject:k]) {
        if ([v isEqualToString:UBOldAppVersion]) return UBTargetAppVersion;
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

static BOOL UBSelectorLooksLikeApplicabilityCheck(SEL selector) {
    NSString *name = NSStringFromSelector(selector).lowercaseString;
    return [name containsString:@"applic"] ||
           [name containsString:@"isenabled"] ||
           [name containsString:@"enabledfor"] ||
           [name containsString:@"canhandle"] ||
           [name containsString:@"supports"] ||
           [name containsString:@"shouldhandle"];
}

static BOOL UBForceUpgradeReturnNO(id self, SEL _cmd) {
    (void)self; (void)_cmd;
    return NO;
}

static void UBDisableForceUpgradeBooleanChecksOnClass(Class cls, NSString *label) {
    if (!cls) return;

    unsigned int count = 0;
    Method *methods = class_copyMethodList(cls, &count);
    NSUInteger hooked = 0;
    for (unsigned int i = 0; i < count; i++) {
        Method method = methods[i];
        SEL selector = method_getName(method);
        const char *encoding = method_getTypeEncoding(method);
        if (!encoding || !UBSelectorLooksLikeApplicabilityCheck(selector)) continue;

        char returnType[32] = {0};
        method_getReturnType(method, returnType, sizeof(returnType));
        if (returnType[0] == 'B' || returnType[0] == 'c') {
            method_setImplementation(method, (IMP)UBForceUpgradeReturnNO);
            hooked++;
            UBDiagnostic([NSString stringWithFormat:@"%@ disabled %@", label, NSStringFromSelector(selector)]);
        }
    }
    free(methods);

    Class meta = object_getClass(cls);
    count = 0;
    methods = class_copyMethodList(meta, &count);
    for (unsigned int i = 0; i < count; i++) {
        Method method = methods[i];
        SEL selector = method_getName(method);
        const char *encoding = method_getTypeEncoding(method);
        if (!encoding || !UBSelectorLooksLikeApplicabilityCheck(selector)) continue;

        char returnType[32] = {0};
        method_getReturnType(method, returnType, sizeof(returnType));
        if (returnType[0] == 'B' || returnType[0] == 'c') {
            method_setImplementation(method, (IMP)UBForceUpgradeReturnNO);
            hooked++;
            UBDiagnostic([NSString stringWithFormat:@"%@ class check disabled %@", label, NSStringFromSelector(selector)]);
        }
    }
    free(methods);

    UBDiagnostic([NSString stringWithFormat:@"%@ applicability hooks: %lu", label, (unsigned long)hooked]);
}

static void UBInstallForceUpgradeRuntimeHooks(void) {
    int count = objc_getClassList(NULL, 0);
    if (count <= 0) return;

    Class *classes = (__unsafe_unretained Class *)calloc((size_t)count, sizeof(Class));
    count = objc_getClassList(classes, count);
    for (int i = 0; i < count; i++) {
        Class cls = classes[i];
        NSString *name = NSStringFromClass(cls);
        if ([name containsString:@"ForceUpgradeOnlineBlockerPluginFactory"] ||
            [name containsString:@"ForceUpgradeBlockerAdapter"]) {
            UBDisableForceUpgradeBooleanChecksOnClass(cls, name);
        }
    }
    free(classes);
}

static BOOL UBIsUberURL(NSURL *url) {
    NSString *host = url.host.lowercaseString;
    return [host isEqualToString:@"uber.com"] || [host hasSuffix:@".uber.com"];
}

static BOOL UBIsDeviceIdentityRequest(NSURLRequest *request) {
    if (!request || !UBIsUberURL(request.URL)) return NO;
    NSString *url = request.URL.absoluteString.lowercaseString ?: @"";
    if ([url containsString:@"uberdevices"] ||
        [url containsString:@"upsert-user-device"] ||
        [url containsString:@"devices/upsert"] ||
        [url containsString:@"device-info"] ||
        [url containsString:@"device_info"]) {
        return YES;
    }
    return [request valueForHTTPHeaderField:@"x-uber-device-data"].length > 0;
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
        if (after == before && UBIsDeviceIdentityRequest(request)) {
            after = UBRewriteOpaqueDeviceIdentityData(before);
            if (![after isEqualToData:before]) UBDiagnostic(@"opaque Uber device identity body rewritten");
        }
        if (after != before && ![after isEqualToData:before]) {
            copy.HTTPBody = after;
            [copy setValue:nil forHTTPHeaderField:@"Content-Length"];
            changed = YES;
        }
    }
    UBDiagnostic(changed ? @"Uber NSURLSession request updated" : @"Uber NSURLSession request observed (no rewrite needed)");
    return changed ? copy : request;
}

%hook NSJSONSerialization
+ (NSData *)dataWithJSONObject:(id)object options:(NSJSONWritingOptions)options error:(NSError **)error {
    NSUInteger changes = 0;
    id updated = UBRewriteJSON(object, 0, &changes);
    if (changes) UBDiagnostic([NSString stringWithFormat:@"JSON serializer compatibility fields changed: %lu", (unsigned long)changes]);
    return %orig(updated, options, error);
}

+ (id)JSONObjectWithData:(NSData *)data options:(NSJSONReadingOptions)options error:(NSError **)error {
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

%hook NSURLSession
- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request {
    return %orig(UBRewriteRequest(request, YES));
}
- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request completionHandler:(void (^)(NSData *, NSURLResponse *, NSError *))handler {
    return %orig(UBRewriteRequest(request, YES), handler);
}
- (NSURLSessionUploadTask *)uploadTaskWithRequest:(NSURLRequest *)request fromData:(NSData *)body {
    NSData *updated = UBIsUberURL(request.URL) && ![request valueForHTTPHeaderField:@"Content-Encoding"].length ? UBRewriteBody(body) : body;
    if (updated == body && UBIsDeviceIdentityRequest(request)) {
        updated = UBRewriteOpaqueDeviceIdentityData(body);
        if (![updated isEqualToData:body]) UBDiagnostic(@"opaque Uber upload identity body rewritten");
    }
    NSMutableURLRequest *copy = [UBRewriteRequest(request, NO) mutableCopy];
    if (updated != body && ![updated isEqualToData:body]) [copy setValue:nil forHTTPHeaderField:@"Content-Length"];
    return %orig(copy, updated);
}
- (NSURLSessionUploadTask *)uploadTaskWithRequest:(NSURLRequest *)request fromData:(NSData *)body completionHandler:(void (^)(NSData *, NSURLResponse *, NSError *))handler {
    NSData *updated = UBIsUberURL(request.URL) && ![request valueForHTTPHeaderField:@"Content-Encoding"].length ? UBRewriteBody(body) : body;
    if (updated == body && UBIsDeviceIdentityRequest(request)) {
        updated = UBRewriteOpaqueDeviceIdentityData(body);
        if (![updated isEqualToData:body]) UBDiagnostic(@"opaque Uber upload identity body rewritten");
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
    return @"Version 17.0 (Build 21A329)";
}

- (NSOperatingSystemVersion)operatingSystemVersion {
    NSOperatingSystemVersion version;
    version.majorVersion = 17;
    version.minorVersion = 0;
    version.patchVersion = 0;
    return version;
}

- (BOOL)isOperatingSystemAtLeastVersion:(NSOperatingSystemVersion)version {
    if (version.majorVersion < 17) return YES;
    if (version.majorVersion > 17) return NO;
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
    }
    return %orig;
}

- (NSDictionary *)infoDictionary {
    NSDictionary *original = %orig;
    if (!UBIsMainBundle(self) || !original) return original;

    NSMutableDictionary *copy = [original mutableCopy];
    copy[@"CFBundleShortVersionString"] = UBTargetAppVersion;
    copy[@"CFBundleVersion"] = UBTargetAppVersion;
    copy[@"MinimumOSVersion"] = UBTargetOSVersion;
    copy[@"UBContinuousVersion"] = UBTargetContinuousVersion;
    return copy;
}
%end

%hook NSMutableURLRequest
- (void)setHTTPBody:(NSData *)body {
    NSData *updated = UBIsUberURL(self.URL) && ![self valueForHTTPHeaderField:@"Content-Encoding"].length ? UBRewriteBody(body) : body;
    if (updated == body && UBIsDeviceIdentityRequest(self)) {
        updated = UBRewriteOpaqueDeviceIdentityData(body);
        if (![updated isEqualToData:body]) UBDiagnostic(@"opaque NSMutableURLRequest device body rewritten");
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

static CFTypeRef (*UBOrigCFBundleGetValueForInfoDictionaryKey)(CFBundleRef bundle, CFStringRef key) = NULL;
static CFTypeRef UBHookCFBundleGetValueForInfoDictionaryKey(CFBundleRef bundle, CFStringRef key) {
    if (bundle == CFBundleGetMainBundle() && key && CFGetTypeID(key) == CFStringGetTypeID()) {
        if (CFEqual(key, CFSTR("CFBundleShortVersionString")) || CFEqual(key, CFSTR("CFBundleVersion"))) {
            return CFSTR("4.584.10000");
        }
        if (CFEqual(key, CFSTR("MinimumOSVersion"))) {
            return CFSTR("17.0");
        }
        if (CFEqual(key, CFSTR("UBContinuousVersion"))) {
            return CFSTR("326106.1");
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
            return UBCopySysctlString("17.0", oldp, oldlenp);
        }
        if (strcmp(name, "kern.osversion") == 0) {
            return UBCopySysctlString("21A329", oldp, oldlenp);
        }
        if (strcmp(name, "kern.osrelease") == 0) {
            return UBCopySysctlString("23.0.0", oldp, oldlenp);
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
        UBDiagnostic(@"UberDriverBypass 0.3.0 loaded; targeting Go Online force-upgrade blocker");
        %init;
        UBInstallForceUpgradeRuntimeHooks();
    }
}
