#include "../Headers/lib.h"
#include <metal_stdlib>

kernel void fill_pow(device group_elem *a [[buffer(0)]],
                     constant uint &n [[buffer(1)]]) {
  a[1] = group_double(a[0]);
  for (uint i = 2; i < n; ++i) {
    a[i] = group_add(a[0], a[i - 1]);
  }
}

kernel void iterate( //
    constant group_elem *gpow [[buffer(0)]],
    device const tweak_point *start [[buffer(1)]],
    device result *results [[buffer(2)]],
    metal::visible_function_table<int(address)> score [[buffer(3)]],
    uint gid [[thread_position_in_grid]]) {
  auto start_point = start[gid].a;
  uint256 d[steps_per_thread]; // d should has no 0
  for (uint i = 0; i < steps_per_thread; ++i) {
    d[i] = mod_sub(start_point.x, gpow[i].x);
  }
  { // batch_inv
    uint256 s[steps_per_thread];
    s[0] = d[0];
    for (uint i = 1; i < steps_per_thread; ++i) {
      s[i] = mod_mul(s[i - 1], d[i]);
    }
    uint256 inv = mod_inv(s[steps_per_thread - 1]);
    for (uint i = steps_per_thread - 1; i > 0; --i) {
      auto di = d[i];
      d[i] = mod_mul(inv, s[i - 1]);
      inv = mod_mul(inv, di);
    }
    d[0] = inv;
  }
  for (uint i = 0; i < steps_per_thread; ++i) {
    uint256 slope = mod_mul(mod_sub(start_point.y, gpow[i].y), d[i]);
    uint256 x =
        mod_sub(mod_mul(slope, slope), mod_add(start_point.x, gpow[i].x));
    uint256 y =
        mod_sub(mod_mul(slope, mod_sub(start_point.x, x)), start_point.y);
    address a = last20bytes(keccak({x, y}));
    int s = score[0](a);
    if (s >= results[gid].score) {
      results[gid] = {.addr = a, .tweak = start[gid].tweak + 1 + i, .score = s};
    }
  }
}
