#include "../Headers/lib.h"

address last20bytes(uint256 hash) {
  auto p = (thread uint *)&hash;
  p += 3;
  return *(thread address *)p;
}

[[visible]]
int zeros_bytes(address a) {
  int r = 0;
  for (uint i = 0; i < 20; ++i) {
    r += a.n[i] == 0;
  }
  return r;
}

[[visible]]
int leading_zeros(address a) {
  int r = 0;
  for (uint i = 0; i < 20; ++i) {
    if (a.n[i] >> 4) {
      break;
    }
    r++;
    if (a.n[i] & 0xf) {
      break;
    }
    r++;
  }
  return r;
}
