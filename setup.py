from setuptools import Extension, setup

setup(
    packages=["tree_sitter_mojo"],
    package_dir={"": "bindings/python"},
    ext_modules=[
        Extension(
            name="tree_sitter_mojo._binding",
            sources=[
                "bindings/python/tree_sitter_mojo/binding.c",
                "src/parser.c",
                "src/scanner.c",
            ],
            include_dirs=["src"],
        )
    ],
)
