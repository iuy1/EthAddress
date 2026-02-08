import Headers

public func str2uint256(_ s: String) -> uint256? {
  let s = s.filter { !$0.isWhitespace }
  if s.count != 64 {
    return nil
  }
  var arr = Array(repeating: UInt32(), count: 8)
  assert(MemoryLayout<UInt32>.stride * 8 == MemoryLayout<uint256>.stride)
  for i in 0..<8 {
    let start = s.index(s.startIndex, offsetBy: i * 8)
    let end = s.index(start, offsetBy: 8)
    guard let chunk = UInt32(s[start..<end], radix: 16) else {
      return nil
    }
    arr[i] = chunk
  }
  arr.reverse()
  return arr.withUnsafeBytes { ptr in
    return ptr.loadUnaligned(as: uint256.self)
  }
}

public func uint2562str(_ v: uint256) -> String {
  var arr = Array(repeating: UInt32(), count: 8)
  assert(MemoryLayout<UInt32>.stride * 8 == MemoryLayout<uint256>.stride)
  withUnsafeBytes(of: v) { ptr in
    for i in 0..<8 {
      arr[i] = ptr.loadUnaligned(fromByteOffset: i * MemoryLayout<UInt32>.stride, as: UInt32.self)
    }
  }
  arr.reverse()
  return arr.map {
    chunk in
    String(format: "%08x", chunk)
  }.joined()
}

public func str2pubkey(_ s: String) -> pubkey? {
  let s = s.filter { !$0.isWhitespace }
  if s.count != 128 {
    return nil
  }
  let mid = s.index(s.startIndex, offsetBy: 64)
  guard let x = str2uint256(String(s[..<mid])) else {
    return nil
  }
  guard let y = str2uint256(String(s[mid...])) else {
    return nil
  }
  return pubkey(x: x, y: y)
}

public func address2str(_ a: address) -> String {
  return withUnsafeBytes(of: a) { ptr in
    let buffer = ptr.bindMemory(to: UInt8.self)
    return buffer.map { b in
      String(format: "%02x", b)
    }.joined()
  }
}
