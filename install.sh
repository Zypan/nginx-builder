#!/bin/bash

. config.sh
. app/nginx_modules.sh
. app/libs.sh
. app/colors.sh


declare -A DOOPT

declare -A OPTIONS_DO=( 
    ['--full']="Install server and clean existing repos" 
    ['--clean']="Clean local files" 
    ['--compile']="Compile from existing directories" 
    ['--deps']="Only dependencies" 
    ['--down']="Only download modules" 
)
declare -A OPTIONS_TYPE=( 
    ['--simple']="Simple web server with perfromance modules and standard configuration"
    ['--simple_ssl']="Simple web server but with extra SSL features"
    ['--steroids']="Nginx, Lua, Lua Scripts, JWT, Imagemagik, Compression"
)


show_yellow "Test" "system variables and paths"
if [ -z ${ROOT+x} ];  then show_red "Error" "ROOT system variable is not set! Check config.sh";  exit 1; fi
if [ -z ${CACHE+x} ]; then show_red "Error" "CACHE system variable is not set! Check config.sh"; exit 1; fi
if [ -z ${BUILD+x} ]; then show_red "Error" "BUILD system variable is not set! Check config.sh"; exit 1; fi
show_green "OK"

###############################################
###############################################
###############################################
# run as root only
if [[ $EUID -ne 0 ]] ; then
    run_error "This script must be run with root access\e[49m"
    exit 1
fi
[ $# -eq 0 ] && { 
    show_title "   What are we building?  "
    for i in ${!OPTIONS_DO[*]}
    do 
        echo -e "\e[1;39m[ \e[1;46m${i}\e[49m ] ${OPTIONS_DO[${i}]}\e[0;39m"
    done
    show_title "   How are we building?  "
    for i in ${!OPTIONS_TYPE[*]}
    do 
        echo -e "\e[1;39m[ \e[1;46m${i}\e[49m ] ${OPTIONS_TYPE[${i}]}\e[0;39m"
    done
    echo -e "\e[1;39m----------------------------\e[0;39m"
    exit 1; 
}
DOOPT=${1}
DOTYPE=${2}


[ -d "$ROOT" ] || mkdir $ROOT
[ -d "$CACHE" ] || mkdir $CACHE
[ -d "$BUILD" ] || mkdir $BUILD


function deps() {
    local -A DEPS_INSTALL="build-essential build-dep libpcre3 libpcre3-dev libpng-dev zlib1g-dev libssl-dev openssl git autoconf libtool tar unzip automake xutils-dev"
    # Install Deps
    show_yellow "Check" "system dependencies"
    ## 
    git --version >/dev/null 2>&1 || { 
        DEPS_INSTALL="${DEPS_INSTALL} git"
    }
    python2.7 -V >/dev/null 2>&1 || {
        DEPS_INSTALL="${DEPS_INSTALL} python2.7 python2.7-dev"
    }
    # Install
    apt-get install ${DEPS_INSTALL}

    # Install: LuaJIT, PCRE, ZLIB, OpenSSL :: mandatory
    ./app/installers/luajit.sh ${VERSION['luajit']}
    ./app/installers/pcre.sh ${VERSION['pcre']}
    ./app/installers/zlib.sh ${VERSION['zlib']}
    ./app/installers/openssl.sh ${VERSION['openssl']}
}
function download() {
    # Download: nginx source
    ./app/installers/nginx.sh ${VERSION['nginx']} DEBUG
    # Clean: modules to fetch them again from cache
    rm -rf ${ROOT}nginx_modules/*
    # Download: ngnx modules
    for i in ${NGINX_INSTALL_MODULES[*]}
    do 
       download_nginx_module $i
    done
}
function configure() {
    # Unzip: nginx
    # Configure || Make: nginx modules     
    for i in ${NGINX_INSTALL_MODULES[*]}
    do 
        configure_nginx_module $i
    done
}
function compile() {
    # Configur nginx
    make_nginx "$DEFAULT_CONFIGURE_PARAMS $NGINX_CONFIGURE_PARAMS"
}




# Loading functions
show_blue "Loading" "local libraries and preparing scrips"
sleep 1


###############################################################
case $DOTYPE in
    "--simple")
        show_blue "Install" "${OPTIONS_TYPE[${DOTYPE}]}"
        sleep 1
            # Define: other dependencies to install because of these modules || NOT USED FOR NOW
            NGINX_INSTALL_DEPS=("")
            # Define: modules to install
            NGINX_INSTALL_MODULES=(
                "ngx_headers_more" "ngx_encrypted_session" "ngx_devel_kit" "ngx_mod_zip" 
                "ngx_xss" "ngx_echo" "ngx_http_sysguard" "ngx_clojure" "ngx_memc" "ngx_lua" "ngx_pagespeed"
            )
            NGINX_INSTALL_LIBS=("lua_resty_http" "lua_resty_memcached" "lua_resty_jwt")
            # Nginx: params
            NGINX_CONFIGURE_PARAMS="--without-http_ssl_module"
        ;;
    "--simple_ssl")
            show_blue "Install" "${OPTIONS_TYPE[${DOTYPE}]}"
            sleep 1
            # Define: other dependencies to install because of these modules
            NGINX_INSTALL_DEPS=("brotli")
            # Define: modules to install
            NGINX_INSTALL_MODULES=(
                "ngx_headers_more" "ngx_encrypted_session" "ngx_devel_kit" "ngx_brotli" "ngx_mod_zip" 
                "ngx_xss" "ngx_echo" "ngx_http_sysguard" "ngx_clojure" "ngx_memc" "ngx_lua" "ngx_pagespeed"
            )
            NGINX_INSTALL_LIBS=("lua_resty_http" "lua_resty_memcached" "lua_resty_jwt")
            # Nginx: params
            NGINX_CONFIGURE_PARAMS="--with-http_ssl_module  --with-http_v2_module --with-google_perftools_module"
        ;;
    "--steroids")
        show_blue "Compiling" "${OPTIONS_TYPE[${DOTYPE}]}"
        sleep 1

        # everything works here!!!!!! 
            
            # Define: other dependencies to install because of these modules
            #NGINX_INSTALL_DEPS=("brotli")
            # Define: modules to install
            NGINX_INSTALL_MODULES=(
                "ngx_headers_more" "ngx_encrypted_session" "ngx_devel_kit" "ngx_mod_zip" 
                "ngx_xss" "ngx_echo" "ngx_clojure" "ngx_memc" "ngx_lua" "ngx_pagespeed" #"ngx_http_sysguard" 
            )
            NGINX_INSTALL_LIBS=("lua_resty_http" "lua_resty_memcached" "lua_resty_jwt")
            NGINX_CONFIGURE_PARAMS="--with-threads --with-file-aio --with-stream_ssl_module --with-http_ssl_module  --with-http_v2_module --with-google_perftools_module"
        ;;
    *)
        ./install.sh
        show_red "Error" "$DOTYPE is unknown. Look at option list"
        exit 1;
esac
###############################################################
case $DOOPT in
    "--full_clean")
            show_blue "Install" "${OPTIONS_DO[${DOOPT}]}"
            sleep 1
            clean
            deps
            download
            configure
            compile
        ;;
    "--full")
            show_blue "Install" "${OPTIONS_DO[${DOOPT}]}"
            sleep 1
            deps
            download
            configure
            compile
        ;;
    "--compile")
            show_blue "Compiling" "${OPTIONS_DO[${DOOPT}]}"
            sleep 1
            download
            configure       
            compile
        ;;
    "--deps")
            show_blue "Fetching" "${OPTIONS_DO[${DOOPT}]}"
            sleep 1
            deps
        ;;
    "--down")
            show_blue "Downloading" "${OPTIONS_DO[${DOOPT}]}"
            sleep 2
            download
        ;;
    "--clean")
        show_red "Deleting" "${OPTIONS_DO[${DOOPT}]}"
        sleep 1
        clean
    ;;
    *)
        ./install.sh
        show_red "Error" "$DOOPT is unknown. Look at option list"
        exit 1;
esac






