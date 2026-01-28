#ifdef __METAL_VERSION__
#else
#include <stdint.h>
#endif

typedef struct {
  uint32_t n[8];
} uint256;

typedef struct {
  // A field element f represents the sum(i=0..9, f.n[i] << (i*26)) mod p,
  // where p is the field modulus, 2^256 - 2^32 - 977.
  uint32_t n[10];
} field_elem;

typedef struct {
  // can not represent point at infinity
  field_elem x;
  field_elem y;
} group_elem;

typedef struct {
  uint256 x;
  uint256 y;
} pubkey;

typedef union {
  uint64_t n[25];
  uint32_t i[50];
} keccak_state;

typedef struct {
  uint8_t n[20];
} address;
