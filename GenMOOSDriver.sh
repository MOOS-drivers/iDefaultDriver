#!/bin/bash

if [ -d src ]; then
    echo "src folder to already exist... quitting to avoid damaging previous work."
    exit 1
fi

if [ -z "$1" ] ; then
    echo "GenMOOSDriver: usage: $0 [app-name] [your-name]"
    exit 0
fi

#if [ -z "$2" ] ; then
#    $2="YOUR-NAME-HERE"
#fi

DATE=`date +%Y/%m/%d`
# echo ${DATE}

#exit 0

cat > CMakeLists.txt <<EOF
#===========================================================================
# FILE:  i${1}/CMakeLists.txt
# DATE:  ${DATE}
# INFO:  Top-level CMakeLists.txt file for the i${1} project
# NAME:  ${2}
#===========================================================================

CMAKE_MINIMUM_REQUIRED(VERSION 2.8)
PROJECT( i${1} )

#=============================================================================
# Set the output directories for the binary and library files
#=============================================================================

GET_FILENAME_COMPONENT(i${1}_BIN_DIR "\${CMAKE_SOURCE_DIR}/bin"  ABSOLUTE )
GET_FILENAME_COMPONENT(i${1}_LIB_DIR "\${CMAKE_SOURCE_DIR}/lib"  ABSOLUTE )

SET( LIBRARY_OUTPUT_PATH      "\${i${1}_LIB_DIR}" CACHE PATH "" )
SET( ARCHIVE_OUTPUT_DIRECTORY "\${i${1}_LIB_DIR}" CACHE PATH "" )
SET( LIBRARY_OUTPUT_DIRECTORY "\${i${1}_LIB_DIR}" CACHE PATH "" )

SET( EXECUTABLE_OUTPUT_PATH    "\${i${1}_BIN_DIR}" CACHE PATH "" )
SET( RUNTIME_OUTPUT_DIRECTORY "\${i${1}_BIN_DIR}"  CACHE PATH "" )

#=============================================================================
# Find MOOS
#=============================================================================
find_package(MOOS 10.0)

if(NOT DEFINED MOOS_LIBRARIES)
  message("Defining MOOS_LIBRARIES")
  set(MOOS_LIBRARIES MOOS)
endif()

INCLUDE_DIRECTORIES(\${MOOS_INCLUDE_DIRS})

message("+++++++++++++++++++++++++++++++++++++++++")
message("MOOS_INCLUDE_DIRS:" \${MOOS_INCLUDE_DIRS})
message("MOOS_LIBRARIES:   " \${MOOS_LIBRARIES})
message("+++++++++++++++++++++++++++++++++++++++++")

#=============================================================================
# Find the "moos-ivp" base directory
#=============================================================================

# Search for the moos-ivp folder
find_path( MOOSIVP_SOURCE_TREE_BASE
           NAMES build-ivp.sh build-moos.sh configure-ivp.sh
           PATHS "../moos-ivp" "../../moos-ivp" "../../moos-ivp/trunk/" "../moos-ivp/trunk/"
           DOC "Base directory of the MOOS-IvP source tree"
           NO_DEFAULT_PATH
)

if (NOT MOOSIVP_SOURCE_TREE_BASE)
    message("Please set MOOSIVP_SOURCE_TREE_BASE to  ")
    message("the location of the \"moos-ivp\" folder ")
    return()
endif()

#=============================================================================
# Specify where to find IvP's headers and libraries...
#=============================================================================

FILE(GLOB IVP_INCLUDE_DIRS \${MOOSIVP_SOURCE_TREE_BASE}/ivp/src/lib_* )
INCLUDE_DIRECTORIES(\${IVP_INCLUDE_DIRS})

FILE(GLOB IVP_LIBRARY_DIRS \${MOOSIVP_SOURCE_TREE_BASE}/lib )
LINK_DIRECTORIES(\${IVP_LIBRARY_DIRS})

message("+++++++++++++++++++++++++++++++++++++++++")
message("MOOS_IVP_INCLUDE_DIRS:" \${IVP_INCLUDE_DIRS})
message("MOOS_IVP_LIBRARIES:   " \${IVP_LIBRARY_DIRS})
message("+++++++++++++++++++++++++++++++++++++++++")

#=============================================================================
# Specify Compiler Flags
#=============================================================================
IF( \${WIN32} )
   #---------------------------------------------
   # Windows Compiler Flags
   #---------------------------------------------
   IF(MSVC)
      # Flags for Microsoft Visual Studio
      SET( WALL_ON OFF CACHE BOOL 
         "tell me about all compiler warnings (-Wall) ")
      IF(WALL_ON)
         SET(CMAKE_CXX_FLAGS "\${CMAKE_CXX_FLAGS} -Wall")
      ENDIF(WALL_ON)
   ELSE(MSVC)
      # Other Windows compilers go here
   ENDIF(MSVC)

ELSE( \${WIN32} )
   #---------------------------------------------
   # Linux and Apple Compiler Flags
   #---------------------------------------------
   # Force -fPIC because gcc complains when we don't use it with x86_64 code.
   # Note sure why: -fPIC should only be needed for shared objects, and
   # AFAIK, CMake gets that right when building shared objects. -CJC
   SET(CMAKE_CXX_FLAGS "\${CMAKE_CXX_FLAGS} -fPIC -g")
   IF(CMAKE_COMPILER_IS_GNUCXX)
      # Flags for the GNU C++ Compiler
      SET( WALL_ON OFF CACHE BOOL 
         "tell me about all compiler warnings (-Wall) ")
      IF(WALL_ON)
         SET(CMAKE_CXX_FLAGS "\${CMAKE_CXX_FLAGS} -Wall")
      ENDIF( WALL_ON)
   ELSE(CMAKE_COMPILER_IS_GNUCXX)
    
   ENDIF(CMAKE_COMPILER_IS_GNUCXX)

ENDIF( \${WIN32} )


#===============================================================================
# FINDING MOOSGeodesy' HEADERS AND LIBRARIES...
#===============================================================================

# moos - http://www.robots.ox.ac.uk/~mobile/MOOS/wiki/pmwiki.php
find_package(MOOSGeodesy)
include_directories(\${MOOSGeodesy_INCLUDE_DIRS})
link_directories(\${MOOSGeodesy_LIBRARY_PATH})

message("+++++++++++++++++++++++++++++++++++++++++")
message("MOOSGeodesy_INCLUDE_DIRS:" \${MOOSGeodesy_INCLUDE_DIRS})
message("MOOSGeodesy_LIB_PATH:" \${MOOSGeodesy_LIBRARY_PATH})
message("+++++++++++++++++++++++++++++++++++++++++")


#=============================================================================
# Add Subdirectories
#=============================================================================
ADD_SUBDIRECTORY( src )

EOF

mkdir -p scripts
cd scripts

cat > clean_test_i${1}.sh <<EOF
#!/bin/bash -e

VERBOSE=""
HELP="no"

## Check command-line arguments
for ARGI; do
    UNDEFINED_ARG=\$ARGI
    if [ "\${ARGI}" = "--verbose" -o "\${ARGI}" = "-v" ] ; then
        VERBOSE="-v"
        UNDEFINED_ARG=""
    fi
    if [ "\${ARGI}" = "--help" -o "\${ARGI}" = "-h" ] ; then
        HELP="yes"
        UNDEFINED_ARG=""
    fi
    if [ "\${UNDEFINED_ARG}" != "" ] ; then
        BAD_ARGS=\$UNDEFINED_ARG
    fi
done

if [ "\${BAD_ARGS}" != "" ] ; then
    printf "Bad Argument: %s \n" \$BAD_ARGS
    exit 0
fi

if [ "\${HELP}" = "yes" ]; then
    printf "%s [SWITCHES]                       \n" \$0
    printf "Switches:                           \n" 
    printf "  --verbose                         \n" 
    printf "  --help, -h                        \n" 
    exit 0;
fi

## Clean the directory
rm -rf  \$VERBOSE   LOG_*
rm -f   \$VERBOSE   *~
rm -f   \$VERBOSE   targ_*
rm -f   \$VERBOSE   .LastOpenedMOOSLogDirectory

EOF
chmod a+x clean_test_i${1}.sh

cat > launch_test_i${1}.sh <<EOF
#!/bin/bash -e

JUST_MAKE="no"

## Check command-line arguments
for ARGI; do
    if [ "\${ARGI}" = "--help" -o "\${ARGI}" = "-h" ] ; then
        printf "%s [SWITCHES] [time_warp]   \n" \$0
        printf "  --just_make, -j    \n" 
        printf "  --help, -h         \n" 
        exit 0;
    elif [ "\${ARGI}" = "--just_build" -o "\${ARGI}" = "-j" ] ; then
        JUST_MAKE="yes"
    else 
        printf "Bad Argument: %s \n" \$ARGI
        exit 0
    fi
done

## Build test file
nsplug meta_test.moos targ_test.moos -f

if [ \${JUST_MAKE} = "yes" ] ; then
    exit 0
fi

## Launch the test
export PATH=\$PATH:\$PWD/../bin
pAntler targ_test.moos >& /dev/null &

uXMS targ_test.moos

printf "Killing all processes ... \n"
kill %1 
printf "Done killing processes.   \n"

EOF
chmod a+x launch_test_i${1}.sh

cat > meta_test.moos <<EOF
ServerHost = localhost
ServerPort = 9000
Community = i${1}_Test

MOOSTimeWarp = 1

ProcessConfig = ANTLER
{
  MSBetweenLaunches = 500
  Run = MOOSDB           @ NewConsole = true 
  Run = i${1}             @ NewConsole = false
}

ProcessConfig = uXMS
{
  AppTick       = 10
  CommsTick     = 10

  source = i${1}
}

#include ../src/i${1}.moos

EOF

cd ..

mkdir -p src
cd src

cat > CMakeLists.txt <<EOF
#===========================================================================
# FILE:  i$1/src/CMakeLists.txt
# DATE:  $DATE
# INFO:  Source-level CMakeLists.txt file for the $1 driver project 
# NAME:  $2
#===========================================================================

FILE(GLOB LOCAL_LIBRARY_DIRS ./lib_*)
INCLUDE_DIRECTORIES(\${LOCAL_LIBRARY_DIRS})

SET(SRC 
  ${1}.cpp
  ${1}_Info.cpp
  main.cpp
)

ADD_EXECUTABLE(i$1 \${SRC})

TARGET_LINK_LIBRARIES(i$1
  \${MOOS_LIBRARIES}
  # \${MOOSGeodesy_LIBRARIES}
  mbutil
  apputil
  m
  pthread
)

EOF

cat > ${1}.h <<EOF
/************************************************************/
/*    NAME: $2                                              */
/*    ORGN: MOOS-Drivers                                    */
/*    FILE: ${1}.h                                          */
/*    DATE: $DATE                                      */
/************************************************************/

#ifndef ${1}_HEADER
#define ${1}_HEADER

#include "MOOS/libMOOS/Thirdparty/AppCasting/AppCastingMOOSInstrument.h"

class ${1} : public AppCastingMOOSInstrument
{
 public:
   ${1}();
   ~${1}() {};

 protected: // Standard MOOSApp functions to overload  
   bool OnNewMail(MOOSMSG_LIST &NewMail);
   bool Iterate();
   bool OnConnectToServer();
   bool OnStartUp();

 protected: // Standard AppCastingMOOSInstrument function to overload 
   bool buildReport();

 protected:
   void registerVariables();

 private: // Configuration variables

 private: // State variables
};

#endif 
EOF

cat > main.cpp <<EOF
/************************************************************/
/*    NAME: $2                                              */
/*    ORGN: MOOS-Drivers                                    */
/*    FILE: main.cpp                                        */
/*    DATE: $DATE                                      */
/************************************************************/

#include <string>
#include "MBUtils.h"
#include "ColorParse.h"
#include "${1}.h"
#include "${1}_Info.h"

using namespace std;

int main(int argc, char *argv[])
{
  string mission_file;
  string run_command = argv[0];

  for(int i=1; i<argc; i++) {
    string argi = argv[i];
    if((argi=="-v") || (argi=="--version") || (argi=="-version"))
      showReleaseInfoAndExit();
    else if((argi=="-e") || (argi=="--example") || (argi=="-example"))
      showExampleConfigAndExit();
    else if((argi == "-h") || (argi == "--help") || (argi=="-help"))
      showHelpAndExit();
    else if((argi == "-i") || (argi == "--interface"))
      showInterfaceAndExit();
    else if(strEnds(argi, ".moos") || strEnds(argi, ".moos++"))
      mission_file = argv[i];
    else if(strBegins(argi, "--alias="))
      run_command = argi.substr(8);
    else if(i==2)
      run_command = argi;
  }
  
  if(mission_file == "")
    showHelpAndExit();

  cout << termColor("green");
  cout << "i${1} launching as " << run_command << endl;
  cout << termColor() << endl;

  ${1} ${1};

  ${1}.Run(run_command.c_str(), mission_file.c_str());
  
  return(0);
}

EOF

cat > i${1}.moos <<EOF
//------------------------------------------------
// i${1} config block

ProcessConfig = i${1}
{
   AppTick   = 4
   CommsTick = 4
   
   // i${1} configuration here
}

EOF

cat > ${1}.cpp <<EOF
/************************************************************/
/*    NAME: $2                                              */
/*    ORGN: MOOS-Drivers                                    */
/*    FILE: ${1}.cpp                                        */
/*    DATE: $DATE                                      */
/************************************************************/

#include <iterator>
#include "MBUtils.h"
#include "ACTable.h"
#include "${1}.h"

using namespace std;

//---------------------------------------------------------
// Constructor

${1}::${1}()
{
}

//---------------------------------------------------------
// Procedure: OnNewMail

bool ${1}::OnNewMail(MOOSMSG_LIST &NewMail)
{
  AppCastingMOOSInstrument::OnNewMail(NewMail);

  MOOSMSG_LIST::iterator p;
  for(p=NewMail.begin(); p!=NewMail.end(); p++) {
    CMOOSMsg &msg = *p;
    string key    = msg.GetKey();

#if 0 // Keep these around just for template
    string comm  = msg.GetCommunity();
    double dval  = msg.GetDouble();
    string sval  = msg.GetString(); 
    string msrc  = msg.GetSource();
    double mtime = msg.GetTime();
    bool   mdbl  = msg.IsDouble();
    bool   mstr  = msg.IsString();
#endif

     if(key == "FOO") 
       cout << "great!";

     else if(key != "APPCAST_REQ") // handle by AppCastingMOOSInstrument
       reportRunWarning("Unhandled Mail: " + key);
   }
	
   return(true);
}

//---------------------------------------------------------
// Procedure: OnConnectToServer

bool ${1}::OnConnectToServer()
{
   registerVariables();
   return(true);
}

//---------------------------------------------------------
// Procedure: Iterate()
//            happens AppTick times per second

bool ${1}::Iterate()
{
  AppCastingMOOSInstrument::Iterate();
  // Do your thing here!
  AppCastingMOOSInstrument::PostReport();
  return(true);
}

//---------------------------------------------------------
// Procedure: OnStartUp()
//            happens before connection is open

bool ${1}::OnStartUp()
{
  AppCastingMOOSInstrument::OnStartUp();

  STRING_LIST sParams;
  m_MissionReader.EnableVerbatimQuoting(false);
  if(!m_MissionReader.GetConfiguration(GetAppName(), sParams))
    reportConfigWarning("No config block found for " + GetAppName());

  STRING_LIST::iterator p;
  for(p=sParams.begin(); p!=sParams.end(); p++) {
    string orig  = *p;
    string line  = *p;
    string param = toupper(biteStringX(line, '='));
    string value = line;

    bool handled = false;
    if(param == "FOO") {
      handled = true;
    }
    else if(param == "BAR") {
      handled = true;
    }

    if(!handled)
      reportUnhandledConfigWarning(orig);

  }
  
  registerVariables();	
  return(true);
}

//---------------------------------------------------------
// Procedure: registerVariables

void ${1}::registerVariables()
{
  AppCastingMOOSInstrument::RegisterVariables();
  // Register("FOOBAR", 0);
}


//------------------------------------------------------------
// Procedure: buildReport()

bool ${1}::buildReport() 
{
  m_msgs << "============================================ \n";
  m_msgs << "File:                                        \n";
  m_msgs << "============================================ \n";

  ACTable actab(4);
  actab << "Alpha | Bravo | Charlie | Delta";
  actab.addHeaderLines();
  actab << "one" << "two" << "three" << "four";
  m_msgs << actab.getFormattedString();

  return(true);
}




EOF


cat >> ${1}_Info.h <<EOF
/****************************************************************/
/*   NAME: ${2}                                                 */
/*   ORGN: MOOS-Drivers                                     */
/*   FILE: ${1}_Info.h                                      */
/*   DATE: $DATE                                        */
/****************************************************************/

#ifndef ${1}_INFO_HEADER
#define ${1}_INFO_HEADER

void showSynopsis();
void showHelpAndExit();
void showExampleConfigAndExit();
void showInterfaceAndExit();
void showReleaseInfoAndExit();

#endif

EOF


cat >> ${1}_Info.cpp <<EOF
/****************************************************************/
/*   NAME: ${2}                                             */
/*   ORGN: MOOS-Drivers                                     */
/*   FILE: ${1}_Info.cpp                               */
/*   DATE: $DATE                                        */
/****************************************************************/

#include <cstdlib>
#include <iostream>
#include "${1}_Info.h"
#include "ColorParse.h"
#include "ReleaseInfo.h"

using namespace std;

//----------------------------------------------------------------
// Procedure: showSynopsis

void showSynopsis()
{
  blk("SYNOPSIS:                                                       ");
  blk("------------------------------------                            ");
  blk("  The i${1} application is used for               ");
  blk("                                                                ");
  blk("                                                                ");
  blk("                                                                ");
  blk("                                                                ");
}

//----------------------------------------------------------------
// Procedure: showHelpAndExit

void showHelpAndExit()
{
  blk("                                                                ");
  blu("=============================================================== ");
  blu("Usage: i${1} file.moos [OPTIONS]                   ");
  blu("=============================================================== ");
  blk("                                                                ");
  showSynopsis();
  blk("                                                                ");
  blk("Options:                                                        ");
  mag("  --alias","=<ProcessName>                                      ");
  blk("      Launch i${1} with the given process name         ");
  blk("      rather than i${1}.                           ");
  mag("  --example, -e                                                 ");
  blk("      Display example MOOS configuration block.                 ");
  mag("  --help, -h                                                    ");
  blk("      Display this help message.                                ");
  mag("  --interface, -i                                               ");
  blk("      Display MOOS publications and subscriptions.              ");
  mag("  --version,-v                                                  ");
  blk("      Display the release version of i${1}.        ");
  blk("                                                                ");
  blk("Note: If argv[2] does not otherwise match a known option,       ");
  blk("      then it will be interpreted as a run alias. This is       ");
  blk("      to support pAntler launching conventions.                 ");
  blk("                                                                ");
  exit(0);
}

//----------------------------------------------------------------
// Procedure: showExampleConfigAndExit

void showExampleConfigAndExit()
{
  blk("                                                                ");
  blu("=============================================================== ");
  blu("i${1} Example MOOS Configuration                   ");
  blu("=============================================================== ");
  blk("                                                                ");
  blk("ProcessConfig = i${1}                              ");
  blk("{                                                               ");
  blk("  AppTick   = 4                                                 ");
  blk("  CommsTick = 4                                                 ");
  blk("                                                                ");
  blk("}                                                               ");
  blk("                                                                ");
  exit(0);
}


//----------------------------------------------------------------
// Procedure: showInterfaceAndExit

void showInterfaceAndExit()
{
  blk("                                                                ");
  blu("=============================================================== ");
  blu("i${1} INTERFACE                                    ");
  blu("=============================================================== ");
  blk("                                                                ");
  showSynopsis();
  blk("                                                                ");
  blk("SUBSCRIPTIONS:                                                  ");
  blk("------------------------------------                            ");
  blk("  NODE_MESSAGE = src_node=alpha,dest_node=bravo,var_name=FOO,   ");
  blk("                 string_val=BAR                                 ");
  blk("                                                                ");
  blk("PUBLICATIONS:                                                   ");
  blk("------------------------------------                            ");
  blk("  Publications are determined by the node message content.      ");
  blk("                                                                ");
  exit(0);
}

//----------------------------------------------------------------
// Procedure: showReleaseInfoAndExit

void showReleaseInfoAndExit()
{
  showReleaseInfo("i${1}", "mit");
  exit(0);
}

EOF


echo "i${1} generated"
