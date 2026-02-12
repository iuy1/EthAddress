import Headers
import Metal

@MainActor
public class Iterate {
  let start_points: MTLBuffer
  let results: MTLBuffer
  let threadsPerGrid = MTLSize(
    width: Int(threads_per_grid),
    height: 1,
    depth: 1
  )
  var res: Result
  let iteratePipeline: MTLComputePipelineState
  let functionTable: MTLVisibleFunctionTable
  let forwardPipeline: MTLComputePipelineState

  public init(score: String, start: group_elem) {
    do {  // initial start points
      start_points = MetalResource.device.makeBuffer(
        bytes: Array(
          repeating: tweak_point(a: start, tweak: 0),
          count: Int(threads_per_grid)
        ),
        length: MemoryLayout<tweak_point>.stride * Int(threads_per_grid)
      )!
      start_points.label = "start_points"
      let fill_starts = MetalResource.library.makeFunction(name: "fill_starts")!
      let pipelineState = try! MetalResource.device.makeComputePipelineState(
        function: fill_starts
      )
      let commandBuffer = MetalResource.commandQueue.makeCommandBuffer()!
      let encoder = commandBuffer.makeComputeCommandEncoder()!
      encoder.setComputePipelineState(pipelineState)
      encoder.setBuffer(start_points, offset: 0, index: 0)
      encoder.setBuffer(PowTable.gnpow, offset: 0, index: 1)
      encoder.dispatchThreads(
        threadsPerGrid,
        threadsPerThreadgroup: MTLSize(
          width: pipelineState.maxTotalThreadsPerThreadgroup,
          height: 1,
          depth: 1
        )
      )
      encoder.endEncoding()
      commandBuffer.commit()
      commandBuffer.waitUntilCompleted()
    }
    results = MetalResource.device.makeBuffer(
      bytes: Array(
        repeating: result(addr: address(), tweak: 0, score: -1),
        count: Int(threads_per_grid)
      ),
      length: MemoryLayout<result>.stride * Int(threads_per_grid)
    )!
    results.label = "results"
    res = Result(addr: "", tweak: 0, score: Int32.min)

    do {
      let scoreFunc = MetalResource.library.makeFunction(name: score)!
      let pipelineDesc = MTLComputePipelineDescriptor()
      pipelineDesc.computeFunction = MetalResource.library.makeFunction(
        name: "iterate"
      )!
      pipelineDesc.linkedFunctions = MTLLinkedFunctions()
      pipelineDesc.linkedFunctions!.functions = [scoreFunc]
      iteratePipeline = try! MetalResource.device.makeComputePipelineState(
        descriptor: pipelineDesc,
        options: []
      ).0
      let functionTableDesc = MTLVisibleFunctionTableDescriptor()
      functionTableDesc.functionCount = 1
      functionTable = iteratePipeline.makeVisibleFunctionTable(
        descriptor: functionTableDesc
      )!
      let functionHandle = iteratePipeline.functionHandle(function: scoreFunc)!
      functionTable.setFunction(functionHandle, index: 0)
    }
    do {
      let pipelineDesc = MTLComputePipelineDescriptor()
      pipelineDesc.computeFunction = MetalResource.library.makeFunction(
        name: "forward"
      )!
      forwardPipeline = try! MetalResource.device.makeComputePipelineState(
        descriptor: pipelineDesc,
        options: []
      ).0
    }
    do {
      let _ = PowTable.gpow
    }
  }

  // return better addresses if found
  public func compute() -> [Result] {
    // let captureDesc = MTLCaptureDescriptor()
    // captureDesc.captureObject = MetalResource.commandQueue
    // captureDesc.destination = .developerTools
    // let _ = try? MTLCaptureManager.shared().startCapture(with: captureDesc)
    do {
      let commandBuffer = MetalResource.commandQueue.makeCommandBuffer()!
      commandBuffer.label = "iterate"
      let encoder = commandBuffer.makeComputeCommandEncoder()!
      encoder.setComputePipelineState(iteratePipeline)
      encoder.setBuffer(PowTable.gpow, offset: 0, index: 0)
      encoder.setBuffer(start_points, offset: 0, index: 1)
      encoder.setBuffer(results, offset: 0, index: 2)
      encoder.setVisibleFunctionTable(functionTable, bufferIndex: 3)
      encoder
        .dispatchThreads(
          threadsPerGrid,
          threadsPerThreadgroup: MTLSize(
            width: 32,
            height: 1,
            depth: 1,
          )
        )
      encoder.endEncoding()
      commandBuffer.commit()
      commandBuffer.waitUntilCompleted()
    }
    // MTLCaptureManager.shared().stopCapture()
    do {
      let commandBuffer = MetalResource.commandQueue.makeCommandBuffer()!
      commandBuffer.label = "forward"
      let encoder = commandBuffer.makeComputeCommandEncoder()!
      encoder.setComputePipelineState(forwardPipeline)
      encoder.setBuffer(start_points, offset: 0, index: 0)
      encoder.setBytes(
        [PowTable.forward],
        length: MemoryLayout<group_elem>.stride,
        index: 1
      )
      encoder
        .dispatchThreads(
          threadsPerGrid,
          threadsPerThreadgroup: MTLSize(
            width: 128,
            height: 1,
            depth: 1,
          )
        )
      encoder.endEncoding()
      commandBuffer.commit()
      commandBuffer.waitUntilCompleted()
    }
    let ptr = results.contents().bindMemory(
      to: result.self,
      capacity: Int(threads_per_grid)
    )
    return UnsafeMutableBufferPointer(start: ptr, count: Int(threads_per_grid))
      .compactMap { r in
        if res.update(r) {
          return res
        }
        return nil
      }
  }
}
