#!/usr/bin/env python3

import os
import sys
import re
import argparse

version = '1.0'
description = f'Makefile generator and runner'

class Target:
    def __init__(self, file, path='.'):
        self.file = file
        self.path = path
        self.name = file.rsplit('.', 1)[0]
        self.deps = []
        self._find_deps(file)

    def _find_deps(self, file):
        cmd_result = run_cmd(f'g++ -MM {file}')
        cmd_result = cmd_result.replace('\\', '')
        cmd_result = cmd_result.replace('\n', '')
        # parse the result
        dep_files = cmd_result.split()[1:]
        header_files = [f for f in dep_files if f.endswith('.h') or f.endswith('.hpp')]
        cpp_source_files = [f for f in dep_files if f.endswith('.cpp')]
        c_source_files = [f for f in dep_files if f.endswith('.c')]
        all_source_files = cpp_source_files + c_source_files
        self.deps += [f.rsplit('.', 1)[0] + '.o' for f in all_source_files]

        all_cpp_files = [f for f in os.listdir(self.path) if f.endswith('.cpp')]
        all_c_files = [f for f in os.listdir(self.path) if f.endswith('.c')]

        # check if the header files have corresponding source files
        for header in header_files:
            header_name = header.rsplit('.', 1)[0]
            header_as_cpp = header_name + '.cpp'
            header_as_c = header_name + '.c'
            header_as_obj = header_name + '.o'
            if header_as_obj in self.deps:
                    continue
            elif header_as_cpp in all_cpp_files:
                self._find_deps(header_as_cpp)
            elif header_as_c in all_c_files:
                self._find_deps(header_as_c)

    def __str__(self):
        return f'{" ".join(self.deps)}'

    def __repr__(self):
        return f'{self.name}: {" ".join(self.deps)}'

def find_all_targets(path):
    files = [f for f in os.listdir(path) if f.endswith('.cpp') or f.endswith('.c')]
    targets = []
    for file in files:
        with open(f'{path}/{file}', 'r') as f:
            content = f.read()
            if re.search(r'\bmain\b', content):
                targets.append(Target(file, path))
    return targets

def run_cmd(cmd, show_output=False):
    import subprocess
    if show_output:
        result = subprocess.run(cmd, shell=True)
    else:
        try:
            result = subprocess.run(cmd, shell=True, check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        except subprocess.CalledProcessError as e:
            print(e.stderr.decode())
            return None
        return result.stdout.decode()

def get_deps(path):
    # check if the path contains .c files
    cfiles = [f for f in os.listdir(path) if f.endswith('.c')]
    cppfiles = [f for f in os.listdir(path) if f.endswith('.cpp')]

    cmd = 'g++ -MM ' + ' '.join(cfiles + cppfiles)

    deps = run_cmd(cmd)

    return deps

def find_target(path, files):
    for f in files:
        with open(f'{path}/{f}', 'r') as file:
            content = file.read()
            if re.search(r'\bmain\b', content):
                # remove the file extension
                return f.rsplit('.', 1)[0]
    return None

def generate_makefile(path, debug=False):
    # find the target
    targets = find_all_targets(path)
    if len(targets) == 0:
        print(f'Error: No target found in {path}')
        sys.exit(1)

    # write the Makefile
    with open(f'{path}/Makefile', 'w') as makefile:
        # Header
        makefile.write(f'# Makefile auto generated by mk {version}\n#\n')
        makefile.write(f'# Targets:\n')
        for target in targets:
            makefile.write(f'# - {target.name}\n')
        makefile.write('\n')

        # Compiler Options
        makefile.write(f'# Compiler Options:\n')
        makefile.write(f'CC = g++\n')                                       # default compiler
        makefile.write(f'CPPFLAGS = -Wall -Wextra -Wpedantic\n')            # default cpp flags
        if (debug):
            makefile.write(f'CPPFLAGS += -ggdb\n')                          # debug flags
        makefile.write(f'LDFLAGS = -lm\n\n')                                # default linker flags

        for target in targets:
            target_name_all_caps = target.name.upper()
            makefile.write(f'{target_name_all_caps}_EXE = {target.name}\n') # target name
        makefile.write('\n')

        makefile.write(f'# Options from .mk file:\n')
        # read the .mk file and copy its contents into the makefile here:
        # check for new line at the end and add one if it doesn't exist
        with open(f'{path}/.mk', 'r') as mkfile:
            mkfile_contents = mkfile.read()
            if (len(mkfile_contents) != 0):
                if mkfile_contents[-1] != '\n':
                    mkfile_contents += '\n'
                makefile.write(mkfile_contents)
                makefile.write('\n')

        # Object Files
        makefile.write(f'# Object Files:\n')
        for target in targets:
            target_name_all_caps = target.name.upper()
            makefile.write(f'{target_name_all_caps}_OBJS = {" \\\n ".join(target.deps)}\n')
        makefile.write('\n')                                         # object files

        # Phony Targets
        makefile.write(f'# Phony Targets:\n')
        makefile.write(f'.PHONY: all clean\n\n')                            # phony targets

        # All Targets
        makefile.write(f'# All Targets:\n')
        makefile.write('all: ')
        target_names = [f"$({t.name.upper()}_EXE)" for t in targets]
        makefile.write(' \\\n '.join(target_names) + '\n\n')                         # default target

        # Targets
        makefile.write(f'# Targets:\n')
        for target in targets:
            target_name_all_caps = target.name.upper()
            exec_name = f'$({target_name_all_caps}_EXE)'
            makefile.write(f'{exec_name}: $({target_name_all_caps}_OBJS)\n')                      # target
            makefile.write(f'\t$(CC) $(CPPFLAGS) $({target_name_all_caps}_OBJS) -o {exec_name} $(LDFLAGS)\n')
        makefile.write('\n')

        # Clean
        makefile.write(f'# Clean:\n')
        makefile.write(f'clean:\n')                                         # clean
        for target in targets:
            target_name_all_caps = target.name.upper()
            makefile.write(f'\trm -f $({target_name_all_caps}_EXE) $({target_name_all_caps}_OBJS)\n')
        makefile.write('\n')

        # Rules
        makefile.write(f'# Rules:\n')
        makefile.write(f'.cpp.o:\n')                                        # rules for .cpp files
        makefile.write(f'\t$(CC) $(CPPFLAGS) -c $< -o $@\n')
        makefile.write(f'.c.o:\n')                                          # rules for .c files
        makefile.write(f'\t$(CC) $(CPPFLAGS) -c $< -o $@\n\n')

        # Dependencies
        makefile.write(f'# Dependencies:\n')
        makefile.write(get_deps(path))                                      # dependencies

def run_make(make_args):
    cmd = 'make ' + ' '.join(make_args)
    run_cmd(cmd, show_output=True)

def print_overwrite_warning(path):
    if (path == '.'):
        print(f'Warning: This will overwrite the Makefile in the current directory')
    else:
        print(f'Warning: This will overwrite the Makefile in {path}')

def build_make_args(args):
    make_args = []
    if args.jobs:
        make_args.append(f'-j {args.jobs}')
    if args.always_make:
        make_args.append('-B')
    if args.clean:
        make_args.append('clean')
    return make_args

def main(args):
    path = args.path
    if not os.path.exists(path):
        print(f'Path {path} does not exist')
        sys.exit(1)

    # if the path doesnt contain a .mk file exit with a warning that it will overwrite the Makefile
    if not os.path.exists(f'{path}/.mk'):
        print(f'Error: no .mk file found. Create this file to use mk, you can specify a custom target in the first line if so desired')
        print_overwrite_warning(path)
        sys.exit(1)

    generate_makefile(path, args.debug)

    if args.run:
        make_args = build_make_args(args)
        run_make(make_args)

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=f'{description} {version}')
    parser.add_argument('path', nargs='?', default='.')
    parser.add_argument('-j', '--jobs', type=int, help='number of jobs to run simultaneously')
    parser.add_argument('-B', '--always-make', action='store_true', help='unconditionally make all targets')
    parser.add_argument('-v', '--version', action='version', version=version)
    parser.add_argument('-c', '--clean', action='store_true', help='clean the directory')
    parser.add_argument('-g', '--debug', action='store_true', help='print debug information')
    parser.add_argument('-r', '--run', action='store_true', help='run the make command')
    main(parser.parse_args())
