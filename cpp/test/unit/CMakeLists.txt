cmake_minimum_required(VERSION 3.5)
project(dolfin-tests)

find_package(DOLFIN REQUIRED)
include(${DOLFIN_USE_FILE})

# Prepare "Catch" library for other executables
set(CATCH_INCLUDE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/catch)

add_library(Catch INTERFACE)
target_include_directories(Catch INTERFACE ${CATCH_INCLUDE_DIR})

# Make test executable
set(TEST_SOURCES
  ${CMAKE_CURRENT_SOURCE_DIR}/main.cpp
  ${CMAKE_CURRENT_SOURCE_DIR}/common/SubSystemsManager.cpp
  ${CMAKE_CURRENT_SOURCE_DIR}/common/IndexMap.cpp
  ${CMAKE_CURRENT_SOURCE_DIR}/function/Expression.cpp
  )

add_executable(unittests ${TEST_SOURCES})
target_link_libraries(unittests PRIVATE Catch dolfin)

# Test target
add_test(unittests unittests)
