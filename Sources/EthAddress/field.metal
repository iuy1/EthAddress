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

kernel void uint256_to_unsigned10x26(device const uint256 *in [[buffer(0)]],
                          device unsigned10x26 *out [[buffer(1)]]) {
  auto a = *in;
  unsigned10x26 b;
  transform<8, 32, 10, 26>(a.n, b.n);
  *out = b;
}

kernel void unsigned10x26_to_uint256(device const unsigned10x26 *in [[buffer(0)]],
                          device uint256 *out [[buffer(1)]]) {
  auto a = *in;
  uint256 b;
  transform<10, 26, 8, 32>(a.n, b.n);
  *out = b;
}

// 2**256 - 2**32 - 977
constant uint256 mod_uint256 =                             //
    {.n = {0xfffffc2f, 0xfffffffe, 0xffffffff, 0xffffffff, //
           0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff}};

void add_carry(thread uint &r, thread uint &cout, uint a, uint b, uint cin) {
  // cin <= 1
  ulong s = ulong(a) + b + cin;
  r = uint(s);
  cout = s >> 32;
}

uint256 mod_add(uint256 a, uint256 b) {
  uint256 r;
  uint c = 0;
  for (uint i = 0; i < 8; ++i) {
    add_carry(r.n[i], c, a.n[i], b.n[i], c);
  }
  // skip checking mod <= r
  if (c) {
    add_carry(r.n[0], c, r.n[0], 0x3d1, 0);
    add_carry(r.n[1], c, r.n[1], 1, c);
    add_carry(r.n[2], c, r.n[2], 0, c);
    add_carry(r.n[3], c, r.n[3], 0, c);
    // assume c is 0 now
  }
  return r;
}

kernel void mod_add(device const uint256 *a [[buffer(0)]],
                    device const uint256 *b [[buffer(1)]],
                    device uint256 *out [[buffer(2)]]) {
  auto r = mod_add(*a, *b);
  *out = r;
}

uint256 mod_sub(uint256 a, uint256 b) {
  uint256 r;
  uint c = 0;
  for (uint i = 0; i < 8; ++i) {
    add_carry(r.n[i], c, a.n[i], ~b.n[i], c);
  }
  // c, r = a - b + 2**256 - 1
  if (c) {
    add_carry(r.n[0], c, r.n[0], 1, 0);
    add_carry(r.n[1], c, r.n[1], 0, c);
  } else {
    add_carry(r.n[0], c, r.n[0], 0x3d1 + 1, 0);
    add_carry(r.n[1], c, r.n[1], 1, c);
  }
  add_carry(r.n[2], c, r.n[2], 0, c);
  add_carry(r.n[3], c, r.n[3], 0, c);
  return r;
}

kernel void mod_sub(device const uint256 *a [[buffer(0)]],
                    device const uint256 *b [[buffer(1)]],
                    device uint256 *out [[buffer(2)]]) {
  auto r = mod_sub(*a, *b);
  *out = r;
}

uint256 mod_mul(uint256 a, uint256 b) {}

kernel void mod_mul(device const uint256 *a [[buffer(0)]],
                    device const uint256 *b [[buffer(1)]],
                    device uint256 *out [[buffer(2)]]) {
  auto r = mod_mul(*a, *b);
  *out = r;
}

struct signed9x30 {
  int n[9];
};

uint256 mod_inv(uint256 a) {}
