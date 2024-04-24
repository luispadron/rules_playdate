"""Defines module extensions for the Playdate SDK"""

_DEFAULT_SDK_BASE_PATH = "Developer/PlaydateSDK"
_PLAYDATE_SDK_ENV = "PLAYDATE_SDK"

def _playdate_sdk_repository_impl(repository_ctx):
    api_path = repository_ctx.attr.api_path
    compiler_path = repository_ctx.attr.compiler_path
    sdk_path = repository_ctx.attr.sdk_path
    simulator_path = repository_ctx.attr.simulator_path

    # Ensure changes are tracked and symlink the C API.
    repository_ctx.watch_tree(api_path)
    repository_ctx.symlink(api_path, "playdate_sdk")

    # Write a BUILD file representing the Playdate SDK Bazel targets.
    repository_ctx.file(
        "BUILD.bazel",
        content = """
load("@rules_cc//cc:defs.bzl", "cc_library")

cc_library(
    name = "pd_api",
    hdrs = ["playdate_sdk/pd_api.h"] + glob(["playdate_sdk/pd_api/*.h"], allow_empty = False),
    includes = ["playdate_sdk"],
    defines = ["TARGET_EXTENSION"],
    visibility = ["//visibility:public"],
)
""",
    )

    # Write the toolchain package
    repository_ctx.template(
        "toolchain/BUILD.bazel",
        Label("@rules_playdate//playdate/toolchains:BUILD.bazel.tpl"),
        substitutions = {
            "(( compiler_path ))": compiler_path,
            "(( sdk_path ))": sdk_path,
            "(( simulator_path ))": simulator_path,
        },
    )
    repository_ctx.symlink(
        Label("@rules_playdate//playdate/toolchains:playdate_toolchain.bzl.tpl"),
        "toolchain/playdate_toolchain.bzl",
    )

_playdate_sdk_repository = repository_rule(
    implementation = _playdate_sdk_repository_impl,
    environ = [_PLAYDATE_SDK_ENV],
    attrs = {
        "api_path": attr.string(mandatory = True),
        "compiler_path": attr.string(mandatory = True),
        "sdk_path": attr.string(mandatory = True),
        "simulator_path": attr.string(mandatory = True),
    },
)

def _find_root_module(module_ctx):
    root_modules = [m for m in module_ctx.modules if m.is_root]
    if len(root_modules) > 1:
        fail("Expected at most one root module, found {}".format(", ".join([x.name for x in root_modules])))

    if root_modules:
        return root_modules[0]
    else:
        return module_ctx.modules[0]

def _playdate_sdk_impl(module_ctx):
    playdate_sdk_path = module_ctx.getenv(_PLAYDATE_SDK_ENV)

    if not playdate_sdk_path:
        # Try to get the SDK path from the default location
        home = module_ctx.getenv("HOME")
        if not home:
            fail("PLAYDATE_SDK is not set and HOME is unavailable. Unable to determine the Playdate SDK path.")
        default_sdk_path = home + "/" + _DEFAULT_SDK_BASE_PATH
        if not module_ctx.path(default_sdk_path).exists:
            fail("""
            SDK_PATH was not set and unable to find the Playdate SDK at the default location: {}/{}
            """.format(home, _DEFAULT_SDK_BASE_PATH))
        playdate_sdk_path = default_sdk_path
    elif not module_ctx.path(playdate_sdk_path).exists:
        fail("Playdate SDK not found at path: {}".format(playdate_sdk_path))

    module = _find_root_module(module_ctx)
    if not module:
        fail("Playdate SDK must be registered in a root module")

    requested_version = module.tags.register[0].version

    c_api_path = module_ctx.path(playdate_sdk_path + "/C_API")
    if not c_api_path.exists:
        fail("Playdate SDK C API not found at path: {}".format(c_api_path))

    compiler_path = module_ctx.path(playdate_sdk_path + "/bin/pdc")
    if not compiler_path.exists:
        fail("Playdate SDK compiler not found at path: {}".format(compiler_path))

    # TODO(fix): We should support more platforms for the SDK.
    # Currently we are only supporting the macOS simulator.
    simulator_path = module_ctx.path(playdate_sdk_path + "/bin/Playdate Simulator.app/Contents/MacOS/Playdate Simulator")
    if not simulator_path.exists:
        fail("Playdate SDK simulator not found at path: {}".format(simulator_path))

    sdk_version = module_ctx.read(playdate_sdk_path + "/VERSION.txt").strip()
    if sdk_version != requested_version:
        fail("Playdate SDK version mismatch: expected {}, got {}".format(requested_version, sdk_version))

    module_ctx.report_progress("Registering Playdate SDK at path: {}".format(playdate_sdk_path))

    # Setup the playdate_sdk repository which will contain the C api along with C library targets.
    _playdate_sdk_repository(
        name = "playdate_sdk",
        api_path = str(c_api_path),
        compiler_path = str(compiler_path),
        sdk_path = playdate_sdk_path,
        simulator_path = str(simulator_path),
    )

playdate_sdk = module_extension(
    implementation = _playdate_sdk_impl,
    environ = [_PLAYDATE_SDK_ENV],
    tag_classes = {
        "register": tag_class(
            attrs = {
                "version": attr.string(mandatory = True),
            },
        ),
    },
)
