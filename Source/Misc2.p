{ Segments: Misc2_1 }
unit Misc2;

interface

	uses
		AppleTalk, ADSP, Serial, Sound, CommResources, TCPTypes, Initial, CreateNewFiles, LoadAndSave, NodePrefs2, NodePrefs, Import;

	procedure ClickInTransPrefs (theEvent: EventRecord; ItemHit: Integer);
	procedure OpenTransPrefs;
	procedure UpdateTransPrefs;
	procedure CloseTransPrefs;
	procedure ClickInMenuPrefs (theEvent: EventRecord; ItemHit: Integer);
	procedure OpenMenuPrefs;
	procedure UpdateMenuPrefs;
	procedure CloseMenuPrefs;
	procedure ClickInMailPrefs (theEvent: EventRecord; ItemHit: Integer);
	procedure OpenMailPrefs;
	procedure UpdateMailPrefs;
	procedure CloseMailPrefs;
	procedure DoUserExport (senario: integer);
	procedure LogError (Error: str255; InFore: boolean; NumBeeps: integer);
	procedure DoErrorWindow (theEvent: EventRecord; ItemHit: integer);
	procedure UpdateErrorWindow (theWindow: windowPtr);
	procedure CloseErrorWindow;
	procedure CheckTransferPaths;
	procedure CheckSomePaths;

implementation

	type
		TheErrorHdl = ^TheErrorPtr;
		TheErrorPtr = ^TheErrorList;
		TheErrorList = array[1..250] of string[83];
	var
		cSize: Point;
		EditingMenu, EditingTrans, NumErrors: integer;
		menuList, transList, ErrorList: ListHandle;

{$S Misc2_1}
	procedure OutputError (var errCode: OSErr; CustomText, ThePath: str255);
	begin
		if errCode = -35 then
		begin
			LogError('!Incorrect volume (hard drive) name.', true, 0);
			if CustomText <> char(0) then
				LogError(concat('!Rename volume to below or reset path in ', CustomText, '.'), true, 0)
			else
				LogError('!Rename volume to below.', true, 0);
		end
		else if errCode = -120 then
		begin
			LogError('!Incorrect directory (folder) name(s).', true, 0);
			if CustomText <> char(0) then
				LogError(concat('!Rename folder(s) to below or reset path in ', CustomText, '.'), true, 0)
			else
				LogError('!Rename folder(s) to below .', true, 0);
		end
		else
			LogError(StringOf('!File Manager Error ', errCode : 0, ' Check Macintosh System Error guide.'), true, 0);
		LogError('!Restart application to recheck path.', true, 0);
		LogError(concat('@', ThePath), true, 0);
		LogError('', true, 0);
	end;

	function ReadTextFile (fileName: str255; storedAs: integer; insertPath: boolean): boolean;
	external;

	procedure CheckSomePaths;
		var
			TheFile, i: integer;
			result: OSErr;
			Error, OneCR: boolean;
	begin
		result := FSOpen(concat(sharedPath, 'Shared Files:Directories'), 0, TheFile);
		if result <> noErr then
		begin
			LogError('WARNING! Unable to find Directories shared file.', true, 1);
			LogError('!Place the Directories shared file in the path below.', true, 0);
			LogError(concat('@', sharedPath, 'Shared Files:Directories'), true, 0);
		end
		else
			result := FSClose(TheFile);
		result := FSOpen(concat(sharedPath, 'Shared Files:GFiles'), 0, TheFile);
		if result <> noErr then
		begin
			LogError('WARNING! Unable to find GFiles shared file.', true, 1);
			LogError('!Place the GFiles shared file in the path below.', true, 0);
			LogError(concat('@', sharedPath, 'Shared Files:GFiles'), true, 0);
		end
		else
			result := FSClose(TheFile);
		result := FSOpen(concat(sharedPath, 'Shared Files:Mailer Prefs'), 0, TheFile);
		if result <> noErr then
		begin
			LogError('WARNING! Unable to find Mailer Prefs shared file.', true, 1);
			LogError('!Place the Mailer Prefs shared file in the path below.', true, 0);
			LogError(concat('@', sharedPath, 'Shared Files:Mailer Prefs'), true, 0);
		end
		else
			result := FSClose(TheFile);
		result := FSOpen(concat(sharedPath, 'Shared Files:Menus'), 0, TheFile);
		if result <> noErr then
		begin
			LogError('WARNING! Unable to find Menus shared file.', true, 1);
			LogError('!Place the Menus shared file in the path below.', true, 0);
			LogError(concat('@', sharedPath, 'Shared Files:Menus'), true, 0);
		end
		else
			result := FSClose(TheFile);
		result := FSOpen(concat(sharedPath, 'Shared Files:Message'), 0, TheFile);
		if result <> noErr then
		begin
			LogError('WARNING! Unable to find Message shared file.', true, 1);
			LogError('!Place the Message shared file in the path below.', true, 0);
			LogError(concat('@', sharedPath, 'Shared Files:Message'), true, 0);
		end
		else
			result := FSClose(TheFile);
		result := FSOpen(concat(sharedPath, 'Shared Files:Modem Drivers'), 0, TheFile);
		if result <> noErr then
		begin
			LogError('WARNING! Unable to find Modem Drivers shared file.', true, 1);
			LogError('!Place the Modem Drivers shared file in the path below.', true, 0);
			LogError(concat('@', sharedPath, 'Shared Files:Modem Drivers'), true, 0);
		end
		else
			result := FSClose(TheFile);
		result := FSOpen(concat(sharedPath, 'Shared Files:New User'), 0, TheFile);
		if result <> noErr then
		begin
			LogError('WARNING! Unable to find New User shared file.', true, 1);
			LogError('!Place the New User shared file in the path below.', true, 0);
			LogError(concat('@', sharedPath, 'Shared Files:New User'), true, 0);
		end
		else
			result := FSClose(TheFile);
		result := FSOpen(concat(sharedPath, 'Shared Files:Nodes'), 0, TheFile);
		if result <> noErr then
		begin
			LogError('WARNING! Unable to find Nodes shared file.', true, 1);
			LogError('!Place the Nodes shared file in the path below.', true, 0);
			LogError(concat('@', sharedPath, 'Shared Files:Nodes'), true, 0);
		end
		else
			result := FSClose(TheFile);
		result := FSOpen(concat(sharedPath, 'Shared Files:Security Levels'), 0, TheFile);
		if result <> noErr then
		begin
			LogError('WARNING! Unable to find Security Levels shared file.', true, 1);
			LogError('!Place the Security Levels shared file in the path below.', true, 0);
			LogError(concat('@', sharedPath, 'Shared Files:Security Levels'), true, 0);
		end
		else
			result := FSClose(TheFile);
		result := FSOpen(concat(sharedPath, 'Shared Files:Strings'), 0, TheFile);
		if result <> noErr then
		begin
			LogError('WARNING! Unable to find Strings shared file.', true, 1);
			LogError('!Place the Strings shared file in the path below.', true, 0);
			LogError(concat('@', sharedPath, 'Shared Files:Strings'), true, 0);
		end
		else
			result := FSClose(TheFile);
		result := FSOpen(concat(sharedPath, 'Shared Files:Text'), 0, TheFile);
		if result <> noErr then
		begin
			LogError('WARNING! Unable to find Text shared file.', true, 1);
			LogError('!Place the Text shared file in the path below.', true, 0);
			LogError(concat('@', sharedPath, 'Shared Files:Text'), true, 0);
		end
		else
			result := FSClose(TheFile);
		result := FSOpen(concat(sharedPath, 'Shared Files:Users'), 0, TheFile);
		if result <> noErr then
		begin
			LogError('WARNING! Unable to find Users shared file.', true, 1);
			LogError('!Place the Users shared file in the path below.', true, 0);
			LogError(concat('@', sharedPath, 'Shared Files:Users'), true, 0);
		end
		else
			result := FSClose(TheFile);
		result := FSOpen(concat(sharedPath, 'Shared Files:Address Books'), 0, TheFile);
		if result <> noErr then
		begin
			LogError('WARNING! Unable to find Address Books shared file.', true, 1);
			LogError('!Replace the Address Books shared file in the path below.', true, 0);
			LogError(concat('@', sharedPath, 'Shared Files:Address Books'), true, 0);
			LogError('@Creating new Address Books shared file in the above path.', true, 0);
			CreateAddressBooks(concat(sharedPath, 'Shared Files:Address Books'));
		end
		else
			result := FSClose(TheFile);
		result := FSOpen(concat(sharedPath, 'Shared Files:Action Words'), 0, TheFile);
		if result <> noErr then
		begin
			LogError('WARNING! Unable to find Action Words shared file.', true, 1);
			LogError('!Replace the Action Words shared file in the path below.', true, 0);
			LogError(concat('@', sharedPath, 'Shared Files:Action Words'), true, 0);
			LogError('@Creating new Action Words shared file in the above path.', true, 0);
			CreateActionWords(concat(sharedPath, 'Shared Files:Action Words'));
		end
		else
			result := FSClose(TheFile);

		result := FSOpen(concat(InitSystHand^^.GFilePath, '?xxNONAMEFILExx?'), 0, TheFile);
		if result <> -43 then
		begin
			LogError('WARNING! GFile path setup problem.', true, 1);
			OutputError(result, 'System Preferences', InitSystHand^^.GFilePath);
		end;
		result := FSOpen(concat(InitSystHand^^.MsgsPath, '?xxNONAMEFILExx?'), 0, TheFile);
		if result <> -43 then
		begin
			LogError('WARNING! Messages path setup problem.', true, 1);
			OutputError(result, 'System Preferences', InitSystHand^^.MsgsPath);
		end;
		result := FSOpen(concat(InitSystHand^^.DataPath, '?xxNONAMEFILExx?'), 0, TheFile);
		if result <> -43 then
		begin
			LogError('WARNING! Data path setup problem.', true, 1);
			OutputError(result, 'System Preferences', InitSystHand^^.MsgsPath);
		end;
		if Mailer^^.MailerAware then
		begin
			result := FSOpen(concat(Mailer^^.EventPath, '?xxNONAMEFILExx?'), 0, TheFile);
			if result <> -43 then
			begin
				LogError('WARNING! Next Event path setup problem.', true, 1);
				OutputError(result, 'Mailer Preferences', Mailer^^.EventPath);
			end;
			result := FSClose(TheFile);
			result := FSOpen(concat(Mailer^^.GenericPath, '?xxNONAMEFILExx?'), 0, TheFile);
			if result <> -43 then
			begin
				LogError('WARNING! Generic path setup problem.', true, 1);
				OutputError(result, 'Mailer Preferences', Mailer^^.GenericPath);
			end;
			result := FSOpen(concat(Mailer^^.Application, '?xxNONAMEFILExx?'), 0, TheFile);
			if result <> -43 then
			begin
				LogError('WARNING! Mailer application path setup problem.', true, 1);
				OutputError(result, 'Mailer Preferences', Mailer^^.Application);
			end;
		end;
		result := FSOpen(concat(sharedPath, 'Forms:?xxNONAMEFILExx?'), 0, TheFile);
		if result <> -43 then
		begin
			LogError('WARNING! Forms Folder not found.', true, 1);
			OutputError(result, char(0), concat(sharedPath, 'Forms:'));
		end;
		result := FSOpen(concat(sharedPath, 'Externals:?xxNONAMEFILExx?'), 0, TheFile);
		if result <> -43 then
		begin
			LogError('WARNING! Externals Folder not found.', true, 1);
			OutputError(result, char(0), concat(sharedPath, 'Externals:'));
		end;
		result := FSOpen(concat(sharedPath, 'Logs:?xxNONAMEFILExx?'), 0, TheFile);
		if result <> -43 then
		begin
			LogError('WARNING! Logs Folder not found.', true, 1);
			OutputError(result, char(0), concat(sharedPath, 'Logs:'));
		end;
		result := FSOpen(concat(sharedPath, 'Misc:?xxNONAMEFILExx?'), 0, TheFile);
		if result <> -43 then
		begin
			LogError('WARNING! Misc Folder not found.', true, 1);
			OutputError(result, char(0), concat(sharedPath, 'Misc:'));
		end;

		(* Check for blank line in Trash Users file *)
		if ReadTextFile('Misc:Trash Users', 0, true) then
		begin
			Error := false;
			OneCR := false;
			i := 0;
			if curGlobs^.TextHnd^^[0] = char(13) then
				Error := true
			else
				for i := 1 to curGlobs^.OpenTextSize - 1 do
					if (curGlobs^.TextHnd^^[i] = char(13)) and OneCR then
					begin
						Error := true;
						leave;
					end
					else if (curGlobs^.TextHnd^^[i] = char(13)) then
						OneCR := true
					else
						OneCR := false;
			if Error then
			begin
				LogError('WARNING! The Trash Users file has a blank line.', true, 1);
				LogError('!Remove the blank line.', true, 0);
				LogError(StringOf('@The blank line is ', i + 1 : 0, ' characater(s) from the top of the file.'), true, 0);
				LogError('', true, 0);
			end;
		end
		else
		begin
			LogError('WARNING! Trash Users file not found.', true, 1);
			LogError('!Create Hermes text file (named: Trash Users) and place in below path.', true, 0);
			LogError(concat('@', sharedPath, 'Misc:Trash Users'), true, 0);
			LogError('', true, 0);
		end;
	end;

	procedure CheckTransferPaths;
		var
			i, x, y, TheFile: integer;
			result: OSErr;
	begin
		if forumIdx^^.NumForums > 0 then
		begin
			for i := 0 to forumIdx^^.NumForums - 1 do
				for x := 1 to forumIdx^^.numDirs[i] do
				begin
					result := FSOpen(concat(forums^^[i].dr[x].path, '?xxNONAMEFILExx?'), 0, TheFile);
					if result <> -43 then
					begin
						LogError(concat('WARNING! Transfer Area "', forumIdx^^.Name[i], '", Directory "', forums^^[i].dr[x].DirName, '" setup problem.'), true, 1);

						if result = -35 then
						begin
							LogError('!Incorrect volume (hard drive) name.', true, 0);
							LogError('!Rename volume to below or reset path in Transfer "Directory Setup" menu.', true, 0);
						end
						else if result = -120 then
						begin
							LogError('!Incorrect directory (folder) name(s).', true, 0);
							LogError('!Rename folder(s) to below or reset path in Transfer "Directory Setup" menu.', true, 0);
						end
						else
							LogError(StringOf('!File Manager Error ', result : 0, ' Check Macintosh System Error guide.'), true, 0);
						LogError('!Restart application to recheck path.', true, 0);
						LogError(concat('@', forums^^[i].dr[x].path), true, 0);
						LogError('', true, 0);
					end;
				end;
		end;
	end;

	procedure RemoveErrorItem; {(WhichItem: integer)}
	{Remove 10 Errors at a time}
		var
			result: OSErr;
			longer, NumE, AnotherLong: longint;
			TheErrors: TheErrorHdl;
			s83: string[83];
			TheFile: integer;
	begin
		TheErrors := nil;
		result := FSOpen(concat(sharedPath, 'Shared Files:Error Log'), 0, TheFile);
		result := GetEOF(TheFile, longer);
		NumE := longer div SizeOf(s83);
		TheErrors := TheErrorHdl(NewHandle(longer));
		result := FSRead(TheFile, longer, @TheErrors^^);
		result := FSClose(TheFile);
		result := FSDelete(concat(sharedPath, 'Shared Files:Error Log'), 0);
		result := Create(concat(sharedPath, 'Shared Files:Error Log'), 0, 'HRMS', 'DATA');
		result := FSOpen(concat(sharedPath, 'Shared Files:Error Log'), 0, TheFile);
		longer := longer - (sizeOf(s83) * 11);
		result := FSWrite(TheFile, longer, @TheErrors^^[11]);
		result := FSClose(TheFile);
		DisposHandle(handle(TheErrors));
		TheErrors := nil;
	end;

	procedure SaveErrorItem (whatError: Str255);
		var
			result: OSErr;
			longer, NumE: longint;
			TheFile: integer;
			TheErrors: TheErrorHdl;
			s83: string[83];
	begin
		result := FSOpen(concat(sharedPath, 'Shared Files:Error Log'), 0, TheFile);
		if result <> noErr then
		begin
			result := Create(concat(sharedPath, 'Shared Files:Error Log'), 0, 'HRMS', 'DATA');
			result := FSOpen(concat(sharedPath, 'Shared Files:Error Log'), 0, TheFile);
		end;
		result := GetEOF(TheFile, longer);
		NumE := longer div SizeOf(s83);
		TheErrors := TheErrorHdl(NewHandle(sizeOf(s83) * (NumE + 1)));
		result := FSRead(TheFile, longer, @TheErrors^^[1]);
		result := SetFPos(TheFile, fsFromStart, 0);
		TheErrors^^[NumE + 1] := whatError;
		longer := (NumE + 1) * sizeOf(s83);
		result := FSWrite(TheFile, longer, @TheErrors^^);
		result := FSClose(TheFile);
		DisposHandle(handle(TheErrors));
		TheErrors := nil;
	end;

	procedure LoadErrorItems;
		var
			result: OSErr;
			TheFile, i: integer;
			longer, NumE: longint;
			TheErrors: TheErrorHdl;
			s83: string[83];
	begin
		TheErrors := nil;
		result := FSOpen(concat(sharedPath, 'Shared Files:Error Log'), 0, TheFile);
		if result <> noErr then
		begin
			result := Create(concat(sharedPath, 'Shared Files:Error Log'), 0, 'HRMS', 'DATA');
			result := FSOpen(concat(sharedPath, 'Shared Files:Error Log'), 0, TheFile);
		end;
		result := GetEOF(TheFile, longer);
		if longer > 0 then
		begin
			NumE := longer div SizeOf(s83);
			NumErrors := NumE;
			TheErrors := TheErrorHdl(NewHandle(longer));  {NumE * SizeOf(s83)}
			result := FSRead(TheFile, longer, @TheErrors^^); {[1]}
			for i := 1 to NumE do
				AddListString(TheErrors^^[i], ErrorList);
			DisposHandle(handle(TheErrors));
			TheErrors := nil;
		end;
		result := FSClose(TheFile);
	end;

	procedure LogError;
		var
			SavedPort: GrafPtr;
			DType: integer;
			DItem: Handle;
			tempRect, tr2: rect;
			cSize: cell;
			SavedWindow: WindowPtr;
			theStr: string[83];
	begin
		GetPort(SavedPort);
		if ErrorDlg = nil then
		begin
			SavedWindow := FrontWindow;
			ErrorDlg := GetNewDialog(270, nil, Pointer(-1));
			SetPort(ErrorDlg);
			SetGeneva(ErrorDlg);
			GetDItem(ErrorDlg, 1, DType, DItem, tempRect);
			TempRect.right := tempRect.right - 15;
			InsetRect(tempRect, -1, -1);
			FrameRect(tempRect);
			InsetRect(tempRect, 1, 1);
			SetRect(tr2, 0, 0, 1, 0);
			cSize.h := tempRect.right - tempRect.left;
			cSize.v := 12;
			ErrorList := LNew(tempRect, tr2, cSize, 2080, ErrorDlg, false, false, false, true);
			ErrorList^^.selFlags := lOnlyOne;
			NumErrors := 0;
			LoadErrorItems;
			LDoDraw(true, ErrorList);
			DrawDialog(ErrorDlg);
			if not InFore then
				SelectWindow(SavedWindow)
		end;
		if Error <> 'OpenFromSysopMenu' then
		begin
			NumErrors := NumErrors + 1;
			if NumErrors > 250 then
			begin
				NumErrors := NumErrors - 10;
				LDelRow(10, 0, ErrorList);
				RemoveErrorItem;
			end;
			SetPort(ErrorDlg);
			if InFore then
				SelectWindow(ErrorDlg);
			theStr := Error;
			SaveErrorItem(theStr);
			for DType := 1 to NumBeeps do
				SysBeep(0);
			cSize.h := 0;
			DType := LAddRow(1, 9000, ErrorList);
			cSize.v := DType;
			LSetCell(Pointer(ord(@theStr) + 1), length(theStr), cSize, ErrorList);
			LScroll(0, 1, ErrorList);
			if not InFore then
				SetPort(SavedPort);
		end;
	end;

	procedure DoErrorWindow;
		var
			tempRect: rect;
			DType: integer;
			DItem: handle;
			tempCell: cell;
			myPt: point;
	begin
		if ErrorDlg <> nil then
		begin
			SetPort(ErrorDlg);
			myPt := theEvent.where;
			GlobalToLocal(myPt);
			case itemHit of
				1:{The Error List}
				begin
					tempCell.v := 0;
					tempCell.h := 0;
					if LClick(myPt, theEvent.modifiers, ErrorList) then
						;
					if LGetSelect(true, tempCell, ErrorList) then
						;
				end;
				2: {Clear List}
				begin
					if ModalQuestion('Are you sure you want to clear the list?', false, true) = 1 then
					begin
						NumErrors := 0;
						LDelRow(0, 0, ErrorList);
						result := FSDelete(concat(sharedPath, 'Shared Files:Error Log'), 0);
					end;
				end;
			end;
		end;
	end;

	procedure UpdateErrorWindow;
		var
			SavedPort: GrafPtr;
			tempRect: rect;
			DType: integer;
			DItem: handle;
	begin
		if (ErrorDlg <> nil) and (theWindow = ErrorDlg) then
		begin
			GetPort(SavedPort);
			SetPort(ErrorDlg);

			GetDItem(ErrorDlg, 1, DType, DItem, tempRect);
			tempRect.Right := tempRect.Right - 15;
			InsetRect(tempRect, -1, -1);
			FrameRect(tempRect);
			if (ErrorList <> nil) then
				LUpdate(ErrorDlg^.visRgn, ErrorList);
			DrawDialog(ErrorDlg);

			SetPort(SavedPort);
		end;
	end;

	procedure CloseErrorWindow;
	begin
		if (ErrorList <> nil) then
		begin
			DisposHandle(handle(ErrorList));
			ErrorList := nil;
		end;
		if (ErrorDlg <> nil) then
		begin
			DisposDialog(ErrorDlg);
			ErrorDlg := nil;
		end;
	end;

	procedure WriteMenuPrefs;
		var
			y: integer;
			DType, i: Integer;
			DItem: Handle;
			tempRect: rect;
			tempString: Str255;
			tempInt: Longint;
			CItem: controlhandle;
	begin
		with theNodes[visibleNode]^ do
		begin
			GetDItem(NodeDilg5, 4, DType, DItem, tempRect);
			GetIText(DItem, TempString);
			Menuhand^^.Name[EditingMenu] := TempString;

			GetDItem(NodeDilg5, 5, DType, DItem, tempRect);
			CItem := Pointer(DItem);
			tempInt := GetCtlValue(CItem);
			if tempInt = 1 then
				Menuhand^^.OnOff[EditingMenu] := True;

			GetDItem(NodeDilg5, 6, DType, DItem, tempRect);
			CItem := Pointer(DItem);
			tempInt := GetCtlValue(CItem);
			if tempInt = 1 then
				Menuhand^^.OnOff[EditingMenu] := False;

			DoMenuRec(true);
		end;
	end;

	procedure WriteTransPrefs;
		var
			y: integer;
			DType, i: Integer;
			DItem: Handle;
			tempRect: rect;
			tempString: Str255;
			tempInt: Longint;
			CItem: controlhandle;
	begin
		with theNodes[visibleNode]^ do
		begin
			GetDItem(NodeDilg6, 4, DType, DItem, tempRect);
			GetIText(DItem, TempString);
			TransHand^^.Name[EditingTrans] := TempString;

			GetDItem(NodeDilg6, 5, DType, DItem, tempRect);
			CItem := Pointer(DItem);
			tempInt := GetCtlValue(CItem);
			if tempInt = 1 then
				TransHand^^.OnOff[EditingTrans] := True;

			GetDItem(NodeDilg6, 6, DType, DItem, tempRect);
			CItem := Pointer(DItem);
			tempInt := GetCtlValue(CItem);
			if tempInt = 1 then
				TransHand^^.OnOff[EditingTrans] := False;

			DoTransRec(true);
		end;
	end;

	procedure CloseMailPrefs;
		var
			i: integer;
	begin
		if (MailDilg <> nil) then
		begin
			Mailer^^.FidoAddress := GetTextBox(MailDilg, 23);
			for i := 1 to InitSystHand^^.NumNodes do
				theNodes[i]^.doCrashMail := false;
			theNodes[Mailer^^.MailerNode]^.doCrashMail := Mailer^^.AllowCrashMail;
			if not Mailer^^.MailerAware then
				DisableItem(getMHandle(mSysop), 11)
			else
			begin
				EnableItem(getMHandle(mSysop), 11);
				doDetermineZMH;
			end;
			DoMailerRec(true);
			DisposDialog(MailDilg);
			MailDilg := nil;
		end;
	end;

	procedure CloseMenuPrefs;
	begin
		if (NodeDilg5 <> nil) then
		begin
			WriteMenuPrefs;
			DisposDialog(NodeDilg5);
			NodeDilg5 := nil;
		end;
	end;

	procedure CloseTransPrefs;
	begin
		if (NodeDilg6 <> nil) then
		begin
			WriteTransPrefs;
			DisposDialog(NodeDilg6);
			NodeDilg6 := nil;
		end;
	end;

	procedure UpDateMailPrefs;
		var
			SavePort: WindowPtr;
			tempRect: rect;
	begin
		if (MailDilg <> nil) then
		begin
			GetPort(SavePort);
			SetPort(MailDilg);
			FrameIt(MailDilg, 14);
			FrameIt(MailDilg, 30);
			FrameIt(MailDilg, 24);
			FrameIt(MailDilg, 27);
			DrawDialog(MailDilg);
			SetPort(SavePort);
		end;
	end;

	procedure UpDateMenuPrefs;
		var
			SavePort: WindowPtr;
			tempRect: rect;
	begin
		if (NodeDilg5 <> nil) then
		begin
			GetPort(SavePort);
			SetPort(NodeDilg5);
			EraseRect(NodeDilg5^.portRect);
			DrawDialog(NodeDilg5);
			TempRect := menuList^^.rView;
			InsetRect(TempRect, -1, -1);
			FrameRect(TempRect);

			LUpdate(NodeDilg5^.visRgn, menuList);

			SetPort(SavePort);
		end;
	end;

	procedure UpDateTransPrefs;
		var
			SavePort: WindowPtr;
			tempRect: rect;
	begin
		if (NodeDilg6 <> nil) then
		begin
			GetPort(SavePort);
			SetPort(NodeDilg6);
			EraseRect(NodeDilg6^.portRect);
			DrawDialog(NodeDilg6);
			TempRect := transList^^.rView;
			InsetRect(TempRect, -1, -1);
			FrameRect(TempRect);

			LUpdate(NodeDilg6^.visRgn, TransList);

			SetPort(SavePort);
		end;
	end;

	procedure PutMenuPrefs;
		var
			i: integer;
	begin
		with theNodes[visibleNode]^ do
		begin
			SetTextBox(NodeDilg5, 4, Menuhand^^.Name[EditingMenu]);
			SetCheckBox(NodeDilg5, 5, Menuhand^^.OnOff[EditingMenu]);
			SetCheckBox(NodeDilg5, 6, not Menuhand^^.OnOff[EditingMenu]);
			SetTextBox(NodeDilg5, 8, StringOf(Menuhand^^.SecLevel[EditingMenu] : 0));
		end;
	end;

	procedure PutTransPrefs;
		var
			i: integer;
	begin
		with theNodes[visibleNode]^ do
		begin
			SetTextBox(Nodedilg6, 4, TransHand^^.Name[EditingTrans]);
			SetCheckBox(Nodedilg6, 5, TransHand^^.OnOff[EditingTrans]);
			SetCheckBox(Nodedilg6, 6, not TransHand^^.OnOff[EditingTrans]);
			SetTextBox(Nodedilg6, 8, stringOf(TransHand^^.SecLevel[EditingTrans] : 0));
		end;
	end;

	procedure SetUpMenu (itemHit: Char);
		var
			i: integer;
	begin
		with theNodes[VisibleNode]^ do
		begin
			for i := 12 to 42 do
				HideDItem(NodeDilg5, i);
			case ItemHit of
				'A': 
				begin
					SetControlBox(NodeDilg5, 22, 'Display At Logon', Menuhand^^.Options[EditingMenu, 1]);
				end;
				'L': 
				begin
					SetControlBox(NodeDilg5, 22, 'Display At Logon', Menuhand^^.Options[EditingMenu, 1]);
				end;
				'O': 
				begin
					SetControlBox(NodeDilg5, 22, 'Ask New User To Keep Account', MenuHand^^.Options[EditingMenu, 1]);
				end;
				'S': 
				begin
					SetControlBox(NodeDilg5, 22, 'Allow Emergency Chat', MenuHand^^.Options[EditingMenu, 1]);
					for i := 12 to 16 do
						ShowDItem(NodeDilg5, i);
					SetTextBox(NodeDilg5, 12, 'Minimum For Emergency Chat:');
					SetTextBox(NodeDilg5, 13, stringOf(Menuhand^^.SecLevel2[EditingMenu] : 0));
				end;
			end;
		end;
	end;

	procedure SetUpTransMenu (itemHit: Char);
		var
			i: integer;
	begin
		with theNodes[VisibleNode]^ do
		begin
			for i := 12 to 42 do
				HideDItem(NodeDilg6, i);
			case ItemHit of
				'O': 
				begin
					SetControlBox(NodeDilg6, 22, 'Ask New User To Keep Account', MenuHand^^.Options[EditingTrans, 1]);
				end;
			end;
		end;
	end;

	procedure OpenMailPrefs;
		var
			tempRect, tr2: Rect;
			tempString: Str255;
			myC: Point;
			DType, i: integer;
			DItem: Handle;
			DataBounds: Rect;
			CItem, CTempItem: controlhandle;
			myPop: popupHand;
	begin
		if (MailDilg = nil) then
		begin
			MailDilg := GetNewDialog(250, nil, Pointer(-1));
			SetPort(MailDilg);
			SetGeneva(MailDilg);
			SetTextBox(MailDilg, 29, Mailer^^.Application);
			SetTextBox(MailDilg, 4, Mailer^^.GenericPath);
			SetTextBox(MailDilg, 8, Mailer^^.EventPath);
			if Mailer^^.CrashMailPath[1] = char(0) then
				Mailer^^.CrashMailPath := Mailer^^.Application;
			SetTextBox(MailDilg, 3, Mailer^^.CrashMailPath);

			if mailer^^.MailerAware then
			begin
				GetDItem(MailDilg, 10, dType, dItem, tempRect);
				HiLiteControl(controlHandle(dItem), 0);
				GetDItem(MailDilg, 11, dType, dItem, tempRect);
				HiLiteControl(controlHandle(dItem), 0);
				GetDItem(MailDilg, 12, dType, dItem, tempRect);
				if (gMac.systemVersion >= $0700) then
					HiLiteControl(controlHandle(dItem), 0)
				else
					HiLiteControl(controlHandle(dItem), 255);
				GetDItem(MailDilg, 18, dType, dItem, tempRect);
				HiLiteControl(controlHandle(dItem), 0);
				GetDItem(MailDilg, 19, dType, dItem, tempRect);
				HiLiteControl(controlHandle(dItem), 0);
				GetDItem(MailDilg, 20, dType, dItem, tempRect);
				HiLiteControl(controlHandle(dItem), 255);
			end
			else
			begin
				GetDItem(MailDilg, 10, dType, dItem, tempRect);
				HiLiteControl(controlHandle(dItem), 255);
				GetDItem(MailDilg, 11, dType, dItem, tempRect);
				HiLiteControl(controlHandle(dItem), 255);
				GetDItem(MailDilg, 12, dType, dItem, tempRect);
				HiLiteControl(controlHandle(dItem), 255);
				GetDItem(MailDilg, 18, dType, dItem, tempRect);
				HiLiteControl(controlHandle(dItem), 255);
				GetDItem(MailDilg, 19, dType, dItem, tempRect);
				HiLiteControl(controlHandle(dItem), 255);
				GetDItem(MailDilg, 20, dType, dItem, tempRect);
				HiLiteControl(controlHandle(dItem), 255);
			end;
			SetCheckBox(MailDilg, 5, Mailer^^.MailerAware);
			SetCheckBox(MailDilg, 9, Mailer^^.AllowCrashMail);
			if Mailer^^.SubLaunchMailer = 1 then
				SetCheckBox(MailDilg, 11, True)
			else if Mailer^^.SubLaunchMailer = 2 then
				SetCheckBox(MailDilg, 12, True)
			else
			begin
				Mailer^^.SubLaunchMailer := 0;
				SetCheckBox(MailDilg, 10, True);
			end;
			if Mailer^^.InternetMail = FidoGated then
				SetCheckBox(MailDilg, 19, true)
			else if Mailer^^.InternetMail = Direct then
				SetCheckBox(MailDilg, 20, true)
			else
			begin
				Mailer^^.InternetMail := NoMail;
				SetCheckBox(MailDilg, 18, true);
			end;
			SetTextBox(MailDilg, 23, Mailer^^.FidoAddress);
			SetCheckBox(MailDilg, 26, Mailer^^.UseEMSI);

			FrameIt(MailDilg, 14);
			FrameIt(MailDilg, 30);
			FrameIt(MailDilg, 24);
			FrameIt(MailDilg, 27);

			GetDItem(MailDilg, 16, dType, dItem, tempRect);
			if newHand^^.Handle and newHand^^.realName and Mailer^^.MailerAware then
				HiLiteControl(controlHandle(dItem), 0)
			else
				HiLiteControl(controlHandle(dItem), 255);
			SetCheckBox(MailDilg, 16, Mailer^^.UseRealNames);

			GetDItem(MailDilg, 15, DType, DItem, tempRect);
			CItem := ControlHandle(DItem);
			myPop := popupHand(Citem^^.contrlData);
			for i := MAX_NODES downto InitSystHand^^.NumNodes + 1 do
				DelMenuItem(myPop^^.mHandle, i);
			if (Mailer^^.MailerNode < 1) or (Mailer^^.MailerNode > InitSystHand^^.NumNodes) then
				Mailer^^.MailerNode := 1;
			SetCtlValue(citem, Mailer^^.MailerNode);
			InsertMenu(myPop^^.mHandle, -1);

			GetDItem(MailDilg, 6, DType, DItem, tempRect);
			CItem := ControlHandle(DItem);
			myPop := popupHand(Citem^^.contrlData);
			if (Mailer^^.ImportSpeed < 1) or (Mailer^^.ImportSpeed > 4) then
				Mailer^^.ImportSpeed := 3;
			SetCtlValue(citem, Mailer^^.ImportSpeed);
			InsertMenu(myPop^^.mHandle, -1);

			ShowWindow(MailDilg);
			SelectWindow(MailDilg);
		end
		else
			SelectWindow(MailDilg);
	end;

	procedure OpenMenuPrefs;
		var
			tempRect, tr2: Rect;
			tempString: Str255;
			myC: Point;
			DType, i: integer;
			DItem: Handle;
			DataBounds: Rect;
			CItem, CTempItem: controlhandle;
	begin
		if (NodeDilg5 = nil) then
		begin
			NodeDilg5 := GetNewDialog(666, nil, Pointer(-1));
			SetPort(NodeDilg5);

			SetGeneva(NodeDilg5);
			GetDItem(NodeDilg5, 2, DType, DItem, tempRect);
			TempRect.right := tempRect.Right - 15;
			InsetRect(TempRect, -1, -1);
			FrameRect(TempRect);
			InsetRect(TempRect, 1, 1);
			SetRect(dataBounds, 0, 0, 1, 0);
			csize.h := tempRect.Right - tempRect.Left;
			csize.v := 14;
			menulist := LNew(tempRect, DataBounds, cSize, 0, NodeDilg5, false, false, false, true);
			menulist^^.selFlags := lOnlyOne + lNoNilHilite;
			for i := 1 to 50 do
			begin
				AddListString(MenuCmds[i], menuList);
			end;
			cSize.v := 0;
			cSize.h := 0;
			LSetSelect(True, cSize, menuList);
			LDoDraw(True, MenuList);
			csize.h := 0;
			csize.v := 0;
			EditingMenu := 1;

			PutMenuPrefs;

			SetUpMenu('A');

			ShowWindow(NodeDilg5);
			SelectWindow(NodeDilg5);
		end
		else
			SelectWindow(NodeDilg5);
	end;

	procedure OpenTransPrefs;
		var
			tempRect, tr2: Rect;
			tempString: Str255;
			myC: Point;
			DType, i: integer;
			DItem: Handle;
			DataBounds: Rect;
			CItem, CTempItem: controlhandle;
	begin
		if (NodeDilg6 = nil) then
		begin
			NodeDilg6 := GetNewDialog(667, nil, Pointer(-1));
			SetPort(NodeDilg6);

			SetGeneva(NodeDilg6);
			GetDItem(NodeDilg6, 2, DType, DItem, tempRect);
			TempRect.right := tempRect.Right - 15;
			InsetRect(TempRect, -1, -1);
			FrameRect(TempRect);
			InsetRect(TempRect, 1, 1);
			SetRect(dataBounds, 0, 0, 1, 0);
			csize.h := tempRect.Right - tempRect.Left;
			csize.v := 14;
			TransList := LNew(tempRect, DataBounds, cSize, 0, NodeDilg6, false, false, false, true);
			TransList^^.selFlags := lOnlyOne + lNoNilHilite;
			for i := 1 to 50 do
			begin
				AddListString(MenuCmds[i], TransList);
			end;
			cSize.v := 0;
			cSize.h := 0;
			LSetSelect(True, cSize, TransList);
			LDoDraw(True, TransList);
			csize.h := 0;
			csize.v := 0;
			EditingTrans := 1;

			PutTransPrefs;

			SetUpTransMenu('A');

			ShowWindow(NodeDilg6);
			SelectWindow(NodeDilg6);
		end
		else
			SelectWindow(NodeDilg6);
	end;

	procedure ClickInMailPrefs (theEvent: EventRecord; itemHit: integer);
		var
			myPt: Point;
			code, tempInt, y, i, xx: integer;
			tempInt2: longint;
			temprect: rect;
			tempstring, t1: str255;
			DType: integer;
			DItem: Handle;
			Doubleclick: Boolean;
			tempCell, tc2: cell;
			CItem, CTempItem: controlhandle;
			tempMenu: Menuhandle;
			adder: integer;
			adder2: real;
	begin
		if (MailDilg <> nil) and (frontWindow = MailDilg) then
		begin
			with theNodes[visibleNode]^ do
			begin
				SetPort(MailDilg);
				myPt := theEvent.where;
				GlobalToLocal(myPt);
				GetDItem(MailDilg, itemHit, DType, DItem, tempRect);
				CItem := Pointer(Ditem);
				case ItemHit of
					5: 
					begin
						if Mailer^^.MailerAware then
							Mailer^^.MailerAware := false
						else
							Mailer^^.MailerAware := true;
						SetCheckBox(MailDilg, 5, Mailer^^.MailerAware);
						if not Mailer^^.MailerAware then
						begin
							GetDItem(MailDilg, 10, dType, dItem, tempRect);
							HiLiteControl(controlHandle(dItem), 255);
							GetDItem(MailDilg, 11, dType, dItem, tempRect);
							HiLiteControl(controlHandle(dItem), 255);
							GetDItem(MailDilg, 12, dType, dItem, tempRect);
							HiLiteControl(controlHandle(dItem), 255);
							GetDItem(MailDilg, 18, dType, dItem, tempRect);
							HiLiteControl(controlHandle(dItem), 255);
							GetDItem(MailDilg, 19, dType, dItem, tempRect);
							HiLiteControl(controlHandle(dItem), 255);
							GetDItem(MailDilg, 20, dType, dItem, tempRect);
							HiLiteControl(controlHandle(dItem), 255);
							GetDItem(MailDilg, 16, dType, dItem, tempRect);
							HiLiteControl(controlHandle(dItem), 255);
						end
						else
						begin
							GetDItem(MailDilg, 10, dType, dItem, tempRect);
							HiLiteControl(controlHandle(dItem), 0);
							GetDItem(MailDilg, 11, dType, dItem, tempRect);
							HiLiteControl(controlHandle(dItem), 0);
							GetDItem(MailDilg, 12, dType, dItem, tempRect);
							HiLiteControl(controlHandle(dItem), 0);
							GetDItem(MailDilg, 18, dType, dItem, tempRect);
							HiLiteControl(controlHandle(dItem), 0);
							GetDItem(MailDilg, 19, dType, dItem, tempRect);
							HiLiteControl(controlHandle(dItem), 0);
							GetDItem(MailDilg, 20, dType, dItem, tempRect);
							HiLiteControl(controlHandle(dItem), 255);
							GetDItem(MailDilg, 16, dType, dItem, tempRect);
							if newHand^^.Handle and newHand^^.realName then
								HiLiteControl(controlHandle(dItem), 0)
							else
								HiLiteControl(controlHandle(dItem), 255);
						end;
					end;
					9: 
					begin
						if Mailer^^.AllowCrashMail then
							Mailer^^.AllowCrashMail := false
						else
							Mailer^^.AllowCrashMail := true;
						SetCheckBox(MailDilg, 9, Mailer^^.AllowCrashMail);
					end;
					10, 11, 12: 
					begin
						SetCheckBox(MailDilg, 10, False);
						SetCheckBox(MailDilg, 11, False);
						SetCheckBox(MailDilg, 12, False);
						if itemHit = 10 then
						begin
							Mailer^^.SubLaunchMailer := 0;
							SetCheckBox(MailDilg, 10, True);
						end
						else if itemHit = 11 then
						begin
							Mailer^^.SubLaunchMailer := 1;
							SetCheckBox(MailDilg, 11, True);
						end
						else if itemHit = 12 then
						begin
							Mailer^^.SubLaunchMailer := 2;
							SetCheckBox(MailDilg, 12, True);
						end;
					end;
					6: 
					begin
						GetDItem(MailDilg, 6, DType, DItem, tempRect);
						CItem := ControlHandle(DItem);
						Mailer^^.ImportSpeed := GetCtlValue(CItem);
					end;
					15: 
					begin
						GetDItem(MailDilg, 15, DType, DItem, tempRect);
						CItem := ControlHandle(DItem);
						Mailer^^.MailerNode := GetCtlValue(CItem);
					end;
					16: 
					begin
						if Mailer^^.UseRealNames then
							Mailer^^.UseRealNames := false
						else
							Mailer^^.UseRealNames := true;
						SetCheckBox(MailDilg, 16, Mailer^^.UseRealNames);
					end;
					1: 
					begin
						globalStr := 'Select Crashmail Application For Hermes';
						TempString := DoGetApplication;
						if TempString <> '' then
						begin
							Mailer^^.CrashMailPath := TempString;
							SetTextBox(MailDilg, 3, Mailer^^.CrashMailPath);
						end;
					end;
					2: 
					begin
						globalStr := 'Select Path For Generic Files';
						TempString := doGetDirectory;
						if TempString <> '' then
						begin
							Mailer^^.GenericPath := TempString;
							SetTextBox(MailDilg, 4, Mailer^^.GenericPath);
						end;
					end;
					7: 
					begin
						globalStr := 'Select Path For Next Event';
						TempString := doGetDirectory;
						if TempString <> '' then
						begin
							Mailer^^.EventPath := TempString;
							SetTextBox(MailDilg, 8, Mailer^^.EventPath);
						end;
					end;
					18, 19, 20: 
					begin
						SetCheckBox(MailDilg, 18, False);
						SetCheckBox(MailDilg, 19, False);
						SetCheckBox(MailDilg, 20, False);
						if itemHit = 18 then
						begin
							Mailer^^.InternetMail := NoMail;
							SetCheckBox(MailDilg, 18, True);
						end
						else if itemHit = 19 then
						begin
							Mailer^^.InternetMail := FidoGated;
							SetCheckBox(MailDilg, 19, True);
						end
						else if itemHit = 20 then
						begin
							Mailer^^.InternetMail := Direct;
							SetCheckBox(MailDilg, 20, True);
						end;
					end;
					26: 
					begin
						Mailer^^.UseEMSI := not Mailer^^.UseEMSI;
						SetCheckBox(MailDilg, 26, Mailer^^.UseEMSI);
					end;
					28: 
					begin
						globalStr := 'Select Mailer For Hermes';
						TempString := DoGetApplication;
						if TempString <> '' then
						begin
							Mailer^^.Application := TempString;
							SetTextBox(MailDilg, 29, Mailer^^.Application);
						end;
					end;
				end;
			end;
		end;
	end;

	procedure ClickInMenuPrefs (theEvent: EventRecord; itemHit: integer);
		var
			myPt: Point;
			code, tempInt, y, i, xx: integer;
			tempInt2: longint;
			temprect: rect;
			tempstring, t1: str255;
			DType: integer;
			DItem: Handle;
			Doubleclick: Boolean;
			tempCell, tc2: cell;
			CItem, CTempItem: controlhandle;
			tempMenu: Menuhandle;
			adder: integer;
			adder2: real;
	begin
		if (nodeDilg5 <> nil) and (frontWindow = NodeDilg5) then
		begin
			with theNodes[visibleNode]^ do
			begin
				SetPort(NodeDilg5);
				myPt := theEvent.where;
				GlobalToLocal(myPt);
				GetDItem(NodeDilg5, itemHit, DType, DItem, tempRect);
				CItem := Pointer(Ditem);
				case ItemHit of
					1: 
						CloseMenuPrefs;
					2: 
					begin
						DoubleClick := LClick(myPt, theEvent.modifiers, menuList);
						tempCell.h := 0;
						tempCell.v := 0;
						if LGetSelect(true, tempCell, menuList) then
						begin
							tempint := 50;
							LGetCell(@tempString[1], tempint, tempCell, menuList);
							if pos(tempString[1], MenuCmds) <> EditingMenu then
							begin
								WriteMenuPrefs;
								EditingMenu := pos(tempString[1], MenuCmds);
								PutMenuPrefs;
								SetUpMenu(TempString[1]);
							end;
						end;
					end;
					5, 6: 
					begin
						GetDItem(NodeDilg5, 5, dType, dItem, TempRect);
						if (itemhit = 5) then
							SetCtlValue(controlHandle(dItem), 1)
						else
							SetCtlValue(controlHandle(ditem), 0);
						GetDItem(NodeDilg5, 6, dType, dItem, TempRect);
						if (itemhit = 6) then
							SetCtlValue(controlHandle(dItem), 1)
						else
							SetCtlValue(controlHandle(ditem), 0);
					end;
					9: 
					begin
						adder := 10;
						if OptionDown then
							adder := 1;
						if (Menuhand^^.SecLevel[EditingMenu] <= (255 - adder)) then
						begin
							Menuhand^^.SecLevel[EditingMenu] := Menuhand^^.SecLevel[EditingMenu] + adder;
							SetTextBox(NodeDilg5, 8, StringOf(Menuhand^^.SecLevel[EditingMenu] : 0));
						end;
					end;
					10: 
					begin
						adder := 10;
						if OptionDown then
							adder := 1;
						if (Menuhand^^.SecLevel[EditingMenu] >= (0 + adder)) then
						begin
							Menuhand^^.SecLevel[EditingMenu] := Menuhand^^.SecLevel[EditingMenu] - adder;
							SetTextBox(NodeDilg5, 8, StringOf(Menuhand^^.SecLevel[EditingMenu] : 0));
						end;
					end;
					14: 
					begin
						adder := 10;
						if OptionDown then
							adder := 1;
						if (Menuhand^^.SecLevel2[EditingMenu] <= (255 - adder)) then
						begin
							Menuhand^^.SecLevel2[EditingMenu] := Menuhand^^.SecLevel2[EditingMenu] + adder;
							SetTextBox(NodeDilg5, 13, stringOf(Menuhand^^.SecLevel2[EditingMenu] : 0));
						end;
					end;
					15: 
					begin
						adder := 10;
						if OptionDown then
							adder := 1;
						if (Menuhand^^.SecLevel2[EditingMenu] >= (0 + adder)) then
						begin
							Menuhand^^.SecLevel2[EditingMenu] := Menuhand^^.SecLevel2[EditingMenu] - adder;
							SetTextBox(NodeDilg5, 13, stringOf(Menuhand^^.SecLevel2[EditingMenu] : 0));
						end;
					end;
					17: 
					begin
						adder := 10;
						if OptionDown then
							adder := 1;
						if (Menuhand^^.SecLevel3[EditingMenu] <= (255 - adder)) then
						begin
							Menuhand^^.SecLevel3[EditingMenu] := Menuhand^^.SecLevel3[EditingMenu] + adder;
							SetTextBox(NodeDilg5, 21, stringOf(Menuhand^^.SecLevel3[EditingMenu] : 0));
						end;
					end;
					18: 
					begin
						adder := 10;
						if OptionDown then
							adder := 1;
						if (Menuhand^^.SecLevel3[EditingMenu] >= (0 + adder)) then
						begin
							Menuhand^^.SecLevel3[EditingMenu] := Menuhand^^.SecLevel3[EditingMenu] - adder;
							SetTextBox(NodeDilg5, 21, stringOf(Menuhand^^.SecLevel3[EditingMenu] : 0));
						end;
					end;
					22..31: 
					begin
						SetCtlValue(CItem, (GetCtlValue(CItem) + 1) mod 2);
						Menuhand^^.Options[EditingMenu, itemhit - 21] := not Menuhand^^.Options[EditingMenu, itemhit - 21];
					end;
				end;
			end;
		end;
	end;

	procedure ClickInTransPrefs (theEvent: EventRecord; itemHit: integer);
		var
			myPt: Point;
			code, tempInt, y, i, xx: integer;
			tempInt2: longint;
			temprect: rect;
			tempstring, t1: str255;
			DType: integer;
			DItem: Handle;
			Doubleclick: Boolean;
			tempCell, tc2: cell;
			CItem, CTempItem: controlhandle;
			tempMenu: Menuhandle;
			adder: integer;
			adder2: real;
	begin
		if (nodeDilg6 <> nil) and (frontWindow = NodeDilg6) then
		begin
			with theNodes[visibleNode]^ do
			begin
				SetPort(NodeDilg6);
				myPt := theEvent.where;
				GlobalToLocal(myPt);
				GetDItem(NodeDilg6, itemHit, DType, DItem, tempRect);
				CItem := Pointer(Ditem);
				case ItemHit of
					1: 
						CloseTransPrefs;
					2: 
					begin
						DoubleClick := LClick(myPt, theEvent.modifiers, transList);
						tempCell.h := 0;
						tempCell.v := 0;
						if LGetSelect(true, tempCell, transList) then
						begin
							tempint := 50;
							LGetCell(@tempString[1], tempint, tempCell, transList);
							if pos(tempString[1], MenuCmds) <> EditingTrans then
							begin
								WriteTransPrefs;
								EditingTrans := pos(tempString[1], MenuCmds);
								PutTransPrefs;
								SetUpTransMenu(tempString[1]);
							end;
						end;
					end;
					5, 6: 
					begin
						GetDItem(NodeDilg6, 5, dType, dItem, TempRect);
						if (itemhit = 5) then
							SetCtlValue(controlHandle(dItem), 1)
						else
							SetCtlValue(controlHandle(ditem), 0);
						GetDItem(NodeDilg6, 6, dType, dItem, TempRect);
						if (itemhit = 6) then
							SetCtlValue(controlHandle(dItem), 1)
						else
							SetCtlValue(controlHandle(ditem), 0);
					end;
					9: 
					begin
						adder := 10;
						if OptionDown then
							adder := 1;
						if (TransHand^^.SecLevel[EditingTrans] <= (255 - adder)) then
						begin
							TransHand^^.SecLevel[EditingTrans] := TransHand^^.SecLevel[EditingTrans] + adder;
							SetTextBox(NodeDilg6, 8, StringOf(TransHand^^.SecLevel[EditingTrans] : 0));
						end;
					end;
					10: 
					begin
						adder := 10;
						if OptionDown then
							adder := 1;
						if (TransHand^^.SecLevel[EditingTrans] >= (0 + adder)) then
						begin
							TransHand^^.SecLevel[EditingTrans] := TransHand^^.SecLevel[EditingTrans] - adder;
							SetTextBox(NodeDilg6, 8, StringOf(TransHand^^.SecLevel[EditingTrans] : 0));
						end;
					end;
					22..31: 
					begin
						SetCtlValue(CItem, (GetCtlValue(CItem) + 1) mod 2);
						if (EditingTrans = 15) then
							Menuhand^^.Options[EditingTrans, itemhit - 21] := not Menuhand^^.Options[EditingTrans, itemhit - 21];
					end;
				end;
			end;
		end;
	end;

	procedure DoUserExport (senario: integer);
		var
			x, a: Integer;
			ExportDilg: DialogPtr;
			Tab, Tb: Boolean;
			UserFields: array[7..35] of Boolean;
			Labels: array[7..35] of Str255;
			DItem: handle;
			temprect: rect;
			tempPt: point;
			repo: SFReply;
			delim: char;
			refnum, i, offset, bytesRead: integer;
			l, l1: longint;
			yaba, t1: str255;
			tempUser: UserRec;
			tempCell: cell;
			myPtr: ptr;
	begin
		ExportDilg := GetNewDialog(1700, nil, pointer(-1));
		SetPort(ExportDilg);
		ShowWindow(ExportDilg);
		SetGeneva(ExportDilg);
		GetDItem(ExportDilg, 1, a, DItem, tempRect);
		InsetRect(tempRect, -4, -4);
		PenSize(3, 3);
		FrameRoundRect(tempRect, 16, 16);
		DrawDialog(ExportDilg);
		tab := true;
		for x := 7 to 35 do
			UserFields[x] := false;
		Labels[7] := 'User #';
		Labels[8] := 'Handle';
		Labels[9] := 'Real Name';
		Labels[10] := 'Voice Phone';
		Labels[11] := 'Data Phone';
		Labels[12] := 'Company';
		Labels[13] := 'Street Address';
		Labels[14] := 'City';
		Labels[15] := 'State';
		Labels[16] := 'Zip Code';
		Labels[17] := 'Country';
		Labels[18] := 'SysOp Note';
		Labels[19] := 'Misc. Field #1';
		Labels[20] := 'Misc. Field #2';
		Labels[21] := 'Misc. Field #3';
		Labels[22] := 'First Logon';
		Labels[23] := 'Last Logon';
		Labels[24] := 'Gender';
		Labels[25] := 'Age';
		Labels[26] := 'Security Level';
		Labels[27] := 'Transfer SL';
		Labels[28] := 'Msgs Posted';
		Labels[29] := 'EMail Sent';
		Labels[30] := 'Number Of U/l''s';
		Labels[31] := 'Number Of KBytes U/l''ed';
		Labels[32] := 'Number Of D/l''s';
		Labels[33] := 'Number Of KBytes D/l''ed';
		Labels[34] := 'Total Logons';
		Labels[35] := 'Total Minutes On';
		SetCheckBox(ExportDilg, 4, true);
		repeat
			ModalDialog(nil, a);
			if (a = 4) and (not tab) then
			begin
				tab := true;
				SetCheckBox(ExportDilg, 4, true);
				SetCheckBox(ExportDilg, 5, false);
			end;
			if (a = 5) and (tab) then
			begin
				tab := false;
				SetCheckBox(ExportDilg, 4, false);
				SetCheckBox(ExportDilg, 5, true);
			end;
			if (a > 6) and (a < 36) then
			begin
				if UserFields[a] then
				begin
					SetCheckBox(ExportDilg, a, false);
					UserFields[a] := False;
				end
				else
				begin
					SetCheckBox(ExportDilg, a, true);
					UserFields[a] := True;
				end;
			end;
		until (a = 1) or (a = 2);
		DisposDialog(ExportDilg);
		if (a = 1) then
		begin
			a := 0;
			for x := 7 to 35 do
				if UserFields[x] then
				begin
					a := 1;
					leave;
				end;
			if a = 0 then
				ProblemRep('No Fields Chosen.')
			else
			begin
				SetPt(tempPt, 40, 40);
				SFPutFile(tempPt, 'Please name your export file:', 'User Export File', nil, repo);
				if repo.good then
				begin
					result := FSDelete(repo.fName, repo.vrefNum);
					result := Create(repo.fname, repo.vrefnum, 'HRMS', 'TEXT');
					result := FSOpen(repo.fname, repo.vRefNum, refnum);
					if tab then
						delim := char(9)
					else
						delim := ',';
					for x := 7 to 35 do
					begin
						labels[x] := concat(labels[x], delim);
						l := length(labels[x]);
						if UserFields[x] then
						begin
							result := FSWrite(refnum, l, @labels[x][1]);
						end;
					end;
					l := 1;
					yaba := char(13);
					result := FSWrite(refnum, l, @yaba[1]);
					i := 0;
					ExportDilg := GetNewDialog(1701, nil, pointer(-1));
					SetPort(ExportDilg);
					ShowWindow(ExportDilg);
					DrawDialog(ExportDilg);
					SetTextBox(ExportDilg, 4, StringOf(senario : 0));
					for i := 1 to senario do
					begin
						SetTextBox(ExportDilg, 5, StringOf(i : 0));
						if senario <> -1 then
						begin
							tempCell.h := 0;
							tempCell.v := i - 1;
							LFind(offset, bytesRead, tempCell, GUList);
							HLockHi(handle(GUList^^.cells));
							myPtr := Ptr(ORD4(GUList^^.cells^) + offset);
							t1 := Str255PtrType(myPtr)^;
							t1[0] := char(bytesRead - 1);
							x := Pos('/#', t1);
							t1 := copy(t1, x + 2, length(t1));
							HUnlock(handle(GUList^^.cells));
						end
						else
							NumToString(i, t1);
						tb := FindUser(t1, tempUser);
						if (not tempUser.DeletedUser) and (tb) then
						begin
							if UserFields[7] then
							begin
								NumToString(tempUser.UserNum, yaba);
								yaba := concat(yaba, delim);
								l := length(yaba);
								result := FSWrite(refnum, l, @yaba[1]);
							end;
							if UserFields[8] then
							begin
								yaba := concat(tempUser.Alias, delim);
								l := length(yaba);
								result := FSWrite(refnum, l, @yaba[1]);
							end;
							if UserFields[9] then
							begin
								yaba := concat(tempUser.RealName, delim);
								l := length(yaba);
								result := FSWrite(refnum, l, @yaba[1]);
							end;
							if UserFields[10] then
							begin
								yaba := concat(tempUser.phone, delim);
								l := length(yaba);
								result := FSWrite(refnum, l, @yaba[1]);
							end;
							if UserFields[11] then
							begin
								yaba := concat(tempUser.dataPhone, delim);
								l := length(yaba);
								result := FSWrite(refnum, l, @yaba[1]);
							end;
							if UserFields[12] then
							begin
								yaba := concat(tempUser.company, delim);
								l := length(yaba);
								result := FSWrite(refnum, l, @yaba[1]);
							end;
							if UserFields[13] then
							begin
								yaba := concat(tempUser.Street, delim);
								l := length(yaba);
								result := FSWrite(refnum, l, @yaba[1]);
							end;
							if UserFields[14] then
							begin
								yaba := concat(tempUser.City, delim);
								l := length(yaba);
								result := FSWrite(refnum, l, @yaba[1]);
							end;
							if UserFields[15] then
							begin
								yaba := concat(tempUser.State, delim);
								l := length(yaba);
								result := FSWrite(refnum, l, @yaba[1]);
							end;
							if UserFields[16] then
							begin
								yaba := concat(tempUser.Zip, delim);
								l := length(yaba);
								result := FSWrite(refnum, l, @yaba[1]);
							end;
							if UserFields[17] then
							begin
								yaba := concat(tempUser.Country, delim);
								l := length(yaba);
								result := FSWrite(refnum, l, @yaba[1]);
							end;
							if UserFields[18] then
							begin
								yaba := concat(tempUser.SysOpNote, delim);
								l := length(yaba);
								result := FSWrite(refnum, l, @yaba[1]);
							end;
							if UserFields[19] then
							begin
								yaba := concat(tempUser.MiscField1, delim);
								l := length(yaba);
								result := FSWrite(refnum, l, @yaba[1]);
							end;
							if UserFields[20] then
							begin
								yaba := concat(tempUser.MiscField2, delim);
								l := length(yaba);
								result := FSWrite(refnum, l, @yaba[1]);
							end;
							if UserFields[21] then
							begin
								yaba := concat(tempUser.MiscField3, delim);
								l := length(yaba);
								result := FSWrite(refnum, l, @yaba[1]);
							end;
							if UserFields[22] then
							begin
								yaba := concat(getDate(tempUser.FirstOn), delim);
								l := length(yaba);
								result := FSWrite(refnum, l, @yaba[1]);
							end;
							if UserFields[23] then
							begin
								yaba := concat(getDate(tempUser.lastOn), delim);
								l := length(yaba);
								result := FSWrite(refnum, l, @yaba[1]);
							end;
							if UserFields[24] then
							begin
								if tempUser.sex then
									yaba := 'M'
								else
									yaba := 'F';
								yaba := concat(yaba, delim);
								l := length(yaba);
								result := FSWrite(refnum, l, @yaba[1]);
							end;
							if UserFields[25] then
							begin
								NumToString(tempUser.age, yaba);
								yaba := concat(yaba, delim);
								l := length(yaba);
								result := FSWrite(refnum, l, @yaba[1]);
							end;
							if UserFields[26] then
							begin
								NumToString(tempUser.SL, yaba);
								yaba := concat(yaba, delim);
								l := length(yaba);
								result := FSWrite(refnum, l, @yaba[1]);
							end;
							if UserFields[27] then
							begin
								NumToString(tempUser.DSL, yaba);
								yaba := concat(yaba, delim);
								l := length(yaba);
								result := FSWrite(refnum, l, @yaba[1]);
							end;
							if UserFields[28] then
							begin
								NumToString(tempUser.MessagesPosted, yaba);
								yaba := concat(yaba, delim);
								l := length(yaba);
								result := FSWrite(refnum, l, @yaba[1]);
							end;
							if UserFields[29] then
							begin
								NumToString(tempUser.EMailSent, yaba);
								yaba := concat(yaba, delim);
								l := length(yaba);
								result := FSWrite(refnum, l, @yaba[1]);
							end;
							if UserFields[30] then
							begin
								NumToString(tempUser.NumUploaded, yaba);
								yaba := concat(yaba, delim);
								l := length(yaba);
								result := FSWrite(refnum, l, @yaba[1]);
							end;
							if UserFields[31] then
							begin
								NumToString(tempUser.UploadedK, yaba);
								yaba := concat(yaba, delim);
								l := length(yaba);
								result := FSWrite(refnum, l, @yaba[1]);
							end;
							if UserFields[32] then
							begin
								NumToString(tempUser.NumDownloaded, yaba);
								yaba := concat(yaba, delim);
								l := length(yaba);
								result := FSWrite(refnum, l, @yaba[1]);
							end;
							if UserFields[33] then
							begin
								NumToString(tempUser.DownloadedK, yaba);
								yaba := concat(yaba, delim);
								l := length(yaba);
								result := FSWrite(refnum, l, @yaba[1]);
							end;
							if UserFields[34] then
							begin
								NumToString(tempUser.TotalLogons, yaba);
								yaba := concat(yaba, delim);
								l := length(yaba);
								result := FSWrite(refnum, l, @yaba[1]);
							end;
							if UserFields[35] then
							begin
								NumToString(tempUser.TotalTimeOn, yaba);
								yaba := concat(yaba, delim);
								l := length(yaba);
								result := FSWrite(refnum, l, @yaba[1]);
							end;
							l := 1;
							yaba := char(13);
							result := FSWrite(refnum, l, @yaba[1]);
						end;
					end;
					result := FSClose(refnum);
					DisposDialog(ExportDilg);
				end
				else
				begin
					exit(DoUserExport);
				end;
			end;
		end;
	end;
end.