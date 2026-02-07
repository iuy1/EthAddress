#ifdef __METAL_VERSION__
#else
#include <stdint.h>
#endif

typedef struct {
  uint32_t n[8];
} uint256;

uint256 mod_add(uint256 a, uint256 b);
uint256 mod_sub(uint256 a, uint256 b);
uint256 mod_mul_u8(uint8_t a, uint256 b);
uint256 mod_mul(uint256 a, uint256 b);
uint256 mod_inv(uint256 a);

// currently unused
typedef struct {
  // A field element f represents the sum(i=0..9, f.n[i] << (i*26)) mod p,
  // where p is the field modulus, 2^256 - 2^32 - 977.
  uint32_t n[10];
} unsigned10x26;

typedef struct {
  // can not represent point at infinity
  uint256 x;
  uint256 y;
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
