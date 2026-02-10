import Metal
import Testing

@testable import EthAddress

let singleThread = MetalResource.singleThread

public func compute<I: BitwiseCopyable, O: BitwiseCopyable>(
  name: String, input: I, output: O.Type
) throws -> O {
  let bufferOut = MetalResource.device.makeBuffer(
    length: MemoryLayout<O>.stride)!
  let function = try #require(MetalResource.library.makeFunction(name: name))
  let piplineState = try! MetalResource.device.makeComputePipelineState(
    function: function)
  let commandBuffer = MetalResource.commandQueue.makeCommandBuffer()!
  let encoder = commandBuffer.makeComputeCommandEncoder()!
  encoder.setComputePipelineState(piplineState)
  encoder.setBytes([input], length: MemoryLayout<I>.stride, index: 0)
  encoder.setBuffer(bufferOut, offset: 0, index: 1)
  encoder.dispatchThreads(singleThread, threadsPerThreadgroup: singleThread)
  encoder.endEncoding()
  commandBuffer.commit()
  commandBuffer.waitUntilCompleted()
  let result = bufferOut.contents().loadUnaligned(as: O.self)
  return result
}

public func compute<I1: BitwiseCopyable, I2: BitwiseCopyable, O: BitwiseCopyable>(
  name: String, input1: I1, input2: I2, output: O.Type
) throws -> O {
  let bufferOut = MetalResource.device.makeBuffer(
    length: MemoryLayout<O>.stride)!
  let function = try #require(MetalResource.library.makeFunction(name: name))
  let piplineState = try! MetalResource.device.makeComputePipelineState(
    function: function)
  let commandBuffer = MetalResource.commandQueue.makeCommandBuffer()!
  let encoder = commandBuffer.makeComputeCommandEncoder()!
  encoder.setComputePipelineState(piplineState)
  encoder.setBytes([input1], length: MemoryLayout<I1>.stride, index: 0)
  encoder.setBytes([input2], length: MemoryLayout<I2>.stride, index: 1)
  encoder.setBuffer(bufferOut, offset: 0, index: 2)
  encoder.dispatchThreads(singleThread, threadsPerThreadgroup: singleThread)
  encoder.endEncoding()
  commandBuffer.commit()
  commandBuffer.waitUntilCompleted()
  let result = bufferOut.contents().loadUnaligned(as: O.self)
  return result
}
