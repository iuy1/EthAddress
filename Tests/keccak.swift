import Headers
import Metal
import Testing

@testable import EthAddress

struct keccak {
  @Test
  func private_key_1() throws {
    let pk = try #require(
      str2pubkey(
        """
        79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798          
        483ada7726a3c4655da4fbfc0e1108a8fd17b448a68554199c47d08ffb10d4b8
        """
      ))
    let bufferIn = MetalResource.device.makeBuffer(
      bytes: [pk], length: MemoryLayout<pubkey>.stride)!
    let bufferOut = MetalResource.device.makeBuffer(length: MemoryLayout<uint256>.stride)!
    let keccak = MetalResource.library.makeFunction(name: "keccak")!
    let piplineState = try! MetalResource.device.makeComputePipelineState(
      function: keccak)
    let threads = MTLSize(width: 1, height: 1, depth: 1)
    let commandBuffer = MetalResource.commandQueue.makeCommandBuffer()!
    let encoder = commandBuffer.makeComputeCommandEncoder()!
    encoder.setComputePipelineState(piplineState)
    encoder.setBuffer(bufferIn, offset: 0, index: 0)
    encoder.setBuffer(bufferOut, offset: 0, index: 1)
    encoder.dispatchThreads(threads, threadsPerThreadgroup: threads)
    encoder.endEncoding()
    commandBuffer.commit()
    commandBuffer.waitUntilCompleted()
    let result = bufferOut.contents().load(as: uint256.self)
    let result_s = uint2562str(result)
    let big_Endian = stride(from: 0, to: 64, by: 2).map { i in
      let start = result_s.index(result_s.startIndex, offsetBy: i)
      let end = result_s.index(start, offsetBy: 2)
      return String(result_s[start..<end])
    }.reversed().joined()
    #expect(
      big_Endian == "c0a6c424ac7157ae408398df7e5f4552091a69125d5dfcb7b8c2659029395bdf",
      "keccak result = \(big_Endian)"
    )
  }
}
