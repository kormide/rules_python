#!/usr/bin/env bash

set -o errexit -o nounset -o pipefail

# Set by GH actions, see
# https://docs.github.com/en/actions/learn-github-actions/environment-variables#default-environment-variables
TAG=${GITHUB_REF_NAME}
PREFIX="rules_python-${TAG}"
SHA=$(git archive --format=tar --prefix=${PREFIX}/ ${TAG} | gzip | shasum -a 256 | awk '{print $1}')

cat << EOF
Using Bzlmod with Bazel 6

Add to your \`MODULE.bazel\` file:

\`\`\`starlark
bazel_dep(name = "rules_python", version = "${TAG}")

pip = use_extension("@rules_python//python:extensions.bzl", "pip")

pip.parse(
    name = "pip",
    requirements_lock = "//:requirements_lock.txt",
)

use_repo(pip, "pip")
\`\`\`

Using WORKSPACE:

Paste this snippet into your \`WORKSPACE\` file:

\`\`\`starlark
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
http_archive(
    name = "rules_python",
    sha256 = "${SHA}",
    strip_prefix = "${PREFIX}",
    url = "https://github.com/bazelbuild/rules_python/archive/refs/tags/${TAG}.tar.gz",
)
\`\`\`
EOF
