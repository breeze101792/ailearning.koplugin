push() {
    local files_to_copy
    # Otherwise, default to all .lua files
    files_to_copy=(*.lua)

    # Execute the scp command
    scp "${files_to_copy[@]}" kindle:/mnt/us/koreader/plugins/ailearning.koplugin/
}
debug()
{
    local crash_file="/mnt/us/koreader/crash.log"
    ssh cat ${crash_file}
}
main(){
    if [ "$1" = "push" ]; then
        push
    elif [ "$1" = "debug" ]; then
        debug
    else
        echo "Usage: $0 [push|debug]"
        exit 1
    fi
}

# Call the main function with all script arguments
main "$@"
