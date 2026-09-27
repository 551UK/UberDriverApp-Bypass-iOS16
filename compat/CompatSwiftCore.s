.text
.p2align 2

// iOS 16 compatibility shims for Swift AnyObject pre-specializations
// emitted by the newer Uber Driver build.

.macro LOAD_ANYOBJECT reg
    adrp \\reg, "_$syXlN"@GOTPAGE
    ldr  \\reg, [\\reg, "_$syXlN"@GOTPAGEOFF]
.endm

// These two AnyObject append specializations are tiny and ABI-stable:
// x0=oldCount, x1=new object, x20=inout Array/ContiguousArray storage.
.globl "_$ss15ContiguousArrayV37_appendElementAssumeUniqueAndCapacity_03newD0ySi_xntFyXl_Ts5"
"_$ss15ContiguousArrayV37_appendElementAssumeUniqueAndCapacity_03newD0ySi_xntFyXl_Ts5":
    ldr x8, [x20]
    add x9, x0, #1
    str x9, [x8, #0x10]
    add x8, x8, x0, lsl #3
    str x1, [x8, #0x20]
    ret

.globl "_$sSa37_appendElementAssumeUniqueAndCapacity_03newB0ySi_xntFyXl_Ts5"
"_$sSa37_appendElementAssumeUniqueAndCapacity_03newB0ySi_xntFyXl_Ts5":
    ldr x8, [x20]
    add x9, x0, #1
    str x9, [x8, #0x10]
    add x8, x8, x0, lsl #3
    str x1, [x8, #0x20]
    ret

// Adapt pre-specialized AnyObject entry points to the older generic
// Swift runtime ABI by supplying the AnyObject metadata argument.
.globl "_$ss15ContiguousArrayV034_makeUniqueAndReserveCapacityIfNotD0yyFyXl_Ts5"
"_$ss15ContiguousArrayV034_makeUniqueAndReserveCapacityIfNotD0yyFyXl_Ts5":
    LOAD_ANYOBJECT x0
    b "_$ss15ContiguousArrayV034_makeUniqueAndReserveCapacityIfNotD0yyF"

.globl "_$ss15ContiguousArrayV15reserveCapacityyySiFyXl_Ts5"
"_$ss15ContiguousArrayV15reserveCapacityyySiFyXl_Ts5":
    LOAD_ANYOBJECT x1
    b "_$ss15ContiguousArrayV15reserveCapacityyySiF"

.globl "_$ss15ContiguousArrayV36_reserveCapacityAssumingUniqueBuffer8oldCountySi_tFyXl_Ts5"
"_$ss15ContiguousArrayV36_reserveCapacityAssumingUniqueBuffer8oldCountySi_tFyXl_Ts5":
    LOAD_ANYOBJECT x1
    b "_$ss15ContiguousArrayV36_reserveCapacityAssumingUniqueBuffer8oldCountySi_tF"

.globl "_$sSa034_makeUniqueAndReserveCapacityIfNotB0yyFyXl_Ts5"
"_$sSa034_makeUniqueAndReserveCapacityIfNotB0yyFyXl_Ts5":
    LOAD_ANYOBJECT x0
    b "_$sSa034_makeUniqueAndReserveCapacityIfNotB0yyF"

// The remaining private pre-specializations are exported so dyld can
// load the app. If one is actually executed, fail at a unique BRK code
// instead of silently corrupting an Array. The next crash then tells us
// exactly which semantic adapter must be implemented.
.macro DIAG_TRAP name, code
.globl \\name
\\name:
    brk #\\code
    ret
.endm

DIAG_TRAP "_$ss12_ArrayBufferV19_getElementSlowPathyyXlSiFyXl_Ts5", 0x403
DIAG_TRAP "_$sSa16_createNewBuffer14bufferIsUnique15minimumCapacity13growForAppendySb_SiSbtFyXl_Ts5", 0x404
DIAG_TRAP "_$ss12_ArrayBufferV20_consumeAndCreateNew14bufferIsUnique15minimumCapacity13growForAppendAByxGSb_SiSbtFyXl_Ts5", 0x407
DIAG_TRAP "_$ss22_ContiguousArrayBufferV20_consumeAndCreateNew14bufferIsUnique15minimumCapacity13growForAppendAByxGSb_SiSbtFyXl_Ts5", 0x408
DIAG_TRAP "_$ss12_ArrayBufferV13_copyContents12initializings16IndexingIteratorVyAByxGG_SitSryxG_tFyXl_Ts5", 0x409
