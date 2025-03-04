#!/bin/bash
# Description   : Script for syncing external repositorities for Oralce Linux / Debian / Proxmox / GIT / other locally
# Author        : Manegold, Martin

function f_quit() {
    if [ "${TMP_LOCK_RESULT}x" == "${TMP_TRUE}x" ] ; then
        ${CMD_RM} --recursive --force "${TMP_LOCK_PATH}" 2> /dev/null
        ${CMD_RM} --recursive --force "/tmp/RPM-GPG-KEY-oracle-ol"* 2> /dev/null
        ${CMD_RM} --recursive --force "/tmp/localsync_ol"* 2> /dev/null
        ${CMD_RM} --recursive --force "${TMP_HOME}/.config/ftpsync/ftpsync.conf" 2> /dev/null
        if [ "${TMP_EXIT}x" == "${TMP_TRUE}x" ] ; then
            ${CMD_RM} --recursive --force "/tmp/repositorysync.wget" 2> /dev/null
        fi
    fi
    exit ${TMP_EXIT}
}

function f_output() {
    # setting output colours and characters 
    TMP_OUTPUT_COLOR_RED="\033[31m" 
    TMP_OUTPUT_COLOR_GREEN="\033[32m" 
    TMP_OUTPUT_COLOR_YELLOW="\033[33m" 
    TMP_OUTPUT_COLOR_RESET="\033[0m" 
    TMP_OUTPUT_CHECK="✓" 
    TMP_OUTPUT_CROSS="✗" 
    TMP_OUTPUT_INFO="o" 
    
    # get current timestamp
    TMP_TIME=$( ${CMD_DATE} +"%d%m%Y_%H%M%S" 2>/dev/null )
    
    # reset exit code
    TMP_EXIT=${TMP_TRUE}
    
    case $1 in
		"error")
            ${CMD_ECHO} -e "${TMP_OUTPUT_COLOR_RED}[${TMP_OUTPUT_CROSS}] [${TMP_TIME}] [${2}]${TMP_OUTPUT_COLOR_RESET}"
            if [ -f "${REPO_DOWNLOAD_BASEPATH}/logs/${TMP_LOG_NAME}" ] ; then
                ${CMD_ECHO} -e "[${TMP_OUTPUT_CROSS}] [${TMP_TIME}] [${2}]" >> "${REPO_DOWNLOAD_BASEPATH}/logs/${TMP_LOG_NAME}"
            fi
            TMP_EXIT=${TMP_FALSE}
            f_quit
            ;;
        "warning")
            ${CMD_ECHO} -e "${TMP_OUTPUT_COLOR_YELLOW}[${TMP_OUTPUT_INFO}] [${TMP_TIME}] [${2}]${TMP_OUTPUT_COLOR_RESET}"
            if [ -f "${REPO_DOWNLOAD_BASEPATH}/logs/${TMP_LOG_NAME}" ] ; then
                ${CMD_ECHO} -e "[${TMP_OUTPUT_INFO}] [${TMP_TIME}] [${2}]" >> "${REPO_DOWNLOAD_BASEPATH}/logs/${TMP_LOG_NAME}"
            fi
            TMP_EXIT=${TMP_TRUE}
            ;;
        "info")
            ${CMD_ECHO} -e "${TMP_OUTPUT_COLOR_GREEN}[${TMP_OUTPUT_CHECK}] [${TMP_TIME}] [${2}]${TMP_OUTPUT_COLOR_RESET}"
            if [ -f "${REPO_DOWNLOAD_BASEPATH}/logs/${TMP_LOG_NAME}" ] ; then
                ${CMD_ECHO} -e "[${TMP_OUTPUT_CHECK}] [${TMP_TIME}] [${2}]" >> "${REPO_DOWNLOAD_BASEPATH}/logs/${TMP_LOG_NAME}"
            fi
            TMP_EXIT=${TMP_TRUE}
            ;;
        "*")
            ${CMD_ECHO} -e "${TMP_OUTPUT_COLOR_RED}[${TMP_OUTPUT_CROSS}] [${TMP_TIME}] [Could not identify valid output parameter. It must be either 'error' / 'warning' or 'info' but is '${1}'.]${TMP_OUTPUT_COLOR_RESET}"
            if [ -f "${REPO_DOWNLOAD_BASEPATH}/logs/${TMP_LOG_NAME}" ] ; then
                ${CMD_ECHO} -e "[${TMP_OUTPUT_CROSS}] [${TMP_TIME}] [Could not identify valid output parameter. It must be either 'error' / 'warning' or 'info' but is '${1}'.]" >> "${REPO_DOWNLOAD_BASEPATH}/logs/${TMP_LOG_NAME}"
            fi
            TMP_EXIT=${TMP_FALSE}
            f_quit
    esac
}

function f_init() {
    # set script execution path
	SCRIPT_NAME=$( /usr/bin/realpath "$0" )
	SCRIPT_PATH=$( /usr/bin/dirname "$SCRIPT_NAME" )
	SCRIPT_PID=$$

    # setting system dependant return values 
    /bin/true 
    TMP_TRUE=$? 
    /bin/false 
    TMP_FALSE=$? 
    
    # set exit code
    TMP_EXIT=${TMP_TRUE}
    
    # set global log file name / lockign path / configuration name 
    TMP_LOG_NAME="repositorysync.log"
    TMP_LOCK_PATH="/tmp/.repositorysync.lck"
    TMP_CONF_NAME="repositorysync.conf"
    
    # setting command binaries 
    CMD_ECHO="/bin/echo" 
    CMD_AWK="/usr/bin/awk" 
    CMD_WHEREIS="/usr/bin/whereis"
    CMD_DATE=$( ${CMD_WHEREIS} date | ${CMD_AWK} '{ print $2 }' )
    CMD_DATE=${CMD_DATE:-/usr/bin/date}
    
    CMD_CLEAR=$( ${CMD_WHEREIS} clear | ${CMD_AWK} '{ print $2 }' )
    CMD_CLEAR=${CMD_CLEAR:-/usr/bin/clear}
    CMD_CP=$( ${CMD_WHEREIS} cp | ${CMD_AWK} '{ print $2 }' )
    CMD_CP=${CMD_CP:-/usr/bin/cp}
    CMD_GPG=$( ${CMD_WHEREIS} gpg | ${CMD_AWK} '{ print $2 }' )
    CMD_GPG=${CMD_GPG:-/usr/bin/gpg}
    CMD_GREP=$( ${CMD_WHEREIS} grep | ${CMD_AWK} '{ print $2 }' )
    CMD_GREP=${CMD_GREP:-/usr/bin/grep}
    CMD_LN=$( ${CMD_WHEREIS} ln | ${CMD_AWK} '{ print $2 }' )
    CMD_LN=${CMD_MKDIR:-/usr/bin/ln}
    CMD_MKDIR=$( ${CMD_WHEREIS} mkdir | ${CMD_AWK} '{ print $2 }' )
    CMD_MKDIR=${CMD_MKDIR:-/usr/bin/mkdir}
    CMD_RM=$( ${CMD_WHEREIS} rm | ${CMD_AWK} '{ print $2 }' )
    CMD_RM=${CMD_RM:-/usr/bin/rm}
    CMD_SED=$( ${CMD_WHEREIS} sed | ${CMD_AWK} '{ print $2 }' )
    CMD_SED=${CMD_SED:-/usr/bin/sed}
    CMD_WGET=$( ${CMD_WHEREIS} wget | ${CMD_AWK} '{ print $2 }' )
    CMD_WGET=${CMD_WGET:-/usr/bin/wget}
    
    for TMP in "${CMD_ECHO}" "${CMD_AWK}" "${CMD_WHEREIS}" "${CMD_DATE}" "${CMD_CLEAR}" "${CMD_CP}" "${CMD_GPG}" "${CMD_GREP}" "${CMD_LN}" "${CMD_MKDIR}" "${CMD_RM}" "${CMD_SED}" "${CMD_WGET}" ; do
        if [ "${TMP}x" == "x" ] || [ ! -f "${TMP}" ] ; then
            TMP_NAME=(${!TMP@})
            f_output "error" "The bash variable '${TMP_NAME}' with value '${TMP}' does not reference to a valid command binary path or is empty."
        fi 
    done 
    
    f_output "info" "Starting script execution and verified the existence of the needed command binaries."
    
    # return if only help or version called
    if [[ "${TMP_OPTION}" =~ ^(help|--help|-h|version|--version|-v)$ ]] ; then
        return
    fi
    
    # handle config
    if [ -f "${SCRIPT_PATH}/${TMP_CONF_NAME}" ] || [ -r "${SCRIPT_PATH}/${TMP_CONF_NAME}" ] ; then
        source "${SCRIPT_PATH}/${TMP_CONF_NAME}"
    else
        f_output "error" "The default configuration file '${SCRIPT_PATH}/${TMP_CONF_NAME}' could not be found or is not readable by the current user."
    fi
    
    # set base path
    if [ "${REPO_DOWNLOAD_BASEPATH}x" == "x" ] || [ ! -r "${REPO_DOWNLOAD_BASEPATH}" ]  ; then
        f_output "error" "The base path variable 'REPO_DOWNLOAD_BASEPATH' is empty or not a valid readable path of the current user. Please set it correctly in the configuration file '${SCRIPT_PATH}/${TMP_CONF_NAME}'."
    fi
    
    if [ ! -r "${REPO_DOWNLOAD_BASEPATH}" ] ; then
        f_output "error" "The defined base path '${REPO_DOWNLOAD_BASEPATH}' is not readable for the current user '${USER}' or does not exist."
    fi
    
    f_output "info" "The base path variable ist set to '${REPO_DOWNLOAD_BASEPATH}'."
    
    # handle locking to prevent multiple execution
    if [ -d "${TMP_LOCK_PATH}" ] ; then
        f_output "error" "There is already an instance running because the lock folder '${TMP_LOCK_PATH}' exists. Stopping execution."
        TMP_EXIT=${TMP_FALSE}
        exit ${TMP_FALSE}
    fi
    
    ${CMD_MKDIR} "${TMP_LOCK_PATH}" > /dev/null 2>&1
    TMP_LOCK_RESULT=$( ${CMD_ECHO} $? )
    if [ $? -eq ${TMP_TRUE} ] ; then
        f_output "info" "The lock directory '${TMP_LOCK_PATH}' was successfully created to prevent multiple script execution."
    else
        f_output "error" "The lock directory '${TMP_LOCK_PATH}' could not be created."
    fi
	
	# handle logging
	if [ ! -d "${REPO_DOWNLOAD_BASEPATH}/logs" ] ; then
        ${CMD_MKDIR} "${REPO_DOWNLOAD_BASEPATH}/logs" > /dev/null 2>&1
        if [ $? -eq ${TMP_TRUE} ] ; then
            f_output "info" "The log directory '${REPO_DOWNLOAD_BASEPATH}/logs' was successfully created to write log files to."
        else
            f_output "error" "The log directory '${REPO_DOWNLOAD_BASEPATH}/logs' could not be created."
        fi
	fi
	
	if [ -w "${REPO_DOWNLOAD_BASEPATH}/logs" ] ; then
        ${CMD_ECHO} "" > "${REPO_DOWNLOAD_BASEPATH}/logs/${TMP_LOG_NAME}"
    else
        f_output "error" "The log directory '${REPO_DOWNLOAD_BASEPATH}/logs' is not writable."
    fi
    
    f_output "info" "Starting logging at '${REPO_DOWNLOAD_BASEPATH}/logs/${TMP_LOG_NAME}'."
    
    # set architecture inclusion
    if [ "${REPO_DOWNLOAD_ARCH_INCLUDE}x" != "x" ] ; then
        REPO_DOWNLOAD_DEBIAN_ARCH_INCLUDE=""
        REPO_DOWNLOAD_ORACLE_ARCH_INCLUDE=""
        REPO_DOWNLOAD_ORACLE_SOURCE_EXCLUDE=1
        TMP_IFS=${IFS}
        IFS='|'
        for TMP in ${REPO_DOWNLOAD_ARCH_INCLUDE} ; do
            case "${TMP}" in
                "amd64")
                    if [[ ! "${REPO_DOWNLOAD_DEBIAN_ARCH_INCLUDE}" == *@(${TMP}|${TMP},|,${TMP},|,${TMP})* ]] ; then
                        if [ "${REPO_DOWNLOAD_DEBIAN_ARCH_INCLUDE}x" == "x" ] ; then
                            REPO_DOWNLOAD_DEBIAN_ARCH_INCLUDE="${TMP}"
                        else
                            REPO_DOWNLOAD_DEBIAN_ARCH_INCLUDE="${REPO_DOWNLOAD_DEBIAN_ARCH_INCLUDE} ${TMP}"
                        fi
                    fi
                    if [[ ! "${REPO_DOWNLOAD_ORACLE_ARCH_INCLUDE}" == *@(x86_64|x86_64,|,x86_64,|,x86_64)* ]] ; then
                        if [ "${REPO_DOWNLOAD_ORACLE_ARCH_INCLUDE}x" == "x" ] ; then
                            REPO_DOWNLOAD_ORACLE_ARCH_INCLUDE="x86_64"
                        else
                            REPO_DOWNLOAD_ORACLE_ARCH_INCLUDE="${REPO_DOWNLOAD_ORACLE_ARCH_INCLUDE},x86_64"
                        fi
                    fi
                    ;;
                "i386")
                    if [[ ! "${REPO_DOWNLOAD_DEBIAN_ARCH_INCLUDE}" == *@(${TMP}|${TMP},|,${TMP},|,${TMP})* ]] ; then
                        if [ "${REPO_DOWNLOAD_DEBIAN_ARCH_INCLUDE}x" == "x" ] ; then
                            REPO_DOWNLOAD_DEBIAN_ARCH_INCLUDE="${TMP}"
                        else
                            REPO_DOWNLOAD_DEBIAN_ARCH_INCLUDE="${REPO_DOWNLOAD_DEBIAN_ARCH_INCLUDE} ${TMP}"
                        fi
                    fi
                    if [[ ! "${REPO_DOWNLOAD_ORACLE_ARCH_INCLUDE}" == *@(i686|i686,|,i686,|,i686)* ]] ; then
                        if [ "${REPO_DOWNLOAD_ORACLE_ARCH_INCLUDE}x" == "x" ] ; then
                            REPO_DOWNLOAD_ORACLE_ARCH_INCLUDE="i686"
                        else
                            REPO_DOWNLOAD_ORACLE_ARCH_INCLUDE="${REPO_DOWNLOAD_ORACLE_ARCH_INCLUDE},i686"
                        fi
                    fi
                    ;;
                "armhf")
                    if [[ ! "${REPO_DOWNLOAD_DEBIAN_ARCH_INCLUDE}" == *@(${TMP}|${TMP},|,${TMP},|,${TMP})* ]] ; then
                        if [ "${REPO_DOWNLOAD_DEBIAN_ARCH_INCLUDE}x" == "x" ] ; then
                            REPO_DOWNLOAD_DEBIAN_ARCH_INCLUDE="${TMP}"
                        else
                            REPO_DOWNLOAD_DEBIAN_ARCH_INCLUDE="${REPO_DOWNLOAD_DEBIAN_ARCH_INCLUDE} ${TMP}"
                        fi
                    fi
                    ;;
                "armel")
                    if [[ ! "${REPO_DOWNLOAD_DEBIAN_ARCH_INCLUDE}" == *@(${TMP}|${TMP},|,${TMP},|,${TMP})* ]] ; then
                        if [ "${REPO_DOWNLOAD_DEBIAN_ARCH_INCLUDE}x" == "x" ] ; then
                            REPO_DOWNLOAD_DEBIAN_ARCH_INCLUDE="${TMP}"
                        else
                            REPO_DOWNLOAD_DEBIAN_ARCH_INCLUDE="${REPO_DOWNLOAD_DEBIAN_ARCH_INCLUDE} ${TMP}"
                        fi
                    fi
                    ;;
                "arm64")
                    if [[ ! "${REPO_DOWNLOAD_DEBIAN_ARCH_INCLUDE}" == *@(${TMP}|${TMP},|,${TMP},|,${TMP})* ]] ; then
                        if [ "${REPO_DOWNLOAD_DEBIAN_ARCH_INCLUDE}x" == "x" ] ; then
                            REPO_DOWNLOAD_DEBIAN_ARCH_INCLUDE="${TMP}"
                        else
                            REPO_DOWNLOAD_DEBIAN_ARCH_INCLUDE="${REPO_DOWNLOAD_DEBIAN_ARCH_INCLUDE} ${TMP}"
                        fi
                    fi
                    if [[ ! "${REPO_DOWNLOAD_ORACLE_ARCH_INCLUDE}" == *@(arch64|arch64,|,arch64,|,arch64)* ]] ; then
                        if [ "${REPO_DOWNLOAD_ORACLE_ARCH_INCLUDE}x" == "x" ] ; then
                            REPO_DOWNLOAD_ORACLE_ARCH_INCLUDE="arch64"
                        else
                            REPO_DOWNLOAD_ORACLE_ARCH_INCLUDE="${REPO_DOWNLOAD_ORACLE_ARCH_INCLUDE},arch64"
                        fi
                    fi
                    ;;
                "arc")
                    if [[ ! "${REPO_DOWNLOAD_DEBIAN_ARCH_INCLUDE}" == *@(${TMP}|${TMP},|,${TMP},|,${TMP})* ]] ; then
                        if [ "${REPO_DOWNLOAD_DEBIAN_ARCH_INCLUDE}x" == "x" ] ; then
                            REPO_DOWNLOAD_DEBIAN_ARCH_INCLUDE="${TMP}"
                        else
                            REPO_DOWNLOAD_DEBIAN_ARCH_INCLUDE="${REPO_DOWNLOAD_DEBIAN_ARCH_INCLUDE} ${TMP}"
                        fi
                    fi
                    ;;
                "mips")
                    if [[ ! "${REPO_DOWNLOAD_DEBIAN_ARCH_INCLUDE}" == *@(${TMP}|${TMP},|,${TMP},|,${TMP})* ]] ; then
                        if [ "${REPO_DOWNLOAD_DEBIAN_ARCH_INCLUDE}x" == "x" ] ; then
                            REPO_DOWNLOAD_DEBIAN_ARCH_INCLUDE="${TMP}"
                        else
                            REPO_DOWNLOAD_DEBIAN_ARCH_INCLUDE="${REPO_DOWNLOAD_DEBIAN_ARCH_INCLUDE} ${TMP}"
                        fi
                    fi
                    ;;
                "mipsel")
                    if [[ ! "${REPO_DOWNLOAD_DEBIAN_ARCH_INCLUDE}" == *@(${TMP}|${TMP},|,${TMP},|,${TMP})* ]] ; then
                        if [ "${REPO_DOWNLOAD_DEBIAN_ARCH_INCLUDE}x" == "x" ] ; then
                            REPO_DOWNLOAD_DEBIAN_ARCH_INCLUDE="${TMP}"
                        else
                            REPO_DOWNLOAD_DEBIAN_ARCH_INCLUDE="${REPO_DOWNLOAD_DEBIAN_ARCH_INCLUDE} ${TMP}"
                        fi
                    fi
                    ;;
                "mips64el")
                    if [[ ! "${REPO_DOWNLOAD_DEBIAN_ARCH_INCLUDE}" == *@(${TMP}|${TMP},|,${TMP},|,${TMP})* ]] ; then
                        if [ "${REPO_DOWNLOAD_DEBIAN_ARCH_INCLUDE}x" == "x" ] ; then
                            REPO_DOWNLOAD_DEBIAN_ARCH_INCLUDE="${TMP}"
                        else
                            REPO_DOWNLOAD_DEBIAN_ARCH_INCLUDE="${REPO_DOWNLOAD_DEBIAN_ARCH_INCLUDE} ${TMP}"
                        fi
                    fi
                    ;;
                "ppc64el")
                    if [[ ! "${REPO_DOWNLOAD_DEBIAN_ARCH_INCLUDE}" == *@(${TMP}|${TMP},|,${TMP},|,${TMP})* ]] ; then
                        if [ "${REPO_DOWNLOAD_DEBIAN_ARCH_INCLUDE}x" == "x" ] ; then
                            REPO_DOWNLOAD_DEBIAN_ARCH_INCLUDE="${TMP}"
                        else
                            REPO_DOWNLOAD_DEBIAN_ARCH_INCLUDE="${REPO_DOWNLOAD_DEBIAN_ARCH_INCLUDE} ${TMP}"
                        fi
                    fi
                    ;;
                "s390x")
                    if [[ ! "${REPO_DOWNLOAD_DEBIAN_ARCH_INCLUDE}" == *@(${TMP}|${TMP},|,${TMP},|,${TMP})* ]] ; then
                        if [ "${REPO_DOWNLOAD_DEBIAN_ARCH_INCLUDE}x" == "x" ] ; then
                            REPO_DOWNLOAD_DEBIAN_ARCH_INCLUDE="${TMP}"
                        else
                            REPO_DOWNLOAD_DEBIAN_ARCH_INCLUDE="${REPO_DOWNLOAD_DEBIAN_ARCH_INCLUDE} ${TMP}"
                        fi
                    fi
                    ;;
                "riscv64")
                    if [[ ! "${REPO_DOWNLOAD_DEBIAN_ARCH_INCLUDE}" == *@(${TMP}|${TMP},|,${TMP},|,${TMP})* ]] ; then
                        if [ "${REPO_DOWNLOAD_DEBIAN_ARCH_INCLUDE}x" == "x" ] ; then
                            REPO_DOWNLOAD_DEBIAN_ARCH_INCLUDE="${TMP}"
                        else
                            REPO_DOWNLOAD_DEBIAN_ARCH_INCLUDE="${REPO_DOWNLOAD_DEBIAN_ARCH_INCLUDE} ${TMP}"
                        fi
                    fi
                    ;;
                "source")
                    if [[ ! "${REPO_DOWNLOAD_DEBIAN_ARCH_INCLUDE}" == *@(${TMP}|${TMP},|,${TMP},|,${TMP})* ]] ; then
                        if [ "${REPO_DOWNLOAD_DEBIAN_ARCH_INCLUDE}x" == "x" ] ; then
                            REPO_DOWNLOAD_DEBIAN_ARCH_INCLUDE="${TMP}"
                        else
                            REPO_DOWNLOAD_DEBIAN_ARCH_INCLUDE="${REPO_DOWNLOAD_DEBIAN_ARCH_INCLUDE} ${TMP}"
                        fi
                    fi
                    REPO_DOWNLOAD_ORACLE_SOURCE_EXCLUDE=0
                    ;;
                *)
                    f_output "warning" "The architecture inclusion definition '${TMP}' is not known and will be ignored in the filter list."
                    ;;
            esac
        done
        IFS=${TMP_IFS}
    else
        f_output "info" "No architecture inclusion definition in variable 'REPO_DOWNLOAD_ARCH_INCLUDE' could be identified. The filter will not be set."
    fi
}

function f_download() {
    # Debian repository synchronisation       
    if [ "${REPO_DOWNLOAD_DEBIAN}x" == "1x" ] ; then        
        if [ "${REPO_DOWNLOAD_DEBIAN_REPOSITORIES}x" != "x" ] ; then
            TMP_IFS=${IFS}
            IFS='|'
            for TMP in ${REPO_DOWNLOAD_DEBIAN_REPOSITORIES} ; do  
                TMP_DOWNLOAD_DEBIAN_HOST=$( ${CMD_AWK} -F ':::' '{ print $1 }' <<< "${TMP}" )
                TMP_DOWNLOAD_DEBIAN_MIRROR=$( ${CMD_AWK} -F ':::' '{ print $2 }' <<< "${TMP}" )
                TMP_DOWNLOAD_DEBIAN_PATH=$( ${CMD_AWK} -F ':::' '{ print "debian/"$3 }' <<< "${TMP}" )
                TMP_DOWNLOAD_DEBIAN_NUMBER=$( ${CMD_AWK} -F ':::' '{ print NF }' <<< "${TMP}" )
                
                # check values
                if [ "${TMP_DOWNLOAD_DEBIAN_HOST}x" == "x" ] || [ "${TMP_DOWNLOAD_DEBIAN_HOST}x" == "x" ] || [ "${TMP_DOWNLOAD_DEBIAN_PATH}x" == "x" ] || [ "${TMP_DOWNLOAD_DEBIAN_NUMBER}x" != "3x" ] ; then
                    f_output "warning" "The Debian download repository string needs to consist of 3 entries divided by three colons (<DEBIAN_HOST>:::<DEBIAN_MIRROR_PATH>:::<DEBIAN_NUMBER>). Skipping Debian repository '${TMP}'..."
                    continue
                fi

                ${CMD_WGET} --spider "${TMP_DOWNLOAD_DEBIAN_HOST}/${TMP_DOWNLOAD_DEBIAN_MIRROR}" 2>/dev/null
                if [ $? -ne ${TMP_TRUE} ] ; then
                    f_output "info" "The URI '${TMP_DOWNLOAD_DEBIAN_HOST}/${TMP_DOWNLOAD_DEBIAN_MIRROR}' does not seem to be a valid URI. Skipping Debian repository '${TMP}'..."
                    continue
                fi

                # write repository definition
                TMP_HOME=~
                
                ${CMD_MKDIR} --parents "${TMP_HOME}/.config/ftpsync" > /dev/null 2>&1
                if [ $? -eq ${TMP_TRUE} ] ; then
                    f_output "info" "The ftpsync configuration directory '${TMP_HOME}/.config/ftpsync' was successfully created to write log files to."
                else
                    f_output "warning" "The ftpsync configuration directory '${TMP_HOME}/.config/ftpsync' could not be created. Ignoring Debian repository synchronisation for '${TMP}'..."
                    continue
                fi
                
                if [ -w "${TMP_HOME}/.config/ftpsync" ] ; then
                    ${CMD_ECHO} 'MIRRORNAME="'${TMP_DOWNLOAD_DEBIAN_MIRROR}'"' > "${TMP_HOME}/.config/ftpsync/ftpsync.conf"            
                    ${CMD_ECHO} 'TO="'${REPO_DOWNLOAD_BASEPATH}'/'${TMP_DOWNLOAD_DEBIAN_PATH}'"' >> "${TMP_HOME}/.config/ftpsync/ftpsync.conf"
                    ${CMD_ECHO} 'RSYNC_PATH="'${TMP_DOWNLOAD_DEBIAN_MIRROR}'"' >> "${TMP_HOME}/.config/ftpsync/ftpsync.conf"
                    ${CMD_ECHO} 'RSYNC_HOST="'${TMP_DOWNLOAD_DEBIAN_HOST}'"' >> "${TMP_HOME}/.config/ftpsync/ftpsync.conf"
                    ${CMD_ECHO} 'RSYNC_OPTIONS1="--max-delete=1000000 --delay-updates --delete --delete-after --delete-excluded"' >> "${TMP_HOME}/.config/ftpsync/ftpsync.conf"
                    ${CMD_ECHO} 'LOGDIR="'${REPO_DOWNLOAD_BASEPATH}'/logs"' >> "${TMP_HOME}/.config/ftpsync/ftpsync.conf"
                    if [ "${REPO_DOWNLOAD_DEBIAN_ARCH_INCLUDE}x" != "x" ] ; then
                        ${CMD_ECHO} 'ARCH_INCLUDE="'${REPO_DOWNLOAD_DEBIAN_ARCH_INCLUDE}'"' >> "${TMP_HOME}/.config/ftpsync/ftpsync.conf"
                    fi
                    if [ "${REPO_DOWNLOAD_DEBIAN_EXCLUDE}x" != "x" ] ; then
                        ${CMD_ECHO} 'EXCLUDE="'${REPO_DOWNLOAD_DEBIAN_EXCLUDE}'"' >> "${TMP_HOME}/.config/ftpsync/ftpsync.conf"
                    fi
                else
                    f_output "warning" "Could not identify user config directory '${TMP_HOME}/.config/ftpsync' or is not writable to create Debian synchronisation configuration. Ignoring Debian repository synchronisation for '${TMP}'..."
                    continue
                fi
                
                # create traget directory
                if [ ! -d "${REPO_DOWNLOAD_BASEPATH}/${TMP_DOWNLOAD_DEBIAN_PATH}" ] ; then
                    ${CMD_MKDIR} --parents "${REPO_DOWNLOAD_BASEPATH}/${TMP_DOWNLOAD_DEBIAN_PATH}" > /dev/null 2>&1
                    if [ $? -eq ${TMP_TRUE} ] ; then
                        f_output "info" "The Debian repository directory '${REPO_DOWNLOAD_BASEPATH}/${TMP_DOWNLOAD_DEBIAN_PATH}' was successfully created to write Debian repositories to it."
                    else
                        f_output "warning" "The Debian repository directory '${REPO_DOWNLOAD_BASEPATH}/${TMP_DOWNLOAD_DEBIAN_PATH}' could not be created. Ignoring Debian repository synchronisation for '${TMP}'..."
                        continue
                    fi 
                fi
                
                # start sync
                if [ -w "${REPO_DOWNLOAD_BASEPATH}/${TMP_DOWNLOAD_DEBIAN_PATH}" ] ; then
                    CMD_FTPSYNC=$( ${CMD_WHEREIS} ftpsync | ${CMD_AWK} '{ print $2 }' )
                    CMD_FTPSYNC=${CMD_FTPSYNC:-/usr/bin/ftpsync}
                    if [ "${CMD_FTPSYNC}x" != "x" ] && [ -f "${CMD_FTPSYNC}" ] ; then
                        f_output "info" "The download of the Debian repositories to '${REPO_DOWNLOAD_BASEPATH}/${TMP_DOWNLOAD_DEBIAN_PATH}' with source URI 'http://${TMP_DOWNLOAD_DEBIAN_HOST}/${TMP_DOWNLOAD_DEBIAN_MIRROR}', architecture inclusion filter '${REPO_DOWNLOAD_DEBIAN_ARCH_INCLUDE}' and exclusion filter '${REPO_DOWNLOAD_DEBIAN_EXCLUDE}' is starting."
                    
                        ${CMD_FTPSYNC} sync:all 2>/dev/null
                        if [ $? -eq ${TMP_TRUE} ] ;  then
                            f_output "info" "The download of the Debian repositories to '${REPO_DOWNLOAD_BASEPATH}/${TMP_DOWNLOAD_DEBIAN_PATH}' finished successfully."
                        else
                            f_output "warning" "The download of the Debian repositories from  to '${REPO_DOWNLOAD_BASEPATH}/${TMP_DOWNLOAD_DEBIAN_PATH}' failed."
                        fi
                    else
                        f_output "warning" "The command binary 'ftpsync' with value '${CMD_FTPSYNC}' could not be identified as a valid command binary path or is empty. Ignoring Debian repository synchronisation for '${TMP}'..."
                    fi 
                else
                    f_output "warning" "The Debian repository directory '${REPO_DOWNLOAD_BASEPATH}/${TMP_DOWNLOAD_DEBIAN_PATH}' is not writable by the current user. Ignoring Debian repository synchronisation for '${TMP}'..."
                fi 
            done
            IFS=${TMP_IFS}
        else
            f_output "warning" "The variable 'REPO_DOWNLOAD_DEBIAN_REPOSITORIES' is empty. Ignoring Debian repository synchronisation..."
        fi
    else
        f_output "warning" "The variable 'REPO_DOWNLOAD_DEBIAN' is not enabled by setting it to '1' but is '${REPO_DOWNLOAD_DEBIAN}' in the configuration file '${SCRIPT_PATH}/${TMP_CONF_NAME}'. Ignoring Debian repository synchronisation..."
    fi
    
    # Oracle repository synchronisation
    if [ "${REPO_DOWNLOAD_ORACLE}x" == "1x" ] ; then        
        # write repository definition        
        TMP_DOWNLOAD_ORACLE_LIST=""
        if [ -w "/tmp" ] ; then        
            if [ "${REPO_DOWNLOAD_ORACLE_REPOSITORIES}x" != "x" ] ; then
                TMP_IFS=${IFS}
                IFS='|'
                for TMP in ${REPO_DOWNLOAD_ORACLE_REPOSITORIES} ; do  
                    TMP_DOWNLOAD_ORACLE_LIST_CHECK=""
                    TMP_DOWNLOAD_ORACLE_REPO_CHECK=""
                    TMP_DOWNLOAD_ORACLE_ID=$( ${CMD_AWK} -F ':::' '{ print $1 }' <<< "${TMP}" )
                    TMP_DOWNLOAD_ORACLE_NAME=$( ${CMD_AWK} -F ':::' '{ print $2 }' <<< "${TMP}" )
                    TMP_DOWNLOAD_ORACLE_URI=$( ${CMD_AWK} -F ':::' '{ print $3 }' <<< "${TMP}" )
                    TMP_DOWNLOAD_ORACLE_VERSION=$( ${CMD_AWK} -F ':::' '{ print $4 }' <<< "${TMP}" )
                    TMP_DOWNLOAD_ORACLE_NUMBER=$( ${CMD_AWK} -F ':::' '{ print NF }' <<< "${TMP}" )

                    # check values
                    if [ "${TMP_DOWNLOAD_ORACLE_ID}x" == "x" ] || [ "${TMP_DOWNLOAD_ORACLE_NAME}x" == "x" ] || [ "${TMP_DOWNLOAD_ORACLE_URI}x" == "x" ] || [ "${TMP_DOWNLOAD_ORACLE_VERSION}x" == "x" ] || [ "${TMP_DOWNLOAD_ORACLE_NUMBER}x" != "4x" ] ; then
                        f_output "warning" "The Oracle download repository string needs to consist of 4 entries divided by three colons (<REPOSITORY_ID>:::<REPOSITORY_NAME>:::<REPOSITORY_URI>:::<ORACLE_VERSION_NUMBER>). Skipping Oracle repository '${TMP}'..."
                        continue
                    fi

                    ${CMD_WGET} --spider "${TMP_DOWNLOAD_ORACLE_URI}" 2>/dev/null
                    if [ $? -ne ${TMP_TRUE} ] ; then
                        f_output "info" "The URI '${TMP_DOWNLOAD_ORACLE_URI}' does not seem to be a valid URI. Skipping Oracle repository '${TMP}'..."
                        continue
                    fi

                    # import GPG keys
                    ${CMD_WGET} --timestamping --quiet "https://yum.oracle.com/RPM-GPG-KEY-oracle-ol${TMP_DOWNLOAD_ORACLE_VERSION}" --output-document="/tmp/RPM-GPG-KEY-oracle-ol${TMP_DOWNLOAD_ORACLE_VERSION}" 2>&1
                    if [ $? -eq ${TMP_TRUE} ] ; then
                        ${CMD_GPG} --quiet --import "/tmp/RPM-GPG-KEY-oracle-ol${TMP_DOWNLOAD_ORACLE_VERSION}" 2>&1
                        if [ $? -eq ${TMP_FALSE} ] ; then
                            f_output "warning" "The import of the Oracle GPG Key '/tmp/RPM-GPG-KEY-oracle-ol${TMP_DOWNLOAD_ORACLE_VERSION}' failed."
                        fi
                        TMP_DOWNLOAD_ORACLE_KEY="/tmp/RPM-GPG-KEY-oracle-ol${TMP_DOWNLOAD_ORACLE_VERSION}"
                        
                        if [ ! -f "${REPO_DOWNLOAD_BASEPATH}/oracle/OL${TMP_DOWNLOAD_ORACLE_VERSION}/RPM-GPG-KEY-oracle-ol${TMP_DOWNLOAD_ORACLE_VERSION}" ] ; then
                            ${CMD_CP} "${TMP_DOWNLOAD_ORACLE_KEY}" "${REPO_DOWNLOAD_BASEPATH}/oracle/OL${TMP_DOWNLOAD_ORACLE_VERSION}/" 2> /dev/null
                            if [ $? -eq ${TMP_TRUE} ] ;  then
                                f_output "info" "The Oracle GPG key '${TMP_DOWNLOAD_ORACLE_KEY}' was successfully copied to '${REPO_DOWNLOAD_BASEPATH}/oracle/OL${TMP_DOWNLOAD_ORACLE_VERSION}/'."
                            else
                                f_output "warning" "The Oracle GPG key '${TMP_DOWNLOAD_ORACLE_KEY}' could not be copied to '${REPO_DOWNLOAD_BASEPATH}/oracle/OL${TMP_DOWNLOAD_ORACLE_VERSION}/'."
                            fi
                        fi
                    else
                        f_output "warning" "The download of the oracle GPG Key 'https://yum.oracle.com/RPM-GPG-KEY-oracle-ol${TMP_DOWNLOAD_ORACLE_VERSION}' to '/tmp/RPM-GPG-KEY-oracle-ol${TMP_DOWNLOAD_ORACLE_VERSION}' failed."
                    fi
                    
                    # write repository config
                    if [ -f  "/tmp/localsync_ol${TMP_DOWNLOAD_ORACLE_VERSION}.repo" ] ; then
                        TMP_DOWNLOAD_ORACLE_REPO_CHECK=$( ${CMD_GREP} -i "\[${TMP_DOWNLOAD_ORACLE_ID}\]" < "/tmp/localsync_ol${TMP_DOWNLOAD_ORACLE_VERSION}.repo" 2> /dev/null )
                    fi
                    
                    if [ "${TMP_DOWNLOAD_ORACLE_REPO_CHECK}x" == "x" ] ; then
                        ${CMD_ECHO} "[${TMP_DOWNLOAD_ORACLE_ID}]" >> "/tmp/localsync_ol${TMP_DOWNLOAD_ORACLE_VERSION}.repo"
                        ${CMD_ECHO} "name=${TMP_DOWNLOAD_ORACLE_NAME}" >> "/tmp/localsync_ol${TMP_DOWNLOAD_ORACLE_VERSION}.repo"
                        ${CMD_ECHO} "baseurl=${TMP_DOWNLOAD_ORACLE_URI}" >> "/tmp/localsync_ol${TMP_DOWNLOAD_ORACLE_VERSION}.repo"
                        if [ -r "${TMP_DOWNLOAD_ORACLE_KEY}" ] ; then
                            ${CMD_ECHO} "gpgkey=${TMP_DOWNLOAD_ORACLE_KEY}" >> "/tmp/localsync_ol${TMP_DOWNLOAD_ORACLE_VERSION}.repo"
                            ${CMD_ECHO} "gpgcheck=1" >> "/tmp/localsync_ol${TMP_DOWNLOAD_ORACLE_VERSION}.repo"
                        else
                            ${CMD_ECHO} "gpgkey=${TMP_DOWNLOAD_ORACLE_KEY}" >> "/tmp/localsync_ol${TMP_DOWNLOAD_ORACLE_VERSION}.repo"
                            ${CMD_ECHO} "gpgcheck=0" >> "/tmp/localsync_ol${TMP_DOWNLOAD_ORACLE_VERSION}.repo"
                        fi
                        ${CMD_ECHO} "enabled=1" >> "/tmp/localsync_ol${TMP_DOWNLOAD_ORACLE_VERSION}.repo"
                    fi
                    
                    TMP_DOWNLOAD_ORACLE_LIST_CHECK=$( ${CMD_GREP} "/tmp/localsync_ol${TMP_DOWNLOAD_ORACLE_VERSION}.repo" <<< "${TMP_DOWNLOAD_ORACLE_LIST}" )
                    if [ "${TMP_DOWNLOAD_ORACLE_LIST_CHECK}x" == "x" ] ; then
                        TMP_DOWNLOAD_ORACLE_LIST+="/tmp/localsync_ol${TMP_DOWNLOAD_ORACLE_VERSION}.repo:::${TMP_DOWNLOAD_ORACLE_VERSION}|"
                    fi
                done
                IFS=${TMP_IFS}
            else
                f_output "warning" "The variable 'REPO_DOWNLOAD_ORACLE_REPOSITORIES' is empty. Ignoring Oracle repository synchronisation..."
            fi
        else
            f_output "warning" "The temp directory '/tmp' is not writable by the current user. Ignoring Oracle repository synchronisation..."
        fi

        CMD_DNF=$( ${CMD_WHEREIS} dnf | ${CMD_AWK} '{ print $2 }' )
        CMD_DNF=${CMD_DNF:-/usr/bin/dnf}
        if [ "${CMD_DNF}x" != "x" ] && [ -f "${CMD_DNF}" ] ; then
            TMP_IFS=${IFS}
            IFS='|'
            for TMP in ${TMP_DOWNLOAD_ORACLE_LIST} ; do
                TMP_DOWNLOAD_ORACLE_LIST_REPO=$( ${CMD_AWK} -F ':::' '{ print $1 }' <<< "${TMP}" )
                TMP_DOWNLOAD_ORACLE_LIST_VERSION=$( ${CMD_AWK} -F ':::' '{ print $2 }' <<< "${TMP}" )
                if [ "${TMP_DOWNLOAD_ORACLE_LIST_REPO}x" == "x" ] || [ "${TMP_DOWNLOAD_ORACLE_LIST_VERSION}x" == "x" ] ; then
                    continue
                fi
                
                if [ "${REPO_DOWNLOAD_ORACLE_SOURCE_EXCLUDE}x" == "1x" ] ; then
                    f_output "info" "The download of the Oracle repositories to '${REPO_DOWNLOAD_BASEPATH}/oracle/OL${TMP_DOWNLOAD_ORACLE_LIST_VERSION}' with configuration '${TMP_DOWNLOAD_ORACLE_LIST_REPO}', architecture inclusion filter '${REPO_DOWNLOAD_ORACLE_ARCH_INCLUDE}' and source file exclusion is starting."
                    ${CMD_DNF} reposync --config="${TMP_DOWNLOAD_ORACLE_LIST_REPO}" --delete --download-metadata --download-path="${REPO_DOWNLOAD_BASEPATH}/oracle/OL${TMP_DOWNLOAD_ORACLE_LIST_VERSION}/" --exclude=*.src,*.nosrc --arch="noarch,${REPO_DOWNLOAD_ORACLE_ARCH_INCLUDE}" > /dev/null 2>&1
                elif [ "${REPO_DOWNLOAD_ORACLE_SOURCE_EXCLUDE}x" == "0x" ] ; then
                    f_output "info" "The download of the Oracle repositories to '${REPO_DOWNLOAD_BASEPATH}/oracle/OL${TMP_DOWNLOAD_ORACLE_LIST_VERSION}' with configuration '${TMP_DOWNLOAD_ORACLE_LIST_REPO}', architecture inclusion filter '${REPO_DOWNLOAD_ORACLE_ARCH_INCLUDE}' and source file inclusion is starting."
                    ${CMD_DNF} reposync --config="${TMP_DOWNLOAD_ORACLE_LIST_REPO}" --delete --download-metadata --download-path="${REPO_DOWNLOAD_BASEPATH}/oracle/OL${TMP_DOWNLOAD_ORACLE_LIST_VERSION}/" --arch="noarch,${REPO_DOWNLOAD_ORACLE_ARCH_INCLUDE}" > /dev/null 2>&1
                else
                    continue
                fi
                
                if [ $? -eq ${TMP_TRUE} ] ;  then
                    f_output "info" "The download of the Oracle repositories to '${REPO_DOWNLOAD_BASEPATH}/oracle/OL${TMP_DOWNLOAD_ORACLE_LIST_VERSION}' with configuration '${TMP_DOWNLOAD_ORACLE_LIST_REPO}' finished successfully."
                else
                    f_output "warning" "The download of the Oracle repositories from  to '${REPO_DOWNLOAD_BASEPATH}/oracle/OL${TMP_DOWNLOAD_ORACLE_LIST_VERSION}' with configuration '${TMP_DOWNLOAD_ORACLE_LIST_REPO}' failed."
                fi
            done
            IFS=${TMP_IFS}
        else
            f_output "warning" "The command binary 'dnf' with value '${CMD_DNF}' could not be identified as a valid command binary path or is empty. Ignoring Oracle repository synchronisation..."
        fi 
    else
        f_output "warning" "The variable 'REPO_DOWNLOAD_ORACLE' is not enabled by setting it to '1' but is '${REPO_DOWNLOAD_ORACLE}' in the configuration file '${SCRIPT_PATH}/${TMP_CONF_NAME}'. Ignoring Oracle repository synchronisation..."
    fi
    
    # Proxmox repository synchronisation
    if [ "${REPO_DOWNLOAD_PROXMOX}x" == "1x" ] ; then
        if [ "${REPO_DOWNLOAD_PROXMOX_REPOSITORIES}x" != "x" ] ; then
                TMP_IFS=${IFS}
                IFS='|'
                for TMP in ${REPO_DOWNLOAD_PROXMOX_REPOSITORIES} ; do 
                    TMP_DOWNLOAD_PROXMOX_URI=$( ${CMD_AWK} -F ':::' '{ print $1 }' <<< "${TMP}" )
                    TMP_DOWNLOAD_PROXMOX_PATH="${REPO_DOWNLOAD_BASEPATH}/proxmox/"
                    TMP_DOWNLOAD_PROXMOX_RECURSION=$( ${CMD_AWK} -F ':::' '{ print $2 }' <<< "${TMP}" )
                    TMP_DOWNLOAD_PROXMOX_NUMBER=$( ${CMD_AWK} -F ':::' '{ print NF }' <<< "${TMP}" )

                    # check values
                    if [ "${TMP_DOWNLOAD_PROXMOX_URI}x" == "x" ] || [ "${TMP_DOWNLOAD_PROXMOX_PATH}x" == "x" ] || [ "${TMP_DOWNLOAD_PROXMOX_RECURSION}x" == "x" ] || [ "${TMP_DOWNLOAD_PROXMOX_NUMBER}x" != "2x" ] ; then
                        f_output "warning" "The Proxmox download repository string needs to consist of 2 entries divided by three colons (<PROXMOX_URI>:::<RECURSION>). Skipping Proxmox repository '${TMP}'..."
                        continue
                    fi

                    ${CMD_WGET} --spider "${TMP_DOWNLOAD_PROXMOX_URI}" 2>/dev/null
                    if [ $? -ne ${TMP_TRUE} ] ; then
                        f_output "warning" "The URI '${TMP_DOWNLOAD_PROXMOX_URI}' does not seem to be a valid URI. Skipping Proxmox repository '${TMP}'..."
                        continue
                    fi

                    if [ "${TMP_DOWNLOAD_PROXMOX_RECURSION}x" != "0x" ] && [ "${TMP_DOWNLOAD_PROXMOX_RECURSION}x" != "1x" ] ; then
                        f_output "warning" "The recursion value needs to be a value of '0' or '1' but is '${TMP_DOWNLOAD_PROXMOX_RECURSION}'. Skipping Proxmox repository '${TMP}'..."
                        continue
                    fi
                    
                    f_download_generic "${TMP_DOWNLOAD_PROXMOX_URI}" "${TMP_DOWNLOAD_PROXMOX_PATH}" "${TMP_DOWNLOAD_PROXMOX_RECURSION}"
                done
                IFS=${TMP_IFS}
        else
            f_output "warning" "The variable 'REPO_DOWNLOAD_PROXMOX_REPOSITORIES' is empty. Ignoring public Proxmox repository synchronisation..."
        fi
        
        if [ "${REPO_DOWNLOAD_PROXMOX_ENTERPRISE}x" != "x" ] ; then
            TMP_DOWNLOAD_PROXMOX_ENTERPRISE_IDS=""
            TMP_DOWNLOAD_PROXMOX_ENTERPRISE_RESULT=""
            TMP_IFS=${IFS}
            IFS='|'
            for TMP in ${REPO_DOWNLOAD_PROXMOX_ENTERPRISE} ; do 
                TMP_DOWNLOAD_PROXMOX_ENTERPRISE_KEY=$( ${CMD_AWK} -F ':::' '{ print $1 }' <<< "${TMP}" )
                TMP_DOWNLOAD_PROXMOX_ENTERPRISE_SERVERID=$( ${CMD_AWK} -F ':::' '{ print $2 }' <<< "${TMP}" )
                TMP_DOWNLOAD_PROXMOX_ENTERPRISE_POM_KEY=$( ${CMD_AWK} -F ':::' '{ print $3 }' <<< "${TMP}" )
                TMP_DOWNLOAD_PROXMOX_ENTERPRISE_PATH="${REPO_DOWNLOAD_BASEPATH}/proxmox/enterprise"
                TMP_DOWNLOAD_PROXMOX_NUMBER=$( ${CMD_AWK} -F ':::' '{ print NF }' <<< "${TMP}" )
                
                # check values
                if [ "${TMP_DOWNLOAD_PROXMOX_ENTERPRISE_KEY}x" == "x" ] || [ "${TMP_DOWNLOAD_PROXMOX_ENTERPRISE_SERVERID}x" == "x" ] || [ "${TMP_DOWNLOAD_PROXMOX_ENTERPRISE_POM_KEY}x" == "x" ]|| [ "${TMP_DOWNLOAD_PROXMOX_NUMBER}x" != "3x" ] ; then
                    f_output "warning" "The Proxmox enterprise download repository string needs to consist of 3 entries divided by three colons (<TMP_DOWNLOAD_PROXMOX_ENTERPRISE_KEY>:::<TMP_DOWNLOAD_PROXMOX_ENTERPRISE_SERVERID>:::<TMP_DOWNLOAD_PROXMOX_ENTERPRISE_POM_KEY>). Skipping Proxmox repository '${TMP}'..."
                    continue
                fi
                
                CMD_PROXMOX_OFFLINE_MIRROR=$( ${CMD_WHEREIS} proxmox-offline-mirror | ${CMD_AWK} '{ print $2 }' )
                CMD_PROXMOX_OFFLINE_MIRROR=${CMD_PROXMOX_OFFLINE_MIRROR:-/usr/bin/proxmox-offline-mirror}
                if [ "${CMD_PROXMOX_OFFLINE_MIRROR}x" == "x" ] && [ ! -f "${CMD_PROXMOX_OFFLINE_MIRROR}" ] ; then
                    f_output "warning" "The command binary 'proxmox-offline-mirror' with value '${CMD_PROXMOX_OFFLINE_MIRROR}' could not be identified as a valid command binary path or is empty. Please ensure to install the package by importing the GPG keys ('${CMD_WGET} https://enterprise.proxmox.com/debian/proxmox-release-<VERSION>.gpg -output-document=/etc/apt/trusted.gpg.d/proxmox-release-<VERSION>.gpg'), adding the apt repository conf ('${CMD_ECHO} \"deb http://download.proxmox.com/debian/pbs-client bookworm main\" > \"/etc/apt/sources.list.d/pbs-client.list\"') and installing the package ('apt install proxmox-offline-mirror'). Ignoring Proxmox enterprise repository synchronisation..."
                    continue
                fi 
                
                if [ ! -f "/etc/ssh/ssh_host_rsa_key.pub" ] ; then
                    f_output "warning" "The general SSH host RSA key ist missing at '/etc/ssh/ssh_host_rsa_key.pub'. If not running the SSHD daemon please ensure it is initially set by executing '/usr/bin/ssh-keygen -A' in the root context. Ignoring Proxmox enterprise repository synchronisation..."
                    continue
                fi
                f_proxmox_enterprise_config "key" "add-mirror-key" "${TMP_DOWNLOAD_PROXMOX_ENTERPRISE_POM_KEY} --config ${HOME}/.proxmox-offline-mirror.cfg"
                if [ ${TMP_DOWNLOAD_PROXMOX_ENTERPRISE_RESULT} -eq ${TMP_TRUE} ] ; then
                    f_output "info" "The Proxmox enterprise POM client key '${TMP_DOWNLOAD_PROXMOX_ENTERPRISE_POM_KEY}' was successfully configured at '${HOME}/.proxmox-offline-mirror.cfg'."
                else
                    f_output "warning" "The Proxmox enterprise POM client key '${TMP_DOWNLOAD_PROXMOX_ENTERPRISE_POM_KEY}' could not be configured at '${HOME}/.proxmox-offline-mirror.cfg'. Ignoring Proxmox enterprise repository synchronisation for PVE subscription key '${TMP_DOWNLOAD_PROXMOX_ENTERPRISE_KEY}'..."
                    continue
                fi
                
                f_proxmox_enterprise_config "key" "add" "${TMP_DOWNLOAD_PROXMOX_ENTERPRISE_KEY} ${TMP_DOWNLOAD_PROXMOX_ENTERPRISE_SERVERID} --config ${HOME}/.proxmox-offline-mirror.cfg"
                if [ ${TMP_DOWNLOAD_PROXMOX_ENTERPRISE_RESULT} -eq ${TMP_TRUE} ] ; then
                    f_output "info" "The Proxmox enterprise key '${TMP_DOWNLOAD_PROXMOX_ENTERPRISE_KEY}' for server ID '${TMP_DOWNLOAD_PROXMOX_ENTERPRISE_SERVERID}' was successfully configured at '${HOME}/.proxmox-offline-mirror.cfg'."
                else
                    f_output "warning" "The Proxmox enterprise key '${TMP_DOWNLOAD_PROXMOX_ENTERPRISE_KEY}' for server ID '${TMP_DOWNLOAD_PROXMOX_ENTERPRISE_SERVERID}' could not be configured at '${HOME}/.proxmox-offline-mirror.cfg'."
                    continue
                fi
                
                # key download
                for i in "proxmox-release-bookworm.gpg" "proxmox-release-bullseye.gpg" "proxmox-ve-release-4.x.gpg" "proxmox-ve-release-5.x.gpg" "proxmox-ve-release-6.x.gpg" ; do
                    if [ "${i}x" != "x" ] && [ ! -f "${TMP_DOWNLOAD_PROXMOX_ENTERPRISE_PATH}/keys" ] ; then
                        f_download_generic "https://enterprise.proxmox.com/debian/${i}" "${TMP_DOWNLOAD_PROXMOX_ENTERPRISE_PATH}/keys" "0"
                        if [ $? -eq ${TMP_TRUE} ] ; then
                            f_output "info" "The Proxmox enterprise signature key 'https://enterprise.proxmox.com/debian/${i}' was successfully updated to '${TMP_DOWNLOAD_PROXMOX_ENTERPRISE_PATH}/keys'."
                        else
                            f_output "warning" "The Proxmox enterprise signature key 'https://enterprise.proxmox.com/debian/${i}' could not be downloaded to '${TMP_DOWNLOAD_PROXMOX_ENTERPRISE_PATH}/keys'."
                            continue
                        fi
                    fi
                done
                
                # mirror configration
                f_proxmox_enterprise_config "config mirror" "add" "--id bookworm-pve --architectures amd64 --base-dir ${TMP_DOWNLOAD_PROXMOX_ENTERPRISE_PATH} --key-path ${TMP_DOWNLOAD_PROXMOX_ENTERPRISE_PATH}/keys/proxmox-release-bookworm.gpg --repository 'deb https://enterprise.proxmox.com/debian/pve bookworm pve-enterprise' --sync 1 --verify 1 --use-subscription pve --config ${HOME}/.proxmox-offline-mirror.cfg"
                if [ ${TMP_DOWNLOAD_PROXMOX_ENTERPRISE_RESULT} -eq ${TMP_TRUE} ] ; then
                    f_output "info" "The Proxmox enterprise mirror configuration for ID 'bookworm-pve' was successfully configured at '${HOME}/.proxmox-offline-mirror.cfg'."
                    TMP_DOWNLOAD_PROXMOX_ENTERPRISE_IDS+="bookworm-pve "
                else
                    f_output "warning" "The Proxmox enterprise mirror configuration for ID 'bookworm-pve' could not be configured at '${HOME}/.proxmox-offline-mirror.cfg'. Ignoring it..."
                fi
                
                f_proxmox_enterprise_config "config mirror" "add" "--id bullseye-pve --architectures amd64 --base-dir ${TMP_DOWNLOAD_PROXMOX_ENTERPRISE_PATH} --key-path ${TMP_DOWNLOAD_PROXMOX_ENTERPRISE_PATH}/keys/proxmox-release-bullseye.gpg --repository 'deb https://enterprise.proxmox.com/debian/pve bullseye pve-enterprise' --sync 1 --verify 1 --use-subscription pve --config ${HOME}/.proxmox-offline-mirror.cfg"
                if [ ${TMP_DOWNLOAD_PROXMOX_ENTERPRISE_RESULT} -eq ${TMP_TRUE} ] ; then
                    f_output "info" "The Proxmox enterprise mirror configuration for ID 'bullseye-pve' was successfully configured at '${HOME}/.proxmox-offline-mirror.cfg'."
                    TMP_DOWNLOAD_PROXMOX_ENTERPRISE_IDS+="bullseye-pve "
                else
                    f_output "warning" "The Proxmox enterprise mirror configuration for ID 'bullseye-pve' could not be configured at '${HOME}/.proxmox-offline-mirror.cfg'. Ignoring it..."
                fi
                
                f_proxmox_enterprise_config "config mirror" "add" "--id bookworm-ceph_quincy --architectures amd64 --base-dir ${TMP_DOWNLOAD_PROXMOX_ENTERPRISE_PATH} --key-path ${TMP_DOWNLOAD_PROXMOX_ENTERPRISE_PATH}/keys/proxmox-release-bookworm.gpg --repository 'deb https://enterprise.proxmox.com/debian/ceph-quincy bookworm enterprise' --sync 1 --verify 1 --use-subscription pve --config ${HOME}/.proxmox-offline-mirror.cfg"
                if [ ${TMP_DOWNLOAD_PROXMOX_ENTERPRISE_RESULT} -eq ${TMP_TRUE} ] ; then
                    f_output "info" "The Proxmox enterprise mirror configuration for ID 'bookworm-ceph_quincy' was successfully configured at '${HOME}/.proxmox-offline-mirror.cfg'."
                    TMP_DOWNLOAD_PROXMOX_ENTERPRISE_IDS+="bookworm-ceph_quincy "
                else
                    f_output "warning" "The Proxmox enterprise mirror configuration for ID 'bookworm-ceph_quincy' could not be configured at '${HOME}/.proxmox-offline-mirror.cfg'. Ignoring it..."
                fi
                
                f_proxmox_enterprise_config "config mirror" "add" "--id bookworm-ceph_reef --architectures amd64 --base-dir ${TMP_DOWNLOAD_PROXMOX_ENTERPRISE_PATH} --key-path ${TMP_DOWNLOAD_PROXMOX_ENTERPRISE_PATH}/keys/proxmox-release-bookworm.gpg --repository 'deb https://enterprise.proxmox.com/debian/ceph-reef bookworm enterprise' --sync 1 --verify 1 --use-subscription pve --config ${HOME}/.proxmox-offline-mirror.cfg"
                if [ ${TMP_DOWNLOAD_PROXMOX_ENTERPRISE_RESULT} -eq ${TMP_TRUE} ] ; then
                    f_output "info" "The Proxmox enterprise mirror configuration for ID 'bookworm-ceph_reef' was successfully configured at '${HOME}/.proxmox-offline-mirror.cfg'."
                    TMP_DOWNLOAD_PROXMOX_ENTERPRISE_IDS+="bookworm-ceph_reef "
                else
                    f_output "warning" "The Proxmox enterprise mirror configuration for ID 'bookworm-ceph_reef' could not be configured at '${HOME}/.proxmox-offline-mirror.cfg'. Ignoring it..."
                fi     
            done
            IFS=${TMP_IFS}

            for i in ${TMP_DOWNLOAD_PROXMOX_ENTERPRISE_IDS} ; do
                f_output "info" "The Proxmox enterprise mirror snapshot with ID '${i}' and configuration file '${HOME}/.proxmox-offline-mirror.cfg' is starting."
                
                ${CMD_PROXMOX_OFFLINE_MIRROR} mirror snapshot create "${i}" --config ~/".proxmox-offline-mirror.cfg" >/dev/null 2>&1
                if [ $? -eq ${TMP_TRUE} ] ; then
                    f_output "info" "The Proxmox enterprise mirror snapshot with ID '${i}' and configuration file '${HOME}/.proxmox-offline-mirror.cfg' was successfully downloaded."
                else
                    f_output "warning" "The Proxmox enterprise mirror snapshot with ID '${i}' and configuration file '${HOME}/.proxmox-offline-mirror.cfg' could not be downloaded. Skippting it..."
                    continue
                fi
                TMP_DOWNLOAD_PROXMOX_ENTERPRISE_SNAPSHOTS=""
                TMP_DOWNLOAD_PROXMOX_ENTERPRISE_SNAPSHOTS=$( ${CMD_PROXMOX_OFFLINE_MIRROR} mirror snapshot list --id "${i}" --output-format text --config ~/".proxmox-offline-mirror.cfg" 2> /dev/null | ${CMD_AWK} -F '-\ ' '{ print $2 }' )
                TMP_DOWNLOAD_PROXMOX_ENTERPRISE_SNAPSHOTS_CHECK=$( ${CMD_GREP} --invert-match '^$' <<< "${TMP_DOWNLOAD_PROXMOX_ENTERPRISE_SNAPSHOTS}" | ${CMD_GREP} --count '^' )
                
                if [ "${TMP_DOWNLOAD_PROXMOX_ENTERPRISE_SNAPSHOTS_CHECK}x" == "x" ] ; then
                    f_output "warning" "The Proxmox enterprise mirror snapshot list for ID '${i}' and configuration file '${HOME}/.proxmox-offline-mirror.cfg' is not cleaned as there are no snapshots. Skippting it..."
                    continue
                elif [ "${TMP_DOWNLOAD_PROXMOX_ENTERPRISE_SNAPSHOTS_CHECK}x" == "1x" ] ; then
                    f_output "warning" "The Proxmox enterprise mirror snapshot list for ID '${i}' and configuration file '${HOME}/.proxmox-offline-mirror.cfg' is not cleaned as there are is only one remaining snapshot. Skippting it..."
                    continue
                else
                    TMP_DOWNLOAD_PROXMOX_ENTERPRISE_SNAPSHOTS=$( ${CMD_GREP} --invert-match '^$' <<< "${TMP_DOWNLOAD_PROXMOX_ENTERPRISE_SNAPSHOTS}" 2> /dev/null | ${CMD_SED} '$d' )
                    for k in ${TMP_DOWNLOAD_PROXMOX_ENTERPRISE_SNAPSHOTS} ; do
                        if [ "${k}x" != "x" ] ; then
                            ${CMD_PROXMOX_OFFLINE_MIRROR} mirror snapshot remove "${i}" "${k}" --config ~/".proxmox-offline-mirror.cfg" >/dev/null 2>&1
                            
                            if [ $? -eq ${TMP_TRUE} ] ; then
                                f_output "info" "The Proxmox enterprise mirror snapshot '${k}' with ID '${i}' and configuration file '${HOME}/.proxmox-offline-mirror.cfg' was successfully removed."
                            else
                                f_output "warning" "The Proxmox enterprise mirror snapshot '${k}' with ID '${i}' and configuration file '${HOME}/.proxmox-offline-mirror.cfg' could not be removed. Skippting it..."
                            fi
                        fi
                    done
                    ${CMD_PROXMOX_OFFLINE_MIRROR} mirror gc "${i}" --config ${HOME}/.proxmox-offline-mirror.cfg >/dev/null 2>&1
                fi
                
                TMP_DOWNLOAD_PROXMOX_ENTERPRISE_SNAPSHOTS=$( ${CMD_PROXMOX_OFFLINE_MIRROR} mirror snapshot list --id "${i}" --output-format text --config ~/".proxmox-offline-mirror.cfg" 2> /dev/null | ${CMD_AWK} -F '-\ ' '{ print $2 }' | ${CMD_GREP} --invert-match '^$' | ${CMD_GREP} "" -B1 )
                
                if [ "${TMP_DOWNLOAD_PROXMOX_ENTERPRISE_SNAPSHOTS}x" != "x" ] ; then
                    ${CMD_LN} --symbolic --force --no-dereference --target-directory="${REPO_DOWNLOAD_BASEPATH}/proxmox/enterprise/${i}/" "${TMP_DOWNLOAD_PROXMOX_ENTERPRISE_SNAPSHOTS}/dists" 2> /dev/null
                    if [ $? -eq ${TMP_TRUE} ] ; then
                        f_output "info" "The Proxmox enterprise mirror symlink '${REPO_DOWNLOAD_BASEPATH}/proxmox/enterprise/${i}/dists' to '${REPO_DOWNLOAD_BASEPATH}/proxmox/enterprise/${i}/${TMP_DOWNLOAD_PROXMOX_ENTERPRISE_SNAPSHOTS}/dists' for ID '${i}' was successfully created."
                    else
                        f_output "warning" "The Proxmox enterprise mirror symlink '${REPO_DOWNLOAD_BASEPATH}/proxmox/enterprise/${i}/dists' to '${REPO_DOWNLOAD_BASEPATH}/proxmox/enterprise/${i}/${TMP_DOWNLOAD_PROXMOX_ENTERPRISE_SNAPSHOTS}/dists' for ID '${i}' could not be created. Skipping it..."
                    fi
                fi
            done
        else
            f_output "warning" "The variable 'REPO_DOWNLOAD_PROXMOX_ENTERPRISE_KEY' is empty. Ignoring Proxmox enterprise repository synchronisation..."
        fi
    else
        f_output "warning" "The variable 'REPO_DOWNLOAD_PROXMOX' is not enabled by setting it to '1' but is '${REPO_DOWNLOAD_PROXMOX}' in the configuration file '${SCRIPT_PATH}/${TMP_CONF_NAME}'. Ignoring Proxmox repository synchronisation..."
    fi
    
    # git
    if [ "${REPO_DOWNLOAD_GIT}x" == "1x" ] ; then
        if [ "${REPO_DOWNLOAD_GIT_REPOSITORIES}x" != "x" ] ; then
            CMD_GIT=$( ${CMD_WHEREIS} git | ${CMD_AWK} '{ print $2 }' )
            CMD_GIT=${CMD_GIT:-/usr/bin/git}
            if [ "${CMD_GIT}x" != "x" ] && [ -f "${CMD_GIT}" ] ; then  
                TMP_IFS=${IFS}
                IFS='|'
                for TMP in ${REPO_DOWNLOAD_GIT_REPOSITORIES} ; do
                    TMP_DOWNLOAD_GIT_URI=$( ${CMD_AWK} -F ':::' '{ print $1 }' <<< "${TMP}" )
                    TMP_DOWNLOAD_GIT_PATH=$( ${CMD_AWK} -F ':::' '{ print $2 }' <<< "${TMP}" )
                    TMP_DOWNLOAD_GIT_PATH="${REPO_DOWNLOAD_BASEPATH}/git/${TMP_DOWNLOAD_GIT_PATH}"
                    TMP_DOWNLOAD_GIT_NUMBER=$( ${CMD_AWK} -F ':::' '{ print NF }' <<< "${TMP}" )

                    # check values
                    if [ "${TMP_DOWNLOAD_GIT_URI}x" == "x" ] || [ "${TMP_DOWNLOAD_GIT_PATH}x" == "x" ] || [ "${TMP_DOWNLOAD_GIT_NUMBER}x" != "2x" ] ; then
                        f_output "warning" "The GIT download repository string needs to consist of 2 entries divided by three colons (<GIT_URI>:::<GIT_PATH>). Skipping GIT repository '${TMP}'..."
                        continue
                    fi

                    ${CMD_WGET} --spider "${TMP_DOWNLOAD_GIT_URI}" 2>/dev/null
                    if [ $? -ne ${TMP_TRUE} ] ; then
                        f_output "warning" "The URI '${TMP_DOWNLOAD_GIT_URI}' does not seem to be a valid URI. Skipping GIT repository '${TMP}'..."
                        continue
                    fi
                
                    if [ ! -d "${TMP_DOWNLOAD_GIT_PATH}" ] ; then
                        ${CMD_GIT} clone --quiet --mirror "${TMP_DOWNLOAD_GIT_URI}" "${TMP_DOWNLOAD_GIT_PATH}"
                        if [ $? -eq ${TMP_TRUE} ] ; then
                            f_output "info" "The GIT repository folder '${TMP_DOWNLOAD_GIT_PATH}' was successfully initialized for URI '${TMP_DOWNLOAD_GIT_URI}'."
                        else
                            f_output "warning" "The GIT repository folder '${TMP_DOWNLOAD_GIT_PATH}' for URI '${TMP_DOWNLOAD_GIT_URI}' could not be initialized. Skipping it..."
                            ${CMD_RM} -rf "${TMP_DOWNLOAD_GIT_PATH}" 2> /dev/null
                            continue
                        fi
                    fi
                    cd "${TMP_DOWNLOAD_GIT_PATH}"
                    ${CMD_GIT} fetch --quiet --all 2> /dev/null
                    if [ $? -eq ${TMP_TRUE} ] ; then
                        f_output "info" "The GIT repository folder '${TMP_DOWNLOAD_GIT_PATH}' was successfully updated for URI '${TMP_DOWNLOAD_GIT_URI}'."
                    else
                        f_output "warning" "The GIT repository folder '${TMP_DOWNLOAD_GIT_PATH}' for URI '${TMP_DOWNLOAD_GIT_URI}' could not be updated. Skipping it..."
                    fi
                    ${CMD_GIT} reset --hard origin/master 2> /dev/null
                    cd "${REPO_DOWNLOAD_BASEPATH}"

                    # download releases
                    TMP_DOWNLOAD_GIT_URI_SHORT=$( ${CMD_AWK} -F '.git$' '{ print $1 }' <<< "${TMP_DOWNLOAD_GIT_URI}" )
                    TMP_DOWNLOAD_GIT_VERSION=$( ${CMD_WGET} --connect-timeout=5 --waitretry=1 --tries=1 --server-response "${TMP_DOWNLOAD_GIT_URI_SHORT}/releases/latest" --quiet --output-document=/dev/null 2>&1 | ${CMD_AWK} -F 'Location: ' '{ printf $2 }' | ${CMD_AWK} -F ' ' '{ print $1 }' | ${CMD_AWK} -F '/' '{ print $NF }' )

                    if [ $? -ne ${TMP_TRUE} ] || [ "${TMP_DOWNLOAD_GIT_VERSION}x" == "x" ] ; then
                        f_output "warning" "The GIT repository latest version extraction with value '${TMP_DOWNLOAD_GIT_VERSION}' for URI '${TMP_DOWNLOAD_GIT_URI_SHORT}/releases/latest' failed. Skipping latest release download..."
                        continue
                    fi

                    ${CMD_WGET} --connect-timeout=5 --waitretry=1 --tries=1 --convert-links "${TMP_DOWNLOAD_GIT_URI_SHORT}/releases/expanded_assets/${TMP_DOWNLOAD_GIT_VERSION}" --quiet --output-document="/tmp/github.wget"

                    if [ $? -ne ${TMP_TRUE} ] || [ ! -f "/tmp/github.wget" ] ; then
                        f_output "warning" "The GIT repository latest version asset link extraction to '/tmp/github.wget' for URI '${TMP_DOWNLOAD_GIT_URI_SHORT}/releases/expanded_assets/${TMP_DOWNLOAD_GIT_VERSION}' failed. Skipping latest release download..."
                        ${CMD_RM} --force "/tmp/github.wget" 2> /dev/null
                        continue
                    fi

                    TMP_DOWNLOAD_GIT_URI_RELEASE=$( ${CMD_AWK} -F '<a href="' '{ print $2 }' < "/tmp/github.wget" | ${CMD_AWK} -F '"' '{ if($1!="") printf $1"|" }' )
                    ${CMD_RM} --force "/tmp/github.wget" 2> /dev/null

                    TMP_DOWNLOAD_GIT_URI_NOHTTP=$( ${CMD_AWK} -F '//' '{print $2}' <<< "${TMP_DOWNLOAD_GIT_URI}" )
                    if [ "${TMP_DOWNLOAD_GIT_URI_NOHTTP}x" == "x" ] ; then
                        f_output "warning" "The GIT repository URI without 'http:' / 'https:' could not be extracted. Skipping latest release download..."
                        continue
                    fi

                    for RELEASE in ${TMP_DOWNLOAD_GIT_URI_RELEASE} ; do
                        if [ "${RELEASE}x" != "x" ] ; then
                            f_download_generic "${RELEASE}" "${REPO_DOWNLOAD_BASEPATH}/other/github/${TMP_DOWNLOAD_GIT_URI_NOHTTP}/${TMP_DOWNLOAD_GIT_VERSION}" "0"
                        fi
                    done
                done
                IFS=${TMP_IFS}
            else
                f_output "warning" "The command binary 'git' with value '${CMD_GIT}' could not be identified as a valid command binary path or is empty. Ignoring Git repository synchronisation..."
            fi
        else
            f_output "warning" "The variable 'REPO_DOWNLOAD_GIT_REPOSITORIES' is empty. Ignoring Git repository synchronisation..."
        fi
    else
        f_output "warning" "The variable 'REPO_DOWNLOAD_GIT' is not enabled by setting it to '1' but is '${REPO_DOWNLOAD_GIT}' in the configuration file '${SCRIPT_PATH}/${TMP_CONF_NAME}'. Ignoring Git repository synchronisation..."
    fi

    # other
    if [ "${REPO_DOWNLOAD_OTHER}x" == "1x" ] ; then
        if [ "${REPO_DOWNLOAD_OTHER_REPOSITORIES}x" != "x" ] ; then
                TMP_IFS=${IFS}
                IFS='|'
                for TMP in ${REPO_DOWNLOAD_OTHER_REPOSITORIES} ; do
                    TMP_DOWNLOAD_OTHER_URI=$( ${CMD_AWK} -F ':::' '{ print $1 }' <<< "${TMP}" )
                    TMP_DOWNLOAD_OTHER_PATH=$( ${CMD_AWK} -F ':::' '{ print $2 }' <<< "${TMP}" )
                    TMP_DOWNLOAD_OTHER_PATH="${REPO_DOWNLOAD_BASEPATH}/other/${TMP_DOWNLOAD_OTHER_PATH}"
                    TMP_DOWNLOAD_OTHER_RECURSION=$( ${CMD_AWK} -F ':::' '{ print $3 }' <<< "${TMP}" )
                    TMP_DOWNLOAD_OTHER_NUMBER=$( ${CMD_AWK} -F ':::' '{ print NF }' <<< "${TMP}" )

                    # check values
                    if [ "${TMP_DOWNLOAD_OTHER_URI}x" == "x" ] || [ "${TMP_DOWNLOAD_OTHER_PATH}x" == "x" ] || [ "${TMP_DOWNLOAD_OTHER_RECURSION}x" == "x" ] || [ "${TMP_DOWNLOAD_OTHER_NUMBER}x" != "3x" ] ; then
                        f_output "warning" "The other download repository string needs to consist of 3 entries divided by three colons (<OTHER_URI>:::<OTHER_PATH>:::<RECURSION>). Skipping other repository '${TMP}'..."
                        continue
                    fi

                    ${CMD_WGET} --spider "${TMP_DOWNLOAD_OTHER_URI}" 2>/dev/null
                    if [ $? -ne ${TMP_TRUE} ] ; then
                        f_output "warning" "The URI '${TMP_DOWNLOAD_OTHER_URI}' does not seem to be a valid URI. Skipping other repository '${TMP}'..."
                        continue
                    fi

                    if [ "${TMP_DOWNLOAD_OTHER_RECURSION}x" != "0x" ] && [ "${TMP_DOWNLOAD_OTHER_RECURSION}x" != "1x" ] ; then
                        f_output "warning" "The recursion value needs to be a value of '0' or '1' but is '${TMP_DOWNLOAD_OTHER_RECURSION}'. Skipping other repository '${TMP}'..."
                        continue
                    fi
                    
                    f_download_generic "${TMP_DOWNLOAD_OTHER_URI}" "${TMP_DOWNLOAD_OTHER_PATH}" "${TMP_DOWNLOAD_OTHER_RECURSION}"
                done
                IFS=${TMP_IFS}
        else
            f_output "warning" "The variable 'REPO_DOWNLOAD_OTHER' is empty. Ignoring other repository synchronisation..."
        fi
    else
        f_output "warning" "The variable 'REPO_DOWNLOAD_OTHER' is not enabled by setting it to '1' but is '${REPO_DOWNLOAD_OTHER}' in the configuration file '${SCRIPT_PATH}/${TMP_CONF_NAME}'. Ignoring other repository synchronisation..."
    fi
}

function f_download_generic() {
    TMP_DOWNLOAD_GENERIC_URI="${1}"
    TMP_DOWNLOAD_GENERIC_PATH="${2}"
    TMP_DOWNLOAD_GENERIC_RECURSIVE="${3}"

    TMP_DOWNLOAD_GENERIC_CRAWL_LOCAL_PATH=""

    if [ "${TMP_DOWNLOAD_GENERIC_URI}x" == "x" ] || [ "${TMP_DOWNLOAD_GENERIC_PATH}x" == "x" ] || [ "${TMP_DOWNLOAD_GENERIC_RECURSIVE}x" == "x" ] ; then
        f_output "warning" "The download URI ('${TMP_DOWNLOAD_GENERIC_URI}') or path ('${TMP_DOWNLOAD_GENERIC_PATH}') or recursion definition was empty. Skipping download."
        return ${TMP_FALSE}
    fi
    
    if [ ! -d "${TMP_DOWNLOAD_GENERIC_PATH}" ] ; then
        ${CMD_MKDIR} --parents "${TMP_DOWNLOAD_GENERIC_PATH}" > /dev/null 2>&1
        if [ $? -eq ${TMP_TRUE} ] ; then
            f_output "info" "The download directory '${TMP_DOWNLOAD_GENERIC_PATH}' was successfully created."
        else
            f_output "warning" "The download directory '${TMP_DOWNLOAD_GENERIC_PATH}' could not be created. Skipping download for URI '${TMP_DOWNLOAD_GENERIC_URI}'..."
            return ${TMP_FALSE}
        fi
    fi
    
    if [ ! -w "${TMP_DOWNLOAD_GENERIC_PATH}" ] ; then
        f_output "warning" "The local download path ('${TMP_DOWNLOAD_GENERIC_PATH}') is not writable by the current user '${USER}'. Skipping download for URI '${TMP_DOWNLOAD_GENERIC_URI}'..."
        return ${TMP_FALSE}
    fi
    
    if [ "${TMP_DOWNLOAD_GENERIC_RECURSIVE}x" == "1x" ] ; then
        f_output "info" "The download of URI '${TMP_DOWNLOAD_GENERIC_URI}' to local path '${TMP_DOWNLOAD_GENERIC_PATH}' with recursion enabled is starting."
        
        TMP_DOWNLOAD_GENERIC_CRAWL_LOCAL_PATH=$( ${CMD_AWK} -v path="${TMP_DOWNLOAD_GENERIC_PATH}" -F '://' '{ if(($1=="http") || ($1=="https")) print path"/"$2 ; else print path"/"$1 }' <<< "${TMP_DOWNLOAD_GENERIC_URI}" | ${CMD_SED} 's/\/\//\//g' 2> /dev/null )
        
        ${CMD_WGET} --timestamping --connect-timeout=5 --waitretry=1 --tries=1 --recursive --level=0 --no-parent --directory-prefix="${TMP_DOWNLOAD_GENERIC_PATH}" --reject "index.html*" "${TMP_DOWNLOAD_GENERIC_URI}" --output-file="/tmp/repositorysync.wget" 2> /dev/null
    elif [ "${TMP_DOWNLOAD_GENERIC_RECURSIVE}x" == "0x" ] ; then
        f_output "info" "The download of URI '${TMP_DOWNLOAD_GENERIC_URI}' to local path '${TMP_DOWNLOAD_GENERIC_PATH}' with recursion disabled is starting."
        
        TMP_DOWNLOAD_GENERIC_CRAWL_LOCAL_PATH=$( ${CMD_SED} 's/\/\//\//g' <<< "${TMP_DOWNLOAD_GENERIC_PATH}" 2> /dev/null )
        
        ${CMD_WGET} --timestamping --connect-timeout=5 --waitretry=1 --tries=1 --level=1 --no-parent --directory-prefix="${TMP_DOWNLOAD_GENERIC_PATH}" --reject "index.html*" "${TMP_DOWNLOAD_GENERIC_URI}" --output-file="/tmp/repositorysync.wget" 2> /dev/null
    else
        f_output "warning" "The defined recursion decision variable 'TMP_DOWNLOAD_GENERIC_RECURSIVE' was passed an invalid value of '${TMP_DOWNLOAD_GENERIC_RECURSIVE}'. It must be either 1 to enable recursion or 0 to disable it. Skipping download for URI '${TMP_DOWNLOAD_GENERIC_URI}'."
    fi

    if [ $? -eq ${TMP_TRUE} ] ; then
        f_output "info" "The download for URI '${TMP_DOWNLOAD_GENERIC_URI}' was successfully saved to '${TMP_DOWNLOAD_GENERIC_PATH}'."
    else
        f_output "warning" "The download for URI '${TMP_DOWNLOAD_GENERIC_URI}' could not be saved to '${TMP_DOWNLOAD_GENERIC_PATH}'."
        return ${TMP_FALSE}
    fi

    f_output "info" "The sync comparison of URI '${TMP_DOWNLOAD_GENERIC_URI}' for path '${TMP_DOWNLOAD_GENERIC_PATH}' is starting."
    CMD_FIND=$( ${CMD_WHEREIS} find | ${CMD_AWK} '{ print $2 }' )
    CMD_FIND=${CMD_FIND:-/usr/bin/find}
    if [ "${CMD_FIND}x" != "x" ] && [ -f "${CMD_FIND}" ] ; then
        if [ "${TMP_DOWNLOAD_GENERIC_RECURSIVE}x" == "1x" ] ; then
            TMP_DOWNLOAD_GENERIC_CRAWL_LOCAL=$( ${CMD_FIND} "${TMP_DOWNLOAD_GENERIC_CRAWL_LOCAL_PATH}" -type f )
        else
            TMP_DOWNLOAD_GENERIC_CRAWL_LOCAL=""
            f_output "info" "The sync comparison of URI '${TMP_DOWNLOAD_GENERIC_URI}' for path '${TMP_DOWNLOAD_GENERIC_PATH}' finished."
            return ${TMP_TRUE}
        fi
        
        if [ $? -ne ${TMP_TRUE} ] || [ "${TMP_DOWNLOAD_GENERIC_CRAWL_LOCAL}x" == "x" ] ; then
            f_output "warning" "The sync comparison of URI '${TMP_DOWNLOAD_GENERIC_URI}' for path '${TMP_DOWNLOAD_GENERIC_PATH}' failed as the local files could not be crawled. Skipping local clean..."
            return ${TMP_FALSE}
        fi
        
        if [ ! -f "/tmp/repositorysync.wget" ] || [ ! -s "/tmp/repositorysync.wget" ] ; then
            f_output "warning" "The sync comparison of URI '${TMP_DOWNLOAD_GENERIC_URI}' for path '${TMP_DOWNLOAD_GENERIC_PATH}' failed as the URI download list '/tmp/repositorysync.wget' is empty or non existent. Skipping local clean..."
            return ${TMP_FALSE}
        fi
        
        while IFS= read -r i; do
            TMP_DOWNLOAD_GENERIC_CRAWL_CHECK=""
            if [ "${i}x" == "x" ] ; then
                continue
            fi
            TMP_DOWNLOAD_GENERIC_CRAWL_CHECK=$( ${CMD_GREP} --ignore-case "${i}" < "/tmp/repositorysync.wget" )
            if [ "${TMP_DOWNLOAD_GENERIC_CRAWL_CHECK}x" == "x" ] && [ ! -L "${i}" ] ; then
                ${CMD_RM} --recursive --force "${i}" 2> /dev/null
                if [ $? -eq ${TMP_TRUE} ] ;  then
                    f_output "info" "The local file '${i}' was deleted as it was no longer on the remote URI '${TMP_DOWNLOAD_GENERIC_URI}'."
                fi
            fi
        done <<< "${TMP_DOWNLOAD_GENERIC_CRAWL_LOCAL}"
        
        ${CMD_RM} --recursive --force "/tmp/repositorysync.wget" 2> /dev/null
        
         f_output "info" "The sync comparison of URI '${TMP_DOWNLOAD_GENERIC_URI}' for path '${TMP_DOWNLOAD_GENERIC_PATH}' finished."
    else
         f_output "warning" "The command binary 'find' with value '${CMD_FIND}' could not be identified as a valid command binary path or is empty. Skipping local clean for URI '${TMP_DOWNLOAD_GENERIC_URI}' and path '${TMP_DOWNLOAD_GENERIC_PATH}'..."
    fi
}

function f_proxmox_enterprise_config() {
    TMP_PROXMOX_ENTERPRISE_CONFIG_COMMAND=${1}
    TMP_PROXMOX_ENTERPRISE_CONFIG_OPERATION=${2}
    TMP_PROXMOX_ENTERPRISE_CONFIG_OPTIONS=${3}
    
    if [[ ! "${TMP_PROXMOX_ENTERPRISE_CONFIG_COMMAND}" =~ ^(config mirror|key)$ ]] ; then
        f_output "warning" "The command for the Proxmox enterprise config operation needs to be either 'config mirror' or 'key' but is '${TMP_PROXMOX_ENTERPRISE_CONFIG_COMMAND}'. Ignoring operation..."
        return ${TMP_FALSE}
    fi
    
    if [[ ! "${TMP_PROXMOX_ENTERPRISE_CONFIG_OPERATION}" =~ ^(add|add-mirror-key)$ ]] ; then
        f_output "warning" "The command for the Proxmox enterprise config operation needs to be 'add' or 'add-mirror-key' but is '${TMP_PROXMOX_ENTERPRISE_CONFIG_OPERATION}'. Ignoring operation..."
        return ${TMP_FALSE}
    fi
    
    if [ "${TMP_PROXMOX_ENTERPRISE_CONFIG_OPTIONS}x" == "x" ] ; then
        f_output "warning" "The command for the Proxmox enterprise config options can not be empty. Ignoring operation..."
        return ${TMP_FALSE}
    fi
    
    TMP_DOWNLOAD_PROXMOX_ENTERPRISE_RESULT=""

    eval `${CMD_ECHO} "${CMD_PROXMOX_OFFLINE_MIRROR} ${TMP_PROXMOX_ENTERPRISE_CONFIG_COMMAND} ${TMP_PROXMOX_ENTERPRISE_CONFIG_OPERATION} ${TMP_PROXMOX_ENTERPRISE_CONFIG_OPTIONS}"` 2> /dev/null
    TMP_DOWNLOAD_PROXMOX_ENTERPRISE_RESULT=$?

    case "${TMP_DOWNLOAD_PROXMOX_ENTERPRISE_RESULT}" in
        "${TMP_TRUE}")
            return ${TMP_TRUE}
            ;;
        "255")
            if [ "${TMP_PROXMOX_ENTERPRISE_CONFIG_COMMAND}" == "key" ] ; then
                TMP_DOWNLOAD_PROXMOX_ENTERPRISE_RESULT=${TMP_TRUE}
                return ${TMP_TRUE}
            else
                TMP_DOWNLOAD_PROXMOX_ENTERPRISE_RESULT=""
                eval `${CMD_ECHO} "${CMD_PROXMOX_OFFLINE_MIRROR} ${TMP_PROXMOX_ENTERPRISE_CONFIG_COMMAND} update ${TMP_PROXMOX_ENTERPRISE_CONFIG_OPTIONS}"` 2> /dev/null
                TMP_DOWNLOAD_PROXMOX_ENTERPRISE_RESULT=$?
                
                if [ ${TMP_DOWNLOAD_PROXMOX_ENTERPRISE_RESULT} -eq ${TMP_TRUE} ] ; then
                    return ${TMP_TRUE}
                else
                    return ${TMP_FALSE}
                fi
            fi
            ;;
        *)
            TMP_DOWNLOAD_PROXMOX_ENTERPRISE_RESULT=${TMP_FALSE}
            return ${TMP_FALSE}
            ;;
    esac
}

# set version information
VERSION="1.0"

trap f_quit EXIT
trap f_quit SIGQUIT
trap f_quit SIGINT
trap f_quit SIGHUP
trap f_quit SIGTERM

TMP_OPTION="${1}"

f_init

case "${TMP_OPTION}" in
    "help" | "--help" | "-h")
        ${CMD_CLEAR}
        ${CMD_ECHO} -e "Please use one of the following parameter options:\n\n\tdownload | --download | -d\n\thelp | --help | -h\n\tversion | --version | -v\n\n"$( if [ -f ./"1.man" ] ; then ${CMD_ECHO} "For more information use 'man --local-file 1.man." ; fi)
        exit ${TMP_TRUE}
        ;;
    "download" | "--download" | "-d")
        f_download
        ;;
    "version" | "--version" | "-v")
        ${CMD_CLEAR}
        ${CMD_ECHO} -e "repositorysync.sh (Version: ${VERSION})"
        exit ${TMP_TRUE}
        ;;
    *)
        f_output "warning" "Please use one of the following parameter options:\n\t\tdownload | --download | -d\n\thelp | --help | -h\n\tversion | --version | -v"
        ;;
esac

f_output "info" "Ending Script execution."
