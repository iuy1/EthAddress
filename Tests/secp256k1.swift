import EthAddress
import Headers
import Testing

struct secp256k1 {
  @Test
  func str_uint256_convert() throws {
    do {
      let s = String(repeating: "a", count: 63)
      #expect(
        str2uint256(s) == nil
      )
    }
    do {
      let s = String(repeating: "a", count: 64)
      let v = try #require(str2uint256(s))
      #expect(v.n.0 == 0xaaaaaaaa)
      #expect(uint2562str(v) == s)
    }
  }
}
