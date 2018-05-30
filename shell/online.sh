#!/bin/bash
# steps:
# 1: backup OnLine system
# 2: sync RC to Local and diff
# 3: Local to OnLine system
# 4: restart resin

#echo "封网期间请不要上线,谢谢配合"
#exit 1

source /data/scripts/settings


do_flush_dns() {
    OL_NOW_IP=$1
    log_info "[:: Flush DNS ::] Flushing ${OL_NOW_IP} 's DNS"
        scp -o ConnectTimeout=5  -r -i $SCRIPT_ROOT/key/id_rsa.online $SCRIPT_ROOT/syd.upline/resolv.conf root@${OL_NOW_IP}:/etc/resolv.conf
        scp -o ConnectTimeout=5  -r -i $SCRIPT_ROOT/key/id_rsa.online $SCRIPT_ROOT/syd.upline/hosts.ol root@${OL_NOW_IP}:/etc/hosts
        scp -o ConnectTimeout=5  -r -i $SCRIPT_ROOT/key/id_rsa.online $SCRIPT_ROOT/syd.upline/addlocalhosts.sh root@${OL_NOW_IP}:/opt/
        ssh -o ConnectTimeout=5 -i $SCRIPT_ROOT/key/id_rsa.online root@${OL_NOW_IP} "/opt/addlocalhosts.sh"
        log_info "[:: Flush DNS ::] system tune done! "
}


do_register_upstream(){
        if [ "$1" = "#" ]; then
                return 0
        fi
        S_NAME=$1
        #调用接口注册upstream
        log_info "[:: UPCONF ::]  register upstream ${S_NAME}"
#        curl "http://${MAIN_NGINX}:10001/gen_upstream/${S_NAME}"
#        curl "http://${MAIN_NGINX}:10001/gen_upstream/${S_NAME}"
        IFS=$IFS_ORIG
        for nginx in `cat ${ListFile} | grep "^nginx.s.com" | sed -e 's,[	 ]\+,%,g' | awk -F '%' '{print $4}' `; do
            IFS_TEMP=$IFS; IFS="%";
            log_info "http://${nginx}:10001/gen_upstream/${S_NAME}"
            /usr/bin/curl -s --connect-timeout 2 "http://${nginx}:10001/gen_upstream/${S_NAME}"
        done
}


do_health_check() {
    OL_NOW_IP=$1
    #强制使用ABlist文件里面注册的端口
    OL_PORT=$2
    if [ "$check_header" != "none" ]; then
    log_info "[:: Health Check ::] Checking http://${OL_NOW_IP}:${OL_PORT}$check_path -H Host: $check_header  every ${SLEEP_TIME} sec."
        RunningFlag=""
        COUNT=1
        until [ $( log_info ${RunningFlag} | grep -i -c 'ok' ) -gt 0 ] ;do
            sleep ${SLEEP_TIME}
            RunningFlag=$(/usr/bin/curl -s --connect-timeout 2 "http://${OL_NOW_IP}:${OL_PORT}$check_path" -H "Host: $check_header")
            log_info "CheckingFlag[${COUNT}]  :$RunningFlag: http://${OL_NOW_IP}:${OL_PORT}$check_path -H Host: $check_header"
            COUNT=`expr $COUNT + 1`
            if [ $( log_info ${RunningFlag} | grep -i -c '404' ) -gt 0 ] ; then
                log_info "[:: HealthCheck ::] Resin is not up or config -_-!"
                break
            fi
            if [ $COUNT -eq 12 ] ; then
                log_info " [:: HealthCheck ::] reboot failed, restart resin! "
                [ "${ONLINE_MOD}" == "yes" ] && ssh -i $SCRIPT_ROOT/key/id_rsa.online root@${OL_NOW_IP} "/sbin/service resin restart"  || log_info "testing restart resin ..."
            fi
            if [ $COUNT -eq 24 ] ; then
                log_info " [:: HealthCheck ::] reboot failed again, plz call master!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! "
                break
                # 自动上线，先把代码上去再说
                #exit 1
            fi
        done
        log_info "[:: HealthCheck ::] done, service is up! "
    else
        log_info "[:: HealthCheck ::] disabled!"
    fi
}


do_restart(){
    #name, path, rc.ip, dest.ip, port, healthcheck_host, healthcheck_uri, is_healthcheck
    S_NAME=$1
    S_DIR=$2
    OL_NOW_IP=$4
    OL_PORT=$5
    check_header=$6
    check_path=$7
    is_healthcheck=$8

    if [ "${OL_NOW_IP}" != "" ]; then
        log_info "[:: Restarting ::] ${S_NAME} @ ${OL_NOW_IP}:${S_DIR} ing..."
        [ "${ONLINE_MOD}" == "yes" ] && ssh -i $SCRIPT_ROOT/key/id_rsa.online root@${OL_NOW_IP} "sh ${S_DIR}/restart.sh >/dev/null 2>&1 &"  || log_info "testing reboot..."
        if [ -f "${GIT_ROOT}/syd.scripts/${S_NAME}.sh" ]; then
            log_info "[:: Restarting ::] sync reboot script ${REBOOT_SCRIPT_ROOT}/${S_NAME}.sh @ ${OL_NOW_IP} ing..."
            [ "${ONLINE_MOD}" == "yes" ] && ssh -i $SCRIPT_ROOT/key/id_rsa.online root@${OL_NOW_IP} "mkdir -p ${REBOOT_SCRIPT_ROOT}"  || log_info "testing reboot..."
            [ "${ONLINE_MOD}" == "yes" ] && scp -i $SCRIPT_ROOT/key/id_rsa.online  ${GIT_ROOT}/syd.scripts/${S_NAME}.sh root@${OL_NOW_IP}:${REBOOT_SCRIPT_ROOT}/${S_NAME}.sh  || log_info "testing reboot..."
        else
            log_info "[:: BEEP! ::] script ${REBOOT_SCRIPT_ROOT}/${S_NAME}.sh not exist! "
        fi
        log_info "[:: Restarting ::] ${S_NAME} @ ${OL_NOW_IP} ing... , use ${REBOOT_SCRIPT_ROOT}/${S_NAME}.sh"
        [ "${ONLINE_MOD}" == "yes" ] && ssh -i $SCRIPT_ROOT/key/id_rsa.online root@${OL_NOW_IP} "sh ${REBOOT_SCRIPT_ROOT}/${S_NAME}.sh >/dev/null 2>&1 &"  || log_info "testing reboot..."
        # health check after restart app
        if [ "$is_healthcheck" = "1" ]; then
            do_health_check  ${OL_NOW_IP} ${OL_PORT}
        fi
        log_info "[:: Restarting ::] $check_header@${OL_NOW_IP} ok! go next...."
        log_info '=========================================================================================================='
        log_info ''
    fi
}


do_sync_config() {
        if [ "$1" = "#" ]; then
                return 0
        fi
    S_NAME=$1
    S_DIR=$2
    RC_IP=$3
    log_info "[:: UPCONF ::] ======== SYNC Config Files $1 ========"
    OL_NOW_IP=$4

        if [ ! -d ${GIT_ROOT}/syd.config/${S_NAME} ]; then
            log_info "[:: UPCONF ::] no config file exist in git, ignore"
            return 0
        fi

    if [ "${OL_NOW_IP}" != "" ]; then
        #backup first!
        log_info "[:: UPCONF ::] BACUP OnLine config files ${S_NAME} @ ${OL_NOW_IP} "
        c_backup_dir=${BACKUP_ROOT}/config/${S_NAME}/${NOW}/${OL_NOW_IP}/${S_NAME}
        log_info "[:: UPCONF ::] backup dir is ${c_backup_dir}"
        mkdir -p ${c_backup_dir}
        rm -rf ${c_backup_dir}/*
            # fix uid
            chown hudson ${BACKUP_ROOT}/config/${S_NAME}

        need_sync_config=0
        declare -a ConfigFileList=($(find ${GIT_ROOT}/syd.config/${S_NAME}/ -type f -exec echo {}% \; | tr -d '\n'))        
        for file in "${ConfigFileList[@]}";do
            sys_file=${file#${GIT_ROOT}/syd.config/${S_NAME}}
            log_info "[:: UPCONF ::] BACUP OnLine config files ${sys_file} "
            rsync -avrRPtlq -e "ssh -i $SCRIPT_ROOT/key/id_rsa.online" root@${OL_NOW_IP}:${sys_file} ${c_backup_dir}/
            if [[ `/usr/bin/diff -raN -bB ${c_backup_dir}${sys_file} ${file}` ]] ; then
                log_info "[:: UPCONF ::] ${c_backup_dir}${sys_file} | ${file} not same , need upline config files"
                        log_info "$(/usr/bin/diff -raN -bB ${c_backup_dir}${sys_file} ${file})"
                need_sync_config=1
            fi
        done

        if [ "${ONLINE_MOD}" == "yes" ] && [ "${need_sync_config}" == "1" ]; then
            log_info "[:: UPCONF ::] SYNC Config Files syd.config/${S_NAME} to ${OL_NOW_IP} "
            rsync -avrPtlq -e "ssh -i $SCRIPT_ROOT/key/id_rsa.online"  ${GIT_ROOT}/syd.config/${S_NAME}/ root@${OL_NOW_IP}:/
#            log_info "[:: UPCONF ::] Restart resin service"
#            ssh -i $SCRIPT_ROOT/key/id_rsa.online root@${OL_NOW_IP} "/sbin/service resin stop && sleep 10 && /sbin/service resin start"
            log_info "[:: UPCONF ::] SYNC Config Files DONE!"
        fi        
    fi
    return 0;
}


do_sync() {
        if [ "$1" = "#" ]; then
                return 0
        fi
    S_NAME=$1
    S_DIR=$2
    RC_IP=$3
    log_info "[:: UPLINE ::] ======== SYNC $1 ========"
    OL_NOW_IP=$4

    if [ "${OL_NOW_IP}" != "" ]; then
        #backup first!
        log_info "[:: UPLINE ::] BACUP OnLine SERVER ${S_NAME} @ ${OL_NOW_IP} "
        mkdir -p ${BACKUP_ROOT}/${OnLine}/${S_NAME}/${NOW}/${OL_NOW_IP}/${S_NAME}
        rm -rf ${BACKUP_ROOT}/${OnLine}/${S_NAME}/${NOW}/${OL_NOW_IP}/${S_NAME}/*
        # fix uid
        # chown hudson ${BACKUP_ROOT}/${OnLine}/${S_NAME}

        [ "${ONLINE_MOD}" == "yes" ] && rsync -avrPtlq --exclude='downloads/' --exclude='annex/' -e "ssh -i $SCRIPT_ROOT/key/id_rsa.online" root@${OL_NOW_IP}:${S_DIR}/ ${BACKUP_ROOT}/${OnLine}/${S_NAME}/${NOW}/${OL_NOW_IP}/${S_NAME}/  || log_info "testing backup..."
        #pull RC source
        rm -rf ${TMP_ROOT}/${S_NAME}
        mkdir -p ${TMP_ROOT}/${S_NAME}
        log_info "[:: UPLINE ::] Pull Source from ${S_NAME} @ ${RC_IP} "
        [ "${ONLINE_MOD}" == "yes" ] && rsync -avrPtlq -e "ssh -i $SCRIPT_ROOT/key/id_rsa.online" --delete --delete-after --exclude='downloads/' --exclude='work/' --exclude='.git/' --exclude='annex/' --exclude='upload/' --exclude='www-footer-v2.jsp' --exclude='www-header-v2.jsp' --exclude='access.log*' root@${RC_IP}:${S_DIR}/ ${TMP_ROOT}/${S_NAME}/ || log_info "test mirror rc..."
        # chown hudson -R ${TMP_ROOT}/${S_NAME}
        #sync RC binary to A
        ssh -i $SCRIPT_ROOT/key/id_rsa.online root@${OL_NOW_IP} "mkdir -p ${S_DIR}"
        log_info "[:: UPLINE ::] SYNC ${S_NAME} @ ${RC_IP}  TO ${OL_NOW_IP}"
        [ "${ONLINE_MOD}" == "yes" ] && rsync -avrPtl  -e "ssh -i $SCRIPT_ROOT/key/id_rsa.online" --delete --delete-after --exclude='upload/' --exclude='text/' --exclude='.git/' --exclude='codeset-obj.js' --exclude='codeset.js' --exclude='downloads/'  --exclude='download/' --exclude='annex/' --exclude='access.log*' ${TMP_ROOT}/${S_NAME}/ root@${OL_NOW_IP}:${S_DIR}/  --exclude='mossle.store/' --exclude='www-footer-v2.jsp' --exclude='www-header-v2.jsp'  || log_info "testing upline..."
        log_info "[:: UPLINE ::] CHOWN resin:resin ${OL_NOW_IP}:${S_DIR}"
        [ "${ONLINE_MOD}" == "yes" ] && ssh -i $SCRIPT_ROOT/key/id_rsa.online root@${OL_NOW_IP} "chown -R resin.resin ${S_DIR}"  || log_info "testing chown..."
        #do flush dns
        log_info "[:: UPLINE ::] Flush DNS ${OL_NOW_IP}"
        [ "${ONLINE_MOD}" == "yes" ] && do_flush_dns ${OL_NOW_IP} || log_info "testing Flush DNS..."
            # clean tmp //keep for quick upload
            # rm -rf ${TMP_ROOT}/${S_NAME}
    fi
    return 0;
}


#__main()__

# new AB.list
# name, path, rc.ip, dest.ip, port, healthcheck_host, healthcheck_uri, is_healthcheck
log_info ''
log_info '[::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::]'
log_info "[:: BUILD_ID ::] ${NOW}"
log_info '[::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::]'
# cat /etc/issue
# log_info '[::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::]'

ARGV=("$@")

key=${ARGV[0]}

IFS_ORIG=$IFS

for i in `cat ${ListFile} | grep "^${key}" | sed -e 's,[	 ]\+,%,g'`; do 
    IFS_TEMP=$IFS; IFS="%";
    
    do_sync $i || log_info "Bad line(input): $i";
    do_sync_config $i || log_info "Bad line(input): $i";
    log_info ''
    do_restart $i || log_info "Bad line(input): $i";
done 
    IFS=$IFS_TEMP
#for register upstream and else
for i in `cat ${ListFile} | grep "^${key}" | sed -e 's,[	 ]\+,%,g' | awk -F '%' '{print $1}' | sort | uniq `; do 
    IFS_TEMP=$IFS; IFS="%";
    do_register_upstream $i || log_info "Bad line(input): $i";
done 
