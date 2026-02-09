import Headers
import Metal
import Testing

@testable import EthAddress

struct Search {
  let start = {
    let start = str2pubkey(
      """
      d798be011def700daf1a62a3670eb5c606dc4cb11acf9366f86d5a82c657135b
      4d3e65aefc08574c72da152af9f78f77666b58257c1554d57424a39807293f5a
      """
    )!
    return unsafeBitCast(start, to: group_elem.self)
  }()
  @Test
  @MainActor
  func singleThreadTest() {
    let iterate = MetalResource.library.makeFunction(name: "iterate")!
    let zeros_bytes = MetalResource.library.makeFunction(name: "zeros_bytes")!
    let res = MetalResource.device.makeBuffer(
      bytes: [result(addr: address(), tweak: 0, score: -1)], length: MemoryLayout<result>.stride)!
    do {
      let descriptor = MTLComputePipelineDescriptor()
      descriptor.computeFunction = iterate
      descriptor.linkedFunctions = MTLLinkedFunctions()
      descriptor.linkedFunctions!.functions = [zeros_bytes]
      let piplineState = try! MetalResource.device.makeComputePipelineState(
        descriptor: descriptor, options: []
      ).0
      let functionTableDesc = MTLVisibleFunctionTableDescriptor()
      functionTableDesc.functionCount = 1
      let functionTable = piplineState.makeVisibleFunctionTable(descriptor: functionTableDesc)!
      let functionHandle = piplineState.functionHandle(function: zeros_bytes)!
      functionTable.setFunction(functionHandle, index: 0)
      let commandBuffer = MetalResource.commandQueue.makeCommandBuffer()!
      let encoder = commandBuffer.makeComputeCommandEncoder()!
      encoder.setComputePipelineState(piplineState)
      encoder.setBuffer(PowTable.gpow, offset: 0, index: 0)
      encoder.setBytes(
        [tweak_point(a: start, tweak: 0)], length: MemoryLayout<tweak_point>.stride, index: 1)
      encoder.setBuffer(res, offset: 0, index: 2)
      encoder.setVisibleFunctionTable(functionTable, bufferIndex: 3)
      encoder.dispatchThreads(singleThread, threadsPerThreadgroup: singleThread)
      encoder.endEncoding()
      commandBuffer.commit()
      commandBuffer.waitUntilCompleted()
    }
    let r = res.contents().loadUnaligned(as: result.self)
    #expect(address2str(r.addr) == "c78bcacd4c801cddd9d5716a08785eff00d85cc2")
    #expect(r.score == 1)
    #expect(r.tweak == 0xfe)
  }
  @Test
  @MainActor
  func iterate() {
    let it = Iterate(score: "zeros_bytes", start: start)
    let output = it.compute()
    let r = output.last!
    #expect(r.addr == "a29d2a009f8ded00bc27ea0d42274d48f1fc2d00")
    #expect(r.score == 3)
    #expect(r.tweak == 0xfac6d, "\(String(format: "r.tweak = %x", r.tweak))")
  }
  @Test
  @MainActor
  func multi_iterate() {
    let it = Iterate(score: "zeros_bytes", start: start)
    let r = (0..<10).map { _ in it.compute() }.last!.last!
    #expect(r.addr == "0000fb844e6310c6a24398821703fe00734df500")
    #expect(r.score == 4)
    #expect(r.tweak == 0x94c8f9, "\(String(format: "r.tweak = %x", r.tweak))")
  }
}
