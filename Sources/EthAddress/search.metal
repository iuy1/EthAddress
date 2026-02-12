#include "../Headers/lib.h"
#include <metal_stdlib>

kernel void fill_pow(device group_elem *a [[buffer(0)]],
                     constant uint &n [[buffer(1)]]) {
  a[1] = group_double(a[0]);
  for (uint i = 2; i < n; ++i) {
    a[i] = group_add(a[0], a[i - 1]);
  }
}

kernel void fill_starts(device tweak_point *start [[buffer((0))]],
                        device group_elem *gnpow [[buffer(1)]],
                        uint gid [[thread_position_in_grid]]) {
  start[gid].a = group_add(start[gid].a, gnpow[gid]);
  start[gid].tweak += steps_per_thread * (gid + 1);
}

kernel void forward(device tweak_point *start [[buffer((0))]],
                    constant group_elem &f [[buffer((1))]],
                    uint gid [[thread_position_in_grid]]) {
  start[gid].a = group_add(start[gid].a, f);
  start[gid].tweak += steps_per_thread * threads_per_grid;
}

kernel void iterate( //
    constant group_elem *gpow [[buffer(0)]],
    device const tweak_point *start [[buffer(1)]],
    device result *results [[buffer(2)]],
    metal::visible_function_table<int(address)> score [[buffer(3)]],
    uint gid [[thread_position_in_grid]]) {
  auto start_point = start[gid].a;
  for (uint b = 0; b < steps_per_thread; b += inv_batch_size) {
    uint256 d[inv_batch_size]; // d should has no 0
    for (uint i = b; i < b + inv_batch_size; ++i) {
      d[i - b] = mod_sub(start_point.x, gpow[i].x);
    }
    { // batch_inv
      uint256 s[inv_batch_size];
      s[0] = d[0];
      for (uint i = 1; i < inv_batch_size; ++i) {
        s[i] = mod_mul(s[i - 1], d[i]);
      }
       uint256 inv = mod_inv(s[inv_batch_size - 1]);
      for (uint i = inv_batch_size - 1; i > 0; --i) {
        auto di = d[i];
        d[i] = mod_mul(inv, s[i - 1]);
        inv = mod_mul(inv, di);
      }
      d[0] = inv;
    }
    for (uint i = b; i < b + inv_batch_size; ++i) {
      uint256 slope = mod_mul(mod_sub(start_point.y, gpow[i].y), d[i - b]);
      uint256 x =
          mod_sub(mod_mul(slope, slope), mod_add(start_point.x, gpow[i].x));
      uint256 y =
          mod_sub(mod_mul(slope, mod_sub(start_point.x, x)), start_point.y);
      address a = last20bytes(keccak({x, y}));
      int s = score[0](a);
      if (s >= results[gid].score) {
        results[gid] = {
            .addr = a, .tweak = start[gid].tweak + 1 + i, .score = s};
      }
    }
  }
}

kernel void iterate_( // without optimization
    constant group_elem *gpow [[buffer(0)]],
    device const tweak_point *start [[buffer(1)]],
    device result *results [[buffer(2)]],
    metal::visible_function_table<int(address)> score [[buffer(3)]],
    uint gid [[thread_position_in_grid]]) {
  auto g = gpow[0];
  auto p = start[gid].a;
  for (uint i = 0; i < steps_per_thread; ++i) {
    p = group_add(p, g);
    address a = last20bytes(keccak({p.x, p.y}));
    int s = score[0](a);
    if (s >= results[gid].score) {
      results[gid] = {.addr = a, .tweak = start[gid].tweak + 1 + i, .score = s};
    }
  }
}
