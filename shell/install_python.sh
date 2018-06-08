#!/bin/bash
#-------------------------------
#   Author: ChunXiao
#   Version: 1.0
#   Description: Install python
#   Coryright @ 2018
#-------------------------------

source /opt/code/shell/settings

function log_info() {
    echo "$*"
    printf "%s --> %s\n" "$(date +%Y-%m-%d-%T)" "$*" 
}


function init_env() {
    if [[ ! -d ${_SOFTWARE_DIR} ]]; then
        mkdir -p ${_SOFTWARE_DIR}
    fi

    if [[ ! -d ${_BUILD_DIR} ]]; then
        mkdir -p ${_BUILD_DIR}
    fi
}


function download_package() {
    _PKG=$1
    _RENAME=$2

    if [[ ! -f ${_SOFTWARE_DIR}/${_PKG} ]]; then
        cd ${_SOFTWARE_DIR}
        wget -c ${_PKG} -O ${_RENAME} 
    fi
}


function unpack_pkg() {
    _NAME=$1
    
    cd ${_SOFTWARE_DIR}
    declare -A _ARRAY
    _ARRAY[tar]="tar xf pkg -C ${_BUILD_DIR}"
    _ARRAY[zip]="unzip pkg -d ${_BUILD_DIR}"

    _KEY=$(echo ${_NAME} | awk -F"[.-]" '{print $1}')
    _RETURNVAL=$(ls ${_BUILD_DIR} | grep -i ${_KEY} | grep -v grep | wc -l)
    [ ${_RETURNVAL} -gt 0 ] && [ $? -eq 0 ] && rm -rf ${_BUILD_DIR}/*
    for i in "${!_ARRAY[@]}"   
    do   
        ls ${_NAME} | grep -v grep | grep -i $i
        if [[ $? -eq 0 ]]; then
            _UNPACK_CMD=${_ARRAY[$i]//pkg/${_NAME}}
            ${_UNPACK_CMD}
        fi
    done  
}


function install_python() {
    cd ${_BUILD_DIR}
    _RETURNVAL=$(ls | grep -i python | grep -v grep)
    if [[ $? -eq 0 ]]; then
        if [[ ! -d /usr/local/python${_VERSION} ]]; then
            cd ${_RETURNVAL}
            ./configure --prefix=/usr/local/python${_VERSION} --enable-shared --with-ensurepip --enable-loadable-sqlite-extensions
            make && make install
            echo /usr/local/python3.6/lib > /etc/ld.so.conf.d/python-3.6.conf && ldconfig
        fi
    fi
}  


function install_setuptools() {
    cd ${_BUILD_DIR}
    _RETURNVAL=$(ls | grep -i setuptools | grep -v grep)
    if [[ $? -eq 0 ]]; then
        if [[ ! -d /usr/local/python${_VERSION} ]]; then
           cd ${_RETURNVAL}
           /usr/local/python${_VERSION}/bin/python${_VERSION} setup.py build
           /usr/local/python${_VERSION}/bin/python${_VERSION} setup.py install 
          # cat << EOF > /usr/local/python${_VERSION}/bin/python${_VERSION}/distutils/distutils.cfg
          # [easy_install]
          # index-url= http://pypi.doubanio.com/simple/
          # EOF
        fi
    fi       
}


#RGV=("$@")
#_VERSION=${ARGV[0]}
_VERSION=$1

init_env
download_package ${_PY_3_SOURCE_RELEASE_URL} ${_PY_3_RENAME} 
download_package ${_SETUPTOOLS_3_SOURCE_RELEASE_URL} ${_SETUPTOOLS_3_RENAME}
unpack_pkg ${_PY_3_RENAME}
unpack_pkg ${_SETUPTOOLS_3_RENAME}
install_python
install_setuptools
