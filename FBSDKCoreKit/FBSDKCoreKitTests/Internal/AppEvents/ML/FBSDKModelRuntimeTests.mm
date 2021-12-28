/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <XCTest/XCTest.h>

#include "FBSDKModelRuntime.hpp"

@interface FBSDKModelRuntimeTests : XCTestCase

@end

@implementation FBSDKModelRuntimeTests

- (void)testReLU
{
  float input_data[2][4] = {
    {-1, -2, 1, 2},
    {1, -0.2, 3.1, -0.5},
  };
  float expected_data[2][4] = {
    {0, 0, 1, 2},
    {1, 0, 3.1, 0},
  };
  fbsdk::MTensor input({2, 4});
  fbsdk::MTensor expected({2, 4});
  memcpy(input.mutable_data(), *input_data, input.count() * sizeof(float));
  memcpy(expected.mutable_data(), *expected_data, expected.count() * sizeof(float));
  fbsdk::relu(input);
  [self AssertEqual:expected input:input];
}

- (void)testFlatten
{
  float input_data[2][2][5] = {
    {
      {1, 2, 3, 4, 5},
      {1, 2, 3, 4, 5},
    },
    {
      {3, 4, 6, 7, 8},
      {6, 7, 8, 9, 10},
    },
  };
  float expected_data[2][10] = {
    {1, 2, 3, 4, 5, 1, 2, 3, 4, 5},
    {3, 4, 6, 7, 8, 6, 7, 8, 9, 10},
  };
  fbsdk::MTensor input({2, 2, 5});
  fbsdk::MTensor expected({2, 10});
  memcpy(input.mutable_data(), **input_data, input.count() * sizeof(float));
  memcpy(expected.mutable_data(), *expected_data, expected.count() * sizeof(float));
  fbsdk::flatten(input, 1);
  [self AssertEqual:expected input:input];
}

- (void)testConcatenate
{
  float tensor1_data[2][2] = {
    {1, 2},
    {3, 4},
  };
  float tensor2_data[2][3] = {
    {3, 4, 5},
    {6, 7, 8},
  };
  float tensor3_data[2][5] = {
    {1, 2, 3, 4, 5},
    {6, 7, 8, 9, 10},
  };
  float expected_data[2][10] = {
    {1, 2, 3, 4, 5, 1, 2, 3, 4, 5},
    {3, 4, 6, 7, 8, 6, 7, 8, 9, 10},
  };
  fbsdk::MTensor tensor1({2, 2});
  fbsdk::MTensor tensor2({2, 3});
  fbsdk::MTensor tensor3({2, 5});
  fbsdk::MTensor expected({2, 10});
  memcpy(tensor1.mutable_data(), *tensor1_data, tensor1.count() * sizeof(float));
  memcpy(tensor2.mutable_data(), *tensor2_data, tensor2.count() * sizeof(float));
  memcpy(tensor3.mutable_data(), *tensor3_data, tensor3.count() * sizeof(float));
  memcpy(expected.mutable_data(), *expected_data, expected.count() * sizeof(float));
  std::vector<fbsdk::MTensor *> concat_tensors{&tensor1, &tensor2, &tensor3};
  [self AssertEqual:expected input:fbsdk::concatenate(concat_tensors)];
}

- (void)testSoftMax
{
  float input_data[2][2] = {
    {1, 1},
    {1, 3},
  };
  float expected_data[2][2] = {
    {0.5, 0.5},
    {0.119, 0.881},
  };
  fbsdk::MTensor input({2, 2});
  fbsdk::MTensor expected({2, 2});
  memcpy(input.mutable_data(), *input_data, input.count() * sizeof(float));
  memcpy(expected.mutable_data(), *expected_data, expected.count() * sizeof(float));
  fbsdk::softmax(input);
  [self AssertEqual:expected input:input];
}

- (void)testEmbedding
{
  char text[] = {"\1\2"};
  float embeddings_data[3][3] = {
    {1, 0, 0},
    {0, 1, 0},
    {0, 0, 1},
  };
  float expected_data[1][2][3] = {
    {
      {0, 1, 0},
      {0, 0, 1},
    },
  };
  fbsdk::MTensor embeddings({3, 3});
  memcpy(embeddings.mutable_data(), *embeddings_data, embeddings.count() * sizeof(float));
  fbsdk::MTensor expected({1, 2, 3});
  memcpy(expected.mutable_data(), **expected_data, expected.count() * sizeof(float));
  [self AssertEqual:expected input:fbsdk::embedding(text, 2, embeddings)];
}

- (void)testDenseExample1
{
  float input_data[2][3] = {{1, 2, 3}, {4, 5, 6}};
  float weight_data[3][2] = {{0, 1}, {1, 0}, {-1, 1}};
  float bias_data[2] = {100, 200};
  float expected_data[2][2] = {{99, 204}, {99, 210}};
  fbsdk::MTensor input({2, 3});
  fbsdk::MTensor weight({3, 2});
  fbsdk::MTensor bias({2});
  fbsdk::MTensor expected({2, 2});
  memcpy(input.mutable_data(), *input_data, input.count() * sizeof(float));
  memcpy(weight.mutable_data(), *weight_data, weight.count() * sizeof(float));
  memcpy(bias.mutable_data(), bias_data, bias.count() * sizeof(float));
  memcpy(expected.mutable_data(), *expected_data, expected.count() * sizeof(float));
  [self AssertEqual:expected input:fbsdk::dense(input, weight, bias)];
}

- (void)testDenseExample2
{
  float input_data[1][2] = {{1, 2}};
  float weight_data[2][3] = {{0, 3, -1}, {1, 0, -2}};
  float bias_data[3] = {100, 200, 5};
  float expected_data[1][3] = {{102, 203, 0}};
  fbsdk::MTensor input({1, 2});
  fbsdk::MTensor weight({2, 3});
  fbsdk::MTensor bias({3});
  fbsdk::MTensor expected({1, 3});
  memcpy(input.mutable_data(), *input_data, input.count() * sizeof(float));
  memcpy(weight.mutable_data(), *weight_data, weight.count() * sizeof(float));
  memcpy(bias.mutable_data(), bias_data, bias.count() * sizeof(float));
  memcpy(expected.mutable_data(), *expected_data, expected.count() * sizeof(float));
  [self AssertEqual:expected input:fbsdk::dense(input, weight, bias)];
}

- (void)testConv1DExample1
{
  float input_data[4][2][3] = {
    {
      {1, 2, 3},
      {4, 5, 6},
    },
    {
      {7, 8, 9},
      {1, 2, 3},
    },
    {
      {3, 2, 1},
      {1, 2, 9},
    },
    {
      {9, 8, 7},
      {4, 5, 6},
    },
  };
  float conv_data[2][3][2] = {
    {
      {-1, 3},
      {5, -7},
      {-9, 9},
    },
    {
      {2, 4},
      {6, 8},
      {10, -10},
    },
  };
  float expected_data[4][1][2] = {
    {{80, 12}},
    {{-4, 36}},
    {{102, -66}},
    {{66, 30}},
  };
  fbsdk::MTensor input({4, 2, 3});
  fbsdk::MTensor conv({2, 3, 2});
  fbsdk::MTensor expected({4, 1, 2});
  memcpy(input.mutable_data(), **input_data, input.count() * sizeof(float));
  memcpy(conv.mutable_data(), **conv_data, conv.count() * sizeof(float));
  memcpy(expected.mutable_data(), **expected_data, expected.count() * sizeof(float));
  [self AssertEqual:expected input:fbsdk::conv1D(input, conv)];
}

- (void)testConv1DExample2
{
  float input_data[1][5][3] = {
    {
      {1, 2, 3},
      {4, 5, 6},
      {9, 8, 7},
      {5, 8, 1},
      {5, 3, 0},
    },
  };
  float conv_data[3][3][4] = {
    {
      {-1, 3, 0, 1},
      {5, -7, 5, 7},
      {-9, 9, 2, 3},
    },
    {
      {2, 4, 5, 6},
      {6, 8, 9, 4},
      {10, -10, 5, 6},
    },
    {
      {1, 0, 5, 6},
      {2, 5, 9, 4},
      {9, 10, 5, 6},
    }
  };
  float expected_data[1][3][4] = {
    {
      {168, 122, 263, 232},
      {133, 111, 291, 253},
      {47, 123, 208, 196},
    }
  };
  fbsdk::MTensor input({1, 5, 3});
  fbsdk::MTensor conv({3, 3, 4});
  fbsdk::MTensor expected({1, 3, 4});
  memcpy(input.mutable_data(), **input_data, input.count() * sizeof(float));
  memcpy(conv.mutable_data(), **conv_data, conv.count() * sizeof(float));
  memcpy(expected.mutable_data(), **expected_data, expected.count() * sizeof(float));
  [self AssertEqual:expected input:fbsdk::conv1D(input, conv)];
}

- (void)testConv1DExample3
{
  float input_data[1][2][3] = {
    {
      {-1, -1, -1},
      {0, 0, 0},
    },
  };
  float conv_data[2][3][2] = {
    {
      {-1, 3},
      {5, -7},
      {-9, 9},
    },
    {
      {2, 4},
      {6, 8},
      {10, -10},
    },
  };
  float expected_data[1][1][2] = {{{5, -5}}};
  fbsdk::MTensor input({1, 2, 3});
  fbsdk::MTensor conv({2, 3, 2});
  fbsdk::MTensor expected({1, 1, 2});
  memcpy(input.mutable_data(), **input_data, input.count() * sizeof(float));
  memcpy(conv.mutable_data(), **conv_data, conv.count() * sizeof(float));
  memcpy(expected.mutable_data(), **expected_data, expected.count() * sizeof(float));
  [self AssertEqual:expected input:fbsdk::conv1D(input, conv)];
}

- (void)testTextVectorizationLessThanMaxLen
{
  char strs[] = {"0123456"};
  const std::vector<int> expected{48, 49, 50, 51, 52, 53, 54, 0, 0, 0};
  const std::vector<int> &res = fbsdk::vectorize(strs, 10);
  XCTAssertEqual(expected, res);
}

- (void)testTextVectorizationLargerThanMaxLen
{
  char strs[] = {"0123456"};
  const std::vector<int> expected{48, 49, 50};
  const std::vector<int> &res = fbsdk::vectorize(strs, 3);
  XCTAssertEqual(expected, res);
}

- (void)testTranspose3D
{
  float input_data[2][3][4] = {
    {
      {0, 1, 2, 3},
      {4, 5, 6, 7},
      {8, 9, 10, 11},
    },
    {
      {12, 13, 14, 15},
      {16, 17, 18, 19},
      {20, 21, 22, 23},
    },
  };
  float expected_data[4][3][2] = {
    {
      {0, 12},
      {4, 16},
      {8, 20},
    },
    {
      {1, 13},
      {5, 17},
      {9, 21},
    },
    {
      {2, 14},
      {6, 18},
      {10, 22},
    },
    {
      {3, 15},
      {7, 19},
      {11, 23},
    },
  };
  fbsdk::MTensor input({2, 3, 4});
  fbsdk::MTensor expected({4, 3, 2});
  memcpy(input.mutable_data(), **input_data, input.count() * sizeof(float));
  memcpy(expected.mutable_data(), **expected_data, expected.count() * sizeof(float));
  [self AssertEqual:expected input:fbsdk::transpose3D(input)];
}

- (void)testTranspose2D
{
  float input_data[3][4] = {
    {0, 1, 2, 3},
    {4, 5, 6, 7},
    {8, 9, 10, 11},
  };
  float expected_data[4][3] = {
    {0, 4, 8},
    {1, 5, 9},
    {2, 6, 10},
    {3, 7, 11},
  };
  fbsdk::MTensor input({3, 4});
  fbsdk::MTensor expected({4, 3});
  memcpy(input.mutable_data(), *input_data, input.count() * sizeof(float));
  memcpy(expected.mutable_data(), *expected_data, expected.count() * sizeof(float));
  [self AssertEqual:expected input:fbsdk::transpose2D(input)];
}

- (void)testAddmv
{
  float input_data[2][3][2] = {
    {
      {0, 12},
      {4, 16},
      {8, 20},
    },
    {
      {1, 13},
      {5, 17},
      {9, 21},
    },
  };
  float bias_data[2] = {1, 2};
  float expected_data[2][3][2] = {
    {
      {1, 14},
      {5, 18},
      {9, 22},
    },
    {
      {2, 15},
      {6, 19},
      {10, 23},
    },
  };
  fbsdk::MTensor input({2, 3, 2});
  fbsdk::MTensor bias({2});
  fbsdk::MTensor expected({2, 3, 2});
  memcpy(input.mutable_data(), **input_data, input.count() * sizeof(float));
  memcpy(bias.mutable_data(), bias_data, bias.count() * sizeof(float));
  memcpy(expected.mutable_data(), **expected_data, expected.count() * sizeof(float));
  fbsdk::addmv(input, bias);
  [self AssertEqual:expected input:input];
}

- (void)testMaxPool1DExample1
{
  float input_data[2][2][3] = {
    {
      {-1, 2, 3},
      {4, -5, 6},
    },
    {
      {7, -8, 9},
      {-10, 11, 12},
    },
  };
  float expected_data[2][1][3] = {
    {{4, 2, 6}},
    {{7, 11, 12}},
  };
  fbsdk::MTensor input({2, 2, 3});
  fbsdk::MTensor expected({2, 1, 3});
  memcpy(input.mutable_data(), **input_data, input.count() * sizeof(float));
  memcpy(expected.mutable_data(), **expected_data, expected.count() * sizeof(float));
  [self AssertEqual:expected input:fbsdk::maxPool1D(input, 2)];
}

- (void)testMaxPool1DExample2
{
  float input_data[2][2][3] = {
    {
      {-1, -2, -3},
      {-4, -5, -6},
    },
    {
      {-7, -8, -9},
      {-10, -11, -12},
    },
  };
  float expected_data[2][1][3] = {
    {{-1, -2, -3}},
    {{-7, -8, -9}},
  };
  fbsdk::MTensor input({2, 2, 3});
  fbsdk::MTensor expected({2, 1, 3});
  memcpy(input.mutable_data(), **input_data, input.count() * sizeof(float));
  memcpy(expected.mutable_data(), **expected_data, expected.count() * sizeof(float));
  [self AssertEqual:expected input:fbsdk::maxPool1D(input, 2)];
}

- (void)testMaxPool1DExample3
{
  float input_data[3][3][4] = {
    {
      {-1, -2, -3, 3},
      {-4, -5, -6, 9},
      {4, 5, 6, 7},
    },
    {
      {-7, -8, -9, 9},
      {-10, -11, -12, 5},
      {4, 5, 6, 7},
    },
    {
      {-7, -8, -9, 0},
      {-10, -11, -12, 2},
      {4, 5, 6, 7},
    },
  };
  float expected_data[3][1][4] = {
    {{4, 5, 6, 9}},
    {{4, 5, 6, 9}},
    {{4, 5, 6, 7}},
  };
  fbsdk::MTensor input({3, 3, 4});
  fbsdk::MTensor expected({3, 1, 4});
  memcpy(input.mutable_data(), **input_data, input.count() * sizeof(float));
  memcpy(expected.mutable_data(), **expected_data, expected.count() * sizeof(float));
  [self AssertEqual:expected input:fbsdk::maxPool1D(input, 3)];
}

- (void)AssertEqual:(const fbsdk::MTensor &)expected
              input:(const fbsdk::MTensor &)input
{
  const std::vector<int> &expected_sizes = expected.sizes();
  const std::vector<int> &input_sizes = input.sizes();
  XCTAssertEqual(expected_sizes, input_sizes);
  const float *expected_data = expected.data();
  const float *input_data = input.data();
  for (int i = 0; i < expected.count(); i++) {
    XCTAssertEqualWithAccuracy(expected_data[i], input_data[i], 0.01);
  }
}

@end
