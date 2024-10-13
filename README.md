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

This tests if each binary has been compiled for the correct platform.

# Sysroot

The example comes already pre-configured with a generic sysroot for Linux on Intel and ARM that should cover the most common uses cases. See the LLVM section in MODULE.bazel for details. 

If you need a custom sysroot i.e. to cross compile system dependencies such as openssl, postgres or similar, read through the excellent tutorial by Steven Casagrande:

https://steven.casagrande.io/posts/2024/sysroot-generation-toolchains-llvm/

## Dependencies

Rust dependencies are vendored in the thirdparty directory.

When you want to add or update dependencies, add them to the `thirdparty` directory
and then run:

`bazel run //thirdparty:crates_vendor`

I've added a number of example dependencies already, among others:

* libpq (postgres)
* lz4-sys
* diesel
* tokio

Notice, none of these crates actually need a sysroot and you can cross compile all of them with MUSL or the Zig C compiler. Conventionally, postgres would require a sysroot, but the pg-sys vendors and patches libpq so that it can be statically linked and cross compiled with any recent C compiler. See the [libpq repo](https://github.com/brainhivenl/libpq) for details. 