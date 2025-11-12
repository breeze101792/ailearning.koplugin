push() {
    local files_to_copy
    # Otherwise, default to all .lua files
    ssh_opts=(-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null)
    files_to_copy=(*.lua utility)

    # Execute the scp command
    scp ${ssh_opts[@]} -r "${files_to_copy[@]}" kindle:/mnt/us/koreader/plugins/ailearning.koplugin/

    # I'll use different ssh, so hack it by adding this on ssh/config.
    # StrictHostKeyChecking no
    # UserKnownHostsFile /dev/null
}
push_key() {
    local files_to_copy
    # Otherwise, default to all .lua files
    ssh_opts=(-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null)
    files_to_copy=($@)

    # Execute the scp command
    scp ${ssh_opts[@]} "${files_to_copy[@]}" kindle:/mnt/us/koreader/data/

}
debug()
{
    local crash_file="/mnt/us/koreader/crash.log"
    ssh kindle tail -n 50 ${crash_file} 
}
main(){
    if [ "$1" = "push" ]; then
        push
    elif [ "$1" = "debug" ]; then
        debug
    elif [ "$1" = "key" ]; then
        push_key $2
    else
        echo "Usage: $0 [push|debug]"
        exit 1
    fi
}

# Call the main function with all script arguments
main "$@"
