#include "../Headers/lib.h"

group_elem group_double(group_elem a) {
  uint256 slope =
      mod_mul(mod_mul_u8(3, mod_mul(a.x, a.x)), mod_inv(mod_mul_u8(2, a.y)));
  uint256 x = mod_sub(mod_mul(slope, slope), mod_mul_u8(2, a.x));
  uint256 y = mod_sub(mod_mul(slope, mod_sub(a.x, x)), a.y);
  return {x, y};
}

kernel void group_double(device const group_elem *a [[buffer(0)]],
                         device group_elem *out [[buffer(1)]]) {
  auto r = group_double(*a);
  *out = r;
}

group_elem group_add(group_elem a, group_elem b) {
  // a and b should have different x
  uint256 slope = mod_mul(mod_sub(a.y, b.y), mod_inv(mod_sub(a.x, b.x)));
  uint256 x = mod_sub(mod_mul(slope, slope), mod_add(a.x, b.x));
  uint256 y = mod_sub(mod_mul(slope, mod_sub(a.x, x)), a.y);
  return {x, y};
}

kernel void group_add(device const group_elem *a [[buffer(0)]],
                      device const group_elem *b [[buffer(1)]],
                      device group_elem *out [[buffer(2)]]) {
  auto r = group_add(*a, *b);
  *out = r;
}

// return (2**n) * a
kernel void group_double_n(device const group_elem *a [[buffer(0)]],
                           constant uint &n [[buffer(1)]],
                           device group_elem *out [[buffer(2)]]) {
  auto r = *a;
  for (uint i = 0; i < n; ++i) {
    r = group_double(r);
  }
  *out = r;
}
