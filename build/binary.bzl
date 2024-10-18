load("@rules_rust//rust:defs.bzl", "rust_binary")

def build_binary_opt(name, srcs, deps = [], visibility = ["//visibility:public"]):
    # Build optimized Rust binary
    rust_binary(
        name = name,
        srcs = srcs,
        crate_root = "src/main.rs",
        rustc_flags = select({
            "//:release": [
                "-Clto=true",
                "-Ccodegen-units=1",
                "-Cpanic=abort",
                "-Copt-level=3",
                "-Cstrip=symbols",
            ],
            "//conditions:default": [
                "-Copt-level=0",
            ],
        }),
        tags = [
            name,
            "binary",
            "service",
        ],
        deps = deps,
        visibility = visibility,
    )
