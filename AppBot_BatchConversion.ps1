##############################################################################################
#
# Citrix Application Streaming to App-V - Commandline extension
#
# Syntax :: AppBotStr2AppV -ProfilePath <PATH_TO_THE_PROFILE_FILE> ...
#
# All parameters:
#
# -projectpath :: Path to the projectfolder (created, if not exist).
# 				The defaultpath is %mydocuments%\ctxstr2msi\Projects\PROFILENAME
#
# -autostart :: Automatic start of the conversion
#
# -ConvertAppV ::Try to vonvert to app-v 5 (only on a App-V 5 sequencer
#
# -autoexit :: Automatic exit this application after the conversion
#
# -ignorerrors :: No messages and no errors the program go on
#
#
##############################################################################################

start-process .\AppBotStr2AppV.exe -ArgumentList ("-ProfilePath",'"C:\temp\citrixStreaming\NotepadPlusPlus\NotepadPlusPlus.profile"', 
"-ProjectPath","C:\temp\testproject3" ,"-autostart" ,"-autoexit") -Wait

Write-Host "Press any key to continue ..."
$x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

