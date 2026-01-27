import Metal

public enum MetalResource {
  static let device = MTLCreateSystemDefaultDevice()!
  static let commandQueue = device.makeCommandQueue()!
  static let library = try! device.makeLibrary(
    URL: Bundle.module.url(forResource: "debug", withExtension: "metallib")!)
}
