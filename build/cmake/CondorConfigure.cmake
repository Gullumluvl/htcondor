 ###############################################################
 #
 # Copyright 2011 Red Hat, Inc.
 #
 # Licensed under the Apache License, Version 2.0 (the "License"); you
 # may not use this file except in compliance with the License.  You may
 # obtain a copy of the License at
 #
 #    http://www.apache.org/licenses/LICENSE-2.0
 #
 # Unless required by applicable law or agreed to in writing, software
 # distributed under the License is distributed on an "AS IS" BASIS,
 # WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 # See the License for the specific language governing permissions and
 # limitations under the License.
 #
 ###############################################################

# OS pre mods
if(${OS_NAME} STREQUAL "DARWIN")
  exec_program (sw_vers ARGS -productVersion OUTPUT_VARIABLE TEST_VER)
  if(${TEST_VER} MATCHES "10.6" AND ${SYS_ARCH} MATCHES "I386")
	set (SYS_ARCH "X86_64")
  endif()
elseif(${OS_NAME} MATCHES "WIN")
	cmake_minimum_required(VERSION 2.8.3)
	set(WINDOWS ON)

	# The following is necessary for sdk/ddk version to compile against.
	# lowest common denominator is winxp (for now)
	add_definitions(-DWINDOWS)
	add_definitions(-D_WIN32_WINNT=_WIN32_WINNT_WINXP)
	add_definitions(-DWINVER=_WIN32_WINNT_WINXP)
	add_definitions(-DNTDDI_VERSION=NTDDI_WINXP)
	add_definitions(-D_CRT_SECURE_NO_WARNINGS)

	set(CMD_TERM \r\n)
	set(C_WIN_BIN ${CONDOR_SOURCE_DIR}/msconfig) #${CONDOR_SOURCE_DIR}/build/backstage/win)
	set(BISON_SIMPLE ${C_WIN_BIN}/bison.simple)
	#set(CMAKE_SUPPRESS_REGENERATION TRUE)

	set (HAVE_SNPRINTF 1)
	set (HAVE_WORKING_SNPRINTF 1)

	if(${CMAKE_CURRENT_SOURCE_DIR} STREQUAL ${CMAKE_CURRENT_BINARY_DIR})
		dprint("**** IN SOURCE BUILDING ON WINDOWS IS NOT ADVISED ****")
	else()
		dprint("**** OUT OF SOURCE BUILDS ****")
		file (COPY ${CMAKE_CURRENT_SOURCE_DIR}/msconfig DESTINATION ${CMAKE_CURRENT_BINARY_DIR})
	endif()
    
	# means user did not specify, so change the default.
	if ( ${CMAKE_INSTALL_PREFIX} MATCHES "Program Files" )
		# mimic *nix for consistency
		set( CMAKE_INSTALL_PREFIX "${CMAKE_CURRENT_BINARY_DIR}/release_dir")
	endif()

	dprint("TODO FEATURE-> Z:TANNENBA:TJ:TSTCLAIR Update registry + paths to use this prefixed debug loc (test_install)")

endif()

  
message(STATUS "***********************************************************")
message(STATUS "System(${HOSTNAME}): ${OS_NAME}(${OS_VER}) Arch=${SYS_ARCH} BitMode=${BIT_MODE} BUILDID:${BUILDID}")
message(STATUS "install prefix:${CMAKE_INSTALL_PREFIX}")
message(STATUS "********* BEGINNING CONFIGURATION *********")

##################################################
##################################################
include (FindThreads)
include (GlibcDetect)

add_definitions(-D${OS_NAME}="${OS_NAME}_${OS_VER}")
if (CONDOR_PLATFORM)
    add_definitions(-DPLATFORM="${CONDOR_PLATFORM}")
elseif(PLATFORM)
    add_definitions(-DPLATFORM="${PLATFORM}")
elseif(LINUX_NAME)
    add_definitions(-DPLATFORM="${SYS_ARCH}-${LINUX_NAME}_${LINUX_VER}")
else()
    add_definitions(-DPLATFORM="${SYS_ARCH}-${OS_NAME}_${OS_VER}")
endif()

if(PRE_RELEASE)
  add_definitions( -DPRE_RELEASE_STR=" ${PRE_RELEASE}" )
else()
  add_definitions( -DPRE_RELEASE_STR="" )
endif(PRE_RELEASE)
add_definitions( -DCONDOR_VERSION="${VERSION}" )

if( NOT BUILD_DATE )
  GET_DATE( BUILD_DATE )
endif()
if(BUILD_DATE)
  add_definitions( -DBUILD_DATE="${BUILD_DATE}" )
endif()

set( CONDOR_EXTERNAL_DIR ${CONDOR_SOURCE_DIR}/externals )

# set to true to enable printing of make actions
set( CMAKE_VERBOSE_MAKEFILE FALSE )
#set( BUILD_SHARED_LIBS FALSE )

# Windows is so different perform the check 1st and start setting the vars.
if( NOT WINDOWS)

	set( CMD_TERM && )

	if (_DEBUG)
	  set( CMAKE_BUILD_TYPE Debug )
	else()
	  # Using -O2 crashes the compiler on ppc mac os x when compiling
	  # condor_submit
	  if ( ${OS_NAME} STREQUAL "DARWIN" AND ${SYS_ARCH} STREQUAL "POWERPC" )
	    set( CMAKE_BUILD_TYPE Debug ) # = -g (package may strip the info)
	  else()
	    set( CMAKE_BUILD_TYPE RelWithDebInfo ) # = -O2 -g (package may strip the info)
	  endif()
	endif()

	set( CMAKE_SUPPRESS_REGENERATION FALSE )

	# when we want to distro dynamic libraries only with localized rpaths.
	# set (CMAKE_SKIP_RPATH TRUE)
	# set (CMAKE_BUILD_WITH_INSTALL_RPATH TRUE)
	# set (CMAKE_INSTALL_RPATH YOUR_LOC)
	# set (CMAKE_INSTALL_RPATH_USE_LINK_PATH TRUE)

	set(HAVE_PTHREAD_H ${CMAKE_HAVE_PTHREAD_H})

	find_library( HAVE_DMTCP dmtcpaware HINTS /usr/local/lib/dmtcp )
	find_library( LIBRESOLV_PATH resolv )
    if( NOT "${LIBRESOLV_PATH}" MATCHES "-NOTFOUND" )
      set(HAVE_LIBRESOLV ON)
    endif()
	find_library( LIBDL_PATH resolv )
    if( NOT "${LIBDL_PATH}" MATCHES "-NOTFOUND" )
      set(HAVE_LIBDL ON)
    endif()
	check_library_exists(dl dlopen "" HAVE_DLOPEN)
	check_symbol_exists(res_init "sys/types.h;netinet/in.h;arpa/nameser.h;resolv.h" HAVE_DECL_RES_INIT)

	check_function_exists("access" HAVE_ACCESS)
	check_function_exists("clone" HAVE_CLONE)
	check_function_exists("dirfd" HAVE_DIRFD)
	check_function_exists("execl" HAVE_EXECL)
	check_function_exists("fstat64" HAVE_FSTAT64)
	check_function_exists("_fstati64" HAVE__FSTATI64)
	check_function_exists("getdtablesize" HAVE_GETDTABLESIZE)
	check_function_exists("getpagesize" HAVE_GETPAGESIZE)
	check_function_exists("gettimeofday" HAVE_GETTIMEOFDAY)
	check_function_exists("inet_ntoa" HAS_INET_NTOA)
	check_function_exists("lchown" HAVE_LCHOWN)
	check_function_exists("lstat" HAVE_LSTAT)
	check_function_exists("lstat64" HAVE_LSTAT64)
	check_function_exists("_lstati64" HAVE__LSTATI64)
	check_function_exists("mkstemp" HAVE_MKSTEMP)
	check_function_exists("setegid" HAVE_SETEGID)
	check_function_exists("setenv" HAVE_SETENV)
	check_function_exists("seteuid" HAVE_SETEUID)
	check_function_exists("setlinebuf" HAVE_SETLINEBUF)
	check_function_exists("snprintf" HAVE_SNPRINTF)
	check_function_exists("snprintf" HAVE_WORKING_SNPRINTF)

	check_function_exists("stat64" HAVE_STAT64)
	check_function_exists("_stati64" HAVE__STATI64)
	check_function_exists("statfs" HAVE_STATFS)
	check_function_exists("statvfs" HAVE_STATVFS)
	check_function_exists("res_init" HAVE_DECL_RES_INIT)
	check_function_exists("strcasestr" HAVE_STRCASESTR)
	check_function_exists("strsignal" HAVE_STRSIGNAL)
	check_function_exists("unsetenv" HAVE_UNSETENV)
	check_function_exists("vasprintf" HAVE_VASPRINTF)
	check_function_exists("getifaddrs" HAVE_GETIFADDRS)
	check_function_exists("readdir64" HAVE_READDIR64)
	check_function_exists("backtrace" HAVE_BACKTRACE)

	# we can likely put many of the checks below in here.
	check_include_files("dlfcn.h" HAVE_DLFCN_H)
	check_include_files("inttypes.h" HAVE_INTTYPES_H)
	check_include_files("ldap.h" HAVE_LDAP_H)
	find_multiple( "ldap;lber" LDAP_FOUND )
	check_include_files("net/if.h" HAVE_NET_IF_H)
	check_include_files("os_types.h" HAVE_OS_TYPES_H)
	check_include_files("resolv.h" HAVE_RESOLV_H)
	check_include_files("sys/mount.h" HAVE_SYS_MOUNT_H)
	check_include_files("sys/param.h" HAVE_SYS_PARAM_H)
	check_include_files("sys/personality.h" HAVE_SYS_PERSONALITY_H)
	check_include_files("sys/syscall.h" HAVE_SYS_SYSCALL_H)
	check_include_files("sys/statfs.h" HAVE_SYS_STATFS_H)
	check_include_files("sys/statvfs.h" HAVE_SYS_STATVFS_H)
	check_include_files("sys/types.h" HAVE_SYS_TYPES_H)
	check_include_files("sys/vfs.h" HAVE_SYS_VFS_H)
	check_include_files("stdint.h" HAVE_STDINT_H)
	check_include_files("ustat.h" HAVE_USTAT_H)
	check_include_files("valgrind.h" HAVE_VALGRIND_H)
	check_include_files("procfs.h" HAVE_PROCFS_H)
	check_include_files("sys/procfs.h" HAVE_SYS_PROCFS_H)

	check_type_exists("struct ifconf" "sys/socket.h;net/if.h" HAVE_STRUCT_IFCONF)
	check_type_exists("struct ifreq" "sys/socket.h;net/if.h" HAVE_STRUCT_IFREQ)
	check_struct_has_member("struct ifreq" ifr_hwaddr "sys/socket.h;net/if.h" HAVE_STRUCT_IFREQ_IFR_HWADDR)

	check_struct_has_member("struct sockaddr_in" sin_len "netinet/in.h" HAVE_STRUCT_SOCKADDR_IN_SIN_LEN)

	check_struct_has_member("struct statfs" f_fstyp "sys/statfs.h" HAVE_STRUCT_STATFS_F_FSTYP)
	if (NOT ${OS_NAME} STREQUAL "DARWIN")
  	  if( HAVE_SYS_STATFS_H )
		check_struct_has_member("struct statfs" f_fstypename "sys/statfs.h" HAVE_STRUCT_STATFS_F_FSTYPENAME )
	  else()
		check_struct_has_member("struct statfs" f_fstypename "sys/mount.h" HAVE_STRUCT_STATFS_F_FSTYPENAME )
	  endif()
	endif()
	check_struct_has_member("struct statfs" f_type "sys/statfs.h" HAVE_STRUCT_STATFS_F_TYPE)
	check_struct_has_member("struct statvfs" f_basetype "sys/types.h;sys/statvfs.h" HAVE_STRUCT_STATVFS_F_BASETYPE)

	# the follow arg checks should be a posix check.
	# previously they were ~=check_cxx_source_compiles
	set(STATFS_ARGS "2")
	set(SIGWAIT_ARGS "2")

	check_cxx_source_compiles("
		#include <sched.h>
		int main() {
			cpu_set_t s;
			sched_setaffinity(0, 1024, &s);
			return 0;
		}
		" HAVE_SCHED_SETAFFINITY )

	check_cxx_source_compiles("
		#include <sched.h>
		int main() {
			cpu_set_t s;
			sched_setaffinity(0, &s);
			return 0;
		}
		" HAVE_SCHED_SETAFFINITY_2ARG )

	if(HAVE_SCHED_SETAFFINITY_2ARG)
		set(HAVE_SCHED_SETAFFINITY ON)
	endif()

	# note the following is fairly gcc specific, but *we* only check gcc version in std:u which it requires.
	exec_program (${CMAKE_CXX_COMPILER}
    		ARGS ${CMAKE_CXX_COMPILER_ARG1} -dumpversion
    		OUTPUT_VARIABLE CMAKE_CXX_COMPILER_VERSION )

	exec_program (${CMAKE_C_COMPILER}
    		ARGS ${CMAKE_C_COMPILER_ARG1} -dumpversion
    		OUTPUT_VARIABLE CMAKE_C_COMPILER_VERSION )

endif()

find_program(HAVE_VMWARE vmware)
find_program(LN ln)

# Check for the existense of and size of various types
check_type_size("id_t" ID_T)
check_type_size("__int64" __INT64)
check_type_size("int64_t" INT64_T)
check_type_size("int" INTEGER)
set(SIZEOF_INT "${INTEGER}")
check_type_size("long" LONG_INTEGER)
set(SIZEOF_LONG "${LONG_INTEGER}")
check_type_size("long long" LONG_LONG)
if(HAVE_LONG_LONG)
  set(SIZEOF_LONG_LONG "${LONG_LONG}")
endif()
check_type_size("void *" VOIDPTR)
set(SIZEOF_VOIDPTR "${VOIDPTR}")


##################################################
##################################################
# Now checking *nix OS based options
set(HAS_FLOCK ON)
set(DOES_SAVE_SIGSTATE OFF)

if (${OS_NAME} STREQUAL "SUNOS")
	set(SOLARIS ON)
	set(NEEDS_64BIT_SYSCALLS ON)
	set(NEEDS_64BIT_STRUCTS ON)
	set(DOES_SAVE_SIGSTATE ON)
	set(HAS_FLOCK OFF)
	add_definitions(-DSolaris)
	if (${OS_VER} STREQUAL "5.9")
		add_definitions(-DSolaris29)
	elseif(${OS_VER} STREQUAL "5.10")
		add_definitions(-DSolaris10)
	elseif(${OS_VER} STREQUAL "5.11")
		add_definitions(-DSolaris11)
	else()
		message(FATAL_ERROR "unknown version of Solaris")
	endif()
	add_definitions(-D_STRUCTURED_PROC)
	set(HAS_INET_NTOA ON)
	set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -lkstat -lelf -lnsl -lsocket")

	#update for solaris builds to use pre-reqs namely binutils in this case
	#set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -B$ENV{PATH}")

elseif(${OS_NAME} STREQUAL "LINUX")

	set(LINUX ON)
	set(DOES_SAVE_SIGSTATE ON)
	check_symbol_exists(SIOCETHTOOL "linux/sockios.h" HAVE_DECL_SIOCETHTOOL)
	check_symbol_exists(SIOCGIFCONF "linux/sockios.h" HAVE_DECL_SIOCGIFCONF)
	check_include_files("linux/ethtool.h" HAVE_LINUX_ETHTOOL_H)
	check_include_files("linux/magic.h" HAVE_LINUX_MAGIC_H)
	check_include_files("linux/nfsd/const.h" HAVE_LINUX_NFSD_CONST_H)
	check_include_files("linux/personality.h" HAVE_LINUX_PERSONALITY_H)
	check_include_files("linux/sockios.h" HAVE_LINUX_SOCKIOS_H)
	check_include_files("linux/types.h" HAVE_LINUX_TYPES_H)

	find_library(HAVE_X11 X11)
	dprint("Threaded functionality only enable in Linux and Windows")
	set(HAS_PTHREADS ${CMAKE_USE_PTHREADS_INIT})
	set(HAVE_PTHREADS ${CMAKE_USE_PTHREADS_INIT})

	# Even if the flavor of linux we are compiling on doesn't
	# have Pss in /proc/pid/smaps, the binaries we generate
	# may run on some other version of linux that does, so
	# be optimistic here.
	set(HAVE_PSS ON)

	#The following checks are for std:u only.
	glibc_detect( GLIBC_VERSION )

elseif(${OS_NAME} STREQUAL "AIX")
	set(AIX ON)
	set(DOES_SAVE_SIGSTATE ON)
	set(NEEDS_64BIT_STRUCTS ON)
elseif(${OS_NAME} STREQUAL "DARWIN")
	add_definitions(-DDarwin)
	set(DARWIN ON)
	check_struct_has_member("struct statfs" f_fstypename "sys/param.h;sys/mount.h" HAVE_STRUCT_STATFS_F_FSTYPENAME)
elseif(${OS_NAME} STREQUAL "HPUX")
	set(HPUX ON)
	set(DOES_SAVE_SIGSTATE ON)
	set(NEEDS_64BIT_STRUCTS ON)
elseif(${OS_NAME} STREQUAL "HPUX")
	set(HPUX ON)
	set(DOES_SAVE_SIGSTATE ON)
	set(NEEDS_64BIT_STRUCTS ON)
endif()

##################################################
##################################################
# compilation/build options.
option(UW_BUILD "Variable to allow UW-esk builds." OFF)
option(HAVE_HIBERNATION "Support for condor controlled hibernation" ON)
option(WANT_LEASE_MANAGER "Enable lease manager functionality" ON)
option(HAVE_JOB_HOOKS "Enable job hook functionality" ON)
option(HAVE_BACKFILL "Compiling support for any backfill system" ON)
option(HAVE_BOINC "Compiling support for backfill with BOINC" ON)
option(SOFT_IS_HARD "Enable strict checking for WITH_<LIB>" OFF)
option(BUILD_TESTS "Will build internal test applications" ON)
option(WANT_CONTRIB "Enable quill functionality" OFF)
option(WANT_FULL_DEPLOYMENT "Install condors deployment scripts, libs, and includes" ON)
option(WANT_GLEXEC "Build and install condor glexec functionality" ON)
option(ENABLE_JAVA_TESTS "Enable java tests" ON)

if (UW_BUILD OR WINDOWS)
  option(PROPER "Try to build using native env" OFF)

  # so the clipped detection will try to match glibc vers and if it fails will disable
  if (LINUX)
	option(CLIPPED "enable/disable the standard universe" OFF)
  else()
	option(CLIPPED "enable/disable the standard universe" ON)
  endif()

  dprint("**TO UW: IF YOU WANT CUSTOM SETTINGS ADD THEM HERE**")

else()
  option(PROPER "Try to build using native env" ON)
  option(CLIPPED "disable the standard universe" ON)
endif()

if (NOT WINDOWS)
    if (HAVE_X11)
        if (NOT (${HAVE_X11} STREQUAL "HAVE_X11-NOTFOUND"))
            option(HAVE_KBDD "Support for condor_kbdd" ON)
        endif()
    endif()
else()
    option(HAVE_KBDD "Support for condor_kbdd" ON)
endif()

if (NOT CLIPPED AND NOT LINUX)
	message (FATAL_ERROR "standard universe is *only* supported on Linux")
endif()

if (NOT HPUX)
	option(HAVE_SHARED_PORT "Support for condor_shared_port" ON)
	if (NOT WINDOWS)
		set (HAVE_SCM_RIGHTS_PASSFD ON)
	endif()
endif(NOT HPUX)

if (NOT WINDOWS) 
    option(HAVE_SSH_TO_JOB "Support for condor_ssh_to_job" ON)
endif()

if (BUILD_TESTS)
	set(TEST_TARGET_DIR ${CMAKE_BINARY_DIR}/src/condor_tests)
endif(BUILD_TESTS)

##################################################
##################################################
# setup for the externals, the variables defined here
# are used in the construction of externals within
# the condor build.  The point of main interest is
# how "cacheing" is performed by performing the build
# external to the tree itself.
if (PROPER)
	message(STATUS "********* Configuring externals using [local env] a.k.a. PROPER *********")
	find_path(HAVE_OPENSSL_SSL_H "openssl/ssl.h")
	find_path(HAVE_PCRE_H "pcre.h")
	find_path(HAVE_PCRE_PCRE_H "pcre/pcre.h" )
else()
	message(STATUS "********* Configuring externals using [uw-externals] a.k.a NONPROPER *********")
endif(PROPER)

if (WINDOWS)
	# the environment variable CONDOR_BLD_EXTERNAL_STAGE will be set to the
	# path for externals if the invoker wants shared externals. otherwise
	# just build externals in a sub-directory of the project directory
	#
	set (EXTERNAL_STAGE $ENV{CONDOR_BLD_EXTERNAL_STAGE})
	if (EXTERNAL_STAGE)
        # cmake doesn't like windows paths, so make sure that this path separators are unix style
	    string (REPLACE "\\" "/" EXTERNAL_STAGE "${EXTERNAL_STAGE}")
	else()
	   set (EXTERNAL_STAGE ${PROJECT_BINARY_DIR}/bld_external)
    endif(EXTERNAL_STAGE)
else()
	if (PROPER)
		set (EXTERNAL_STAGE ${CMAKE_CURRENT_BINARY_DIR}/externals/stage/root/${PACKAGE_NAME}_${PACKAGE_VERSION})
	else()
		# temporarily disable AFS cache. 
		#if ( EXISTS /p/condor/workspaces/externals  )
		#	set (EXTERNAL_STAGE /p/condor/workspaces/externals/cmake/${OS_NAME}/${SYS_ARCH})
		#else()
			# in case someone tries something funky insert OS & ARCH in path
			set (EXTERNAL_STAGE /scratch/condor_externals) #${OS_NAME}/${SYS_ARCH})
		#endif()	
	endif()
endif(WINDOWS)

dprint("EXTERNAL_STAGE=${EXTERNAL_STAGE}")
if (NOT EXISTS ${EXTERNAL_STAGE})
	file ( MAKE_DIRECTORY ${EXTERNAL_STAGE} )
endif()

###########################################
add_subdirectory(${CONDOR_EXTERNAL_DIR}/bundles/boost/1.39.0)
add_subdirectory(${CONDOR_EXTERNAL_DIR}/bundles/qpid/0.8-RC3)
add_subdirectory(${CONDOR_EXTERNAL_DIR}/bundles/krb5/1.4.3-p0)
add_subdirectory(${CONDOR_EXTERNAL_DIR}/bundles/openssl/0.9.8h-p2)
add_subdirectory(${CONDOR_EXTERNAL_DIR}/bundles/pcre/7.6)
add_subdirectory(${CONDOR_EXTERNAL_DIR}/bundles/gsoap/2.7.10-p5)
# use from external package
#add_subdirectory(${CONDOR_SOURCE_DIR}/src/classad)
add_subdirectory(${CONDOR_EXTERNAL_DIR}/bundles/zlib/1.2.3)
add_subdirectory(${CONDOR_EXTERNAL_DIR}/bundles/curl/7.19.6-p1 )
add_subdirectory(${CONDOR_EXTERNAL_DIR}/bundles/hadoop/0.21.0)
add_subdirectory(${CONDOR_EXTERNAL_DIR}/bundles/postgresql/8.2.3-p1)
add_subdirectory(${CONDOR_EXTERNAL_DIR}/bundles/drmaa/1.6)

if (NOT WINDOWS)
	add_subdirectory(${CONDOR_EXTERNAL_DIR}/bundles/coredumper/0.2)
	add_subdirectory(${CONDOR_EXTERNAL_DIR}/bundles/unicoregahp/1.2.0)
	add_subdirectory(${CONDOR_EXTERNAL_DIR}/bundles/expat/2.0.1)
	add_subdirectory(${CONDOR_EXTERNAL_DIR}/bundles/libxml2/2.7.3)
	add_subdirectory(${CONDOR_EXTERNAL_DIR}/bundles/libvirt/0.6.2)
	add_subdirectory(${CONDOR_EXTERNAL_DIR}/bundles/libdeltacloud/0.7)
	add_subdirectory(${CONDOR_EXTERNAL_DIR}/bundles/libcgroup/0.37)

	# globus is an odd *beast* which requires a bit more config.
	add_subdirectory(${CONDOR_EXTERNAL_DIR}/bundles/globus/5.0.1-p1)
	add_subdirectory(${CONDOR_EXTERNAL_DIR}/bundles/blahp/1.16.1)
	add_subdirectory(${CONDOR_EXTERNAL_DIR}/bundles/voms/1.9.10_4)
	add_subdirectory(${CONDOR_EXTERNAL_DIR}/bundles/cream/1.12.1_14)
	add_subdirectory(${CONDOR_EXTERNAL_DIR}/bundles/wso2/2.1.0)

	# the following logic if for standard universe *only*
	if (LINUX AND NOT CLIPPED AND GLIBC_VERSION AND NOT PROPER)

		add_subdirectory(${CONDOR_EXTERNAL_DIR}/bundles/glibc)

		if (EXT_GLIBC_FOUND)
		  if (${BIT_MODE} STREQUAL "32")
			  set (DOES_COMPRESS_CKPT ON) # this is total crap
		  endif(${BIT_MODE} STREQUAL "32")

		  if (DOES_SAVE_SIGSTATE)
			  set(STD_U_C_FLAGS -DSAVE_SIGSTATE)
		  endif(DOES_SAVE_SIGSTATE)

		  set (STD_UNIVERSE ON)

		  # seriously I've sold my soul doing this dirty work
		  set (CONDOR_COMPILE ${CONDOR_SOURCE_DIR}/src/condor_scripts/condor_compile)
		  set (CONDOR_ARCH_LINK ${CONDOR_SOURCE_DIR}/src/condor_scripts/condor_arch_link)
		  set (STDU_LIB_LOC ${CMAKE_INSTALL_PREFIX}/${C_LIB})

		  include_directories( ${CONDOR_SOURCE_DIR}/src/condor_io.std )

		  message( STATUS "** Standard Universe Enabled **")

		else()
			message( STATUS "** Standard Universe Disabled **")
		endif()
	else()
		message( STATUS "** Standard Universe Disabled **")
	endif()

endif(NOT WINDOWS)

if (CONDOR_EXTERNALS AND NOT WINDOWS)
	### addition of a single externals target which allows you to
	add_custom_target( externals DEPENDS ${EXTERNAL_MOD_DEP} )
	add_dependencies( externals ${CONDOR_EXTERNALS} )
endif(CONDOR_EXTERNALS AND NOT WINDOWS)

######### special case for contrib
if (WANT_CONTRIB AND WITH_MANAGEMENT)
    # global scoping external linkage var when options enable.
    if (WINDOWS)
        set (CONDOR_QMF condor_qmflib;${QPID_FOUND})
    endif()
    add_definitions( -DWANT_CONTRIB )
    add_definitions( -DWITH_MANAGEMENT )
endif()

message(STATUS "********* External configuration complete (dropping config.h) *********")
dprint("CONDOR_EXTERNALS=${CONDOR_EXTERNALS}")

########################################################
configure_file(${CONDOR_SOURCE_DIR}/src/condor_includes/config.h.cmake ${CMAKE_CURRENT_BINARY_DIR}/src/condor_includes/config.tmp)
# only update config.h if it is necessary b/c it causes massive rebuilding.
exec_program ( ${CMAKE_COMMAND} ARGS -E copy_if_different ${CMAKE_CURRENT_BINARY_DIR}/src/condor_includes/config.tmp ${CMAKE_CURRENT_BINARY_DIR}/src/condor_includes/config.h )
add_definitions(-DHAVE_CONFIG_H)

###########################################
# include and link locations
include_directories( ${CONDOR_EXTERNAL_INCLUDE_DIRS} )
link_directories( ${CONDOR_EXTERNAL_LINK_DIRS} )

if ( $ENV{JAVA_HOME} )
	include_directories($ENV{JAVA_HOME}/include)
endif()

include_directories(${CONDOR_SOURCE_DIR}/src/condor_includes)
include_directories(${CMAKE_CURRENT_BINARY_DIR}/src/condor_includes)
include_directories(${CONDOR_SOURCE_DIR}/src/condor_utils)
include_directories(${CMAKE_CURRENT_BINARY_DIR}/src/condor_utils)
set (DAEMON_CORE ${CONDOR_SOURCE_DIR}/src/condor_daemon_core.V6) #referenced elsewhere primarily for soap gen stuff
include_directories(${DAEMON_CORE})
include_directories(${CONDOR_SOURCE_DIR}/src/condor_daemon_client)
include_directories(${CONDOR_SOURCE_DIR}/src/ccb)
include_directories(${CONDOR_SOURCE_DIR}/src/condor_io)
include_directories(${CONDOR_SOURCE_DIR}/src/h)
include_directories(${CMAKE_CURRENT_BINARY_DIR}/src/h)
#include_directories(${CONDOR_SOURCE_DIR}/src/classad)
if (WANT_CONTRIB)
    include_directories(${CONDOR_SOURCE_DIR}/src/condor_contrib)
endif(WANT_CONTRIB)
###########################################

###########################################
#extra build flags and link libs.
if (HAVE_EXT_OPENSSL)
	add_definitions(-DWITH_OPENSSL) # used only by SOAP
endif(HAVE_EXT_OPENSSL)

if (HAVE_SSH_TO_JOB AND NOT HAVE_EXT_OPENSSL)
	message (FATAL_ERROR "HAVE_SSH_TO_JOB requires openssl (for condor_base64 functions)")
endif()

###########################################
# order of the below elements is important, do not touch unless you know what you are doing.
# otherwise you will break due to stub collisions.
set (CONDOR_LIBS "procd_client;daemon_core;daemon_client;procapi;cedar;privsep;${CLASSADS_FOUND};sysapi;ccb;utils;${VOMS_FOUND};${GLOBUS_FOUND};${EXPAT_FOUND};${PCRE_FOUND}")
set (CONDOR_TOOL_LIBS "procd_client;daemon_client;procapi;cedar;privsep;${CLASSADS_FOUND};sysapi;ccb;utils;${VOMS_FOUND};${GLOBUS_FOUND};${EXPAT_FOUND};${PCRE_FOUND}")
set (CONDOR_SCRIPT_PERMS OWNER_READ OWNER_WRITE OWNER_EXECUTE GROUP_READ GROUP_EXECUTE WORLD_READ WORLD_EXECUTE)

message(STATUS "----- Begin compiler options/flags check -----")

if (CONDOR_CXX_FLAGS)
	set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${CONDOR_CXX_FLAGS}")
endif()

if(MSVC)
	set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} /FC")      # use full paths names in errors and warnings
	#set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} /wd4251")  #
	#set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} /wd4275")  #
	set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} /wd4996")  # use of obsolete names for c-runtime functions	
	#set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} /wd4273")  # inconsistent dll linkage
	set(CONDOR_WIN_LIBS "crypt32.lib;mpr.lib;psapi.lib;mswsock.lib;netapi32.lib;imagehlp.lib;ws2_32.lib;powrprof.lib;iphlpapi.lib;userenv.lib;Pdh.lib")
else(MSVC)

	if (GLIBC_VERSION)
		add_definitions(-DGLIBC=GLIBC)
		add_definitions(-DGLIBC${GLIBC_VERSION}=GLIBC${GLIBC_VERSION})
		set(GLIBC${GLIBC_VERSION} ON)
	endif(GLIBC_VERSION)

	check_cxx_compiler_flag(-Wall cxx_Wall)
	if (cxx_Wall)
		set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wall")
	endif(cxx_Wall)

	check_cxx_compiler_flag(-W cxx_W)
	if (cxx_W)
		set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -W")
	endif(cxx_W)

	check_cxx_compiler_flag(-Wextra cxx_Wextra)
	if (cxx_Wextra)
		set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wextra")
	endif(cxx_Wextra)

	check_cxx_compiler_flag(-Wfloat-equal cxx_Wfloat_equal)
	if (cxx_Wfloat_equal)
		set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wfloat-equal")
	endif(cxx_Wfloat_equal)

	check_cxx_compiler_flag(-Wshadow cxx_Wshadow)
	if (cxx_Wshadow)
		set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wshadow")
	endif(cxx_Wshadow)

	# someone else can enable this, as it overshadows all other warnings and can be wrong.
	# check_cxx_compiler_flag(-Wunreachable-code cxx_Wunreachable_code)
	# if (cxx_Wunreachable_code)
	#	set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wunreachable-code")
	# endif(cxx_Wunreachable_code)

	check_cxx_compiler_flag(-Wendif-labels cxx_Wendif_labels)
	if (cxx_Wendif_labels)
		set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wendif-labels")
	endif(cxx_Wendif_labels)

	check_cxx_compiler_flag(-Wpointer-arith cxx_Wpointer_arith)
	if (cxx_Wpointer_arith)
		set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wpointer-arith")
	endif(cxx_Wpointer_arith)

	check_cxx_compiler_flag(-Wcast-qual cxx_Wcast_qual)
	if (cxx_Wcast_qual)
		set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wcast-qual")
	endif(cxx_Wcast_qual)

	check_cxx_compiler_flag(-Wcast-align cxx_Wcast_align)
	if (cxx_Wcast_align)
		set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wcast-align")
	endif(cxx_Wcast_align)

	check_cxx_compiler_flag(-Wvolatile-register-var cxx_Wvolatile_register_var)
	if (cxx_Wvolatile_register_var)
		set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wvolatile-register-var")
	endif(cxx_Wvolatile_register_var)

	# gcc on our AIX machines recognizes -fstack-protector, but lacks
	# the requisite library.
	if (NOT AIX)
		check_cxx_compiler_flag(-fstack-protector cxx_fstack_protector)
		if (cxx_fstack_protector)
			set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fstack-protector")
		endif(cxx_fstack_protector)

		check_cxx_compiler_flag(-fnostack-protector cxx_fnostack_protector)
		if (cxx_fnostack_protector)
			set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fnostack-protector")
		endif(cxx_fnostack_protector)
	endif(NOT AIX)

	check_cxx_compiler_flag(-rdynamic cxx_rdynamic)
	if (cxx_rdynamic)
		set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -rdynamic")
	endif(cxx_rdynamic)

	if (LINUX)
		set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -Wl,--warn-once -Wl,--warn-common")
	endif(LINUX)

	if( HAVE_LIBDL AND NOT BSD_UNIX )
		set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -ldl")
	endif()

	if (AIX)
		# specifically ask for the C++ libraries to be statically linked
		set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -Wl,-berok -Wl,-bstatic -lstdc++ -Wl,-bdynamic -lcfg -lodm -static-libgcc")
	endif(AIX)

	if ( NOT PROPER AND HAVE_LIBRESOLV )
		set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -lresolv")
		if (NOT DARWIN)
			set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -lcrypt")
		endif()
	endif()

	if (HAVE_PTHREADS)
		set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -pthread")
	endif(HAVE_PTHREADS)

	check_cxx_compiler_flag(-shared HAVE_CC_SHARED)

	if ( NOT PROPER AND ${SYS_ARCH} MATCHES "86")

		if (NOT ${SYS_ARCH} MATCHES "64" )
			add_definitions( -DI386=${SYS_ARCH} )
		endif()

		# set for maximum binary compatibility based on current machine arch.
		check_cxx_compiler_flag(-mtune=generic cxx_mtune)
		if (cxx_mtune)
			set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -mtune=generic")
		endif(cxx_mtune)

	endif()

	add_definitions(-D${SYS_ARCH}=${SYS_ARCH})

	# b/c we don't do anything c++ specific copy flags for c-compilation
	set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${CMAKE_CXX_FLAGS}")

endif(MSVC)

message(STATUS "----- End compiler options/flags check -----")
message(STATUS "----- Begin CMake Var DUMP -----")
message(STATUS "CMAKE_STRIP: ${CMAKE_STRIP}")
message(STATUS "LN: ${LN}")
# if you are building in-source, this is the same as CMAKE_SOURCE_DIR, otherwise
# this is the top level directory of your build tree
dprint ( "CMAKE_BINARY_DIR: ${CMAKE_BINARY_DIR}" )

# if you are building in-source, this is the same as CMAKE_CURRENT_SOURCE_DIR, otherwise this
# is the directory where the compiled or generated files from the current CMakeLists.txt will go to
dprint ( "CMAKE_CURRENT_BINARY_DIR: ${CMAKE_CURRENT_BINARY_DIR}" )

# this is the directory, from which cmake was started, i.e. the top level source directory
dprint ( "CMAKE_SOURCE_DIR: ${CMAKE_SOURCE_DIR}" )

# this is the directory where the currently processed CMakeLists.txt is located in
dprint ( "CMAKE_CURRENT_SOURCE_DIR: ${CMAKE_CURRENT_SOURCE_DIR}" )

# contains the full path to the top level directory of your build tree
dprint ( "PROJECT_BINARY_DIR: ${PROJECT_BINARY_DIR}" )

# contains the full path to the root of your project source directory,
# i.e. to the nearest directory where CMakeLists.txt contains the PROJECT() command
dprint ( "PROJECT_SOURCE_DIR: ${PROJECT_SOURCE_DIR}" )

# set this variable to specify a common place where CMake should put all executable files
# (instead of CMAKE_CURRENT_BINARY_DIR)
dprint ( "EXECUTABLE_OUTPUT_PATH: ${EXECUTABLE_OUTPUT_PATH}" )

# set this variable to specify a common place where CMake should put all libraries
# (instead of CMAKE_CURRENT_BINARY_DIR)
dprint ( "LIBRARY_OUTPUT_PATH: ${LIBRARY_OUTPUT_PATH}" )

# tell CMake to search first in directories listed in CMAKE_MODULE_PATH
# when you use FIND_PACKAGE() or INCLUDE()
dprint ( "CMAKE_MODULE_PATH: ${CMAKE_MODULE_PATH}" )

# print out where we are installing to.
dprint ( "CMAKE_INSTALL_PREFIX: ${CMAKE_INSTALL_PREFIX}" )

# this is the complete path of the cmake which runs currently (e.g. /usr/local/bin/cmake)
dprint ( "CMAKE_COMMAND: ${CMAKE_COMMAND}" )

# this is the CMake installation directory
dprint ( "CMAKE_ROOT: ${CMAKE_ROOT}" )

# this is the filename including the complete path of the file where this variable is used.
dprint ( "CMAKE_CURRENT_LIST_FILE: ${CMAKE_CURRENT_LIST_FILE}" )

# this is linenumber where the variable is used
dprint ( "CMAKE_CURRENT_LIST_LINE: ${CMAKE_CURRENT_LIST_LINE}" )

# this is used when searching for include files e.g. using the FIND_PATH() command.
dprint ( "CMAKE_INCLUDE_PATH: ${CMAKE_INCLUDE_PATH}" )

# this is used when searching for libraries e.g. using the FIND_LIBRARY() command.
dprint ( "CMAKE_LIBRARY_PATH: ${CMAKE_LIBRARY_PATH}" )

# the complete system name, e.g. "Linux-2.4.22", "FreeBSD-5.4-RELEASE" or "Windows 5.1"
dprint ( "CMAKE_SYSTEM: ${CMAKE_SYSTEM}" )

# the short system name, e.g. "Linux", "FreeBSD" or "Windows"
dprint ( "CMAKE_SYSTEM_NAME: ${CMAKE_SYSTEM_NAME}" )

# only the version part of CMAKE_SYSTEM
dprint ( "CMAKE_SYSTEM_VERSION: ${CMAKE_SYSTEM_VERSION}" )

# the processor name (e.g. "Intel(R) Pentium(R) M processor 2.00GHz")
dprint ( "CMAKE_SYSTEM_PROCESSOR: ${CMAKE_SYSTEM_PROCESSOR}" )

# the Condor src directory
dprint ( "CONDOR_SOURCE_DIR: ${CONDOR_SOURCE_DIR}" )
dprint ( "CONDOR_EXTERNAL_DIR: ${CONDOR_EXTERNAL_DIR}" )
dprint ( "TEST_TARGET_DIR: ${TEST_TARGET_DIR}" )

# the Condor version string being used
dprint ( "CONDOR_VERSION: ${CONDOR_VERSION}" )

# the build id
dprint ( "BUILDID: ${BUILDID}" )

# the build date & time
dprint ( "BUILD_TIMEDATE: ${BUILD_TIMEDATE}" )
dprint ( "BUILD_DATE: ${BUILD_DATE}" )

# the pre-release string
dprint ( "PRE_RELEASE: ${PRE_RELEASE}" )

# the platform specified
dprint ( "PLATFORM: ${PLATFORM}" )

# the Condor platform specified
dprint ( "CONDOR_PLATFORM: ${CONDOR_PLATFORM}" )

# the system name (used for generated tarballs)
dprint ( "SYSTEM_NAME: ${SYSTEM_NAME}" )

# the RPM system name (used for generated tarballs)
dprint ( "RPM_SYSTEM_NAME: ${RPM_SYSTEM_NAME}" )

# the Condor package name
dprint ( "CONDOR_PACKAGE_NAME: ${CONDOR_PACKAGE_NAME}" )

# is TRUE on all UNIX-like OS's, including Apple OS X and CygWin
dprint ( "UNIX: ${UNIX}" )

# is TRUE on all BSD-derived UNIXen
dprint ( "BSD_UNIX: ${BSD_UNIX}" )

# is TRUE on all UNIX-like OS's, including Apple OS X and CygWin
dprint ( "Linux: ${LINUX_NAME}" )

# Print FreeBSD info
dprint ( "FreeBSD: ${FREEBSD_MAJOR}.${FREEBSD_MINOR}" )

# is TRUE on Windows, including CygWin
dprint ( "WIN32: ${WIN32}" )

# is TRUE on Apple OS X
dprint ( "APPLE: ${APPLE}" )

# is TRUE when using the MinGW compiler in Windows
dprint ( "MINGW: ${MINGW}" )

# is TRUE on Windows when using the CygWin version of cmake
dprint ( "CYGWIN: ${CYGWIN}" )

# is TRUE on Windows when using a Borland compiler
dprint ( "BORLAND: ${BORLAND}" )

if (WINDOWS)
	dprint ( "MSVC: ${MSVC}" )
	dprint ( "MSVC_IDE: ${MSVC_IDE}" )
	dprint ( "MSVC60: ${MSVC60}" )
	dprint ( "MSVC70: ${MSVC70}" )
	dprint ( "MSVC71: ${MSVC71}" )
	dprint ( "MSVC80: ${MSVC80}" )
	dprint ( "CMAKE_COMPILER_2005: ${CMAKE_COMPILER_2005}" )
endif(WINDOWS)

# set this to true if you don't want to rebuild the object files if the rules have changed,
# but not the actual source files or headers (e.g. if you changed the some compiler switches)
dprint ( "CMAKE_SKIP_RULE_DEPENDENCY: ${CMAKE_SKIP_RULE_DEPENDENCY}" )

# since CMake 2.1 the install rule depends on all, i.e. everything will be built before installing.
# If you don't like this, set this one to true.
dprint ( "CMAKE_SKIP_INSTALL_ALL_DEPENDENCY: ${CMAKE_SKIP_INSTALL_ALL_DEPENDENCY}" )

# If set, runtime paths are not added when using shared libraries. Default it is set to OFF
dprint ( "CMAKE_SKIP_RPATH: ${CMAKE_SKIP_RPATH}" )

# set this to true if you are using makefiles and want to see the full compile and link
# commands instead of only the shortened ones
dprint ( "CMAKE_VERBOSE_MAKEFILE: ${CMAKE_VERBOSE_MAKEFILE}" )

# this will cause CMake to not put in the rules that re-run CMake. This might be useful if
# you want to use the generated build files on another machine.
dprint ( "CMAKE_SUPPRESS_REGENERATION: ${CMAKE_SUPPRESS_REGENERATION}" )

# A simple way to get switches to the compiler is to use ADD_DEFINITIONS().
# But there are also two variables exactly for this purpose:

# output what the linker flags are
dprint ( "CMAKE_EXE_LINKER_FLAGS: ${CMAKE_EXE_LINKER_FLAGS}" )

# the compiler flags for compiling C sources
dprint ( "CMAKE_C_FLAGS: ${CMAKE_C_FLAGS}" )

# the compiler flags for compiling C++ sources
dprint ( "CMAKE_CXX_FLAGS: ${CMAKE_CXX_FLAGS}" )

# Choose the type of build.  Example: SET(CMAKE_BUILD_TYPE Debug)
dprint ( "CMAKE_BUILD_TYPE: ${CMAKE_BUILD_TYPE}" )

# if this is set to ON, then all libraries are built as shared libraries by default.
dprint ( "BUILD_SHARED_LIBS: ${BUILD_SHARED_LIBS}" )

# the compiler used for C files
dprint ( "CMAKE_C_COMPILER: ${CMAKE_C_COMPILER}" )

# version information about the compiler
dprint ( "CMAKE_C_COMPILER_VERSION: ${CMAKE_C_COMPILER_VERSION}" )

# the compiler used for C++ files
dprint ( "CMAKE_CXX_COMPILER: ${CMAKE_CXX_COMPILER}" )

# version information about the compiler
dprint ( "CMAKE_CXX_COMPILER_VERSION: ${CMAKE_CXX_COMPILER_VERSION}" )

# if the compiler is a variant of gcc, this should be set to 1
dprint ( "CMAKE_COMPILER_IS_GNUCC: ${CMAKE_COMPILER_IS_GNUCC}" )

# if the compiler is a variant of g++, this should be set to 1
dprint ( "CMAKE_COMPILER_IS_GNUCXX : ${CMAKE_COMPILER_IS_GNUCXX}" )

# the tools for creating libraries
dprint ( "CMAKE_AR: ${CMAKE_AR}" )
dprint ( "CMAKE_RANLIB: ${CMAKE_RANLIB}" )

message(STATUS "----- Begin CMake Var DUMP -----")

message(STATUS "********* ENDING CONFIGURATION *********")
