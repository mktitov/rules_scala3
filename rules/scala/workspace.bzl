load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive", "http_file")
load("@bazel_tools//tools/build_defs/repo:jvm.bzl", "jvm_maven_import_external")
load("@rules_jvm_external//:defs.bzl", "maven_install")

_SRC_FILEGROUP_BUILD_FILE_CONTENT = """
filegroup(
    name = "src",
    srcs = glob(["**/*.scala", "**/*.java"]),
    visibility = ["//visibility:public"]
)

filegroup(
    name = "meta",
    srcs = glob(["META-INF/**"], allow_empty = False),
    visibility = ["//visibility:public"]
)
"""

zinc_version = "1.5.0-M3"

def scala_artifacts():
    return [
        "net.sourceforge.argparse4j:argparse4j:0.8.1",
        "org.jacoco:org.jacoco.core:0.7.5.201505241946",
        "com.lihaoyi:sourcecode_2.13:0.2.1,",
        "org.scala-sbt:test-interface:1.0",
        "org.scala-sbt:util-interface:1.4.6",
        "org.scala-sbt:util-logging_2.13:1.4.6",
        "org.scala-sbt:zinc_2.13:" + zinc_version,
    ]

def scala_repositories(java_launcher_version = "3.7.2"):
    maven_install(
        name = "annex",
        artifacts = scala_artifacts(),
        repositories = [
            "https://repo.maven.apache.org/maven2",
            "https://maven-central.storage-download.googleapis.com/maven2",
            "https://mirror.bazel.build/repo1.maven.org/maven2",
        ],
        fetch_sources = True,
        maven_install_json = "@rules_scala_annex//:annex_install.json",
    )

    http_file(
        name = "anx_java_stub_template",
        sha256 = "a618e746e743f3119a9939e60645a02de40149aae9d63201c3cd05706010f6eb",
        urls = [
            "https://raw.githubusercontent.com/bazelbuild/bazel/" + java_launcher_version + "/src/main/java/com/google/devtools/build/lib/bazel/rules/java/java_stub_template.txt"
        ],
    )

    http_archive(
        name = "compiler_bridge_2_13",
        build_file_content = _SRC_FILEGROUP_BUILD_FILE_CONTENT,
        sha256 = "cd47360da60269bf44b68cf0069c8101119814f8f5b1c9c1961e9c8c7533289e",
        url = "https://repo.maven.apache.org/maven2/org/scala-sbt/compiler-bridge_2.13/" + zinc_version + "/compiler-bridge_2.13-" + zinc_version + "-sources.jar",
    )

def scala_register_toolchains():
    # reserved for future use
    return ()
