#ifdef __METAL_VERSION__
#else
#include <stdint.h>
#endif

struct uint256 {
  uint32_t n[8];
};

struct field_elem {
  // A field element f represents the sum(i=0..9, f.n[i] << (i*26)) mod p,
  // where p is the field modulus, 2^256 - 2^32 - 977.
  uint32_t n[10];
};
