# My macOS-specific commands.

use zdu.nu err

# I need a quick way to toggle the scroll direction as I switch between the trackpad and a mouse.
#
# For years, I used the following flow:
#
#   - Press "Cmd + Space" to open the launcher
#   - Type "track" to get the "Trackpad" result
#   - Press enter to open the settings window
#   - Point and click "Scroll & Zoom"
#   - Point and click "Natural scrolling"
#
# That's a bit slow for a daily thing. The below toggle command is a compressed version of the exact same effect and the
# same "just toggle it" UX.
#
# Thanks to this solution: https://forums.macrumors.com/threads/how-to-set-natural-scrolling-for-mouse-and-trackpad-independently.2396187/?post=32393580#post-32393580
#
export def "toggle-scrolling-direction" [] {
    python3 -c r#'
from ctypes import cdll
lib = cdll.LoadLibrary("/System/Library/PrivateFrameworks/PreferencePanesSupport.framework/Versions/A/PreferencePanesSupport")
lib.setSwipeScrollDirection(0 if lib.swipeScrollDirection() else 1)
'#

    # Using the 'defaults' CLI, we can see the scroll direction. This is convenient.
    #
    # You might be wondering why we aren't using 'defaults' to also set the scroll direction. You can try, and
    # 'defaults' will report that the direction is changed, but that change isn't fully persisted throughout the system
    # and your scrolling behavior will be the same. There were also some old suggestions to use 'killall cfprefsd', but
    # that didn't have any effect for me.
    #
    # So, we have to use the native call above, which works great. When you run that and if you have the "Scroll & Zoom"
    # settings window open, you can even see the "Natural scrolling" UI element animate to the opposite toggle state.
    # Neat!
    let current = ^defaults read -g com.apple.swipescrolldirection | str trim

    if ($current == "1") {
        print "Natural scrolling: ON"
    } else {
        print "Natural scrolling: OFF"
    }
}
