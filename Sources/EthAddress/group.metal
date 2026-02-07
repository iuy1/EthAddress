#include "../Headers/lib.h"

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
