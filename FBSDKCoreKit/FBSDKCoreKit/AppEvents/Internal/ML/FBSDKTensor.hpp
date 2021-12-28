/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#include <cassert>
#include <cmath>
#include <cstring>
#include <iostream>
#include <memory>
#include <unordered_map>
#include <vector>

#include <stddef.h>
#include <stdint.h>

#import <Accelerate/Accelerate.h>

// minimal aten implementation
#define MAT_ALWAYS_INLINE inline __attribute__((always_inline))
namespace fbsdk {
  static void *MAllocateMemory(size_t nbytes)
  {
    void *ptr = nullptr;
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

  static void MFreeMemory(void *ptr)
  {
    if (ptr) {
      free(ptr);
    }
  }

  class MTensor {
  public:
    MTensor() :
      storage_(nullptr),
      sizes_(),
      strides_(),
      capacity_(0) {};
    explicit MTensor(const std::vector<int> &sizes)
    {
      std::vector<int> strides = std::vector<int>(sizes.size());
      strides[strides.size() - 1] = 1;
      for (int i = static_cast<int32_t>(strides.size()) - 2; i >= 0; --i) {
        strides[i] = strides[i + 1] * sizes[i + 1];
      }
      strides_ = strides;
      sizes_ = sizes;
      capacity_ = 1;
      for (int size : sizes) {
        capacity_ *= size;
      }
      storage_ = std::shared_ptr<void>(MAllocateMemory((size_t)capacity_ * sizeof(float)), MFreeMemory);
    }

    MAT_ALWAYS_INLINE int count() const
    {
      return capacity_;
    }

    MAT_ALWAYS_INLINE int size(int dim) const
    {
      return sizes_[dim];
    }

    MAT_ALWAYS_INLINE const std::vector<int> &sizes() const
    {
      return sizes_;
    }

    MAT_ALWAYS_INLINE const std::vector<int> &strides() const
    {
      return strides_;
    }

    MAT_ALWAYS_INLINE const float *data() const
    {
      return (const float *)(storage_.get());
    }

    MAT_ALWAYS_INLINE float *mutable_data()
    {
      return static_cast<float *>(storage_.get());
    }

    MAT_ALWAYS_INLINE void Reshape(const std::vector<int> &sizes)
    {
      int count = 1;
      for (int i = 0; i < sizes.size(); i++) {
        count *= sizes[i];
      }
      if (count > capacity_) {
        capacity_ = count;
        storage_.reset(MAllocateMemory((size_t)capacity_ * sizeof(float)), MFreeMemory);
      }
      sizes_ = sizes;
    }

  private:
    int capacity_;
    std::vector<int> sizes_;
    std::vector<int> strides_;
    std::shared_ptr<void> storage_;
  };
}

#endif
