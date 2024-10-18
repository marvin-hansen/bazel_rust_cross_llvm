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

## Secure Chainguard Base Image

Chainguard pioneered the un-distro wolfi and with it the secure base image. Unlike Distroless,
the Chainguard base image does not have Linux Kernel (one less to patch) 
is updated within 24 hours whenever one of its dependencies receives an update. [Rules Apko ](https://github.com/chainguard-dev/rules_apko)take the idea 
one step further and, instead of pulling in an external base image, the base image is updated and build with every
bazel build thus ensuring the Chainguard base image always comes with the latest libc and all available security patches.

That means, instead of late patching whenever a new CVE makes headlines, 
you just rebuild and release with Bazel knowing the latest security patches have already been applied to all of your containers. 

This demo repo has already configured, built and tested the Chainguard base image for the following target platforms:
* linux-x86_64, 
* linux-aarch64

The relevant configuration is stored in the `images/base_image/` folder. If you want to customize the base image i.e. adding sys libraries or packages, please refer to the [official documentation](https://github.com/chainguard-dev/rules_apko?tab=readme-ov-file#usage), edit the  `apko.yaml` file and re-generate the lockfile, as shown below.

However, if you ever encounter a build hiccup related to the base image, 
just regenerate the lock file with the following command:

`
command bazel run @rules_apko//apko lock images/base_image/apko.yaml
`

## OCI Multiarch Image

This example contains a multiarch image derived from the host binary using aspects platform transitions.
For that, a custom rule `build_multi_arch_image` is defined in build/container.bzl. Using this rule means, you define the Rust binary only once for the host platform and this rule does all the heavy lifting for you to create a new binary for each platform and packages them all into a multi-arch OCI image ready to upload to an image registry.

## Sortable OCI image tags

Image tagging comes in two flavors:
* tag_with_sha265
* tag_with_commit_and_timestamp

The first one generates a tag with the sha256 hash of the binary. The second one generates a tag with the current (head) git commit and the timestamp of the build. The example configuration the second one, with git hash and timestamp, to support continuous delivery systems that require unique and sortable image tags.

## Rust Dependencies

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

## Sysroot

The example comes already pre-configured with a generic sysroot for Linux on Intel and ARM that should cover the most common uses cases. See the LLVM section in MODULE.bazel for details.

If you need a custom sysroot i.e. to cross compile system dependencies such as openssl or similar, read through the excellent tutorial by Steven Casagrande:

https://steven.casagrande.io/posts/2024/sysroot-generation-toolchains-llvm/


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
