#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CoreFoundation/CoreFoundation.h>
#import <objc/runtime.h>
#import <substrate.h>
#import <sys/sysctl.h>
#import <errno.h>
#import <string.h>

static NSString * const UBTargetOSVersion = @"17.0";
static NSString * const UBTargetOSMajor = @"17";
static NSString * const UBTargetOSBuild = @"21A329";
static NSString * const UBOldAppVersion = @"4.527.10000";
static NSString * const UBTargetAppVersion = @"4.584.10000";
static NSString * const UBTargetContinuousVersion = @"326106.1";

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

static id UBRewriteValueForKey(id value, NSString *key) {
    if (![key isKindOfClass:NSString.class]) return value;
    NSString *k = UBNormalizedKey(key);
    BOOL numeric = [value isKindOfClass:NSNumber.class];
    if (![value isKindOfClass:NSString.class] && !numeric) return value;
    NSString *v = numeric ? [value stringValue] : value;
    if ([@[@"deviceosversion", @"osversion", @"osfullversion", @"iosversion",
           @"prevosversion", @"xuberalsdeviceosversion"] containsObject:k])
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

static BOOL UBIsUberURL(NSURL *url) {
    NSString *host = url.host.lowercaseString;
    return [host isEqualToString:@"uber.com"] || [host hasSuffix:@".uber.com"];
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
        if (after != before) {
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
    NSMutableURLRequest *copy = [UBRewriteRequest(request, NO) mutableCopy];
    if (updated != body) [copy setValue:nil forHTTPHeaderField:@"Content-Length"];
    return %orig(copy, updated);
}
- (NSURLSessionUploadTask *)uploadTaskWithRequest:(NSURLRequest *)request fromData:(NSData *)body completionHandler:(void (^)(NSData *, NSURLResponse *, NSError *))handler {
    NSData *updated = UBIsUberURL(request.URL) && ![request valueForHTTPHeaderField:@"Content-Encoding"].length ? UBRewriteBody(body) : body;
    NSMutableURLRequest *copy = [UBRewriteRequest(request, NO) mutableCopy];
    if (updated != body) [copy setValue:nil forHTTPHeaderField:@"Content-Length"];
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
    %orig(updated);
    if (updated != body) [self setValue:nil forHTTPHeaderField:@"Content-Length"];
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
    }
    return UBOrigSysctlByName(name, oldp, oldlenp, newp, newlen);
}

%ctor {
    @autoreleasepool {
        if (![NSBundle.mainBundle.bundleIdentifier isEqualToString:@"com.ubercab.UberPartner"]) return;

        MSHookFunction((void *)&CFBundleGetValueForInfoDictionaryKey,
                       (void *)&UBHookCFBundleGetValueForInfoDictionaryKey,
                       (void **)&UBOrigCFBundleGetValueForInfoDictionaryKey);

        MSHookFunction((void *)&sysctlbyname,
                       (void *)&UBHookSysctlByName,
                       (void **)&UBOrigSysctlByName);

        [[NSFileManager defaultManager] removeItemAtPath:[NSHomeDirectory() stringByAppendingPathComponent:@"Documents/UberDriverBypass.log"] error:nil];
        UBDiagnostic(@"UberDriverBypass 0.2.0 loaded; metadata-only diagnostics (no request contents)");
        %init;
    }
}
