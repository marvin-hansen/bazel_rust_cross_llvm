# Cross Compilation

Pure LLVM setup. No MUSL. 

For cross compilation, you have to specify a custom platform to let Bazel know that you are compiling for a different platform than the default host platform.

The example code is setup to cross compile from the following hosts to the the following targets:

* {linux, x86_64} -> {linux, aarch64}
* {linux, aarch64} -> {linux, x86_64}
* {darwin, x86_64} -> {linux, x86_64}
* {darwin, x86_64} -> {linux, aarch64}
* {darwin, aarch64 (Apple Silicon)} -> {linux, x86_64}
* {darwin, aarch64 (Apple Silicon)} -> {linux, aarch64}


You cross-compile by calling the target.

`bazel build //:hello_world_x86_64`

or

`bazel build //:hello_world_aarch64`


You can also build all targets at once:
 

`bazel build //...`

And you can run all test with:

`bazel test //...`

If you need a custom sysroot i.e. to cross compile system dependencies such as openssl, postgres or similar, read through the excellent tutorial by Steven Casagrande:

https://steven.casagrande.io/posts/2024/sysroot-generation-toolchains-llvm/