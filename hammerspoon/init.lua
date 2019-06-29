-- Modal mode
local modalBinding = hs.hotkey.modal.new({"cmd", "option", "ctrl", "shift"}, "M")
function modalBinding:entered()
--  hs.alert.show("Entered modal mode")
end
modalBinding:bind('', 'escape', function()
  modalBinding:exit()
--   hs.alert.show('Exited modal mode')
end)
-- Windows Resizing in Modal Mode
--
-- What kind of window resizing? This code defines the ability to toggle a
-- window's size and position in the following states:
--   first state : 1/3 the width of the screen, the full height of the screen and aligned to the left
--   second state: 1/2 the width of the screen, the full height of the screen and aligned to the left
--   thrid state : 2/3 the width of the screen, the full height of the screen and aligned to the left
--   fourth state: the full width of the screen, the full height of the screen
--   ... AND the same four states except the window is aligned to the right ,not the left.
--
-- Data to describe the pattern of resizing and positioning:
-- {{xOffsetWidthFraction, widthFraction}}
local fromTheLeftWindowResizingCharacteristics = {{0, 1/2}, {0, 1}}
local fromTheRightWindowResizingCharacteristics = {{1/2, 1/2}, {0, 1}}

function createResizingFunctionWithState(command, windowResizingCharacteristicsCollection, collectionLength)
  local step = 1
  return function()
    print('entering binding function for command \'' .. command ..  '\'')
    print('step: ' .. step)
    local appWindow = hs.window.focusedWindow()
    local appFrame = appWindow:frame()
    local screenWindow = appWindow:screen()
    local screenFrame = screenWindow:frame()
    local screenWidth = screenFrame.w
    print('screenWidth: ' .. screenWidth)

    local windowResizingCharacteristics = windowResizingCharacteristicsCollection[step]

    step = step == collectionLength and 1 or step + 1
    print('step cycled to next step: ' .. step)

    local xOffsetWidthFraction = windowResizingCharacteristics[1]
    print('xOffsetWidthFraction: ' .. xOffsetWidthFraction)
    local widthFraction = windowResizingCharacteristics[2]
    print('widthFraction: ' .. widthFraction)

    local xOffset =  screenWidth * xOffsetWidthFraction
    print('xOffset: ' .. xOffset)
    local width = screenWidth * widthFraction
    print('width: ' .. width)

    appFrame.x = screenFrame.x + xOffset
    appFrame.y = screenFrame.y
    appFrame.w = width
    appFrame.h = screenFrame.h
    appWindow:setFrame(appFrame)
    print('exiting binding function for command \'' .. command .. '\'')
  end
end
-- Assign 'U' to be the toggle key to toggle a window between the left-aligned window states
modalBinding:bind('', 'U', createResizingFunctionWithState('U', fromTheLeftWindowResizingCharacteristics, 2))
-- Assign 'O' to be the toggle key to toggle a window between the right-aligned window states
modalBinding:bind('', 'O', createResizingFunctionWithState('O', fromTheRightWindowResizingCharacteristics, 2))
