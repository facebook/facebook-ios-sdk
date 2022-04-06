/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <TargetConditionals.h>

#if !TARGET_OS_TV

/**
 Internal Type exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.

 @warning INTERNAL - DO NOT USE
 */
typedef NS_CLOSED_ENUM (NSInteger, FBAEMAdvertiserRuleOperator)
{
  FBAEMAdvertiserRuleOperatorUnknown = 0,
  // Multi Entry Rule Operator
  FBAEMAdvertiserRuleOperatorAnd,
  FBAEMAdvertiserRuleOperatorOr,
  FBAEMAdvertiserRuleOperatorNot,
  // Single Entry Rule Operator
  FBAEMAdvertiserRuleOperatorContains,
  FBAEMAdvertiserRuleOperatorNotContains,
  FBAEMAdvertiserRuleOperatorStartsWith,
  FBAEMAdvertiserRuleOperatorCaseInsensitiveContains,
  FBAEMAdvertiserRuleOperatorCaseInsensitiveNotContains,
  FBAEMAdvertiserRuleOperatorCaseInsensitiveStartsWith,
  FBAEMAdvertiserRuleOperatorRegexMatch,
  FBAEMAdvertiserRuleOperatorEqual,
  FBAEMAdvertiserRuleOperatorNotEqual,
  FBAEMAdvertiserRuleOperatorLessThan,
  FBAEMAdvertiserRuleOperatorLessThanOrEqual,
  FBAEMAdvertiserRuleOperatorGreaterThan,
  FBAEMAdvertiserRuleOperatorGreaterThanOrEqual,
  FBAEMAdvertiserRuleOperatorCaseInsensitiveIsAny,
  FBAEMAdvertiserRuleOperatorCaseInsensitiveIsNotAny,
  FBAEMAdvertiserRuleOperatorIsAny,
  FBAEMAdvertiserRuleOperatorIsNotAny
} NS_SWIFT_NAME(_AEMAdvertiserRuleOperator);

#endif
