"Module extensions for use with bzlmod"

load("@rules_python//python:pip.bzl", "pip_parse")
load("@rules_python//python/pip_install:pip_repository.bzl", "locked_requirements_label", "pip_repository_attrs", "use_isolated", "whl_library")
load("@rules_python//python/pip_install:repositories.bzl", "pip_install_dependencies")
load("@rules_python//python/pip_install:requirements_parser.bzl", parse_requirements = "parse")

# buildifier: disable=unused-variable
def _internal_deps_impl(module_ctx):
    pip_install_dependencies()

internal_deps = module_extension(
    implementation = _internal_deps_impl,
    tag_classes = {
        "install": tag_class(attrs = dict()),
    },
)

def _pip_impl(module_ctx):
    for mod in module_ctx.modules:
        for attr in mod.tags.parse:
            requrements_lock = locked_requirements_label(module_ctx, attr)

            # Parse the requirements file directly in starlark to get the information
            # needed for the whl_libary declarations below. This is needed to contain
            # the pip_parse logic to a single module extension.
            requirements_lock_content = module_ctx.read(requrements_lock)
            parse_result = parse_requirements(requirements_lock_content)
            requirements = parse_result.requirements
            extra_pip_args = attr.extra_pip_args + parse_result.options

            # Create the repository where users load the `requirement` macro. Under bzlmod
            # this does not create the install_deps() macro.
            pip_parse(
                name = attr.name,
                requirements_lock = attr.requirements_lock,
                bzlmod = True,
                timeout = attr.timeout,
                python_interpreter = attr.python_interpreter,
                python_interpreter_target = attr.python_interpreter_target,
                quiet = attr.quiet,
            )

            for name, requirement_line in requirements:
                whl_library(
                    name = "%s_%s" % (attr.name, name),
                    requirement = requirement_line,
                    repo = attr.name,
                    repo_prefix = attr.name + "_",
                    annotation = attr.annotations.get(name),
                    python_interpreter = attr.python_interpreter,
                    python_interpreter_target = attr.python_interpreter_target,
                    quiet = attr.quiet,
                    timeout = attr.timeout,
                    isolated = use_isolated(module_ctx, attr),
                    extra_pip_args = extra_pip_args,
                    download_only = attr.download_only,
                    pip_data_exclude = attr.pip_data_exclude,
                    enable_implicit_namespace_pkgs = attr.enable_implicit_namespace_pkgs,
                    environment = attr.environment,
                )

def _pip_parse_ext_attrs():
    attrs = dict({
        "name": attr.string(),
    }, **pip_repository_attrs)

    # Like the pip_parse macro, we end up setting this manually so
    # don't allow users to override it.
    attrs.pop("repo_prefix")

    return attrs

pip = module_extension(
    implementation = _pip_impl,
    tag_classes = {
        "parse": tag_class(attrs = _pip_parse_ext_attrs()),
    },
)
