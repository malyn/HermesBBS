{ Segments: InpOut2_1 }
unit inpOut2;

interface
	uses
		AppleTalk, ADSP, Serial, Sound, aliases, Initial, LoadAndSave, NodePrefs2, NodePrefs, SystemPrefs, Terminal, inpOut3;

	procedure SysopFileConfigure;
	procedure DoUpdate (window: WindowPtr);
	procedure SysCloseDirectory;
	function SysOpenDirectory (whichDir, whichSub: integer): boolean;
	procedure SysSaveDirectory;

implementation

	var
		enhanced: boolean; {22 = regular, 23 = stats}

{$S InpOut2_1}
	procedure SysCloseDirectory;
	begin
		if SysopOpenDir <> nil then
		begin
			HPurge(handle(SysopOpenDir));
			DisposHandle(handle(SysopOpenDir));
		end;
		SysopOpenDir := nil;
	end;

	function SysOpenDirectory (whichDir, whichSub: integer): boolean;
		var
			result: OSerr;
			DirRef: integer;
			tempLong: LongInt;
			myHParmer: HParamBlockRec;
			myParmer: ParamBlockRec;
			tempString, s1: str255;
			s26: string[26];
	begin
		SysOpenDirectory := false;
		SysCloseDirectory;
		SysopNumFiles := 0;
		if ForumIdx^^.numDirs[whichDir] >= (whichSub) then
		begin
			tempString := concat(InitSystHand^^.DataPath, forumIdx^^.name[whichDir], ':', forums^^[whichDir].dr[whichSub].dirName);
			myHParmer.ioCompletion := nil;
			myHParmer.ioNamePtr := @TEMPSTRING;
			myHParmer.ioVRefNum := 0;
			myHParmer.ioPermssn := fsRdPerm;
			myHParmer.ioMisc := nil;
			myHParmer.ioDirID := 0;
			result := PBHOpen(@myHParmer, false);
			if result <> noErr then
			begin
				s26 := forums^^[whichDir].dr[whichSub].dirName;
				s1 := concat(InitSystHand^^.DataPath, forumIdx^^.name[whichDir], ':', s26);
				if length(s1) > 0 then
				begin
					result := Create(concat(s1, ' AHDR'), 0, 'HRMS', 'TEXT');
					result := Create(concat(s1, ' HDR'), 0, 'HRMS', 'TEXT');
				end;
				result := Create(tempString, 0, 'HRMS', 'DATA');
				CreateResFile(tempString);
				result := PBHOpen(@myHParmer, false);
			end;
			if result = noErr then
			begin
				dirRef := myHParmer.ioRefNum;
				result := SetFPos(DirRef, fsFromStart, 0);
				result := GetEOF(DirRef, tempLong);
				sysopOpenDir := aDirHand(NewHandle(tempLong));
				if MemError = noErr then
				begin
					MoveHHi(handle(sysopOpenDir));
					HNoPurge(handle(sysopOpenDir));
					result := FSRead(dirRef, tempLong, pointer(sysopOpenDir^));
					SysOpenDirectory := true;
					SysopDirNum := whichDir;
					SysOpSubNum := whichSub;
					SysopnumFiles := tempLong div SizeOf(filEntryRec);
				end
				else
					sysopOpenDir := nil;
				myParmer.ioCompletion := nil;
				myParmer.ioRefNum := dirRef;
				result := PBClose(@myParmer, false);
			end;
		end;
	end;

	procedure SysopAddExtended (theFil: filEntryRec; whichDir, whichSub: integer; curWriting: charsHandle);
		var
			s1, tempstring: str255;
			myRef, tempint: integer;
			tuba: longint;
			tempers: filentryrec;
			s26: string[26];
	begin
		tempString := concat(InitSystHand^^.DataPath, forumIdx^^.name[whichDir], ':', forums^^[whichDir].dr[whichSub].dirName);
		tempInt := OpenRFPerm(tempString, 0, fsRdWrPerm);
		if tempint = -1 then
		begin
			if not fexist(tempString) then
			begin
				result := MakeADir(Concat(InitSystHand^^.DataPath, ForumIdx^^.name[whichDir]));
				result := Create(tempString, 0, 'HRMS', 'DATA');
				s26 := forums^^[whichDir].dr[whichSub].dirName;
				s1 := concat(InitSystHand^^.DataPath, forumIdx^^.name[whichDir], ':', s26);
				if (length(s1) > 0) then
				begin
					result := Create(concat(s1, ' AHDR'), 0, 'HRMS', 'TEXT');
					result := Create(concat(s1, ' HDR'), 0, 'HRMS', 'TEXT');
				end;

			end;
			CreateResFile(tempString);
			CloseResFile(OpenResFile(tempstring));
			tempInt := OpenRFPerm(tempString, 0, fsRdWrPerm);
		end;
		if tempint <> -1 then
		begin
			UseResFile(TempInt);
			AddResource(handle(curWriting), 'DESC', Unique1Id('DESC'), theFil.flName);
			WriteResource(handle(curWriting));
			DetachResource(handle(curWriting));
			CloseResFile(tempInt);
			UseResFile(myResourceFile);
		end
		else
			ProblemRep(StringOf(RetInStr(508))); {Could Not Save Extended Description!}
	end;

	procedure SysSaveDirectory;
		var
			DirFileName, s1: str255;
			theDirref: integer;
			tempLong: longint;
			s26: string[26];
	begin
		dirFileName := concat(InitSystHand^^.DataPath, forumIdx^^.name[sysopDirNum], ':', forums^^[sysopDirNum].dr[SysOpSubNum].dirName);
		result := FSOpen(dirFileName, 0, theDirRef);
		if result <> noErr then
		begin
			result := MakeADir(concat(InitSystHand^^.DataPath, forumIDx^^.name[sysopDirNum]));
			result := Create(dirFileName, 0, 'HRMS', 'DATA');
			s26 := forums^^[sysopDirNum].dr[SysOpSubNum].dirName;
			s1 := concat(InitSystHand^^.DataPath, forumIdx^^.name[sysopDirNum], ':', s26);
			if length(s1) > 0 then
			begin
				result := Create(concat(s1, ' AHDR'), 0, 'HRMS', 'TEXT');
				result := Create(concat(s1, ' HDR'), 0, 'HRMS', 'TEXT');
			end;
			result := FSOpen(dirFileName, 0, theDirRef);
		end
		else
			result := SetEOF(theDirRef, 0);
		if (result = noErr) then
		begin
			tempLong := SizeOf(filEntryRec) * longint(sysopNumFiles);
			HLock(handle(sysopOpenDir));
			result := FSWrite(theDirRef, tempLong, pointer(sysopOpenDir^));
			HUnlock(handle(sysopOpenDir));
			result := FSClose(theDirRef);
		end;
	end;

	function SysopFileFilter (p: ParmBlkPtr): BOOLEAN;
		var
			gotOne: boolean;
			place: longint;
			theV, i: integer;
			hhh: HparamBlockRec;
			Tetatet: CInfoPBRec;
			t2, t3, t4, t5: str255;
	begin
		SysopFileFilter := false;
		if maskFiles then
		begin
			t3 := p^.ioNamePtr^;
			gotOne := false;
			place := 0;
			t2 := forums^^[sysopDirNum].dr[sysopSubNum].path;
			with hhh do
			begin
				iocompletion := nil;
				ioNamePtr := @t2;
				ioVolIndex := -1;
				ioVRefNum := 0;
			end;
			result := PBHGetVInfo(@hhh, false);
			t2 := forums^^[sysopDirNum].dr[sysopSubNum].path;
			with tetatet do
			begin
				iocompletion := nil;
				ioNamePtr := @t2;
				iovRefNum := HHH.ioVRefNum;
				ioFDirIndex := 0;
			end;
			result := PBGetCatInfo(@tetatet, false);
			if (tetatet.ioDrDirID = curDirStore^) and (hhh.ioVRefNum = (-SFSaveDisk^)) then
			begin
				if sysopNumFiles > 0 then
				begin
					repeat
						if EqualString(sysopOpenDir^^[place].flName, t3, false, false) then
							gotOne := true;
						place := place + 1;
					until GotOne or (place > sysopNumFiles);
				end;
				if gotOne then
					SysopFileFilter := true;
			end;
		end;
	end;

	procedure DrawXFerList (theWindow: WindowPtr; item: integer);
		var
			kind: integer;
			h: handle;
			r: rect;
	begin
		if (item = 11) then
		begin
			SetPort(theWindow);
			GetDItem(theWindow, 11, kind, h, r);
			FrameRect(r);
			LUpdate(theWindow^.visRgn, XFerList);
			if SFXferTE <> nil then
			begin
				EraseRect(SFXFerTE^^.viewRect);
				TEUpdate(SFXFerTE^^.viewRect, SFXferTE);
			end;
			DrawClippedGrow(theWindow);
		end;
	end;

	function GenFileNote (which: integer): str255;
		var
			b, tempint: integer;
			s2, s3, s4, t1, t2, t3, t4, t5, t6: str255;
	begin
		s3 := sysopOpenDir^^[which].flName;
		if length(S3) < forums^^[SysOpDirNum].dr[SysOpSubNum].fileNameLength then
			for b := length(s3) to (forums^^[SysOpDirNum].dr[SysOpSubNum].fileNameLength - 1) do
				s3 := concat(s3, ' ');
		if length(S3) > forums^^[SysOpDirNum].dr[SysOpSubNum].fileNameLength then
		begin
			s3[forums^^[SysOpDirNum].dr[SysOpSubNum].fileNameLength] := '*';
			s3[0] := char(forums^^[SysOpDirNum].dr[SysOpSubNum].fileNameLength);
		end;
		if sysopOpenDir^^[which].fileStat <> 'F' then
		begin
			tempInt := sysopOpenDir^^[which].byteLen div 1024;
			if (tempInt < 1) and (sysopOpenDir^^[which].byteLen <> 0) then
				s2 := StringOf(tempInt : 0, 'k')
			else if (sysopOpenDir^^[which].byteLen = -1) then
				s2 := 'ASK'
			else
				s2 := StringOf(tempInt : 0, 'k');
			if length(s2) < 7 then
				for b := length(s2) to 7 do
					s2 := concat(' ', s2);
			if sysopOpenDir^^[which].hasExtended then
				s2[1] := char(249);
			if (pos(':', sysopOpenDir^^[which].realFName) = 0) then
				s4 := concat(forums^^[SysOpDirNum].dr[SysOpSubNum].path, sysopOpenDir^^[which].realFName)
			else
				s4 := sysopOpenDir^^[which].realFName;
			if FExist(s4) then
				s2[2] := char(249);
		end
		else
		begin
			s2 := 'UL FRAG';
		end;
		with SysOpOpenDir^^[which] do
		begin
			t1 := getdate(whenUl);
			t2 := getdate(lastDL);{myUsers^^[curMesgRec.fromuserNum - 1].real}
			t3 := stringOf('#', UploaderNum : 0);
			if lastdl = 0 then
				t2 := '00/00/00';
			if length(filetype) < 4 then
				t5 := stringOf(filetype, ' ' : 4 - length(filetype))
			else
				t5 := filetype;
			if length(filecreator) < 4 then
				t6 := stringOf(filecreator, ' ' : 4 - length(filecreator))
			else
				t6 := filecreator;
			genFileNote := concat(s3, ':', s2, ':', sysopOpenDir^^[which].flDesc);
			if enhanced then
				genFileNote := stringOf('•', s3, ':', s2, ':', numDLoads : 4, ':', ' ' : 5 - length(t3), t3, ':', t1, ':', t2, ':', t5, '/', t6);
		end;
	end;

	procedure FillXFerList;
		label
			100;
		var
			i, b: integer;
			tempInt: longint;
			s2, s3, endUp: str255;
			cSize: cell;
	begin
		LDelRow(0, 0, XFERList);
		LDoDraw(false, XFerList);
		if sysopNumFiles > 0 then
		begin
			cSize.v := LAddRow(sysopNumFiles, 5000, XFerList);
			for i := 1 to sysopNumFiles do
			begin
				endUp := GenFileNote(i - 1);
				cSize.h := 0;
				cSize.v := i - 1;
				LSetCell(Pointer(ord(@endUp) + 1), length(endUp), cSize, XFerList);
				if GetHandleSize(handle(XFerList^^.cells)) > 32000 then
				begin
					ProblemRep('Displayable list size is limited to 32K.  List will be truncated.');
					LDelRow(sysopNumFiles - i, i, XFerList);
					goto 100;
				end;
			end;
100:
		end;
		LDoDraw(true, XFerList);
	end;

	procedure ClearRename (dptr: dialogPtr);
		var
			kind: integer;
			h: handle;
			r: rect;
			tempChars: charsHandle;
			load, t2: str255;
			tempCell: cell;
			tempo: longint;
	begin
		if (BeingRenamed > -1) and (SFXFerTE <> nil) then
		begin
			tempChars := TEGetText(SFXferTE);
			load := '';
			if SFXFerTE^^.teLength > 0 then
			begin
				for kind := 1 to SFXFerTE^^.teLength do
					load := concat(load, ' ');
				BlockMove(@tempChars^^[0], @load[1], SFXFerTE^^.teLength);
			end;
			if (nameOrDesc = 0) then
			begin
				if (length(load) > 0) and (length(load) < 32) then
				begin
					kind := pos(':', sysopOpenDir^^[beingRenamed].realFName);
					t2 := '';
					if (kind = 0) then
						result := Rename(concat(forums^^[SysOpDirNum].dr[SysOpSubNum].path, sysopOpenDir^^[beingRenamed].realFName), 0, concat(forums^^[SysOpDirNum].dr[SysOpSubNum].path, load))
					else
					begin
						t2 := copy(sysopOpenDir^^[beingRenamed].realFName, 1, kind);
						result := Rename(sysopOpenDir^^[beingRenamed].realFName, 0, load);
					end;
					if result = noErr then
					begin
						if sysopOpenDir^^[beingRenamed].hasExtended then
						begin
							ReadExtended(sysopOpenDir^^[beingRenamed], sysopDirNum, sysopSubNum);
							DeleteExtDesc(sysopOpenDir^^[beingRenamed], sysopDirNum, sysopSubNum);
						end;
						sysopOpenDir^^[beingRenamed].realFName := concat(t2, load);
						sysopOpenDir^^[beingRenamed].flName := load;
						if sysopOpenDir^^[beingRenamed].hasExtended then
							AddExtended(sysopOpenDir^^[beingRenamed], sysopDirNum, sysopSubNum);
					end
					else
						SysBeep(10);
				end
				else
					SysBeep(10);
			end
			else if (nameOrDesc = 1) and (not enhanced) then
			begin
				sysopOpenDir^^[beingRenamed].flDesc := load;
			end
			else if (nameOrDesc = 2) and (enhanced) then
			begin
				StringToNum(load, tempo);
				sysOpOpenDir^^[beingRenamed].numdloads := tempo;
			end
			else if (nameOrDesc = 3) and (enhanced) then
			begin
				sysopOpenDir^^[beingRenamed].version := load;
			end;
			TEDispose(SFXFerTE);
			SFXferTE := nil;
			tempCell.h := 0;
			tempCell.v := beingRenamed;
			load := GenFileNote(beingRenamed);
			LSetCell(@load[1], length(load), tempCell, XFerList);
		end;
		beingRenamed := -1;
	end;

	function SysopUploadHook (item: integer; dPtr: DialogPtr): integer;
		label
			900, 1000, 444;
		var
			messageTitle, t2: str255;
			h: Handle;
			kind, kind2, wid, wid2, i, ky: Integer;
			r, rView, dataBounds: rect;
			cSize: point;
			hhh: HparamBlockRec;
			Tetatet: CInfoPBRec;
			myPop, myPop2: myPopContHand;
			sysCurFil: filEntryRec;
			myC: controlHandle;
			citem: controlhandle;
			tempcell: cell;
			deleteRemoved, RemoveEntry, isAnAlias, myOwn, removeULCredit: boolean;
			kbNunc: keyMap;
			tempFS: FSSpec;
			myTempInt: integer;
			myUser: UserRec;
	begin
		SysopUploadHook := item;
		isAnAlias := false;
		SetPort(dPtr);
		TextSize(12);
		TextFont(0);
		if XFerNeedsUpdate and (item = 100) then
		begin
			SysopUploadHook := 101;
			XFerNeedsUpdate := false;
			item := 101;
		end
		else
			case item of
				100: 
				begin
					if SFXferTE <> nil then
						TEIdle(SFXferTE);
					giveBBStime;
				end;
				-1: 
				begin
					enhanced := False;
					ClearRename(dPtr);
					GetDItem(dPtr, 17, kind, h, r);
					myPop := pointer(h);
					DelMenuItem(myPop^^.contrlData^^.mHandle, 1);
					for i := 1 to forumIdx^^.numforums do
					begin
						AppendMenu(myPop^^.contrlData^^.mHandle, 'B');
						SetItem(myPop^^.contrlData^^.mHandle, i, forumIdx^^.name[i - 1]);
					end;
					SetCtlValue(controlhandle(myPop), 1);
					if enhanced then
						SetCheckBox(dPtr, 23, true)
					else
						SetCheckBox(dPtr, 22, true);
					GetDItem(dPtr, 25, kind, h, r);
					myPop2 := pointer(h);
					DelMenuItem(myPop2^^.contrlData^^.mHandle, 1);
					for i := 1 to forumIdx^^.numdirs[0] do
					begin
						AppendMenu(myPop2^^.contrlData^^.mHandle, 'B');
						SetItem(myPop2^^.contrlData^^.mHandle, i, forums^^[0].dr[i].dirname);
					end;
					SetCtlValue(controlhandle(myPop2), 1);
					GetDItem(dPtr, 12, kind, h, r);
					SetCtlValue(controlHandle(h), 1);
					GetDItem(dPtr, 15, kind, h, r);
					HiLiteControl(controlHandle(h), 255);
					GetDItem(dPtr, 14, kind, h, r);
					HiLiteControl(controlHandle(h), 255);
					GetDItem(dPtr, 11, kind, h, r);
					SetDItem(dPtr, 11, kind, handle(@DrawXFerList), r);
					rView := r;
					rView.right := rView.right - 15;
					InsetRect(rView, 1, 1);
					dataBounds.topLeft := Point(0);
					dataBounds.bottom := 0;
					databounds.Right := 1;
					cSize.v := 11;		{ could be 22 }
					cSize.h := rView.right - rView.left;
					XFerList := LNew(rView, dataBounds, cSize, 2056, dPtr, FALSE, FALSE, FALSE, TRUE);  {2056 is custom LDEF}
					XFerList^^.selFlags := lNoNilHilite;
					FillXFerList;
					GetDItem(dPtr, 16, kind, h, r);
					EraseRect(r);
					r.left := -(r.right - r.left);
					r.right := 0;
					OffsetRect(r, forums^^[sysopDirNum].dr[sysopSubNum].fileNameLength * 6 + 20, 0);
					SetDItem(dptr, 16, kind, h, r);
				end;
				26: 
				begin
					t2 := forums^^[SysOpDirNum].dr[sysopSubNum].path;
					with hhh do
					begin
						iocompletion := nil;
						ioNamePtr := @t2;
						ioVolIndex := -1;
						ioVRefNum := 0;
					end;
					result := PBHGetVInfo(@hhh, false);
					t2 := forums^^[SysOpDirNum].dr[sysopSubNum].path;
					with tetatet do
					begin
						iocompletion := nil;
						ioNamePtr := @t2;
						iovRefNum := HHH.ioVRefNum;
						ioFDirIndex := 0;
					end;
					result := PBGetCatInfo(@tetatet, false);
					curDirStore^ := tetaTet.ioDrDirId;
					SFSaveDisk^ := -(hhh.ioVRefNum);
					XFerNeedsUpdate := true;
				end;
				15: 
				begin
					ClearRename(dPtr);
					SelectDirectory(wid, wid2);
					if wid >= 0 then
					begin
						if (wid <> sysopDirNum) or (wid2 <> SysOpSubNum) then
						begin
							tempcell.v := 0;
							tempcell.h := 0;
							result := noErr;
							while (LGetSelect(true, tempCell, XFerList)) and (result = noErr) do
							begin
								kind := sysopDirNum;
								sysCurFil := sysopOpenDir^^[tempCell.v];
								ky := pos(':', sysCurFil.realFName);
								if (ky = 0) then
									result := copy1File(concat(forums^^[SysOpDirNum].dr[sysopSubNum].path, sysCurFil.realFName), concat(forums^^[wid].dr[wid2].path, sysCurFil.realFname));
								if (result = noErr) then
								begin
									if (ky = 0) then
										result := FSDelete(concat(forums^^[SysOpDirNum].dr[sysopSubNum].path, sysCurFil.realFName), 0)
									else
									begin
										if (ModalQuestion('Do you want to move the file itself too?', false, true) = 1) then
										begin
											result := copy1File(sysCurFil.realFName, concat(forums^^[wid].dr[wid2].path, GetFNameFromPath(sysCurFil.realFName)));
											result := FSDelete(sysCurFil.realFName, 0);
										end;
									end;
									if tempCell.v < sysopNumFiles then
									begin
										for i := 1 to ((sysopNumFiles - tempCell.v) - 1) do
										begin
											sysopOpenDir^^[tempCell.v + (i - 1)] := sysopOpenDir^^[tempCell.v + i];
										end;
									end;
									LDelRow(1, tempCell.v, XFERList);
									sysopNumFiles := sysopNumFiles - 1;
									SysSaveDirectory;
									readExtended(sysCurFil, sysopDirNum, sysopSubNum);
									deleteExtDesc(sysCurFil, sysopDirNum, sysopSubNum);
									AddExtended(sysCurFil, wid, wid2);
									FileEntry(sysCurFil, wid, wid2, myTempInt, 0);
									if (ForumIdx^^.lastUpload[wid, wid2] < sysCurFil.whenUl) or (ForumIdx^^.lastUpload[wid, wid2] = 0) then
									begin
										ForumIdx^^.lastUpload[wid, wid2] := sysCurFil.whenUl;
										DoForumRec(true);
									end;
									if SysOpenDirectory(sysopDirNum, sysopSubNum) then
										;
								end
								else if (result = -43) then
								begin
									myOwn := optionDown;
									if not optiondown then
										myOwn := (ModalQuestion('File Doest Not Exist, Move Anyways?', false, true) = 1);
									if myOwn then
									begin
										if tempCell.v < sysopNumFiles then
										begin
											for i := 1 to ((sysopNumFiles - tempCell.v) - 1) do
											begin
												sysopOpenDir^^[tempCell.v + (i - 1)] := sysopOpenDir^^[tempCell.v + i];
											end;
										end;
										LDelRow(1, tempCell.v, XFERList);
										sysopNumFiles := sysopNumFiles - 1;
										SysSaveDirectory;
										readExtended(sysCurFil, sysopDirNum, sysopSubNum);
										deleteExtDesc(sysCurFil, sysopDirNum, sysopSubNum);
										AddExtended(sysCurFil, wid, wid2);
										myTempInt := sysCurFil.byteLen div 1024;
										FileEntry(sysCurFil, wid, wid2, myTempInt, -102);
										if (ForumIdx^^.lastUpload[wid, wid2] < sysCurFil.whenUl) or (ForumIdx^^.lastUpload[wid, wid2] = 0) then
										begin
											ForumIdx^^.lastUpload[wid, wid2] := sysCurFil.whenUl;
											DoForumRec(true);
										end;
										if SysOpenDirectory(sysopDirNum, sysopSubNum) then
											;
									end;
								end
								else
									ProblemRep(StringOf(RetInStr(514), result : 0));	{Move aborted, file copy error: }
							end;
							XFERNeedsUpdate := true;
						end
						else
							ProblemRep(RetInStr(515));	{The file(s) are already in that directory!}
						SetPort(dPtr);
					end;
				end;
				18: 
				begin
					ClearRename(dPtr);
					GetDItem(dPtr, 18, kind, h, r);
					kind := GetCtlValue(controlhandle(h));
					SetCtlValue(controlHandle(h), (kind + 1) mod 2);
					if (GetCtlValue(controlHandle(h)) = 1) then
						maskFiles := true
					else
						maskFiles := false;
					XFerNeedsUpdate := true;
				end;
				22, 23: 
				begin
					SetCheckBox(dPtr, 22, false);
					SetCheckBox(dPtr, 23, false);
					if enhanced then
					begin
						enhanced := false;
						SetCheckBox(dPtr, 22, true);
					end
					else
					begin
						enhanced := true;
						SetCheckBox(dPtr, 23, true);
					end;
					FillXFerList;
					GetDItem(dptr, 11, kind, h, r);
					FrameRect(r);
					LUpdate(dPtr^.visRgn, XFerList);
				end;
				19: 
				begin
					ClearRename(dPtr);
					GetDItem(dPtr, 12, kind, h, r);
					if (GetCtlValue(controlHandle(h)) = 1) then
						i := 1
					else
						i := 2;
					SysQuickSort(0, sysopNumFiles - 1, i);
					FillXFerList;
					GetDItem(dptr, 11, kind, h, r);
					FrameRect(r);
					LUpdate(dPtr^.visRgn, XFerList);
				end;
				14: 
				begin
					ClearRename(dPtr);
					GetKeys(KBNunc);
					if not KBNunc[58] then
					begin
						if (ModalQuestion('Delete entry(s) from data file?', false, true) = 1) then	{Delete entry from data file?}
							removeEntry := true
						else
							removeEntry := false;
						SetPort(dPtr);
					end
					else
						removeEntry := true;
					GetKeys(KBNunc);
					if not KBNunc[58] then
					begin
						if (ModalQuestion(RetInStr(516), false, true) = 1) then	{Delete file(s) from the disk?}
							deleteRemoved := true
						else
							deleteRemoved := false;
						SetPort(dPtr);
					end
					else
						deleteRemoved := true;
					GetKeys(KBNunc);
					if not KBNunc[58] then
					begin
						if (ModalQuestion('Remove UL credit?', false, true) = 1) then
							removeULCredit := true
						else
							removeULCredit := false;
						SetPort(dPtr);
					end
					else
						removeULCredit := true;
					tempcell.v := 0;
					tempcell.h := 0;
					while LGetSelect(true, tempCell, XFerList) do
					begin
						if removeULCredit then
						begin
							if FindUser(myUsers^^[sysopOpenDir^^[tempCell.v].uploaderNum - 1].UName, myUser) then
							begin
								MyUser.numUploaded := myUser.numUploaded - 1;
								MyUser.UploadedK := myUser.uploadedK - (sysopOpenDir^^[tempCell.v].byteLen div 1024);
								if MyUser.UploadedK < 0 then
									MyUser.UploadedK := 0;
								if myUser.UserNum = curglobs^.thisUser.userNum then
								begin
									curglobs^.thisUser.numUploaded := curglobs^.thisUser.numUploaded - 1;
									curglobs^.thisUser.UploadedK := curglobs^.thisUser.uploadedK - (sysopOpenDir^^[tempCell.v].byteLen div 1024);
									if curglobs^.thisUser.UploadedK < 0 then
										curglobs^.thisUser.UploadedK := 0;
								end;
								WriteUser(myUser);
							end;
						end;
						if deleteRemoved then
						begin
							if (pos(':', sysopOpenDir^^[tempCell.v].realFName) = 0) then
								t2 := concat(forums^^[sysopDirNum].dr[SysopSubNum].path, sysopOpenDir^^[tempCell.v].realFName)
							else
								t2 := sysopOpenDir^^[tempCell.v].realFName;
							result := FSDelete(t2, 0);
						end;
						if removeEntry then
						begin
							deleteExtDesc(sysopOpenDir^^[tempCell.v], sysopDirNum, SysOpSubNum);
							if tempCell.v < (sysopNumFiles - 1) then
							begin
								BlockMove(@sysopOpenDir^^[tempCell.v + 1], @sysopOpenDir^^[tempCell.v], SizeOf(filEntryRec) * longint(sysopNumFiles - (tempCell.v + 1)));
							end;
							sysopNumFiles := sysopNumFiles - 1;
							LDelRow(1, tempCell.v, XFerList);
						end
						else
							LSetSelect(False, tempCell, XFerList);
					end;
					XFerNeedsUpdate := true;
				end;
				12: 
				begin
					GetDItem(dPtr, 12, kind, h, r);
					kind := GetCtlValue(controlhandle(h));
					SetCtlValue(controlHandle(h), (kind + 1) mod 2);
				end;
				17: 
				begin
					GetDItem(dPtr, 17, kind, h, r);
					kind := GetCtlValue(controlhandle(h));
					if (kind - 1) <> sysopDirNum then
					begin
						GetDItem(dPtr, 14, tempCell.v, h, r);
						HiLiteControl(controlHandle(h), 255);
						ClearRename(dPtr);
						GetDItem(dPtr, 25, kind2, h, r);
						myPop2 := pointer(h);
						for i := 1 to forumIdx^^.numdirs[SysOpDirNum] do
							DelMenuItem(myPop2^^.contrlData^^.mHandle, 1);
						SysSaveDirectory;
						if SysOpenDirectory(kind - 1, 1) then
							;
						if sysopOpenDir = nil then
						begin
							sysopNumFiles := 0;
							sysopOpenDir := aDirHand(NewHandle(0));
							HNoPurge(handle(sysopOpenDir));
							sysopDirNum := kind - 1;
							sysopSubNum := 1;
						end;
						FillXFerList;
						GetDItem(dptr, 11, kind, h, r);
						FrameRect(r);
						LUpdate(dPtr^.visRgn, XFerList);
						GetDItem(dPtr, 16, kind, h, r);
						EraseRect(r);
						r.left := -(r.right - r.left);
						r.right := 0;
						OffSetRect(r, forums^^[SysOpDirNum].dr[SysOpSubNum].fileNameLength * 6 + 20, 0);
						SetDItem(dptr, 16, kind, h, r);
						GetDItem(dPtr, 25, kind, h, r);
						myPop2 := pointer(h);
						DelMenuItem(myPop2^^.contrlData^^.mHandle, 1);
						for i := 1 to forumIdx^^.numdirs[SysOpDirNum] do
						begin
							AppendMenu(myPop2^^.contrlData^^.mHandle, 'B');
							SetItem(myPop2^^.contrlData^^.mHandle, i, forums^^[SysOpDirNum].dr[i].dirname);
						end;
						SetCtlValue(controlhandle(myPop2), 1);
						DrawDialog(dPtr);
						XFerNeedsUpdate := true;
					end;
				end;
				25: 
				begin
					GetDItem(dPtr, 25, kind, h, r);
					kind := GetCtlValue(controlhandle(h));
					if (kind) <> sysopSubNum then
					begin
						GetDItem(dPtr, 14, tempCell.v, h, r);
						HiLiteControl(controlHandle(h), 255);
						ClearRename(dPtr);
						SysSaveDirectory;
						if SysOpenDirectory(SysOpDirNum, kind) then
							;
						if sysopOpenDir = nil then
						begin
							sysopNumFiles := 0;
							sysopOpenDir := aDirHand(NewHandle(0));
							HNoPurge(handle(sysopOpenDir));
							sysopSubNum := kind;
						end;
						FillXFerList;
						GetDItem(dptr, 11, kind, h, r);
						FrameRect(r);
						LUpdate(dPtr^.visRgn, XFerList);
						GetDItem(dPtr, 16, kind, h, r);
						EraseRect(r);
						r.left := -(r.right - r.left);
						r.right := 0;
						OffSetRect(r, forums^^[SysOpDirNum].dr[SysOpSubNum].fileNameLength * 6 + 20, 0);
						SetDItem(dptr, 16, kind, h, r);
						DrawDialog(dPtr);
						XFerNeedsUpdate := true;
					end;
				end;
				sfHookOpenAlias: 
				begin
					isAnAlias := true;
					goto 900;
				end;
				getOpen: 
				begin
900:
					ClearRename(dPtr);
					deleteRemoved := false;
					messageTitle := PathnameFromDirID(curDirStore^, -(SFSaveDisk^));
					t2 := replySF.fname;
					if (length(t2) > 0) then
					begin
						result := noErr;
						sysCurFil.realFName := replySF.fName;
						if messageTitle <> forums^^[SysOpDirNum].dr[SysOpSubNum].path then
						begin
							if not FEXIST(concat(forums^^[SysOpDirNum].dr[SysOpSubNum].path, replySF.fName)) then
							begin
								GetKeys(KBNunc);
								if not KBNunc[58] then
								begin
									if (ModalQuestion(RetInStr(517), false, true) = 0) then	{Move file into directory path?}
									begin
										sysCurFil.realFName := concat(messageTitle, replySF.fName);
										goto 444;
									end
									else if (ModalQuestion('Delete original file?', false, true) = 1) then
										deleteRemoved := true
									else
										deleteRemoved := false;
									SetPort(dPtr);
								end
								else
									deleteRemoved := true;
								SetPort(dPtr);
								t2 := concat(forums^^[SysOpDirNum].dr[SysOpSubNum].path, replySF.fName);
								messageTitle := concat(messageTitle, replySF.fName);
								result := copy1File(messageTitle, t2);
								if (result <> noErr) then
								begin
									ProblemRep(StringOf(RetInStr(518), result : 0));	{Error copying file: }
									sysopUploadHook := 100;
									exit(sysopUploadHook);
								end
								else if deleteRemoved then
									result := FSDelete(messageTitle, 0);
							end
							else
							begin
								ProblemRep(RetInStr(519));	{File already exists in this directory.}
								sysopUploadHook := 100;
								exit(sysopUploadHook);
							end;
						end;
						if result = noErr then
						begin
444:
							t2 := replySF.fName;
							sysCurFil.flName := t2;
							sysCurFil.flDesc := '';
							GetDateTime(sysCurFil.whenUL);
							sysCurFil.uploaderNum := 1;
							sysCurFil.numDLoads := 0;
							hhh.ioCompletion := nil;
							if (pos(':', sysCurFil.realFName) = 0) then
								messageTitle := concat(forums^^[SysOpDirNum].dr[SysOpSubNum].path, sysCurFil.realFName)
							else
								messageTitle := sysCurFil.realFName;
							sysCurFil.byteLen := 0;
							if (gMac.systemVersion >= $0700) then
							begin
								result := FSMakeFSSpec(0, 0, messageTitle, tempFS);
								result := ResolveAliasFile(tempFS, true, deleteRemoved, isAnAlias);
								if deleteRemoved then
									goto 1000;
								hhh.ioVRefNum := tempFS.vrefnum;
								hhh.ioFDirIndex := 0;
								hhh.ioDirID := tempFS.parID;
								hhh.ioNamePtr := @tempFS.name;
								if (PBHGetFInfo(@hhh, false) = noErr) then
									sysCurFil.byteLen := hhh.ioFLLgLen + hhh.ioFLRLgLen;
							end
							else
							begin
								hhh.ioNamePtr := @messageTitle;
								hhh.ioVRefNum := 0;
								hhh.ioFVersNum := 0;
								hhh.ioFDirIndex := 0;
								if PBGetFInfo(@hhh, false) = noErr then
									sysCurFil.byteLen := hhh.ioFLLgLen + hhh.ioFLRLgLen;
							end;
							if sysCurFil.byteLen < 1024 then
								sysCurFil.byteLen := 1024;
							sysCurFil.hasExtended := false;
							sysCurFil.fileStat := char(0);
							sysCurFil.lastDL := 0;
							for i := 1 to 50 do
								sysCurFil.reserved[i] := char(0);
							SysCurFil.Version := '';
							SysCurFil.FileType := hhh.ioFlFndrInfo.fdtype;
							SysCurFil.FileCreator := hhh.ioFlFndrInfo.fdcreator;
							SysCurFil.FileNumber := 0;
							SetHandleSize(handle(sysopOpenDir), GetHandleSize(handle(sysopOpenDir)) + SizeOf(filEntryRec));
							BlockMove(pointer(sysopOpenDir^), @sysopOpenDir^^[1], longInt(sysopNumFiles) * SizeOf(filEntryRec));
							sysopNumFiles := sysopNumFiles + 1;
							sysopOpenDir^^[0] := sysCurFil;
							kind := LAddRow(1, 0, XFerList);
							tempCell.h := 0;
							tempCell.v := kind;
							t2 := GenFileNote(0);
							LSetCell(@t2[1], length(t2), tempCell, XFerList);
							GetDateTime(ForumIdx^^.lastupload[SysOpDirNum, SysOpSubNum]);
							DoForumRec(true);
							GetDItem(dptr, 11, kind, h, r);
							FrameRect(r);
							LUpdate(dPtr^.visRgn, XFerList);
							GetDItem(dPtr, 18, kind, h, r);
							if (GetCtlValue(controlHandle(h)) = 1) or deleteRemoved then
								XFerNeedsUpdate := true;
						end
						else
1000:
							SysBeep(10);
					end
					else
						SysBeep(10);
					SysopUploadHook := 100;
				end;
				20: 
				begin
					ClearRename(dPtr);
					SysSaveDirectory;
					LDispose(XFerList);
					if SFXFerTE <> nil then
						TEDispose(SFXFerTE);
					SFXferTE := nil;
					SysopUploadHook := getCancel;
				end;
				otherwise
			end;
	end;

	function ExtMyFilter (theDialog: dialogPtr; var theEvent: eventRecord; var itemHit: integer): boolean;
		var
			myPt: point;
			key: char;
			kind: integer;
			h, aHandle: handle;
			r: rect;
			oldSize, newSize: LongInt;
			tempLong, tempLong2: LongInt;
	begin
		ExtMyFilter := false;
		SetPort(theDialog);
		TEIdle(myTE);
		mypt := theEvent.where;
		GlobalToLocal(mypt);
		if (theEvent.what = mouseDown) then
		begin
			GetDItem(theDialog, 1, kind, h, r);
			if PtInRect(myPt, r) then
				TEClick(myPt, false, myTE);
		end
		else if (theEvent.what = keyDown) or (theEvent.what = autoKey) then
		begin
			if cmddown then
			begin
				if theEvent.message = 133494 then
				begin
					if TEFromScrap = noErr then
					begin
						if TEGetScrapLen + (myte^^.teLength - (myte^^.selEnd - myte^^.selStart)) > 560 then
							SysBeep(10)
						else
						begin
							aHandle := Handle(TEGetText(myte));
							oldSize := GetHandleSize(aHandle);
							newSize := oldSize + TEGetScrapLen + 1024;  {1024 just for safety}
							SetHandleSize(aHandle, newSize);
							result := MemError;
							SetHandleSize(aHandle, oldSize);
							if result <> noErr then
								SysBeep(10)
							else
								TEPaste(myte);
						end;
					end
					else
						SysBeep(10);
				end
				else if theEvent.message = 133219 then
				begin
					if ZeroScrap = noErr then
					begin
						TECopy(myte);
						if TEToScrap <> noErr then
						begin
							SysBeep(10);
							if ZeroScrap = noErr then
								;
						end;
					end;
				end
				else if theEvent.message = 131169 then
				begin
					TESetSelect(0, 32767, myte);
				end
				else if theEvent.message = 132984 then
				begin
					if ZeroScrap = noErr then
					begin
						PurgeSpace(tempLong, tempLong2);
						if (myTe^^.selEnd - myTe^^.selStart) + 1024 > tempLong2 then   {1024 is just for safety}
						begin
							SysBeep(10);
							SysBeep(10);
						end
						else
						begin
							TECut(myTe);
							if TEToScrap <> noErr then
							begin
								SysBeep(10);
								if ZeroScrap = noErr then
									;
							end;
						end;
					end;
				end;
			end
			else
			begin
				key := CHR(BAnd(theevent.message, charCodeMask));
				TEKey(key, myTE);
			end;
			extMyFilter := true;
		end
		else
			giveBBStime;
	end;

	procedure SysopExtDesc (var myFRec: filEntryRec; whichDir, whichSub: integer);
		var
			descDilg, askDilg: dialogPtr;
			kind, a, i: integer;
			h: handle;
			r, r2: rect;
			t1: str255;
			ttUser: UserRec;
	begin
		descDilg := GetNewDialog(624, nil, pointer(-1));
		SetPort(descDilg);
		SetGeneva(descDilg);

		SetTextBox(descDilg, 3, stringOf((80 - forums^^[sysOpDirNum].dr[SysopSubNum].FilenameLength) : 0, ' chars/10 Lines'));
		SetTextBox(descDilg, 6, stringOf(myUsers^^[myFRec.uploaderNum - 1].UName, ' #', myFRec.uploaderNum : 0));
		SetTextBox(descDilg, 8, myFrec.flName);
		GetDItem(descDilg, 1, kind, h, r);
		SetRect(r, r.left, r.Top, ((82 - forums^^[sysopDirNum].dr[SysopSubNum].fileNameLength) * 6) + 1, r.Bottom);
		r2 := r;
		InsetRect(r2, 2, 2);
		myTE := TENew(r2, r2);
		if myTE <> nil then
		begin
			myTE^^.txFont := 150;
			myTE^^.txSize := 9;
			myTE^^.crOnly := -1; {-1}
			myTE^^.lineHeight := 11;
			myTE^^.fontAscent := 9;
			if myFRec.hasExtended then
			begin
				SysopDesc := SysopReadExtended(myFRec, whichDir, whichSub);
				HLock(handle(SysopDesc));
				if SysopDesc <> nil then
					TESetText(pointer(SysopDesc^), GetHandleSize(handle(SysopDesc)), myTE);
				HUnLock(handle(SysopDesc));
				DisposHandle(handle(SysopDesc));
				SysopDesc := nil;
			end;
			TEUpdate(descDilg^.portRect, myTE);
			ShowWindow(descDilg);
			DrawDialog(descDilg);
			FrameRect(r);
			TEUpdate(descDilg^.portRect, myTE);
			TEActivate(myTE);
			repeat
				ModalDialog(@extMyFilter, a);
				if a = 6 then
				begin
					askDilg := GetNewDialog(744, nil, pointer(-1));
					SetPort(askDilg);
					ParamText('Enter name or number, * wildcard allowed.', '', '', '');
					DrawDialog(askDilg);
					repeat
						ModalDialog(nil, i);
					until (i = 1);
					GetDItem(askDilg, 3, kind, h, r);
					GetIText(h, t1);
					DisposDialog(askDilg);
					SetPort(descDilg);
					DrawDialog(descDilg);
					TEUpdate(descDilg^.portRect, myTE);
					if FindUser(t1, ttUser) then
						myFRec.uploaderNum := ttUser.userNum;
					SetTextBox(descDilg, 6, stringOf(myUsers^^[myFRec.uploaderNum - 1].UName, ' #', myFRec.uploaderNum : 0));
					SetTextBox(descDilg, 8, myFrec.flName);
					GetDItem(descDilg, 1, kind, h, r);
					SetRect(r, r.left, r.Top, ((82 - forums^^[sysopDirNum].dr[SysopSubNum].fileNameLength) * 6) + 1, r.Bottom);
					r2 := r;
					InsetRect(r2, 2, 2);
					FrameRect(r);
				end;
			until (a = 4);
			DeleteExtDesc(myFRec, whichDir, whichSub);
			SysopDesc := TEGetText(myTE);
			result := HandToHand(handle(SysopDesc));
			if result = noErr then
			begin
				HNoPurge(handle(SysopDesc));
				myFRec.hasExtended := false;
				if GetHandleSize(handle(SysopDesc)) > 0 then
				begin
					SysopAddExtended(myFRec, whichDir, whichSub, SysopDesc);
					myFRec.hasExtended := true;
				end;
				HPurge(handle(SysopDesc));
				DisposHandle(handle(SysopDesc));
			end
			else
				SysBeep(10);
			TEDispose(myTE);
		end
		else
			SysBeep(10);
		DisposDialog(descDilg);
	end;

	procedure DoUpdate (window: WindowPtr);
		var
			indWind, id2: integer;
	begin
		indWind := isMyTextWindow(window);
		id2 := ismyBBSwindow(window);
		if (window = statWindow) or (window = ssWind) then
		begin
			BeginUpdate(window);
			EndUpdate(window);
			if window = statWindow then
				UpdateStatWindow;
		end
		else if id2 > 0 then
		begin
			if id2 = 1 then
				id2 := 1;
			BeginUpdate(window);
			UpdateBBSwindow(id2);
			EndUpdate(window);
		end
		else if indWind >= 0 then
		begin
			with textWinds[indWind] do
			begin
				BeginUpdate(w);
				SetPort(w);
				with w^ do
				begin
					EraseRect(portRect);
					TEUpdate(portRect, t);
					DrawControls(w);
					DrawGrowIcon(w);
				end;
				EndUpdate(w);
			end;
		end;
	end;

	function XFerListModal (theDialog: DialogPtr; var theEvent: EventRecord; var itemHit: integer): boolean;
		var
			localPt: Point;
			kind, maxLen, part: integer;
			key: char;
			shiftDown, didSomething: boolean;
			growReturn: longint;
			t5, t6, t1: str255;
			r, rView, dataBounds, dumRect: rect;
			tempcell, cSize: cell;
			whereWindow: WindowPtr;
			h, aHandle: handle;
			oldSize, newSize: LongInt;
			tempLong, tempLong2: LongInt;
			askDilg: dialogPtr;
			ttUser: UserRec;
	begin
		didSomething := false;
		XFerListModal := FALSE;
		SetPort(theDialog);
		if (theEvent.what = updateEvt) then
		begin
			if (DialogPtr(theEvent.message) <> theDialog) then
			begin
				itemHit := 100;
				XFerListModal := TRUE;
				DoUpdate(windowPtr(theEvent.message));
			end;
		end
		else if (theEvent.what = KeyDown) or (theEvent.what = AutoKey) then
		begin
			if SFXFerTE <> nil then
			begin
				if (nameOrDesc = 0) then
					maxLen := forums^^[sysopDirNum].dr[SysopSubNum].fileNameLength
				else if (nameorDesc = 1) then
					MaxLen := 80 - forums^^[sysopDirNum].dr[SysopSubNum].fileNameLength
				else if (nameorDesc = 2) then
					MaxLen := 4
				else if (nameorDesc = 3) then
					MaxLen := 10;
				key := CHR(BAnd(theevent.message, charCodeMask));
				if cmddown then
				begin
					if theEvent.message = 133494 then
					begin
						if TEFromScrap = noErr then
						begin
							if TEGetScrapLen + (SFXferTE^^.teLength - (SFXferTE^^.selEnd - SFXferTE^^.selStart)) > maxLen then
								SysBeep(10)
							else
							begin
								aHandle := Handle(TEGetText(SFXferTE));
								oldSize := GetHandleSize(aHandle);
								newSize := oldSize + TEGetScrapLen + 1024;  {1024 just for safety}
								SetHandleSize(aHandle, newSize);
								result := MemError;
								SetHandleSize(aHandle, oldSize);
								if result <> noErr then
									SysBeep(10)
								else
									TEPaste(SFXferTE);
							end;
						end
						else
							SysBeep(10);
					end
					else if theEvent.message = 133219 then
					begin
						if ZeroScrap = noErr then
						begin
							TECopy(SFXferTE);
							if TEToScrap <> noErr then
							begin
								SysBeep(10);
								if ZeroScrap = noErr then
									;
							end;
						end;
					end
					else if theEvent.message = 131169 then
					begin
						TESetSelect(0, 32767, SFXferTE);
					end
					else if theEvent.message = 132984 then
					begin
						if ZeroScrap = noErr then
						begin
							PurgeSpace(tempLong, tempLong2);
							if (SFXferTE^^.selEnd - SFXferTE^^.selStart) + 1024 > tempLong2 then   {1024 is just for safety}
							begin
								SysBeep(10);
								SysBeep(10);
							end
							else
							begin
								TECut(SFXferTE);
								if TEToScrap <> noErr then
								begin
									SysBeep(10);
									if ZeroScrap = noErr then
										;
								end;
							end;
						end;
					end;
				end
				else if (key = CHR(8)) | (SFXferTE^^.teLength - (SFXferTE^^.selEnd - SFXferTE^^.selStart) + 1 <= maxLen) then
				begin
					TEKey(key, SFXferTE);
				end
				else
					SysBeep(10);
				XFerListModal := true;
				itemHit := 100;
			end;
		end
		else if (theEvent.what = mouseDown) then
		begin
			localPt := theEvent.where;
			GlobalToLocal(localPt);
			part := FindWindow(theEvent.where, whereWindow);
			case part of
				inDrag: 
				begin
					if whereWindow = theDialog then
					begin
						xferlistmodal := true;
						dumrect := screenbits.bounds;
						SetRect(dumRect, dumRect.Left + 5, dumRect.Top + 25, dumRect.Right - 5, dumRect.Bottom - 5);
						DragWindow(theDialog, theEvent.where, dumRect);
					end;
				end;
				inContent: 
				begin
					if whereWindow = theDialog then
					begin
						if (SFXferTE <> nil) then
						begin
							if (PtInRect(localPt, SFXferTE^^.viewRect)) then
							begin
								shiftDown := BAnd(theevent.modifiers, shiftKey) <> 0;	{extend if Shift is down}
								TEClick(localPt, shiftDown, SFXferTE);
							end
							else
								ClearRename(theDialog);
						end
						else if LClick(localPt, theEvent.modifiers, XFerList) then
						begin
							if beingRenamed >= 0 then
							begin
								ClearRename(theDialog);
							end;
							tempcell.v := 0;
							tempcell.h := 0;
							if LGetSelect(true, tempCell, XFerList) then
							begin
								if tempCell.v <= sysopNumFiles then
								begin
									LRect(r, tempCell, XFerList);
									if (localpt.h < ((forums^^[sysopDirNum].dr[SysopSubNum].fileNameLength * 6) + 2)) then	{and (localPt.v < (r.bottom - 11))}
									begin
										r.left := 2;
										r.right := (forums^^[sysopDirNum].dr[SysopSubNum].fileNameLength * 6) + 1;
										nameOrDesc := 0;
									end
									else if (localpt.h > (((forums^^[sysopDirNum].dr[SysopSubNum].fileNameLength + 9) * 6) + 2)) and (not enhanced) then	{localPt.v > (r.bottom - 11)}
									begin
										r.left := ((forums^^[sysopDirNum].dr[SysopSubNum].fileNameLength + 10) * 6) + 2;
										nameOrDesc := 1;
									end
									else if (localpt.h > (((forums^^[sysopDirNum].dr[SysopSubNum].fileNameLength + 9) * 6) + 2)) and (localpt.h < (((forums^^[sysopDirNum].dr[SysopSubNum].fileNameLength + 14) * 6) + 2)) and enhanced then
									begin
										r.left := (((forums^^[sysopDirNum].dr[SysopSubNum].fileNameLength + 10) * 6) + 2);
										r.right := (((forums^^[sysopDirNum].dr[SysopSubNum].fileNameLength + 14) * 6) + 2);
										nameOrDesc := 2;
									end
									else if (localpt.h > (((forums^^[sysopDirNum].dr[SysopSubNum].fileNameLength + 14) * 6) + 2)) and (localpt.h < (((forums^^[sysopDirNum].dr[SysopSubNum].fileNameLength + 25) * 6) + 2)) and (not enhanced) then
									begin
										r.left := (((forums^^[sysopDirNum].dr[SysopSubNum].fileNameLength + 15) * 6) + 2);
										r.right := (((forums^^[sysopDirNum].dr[SysopSubNum].fileNameLength + 25) * 6) + 2);
										nameOrDesc := 3;
									end
									else
									begin
										SysopExtDesc(sysopOpenDir^^[tempCell.v], sysopDirNum, sysopSubNum);
										didSomething := true;
										SetPort(theDialog);
										t5 := GenFileNote(tempCell.v);
										LSetCell(pointer(ord4(@t5) + 1), length(t5), tempCell, XFerList);
									end;
									if not didSomething then
									begin
										SFXferTE := TENew(r, r);
										SFXferTE^^.txFont := 150;
										SFXferTE^^.txSize := 9;
										SFXferTE^^.crOnly := -1;
										SFXferTE^^.lineHeight := 11;
										SFXferTE^^.fontAscent := 9;
										if (nameOrDesc = 0) then
											TESetText(@sysopOpenDir^^[tempCell.v].flName[1], length(sysopOpenDir^^[tempCell.v].flName), SFXferTE)
										else if (nameordesc = 1) then
											TESetText(@sysopOpenDir^^[tempCell.v].flDesc[1], length(sysopOpenDir^^[tempCell.v].flDesc), SFXferTE)
										else if (nameorDesc = 2) then
										begin
											NumToString(sysopOpenDir^^[tempCell.v].numDLoads, t5);
											TESetText(@t5[1], length(t5), SFXferTE);
										end
										else if (nameordesc = 3) then
											TESetText(@sysopOpenDir^^[tempCell.v].version[1], length(sysopOpenDir^^[tempCell.v].version), SFXferTE);
										InvalRect(r);
										TEActivate(SFXferTE);
										beingRenamed := tempCell.v;
									end;
								end;
							end;
						end
						else if beingRenamed >= 0 then
						begin
							ClearRename(theDialog);
						end;
					end;
				end;
				otherwise
					SysBeep(10);
			end;
			tempcell.v := 0;
			tempcell.h := 0;
			if LGetSelect(true, tempCell, XFerList) then
			begin
				GetDItem(theDialog, 15, kind, h, r);
				HiLiteControl(controlHandle(h), 0);
				GetDItem(theDialog, 14, kind, h, r);
				HiLiteControl(controlHandle(h), 0);
			end
			else
			begin
				GetDItem(theDialog, 15, kind, h, r);
				HiLiteControl(controlHandle(h), 255);
				GetDItem(theDialog, 14, kind, h, r);
				HiLiteControl(controlHandle(h), 255);
			end;
			SetRect(r, theDialog^.portRect.right - 15, theDialog^.portRect.bottom - 15, theDialog^.portRect.right, theDialog^.portRect.bottom);
			if PtInRect(localPt, r) then
			begin
				SetRect(r, 499, 299, 499, 900);
				growReturn := GrowWindow(theDialog, theEvent.where, r);
				if growReturn <> 0 then
				begin
					SizeWindow(theDialog, loWord(growReturn), hiWord(growReturn), true);
					LDispose(XFerList);
					GetDItem(theDialog, 11, kind, h, r);
					r.bottom := theDialog^.portRect.bottom - 14;
					SetDItem(theDialog, 11, kind, handle(@DrawXFerList), r);
					SetPort(theDialog);
					rView := r;
					rView.bottom := theDialog^.portRect.bottom;
					EraseRect(rView);
					InvalRect(theDialog^.portRect);
					rView := r;
					rView.right := rView.right - 15;
					InsetRect(rView, 1, 1);
					dataBounds.topLeft := Point(0);
					dataBounds.bottom := 0;
					databounds.Right := 1;
					cSize.v := 11;	{could be 22}
					cSize.h := rView.right - rView.left;
					XFerList := LNew(rView, dataBounds, cSize, 2056, theDialog, FALSE, FALSE, FALSE, TRUE);
					XFerList^^.selFlags := lNoNilHilite;
					FillXFerList;
				end;
				localPt := point($00000000);
				LocalToGlobal(localPt);
				theEvent.where := localPt;
			end;
		end;
	end;

	procedure SysopFileConfigure;
		var
			typeList: SFTypeList;
			t1: str255;
			atPt: point;
	begin
		if ForumIdx^^.numDirs[0] > 0 then
		begin

			if SysOpenDirectory(0, 1) then
				;
			if sysopOpenDir = nil then
			begin
				sysopNumFiles := 0;
				sysopOpenDir := aDirHand(NewHandle(0));
				HNoPurge(handle(sysopOpenDir));
				sysopDirNum := 0;
				sysopSubNum := 1;
			end;
			XferNeedsUpdate := false;
			beingRenamed := -1;
			maskFiles := false;
			SFXferTE := nil;
			if gMac.systemVersion >= $0700 then
				SFPGetFile(Point($00280005), '', @sysopFileFilter, -1, typeList, @SysopUploadHook, replySF, 7070, @xferlistmodal)
			else
				SFPGetFile(Point($00280005), '', @sysopFileFilter, -1, typeList, @SysopUploadHook, replySF, 6767, @xferlistmodal);

			SysCloseDirectory;
		end
		else
			ProblemRep(RetInStr(521));	{You must first set up your transfer directories.}
	end;
end.