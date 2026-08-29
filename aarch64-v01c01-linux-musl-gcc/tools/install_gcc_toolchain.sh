#!/bin/bash

install_path=/opt/linux/x86-arm
if [ -n "$1" ] ; then
	[ -d "$1" ] && install_path=$1
fi

current_path=`pwd`
install_dir=

names=$(ls $current_path)
for dir_name in ${names}
do
    if [ -d ${current_path}/${dir_name} ] ;  then
        install_dir=${dir_name}
        break
    fi
done

set +e

# install gcc toolchain
mkdir -pv ${install_path}

if [ -d ${install_path}/${install_dir} ] ;  then
    rm -rf ${install_path}/${install_dir}
fi

cp -rf ${install_dir} ${install_path}
if [ -f $current_path/runtime_lib.tar.gz ]; then
    cp -rf $current_path/runtime_lib.tar.gz ${install_path}/${install_dir}
    tar -xf ${install_path}/${install_dir}/runtime_lib.tar.gz -C ${install_path}/${install_dir}
fi

# Modify env PATH
toolchain_path=${install_path}/${install_dir}/bin
if [ -z "`grep "${toolchain_path}" < /etc/profile`" ] ; then
	echo "export path ${toolchain_path}" >&2
	cat >> /etc/profile << EOF

# `date`
# ${install_dir}, Cross-Toolchain PATH
export PATH="${toolchain_path}:\$PATH"
#

EOF
	source /etc/profile
else
	echo "skip export toolchains path" >&2
fi
