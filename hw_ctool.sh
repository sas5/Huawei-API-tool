#!/bin/bash
GW=192.168.8.1
_url="http://$GW"
password="${1}"
api_out_post='log/api_POST'
api_out='log/api_GET'
api_out_post_hd='log/api_POST.header'
api_out_hd='log/api_GET.header'
api_cookies='log/ipCookies'
_ting_me='....'
_logger="log/Logger"
[[ ! -d log ]] && mkdir log

UsrAg='Kids/1.0 (MyMind 3000; Win64 + win32 + linux 1964; x64 + x32 + armf) Chrome||firefox/22.22.12.12 killer/000.09 TESTER/23.23.21.21'

declare -A Band_num=(
                [1]="2100" 
                [2]="1900" 
                [3]="1800"
                [4]="1700" 
                [5]="850"  
                [7]="2600"
                [8]="900"  
                [11]="1500"
                [12]="700"
                [13]="700" 
                [17]="700" 
                [19]="850"
                [20]="800" 
                [26]="850" 
                [28]="700"
                [32]="1500"
                [38]="2600"
                [40]="2300"
                [41]="2500"
                [43]="3700"
                [44]="700"
                [98]="Multi bands"
                [99]="AUTO"
)


## path: '/api/device/signal'
Network_info=(
            "pci"
            "cell_id"
            "rsrq"
            "rsrp"
            "rssi"
            "sinr"
            "band"
            "plmn"
            "lteulfreq"
            "ltedlfreq"
            "earfcn"
            "nei_cellid"
)

Network_info_names=(
            "pci"
            "Cell id"
            "Rsrq"
            "Rsrp"
            "Rssi"
            "Sinr"
            "Band"
            "Plmn"
            "lte_Ul_freq"
            "lte_Dl_freq"
            "Earfcn"
            "Cells"
)


Lerror() {
    printf '\e[0m[x] \e[90m[%s]\e[0m \e[91m%-1s \e[0m\n' "$(date +"%T")" "${1}" && return 0
}

Linfo() {
    printf '\e[0m[+] \e[90m[%s]\e[0m \e[93m%-1s \e[0m\n' "$(date +"%T")" "${1}" && return 0
}

Ldone() {
    printf '\e[0m[+] \e[90m[%s]\e[0m \e[92m%-1s \e[0m\n' "$(date +"%T")" "${1}" && return 0
}

Lwar() {
    printf '\e[0m[!] \e[90m[%s]\e[0m \e[95m%-1s \e[0m\n' "$(date +"%T")" "${1}" && return 0
}

Ldone_txtvalue() {
    printf '\e[0m[+] \e[90m[%s]\e[0m \e[36m%-1s \e[92m%-1s \e[0m\n' "$(date +"%T")" "${1}" "${2}" && return 0
}

Lerror_txtvalue() {
    printf '\e[0m[!] \e[90m[%s]\e[0m \e[36m%-1s \e[91m%-1s \e[0m\n' "$(date +"%T")" "${1}" "${2}" && return 0
}

Lwar_txtvalue() {
    printf '\e[0m[!] \e[90m[%s]\e[0m \e[95m%-1s \e[33m%-1s \e[0m\n' "$(date +"%T")" "${1}" "${2}" && return 0
}


Lwar_noline() {
    printf '[^] \e[90m[%s]\e[0m \e[92m%-20s %-1s \e[0m\r' "$(date +"%T")" "${1}" "${2}" && return 0
}

Ldar_noline() {
    printf '\r[!] \e[90m[%s]\e[0m \e[90m%-20s %-1s \e[0m\r' "$(date +"%T")" "${1}" "${2}" && return 0
}

_api_get() {
    local _times=0
    local _path="${1}"
    [[ ${_path:0:1} == '/' ]] && _path="${_path:1}"

    while [[ ${_times} -le 3 ]]; do
        
        curl -s "${_url}/${_path}" \
            -A "${UsrAg}" \
            -o "${api_out}" \
            -D "${api_out_hd}" \
            -b "${api_cookies}" \
            -c "${api_cookies}" \
            -b "${api_cookies}" \
            -c "${api_cookies}" \
            -H 'Accept: */*' \
            -H 'Connection: keep-alive'
    
        if grep -q 'HTTP/1.1 200 OK' "${api_out_hd}"; then
            if _is_there_error "${2}"; then 
                return 0
            else
                return 1
            fi
        fi

        Linfo "Sending Request Again"
        ((_times+=1))
    done

    Lerror "Cannot [GET ${_url}/${_path}]"
    return 1
}

_api_send() {
    local _times=0
    local _path="${1}"
    local _Data="${2}"
    [[ ${_path:0:1} == '/' ]] && _path="${_path:1}"
    [[ -z ${_Data} ]] && Lerror "Cannot [POST ${_path}] -> Data is null" && return 1
    [[ -z ${_path} ]] && Lerror "Cannot [POST ${_path}] -> no path" && return 1
    [[ -z ${Token} ]] && _token_get
    [[ -z ${Token} ]] && Lerror "No Token no POST" && return 1
    
    # Ldone "${_path}"
    while [[ ${_times} -le 2 ]]; do

        curl -s "${_url}/${_path}" \
            -D "${api_out_post_hd}" \
            -o "${api_out_post}" \
            -A "${UA}" \
            -b "${api_cookies}" \
            -c "${api_cookies}" \
            -H "Accept: */*" \
            -H "Connection: keep-alive" \
            -H "Content-Type: application/xml" \
            -H "__RequestVerificationToken: $Token" \
            -X POST \
            --data "<?xml version=\"1.0\" encoding=\"UTF-8\" ?><request>${_Data}</request>" \
            -v &>> log/api.Log


        if grep -q 'HTTP/1.1 200 OK' "${api_out_post_hd}"; then
            Linfo "HTTP/1.1 200 OK ${_path}"
            if _request_post_checker; then 
                Ldone "POST Success [ ${_path} ]"
                return 0
            else
                _check_loin_info && _token_get || return 1
                ((_times+=2))
                Linfo "Request is falied sending again"
            fi
        fi
        

    done
    Lerror "Can't send [POST] to [${_path}] data: [${_Data:0:13}...]"
    return 1
}

_is_there_error() {
    if grep -q '<error>' "${api_out}"; then 
        _Get_error_level
        return 1
    elif [[ "${1}" == '0' ]]; then
        cat ${api_out} && return 0
    else
        return 0
    fi
}

_request_post_checker() {
    if grep -q '<response>OK</response>' "${api_out_post}" ; then
        Token=$(grep '__RequestVerificationToken' < "${api_out_post_hd}" |  tr -d '\r' | awk '{print $2}' )
        return 0
    else
        _Get_error_level
        Linfo 'Checking again...'
        return 1
    fi
}

_xml_parse() {
    local _var="${1}"
    [[ -z ${2} ]] && _otpt=${api_out} || _otpt=${api_POST}
    grep -q "${_var}" ${_otpt} || return 1
    grep -o "<${_var}>.*</${_var}>" "${_otpt}" | sed "s/\(<${_var}>\|<\/${_var}>\)//g"
    return 0
}

_xml_parse_get() {
    local _var="${1}"
    _api_get "${2}" || { Lerror "${FUNCNAME}: api error"; return 1; }    
    grep -q "${_var}" ${api_out} || return 1
    grep -o "<${_var}>.*</${_var}>" "${api_out}" | sed "s/\(<${_var}>\|<\/${_var}>\)//g"
    return 0
}

_Get_error_level() {
    local code=`_xml_parse "code" `
    
    ## system
    ers[100002]="ERROR_SYSTEM_NO_SUPPORT"
    ers[100003]="ERROR_SYSTEM_NO_RIGHTS"
    ers[100004]="ERROR_SYSTEM_BUSY"
    ers[120001]="ERROR_VOICE_BUSY"
    ers[125001]="ERROR_WRONG_TOKEN"
    ers[125002]="ERROR_WRONG_SESSION"
    ers[125003]="ERROR_WRONG_SESSION_TOKEN"
    
    ## login
    ers[108003]="ERROR_LOGIN_ALREADY_LOGIN";
    ers[108005]="ERROR_LOGIN_TOOMANY_LOGIN";
    ers[108006]="ERROR_LOGIN_USERNAME_PWD_WRONG";
    ers[108007]="ERROR_LOGIN_USERNAME_PWD_ORERRUN";
    ers[108009]="ERROR_LOGIN_IN_DEFFERENT_DEVICES";
    ers[108010]="ERROR_LOGIN_FREQUENTLY_LOGIN";

    case ${code} in
                100002) ### System
                    Lerror "ERROR [$code]: ${ers[$code]}" 
                    return 1

	            ;;
                100004)
                    Lerror "ERROR [$code]: ${ers[$code]}" 
                    return 1

	            ;;
                120001)
                    Lerror "ERROR [$code]: ${ers[$code]}" 
                    return 1

	            ;;
                125001)
                    Lerror "ERROR [$code]: ${ers[$code]}" 
                    _check_loin_info
                    return $?

	            ;;
                125003|125002|100003)
                    Lerror "ERROR [$code]: ${ers[$code]}"
                    Linfo "Trying to fix this... [log in again]"
                    _Logg_in || Lerror 'Error'
                    return 1
	            ;;
                108003|108005|108009|108010) ### login

                    Lerror "ERROR [$code]: ${ers[$code]}" 
                    return 1
                ;;
                108006)
                    Lerror "ERROR [$code]: ${ers[$code]}" 
                    Linfo "Password is wrong" 
                    return 1

	            ;;
                108007)
                    Lerror "ERROR [$code]: ${ers[$code]}" 
                    Linfo "Incorrect password was entered too many times."
                    _wait_time=$(_xml_parse 'waittime' 0)
                    _Timer "${_wait_time}"
                    Linfo "You can login now"
                    Lwar "Woud you like to Login again with the same password--"
                    if _ask_Yn "--Or change password" ; then
                        _user_input "Enter your router password !"
                        password=${_user_var}
                    fi
                    _Logg_in
                    return $?
                ;;
                *)
                    Lerror "Unknow ERROR [$code]:  ${ers[$code]}" 
                    Linfo "Trying to fix this... [by login again]"
                    # _Logg_in
                    Lerror 'Error'
                    return 1
            esac
}

_user_input() {
    local msg=${1}
    Ldone "${msg}"
    printf '> '
    read _user_var
    return 0
}

_ask_Yn() {
    local _msg=${1}
    Lwar "${1} ?  [Y/n]"
    printf '> '

    read Q

    printf '\n'
    
    case ${Q} in
        Y|y)
            return 0
    	;;

        *)
            return 1
        ;;
    esac
}

_token_get() {
    Linfo "GET Token"
    Token=$(_xml_parse_get 'token' 'api/webserver/token')    
    [[ -z $Token ]] && return 1 || return 0
}

_token_for_login_get() {
    rm -rf "${api_cookies}"
    sleep 0.2
    Linfo "GET token"
    Token=$(_xml_parse_get 'TokInfo' 'api/webserver/SesTokInfo')    
    Token=$(_xml_parse_get 'TokInfo' 'api/webserver/SesTokInfo')    
    [[ -z $Token ]] && return 1 || return 0
}

_check_loin_info() { 
    if [[ $(_xml_parse_get 'State' '/api/user/state-login' ) -eq 0 ]] ; then
        _token_get || return 1
        return 0
    fi
    return 1
}

_Timer() {
    local _s=`awk "BEGIN {print (${1}*60)}"`
    
    while (( _s != -1 )) ;do
        awk "BEGIN {
            (\"date +%T\" )| getline dt
            if ( $((_s/60)) >= 1 ) 
                printf \"\033[0m[!] \033[90m[%s]\033[0m \033[33m %02d m %02d s \r\" , dt, ($_s/60), ($_s%60)
            else
                printf \"\033[0m[!] \033[90m[%s]\033[0m \033[33m%02d s         \r\" , dt, $_s, "$((_s%60))"
        }"
        ((_s-=1))
        sleep 1
    done
    return 0
}

_Logg_in() {
    local _times=0
    local user='admin'
    [[ -z "${password}" ]] && password='admin' ## passaowrd
    _token_for_login_get
    # while ! grep -q 'SessionID' < <(sed 1,3d log/ipCookies); do 
    #     Linfo "Wait"
    #     [[ ${_times} == 3 ]] && Lerror "No cookies" && return 1
    # done 
    Linfo "Encript password"
    Encpass=$(echo -n "$user$(echo -n $password | openssl dgst -sha256 | awk '{print $2}' | base64 -w0 | cut -b 1-86 | tr -d '\n'; echo -n ==)$Token" | openssl dgst -sha256 | awk '{print $2}' | base64 -w0 | cut -b 1-86 | tr -d '\n'; echo -n ==)
    
    _api_send 'api/user/login' \
        "<Username>$user</Username><Password>$Encpass</Password><password_type>4</password_type>" || return 1
    
    return 0
}

detect_band() {
    LTEBand=$(_xml_parse_get 'band' '/api/device/signal')

    [[ -z "${LTEBand}" ]] && Lerror "LTEBand is null :(" && return 1
    
    Band="${Band_num[$LTEBand]}"
    [[ -z ${Band} ]] || return 0

    Band="$LTEBand - ?"
    Lerror 'Unable to detect Band'
    return 1
}

_Set_band() {
    local _times=0
    

    # # Linfo "Change from [ ${Band} {$LTEBand} ] to  [ ${Band_num[$random]} {$random} ]"
    while [[ ${_times} -le 3 ]] ; do
        Linfo "Band [ ${Band} ] --> [ ${Band_num[${_Band_is}]} ]"
        Linfo 'Waiting...'

        _api_send '/api/net/net-mode' \
            "<NetworkMode>00</NetworkMode><NetworkBand>3FFFFFFF</NetworkBand><LTEBand>${_code}</LTEBand>"
        if [[ $? == 0 ]]; then

            return 0
        fi

        Lerror "${FUNCNAME} Something went worng"
        Lerror "[resend again [$_times]]"
        sleep 0.2
        ((_times+=1))
    done

    return 1
}

_get_code() {
    _Band_is=${1}
    [[ -z ${_Band_is} ]] && _Band_is=99
    _code=''

    case ${_Band_is} in
        1)
            _code='1'                   # 2100  MHz
        ;;
        3)
            _code='4'                   # 1800  MHz
        ;;
        28)
            _code='8000000'             # 700   MHz
        ;;
        40)
            _code='8000000000'          # 2300  MHz
        ;;
        98)
            _code='180080800c5'         # choose one of the above bands only 
        ;;
        99)
            _code='7FFFFFFFFFFFFFFF'    # Auto  * 
        ;;
        *)
            Lerror "This band is not in the list ${_Band_is}"
            Linfo "Returned to AUTO"
            _code='7FFFFFFFFFFFFFFF'    # Auto  * 
        ;;
    esac
    
    [[ -z ${_code} ]] && return 1 # :)
    
    return 0 
}

_random_Band() {
    local random=''
    local CrtBands=(1 3 28 40 99) ## common bands ^_*
    detect_band
    
    while : ; do
        random=${CrtBands[$((RANDOM % 5))]}
        
        [[ -n "${_Band_is}" ]] && [[ ${Band_num[${_Band_is}]} == "${Band_num[${random}]}" ]] && echo same && continue
        [[ ${Band_num[$random]} != ${Band} ]] && break || continue
    done

    _get_code "${random}"
    Linfo "Randomly chosen [${_Band_is}-[${Band_num[${_Band_is}]}]]"
    _Set_band && return 0 || return 1
}

_get_cell_id(){
    local c_id
    [[ -z ${1} ]] && c_id='3329349' || c_id="${1}"
    cell_id=$(_xml_parse_get 'cell_id' '/api/device/signal')
    grep -q "${c_id}" <<< ${_cell_id} && return 0 || return 1
}

_band_must_be() {
    local H_band
    [[ -z "${1}" ]] && H_band='2300' || H_band="${1}"
    detect_band
    grep -q "${H_band}" <<< ${Band} && return 0 || return 1
}

_Change_band() {
    local _Band
    local Q=''

    detect_band

    Lwar "...................."
    Lwar "0- Back to main menu"
    Lwar "1- B1   [2100 MHz]"
    Lwar "2- B3   [1800 MHz]"
    Lwar "3- B28  [700  MHz]"
    Lwar "4- B40  [2300 MHz]"
    Lwar "5- Auto           "
    Lwar "...................."

    while : ; do
        _user_input "Choose band of the following ?"
        case ${_user_var} in
            0)
                Linfo "back to main menu"
                return 0
                break
            ;;
            1)
                _Band='1'
                break
            ;;
            2)
                _Band="3"
                break
            ;;
            3)
                _Band="28"
                break
            ;;
            4)
                _Band="40"
                break
            ;;
            5)
                _Band="99"
                break
            ;;
            6)
                _Band="98" ## some times it's good idk why !?
                break
            ;;
            *)
                Lerror "Out of list"
            ;;
        esac
    done

    _get_code "${_Band}"

    if _Set_band ; then
        Ldone "Success change to ${Band_num[${_Band_is}]}"
        return 0
    else
        Lerror "Unable to change band"
        return 1
    fi
}

_cleaning() {
        clear -x
        stty echo
        Linfo 'Cleaning...'
        Ldone 'done'
        exit 0
}

check_socialM() {
    Linfo 'Conneceting to social media' 
    
    curl -s -m 10 --connect-time 10 'https://www.instagram.com/web/__mid/' \
    -A "${UA}" &>/dev/null
    
    if [[ "$?" == 0 ]]; then Ldone 'Success' ; return 0; fi
    
    Lerror "Unable to connect to web site"
    return 1
}

_wan_address() {
    _wan=''
    _wan=$(_xml_parse_get 'WanIPAddress' '/api/device/information')
    [[ -z ${_wan} ]] && return 1 || return 0
}

_heart_beat() {
        _heart_beat=$(_xml_parse_get 'userlevel' 'api/user/heartbeat')

}

_unit_converter() {
    [[ -z ${1} ]] && return 1
    Units=("byte" "KB" "MB" "GB" "TB");
    local U=0           #unit
    local _Num=${1}     #value

    while (( ${_Num} >= 1024 && ${U} <= 4 )); do 
        _Num=$((${_Num}/1024));
        ((U+=1))
    done

    printf '%-8s %s' "$(awk "BEGIN {printf \"%0.$((U))f\", ((${1}/(1024^${U})))}")" "${Units[${U}]}"
    return 0
} 


row() {
    local COL
    local ROW
    IFS=';' read -sdR -p $'\E[6n' ROW COL
    echo "${ROW#*[}"
}


_show_data_usg() {
    local _s=0
    local _traffic_statics=()
    local _ts_values
    _traffic_statics=('CurrentUploadRate' 'CurrentDownloadRate' 'TotalUpload' 'TotalDownload')
    _choice=''

    if [[ "$(row)" -ge 25 ]]; then clear -x; fi
    clear -x
    Lerror '\n___________________________\n'
    Lwar 'Click 0 to back to main menu'
    Lwar 'to remove this info click C'
    Lerror '\n___________________________\n'
    sleep 1

    printf '\033[s' # save corser location
    printf '\r
 #           Total             Rate         
 ---------------------------------------    
 Up                                         
 Down                                       \n'
    stty -echo
    while : ; do
        _api_get '/api/monitoring/traffic-statistics'
        printf '\033[u\n'

        for i in ${!_traffic_statics[*]}; do
            _ts_values[$i]="$(_xml_parse "${_traffic_statics[${i}]}")"
        done

        ## just for fun, keep your suggestion there :)
        for i in ${!_traffic_statics[*]}; do
            _ts_values[$i]=$(_unit_converter "${_ts_values[$i]}")
        done
        
        printf '\r\e[2A\n\n\n\n\t %-18s %13s  \n\t %-18s %13s  ' \
                "${_ts_values[2]}" "${_ts_values[0]}" \
                "${_ts_values[3]}" "${_ts_values[1]}" 
        # awk "BEGIN { printf \"\t\t %-15s %s\n \t\t %-15s %s\n\", \"${_ts_values[0]::-3}\", \"${_ts_values[1]}\", \"${_ts_values[2]::-3}\", \"${_ts_values[3]}\" ; }"
        
        
        read -n1 -t0.1 _choice 2> /dev/null 
        if [[ -n ${_choice} ]]; then
            if [[ ${_choice} == 0  ]]; then
                clear -x
                stty echo

                return 0
            elif [[ ${_choice} == @(C|c)  ]]; then
                sleep 0.5
                clear -x
                printf '\033[s' # save corser location
                printf '\n
 #           Total             Rate         
 ---------------------------------------    
 Up                                         
 Down                                       \n'
                continue
    
            elif [[ ${_choice} == @(I|i)  ]]; then
                printf '\n\n\n\n\n\n' 
                [[ -z ${_wan} ]] && _check_wan 1 || Lwar_noline "WAN IP: ${_wan}     "
            elif [[ ${_choice} == @(S|s)  ]]; then
                printf '\r\n\n\n\n\n\n\n\n' 
                Lerror "sleeping 3 s"                
                sleep 3
            else
                printf '\n\n\n\n\n\n\n' 
                Lerror "${_choice} Unknow entry"                
            fi
        fi
    sleep 0.4
    done

    printf '\033[u \n\n\n\n\n\n'
}

_mobile_data_get() {
    M_data=$(_xml_parse_get 'dataswitch' "/api/dialup/mobile-dataswitch")
    if [[ ${M_data} == 0 ]]; then
        return 1
    elif [[ ${M_data} == 1 ]]; then
        return 0
    else
        return 2
    fi
} 

_mobile_data_set() {
    M_data=$(_xml_parse_get 'dataswitch' "/api/dialup/mobile-dataswitch")
    if [[ ${M_data} == 0 ]]; then
        Ldone "Turning on Mobile data"
        _api_send '/api/dialup/mobile-dataswitch' '<dataswitch>1</dataswitch>' && Ldone "Success Turning on Mobile data" || Lerror "Unable to send data to router"
        return 1
    elif [[ ${M_data} == 1 ]]; then
        Ldone "Turning off Mobile data"
        _api_send '/api/dialup/mobile-dataswitch' '<dataswitch>0</dataswitch>' && Ldone "Success Turning off Mobile data" || Lerror "Unable to send data to router"
        return 0
    else
        Lerror "Something went wrong"
        return 2
    fi
} 

_check_wan() {
    local _s=0
    _wan_address
    while [[ ${_times} -le 12 ]] ; do 
        [[ -n $_wan ]] && break
        _wan_address
        Lwar_noline "Collecting info${_ting_me:0:$_s}" ' '
        ((_times+=1))
        [[ ${_s} -lt 5 ]] && ((_s+=1)) || _s=0 
    done

    # && Linfo "The router is not connected to any cell" ||
    
    [[ -z ${1} ]] && [[ -n ${_wan} ]] && Ldone_txtvalue "Current WAN-IP: " "$_wan" 
}

_check_login() {
    if ! _check_loin_info ; then
	    if ! _Logg_in; then
            Lerror 'Unable to Login to Router'
        	return 1
	    fi
    else
        Linfo "Session restored"
        Linfo "Already loged in"
    fi
    return 0
}

_simple_view_Network() {
    local Network_info_values=()
    local clrs=''
    _api_get '/api/device/signal'

    LTEBand=$(_xml_parse 'band')


    for i in ${Network_info[*]}; do
        Network_info_values+=( "$(_xml_parse "${i}" | sed 's/&gt;=/<=/g')" ) 
    done


    for i in ${!Network_info[*]}; do
        _clrs=33
        if [[ ${Network_info[$i]} == @(rsrq|rsrp|rssi|sinr) ]]; then 
            # Network_info_values[$i]=$(sed 's/&gt;=/<=/g' <<< ${Network_info_values[$i]})
            _clrs=91
        fi
        if [[ -z "${Network_info_values[$i]}" ]]; then 
            Network_info_values[$i]=' - '
        else
            [[ ${Network_info[$i]} == "band" ]] && Network_info_values[$i]="B-${Network_info_values[$i]} [${Band_num[$LTEBand]} MHz]"
        fi

        if [[ ${i} -le 9 ]]; then 
            printf "\e[${_clrs}m%-14s\e[0m: \e[96m%-15s \e[0m" "${Network_info_names[$i]}" "${Network_info_values[$i]}" 
            [[ $i != 0 ]] && [[ $((i%2)) == 1 ]] && printf '\n' || printf '| '
        else
            [[ ${i} == 10 ]] && echo || Network_info_values[$i]="$(sed 's/\(No[0-9]:\)\([0-9]*\)/\1\2  /g' <<< ${Network_info_values[$i]})"
            printf "\e[${_clrs}m%-14s\e[0m: \e[96m%0s                          \n\e[0m" "${Network_info_names[$i]}" "${Network_info_values[$i]}" 
        fi
    done
    printf '\n'


    # for i in ${!Network_info[*]}; do
    #     printf '\e[33m%-10s: \e[96m%-15s \e[30m' "${Network_info[$i]}" "${Network_info_values[$i]}"
    #     [[ $i != 0 ]] && [[ $((i%2)) == 1 ]] && printf '\n' || printf '| '
    # done
}

_simple_view_device() {
    local Network_info_values=()
    _api_get '/api/device/signal'
    local _clrs_inf=''
    # local _clrs_v=''
    for i in ${Network_info[*]}; do
        Network_info_values+=( "_xml_parse "${i}"" ) 
    done

    for i in ${!Network_info_value}; do
        [[ ${Network_info[$i]} == @(rsrq|rsrp|rssi|sinr) ]] && _clrs_inf=1

        printf '\e[33m%-10s: \e[96m%s \e[30m\t\t' "${Network_info[$i]}" "${Network_info_value[$i]}" 
        [[ $i != 0 ]] && [[ $((i%2)) == 1 ]] && printf '\n' || printf '| '
    done
}

_pro_screen_band() {
    local _Band=${1}
    detect_band
    case ${_Band} in
        1)
            _Band='1'
        ;;
        2)
            _Band="3"
        ;;
        3)
            _Band="28"
        ;;
        4)
            _Band="40"
        ;;
        5)
            _Band="99"
        ;;
        6)
            _Band="98" ## some times it's good idk why !?
        ;;
        *)
            Lerror "Out of list"    &>> "${_logger}"
            return 1
        ;;
    esac 

    _get_code "${_Band}"

    
    if _Set_band &>> "${_logger}"; then
        _wan=''
        Ldone "Success change to ${Band_num[${_Band_is}]}"   &>> "${_logger}"
        return 0
    else
        Lerror "Unable to change band"                       &>> "${_logger}"
        return 1
    fi
}

_show_pro_menu() {
    Lwar "...................."   &>> "${_logger}"
    Lwar "0- Back to main menu"   &>> "${_logger}"
    Lwar "1- B1   [2100 MHz]"     &>> "${_logger}"
    Lwar "2- B3   [1800 MHz]"     &>> "${_logger}"
    Lwar "3- B28  [700  MHz]"     &>> "${_logger}"
    Lwar "4- B40  [2300 MHz]"     &>> "${_logger}"
    Lwar "5- Auto           "     &>> "${_logger}"
    Lwar "...................."   &>> "${_logger}"
    Lwar "show pro menu click [m]"&>> "${_logger}"
    Lwar "...................."   &>> "${_logger}"
    Lwar '-> '                    &>> "${_logger}"
    
}

Show_pro_screen() {
    echo > ${_logger}
    _show_pro_menu
    clear -x
    printf '\033[s' # save corser location

    printf '\033[u'     # back to the saved cursor location
    for i in {0..10}; do echo -e '\r                                                          '; done    
    printf '\n______________\n'
    tail -10 "${_logger}"
    printf '______________\n'
    
    while : ; do
        printf '\033[u'     # back to the saved cursor location
        _simple_view_Network
        printf '\n'
        
        [[ -z ${_wan} ]] && _check_wan 1 || Ldone_txtvalue "WAN IP: "  "${_wan} "

        read -n1 -t0.1 _choice 2> /dev/null 

        
        if [[ -n ${_choice} ]]; then
            if [[ ${_choice} == 0  ]]; then
                clear -x
                Linfo "Back to main menu"   &>> "${_logger}"
                Linfo 'Back to main menu' 
                _simple_view_Network
                return 0
            elif [[ ${_choice} == @(M|m)  ]]; then
                _show_pro_menu
            elif [[ ${_choice} == @(C|c)  ]]; then
                clear -x
                printf '\033[s'
                continue
            else
                if ! _pro_screen_band ${_choice}; then
                    Linfo 'cannot change band' &>> "${_logger}"
                fi
            fi
            _choice=''
            for i in $(seq 0 16); do echo -e '                                                         '; done
            printf '\033[16A'
            printf '\n\n____________\n'

            tail -10 "${_logger}"
            printf '____________\n'
        fi
    done
}

Show_options() {
    _user_var=''
    
    _mobile_data_get && _mobile_data_to='Off' || _mobile_data_to='On'

    Lwar ".........................."
    Lwar "0- Exit"
    Lwar "1- Show pro screen"
    Lwar "2- Change Band manually"
    Lwar "3- Change Band Randomly"
    Lwar "4- Show Network-info Only"
    Lwar "5- Data-monitor real time"
    Lwar_txtvalue "6- Turning Mobile data:"  "${_mobile_data_to}"
    Lwar "7- Reset screen.."
    Lwar "8- Show Device-info"
    Lwar "9- Logout"
    Lwar ".........................."
    
    _user_input "choose one commond of the following"
    
   
    case ${_user_var} in
        0)
            # do
            _cleaning
            return 0
        ;;
        1)
            # do
            Show_pro_screen
        ;;
        2)
            # do
            _Change_band
            _check_wan
        ;;
        3)
            # do
            _random_Band
            _check_wan
        ;;
        4)
            # do
            _simple_view_Network
            _check_wan  
        ;;
        5)
            # do
            _show_data_usg
            _check_wan
            Linfo "Network-details"
            _simple_view_Network
        ;;
        6)
            # do
            _mobile_data_set
        ;;
        7)
            # do
            Lwar "Reset screen"
            sleep 1
            reset
            Lwar "Reset screen"
            sleep 1
            Ldone "Done"
        ;;
        8)
            # do
            Linfo "unavilable :_"
        ;;
        9)
            # do
            _cleaning
            return 0
        ;;
        *)
            # do
            Lerror 'out of the list'
        ;;
    esac
}



main() {
    local _times=0
    local _s=0

    _check_login || exit 1
    _check_wan || Lerror_txtvalue "WAN IP: " "Unabailable       "
    _mobile_data_get && Ldone_txtvalue "Mobile data:" "On" || Lerror_txtvalue "Mobile data: " "Off"
    Linfo "Network-details"
    _simple_view_Network
    # _mobile_data_get && Linfo "Mobile data: On" || Lwar "Mobile data: Off"
    while : ; do
        Show_options
    done
}

trap _cleaning INT
clear -x
main
