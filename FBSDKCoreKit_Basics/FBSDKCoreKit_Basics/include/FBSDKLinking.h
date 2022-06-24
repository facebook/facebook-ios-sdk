/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

// These macros exist to allow templates to substitute names of the class and category
#define FB_LINK_CATEGORY_INTERFACE(CLASS, CATEGORY) FB_LINK_REQUIRE_CATEGORY(CLASS ## _ ## CATEGORY)
#define FB_LINK_CATEGORY_IMPLEMENTATION(CLASS, CATEGORY) FB_LINKABLE(CLASS ## _ ## CATEGORY)

#if !TARGET_OS_TV && !defined(FB_LINK_REQUIRE_DISABLE_I_KNOW_WHAT_I_AM_DOING)
// DO NOT USE this macro directly, use FB_LINK_REQUIRE_CATEGORY.
 #define FB_LINK_REQUIRE_(NAME) \
  extern char FBLinkable_ ## NAME; \
  extern const void *_Nonnull const OS_WEAK OS_CONCAT(FBLink_, NAME); \
  OS_USED const void *_Nonnull const OS_WEAK OS_CONCAT(FBLink_, NAME) = &FBLinkable_ ## NAME;

// Annotate category @implementation definitions with this macro.
 #ifdef DEBUG
  #define FB_LINKABLE(NAME) \
  __attribute__((used)) __attribute__((visibility("default"))) char FBLinkable_ ## NAME = 'L';
 #else
  #define FB_LINKABLE(NAME) \
  __attribute__((visibility("default"))) char FBLinkable_ ## NAME = 'L';
 #endif

// Annotate category @interface declarations with this macro.
 #define FB_LINK_REQUIRE_CATEGORY(NAME) \
  FB_LINK_REQUIRE_(NAME)

// Annotate class @interface declarations with this macro if they are getting dropped by dead stripping due to a lack of static references.
 #define FB_LINK_REQUIRE_CLASS(NAME) \
  FB_LINK_REQUIRE_(NAME) \
  extern void *OBJC_CLASS_$_ ## NAME; \
  extern const void *const OS_WEAK OS_CONCAT(FBLinkClass_, NAME); \
  OS_USED const void *const OS_WEAK OS_CONCAT(FBLinkClass_, NAME) = (void *)&OBJC_CLASS_$_ ## NAME;

// Annotate class @implementations with this macro if you know they
// will have a lack of static references or even header imports and
// you have ensured that the containing implementation will be linked
// by other means (e.g., other used classes in the same file.
 #define FB_DONT_DEAD_STRIP_CLASS(NAME) \
  asm (".no_dead_strip _OBJC_CLASS_$_" #NAME);

#else

 #define FB_LINK_REQUIRE_(NAME)
 #define FB_LINKABLE(NAME)
 #define FB_LINK_REQUIRE_CATEGORY(NAME)
 #define FB_LINK_REQUIRE_CLASS(NAME)
 #define FB_DONT_DEAD_STRIP_CLASS(NAME)

#endif
