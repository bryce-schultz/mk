# mk - Makefile Generator

`mk` is a Makefile generator that simplifies the process of creating and managing Makefiles. It reads a `.mk` configuration file which may be left blank
to ensure the user accepts that it will override any Makefile where mk is ran.

## Features

- Generates Makefiles from a project structure
- Supports building multiple exes
- Supports various command-line arguments
- Builtin include dir support (INCLUDE_DIRS)

## TODOS

- Add a way to configure the default compiler and other options, maybe a .mkconf file in ~
- Per target include dirs

## Installation

To install `mk`, simply clone the repository and navigate to the project directory:

```sh
git clone https://github.com/bryce-schultz/mk.git
cd mk
```

You can then copy mk to either a local project folder or a bin folder.

## Usage

To use `mk`, create a `.mk` file in the directory where you want to generate the `Makefile`. Then, run the `mk` command:

```sh
mk [options]
```

### Command-Line Arguments

`mk` accepts several command-line arguments:

```
-h, --help            show this help message and exit
-j JOBS, --jobs JOBS  number of jobs to run simultaneously when used with --run
-B, --always-make     unconditionally make all targets when used with --run
-v, --version         show program's version number and exit
-c, --clean           clean the directory
-g, --debug           enable debug flags
-r, --run             run the make command
```

### `.mk` File

The `.mk` file may contain additional configuration options for generating the `Makefile`, but may also be left empty for the default expierence. Here is an example of a simple `.mk` file:

```mk
CPPFLAGS += -g # add debugging to the compile options
MAIN_EXE = calculator # change the name of the exe made from main.cpp
INCLUDE_DIRS = /path/to/include
```

Executable files will have a variable target created called `<FILENAME>_EXE` and so it can be overriden for any executable. For example `main.cpp` would become `MAIN_EXE`, `book_program.c` would become `BOOK_PROGRAM_EXE`, and `FunProgram.cpp` would become `FUNPROGRAM_EXE`.

## Example

1. Run the `mk` command:

    ```sh
    mk
    ```

2. A `Makefile` will be generated and it will use any options specified in the `.mk` file. You can now run `make` as usual.

    ```sh
    make
    ```
