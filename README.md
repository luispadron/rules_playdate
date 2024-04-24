# rules_playdate

[![CI status](https://github.com/luispadron/rules_playdate/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/luispadron/rules_playdate/actions/workflows/ci.yml)

Bazel rules for building and running [Playdate](https://play.date/) applications in Swift and C.

> [!CAUTION]
> This is all very much a work in progress. Things will break and change over time but it'll be fun.

## Documentation

See the [examples](examples) directory for the latest tested examples on using the rules.

## Requirements

| Bazel release | Min. rules version | Final rules version |
|--|--|--|
| 7.0.0 | current | current |

|| macOS | Linux | Windows |
|--|--|--|--|
| Supported platform | ✅ | ❌ | ❌ |

|| Swift | C | Lua |
|--|--|--|--|
| Supported language | ✅ | ✅ | ❌ |

## Getting started

`rules_playdate` provides a set of Bazel rules and toolchains for building Playdate applications.

1. Download the Playdate SDK. You can download the SDK from the [play.date/dev](https://play.date/dev) site.

1. Depend on the required rules to build your Playdate application, the following example uses macOS as the development platform. See the release notes for a snippet on adding `rules_playdate` as a dependency.

1. Create the targets in a `BUILD.bazel`:

    ```starlark
    load("@rules_apple//apple:macos.bzl", "macos_dylib")
    load("@rules_playdate//playdate:playdate.bzl", "playdate_application")
    load("@rules_swift//swift:swift.bzl", "swift_library")

    # Define a Swift library which contains your application's code.
    swift_library(
        name = "MyApp.swift_lib",
        srcs = ["MyApp.swift"],
        deps = [ ... ],
    )

    # Define a dylib target to package the `swift_library` as a dynamic library.
    macos_dylib(
        name = "MyApp_macos_lib",
        deps = [":MyApp.swift_lib"],
        minimum_os_version = "14.0",
    )

    # Define a Playdate application
    playdate_application(
        name = "MyApp",
        library = ":MyApp_macos_lib",
    )
    ```

1. You can build the Playdate application:

    ```shell
    bazel build //path/to:MyApp
    ```

1. You can run the Playdate application in the Playdate Simulator:

    ```shell
    bazel run //path/to:MyApp
    ```

## Playdate C and Swift API

This project is mostly focused on providing build rules for the Playdate and not any additional APIs around the SDK.
However, there are some simple Swift and C libraries which wrap the Playdate SDK API to make it easier to get started. You may use these libraries or use the Playdate SDK directly.

See the [@rules_playdate//playdate/lib](./playdate/lib/) targets for more information. For any information on the Playdate SDK, please refer to the [Playdate SDK documentation](https://play.date/dev/).

### Swift

Swift playdate support is pretty experimental as building with Swift for embedded platforms is not supported in any official release yet. You will need to use a development version of the Swift toolchain that supports building for embedded platforms. The best starting point to learn more are the examples here and the [Byte-sized Swift: Building Tiny Games for the Playdate](https://www.swift.org/blog/byte-sized-swift-tiny-games-playdate/) blog post.

```starlark
load("@rules_swift//swift:swift.bzl", "swift_library")

swift_library(
    name = "MyApp.swift_lib",
    srcs = ["MyApp.swift"],
    deps = ["@rules_playdate//playdate/lib/swift:playdate"],
)
```

```swift
import Playdate

let displayAPI = playdateAPI.display.unsafelyUnwrapped.pointee
```

### C

For C libraries, you may use the C API directly from the Playdate SDK. It is defined as a `cc_library` target via the `playdate_sdk` module extension.

```starlark
load("@rules_cc//cc:defs.bzl", "cc_library")

cc_library(
    name = "MyApp.c_lib",
    srcs = ["MyApp.c"],
    deps = ["@playdate_sdk//:pd_api"],

    # You may also use a thin wrapper around the C API with:
    # deps = ["@rules_playdate//playdate/lib/c:playdate"],
)
```

```c
// in MyApp.h

#include "pd_api.h"
// or #include "cplaydate.h" if using the wrapper
```
