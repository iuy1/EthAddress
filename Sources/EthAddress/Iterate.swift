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
      let pipelineState = try! MetalResource.device.makeComputePipelineState(
        function: fill_starts)
      let commandBuffer = MetalResource.commandQueue.makeCommandBuffer()!
      let encoder = commandBuffer.makeComputeCommandEncoder()!
      encoder.setComputePipelineState(pipelineState)
      encoder.setBuffer(start_points, offset: 0, index: 0)
      encoder.setBuffer(PowTable.gnpow, offset: 0, index: 1)
      encoder.dispatchThreads(
        threadsPerGrid,
        threadsPerThreadgroup: MTLSize(
          width: pipelineState.maxTotalThreadsPerThreadgroup, height: 1, depth: 1))
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
      let pipelineDesc = MTLComputePipelineDescriptor()
      pipelineDesc.computeFunction = MetalResource.library.makeFunction(name: "iterate")!
      pipelineDesc.linkedFunctions = MTLLinkedFunctions()
      pipelineDesc.linkedFunctions!.functions = [scoreFunc]
      pipelineDesc.supportIndirectCommandBuffers = true
      let pipelineState = try! MetalResource.device.makeComputePipelineState(
        descriptor: pipelineDesc, options: []
      ).0
      let functionTableDesc = MTLVisibleFunctionTableDescriptor()
      functionTableDesc.functionCount = 1
      functionTable = pipelineState.makeVisibleFunctionTable(descriptor: functionTableDesc)!
      let functionHandle = pipelineState.functionHandle(function: scoreFunc)!
      functionTable.setFunction(functionHandle, index: 0)
      let command = icb.indirectComputeCommandAt(0)
      command.setComputePipelineState(pipelineState)
      command.concurrentDispatchThreads(
        threadsPerGrid,
        threadsPerThreadgroup: MTLSize(
          width: pipelineState.maxTotalThreadsPerThreadgroup, height: 1, depth: 1))
    }
    do {
      let pipelineDesc = MTLComputePipelineDescriptor()
      pipelineDesc.computeFunction = MetalResource.library.makeFunction(name: "forward")!
      pipelineDesc.supportIndirectCommandBuffers = true
      let pipelineState = try! MetalResource.device.makeComputePipelineState(
        descriptor: pipelineDesc, options: []
      ).0
      let command = icb.indirectComputeCommandAt(1)
      command.setComputePipelineState(pipelineState)
      command.concurrentDispatchThreads(
        threadsPerGrid,
        threadsPerThreadgroup: MTLSize(
          width: pipelineState.maxTotalThreadsPerThreadgroup, height: 1, depth: 1))
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
    // after enable shader validation, this line will cause an error
    // seems something about visible function table goes wrong
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
