#include "../Headers/lib.h"
#include <metal_stdlib>

using state = keccak_state;

uint bswap(uint x) {
  auto c = as_type<uchar4>(x);
  return as_type<uint>(c.wzyx);
}

state pad(pubkey pk) {
  // rate = 1088 bits = 136 bytes = 34 uints
  state s{};
  for (uint i = 0; i < 8; ++i) {
    s.i[7 - i] = bswap(pk.x.n[i]);
  }
  for (uint i = 0; i < 8; ++i) {
    s.i[15 - i] = bswap(pk.y.n[i]);
  }
  s.i[16] = 1;
  s.i[33] = 0x8000'0000;
  return s;
}

void theta(thread state &s) {
  ulong t[5]{};
  for (uint r = 0; r < 5; ++r) {
    for (uint c = 0; c < 5; ++c) {
      t[c] ^= s.n[5 * r + c];
    }
  }
  for (uint r = 0; r < 5; ++r) {
    for (uint c = 0; c < 5; ++c) {
      s.n[5 * r + c] ^= t[(c + 4) % 5] ^ metal::rotate(t[(c + 1) % 5], 1ul);
    }
  }
}

void tho_pi(thread state &s) {
  const ulong ROTATION_OFFSETS[5][5] = {{0, 1, 62, 28, 27},
                                        {36, 44, 6, 55, 20},
                                        {3, 10, 43, 25, 39},
                                        {41, 45, 15, 21, 8},
                                        {18, 2, 61, 56, 14}};
  state t = s;
  for (uint x = 0; x < 5; ++x) {
    for (uint y = 0; y < 5; ++y) {
      uint z = (2 * x + 3 * y) % 5;
      s.n[5 * z + y] = metal::rotate(t.n[5 * y + x], ROTATION_OFFSETS[y][x]);
    }
  }
}

void chi(thread state &s) {
  for (uint r = 0; r < 5; ++r) {
    ulong t[5]{};
    for (uint c = 0; c < 5; ++c) {
      t[c] = s.n[5 * r + c];
    }
    for (uint c = 0; c < 5; ++c) {
      s.n[5 * r + c] ^= (~t[(c + 1) % 5]) & t[(c + 2) % 5];
    }
  }
}

void iota(thread state &s, uint i) {
  const ulong ROUND_CONSTANTS[24] = {
      0x0000000000000001, 0x0000000000008082, 0x800000000000808A,
      0x8000000080008000, 0x000000000000808B, 0x0000000080000001,
      0x8000000080008081, 0x8000000000008009, 0x000000000000008A,
      0x0000000000000088, 0x0000000080008009, 0x000000008000000A,
      0x000000008000808B, 0x800000000000008B, 0x8000000000008089,
      0x8000000000008003, 0x8000000000008002, 0x8000000000000080,
      0x000000000000800A, 0x800000008000000A, 0x8000000080008081,
      0x8000000000008080, 0x0000000080000001, 0x8000000080008008};
  s.n[0] ^= ROUND_CONSTANTS[i];
}

void permute(thread state &s) {
  for (uint i = 0; i < 24; ++i) {
    theta(s);
    tho_pi(s);
    chi(s);
    iota(s, i);
  }
}

uint256 keccak(pubkey pk) {
  state s = pad(pk);
  permute(s);
  return *(thread uint256 *)&s;
}

kernel void keccak(device const pubkey *in [[buffer(0)]],
                   device uint256 *out [[buffer(1)]]) {
  *out = keccak(*in);
}
