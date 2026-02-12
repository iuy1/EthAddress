#include "../Headers/lib.h"
#include <metal_stdlib>

// llvm can't optimize these functions in metal_stdlib
template <class T> T max(T a, T b) {
  if (a > b) {
    return a;
  } else {
    return b;
  }
}
template <class T> T min(T a, T b) {
  if (a < b) {
    return a;
  } else {
    return b;
  }
}

template <uint aLen, uint aBits, uint bLen, uint bBits>
void transform(thread const uint a[], thread uint b[]) {
  for (uint i = 0; i < bLen; ++i) {
    b[i] = 0;
  }
  // unfortunately the loop is not unrolled
  for (uint i = 0; i < aLen; ++i) {
    for (uint j = 0; j < bLen; ++j) {
      uint aStart = i * aBits;
      uint aEnd = aStart + aBits;
      uint bStart = j * bBits;
      uint bEnd = bStart + bBits;
      uint overlapStart = max(aStart, bStart);
      uint overlapEnd = min(aEnd, bEnd);
      if (overlapStart < overlapEnd) {
        uint overlapBits = overlapEnd - overlapStart;
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

kernel void unsigned10x26_to_uint256(device const unsigned10x26 *in
                                     [[buffer(0)]],
                                     device uint256 *out [[buffer(1)]]) {
  auto a = *in;
  uint256 b;
  transform<10, 26, 8, 32>(a.n, b.n);
  *out = b;
}

// 2**256 - 2**32 - 977
// constant uint256 mod_uint256 =                             //
//     {.n = {0xfffffc2f, 0xfffffffe, 0xffffffff, 0xffffffff, //
//            0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff}};

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

uint256 mod_neg(uint256 a) {
  uint256 r;
  for (uint i = 0; i < 8; ++i) {
    r.n[i] = ~a.n[i];
  }
  // 2**256 - 1 - a + mod + 1
  uint c = 0;
  add_carry(r.n[0], c, r.n[0], 0xfffffc30, c);
  add_carry(r.n[1], c, r.n[1], 0xfffffffe, c);
  add_carry(r.n[2], c, r.n[2], 0xffffffff, c);
  add_carry(r.n[3], c, r.n[3], 0xffffffff, c);
  // assume c is 1 now
  return r;
}

kernel void mod_neg(device const uint256 *a [[buffer(0)]],
                    device uint256 *out [[buffer(1)]]) {
  auto r = mod_neg(*a);
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
    add_carry(r.n[2], c, r.n[2], 0, c);
    // add_carry(r.n[3], c, r.n[3], 0, c);
  } else {
    add_carry(r.n[0], c, r.n[0], 0xfffffc30, c);
    add_carry(r.n[1], c, r.n[1], 0xfffffffe, c);
    add_carry(r.n[2], c, r.n[2], 0xffffffff, c);
    add_carry(r.n[3], c, r.n[3], 0xffffffff, c);
  }
  return r;
}

kernel void mod_sub(device const uint256 *a [[buffer(0)]],
                    device const uint256 *b [[buffer(1)]],
                    device uint256 *out [[buffer(2)]]) {
  auto r = mod_sub(*a, *b);
  *out = r;
}

uint256 mod_mul_u8(uint8_t a, uint256 b) {
  uint256 r;
  ulong c = 0;
  for (uint i = 0; i < 8; ++i) {
    c += (ulong)b.n[i] * a;
    r.n[i] = uint(c);
    c >>= 32;
  }
  ulong d = 0;
  d = r.n[0] + 0x3d1 * c;
  r.n[0] = d, d >>= 32;
  d += r.n[1], d += c;
  r.n[1] = d, d >>= 32;
  d += r.n[2];
  r.n[2] = d, d >>= 32;
  d += r.n[3];
  r.n[3] = d, d >>= 32;
  return r;
}

uint256 mod_mul(uint256 a, uint256 b) {
  uint r[16]{};
  for (int i = 0; i <= 14; ++i) {
    for (int i1 = 0; i1 < 8; ++i1) {
      if (i1 > i) {
        continue;
      }
      int i2 = i - i1;
      if (i2 < 0 || i2 > 7) {
        continue;
      }
      ulong ri = ulong(a.n[i1]) * b.n[i2] + r[i];
      r[i] = uint(ri);
      ri = r[i + 1] + (ri >> 32);
      r[i + 1] = uint(ri);
      if (i < 14) {
        r[i + 2] += uint(ri >> 32);
      } else {
        // r[16] is always 0
      }
    }
  }
  ulong c = 0; // carray from last limb, < 2**33
  for (uint i = 0; i < 8; ++i) {
    ulong t = ulong(r[i + 8]) * 0x3d1 + r[i] + c;
    r[i] = uint(t);
    c = (t >> 32) + r[i + 8];
  }
  {
    ulong t = c * 0x3d1 + r[0];
    r[0] = uint(t);
    t = (t >> 32) + c + r[1];
    r[1] = uint(t);
    uint co;
    add_carry(r[2], co, r[2], t >> 32, 0);
    add_carry(r[3], co, r[3], 0, co);
    add_carry(r[4], co, r[4], 0, co);
  }
  return *(thread uint256 *)r;
}

kernel void mod_mul(device const uint256 *a [[buffer(0)]],
                    device const uint256 *b [[buffer(1)]],
                    device uint256 *out [[buffer(2)]]) {
  auto r = mod_mul(*a, *b);
  *out = r;
}

struct signed9x30 {
  int n[9];
};

constant signed9x30 mod_signed9x30 = {
    .n = {-0x3d1, -4, 0, 0, 0, 0, 0, 0, 0x10000}};

uint256 mod_inv(uint256 a) {
  signed9x30 f = mod_signed9x30;
  signed9x30 g;
  transform<8, 32, 9, 30>(a.n, (thread uint *)g.n);
  signed9x30 d = {.n = {0}};
  signed9x30 e = {.n = {1}};
  int delta = 1;
  const int M30 = 0x3fffffff;
  for (uint i0 = 0; i0 < 20; ++i0) {
    int4 t = {1, 0, 0, 1};
    /*
      [out_f] = 1/2**30 * [x, y] * [in_f]
      [out_g]             [z, w]   [in_g]
    */
    int f0 = f.n[0], g0 = g.n[0]; // f0 is always odd
    for (uint i = 0; i < 30; ++i) {
      if (delta > 0 && (g0 & 1)) {
        delta = 1 - delta;
        int g_ = (g0 - f0) >> 1;
        f0 = g0, g0 = g_;
        int4 t_ = t;
        t.xy = t_.zw * 2;
        t.zw = t_.zw - t_.xy;
      } else if (g0 & 1) {
        delta += 1;
        g0 = (g0 + f0) >> 1;
        t.zw += t.xy;
        t.xy *= 2;
      } else {
        delta += 1;
        g0 >>= 1;
        t.xy *= 2;
      }
    }
    { // update f g
      // the result of the bottom 30 bits is already calculated
      long cf = f0;
      long cg = g0;
      for (uint i = 1; i < 9; ++i) {
        cf += (long)t.x * f.n[i] + (long)t.y * g.n[i];
        cg += (long)t.z * f.n[i] + (long)t.w * g.n[i];
        f.n[i - 1] = cf & M30;
        g.n[i - 1] = cg & M30;
        cf >>= 30;
        cg >>= 30;
      }
      f.n[8] = cf;
      g.n[8] = cg;
    }
    // mod_inv30 * mod % 2**30 == 1
    const uint mod_inv30 = 0x2ddacacf;
    { // update d e
      // on input and output, d and e are in range (-2*mod, mod)
      long cd = (long)t.x * d.n[0] + (long)t.y * e.n[0];
      long ce = (long)t.z * d.n[0] + (long)t.w * e.n[0];
      int md = 0, me = 0;
      if (d.n[8] < 0) {
        md = t.x + t.y;
      }
      if (e.n[8] < 0) {
        me = t.z + t.w;
      }
      md -= (mod_inv30 * cd + md) & M30;
      me -= (mod_inv30 * ce + me) & M30;
      cd += (long)md * mod_signed9x30.n[0];
      ce += (long)me * mod_signed9x30.n[0];
      cd >>= 30; // the bottom 30 bits are 0
      ce >>= 30;
      for (uint i = 1; i < 9; ++i) {
        cd += (long)t.x * d.n[i] + (long)t.y * e.n[i];
        ce += (long)t.z * d.n[i] + (long)t.w * e.n[i];
        cd += (long)md * mod_signed9x30.n[i];
        ce += (long)me * mod_signed9x30.n[i];
        d.n[i - 1] = cd & M30;
        e.n[i - 1] = ce & M30;
        cd >>= 30;
        ce >>= 30;
      }
      d.n[8] = cd;
      e.n[8] = ce;
    }
  }
  // f == 1 or -1
  { // normalize d
    if (d.n[8] < 0) {
      for (uint i = 0; i < 9; ++i) {
        d.n[i] += mod_signed9x30.n[i];
      }
    }
    if (f.n[8] < 0) {
      for (uint i = 0; i < 9; ++i) {
        d.n[i] = -d.n[i];
      }
    }
    // skip this propagation
    // for (uint i = 0; i < 8; ++i) {
    //   d.n[i + 1] += d.n[i] >> 30;
    //   d.n[i] &= M30;
    // }
    if (d.n[8] < 0) {
      for (uint i = 0; i < 9; ++i) {
        d.n[i] += mod_signed9x30.n[i];
      }
    }
    for (uint i = 0; i < 8; ++i) {
      d.n[i + 1] += d.n[i] >> 30;
      d.n[i] &= M30;
    }
  }
  uint256 r;
  transform<9, 30, 8, 32>((thread uint *)d.n, r.n);
  return r;
}

kernel void mod_inv(device const uint256 *a [[buffer(0)]],
                    device uint256 *out [[buffer(1)]]) {
  auto r = mod_inv(*a);
  *out = r;
}
