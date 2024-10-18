load("@rules_oci//oci:defs.bzl", "oci_image", "oci_image_index")
load("@rules_pkg//pkg:tar.bzl", "pkg_tar")
load("//:build/transition.bzl", "multi_arch")

# Build a Bazel Macro
# https://belov.nz/posts/bazel-rules-macros/
# https://codilime.com/blog/bazel-build-system-build-containerized-applications/

def build_multi_arch_image(
        name,
        entry_point,
        base,
        srcs,
        exposed_ports = [],
        platforms = [],
        visibility = None):
    layer_name = "tar_layer"

    # Compress binary to a layer using pkg_tar
    pkg_tar(
        name = layer_name,
        srcs = srcs,
    )

    # Build container image
    oci_image(
        name = "image",
        base = base,
        tars = [layer_name],
        entrypoint = ["/{}".format(entry_point)],
        exposed_ports = exposed_ports,
    )

    # Build multi-arch image using platform transition defined in //build/transition.bzl
    multi_arch(
        name = "multi_arch_images",
        image = ":image",
        platforms = platforms,
    )

    oci_image_index(
        name = name,
        images = [
            ":multi_arch_images",
        ],
        visibility = visibility,
    )

def build_image(name, srcs, base, exposed_ports = [], visibility = None):
    entry_point = "bin"
    layer_name = "tar_layer"

    # Compress binary to a layer using pkg_tar
    pkg_tar(
        name = layer_name,
        srcs = srcs,
    )

    # Build container image
    # https://github.com/bazel-contrib/rules_oci/blob/main/docs/image.md
    oci_image(
        name = name,
        base = base,
        tars = [layer_name],
        entrypoint = ["/{}".format(entry_point)],
        exposed_ports = exposed_ports,
        visibility = visibility,
    )

# Produces an image tag based on the existing image sha286 and and UTC timestamp.
# Timestamp format is YYYY MM DD HH MM SS i.e. 2024 10 13 08 38 54, UTC
def tag_with_sha265(name, target, src):
    native.genrule(
        name = name,
        srcs = [src],
        outs = ["_tag.txt"],
        stamp = True,
        cmd = """
           IMAGE_HASH=$$(cat $(location """ + src + """) | sed 's/^sha256://' | cut -c1-8 || :)
           TIMESTAMP=$$(date -u +"%Y%m%d%H%M%S")
           echo $${IMAGE_HASH}-$${TIMESTAMP} > $(OUTS);
           """,
    )

# Produces an image tag based on the current git commit and Unix timestamp of the current build.
# For example: 458b6779-1729045897
def tag_with_commit_and_timestamp(name, target):
    stable_status = "//build/status:stable_status"
    volatile_status = "//build/status:volatile_status"
    native.genrule(
        name = name,
        srcs = [target, stable_status, volatile_status],
        outs = ["_tag.txt"],
        stamp = True,
        cmd = """
            STABLE_RELEASE_VERSION=$$(cat $(location """ + stable_status + """) | grep 'STABLE_GIT_COMMIT' | awk '{print $$2}' || :)
            STABLE_TIMESTAMP=$$(cat $(location """ + volatile_status + """) | grep 'BUILD_TIMESTAMP' | awk '{print $$2}' || :)
            echo $${STABLE_RELEASE_VERSION}-$${STABLE_TIMESTAMP} > $(OUTS);
            """,
    )
