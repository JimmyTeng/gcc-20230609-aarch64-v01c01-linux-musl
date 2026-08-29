Complier : gcc-10.3.0
C Library : openEuler:musl 1.2.3-1.oe2203
Linux kernel header : Linux Kernel 5.10

完整方案与用法见 README.md（不要改 ~/.bashrc，不要 alias cmake）。

# 初始化（只写 local/，不改 bashrc）
./setup_local.sh

# 推荐：系统 cmake + toolchain 文件
cmake -S examples -B build -G Ninja \
  -DCMAKE_TOOLCHAIN_FILE="$PWD/cmake/aarch64-linux-musleabi.cmake"
cmake --build build

# VINS-Mono（包放在 $HOME/Public/ 时可自动识别）
#   cd /path/to/VINS-Mono && ./scripts/build_menu.sh 7 1
# 或: export VINSMONO_MUSL_TOOLCHAIN=/path/to/本目录

# 旧版系统安装（不推荐）
# sudo ./install_gcc_toolchain.sh [path]
