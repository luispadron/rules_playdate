// The following code is taken from the Swift Playdate Apple examples, with slight modifications.
// https://github.com/apple/swift-playdate-examples

@_documentation(visibility: internal)
@_exported
import cplaydate

@_documentation(visibility: internal)
public var playdateAPI: PlaydateAPI { playdate_api.unsafelyUnwrapped.pointee }

public func initializePlaydateAPI(with pointer: UnsafeMutableRawPointer) {
  playdate_api = pointer.bindMemory(to: PlaydateAPI.self, capacity: 1)
}

/// Implement `posix_memalign(3)`, which is required by the Swift runtime but is
/// not provided by the Playdate C library.
@_documentation(visibility: internal)
@_cdecl("posix_memalign")
public func posix_memalign(
  _ memptr: UnsafeMutablePointer<UnsafeMutableRawPointer?>,
  _ alignment: Int,
  _ size: Int
) -> CInt {
  guard let allocation = malloc(Int(size + alignment - 1)) else {
    #if hasFeature(Embedded)
    fatalError()
    #else
    fatalError("Unable to handle memory request: Out of memory.")
    #endif
  }
  let misalignment = Int(bitPattern: allocation) % alignment
  #if hasFeature(Embedded)
  precondition(misalignment == 0)
  #else
  #error("You must use a Swift Toolchain with the 'Embedded' feature enabled.")
  #endif
  memptr.pointee = allocation
  return 0
}
