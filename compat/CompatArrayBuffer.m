#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <stdint.h>

extern void *swift_retain(void *object);
extern id objc_retain(id object);

// Swift 5.9 pre-specialization ABI used by Carbon:
//   x0 = index
//   x1 = _ArrayBuffer<AnyObject> bridge-storage word
//   x0 = owned AnyObject result
//
// For an unflagged native buffer Carbon inlines the fast path and never calls
// this symbol. The slow path is therefore either:
//   - a native buffer with the deferred-type-check low flag set, or
//   - an Objective-C NSArray bridge object (bit 62 set).
//
// AnyObject needs no deferred element downcast, so both cases can be serviced
// directly without invoking iOS16's generic _ArrayBuffer implementation.
__attribute__((visibility("default")))
id UBArrayBufferGetElementSlowPath(long index, uintptr_t storage)
__asm__("_$ss12_ArrayBufferV19_getElementSlowPathyyXlSiFyXl_Ts5");

id UBArrayBufferGetElementSlowPath(long index, uintptr_t storage) {
    static const uintptr_t ObjCBridgeBit = 0x4000000000000000ULL;

    if ((storage & ObjCBridgeBit) != 0) {
        // Swift BridgeObject marks ordinary Objective-C references with bit 62.
        // Strip only that discriminator to recover the actual NSArray pointer.
        NSArray *array = (NSArray *)(storage & ~ObjCBridgeBit);
        id value = [array objectAtIndex:(NSUInteger)index];
        return (id)objc_retain(value);
    }

    // Native deferred-type-check storage: the low spare bit is the flag.
    // _ContiguousArrayStorage keeps count/capacity at +0x10/+0x18 and its
    // element area begins at +0x20, matching Carbon's own inlined fast path.
    uintptr_t nativeStorage = storage & ~(uintptr_t)1;
    id value = *(id *)(nativeStorage + 0x20 + ((uintptr_t)index * sizeof(void *)));

    // Return an owned object, matching the Swift specialized function's
    // ownership convention.
    return (id)swift_retain((void *)value);
}
