tell application "/Applications/UTM.app"
    set vm to first virtual machine whose name is "lab5-ad-srv-2"
    if status of vm is not stopped then error "Second VM must be stopped"
    set cfg to configuration of vm
    set diskList to drives of cfg
    if (count of diskList) is not 2 then error "Unexpected drive list"
    set end of diskList to {removable:true, interface:IDE, source:POSIX file "/Users/k6zma/Documents/ChatGPT/Windows/vm-media/utm-guest-tools-manual.iso"}
    set drives of cfg to diskList
    update configuration vm with cfg
    start vm
end tell
