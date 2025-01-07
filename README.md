# MUSL Cross Compilation

This branch uses only the MUSL toolchain for cross compiling with static linking for Linux X86 and Aarch64 (ARM64) targets

The example code is setup to cross compile from the following hosts to the the following targets:

* {linux, x86_64} -> {linux, aarch64/MUSL}
* {darwin, aarch64 (Apple Silicon)} -> {linux, x86_64/MUSL}
* {darwin, aarch64 (Apple Silicon)} -> {linux, aarch64/MUSL}

You cross-compile by calling the target for each platform:

`bazel build //:hello_linux_x86_64_musl`

`bazel build //:hello_linux_arm64_musl`

or

`bazel build //:all`

You can also build all targets all at once:

`bazel build //...`

And you can run all test with:

`bazel test //...`

This tests if each binary has been compiled for the correct platform.

## Release optimization

You can build a release binaries with:

`bazel build --copt //...`

The following release optimization is enabled by default:

* LTO
* optlevel=3
* codegen-units=1
* Strip symbols

For details of the release config, see the[ build_binary_opt rule](build/binary.bzl) in the build folder.

## MUSL toolchain configuration

The MUSL configuration comprises of three steps:

1) Define platform targets and linker settings

See the [platform definition ](build/platforms/BUILD.bazel) and linker [configuration](build/linker_config/BUILD.bazel)
in the build folder.

2) Setup target triplets, the Rust and MUSL toolchain

See the[MODULE.bazel](MODULE.bazel)file in the project root.

Run a quick bazel build to see if all toolchains resolve correctly.

3) Configure your binaries

You can use a simple rust binary rule and refer to the platform targets i.e.

```text
rust_binary(
    name = "hello_linux_x86_64_musl",
    srcs = ["src/main.rs"],
    platform = "//build/platforms:linux_x86_64_musl",
    deps = [
        ...
    ],
)
```

However, in practice you usually want to apply compiler optimization and some other custom settings.
For that case, you can use the [build_binary_opt rule](build/binary.bzl) in the build folder. You use that rule
by importing it and then, similar to the normal rust rule, declare the sources and dependencies. Note, there is no need
to declare a target platform. For that, you can either use platform transition rule or, if the delivery is a multi-arch
image, you can use the image rule.

```text
load("//:build/binary.bzl", "build_binary_opt")
 
build_binary_opt(
    name = "hello_world_bin",
    srcs = ["src/main.rs"],
    deps = [
        ... 
    ],
)
```

## OCI image

You can build the multi-arch image with:

`bazel build //:image_index`

Which the produces a multi-arch image for aarch64 and x86_64.
The base image is a scratch image from the Docker registry.

As mentioned earlier, you can also use the [build_multi_arch_image rule](build/container.bzl) to build a multi-arch
image.
Here, you specify the target platform and the rule applies the appropriate linker and toolchain configuration
automatically
using a platform transition rule. Furthermore, you may want to add a container tag and a push rule to publish the final
image.

```text
load("//:build/container.bzl", "build_multi_arch_image", "git_with_timestamp_tag")
  
build_multi_arch_image(
    name = "image_index",
    srcs = ["hello_world_bin"],
    base = "@scratch",
    entry_point = "hello_world_bin",
    exposed_ports = [
        "7070",
    ],
    platforms = [
       "//build/platforms:linux_x86_64_musl",
       "//build/platforms:linux_arm64_musl",
    ],
    visibility = ["//visibility:public"],
)

git_with_timestamp_tag(
    name = "remote_tag",
    target = ":image_index",
)

oci_push(
    name = "push",
    image = ":image_index",
    remote_tags = ":remote_tag",
    repository = "my_registry/my_project/my_repo/my_image",
    visibility = ["//visibility:public"],
)  
```

The bulk of the settings are rather self-explanatory. As for the tag, there are actually multiple ways to tag OCI
images.
One way is to produces an image tag based on the existing image sha265 hash, albeit in a short form, for example :
458b6779
For that, you have to replace the git_with_timestamp_tag rule with the sha265_tag rule. The benefit is that the image
will remain the
same when the binary has not changed and with that no rebuild and no upload will happen and that might be of interest
when
you have a large number of container images.

The other way is to produces an image tag based on the current git commit and Unix timestamp of the current build.
For example: 44b024cf-1729230173. The benefit here is that the image will become sortable by timestamp and that
helps with CI systems such as FluxCD that require sortable image tags. The downside is, that, when the image remains
the same, but a new build changes the git commit, the timestamp, or both, your image will accumulate multiple tags over
time.

In practice, you may use sha265 tags during development as long as no deployment is involved and later, when deployment
is involved,
you can switch to a more appropriate image tag convention that supports your CI/CD system.

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

Conventionally, postgres would require a sysroot, but the pg-sys module vendors and patches libpq 16.4
so that it can be statically linked and cross compiled with any recent C compiler.
See the [libpq repo](https://github.com/brainhivenl/libpq) for details. 
