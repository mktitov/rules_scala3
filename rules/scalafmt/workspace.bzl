load("@rules_jvm_external//:defs.bzl", "maven_install")

def scalafmt_artifacts():
    return [
        "com.geirsson:metaconfig-core_2.13:0.9.15",
        "org.scalameta:parsers_2.13:4.4.31",
        "org.scalameta:scalafmt-core_2.13:3.3.0",
    ]

def scalafmt_repositories():
    maven_install(
        name = "annex_scalafmt",
        artifacts = scalafmt_artifacts(),
        repositories = [
            "https://repo.maven.apache.org/maven2",
            "https://maven-central.storage-download.googleapis.com/maven2",
            "https://mirror.bazel.build/repo1.maven.org/maven2",
        ],
        fetch_sources = True,
        maven_install_json = "@rules_scala3//:annex_scalafmt_install.json",
    )

def scalafmt_default_config(path = ".scalafmt.conf"):
    build = []
    build.append("filegroup(")
    build.append("    name = \"config\",")
    build.append("    srcs = [\"{}\"],".format(path))
    build.append("    visibility = [\"//visibility:public\"],")
    build.append(")")
    native.new_local_repository(name = "scalafmt_default", build_file_content = "\n".join(build), path = "")
