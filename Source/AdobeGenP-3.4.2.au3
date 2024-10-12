#NoTrayIcon
#RequireAdmin
#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=Skull.ico
#AutoIt3Wrapper_UseX64=y
#AutoIt3Wrapper_Outfile_x64=AdobeGenP.exe
#AutoIt3Wrapper_Res_Comment=AdobeGenP
#AutoIt3Wrapper_Res_Description=AdobeGenP
#AutoIt3Wrapper_Res_ProductName=AdobeGenP
#AutoIt3Wrapper_Res_CompanyName=AdobeGenP
#AutoIt3Wrapper_Res_LegalCopyright=AdobeGenP
#AutoIt3Wrapper_Res_LegalTradeMarks=AdobeGenP
#AutoIt3Wrapper_Run_Tidy=y
#AutoIt3Wrapper_Run_Au3Stripper=y
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****

#include <String.au3>
#include <ProgressConstants.au3>
#include <WindowsConstants.au3>
#include <GUIConstantsEx.au3>
#include <GUITab.au3>
#include <ButtonConstants.au3>
#include <MsgBoxConstants.au3>
#include <EditConstants.au3>
#include <GuiListView.au3>
#include <WinAPIProc.au3>
#include <Misc.au3>
#include <Crypt.au3>

AutoItSetOption("GUICloseOnESC", 0)  ;1=ESC closes, 0=ESC won't close

Global Const $g_AppWndTitle = "AdobeGenP", $g_AppVersion = "Original version by uncia - CGP Community Edition - v3.4.2"

If _Singleton($g_AppWndTitle, 1) = 0 Then
	Exit
EndIf

Global $MyLVGroupIsExpanded = True
Global $fInterrupt = 0
Global $FilesToPatch[0][1], $FilesToPatchNull[0][1]
Global $FilesToRestore[0][1], $fFilesListed = 0
Global $MyhGUI, $hTab, $hMainTab, $hLogTab, $idMsg, $idListview, $g_idListview, $idButtonSearch, $idButtonStop
Global $idButtonCustomFolder, $idBtnCure, $idBtnDeselectAll, $ListViewSelectFlag = 1
Global $idBtnBlockPopUp, $idBtnRunasTI, $idMemo, $timestamp, $idLog, $idBtnRestore, $idBtnCopyLog, $idFindACC
Global $idEnableMD5, $idOnlyAdobeFolders, $idBtnSaveOptions, $idUseCustomDomains, $idCustomDomainsInput
Global $hPopupTab, $idBtnDestroyAGS, $idBtnEditHosts, $idLabelEditHosts, $sEditHostsText, $idBtnRestoreHosts
Global $sDestroyAGSText, $idLabelDestroyAGS, $sCleanFirewallText, $idLabelCleanFirewall, $idBtnCleanFirewall, $idBtnOpenWF, $idBtnEnableDisableWF

Global $sINIPath = @ScriptDir & "\config.ini"
If Not FileExists($sINIPath) Then
	FileInstall("config.ini", @ScriptDir & "\config.ini")
EndIf

Global $MyDefPath = IniRead($sINIPath, "Default", "Path", "C:\Program Files")
If Not FileExists($MyDefPath) Or Not StringInStr(FileGetAttrib($MyDefPath), "D") Then
	IniWrite($sINIPath, "Default", "Path", "C:\Program Files")
	$MyDefPath = "C:\Program Files"
EndIf

If (@UserName = "SYSTEM") Then
	FileDelete(@WindowsDir & "\Temp\RunAsTI.exe")
EndIf

Global $MyRegExpGlobalPatternSearchCount = 0, $Count = 0, $idProgressBar
Global $aOutHexGlobalArray[0], $aNullArray[0], $aInHexArray[0]
Global $MyFileToParse = "", $MyFileToParsSweatPea = "", $MyFileToParseEaclient = ""
Global $sz_type, $bFoundAcro32 = False, $aSpecialFiles, $sSpecialFiles = "|"
Global $ProgressFileCountScale, $FileSearchedCount

Global $bFindACC = IniRead($sINIPath, "Options", "FindACC", "1")
Global $bEnableMD5 = IniRead($sINIPath, "Options", "EnableMD5", "1")
Global $bOnlyAdobeFolders = IniRead($sINIPath, "Options", "OnlyAdobeFolder", "1")
Global $bUseCustomDomains = IniRead($sINIPath, "Options", "UseCustomDomains", "0")
Global $sCustomDomains = IniRead($sINIPath, "Options", "CustomDomains", "'8eptecerpq.adobestats.io','xa8g202i4u.adobestats.io'")
If $sCustomDomains = "" Then
	IniWrite($sINIPath, "Options", "CustomDomains", "'8eptecerpq.adobestats.io','xa8g202i4u.adobestats.io'")
	$sCustomDomains = "'8eptecerpq.adobestats.io','xa8g202i4u.adobestats.io'"
EndIf

Local $tTargetFileList_Adobe = IniReadSection($sINIPath, "TargetFiles")
Global $TargetFileList_Adobe[0]
If Not @error Then
	ReDim $TargetFileList_Adobe[$tTargetFileList_Adobe[0][0]]
	For $i = 1 To $tTargetFileList_Adobe[0][0]
		$TargetFileList_Adobe[$i - 1] = StringReplace($tTargetFileList_Adobe[$i][1], '"', "")
	Next
EndIf
;_ArrayDisplay($TargetFileList_Adobe, "TargetFileList_Adobe")

$aSpecialFiles = IniReadSection($sINIPath, "CustomPatterns")
;_ArrayDisplay($aSpecialFiles)
For $i = 1 To UBound($aSpecialFiles) - 1
	$sSpecialFiles = $sSpecialFiles & $aSpecialFiles[$i][0] & "|"
Next
;MsgBox(0, "", $sSpecialFiles)

GUIRegisterMsg($WM_COMMAND, "WM_COMMAND")

MainGui()

Local $bHostsbakExists = False
If FileExists("C:\Windows\System32\drivers\etc\hosts.bak") Then
	GUICtrlSetState($idBtnRestoreHosts, $GUI_ENABLE)
	$bHostsbakExists = True
EndIf

While 1

	Local $bHostsbakExistsNow
	If FileExists("C:\Windows\System32\drivers\etc\hosts.bak") Then
		$bHostsbakExistsNow = True
	Else
		$bHostsbakExistsNow = False
	EndIf

	If $bHostsbakExistsNow <> $bHostsbakExists Then
		If $bHostsbakExistsNow Then
			GUICtrlSetState($idBtnRestoreHosts, $GUI_ENABLE)
		Else
			GUICtrlSetState($idBtnRestoreHosts, $GUI_DISABLE)
		EndIf
		$bHostsbakExists = $bHostsbakExistsNow
	EndIf

	$idMsg = GUIGetMsg()

	Select
		Case $idMsg = $GUI_EVENT_CLOSE
			GUIDelete($MyhGUI)
			_Exit()
		Case $idMsg = $GUI_EVENT_RESIZED
			ContinueCase
		Case $idMsg = $GUI_EVENT_RESTORE
			ContinueCase
		Case $idMsg = $GUI_EVENT_MAXIMIZE
			Local $iWidth
			Local $aGui = WinGetPos($MyhGUI)
			Local $aRect = _GUICtrlListView_GetViewRect($g_idListview)
			If ($aRect[2] > $aGui[2]) Then
				$iWidth = $aGui[2] - 75
			Else
				$iWidth = $aRect[2] - 25
			EndIf
			GUICtrlSendMsg($idListview, $LVM_SETCOLUMNWIDTH, 1, $iWidth)

		Case $idMsg = $idButtonStop
			$ListViewSelectFlag = 0   ; Set Flag to Deselected State
			FillListViewWithInfo()
			MemoWrite(@CRLF & "Path" & @CRLF & "---" & @CRLF & $MyDefPath & @CRLF & "---" & @CRLF & "Waiting for user action.")
			GUICtrlSetState($idButtonStop, $GUI_HIDE)
			GUICtrlSetState($idButtonSearch, $GUI_SHOW)
			GUICtrlSetState($idButtonSearch, 64)
			GUICtrlSetState($idBtnRestore, $GUI_HIDE)
			GUICtrlSetState($idBtnBlockPopUp, $GUI_SHOW)
			GUICtrlSetState($idBtnBlockPopUp, 64)
			GUICtrlSetState($idBtnDeselectAll, 128)
			GUICtrlSetState($idBtnCure, 128)

		Case $idMsg = $idButtonSearch
			$fInterrupt = 0
			GUICtrlSetState($idButtonSearch, $GUI_HIDE)
			GUICtrlSetState($idButtonStop, $GUI_SHOW)
			ToggleLog(0)
			GUICtrlSetState($idBtnDeselectAll, 128)
			GUICtrlSetState($idBtnBlockPopUp, 128)
			GUICtrlSetState($idListview, 128)
			GUICtrlSetState($idBtnCure, 128)
			GUICtrlSetState($idButtonCustomFolder, 128)
			;Search through all files and folders in directory and fill ListView
			_GUICtrlListView_DeleteAllItems($g_idListview)
			_GUICtrlListView_SetExtendedListViewStyle($idListview, BitOR($LVS_EX_FULLROWSELECT, $LVS_EX_GRIDLINES, $LVS_EX_DOUBLEBUFFER))
			_GUICtrlListView_AddItem($idListview, "", 0)
			_GUICtrlListView_AddItem($idListview, "", 1)
			_GUICtrlListView_AddItem($idListview, "", 2)
			_GUICtrlListView_AddItem($idListview, "", 2)

			_GUICtrlListView_RemoveAllGroups($idListview)
			_GUICtrlListView_InsertGroup($idListview, -1, 1, "", 1)    ; Group 1
			_GUICtrlListView_SetGroupInfo($idListview, 1, "Info", 1, $LVGS_COLLAPSIBLE)

			_GUICtrlListView_AddSubItem($idListview, 0, "", 1)
			_GUICtrlListView_AddSubItem($idListview, 1, "Preparing...", 1)
			_GUICtrlListView_AddSubItem($idListview, 2, "", 1)
			_GUICtrlListView_AddSubItem($idListview, 3, "Be patient, please.", 1)
			_GUICtrlListView_SetItemGroupID($idListview, 0, 1)
			_GUICtrlListView_SetItemGroupID($idListview, 1, 1)
			_GUICtrlListView_SetItemGroupID($idListview, 2, 1)
			_GUICtrlListView_SetItemGroupID($idListview, 3, 1)

			_Expand_All_Click()
			_GUICtrlListView_SetGroupInfo($idListview, 1, "Info", 1, $LVGS_COLLAPSIBLE)


			; Clear previous results
			$FilesToPatch = $FilesToPatchNull
			$FilesToRestore = $FilesToPatchNull

			$timestamp = TimerInit()

			Local $FileCount

			If $bFindACC = 1 Then
				Local $sAppsPanelDir = EnvGet('ProgramFiles(x86)') & "\Common Files\Adobe"
				Local $aSize = DirGetSize($sAppsPanelDir, $DIR_EXTENDED)     ; extended mode
				If UBound($aSize) >= 2 Then
					$FileCount = $aSize[1]
					RecursiveFileSearch($sAppsPanelDir, 0, $FileCount)   ;Search through all files and folders
					ProgressWrite(0)
				EndIf
			EndIf

			$aSize = DirGetSize($MyDefPath, $DIR_EXTENDED)     ; extended mode
			If UBound($aSize) >= 2 Then
				$FileCount = $aSize[1]
				$ProgressFileCountScale = 100 / $FileCount
				$FileSearchedCount = 0
				ProgressWrite(0)
				RecursiveFileSearch($MyDefPath, 0, $FileCount)   ;Search through all files and folders
				Sleep(100)
				ProgressWrite(0)
			EndIf

			FillListViewWithFiles()

			If _GUICtrlListView_GetItemCount($idListview) > 0 Then

				_Assign_Groups_To_Found_Files()

				$ListViewSelectFlag = 1   ; Set Flag to Selected State
				GUICtrlSetState($idButtonSearch, 128)
				GUICtrlSetState($idBtnDeselectAll, 128)
				GUICtrlSetState($idBtnCure, 64)
				GUICtrlSetState($idBtnCure, 256)     ; Set focus

				If UBound($FilesToRestore) > 0 Then
					GUICtrlSetState($idBtnBlockPopUp, $GUI_HIDE)
					GUICtrlSetState($idBtnRestore, 64)
					GUICtrlSetState($idBtnRestore, $GUI_SHOW)
				EndIf
			Else
				$ListViewSelectFlag = 0   ; Set Flag to Deselected State
				FillListViewWithInfo()
				GUICtrlSetState($idBtnCure, 128)
				GUICtrlSetState($idBtnDeselectAll, 128)
				GUICtrlSetState($idButtonSearch, 64)
				GUICtrlSetState($idButtonSearch, 256)     ; Set focus
			EndIf

			;_Collapse_All_Click()
			_Expand_All_Click()

			GUICtrlSetState($idBtnDeselectAll, 64)
			GUICtrlSetState($idBtnBlockPopUp, 64)
			GUICtrlSetState($idListview, 64)
			GUICtrlSetState($idButtonCustomFolder, 64)
			GUICtrlSetState($idButtonSearch, $GUI_SHOW)
			GUICtrlSetState($idButtonStop, $GUI_HIDE)

		Case $idMsg = $idButtonCustomFolder     ; Select Custom Path

			ToggleLog(0)

			MyFileOpenDialog()
			_Expand_All_Click()

			If $fFilesListed = 0 Then
				GUICtrlSetState($idBtnCure, 128)
				GUICtrlSetState($idBtnDeselectAll, 128)
				GUICtrlSetState($idButtonSearch, 64)
				GUICtrlSetState($idButtonSearch, 256)     ; Set focus
			Else
				GUICtrlSetState($idButtonSearch, 128)
				GUICtrlSetState($idBtnDeselectAll, 64)
				GUICtrlSetState($idBtnCure, 64)
				GUICtrlSetState($idBtnCure, 256)     ; Set focus
			EndIf

		Case $idMsg = $idBtnDeselectAll     ; Deselect-Select All
			ToggleLog(0)
			If $ListViewSelectFlag = 1 Then
				For $i = 0 To _GUICtrlListView_GetItemCount($idListview) - 1
					_GUICtrlListView_SetItemChecked($idListview, $i, 0)
				Next
				$ListViewSelectFlag = 0   ; Set Flag to Deselected State
			Else
				For $i = 0 To _GUICtrlListView_GetItemCount($idListview) - 1
					_GUICtrlListView_SetItemChecked($idListview, $i, 1)
				Next
				$ListViewSelectFlag = 1   ; Set Flag to Selected State
			EndIf


		Case $idMsg = $idBtnBlockPopUp     ; Add firewall rule button
			ToggleLog(0)
			BlockPopUp()

		Case $idMsg = $idBtnRunasTI     ; Run as TrustedInstaller button
			FileInstall("RunAsTI.exe", @WindowsDir & "\Temp\RunAsTI.exe")
			Exit Run(@WindowsDir & '\Temp\RunAsTI.exe "' & @ScriptFullPath & '"')

		Case $idMsg = $idBtnCure
			ToggleLog(0)
			GUICtrlSetState($idListview, 128)
			GUICtrlSetState($idBtnDeselectAll, 128)
			GUICtrlSetState($idButtonSearch, 128)
			GUICtrlSetState($idBtnCure, 128)
			GUICtrlSetState($idBtnBlockPopUp, 128)
			GUICtrlSetState($idBtnRestore, 128)
			GUICtrlSetState($idButtonCustomFolder, 128)
			_Expand_All_Click()
			_GUICtrlListView_EnsureVisible($idListview, 0, 0)

			Local $ItemFromList
			For $i = 0 To _GUICtrlListView_GetItemCount($idListview) - 1

				If _GUICtrlListView_GetItemChecked($idListview, $i) = True Then

					_GUICtrlListView_SetItemSelected($idListview, $i)
					$ItemFromList = _GUICtrlListView_GetItemText($idListview, $i, 1)

					MyGlobalPatternSearch($ItemFromList)
					ProgressWrite(0)
					Sleep(100)
					MemoWrite(@CRLF & "Path" & @CRLF & "---" & @CRLF & $ItemFromList & @CRLF & "---" & @CRLF & "medication :)")
					LogWrite(1, $ItemFromList)
					Sleep(100)

					MyGlobalPatternPatch($ItemFromList, $aOutHexGlobalArray)


					; Scroll control 10 pixels - 1 line
					_GUICtrlListView_Scroll($idListview, 0, 10)
					_GUICtrlListView_EnsureVisible($idListview, $i, 0)
					Sleep(100)

				EndIf

				_GUICtrlListView_SetItemChecked($idListview, $i, False)
			Next

			_GUICtrlListView_DeleteAllItems($g_idListview)
			_GUICtrlListView_SetExtendedListViewStyle($idListview, BitOR($LVS_EX_FULLROWSELECT, $LVS_EX_GRIDLINES, $LVS_EX_DOUBLEBUFFER))


			_GUICtrlListView_RemoveAllGroups($idListview)
			_GUICtrlListView_InsertGroup($idListview, -1, 1, "", 1)    ; Group 1
			_GUICtrlListView_SetGroupInfo($idListview, 1, "Info", 1, $LVGS_COLLAPSIBLE)

			MemoWrite(@CRLF & "Path" & @CRLF & "---" & @CRLF & $MyDefPath & @CRLF & "---" & @CRLF & "waiting for user action")
			GUICtrlSetState($idListview, 64)
			GUICtrlSetState($idButtonSearch, 64)
			GUICtrlSetState($idButtonCustomFolder, 64)
			GUICtrlSetState($idBtnBlockPopUp, 64)
			GUICtrlSetState($idBtnBlockPopUp, $GUI_SHOW)
			GUICtrlSetState($idBtnRestore, $GUI_HIDE)
			GUICtrlSetState($idBtnCure, 128)
			GUICtrlSetState($idButtonSearch, 256)     ; Set focus
			FillListViewWithInfo()

			If $bFoundAcro32 = True Then
				MsgBox($MB_SYSTEMMODAL, "Information", "GenP does not patch the x32 bit version of Acrobat. Please use the x64 bit version of Acrobat.")
				LogWrite(1, "GenP does not patch the x32 bit version of Acrobat. Please use the x64 bit version of Acrobat.")
			EndIf

			ToggleLog(1)

			GUICtrlSetState($hLogTab, $GUI_SHOW)

		Case $idMsg = $idBtnRestore
			GUICtrlSetData($idLog, "Activity Log" & @CRLF)
			ToggleLog(0)
			GUICtrlSetState($idListview, 128)
			GUICtrlSetState($idBtnDeselectAll, 128)
			GUICtrlSetState($idButtonSearch, 128)
			GUICtrlSetState($idBtnCure, 128)
			GUICtrlSetState($idBtnBlockPopUp, 128)
			GUICtrlSetState($idBtnRestore, 128)
			GUICtrlSetState($idButtonCustomFolder, 128)
			_Expand_All_Click()
			_GUICtrlListView_EnsureVisible($idListview, 0, 0)

			Local $ItemFromList, $iCheckedItems, $iProgress
			For $i = 0 To _GUICtrlListView_GetItemCount($idListview) - 1

				If _GUICtrlListView_GetItemChecked($idListview, $i) = True Then

					_GUICtrlListView_SetItemSelected($idListview, $i)

					$ItemFromList = _GUICtrlListView_GetItemText($idListview, $i, 1)
					$iCheckedItems = _GUICtrlListView_GetSelectedCount($idListview)
					$iProgress = 100 / $iCheckedItems
					ProgressWrite(0)
					RestoreFile($ItemFromList)

					ProgressWrite($iProgress)
					Sleep(100)
					MemoWrite(@CRLF & "Path" & @CRLF & "---" & @CRLF & $ItemFromList & @CRLF & "---" & @CRLF & "restoring :)")
					Sleep(100)

					; Scroll control 10 pixels - 1 line
					_GUICtrlListView_Scroll($idListview, 0, 10)
					_GUICtrlListView_EnsureVisible($idListview, $i, 0)
					Sleep(100)

				EndIf

				_GUICtrlListView_SetItemChecked($idListview, $i, False)
			Next

			_GUICtrlListView_DeleteAllItems($g_idListview)
			_GUICtrlListView_SetExtendedListViewStyle($idListview, BitOR($LVS_EX_FULLROWSELECT, $LVS_EX_GRIDLINES, $LVS_EX_DOUBLEBUFFER))

			_GUICtrlListView_RemoveAllGroups($idListview)
			_GUICtrlListView_InsertGroup($idListview, -1, 1, "", 1)    ; Group 1
			_GUICtrlListView_SetGroupInfo($idListview, 1, "Info", 1, $LVGS_COLLAPSIBLE)

			MemoWrite(@CRLF & "Path" & @CRLF & "---" & @CRLF & $MyDefPath & @CRLF & "---" & @CRLF & "waiting for user action")
			GUICtrlSetState($idListview, 64)
			GUICtrlSetState($idButtonCustomFolder, 64)
			GUICtrlSetState($idBtnBlockPopUp, 64)
			GUICtrlSetState($idBtnBlockPopUp, $GUI_SHOW)
			GUICtrlSetState($idBtnRestore, $GUI_HIDE)
			GUICtrlSetState($idBtnRestore, 64)
			GUICtrlSetState($idBtnCure, 128)
			GUICtrlSetState($idButtonSearch, 64)
			GUICtrlSetState($idButtonSearch, 256)     ; Set focus
			FillListViewWithInfo()

			ToggleLog(1)

		Case $idMsg = $idBtnCopyLog
			SendToClipBoard()

		Case $idMsg = $idFindACC
			If _IsChecked($idFindACC) Then
				$bFindACC = 1
			Else
				$bFindACC = 0
			EndIf

		Case $idMsg = $idEnableMD5
			If _IsChecked($idEnableMD5) Then
				$bEnableMD5 = 1
			Else
				$bEnableMD5 = 0
			EndIf

		Case $idMsg = $idOnlyAdobeFolders
			If _IsChecked($idOnlyAdobeFolders) Then
				$bOnlyAdobeFolders = 1
			Else
				$bOnlyAdobeFolders = 0
			EndIf

		Case $idMsg = $idUseCustomDomains
			GUICtrlSetState($idBtnBlockPopUp, 64)
			If _IsChecked($idUseCustomDomains) Then
				$bUseCustomDomains = 1
				If Not StringInStr(GUICtrlRead($idCustomDomainsInput), ".adobestats.io") Then
					GUICtrlSetData($idCustomDomainsInput, "8eptecerpq.adobestats.io" & @CRLF & "xa8g202i4u.adobestats.io")
				EndIf
			Else
				$bUseCustomDomains = 0
			EndIf

		Case $idMsg = $idBtnSaveOptions
			SaveOptionsToConfig()

		Case $idMsg = $idBtnDestroyAGS
			DestroyAGS()

		Case $idMsg = $idBtnEditHosts
			EditHosts()

		Case $idMsg = $idBtnRestoreHosts
			RestoreHosts()

		Case $idMsg = $idBtnCleanFirewall
			CleanFirewall()

		Case $idMsg = $idBtnOpenWF
			OpenWF()

		Case $idMsg = $idBtnEnableDisableWF
			EnableDisableWFRules()

	EndSelect
WEnd


Func MainGui()
	$MyhGUI = GUICreate($g_AppWndTitle, 595, 710, -1, -1, BitOR($WS_MAXIMIZEBOX, $WS_MINIMIZEBOX, $WS_SIZEBOX, $GUI_SS_DEFAULT_GUI))
	$hTab = GUICtrlCreateTab(0, 1, 597, 710)

	$hMainTab = GUICtrlCreateTabItem("Main")
	$idListview = GUICtrlCreateListView("", 10, 35, 575, 555)
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)
	$g_idListview = GUICtrlGetHandle($idListview) ; get the handle for use in the notify events
	_GUICtrlListView_SetExtendedListViewStyle($idListview, BitOR($LVS_EX_FULLROWSELECT, $LVS_EX_GRIDLINES, $LVS_EX_DOUBLEBUFFER, $LVS_EX_CHECKBOXES))

	; Add columns
	_GUICtrlListView_SetItemCount($idListview, UBound($FilesToPatch))
	_GUICtrlListView_AddColumn($idListview, "", 20)
	_GUICtrlListView_AddColumn($idListview, "For collapsing or expanding all groups, please click here", 532, 2)

	; Build groups
	_GUICtrlListView_EnableGroupView($idListview)
	_GUICtrlListView_InsertGroup($idListview, -1, 1, "", 1) ; Group 1
	_GUICtrlListView_SetGroupInfo($idListview, 1, "Info", 1, $LVGS_COLLAPSIBLE)

	FillListViewWithInfo()

	$idButtonCustomFolder = GUICtrlCreateButton("Path", 10, 630, 80, 30)
	GUICtrlSetTip(-1, "Select Path that You want -> press Search -> press Patch button")
	GUICtrlSetImage(-1, "imageres.dll", -4, 0)
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)

	$idButtonSearch = GUICtrlCreateButton("Search", 110, 630, 80, 30)
	GUICtrlSetTip(-1, "Let GenP find Apps automatically in current path")
	GUICtrlSetImage(-1, "imageres.dll", -8, 0)
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)

	$idButtonStop = GUICtrlCreateButton("Stop", 110, 630, 80, 30)
	GUICtrlSetState(-1, $GUI_HIDE)
	GUICtrlSetTip(-1, "Stop searching for Apps")
	GUICtrlSetImage(-1, "imageres.dll", -8, 0)
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)

	$idBtnDeselectAll = GUICtrlCreateButton("De/Select", 210, 630, 80, 30)
	GUICtrlSetState(-1, $GUI_DISABLE)
	GUICtrlSetTip(-1, "De/Select All files")
	GUICtrlSetImage(-1, "imageres.dll", -76, 0)
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)

	$idBtnCure = GUICtrlCreateButton("Patch", 305, 630, 80, 30)
	GUICtrlSetState(-1, $GUI_DISABLE)
	GUICtrlSetTip(-1, "Patch all selected files")
	GUICtrlSetImage(-1, "imageres.dll", -102, 0)
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)

	$idBtnBlockPopUp = GUICtrlCreateButton("Pop-up", 405, 630, 80, 30)
	GUICtrlSetTip(-1, "Block Unlicensed Pop-up by creating Windows Firewall Rule")
	GUICtrlSetImage(-1, "imageres.dll", -101, 0)
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)

	$idBtnRestore = GUICtrlCreateButton("Restore", 405, 630, 80, 30)
	GUICtrlSetState(-1, $GUI_HIDE)
	GUICtrlSetTip(-1, "Restore Original Files")
	GUICtrlSetImage(-1, "imageres.dll", -113, 0)
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)

	$idBtnRunasTI = GUICtrlCreateButton("Runas TI", 505, 630, 80, 30)
	GUICtrlSetImage(-1, "imageres.dll", -74, 0)
	If (@UserName = "SYSTEM") Then
		GUICtrlSetState(-1, $GUI_DISABLE)
	EndIf
	GUICtrlSetTip(-1, "Run as Trusted Installer")
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)

	$idProgressBar = GUICtrlCreateProgress(10, 597, 575, 25, $PBS_SMOOTHREVERSE)
	GUICtrlSetResizing(-1, $GUI_DOCKVCENTER)

	GUICtrlCreateLabel($g_AppVersion, 10, 677, 575, 25, $ES_CENTER)
	GUICtrlSetResizing(-1, $GUI_DOCKBOTTOM)
	GUICtrlCreateTabItem("")

	$hOptionsTab = GUICtrlCreateTabItem("Options")

	$idFindACC = GUICtrlCreateCheckbox("Always search for ACC", 10, 50, 300, 25, BitOR($BS_AUTOCHECKBOX, $BS_LEFT))
	If $bFindACC = 1 Then
		GUICtrlSetState($idFindACC, $GUI_CHECKED)
	Else
		GUICtrlSetState($idFindACC, $GUI_UNCHECKED)
	EndIf
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)

	$idEnableMD5 = GUICtrlCreateCheckbox("Enable MD5 Checksum", 10, 90, 300, 25, BitOR($BS_AUTOCHECKBOX, $BS_LEFT))
	If $bEnableMD5 = 1 Then
		GUICtrlSetState($idEnableMD5, $GUI_CHECKED)
	Else
		GUICtrlSetState($idEnableMD5, $GUI_UNCHECKED)
	EndIf
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)

	$idOnlyAdobeFolders = GUICtrlCreateCheckbox("Only find files in Adobe or Acrobat folders", 10, 130, 300, 25, BitOR($BS_AUTOCHECKBOX, $BS_LEFT))
	If $bOnlyAdobeFolders = 1 Then
		GUICtrlSetState($idOnlyAdobeFolders, $GUI_CHECKED)
	Else
		GUICtrlSetState($idOnlyAdobeFolders, $GUI_UNCHECKED)
	EndIf
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)

	$idUseCustomDomains = GUICtrlCreateCheckbox("Only use domains below for pop-up blocker", 10, 170, 300, 25, BitOR($BS_AUTOCHECKBOX, $BS_LEFT))
	If $bUseCustomDomains = 1 Then
		GUICtrlSetState($idUseCustomDomains, $GUI_CHECKED)
	Else
		GUICtrlSetState($idUseCustomDomains, $GUI_UNCHECKED)
	EndIf
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)

	$idCustomDomainsInput = GUICtrlCreateInput("Custom Domains", 10, 195, 288, 150, BitOR($ES_MULTILINE, $ES_LEFT, $ES_WANTRETURN))
	GUICtrlSetResizing(-1, $GUI_DOCKVCENTER)
	GUICtrlSetData($idCustomDomainsInput, StringReplace(StringReplace($sCustomDomains, ",", @CRLF), "'", ""))

	$idBtnSaveOptions = GUICtrlCreateButton("Save Options", 247, 630, 100, 30)
	GUICtrlSetTip(-1, "Save Options to config.ini")
	GUICtrlSetImage(-1, "imageres.dll", 5358, 0)
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)
	GUICtrlCreateTabItem("")

	$hPopupTab = GUICtrlCreateTabItem("Pop-up Tools")

	$sDestroyAGSText = "ADOBE GENUINE SERVICES REMOVAL" & @CRLF & @CRLF & _
			"Many times, the unlicensed pop-up you are getting is due to AGS." & @CRLF & _
			"You really don't want it on your system spying on you. So, just nuke it!" & @CRLF & _
			"This runs a quick script to stop and remove the services and files associated with AGS." & @CRLF & _
			"Before you go blocking pop-ups, make sure you need to. Nuke AGS. See if pop-up is gone ;)"

	$idLabelDestroyAGS = GUICtrlCreateLabel($sDestroyAGSText, 10, 50, 575, 90, $ES_CENTER)
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)

	$idBtnDestroyAGS = GUICtrlCreateButton("Destroy AGS", 235, 150, 140, 30)
	GUICtrlSetTip(-1, "Totally remove AGS from your system.")
	;GUICtrlSetImage(-1, "imageres.dll", 167, 0)
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)

	$sEditHostsText = "EDIT HOSTS" & @CRLF & @CRLF & _
			"Before running the pop-up blocker, you need a clean hosts file. (No adobe rules!)" & @CRLF & _
			"Be very careful editing hosts file. You'll find it at C:\Windows\System32\drivers\etc\hosts." & @CRLF & _
			"Disable rules by putting a # in front of the rule (# comments the rule out). If things work as expected, remove the rule." & @CRLF & _
			"Be sure to save the hosts file when done editing. We make a backup just in case you mess up ;)"

	$idLabelEditHosts = GUICtrlCreateLabel($sEditHostsText, 10, 200, 575, 90, $ES_CENTER)
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)

	$idBtnEditHosts = GUICtrlCreateButton("Edit Hosts", 155, 300, 140, 30)
	GUICtrlSetTip(-1, "Open hosts file for editing in notepad.")
	;GUICtrlSetImage(-1, "imageres.dll", 15, 0)
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)

	$idBtnRestoreHosts = GUICtrlCreateButton("Restore Hosts", 315, 300, 140, 30)
	GUICtrlSetState($idBtnRestoreHosts, $GUI_DISABLE)
	GUICtrlSetTip(-1, "Restore hosts backup. Available after editing hosts file.")
	;GUICtrlSetImage(-1, "imageres.dll", 15, 0)
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)

	$sCleanFirewallText = "CLEAN WINDOWS FIREWALL" & @CRLF & @CRLF & _
			"If you have used GenP in the past, or experience problems with internet access" & @CRLF & _
			"this will remove any OUTBOUND BLOCK rules that GenP created." & @CRLF & _
			"This enables you know you have a clean start, and allows ACC correct access for updates." & @CRLF & _
			"You can always run pop-up blocker to add rules back if necessary ;)"

	$idLabelCleanFirewall = GUICtrlCreateLabel($sCleanFirewallText, 10, 350, 575, 90, $ES_CENTER)
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)


	$idBtnCleanFirewall = GUICtrlCreateButton("Clean Firewall", 235, 450, 140, 30)
	GUICtrlSetTip(-1, "Remove all Windows Firewall Rules created by GenP.")
	;GUICtrlSetImage(-1, "imageres.dll", 15, 0)
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)

	$idBtnOpenWF = GUICtrlCreateButton("Open Windows Firewall", 155, 500, 140, 30)
	GUICtrlSetTip(-1, "Open Windows Firewall to check settings.")
	;GUICtrlSetImage(-1, "imageres.dll", 15, 0)
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)

	$idBtnEnableDisableWF = GUICtrlCreateButton("Enable/Disable Rules", 315, 500, 140, 30)
	GUICtrlSetTip(-1, "Toggle state of Windows Firewall OUTBOUND BLOCK rules with ADOBE in their name.")
	;GUICtrlSetImage(-1, "imageres.dll", 15, 0)
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)

	GUICtrlCreateTabItem("")

	$hLogTab = GUICtrlCreateTabItem("Log")
	$idMemo = GUICtrlCreateEdit("", 10, 35, 575, 555, BitOR($ES_READONLY, $ES_CENTER, $WS_DISABLED))
	GUICtrlSetResizing(-1, $GUI_DOCKVCENTER)

	$idLog = GUICtrlCreateEdit("", 10, 35, 575, 555, BitOR($WS_VSCROLL, $ES_AUTOVSCROLL, $ES_READONLY))
	GUICtrlSetResizing(-1, $GUI_DOCKVCENTER)
	GUICtrlSetState($idLog, $GUI_HIDE)
	GUICtrlSetData($idLog, "Activity Log" & @CRLF)

	$idBtnCopyLog = GUICtrlCreateButton("Copy", 257, 630, 80, 30)
	GUICtrlSetTip(-1, "Copy log to the clipboard")
	GUICtrlSetImage(-1, "imageres.dll", -77, 0)
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)

	GUICtrlCreateLabel($g_AppVersion, 10, 677, 575, 25, $ES_CENTER)
	GUICtrlSetResizing(-1, $GUI_DOCKBOTTOM)
	GUICtrlCreateTabItem("")

	MemoWrite(@CRLF & "Path" & @CRLF & "---" & @CRLF & $MyDefPath & @CRLF & "---" & @CRLF & "Waiting for user action.")

	GUICtrlSetState($idButtonSearch, 256) ; Set focus
	GUISetState(@SW_SHOW)

	GUIRegisterMsg($WM_NOTIFY, "WM_NOTIFY")
EndFunc   ;==>MainGui

Func RecursiveFileSearch($INSTARTDIR, $DEPTH, $FileCount)
	;_FileListToArrayEx
	_GUICtrlListView_SetItemText($idListview, 1, "Searching for files.", 1)
	;_GUICtrlListView_SetItemGroupID($idListview, 0, 1)

	Local $RecursiveFileSearch_MaxDeep = 6
	; Local $RecursiveFileSearch_WhenFoundRaiseToLevel = 0 ;0 to disable raising
	If $DEPTH > $RecursiveFileSearch_MaxDeep Then Return

	Local $STARTDIR = $INSTARTDIR & "\"
	$FileSearchedCount += 1

	Local $HSEARCH = FileFindFirstFile($STARTDIR & "*.*")
	If @error Then Return

	Local $NEXT, $IPATH, $isDir

	While $fInterrupt = 0

		$NEXT = FileFindNextFile($HSEARCH)
		$FileSearchedCount += 1

		If @error Then ExitLoop
		$isDir = StringInStr(FileGetAttrib($STARTDIR & $NEXT), "D")

		If $isDir Then
			Local $targetDepth
			$targetDepth = RecursiveFileSearch($STARTDIR & $NEXT, $DEPTH + 1, $FileCount)
			; raise up in recursion to wanted level
;~ 			if ( $targetDepth > 0 ) and _
;~ 			 ( $targetDepth < $DEPTH ) Then _
;~ 				Return $targetDepth
		Else
			$IPATH = $STARTDIR & $NEXT
			Local $FileNameCropped, $PathToCheck
			If (IsArray($TargetFileList_Adobe)) Then
				For $AdobeFileTarget In $TargetFileList_Adobe

					If StringInStr($AdobeFileTarget, "$") Then
						;  split the string at the $ sign
						$AdobeFileTarget = StringSplit($AdobeFileTarget, "$", $STR_ENTIRESPLIT)
						$PathToCheck = $AdobeFileTarget[2]
						$AdobeFileTarget = $AdobeFileTarget[1]

						;  ConsoleWrite($AdobeFileTarget & " / " & $PathToCheck & @CRLF)

					EndIf
					$FileNameCropped = StringSplit(StringLower($IPATH), StringLower($AdobeFileTarget), $STR_ENTIRESPLIT)
					If @error <> 1 Then
						If Not StringInStr($IPATH, ".bak") Then
							;_ArrayAdd( $FilesToPatch, $DEPTH & " - " & $IPATH )
							If (StringInStr($IPATH, "Adobe") Or StringInStr($IPATH, "Acrobat")) Or $bOnlyAdobeFolders = 0 Then
								If $PathToCheck = "" Then
									_ArrayAdd($FilesToPatch, $IPATH)
								Else
									If StringInStr($IPATH, $PathToCheck) Then
										_ArrayAdd($FilesToPatch, $IPATH)
									EndIf
								EndIf
							EndIf
						Else
							_ArrayAdd($FilesToRestore, $IPATH)
						EndIf

						; File Found and stored - Quit search in current dir
;~ 					return $RecursiveFileSearch_WhenFoundRaiseToLevel
					EndIf
					$PathToCheck = ""
				Next
			EndIf
		EndIf
	WEnd

	;Lazy screenupdates
	If 1 = Random(0, 10, 1) Then
		MemoWrite(@CRLF & "Searching in " & $FileCount & " files" & @TAB & @TAB & "Found : " & UBound($FilesToPatch) & @CRLF & _
				"---" & @CRLF & _
				"Level: " & $DEPTH & " Time elapsed : " & Round(TimerDiff($timestamp) / 1000, 0) & " second(s)" & @TAB & @TAB & "Excluded because of *.bak: " & UBound($FilesToRestore) & @CRLF & _
				"---" & @CRLF & _
				$INSTARTDIR _
				)
		ProgressWrite($ProgressFileCountScale * $FileSearchedCount)
	EndIf

	FileClose($HSEARCH)
EndFunc   ;==>RecursiveFileSearch

Func FillListViewWithInfo()

	_GUICtrlListView_DeleteAllItems($g_idListview)
	_GUICtrlListView_SetExtendedListViewStyle($idListview, BitOR($LVS_EX_FULLROWSELECT, $LVS_EX_GRIDLINES, $LVS_EX_DOUBLEBUFFER))

	_Expand_All_Click()
	_GUICtrlListView_SetGroupInfo($idListview, 1, "Info", 1, $LVGS_COLLAPSIBLE)

	; Add items
	For $i = 0 To 24
		_GUICtrlListView_AddItem($idListview, "", $i)
		_GUICtrlListView_SetItemGroupID($idListview, $i, 1)
	Next

	_GUICtrlListView_AddSubItem($idListview, 0, "", 1)
	_GUICtrlListView_AddSubItem($idListview, 1, "To patch all Adobe apps in default location:", 1)
	_GUICtrlListView_AddSubItem($idListview, 2, "Press 'Search Files' - Press 'Patch Files'", 1)
	_GUICtrlListView_AddSubItem($idListview, 3, "Default path - C:\Program Files", 1)
	_GUICtrlListView_AddSubItem($idListview, 4, '-------------------------------------------------------------', 1)
	_GUICtrlListView_AddSubItem($idListview, 5, "After searching, some products may already be patched.", 1)
	_GUICtrlListView_AddSubItem($idListview, 6, "To select\deselect products to patch, LEFT CLICK on the product group", 1)
	_GUICtrlListView_AddSubItem($idListview, 7, "To select\deselect individual files, RIGHT CLICK on the file", 1)
	_GUICtrlListView_AddSubItem($idListview, 8, '-------------------------------------------------------------', 1)
	_GUICtrlListView_AddSubItem($idListview, 9, "What's new in GenP:", 1)
	_GUICtrlListView_AddSubItem($idListview, 10, "Can patch apps from 2019 version to current and future releases", 1)
	_GUICtrlListView_AddSubItem($idListview, 11, "Automatic search and patch in selected folder", 1)
	_GUICtrlListView_AddSubItem($idListview, 12, "New patching logic. 'Unlicensed Pop-up' Blocker for Windows Firewall", 1)
	_GUICtrlListView_AddSubItem($idListview, 13, "Support for all Substance products", 1)
	_GUICtrlListView_AddSubItem($idListview, 14, '-------------------------------------------------------------', 1)
	_GUICtrlListView_AddSubItem($idListview, 15, "Known issues:", 1)
	_GUICtrlListView_AddSubItem($idListview, 16, "InDesign and InCopy will have high Cpu usage", 1)
	_GUICtrlListView_AddSubItem($idListview, 17, "Animate will have some problems with home screen if Signed Out", 1)
	_GUICtrlListView_AddSubItem($idListview, 18, "Acrobat, XD, Lightroom Classic will partially work if Signed Out", 1)
	_GUICtrlListView_AddSubItem($idListview, 19, "Premiere Rush, Lightroom Online, Photoshop Express", 1)
	_GUICtrlListView_AddSubItem($idListview, 20, "Won't be fully unlocked", 1)
	_GUICtrlListView_AddSubItem($idListview, 21, '-------------------------------------------------------------', 1)
	_GUICtrlListView_AddSubItem($idListview, 22, "Some Apps demand Creative Cloud App and mandatory SignIn", 1)
	_GUICtrlListView_AddSubItem($idListview, 23, "Fresco, Aero, Lightroom Online, Premiere Rush, Photoshop Express", 1)

	$fFilesListed = 0

EndFunc   ;==>FillListViewWithInfo

Func FillListViewWithFiles()

	_GUICtrlListView_DeleteAllItems($g_idListview)
	_GUICtrlListView_SetExtendedListViewStyle($idListview, BitOR($LVS_EX_FULLROWSELECT, $LVS_EX_GRIDLINES, $LVS_EX_DOUBLEBUFFER, $LVS_EX_CHECKBOXES))

	; Two column load
	If UBound($FilesToPatch) > 0 Then
		Global $aItems[UBound($FilesToPatch)][2]
		For $i = 0 To UBound($aItems) - 1
			$aItems[$i][0] = $i
			$aItems[$i][1] = $FilesToPatch[$i][0]

		Next
		_GUICtrlListView_AddArray($idListview, $aItems)

		MemoWrite(@CRLF & UBound($FilesToPatch) & " File(s) were found in " & Round(TimerDiff($timestamp) / 1000, 0) & " second(s) at:" & @CRLF & "---" & @CRLF & $MyDefPath & @CRLF & "---" & @CRLF & "Press the 'Patch Files'")
		LogWrite(1, UBound($FilesToPatch) & " File(s) were found in " & Round(TimerDiff($timestamp) / 1000, 0) & " second(s)" & @CRLF)
		;_ArrayDisplay($FilesToPatch)
		$fFilesListed = 1
	Else
		MemoWrite(@CRLF & "Nothing was found in" & @CRLF & "---" & @CRLF & $MyDefPath & @CRLF & "---" & @CRLF & "waiting for user action")
		LogWrite(1, "Nothing was found in " & $MyDefPath)
		$fFilesListed = 0
	EndIf

EndFunc   ;==>FillListViewWithFiles

; Write a line to the memo control
Func MemoWrite($sMessage)
	GUICtrlSetData($idMemo, $sMessage)
EndFunc   ;==>MemoWrite

Func LogWrite($bTS, $sMessage)
	GUICtrlSetDataEx($idLog, $sMessage, $bTS)
EndFunc   ;==>LogWrite

Func ToggleLog($bShow)
	If $bShow = 1 Then
		GUICtrlSetState($idMemo, $GUI_HIDE)
		GUICtrlSetState($idLog, $GUI_SHOW)
	Else
		GUICtrlSetState($idLog, $GUI_HIDE)
		GUICtrlSetState($idMemo, $GUI_SHOW)
	EndIf
EndFunc   ;==>ToggleLog

Func SendToClipBoard()
	If BitAND(GUICtrlGetState($idMemo), $GUI_HIDE) = $GUI_HIDE Then
		ClipPut(GUICtrlRead($idLog))
	Else
		ClipPut(GUICtrlRead($idMemo))
	EndIf
EndFunc   ;==>SendToClipBoard

Func GUICtrlSetDataEx($hWnd, $sText, $bTS)
	If Not IsHWnd($hWnd) Then $hWnd = GUICtrlGetHandle($hWnd)
	Local $iLength = DllCall("user32.dll", "lresult", "SendMessageW", "hwnd", $hWnd, "uint", 0x000E, "wparam", 0, "lparam", 0)
	DllCall("user32.dll", "lresult", "SendMessageW", "hwnd", $hWnd, "uint", 0xB1, "wparam", $iLength[0], "lparam", $iLength[0]) ; $EM_SETSEL
	If $bTS = 1 Then
		Local $iData = @CRLF & @YEAR & "-" & @MON & "-" & @MDAY & " " & @HOUR & ":" & @MIN & ":" & @SEC & "." & @MSEC & " " & $sText
	Else
		Local $iData = $sText
	EndIf
	DllCall("user32.dll", "lresult", "SendMessageW", "hwnd", $hWnd, "uint", 0xC2, "wparam", True, "wstr", $iData) ; $EM_REPLACESEL
EndFunc   ;==>GUICtrlSetDataEx

; Send a message to the Progress control
Func ProgressWrite($msg_Progress)
	;_SendMessage($hWnd_Progress, $PBM_SETPOS, $msg_Progress)
	GUICtrlSetData($idProgressBar, $msg_Progress)
EndFunc   ;==>ProgressWrite


Func MyFileOpenDialog()
	; Create a constant variable in Local scope of the message to display in FileOpenDialog.
	Local Const $sMessage = "Select a Path"

	; Display an open dialog to select a file.
	FileSetAttrib("C:\Program Files\WindowsApps", "-H")
	Local $MyTempPath = FileSelectFolder($sMessage, $MyDefPath, 0, $MyDefPath, $MyhGUI)


	If @error Then
		; Display the error message.
		;MsgBox($MB_SYSTEMMODAL, "", "No folder was selected.")
		FileSetAttrib("C:\Program Files\WindowsApps", "+H")
		MemoWrite(@CRLF & "Path" & @CRLF & "---" & @CRLF & $MyDefPath & @CRLF & "---" & @CRLF & "waiting for user action")

	Else
		GUICtrlSetState($idBtnCure, 128)
		$MyDefPath = $MyTempPath
		IniWrite($sINIPath, "Default", "Path", $MyDefPath)
		_GUICtrlListView_DeleteAllItems($g_idListview)
		_GUICtrlListView_SetExtendedListViewStyle($idListview, BitOR($LVS_EX_GRIDLINES, $LVS_EX_FULLROWSELECT, $LVS_EX_SUBITEMIMAGES))
		_GUICtrlListView_AddItem($idListview, "", 0)
		_GUICtrlListView_AddItem($idListview, "", 1)
		_GUICtrlListView_AddItem($idListview, "", 2)
		_GUICtrlListView_AddItem($idListview, "", 3)
		_GUICtrlListView_AddItem($idListview, "", 4)
		_GUICtrlListView_AddItem($idListview, "", 5)
		_GUICtrlListView_AddItem($idListview, "", 6)
		_GUICtrlListView_AddSubItem($idListview, 0, "", 1)
		_GUICtrlListView_AddSubItem($idListview, 1, "Path:", 1)
		_GUICtrlListView_AddSubItem($idListview, 2, " " & $MyDefPath, 1)
		_GUICtrlListView_AddSubItem($idListview, 3, "Step 1:", 1)
		_GUICtrlListView_AddSubItem($idListview, 4, " Press 'Search Files' - wait until GenP finds all files", 1)
		_GUICtrlListView_AddSubItem($idListview, 5, "Step 2:", 1)
		_GUICtrlListView_AddSubItem($idListview, 6, " Press 'Patch Files' - wait until GenP will do it's job", 1)
		_GUICtrlListView_SetItemGroupID($idListview, 0, 1)
		_GUICtrlListView_SetItemGroupID($idListview, 1, 1)
		_GUICtrlListView_SetItemGroupID($idListview, 2, 1)
		_GUICtrlListView_SetItemGroupID($idListview, 3, 1)
		_GUICtrlListView_SetItemGroupID($idListview, 4, 1)
		_GUICtrlListView_SetItemGroupID($idListview, 5, 1)
		_GUICtrlListView_SetItemGroupID($idListview, 6, 1)
		_GUICtrlListView_SetGroupInfo($idListview, 1, "Info", 1, $LVGS_COLLAPSIBLE)

		FileSetAttrib("C:\Program Files\WindowsApps", "+H")
		MemoWrite(@CRLF & "Path" & @CRLF & "---" & @CRLF & $MyDefPath & @CRLF & "---" & @CRLF & "Press the Search button")
		; Display the selected folder.
		;MsgBox($MB_SYSTEMMODAL, "", "You chose the following folder:" & @CRLF & $MyDefPath)
		GUICtrlSetState($idBtnBlockPopUp, $GUI_SHOW)
		GUICtrlSetState($idBtnRestore, $GUI_HIDE)
		$fFilesListed = 0

	EndIf

EndFunc   ;==>MyFileOpenDialog


Func _ProcessCloseEx($sName)
	Local $iPID = Run("TASKKILL /F /T /IM " & $sName, @TempDir, @SW_HIDE)
	ProcessWaitClose($iPID)
EndFunc   ;==>_ProcessCloseEx


Func MyGlobalPatternSearch($MyFileToParse)
	;ConsoleWrite($MyFileToParse & @CRLF)
	$aInHexArray = $aNullArray   ; Nullifay Array that will contain Hex later
	$aOutHexGlobalArray = $aNullArray     ; Nullifay Array that will contain Hex later

	ProgressWrite(0)
	$MyRegExpGlobalPatternSearchCount = 0
	$Count = 15

	Local $sFileName = StringRegExpReplace($MyFileToParse, "^.*\\", "")
	Local $sExt = StringRegExpReplace($sFileName, "^.*\.", "")

	MemoWrite(@CRLF & $MyFileToParse & @CRLF & "---" & @CRLF & "Preparing to Analyze" & @CRLF & "---" & @CRLF & "*****")
	LogWrite(1, "Checking File: " & $sFileName & " ")
	;MsgBox($MB_SYSTEMMODAL,"","$sFileName = " & $sFileName & @CRLF & "$sExt = " & $sExt)

	If $sExt = "exe" Then
		_ProcessCloseEx("""" & $sFileName & """")
	EndIf

	If $sFileName = "Adobe Desktop Service.exe" Then
		_ProcessCloseEx("""Creative Cloud.exe""")
		Sleep(100)
	EndIf

	If $sFileName = "AppsPanelBL.dll" Then
		_ProcessCloseEx("""Creative Cloud.exe""")
		_ProcessCloseEx("""Adobe Desktop Service.exe""")
		Sleep(100)
	EndIf

	If StringInStr($sSpecialFiles, $sFileName) Then
		;MsgBox($MB_SYSTEMMODAL, "", "Special File: " & $sFileName)
		LogWrite(0, " - using Custom Patterns")
		ExecuteSearchPatterns($sFileName, 0, $MyFileToParse)
	Else
		LogWrite(0, " - using Default Patterns")
		ExecuteSearchPatterns($sFileName, 1, $MyFileToParse)
		;MsgBox($MB_SYSTEMMODAL, "", "File: " & $sFileName & @CRLF & "Not in Special Files")
	EndIf
	Sleep(100)
EndFunc   ;==>MyGlobalPatternSearch

Func ExecuteSearchPatterns($FileName, $DefaultPatterns, $MyFileToParse)

	Local $aPatterns, $sPattern, $sData, $aArray, $sSearch, $sReplace, $iPatternLength

	If $DefaultPatterns = 0 Then
		$aPatterns = IniReadArray($sINIPath, "CustomPatterns", $FileName, "")
	Else
		$aPatterns = IniReadArray($sINIPath, "DefaultPatterns", "Values", "")
	EndIf

	;_ArrayDisplay($aPatterns, "Patterns for " & $FileName)

	For $i = 0 To UBound($aPatterns) - 1
		$sPattern = $aPatterns[$i]
		$sData = IniRead($sINIPath, "Patches", $sPattern, "")
		If StringInStr($sData, "|") Then
			$aArray = StringSplit($sData, "|")
			If UBound($aArray) = 3 Then

				$sSearch = StringReplace($aArray[1], '"', '')
				$sReplace = StringReplace($aArray[2], '"', '')

				$iPatternLength = StringLen($sSearch)
				If $iPatternLength <> StringLen($sReplace) Or Mod($iPatternLength, 2) <> 0 Then
					MsgBox($MB_SYSTEMMODAL, "Error", "Pattern Error in config.ini:" & $sPattern & @CRLF & $sSearch & @CRLF & $sReplace)
					Exit
				EndIf

				;MsgBox(0,0, $MyFileToParse & @CRLF & $sSearch & @CRLF  & $aReplace & @CRLF  & $sPattern )
				LogWrite(1, "Searching for: " & $sPattern & ": " & $sSearch)

				MyRegExpGlobalPatternSearch($MyFileToParse, $sSearch, $sReplace, $sPattern)

				;Exit ; STOP AT FIRST VALUE - COMMENT OUT TO CONTINUE
			EndIf
			;Exit
		EndIf

	Next

EndFunc   ;==>ExecuteSearchPatterns


Func MyRegExpGlobalPatternSearch($FileToParse, $PatternToSearch, $PatternToReplace, $PatternName)  ; Path to a file to parse
	;MsgBox($MB_SYSTEMMODAL, "Path", $FileToParse)
	;ConsoleWrite($FileToParse & @CRLF)
	Local $hFileOpen = FileOpen($FileToParse, $FO_READ + $FO_BINARY)

	FileSetPos($hFileOpen, 60, 0)

	$sz_type = FileRead($hFileOpen, 4)
	FileSetPos($hFileOpen, Number($sz_type) + 4, 0)

	$sz_type = FileRead($hFileOpen, 2)

	If $sz_type = "0x4C01" And StringInStr($FileToParse, "Acrobat", 2) > 0 Then ; Acrobat x86 won't work with this script

		MemoWrite(@CRLF & $FileToParse & @CRLF & "---" & @CRLF & "File is 32bit. Aborting..." & @CRLF & "---")
		FileClose($hFileOpen)
		Sleep(100)
		$bFoundAcro32 = True

	Else

		FileSetPos($hFileOpen, 0, 0)

		Local $sFileRead = FileRead($hFileOpen)

		Local $GeneQuestionMark, $AnyNumOfBytes, $OutStringForRegExp
		For $i = 256 To 1 Step -2 ; limiting to 256 -?-
			$GeneQuestionMark = _StringRepeat("??", $i / 2) ; Repeat the string -??- $i/2 times.
			$AnyNumOfBytes = "(.{" & $i & "})"
			$OutStringForRegExp = StringReplace($PatternToSearch, $GeneQuestionMark, $AnyNumOfBytes)
			$PatternToSearch = $OutStringForRegExp
		Next

		Local $sSearchPattern = $OutStringForRegExp     ;string
		Local $aReplacePattern = $PatternToReplace     ;string
		Local $sWildcardSearchPattern = "", $sWildcardReplacePattern = "", $sFinalReplacePattern = ""
		Local $aInHexTempArray[0]
		Local $sSearchCharacter = "", $sReplaceCharacter = ""

		$aInHexTempArray = $aNullArray
		$aInHexTempArray = StringRegExp($sFileRead, $sSearchPattern, $STR_REGEXPARRAYGLOBALFULLMATCH, 1)

		For $i = 0 To UBound($aInHexTempArray) - 1

			$aInHexArray = $aNullArray
			$sSearchCharacter = ""
			$sReplaceCharacter = ""
			$sWildcardSearchPattern = ""
			$sWildcardReplacePattern = ""
			$sFinalReplacePattern = ""


			$aInHexArray = $aInHexTempArray[$i]
			;_ArrayDisplay($aInHexArray)

			If @error = 0 Then
				$sWildcardSearchPattern = $aInHexArray[0]   ; full founded Search Pattern index 0
				$sWildcardReplacePattern = $aReplacePattern

				;MsgBox(-1,"",$sWildcardSearchPattern & @CRLF & $sWildcardReplacePattern) ; full search and full patch with ?? symbols

				If StringInStr($sWildcardReplacePattern, "?") Then
					;MsgBox($MB_SYSTEMMODAL, "Found ? symbol", "Constructing new Replace string")
					For $j = 1 To StringLen($sWildcardReplacePattern) + 1
						; Retrieve a characters from the $jth position in each string.
						$sSearchCharacter = StringMid($sWildcardSearchPattern, $j, 1)
						$sReplaceCharacter = StringMid($sWildcardReplacePattern, $j, 1)

						If $sReplaceCharacter <> "?" Then
							$sFinalReplacePattern &= $sReplaceCharacter
						Else
							$sFinalReplacePattern &= $sSearchCharacter
						EndIf

					Next
				Else
					$sFinalReplacePattern = $sWildcardReplacePattern
				EndIf

				_ArrayAdd($aOutHexGlobalArray, $sWildcardSearchPattern)
				_ArrayAdd($aOutHexGlobalArray, $sFinalReplacePattern)

				ConsoleWrite($PatternName & "---" & @TAB & $sWildcardSearchPattern & "	" & @CRLF)
				ConsoleWrite($PatternName & "R" & "--" & @TAB & $sFinalReplacePattern & "	" & @CRLF)
				MemoWrite(@CRLF & $FileToParse & @CRLF & "---" & @CRLF & $PatternName & @CRLF & "---" & @CRLF & $sWildcardSearchPattern & @CRLF & $sFinalReplacePattern)
				LogWrite(1, "Replacing with: " & $sFinalReplacePattern)

			Else
				ConsoleWrite($PatternName & "---" & @TAB & "No" & "	" & @CRLF)
				MemoWrite(@CRLF & $FileToParse & @CRLF & "---" & @CRLF & $PatternName & "---" & "No")
			EndIf
			$MyRegExpGlobalPatternSearchCount += 1

		Next
		FileClose($hFileOpen)
		$sFileRead = ""
		ProgressWrite(Round($MyRegExpGlobalPatternSearchCount / $Count * 100))
		Sleep(100)

	EndIf      ;==>If $sz_type = "0x4C01"

EndFunc   ;==>MyRegExpGlobalPatternSearch


;---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Func MyGlobalPatternPatch($MyFileToPatch, $MyArrayToPatch)
	;MsgBox($MB_SYSTEMMODAL, "", $MyFileToPatch)
	;_ArrayDisplay($MyArrayToPatch)
	ProgressWrite(0)
	;MemoWrite("Current path" & @CRLF & "---" & @CRLF & $MyFileToPatch & @CRLF & "---" & @CRLF & "medication :)")
	Local $iRows = UBound($MyArrayToPatch) ; Total number of rows
	If $iRows > 0 Then
		MemoWrite(@CRLF & "Path" & @CRLF & "---" & @CRLF & $MyFileToPatch & @CRLF & "---" & @CRLF & "medication :)")
		Local $hFileOpen = FileOpen($MyFileToPatch, $FO_READ + $FO_BINARY)
		Local $sFileRead = FileRead($hFileOpen)
		Local $sStringOut

		For $i = 0 To $iRows - 1 Step 2
			$sStringOut = StringReplace($sFileRead, $MyArrayToPatch[$i], $MyArrayToPatch[$i + 1], 0, 1)
			$sFileRead = $sStringOut
			$sStringOut = $sFileRead
			ProgressWrite(Round($i / $iRows * 100))
		Next

		;MsgBox($MB_SYSTEMMODAL, "", "binary: " & Binary($sStringOut))
		FileClose($hFileOpen)
		FileMove($MyFileToPatch, $MyFileToPatch & ".bak", $FC_OVERWRITE)
		Local $hFileOpen1 = FileOpen($MyFileToPatch, $FO_OVERWRITE + $FO_BINARY)
		FileWrite($hFileOpen1, Binary($sStringOut))
		FileClose($hFileOpen1)
		ProgressWrite(0)
		Sleep(100)
		;MemoWrite1(@CRLF & "---" & @CRLF & "Waitng for your command :)" & @CRLF & "---")

		LogWrite(1, "File patched.")
		If $bEnableMD5 = 1 Then
			_Crypt_Startup()
			Local $sMD5Checksum = _Crypt_HashFile($MyFileToPatch, $CALG_MD5)
			If Not @error Then
				LogWrite(1, "MD5 Checksum: " & $sMD5Checksum & @CRLF)
			EndIf
			_Crypt_Shutdown()
		EndIf

	Else
		;Empty array - > no search-replace patterns
		;File is already patched or no patterns were found .
		MemoWrite(@CRLF & "No patterns were found" & @CRLF & "---" & @CRLF & "or" & @CRLF & "---" & @CRLF & "file is already patched.")
		Sleep(100)

		LogWrite(1, "No patterns were found or file already patched." & @CRLF)

	EndIf
	;Sleep(100)
	;MemoWrite2("***")
EndFunc   ;==>MyGlobalPatternPatch

Func RestoreFile($MyFileToDelete)
	If FileExists($MyFileToDelete & ".bak") Then
		If $MyFileToDelete = "AppsPanelBL.dll" Or $MyFileToDelete = "Adobe Desktop Service.exe" Then
			_ProcessCloseEx("""Creative Cloud.exe""")
			_ProcessCloseEx("""Adobe Desktop Service.exe""")
			Sleep(100)
		EndIf
		FileDelete($MyFileToDelete)
		FileMove($MyFileToDelete & ".bak", $MyFileToDelete, $FC_OVERWRITE)
		Sleep(100)
		MemoWrite(@CRLF & "File restored" & @CRLF & "---" & @CRLF & $MyFileToDelete)
		LogWrite(1, $MyFileToDelete)
		LogWrite(1, "File restored.")
	Else
		Sleep(100)
		MemoWrite(@CRLF & "No backup file found" & @CRLF & "---" & @CRLF & $MyFileToDelete)
		LogWrite(1, $MyFileToDelete)
		LogWrite(1, "No backup file found.")
	EndIf
EndFunc   ;==>RestoreFile

;---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Func BlockPopUp()
	GUICtrlSetState($idBtnBlockPopUp, 128)
	_GUICtrlTab_SetCurFocus($hTab, 3)

	MemoWrite(@CRLF & "Checking for Internet connectivity" & @CRLF & "---" & @CRLF & "Please wait...")
	Local $sCmdInfo = "PowerShell Set-ExecutionPolicy Bypass -scope Process -Force;(Get-NetRoute | Where-Object DestinationPrefix -eq '0.0.0.0/0' | Get-NetIPInterface | Where-Object ConnectionState -eq 'Connected') -ne $null"
	Local $iPID = Run($sCmdInfo, "", @SW_HIDE, BitOR($STDERR_CHILD, $STDOUT_CHILD))
	Local $sIPs = ""
	Local $sOutput = ""
	Local $bAbort = False
	While 1
		$sOutput &= StdoutRead($iPID)
		If @error Then ExitLoop
	WEnd
	ProcessWaitClose($iPID)
	;MsgBox(0, "", $sOutput)
	If StringReplace($sOutput, @CRLF, "") = "True" Then
		MemoWrite(@CRLF & "Searching for IP Addresses" & @CRLF & "---" & @CRLF & "Please wait...")
		If $bUseCustomDomains = 1 Then
			$sCustomDomains = "'" & StringReplace(GUICtrlRead($idCustomDomainsInput), @CRLF, "','") & "'"
			$sCmdInfo = "PowerShell Set-ExecutionPolicy Bypass -scope Process -Force;$ips=@();$domains=@(" & $sCustomDomains & ");$soa=(Resolve-DnsName -Name ic.adobe.io -Type SOA).PrimaryServer;Do{$ip=(Resolve-DnsName -Name ic.adobe.io -Server $soa).IPAddress;$ips+=$ip;If($ip -eq '0.0.0.0'){Break};If($ip -eq '127.0.0.1'){Break};$ips=$ips|Select-Object -Unique|Sort-Object}While($ips.Count -lt 8);$domains.foreach({$ip=(Resolve-DnsName -Name $_).IPAddress;$ips+=$ip});$ips=$ips|Select-Object -Unique|Sort-Object;$list=$ips -join ',';$list;"
		Else
			$sCmdInfo = "PowerShell Set-ExecutionPolicy Bypass -scope Process -Force;$path = Join-Path -Path $env:TEMP -ChildPath pihole.txt;Invoke-WebRequest 'https://a.dove.isdumb.one/pihole.txt' -OutFile $path;$ips=@();$soa=(Resolve-DnsName -Name ic.adobe.io -Type SOA).PrimaryServer;Do{$ip=(Resolve-DnsName -Name ic.adobe.io -Server $soa).IPAddress;$ips+=$ip;If($ip -eq '0.0.0.0'){Break};If($ip -eq '127.0.0.1'){Break};$ips=$ips|Select-Object -Unique|Sort-Object}While($ips.Count -lt 8);[System.IO.File]::ReadLines($path) | ForEach-Object {if($_ -Match 'adobestats.io'){$ip=(Resolve-DnsName -Name $_).IPAddress;$ips+=$ip;}};Remove-Item $path;$ips=$ips|Select-Object -Unique|Sort-Object;$list=$ips -join ',';$list;"
		EndIf
		$iPID = Run($sCmdInfo, "", @SW_HIDE, BitOR($STDERR_CHILD, $STDOUT_CHILD))
		$sOutput = ""
		While 1
			$sOutput &= StdoutRead($iPID)
			If @error Then ExitLoop
		WEnd
		ProcessWaitClose($iPID)
		$sIPs = StringReplace($sOutput, @CRLF, "")
		If StringInStr($sIPs, "0.0.0.0") Or StringInStr($sIPs, "127.0.0.1") Then
			LogWrite(1, "Detected 0.0.0.0/127.0.0.1 in IP address list. This means your host file contains Adobe domains. Please remove them and try again. No changes have been made to firewall rules!" & @CRLF)
			$bAbort = True
			ToggleLog(1)
		EndIf
		If $sIPs = "" Then
			LogWrite(1, "Something went wrong! No Genuine IP addresses found. This means your host file contains Adobe rules like 127.0.0.1 ic.adobe.io. Please remove them and try again. No changes have been made to firewall rules!" & @CRLF)
			$bAbort = True
			ToggleLog(1)
		EndIf
		$sCmdInfo = "PowerShell Set-ExecutionPolicy Bypass -scope Process -Force;$fws = Get-CimInstance -ClassName FirewallProduct -Namespace 'root\SecurityCenter2';if(!$fws){Write-Output 'Windows'}else{$fws | ForEach-Object {Write-Output $_.displayName}}"
		$iPID = Run($sCmdInfo, "", @SW_HIDE, BitOR($STDERR_CHILD, $STDOUT_CHILD))
		$sOutput = ""
		While 1
			$sOutput &= StdoutRead($iPID)
			If @error Then ExitLoop
		WEnd
		ProcessWaitClose($iPID)
		If StringReplace($sOutput, @CRLF, "") = "Windows" Then
			MemoWrite(@CRLF & "Creating Windows Firewall Rule" & @CRLF & "---" & @CRLF & "Blocking:" & @CRLF & $sIPs)

			If $bAbort = False Then
				$sCmdInfo = "netsh advfirewall firewall delete rule name=""Adobe Unlicensed Pop-up"""
				$iPID = Run($sCmdInfo, "", @SW_HIDE, BitOR($STDERR_CHILD, $STDOUT_CHILD))
				ProcessWaitClose($iPID)
				$sCmdInfo = "netsh advfirewall firewall add rule name=""Adobe Unlicensed Pop-up"" dir=out action=block remoteip=""" & $sIPs & """"
				$iPID = Run($sCmdInfo, "", @SW_HIDE, BitOR($STDERR_CHILD, $STDOUT_CHILD))
				ProcessWaitClose($iPID)
				LogWrite(1, "Windows Firewall Rule added, blocking:" & @CRLF & @CRLF & StringReplace($sIPs, ",", @CRLF) & @CRLF)
			EndIf
			ToggleLog(1)
		Else
			If $bAbort = False Then
				LogWrite(1, "Detected 3rd party firewall: " & $sOutput & "---" & @CRLF & "This will disable Windows Firewall, so you will have to manually create an OUTBOUND rule in " & StringReplace($sOutput, @CRLF, "") & " to block the following IP addresses: " & @CRLF & @CRLF & StringReplace($sIPs, ",", @CRLF) & @CRLF)
			Else
				LogWrite(0, "Detected 3rd party firewall: " & $sOutput & "---" & @CRLF & "This will disable Windows Firewall, so you will have to manually create an OUTBOUND rule in " & StringReplace($sOutput, @CRLF, "") & " to block pop-ups from Adobe domains." & @CRLF)
			EndIf
			ToggleLog(1)
		EndIf
	Else
		LogWrite(1, "No Internet Connectivity" & @CRLF & "---" & @CRLF & "Powershell was unable to connect to the Internet to fetch current IP addresses. Check you are not blocking it with a firewall." & @CRLF)
		ToggleLog(1)
		GUICtrlSetState($idBtnBlockPopUp, 64)
	EndIf
EndFunc   ;==>BlockPopUp

;---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Func _ListView_LeftClick($hListView, $lParam)
	Local $tInfo = DllStructCreate($tagNMITEMACTIVATE, $lParam)
	Local $iIndex = DllStructGetData($tInfo, "Index")

	If $iIndex <> -1 Then
		Local $iX = DllStructGetData($tInfo, "X")
		Local $aIconRect = _GUICtrlListView_GetItemRect($hListView, $iIndex, 1)
		If $iX < $aIconRect[0] And $iX >= 5 Then
			Return 0
		Else
			Local $aHit
			$aHit = _GUICtrlListView_HitTest($g_idListview)
			If $aHit[0] <> -1 Then
				Local $GroupIdOfHitItem = _GUICtrlListView_GetItemGroupID($idListview, $aHit[0])
				If _GUICtrlListView_GetItemChecked($g_idListview, $aHit[0]) = 1 Then
					For $i = 0 To _GUICtrlListView_GetItemCount($idListview) - 1
						If _GUICtrlListView_GetItemGroupID($idListview, $i) = $GroupIdOfHitItem Then
							_GUICtrlListView_SetItemChecked($g_idListview, $i, 0)
						EndIf
					Next
				Else
					For $i = 0 To _GUICtrlListView_GetItemCount($idListview) - 1
						If _GUICtrlListView_GetItemGroupID($idListview, $i) = $GroupIdOfHitItem Then
							_GUICtrlListView_SetItemChecked($g_idListview, $i, 1)
						EndIf
					Next
				EndIf
				;$g_iIndex = $aHit[0]
			EndIf
		EndIf
	EndIf
EndFunc   ;==>_ListView_LeftClick


Func _ListView_RightClick()
	Local $aHit
	$aHit = _GUICtrlListView_HitTest($g_idListview)
	If $aHit[0] <> -1 Then
		If _GUICtrlListView_GetItemChecked($g_idListview, $aHit[0]) = 1 Then
			_GUICtrlListView_SetItemChecked($g_idListview, $aHit[0], 0)
		Else
			_GUICtrlListView_SetItemChecked($g_idListview, $aHit[0], 1)
		EndIf
		;$g_iIndex = $aHit[0]
	EndIf
EndFunc   ;==>_ListView_RightClick

Func _Assign_Groups_To_Found_Files()

	;_GUICtrlListView_RemoveAllGroups ( $idListview )
	Local $MyListItemCount = _GUICtrlListView_GetItemCount($idListview)
	Local $ItemFromList

	;MsgBox(-1,"ItemCount",_GUICtrlListView_GetItemCount($idListview))
	;MsgBox(-1,"GroupCount",_GUICtrlListView_GetGroupCount($idListview))

	For $i = 0 To $MyListItemCount - 1
		_GUICtrlListView_SetItemChecked($idListview, $i)

		; Build groups
		$ItemFromList = _GUICtrlListView_GetItemText($idListview, $i, 1)

		Select
			Case StringInStr($ItemFromList, "Acrobat")
				_GUICtrlListView_InsertGroup($idListview, $i, 1, "", 1)
				_GUICtrlListView_SetItemGroupID($idListview, $i, 1)
				_GUICtrlListView_SetGroupInfo($idListview, 1, "Acrobat", 1, $LVGS_COLLAPSIBLE)

			Case StringInStr($ItemFromList, "Aero")
				_GUICtrlListView_InsertGroup($idListview, $i, 2, "", 1)
				_GUICtrlListView_SetItemGroupID($idListview, $i, 2)
				_GUICtrlListView_SetGroupInfo($idListview, 2, "Aero", 1, $LVGS_COLLAPSIBLE)

			Case StringInStr($ItemFromList, "After Effects")
				_GUICtrlListView_InsertGroup($idListview, $i, 3, "", 1)
				_GUICtrlListView_SetItemGroupID($idListview, $i, 3)
				_GUICtrlListView_SetGroupInfo($idListview, 3, "After Effects", 1, $LVGS_COLLAPSIBLE)


			Case StringInStr($ItemFromList, "Animate")
				_GUICtrlListView_InsertGroup($idListview, $i, 4, "", 1)
				_GUICtrlListView_SetItemGroupID($idListview, $i, 4)
				_GUICtrlListView_SetGroupInfo($idListview, 4, "Animate", 1, $LVGS_COLLAPSIBLE)


			Case StringInStr($ItemFromList, "Audition")
				_GUICtrlListView_InsertGroup($idListview, $i, 5, "", 1)
				_GUICtrlListView_SetItemGroupID($idListview, $i, 5)
				_GUICtrlListView_SetGroupInfo($idListview, 5, "Audition", 1, $LVGS_COLLAPSIBLE)

			Case StringInStr($ItemFromList, "Adobe Bridge")
				_GUICtrlListView_InsertGroup($idListview, $i, 6, "", 1)
				_GUICtrlListView_SetItemGroupID($idListview, $i, 6)
				_GUICtrlListView_SetGroupInfo($idListview, 6, "Bridge", 1, $LVGS_COLLAPSIBLE)

			Case StringInStr($ItemFromList, "Character Animator")
				_GUICtrlListView_InsertGroup($idListview, $i, 7, "", 1)
				_GUICtrlListView_SetItemGroupID($idListview, $i, 7)
				_GUICtrlListView_SetGroupInfo($idListview, 7, "Character Animator", 1, $LVGS_COLLAPSIBLE)


			Case StringInStr($ItemFromList, "AppsPanel")
				_GUICtrlListView_InsertGroup($idListview, $i, 8, "", 1)
				_GUICtrlListView_SetItemGroupID($idListview, $i, 8)
				_GUICtrlListView_SetGroupInfo($idListview, 8, "Creative Cloud", 1, $LVGS_COLLAPSIBLE)

			Case StringInStr($ItemFromList, "Adobe Desktop Service")
				_GUICtrlListView_InsertGroup($idListview, $i, 8, "", 1)
				_GUICtrlListView_SetItemGroupID($idListview, $i, 8)
				_GUICtrlListView_SetGroupInfo($idListview, 8, "Creative Cloud", 1, $LVGS_COLLAPSIBLE)

			Case StringInStr($ItemFromList, "Dimension")
				_GUICtrlListView_InsertGroup($idListview, $i, 9, "", 1)
				_GUICtrlListView_SetItemGroupID($idListview, $i, 9)
				_GUICtrlListView_SetGroupInfo($idListview, 9, "Dimension", 1, $LVGS_COLLAPSIBLE)

			Case StringInStr($ItemFromList, "Dreamweaver")
				_GUICtrlListView_InsertGroup($idListview, $i, 10, "", 1)
				_GUICtrlListView_SetItemGroupID($idListview, $i, 10)
				_GUICtrlListView_SetGroupInfo($idListview, 10, "Dreamweaver", 1, $LVGS_COLLAPSIBLE)

			Case StringInStr($ItemFromList, "Illustrator")
				_GUICtrlListView_InsertGroup($idListview, $i, 11, "", 1)
				_GUICtrlListView_SetItemGroupID($idListview, $i, 11)
				_GUICtrlListView_SetGroupInfo($idListview, 11, "Illustrator", 1, $LVGS_COLLAPSIBLE)

			Case StringInStr($ItemFromList, "InCopy")
				_GUICtrlListView_InsertGroup($idListview, $i, 12, "", 1)
				_GUICtrlListView_SetItemGroupID($idListview, $i, 12)
				_GUICtrlListView_SetGroupInfo($idListview, 12, "InCopy", 1, $LVGS_COLLAPSIBLE)

			Case StringInStr($ItemFromList, "InDesign")
				_GUICtrlListView_InsertGroup($idListview, $i, 13, "", 1)
				_GUICtrlListView_SetItemGroupID($idListview, $i, 13)
				_GUICtrlListView_SetGroupInfo($idListview, 13, "InDesign", 1, $LVGS_COLLAPSIBLE)

			Case StringInStr($ItemFromList, "Lightroom CC")
				_GUICtrlListView_InsertGroup($idListview, $i, 14, "", 1)
				_GUICtrlListView_SetItemGroupID($idListview, $i, 14)
				_GUICtrlListView_SetGroupInfo($idListview, 14, "Lightroom CC", 1, $LVGS_COLLAPSIBLE)

			Case StringInStr($ItemFromList, "Lightroom Classic")
				_GUICtrlListView_InsertGroup($idListview, $i, 15, "", 1)
				_GUICtrlListView_SetItemGroupID($idListview, $i, 15)
				_GUICtrlListView_SetGroupInfo($idListview, 15, "Lightroom Classic", 1, $LVGS_COLLAPSIBLE)

			Case StringInStr($ItemFromList, "Media Encoder")
				_GUICtrlListView_InsertGroup($idListview, $i, 16, "", 1)
				_GUICtrlListView_SetItemGroupID($idListview, $i, 16)
				_GUICtrlListView_SetGroupInfo($idListview, 16, "Media Encoder", 1, $LVGS_COLLAPSIBLE)

			Case StringInStr($ItemFromList, "Photoshop")
				_GUICtrlListView_InsertGroup($idListview, $i, 17, "", 1)
				_GUICtrlListView_SetItemGroupID($idListview, $i, 17)
				_GUICtrlListView_SetGroupInfo($idListview, 17, "Photoshop", 1, $LVGS_COLLAPSIBLE)

			Case StringInStr($ItemFromList, "Premiere Pro")
				_GUICtrlListView_InsertGroup($idListview, $i, 18, "", 1)
				_GUICtrlListView_SetItemGroupID($idListview, $i, 18)
				_GUICtrlListView_SetGroupInfo($idListview, 18, "Premiere Pro", 1, $LVGS_COLLAPSIBLE)

			Case StringInStr($ItemFromList, "Premiere Rush")
				_GUICtrlListView_InsertGroup($idListview, $i, 19, "", 1)
				_GUICtrlListView_SetItemGroupID($idListview, $i, 19)
				_GUICtrlListView_SetGroupInfo($idListview, 19, "Premiere Rush", 1, $LVGS_COLLAPSIBLE)

			Case StringInStr($ItemFromList, "Substance 3D Designer")
				_GUICtrlListView_InsertGroup($idListview, $i, 20, "", 1)
				_GUICtrlListView_SetItemGroupID($idListview, $i, 20)
				_GUICtrlListView_SetGroupInfo($idListview, 20, "Substance 3D Designer", 1, $LVGS_COLLAPSIBLE)

			Case StringInStr($ItemFromList, "Substance 3D Modeler")
				_GUICtrlListView_InsertGroup($idListview, $i, 21, "", 1)
				_GUICtrlListView_SetItemGroupID($idListview, $i, 21)
				_GUICtrlListView_SetGroupInfo($idListview, 21, "Substance 3D Modeler", 1, $LVGS_COLLAPSIBLE)

			Case StringInStr($ItemFromList, "Substance 3D Painter")
				_GUICtrlListView_InsertGroup($idListview, $i, 22, "", 1)
				_GUICtrlListView_SetItemGroupID($idListview, $i, 22)
				_GUICtrlListView_SetGroupInfo($idListview, 22, "Substance 3D Painter", 1, $LVGS_COLLAPSIBLE)

			Case StringInStr($ItemFromList, "Substance 3D Sampler")
				_GUICtrlListView_InsertGroup($idListview, $i, 23, "", 1)
				_GUICtrlListView_SetItemGroupID($idListview, $i, 23)
				_GUICtrlListView_SetGroupInfo($idListview, 23, "Substance 3D Sampler", 1, $LVGS_COLLAPSIBLE)

			Case StringInStr($ItemFromList, "Substance 3D Stager")
				_GUICtrlListView_InsertGroup($idListview, $i, 24, "", 1)
				_GUICtrlListView_SetItemGroupID($idListview, $i, 24)
				_GUICtrlListView_SetGroupInfo($idListview, 24, "Substance 3D Stager", 1, $LVGS_COLLAPSIBLE)

			Case StringInStr($ItemFromList, "Adobe.Fresco")
				_GUICtrlListView_InsertGroup($idListview, $i, 25, "", 1)
				_GUICtrlListView_SetItemGroupID($idListview, $i, 25)
				_GUICtrlListView_SetGroupInfo($idListview, 25, "Fresco", 1, $LVGS_COLLAPSIBLE)

			Case StringInStr($ItemFromList, "Adobe.XD")
				_GUICtrlListView_InsertGroup($idListview, $i, 26, "", 1)
				_GUICtrlListView_SetItemGroupID($idListview, $i, 26)
				_GUICtrlListView_SetGroupInfo($idListview, 26, "XD", 1, $LVGS_COLLAPSIBLE)

			Case StringInStr($ItemFromList, "PhotoshopExpress")
				_GUICtrlListView_InsertGroup($idListview, $i, 27, "", 1)
				_GUICtrlListView_SetItemGroupID($idListview, $i, 27)
				_GUICtrlListView_SetGroupInfo($idListview, 27, "PhotoshopExpress", 1, $LVGS_COLLAPSIBLE)

			Case Else
				_GUICtrlListView_InsertGroup($idListview, $i, 28, "", 1)
				_GUICtrlListView_SetItemGroupID($idListview, $i, 28)
				_GUICtrlListView_SetGroupInfo($idListview, 28, "Else", 1, $LVGS_COLLAPSIBLE)
		EndSelect
	Next

	;MsgBox(-1,"ItemCount",_GUICtrlListView_GetItemCount($idListview))
	;MsgBox(-1,"GroupCount",_GUICtrlListView_GetGroupCount($idListview))

EndFunc   ;==>_Assign_Groups_To_Found_Files

Func _Collapse_All_Click()
	Local $aInfo, $aCount = _GUICtrlListView_GetGroupCount($idListview) ; Group Count
	If $aCount > 0 Then
		If $MyLVGroupIsExpanded = 1 Then
			; Change group information
			For $i = 1 To 28
				$aInfo = _GUICtrlListView_GetGroupInfo($idListview, $i)
				_GUICtrlListView_SetGroupInfo($idListview, $i, $aInfo[0], $aInfo[1], $LVGS_COLLAPSED)
			Next
		Else
			_Expand_All_Click()
		EndIf
		$MyLVGroupIsExpanded = Not $MyLVGroupIsExpanded
	EndIf

EndFunc   ;==>_Collapse_All_Click


Func _Expand_All_Click()
	Local $aInfo, $aCount = _GUICtrlListView_GetGroupCount($idListview) ; Group Count
	If $aCount > 0 Then
		; Change group information
		For $i = 1 To 28
			$aInfo = _GUICtrlListView_GetGroupInfo($idListview, $i)
			_GUICtrlListView_SetGroupInfo($idListview, $i, $aInfo[0], $aInfo[1], $LVGS_NORMAL)
			_GUICtrlListView_SetGroupInfo($idListview, $i, $aInfo[0], $aInfo[1], $LVGS_COLLAPSIBLE)
		Next
	EndIf

EndFunc   ;==>_Expand_All_Click

Func WM_COMMAND($hWnd, $Msg, $wParam, $lParam)
	If BitAND($wParam, 0x0000FFFF) = $idButtonStop Then $fInterrupt = 1
	Return $GUI_RUNDEFMSG
EndFunc   ;==>WM_COMMAND

Func WM_NOTIFY($hWnd, $iMsg, $wParam, $lParam)
	#forceref $hWnd, $iMsg, $wParam, $lParam
	Local $tNMHDR = DllStructCreate($tagNMHDR, $lParam)
	Local $hWndFrom = HWnd(DllStructGetData($tNMHDR, "hWndFrom"))
	Local $iCode = DllStructGetData($tNMHDR, "Code")
	Switch $hWndFrom
		Case $g_idListview
			Switch $iCode
				Case $LVN_COLUMNCLICK ; A column was clicked
					_Collapse_All_Click()
					; No return value
				Case $NM_CLICK ; Sent by a list-view control when the user clicks an item with the left mouse button
					_ListView_LeftClick($g_idListview, $lParam)
					; No return value
				Case $NM_RCLICK ; Sent by a list-view control when the user clicks an item with the right mouse button
					_ListView_RightClick()
					; No return value
			EndSwitch
	EndSwitch
	Return $GUI_RUNDEFMSG
EndFunc   ;==>WM_NOTIFY

Func _Exit()
	FileDelete(@WindowsDir & "\Temp\RunAsTI.exe")
	Exit
EndFunc   ;==>_Exit

Func IniReadArray($FileName, $section, $key, $default)
	Local $sINI = IniRead($FileName, $section, $key, $default)
	$sINI = StringReplace($sINI, '"', '')
	StringReplace($sINI, ",", ",")
	Local $aSize = @extended
	Local $aReturn[$aSize + 1]
	Local $aSplit = StringSplit($sINI, ",")
	For $i = 0 To $aSize
		$aReturn[$i] = $aSplit[$i + 1]
	Next
	Return $aReturn
EndFunc   ;==>IniReadArray

Func ReplaceToArray($sParam)
	Local $sString = StringReplace($sParam, '"', '')
	StringReplace($sString, ",", ",")
	Local $aSize = @extended
	Local $aReturn[$aSize + 1]
	Local $aSplit = StringSplit($sString, ",")
	For $i = 0 To $aSize
		$aReturn[$i] = $aSplit[$i + 1]
	Next
	Return $aReturn
EndFunc   ;==>ReplaceToArray

Func _IsChecked($idControlID)
	Return BitAND(GUICtrlRead($idControlID), $GUI_CHECKED) = $GUI_CHECKED
EndFunc   ;==>_IsChecked


Func SaveOptionsToConfig()

	If _IsChecked($idFindACC) Then
		IniWrite($sINIPath, "Options", "FindACC", "1")
	Else
		IniWrite($sINIPath, "Options", "FindACC", "0")
	EndIf
	If _IsChecked($idEnableMD5) Then
		IniWrite($sINIPath, "Options", "EnableMD5", "1")
	Else
		IniWrite($sINIPath, "Options", "EnableMD5", "0")
	EndIf
	If _IsChecked($idOnlyAdobeFolders) Then
		IniWrite($sINIPath, "Options", "OnlyAdobeFolders", "1")
	Else
		IniWrite($sINIPath, "Options", "OnlyAdobeFolders", "0")
	EndIf
	If _IsChecked($idUseCustomDomains) Then
		IniWrite($sINIPath, "Options", "UseCustomDomains", "1")
	Else
		IniWrite($sINIPath, "Options", "UseCustomDomains", "0")
	EndIf
	If Not StringInStr(GUICtrlRead($idCustomDomainsInput), ".adobestats.io") Then
		IniWrite($sINIPath, "Options", "CustomDomains", "'8eptecerpq.adobestats.io','xa8g202i4u.adobestats.io'")
		GUICtrlSetData($idCustomDomainsInput, "8eptecerpq.adobestats.io" & @CRLF & "xa8g202i4u.adobestats.io")
		$sCustomDomains = "'8eptecerpq.adobestats.io','xa8g202i4u.adobestats.io'"
	Else
		IniWrite($sINIPath, "Options", "CustomDomains", """'" & StringReplace(GUICtrlRead($idCustomDomainsInput), @CRLF, "','") & "'""")
	EndIf

EndFunc   ;==>SaveOptionsToConfig

Func DestroyAGS()
	GUICtrlSetState($idBtnDestroyAGS, 128)
	_GUICtrlTab_SetCurFocus($hTab, 3)

	MemoWrite(@CRLF & "Removing AGS from this Computer" & @CRLF & "---" & @CRLF & "Please wait...")

	$sCmdInfo = "PowerShell Set-ExecutionPolicy Bypass -scope Process -Force;"

	$sCmdInfo &= "Stop-Process -Name ""AGMService"" -Force -ErrorAction SilentlyContinue;"
	$sCmdInfo &= "Stop-Process -Name ""AGSService"" -Force -ErrorAction SilentlyContinue;"
	$sCmdInfo &= "Remove-Item -Path ""C:\Program Files (x86)\Common Files\Adobe\AdobeGCClient"" -Recurse -Force -ErrorAction SilentlyContinue;"
	$sCmdInfo &= "Remove-Item -Path ""C:\Program Files (x86)\Common Files\Adobe\OOBE\PDApp\AdobeGCClient"" -Recurse -Force -ErrorAction SilentlyContinue;"
	$sCmdInfo &= "sc.exe delete ""AGMService"";"
	$sCmdInfo &= "sc.exe delete ""AGSService"";"
	$sCmdInfo &= "Remove-Item -Path ""C:\Users\Public\Documents\AdobeGCData"" -Recurse -Force -ErrorAction SilentlyContinue;"
	$sCmdInfo &= "Remove-Item -Path ""C:\Windows\System32\Tasks\AdobeGCInvoker-1.0"" -Force -ErrorAction SilentlyContinue;"
	$sCmdInfo &= "Remove-Item -Path ""C:\Windows\System32\Tasks_Migrated\AdobeGCInvoker-1.0"" -Force -ErrorAction SilentlyContinue;"
	$sCmdInfo &= "Remove-Item -Path ""C:\Program Files (x86)\Adobe\Adobe Creative Cloud\Utils\AdobeGenuineValidator.exe"" -Force -ErrorAction SilentlyContinue;"
	$sCmdInfo &= "Remove-Item -Path ""C:\Windows\Temp\adobegc.log"" -Force -ErrorAction SilentlyContinue;"
	$sCmdInfo &= "Remove-Item -Path ""C:\Users\maxfa\AppData\Local\Temp\adobegc.log"" -Force -ErrorAction SilentlyContinue;"

	Local $iPID = Run($sCmdInfo, "", @SW_HIDE, BitOR($STDERR_CHILD, $STDOUT_CHILD))
	Local $sOutput = ""
	While 1
		$sOutput &= StdoutRead($iPID)
		If @error Then ExitLoop
	WEnd
	ProcessWaitClose($iPID)
	LogWrite(1, "Removing AGS: Commands completed successfully." & @CRLF)
	ToggleLog(1)

EndFunc   ;==>DestroyAGS

Func EditHosts()
	Local $sHostsPath = "C:\Windows\System32\drivers\etc\hosts"
	Local $sBackupPath = "C:\Windows\System32\drivers\etc\hosts.bak"

	; Remove the read-only attribute
	FileSetAttrib($sHostsPath, "-R")

	; If the backup file doesn't exist, create it
	If Not FileExists($sBackupPath) Then
		FileCopy($sHostsPath, $sBackupPath)
	EndIf

	; Open the hosts file with Notepad
	Run("notepad.exe " & $sHostsPath)

	; Wait for the hosts file to be closed
	While ProcessExists("notepad.exe")
		Sleep(1000) ; Wait for 1 second
	WEnd

	; Reset the read-only attribute
	FileSetAttrib($sHostsPath, "+R")
EndFunc   ;==>EditHosts

Func RestoreHosts()
	_GUICtrlTab_SetCurFocus($hTab, 3)
	MemoWrite(@CRLF & "Restoring the hosts file from backup..." & @CRLF & "---" & @CRLF & "Please wait..." & @CRLF)
	Local $sHostsPath = "C:\Windows\System32\drivers\etc\hosts"
	Local $sBackupPath = "C:\Windows\System32\drivers\etc\hosts.bak"

	; If the backup file exists, restore it
	If FileExists($sBackupPath) Then
		; Remove the read-only attribute from the hosts file
		FileSetAttrib($sHostsPath, "-R")

		; Replace the hosts file with the backup file
		FileCopy($sBackupPath, $sHostsPath, 1)

		; Reset the read-only attribute
		FileSetAttrib($sHostsPath, "+R")

		; Delete the backup file
		FileDelete($sBackupPath)
		LogWrite(1, "Restoring the hosts file from backup: Commands completed successfully." & @CRLF)
	Else
		LogWrite(1, "Restoring the hosts file from backup: No backup file found." & @CRLF)
	EndIf
	ToggleLog(1)
EndFunc   ;==>RestoreHosts

Func CleanFirewall()
	_GUICtrlTab_SetCurFocus($hTab, 3)
	Local $sCmdInfo = "netsh advfirewall firewall delete rule name=""Adobe Unlicensed Pop-up"""
	Local $iPID = Run($sCmdInfo, "", @SW_HIDE, BitOR($STDERR_CHILD, $STDOUT_CHILD))
	Local $sOutput = ""
	While 1
		$sOutput &= StdoutRead($iPID)
		If @error Then ExitLoop
	WEnd
	ProcessWaitClose($iPID)
	LogWrite(1, "Removing Adobe Firewall Blocks:" & @CRLF & $sOutput & @CRLF)

	ToggleLog(1)
EndFunc   ;==>CleanFirewall

Func OpenWF()
	Run("mmc.exe C:\Windows\System32\wf.msc")
	ConsoleWrite("Opening Windows Firewall...")
EndFunc   ;==>OpenWF

Func EnableDisableWFRules()
	_GUICtrlTab_SetCurFocus($hTab, 3)
	MemoWrite(@CRLF & "Checking state of Windows Firewall Rules..." & @CRLF & "---" & @CRLF & "Please wait...")
	Local $sCmdInfo = "PowerShell Set-ExecutionPolicy Bypass -scope Process -Force;try{$name = (Get-NetFirewallRule -DisplayName 'Adobe Unlicensed Pop-up').Name} catch{$name='no'};If($name -ne 'no'){(Get-NetFirewallRule -Name $name).Enabled};"
	Local $iPID = Run($sCmdInfo, "", @SW_HIDE, BitOR($STDERR_CHILD, $STDOUT_CHILD))
	Local $sOutput = ""
	While 1
		$sOutput &= StdoutRead($iPID)
		If @error Then ExitLoop
	WEnd
	ProcessWaitClose($iPID)

	If StringInStr($sOutput, "True") > 0 Then
		; If the rule is enabled, disable it
		$sCmdInfo = 'netsh advfirewall firewall set rule name="Adobe Unlicensed Pop-up" new enable=no'
		$iPID = Run($sCmdInfo, "", @SW_HIDE, BitOR($STDERR_CHILD, $STDOUT_CHILD))
		LogWrite(1, "Disabling Windows Firewall Rule: Adobe Unlicensed Pop-up" & @CRLF)
	Else
		; If the rule is disabled, enable it
		$sCmdInfo = 'netsh advfirewall firewall set rule name="Adobe Unlicensed Pop-up" new enable=yes'
		$iPID = Run($sCmdInfo, "", @SW_HIDE, BitOR($STDERR_CHILD, $STDOUT_CHILD))
		LogWrite(1, "Enabling Windows Firewall Rule: Adobe Unlicensed Pop-up" & @CRLF)
	EndIf
	Local $sOutput = ""
	While 1
		$sOutput &= StdoutRead($iPID)
		If @error Then ExitLoop
	WEnd
	ProcessWaitClose($iPID)
	LogWrite(0, "Windows Firewall Rule Status: " & $sOutput & @CRLF)
	ToggleLog(1)
EndFunc   ;==>EnableDisableWFRules
