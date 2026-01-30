import Metal
import Testing

@testable import EthAddress

let threads = MTLSize(width: 1, height: 1, depth: 1)

public func compute<I: BitwiseCopyable, O: BitwiseCopyable>(
  name: String, input: I, output: O.Type
) throws -> O {
  let bufferIn = MetalResource.device.makeBuffer(
    bytes: [input], length: MemoryLayout<I>.stride)!
  let bufferOut = MetalResource.device.makeBuffer(
    length: MemoryLayout<O>.stride)!
  let function = try #require(MetalResource.library.makeFunction(name: name))
  let piplineState = try! MetalResource.device.makeComputePipelineState(
    function: function)
  let commandBuffer = MetalResource.commandQueue.makeCommandBuffer()!
  let encoder = commandBuffer.makeComputeCommandEncoder()!
  encoder.setComputePipelineState(piplineState)
  encoder.setBuffer(bufferIn, offset: 0, index: 0)
  encoder.setBuffer(bufferOut, offset: 0, index: 1)
  encoder.dispatchThreads(threads, threadsPerThreadgroup: threads)
  encoder.endEncoding()
  commandBuffer.commit()
  commandBuffer.waitUntilCompleted()
  let result = bufferOut.contents().loadUnaligned(as: O.self)
  return result
}

public func compute<I1: BitwiseCopyable, I2: BitwiseCopyable, O: BitwiseCopyable>(
  name: String, input1: I1, input2: I2, output: O.Type
) throws -> O {
  let bufferIn1 = MetalResource.device.makeBuffer(
    bytes: [input1], length: MemoryLayout<I1>.stride)!
  let bufferIn2 = MetalResource.device.makeBuffer(
    bytes: [input2], length: MemoryLayout<I2>.stride)!
  let bufferOut = MetalResource.device.makeBuffer(
    length: MemoryLayout<O>.stride)!
  let function = try #require(MetalResource.library.makeFunction(name: name))
  let piplineState = try! MetalResource.device.makeComputePipelineState(
    function: function)
  let commandBuffer = MetalResource.commandQueue.makeCommandBuffer()!
  let encoder = commandBuffer.makeComputeCommandEncoder()!
  encoder.setComputePipelineState(piplineState)
  encoder.setBuffer(bufferIn1, offset: 0, index: 0)
  encoder.setBuffer(bufferIn2, offset: 0, index: 1)
  encoder.setBuffer(bufferOut, offset: 0, index: 2)
  encoder.dispatchThreads(threads, threadsPerThreadgroup: threads)
  encoder.endEncoding()
  commandBuffer.commit()
  commandBuffer.waitUntilCompleted()
  let result = bufferOut.contents().loadUnaligned(as: O.self)
  return result
}
