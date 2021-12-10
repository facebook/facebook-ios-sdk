/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "TargetConditionals.h"

#if !TARGET_OS_TV

typedef NS_CLOSED_ENUM (NSInteger, FBAEMAdvertiserRuleOperator)
{
  Unknown = 0,
  // Multi Entry Rule Operator
  FBAEMAdvertiserRuleOperatorAnd,
  FBAEMAdvertiserRuleOperatorOr,
  FBAEMAdvertiserRuleOperatorNot,
  // Single Entry Rule Operator
  FBAEMAdvertiserRuleOperatorContains,
  FBAEMAdvertiserRuleOperatorNotContains,
  FBAEMAdvertiserRuleOperatorStartsWith,
  FBAEMAdvertiserRuleOperatorI_Contains,
  FBAEMAdvertiserRuleOperatorI_NotContains,
  FBAEMAdvertiserRuleOperatorI_StartsWith,
  FBAEMAdvertiserRuleOperatorRegexMatch,
  FBAEMAdvertiserRuleOperatorEqual,
  FBAEMAdvertiserRuleOperatorNotEqual,
  FBAEMAdvertiserRuleOperatorLessThan,
  FBAEMAdvertiserRuleOperatorLessThanOrEqual,
  FBAEMAdvertiserRuleOperatorGreaterThan,
  FBAEMAdvertiserRuleOperatorGreaterThanOrEqual,
  FBAEMAdvertiserRuleOperatorI_IsAny,
  FBAEMAdvertiserRuleOperatorI_IsNotAny,
  FBAEMAdvertiserRuleOperatorIsAny,
  FBAEMAdvertiserRuleOperatorIsNotAny
} NS_SWIFT_NAME(AEMAdvertiserRuleOperator);

#endif
