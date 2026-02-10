import Headers
import Metal

@MainActor
public class Iterate {
  let start_points: MTLBuffer
  let results: MTLBuffer
  let threadsPerGrid = MTLSize(width: Int(threads_per_grid), height: 1, depth: 1)
  // let threadsPerGroup = MTLSize(width: MetalResource.device., height: Int, depth: Int)
  var res: Result
  let icb: MTLIndirectCommandBuffer
  let functionTable: MTLVisibleFunctionTable

  public init(score: String, start: group_elem) {
    do {  // initial start points
      start_points = MetalResource.device.makeBuffer(
        bytes: Array(
          repeating: tweak_point(a: start, tweak: 0),
          count: Int(threads_per_grid)),
        length: MemoryLayout<tweak_point>.stride * Int(threads_per_grid))!
      let fill_starts = MetalResource.library.makeFunction(name: "fill_starts")!
      let piplineState = try! MetalResource.device.makeComputePipelineState(
        function: fill_starts)
      let commandBuffer = MetalResource.commandQueue.makeCommandBuffer()!
      let encoder = commandBuffer.makeComputeCommandEncoder()!
      encoder.setComputePipelineState(piplineState)
      encoder.setBuffer(start_points, offset: 0, index: 0)
      encoder.setBuffer(PowTable.gnpow, offset: 0, index: 1)
      encoder.dispatchThreads(
        threadsPerGrid,
        threadsPerThreadgroup: MTLSize(
          width: piplineState.maxTotalThreadsPerThreadgroup, height: 1, depth: 1))
      encoder.endEncoding()
      commandBuffer.commit()
      commandBuffer.waitUntilCompleted()
    }
    results = MetalResource.device.makeBuffer(
      bytes: Array(
        repeating: result(addr: address(), tweak: 0, score: -1), count: Int(threads_per_grid)),
      length: MemoryLayout<result>.stride * Int(threads_per_grid))!
    res = Result(addr: "", tweak: 0, score: Int32.min)

    icb = {
      let icbDesc = MTLIndirectCommandBufferDescriptor()
      icbDesc.commandTypes = .concurrentDispatch
      icbDesc.inheritBuffers = true
      return MetalResource.device.makeIndirectCommandBuffer(
        descriptor: icbDesc, maxCommandCount: 2)!
    }()
    do {
      let scoreFunc = MetalResource.library.makeFunction(name: score)!
      let piplineDesc = MTLComputePipelineDescriptor()
      piplineDesc.computeFunction = MetalResource.library.makeFunction(name: "iterate")!
      piplineDesc.linkedFunctions = MTLLinkedFunctions()
      piplineDesc.linkedFunctions!.functions = [scoreFunc]
      piplineDesc.supportIndirectCommandBuffers = true
      let piplineState = try! MetalResource.device.makeComputePipelineState(
        descriptor: piplineDesc, options: []
      ).0
      let functionTableDesc = MTLVisibleFunctionTableDescriptor()
      functionTableDesc.functionCount = 1
      functionTable = piplineState.makeVisibleFunctionTable(descriptor: functionTableDesc)!
      let functionHandle = piplineState.functionHandle(function: scoreFunc)!
      functionTable.setFunction(functionHandle, index: 0)
      let command = icb.indirectComputeCommandAt(0)
      command.setComputePipelineState(piplineState)
      command.concurrentDispatchThreads(
        threadsPerGrid,
        threadsPerThreadgroup: MTLSize(
          width: piplineState.maxTotalThreadsPerThreadgroup, height: 1, depth: 1))
    }
    do {
      let piplineDesc = MTLComputePipelineDescriptor()
      piplineDesc.computeFunction = MetalResource.library.makeFunction(name: "forward")!
      piplineDesc.supportIndirectCommandBuffers = true
      let piplineState = try! MetalResource.device.makeComputePipelineState(
        descriptor: piplineDesc, options: []
      ).0
      let command = icb.indirectComputeCommandAt(1)
      command.setComputePipelineState(piplineState)
      command.concurrentDispatchThreads(
        threadsPerGrid,
        threadsPerThreadgroup: MTLSize(
          width: piplineState.maxTotalThreadsPerThreadgroup, height: 1, depth: 1))
    }
  }

  // return better addresses if found
  public func compute() -> [Result] {
    let commandBuffer = MetalResource.commandQueue.makeCommandBuffer()!
    let encoder = commandBuffer.makeComputeCommandEncoder()!
    encoder.setBuffer(PowTable.gpow, offset: 0, index: 0)
    encoder.setBuffer(start_points, offset: 0, index: 1)
    encoder.setBuffer(results, offset: 0, index: 2)
    encoder.setVisibleFunctionTable(functionTable, bufferIndex: 3)
    encoder.executeCommandsInBuffer(icb, range: 0..<1)
    encoder.setBuffer(start_points, offset: 0, index: 0)
    encoder.setBytes([PowTable.forward], length: MemoryLayout<group_elem>.stride, index: 1)
    encoder.executeCommandsInBuffer(icb, range: 1..<2)
    encoder.endEncoding()
    commandBuffer.commit()
    commandBuffer.waitUntilCompleted()
    let ptr = results.contents().bindMemory(to: result.self, capacity: Int(threads_per_grid))
    return UnsafeMutableBufferPointer(start: ptr, count: Int(threads_per_grid)).compactMap { r in
      if res.update(r) {
        return res
      }
      return nil
    }
  }
}
