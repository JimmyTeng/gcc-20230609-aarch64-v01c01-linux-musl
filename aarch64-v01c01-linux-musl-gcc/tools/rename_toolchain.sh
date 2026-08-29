#!/bin/bash

original_prefix_name=(aarch64-linux-musleabi aarch64-linux-gnu aarch64-linux-musl arm-linux-gnueabi arm-linux-musleabi)
toolchain_path=
prefix_name=

function show_help()
{
    echo ""
    echo "Usage:"
    echo "  ./rename_toolchain.sh toolchain_path prefix_name"
    echo "  toolchain_path is the path of toolchain executable file"
    echo "  prefix_name is the alias to be renamed"
    echo ""
}

function show_current_configuration()
{
    echo ""
    echo "All parameters in script as follow"
    echo "  toolchain_path              :${toolchain_path}"
    echo "  prefix_name                 :${prefix_name}"
    echo ""
}

function proc_rename_args()
{
    if [[ ($# -gt 2) || ($# -le 1) ]] ; then
        show_help
        exit 0
    fi

    toolchain_path=$1
    prefix_name=$2

    if [[ ! -d ${toolchain_path} ]]  ; then
        echo "The toolchain directory does not exist."
        exit 0
    fi

    show_current_configuration
}


function ln_command_to_rename()
{
    old_prefix=$1
    rm -f $prefix_name-*
    ln -s ./$old_prefix-cpp        $prefix_name-cpp
    ln -s ./$old_prefix-gcc        $prefix_name-gcc
    ln -s ./$old_prefix-gcc-ar     $prefix_name-gcc-ar
    ln -s ./$old_prefix-gcc-nm     $prefix_name-gcc-nm
    ln -s ./$old_prefix-gcc-ranlib $prefix_name-gcc-ranlib
    ln -s ./$old_prefix-gcov       $prefix_name-gcov
    ln -s ./$old_prefix-gcov-tool  $prefix_name-gcov-tool
    ln -s ./$old_prefix-c++        $prefix_name-c++
    ln -s ./$old_prefix-g++        $prefix_name-g++
    ln -s ./$old_prefix-gprof      $prefix_name-gprof
    ln -s ./$old_prefix-ld         $prefix_name-ld
    ln -s ./$old_prefix-ld.bfd     $prefix_name-ld.bfd
    ln -s ./$old_prefix-as         $prefix_name-as
    ln -s ./$old_prefix-c++filt    $prefix_name-c++filt
    ln -s ./$old_prefix-elfedit    $prefix_name-elfedit
    ln -s ./$old_prefix-nm         $prefix_name-nm
    ln -s ./$old_prefix-strip      $prefix_name-strip
    ln -s ./$old_prefix-addr2line  $prefix_name-addr2line
    ln -s ./$old_prefix-ar         $prefix_name-ar
    ln -s ./$old_prefix-objcopy    $prefix_name-objcopy
    ln -s ./$old_prefix-objdump    $prefix_name-objdump
    ln -s ./$old_prefix-ranlib     $prefix_name-ranlib
    ln -s ./$old_prefix-readelf    $prefix_name-readelf
    ln -s ./$old_prefix-size       $prefix_name-size
    ln -s ./$old_prefix-strings    $prefix_name-strings
    ln -s ./$old_prefix-gcc-10.3.0 $prefix_name-gcc-10.3.0
    ln -s ./$old_prefix-lto-dump   $prefix_name-lto-dump
    ln -s ./$old_prefix-gcov-dump  $prefix_name-gcov-dump
    if [ -f ./$old_prefix-run ]; then
        ln -s ./$old_prefix-run    $prefix_name-run
    fi

    if [ -f ./$old_prefix-gdb ]; then
       ln -s ./$old_prefix-gdb    $prefix_name-gdb
       ln -s ./$old_prefix-gdb-add-index    $prefix_name-gdb-add-index
    fi
}

function rename_toolchain()
{
    echo "Rename toolchain command start..."

    cd ${toolchain_path}
    for val in ${original_prefix_name[@]}; do
        if [[ -f ${val}-gcc ]] ; then
            ln_command_to_rename $val
        fi
    done

    cd -

    echo "Rename toolchain command end..."
}

proc_rename_args $@

rename_toolchain
