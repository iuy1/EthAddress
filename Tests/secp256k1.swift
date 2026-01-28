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
  func uint256_to_fe() {
    let u = str2uint256(String(repeating: "9a", count: 32))!
    let threads = MTLSize(width: 1, height: 1, depth: 1)
    let buffer1 = MetalResource.device.makeBuffer(bytes: [u], length: MemoryLayout<uint256>.stride)!
    let buffer2 = MetalResource.device.makeBuffer(length: MemoryLayout<field_elem>.stride)!
    let buffer3 = MetalResource.device.makeBuffer(length: MemoryLayout<uint256>.stride)!
    do {
      let uint256_to_fe = MetalResource.library.makeFunction(name: "uint256_to_fe")!
      let piplineState = try! MetalResource.device.makeComputePipelineState(
        function: uint256_to_fe)
      let commandBuffer = MetalResource.commandQueue.makeCommandBuffer()!
      let encoder = commandBuffer.makeComputeCommandEncoder()!
      encoder.setComputePipelineState(piplineState)
      encoder.setBuffer(buffer1, offset: 0, index: 1)
      encoder.setBuffer(buffer2, offset: 0, index: 0)
      encoder.dispatchThreads(threads, threadsPerThreadgroup: threads)
      encoder.endEncoding()
      commandBuffer.commit()
      commandBuffer.waitUntilCompleted()
    }
    let fe = buffer2.contents().load(as: field_elem.self)
    #expect(fe.n.0 == 0x029a_9a9a, "fe.n.0 = \(String(format: "%08x", fe.n.0))")
    #expect(fe.n.1 == 0x02a6_a6a6, "fe.n.1 = \(String(format: "%08x", fe.n.1))")
    do {
      let fe_to_uint256 = MetalResource.library.makeFunction(name: "fe_to_uint256")!
      let piplineState = try! MetalResource.device.makeComputePipelineState(
        function: fe_to_uint256)
      let commandBuffer = MetalResource.commandQueue.makeCommandBuffer()!
      let encoder = commandBuffer.makeComputeCommandEncoder()!
      encoder.setComputePipelineState(piplineState)
      encoder.setBuffer(buffer2, offset: 0, index: 1)
      encoder.setBuffer(buffer3, offset: 0, index: 0)
      encoder.dispatchThreads(threads, threadsPerThreadgroup: threads)
      encoder.endEncoding()
      commandBuffer.commit()
      commandBuffer.waitUntilCompleted()
    }
    let out = buffer3.contents().load(as: uint256.self)
    #expect(uint2562str(u) == uint2562str(out), "out = \(uint2562str(out))")
  }
}
