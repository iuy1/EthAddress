import Headers

public struct Result {
  let addr: String
  let tweak: UInt64
  let score: Int32

  mutating func update(_ r: result) -> Bool {
    if (r.score, r.tweak) > (score, tweak) {
      self = Result(addr: address2str(r.addr), tweak: r.tweak, score: r.score)
      return true
    }
    return false
  }

  public func toString() -> String {
    return String(format: "score: %2d  tweak: %9x  address: \(addr)", score, tweak)
  }
}
