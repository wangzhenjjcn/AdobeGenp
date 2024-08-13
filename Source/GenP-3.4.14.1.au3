#NoTrayIcon
#RequireAdmin
#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=ICONS/Logo.ico
#AutoIt3Wrapper_Outfile_x64=GenP-3.4.14.1.exe
#AutoIt3Wrapper_Res_Comment=GenP v3.4.14.1
#AutoIt3Wrapper_Res_Description=GenP v3.4.14.1
#AutoIt3Wrapper_Res_Fileversion=3.4.14.1
#AutoIt3Wrapper_Res_ProductName=GenP v3.4.14.1
#AutoIt3Wrapper_Res_ProductVersion=3.4.14.1
#AutoIt3Wrapper_Res_CompanyName=GenP
#AutoIt3Wrapper_Res_LegalCopyright=GenP
#AutoIt3Wrapper_Res_LegalTradeMarks=GenP
#AutoIt3Wrapper_Res_requestedExecutionLevel=asInvoker
#AutoIt3Wrapper_Run_Au3Stripper=y
#Au3Stripper_Parameters=/pe /sf /sv /rm
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****

#include <ProgressConstants.au3>
#include <WindowsConstants.au3>
#include <GUIConstantsEx.au3>
#include <EditConstants.au3>
#include <GuiListView.au3>
#include <WinAPIProc.au3>
#include <Constants.au3>
#include <String.au3>
#include <WinAPI.au3>
#include <Misc.au3>

AutoItSetOption("GUICloseOnESC", 0)  ;1=ESC closes, 0=ESC won't close

Global Const $g_AppWndTitle = "GenP v3.4.14.1", $g_AppVersion = "Original version by uncia/CGP - GenP Community Edition - v3.4.14.1"

If _Singleton($g_AppWndTitle, 1) = 0 Then
	Exit
EndIf

Global $MyLVGroupIsExpanded = True
Global $fInterrupt = 0
Global $FilesToPatch[0][1], $FilesToPatchNull[0][1]
Global $FilesToRestore[0][1], $fFilesListed = 0
Global $MyhGUI, $hTab, $hMainTab, $hLogTab, $idMsg, $idListview, $g_idListview, $idButtonSearch, $idButtonStop
Global $idButtonCustomFolder, $idBtnCure, $idBtnDeselectAll, $ListViewSelectFlag = 1
Global $idBtnBlockPopUp, $idBtnPatchCC, $idMemo, $timestamp, $idLog, $idBtnRestore, $idBtnCopyLog

Global $sINIPath = @ScriptDir & "\config.ini"
If Not FileExists($sINIPath) Then
	FileInstall("config.ini", @ScriptDir & "\config.ini")
EndIf

Global $MyDefPath = IniRead($sINIPath, "Default", "Path", "C:\Program Files\Adobe")
If Not FileExists($MyDefPath) Or Not StringInStr(FileGetAttrib($MyDefPath), "D") Then
	IniWrite($sINIPath, "Default", "Path", "C:\Program Files\Adobe")
	$MyDefPath = "C:\Program Files\Adobe"
EndIf

FileInstall("NSudoLG.exe", @TempDir & "\NSudoLG.exe", 1)

Local $sNSudoLGPath = @TempDir & "\NSudoLG.exe"

If Not (@UserName = "SYSTEM") And FileExists($sNSudoLGPath) Then
	Local $iAnswer = MsgBox(4, "TrustedInstaller", "Do you wish to elevate GenP to TrustedInstaller to allow for patching of XD/UWP apps? Do not use this option if you encounter any issues, it is experimental!")
	If $iAnswer = 6 Then
		Exit Run($sNSudoLGPath & ' -U:T -P:E -M:S "' & @ScriptFullPath & '"')
	EndIf
Else
	Local $sFixPath = "C:\Windows\System32\config\systemprofile\Desktop"
	If Not FileExists($sFixPath) Then
		DirCreate($sFixPath)
	EndIf
EndIf

FileDelete($sNSudoLGPath)

Global $MyRegExpGlobalPatternSearchCount = 0, $Count = 0, $idProgressBar
Global $aOutHexGlobalArray[0], $aNullArray[0], $aInHexArray[0]
Global $MyFileToParse = "", $MyFileToParsSweatPea = "", $MyFileToParseEaclient = ""
Global $sz_type, $bFoundAcro32 = False, $bFoundLrARM = False, $bFoundCCARM = False, $bFoundPsARM = False, $bFoundGenericARM = False, $aSpecialFiles, $sSpecialFiles = "|"
Global $ProgressFileCountScale, $FileSearchedCount

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

While 1
	$idMsg = GUIGetMsg()

	Select
		Case $idMsg = $GUI_EVENT_CLOSE
			GUIDelete($MyhGUI)
			Exit
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
			GUICtrlSetState($idBtnPatchCC, 64)

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
			GUICtrlSetState($idBtnPatchCC, 128)
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
			Local $aSize = DirGetSize($MyDefPath, $DIR_EXTENDED)     ; extended mode
			If UBound($aSize) >= 2 Then
				$FileCount = $aSize[1]
				$ProgressFileCountScale = 100 / $FileCount
				$FileSearchedCount = 0
				ProgressWrite(0)
				RecursiveFileSearch($MyDefPath, 0, $FileCount)   ;Search through all files and folders
				Sleep(100)
				ProgressWrite(0)
			EndIf

			If $MyDefPath = "C:\Program Files" Or $MyDefPath = "C:\Program Files\Adobe" Then
				Local $sProgramFiles = EnvGet('ProgramFiles(x86)') & "\Common Files\Adobe"
				$aSize = DirGetSize($sProgramFiles, $DIR_EXTENDED)     ; extended mode
				If UBound($aSize) >= 2 Then
					$FileCount = $aSize[1]
					RecursiveFileSearch($sProgramFiles, 0, $FileCount)   ;Search through all files and folders
					ProgressWrite(0)
				EndIf
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
			GUICtrlSetState($idBtnPatchCC, 64)

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


		Case $idMsg = $idBtnBlockPopUp     ; Pop-up button
			ToggleLog(0)
			BlockPopUp()

		Case $idMsg = $idBtnPatchCC     ; Patch Creative Cloud button
			Global $appsPanelFile
			Global $containerBLFile
			Global $adobeDesktopServiceFile
			ToggleLog(0)
			GUICtrlSetState($hLogTab, $GUI_SHOW)
			GUICtrlSetState($idBtnDeselectAll, 128)
			GUICtrlSetState($idBtnBlockPopUp, 128)
			GUICtrlSetState($idListview, 128)
			GUICtrlSetState($idButtonCustomFolder, 128)
			GUICtrlSetState($idButtonSearch, 128)
			GUICtrlSetState($idBtnPatchCC, 128)
			If FileExists("C:\Program Files\Common Files\Adobe\Adobe Desktop Common\AppsPanel\AppsPanelBL.dll") Then
				$appsPanelFile = "C:\Program Files\Common Files\Adobe\Adobe Desktop Common\AppsPanel\AppsPanelBL.dll"
			ElseIf FileExists("C:\Program Files (x86)\Common Files\Adobe\Adobe Desktop Common\AppsPanel\AppsPanelBL.dll") Then
				$appsPanelFile = "C:\Program Files (x86)\Common Files\Adobe\Adobe Desktop Common\AppsPanel\AppsPanelBL.dll"
			Else
				$appsPanelFile = FileOpenDialog("Select a File", @ScriptDir, "AppsPanelBL.dll (AppsPanelBL.dll)")
			EndIf
			ProgressWrite(0)
			If FileExists($appsPanelFile) Then
				MyGlobalPatternSearch($appsPanelFile)
				Sleep(100)
				MemoWrite(@CRLF & "File Path:" & @CRLF & "" & @CRLF & $appsPanelFile & @CRLF & "" & @CRLF & "")
				Sleep(100)
				MyGlobalPatternPatch($appsPanelFile, $aOutHexGlobalArray)
				Sleep(500)
			EndIf
			ProgressWrite(0)
			If $bFoundCCARM = False Then
				If FileExists("C:\Program Files\Common Files\Adobe\Adobe Desktop Common\ADS\ContainerBL.dll") Then
					$containerBLFile = "C:\Program Files\Common Files\Adobe\Adobe Desktop Common\ADS\ContainerBL.dll"
				ElseIf FileExists("C:\Program Files (x86)\Common Files\Adobe\Adobe Desktop Common\ADS\ContainerBL.dll") Then
					$containerBLFile = "C:\Program Files (x86)\Common Files\Adobe\Adobe Desktop Common\ADS\ContainerBL.dll"
				Else
					$containerBLFile = FileOpenDialog("Select a File", @ScriptDir, "ContainerBL.dll (ContainerBL.dll)")
				EndIf
				ProgressWrite(0)
				If FileExists($containerBLFile) Then
					MyGlobalPatternSearch($containerBLFile)
					Sleep(100)
					MemoWrite(@CRLF & "File Path:" & @CRLF & "" & @CRLF & $containerBLFile & @CRLF & "" & @CRLF & "")
					Sleep(100)
					MyGlobalPatternPatch($containerBLFile, $aOutHexGlobalArray)
					Sleep(500)
				EndIf
				ProgressWrite(0)
				If FileExists("C:\Program Files\Common Files\Adobe\Adobe Desktop Common\ADS\Adobe Desktop Service.exe") Then
					$adobeDesktopServiceFile = "C:\Program Files\Common Files\Adobe\Adobe Desktop Common\ADS\Adobe Desktop Service.exe"
				ElseIf FileExists("C:\Program Files (x86)\Common Files\Adobe\Adobe Desktop Common\ADS\Adobe Desktop Service.exe") Then
					$adobeDesktopServiceFile = "C:\Program Files (x86)\Common Files\Adobe\Adobe Desktop Common\ADS\Adobe Desktop Service.exe"
				Else
					$adobeDesktopServiceFile = FileOpenDialog("Select a File", @ScriptDir, "Adobe Desktop Service.exe (Adobe Desktop Service.exe)")
				EndIf
				If FileExists($adobeDesktopServiceFile) Then
					MyGlobalPatternSearch($adobeDesktopServiceFile)
					Sleep(100)
					MemoWrite(@CRLF & "File Path:" & @CRLF & "" & @CRLF & $adobeDesktopServiceFile & @CRLF & "" & @CRLF & "")
					Sleep(100)
					MyGlobalPatternPatch($adobeDesktopServiceFile, $aOutHexGlobalArray)
					Sleep(500)
				EndIf
				ProgressWrite(0)
				MemoWrite(@CRLF & "All files patched." & @CRLF & "" & @CRLF & "")
			Else
				ProgressWrite(0)
				MemoWrite(@CRLF & "Creative Cloud patching aborted due to unsupported architecture." & @CRLF & "" & @CRLF & "")
				$bFoundCCARM = False
			EndIf
			GUICtrlSetState($idBtnDeselectAll, 64)
			GUICtrlSetState($idBtnBlockPopUp, 64)
			GUICtrlSetState($idListview, 64)
			GUICtrlSetState($idButtonCustomFolder, 64)
			GUICtrlSetState($idButtonSearch, 64)
			GUICtrlSetState($idBtnPatchCC, 64)

		Case $idMsg = $idBtnCure
			ToggleLog(0)
			GUICtrlSetState($idListview, 128)
			GUICtrlSetState($idBtnDeselectAll, 128)
			GUICtrlSetState($idButtonSearch, 128)
			GUICtrlSetState($idBtnCure, 128)
			GUICtrlSetState($idBtnBlockPopUp, 128)
			GUICtrlSetState($idBtnRestore, 128)
			GUICtrlSetState($idButtonCustomFolder, 128)
			GUICtrlSetState($idBtnPatchCC, 128)
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
			GUICtrlSetState($idBtnPatchCC, 64)
			FillListViewWithInfo()

			If $bFoundAcro32 = True Then
				MsgBox($MB_SYSTEMMODAL, "Information", "GenP does not patch the x86 version of Acrobat. Please use the x64 version of Acrobat.")
				LogWrite(1, "GenP does not patch the x86 version of Acrobat. Please use the x64 version of Acrobat.")
			EndIf

			If $bFoundLrARM = True Then
				MsgBox($MB_SYSTEMMODAL, "Information", "GenP does not patch the ARM version of Lightroom. Please use the x64 version of Lightroom.")
				LogWrite(1, "GenP does not patch the ARM version of Lightroom. Please use the x64 version of Lightroom.")
			EndIf

			If $bFoundPsARM = True Then
				MsgBox($MB_SYSTEMMODAL, "Information", "GenP does not patch the ARM version of Photoshop. Please use the x64 version of Photoshop.")
				LogWrite(1, "GenP does not patch the ARM version of Photoshop. Please use the x64 version of Photoshop.")
			EndIf

			If $bFoundGenericARM = True Then
				MsgBox($MB_SYSTEMMODAL, "Information", "GenP cannot patch files with ARM architecture.")
				LogWrite(1, "GenP cannot patch files with ARM architecture.")
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
			GUICtrlSetState($idBtnPatchCC, 128)
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
			GUICtrlSetState($idBtnPatchCC, 64)
			FillListViewWithInfo()

			ToggleLog(1)

		Case $idMsg = $idBtnCopyLog
			SendToClipBoard()

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
	$iStyles = _WinAPI_GetWindowLong($MyhGUI, $GWL_STYLE)
	_WinAPI_SetWindowLong($MyhGUI, $GWL_STYLE, BitXOR($iStyles, $WS_SIZEBOX, $WS_MINIMIZEBOX, $WS_MAXIMIZEBOX))

	; Add columns
	_GUICtrlListView_SetItemCount($idListview, UBound($FilesToPatch))
	_GUICtrlListView_AddColumn($idListview, "", 20)
	_GUICtrlListView_AddColumn($idListview, "", 532, 2)

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
	GUICtrlSetTip(-1, "Block Unlicensed Pop-up via Windows Firewall")
	GUICtrlSetImage(-1, "imageres.dll", -101, 0)
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)

	$idBtnRestore = GUICtrlCreateButton("Restore", 405, 630, 80, 30)
	GUICtrlSetState(-1, $GUI_HIDE)
	GUICtrlSetTip(-1, "Restore Original Files")
	GUICtrlSetImage(-1, "imageres.dll", -113, 0)
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)

	$idBtnPatchCC = GUICtrlCreateButton("Patch CC", 505, 630, 80, 30)
	GUICtrlSetImage(-1, "imageres.dll", -74, 0)
	GUICtrlSetTip(-1, "Patch Creative Cloud")
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)

	$idProgressBar = GUICtrlCreateProgress(10, 597, 575, 25, $PBS_SMOOTHREVERSE)
	GUICtrlSetResizing(-1, $GUI_DOCKVCENTER)

	GUICtrlCreateLabel($g_AppVersion, 10, 677, 575, 25, $ES_CENTER)
	GUICtrlSetResizing(-1, $GUI_DOCKBOTTOM)
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
			Local $FileNameCropped
			If (IsArray($TargetFileList_Adobe)) Then
				For $AdobeFileTarget In $TargetFileList_Adobe
					$FileNameCropped = StringSplit(StringLower($IPATH), StringLower($AdobeFileTarget), $STR_ENTIRESPLIT)
					If @error <> 1 Then
						If Not StringInStr($IPATH, ".bak") Then
							;_ArrayAdd( $FilesToPatch, $DEPTH & " - " & $IPATH )
							If StringInStr($IPATH, "Adobe") Or StringInStr($IPATH, "Acrobat") Then
								If StringInStr($IPATH, "4.js") And Not StringInStr($IPATH, "UXP\com.adobe.ccx.start\js\4.js") Then
									Return
								EndIf
								If StringInStr($IPATH, "manifest.json") And Not StringInStr($IPATH, "UXP\com.adobe.ccx.start\manifest.json") Then
									Return
								EndIf
								_ArrayAdd($FilesToPatch, $IPATH)
							EndIf
						Else
							_ArrayAdd($FilesToRestore, $IPATH)
						EndIf

						; File Found and stored - Quit search in current dir
;~ 					return $RecursiveFileSearch_WhenFoundRaiseToLevel
					EndIf
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
	For $i = 0 To 17
		_GUICtrlListView_AddItem($idListview, "", $i)
		_GUICtrlListView_SetItemGroupID($idListview, $i, 1)
	Next

	_GUICtrlListView_AddSubItem($idListview, 0, "", 1)
	_GUICtrlListView_AddSubItem($idListview, 1, "To patch all apps in the default location:", 1)
	_GUICtrlListView_AddSubItem($idListview, 2, "Press 'Search Files', then press 'Patch Files'.", 1)
	_GUICtrlListView_AddSubItem($idListview, 3, "Default path - C:\Program Files\Adobe", 1)
	_GUICtrlListView_AddSubItem($idListview, 4, '-------------------------------------------------------------', 1)
	_GUICtrlListView_AddSubItem($idListview, 5, "To patch Creative Cloud, press 'Patch CC'.", 1)
	_GUICtrlListView_AddSubItem($idListview, 6, '-------------------------------------------------------------', 1)
	_GUICtrlListView_AddSubItem($idListview, 7, "After searching, some products may already be patched.", 1)
	_GUICtrlListView_AddSubItem($idListview, 8, "To select/deselect products to patch, LEFT CLICK on the product group.", 1)
	_GUICtrlListView_AddSubItem($idListview, 9, "To select/deselect individual files, RIGHT CLICK on the file.", 1)
	_GUICtrlListView_AddSubItem($idListview, 10, "Auditon may require a clean re-install when updating to a newer release.", 1)
	_GUICtrlListView_AddSubItem($idListview, 11, '-------------------------------------------------------------', 1)
	_GUICtrlListView_AddSubItem($idListview, 12, "What's new in GenP:", 1)
	_GUICtrlListView_AddSubItem($idListview, 13, "Added Character Animator (Beta) support.", 1)
	_GUICtrlListView_AddSubItem($idListview, 14, "Fixed issues with TrustedInstaller elevation and 32-bit Creative Cloud installations.", 1)
	_GUICtrlListView_AddSubItem($idListview, 15, "Added Hosts file backup and prevented it from being overwritten.", 1)
	_GUICtrlListView_AddSubItem($idListview, 16, "Removed support for all Maxon products due to compatibility reasons.", 1)
	_GUICtrlListView_AddSubItem($idListview, 17, "You should OPTIONALLY remove any old GenP/Adobe entries within your Hosts file for this update.", 1)

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

	If $sFileName = "AppsPanelBL.dll" Or $sFileName = "ContainerBL.dll" Or $sFileName = "Adobe Desktop Service.exe" Then
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

	ElseIf $sz_type = "0x64AA" Then ; AArch64 (ARM64) and ~~AArch32 (ARM32) architectures~~ (big-endian). only exist as photoshop, lightroom, and ccdesktop at time of writing

		If StringInStr($FileToParse, "Lightroom", 2) > 0 Then ; Lightroom ARM
			MemoWrite(@CRLF & $FileToParse & @CRLF & "---" & @CRLF & "Lightroom is ARM. Aborting..." & @CRLF & "---")
			FileClose($hFileOpen)
			Sleep(100)
			$bFoundLrARM = True

		ElseIf StringInStr($FileToParse, "AppsPanelBL.dll", 2) Or StringInStr($FileToParse, "ContainerBL.dll", 2) Or StringInStr($FileToParse, "Adobe Desktop Service.exe", 2) > 0 Then ; CC Desktop ARM
			MemoWrite(@CRLF & $FileToParse & @CRLF & "---" & @CRLF & "Creative Cloud is ARM. Aborting..." & @CRLF & "---")
			FileClose($hFileOpen)
			Sleep(100)
			$bFoundCCARM = True

		ElseIf StringInStr($FileToParse, "Photoshop", 2) > 0 Then ; Photoshop ARM
			MemoWrite(@CRLF & $FileToParse & @CRLF & "---" & @CRLF & "Photoshop is ARM. Aborting..." & @CRLF & "---")
			FileClose($hFileOpen)
			Sleep(100)
			$bFoundPsARM = True

		Else ; Other ARM
			MemoWrite(@CRLF & $FileToParse & @CRLF & "---" & @CRLF & "File is ARM. Aborting..." & @CRLF & "---")
			FileClose($hFileOpen)
			Sleep(100)
			$bFoundGenericARM = True

		EndIf

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

		LogWrite(1, "File patched." & @CRLF)

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
	GUICtrlSetState($hLogTab, $GUI_SHOW)
	GUICtrlSetState($idBtnBlockPopUp, 128)
	MemoWrite(@CRLF & "Checking for an active internet connection..." & @CRLF & "" & @CRLF & "")
	Local $sCmdInfo = """C:\Windows\System32\WindowsPowerShell\v1.0\PowerShell.exe"" -Command ""Test-Connection 8.8.8.8 -Count 1 -Quiet"""
	Local $iPID = Run($sCmdInfo, "", @SW_HIDE, BitOR($STDERR_CHILD, $STDOUT_CHILD))
	Local $sOutput = ""
	While 1
		$sOutput &= StdoutRead($iPID)
		If @error Then ExitLoop
	WEnd
	ProcessWaitClose($iPID)
	If StringReplace($sOutput, @CRLF, "") = "True" Then
		MemoWrite(@CRLF & "Resolving ip-addresses..." & @CRLF & "" & @CRLF & "")
		$sCmdInfo = """C:\Windows\System32\WindowsPowerShell\v1.0\PowerShell.exe"" -Command ""$currentDate=Get-Date;$ipAddresses=@();try{$SOA=(Resolve-DnsName -Name adobe.io -Type SOA -ErrorAction Stop).PrimaryServer}catch{$SOA=$null};if($SOA){Do{if((New-TimeSpan -Start $currentDate -End (Get-Date)).TotalSeconds -gt 5){if($ipAddresses.Count -eq 0){$ipAddresses+='False'};break};try{$ipAddress=(Resolve-DnsName -Name adobe.io -Server $SOA -ErrorAction Stop).IPAddress}catch{$ipAddress=$null};if($ipAddress){$ipAddresses+=$ipAddress};$ipAddresses=$ipAddresses|Select -Unique|Sort-Object}While($ipAddresses.Count -lt 8)}else{$ipAddresses+='False'};Do{if((New-TimeSpan -Start $currentDate -End (Get-Date)).TotalSeconds -gt 5 -or $ipAddresses[0] -eq 'False'){break};try{$ipAddress=(Resolve-DnsName -Name 3u6k9as4bj.adobestats.io -ErrorAction Stop).IPAddress}catch{$ipAddress=$null};if($ipAddress){$ipAddresses+=$ipAddress};$ipAddresses=$ipAddresses|Select -Unique|Sort-Object}While($ipAddresses.Count -lt 12 -and $ipAddresses[0] -ne 'False');$ipAddresses=$ipAddresses -ne 'False'|Select -Unique|Sort-Object;$ipAddressList=if($ipAddresses.Count -eq 0){'False'}else{$ipAddresses -join ','};$ipAddressList"""
		$iPID = Run($sCmdInfo, "", @SW_HIDE, BitOR($STDERR_CHILD, $STDOUT_CHILD))
		$sOutput = ""
		While 1
			$sOutput &= StdoutRead($iPID)
			If @error Then ExitLoop
		WEnd
		ProcessWaitClose($iPID)
		If StringInStr($sOutput, "False") Then
			MemoWrite(@CRLF & "Failed to resolve ip-addresses, try using a VPN..." & @CRLF & "" & @CRLF & "")
			Sleep(2000)
		Else
			MemoWrite(@CRLF & "Adding Windows Firewall rule..." & @CRLF & "" & @CRLF & "")
			$sCmdInfo = "netsh advfirewall firewall delete rule name=""Adobe Unlicensed Pop-up"""
			$iPID = Run($sCmdInfo, "", @SW_HIDE, BitOR($STDERR_CHILD, $STDOUT_CHILD))
			ProcessWaitClose($iPID)
			$sCmdInfo = "netsh advfirewall firewall add rule name=""Adobe Unlicensed Pop-up"" dir=out action=block remoteip=""" & StringReplace($sOutput, @CRLF, "") & """"
			$iPID = Run($sCmdInfo, "", @SW_HIDE, BitOR($STDERR_CHILD, $STDOUT_CHILD))
			ProcessWaitClose($iPID)
		EndIf
		MemoWrite(@CRLF & "Blocking Hosts..." & @CRLF & "" & @CRLF & "")
		$sCmdInfo = """C:\Windows\System32\WindowsPowerShell\v1.0\PowerShell.exe"" -Command ""try{if(-not([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)){Write-Host 'Script execution failed...';return};$hostsPath='C:\Windows\System32\drivers\etc\hosts';$bakPath=$hostsPath+'.bak';if(-not(Test-Path $bakPath)){Copy-Item -Path $hostsPath -Destination $bakPath};$webContent=(Invoke-RestMethod -Uri 'https://a.dove.isdumb.one/list.txt' -UseBasicParsing).Split($([char]0x0A))|ForEach-Object{ $_.Trim()};$currentHostsContent=Get-Content -Path $hostsPath;$startMarker='# <GenP>';$endMarker='# </GenP>';$blockStart=$currentHostsContent.IndexOf($startMarker);$blockEnd=$currentHostsContent.IndexOf($endMarker);if($blockStart -eq -1 -or $blockEnd -eq -1){$currentHostsContent+=$startMarker;$currentHostsContent+=$endMarker;$blockStart=$currentHostsContent.IndexOf($startMarker);$blockEnd=$currentHostsContent.IndexOf($endMarker)};$newBlock=@($startMarker)+$webContent+$endMarker;$newHostsContent=$currentHostsContent[0..($blockStart-1)]+$newBlock+$currentHostsContent[($blockEnd+1)..$currentHostsContent.Length];Set-Content -Path $hostsPath -Value $newHostsContent;Write-Host 'Script execution complete.'}catch{Write-Host 'Script execution failed...'}"""
		$iPID = Run($sCmdInfo, "", @SW_HIDE, $STDOUT_CHILD)
		$sOutput = ""
		While 1
			$sLine = StdoutRead($iPID)
			If @error Then ExitLoop
			$sOutput &= $sLine
		WEnd
		If StringInStr($sOutput, "Script execution complete.") Then
			MemoWrite(@CRLF & "All Hosts blocked." & @CRLF & "" & @CRLF & "")
		Else
			MemoWrite(@CRLF & "Failed to block Hosts, try using a VPN..." & @CRLF & "" & @CRLF & "")
		EndIf
	Else
		MemoWrite(@CRLF & "You are not connected to the internet..." & @CRLF & "" & @CRLF & "")
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
				_GUICtrlListView_InsertGroup($idListview, $i, 29, "", 1)
				_GUICtrlListView_SetItemGroupID($idListview, $i, 29)
				_GUICtrlListView_SetGroupInfo($idListview, 29, "Miscellaneous", 1, $LVGS_COLLAPSIBLE)
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
