#!/bin/bash
# 本地初始化：只写本目录 local/，不改 ~/.bashrc、不劫持系统 cmake。
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOLCHAIN_DIR="${PROJECT_ROOT}/aarch64-v01c01-linux-musl-gcc"
LOCAL_DIR="${PROJECT_ROOT}/local"
ENV_FILE="${LOCAL_DIR}/env.sh"
ENV_CROSS="${LOCAL_DIR}/env-cross.sh"
SYSROOT_OVERLAY="${LOCAL_DIR}/sysroot"
RUNTIME_LIB="${PROJECT_ROOT}/runtime_lib.tar.gz"

BASHRC="${HOME}/.bashrc"
BASHRC_BEGIN="# >>> aarch64-linux-musleabi cross toolchain (gcc-20230609) >>>"
BASHRC_END="# <<< aarch64-linux-musleabi cross toolchain (gcc-20230609) <<<"

die() { echo "错误: $*" >&2; exit 1; }

[[ -d "${TOOLCHAIN_DIR}/bin" ]] || die "未找到工具链目录: ${TOOLCHAIN_DIR}"
[[ -x "${TOOLCHAIN_DIR}/bin/aarch64-linux-musleabi-gcc" ]] \
    || die "未找到交叉编译器: ${TOOLCHAIN_DIR}/bin/aarch64-linux-musleabi-gcc"

mkdir -p "${LOCAL_DIR}"

# 可选：将 runtime_lib 解压到 local/sysroot，供链接/部署参考（不影响系统）
if [[ -f "${RUNTIME_LIB}" && ! -f "${SYSROOT_OVERLAY}/.installed" ]]; then
    echo "解压 runtime_lib 到 ${SYSROOT_OVERLAY} ..."
    mkdir -p "${SYSROOT_OVERLAY}"
    tar -xzf "${RUNTIME_LIB}" -C "${SYSROOT_OVERLAY}"
    if [[ -f "${SYSROOT_OVERLAY}/runtime_lib/lib.tgz" ]]; then
        tar -xzf "${SYSROOT_OVERLAY}/runtime_lib/lib.tgz" -C "${SYSROOT_OVERLAY}"
        rm -rf "${SYSROOT_OVERLAY}/runtime_lib"
    fi
    touch "${SYSROOT_OVERLAY}/.installed"
fi

# 默认环境：只加前缀工具到 PATH，不设置 CC/CXX，不 alias cmake。
cat > "${ENV_FILE}" << EOF
# 由 setup_local.sh 生成。可 source，但不是必须。
# 安全：不设置 CC/CXX/CMAKE_TOOLCHAIN_FILE，不劫持 cmake。
# 用法: source "${ENV_FILE}"

export VINSMONO_MUSL_TOOLCHAIN="${PROJECT_ROOT}"
export PROJECT_ROOT="${PROJECT_ROOT}"
export TOOLCHAIN_ROOT="${TOOLCHAIN_DIR}"
export TOOLCHAIN_PREFIX="aarch64-linux-musleabi"
export PATH="\${TOOLCHAIN_ROOT}/bin:\${PROJECT_ROOT}:\${PATH}"
EOF

# 可选：仅在「专用交叉编译终端」里 source，禁止与 vcpkg 宿主机构建混用。
cat > "${ENV_CROSS}" << EOF
# 可选、危险：会设置 CC/CXX。仅用于手写 gcc 的一次性终端。
# 不要在编译 VINS-Mono / vcpkg 的终端里 source。
# 用法: source "${ENV_CROSS}"

source "${ENV_FILE}"
export CC="\${TOOLCHAIN_PREFIX}-gcc"
export CXX="\${TOOLCHAIN_PREFIX}-g++"
export AR="\${TOOLCHAIN_PREFIX}-ar"
export STRIP="\${TOOLCHAIN_PREFIX}-strip"
export RANLIB="\${TOOLCHAIN_PREFIX}-ranlib"
export SYSROOT="\${TOOLCHAIN_ROOT}/target"
# 故意不设置 CMAKE_TOOLCHAIN_FILE，也不 alias cmake。
EOF

# 若旧版曾写入 ~/.bashrc，这里只删除、不再追加。
strip_legacy_bashrc() {
    [[ -f "${BASHRC}" ]] || return 0
    grep -qF "${BASHRC_BEGIN}" "${BASHRC}" || return 0
    while grep -qF "${BASHRC_BEGIN}" "${BASHRC}"; do
        sed -i "/$(printf '%s\n' "${BASHRC_BEGIN}" | sed 's/[[\.*^$()+?{|]/\\&/g')/,/$(printf '%s\n' "${BASHRC_END}" | sed 's/[[\.*^$()+?{|]/\\&/g')/d" "${BASHRC}"
    done
    echo "已从 ${BASHRC} 移除旧版自动 source 块。"
}

strip_legacy_bashrc

echo ""
echo "本地工具链已就绪（不修改 ~/.bashrc，不劫持 cmake）。"
echo "  包根目录   : ${PROJECT_ROOT}"
echo "  交叉 gcc   : ${TOOLCHAIN_DIR}/bin/aarch64-linux-musleabi-gcc"
echo "  安全环境   : ${ENV_FILE}     （可选 source）"
echo "  交叉环境   : ${ENV_CROSS}    （可选；会设 CC/CXX，勿用于 vcpkg）"
echo ""
echo "推荐（系统 cmake + toolchain 文件）:"
echo "  cmake -S examples -B build -G Ninja \\"
echo "    -DCMAKE_TOOLCHAIN_FILE=${PROJECT_ROOT}/cmake/aarch64-linux-musleabi.cmake"
echo "  cmake --build build"
echo ""
echo "VINS-Mono: 将本目录放在 \$HOME/Public/ 即可被自动识别，或:"
echo "  export VINSMONO_MUSL_TOOLCHAIN=${PROJECT_ROOT}"
echo "  ./scripts/build_menu.sh 7 1"
echo ""
echo "详见 README.md"
echo ""
