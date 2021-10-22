/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

typedef enum {
  RPSCallNone = -1,
  RPSCallRock = 0,
  RPSCallPaper = 1,
  RPSCallScissors = 2, // enum is also used to index arrays
} RPSCall;

typedef enum {
  RPSResultWin = 0,
  RPSResultLoss = 1,
  RPSResultTie = 2,
} RPSResult;

extern NSString *builtInOpenGraphObjects[3];
