.text
.p2align 2

// iOS 16 compatibility shims for Swift AnyObject pre-specializations
// emitted by the newer Uber Driver build.

// AnyObject append specialization.
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

// Supply AnyObject metadata and tail-call generic entry points that
// exist in the older Swift runtime.
.globl "_$ss15ContiguousArrayV034_makeUniqueAndReserveCapacityIfNotD0yyFyXl_Ts5"
"_$ss15ContiguousArrayV034_makeUniqueAndReserveCapacityIfNotD0yyFyXl_Ts5":
    adrp x0, "_$syXlN"@GOTPAGE
    ldr  x0, [x0, "_$syXlN"@GOTPAGEOFF]
    b "_$ss15ContiguousArrayV034_makeUniqueAndReserveCapacityIfNotD0yyF"

.globl "_$ss15ContiguousArrayV15reserveCapacityyySiFyXl_Ts5"
"_$ss15ContiguousArrayV15reserveCapacityyySiFyXl_Ts5":
    adrp x1, "_$syXlN"@GOTPAGE
    ldr  x1, [x1, "_$syXlN"@GOTPAGEOFF]
    b "_$ss15ContiguousArrayV15reserveCapacityyySiF"

.globl "_$ss15ContiguousArrayV36_reserveCapacityAssumingUniqueBuffer8oldCountySi_tFyXl_Ts5"
"_$ss15ContiguousArrayV36_reserveCapacityAssumingUniqueBuffer8oldCountySi_tFyXl_Ts5":
    adrp x1, "_$syXlN"@GOTPAGE
    ldr  x1, [x1, "_$syXlN"@GOTPAGEOFF]
    b "_$ss15ContiguousArrayV36_reserveCapacityAssumingUniqueBuffer8oldCountySi_tF"

.globl "_$sSa034_makeUniqueAndReserveCapacityIfNotB0yyFyXl_Ts5"
"_$sSa034_makeUniqueAndReserveCapacityIfNotB0yyFyXl_Ts5":
    adrp x0, "_$syXlN"@GOTPAGE
    ldr  x0, [x0, "_$syXlN"@GOTPAGEOFF]
    b "_$sSa034_makeUniqueAndReserveCapacityIfNotB0yyF"

// Adapt the remaining AnyObject pre-specializations to their generic
// iOS 16 Swift runtime entry points. Register placement is the Swift ABI:
// metadata is appended after the explicit/self value arguments.
.globl "_$ss12_ArrayBufferV19_getElementSlowPathyyXlSiFyXl_Ts5"
"_$ss12_ArrayBufferV19_getElementSlowPathyyXlSiFyXl_Ts5":
    adrp x2, "_$syXlN"@GOTPAGE
    ldr  x2, [x2, "_$syXlN"@GOTPAGEOFF]
    b "_$ss12_ArrayBufferV19_getElementSlowPathyyXlSiF"

.globl "_$sSa16_createNewBuffer14bufferIsUnique15minimumCapacity13growForAppendySb_SiSbtFyXl_Ts5"
"_$sSa16_createNewBuffer14bufferIsUnique15minimumCapacity13growForAppendySb_SiSbtFyXl_Ts5":
    brk #0x404
    ret

.globl "_$ss12_ArrayBufferV20_consumeAndCreateNew14bufferIsUnique15minimumCapacity13growForAppendAByxGSb_SiSbtFyXl_Ts5"
"_$ss12_ArrayBufferV20_consumeAndCreateNew14bufferIsUnique15minimumCapacity13growForAppendAByxGSb_SiSbtFyXl_Ts5":
    brk #0x407
    ret

.globl "_$ss22_ContiguousArrayBufferV20_consumeAndCreateNew14bufferIsUnique15minimumCapacity13growForAppendAByxGSb_SiSbtFyXl_Ts5"
"_$ss22_ContiguousArrayBufferV20_consumeAndCreateNew14bufferIsUnique15minimumCapacity13growForAppendAByxGSb_SiSbtFyXl_Ts5":
    brk #0x408
    ret

.globl "_$ss12_ArrayBufferV13_copyContents12initializings16IndexingIteratorVyAByxGG_SitSryxG_tFyXl_Ts5"
"_$ss12_ArrayBufferV13_copyContents12initializings16IndexingIteratorVyAByxGG_SitSryxG_tFyXl_Ts5":
    adrp x3, "_$syXlN"@GOTPAGE
    ldr  x3, [x3, "_$syXlN"@GOTPAGEOFF]
    b "_$ss12_ArrayBufferV13_copyContents12initializings16IndexingIteratorVyAByxGG_SitSryxG_tF"
