# Cross Compilation

For cross compilation, you have to specify a custom platform to let Bazel know that you are compiling for a different platform than the default host platform.

The example code is setup to cross compile from the following hosts to the the following targets:

* {linux, x86_64} -> {linux, aarch64}
* {darwin, x86_64} -> {linux, x86_64}
* {darwin, x86_64} -> {linux, aarch64}
* {darwin, aarch64 (Apple Silicon)} -> {linux, x86_64}
* {darwin, aarch64 (Apple Silicon)} -> {linux, aarch64}

## PC Linux hosts

When you run linux on either Intel, AMD, or ARM64, you can compile and run the example in the following way:

You cross-compile by calling the target.

`bazel build //:hello_world_x86_64`

or

`bazel build //:hello_world_aarch64`


You can also build all targets at once:
 

`bazel build //...`

And you can run all test with:

`bazel test //...`


## Apple hosts

When you compile this repo from an Apple Computer, you need to add an additional flag depending on your system:

**Apple Silicon Macs**

```bash
bazel build //... --extra_execution_platforms=//build/platforms:darwin-aarch64
bazel test //... --extra_execution_platforms=//build/platforms:darwin-aarch64
```

**Intel Macs**

```bash
bazel build //... --extra_execution_platforms=//build/platforms:darwin-x86_64
bazel test //... --extra_execution_platforms=//build/platforms:darwin-x86_64
```

Background is, if you were to set these flags in the .bazelrc file, 
you would need to specify the platform in the `--extra_execution_platforms` flag for which
you would have to declare an Apple LLVM toolchain and install the Apple XCode tools on all potential hosts including linux.
This is impractical when your CI is running on linux, but some team members use Macbooks for development.
Instead, you can just wrap the Bazel build, run, and test commands in a script on a Mac and just append these flags
so that all targets are built and tested while your CI and remaining teams remains unaffected.
