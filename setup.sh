export VAR_TARGET_HOST=''
export VAR_KOREADER_ROOT_PATH=''

export VAR_PROTOCAL='ssh'

# precheck
if test -n "${AL_HOST}"; then
    export VAR_TARGET_HOST="${AL_HOST}"
fi

# Helper function for adb push
_adb_push_files() {
    local files=($1)
    local dest="${VAR_KOREADER_ROOT_PATH}/$2"
    echo adb push "${files[@]}" "$dest"
    adb push "${files[@]}" "$dest"
}

# Helper function for scp push
_scp_push_files() {
    local files=($1)
    local dest="${VAR_TARGET_HOST}:${VAR_KOREADER_ROOT_PATH}/$2"
    # local ssh_opts=(-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null)
    local ssh_opts=()
    echo scp ${ssh_opts[@]} -r "${files[@]}" "$dest"
    scp ${ssh_opts[@]} -r "${files[@]}" "$dest"
}

# Helper function for adb push
_adb_eval() {
    echo adb shell "$dest" "$@"
    adb shell "$dest" "$@"
}

# Helper function for scp push
_ssh_eval() {
    local dest="${VAR_TARGET_HOST}"
    # local ssh_opts=(-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null)
    local ssh_opts=()
    echo ssh ${ssh_opts[@]} "$dest" sh $@
    ssh ${ssh_opts[@]} "$dest" "$@"
}

push() {
    if [ ${VAR_PROTOCAL} = "ssh" ]; then
        _scp_push_files "$1" "$2"
    elif [ ${VAR_PROTOCAL} = "adb" ]; then
        _adb_push_files "$1" "$2"
    fi
}
execute() {
    if [ ${VAR_PROTOCAL} = "ssh" ]; then
        _ssh_eval "$@"
    elif [ ${VAR_PROTOCAL} = "adb" ]; then
        _adb_eval "$@"
    fi
}

setup_info() {
    if [ ${VAR_PROTOCAL} = "ssh" ]; then
        VAR_KOREADER_ROOT_PATH="/storage/emulated/0/koreader"
    elif [ ${VAR_PROTOCAL} = "adb" ]; then
        VAR_KOREADER_ROOT_PATH="/mnt/us/koreader"
    fi
}

fupgrade() {
    push "*.lua utility" "plugins/ailearning.koplugin/"
}

fpush_key() {
    local files_to_copy=("$@")
    push "${files_to_copy[@]}" "data/"
}

show_crash() {
    local crash_file="${VAR_KOREADER_ROOT_PATH}/crash.log"
    execute cat ${crash_file}
}

echo_test() {
    execute echo test
}


# # Helper function for adb push
# _adb_push_files() {
#     local files=($1)
#     local dest="$2"
#     adb push "${files[@]}" "$dest"
# }
#
# # Helper function for scp push
# _scp_push_files() {
#     local files=($1)
#     local dest="$2"
#     local ssh_opts=(-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null)
#     scp ${ssh_opts[@]} -r "${files[@]}" "$dest"
# }
#
# push_android() {
#     _adb_push_files "*.lua utility" /storage/emulated/0/koreader/plugins/ailearning.koplugin/
# }
#
# push_ankey() {
#     local files_to_copy=($@)
#     _adb_push_files "${files_to_copy[@]}" /storage/emulated/0/koreader/data/
# }
#
# push() {
#     _scp_push_files "*.lua utility" kindle:/mnt/us/koreader/plugins/ailearning.koplugin/
# }
#
# push_key() {
#     local files_to_copy=($@)
#     _scp_push_files "${files_to_copy[@]}" kindle:/mnt/us/koreader/data/
# }
#
# debug() {
#     local crash_file="/mnt/us/koreader/crash.log"
#     ssh kindle tail -n 50 ${crash_file}
# }
fhelp(){
    echo "Usage: $0 [options] [command]"
    echo ""
    echo "Options:"
    echo "  -p, --protocal <ssh|adb>  Specify the protocal to use (ssh or adb)."
    echo "  -t, --target <hostname>     Specify the target host for ssh/adb."
    echo "                            Alternatively, set the AL_HOST environment variable."
    echo "  -h, --help                Display this help message."
    echo ""
    echo "Commands:"
    echo "  help      Display this help message."
    echo "  upgrade   Push plugin files to the device."
    echo "  key <file> Push a key file to the device's data directory."
    echo "  crash     Display the crash log from the device."
    echo "  test      Execute a test command on the device."
    echo "Example:"
    echo "  export AL_HOST='kindle'"
}
main(){
    var_action=""
    while [ "$#" != "0" ]
    do
        case $1 in
            -p|--protocal)
                if [ "$2" = 'ssh' ]; then
                    VAR_PROTOCAL='ssh'
                elif [ "$2" = 'adb' ]; then
                    VAR_PROTOCAL='adb'
                else
                    echo "Please specify adb/ssh"
                    return 1
                fi
                shift 1
                ;;
            -t|--target)
                VAR_TARGET_HOST=${2}
                shift 1
                ;;
            -h|--help)
                fhelp
                return 0
                ;;
            *)
                var_action="$1"
                shift 1
                break
                ;;
        esac
        shift 1
    done
    if test -z "${VAR_TARGET_HOST}"; then
        echo "Pleaes set target host first."
        fhelp
        return 1
    fi
    # sync info.
    setup_info


    if [ "${var_action}" = "upgrade" ]; then
        fupgrade
    elif [ "${var_action}" = "key" ]; then
        fpush_key $@
    elif [ "${var_action}" = "crash" ]; then
        show_crash
    elif [ "${var_action}" = "test" ]; then
        echo_test
    fi

}

# Call the main function with all script arguments
main "$@"
