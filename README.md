# Cross Compilation

Pure LLVM setup. No MUSL. 

For cross compilation, you have to specify a custom platform to let Bazel know that you are compiling for a different platform than the default host platform.

The example code is setup to cross compile from the following hosts to the the following targets:

* {linux, x86_64} -> {linux, aarch64}
* {linux, aarch64} -> {linux, x86_64}
* {darwin, aarch64 (Apple Silicon)} -> {linux, x86_64}
* {darwin, aarch64 (Apple Silicon)} -> {linux, aarch64}

MacOS on x86_64 (Intel) may work, but has not been tested. 

You cross-compile by calling the target for each platform: 

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

If you need a custom sysroot i.e. to cross compile system dependencies such as openssl or similar, read through the excellent tutorial by Steven Casagrande:

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

Notice, none of these crates actually need a sysroot to build so you can cross compile all of them with 
either LLVM, MUSL or the Zig C compiler a.k.a the hermetic C toolchain. 
The sysroot is only there to showcase how configure one and to ensure that most dependencies you add over time  
work out of the box on all supported platforms.

Conventionally, postgres would require a sysroot, but the pg-sys module vendors and patches libpq 16.4 
so that it can be statically linked and cross compiled with any recent C compiler. 
See the [libpq repo](https://github.com/brainhivenl/libpq) for details. 

## Small LLVM

This repository comes with two additional branches:

* `small-clang`: Replaces the full LLVM toolchain with a smaller version that only contains CLang and a few tools.
* `llvm_musl`: Only declares a small host clang toolchain and uses MUSL to cross compile all other targets.

The motivation for small-clang is that it is a much smaller toolchain, about 10% the size of the full llvm toolchain
and therefore reduces download times especially on clean CI builds.

The motivation for llvm_musl is that MUSL simply compiles significantly faster than the full llvm toolchain. Ideally,
MUSL could also be used as host toolchain, but that has been proven complex to configure due to an issue with how
rules_rules identify the host toolchain on Linux. On MacOS, MUSL works as host toolchain, on Linux (X86_64) it does not,
hence the need for llvm as host toolchain.
