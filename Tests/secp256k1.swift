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
      let a = str2uint256(String(repeating: "12345678", count: 8))!
      let n = try compute(name: "mod_neg", input: a, output: uint256.self)
      let a_ = try compute(name: "mod_neg", input: n, output: uint256.self)
      #expect(uint2562str(a) == uint2562str(a_))
    }
    do {
      let a = str2uint256("8" + String(repeating: "0", count: 63))!
      let b = str2uint256("7" + String(repeating: "f", count: 63))!
      let o = try compute(name: "mod_sub", input1: a, input2: b, output: uint256.self)
      #expect(uint2562str(o) == String(repeating: "0", count: 63) + "1")
    }
    do {
      let a = str2uint256(String(repeating: "00000000", count: 7) + "20000000")!
      let o = try compute(name: "mod_mul", input1: a, input2: a, output: uint256.self)
      #expect(uint2562str(o) == String(repeating: "00000000", count: 6) + "04000000" + "00000000")
    }
    do {
      let a = str2uint256(String(repeating: "12345678", count: 8))!
      let n = try compute(name: "mod_neg", input: a, output: uint256.self)
      let o = try compute(name: "mod_mul", input1: a, input2: a, output: uint256.self)
      let o2 = try compute(name: "mod_mul", input1: n, input2: n, output: uint256.self)
      #expect(uint2562str(o) == uint2562str(o2))
    }
    do {
      let a = str2uint256(String(repeating: "00000000", count: 7) + "00000001")!
      let i = try compute(name: "mod_inv", input: a, output: uint256.self)
      #expect(uint2562str(i) == uint2562str(a))
    }
    do {
      let a = str2uint256(String(repeating: "00000000", count: 7) + "00000002")!
      let i = try compute(name: "mod_inv", input: a, output: uint256.self)
      #expect(
        uint2562str(i) == "7fffffffffffffffffffffffffffffffffffffffffffffffffffffff7ffffe18")
    }
    do {
      let a = str2uint256(String(repeating: "12345678", count: 8))!
      let i = try compute(name: "mod_inv", input: a, output: uint256.self)
      let _1 = try compute(name: "mod_mul", input1: a, input2: i, output: uint256.self)
      // _1 == mod + 1
      let _i = try compute(name: "mod_mul", input1: _1, input2: i, output: uint256.self)
      #expect(uint2562str(_i) == uint2562str(i))
    }
  }
  @Test
  func group_add() throws {
    let a = str2pubkey(  // G
      """
      79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798          
      483ada7726a3c4655da4fbfc0e1108a8fd17b448a68554199c47d08ffb10d4b8
      """
    )!
    let b = str2pubkey(  // 2G
      """
      c6047f9441ed7d6d3045406e95c07cd85c778e4b8cef3ca7abac09b95c709ee5
      1ae168fea63dc339a3c58419466ceaeef7f632653266d0e1236431a950cfe52a
      """
    )!
    let c = try compute(name: "group_add", input1: a, input2: b, output: pubkey.self)
    #expect(
      uint2562str(c.x) == "f9308a019258c31049344f85f89d5229b531c845836f99b08601f113bce036f9")
    #expect(
      uint2562str(c.y) == "388f7b0f632de8140fe337e62a37f3566500a99934c2231b6cb9fd7584b8e672")
  }
}
