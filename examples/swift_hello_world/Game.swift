import Playdate

/// The "main" entry point for playdate games.
@_cdecl("eventHandler")
public func eventHandler(
  pointer playdate: UnsafeMutableRawPointer!,
  event: PDSystemEvent,
  arg: UInt32
) -> Int32 {
  if event == .initialize {
    initializeGame(with: playdate)
  }
  return 0
}

/// The update function called on each runloop tick.
@_cdecl("update")
public func update(pointer playdate: UnsafeMutableRawPointer!) -> Int32 {
  let graphics = playdateAPI.graphics.unsafelyUnwrapped.pointee
  let message: StaticString = "Hello, World!"
  _ = message.withUTF8Buffer { buffer in
    graphics.drawText.unsafelyUnwrapped(buffer.baseAddress!, buffer.count, .kASCIIEncoding, 100, 100)
  }
  return 1
}

private func initializeGame(with playdate: UnsafeMutableRawPointer!) {
  // required as of this example in order for Swift to call the right functions at runtime
  // see //playdate/lib/swift Bazel target for more information
  initializePlaydateAPI(with: playdate)

  let system = playdateAPI.system.unsafelyUnwrapped.pointee
  system.setUpdateCallback.unsafelyUnwrapped(update, nil)
}
