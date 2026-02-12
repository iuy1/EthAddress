import Metal

public enum MetalResource {
  static let singleThread = MTLSize(width: 1, height: 1, depth: 1)
  static let device = MTLCreateSystemDefaultDevice()!
  static let commandQueue = device.makeCommandQueue()!
  static let library = {
    let l = try! device.makeLibrary(
      URL: Bundle.module.url(forResource: "debug", withExtension: "metallib")!
    )
    // print(l.functionNames)
    return l
  }()
}
