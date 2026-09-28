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

// iOS 17+ UIKit trait-change registration compatibility.
// iOS 16 does not provide UIViewController.registerForTraitChanges.
// Returning nil makes registration a no-op; callers may safely retain/release
// or message the returned Objective-C protocol object as nil.
.globl "_$sSo16UIViewControllerC5UIKitE23registerForTraitChanges_7handlerSo25UITraitChangeRegistration_pSayAC0I10Definition_pXpG_yx_So0I10CollectionCtctSo0I11EnvironmentRzlF"
"_$sSo16UIViewControllerC5UIKitE23registerForTraitChanges_7handlerSo25UITraitChangeRegistration_pSayAC0I10Definition_pXpG_yx_So0I10CollectionCtctSo0I11EnvironmentRzlF":
    mov x0, xzr
    ret

.globl "_$sSo16UIViewControllerC5UIKitE23registerForTraitChanges_6actionSo25UITraitChangeRegistration_pSayAC0I10Definition_pXpG_10ObjectiveC8SelectorVtF"
"_$sSo16UIViewControllerC5UIKitE23registerForTraitChanges_6actionSo25UITraitChangeRegistration_pSayAC0I10Definition_pXpG_10ObjectiveC8SelectorVtF":
    mov x0, xzr
    ret

// iOS 17+ trait-definition metadata compatibility
// These newer UIKit trait-definition types do not exist on iOS 16.
// The registration APIs are shimmed as no-ops, so the callers only need
// valid Swift metadata/witness placeholders while constructing arguments.

// Reuse a real Swift protocol descriptor for the otherwise unavailable
// UITraitDefinition existential metadata.
.section __DATA,__data
.p2align 3
.globl "_$s5UIKit17UITraitDefinitionMp"
"_$s5UIKit17UITraitDefinitionMp":
    .quad 0, 0, 0, 0

.text
.p2align 2

// Metadata accessors: expose Int metadata (single-word value semantics are
// sufficient for these trait-definition metatypes because the registration
// functions never inspect them).
.text
.p2align 2

.globl "_$s5UIKit26UITraitHorizontalSizeClassVMa"
"_$s5UIKit26UITraitHorizontalSizeClassVMa":
    adrp x0, "_$sSiN"@GOTPAGE
    ldr  x0, [x0, "_$sSiN"@GOTPAGEOFF]
    mov  x1, xzr
    ret

.globl "_$s5UIKit24UITraitVerticalSizeClassVMa"
"_$s5UIKit24UITraitVerticalSizeClassVMa":
    adrp x0, "_$sSiN"@GOTPAGE
    ldr  x0, [x0, "_$sSiN"@GOTPAGEOFF]
    mov  x1, xzr
    ret

.globl "_$s5UIKit25UITraitUserInterfaceStyleVMa"
"_$s5UIKit25UITraitUserInterfaceStyleVMa":
    adrp x0, "_$sSiN"@GOTPAGE
    ldr  x0, [x0, "_$sSiN"@GOTPAGEOFF]
    mov  x1, xzr
    ret

.globl "_$s5UIKit23UITraitLegibilityWeightVMa"
"_$s5UIKit23UITraitLegibilityWeightVMa":
    adrp x0, "_$sSiN"@GOTPAGE
    ldr  x0, [x0, "_$sSiN"@GOTPAGEOFF]
    mov  x1, xzr
    ret

.globl "_$s5UIKit16UITraitOverridesVMa"
"_$s5UIKit16UITraitOverridesVMa":
    adrp x0, "_$sSiN"@GOTPAGE
    ldr  x0, [x0, "_$sSiN"@GOTPAGEOFF]
    mov  x1, xzr
    ret

// UITraitOverrides operations are unavailable before iOS 17.
// Return an empty word from the getter and ignore mutations.
.globl "_$sSo6UIViewC5UIKitE14traitOverridesAC07UITraitD0Vvg"
"_$sSo6UIViewC5UIKitE14traitOverridesAC07UITraitD0Vvg":
    mov x0, xzr
    ret

.globl "_$sSo6UIViewC5UIKitE14traitOverridesAC07UITraitD0Vvs"
"_$sSo6UIViewC5UIKitE14traitOverridesAC07UITraitD0Vvs":
    ret

.globl "_$s5UIKit16UITraitOverridesV6removeyyAA0B10Definition_pXpF"
"_$s5UIKit16UITraitOverridesV6removeyyAA0B10Definition_pXpF":
    ret

// Instance self for this Swift extension is carried in x20.
// Preserve the current collection while ignoring the iOS 17 mutable-traits
// closure. objc_retain gives the returned object normal owned lifetime.
.globl "_$sSo17UITraitCollectionC5UIKitE15modifyingTraitsyAByAC09UIMutableE0_pzXEF"
"_$sSo17UITraitCollectionC5UIKitE15modifyingTraitsyAByAC09UIMutableE0_pzXEF":
    mov x0, x20
    ret

// The witness-table values are only packaged into trait-definition existential
// arguments which are consumed by our no-op registration shims.
.section __DATA,__data
.p2align 3

.globl "_$s5UIKit26UITraitHorizontalSizeClassVAA0B10DefinitionAAWP"
"_$s5UIKit26UITraitHorizontalSizeClassVAA0B10DefinitionAAWP":
    .quad 0, 0, 0, 0

.globl "_$s5UIKit24UITraitVerticalSizeClassVAA0B10DefinitionAAWP"
"_$s5UIKit24UITraitVerticalSizeClassVAA0B10DefinitionAAWP":
    .quad 0, 0, 0, 0

.globl "_$s5UIKit25UITraitUserInterfaceStyleVAA0B10DefinitionAAWP"
"_$s5UIKit25UITraitUserInterfaceStyleVAA0B10DefinitionAAWP":
    .quad 0, 0, 0, 0

.globl "_$s5UIKit23UITraitLegibilityWeightVAA0B10DefinitionAAWP"
"_$s5UIKit23UITraitLegibilityWeightVAA0B10DefinitionAAWP":
    .quad 0, 0, 0, 0

.globl "_$s5UIKit16UITraitOverridesVAA15UIMutableTraitsAAWP"
"_$s5UIKit16UITraitOverridesVAA15UIMutableTraitsAAWP":
    .quad 0, 0, 0, 0

// iOS 18 popover source-item compatibility
// UIPopoverPresentationControllerSourceItem.frame(in:) is unavailable on iOS 16.
// CGRect? has a 32-byte CGRect payload plus a single-payload enum tag.
// Return .none so callers fall back to legacy sourceView/sourceRect handling.
.text
.p2align 2
.globl "_$sSo41UIPopoverPresentationControllerSourceItemP5UIKitE5frame2inSo6CGRectVSgSo6UIViewC_tF"
"_$sSo41UIPopoverPresentationControllerSourceItemP5UIKitE5frame2inSo6CGRectVSgSo6UIViewC_tF":
    stp xzr, xzr, [x8]
    stp xzr, xzr, [x8, #16]
    mov w9, #1
    strb w9, [x8, #32]
    ret

// Opaque-result descriptor aliases for back-deployed SwiftUI onChange
// The wrapper implementations are compiled in the CompatSwiftCore module,
// while Carbon imports the opaque descriptors using SwiftUI's ABI names.
// Alias those public ABI names to the descriptors generated for our wrappers.
.globl "_$s7SwiftUI4ViewPAAE8onChange2of7initial_Qrqd___Sbyqd___qd__tctSQRd__lFQOMQ"
.set "_$s7SwiftUI4ViewPAAE8onChange2of7initial_Qrqd___Sbyqd___qd__tctSQRd__lFQOMQ", "_$s7SwiftUI4ViewP06CompatA4CoreE15ub_onChangePair2of7initial_Qrqd___Sbyqd___qd__tctSQRd__lFQOMQ"

.globl "_$s7SwiftUI4ViewPAAE8onChange2of7initial_Qrqd___SbyyctSQRd__lFQOMQ"
.set "_$s7SwiftUI4ViewPAAE8onChange2of7initial_Qrqd___SbyyctSQRd__lFQOMQ", "_$s7SwiftUI4ViewP06CompatA4CoreE15ub_onChangeZero2of7initial_Qrqd___SbyyctSQRd__lFQOMQ"

// Observation module metadata aliases for iOS 16
// CompatObservation.swift supplies a minimal ABI-compatible registrar and an
// empty observable protocol. Export their metadata using the names Carbon was
// linked against from the iOS 17+ Observation module.

.globl "_$s11Observation0A9RegistrarVMa"
.set "_$s11Observation0A9RegistrarVMa", "_$s15CompatSwiftCore22UBObservationRegistrarVMa"

.globl "_$s11Observation0A9RegistrarVMn"
.set "_$s11Observation0A9RegistrarVMn", "_$s15CompatSwiftCore22UBObservationRegistrarVMn"

.globl "_$s11Observation10ObservableMp"
.set "_$s11Observation10ObservableMp", "_$s15CompatSwiftCore12UBObservableMp"

// SwiftUI Bindable metadata aliases for iOS 16
.globl "_$s7SwiftUI8BindableVMa"
.set "_$s7SwiftUI8BindableVMa", "_$s15CompatSwiftCore10UBBindableVMa"

.globl "_$s7SwiftUI8BindableVMn"
.set "_$s7SwiftUI8BindableVMn", "_$s15CompatSwiftCore10UBBindableVMn"

// SwiftUI StrokeShapeView ABI aliases for iOS 16
// Carbon imports the iOS 17+ SwiftUI type metadata and View conformance.
// CompatStrokeShape.swift reproduces the frozen one-field layout using iOS 16
// SwiftUI building blocks, so expose its metadata under Apple's ABI names.
.globl "_$s7SwiftUI15StrokeShapeViewVMa"
.set "_$s7SwiftUI15StrokeShapeViewVMa", "_$s15CompatSwiftCore17UBStrokeShapeViewVMa"

.globl "_$s7SwiftUI15StrokeShapeViewVMn"
.set "_$s7SwiftUI15StrokeShapeViewVMn", "_$s15CompatSwiftCore17UBStrokeShapeViewVMn"

.globl "_$s7SwiftUI15StrokeShapeViewVyxq_q0_GAA0E0AAMc"
.set "_$s7SwiftUI15StrokeShapeViewVyxq_q0_GAA0E0AAMc", "_$s15CompatSwiftCore17UBStrokeShapeViewVyxq_q0_G7SwiftUI4ViewAAMc"

