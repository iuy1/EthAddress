#include "../Headers/lib.h"
#include <metal_stdlib>

template <uint aLen, uint aBits, uint bLen, uint bBits>
void transform(thread const uint a[], thread uint b[]) {
  for (uint i = 0; i < bLen; ++i) {
    b[i] = 0;
  }
  for (uint i = 0; i < aLen; ++i) {
    for (uint j = 0; j < bLen; ++j) {
      uint aStart = i * aBits;
      uint aEnd = aStart + aBits;
      uint bStart = j * bBits;
      uint bEnd = bStart + bBits;
      uint overlapStart = metal::max(aStart, bStart);
      uint overlapEnd = metal::min(aEnd, bEnd);
      if (overlapStart < overlapEnd) {
        uint overlapBits = overlapEnd - overlapStart;
        /*
          T extract_bits(T x, uint offset, uint bits)
          For unsigned data types, the most significant
          bits of the result are set to zero. For signed data
          types, the most significant bits are set to the
          value of bit offset+bits-1.
        */
        // it seems that the most significant bit are not set to zero
        uint e = metal::extract_bits(a[i], overlapStart - aStart, overlapBits);
        b[j] = metal::insert_bits(b[j], e, overlapStart - bStart, overlapBits);
      }
    }
  }
}

kernel void uint256_to_fe(device const uint256 *in [[buffer(0)]],
                          device field_elem *out [[buffer(1)]]) {
  auto a = *in;
  field_elem b;
  transform<8, 32, 10, 26>(a.n, b.n);
  *out = b;
}

kernel void fe_to_uint256(device const field_elem *in [[buffer(0)]],
                          device uint256 *out [[buffer(1)]]) {
  auto a = *in;
  uint256 b;
  transform<10, 26, 8, 32>(a.n, b.n);
  *out = b;
}

constant uint256 mod_uint256 =                             //
    {.n = {0xfffffc2f, 0xfffffffe, 0xffffffff, 0xffffffff, //
           0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff}};
