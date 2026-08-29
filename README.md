# aarch64-v01c01-linux-musl 交叉工具链

在 **x86_64 Linux** 主机上，为 **ARM64 + musl** 目标交叉编译 C/C++。

| 项目 | 版本 / 说明 |
|------|-------------|
| 编译器 | GCC 10.3.0 |
| C 库 | openEuler musl 1.2.3 |
| 内核头文件 | Linux 5.10 |
| 目标三元组 | `aarch64-linux-musleabi` |
| 宿主机 | x86_64 Linux |
| 发布日期 | 2023-06-09 |

---

## 推荐方案（不要改 bashrc）

**不要**把本工具链写进 `~/.bashrc`，**不要** `alias cmake=...`，**不要**全局 `export CC` / `CXX` / `CMAKE_TOOLCHAIN_FILE`。

原因：这些变量会泄漏到所有 CMake/vcpkg 进程。vcpkg 安装**宿主机**包（例如 `openblas:x64-linux`）时会误用 `aarch64-linux-musleabi-g++`，随后找不到 Ninja（`CMAKE_FIND_ROOT_PATH_MODE_PROGRAM=NEVER`）。

正确做法：交叉信息只通过 **CMake toolchain 文件**传入**目标**编译；宿主机仍用系统 `gcc` / `cmake` / `ninja`。

```text
系统 cmake / ninja / 宿主 gcc     →  配置、编 vcpkg 宿主机包
cmake/aarch64-linux-musleabi.cmake →  只给目标 aarch64+musl 用交叉 gcc
```

| 做法 | 推荐 | 说明 |
|------|------|------|
| `cmake -DCMAKE_TOOLCHAIN_FILE=.../aarch64-linux-musleabi.cmake` | **是** | 标准交叉编译 |
| 把本包装在 `$HOME/Public/`，由工程自动识别 | **是** | VINS-Mono 默认搜索路径 |
| `export VINSMONO_MUSL_TOOLCHAIN=<本目录>` | 可选 | 路径不在 Public 时 |
| `source local/env.sh` | 可选 | 只把前缀 gcc 加入 PATH，不改 CC |
| `source local/env-cross.sh` | 慎用 | 会设 CC/CXX，仅限手写 gcc 的一次性终端 |
| `./v01c01-cmake` | 仅 examples | 玩具驱动，**不是**真 CMake |
| 写入 `~/.bashrc` / `alias cmake=` | **禁止** | 污染本机所有构建 |

---

## 目录结构

```
gcc-20230609-aarch64-v01c01-linux-musl/
├── aarch64-v01c01-linux-musl-gcc/   # 预编译交叉工具链本体
├── runtime_lib.tar.gz               # 目标机运行时动态库（可选）
├── setup_local.sh                   # 生成本地 local/（不改 bashrc）
├── cmake/
│   └── aarch64-linux-musleabi.cmake # 给「真 CMake」用的 toolchain
├── v01c01-cmake                     # 仅 examples 的简易驱动（勿 alias 成 cmake）
├── examples/
├── local/                           # setup_local.sh 生成（勿提交）
│   ├── env.sh                       # 安全：PATH + VINSMONO_MUSL_TOOLCHAIN
│   ├── env-cross.sh                 # 可选：另设 CC/CXX
│   └── sysroot/
├── install_gcc_toolchain.sh         # 旧版系统安装（/opt、/etc/profile）
└── README.md
```

---

## 一次初始化

```bash
./setup_local.sh
```

会完成：

- 生成 `local/env.sh`（安全）和 `local/env-cross.sh`（可选）
- 若存在 `runtime_lib.tar.gz`，解压到 `local/sysroot`
- **若** `~/.bashrc` 里还有旧版自动 source 块，则删掉（不再写入）

不需要 `source ~/.bashrc`。

---

## 用法 A：系统 cmake（推荐，任意工程）

需要本机已安装 **CMake ≥ 3.16** 与 **Ninja**。不要使用本目录的 `v01c01-cmake` 冒充 cmake。

```bash
cmake -S examples -B build -G Ninja \
  -DCMAKE_TOOLCHAIN_FILE=/path/to/gcc-20230609-aarch64-v01c01-linux-musl/cmake/aarch64-linux-musleabi.cmake
cmake --build build
file build/demo/demo
# 期望: ELF 64-bit LSB executable, ARM aarch64
```

静态链接（目标机可不带 musl 动态库）：

```bash
cmake -S examples -B build -G Ninja \
  -DCMAKE_TOOLCHAIN_FILE=.../cmake/aarch64-linux-musleabi.cmake \
  -DBUILD_STATIC=ON
cmake --build build --clean-first
```

直接调前缀编译器（不必 source 任何 env）：

```bash
./aarch64-v01c01-linux-musl-gcc/bin/aarch64-linux-musleabi-gcc -o hello hello.c
./aarch64-v01c01-linux-musl-gcc/bin/aarch64-linux-musleabi-gcc -static -o hello hello.c
```

---

## 用法 B：VINS-Mono

VINS-Mono 用 **vcpkg + 本工具链 chainload**，预设：

| 预设 / 菜单 | 说明 |
|-------------|------|
| `arm64-musl-vcpkg-release` / `./scripts/build_menu.sh 7 1` | musl 交叉 Release |
| `arm64-musl-vcpkg-debug` / `./scripts/build_menu.sh 8 1` | musl 交叉 Debug |

与 glibc 预设 `arm64-vcpkg-release`（`aarch64-linux-gnu`）**不要混用**。

自动识别顺序（CMake 工具链文件）：

1. `VINSMONO_MUSL_TOOLCHAIN`（包根、gcc 根、或 gcc 可执行文件）
2. `TOOLCHAIN_ROOT`（若已 export）
3. PATH 中的 `aarch64-linux-musleabi-gcc`
4. `$HOME/Public/gcc-*-aarch64-v01c01-linux-musl`
5. `/opt/linux/x86-arm/` 下同名布局

本包装在 `/home/jimmy/Public/gcc-20230609-aarch64-v01c01-linux-musl` 时，一般**不用设环境变量**：

```bash
cd /path/to/VINS-Mono
./scripts/build_menu.sh 7 1
```

路径不在 Public 时：

```bash
export VINSMONO_MUSL_TOOLCHAIN=/path/to/gcc-20230609-aarch64-v01c01-linux-musl
./scripts/build_menu.sh 7 1
```

VINS-Mono 的 `build_menu.sh` 和 CMake preset 会清掉泄漏的 `CC`/`CXX`/`CMAKE_TOOLCHAIN_FILE`，避免 vcpkg 宿主机 triplet 被交叉 gcc 污染。即便如此，也请不要在 `~/.bashrc` 里 source 本目录的 env。

---

## 用法 C：可选环境脚本

```bash
source /path/to/gcc-20230609-aarch64-v01c01-linux-musl/local/env.sh
# 此时可直接敲: aarch64-linux-musleabi-gcc --version
# 仍使用系统 cmake，不要 alias
```

仅当要在当前终端里写 `gcc`/`g++` 就走交叉链时（**不要**同时编 VINS-Mono / vcpkg）：

```bash
source .../local/env-cross.sh
aarch64-linux-musleabi-gcc -o hello hello.c
```

用完后关掉该终端，或：

```bash
unset CC CXX AR STRIP RANLIB SYSROOT
```

---

## 用法 D：v01c01-cmake（仅 examples）

`v01c01-cmake` **不是** CMake：它只解析极简 `CMakeLists.txt`，不能编 VINS-Mono。请用**绝对路径或 `./`** 调用，不要 alias 成 `cmake`。

```bash
./v01c01-cmake -S examples -B build
./v01c01-cmake --build build
```

---

## 静态 / 动态链接与上板

动态链接产物依赖目标机的 `ld-musl-aarch64.so.1` 等。可用 `local/sysroot` 或 `runtime_lib.tar.gz` 部署到板子。静态链接加 `-DBUILD_STATIC=ON`（真 CMake）或 `./v01c01-cmake ... -DBUILD_STATIC=ON`。

---

## 旧版系统安装

一般不推荐。会写入 `/opt` 与 `/etc/profile`：

```bash
sudo ./install_gcc_toolchain.sh
# 或
sudo ./install_gcc_toolchain.sh /自定义路径
```

| | 当前推荐 | 旧 `setup_local.sh` | 旧 `install_gcc_toolchain.sh` |
|--|----------|---------------------|-------------------------------|
| 权限 | 无需 root | 无需 root | 需要 sudo |
| 系统文件 | 不改 | 曾写 `~/.bashrc` | `/etc/profile` |
| cmake | 系统 cmake + toolchain 文件 | 曾 alias 成 v01c01-cmake | 手动 gcc |
| vcpkg 工程 | 可用 | 会污染宿主机编译 | 视 PATH 而定 |

---

## 常见问题

### 已经 source 过旧 env / bashrc，当前终端怎么清？

```bash
unalias cmake v01c01-cmake 2>/dev/null
unset CC CXX AR STRIP RANLIB CMAKE_TOOLCHAIN_FILE SYSROOT TOOLCHAIN_ROOT TOOLCHAIN_PREFIX
```

新开一个终端最省事。`./setup_local.sh` 会尝试删掉 `~/.bashrc` 里的旧标记块。

### `openblas:x64-linux` 失败 / 找不到 Ninja

多半是 `CC`/`CXX`/`CMAKE_TOOLCHAIN_FILE` 仍指向本工具链。按上一节清理后重配。不要在编 VINS-Mono 的终端里 `source local/env-cross.sh`。

### `v01c01-cmake: command not found`

不要依赖 PATH alias。用 `./v01c01-cmake`，或改用系统 cmake（推荐）。

### 默认生成器是 Ninja

```bash
cmake -G Ninja ...
# 或
cmake -G "Unix Makefiles" ...
```

---

## 依赖

- 宿主机：x86_64 Linux
- 推荐：系统 `cmake`（≥ 3.16；VINS-Mono 预设需 ≥ 3.25）、`ninja`、`bash`
- 不需要：把本目录加入 bashrc

---

## 许可证与来源

预编译工具链来自 openEuler / 相关发行包（GCC 10.3.0 + musl 1.2.3）。  
`setup_local.sh`、`v01c01-cmake`、示例与本文档为本地辅助脚本与说明。
