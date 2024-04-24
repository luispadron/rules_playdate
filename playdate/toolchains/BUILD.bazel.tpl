load("@playdate_sdk//toolchain:playdate_toolchain.bzl", "playdate_toolchain")

toolchain_type(
    name = "toolchain_type",
    visibility = ["//visibility:public"],
)

# TODO: Support more platforms.
# Right now we only support macOS (both arm64 and x86_64).

toolchain(
    name = "playdate_macos_toolchain",
    exec_compatible_with = [
        "@platforms//os:macos",
        "@apple_support//constraints:apple",
        "@apple_support//constraints:device",
    ],
    target_compatible_with = [
        "@platforms//os:macos",
        "@apple_support//constraints:apple",
        "@apple_support//constraints:device",
    ],
    toolchain = ":playdate_macos",
    toolchain_type = ":toolchain_type",
    visibility = ["//visibility:public"],
)

playdate_toolchain(
    name = "playdate_macos",
    compiler_path = "(( compiler_path ))",
    sdk_path = "(( sdk_path ))",
    simulator_path = "(( simulator_path ))",
)
