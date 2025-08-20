# ARM64 cross-compilation toolchain file
set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_PROCESSOR aarch64)

# Cross-compilation tools
set(CMAKE_C_COMPILER aarch64-linux-gnu-gcc)
set(CMAKE_CXX_COMPILER aarch64-linux-gnu-g++)

# Find root path for libraries and headers
#set(CMAKE_FIND_ROOT_PATH /usr/aarch64-linux-gnu)

# Search programs in host environment
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)

# Search libraries and headers in target environment
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)

# Qt6 specific paths
set(QT_HOST_PATH /usr/lib/qt6)
set(CMAKE_PREFIX_PATH /usr/lib/aarch64-linux-gnu/qt6)

# OpenGL configuration for ARM64
set(OPENGL_INCLUDE_DIR /usr/include)
set(OPENGL_opengl_LIBRARY /usr/lib/aarch64-linux-gnu/libOpenGL.so)
set(OPENGL_gl_LIBRARY /usr/lib/aarch64-linux-gnu/libGL.so)
set(OPENGL_glx_LIBRARY /usr/lib/aarch64-linux-gnu/libGLX.so)

# Create OpenGL::GL target manually if not found
if(NOT TARGET OpenGL::GL)
    add_library(OpenGL::GL INTERFACE IMPORTED)
    set_target_properties(OpenGL::GL PROPERTIES
        INTERFACE_LINK_LIBRARIES "${OPENGL_gl_LIBRARY}"
    )
endif()
