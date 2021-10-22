/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import "FBSDKCodelessPathComponent.h"

#import "FBSDKViewHierarchyMacros.h"

@implementation FBSDKCodelessPathComponent

- (instancetype)initWithJSON:(NSDictionary<NSString *, id> *)dict
{
  if ((self = [super init])) {
    _className = [dict[CODELESS_MAPPING_CLASS_NAME_KEY] copy];
    _text = [dict[CODELESS_MAPPING_TEXT_KEY] copy];
    _hint = [dict[CODELESS_MAPPING_HINT_KEY] copy];
    _desc = [dict[CODELESS_MAPPING_DESC_KEY] copy];

    if (dict[CODELESS_MAPPING_INDEX_KEY]) {
      _index = [dict[CODELESS_MAPPING_INDEX_KEY] intValue];
    } else {
      _index = -1;
    }

    if (dict[CODELESS_MAPPING_SECTION_KEY]) {
      _section = [dict[CODELESS_MAPPING_SECTION_KEY] intValue];
    } else {
      _section = -1;
    }

    if (dict[CODELESS_MAPPING_ROW_KEY]) {
      _row = [dict[CODELESS_MAPPING_ROW_KEY] intValue];
    } else {
      _row = -1;
    }

    _tag = [dict[CODELESS_MAPPING_TAG_KEY] intValue];
    _matchBitmask = [dict[CODELESS_MAPPING_MATCH_BITMASK_KEY] intValue];
  }

  return self;
}

- (BOOL)isEqualToPath:(FBSDKCodelessPathComponent *)path
{
  NSString *current = [NSString stringWithFormat:@"%@|%@|%@|%@|%d|%d|%d|%d|%d",
                       _className ?: @"",
                       _text ?: @"",
                       _hint ?: @"",
                       _desc ?: @"",
                       _index, _section, _row, _tag, _matchBitmask];
  NSString *compared = [NSString stringWithFormat:@"%@|%@|%@|%@|%d|%d|%d|%d|%d",
                        path.className ?: @"",
                        path.text ?: @"",
                        path.hint ?: @"",
                        path.desc ?: @"",
                        path.index, path.section, path.row, path.tag, path.matchBitmask];
  return [current isEqualToString:compared];
}

@end

#endif
