import Headers
import Metal
import Testing

@testable import EthAddress

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
      #expect(v.n.0 == 0xaaaa_aaaa)
      #expect(uint2562str(v) == s)
    }
    do {
      let s = String(repeating: "ab ", count: 32)
      let v = try #require(str2uint256(s))
      #expect(v.n.0 == 0xabab_abab)
    }
    do {
      let s = String(repeating: "c", count: 63) + "d"
      let v = try #require(str2uint256(s))
      #expect(uint2562str(v) == s)
    }
  }
  @Test
  func uint256_to_unsigned10x26() throws {
    let u = str2uint256(String(repeating: "9a", count: 32))!
    let i = try compute(name: "uint256_to_unsigned10x26", input: u, output: unsigned10x26.self)
    #expect(i.n.0 == 0x029a_9a9a, "i.n.0 = \(String(format: "%08x", i.n.0))")
    #expect(i.n.1 == 0x02a6_a6a6, "i.n.1 = \(String(format: "%08x", i.n.1))")
    let o = try compute(name: "unsigned10x26_to_uint256", input: i, output: uint256.self)
    #expect(uint2562str(u) == uint2562str(o), "o = \(uint2562str(o))")
  }
  @Test
  func uint256_arithmetic() throws {
    do {
      let a = str2uint256("8" + String(repeating: "0", count: 63))!
      let o = try compute(name: "mod_add", input1: a, input2: a, output: uint256.self)
      #expect(uint2562str(o) == String(repeating: "0", count: 48) + "00000001" + "000003d1")
    }
    do {
      let a = str2uint256("8" + String(repeating: "0", count: 63))!
      let b = str2uint256("7" + String(repeating: "f", count: 63))!
      let o = try compute(name: "mod_sub", input1: a, input2: b, output: uint256.self)
      #expect(uint2562str(o) == String(repeating: "0", count: 63) + "1")
    }
  }
}
