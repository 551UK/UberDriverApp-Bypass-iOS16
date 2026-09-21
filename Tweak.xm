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

static BOOL UBStringHasDigit(NSString *value) {
    if (![value isKindOfClass:NSString.class]) return NO;
    NSCharacterSet *digits = NSCharacterSet.decimalDigitCharacterSet;
    return [value rangeOfCharacterFromSet:digits].location != NSNotFound;
}

static BOOL UBKeyEquals(NSString *lower, NSArray<NSString *> *names) {
    for (NSString *name in names) {
        if ([lower isEqualToString:name]) return YES;
    }
    return NO;
}

static NSString *UBRewriteValueForKey(NSString *value, NSString *key) {
    if (![value isKindOfClass:NSString.class] || ![key isKindOfClass:NSString.class]) return value;

    NSString *lower = key.lowercaseString;

    if (UBKeyEquals(lower, @[
        @"x-uber-als-device-os-version",
        @"device_os_version",
        @"deviceosversion",
        @"os_version",
        @"osversion",
        @"osfullversion",
        @"prevosversion"
    ])) {
        return UBTargetOSVersion;
    }

    if (UBKeyEquals(lower, @[@"osmajorversion", @"os_major_version"])) {
        return UBTargetOSMajor;
    }

    if (UBKeyEquals(lower, @[@"x-uber-device-os-build", @"os_version_build", @"osbuildversion"])) {
        return UBTargetOSBuild;
    }

    if (UBKeyEquals(lower, @[@"deviceos", @"device_os", @"x-uber-device-os", @"backend_device_os"])) {
        if (!UBStringHasDigit(value)) return value;
        if ([value.lowercaseString containsString:@"ios"]) return @"iOS 17.0";
        return UBTargetOSVersion;
    }

    if (UBKeyEquals(lower, @[
        @"x-uber-client-version",
        @"x-uber-als-app-version",
        @"appversion",
        @"app_version",
        @"clientversion",
        @"client_version"
    ])) {
        if ([value containsString:UBOldAppVersion]) {
            return [value stringByReplacingOccurrencesOfString:UBOldAppVersion withString:UBTargetAppVersion];
        }
        if ([value isEqualToString:UBOldAppVersion]) return UBTargetAppVersion;
    }

    if ([lower isEqualToString:@"ubcontinuousversion"] || [lower isEqualToString:@"continuousversion"]) {
        return UBTargetContinuousVersion;
    }

    return value;
}

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
- (void)setValue:(NSString *)value forHTTPHeaderField:(NSString *)field {
    %orig(UBRewriteValueForKey(value, field), field);
}

- (void)addValue:(NSString *)value forHTTPHeaderField:(NSString *)field {
    %orig(UBRewriteValueForKey(value, field), field);
}
%end

%hook NSMutableDictionary
- (void)setObject:(id)object forKey:(id<NSCopying>)key {
    id rewritten = object;
    if ([object isKindOfClass:NSString.class] && [(id)key isKindOfClass:NSString.class]) {
        rewritten = UBRewriteValueForKey((NSString *)object, (NSString *)key);
    }
    %orig(rewritten, key);
}

- (void)setObject:(id)object forKeyedSubscript:(id<NSCopying>)key {
    id rewritten = object;
    if ([object isKindOfClass:NSString.class] && [(id)key isKindOfClass:NSString.class]) {
        rewritten = UBRewriteValueForKey((NSString *)object, (NSString *)key);
    }
    %orig(rewritten, key);
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

static void (*UBOrigDictMSetObject)(id, SEL, id, id) = NULL;
static void UBDictMSetObject(id self, SEL _cmd, id object, id key) {
    id rewritten = object;
    if ([object isKindOfClass:NSString.class] && [key isKindOfClass:NSString.class]) {
        rewritten = UBRewriteValueForKey((NSString *)object, (NSString *)key);
    }
    UBOrigDictMSetObject(self, _cmd, rewritten, key);
}

static void (*UBOrigDictMSetSubscript)(id, SEL, id, id) = NULL;
static void UBDictMSetSubscript(id self, SEL _cmd, id object, id key) {
    id rewritten = object;
    if ([object isKindOfClass:NSString.class] && [key isKindOfClass:NSString.class]) {
        rewritten = UBRewriteValueForKey((NSString *)object, (NSString *)key);
    }
    UBOrigDictMSetSubscript(self, _cmd, rewritten, key);
}

static void UBHookMutableDictionaryConcreteClass(void) {
    Class cls = NSClassFromString(@"__NSDictionaryM");
    if (!cls) return;

    Method setter = class_getInstanceMethod(cls, @selector(setObject:forKey:));
    if (setter) {
        MSHookMessageEx(cls, @selector(setObject:forKey:), (IMP)&UBDictMSetObject, (IMP *)&UBOrigDictMSetObject);
    }

    Method subscript = class_getInstanceMethod(cls, @selector(setObject:forKeyedSubscript:));
    if (subscript) {
        MSHookMessageEx(cls, @selector(setObject:forKeyedSubscript:), (IMP)&UBDictMSetSubscript, (IMP *)&UBOrigDictMSetSubscript);
    }
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

        UBHookMutableDictionaryConcreteClass();
        %init;
    }
}
