#include "../Headers/lib.h"

field_elem uint256_to_fe(uint256 v) {
  field_elem res;
  res.n[0] = v.n[0] & 0x03ff'ffff;
  res.n[1] = (v.n[0] >> 26) | (v.n[1] << 6 & 0x03ff'ffff);
  res.n[2] = (v.n[1] >> 20) | (v.n[2] << 12 & 0x03ff'ffff);
  res.n[3] = (v.n[2] >> 14) | (v.n[3] << 18 & 0x03ff'ffff);
  res.n[4] = (v.n[3] >> 8) | (v.n[4] << 24 & 0x03ff'ffff);
  res.n[5] = (v.n[4] >> 2) & 0x03ff'ffff;
  res.n[6] = (v.n[4] >> 28) | (v.n[5] << 4 & 0x03ff'ffff);
  res.n[7] = (v.n[5] >> 22) | (v.n[6] << 10 & 0x03ff'ffff);
  res.n[8] = (v.n[6] >> 16) | (v.n[7] << 16 & 0x03ff'ffff);
  res.n[9] = v.n[7] >> 10;
  return res;
}

kernel void uint256_to_fe(device field_elem *out [[buffer(0)]],
                          device const uint256 *in [[buffer(1)]]) {
  *out = uint256_to_fe(*in);
}

uint256 fe_to_uint256(field_elem v) {
  uint256 res;
  res.n[0] = v.n[0] | (v.n[1] << 26);
  res.n[1] = (v.n[1] >> 6) | (v.n[2] << 20);
  res.n[2] = (v.n[2] >> 12) | (v.n[3] << 14);
  res.n[3] = (v.n[3] >> 18) | (v.n[4] << 8);
  res.n[4] = (v.n[4] >> 24) | (v.n[5] << 2) | (v.n[6] << 28);
  res.n[5] = (v.n[6] >> 4) | (v.n[7] << 22);
  res.n[6] = (v.n[7] >> 10) | (v.n[8] << 16);
  res.n[7] = (v.n[8] >> 16) | (v.n[9] << 10);
  return res;
}

kernel void fe_to_uint256(device uint256 *out [[buffer(0)]],
                          device const field_elem *in [[buffer(1)]]) {
  *out = fe_to_uint256(*in);
}
