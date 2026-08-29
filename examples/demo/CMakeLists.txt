add_executable(demo main.c)
target_compile_options(demo PRIVATE -Wall -Wextra)

install(TARGETS demo RUNTIME DESTINATION bin)
