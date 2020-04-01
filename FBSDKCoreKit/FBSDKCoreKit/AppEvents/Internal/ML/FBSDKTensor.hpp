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

#include <cassert>
#include <cmath>
#include <cstring>
#include <iostream>
#include <memory>
#include <stddef.h>
#include <stdint.h>
#include <unordered_map>
#include <vector>

#import <Accelerate/Accelerate.h>

// minimal aten implementation
#define MAT_ALWAYS_INLINE inline __attribute__((always_inline))
namespace facebook {

    static void* MAllocateMemory(size_t nbytes) {
        void* ptr = nullptr;
        assert(nbytes > 0);
#ifdef __ANDROID__
        ptr = memalign(64, nbytes);
#else
        const int ret = posix_memalign(&ptr, 64, nbytes);
        (void)ret;
        assert(ret == 0);
#endif
        return ptr;
    }

    static void MFreeMemory(void* ptr) {
      if (ptr) {
        free(ptr);
      }
    }

    class MTensor {
    public:
        MTensor(){};
        MTensor(const std::vector<int64_t>& sizes) {
            auto strides = std::vector<int64_t>(sizes.size());
            strides[strides.size() - 1] = 1;
            for (auto i = static_cast<int32_t>(strides.size()) - 2; i >= 0; --i) {
                strides[i] = strides[i + 1] * sizes[i + 1];
            }
            strides_ = strides;
            sizes_ = sizes;
            capacity_ = 1;
            for (auto size : sizes) {
                capacity_ *= size;
            }
            storage_ = std::shared_ptr<void>(MAllocateMemory(capacity_ * sizeof(float)), MFreeMemory);
        }

        MAT_ALWAYS_INLINE int64_t count() const {
            return capacity_;
        }

        MAT_ALWAYS_INLINE int64_t size(int dim) const {
            return sizes_[dim];
        }

        MAT_ALWAYS_INLINE const std::vector<int64_t>& sizes() const {
            return sizes_;
        }

        MAT_ALWAYS_INLINE const std::vector<int64_t>& strides() const {
            return strides_;
        }

        MAT_ALWAYS_INLINE const float* data() const {
            return (const float*)(storage_.get());
        }

        MAT_ALWAYS_INLINE float* mutable_data() {
            return static_cast<float*>(storage_.get());
        }

    private:
        int64_t capacity_;
        std::vector<int64_t> sizes_;
        std::vector<int64_t> strides_;
        std::shared_ptr<void> storage_;
    };
}

#endif
