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

#include "FBSDKStandaloneModel.hpp"

#define SEQ_LEN 128
#define ALPHABET_SIZE 256
#define MTML_EMBEDDING_SIZE 32
#define NON_MTML_EMBEDDING_SIZE 64
#define DENSE_FEATURE_LEN 30

namespace mat1 {
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

    static float* embedding(const int *a, const float *b, const int n_examples, const int seq_length, const int embedding_size) {
        int i,j,k,val;
        float* res = (float *)malloc(sizeof(float) * (n_examples * seq_length * embedding_size));
        for (i = 0; i < n_examples; i++) {
            for (j = 0; j < seq_length; j++) {
                val = a[i * seq_length + j];
                for (k = 0; k < embedding_size; k++) {
                    res[(embedding_size * seq_length) * i + embedding_size * j + k] = b[val * embedding_size + k];
                }
            }
        }
        return res;
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
    static float* conv1D(const float *x, const float *w, const int n_examples, const int seq_len, const int input_size, const int kernel_size, const int output_size) {
        int n, o, i, k, m;
        float sum;
        float *res = (float *)malloc(sizeof(float) * (n_examples * (seq_len - kernel_size + 1) * output_size));
        float *temp_x = (float *)malloc(sizeof(float) * (kernel_size * input_size));
        float *temp_w = (float *)malloc(sizeof(float) * (kernel_size * input_size));
        for (n = 0; n < n_examples; n++){
            for (o = 0; o < output_size; o++){
                for (i = 0; i < seq_len - kernel_size + 1; i++) {
                    sum = 0;
                    for (m = 0; m < kernel_size; m++) {
                        for (k = 0; k < input_size; k++) {
                            temp_x[m * input_size + k] = x[n * (seq_len * input_size) + (m + i) * input_size + k];
                            temp_w[m * input_size + k] = w[(m * input_size + k) * output_size + o];
                        }
                    }
                    vDSP_dotpr(temp_x, 1, temp_w, 1, &sum, kernel_size * input_size);
                    res[(n * (output_size * (seq_len - kernel_size + 1)) + i * output_size + o)] = sum;
                }
            }
        }
        free(temp_x);
        free(temp_w);
        return res;
    }

    /*
     input shape: n_examples, len, n_channel
     return shape: n_examples, len - pool_size + 1, n_channel
     */
    static float* maxPool1D(const float *input, const int n_examples, const int input_len, const int n_channel, const int pool_size) {
        int res_len = input_len - pool_size + 1;
        float* res = (float *)calloc(n_examples * res_len * n_channel, sizeof(float));

        for (int n = 0; n < n_examples; n++) {
            for (int c = 0; c < n_channel; c++) {
                for (int i  = 0; i < res_len; i++) {
                    for (int r = i; r < i + pool_size; r++) {
                        int res_pos = n * (n_channel * res_len) + i * n_channel + c;
                        int input_pos = n * (n_channel * input_len) + r * n_channel + c;
                        if (r == i) {
                            res[res_pos] = input[input_pos];
                        } else {
                            res[res_pos] = fmax(res[res_pos], input[input_pos]);
                        }
                    }
                }
            }
        }
        return res;
    }

    static int* vectorize(const char *texts, const int str_len, const int max_len) {
        int *res = (int *)malloc(sizeof(int) * max_len);
        for (int i = 0; i < max_len; i++) {
            if (i < str_len){
                res[i] = static_cast<unsigned char>(texts[i]);
            } else {
                res[i] = 0;
            }
        }
        return res;
    }

    /*
     input shape: m, n
     return shape: n, m
     */
    static float* transpose2D(const float *input, const int m, const int n) {
        float *transposed = (float *)malloc(sizeof(float) * m * n);
        for (int i = 0; i < m; i++){
            for (int j = 0; j < n; j++) {
                transposed[j * m + i] = input[i * n + j];
            }
        }
        return transposed;
    }

    /*
     input shape: m, n, p
     return shape: p, n, m
     */
    static float* transpose3D(const float *input, const int64_t m, const int n, const int p) {
        float *transposed = (float *)malloc((size_t)(sizeof(float) * m * n * p));
        for (int i = 0; i < m; i++){
            for (int j = 0; j < n; j++) {
                for (int k = 0; k < p; k++) {
                    transposed[k * m * n + j * m + i] = input[i * n * p + j * p + k];
                }
            }
        }
        return transposed;
    }

    static float* add(float *a, const float *b, const int m, const int n, const int p) {
        for(int i = 0; i < m * n; i++){
            for(int j = 0; j < p; j++){
                a[i * p + j] += b[j];
            }
        }
        return a;
    }

    static float* predictOnMTML(const std::string task, const char *texts, const std::unordered_map<std::string, mat::MTensor>& weights, const float *df) {
        int *x;
        float *embed_x;
        float *c0, *c1, *c2;
        int c0_shape, c1_shape, c2_shape;
        float *ca, *cb, *cc;
        float *dense1_x, *dense2_x;
        float *final_layer_dense_x;
        std::string final_layer_weight_key = task + ".weight";
        std::string final_layer_bias_key = task + ".bias";

        const mat::MTensor& embed_t = weights.at("embed.weight");
        const mat::MTensor& conv0w_t = weights.at("convs.0.weight");
        const mat::MTensor& conv1w_t = weights.at("convs.1.weight");
        const mat::MTensor& conv2w_t = weights.at("convs.2.weight");
        const mat::MTensor& conv0b_t = weights.at("convs.0.bias");
        const mat::MTensor& conv1b_t = weights.at("convs.1.bias");
        const mat::MTensor& conv2b_t = weights.at("convs.2.bias");
        const mat::MTensor& fc1w_t = weights.at("fc1.weight"); // (128, 190)
        const mat::MTensor& fc1b_t = weights.at("fc1.bias"); // 128
        const mat::MTensor& fc2w_t = weights.at("fc2.weight"); // (64, 128)
        const mat::MTensor& fc2b_t = weights.at("fc2.bias"); // 64
        const mat::MTensor& final_layer_weight_t = weights.at(final_layer_weight_key); // (2, 64) or (5, 64)
        const mat::MTensor& final_layer_bias_t = weights.at(final_layer_bias_key); // 2 or 5

        const float *embed_weight = embed_t.data<float>();
        const float *convs_0_weight = transpose3D(conv0w_t.data<float>(), (int)conv0w_t.size(0), (int)conv0w_t.size(1), (int)conv0w_t.size(2));
        const float *convs_1_weight = transpose3D(conv1w_t.data<float>(), (int)conv1w_t.size(0), (int)conv1w_t.size(1), (int)conv1w_t.size(2));
        const float *convs_2_weight = transpose3D(conv2w_t.data<float>(), (int)conv2w_t.size(0), (int)conv2w_t.size(1), (int)conv2w_t.size(2));
        const float *convs_0_bias = conv0b_t.data<float>();
        const float *convs_1_bias = conv1b_t.data<float>();
        const float *convs_2_bias = conv2b_t.data<float>();
        const float *fc1_weight = transpose2D(fc1w_t.data<float>(), (int)fc1w_t.size(0), (int)fc1w_t.size(1));
        const float *fc2_weight = transpose2D(fc2w_t.data<float>(), (int)fc2w_t.size(0), (int)fc2w_t.size(1));
        const float *final_layer_weight = transpose2D(final_layer_weight_t.data<float>(),
                                                      (int)final_layer_weight_t.size(0),
                                                      (int)final_layer_weight_t.size(1));
        const float *fc1_bias = fc1b_t.data<float>();
        const float *fc2_bias = fc2b_t.data<float>();
        const float *final_layer_bias = final_layer_bias_t.data<float>();

        // vectorize text
        x = vectorize(texts, (int)strlen(texts), SEQ_LEN);

        // embedding
        embed_x = embedding(x, embed_weight, 1, SEQ_LEN, MTML_EMBEDDING_SIZE); // (1, 128, 32)
        free(x);

        // conv0
        c0 = conv1D(embed_x, convs_0_weight, 1, SEQ_LEN, MTML_EMBEDDING_SIZE, (int)conv0w_t.size(2), (int)conv0w_t.size(0)); // (1, 126, 32)
        c0_shape = (int)(SEQ_LEN - conv0w_t.size(2) + 1);
        add(c0, convs_0_bias, 1, c0_shape, (int)conv0w_t.size(0));
        relu(c0, c0_shape * (int)conv0w_t.size(0));
        free(embed_x);

        // conv1
        c1 = conv1D(c0, convs_1_weight, 1, c0_shape, (int)conv0w_t.size(0), (int)conv1w_t.size(2), (int)conv1w_t.size(0)); // (1, 124, 64)
        c1_shape = (int)(c0_shape - conv1w_t.size(2) + 1);
        add(c1, convs_1_bias, 1, c1_shape, (int)conv1w_t.size(0));
        relu(c1, c1_shape * (int)conv1w_t.size(0));
        c1 = maxPool1D(c1, 1, c1_shape, (int)conv1w_t.size(0), 2); // (1, 123, 64)
        c1_shape = c1_shape - 1;

        // conv2
        c2 = conv1D(c1, convs_2_weight, 1, c1_shape, (int)conv1w_t.size(0), (int)conv2w_t.size(2), (int)conv2w_t.size(0)); // (1, 121, 64)
        c2_shape = (int)(c1_shape - conv2w_t.size(2) + 1);
        add(c2, convs_2_bias, 1, c2_shape, (int)conv2w_t.size(0));
        relu(c2, c2_shape * (int)conv2w_t.size(0));

        // max pooling
        ca = maxPool1D(c0, 1, c0_shape, (int)conv0w_t.size(0), c0_shape);
        cb = maxPool1D(c1, 1, c1_shape, (int)conv1w_t.size(0), c1_shape);
        cc = maxPool1D(c2, 1, c2_shape, (int)conv2w_t.size(0), c2_shape);
        free(c0);
        free(c1);
        free(c2);

        // concatenate
        float *concat = (float *)malloc((size_t)(sizeof(float) * (conv0w_t.size(0) + conv1w_t.size(0) + conv2w_t.size(0) + 30)));
        concatenate(concat, ca, cb, (int)conv0w_t.size(0), (int)conv1w_t.size(0));
        concatenate(concat + conv0w_t.size(0) + conv1w_t.size(0), cc, df, (int)conv2w_t.size(0), 30);
        free(ca);
        free(cb);
        free(cc);

        // dense + relu
        dense1_x = dense(concat, fc1_weight, fc1_bias, 1, (int)fc1w_t.size(1), (int)fc1w_t.size(0));
        free(concat);
        relu(dense1_x, (int)fc1b_t.size(0));
        dense2_x = dense(dense1_x, fc2_weight, fc2_bias, 1, (int)fc2w_t.size(1), (int)fc2w_t.size(0));
        relu(dense2_x, (int)fc2b_t.size(0));
        free(dense1_x);
        final_layer_dense_x = dense(dense2_x,
                                    final_layer_weight,
                                    final_layer_bias,
                                    1,
                                    (int)final_layer_weight_t.size(1),
                                    (int)final_layer_weight_t.size(0));
        free(dense2_x);
        softmax(final_layer_dense_x, (int)final_layer_bias_t.size(0));
        return final_layer_dense_x;
    }

    static float* predictOnNonMTML(const std::string task, const char *texts, const std::unordered_map<std::string, mat::MTensor>& weights, const float *df) {
        int *x;
        float *embed_x;
        float *c0, *c1, *c2;
        int c0_shape, c1_shape, c2_shape;
        float *ca, *cb, *cc;
        float *dense1_x, *dense2_x;
        float *final_layer_dense_x;
        std::string final_layer_weight_key = task + ".weight";
        std::string final_layer_bias_key = task + ".bias";

        const mat::MTensor& embed_t = weights.at("embed.weight");
        const mat::MTensor& conv0w_t = weights.at("convs.0.weight");
        const mat::MTensor& conv1w_t = weights.at("convs.1.weight");
        const mat::MTensor& conv2w_t = weights.at("convs.2.weight");
        const mat::MTensor& conv0b_t = weights.at("convs.0.bias");
        const mat::MTensor& conv1b_t = weights.at("convs.1.bias");
        const mat::MTensor& conv2b_t = weights.at("convs.2.bias");
        const mat::MTensor& fc1w_t = weights.at("fc1.weight"); // (128, 126)
        const mat::MTensor& fc1b_t = weights.at("fc1.bias"); // 128
        const mat::MTensor& fc2w_t = weights.at("fc2.weight"); // (64, 128)
        const mat::MTensor& fc2b_t = weights.at("fc2.bias"); // 64
        const mat::MTensor& final_layer_weight_t = weights.at(final_layer_weight_key); // (2, 64) or (4, 64)
        const mat::MTensor& final_layer_bias_t = weights.at(final_layer_bias_key); // 2 or 4

        const float *embed_weight = embed_t.data<float>();
        const float *convs_0_weight = transpose3D(conv0w_t.data<float>(), (int)conv0w_t.size(0), (int)conv0w_t.size(1), (int)conv0w_t.size(2));
        const float *convs_1_weight = transpose3D(conv1w_t.data<float>(), (int)conv1w_t.size(0), (int)conv1w_t.size(1), (int)conv1w_t.size(2));
        const float *convs_2_weight = transpose3D(conv2w_t.data<float>(), (int)conv2w_t.size(0), (int)conv2w_t.size(1), (int)conv2w_t.size(2));
        const float *convs_0_bias = conv0b_t.data<float>();
        const float *convs_1_bias = conv1b_t.data<float>();
        const float *convs_2_bias = conv2b_t.data<float>();
        const float *fc1_weight = transpose2D(fc1w_t.data<float>(), (int)fc1w_t.size(0), (int)fc1w_t.size(1));
        const float *fc2_weight = transpose2D(fc2w_t.data<float>(), (int)fc2w_t.size(0), (int)fc2w_t.size(1));
        const float *final_layer_weight = transpose2D(final_layer_weight_t.data<float>(),
                                                      (int)final_layer_weight_t.size(0),
                                                      (int)final_layer_weight_t.size(1));
        const float *fc1_bias = fc1b_t.data<float>();
        const float *fc2_bias = fc2b_t.data<float>();
        const float *final_layer_bias = final_layer_bias_t.data<float>();

        // vectorize text
        x = vectorize(texts, (int)strlen(texts), SEQ_LEN);

        // embedding
        embed_x = embedding(x, embed_weight, 1, SEQ_LEN, NON_MTML_EMBEDDING_SIZE); // (1, 128, 64)
        free(x);

        // conv1D
        c0 = conv1D(embed_x, convs_0_weight, 1, SEQ_LEN, NON_MTML_EMBEDDING_SIZE, (int)conv0w_t.size(2), (int)conv0w_t.size(0)); // (1, 127, 32)
        c1 = conv1D(embed_x, convs_1_weight, 1, SEQ_LEN, NON_MTML_EMBEDDING_SIZE, (int)conv1w_t.size(2), (int)conv1w_t.size(0)); // (1, 126, 32)
        c2 = conv1D(embed_x, convs_2_weight, 1, SEQ_LEN, NON_MTML_EMBEDDING_SIZE, (int)conv2w_t.size(2), (int)conv2w_t.size(0)); // (1, 124, 32)
        free(embed_x);

        // shape
        c0_shape = (int)(SEQ_LEN - conv0w_t.size(2) + 1);
        c1_shape = (int)(SEQ_LEN - conv1w_t.size(2) + 1);
        c2_shape = (int)(SEQ_LEN - conv2w_t.size(2) + 1);

        // add bias
        add(c0, convs_0_bias, 1, c0_shape, (int)conv0w_t.size(0));
        add(c1, convs_1_bias, 1, c1_shape, (int)conv1w_t.size(0));
        add(c2, convs_2_bias, 1, c2_shape, (int)conv2w_t.size(0));

        // relu
        relu(c0, c0_shape * (int)conv0w_t.size(0));
        relu(c1, c1_shape * (int)conv1w_t.size(0));
        relu(c2, c2_shape * (int)conv2w_t.size(0));

        // max pooling
        ca = maxPool1D(c0, 1, c0_shape, (int)conv0w_t.size(0), c0_shape);
        cb = maxPool1D(c1, 1, c1_shape, (int)conv1w_t.size(0), c1_shape);
        cc = maxPool1D(c2, 1, c2_shape, (int)conv2w_t.size(0), c2_shape);
        free(c0);
        free(c1);
        free(c2);

        // concatenate
        float *concat = (float *)malloc((size_t)(sizeof(float) * (conv0w_t.size(0) + conv1w_t.size(0) + conv2w_t.size(0) + 30)));
        concatenate(concat, ca, cb, (int)conv0w_t.size(0), (int)conv1w_t.size(0));
        concatenate(concat + conv0w_t.size(0) + conv1w_t.size(0), cc, df, (int)conv2w_t.size(0), 30);
        free(ca);
        free(cb);
        free(cc);

        // dense + relu
        dense1_x = dense(concat, fc1_weight, fc1_bias, 1, (int)fc1w_t.size(1), (int)fc1w_t.size(0));
        free(concat);
        relu(dense1_x, (int)fc1b_t.size(0));
        dense2_x = dense(dense1_x, fc2_weight, fc2_bias, 1, (int)fc2w_t.size(1), (int)fc2w_t.size(0));
        relu(dense2_x, (int)fc2b_t.size(0));
        free(dense1_x);
        final_layer_dense_x = dense(dense2_x,
                                    final_layer_weight,
                                    final_layer_bias,
                                    1,
                                    (int)final_layer_weight_t.size(1),
                                    (int)final_layer_weight_t.size(0));
        free(dense2_x);
        softmax(final_layer_dense_x, (int)final_layer_bias_t.size(0));
        return final_layer_dense_x;
    }

    static float* predictOnText(const std::string key, const char *texts, const std::unordered_map<std::string, mat::MTensor>& weights, const float *df) {
        // switch to MTML key if needed
        if (key.compare("MTML_APP_EVENT_PRED") == 0) {
            return predictOnMTML("app_event_pred", texts, weights, df);
        } else if (key.compare("MTML_ADDRESS_DETECT") == 0) {
            return predictOnMTML("address_detect", texts, weights, df);
        }
        return predictOnNonMTML("fc3", texts, weights, df);
    }
}

#endif
