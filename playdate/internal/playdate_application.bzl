"""Defines a Bazel rule for creating `.pdx` application files for the Playdate using `pdc` the Playdate compiler."""

# TODO: support more platform and file extensions.
# Right now we assume usage of `maocs_dylib` to create `.dylib` files for macOS.
_EXPECTED_EXTENSIONS = ["dylib"]

def _playdate_application_impl(ctx):
    # type: (ctx) -> List[Provider]
    playdate_toolchain = ctx.toolchains["@playdate_sdk//toolchain:toolchain_type"]
    playdate_compiler = playdate_toolchain.playdate.compiler_path
    playdate_sdk_path = playdate_toolchain.playdate.sdk_path
    playdate_simulator = playdate_toolchain.playdate.simulator_path

    libraries = [f for f in ctx.files.library if f.extension in _EXPECTED_EXTENSIONS]

    if not libraries:
        fail("""
        No libraries found in the dep that have the expected extensions: {}".format(_EXPECTED_EXTENSIONS))
        Found libraries: {}
        """.format(_EXPECTED_EXTENSIONS, ctx.files.library))
    if len(libraries) > 1:
        fail("Expected only one library in the dep but found: {}".format(len(libraries)))

    library = libraries[0]

    # create the build directory (input to `pdc`)
    input = ctx.actions.declare_directory("input")
    ctx.actions.run_shell(
        outputs = [input],
        inputs = [library],
        command = "mkdir -p \"${INPUT_DIR}\" && cp -RL \"${LIBRARY}\" \"${INPUT_DIR}\"/pdex.dylib",
        env = {
            "INPUT_DIR": input.path,
            "LIBRARY": library.path,
        },
        progress_message = "Creating Playdate compiler input",
    )

    # run `pdc` to compiler the `pdx` executable
    pdx_bundle = ctx.actions.declare_directory("{}.pdx".format(ctx.label.name))
    args = ctx.actions.args()
    args.add(input.path)
    args.add(pdx_bundle.path)
    args.add("-sdkpath", playdate_sdk_path)
    ctx.actions.run(
        outputs = [pdx_bundle],
        inputs = [input],
        executable = playdate_compiler,
        arguments = [args],
        toolchain = "@playdate_sdk//toolchain:toolchain_type",
        mnemonic = "PlaydateCompile",
        progress_message = "Compiling Playdate application: {}".format(ctx.label.name),
    )

    # Create an executable that can be `bazel run` to run the compiled `.pdx` file in the Playdate simulator.
    run_in_sim = ctx.actions.declare_file("{}.run_in_sim.sh".format(ctx.label.name))
    ctx.actions.write(
        output = run_in_sim,
        content = "\"{simulator}\" \"{pdx_bundle}\"".format(
            simulator = playdate_simulator,
            pdx_bundle = pdx_bundle.short_path,
        ),
        is_executable = True,
    )

    return [
        DefaultInfo(
            files = depset([pdx_bundle]),
            runfiles = ctx.runfiles(
                files = [pdx_bundle, run_in_sim],
            ),
            executable = run_in_sim,
        ),
    ]

playdate_application = rule(
    implementation = _playdate_application_impl,
    attrs = {
        "library": attr.label(
            mandatory = True,
        ),
    },
    toolchains = ["@playdate_sdk//toolchain:toolchain_type"],
    executable = True,
)
