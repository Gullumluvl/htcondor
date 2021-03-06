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

condor_exe( condor_testingd "testingd.cpp" ${C_LIBEXEC} "${CONDOR_LIBS}" OFF )
condor_exe( condor_sinful "sinful-tool.cpp" ${C_LIBEXEC} "${CONDOR_LIBS}" OFF )
condor_exe( test_user_mapping "test_user_mapping.cpp" ${C_LIBEXEC} "${CONDOR_LIBS}" OFF )

##################################################
# utils library
if(WINDOWS)
  file( GLOB RmvSrcs y.tab* lex.yy* ckpt_server_api_stubs* libcondorapi_stubs* dprintf_syslog*
  testingd.cpp sinful-tool.cpp test_user_mapping.cpp
  test_* *.t.cpp *test.cpp cat_url.cpp *Test* param_info_hash.cpp param_info_init.c )
else()
  file( GLOB RmvSrcs y.tab* lex.yy* ckpt_server_api_stubs* libcondorapi_stubs* 
  testingd.cpp sinful-tool.cpp test_user_mapping.cpp
  test_* *.t.cpp *test.cpp cat_url.cpp *Test* param_info_hash.cpp param_info_init.c )
endif()

condor_glob( HeaderFiles SourceFiles "${RmvSrcs}" )

############ generate params
add_custom_command (OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/command_name_tables.h
		COMMAND perl
		ARGS ${CMAKE_CURRENT_SOURCE_DIR}/command_table_generator.pl -i ${CMAKE_CURRENT_SOURCE_DIR}/../condor_includes/condor_commands.h -o ${CMAKE_CURRENT_BINARY_DIR}/command_name_tables.h
		DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/../condor_includes/condor_commands.h ${CMAKE_CURRENT_SOURCE_DIR}/command_table_generator.pl)

add_custom_command (OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/param_info_tables.h
		COMMAND perl
		ARGS ${CMAKE_CURRENT_SOURCE_DIR}/param_table_generator.pl -i ${CMAKE_CURRENT_SOURCE_DIR}/param_info.in -o ${CMAKE_CURRENT_BINARY_DIR}/param_info_tables.h -p ${PLATFORM}
		DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/param_info.in ${CMAKE_CURRENT_SOURCE_DIR}/param_table_generator.pl)

add_custom_target (utils_genparams ALL DEPENDS ${CMAKE_CURRENT_BINARY_DIR}/param_info_tables.h ${CMAKE_CURRENT_BINARY_DIR}/command_name_tables.h)

if(UNIX)
	set_source_files_properties(param_info.cpp PROPERTIES COMPILE_FLAGS -Wno-unused-parameter)
endif(UNIX)

############ end generate params


# These are source files that reside in other directories that we want to
# include in libcondor_utils. They used to be in separate libraries.
set( EXTRA_SRCS "${SAFE_OPEN_SRC};${ANALYSIS_UTIL_SRCS};${CCB_UTIL_SRCS};${CEDAR_UTIL_SRCS};${DAEMON_CLIENT_UTIL_SRCS};${DAEMON_CORE_UTIL_SRCS};${PROCAPI_UTIL_SRCS};${PROCD_CLIENT_UTIL_SRCS};${QMGMT_UTIL_SRCS};${SYSAPI_UTIL_SRCS}" )
if (UNIX)
set_source_files_properties(../condor_sysapi/clinpack.cpp PROPERTIES COMPILE_FLAGS -w)
set_source_files_properties(../condor_daemon_core.V6/self_monitor.cpp ../classad_analysis/analysis.cpp ../classad_analysis/interval.cpp generic_stats.cpp generic_query.cpp PROPERTIES COMPILE_FLAGS -Wno-float-equal)
endif(UNIX)

if (SCITOKENS_FOUND)
include_directories(${SCITOKENS_INCLUDE_DIRS})
endif(SCITOKENS_FOUND)

# Turn off the OpenSSL deprecation warnings until we decide on the long-term direction with OpenSSL on Mac.
if (DARWIN)
	set_source_files_properties(condor_base64.cpp PROPERTIES COMPILE_FLAGS -Wno-deprecated-declarations)
	set_source_files_properties(condor_dh.cpp PROPERTIES COMPILE_FLAGS -Wno-deprecated-declarations)
	set_source_files_properties(condor_md.cpp PROPERTIES COMPILE_FLAGS -Wno-deprecated-declarations)
	set_source_files_properties(../condor_io/condor_auth_passwd.cpp PROPERTIES COMPILE_FLAGS -Wno-deprecated-declarations)
	set_source_files_properties(../condor_io/condor_auth_ssl.cpp PROPERTIES COMPILE_FLAGS -Wno-deprecated-declarations)
	set_source_files_properties(../condor_io/condor_crypt.cpp PROPERTIES COMPILE_FLAGS -Wno-deprecated-declarations)
	set_source_files_properties(../condor_io/condor_crypt_3des.cpp PROPERTIES COMPILE_FLAGS -Wno-deprecated-declarations)
	set_source_files_properties(../condor_io/condor_crypt_blowfish.cpp PROPERTIES COMPILE_FLAGS -Wno-deprecated-declarations)
endif()

condor_shared_lib( condor_utils "${HeaderFiles};${SourceFiles};${EXTRA_SRCS}" )
add_dependencies(condor_utils utils_genparams )
if ( ${PACKAGE_VERSION} MATCHES "([0-9]+)[.]([0-9]+)[.]([0-9]+)" )
	set( UTILS_LIB_NAME "condor_utils_${CMAKE_MATCH_1}_${CMAKE_MATCH_2}_${CMAKE_MATCH_3}" )
else()
	message(FATAL_ERROR "Can't determine Condor version!")
endif()
set_target_properties( condor_utils PROPERTIES OUTPUT_NAME "${UTILS_LIB_NAME}" )
if (HAVE_GNU_LD)
	target_link_libraries( condor_utils -Wl,--wrap,exit )
endif()

# for linux also make a static version of condor_utils
#
if (LINUX OR DARWIN)
   condor_static_lib( condor_utils_s "${HeaderFiles};${SourceFiles};${EXTRA_SRCS}" )
   add_dependencies( condor_utils_s utils_genparams )
   set_target_properties( condor_utils_s PROPERTIES OUTPUT_NAME "${UTILS_LIB_NAME}" )
   if (HAVE_GNU_LD)
	target_link_libraries( condor_utils_s -Wl,--wrap,exit )
   endif()
endif(LINUX OR DARWIN)


# Brain twister:
#
# If you dynamicly load a library which links against libcondor_utils (such as
# a python module), the dprintf inside libcondor_utils will be linked against
# the libc dprintf.  Hilarity ensues as internal condor functions use the libc
# dprintf.
#
# The magic below will cause internal references to dprintf to be changed to
# __wrap_dprintf, which is also provided by condor_utils.  Hence, when
# dynamically loaded, Condor's __wrap_dprintf (identical to Condor's dprintf)
# is used instead of libc's.  Condor's dprintf is still exported, meaning
# linking executables against condor_utils still works.
#
# Voodoo, that's what this is.  Never overload libc functions!
#
if ( LINUX )
  set_target_properties( condor_utils PROPERTIES LINK_FLAGS "-Wl,--wrap=dprintf" )
endif()

if (DLOPEN_GSI_LIBS)
	target_link_libraries(condor_utils ${RT_FOUND} ${CLASSADS_FOUND} ${PCRE_FOUND} ${SCITOKENS_FOUND} ${OPENSSL_FOUND} ${KRB5_FOUND} ${MUNGE_FOUND} )
else()
	target_link_libraries(condor_utils ${RT_FOUND} ${CLASSADS_FOUND} ${PCRE_FOUND} ${VOMS_FOUND} ${GLOBUS_FOUND} ${SCITOKENS_FOUND} ${OPENSSL_FOUND} ${KRB5_FOUND} ${MUNGE_FOUND} )
endif()
if (LINUX AND LIBUUID_FOUND)
	target_link_libraries(condor_utils ${LIBUUID_FOUND})
endif()

if ( DARWIN )
	target_link_libraries( condor_utils ${IOKIT_FOUND} ${COREFOUNDATION_FOUND} resolv )
	set_target_properties( condor_utils PROPERTIES INSTALL_NAME_DIR ${CMAKE_CURRENT_BINARY_DIR} )
	install( CODE "execute_process(COMMAND ${CMAKE_SOURCE_DIR}/src/condor_scripts/macosx_rewrite_libs \$ENV{DESTDIR}/${CMAKE_INSTALL_PREFIX}/${C_LIB}/lib${UTILS_LIB_NAME}.dylib)" )
endif()
add_dependencies(condor_utils utils_genparams )

##################################################
# condorapi & tests

condor_selective_glob("ToE.cpp;my_username.*;condor_event.*;misc_utils.*;user_log_header.*;write_user_log*;CondorError*;get_last_error_string.*;read_user_log*;iso_dates.*;file_lock.*;format_time.*;utc_time.*;stat_wrapper*;log_rotate.*;dprintf.cpp;dprintf_c*;dprintf_setup.cpp;sig_install.*;basename.*;except.*;strupr.*;lock_file.*;rotate_file.*;strcasestr.*;strnewp.*;condor_environ.*;passwd_cache.*;uids.c*;chomp.*;subsystem_info.*;distribution.*;my_distribution.*;get_random_num.*;libcondorapi_stubs.*;condor_open.*;classad_merge.*;condor_attributes.*;simple_arg.*;compat_classad.*;compat_classad_util.*;condor_snutils.*;stringSpace.*;string_list.*;stl_string_utils.*;MyString.*;directory*;filename_tools_cpp.*;filename_tools.*;stat_info.*;consumption_policy.*;env.*;condor_arglist.*;setenv.*;condor_ver_info.*;HashTable.*;condor_version.*;${SAFE_OPEN_SRC}" ApiSrcs)
if(WINDOWS)
    condor_selective_glob("directory.WINDOWS.*;directory_util.*;dynuser.WINDOWS.*;lock_file.WINDOWS.*;lsa_mgr.*;my_dynuser.*;ntsysinfo.WINDOWS.*;posix.WINDOWS.*;stat.WINDOWS.*;token_cache.WINDOWS.*;truncate.WINDOWS.*" ApiSrcs)
    set_property( TARGET utils_genparams PROPERTY FOLDER "libraries" )
else()
    condor_selective_glob("dprintf_syslog*" ApiSrcs)
endif()

if(LINUX)
    condor_selective_glob("../condor_sysapi/kernel_version.*;../condor_sysapi/sysapi.*;../condor_sysapi/reconfig.*" ApiSrcs)
endif()

condor_static_lib( condorapi "${ApiSrcs}" )
add_dependencies( condorapi condor_utils )

if (HAVE_OLD_SCANDIR)
	add_definitions(-DHAVE_OLD_SCANDIR)
endif()

if (DOCKER_ALLOW_RUN_AS_ROOT)
	set_source_files_properties(docker-api.cpp PROPERTIES COMPILE_DEFINITIONS DOCKER_ALLOW_RUN_AS_ROOT=1)
endif()


target_link_libraries(condorapi ${CLASSADS_FOUND};${CMAKE_DL_LIBS};${RT_FOUND})
if (LINUX AND LIBUUID_FOUND)
	target_link_libraries(condorapi ${LIBUUID_FOUND})
endif()

if (LINUX OR DARWIN)
	condor_shared_lib( condorapi_shared "${ApiSrcs}" )
	add_dependencies( condorapi_shared condor_utils )
	target_link_libraries(condorapi_shared ${CLASSADS_FOUND};${CMAKE_DL_LIBS};${RT_FOUND})
	set_target_properties( condorapi_shared PROPERTIES OUTPUT_NAME condorapi )
endif()

if (WANT_FULL_DEPLOYMENT)
	install (FILES MyString.h
			 condor_event.h
			 condor_holdcodes.h
			 read_user_log.h
			 user_log.c++.h
			 user_log.README
			 write_user_log.h
			 compat_classad.h
			 compat_classad_list.h
			 compat_classad_util.h
			 stl_string_utils.h
			DESTINATION ${C_INCLUDE})

    install ( TARGETS condorapi DESTINATION ${C_LIB} )
    if (LINUX OR DARWIN)
        install ( TARGETS condorapi_shared DESTINATION ${C_LIB} )
    endif()
endif(WANT_FULL_DEPLOYMENT)

set_source_files_properties(test_log_reader.cpp PROPERTIES DEFINITIONS ENABLE_STATE_DUMP)

condor_exe_test(test_log_reader "test_log_reader.cpp" "${CONDOR_TOOL_LIBS}")
condor_exe_test(test_log_reader_state "test_log_reader_state.cpp" "${CONDOR_TOOL_LIBS}")
condor_exe_test(test_log_writer "test_log_writer.cpp" "${CONDOR_TOOL_LIBS}")
condor_exe_test(test_libcondorapi "test_libcondorapi.cpp" "condorapi")

condor_exe_test(test_sinful "test_sinful.cpp" "${CONDOR_TOOL_LIBS}" )
condor_exe_test(test_macro_expand "test_macro_expand.cpp" "${CONDOR_TOOL_LIBS}" )
