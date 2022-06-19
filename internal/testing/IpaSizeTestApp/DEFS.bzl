load("@fbsource//tools/build_defs:fb_native_wrapper.bzl", "fb_native")

def apple_package_rule(build_type):
    fb_native.apple_package(
        name = "IpaSizeTestAppPackage_" + build_type,
        bundle = ":IpaSizeTestApp_" + build_type,
    )

def apple_bundle_rule(build_type):
    fb_native.apple_bundle(
        name = "IpaSizeTestApp_" + build_type,
        binary = ":IpaSizeTestAppBinary_" + build_type,
        extension = "app",
        info_plist = "Info.plist",
    )

def apple_binary_rule(build_type, build_types):
    fb_native.apple_binary(
        name = "IpaSizeTestAppBinary_" + build_type,
        deps = [":IpaSizeTestAppResources"] + build_types[build_type]["deps"],
        preprocessor_flags = ["-fobjc-arc", "-Wno-objc-designated-initializers"],
        headers = native.glob([
            "*.h",
        ]),
        srcs = native.glob([
            "*.m",
        ]),
        frameworks = [
            "$SDKROOT/System/Library/Frameworks/Foundation.framework",
            "$SDKROOT/System/Library/Frameworks/UIKit.framework",
        ],
    )
