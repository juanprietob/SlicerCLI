
#-----------------------------------------------------------------------------
enable_language(C)
enable_language(CXX)


#-----------------------------------------------------------------------------
include(${CMAKE_CURRENT_SOURCE_DIR}/Common.cmake)

#-----------------------------------------------------------------------------
# Git protocole option
#-----------------------------------------------------------------------------
option(USE_GIT_PROTOCOL "If behind a firewall turn this off to use http instead." ON)
set(git_protocol "git")
if(NOT USE_GIT_PROTOCOL)
  set(git_protocol "http")
endif()

find_package(Git REQUIRED)
find_package(Subversion REQUIRED)

set(EXTERNAL_SOURCE_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR} CACHE PATH "Select where external packages will be downloaded" )
set(EXTERNAL_BINARY_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR} CACHE PATH "Select where external packages will be compiled and installed" )

#-----------------------------------------------------------------------------
# Enable and setup External project global properties
#-----------------------------------------------------------------------------
include(ExternalProject)
include(SlicerMacroEmptyExternalProject)
include(SlicerMacroCheckExternalProjectDependency)

# Compute -G arg for configuring external projects with the same CMake generator:
if(CMAKE_EXTRA_GENERATOR)
  set(gen "${CMAKE_EXTRA_GENERATOR} - ${CMAKE_GENERATOR}")
else()
  set(gen "${CMAKE_GENERATOR}")
endif()


# With CMake 2.8.9 or later, the UPDATE_COMMAND is required for updates to occur.
# For earlier versions, we nullify the update state to prevent updates and
# undesirable rebuild.
option(FORCE_EXTERNAL_BUILDS "Force rebuilding of external project (if they are updated)" ON)
if(CMAKE_VERSION VERSION_LESS 2.8.9 OR NOT FORCE_EXTERNAL_BUILDS)
  set(cmakeversion_external_update UPDATE_COMMAND)
  set(cmakeversion_external_update_value "" )
else()
  set(cmakeversion_external_update LOG_UPDATE )
  set(cmakeversion_external_update_value 1)
endif()

#-----------------------------------------------------------------------------
# Platform check
#-----------------------------------------------------------------------------

set(PLATFORM_CHECK true)

if(PLATFORM_CHECK)
  # See CMake/Modules/Platform/Darwin.cmake)
  #   6.x == Mac OSX 10.2 (Jaguar)
  #   7.x == Mac OSX 10.3 (Panther)
  #   8.x == Mac OSX 10.4 (Tiger)
  #   9.x == Mac OSX 10.5 (Leopard)
  #  10.x == Mac OSX 10.6 (Snow Leopard)
  if (DARWIN_MAJOR_VERSION LESS "9")
    message(FATAL_ERROR "Only Mac OSX >= 10.5 are supported !")
  endif()
endif()

#-----------------------------------------------------------------------------
# Superbuild option(s)
#-----------------------------------------------------------------------------

option(BUILD_STYLE_UTILS "Build uncrustify, cppcheck, & KWStyle" OFF)
CMAKE_DEPENDENT_OPTION(
  USE_SYSTEM_Uncrustify "Use system Uncrustify program" OFF
  "BUILD_STYLE_UTILS" OFF
  )
CMAKE_DEPENDENT_OPTION(
  USE_SYSTEM_KWStyle "Use system KWStyle program" OFF
  "BUILD_STYLE_UTILS" OFF
  )
CMAKE_DEPENDENT_OPTION(
  USE_SYSTEM_Cppcheck "Use system Cppcheck program" OFF
  "BUILD_STYLE_UTILS" OFF
  )

set(EXTERNAL_PROJECT_BUILD_TYPE "Release" CACHE STRING "Default build type for support libraries")

set( Slicer_Revision "0" CACHE STRING "Download source code from Slicer at this revision. 0 for current revision" )
option(USE_SYSTEM_zlib "build using the system version of zlib" OFF)
option(USE_SYSTEM_ITK "Build using an externally defined version of ITK" OFF)
option(USE_SYSTEM_SlicerExecutionModel "Build using an externally defined version of SlicerExecutionModel"  OFF)
option(USE_SYSTEM_VTK "Build using an externally defined version of VTK" OFF)
set( ${PROJECT_NAME}_BUILD_ZLIB_SUPPORT ON )
option(BUILD_TESTING "Build Testing" OFF)
#------------------------------------------------------------------------------
# ${PROJECT_NAME} dependency list
#------------------------------------------------------------------------------
set(ITK_EXTERNAL_NAME ITKv${ITK_VERSION_MAJOR})

set(${PROJECT_NAME}_DEPENDENCIES
  SlicerExecutionModel
  ${ITK_EXTERNAL_NAME}
  VTK
  )

if(BUILD_STYLE_UTILS)
  list(APPEND ${PROJECT_NAME}_DEPENDENCIES Cppcheck KWStyle Uncrustify)
endif()

#-----------------------------------------------------------------------------
if( BUILD_TESTING )
  enable_testing()
  include(CTest)
endif()

#-----------------------------------------------------------------------------
# Define Superbuild global variables
#-----------------------------------------------------------------------------

# This variable will contain the list of CMake variable specific to each external project
# that should passed to ${CMAKE_PROJECT_NAME}.
# The item of this list should have the following form: <EP_VAR>:<TYPE>
# where '<EP_VAR>' is an external project variable and TYPE is either BOOL, STRING, PATH or FILEPATH.
# TODO Variable appended to this list will be automatically exported in ${PROJECT_NAME}Config.cmake,
# prefix '${PROJECT_NAME}_' will be prepended if it applies.
set(${CMAKE_PROJECT_NAME}_SUPERBUILD_EP_VARS)

# The macro '_expand_external_project_vars' can be used to expand the list of <EP_VAR>.
set(${CMAKE_PROJECT_NAME}_SUPERBUILD_EP_ARGS) # List of CMake args to configure ${PROJECT_NAME}
set(${CMAKE_PROJECT_NAME}_SUPERBUILD_EP_VARNAMES) # List of CMake variable names

# Convenient macro allowing to expand the list of EP_VAR listed in ${CMAKE_PROJECT_NAME}_SUPERBUILD_EP_VARS
# The expanded arguments will be appended to the list ${CMAKE_PROJECT_NAME}_SUPERBUILD_EP_ARGS
# Similarly the name of the EP_VARs will be appended to the list ${CMAKE_PROJECT_NAME}_SUPERBUILD_EP_VARNAMES.
macro(_expand_external_project_vars)
  set(${CMAKE_PROJECT_NAME}_SUPERBUILD_EP_ARGS "")
  set(${CMAKE_PROJECT_NAME}_SUPERBUILD_EP_VARNAMES "")
  foreach(arg ${${CMAKE_PROJECT_NAME}_SUPERBUILD_EP_VARS})
    string(REPLACE ":" ";" varname_and_vartype ${arg})
    set(target_info_list ${target_info_list})
    list(GET varname_and_vartype 0 _varname)
    list(GET varname_and_vartype 1 _vartype)
    list(APPEND ${CMAKE_PROJECT_NAME}_SUPERBUILD_EP_ARGS -D${_varname}:${_vartype}=${${_varname}})
    list(APPEND ${CMAKE_PROJECT_NAME}_SUPERBUILD_EP_VARNAMES ${_varname})
  endforeach()
endmacro()

#-----------------------------------------------------------------------------
# Common external projects CMake variables
#-----------------------------------------------------------------------------
set(CMAKE_INCLUDE_DIRECTORIES_BEFORE ON CACHE BOOL "Set default to prepend include directories.")

list(APPEND ${CMAKE_PROJECT_NAME}_SUPERBUILD_EP_VARS
  MAKECOMMAND:STRING
  CMAKE_SKIP_RPATH:BOOL
  CMAKE_MODULE_PATH:PATH
  CMAKE_BUILD_TYPE:STRING
  BUILD_SHARED_LIBS:BOOL
  CMAKE_INCLUDE_DIRECTORIES_BEFORE:BOOL
  CMAKE_CXX_COMPILER:PATH
  CMAKE_CXX_FLAGS:STRING
  CMAKE_CXX_FLAGS_DEBUG:STRING
  CMAKE_CXX_FLAGS_MINSIZEREL:STRING
  CMAKE_CXX_FLAGS_RELEASE:STRING
  CMAKE_CXX_FLAGS_RELWITHDEBINFO:STRING
  CMAKE_C_COMPILER:PATH
  CMAKE_C_FLAGS:STRING
  CMAKE_C_FLAGS_DEBUG:STRING
  CMAKE_C_FLAGS_MINSIZEREL:STRING
  CMAKE_C_FLAGS_RELEASE:STRING
  CMAKE_C_FLAGS_RELWITHDEBINFO:STRING
  CMAKE_EXE_LINKER_FLAGS:STRING
  CMAKE_EXE_LINKER_FLAGS_DEBUG:STRING
  CMAKE_EXE_LINKER_FLAGS_MINSIZEREL:STRING
  CMAKE_EXE_LINKER_FLAGS_RELEASE:STRING
  CMAKE_EXE_LINKER_FLAGS_RELWITHDEBINFO:STRING
  CMAKE_MODULE_LINKER_FLAGS:STRING
  CMAKE_MODULE_LINKER_FLAGS_DEBUG:STRING
  CMAKE_MODULE_LINKER_FLAGS_MINSIZEREL:STRING
  CMAKE_MODULE_LINKER_FLAGS_RELEASE:STRING
  CMAKE_MODULE_LINKER_FLAGS_RELWITHDEBINFO:STRING
  CMAKE_SHARED_LINKER_FLAGS:STRING
  CMAKE_SHARED_LINKER_FLAGS_DEBUG:STRING
  CMAKE_SHARED_LINKER_FLAGS_MINSIZEREL:STRING
  CMAKE_SHARED_LINKER_FLAGS_RELEASE:STRING
  CMAKE_SHARED_LINKER_FLAGS_RELWITHDEBINFO:STRING
  CMAKE_GENERATOR:STRING
  CMAKE_EXTRA_GENERATOR:STRING
  CMAKE_INSTALL_PREFIX:PATH
  CMAKE_LIBRARY_OUTPUT_DIRECTORY:PATH
  CMAKE_ARCHIVE_OUTPUT_DIRECTORY:PATH
  CMAKE_RUNTIME_OUTPUT_DIRECTORY:PATH
  CMAKE_BUNDLE_OUTPUT_DIRECTORY:PATH
  CTEST_NEW_FORMAT:BOOL
  MEMORYCHECK_COMMAND_OPTIONS:STRING
  MEMORYCHECK_COMMAND:PATH
  CMAKE_SHARED_LINKER_FLAGS:STRING
  CMAKE_EXE_LINKER_FLAGS:STRING
  CMAKE_MODULE_LINKER_FLAGS:STRING
  SITE:STRING
  BUILDNAME:STRING
  PYTHON_EXECUTABLE:FILEPATH
  PYTHON_INCLUDE_DIR:PATH
  PYTHON_LIBRARY:FILEPATH
  )

if(${PROJECT_NAME}_USE_QT)
  list(APPEND ${CMAKE_PROJECT_NAME}_SUPERBUILD_EP_VARS
    ${PROJECT_NAME}_USE_QT:BOOL
    QT_QMAKE_EXECUTABLE:PATH
    QT_MOC_EXECUTABLE:PATH
    QT_UIC_EXECUTABLE:PATH
    )
endif()

_expand_external_project_vars()
set(COMMON_EXTERNAL_PROJECT_ARGS ${${CMAKE_PROJECT_NAME}_SUPERBUILD_EP_ARGS})
set(extProjName ${PROJECT_NAME})
set(proj        ${PROJECT_NAME})
SlicerMacroCheckExternalProjectDependency(${proj})

#-----------------------------------------------------------------------------
# Set CMake OSX variable to pass down the external project
#-----------------------------------------------------------------------------
set(CMAKE_OSX_EXTERNAL_PROJECT_ARGS)
if(APPLE)
  list(APPEND CMAKE_OSX_EXTERNAL_PROJECT_ARGS
    -DCMAKE_OSX_ARCHITECTURES=${CMAKE_OSX_ARCHITECTURES}
    -DCMAKE_OSX_SYSROOT=${CMAKE_OSX_SYSROOT}
    -DCMAKE_OSX_DEPLOYMENT_TARGET=${CMAKE_OSX_DEPLOYMENT_TARGET})
endif()

#-----------------------------------------------------------------------------
# Add external project CMake args
#-----------------------------------------------------------------------------
foreach(var ${ListModules} )
  option(BUILD_CLI_${var} "Build ${var}" OFF)
  if( BUILD_CLI_${var} )
    if( DEFINED StringModules )#Even if we don't want to build on module, we still download it's code, because another module might depend on it
      set(StringModules "${StringModules} ${var}" )
    else()
      set(StringModules "${var}")
    endif()
  endif()
  list(APPEND ${CMAKE_PROJECT_NAME}_SUPERBUILD_EP_VARS BUILD_CLI_${var}:BOOL)
endforeach()


list(APPEND ${CMAKE_PROJECT_NAME}_SUPERBUILD_EP_VARS
  BUILD_EXAMPLES:BOOL
  BUILD_TESTING:BOOL
  ITK_VERSION_MAJOR:STRING
  ITK_DIR:PATH
  )

_expand_external_project_vars()

#
# By default we want to build ${PROJECT_NAME} stuff using the CMAKE_BUILD_TYPE of
# the top level build, but build the support libraries in Release.
# So make one list of parameters to pass to ${PROJECT_NAME} when we build it and
# another for all the prerequisite libraries
#
# since we use a macro to build the list of arguments, it's easier to modify the
# list after it's built than try and conditionally change just the build type in the macro.

set(${PROJECT_NAME}_EXTERNAL_PROJECT_ARGS ${${CMAKE_PROJECT_NAME}_SUPERBUILD_EP_ARGS})

set(COMMON_EXTERNAL_PROJECT_ARGS)
foreach(arg ${${CMAKE_PROJECT_NAME}_SUPERBUILD_EP_ARGS})
  if(arg MATCHES "-DCMAKE_BUILD_TYPE:STRING.*")
    set(_arg -DCMAKE_BUILD_TYPE:STRING=${EXTERNAL_PROJECT_BUILD_TYPE})
  else()
    set(_arg ${arg})
  endif()
  list(APPEND COMMON_EXTERNAL_PROJECT_ARGS ${_arg})
endforeach()

#-----------------------------------------------------------------------------
set(verbose FALSE)
#-----------------------------------------------------------------------------
if(verbose)
foreach(x ${COMMON_EXTERNAL_PROJECT_ARGS})
  message("COMMON_EXTERNAL_PROJECT_ARGS:   ${x}")
endforeach()

  message("Inner external project args:")
  foreach(arg ${${CMAKE_PROJECT_NAME}_SUPERBUILD_EP_ARGS})
    message("  ${arg}")
  endforeach()
endif()

string(REPLACE ";" "^" ${CMAKE_PROJECT_NAME}_SUPERBUILD_EP_VARNAMES "${${CMAKE_PROJECT_NAME}_SUPERBUILD_EP_VARNAMES}")

if(verbose)
  message("Inner external project argnames:")
  foreach(argname ${${CMAKE_PROJECT_NAME}_SUPERBUILD_EP_VARNAMES})
    message("  ${argname}")
  endforeach()
endif()

#-----------------------------------------------------------------------------
# CTestCustom
#-----------------------------------------------------------------------------
if(BUILD_TESTING AND NOT Slicer_BUILD_${PROJECT_NAME})
  configure_file(
    CMake/CTestCustom.cmake.in
    ${CMAKE_CURRENT_BINARY_DIR}/CTestCustom.cmake
    @ONLY)
endif()


#------------------------------------------------------------------------------
# Configure and build ${PROJECT_NAME}
#------------------------------------------------------------------------------
set(proj ${LOCAL_PROJECT_NAME})
ExternalProject_Add(${proj}
  DEPENDS ${${PROJECT_NAME}_DEPENDENCIES}
  URL ${CMAKE_CURRENT_SOURCE_DIR}
  SOURCE_DIR ${CMAKE_CURRENT_BINARY_DIR}/${proj}
  BINARY_DIR ${proj}-build
  CMAKE_GENERATOR ${gen}
  CMAKE_ARGS
    --no-warn-unused-cli    # HACK Only expected variables should be passed down.
    ${CMAKE_OSX_EXTERNAL_PROJECT_ARGS}
    ${${PROJECT_NAME}_EXTERNAL_PROJECT_ARGS}
    -D${LOCAL_PROJECT_NAME}_SUPERBUILD:BOOL=OFF    #NOTE: VERY IMPORTANT reprocess top level CMakeList.txt
  INSTALL_COMMAND ""
  PATCH_COMMAND ${CMAKE_COMMAND} -DSlicer_Revision:STRING=${Slicer_Revision} -DStringModules:STRING="${StringModules}" -DSubversion_SVN_EXECUTABLE:FILEPATH=${Subversion_SVN_EXECUTABLE} -DDOWNLOAD_DIR:PATH=${CMAKE_CURRENT_BINARY_DIR}/${proj} -P ${CMAKE_CURRENT_SOURCE_DIR}/SuperBuild/SlicerExecutionModelDownload.cmake
  )


