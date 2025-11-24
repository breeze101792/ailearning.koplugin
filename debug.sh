
push_android() {
    adb push *.lua utility /storage/emulated/0/koreader/plugins/ailearning.koplugin/
    # adb push utility/*.lua /storage/emulated/0/koreader/plugins/ailearning.koplugin/utility
}
push_ankey() {
    local files_to_copy

    files_to_copy=($@)

    # Execute the scp command
    adb push "${files_to_copy[@]}" /storage/emulated/0/koreader/data/
    # adb push utility/*.lua /storage/emulated/0/koreader/plugins/ailearning.koplugin/utility
}

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
    if [ "$1" = "help" ]; then
        echo "Usage: $0 [command]"
        echo ""
        echo "Commands:"
        echo "  help      Display this help message."
        echo "  anpush    Push plugin files to Android device via adb."
        echo "  kpush     Push plugin files to Kindle device via scp."
        echo "  kdebug    Display the last 50 lines of the Kindle crash log."
        echo "  kkey <file> Push a key file to Kindle device's data directory."
        echo "  ankey <file> Push a key file to Android device's data directory."
    elif [ "$1" = "anpush" ]; then
        push_android
    elif [ "$1" = "kpush" ]; then
        push
    elif [ "$1" = "kdebug" ]; then
        debug
    elif [ "$1" = "ankey" ]; then
        push_ankey $2
    elif [ "$1" = "kkey" ]; then
        push_key $2
    else
        echo "Usage: $0 [help|anpush|kpush|kdebug|ankey|kkey <file>]"
        exit 1
    fi
}

# Call the main function with all script arguments
main "$@"
