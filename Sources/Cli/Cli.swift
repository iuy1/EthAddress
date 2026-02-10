import ArgumentParser
import EthAddress
import Headers

@main
struct Main: AsyncParsableCommand {
  @Argument(transform: { (s: String) -> pubkey in
    guard let k = str2pubkey(s) else {
      throw ValidationError("")
    }
    return k
  })
  var pubkey: pubkey

  @Flag
  var zero_bytes: Bool = false
  @Flag
  var leading_zeros: Bool = false

  func run() async {
    await Task { @MainActor in
      var score = "leading_zeros"
      if zero_bytes {
        score = "zero_bytes"
      }
      let clock = ContinuousClock()
      let start = clock.now
      print("initializing...")
      let it = Iterate(score: score, start: unsafeBitCast(pubkey, to: group_elem.self))
      while true {
        let elapsed = clock.measure {
          let r = it.compute()
          for ri in r {
            print(ri.toString())
          }
        }
        let s: Double =
          Double(elapsed.components.seconds) + Double(elapsed.components.attoseconds)
          / 1_000_000_000_000_000_000
        print(
          "\u{1B}[2K\rtime: \(start.duration(to: clock.now)) "
            + "speed: \(Double(steps_per_thread * threads_per_grid) / s / 1000_000) M/s\r",
          terminator: "")
        fflush(stdout)
      }
    }.value
  }
}
