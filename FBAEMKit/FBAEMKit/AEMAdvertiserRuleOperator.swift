/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

enum AEMAdvertiserRuleOperator: Int {
  case unknown = 0
  // Multi Entry Rule Operator
  case and
  // swiftlint:disable:next identifier_name
  case or
  case not
  // Single Entry Rule Operator
  case contains
  case notContains
  case startsWith
  case caseInsensitiveContains
  case caseInsensitiveNotContains
  case caseInsensitiveStartsWith
  case regexMatch
  case equal
  case notEqual
  case lessThan
  case lessThanOrEqual
  case greaterThan
  case greaterThanOrEqual
  case caseInsensitiveIsAny
  case caseInsensitiveIsNotAny
  case isAny
  case isNotAny
}
