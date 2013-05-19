{ Segments: FileTrans2_1 }
unit FileTrans2;

interface
	uses
		AppleTalk, ADSP, Serial, Sound, TCPTypes, Initial, LoadAndSave, NodePrefs2, NodePrefs, SystemPrefs, Message_Editor, Terminal, inpOut4, inpOut3, FileTrans3;

	procedure EnterExtended;
	procedure OpenTransferSections;
	procedure CloseTransferSections (theWindow: WindowPtr);
	procedure UpdateTransferSections (theWindow: WindowPtr);
	procedure DoTransferSections (theEvent: EventRecord; theWindow: WindowPtr; itemHit: integer);
	procedure DoMove;
	function AskDesc (fileName: str255): str255;
	procedure UploadVRef (dirPath: str255);
	procedure RemoveFiles;
	procedure SwitchError (er: str255);
	procedure EditTransferSec (new: boolean; which: integer);
	procedure RemoveIt;

implementation
	var
		ForumList, DirectoryList: ListHandle;
		Rect_I_List1, Rect_I_List2: Rect;
		ExitDialog: Boolean;
		tempRect: Rect;
		DType: Integer;
		Index: Integer;
		DItem: Handle;
		CItem, CTempItem: controlhandle;
		temp: Integer;
		dataBounds: Rect;
		cSize, selectThis: Point;
		curDir: integer;

{$S FileTrans2_1}
	function AskDesc (fileName: str255): str255;
		var
			askDilg: dialogPtr;
			ThisEditText: TEHandle;
			TheDialogPtr: DialogPeek;
			DType, a: Integer;
			DItem: Handle;
			tempRect: rect;
			tempString: str255;
	begin
		with curglobs^ do
		begin
			repeat
				askDilg := GetNewDialog(744, nil, pointer(-1));
				SetPort(askDilg);
				TheDialogPtr := DialogPeek(askDilg);
				ThisEditText := TheDialogPtr^.textH;
				HLock(Handle(ThisEditText));
				ThisEditText^^.txSize := 9;
				TextSize(9);
				ThisEditText^^.txFont := monaco;
				TextFont(monaco);
				ThisEditText^^.txFont := 4;
				ThisEditText^^.fontAscent := 9;
				ThisEditText^^.lineHeight := 9 + 2 + 0;
				HUnLock(Handle(ThisEditText));
				NumToString(70 - forums^^[tempInDir].dr[tempSubDir].fileNameLength, tempstring);
				ParamText(concat('Please enter a <', tempstring, ' character description for ', fileName, ' :'), '', '', '');
				DrawDialog(askDilg);
				repeat
					ModalDialog(nil, a);
				until (a = 1);
				GetDItem(askDilg, 3, DType, DItem, tempRect);
				GetIText(DItem, tempString);
				DisposDialog(askDilg);
				if length(tempString) > (70 - forums^^[tempInDir].dr[tempSubDir].fileNameLength) then
				begin
					askDilg := GetNewDialog(1055, nil, pointer(-1));
					NumToString(70 - forums^^[tempInDir].dr[tempSubDir].fileNameLength, tempstring);
					ParamText(concat('File description must be less than ', tempstring, ' characters.'), '', '', '');
					DrawDialog(askDilg);
					SysBeep(10);
					repeat
						ModalDialog(nil, a);
					until (a = 1);
					DisposDialog(askDilg);
				end;
			until (length(tempString) < (70 - forums^^[tempInDir].dr[tempSubDir].fileNameLength));
			askDesc := tempString;
		end;
	end;

	procedure UploadVRef (dirPath: str255);
		var
			index, tempint: integer;
			FName: Str255;
			myCPB: CInfoPBRec;
			myHPB: HParamBlockRec;
			err: OSErr;
			CONFIRMER, didIt: boolean;
		procedure EnumerateCatalog (dirIDToSearch: longint);
			var
				ic: integer;
		begin {EnumerateCatalog}
			with curglobs^ do
			begin
				index := 1;
				repeat
					FName := '';
					myCPB.ioFDirIndex := index;
					myCPB.ioDrDirID := dirIDToSearch;
					err := PBGetCatInfo(@myCPB, FALSE);
					if err = noErr then
						if not (BitTst(@myCPB.ioFlAttrib, 3)) then
						begin {we have a file}
							if confirmer then
								didIt := (ModalQuestion(concat('Upload " ', fName, ' " ?'), false, true) = 1)
							else
								didIt := true;
							if didIt then
							begin
								if confirmer then
									curFil.flDesc := AskDesc(fName)
								else
									curFil.flDesc := '';
								curFil.realFName := fName;
								curFil.flName := fName;
								GetDateTime(curFil.whenUL);
								curFil.uploaderNum := thisUser.userNum;
								curFil.numDLoads := 0;
								curFil.hasExtended := false;
								curFil.fileStat := char(0);
								curFil.lastDL := 0;
								for ic := 1 to 50 do
									curFil.reserved[ic] := char(0);
								curFil.Version := '';
								curFil.FileType := myCPB.ioFlFndrInfo.fdtype;
								CurFil.FileCreator := myCPB.ioFlFndrInfo.fdcreator;
								CurFil.FileNumber := 0;
								FileEntry(curFil, tempinDir, tempSubDir, tempInt, 0);
								thisUser.numUploaded := thisUser.numUploaded + 1;
								thisUser.UploadedK := thisUser.UploadedK + tempint;
								InitSystHand^^.kuploaded[activeNode] := InitSystHand^^.kuploaded[activeNode] + tempint;
								InitSystHand^^.uploadsToday[activeNode] := InitSystHand^^.uploadsToday[activeNode] + 1;
								GetDateTime(InitSystHand^^.lastUL);
								DoSystRec(true);
								GetDateTime(ForumIdx^^.lastupload[tempInDir, tempSubDir]);
								DoForumRec(true);
							end;
						end; {else}
					index := index + 1;
				until (err <> noErr);
			end;
		end;  {EnumerateCatalog}

{begin uploadVRef}
	begin
		confirmer := (ModalQuestion('Confirm choices and ask for descriptions?', false, true) = 1);
		myCPB.ioCompletion := nil;
		myCPB.ioNamePtr := @dirPath;
		myCPB.ioVRefNum := 0;
		myCPB.ioFDirIndex := 0;
		result := PBGetCatInfo(@myCPB, false);
		myHPB.ioCompletion := nil;
		myHPB.ioNamePtr := @dirPath;
		myHPB.ioVRefNum := 0;
		myHPB.ioVolIndex := -1;
		result := PBHGetVInfo(@myHPB, false);
		myCPB.iovRefNum := myHPB.ioVRefNum;
		myCPB.ioNamePtr := @fName;
		if result = noErr then
			EnumerateCatalog(myCPB.ioDrDirID);
		curglobs^.lastKeyPressed := tickCount;
	end;

{$D-}
	function FindCell (TheList: ListHandle; mousPos: point): cell;
		var
			startCell, selCell: cell;
			temprect: rect;
	begin
		StartCell := cell($00000000);
		selCell := cell($FFFFFFFF);
		repeat
			LRect(temprect, startCell, TheList);
			if PtInRect(mousPos, tempRect) then
				selCell := startCell;
		until not LNextCell(false, true, startCell, TheList);
		FindCell := selcell;
	end;


	function FmyListDragger: boolean;
		var
			myCell, myCell2: cell;
			tempRect: rect;
			tempBool, tempbool2, tb3: boolean;
			curMouse: point;
			addLine, i, useddiff, tempint: integer;
			movedTo, hDiff, vDiff: longint;
			takeThis, toHere: integer;
			dragged: rgnHandle;
			tempForums: DirListHand;
			tempForumIdx: ForumIdxHand;
	begin
		tempbool2 := true;
		SetPort(getDSelection);
		myCell := LLastClick(ForumList);
		myCell2 := cell($00000000);
		tempbool := LGetSelect(true, myCell2, ForumList);
		if (longint(myCell) = longint(mycell2)) and (myCell.v >= 0) and (myCell.v < ForumList^^.dataBounds.bottom) and tempBool and (myCell2.v < ForumList^^.dataBounds.bottom) then
		begin
			if (longint(myCell) = longint(DragFirst)) then
			begin
				myCell2.h := 0;
				myCell2.v := 0;
				LRect(temprect, myCell, ForumList);
				dragged := NewRgn;
				OpenRgn;
				FrameRect(tempRect);
				CloseRgn(dragged);
				movedTo := DragGrayRgn(dragged, ForumList^^.clikLoc, ForumList^^.rView, GetDSelection^.portRect, vAxisOnly, nil);
				DisposeRgn(dragged);
				vDiff := hiWord(movedTo);
				hDiff := LoWord(movedTo);
				usedDiff := temprect.top + abs(vDiff);
				if ((vDiff <> $8000) and (hDiff <> $8000)) and (abs(usedDiff - tempRect.top) > 8) then
				begin
					curMouse.v := ForumList^^.clikLoc.v + vDiff;
					curmouse.h := ForumList^^.clikLoc.h + hDiff;
					myCell2 := FindCell(ForumList, curMouse);
					if (longint(mycell2) <> $FFFFFFFF) and (longint(mycell2) <> longint(myCell)) then
					begin
						takeThis := myCell.v;
						toHere := myCell2.v;

						tempForumIdx^^.name[1] := forumIdx^^.name[takethis];
						tempForumIdx^^.MinDsl[1] := forumIdx^^.MinDsl[takethis];
						tempForumIdx^^.Restriction[1] := forumIdx^^.Restriction[takethis];
						tempForumIdx^^.numDirs[1] := forumIdx^^.numDirs[takethis];
						tempForumIdx^^.age[1] := forumIdx^^.age[takethis];
						tempforums := DirListHand(NewHandleClear(0));
						SetHandleSize(handle(tempforums), sizeOf(DirDataFile));
						tempForums^^[0] := forums^^[takethis];
						if forumIdx^^.numforums - 1 > (takeThis + 1) then
						begin
							for i := (takeThis + 2) to forumIdx^^.numforums - 1 do
							begin
								forumIdx^^.name[i - 2] := forumIdx^^.name[i - 1];
								forumIdx^^.MinDsl[i - 2] := forumIdx^^.MinDsl[i - 1];
								forumIdx^^.Restriction[i - 2] := forumIdx^^.Restriction[i - 1];
								forumIdx^^.numDirs[i - 2] := forumIdx^^.numDirs[i - 1];
								forumIdx^^.age[i - 2] := forumIdx^^.age[i - 1];
								forums^^[i - 2] := forums^^[i - 1];
							end;
						end;
						if forumIdx^^.numforums - 1 > (toHere + 1) then
						begin
							for i := forumIdx^^.numforums - 1 downto (toHere + 2) do
							begin
								forumIdx^^.name[i - 1] := forumIdx^^.name[i - 2];
								forumIdx^^.MinDsl[i - 1] := forumIdx^^.MinDsl[i - 2];
								forumIdx^^.Restriction[i - 1] := forumIdx^^.Restriction[i - 2];
								forumIdx^^.numDirs[i - 1] := forumIdx^^.numDirs[i - 2];
								forumIdx^^.age[i - 1] := forumIdx^^.age[i - 2];
								forums^^[i - 1] := forums^^[i - 2];
							end;
						end;
						forumIdx^^.name[tohere] := tempForumIdx^^.name[1];
						forumIdx^^.MinDsl[tohere] := tempForumIdx^^.MinDsl[1];
						forumIdx^^.Restriction[tohere] := tempForumIdx^^.Restriction[1];
						forumIdx^^.numDirs[tohere] := tempForumIdx^^.numDirs[1];
						forumIdx^^.age[tohere] := tempForumIdx^^.age[1];
						forums^^[tohere] := tempForums^^[0];
					end;
					LDelRow(0, 0, ForumList);
					for i := 1 to forumIdx^^.numforums do
					begin
						AddListString(forumIdx^^.name[i - 1], ForumList);
					end;
				end;
			end;
			DragFirst := myCell2;
		end;
		FmyListDragger := tempbool2;
		DisposHandle(handle(tempForums));
	end;
{$D+}

{$D-}

	function MouseVSSelected (aList: listHandle; aCell: cell): boolean;
		var
			curPoint: point;
			bCell: cell;
	begin
		GetMouse(curPoint);
		bCell := FindCell(aList, cell(curPoint));
		if longint(bCell) = longint(aCell) then
			MouseVSSelected := true
		else
			MouseVSSelected := false;
	end;

	function FmyListDragger2: boolean;
		var
			myCell, myCell2: cell;
			tempRect: rect;
			tempBool, tempbool2, tb3: boolean;
			curMouse: point;
			addLine, i, useddiff, tempint, mdm: integer;
			movedTo, hDiff, vDiff: longint;
			takeThis, toHere: integer;
			dragged: rgnHandle;
			tempDirInfo: DirInfoRec;
			newForum: ReadDirHandle;
			upload: longint;
			t1: str255;
	begin
		tempbool2 := true;
		SetPort(getDSelection);
		GetMouse(curMouse);
		myCell := cell($00000000);
		tempbool := LGetSelect(true, myCell, DirectoryList);
		tempBool := MouseVSSelected(DirectoryList, myCell);
		if (myCell.v >= 0) and (myCell.v < DirectoryList^^.dataBounds.bottom) and tempBool then
		begin
			LRect(temprect, myCell, DirectoryList);
			DirectoryList^^.clikLoc.v := curMouse.v;
			dragged := NewRgn;
			OpenRgn;
			FrameRect(tempRect);
			CloseRgn(dragged);
			movedTo := DragGrayRgn(dragged, DirectoryList^^.clikLoc, DirectoryList^^.rView, GetDSelection^.portRect, vAxisOnly, nil);
			DisposeRgn(dragged);
			vDiff := hiWord(movedTo);
			hDiff := LoWord(movedTo);
			usedDiff := temprect.top + abs(vDiff);
			if ((vDiff <> $8000) and (hDiff <> $8000)) and (abs(usedDiff - tempRect.top) > 8) then
			begin
				curMouse.v := DirectoryList^^.clikLoc.v + vDiff;
				curmouse.h := DirectoryList^^.clikLoc.h + hDiff;
				myCell2 := FindCell(DirectoryList, curMouse);
				if (longint(mycell2) <> $FFFFFFFF) and (longint(mycell2) <> longint(myCell)) then
				begin
					takeThis := myCell.v + 1;
					toHere := myCell2.v + 1;
					tempDirInfo := forums^^[curdir].dr[takethis];
					upload := forumIdx^^.lastupload[curdir, takethis];
					if ForumIdx^^.numDirs[curdir] > (takeThis) then
					begin
						for i := (takeThis + 1) to ForumIdx^^.numDirs[curdir] do
						begin
							forums^^[curdir].dr[i - 1] := forums^^[curdir].dr[i];
							forumidx^^.lastupload[curdir, i - 1] := forumIdx^^.lastupload[curdir, i];
						end;
					end;
					if ForumIdx^^.numDirs[curdir] > (toHere) then
					begin
						for i := ForumIdx^^.numDirs[curdir] downto (toHere + 1) do
						begin
							forums^^[curdir].dr[i] := forums^^[curdir].dr[i - 1];
							forumidx^^.lastupload[curdir, i] := forumIdx^^.lastupload[curdir, i - 1];
						end;
					end;
					forums^^[curdir].dr[toHere] := tempDirInfo;
					forumIdx^^.lastUpload[curDir, toHere] := upload;
					doForumRec(true);
				end;
				LDelRow(0, 0, DirectoryList);
				for i := 1 to ForumIdx^^.numDirs[curdir] do
				begin
					AddListString(forums^^[curdir].dr[i].dirname, DirectoryList);
				end;
				mdm := OpenRFPerm(concat(SharedFiles, 'Directories'), 0, fsRdWrPerm);
				newForum := ReadDirHandle(GetNamedResource('Dirs', forumIdx^^.name[curDir]));
				HLock(handle(newForum));
				newForum^^ := forums^^[CurDir];
				ChangedResource(handle(NewForum));
				WriteResource(handle(newForum));
				DetachResource(handle(newForum));
				HUnlock(handle(newForum));
				DisposHandle(handle(newForum));
				CloseResFile(mdm);
			end;
		end;
		FmyListDragger2 := tempbool2;
	end;
{$D+}

	function myMDFilter (theDialog: dialogPtr; var ev: EventRecord; var it: integer): boolean;
		var
			localPt: point;
			t: integer;
	begin
		if (ev.what = mouseDown) then
		begin
			SetPort(theDialog);
			localPt := ev.where;
			GlobalToLocal(localPt);
			if LClick(localPt, ev.modifiers, ForumList) then
			begin
				selectThis.h := 0;
				selectThis.v := 0;
				if LGetSelect(true, selectThis, ForumList) then
					;
			end;
		end;
		myMDFilter := false;
	end;

	procedure CloseTransferSections;
	begin
		if (theWindow = GetDSelection) and (GetDSelection <> nil) then
		begin
			DoForumRec(True);
			DisposDialog(GetDSelection);
			GetDSelection := nil;
		end;
	end;

	procedure UpdateTransferSections;
		var
			SavedPort: GrafPtr;
	begin
		if (GetDSelection <> nil) and (theWindow = GetDSelection) then
		begin
			GetPort(SavedPort);
			SetPort(GetDSelection);
			DrawDialog(GetDSelection);
			tempRect := Rect_I_List1;
			tempRect.Right := tempRect.Right - 15;
			if (tempRect.Right <= (tempRect.Left + 10)) then
				tempRect.Right := tempRect.Left + 10;
			InsetRect(tempRect, -1, -1);
			FrameRect(tempRect);
			LUpdate(ForumList^^.port^.visRgn, ForumList);

			tempRect := Rect_I_List2;
			tempRect.Right := tempRect.Right - 15;
			if (tempRect.Right <= (tempRect.Left + 10)) then
				tempRect.Right := tempRect.Left + 10;
			InsetRect(tempRect, -1, -1);
			FrameRect(tempRect);
			LUpdate(DirectoryList^^.port^.visRgn, DirectoryList);
			SetPort(SavedPort);
		end;
	end;

	procedure OpenTransferSections;
		var
			Index, i, a: integer;
			theRow: integer;
			MyD: DialogPtr;
			TempString: Str255;
	begin
		if (GetDSelection = nil) then
		begin
			GetDSelection := GetNewDialog(4, nil, Pointer(-1));
			SetPort(GetDSelection);
			SetGeneva(GetDSelection);

			GetDItem(GetDSelection, 4, DType, DItem, Rect_I_List1);
			tempRect := Rect_I_List1;
			tempRect.Right := tempRect.Right - 15;
			if (tempRect.Right <= (tempRect.Left + 15)) then
				tempRect.Right := tempRect.Left + 15;
			InsetRect(tempRect, -1, -1);
			FrameRect(tempRect);
			InsetRect(tempRect, 1, 1);
			SetRect(dataBounds, 0, 0, 1, 0);
			cSize.h := tempRect.Right - tempRect.Left;
			cSize.v := 15;
			ForumList := LNew(tempRect, dataBounds, cSize, 0, GetDSelection, false, FALSE, FALSE, TRUE);
			ForumList^^.selFlags := lOnlyOne + lNoNilHilite;
{    ForumList^^.lClikLoop := @FmyListDragger;}
			if forumIdx^^.numforums > 0 then
			begin
				for i := 1 to forumIdx^^.numforums do
				begin
					AddListString(forumIdx^^.name[i - 1], ForumList);
				end;
				cSize.v := 0;
				cSize.h := 0;
				LSetSelect(True, cSize, ForumList);
			end;
			cSize.v := 0;
			cSize.h := 0;
			LSetSelect(True, cSize, ForumList);
			LdoDraw(TRUE, ForumList);
			curDir := 0;

			GetDItem(GetDSelection, 8, DType, DItem, Rect_I_List2);
			tempRect := Rect_I_List2;
			tempRect.Right := tempRect.Right - 15;
			if (tempRect.Right <= (tempRect.Left + 15)) then
				tempRect.Right := tempRect.Left + 15;
			InsetRect(tempRect, -1, -1);
			FrameRect(tempRect);
			InsetRect(tempRect, 1, 1);
			SetRect(dataBounds, 0, 0, 1, 0);
			cSize.h := tempRect.Right - tempRect.Left;
			cSize.v := 15;
			DirectoryList := LNew(tempRect, dataBounds, cSize, 0, GetDSelection, false, FALSE, FALSE, TRUE);
			DirectoryList^^.selFlags := lOnlyOne + lNoNilHilite;
			DirectoryList^^.lClikLoop := @FmyListDragger2;

			if (forumIdx^^.numforums > 0) and (ForumIdx^^.numDirs[curDir] > 0) then
				for i := 1 to ForumIdx^^.numDirs[curdir] do
				begin
					AddListString(forums^^[curdir].dr[i].dirname, DirectoryList);
				end;
			cSize.v := 0;
			cSize.h := 0;
			LSetSelect(True, cSize, DirectoryList);
			LdoDraw(TRUE, DirectoryList);
			ShowWindow(GetDSelection);
			LActivate(TRuE, DirectoryList);
			LActivate(TRuE, forumList);
		end
		else
			SelectWindow(getDSelection);
	end;

	procedure EditTransferSec (new: boolean; which: integer);
		var
			ModeratorDlg, theDilg, tempDialog: dialogPtr;
			s1, t1, oldname, stemp, tempstring: str255;
			a, b, i, adder: integer;
			adder2: real;
			ttUser: UserRec;
			result: OSErr;
			s26: string[26];
		procedure SetNewStat;
		begin
			SetCheckBox(theDilg, 28, false);
			SetCheckBox(theDilg, 29, false);
			SetCheckBox(theDilg, 30, false);
			SetCheckBox(theDilg, 29 - forums^^[curDir].dr[which].mode, true);
		end;
		procedure DrawPath;
		begin
			GetDItem(theDilg, 26, DType, DItem, tempRect);
			FrameRect(temprect);
			TextSize(9);
			TextFont(3);
			InsetRect(tempRect, 2, 2);
			TextBox(@forums^^[curDir].dr[which].path[1], length(forums^^[curDir].dr[which].path), temprect, teJustLeft);
		end;
	begin
		if new then
		begin
			with forums^^[curDir].dr[which] do
			begin
				DirName := stringOf('Directory', which : 0);
				Path := 'Macintosh HD:Hermes Files:Files:';
				if which > 1 then
				begin
					MinDSL := forums^^[curDir].dr[which - 1].MinDsl;
					DSLtoUL := forums^^[curDir].dr[which - 1].DSLtoUL;
					DSLtoDL := forums^^[curDir].dr[which - 1].DSLtoDL;
					MaxFiles := forums^^[curDir].dr[which - 1].MaxFiles;
					Restriction := forums^^[curDir].dr[which - 1].Restriction;
					NonMacFiles := forums^^[curDir].dr[which - 1].NonMacFiles;
					freeDir := forums^^[curDir].dr[which - 1].freeDir;
					mode := forums^^[curDir].dr[which - 1].mode;   {  -1 = Never New, 0=Normal , 1= Always New  }
					MinAge := forums^^[curDir].dr[which - 1].MinAge;
					FileNameLength := forums^^[curDir].dr[which - 1].FileNameLength;
					Color := forums^^[curDir].dr[which - 1].Color;
					TapeVolume := forums^^[curDir].dr[which - 1].TapeVolume;
					SlowVolume := forums^^[curDir].dr[which - 1].SlowVolume;
					AllowUploads := forums^^[curDir].dr[which - 1].AllowUploads;
					Handles := forums^^[curDir].dr[which - 1].Handles;
					ShowUploader := forums^^[curDir].dr[which - 1].ShowUploader;
					DLCost := forums^^[curDir].dr[which - 1].DLCost;
					ULCost := forums^^[curDir].dr[which - 1].ULCost;
					DLCreditor := forums^^[curDir].dr[which - 1].DLCreditor;
					HowLong := forums^^[curDir].dr[which - 1].HowLong;
					UploadOnly := forums^^[curDir].dr[which - 1].UploadOnly;
				end
				else
				begin
					MinDSL := 10;
					DSLtoUL := 10;
					DSLtoDL := 10;
					MaxFiles := 200;
					Restriction := char(0);
					NonMacFiles := 0;
					freeDir := false;
					mode := 0;   {  -1 = Never New, 0=Normal , 1= Always New  }
					MinAge := 0;
					FileNameLength := 20;
					Color := 0;
					TapeVolume := False;
					SlowVolume := False;
					AllowUploads := False;
					Handles := False;
					ShowUploader := False;
					DLCost := 1.0;
					ULCost := 1.0;
					DLCreditor := 0.0;
					HowLong := 0;
					UploadOnly := False;
				end;
				for a := 1 to 3 do
					operators[a] := 0;
				for a := 0 to 44 do
					reserved[a] := char(0);
			end;
		end;
		oldName := forums^^[curDir].dr[which].dirName;
		theDilg := GetNewDialog(222, nil, pointer(-1));
		setPort(theDilg);
		SetGeneva(theDilg);
		SetTextBox(theDilg, 16, forums^^[curDir].dr[which].DirName);
		SelIText(theDilg, 16, 0, 32767);
		SetTextBox(theDilg, 17, stringOf(forums^^[curDir].dr[which].minDSL : 0));
		SetTextBox(theDilg, 42, stringOf(forums^^[curDir].dr[which].DSLtoDL : 0));
		SetTextBox(theDilg, 21, DoNumber(forums^^[curDir].dr[which].maxFiles));
		SetTextBox(theDilg, 19, stringOf(forums^^[curDir].dr[which].DSLtoUL : 0));
		SetTextBox(theDilg, 24, stringOf(forums^^[curDir].dr[which].minAge : 0));
		SetTextBox(theDilg, 57, stringOf(forums^^[curDir].dr[which].DLCost : 0 : 2));
		SetTextBox(theDilg, 62, stringOf(forums^^[curDir].dr[which].ULCost : 0 : 2));
		SetTextBox(theDilg, 70, stringOf(forums^^[curDir].dr[which].HowLong : 0));
		SetTextBox(theDilg, 73, stringOf(forums^^[curDir].dr[which].DLCreditor : 0 : 2));
		if FindUser(stringOf(forums^^[curDir].dr[which].Operators[1] : 0), ttuser) then
			SetTextBox(theDilg, 45, stringOf(ttuser.username, ' #', ttuser.usernum : 0));
		if FindUser(stringOf(forums^^[curDir].dr[which].Operators[2] : 0), ttuser) then
			SetTextBox(theDilg, 46, stringOf(ttuser.username, ' #', ttuser.usernum : 0));
		if FindUser(stringOf(forums^^[curDir].dr[which].Operators[3] : 0), ttuser) then
			SetTextBox(theDilg, 47, stringOf(ttuser.username, ' #', ttuser.usernum : 0));
		if forums^^[curDir].dr[which].restriction <> char(0) then
			SetTextBox(theDilg, 32, forums^^[curDir].dr[which].restriction);
		SetTextBox(theDilg, 34, stringOf(forums^^[curDir].dr[which].fileNameLength : 0));
		SetNewStat;
		SetCheckBox(theDilg, 53, forums^^[curDir].dr[which].SlowVolume);
		if forums^^[curDir].dr[which].nonMacFiles = 1 then
			SetCheckBox(theDilg, 37, true);
		if forums^^[curDir].dr[which].freeDir then
			SetCheckBox(theDilg, 38, true);
		ShowWindow(theDilg);
		DrawPath;
		GetDItem(theDilg, 1, DType, DItem, tempRect);
		InsetRect(tempRect, -4, -4);
		PenSize(3, 3);
		FrameRoundRect(tempRect, 16, 16);
		repeat
			ModalDialog(@usemodaltime, a);
			if optiondown then
			begin
				adder := 1;
				adder2 := 0.1;
			end
			else
			begin
				adder2 := 1.0;
				adder := 10;
			end;
			case a of
				37: 
				begin
					GetDItem(theDilg, 37, DType, DItem, tempRect);
					SetCtlValue(controlHandle(Ditem), (GetCtlValue(controlHandle(Ditem)) + 1) mod 2);
					if forums^^[curDir].dr[which].nonMacFiles = 1 then
						forums^^[curDir].dr[which].nonMacFiles := 0
					else
						forums^^[curDir].dr[which].nonMacFiles := 1;
				end;
				53: 
				begin
					forums^^[curDir].dr[which].SlowVolume := not forums^^[curDir].dr[which].SlowVolume;
					SetCheckBox(theDilg, 53, forums^^[curDir].dr[which].SlowVolume);
					result := FSOpen(concat(sharedPath, 'Slow Files:xxx'), 0, b);
					if result = -120 then
						result := MakeADir(concat(sharedPath, 'Slow Files'));
				end;
				38: 
				begin
					GetDItem(theDilg, 38, DType, DItem, tempRect);
					forums^^[curDir].dr[which].freeDir := not forums^^[curDir].dr[which].freeDir;
					SetCtlValue(controlHandle(Ditem), (GetCtlValue(controlHandle(Ditem)) + 1) mod 2);
				end;
				10, 11: 
				begin
					adder := 1;
					if (a = 11) then
						adder := adder * (-1);
					forums^^[curDir].dr[which].FileNameLength := UpDown(theDilg, 34, forums^^[curDir].dr[which].FileNameLength, Adder, 31, 12);
				end;
				8, 9: 
				begin
					if (a = 9) then
						adder := adder * (-1);
					forums^^[CurDir].dr[which].minAge := UpDown(theDilg, 24, forums^^[curDir].dr[which].MinAge, Adder, 99, 0);
				end;
				6, 7: 
				begin
					if (a = 7) then
						adder := adder * (-1);
					forums^^[curDir].dr[which].DSLtoUL := UpDown(theDilg, 19, forums^^[curDir].dr[which].DSLtoUL, Adder, 255, 0);
				end;
				39, 40: 
				begin
					if (a = 40) then
						adder := adder * (-1);
					forums^^[curDir].dr[which].DSLtoDL := UpDown(theDilg, 42, forums^^[curDir].dr[which].DSLtoDL, Adder, 255, 0);
				end;
				4, 5: 
				begin
					if (a = 5) then
						adder := adder * (-1);
					forums^^[curDir].dr[which].maxFiles := UpDown(theDilg, 21, forums^^[curDir].dr[which].maxFiles, Adder, 9999, 1);
				end;
				45, 46, 47: 
				begin
					ModeratorDlg := GetNewDialog(178, nil, pointer(-1));
					SetPort(ModeratorDlg);
					SetGeneva(ModeratorDlg);
					i := a - 44;
					if FindUser(stringOf(forums^^[curDir].dr[which].Operators[i] : 0), ttUser) then
						ParamText(StringOf('Current Administrator: ', ttUser.UserName, ' #', ttUser.UserNum : 0), 'Enter name or number, * wildcard allowed.', 'To remove a moderator enter a 0', '')
					else
						ParamText('Current Administrator: None', 'Enter name or number, * wildcard allowed.', 'To remove an administrator enter a 0.', '');
					DrawDialog(ModeratorDlg);
					repeat
						ModalDialog(@useModalTime, i)
					until (i = 1) or (i = 4);
					s1 := GetTextBox(ModeratorDlg, 3);
					DisposDialog(ModeratorDlg);
					SetPort(theDilg);
					if i = 1 then
					begin
						i := a - 44;
						if FindUser(s1, ttUser) and (s1 <> '0') then
						begin
							if (ttUser.usernum <> forums^^[curDir].dr[which].Operators[1]) and (ttUser.usernum <> forums^^[curDir].dr[which].Operators[2]) and (ttUser.usernum <> forums^^[curDir].dr[which].Operators[3]) then
							begin
								forums^^[curDir].dr[which].Operators[i] := ttUser.UserNum;
								SetTextBox(theDilg, a, stringOf(ttuser.username, ' #', ttuser.usernum : 0));
							end
							else
								ProblemRep('That user is already an administrator for this directory.');
						end
						else if s1 = '0' then
						begin
							forums^^[curDir].dr[which].Operators[i] := 0;
							SetTextBox(theDilg, a, ' ');
						end
						else
							ProblemRep('No Such User.');
					end;
					DrawDialog(theDilg);
				end;
				58, 59: 
				begin
					if (a = 59) then
						adder2 := adder2 * (-1);
					forums^^[curDir].dr[which].DLCost := UpDownReal(theDilg, 57, forums^^[curDir].dr[which].DLCost, Adder2, 99.9, 0.00);
				end;
				63, 64: 
				begin
					if (a = 64) then
						adder2 := adder2 * (-1);
					forums^^[curDir].dr[which].ULCost := UpDownReal(theDilg, 62, forums^^[curDir].dr[which].ULCost, Adder2, 99.9, 0.00);
				end;
				74, 75: 
				begin
					if (a = 75) then
						adder2 := adder2 * (-1);
					forums^^[curDir].dr[which].DLCreditor := UpDownReal(theDilg, 73, forums^^[curDir].dr[which].DLCreditor, Adder2, 99.9, 0.00);
				end;
				66, 67: 
				begin
					if (a = 67) then
						adder := adder * (-1);
					forums^^[curDir].dr[which].HowLong := UpDown(theDilg, 70, forums^^[curDir].dr[which].HowLong, Adder, 999, 0);
				end;
				2, 3: 
				begin
					if (a = 3) then
						adder := adder * (-1);
					forums^^[curDir].dr[which].minDSL := UpDown(theDilg, 17, forums^^[curDir].dr[which].minDSL, Adder, 255, 0);
				end;
				28, 29, 30: 
				begin
					forums^^[curDir].dr[which].mode := a - 29;
					if (a - 29) = -1 then
						forums^^[curDir].dr[which].mode := 1
					else if (a - 29) = 1 then
						forums^^[curDir].dr[which].mode := -1;
					SetNewStat;
				end;
				25: 
				begin
					globalStr := 'Select path for this directory:';
					stemp := doGetDirectory;
					if sTemp <> '' then
					begin
						forums^^[curDir].dr[which].path := sTemp;
					end;
					DrawPath;
					GetDItem(theDilg, 1, DType, DItem, tempRect);
					InsetRect(tempRect, -4, -4);
					PenSize(3, 3);
					FrameRoundRect(tempRect, 16, 16);
				end;
				otherwise
			end;
		until (a = 1);
		GetDItem(theDilg, 32, DType, DItem, tempRect);
		GetIText(DItem, t1);
		if (length(t1) > 0) and ((t1[1] >= 'A') and (t1[1] <= 'Z')) then
			forums^^[curDir].dr[which].restriction := t1[1]
		else
			forums^^[curDir].dr[which].restriction := char(0);
		GetDItem(theDilg, 16, DType, DItem, tempRect);
		GetIText(DItem, t1);
		if length(t1) > 0 then
		begin
			if (length(t1) < 30) and (oldName <> 'Mail Attachments') then
			begin
				forums^^[curDir].dr[which].dirName := t1;
				if t1 <> oldName then
				begin
					result := Rename(concat(InitSystHand^^.DataPath, forumIdx^^.name[CurDir], ':', oldname), 0, concat(InitSystHand^^.DataPath, forumIdx^^.name[CurDir], ':', t1));
					s26 := forums^^[curDir].dr[which].dirName;
					if length(oldName) > 26 then
						oldName[0] := char(26);
					result := Rename(concat(InitSystHand^^.DataPath, forumIdx^^.name[CurDir], ':', oldname, ' AHDR'), 0, concat(InitSystHand^^.DataPath, forumIdx^^.name[CurDir], ':', s26, ' AHDR'));
					result := Rename(concat(InitSystHand^^.DataPath, forumIdx^^.name[CurDir], ':', oldname, ' HDR'), 0, concat(InitSystHand^^.DataPath, forumIdx^^.name[CurDir], ':', s26, ' HDR'));
				end;
				if new then
				begin
					ForumIdx^^.numDirs[curdir] := ForumIdx^^.numDirs[curdir] + 1;
					tempString := concat(InitSystHand^^.DataPath, forumIdx^^.name[CurDir], ':', forums^^[curDir].dr[which].dirName);
					result := Create(tempString, 0, 'HRMS', 'DATA');
					CreateResFile(tempString);
					CloseResFile(OpenResFile(tempstring));

					s26 := forums^^[curDir].dr[Which].dirName;
					tempString := concat(InitSystHand^^.DataPath, forumIdx^^.name[curDir], ':', s26);
					if length(tempString) > 0 then
					begin
						result := Create(concat(tempString, ' AHDR'), 0, 'HRMS', 'TEXT');
						result := Create(concat(tempString, ' HDR'), 0, 'HRMS', 'TEXT');
					end;
				end;
			end
			else if (length(t1) > 29) then
				ProblemRep('Aborted, directory names must be less than 31 characters.')
			else if (oldName = 'Mail Attachments') and (t1 <> 'Mail Attachments') then
				ProblemRep('Directory name not changed.  File attachment directories cannot be renamed.');
		end
		else
			ProblemRep('Aborted, a directory name must have at least 1 character.');
		DisposDialog(theDilg);
	end;

	function EditDirForum (var Dir: ForumIdxRec; which: integer): boolean;
		var
			Index, i, a, b, theRow, adder: integer;
			askDilg, theDilg, temporary, ModeratorDlg: DialogPtr;
			MyD: DialogPtr;
			t1: Str255;
			Rect_I_List, theRect: Rect;
			myList: ListHandle;
			DoubleClick: Boolean;
			myPt, tempPt: Point;
			ttUser: UserRec;
	begin
		temporary := GetNewDialog(300, nil, Pointer(-1));
		ShowWindow(Temporary);
		SelectWindow(Temporary);
		SetPort(Temporary);
		SetGeneva(temporary);

		GetDItem(temporary, 1, DType, DItem, tempRect);
		InsetRect(tempRect, -4, -4);
		PenSize(3, 3);
		FrameRoundRect(tempRect, 16, 16);
		SetTextBox(temporary, 2, dir.name[which]);
		SelIText(temporary, 2, 0, 32767);
		SetTextBox(temporary, 4, stringOf(dir.MinDSL[which] : 0));
		SetTextBox(temporary, 13, stringOf(dir.age[which] : 0));
		if FindUser(stringOf(dir.ops[which, 1] : 0), ttuser) then
			SetTextBox(temporary, 21, stringOf(ttuser.username, ' #', ttuser.usernum : 0));
		if FindUser(stringOf(dir.ops[which, 2] : 0), ttuser) then
			SetTextBox(temporary, 22, stringOf(ttuser.username, ' #', ttuser.usernum : 0));
		if FindUser(stringOf(dir.ops[which, 3] : 0), ttuser) then
			SetTextBox(temporary, 23, stringOf(ttuser.username, ' #', ttuser.usernum : 0));
		if dir.restriction[which] <> char(0) then
			SetTextBox(temporary, 9, dir.Restriction[which]);
		repeat
			ModalDialog(@usemodaltime, a);
			if optiondown then
				adder := 1
			else
				adder := 10;
			case a of
				5, 6: 
				begin
					if (a = 5) then
						adder := adder * (-1);
					dir.MinDSL[which] := UpDown(temporary, 4, dir.MinDSL[which], Adder, 255, 0);
				end;
				21, 22, 23: 
				begin
					ModeratorDlg := GetNewDialog(178, nil, pointer(-1));
					SetPort(ModeratorDlg);
					SetGeneva(ModeratorDlg);
					i := a - 20;
					if FindUser(stringOf(dir.ops[which, i] : 0), ttUser) then
						ParamText(StringOf('Current Administrator: ', ttUser.UserName, ' #', ttUser.UserNum : 0), 'Enter name or number, * wildcard allowed.', 'To remove a moderator enter a 0', '')
					else
						ParamText('Current Administrator: None', 'Enter name or number, * wildcard allowed.', 'To remove an administrator enter a 0.', '');
					DrawDialog(ModeratorDlg);
					repeat
						ModalDialog(@useModalTime, i)
					until (i = 1) or (i = 4);
					t1 := GetTextBox(ModeratorDlg, 3);
					DisposDialog(ModeratorDlg);
					SetPort(temporary);
					if i = 1 then
					begin
						i := a - 20;
						if FindUser(t1, ttUser) and (t1 <> '0') then
						begin
							if (ttUser.usernum <> dir.ops[which, 1]) and (ttUser.usernum <> dir.ops[which, 2]) and (ttUser.usernum <> dir.ops[which, 3]) then
							begin
								dir.ops[which, i] := ttUser.UserNum;
								SetTextBox(temporary, a, stringOf(ttuser.username, ' #', ttuser.usernum : 0));
							end
							else
								ProblemRep('That user is already an administrator for this directory.');
						end
						else if t1 = '0' then
						begin
							dir.ops[which, i] := 0;
							SetTextBox(temporary, a, ' ');
						end
						else
							ProblemRep('No Such User.');
					end;
					DrawDialog(temporary);
				end;
				14, 15: 
				begin
					if (a = 14) then
						adder := adder * (-1);
					dir.age[which] := UpDown(temporary, 13, dir.age[which], Adder, 100, 0);
				end;
			end;
		until (a = 11) or (a = 1);
		if (a = 1) and (length(GetTextBox(Temporary, 2)) > 0) and (length(GetTextBox(Temporary, 2)) < 31) then
		begin
			dir.name[which] := GetTextBox(temporary, 2);
			t1 := GetTextBox(temporary, 9);
			if (length(t1) > 0) and ((t1[1] >= 'A') and (t1[1] <= 'Z')) then
				dir.Restriction[which] := t1[1]
			else
				dir.Restriction[which] := char(0);
			EditDirForum := True;
		end
		else if (a = 11) then
			EditDirForum := False
		else
			ProblemRep('Aborted, area names must be greater than 0 characters and less than 31 characters.');
		if (a = 11) then
			EditDirForum := False;
		DisposDialog(temporary);
	end;

	procedure DoTransferSections;
		var
			Index, i, whichone, mdm, x: integer;
			myPt, tempPt: Point;
			ExitDialog: boolean;
			DoubleClick: boolean;
			CmdDown: boolean;
			chCode: integer;
			MyCmdKey: char;
			tempDilg: dialogPtr;
			tempLong: longInt;
			theReply: SFReply;
			tempCell: cell;
			t1, s1: Str255;
			newForum: ReadDirHandle;
			s26: string[26];
	begin
		ExitDialog := FALSE;
		if (GetDSelection <> nil) then
		begin
			if (GetDSelection <> nil) and (GetDSelection = theWindow) then
			begin
				setPort(getDSelection);
				myPt := theEvent.where;
				GlobalToLocal(myPt);
				GetDItem(GetDSelection, itemHit, DType, DItem, tempRect);
				CItem := Pointer(DItem);
				if memerror <> 0 then
					ProblemRep(StringOf(memerror : 0));

				if (itemHit = 7) then
				begin
					tempCell.h := 0;
					tempCell.v := 0;
					if LGetSelect(true, tempCell, DirectoryList) then
					begin
						if (ModalQuestion('Delete This Directory?', false, true) = 1) then
						begin
							if (forums^^[curDir].dr[tempCell.v + 1].DirName = 'Mail Attachments') then
								InitSystHand^^.MailAttachments := false;
							LDelRow(1, tempCell.v, DirectoryList);
							if (tempCell.v + 1) < (forumIdx^^.numdirs[curdir]) then
							begin
								for i := (tempCell.v + 2) to (forumIdx^^.numdirs[curdir]) do
								begin
									forums^^[curDir].dr[i - 1] := forums^^[curDir].dr[i];
									forumIdx^^.lastupload[CurDir, i - 1] := forumIdx^^.lastupload[CurDir, i];
								end;
								LSetSelect(true, tempCell, DirectoryList);
							end;
							forumIdx^^.numdirs[curdir] := forumIdx^^.numdirs[curdir] - 1;
							mdm := OpenRFPerm(concat(SharedFiles, 'Directories'), 0, fsRdWrPerm);
							newForum := ReadDirHandle(GetNamedResource('Dirs', forumIdx^^.name[curDir]));
							RmveResource(handle(newForum));
							DisposeHandle(handle(newForum));
							newForum := ReadDirHandle(NewHandleClear(SizeOf(DirDataFile)));
							HLock(handle(newForum));
							newForum^^ := forums^^[CurDir];
							AddResource(handle(newForum), 'Dirs', UniqueId('Dirs'), ForumIdx^^.name[curDir]);
							WriteResource(handle(newForum));
							DetachResource(handle(newForum));
							HUnlock(handle(newForum));
							DisposHandle(handle(newForum));
							CloseResFile(mdm);
						end;
					end
					else
						SysBeep(10);
				end;

				if (itemHit = 4) then
				begin
					DoubleClick := LClick(myPt, theEvent.modifiers, ForumList);
					if doubleClick then
					begin
						tempCell.h := 0;
						tempCell.v := 0;
						if LGetSelect(true, tempCell, ForumList) then
						begin
							t1 := forumidx^^.name[tempCell.v];
							if EditDirForum(forumidx^^, tempCell.v) then
							begin
								s26 := t1;
								s1 := t1;
								s26 := forumIdx^^.name[tempCell.v];
								result := Rename(concat(InitSystHand^^.DataPath, t1, ':', s1, ' AHDR'), 0, concat(InitSysthand^^.DataPath, t1, ':', s26, ' AHDR'));
								result := Rename(concat(InitSystHand^^.DataPath, t1, ':', s1, ' HDR'), 0, concat(InitSysthand^^.DataPath, t1, ':', s26, ' HDR'));

								result := Rename(concat(InitSystHand^^.DataPath, t1, ':'), 0, concat(InitSystHand^^.DataPath, ForumIdx^^.name[tempCell.v], ':'));
								mdm := OpenRFPerm(concat(SharedFiles, 'Directories'), 0, fsRdWrPerm);
								newForum := ReadDirHandle(GetNamedResource('Dirs', t1));
								RmveResource(handle(newForum));
								DisposeHandle(handle(newForum));
								newForum := ReadDirHandle(NewHandleClear(SizeOf(DirDataFile)));
								HLock(handle(newForum));
								newForum^^ := forums^^[tempCell.v];
								AddResource(handle(newForum), 'Dirs', UniqueId('Dirs'), ForumIdx^^.name[tempCell.v]);
								WriteResource(handle(newForum));
								DetachResource(handle(newForum));
								HUnlock(handle(newForum));
								DisposHandle(handle(newForum));
								SetPort(GetDSelection);
								LDoDraw(false, ForumList);
								LDelRow(0, 0, ForumList);
								if forumIdx^^.numforums > 0 then
									for i := 1 to forumIdx^^.NumForums do
										AddListString(ForumIdx^^.Name[i - 1], ForumList);
								LSetSelect(true, tempCell, ForumList);
								LDoDraw(true, ForumList);
								GetDItem(GetDSelection, 4, DType, DItem, tempRect);
								tempRect.Right := tempRect.Right - 15;
								InsetRect(tempRect, -1, -1);
								EraseRect(tempRect);
								FrameRect(tempRect);
								LUpdate(ForumList^^.port^.visRgn, ForumList);
								CloseResFile(mdm);
							end;
						end;
					end
					else
					begin
						tempCell.h := 0;
						tempCell.v := 0;
						if LGetSelect(True, tempCell, ForumList) then
							curDir := tempCell.v;
						LDoDraw(false, DirectoryList);
						LDelRow(0, 0, DirectoryList);
						if ForumIdx^^.numDirs[curDir] > 0 then
						begin
							for i := 1 to ForumIdx^^.numDirs[CurDir] do
							begin
								AddListString(forums^^[curDir].dr[i].dirName, DirectoryList);
							end;
						end;
						LdoDraw(TRUE, DirectoryList);
						GetDItem(GetDSelection, 8, DType, DItem, tempRect);
						tempRect.Right := tempRect.Right - 15;
						InsetRect(tempRect, -1, -1);
						EraseRect(tempRect);
						FrameRect(tempRect);
						LUpdate(DirectoryList^^.port^.visRgn, DirectoryList);
					end;
				end;

				if (ItemHit = 1) then
				begin
					ExitDialog := TRUE;
				end;

				if (itemHit = 8) then
				begin
					DoubleClick := LClick(myPt, theEvent.modifiers, DirectoryList);
					if doubleClick then
					begin
						tempCell.h := 0;
						tempCell.v := 0;
						if LGetSelect(true, tempCell, DirectoryList) then
						begin
							EditTransferSec(false, tempCell.v + 1);
							begin
								mdm := OpenRFPerm(concat(SharedFiles, 'Directories'), 0, fsRdWrPerm);
								newForum := ReadDirHandle(GetNamedResource('Dirs', forumIdx^^.name[curDir]));
								RmveResource(handle(newForum));
								DisposeHandle(handle(newForum));
								newForum := ReadDirHandle(NewHandleClear(SizeOf(DirDataFile)));
								HLock(handle(newForum));
								newForum^^ := forums^^[CurDir];
								AddResource(handle(newForum), 'Dirs', UniqueId('Dirs'), ForumIdx^^.name[curDir]);
								WriteResource(handle(newForum));
								DetachResource(handle(newForum));
								HUnlock(handle(newForum));
								DisposHandle(handle(newForum));
								SetPort(GetDSelection);
								LDoDraw(false, DirectoryList);
								LDelRow(0, 0, DirectoryList);
								if ForumIdx^^.numDirs[curDir] > 0 then
								begin
									for i := 1 to ForumIdx^^.numDirs[CurDir] do
									begin
										AddListString(forums^^[curDir].dr[i].dirName, DirectoryList);
									end;
								end;
								LSetSelect(true, tempCell, DirectoryList);
								LDoDraw(true, DirectoryList);
								LUpdate(ForumList^^.port^.visRgn, DirectoryList);
								CloseResFile(mdm);
							end;
						end;
					end;
				end;

				if (itemHit = 6) then
				begin
					if ForumIdx^^.numDirs[CurDir] < 64 then
					begin
						EditTransferSec(true, ForumIdx^^.numDirs[CurDir] + 1);
						mdm := OpenRFPerm(concat(SharedFiles, 'Directories'), 0, fsRdWrPerm);
						newForum := ReadDirHandle(GetNamedResource('Dirs', forumIdx^^.name[curDir]));
						RmveResource(handle(newForum));
						DisposeHandle(handle(newForum));
						newForum := ReadDirHandle(NewHandleClear(SizeOf(DirDataFile)));
						HLock(handle(newForum));
						newForum^^ := forums^^[CurDir];
						AddResource(handle(newForum), 'Dirs', UniqueId('Dirs'), ForumIdx^^.name[curDir]);
						WriteResource(handle(newForum));
						DetachResource(handle(newForum));
						HUnlock(handle(newForum));
						DisposHandle(handle(newForum));
						CloseResFile(mdm);
						LDoDraw(false, DirectoryList);
						LDelRow(0, 0, DirectoryList);
						for i := 1 to ForumIdx^^.numDirs[CurDir] do
						begin
							AddListString(forums^^[curDir].dr[i].dirName, DirectoryList);
						end;
						LdoDraw(TRUE, DirectoryList);
					end;
				end;

				if (ItemHit = 2) then
				begin
					if forumIdx^^.numforums < 64 then
					begin
						newForum := ReadDirHandle(NewHandleClear(SizeOf(DirDataFile)));
						HLock(handle(newForum));
						ForumIdx^^.name[forumIdx^^.numforums] := stringOf('Area #', forumIdx^^.numforums : 0);
						ForumIdx^^.minDSL[forumIdx^^.numforums] := 0;
						ForumIdx^^.restriction[forumIdx^^.numforums] := char(0);
						forumIdx^^.numDirs[forumIdx^^.numforums] := 0;
						forumIdx^^.age[forumIdx^^.numforums] := 0;
						for i := 1 to 3 do
							forumIdx^^.ops[forumIdx^^.numforums, i] := 0;
						if EditDirForum(ForumIdx^^, forumIdx^^.numForums) then
						begin
							mdm := OpenRFPerm(concat(SharedFiles, 'Directories'), 0, fsRdWrPerm);
							AddResource(handle(newForum), 'Dirs', UniqueId('Dirs'), ForumIdx^^.name[forumIdx^^.numforums]);
							WriteResource(handle(newForum));
							DetachResource(handle(newForum));
							AddListString(forumIdx^^.name[forumIdx^^.numforums], ForumList);
							SetHandleSize(handle(forums), GetHandleSize(handle(forums)) + sizeOf(DirDataFile));
							result := MakeADir(concat(InitSystHand^^.DataPath, forumIdx^^.name[forumIdx^^.numForums]));
							s26 := forumIdx^^.name[forumIdx^^.numForums];
							s1 := concat(InitSystHand^^.DataPath, forumIdx^^.name[forumIdx^^.numForums], ':', s26);
							if length(s1) > 0 then
							begin
								result := Create(concat(s1, ' AHDR'), 0, 'HRMS', 'TEXT');
								result := Create(concat(s1, ' HDR'), 0, 'HRMS', 'TEXT');
							end;
							forumIdx^^.numforums := forumIdx^^.numforums + 1;
							DoForumRec(true);
							CloseResFile(mdm);
						end;
						HUnlock(handle(newForum));
						DisposHandle(handle(newForum));
					end
					else
						SysBeep(10);
				end;

				if (ItemHit = 3) then
				begin
					tempCell.h := 0;
					tempCell.v := 0;
					if LGetSelect(true, tempCell, ForumList) then
					begin
						if (ModalQuestion('Delete This Area?', false, true) = 1) then
						begin
							mdm := OpenRFPerm(concat(SharedFiles, 'Directories'), 0, fsRdWrPerm);
							newForum := ReadDirHandle(GetNamedResource('Dirs', forumIdx^^.name[tempCell.v]));
							RmveResource(handle(newForum));
							LDelRow(1, tempCell.v, ForumList);
							if forumIdx^^.numforums > tempCell.v + 1 then
								for i := tempCell.v + 1 to forumIdx^^.numforums do
								begin
									forumIdx^^.name[i - 1] := forumIdx^^.name[i];
									forumIdx^^.MinDsl[i - 1] := forumIdx^^.MinDsl[i];
									forumIdx^^.Restriction[i - 1] := forumIdx^^.Restriction[i];
									forumIdx^^.numDirs[i - 1] := forumIdx^^.numDirs[i];
									forumIdx^^.age[i - 1] := forumIdx^^.age[i];
									for x := 1 to 64 do
										forumIdx^^.lastupload[i - 1, x] := forumIdx^^.lastupload[i, x];
									forums^^[i - 1] := forums^^[i];
								end;
							forumIdx^^.numforums := forumIdx^^.numforums - 1;
							SetHandleSize(handle(forums), GetHandleSize(handle(forums)) - sizeOf(DirDataFile));
							if memerror <> 0 then
								ProblemRep(stringOf('Memory Error: ', Memerror : 0));
							CloseResFile(mdm);
						end;
					end;
				end;
			end;
		end;

		if ExitDialog then
		begin
			CloseTransferSections(GetDSelection);
			GetDSelection := nil;
		end;
	end;

	procedure SwitchError (er: str255);
		var
			tempDilg: dialogPtr;
			a: integer;
	begin
		with curglobs^ do
		begin
			if BoardMode = terminal then
			begin
				tempDilg := GetNewDialog(1055, nil, pointer(-1));
				ParamText(er, '', '', '');
				DrawDialog(tempDilg);
				SysBeep(10);
				repeat
					ModalDialog(nil, a);
				until (a = 1);
				DisposDialog(tempDilg);
			end
			else
			begin
				OutLine(er, true, 6);
			end;
		end;
	end;

	procedure RemoveIt;
		var
			i: integer;
			mycurDirPos: integer;
	begin
		with curglobs^ do
		begin
			if curDirPos < curnumFiles then
			begin
				for i := 0 to ((curNumFiles - curDirPos) - 1) do
				begin
					curOpenDir^^[curDirPos + (i - 1)] := curOpenDir^^[curDirPos + i];
				end;
			end;
			curNumFiles := curNumFiles - 1;
			curDirPos := curDirPos - 1;
			if curDirPos > curNumFiles then
				curDirPos := curNumFiles;
			SaveDirectory;
		end;
	end;

	procedure RemoveFiles;
		var
			tempString: str255;
			result: OSerr;
			myUser: UserRec;
	begin
		with curglobs^ do
		begin
			case RFdo of
				RFone: 
				begin
					descsearch := false;
					bCR;
					LettersPrompt(RetInStr(436), '', forums^^[inRealDir].dr[InRealSubDir].fileNameLength, false, false, false, char(0));{Enter filename to remove: }
					ANSIPrompter(forums^^[InRealDir].dr[InRealSubDir].fileNameLength);
					RFdo := RFtwo;
				end;
				RFTwo: 
				begin
					if length(curPrompt) > 0 then
					begin
						curDirPos := 0;
						if OpenDirectory(InRealDir, InRealSubDir) then
						begin
							RFDo := RFThree;
							tempInDir := InRealDir;
							tempSubDir := InRealSubDir;
							fileMask := curPrompt;
						end
						else
						begin
							OutLine(RetInStr(59), true, 0);
							GoHome;
						end;
					end
					else
						GoHome;
				end;
				RFThree: 
				begin
					GetNextFile(tempInDir, tempSubDir, fileMask, curDirPos, curFil, 0);
					if curFil.flName <> '' then
					begin
						if (thisUser.coSysop) or DirOp(tempInDir, tempSubDir, thisUser) or AreaOp(tempInDir, thisUser) or (EqualString(myUsers^^[curFil.uploaderNum - 1].UName, thisUser.userName, false, false)) then
						begin
							if PrintFileInfo(curFil, tempInDir, tempSubDir, false) = 0 then
								;
							RFDo := RFFour;
						end;
					end
					else
						GoHome;
				end;
				RFFour: 
				begin
					bCR;
					bCR;
					LettersPrompt(RetInStr(437), 'YNQ', 1, true, false, true, char(0));	{Remove (Y/N/Q) : }
					RFDo := RFFive;
				end;
				RFFive: 
				begin
					if curPrompt = 'Y' then
					begin
						RemoveIt;
						deleteExtDesc(curFil, InRealDir, InRealSubDir);
						sysopLog(concat('      -', curFil.flName, ' Removed off of ', forums^^[InRealDir].dr[InRealSubDir].dirName), 0);
						if (thisUser.coSysop) or DirOp(InRealDir, InRealSubDir, thisUser) or AreaOp(InRealDir, thisUser) then
							RFDo := RFSix
						else
						begin
							if curFil.fileStat <> 'F' then
							begin
								thisUser.uploadedK := thisUser.uploadedK - (curFil.byteLen div 1024);
								if thisUser.UploadedK < 0 then
									thisUser.UploadedK := 0;
							end;
							if (pos(':', curFil.realFName) = 0) then
								tempString := concat(forums^^[InRealDir].dr[InRealSubDir].path, curFil.realFName)
							else
								tempString := curFil.realFName;
							result := FSDelete(tempString, 0);
							OutLine(RetInStr(438), true, 0);	{File removed.}
							bCR;
							RFDo := RFThree;
						end;
					end
					else if curprompt = 'N' then
						RFdo := RFThree
					else
						GoHome;
				end;
				RFSix: 
				begin
					YesNoQuestion(RetInStr(439), false);	{Delete file too? }
					RFDo := RFSeven;
				end;
				RFSeven: 
				begin
					if curPrompt = 'Y' then
					begin
						if (pos(':', curFil.realFName) = 0) then
							tempString := concat(forums^^[InRealDir].dr[InRealSubDir].path, curFil.realFName)
						else
							tempString := curFil.realFName;
						result := FSDelete(tempString, 0);
						YesNoQuestion(RetInStr(440), false);	{Remove UL points? }
						RFDo := RFEight;
					end
					else
						RfDo := RFThree;
				end;
				RFEight: 
				begin
					if curprompt = 'Y' then
					begin
						if FindUser(myUsers^^[curFil.uploaderNum - 1].UName, myUser) then
						begin
							MyUser.numUploaded := myUser.numUploaded - 1;
							MyUser.UploadedK := myUser.uploadedK - (curFil.byteLen div 1024);
							if MyUser.UploadedK < 0 then
								MyUser.UploadedK := 0;
							if myUser.UserNum = thisUser.userNum then
							begin
								thisUser.numUploaded := thisUser.numUploaded - 1;
								thisUser.UploadedK := thisUser.uploadedK - (curFil.byteLen div 1024);
								if thisUser.UploadedK < 0 then
									thisUser.UploadedK := 0;
							end;
							WriteUser(myUser);
						end;
					end;
					RFDo := RFTHree;
				end;
				otherwise
			end;
		end;
	end;

	procedure EnterExtended;
		var
			ts, s1: str255;
			tuba: longint;
			myref: integer;
			TEMPSTRING: STR255;
	begin
		with curglobs^ do
		begin
			case extenDo of
				ex1: 
				begin
					if curprompt = 'Y' then
					begin
						OutLine(stringOf(RetInStr(650), 80 - forums^^[tempInDir].dr[tempSubDir].fileNameLength : 0, RetInStr(651)), true, 0);{Enter up to 10 lines, }
{ chars each.}
						OutLine(RetInStr(652), true, 0);{Type blank line to end.}
						bCR;
						excess := '';
						if curWriting <> nil then
							DisposHandle(handle(curWriting));
						curWriting := nil;
						curPrompt := '';
						crossInt := 0;
						extenDo := ex2;
					end
					else
						GoHome;
				end;
				ex2: 
				begin
					if (length(curPrompt) > 0) or (crossint = 0) then
					begin
						if crossInt > 0 then
						begin
							if curWriting = nil then
								curWriting := TextHand(NewHandle(0));
							SetHandleSize(handle(curWriting), GetHandleSize(handle(curWriting)) + length(curPrompt) + 1);
							BlockMove(@curPrompt[1], @curWriting^^[GetHandleSize(handle(curWriting)) - length(curPrompt) - 1], length(curPrompt));
							CurWriting^^[getHandleSize(handle(curWriting)) - 1] := char(13);
						end;
						crossInt := crossInt + 1;
						NumToString(crossInt, ts);
						if crossint = 10 then
						begin
							ts := '10';
						end;
						if crossInt = 10 then
						begin
							LettersPrompt(stringOf(crossInt : 2, ': '), '', 80 - forums^^[tempInDir].dr[tempSubDir].fileNameLength, false, false, false, char(0));
							ExtenDo := ex3;
						end
						else
							LettersPrompt(stringOf(crossInt : 2, ': '), '', 80 - forums^^[tempInDir].dr[tempSubDir].fileNameLength, false, true, false, char(0));
						if length(excess) > 0 then
						begin
							OutLine(excess, false, myPrompt.inputColor);
							curPrompt := excess;
							excess := '';
						end;
					end
					else
						extendo := ex3;
				end;
				ex3: 
				begin
					if curWriting <> nil then
					begin
						if length(curprompt) > 0 then
						begin
							SetHandleSize(handle(curWriting), GetHandleSize(handle(curWriting)) + length(curPrompt) + 1);
							BlockMove(@curPrompt[1], @curWriting^^[GetHandleSize(handle(curWriting)) - length(curPrompt) - 1], length(curPrompt));
							CurWriting^^[getHandleSize(handle(curWriting))] := char(13);
						end;
						LettersPrompt(RetInStr(45), 'YNQ', 1, true, false, true, char(0));
						ExtenDo := Ex4;
					end
					else
					begin
						if renDo = reneight then
						begin
							BoardSection := renFiles;
							curPrompt := 'N';
						end
						else
							GOHOME;
					end;
				end;
				Ex4: 
				begin
					if curPrompt = 'Y' then
					begin
						AddExtended(curFil, tempinDir, tempSubDir);
						curFil.hasExtended := true;
						if renDo = reneight then
						begin
							BoardSection := renFiles;
							curPrompt := 'N';
						end
						else
							GOHOME;
					end
					else if curPrompt = 'N' then
					begin
						curprompt := 'Y';
						ExtenDo := Ex1;
					end
					else
					begin
						if renDo = reneight then
						begin
							BoardSection := renFiles;
							curPrompt := 'N';
						end
						else
							GOHOME;
					end;
				end;
				otherwise
			end;
		end;
	end;

	procedure doMove;
		var
			tem, tem2: longint;
			tempString, t2, t3: str255;
			tempInt, TI2: integer;
			result: oserr;
	begin
		with curglobs^ do
		begin
			case MoveDo of
				MoveOne: 
				begin
					descSearch := false;
					bCR;
					LettersPrompt(RetInStr(447), '', forums^^[inRealDir].dr[InRealSubDir].fileNameLength, false, false, false, char(0));{Filename to move: }
					ANSIPrompter(forums^^[inRealDir].dr[InRealSubDir].fileNameLength);
					MoveDo := MoveTwo;
				end;
				MoveTwo: 
				begin
					if length(curPrompt) > 0 then
					begin
						curDirPos := 0;
						if OpenDirectory(inRealDir, InRealSubDir) then
						begin
							MoveDo := MoveThree;
							tempInDir := inRealDir;
							tempSubDir := InRealSubDir;
							fileMask := curPrompt;
						end
						else
						begin
							OutLine(RetInStr(59), true, 0);
							GoHome;
						end;
					end
					else
						GoHome;
				end;
				MoveThree: 
				begin
					GetNextFile(tempInDir, tempSubDir, fileMask, curDirPos, curFil, 0);
					if curFil.flName <> '' then
					begin
						if PrintFileInfo(curFil, tempInDir, tempSubDir, false) = 0 then
							;
						MoveDo := MoveFour;
					end
					else
						GoHome;
				end;
				MoveFour: 
				begin
					bCR;
					bCR;
					LettersPrompt(RetInStr(448), 'YNQ', 1, true, false, true, char(0));{Move this (Y/N/Q)? }
					MoveDo := MoveFive;
				end;
				MoveFive: 
				begin
					if curPrompt = 'Y' then
					begin
						bcr;
						NumbersPrompt('To Which Area? ', '?', ForumIdx^^.numForums, 0);	{To which directory? }
						MoveDo := MoveSix;
					end
					else if (curPrompt = 'Q') then
						goHome
					else
						MoveDo := MoveThree;
				end;
				MoveSix: 
					if curprompt = '?' then
					begin
						PrintDirList(False);
						CurPrompt := 'Y';
						MoveDo := MoveFive;
					end
					else
					begin
						StringToNum(curprompt, tem);
						crossint := tem;
						OutLine('Area Moving To ', true, 0);
						OutLine(concat(ForumIdx^^.name[crossint], '.'), false, 6);
						MoveDo := MoveSeven;
						bcr;
						bcr;
						NumbersPrompt(RetInStr(449), '?', ForumIdx^^.numDirs[crossint], 1);	{To which directory? }
					end;
				MoveSeven: 
				begin
					if curPrompt = '?' then
					begin
						PrintSubDirList(crossint);
						NumToString(crossint, curPrompt);
						MoveDo := MoveSix;
					end
					else
					begin
						StringToNum(curPrompt, tem2);
						if (tem2 > 0) and (forums^^[crossint].dr[tem2].DSLtoUL <= thisuser.DSL) and (ForumIdx^^.numDirs[crossint] >= tem2) and (crossint < ForumIdx^^.NumForums) then
						begin
							t2 := forums^^[tempInDir].dr[tempSubDir].path;
							tempString := forums^^[crossint].dr[tem2].path;
							if (FreeK(tempString) > (curFil.byteLen div 1024)) then
							begin
								ti2 := curdirpos;
								tempint := pos(':', curFil.realFName);
								if (tempint = 0) then
									t2 := concat(t2, curFil.realFName)
								else
								begin
									t2 := curFil.realFName; {does not delete path, bug}
								end;
								result := copy1File(t2, concat(tempString, curFil.realFname));
								if (result = noErr) then
									result := FSDelete(t2, 0);
								RemoveIt;
								ReadExtended(curFil, tempInDir, tempSubDir);
								DeleteExtDesc(curFil, tempInDir, tempSubDir);
								AddExtended(curFil, crossint, tem2);
								FileEntry(curFil, crossint, tem2, tempInt, 0);
								if OpenDirectory(tempIndir, tempSubDir) then
									;
								if (ForumIdx^^.lastUpload[crossint, tem2] < curFil.whenUl) or (ForumIdx^^.lastUpload[crossint, tem2] = 0) then
								begin
									ForumIdx^^.lastUpload[crossint, tem2] := curFil.whenUl;
									DoForumRec(true);
								end;
								curDirPos := ti2 - 1;
								OutLine(RetInStr(450), true, 1);	{File moved.}
								bCR;
								MoveDo := MoveThree;
							end
							else
							begin
								OutLine(RetInStr(64), true, 6);
								GoHome;
							end;
						end
						else
						begin
							OutLine(RetInStr(451), true, 5);{You cannot move to that directory.}
							GoHome;
						end;
					end;
				end;
				otherwise
			end;
		end;
	end;
end.