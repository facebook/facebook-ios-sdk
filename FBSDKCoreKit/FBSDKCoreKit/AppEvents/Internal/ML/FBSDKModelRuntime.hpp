// Copyright (c) 2014-present, Facebook, Inc. All rights reserved.
//
// You are hereby granted a non-exclusive, worldwide, royalty-free license to use,
// copy, modify, and distribute this software in source code or binary form for use
// in connection with the web services and APIs provided by Facebook.
//
// As with any software that integrates with the Facebook platform, your use of
// this software is subject to the Facebook Developer Principles and Policies
// [http://developers.facebook.com/policy/]. This copyright notice shall be
// included in all copies or substantial portions of the software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
// IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#import "TargetConditionals.h"

#if !TARGET_OS_TV

#include <float.h>
#include <math.h>
#include <stdint.h>
#include <unordered_map>

#import <Accelerate/Accelerate.h>

#include "FBSDKTensor.hpp"

#define SEQ_LEN 128
#define ALPHABET_SIZE 256
#define MTML_EMBEDDING_SIZE 32
#define NON_MTML_EMBEDDING_SIZE 64
#define DENSE_FEATURE_LEN 30

namespace fbsdk {

static void relu(float *data, const int len) {
  float min = 0;
  float max = FLT_MAX;
  vDSP_vclip(data, 1, &min, &max, data, 1, len);
}

static void concatenate(float *dst, const float *a, const float *b, const int a_len, const int b_len) {
  memcpy(dst, a, a_len * sizeof(float));
  memcpy(dst + a_len, b, b_len * sizeof(float));
}

static void softmax(float *data, const int n) {
  int i = 0;
  float max = FLT_MIN;
  float sum = 0;

  for (i = 0; i < n; i++) {
    if (data[i] > max) {
      max = data[i];
    }
  }

  for (i = 0; i < n; i++){
    data[i] = expf(data[i] - max);
  }

  for (i = 0; i < n; i++){
    sum += data[i];
  }

  for (i = 0; i < n; i++){
    data[i] = data[i] / sum;
  }
}

static std::vector<int> vectorize(const char *texts, const int seq_length) {
  int str_len = (int)strlen(texts);
  std::vector<int> vec(seq_length, 0);
  for (int i = 0; i < seq_length; i++) {
    if (i < str_len){
      vec[i] = static_cast<unsigned char>(texts[i]);
    }
  }
  return vec;
}

static MTensor embedding(const char *texts, const int seq_length, const MTensor& w) {
  // TODO: T65152708 support batch prediction
  const std::vector<int>& vec = vectorize(texts, seq_length);
  int64_t n_examples = 1;
  int64_t embedding_size = w.size(1);
  MTensor y({n_examples, seq_length, embedding_size});
  const float* w_data = w.data();
  float *y_data = y.mutable_data();
  for (int i = 0; i < n_examples; i++) {
    for (int j = 0; j < seq_length; j++) {
      memcpy(y_data, w_data + vec[i * seq_length + j] * embedding_size, (size_t)(embedding_size * sizeof(float)));
      y_data += embedding_size;
    }
  }
  return y;
}

/*
 a shape: n_examples, in_vector_size
 b shape: n_examples, out_vector_size
 c shape: out_vector_size
 return shape: n_examples, out_vector_size
 */
static float* dense(const float *a, const float *b, const float *c, const int n_examples, const int in_vector_size, const int out_vector_size) {
  int i,j;
  float *m_res = (float *)malloc(sizeof(float) * (n_examples * out_vector_size));
  vDSP_mmul(a, 1, b, 1, m_res, 1, n_examples, out_vector_size, in_vector_size);
  for (i = 0; i < n_examples; i++) {
    for (j = 0; j < out_vector_size; j++) {
      m_res[i * out_vector_size + j] += c[j];
    }
  }
  return m_res;
}

/*
 x shape: n_examples, seq_len, input_size
 w shape: kernel_size, input_size, output_size
 return shape: n_examples, seq_len - kernel_size + 1, output_size
 */
static MTensor conv1D(const MTensor& x, const MTensor& w) {
  int64_t n_examples = x.size(0);
  int64_t seq_len = x.size(1);
  int64_t input_size = x.size(2);
  int64_t kernel_size = w.size(0);
  int64_t output_size = w.size(2);
  MTensor y({n_examples, seq_len - kernel_size + 1, output_size});
  MTensor temp_x({kernel_size, input_size});
  MTensor temp_w({kernel_size, input_size});
  const float *x_data = x.data();
  const float *w_data = w.data();
  float *y_data = y.mutable_data();
  float *temp_x_data = temp_x.mutable_data();
  float *temp_w_data = temp_w.mutable_data();
  float sum;
  for (int n = 0; n < n_examples; n++){
    for (int o = 0; o < output_size; o++){
      for (int i = 0; i < seq_len - kernel_size + 1; i++) {
        for (int m = 0; m < kernel_size; m++) {
          for (int k = 0; k < input_size; k++) {
            temp_x_data[m * input_size + k] = x_data[n * (seq_len * input_size) + (m + i) * input_size + k];
            temp_w_data[m * input_size + k] = w_data[(m * input_size + k) * output_size + o];
          }
        }
        vDSP_dotpr(temp_x_data, 1, temp_w_data, 1, &sum, (size_t)(kernel_size * input_size));
        y_data[(n * (output_size * (seq_len - kernel_size + 1)) + i * output_size + o)] = sum;
      }
    }
  }
  return y;
}

/*
 input shape: n_examples, len, n_channel
 return shape: n_examples, len - pool_size + 1, n_channel
 */
static MTensor maxPool1D(const MTensor& x, const int pool_size) {
  int64_t n_examples = x.size(0);
  int64_t input_len = x.size(1);
  int64_t n_channel = x.size(2);
  int64_t output_len = input_len - pool_size + 1;
  MTensor y({n_examples, output_len, n_channel});
  const float *x_data = x.data();
  float *y_data = y.mutable_data();
  for (int n = 0; n < n_examples; n++) {
    for (int c = 0; c < n_channel; c++) {
      for (int i  = 0; i < output_len; i++) {
        float this_max = -FLT_MAX;
        for (int r = i; r < i + pool_size; r++) {
          this_max = fmax(this_max, x_data[n * (n_channel * input_len) + r * n_channel + c]);
        }
        y_data[n * (n_channel * output_len) + i * n_channel + c] = this_max;
      }
    }
  }
  return y;
}

/*
 input shape: m, n
 return shape: n, m
 */
static MTensor transpose2D(const MTensor& x) {
  int64_t m = x.size(0);
  int64_t n = x.size(1);
  MTensor y({n, m});

  float *y_data = y.mutable_data();
  const float *x_data = x.data();
  for (int i = 0; i < m; i++){
    for (int j = 0; j < n; j++) {
      y_data[j * m + i] = x_data[i * n + j];
    }
  }
  return y;
}

/*
 input shape: m, n, p
 return shape: p, n, m
 */
static MTensor transpose3D(const MTensor& x) {
  int64_t m = x.size(0);
  int64_t n = x.size(1);
  int64_t p = x.size(2);
  MTensor y({p, n, m});

  float *y_data = y.mutable_data();
  const float *x_data = x.data();
  for (int i = 0; i < m; i++){
    for (int j = 0; j < n; j++) {
      for (int k = 0; k < p; k++) {
        y_data[k * m * n + j * m + i] = x_data[i * n * p + j * p + k];
      }
    }
  }
  return y;
}

static float* add(float *a, const float *b, const int m, const int n, const int p) {
  for(int i = 0; i < m * n; i++){
    for(int j = 0; j < p; j++){
      a[i * p + j] += b[j];
    }
  }
  return a;
}

static float* predictOnMTML(const std::string task, const char *texts, const std::unordered_map<std::string, MTensor>& weights, const float *df) {
  int c0_shape, c1_shape, c2_shape;
  float *dense1_x, *dense2_x;
  float *final_layer_dense_x;
  std::string final_layer_weight_key = task + ".weight";
  std::string final_layer_bias_key = task + ".bias";

  const MTensor& embed_t = weights.at("embed.weight");
  const MTensor& conv0w_t = weights.at("convs.0.weight");
  const MTensor& conv1w_t = weights.at("convs.1.weight");
  const MTensor& conv2w_t = weights.at("convs.2.weight");
  const MTensor& conv0b_t = weights.at("convs.0.bias");
  const MTensor& conv1b_t = weights.at("convs.1.bias");
  const MTensor& conv2b_t = weights.at("convs.2.bias");
  const MTensor& fc1w_t = weights.at("fc1.weight"); // (128, 190)
  const MTensor& fc1b_t = weights.at("fc1.bias"); // 128
  const MTensor& fc2w_t = weights.at("fc2.weight"); // (64, 128)
  const MTensor& fc2b_t = weights.at("fc2.bias"); // 64
  const MTensor& final_layer_weight_t = weights.at(final_layer_weight_key); // (2, 64) or (5, 64)
  const MTensor& final_layer_bias_t = weights.at(final_layer_bias_key); // 2 or 5

  const MTensor& convs_0_weight = transpose3D(conv0w_t);
  const MTensor& convs_1_weight = transpose3D(conv1w_t);
  const MTensor& convs_2_weight = transpose3D(conv2w_t);
  const float *convs_0_bias = conv0b_t.data();
  const float *convs_1_bias = conv1b_t.data();
  const float *convs_2_bias = conv2b_t.data();
  const MTensor& fc1_weight = transpose2D(fc1w_t);
  const MTensor& fc2_weight = transpose2D(fc2w_t);
  const MTensor& final_layer_weight = transpose2D(final_layer_weight_t);
  const float *fc1_bias = fc1b_t.data();
  const float *fc2_bias = fc2b_t.data();
  const float *final_layer_bias = final_layer_bias_t.data();

  // embedding
  const MTensor& embed_x = embedding(texts, SEQ_LEN, embed_t);

  // conv0
  MTensor c0 = conv1D(embed_x, convs_0_weight); // (1, 126, 32)
  c0_shape = (int)(SEQ_LEN - conv0w_t.size(2) + 1);
  add(c0.mutable_data(), convs_0_bias, 1, c0_shape, (int)conv0w_t.size(0));
  relu(c0.mutable_data(), c0_shape * (int)conv0w_t.size(0));

  // conv1
  MTensor c1 = conv1D(c0, convs_1_weight); // (1, 124, 64)
  c1_shape = (int)(c0_shape - conv1w_t.size(2) + 1);
  add(c1.mutable_data(), convs_1_bias, 1, c1_shape, (int)conv1w_t.size(0));
  relu(c1.mutable_data(), c1_shape * (int)conv1w_t.size(0));
  c1 = maxPool1D(c1, 2); // (1, 123, 64)
  c1_shape = c1_shape - 1;

  // conv2
  MTensor c2 = conv1D(c1, convs_2_weight); // (1, 121, 64)
  c2_shape = (int)(c1_shape - conv2w_t.size(2) + 1);
  add(c2.mutable_data(), convs_2_bias, 1, c2_shape, (int)conv2w_t.size(0));
  relu(c2.mutable_data(), c2_shape * (int)conv2w_t.size(0));

  // max pooling
  MTensor ca = maxPool1D(c0, c0_shape);
  MTensor cb = maxPool1D(c1, c1_shape);
  MTensor cc = maxPool1D(c2, c2_shape);

  // concatenate
  float *concat = (float *)malloc((size_t)(sizeof(float) * (conv0w_t.size(0) + conv1w_t.size(0) + conv2w_t.size(0) + 30)));
  concatenate(concat, ca.data(), cb.data(), (int)conv0w_t.size(0), (int)conv1w_t.size(0));
  concatenate(concat + conv0w_t.size(0) + conv1w_t.size(0), cc.data(), df, (int)conv2w_t.size(0), 30);

  // dense + relu
  dense1_x = dense(concat, fc1_weight.data(), fc1_bias, 1, (int)fc1w_t.size(1), (int)fc1w_t.size(0));
  free(concat);
  relu(dense1_x, (int)fc1b_t.size(0));
  dense2_x = dense(dense1_x, fc2_weight.data(), fc2_bias, 1, (int)fc2w_t.size(1), (int)fc2w_t.size(0));
  relu(dense2_x, (int)fc2b_t.size(0));
  free(dense1_x);
  final_layer_dense_x = dense(dense2_x,
                              final_layer_weight.data(),
                              final_layer_bias,
                              1,
                              (int)final_layer_weight_t.size(1),
                              (int)final_layer_weight_t.size(0));
  free(dense2_x);
  softmax(final_layer_dense_x, (int)final_layer_bias_t.size(0));
  return final_layer_dense_x;
}
}

#endif
