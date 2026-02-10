import Headers
import Metal

let singleThread = MetalResource.singleThread

public enum PowTable {
  static let g = {
    let g = str2pubkey(
      """
      79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798          
      483ada7726a3c4655da4fbfc0e1108a8fd17b448a68554199c47d08ffb10d4b8
      """
    )!
    return unsafeBitCast(g, to: group_elem.self)
  }()

  static let gn = {  // steps_per_thread * g
    let group_double_n = MetalResource.library.makeFunction(name: "group_double_n")!
    let output = MetalResource.device.makeBuffer(length: MemoryLayout<group_elem>.stride)!
    let piplineState = try! MetalResource.device.makeComputePipelineState(function: group_double_n)
    let commandBuffer = MetalResource.commandQueue.makeCommandBuffer()!
    let encoder = commandBuffer.makeComputeCommandEncoder()!
    encoder.setComputePipelineState(piplineState)
    encoder.setBytes([g], length: MemoryLayout<group_elem>.stride, index: 0)
    assert(steps_per_thread.nonzeroBitCount == 1)
    let n = steps_per_thread.trailingZeroBitCount
    encoder.setBytes([n], length: 4, index: 1)
    encoder.setBuffer(output, offset: 0, index: 2)
    encoder.dispatchThreads(singleThread, threadsPerThreadgroup: singleThread)
    encoder.endEncoding()
    commandBuffer.commit()
    commandBuffer.waitUntilCompleted()
    return output.contents().loadUnaligned(as: group_elem.self)
  }()

  static let forward = {  // threads_per_grid * gn
    let group_double_n = MetalResource.library.makeFunction(name: "group_double_n")!
    let output = MetalResource.device.makeBuffer(length: MemoryLayout<group_elem>.stride)!
    let piplineState = try! MetalResource.device.makeComputePipelineState(function: group_double_n)
    let commandBuffer = MetalResource.commandQueue.makeCommandBuffer()!
    let encoder = commandBuffer.makeComputeCommandEncoder()!
    encoder.setComputePipelineState(piplineState)
    encoder.setBytes([gn], length: MemoryLayout<group_elem>.stride, index: 0)
    assert(threads_per_grid.nonzeroBitCount == 1)
    let n = threads_per_grid.trailingZeroBitCount
    encoder.setBytes([n], length: 4, index: 1)
    encoder.setBuffer(output, offset: 0, index: 2)
    encoder.dispatchThreads(singleThread, threadsPerThreadgroup: singleThread)
    encoder.endEncoding()
    commandBuffer.commit()
    commandBuffer.waitUntilCompleted()
    return output.contents().loadUnaligned(as: group_elem.self)
  }()

  @MainActor static let gpow = {  // g, 2g, ...
    let gpow = MetalResource.device.makeBuffer(
      length: MemoryLayout<group_elem>.stride * Int(steps_per_thread))!
    gpow.contents().bindMemory(to: group_elem.self, capacity: 1).pointee = g
    let fill_pow = MetalResource.library.makeFunction(name: "fill_pow")!
    let piplineState = try! MetalResource.device.makeComputePipelineState(
      function: fill_pow)
    let commandBuffer = MetalResource.commandQueue.makeCommandBuffer()!
    let encoder = commandBuffer.makeComputeCommandEncoder()!
    encoder.setComputePipelineState(piplineState)
    encoder.setBuffer(gpow, offset: 0, index: 0)
    encoder.setBytes([steps_per_thread], length: 4, index: 1)
    encoder.dispatchThreads(singleThread, threadsPerThreadgroup: singleThread)
    encoder.endEncoding()
    commandBuffer.commit()
    commandBuffer.waitUntilCompleted()
    return gpow
  }()

  @MainActor static let gnpow = {  // gn, 2gn, ...
    let gnpow = MetalResource.device.makeBuffer(
      length: MemoryLayout<group_elem>.stride * Int(threads_per_grid))!
    gnpow.contents().bindMemory(to: group_elem.self, capacity: 1).pointee = gn
    let fill_pow = MetalResource.library.makeFunction(name: "fill_pow")!
    let piplineState = try! MetalResource.device.makeComputePipelineState(
      function: fill_pow)
    let commandBuffer = MetalResource.commandQueue.makeCommandBuffer()!
    let encoder = commandBuffer.makeComputeCommandEncoder()!
    encoder.setComputePipelineState(piplineState)
    encoder.setBuffer(gnpow, offset: 0, index: 0)
    encoder.setBytes([threads_per_grid], length: 4, index: 1)
    encoder.dispatchThreads(singleThread, threadsPerThreadgroup: singleThread)
    encoder.endEncoding()
    commandBuffer.commit()
    commandBuffer.waitUntilCompleted()
    return gnpow
  }()
}
