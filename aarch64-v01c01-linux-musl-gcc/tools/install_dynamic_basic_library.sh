#!/bin/bash

help_commands=(help -h --help)
target_triple_list=(arm-linux-gnueabi \
                    aarch64-linux-gnu \
                    aarch64-linux-musleabi \
                    aarch64-liteos-eabi \
                    arm-linux-musleabi \
                    arm-liteos-eabi)
mcpu_abi_mfpu_list=(armv5te_arm9_soft \
                    a9_soft a9_softfp_vfp \
                    a9_softfp_vfpv3-d16 \
                    a9_softfp_vfpv3 \
                    a9_softfp_neon \
                    a9_hard_neon \
                    a9_hard_vfpv3-d16 \
                    a9_hard_neon-vfpv4 \
                    a7_hard_vfpv4-d16 \
                    a7_soft \
                    a7_softfp_neon-vfpv4 \
                    a7_hard_neon-vfpv4 \
                    a17_soft \
                    a17_softfp_neon-vfpv4 \
                    a17_hard_neon-vfpv4 \
                    a17_a7_soft \
                    a17_a7_softfp_neon-vfpv4 \
                    a17_a7_hard_neon-vfpv4 \
                    a53_soft \
                    a53_softfp_neon-vfpv4 \
                    a53_hard_neon-vfpv4 \
                    a55_soft \
                    a55_softfp \
                    a55_hard \
                    a73_soft \
                    a73_softfp_neon-vfpv4 \
                    a73_hard_neon-vfpv4 \
                    a73_a53_soft \
                    a73_a53_softfp_neon-vfpv4 \
                    a73_a53_hard_neon-vfpv4\
                    r8_soft)

target_triple=arm-linux-gnueabi
mcpu_abi_mfpu=
install_path=
toolchain_path=

function show_help()
{
    echo ""
    echo "usage:"
    echo "  ./install_dynamic_basic_library.sh toolchain_path install_path  mcpu_abi_mfpu"
    echo ""
    echo "optional arguments:"
    echo "  toolchain_path         toolchain root path"
    echo "  install_path           dynamic library install path"
    echo "  mcpu_abi_mfpu          Combination identifier of mcpu, mfloat_abi, and mfpu. Optional Parameters, (default: '')"
    echo "                         If mcpu is cortex-a17, mfloat_abi is hard, and mfpu is neon-vfpv4, the identifier is a17_hard_neon-vfpv4."
    echo "                         ALL the identifiers list:"
    for i in ${mcpu_abi_mfpu_list[*]}; do
    echo "                         ${i}";
    done
    echo ""
}

function show_current_configuration()
{
    echo ""
    echo "all parameters in script as follow"
    echo "  toolchain_path              :${toolchain_path}"
    echo "  install_path                :${install_path}"
    echo "  mcpu_abi_mfpu               :${mcpu_abi_mfpu}"
    echo ""
}

function error_exit()
{
    echo $1
    echo "Try '--help' for more information"
    exit 1
}

function get_target_name()
{
    for name in ${target_triple_list[@]} ; do
        if [[ -d ${toolchain_path}/$name ]] ; then
            target_triple=$name
            echo "toolchain target is ${name}."
        fi
    done
}

function proc_args()
{
    if [[ $# -eq 0 ]] ; then
        echo ""
        echo "Parameters must be set!"
        show_help
        exit 1

    elif [[ $# -eq 1  && ${help_commands[@]} =~ $1 ]]  ; then
        show_help
        exit 1

    elif [[ $# -eq 2 ]] ; then
        if [[ ! -d $1 ]] ; then
            echo "Parameters Error, toolchain_path not exist."
            exit 1
        fi
        toolchain_path=$1
        install_path=$2

    elif [[ $# -eq 3 ]] ; then
        if [[ ! -d $1 ]] ; then
            echo "Parameters Error, toolchain_path not exist."
            exit 1
        fi
        toolchain_path=$1
        install_path=$2
        for i in ${mcpu_abi_mfpu_list[@]} ; do
		    if [[ $i == $3 ]] ; then
                mcpu_abi_mfpu=$3
                break
            fi
        done
        if [[ ${mcpu_abi_mfpu} != $3 ]] ; then
            echo "Parameters Error, parameters:$3 not support."
            echo "Support parameters:"
            echo "${mcpu_abi_mfpu_list[*]}"
            exit 1
        fi

    else
        echo ""
        echo "Parameters Error!"
        show_help
        exit 1
    fi

    get_target_name

    show_current_configuration
}

function install_dynamic_basic_library()
{
    if [ ! -d ${toolchain_path} ] ; then
        return
    fi

    echo "install dynamic library start..."

    set -x

    if [[ ${target_triple} == *linux* ]] ; then
        if [ ! -d ${install_path}/lib ] ; then
            mkdir -p ${install_path}/lib
        fi
        arch=
        if [[ ${target_triple} == aarch64* ]] ; then
            arch=64
            if [ ! -d ${install_path}/lib64 ] ; then
                mkdir -p ${install_path}/lib64
            fi
        fi
        if [[ ${target_triple} == *gnu* ]] ; then
            cp -d ${toolchain_path}/target/lib/${mcpu_abi_mfpu}/ld-*  ${install_path}/lib
            cp -d ${toolchain_path}/target/lib/${mcpu_abi_mfpu}/lib*  ${install_path}/lib${arch}
            cp -d ${toolchain_path}/target/usr/lib/${mcpu_abi_mfpu}/libtirpc.so* ${install_path}/lib${arch}
        elif [[ ${target_triple} == *musl* ]] ; then
            cp -d ${toolchain_path}/target/usr/lib/${mcpu_abi_mfpu}/*.so* ${install_path}/lib${arch}
            if [[ ${target_triple} == "aarch64-linux-musleabi" ]] ; then
                if [ ! -d ${install_path}/etc ] ; then
                    mkdir -p ${install_path}/etc
                fi
                cp -f ${toolchain_path}/target/usr/etc/ld-musl-aarch64.path ${install_path}/etc
                rm -rf ${install_path}/lib64/ld-musl-aarch64.so.1
                rm -f ${install_path}/lib/ld-musl-aarch64.so.1
                cd ${install_path}/lib;ln -s /lib64/libc.so ld-musl-aarch64.so.1;cd -
            fi
        fi
        cp -d ${toolchain_path}/${target_triple}/lib${arch}/${mcpu_abi_mfpu}/libstdc++.so* ${install_path}/lib${arch}
        cp -d ${toolchain_path}/${target_triple}/lib${arch}/${mcpu_abi_mfpu}/libgcc_s.so.1 ${install_path}/lib${arch}
        cp -d ${toolchain_path}/${target_triple}/lib${arch}/${mcpu_abi_mfpu}/libatomic.so* ${install_path}/lib${arch}
        cp -d ${toolchain_path}/${target_triple}/lib${arch}/${mcpu_abi_mfpu}/libgomp.so* ${install_path}/lib${arch}
        cd ${install_path}/lib${arch}; rm -f libgcc_s.so; ln -s libgcc_s.so.1 libgcc_s.so; cd -
        rm -f ${install_path}/lib${arch}/*.py
    elif [[ ${target_triple} == *liteos* ]] ; then
        echo "not support liteos install dynamic library."
    fi

    set +x

    echo "install dynamic library end..."
}

proc_args $@

install_dynamic_basic_library
