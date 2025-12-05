#import <Foundation/Foundation.h>

#if __has_attribute(swift_private)
#define AC_SWIFT_PRIVATE __attribute__((swift_private))
#else
#define AC_SWIFT_PRIVATE
#endif

/// The "NEXO LOGO" asset catalog image resource.
static NSString * const ACImageName_NEXO_LOGO AC_SWIFT_PRIVATE = @"NEXO LOGO";

/// The "Screenshot_2025-11-03_at_9.46.50_AM-removebg-preview" asset catalog image resource.
static NSString * const ACImageNameScreenshot20251103At94650AMRemovebgPreview AC_SWIFT_PRIVATE = @"Screenshot_2025-11-03_at_9.46.50_AM-removebg-preview";

#undef AC_SWIFT_PRIVATE
