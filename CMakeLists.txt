cmake_minimum_required(VERSION 3.28)
enable_language(C ASM)
set ( SOURCES 
	DisplayImage.cpp
)
set (LD_NOEXECSTACK_FLAG "-z noexecstack")
set (ASM_OPTIONS "-x assembler-with-cpp -lm")
set (CMAKE_BUILD_TYPE Debug)
project( DisplayImage )
find_package( OpenCV REQUIRED )
include_directories( ${OpenCV_INCLUDE_DIRS} )
add_executable( DisplayImage ${SOURCES} )
target_link_libraries( DisplayImage ${OpenCV_LIBS})
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ")
set(CMAKE_ASM_FLAGS "${CFLAGS} ${ASM_OPTIONS}")
set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} ${LD_NOEXECSTACK_FLAG} ")


