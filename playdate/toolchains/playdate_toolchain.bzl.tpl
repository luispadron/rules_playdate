"""Defines a toolchain with the required tools to build Playdate applications."""

PlaydateToolchainInfo = provider(
    fields = {
        "compiler_path": "The path to the Playdate SDK compiler (`pdc`).",
        "sdk_path": "The path to the Playdate SDK.",
        "simulator_path": "The path to the simulator bundled in the Playdate SDK.",
    },
    doc = "Information about the Playdate toolchain.",
)

def _playdate_toolchain_impl(ctx):
    return [
        platform_common.ToolchainInfo(
            playdate = PlaydateToolchainInfo(
                compiler_path = ctx.attr.compiler_path,
                sdk_path = ctx.attr.sdk_path,
                simulator_path = ctx.attr.simulator_path,
            ),
        ),
    ]

playdate_toolchain = rule(
    implementation = _playdate_toolchain_impl,
    attrs = {
        "compiler_path": attr.string(mandatory = True),
        "sdk_path": attr.string(mandatory = True),
        "simulator_path": attr.string(mandatory = True),
    },
)
