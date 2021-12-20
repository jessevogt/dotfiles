#!/usr/bin/osascript

use framework "Foundation"
use framework "AppKit"
use scripting additions

-- https://developer.apple.com/library/archive/documentation/LanguagesUtilities/Conceptual/MacAutomationScriptingGuide/ManipulateText.html
on findAndReplaceInText(theText, theSearchString, theReplacementString)
	set AppleScript's text item delimiters to theSearchString
	set theTextItems to every text item of theText
	set AppleScript's text item delimiters to theReplacementString
	set theText to theTextItems as string
	set AppleScript's text item delimiters to ""
	return theText
end findAndReplaceInText

on jsonSafeString(str)
	return findAndReplaceInText(str, "\"", "\\\"")
end jsonSafeString

on cleanUrl(str)
    return findAndReplaceInText(str, "https://", "")
end

on makeTabInfoRecord(aUrl, aTitle, windowId, tabIndex)
    return { ¬
        url: aUrl, ¬
        title: aTitle, ¬
        windowId: windowId, ¬
        tabIndex: tabIndex ¬
    } as record
end

on listTabs()
	set tabInfo to {}
	tell application "Google Chrome"

		set windowIds to item 1 of {id} of windows
		set windowCount to length of windowIds
		
		set allTabTitlesAndUrls to {title, URL} of tabs of windows
		set allTabTitles to item 1 of allTabTitlesAndUrls
		set allTabUrls to item 2 of allTabTitlesAndUrls
		
		repeat with windowIndex from 1 to windowCount
			set windowId to item windowIndex of windowIds
			
			set tabTitles to item windowIndex of allTabTitles
			set tabUrls to item windowIndex of allTabUrls
			set tabCount to length of tabTitles
			
			repeat with tabIndex from 1 to tabCount
				set aTitle to my jsonSafeString(item tabIndex of tabTitles)
				set aUrl to my cleanUrl(item tabIndex of tabUrls)
				set end of tabInfo to my makeTabInfoRecord(aUrl, aTitle, windowId, tabIndex)
			end repeat
		end repeat
	end tell
	return tabInfo
end listTabs

on raiseTabByWindowIdAndTabIndex(windowId, tabIndex, mainFocus)
	tell application "Google Chrome"
		set aWindow to item 1 of (windows whose id is windowId)

        set newX to 0
        set newY to 0

        if mainFocus then
            set mainFrame to ((item 1 of (current application's NSScreen's screens() as list))'s frame as list)
            set mainFrameWidth to item 1 of (item 2 of mainFrame)
            set mainFrameHeight to item 2 of (item 2 of mainFrame)

            set aBounds to (bounds of aWindow as list)
            set windowWidth to (item 3 of aBounds) - (item 1 of aBounds)
            set windowHeight to (item 4 of aBounds) - (item 2 of aBounds)

            set newX to (mainFrameWidth - windowWidth) / 2 
            set newY to (mainFrameHeight - windowHeight) / 2
        end
		
		activate
		
		set visible of aWindow to true
		set index of aWindow to 1
		set active tab index of aWindow to tabIndex
		
		set searchTitle to (title of aWindow as string) & " - Google Chrome"
                    
		
		tell application "System Events" to tell process "Google Chrome"
            set windowTitles to item 1 of {title} of windows
            set windowTitleCount to length of windowTitles
            repeat with windowIndex from 1 to windowTitleCount
                set windowTitle to item windowIndex of windowTitles
                if (offset of "Shopify Mail" in windowTitle) is greater than 0 then
                    set pWindow to item windowIndex of windows
                    perform action "AXRaise" of pWindow

                    if mainFocus then
                        set pWindow's position to {newX, newY}
                    end
                    return
                end if
            end repeat
		end tell
	end tell
end raiseTabByWindowIdAndTabIndex

on isNumber(str)
    try
        set str to str as number
        return true
    on error
        return false
    end try
end isNumber

on findTab(searchTerm)
    set tabInfos to listTabs()
    set tabInfosCount to length of tabInfos
    repeat with tabInfoIndex from 1 to tabInfosCount
        set tabInfo to item tabInfoIndex of tabInfos
        if (offset of searchTerm in (url of tabInfo)) greater than 0 then
            raiseTabByWindowIdAndTabIndex(windowId of tabInfo, tabIndex of tabInfo, true)
            return
        end
    end
end findTab

on run argv
    log(argv)
	set command to system attribute "alfred_chrome_control_mode"
    if command is "" then
        set command to "listTabs"
    end

	if command = "listTabs" then
		set tabList to listTabs()
		set tabListLength to length of tabList
		set output to "{ \"items\": ["
		
		repeat with i from 1 to tabListLength
            set tabInfo to item i of tabList
            set subtitle to (title of tabInfo)
            set title to (url of tabInfo)

			set output to output & "{\"title\":\"" & title & ¬
			    "\",\"subtitle\":\"" & subtitle  & ¬
			 	"\",\"match\":\"" & title  & " " & subtitle & ¬
			 	"\",\"arg\":[" & (windowId of tabInfo) & "," & (tabIndex of tabInfo) & "]}"

			if i is not tabListLength then
				set output to output & ","
			end if
		end repeat
		
		return output & "]}"
    else if command is "showTabByWindowIdAndTabIndex" then
        set windowId to item 1 of argv as number
        set tabIndex to item 2 of argv as number
        raiseTabByWindowIdAndTabIndex(windowId, tabIndex, false)
    else if command is "focusTabByUrl" then
        set searchUrl to system attribute "alfred_chrome_control_mode_arg"
        if searchUrl is "" then
            set searchUrl to "mail.google.com"
        end
        findTab(searchUrl)
	end if
end run
