{ Segments: InpOut3_1 }
unit inpOut3;

interface
	uses
		AppleTalk, ADSP, Serial, Sound, aliases, Initial, LoadAndSave, NodePrefs2, NodePrefs, SystemPrefs, Terminal, inpOut4;

	procedure ContinueTrans;
	procedure StartTrans;
	procedure AbortTrans;
	procedure SaveDirectory;
	procedure FileEntry (theFil: filEntryRec; theDir, theSub: integer; var SizeinK: integer; atDirPos: integer);
	procedure AddExtended (theFil: filEntryRec; whichDir, whichSub: integer);
	procedure DeleteExtDesc (theFile: filEntryRec; whichDir, whichSub: integer);
	function FragFile (path: str255): boolean;
	function CallUtility (message: integer; extRecPtr: ptr; refCon: longint): OSerr;
	procedure PrintExtended (howMuch: Integer);
	procedure DoFindDesc;
	procedure DoAddressBook;

implementation

{$S InpOut3_1}
	procedure DoAddressBook;
		const
			spaces = '                                                   ';
		var
			i: integer;
			s351, s352: string[35];
			s1, s2: str255;
			gotOne: boolean;
			l: longint;
	begin
		with curGlobs^ do
		begin
			case ABDo of
				AB1: (* List The Address Book *)
				begin
					ClearScreen;
					for i := 1 to 20 do
					begin
						NumToString(i, s1);
						if i < 10 then
							s1 := concat(' ', s1, '. ')
						else
							s1 := concat(s1, '. ');
						if AddressBook^^[i] = char(0) then
							s351 := concat(' ', spaces)
						else
							s351 := concat(AddressBook^^[i], spaces);

						NumToString(i + 20, s2);
						s2 := concat(s2, '. ');
						if AddressBook^^[i + 20] = char(0) then
							s352 := ' '
						else
							s352 := AddressBook^^[i + 20];

						OutLine(s1, true, 2);
						OutLine(s351, false, 1);
						OutLine(s2, false, 2);
						OutLine(s352, false, 1);
					end;
					ABDo := AB2;
				end;
				AB2: 
				begin
					bCR;
					bCR;
					if wasEmail then
						NumbersPrompt(RetInStr(584), 'ADCQ', 40, 1)	{#] of Address, A]dd, D]elete, C]hange, Q]uit : }
					else
						LettersPrompt(RetInStr(585), 'ADQC', 1, true, false, true, char(0));	{A]dd, D]elete, C]hange, Q]uit : }
					ABDo := AB3;
				end;
				AB3: 
				begin
					if curPrompt = '' then
						ABDo := AB1
					else if curPrompt = 'Q' then
					begin
						if wasEMail then
						begin
							BoardSection := EMail;
							EMailDo := WhichUser;
						end
						else
						begin
							BoardSection := Defaults;
							DefaultDo := DefaultOne;
						end;
					end
					else if curPrompt = 'D' then
						ABDo := AB4
					else if curPrompt = 'A' then
						ABDo := AB7
					else if curPrompt = 'C' then
						ABDo := AB9
					else if wasEMail then
					begin
						StringToNum(curPrompt, l);
						if AddressBook^^[l] <> char(0) then
						begin
							curPrompt := AddressBook^^[l];
							EMailDo := EMailOne;
						end
						else
							EMailDo := WhichUser;
						BoardSection := EMail;
					end
					else
						ABDo := AB1;
				end;
				AB4: 
				begin
					bCR;
					NumbersPrompt(RetInStr(586), '', 40, 1);	{Enter address # to delete: }
					ABDo := AB5;
				end;
				AB5: 
				begin
					ABDo := AB1;
					if curPrompt <> '' then
					begin
						StringToNum(curPrompt, l);
						crossint := l;
						if AddressBook^^[l] <> char(0) then
						begin
							YesNoQuestion(concat(RetInStr(587), AddressBook^^[l], RetInStr(206)), false);	{Delete xxxx   (Y/N)? }
							ABDo := AB6;
						end
						else
							OutLine(RetInStr(588), true, 0);	{There is no address to delete.}
					end;
				end;
				AB6: 
				begin
					if curPrompt = 'Y' then
					begin
						AddressBook^^[crossint] := char(0);
						DoAddressBooks(AddressBook, thisUser.UserNum, true);
					end;
					ABDo := AB1;
				end;
				AB7: 
				begin
					bCR;
					LettersPrompt(RetInStr(589), '', 45, false, false, false, char(0));	{Enter address: }
					ABDo := AB8;
				end;
				AB8: 
				begin
					if curPrompt <> '' then
					begin
						gotOne := false;
						for i := 1 to 40 do
							if AddressBook^^[i] = char(0) then
							begin
								gotOne := true;
								AddressBook^^[i] := curPrompt;
								leave;
							end;
						if gotOne then
							DoAddressBooks(AddressBook, thisUser.UserNum, true)
						else
							OutLine(RetInStr(590), true, 0);	{Not added. Address Book is full.}
					end;
					ABDo := AB1;
				end;
				AB9: 
				begin
					bCR;
					NumbersPrompt(RetInStr(591), '', 40, 1);	{Enter address # to change: }
					ABDo := AB10;
				end;
				AB10: 
					if curPrompt = '' then
						ABDo := AB1
					else
					begin
						StringToNum(curPrompt, l);
						crossint := l;
						bCR;
						OutLine(RetInStr(592), true, 2);	{Current Address: }
						if AddressBook^^[l] = char(0) then
							OutLine(' ', false, 1)
						else
							OutLine(AddressBook^^[l], false, 1);
						bCR;
						bCR;
						LettersPrompt(RetInStr(593), '', 45, false, false, false, char(0)); {Enter new address: }
						ABDo := AB11;
					end;
				AB11: 
				begin
					if curPrompt <> '' then
					begin
						AddressBook^^[crossint] := curPrompt;
						DoAddressBooks(AddressBook, thisUser.UserNum, true)
					end;
					ABDo := AB1;
				end;
				AB12: 
				begin
					if length(curPrompt) = 1 then
						ABDo := AB1
					else
					begin
						Delete(curPrompt, 1, 1);
						s1 := curPrompt;
						l := length(curPrompt);
						repeat
							i := pos(' ', curPrompt);
							if i <> 0 then
								Delete(curPrompt, i, 1);
						until i = 0;
						if (curPrompt[1] > '/') and (curPrompt[1] < ':') then
						begin
							StringToNum(curPrompt, l);
							if AddressBook^^[l] = char(0) then
								ABDo := AB1
							else
							begin
								curPrompt := AddressBook^^[l];
								BoardSection := EMail;
								EMailDo := EMailOne;
							end;
						end
						else
						begin
							gotOne := false;
							for i := 1 to 40 do
								if AddressBook^^[i] = char(0) then
								begin
									gotOne := true;
									if s1[1] = ' ' then
										Delete(s1, 1, 1);
									AddressBook^^[i] := s1;
									leave;
								end;
							if gotOne then
							begin
								Outline(RetInStr(569), true, 0);
								DoAddressBooks(AddressBook, thisUser.UserNum, true);
							end
							else
								OutLine(RetInStr(590), true, 0);	{Not added. Address Book is full.}
							curPrompt := s1;
							if (pos(',', curPrompt) = 0) and (pos('@', curPrompt) = 0) then
								UprString(curPrompt, true);
							BoardSection := EMail;
							EMailDo := EMailOne;
						end;
					end;
				end;
				otherwise
			end;
		end;
	end;

	procedure DeleteExtDesc (theFile: filEntryRec; whichDir, whichSub: integer);
		var
			tempint: integer;
			ss: handle;
	begin
		ss := nil;
		tempInt := OpenRFPerm(concat(InitSystHand^^.DataPath, forumIdx^^.name[whichDir], ':', forums^^[whichDir].dr[whichSub].dirName), 0, fsRdWrPerm);
		if tempint <> -1 then
		begin
			UseResFile(tempint);
			handle(ss) := Get1NamedResource('DESC', theFile.flName);
			RmveResource(handle(ss));
			CloseResFile(tempInt);
			UseResFile(myResourceFile);
		end;
	end;

	procedure AddExtended (theFil: filEntryRec; whichDir, whichSub: integer);
		var
			s1, tempstring: str255;
			myRef, tempint: integer;
			tuba: longint;
			tempers: filentryrec;
			s26: string[26];
	begin
		with curglobs^ do
		begin
			DeleteExtDesc(theFil, whichDir, whichSub);
			tempString := concat(InitSystHand^^.DataPath, forumIdx^^.name[whichDir], ':', forums^^[whichDir].dr[whichSub].dirName);
			tempInt := OpenRFPerm(concat(tempString), 0, fsRdWrPerm);
			if tempint = -1 then
			begin
				if not fexist(tempString) then
				begin
					result := MakeADir(concat(InitSystHand^^.DataPath, forumIdx^^.name[whichDir]));
					result := Create(tempString, 0, 'HRMS', 'DATA');
					s26 := forums^^[whichDir].dr[whichSub].dirName;
					s1 := concat(InitSystHand^^.DataPath, forumIdx^^.name[whichDir], ':', s26);
					if length(s1) > 0 then
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
				UseResFile(tempint);
				AddResource(handle(curWriting), 'DESC', Unique1Id('DESC'), theFil.flName);
				WriteResource(handle(curWriting));
				DetachResource(handle(curWriting));
				CloseResFile(tempInt);
				UseResFile(myResourceFile);
				if OpenDirectory(whichdir, whichsub) then
				begin
					curDirPos := 0;
					repeat
						GetNextFile(whichdir, whichSub, theFil.FlName, curDirPos, tempers, 0)
					until (tempers.flname = '') or (tempers.flName = theFil.flname);
					tempers.hasExtended := true;
					if (tempers.flName = theFil.flName) then
					begin
						FileEntry(tempers, whichdir, whichsub, tempInt, curDirPos);
					end;
				end
				else
				begin
					OutLine('Problem Opening Directory.', true, 0);
					LogThis(StringOf('Problem Opening Directory #', whichdir : 0), 0);
				end
			end
			else
			begin
				OutLine(RetInStr(508), true, 0);	{Could Not Save Extended Description!}
				LogThis(StringOf('Problem Saving Extended Description #', whichdir : 0), 0);
			end;
		end;
	end;

	function FragFile (path: str255): boolean;
		var
			myFInfo: FInfo;
	begin
		result := GetFInfo(path, 0, myFInfo);
		if result = noErr then
		begin
			if myFInfo.fdType = 'FRAG' then
				FragFile := true
			else
				FragFile := false;
		end
		else
			FragFile := false;
	end;

	procedure FileDLd;
		var
			tempers: FilEntryRec;
			tempEM: EmailRec;
			tempInt: integer;
			tsr: str255;
			tempTime, count: longint;
			emaildataref: integer;
	begin
		with curglobs^ do
		begin
			if (BoardSection = Batch) then
			begin
				tempindir := fileTransit^^.filesGoing[extTrans^^.filesDone + 1].fromDir;
				tempSubDir := fileTransit^^.filesGoing[extTrans^^.filesDone + 1].fromSub;
				curFil := fileTransit^^.filesGoing[extTrans^^.filesDone + 1].theFile;
			end;
			if OpenDirectory(tempIndir, tempSubDir) then
			begin
				descSearch := false;
				curDirPos := 0;
				repeat
					GetNextFile(tempIndir, tempSubDir, curFil.flName, curDirPos, tempers, 0)
				until (tempers.flname = '') or (tempers.flName = curFil.flName);
				if (tempers.flName = curFil.flName) then
				begin
					tempers.numDLoads := tempers.numDLoads + 1;
					GetDateTime(tempers.lastDL);
					FileEntry(tempers, tempInDir, TempSubDir, tempInt, curDirPos);
					if tempers.uploaderNum <> 1 then
					begin
						if FindUser(myUsers^^[tempers.uploaderNum - 1].UName, tempUser) then
						begin
							if (tempUser.userNum = tempers.uploaderNum) and not (tempUser.DeletedUser) then
							begin
								if (tempUser.firstOn < Tempers.whenUl) and (tempUser.UserNum <= numUserRecs) then
								begin
									GetDateTime(tempEM.dateSent);
									tempEM.title := tempers.flName;
									tempEM.fromUser := thisUser.userNum;
									tempEM.touser := tempuser.userNum;
									tempEM.anonyFrom := false;
									tempEM.anonyTo := false;
									tempEM.MType := 0;
									tempEM.multimail := false;
									tempEm.storedAs := 0;
									tempEM.fileAttached := false;
									tempEM.FileName := char(0);
									for tempInt := 0 to 15 do
										tempEM.reserved[tempint] := char(0);
									SetHandleSize(handle(theEmail), GetHandleSize(handle(theEmail)) + SizeOf(emailRec));
									BlockMove(@tempEm, @theEmail^^[availEmails], sizeof(emailrec));
									availEmails := availEmails + 1;
									emailDirty := true;
									if forums^^[tempInDir].dr[tempSubDir].howlong > 0 then
									begin
										GetDateTime(count);
										count := (count - tempers.whenUl) div 60 div 60 div 24;
										if count <= forums^^[tempInDir].dr[tempSubDir].howlong then
											tempuser.DLCredits := tempuser.DLCredits + trunc((tempers.byteLen / 1024) * forums^^[tempInDir].dr[tempSubDir].DLCreditor);
									end;
									tempuser.DlsByOther := tempuser.DlsByOther + 1;
									WriteUser(tempuser);
								end
								else
								begin
									tempers.uploaderNum := 1;
									FileEntry(tempers, tempInDir, TempSubDir, tempInt, curDirPos);
								end;
							end;
						end;
					end;
				end;
			end;
		end;
	end;

	procedure FileEntry (theFil: filEntryRec; theDir, theSub: integer; var SizeinK: integer; atDirPos: integer);
		var
			tempString, s1: str255;
			tempRef, tempInt: integer;
			tempLong, tl2: longInt;
			result: OSerr;
			yyyy: Ptr;
			hhh: HParamBlockRec;
			savedOpenDir, savedOpenSub: integer;
			ty: boolean;
			tempFS: FSSpec;
			s26: string[26];
	begin
		with curglobs^ do
		begin
			savedOpenDir := dirOpenNum;
			savedOpenSub := SubDirOpenNum;
			CloseDirectory;
			hhh.ioCompletion := nil;
			if (pos(':', theFil.realFName) = 0) then
				tempString := concat(forums^^[theDir].dr[theSub].path, theFil.realFName)
			else
				tempstring := theFil.realFName;
			if (Gestalt(gestaltAliasMgrAttr, tempLong) = noErr) and (tempLong = 1) then
			begin
				result := FSMakeFSSpec(0, 0, tempString, tempFS);
				hhh.ioVRefNum := tempFS.vrefnum;
				hhh.ioDirID := tempFS.parID;
				hhh.ioNamePtr := @tempstring;
			end
			else
			begin
				hhh.ioNamePtr := @tempString;
				hhh.ioVRefNum := 0;
				hhh.ioDirID := 0;
			end;
			hhh.ioFVersNum := 0;
			hhh.ioFDirIndex := 0;
			if atdirPos <> -102 then
			begin
				SizeInK := 0;
				theFil.byteLen := 0;
				if PBHGetFInfo(@hhh, false) = noErr then
				begin
					theFil.byteLen := hhh.ioFLLgLen + hhh.ioFLRLgLen;
					SizeInK := theFil.byteLen div 1024 + 1;
					if SizeinK < 0 then
						SizeinK := 1;
				end;
			end
			else
				atDirPos := 0;
			tempstring := concat(InitSystHand^^.DataPath, forumIdx^^.name[thedir], ':', forums^^[theDir].dr[theSub].dirName);
			result := FSOpen(tempstring, 0, tempRef);
			if result <> noErr then
			begin
				result := MakeADir(concat(InitSystHand^^.DataPath, forumIdx^^.name[theDir]));
				result := Create(tempstring, 0, 'HRMS', 'DATA');
				s26 := forums^^[theDir].dr[theSub].dirName;
				s1 := concat(InitSystHand^^.DataPath, forumIdx^^.name[theDir], ':', s26);
				if length(s1) > 0 then
				begin
					result := Create(concat(s1, ' AHDR'), 0, 'HRMS', 'TEXT');
					result := Create(concat(s1, ' HDR'), 0, 'HRMS', 'TEXT');
				end;
				result := FSOpen(tempstring, 0, tempref);
			end;
			if atDirPos < 1 then
			begin
				result := GetEOF(tempRef, tempLong);
				if (result = noErr) then
				begin
					yyyy := NewPtr(tempLong);
					if memError = noErr then
					begin
						if (templong > 0) then
							result := FSRead(tempRef, tempLong, yyyy);
						result := SetFPos(tempRef, fsFromStart, 0);
						tl2 := SizeOf(filEntryRec);
						result := FSWrite(tempRef, tl2, @theFil);
						if (tempLong > 0) then
							result := FSWrite(tempRef, tempLong, yyyy);
						DisposPtr(yyyy);
					end
					else
						SysBeep(1);
				end;
			end
			else
			begin
				result := SetFPos(tempRef, fsFromStart, SizeOf(filEntryRec) * (longInt(atDirPos) - 1));
				tempLong := SizeOf(filEntryRec);
				result := FSWrite(tempRef, tempLong, @theFil);
			end;
			result := FSClose(tempRef);
			if savedOpenDir > -1 then
				ty := OpenDirectory(savedOpenDir, savedOpenSub);
		end;
	end;

	procedure SaveDirectory;
		var
			DirFileName, s1: str255;
			theDirref: integer;
			tempLong: longint;
			s26: string[26];
	begin
		with curglobs^ do
		begin
			dirFileName := concat(InitSystHand^^.DataPath, forumIdx^^.name[dirOpenNum], ':', forums^^[dirOpenNum].dr[SubDirOpenNum].dirName);
			result := FSOpen(dirFileName, 0, theDirRef);
			if result <> noErr then
			begin
				result := MakeADir(concat(InitSystHand^^.DataPath, forumIDx^^.name[DirOpenNum]));
				result := Create(dirFileName, 0, 'HRMS', 'DATA');
				s26 := forums^^[dirOpenNum].dr[SubDirOpenNum].dirName;
				s1 := concat(InitSystHand^^.DataPath, forumIdx^^.name[dirOpenNum], ':', s26);
				if (length(s1) > 0) then
				begin
					result := Create(concat(s1, ' AHDR'), 0, 'HRMS', 'TEXT');
					result := Create(concat(s1, ' HDR'), 0, 'HRMS', 'TEXT');
				end;
				result := FSOpen(dirFileName, 0, theDirRef);
			end
			else
				result := SetEOF(theDirRef, 0);
			if result = noErr then
			begin
				tempLong := SizeOf(filEntryRec) * longint(curNumFiles);
				HLock(handle(curOpenDir));
				result := FSWrite(theDirRef, tempLong, pointer(curOpenDir^));
				HUnlock(handle(curOpenDir));
				result := FSClose(theDirRef);
			end;
		end;
	end;

	procedure AddExtFile (Fname: str255; mabName: str255);
	begin
		with curglobs^ do
		begin
			HUnlock(handle(extTrans));
			if extTrans^^.fileCount > 0 then
				SetHandleSize(HANDLE(extTrans), GetHandleSize(handle(extTrans)) + SizeOf(pathsFilesRec));
			extTrans^^.fPaths[extTrans^^.fileCount + 1].fname := NewString(fname);
			extTrans^^.fPaths[extTrans^^.fileCount + 1].mbName := NewString(mabName);
			extTrans^^.fPaths[extTrans^^.fileCount + 1].myVRef := 0;
			extTrans^^.fPaths[extTrans^^.fileCount + 1].myDirID := 0;
			extTrans^^.fPaths[extTrans^^.fileCount + 1].myFileID := 0;
			extTrans^^.fileCount := extTrans^^.fileCount + 1;
			HLock(handle(extTrans));
		end;
	end;

	procedure AbortTrans;
		var
			tempint: integer;
			aHandle: handle;
			temprect: rect;
	begin
		with curglobs^ do
		begin
			if extTrans^^.flags[stopTrans] then
				extTrans^^.flags[carrierLoss] := true
			else
				extTrans^^.flags[stopTrans] := true;
			if transDilg <> nil then
			begin
				GetDItem(transDilg, 1, tempInt, aHandle, tempRect);
				SetCTitle(controlHandle(pointer(aHandle)), 'EXIT');
			end;
		end;
	end;

	procedure StartTrans;
		var
			myCRHandle, aHandle: handle;
			tempint, i, sharedRef, TheFile: integer;
			temprect: rect;
			tems, T2, t3: str255;
			result: OSErr;
			wasSlowDevice: boolean;
	begin
		with curglobs^ do
		begin
			if BoardMode = User then
				InitXFerRec
			else if (BoardMode = Terminal) then
			begin
				DisableItem(getMHandle(mTerminal), 0);
				DisableItem(getMHandle(1009), 0);
				DrawMenuBar;
			end;
			lastCurBytes := 0;
			if InitSystHand^^.useXWind and (activeNode = visibleNode) and (gBBSwindows[activeNode]^.ansiPort <> nil) then
			begin
				SetDAFont(monaco);
				transDilg := GetNewDialog(982, nil, pointer(-1));
				tems := theProts^^.prots[activeProtocol].protoName;
				if myTrans.sending then
					tems := concat(tems, ' Send')
				else
					tems := concat(tems, ' Receive');
				SetWTitle(transdilg, tems);
				SetPort(transDilg);
				TextFont(monaco);
				TextSize(9);
				SetDAFont(0);
				ShowWindow(transDilg);
				DrawDialog(transDilg);
			end
			else
			begin
				TransDilg := nil;
				t2 := '^C to Cancel';
				for i := 1 to 10 do
					t2 := concat(char(205), t2, char(205));
				t2 := concat(char(27), '[22H', t2, char(13), char(10), 'Transferring:');
				for i := 1 to 30 do
					t2 := concat(t2, ' ');
				t2 := concat(t2, char(13), char(10));
				for i := 1 to 40 do
					t2 := concat(t2, ' ');
				for i := 1 to 3 do
					t2 := concat(char(13), char(10), t2);
				ProcessData(activeNode, @t2[1], length(t2));
			end;
			protCodeHand := Get1Resource('PROC', theProts^^.prots[activeProtocol].resID);
			if protCodeHand <> nil then
			begin
				DetachResource(protCodeHand);
				MoveHHi(protCodeHand);
				HLock(protCodeHand);
				if (theProts^^.prots[activeProtocol].pFlags[SENDFLOW] and myTrans.sending) or (theProts^^.prots[activeProtocol].pFlags[RECEIVEFLOW] and not myTrans.sending) then
					flowie(true)
				else
					flowie(false);
				if visibleNode = activeNode then
					DisableItem(getMHandle(mDisconnects), 0);
				if (BoardMode = User) then
				begin
					if (BoardSection = Upload) or (BoardSection = Download) then
					begin
						wasSlowDevice := false;
						if forums^^[tempInDir].dr[tempSubDir].SlowVolume then
						begin
							result := FSOpen(StringOf(sharedPath, 'Slow Files:Node ', activeNode : 0, ':', CurFil.flName), 0, TheFile);
							if result = noErr then
							begin
								wasSlowDevice := true;
								result := FSClose(TheFile);
							end;
						end;
						if wasSlowDevice then
						begin
							tems := StringOf(sharedPath, 'Slow Files:Node ', activeNode : 0, ':', CurFil.flName);
						end
						else
						begin
							if (pos(':', curFil.realFName) = 0) then
								tems := concat(forums^^[tempInDir].dr[tempSubDir].path, curFil.realFName)
							else
								tems := curFil.realFName;
						end;
						AddExtFile(tems, curFil.flName);
						if forums^^[tempInDir].dr[tempSubDir].nonMacFiles = 1 then
							extTrans^^.flags[useMacbinary] := false;
					end
					else if (BoardSection = Batch) then
					begin
						for i := 1 to fileTransit^^.numFiles do
						begin
							wasSlowDevice := false;
							if forums^^[fileTransit^^.filesGoing[i].fromDir].dr[fileTransit^^.filesGoing[i].fromSub].SlowVolume then
							begin
								result := FSOpen(StringOf(sharedPath, 'Slow Files:Node ', activeNode : 0, ':', fileTransit^^.filesGoing[i].theFile.flName), 0, TheFile);
								if result = noErr then
								begin
									wasSlowDevice := true;
									result := FSClose(TheFile);
								end;
							end;
							if wasSlowDevice then
							begin
								AddExtFile(StringOf(sharedPath, 'Slow Files:Node ', activeNode : 0, ':', fileTransit^^.filesGoing[i].theFile.flName), fileTransit^^.filesGoing[i].theFile.flName);
							end
							else
							begin
								if (pos(':', fileTransit^^.filesGoing[i].theFile.realFName) = 0) then
									AddExtFile(concat(forums^^[fileTransit^^.filesGoing[i].fromDir].dr[fileTransit^^.filesGoing[i].fromSub].path, fileTransit^^.filesGoing[i].theFile.realFName), fileTransit^^.filesGoing[i].theFile.flName)
								else
									AddExtFile(fileTransit^^.filesGoing[i].theFile.realFName, fileTransit^^.filesGoing[i].theFile.flName);
							end;
						end;
					end
					else if (BoardSection = MessUp) then
					begin
						AddExtFile(StringOf(sharedPath, 'Misc:Local Workspace ', activeNode : 0), StringOf('Local Workspace ', activeNode : 0));
					end
					else if (BoardSection = AttachFile) then
					begin
						tems := curFil.realFName;
						if (pos(':', curFil.realFName) = 0) then
							tems := concat(forums^^[tempInDir].dr[tempSubDir].path, curFil.realFName)
						else
							tems := curFil.realFName;
						AddExtFile(tems, curFil.flName);
						if curEMailRec.isAMacFile then
							extTrans^^.flags[useMacbinary] := true
						else
							extTrans^^.flags[useMacbinary] := false;
					end
					else if (BoardSection = DetachFile) then
					begin
						tems := curFil.realFName;
						if (pos(':', curFil.realFName) = 0) then
							tems := concat(forums^^[tempInDir].dr[tempSubDir].path, curFil.realFName)
						else
							tems := curFil.realFName;
						AddExtFile(tems, curFil.flName);
						if WasAttachMac then
							extTrans^^.flags[useMacbinary] := true
						else
							extTrans^^.flags[useMacbinary] := false;
					end;
				end;
				startCPS := 0;
				bUploadCompense := 0;
				lastTransError := '';
				t2 := extTrans^^.fPaths[1].fName^^;
				i := length(t2);
				t3 := '';
				while (t2[i] <> ':') and (i > 0) do
				begin
					i := i - 1;
				end;
				if t2[i] = ':' then
					t3 := copy(t2, i + 1, length(t2) - i)
				else
					t3 := t2;
				if transDilg <> nil then
				begin
					GetDItem(transDilg, 6, tempInt, aHandle, tempRect);
					SetIText(aHandle, t3);
				end
				else
				begin
					t3 := concat(char(27), '[23;15H', char(27), '[K', t3);
					ProcessData(activeNode, @t3[1], length(t3));
				end;
			end
			else
			begin
				myTrans.active := false;
				if transDilg <> nil then
					DisposDialog(transDilg);
				transDilg := nil;
				GoHome;
			end;
			lastFTUpdate := tickCount;
		end;
	end;

	function ProtocolCall (message: integer; ExtRecPtr: ptr; refcon: longint; PP: procptr): OSerr;
	inline
		$205f,  	{   movea.l (a7)+,a0  }
		$4e90;	{	jsr(a0)			   }

	function CallUtility (message: integer; extRecPtr: ptr; refCon: longint): OSerr;
		var
			utilHand: handle;
	begin
		utilHand := GetResource('PROC', 900);
		if utilHand <> nil then
		begin
			MoveHHi(utilHand);
			HLock(utilHand);
			CallUtility := ProtocolCall(message, extRecPtr, refCon, StripAddress(pointer(utilHand^)));
			HUnlock(utilHand);
		end;
	end;

	procedure ContinueTrans;
		var
			tempint, i: integer;
			temprect: rect;
			FRAGGED, stored: boolean;
			aHandle: handle;
			tempstring, ts1, ts2, t2, t3: str255;
			hhh: paramBlockRec;
			tempLong, count, kbs: longint;
	begin
		with curglobs^ do
		begin
			result := noErr;
			t3 := '';
			if myTrans.sending then
				result := ProtocolCall(DOWNLOADCALL, pointer(extTrans^), theprots^^.prots[activeProtocol].refCon, pointer(protCodeHand^))
			else
				result := ProtocolCall(UPLOADCALL, pointer(extTrans^), theprots^^.prots[activeProtocol].refCon, pointer(protCodeHand^));  {theProts^^.prots[activeProtocol].protHand}
			if extTrans^^.flags[newMBName] then
			begin
				extTrans^^.flags[newMBName] := false;
				if (BoardMode = Terminal) then
				begin
					if (transDilg <> nil) then
					begin
						SetPort(transDilg);
						GetDItem(transDilg, 6, tempInt, aHandle, tempRect);
						t2 := extTrans^^.fPaths[extTrans^^.filesDone + 1].mbName^^;
						SetIText(aHandle, t2);
					end;
				end;
				DisposHandle(handle(extTrans^^.fpaths[extTrans^^.filesDone + 1].mbName));
				extTrans^^.fpaths[extTrans^^.filesDone + 1].mbName := nil;
			end;
			if extTrans^^.flags[newError] then
			begin
				HLock(handle(extTrans^^.errorReason));
				if (transDilg <> nil) then
				begin
					GetDItem(transDilg, 9, tempInt, aHandle, tempRect);
					SetIText(aHandle, extTrans^^.errorReason^^);
				end;
				lastTransError := extTrans^^.errorReason^^;
				HUnlock(handle(extTrans^^.errorReason));
				DisposHandle(handle(extTrans^^.errorReason));
				ExtTrans^^.flags[newError] := false;
				extTrans^^.errorReason := nil;
			end;
			if extTrans^^.flags[recovering] then
			begin
				startCPS := extTrans^^.curBytesDone;
				extTrans^^.flags[recovering] := false;
			end;
			if (extTrans^^.flags[newFile]) then
			begin
				startCPS := 0;
				lastTransError := '';
				extTrans^^.flags[newFile] := false;
				if (tickCount - extTrans^^.curStartTime) > 60 then
					NumToString((extTrans^^.curBytesTotal - startCPS) div ((tickCount - extTrans^^.curStartTime) div 60), t3)
				else
					t3 := '?';
				if (BoardMode = User) then
				begin
					if (extTrans^^.filesDone < (extTrans^^.fileCount - 1)) and (BoardSection = Batch) then
					begin
						t2 := FileTransit^^.filesGoing[extTrans^^.filesDone + 2].theFile.flName;
						if (transDilg <> nil) then
						begin
							SetPort(transDilg);
							GetDItem(transDilg, 6, tempInt, aHandle, tempRect);
							SetIText(aHandle, t2);
							GetDItem(transDilg, 5, tempInt, aHandle, tempRect);
							EraseRect(temprect);
						end
						else
						begin
							t2 := concat(char(27), '[23;15H', char(27), '[K', t2);
							ProcessData(activeNode, @t2[1], length(t2));
						end;
					end;
					if (BoardSection = Upload) or (BoardSection = AttachFile) or ((BoardSection = Batch) and not (fileTransit^^.sendingBatch)) then
					begin
						if (BoardSection = Batch) then
						begin
							curFil := fileTransit^^.filesGoing[extTrans^^.filesDone + 1].theFile;
							tempinDir := fileTransit^^.filesgoing[extTrans^^.filesDone + 1].fromDir;
							tempSubDir := fileTransit^^.filesgoing[extTrans^^.filesDone + 1].fromSub;
						end;
						if (pos(':', curFil.realFName) = 0) then
							tempstring := concat(forums^^[tempinDir].dr[tempSubDir].path, curFil.realFName)
						else
							tempString := curFil.realFName;
						if (FExist(tempstring)) then
						begin
							hhh.ioCompletion := nil;
							if (pos(':', curFil.realFName) = 0) then
								tempstring := concat(forums^^[tempinDir].dr[tempSubDir].path, curFil.realFName)
							else
								tempString := curFil.realFName;
							hhh.ioNamePtr := @tempString;
							hhh.ioVRefNum := 0;
							hhh.ioFVersNum := 0;
							hhh.ioFDirIndex := 0;
							if PBGetFInfo(@hhh, false) = noErr then
							begin
								curFil.byteLen := hhh.ioFLLgLen + hhh.ioFLRLgLen;
								CurFil.FileType := hhh.ioFlFndrInfo.fdtype;
								CurFil.FileCreator := hhh.ioFlFndrInfo.fdcreator;
							end;
							stored := false;
							if OpenDirectory(tempInDir, tempSubDir) then
							begin
								if curNumFiles > 0 then
								begin
									for i := 1 to curNumFiles do
									begin
										if not stored then
										begin
											if (EqualString(curOpenDir^^[i - 1].flName, curFil.flname, false, false)) then
											begin
												curOpenDir^^[i - 1].byteLen := curFil.byteLen;
												curOpenDir^^[i - 1].fileStat := char(0);
												tempInt := curFil.byteLen div 1024;
												if tempint < 1 then
													tempInt := 1;
												stored := true;
												SaveDirectory;
											end;
										end;
									end;
								end;
							end;
							CloseDirectory;
							GetDateTime(curFil.whenUL);
							if not stored then
							begin
								FileEntry(curFil, tempinDir, tempSubDir, tempInt, 0);
								GetDateTime(curFil.whenUL);
							end;
							tempint := trunc(tempint * forums^^[tempInDir].dr[tempSubDir].UlCost);
							if (BoardSection <> AttachFile) then
							begin
								InitSystHand^^.kuploaded[activeNode] := InitSystHand^^.kuploaded[activeNode] + tempint;
								InitSystHand^^.uploadsToday[activeNode] := InitSystHand^^.uploadsToday[activeNode] + 1;
								thisUser.UploadedK := thisUser.UploadedK + tempint;
								thisUser.KBULToday := thisUser.KBULToday + tempint;
								thisUSer.NumULToday := thisUser.NumULToday + 1;
								thisUser.numUploaded := thisUser.numUploaded + 1;
								GetDateTime(InitSystHand^^.lastUL);
							end;
							GetDateTime(ForumIdx^^.lastupload[tempInDir, tempSubDir]);
							DoForumRec(true);
							DoSystRec(true);
							tempLong := tickcount - extTrans^^.curStartTime;
							GiveTime(tempLong, thisUser.xfercomp, false);
							bUploadCompense := bUploadCompense + tempLong;
							if (tickCount - extTrans^^.curStartTime) > 60 then
								NumToString((extTrans^^.curBytesTotal - startCPS) div ((tickCount - extTrans^^.curStartTime) div 60), t3)
							else
								t3 := '?';
							if (BoardSection <> AttachFile) then
								sysopLog(concat('      U/L:', theprots^^.prots[activeProtocol].ProtoName, ': ', curFil.flName, ' on ', forums^^[tempInDir].dr[tempSubDir].dirName, ' :', t3, 'cps. '), 0)
							else
								sysopLog(concat('      Attached File:', theprots^^.prots[activeProtocol].ProtoName, ': ', curFil.flName, ' :', t3, 'cps. '), 0);
						end;
					end
					else
					begin
						if (BoardSection = Download) then
						begin
							kbs := trunc((extTrans^^.curBytesTotal div 1024) * forums^^[tempInDir].dr[tempSubDir].DLCost) + 1;
							InitSystHand^^.dlsToday[activeNode] := InitSystHand^^.dlsToday[activeNode] + 1;
							InitSystHand^^.kdownloaded[activeNode] := InitSystHand^^.kdownloaded[activeNode] + kbs;
							if not forums^^[tempInDir].dr[tempSubDir].freeDir then
							begin
								if thisUser.DLCRedits >= kbs then
									thisUser.DLCredits := thisUser.DLCredits - Kbs
								else if thisUser.DLCredits > 0 then
								begin
									Kbs := Kbs - ThisUser.DLCredits;
									ThisUser.DLCredits := 0;
									thisuser.downloadedK := thisUser.downloadedK + kbs;
									thisUser.NumDLToday := thisUser.NumDLToday + 1;
									thisUser.KBDLToday := thisUser.KBDLToday + kbs;
									thisUser.numDownloaded := thisUser.numDownloaded + 1;
								end
								else
								begin
									thisuser.downloadedK := thisUser.downloadedK + kbs;
									thisUser.NumDLToday := thisUser.NumDLToday + 1;
									thisUser.KBDLToday := thisUser.KBDLToday + kbs;
									thisUser.numDownloaded := thisUser.numDownloaded + 1;
								end;
								GetDateTime(InitSystHand^^.lastDL);
							end;
							sysopLog(concat('      D/L:', theprots^^.prots[activeProtocol].ProtoName, ': ', curFil.flName, ' from ', forums^^[tempInDir].dr[tempSubDir].dirName, ':', t3, 'cps. '), 0);
						end
						else if (BoardSection = Batch) then
						begin
							Delay(120, templong);
							if not forums^^[FileTransit^^.filesGoing[extTrans^^.filesDone + 1].fromDir].dr[FileTransit^^.filesGoing[extTrans^^.filesDone + 1].fromSub].freeDir then
							begin
								kbs := (extTrans^^.curBytesTotal div 1024) + 1;
								if thisUser.DLCRedits >= kbs then
									thisUser.DLCredits := thisUser.DLCredits - Kbs
								else if thisUser.DLCredits > 0 then
								begin
									Kbs := Kbs - ThisUser.DLCredits;
									ThisUser.DLCredits := 0;
									thisuser.downloadedK := thisUser.downloadedK + kbs;
									thisUser.NumDLToday := thisUser.NumDLToday + 1;
									thisUser.KBDLToday := thisUser.KBDLToday + kbs;
									thisUser.numDownloaded := thisUser.numDownloaded + 1;
								end
								else
								begin
									thisuser.downloadedK := thisUser.downloadedK + kbs;
									thisUser.NumDLToday := thisUser.NumDLToday + 1;
									thisUser.KBDLToday := thisUser.KBDLToday + kbs;
									thisUser.numDownloaded := thisUser.numDownloaded + 1;
								end;
								InitSystHand^^.dlsToday[activeNode] := InitSystHand^^.dlsToday[activeNode] + 1;
								InitSystHand^^.kdownloaded[activeNode] := InitSystHand^^.kdownloaded[activeNode] + (extTrans^^.curBytesTotal div 1024) + 1;
								GetDateTime(InitSystHand^^.lastDL);
							end;
							sysopLog(concat('      D/L:', theprots^^.prots[activeProtocol].ProtoName, ': ', FileTransit^^.filesGoing[extTrans^^.filesDone + 1].theFile.flName, ' from ', forums^^[FileTransit^^.filesGoing[extTrans^^.filesDone + 1].fromDir].dr[FileTransit^^.filesGoing[extTrans^^.filesDone + 1].fromSub].dirName, ':', t3, 'cps. '), 0);
						end
						else if (BoardSection = DetachFile) then
						begin
							kbs := trunc((extTrans^^.curBytesTotal div 1024) * InitSystHand^^.MailDLCost) + 1;
							if not InitSystHand^^.FreeMailDL then
							begin
								if thisUser.DLCRedits >= kbs then
									thisUser.DLCredits := thisUser.DLCredits - Kbs
								else if thisUser.DLCredits > 0 then
								begin
									Kbs := Kbs - ThisUser.DLCredits;
									ThisUser.DLCredits := 0;
									thisuser.downloadedK := thisUser.downloadedK + kbs;
									thisUser.NumDLToday := thisUser.NumDLToday + 1;
									thisUser.KBDLToday := thisUser.KBDLToday + kbs;
									thisUser.numDownloaded := thisUser.numDownloaded + 1;
								end
								else
								begin
									thisuser.downloadedK := thisUser.downloadedK + kbs;
									thisUser.NumDLToday := thisUser.NumDLToday + 1;
									thisUser.KBDLToday := thisUser.KBDLToday + kbs;
									thisUser.numDownloaded := thisUser.numDownloaded + 1;
								end;
							end;
							sysopLog(concat('      Detached File:', theprots^^.prots[activeProtocol].ProtoName, ': ', curFil.flName, ':', t3, 'cps. '), 0);
						end;
						FileDLd;
					end;
				end;
			end;
			if ((tickCount - lastFTUpdate) > 80) and (lastCurBytes <> extTrans^^.curBytesDone) then
			begin
				UpdateProgress;
				lastCurBytes := extTrans^^.curBytesDone;
				lastFTUpdate := tickCount;
			end;
			lastKeyPressed := tickCount;
			if result <> noErr then
			begin
				lastKeyPressed := tickCount;
				flowie(true);
				ClearInBuf;
				if transDilg <> nil then
					DisposDialog(transDilg);
				transDilg := nil;
				if (BoardMode = User) then
				begin
					if (extTrans^^.fileCount > extTrans^^.filesDone) then
					begin
						if (BoardSection = Batch) and fileTransit^^.sendingBatch then
						begin
							sysopLog(concat('      Failed D/L(', fileTransit^^.filesGoing[extTrans^^.filesDone + 1].theFile.flName, '):', lastTransError), 0);
							InitSystHand^^.failedDLs[activeNode] := InitSystHand^^.failedDLs[activeNode] + 1;
						end
						else if (BoardSection = Download) or (BoardSection = DetachFile) then
						begin
							sysopLog(concat('      Failed D/L(', curFil.flName, '):', lastTransError), 0);
							InitSystHand^^.failedDLs[activeNode] := InitSystHand^^.failedDLs[activeNode] + 1;
						end
						else if (BoardSection = Upload) or (BoardSection = Batch) or (BoardSection = MessUp) or (BoardSection = AttachFile) then
						begin
							if (BoardSection = MessUp) then
								tempString := StringOf(sharedPath, 'Misc:Local Workspace ', activeNode : 0)
							else
							begin
								if (BoardSection = Batch) then
								begin
									curFil := fileTransit^^.filesGoing[extTrans^^.filesDone + 1].theFile;
									tempinDir := fileTransit^^.filesgoing[extTrans^^.filesDone + 1].fromDir;
									TempSubDir := fileTransit^^.filesgoing[extTrans^^.filesDone + 1].fromSub;
								end;
								if (pos(':', curFil.realFName) = 0) then
									tempstring := concat(forums^^[tempInDir].dr[tempSubDir].path, curFil.realFName)
								else
									tempString := curFil.realFName;
							end;
							fragged := FragFile(tempstring);
							if fragged and (BoardSection <> MessUp) then
							begin
								curFil.fileStat := 'F';
								stored := false;
								if OpenDirectory(tempInDir, tempSubDir) then
								begin
									if curNumFiles > 0 then
									begin
										for i := 1 to curNumFiles do
										begin
											if not stored then
											begin
												if (EqualString(curOpenDir^^[i - 1].flName, curFil.flname, false, false)) then
													stored := true;
											end;
										end;
									end;
								end;
								CloseDirectory;
								if not stored then
									FileEntry(curFil, tempinDir, tempSubDir, tempInt, 0);
								bCR;
								if (BoardSection = AttachFile) then
								begin
									curEMailRec.FileAttached := false;
									OutLine(RetInStr(124), true, 0);{A file was not attached successfully to this piece of mail.}
								end
								else
									OutLine(RetInStr(509), true, 3);	{Fragment upload received.}
								SysopLog(concat('      FRAG U/L(', curFil.flname, '):', ts2), 0);
								bCR;
								GoHome;
							end
							else
							begin
								crossInt := 10;
								ts1 := curFil.flname;
								if (BoardSection = MessUp) then
									ts1 := StringOf('Message Upload - Node ', activeNode : 0)
								else if curFil.hasExtended then
									DeleteExtDesc(curFil, tempinDir, tempSubDir);
								SysopLog(concat('      Failed U/L(', ts1, '):', lastTransError), 0);
								InitSystHand^^.failedULs[activeNode] := InitSystHand^^.failedULs[activeNode] + 1;
								if (BoardSection = AttachFile) then
								begin
									curEMailRec.FileAttached := false;
									OutLine(RetInStr(124), true, 0);{A file was not attached successfully to this piece of mail.}
								end
								else
									OutLine('Upload aborted.', true, 0);
								goHome;
							end;
						end;
					end
					else if (BoardSection = Upload) or ((BoardSection = Batch) and not (fileTransit^^.sendingBatch)) then
					begin
						bCR;
						OutLine(RetInStr(510), true, 3);	{Upload(s) completed successfully.}
						bCR;
						DLRatioStr(tempString, activeNode);
						Outline(concat(RetInStr(511), tempString), true, 3);	{Your ratio is now: }
						bCR;
						OutLine(concat(RetInStr(512), tickToTime(bUploadCompense), RetInStr(513)), true, 1);{ compensation time.}
						bCR;
						bCR;
						bCR;
						if (BoardSection = Upload) then
							GoHome;
					end
					else if (BoardSection = AttachFile) then
					begin
						bCR;
						OutLine(RetInStr(125), true, 3); {File Attached Successfully}
						bCR;
						GoHome;
					end;
				end;
				if (BoardSection = Batch) then
				begin
					FileTransit^^.numFiles := 0;
					FileTransit^^.batchTime := 0;
					FileTransit^^.batchKBytes := 0;
				end;
				myTrans.active := false;
				KillXferRec;
				if (visibleNode = activeNode) then
				begin
					if BoardMode = Terminal then
					begin
						EnableItem(getMHandle(1009), 0);
						EnableItem(getMHandle(mTerminal), 0);
					end;
					EnableItem(getMHandle(mDisconnects), 0);
				end;
				DrawMenuBar;
				DownDo := DownThree;
				BatDo := BatSix;
				DetachDo := Detach5;
				HUnlock(protCodeHand);
				DisposHandle(protCodeHand);
				protCodeHand := nil;
			end;
		end;
	end;

	procedure PrintExtended (howMuch: Integer);
		var
			curPos, leng, i: integer;
			tempString, s2: str255;
	begin
		with curglobs^ do
		begin
			s2 := '                                                   ';
			curPos := 0;
			leng := GetHandleSize(handle(curWriting));
			repeat
				tempString := '';
				while (curWriting^^[curPos] <> char(13)) and (curPos < leng) do
				begin
					tempString := concat(tempString, curWriting^^[curPos]);
					curPos := curPos + 1;
				end;
				curPos := curPos + 1;
				bCR;
				if (thisUser.TerminalType = 1) and (howMuch > 0) then
				begin
					OutLine(stringOf(char(27), '[', howMuch : 0, 'C'), false, 5);
					OutLine(tempstring, false, 5);
				end
				else if thisUser.TerminalType = 1 then
					OutLine(tempstring, false, 5)
				else if howMuch > 0 then
					OutLine(concat(copy(s2, 1, howmuch), tempstring), false, 5)
				else
					OutLine(tempString, false, 5);
			until (curPos >= (leng - 1));
		end;
	end;

	procedure DoFindDesc;
	(* We'll break this one down into several stages to avoid hogging this node's fair *)
  (* share of time. *)
		var
			ThisOK: boolean;
			tempFile: filEntryRec;
			ts, s2, s3, tempstring: str255;
			FirstLett, SecondLett: char;
			i, x, tempInt: integer;
	begin
		with curGlobs^ do
		begin
			case FDescDo of
				FDesc1: {Init the Search}
				begin
					bCR;
					Outline(RetInStr(139), true, 2);
					bCR;
					lastKeyPressed := tickCount;
					fileMask := curPrompt;
					if fileMask[length(fileMask)] = '*' then
						delete(fileMask, length(fileMask), 1);
					UprString(fileMask, true);
					flsListed := 0;
					fListedCurDir := 0;
					if (thisUser.coSysop) then
						tempDir := -1
					else
						tempDir := 0;
					tempSubDir := 0;
					if length(fileMask) > 0 then
						FDescDo := FDesc2
					else
						FDescDo := FDesc4;
				end;
				FDesc2: {Find an available Forum}
				begin
					ThisOK := false;
					tempSubDir := 0;
					while not ThisOK and (tempDir < ForumIdx^^.numForums) do
					begin
						tempDir := tempDir + 1;
						ThisOK := ForumOk(tempDir);
					end;
					if not ThisOK then
						FDescDo := FDesc4
					else
						FDescDo := FDesc3;
				end;
				FDesc3: {Find an available SubDir}
				begin
					ThisOK := false;
					while not ThisOK and (tempSubDir < forumIdx^^.NumDirs[tempDir]) do
					begin
						tempSubDir := tempSubDir + 1;
						ThisOK := SubDirOk(tempDir, tempSubDir);
					end;
					if not ThisOK then
						FDescDo := FDesc2
					else
						FDescDo := FDesc5;
				end;
				FDesc4: {Output Files Found and Exit}
				begin
					BoardAction := none;
					bCR;
					OutLine(concat(RetInStr(380), doNumber(flsListed)), true, 2);	{Files listed: }
					GoHome;
				end;
				FDesc5: {Load the current dir}
				begin
					BoardAction := repeating;
					if OpenDirectory(tempDir, tempSubDir) then
					begin
						curDirPos := 0;
						fListedCurDir := 0;
						FDescDo := FDesc6;
					end
					else
					begin
						bCR;
						OutLine(StringOf('Unable to open forum ', tempDir : 0, ' sub ', tempSubDir : 0, '.'), true, 6);
						FDescDo := FDesc3;
					end;
				end;
				FDesc6: {Search One Line Desc}
				begin
					if not aborted then
					begin
						if (curDirPos + 1 <= curNumFiles) then
						begin
							curDirPos := curDirPos + 1;
							tempFile := curOpenDir^^[curDirPos - 1];
							ts := tempFile.flDesc;
							UprString(ts, true);
							if (pos(fileMask, ts) <> 0) then
								FDescDo := FDesc9
							else if (pos(fileMask, ts) = 0) and (not thisUser.ExtDesc) then
								FDescDo := FDesc6
							else if (tempFile.hasExtended) then
								FDescDo := FDesc7
							else
								FDescDo := FDesc6;
						end
						else
							FDescDo := FDesc3;
					end
					else
						FDescDo := FDesc4;
				end;
				FDesc7: {Get The Extended Description}
				begin
					tempFile := curOpenDir^^[curDirPos - 1];
					ReadExtended(tempFile, tempDir, tempSubDir);
					FDescDo := FDesc8;
				end;
				FDesc8:  {Search Extended Description}
				begin
					ThisOK := false;
					FirstLett := Chr(Ord(fileMask[1]) + 32);
					if (length(fileMask) > 1) then
						SecondLett := Chr(Ord(fileMask[2]) + 32);
					for i := 1 to GetHandleSize(handle(curWriting)) do
					begin
						if (curWriting^^[i] = fileMask[1]) or (curWriting^^[i] = FirstLett) then
							if (length(fileMask) > 1) then
							begin
								if (curWriting^^[i + 1] = fileMask[2]) or (curWriting^^[i + 1] = SecondLett) then
								begin
									ts := '';
									for x := i to (i + (length(fileMask) - 1)) do
										if (CurWriting^^[x] >= char('a')) and (CurWriting^^[x] <= char('z')) then
											ts := concat(ts, Chr(Ord(curWriting^^[x]) - 32))
										else
											ts := concat(ts, curWriting^^[x]);
									if fileMask = ts then
									begin
										ThisOK := true;
										FDescDo := FDesc9;
										leave;
									end;
								end;
							end
							else
							begin
								ThisOK := true;
								FDescDo := FDesc9;
								leave;
							end;
					end;
					if not ThisOK then
						FDescDo := FDesc6;
				end;
				FDesc9:  {Output File to screen}
				begin
					ThisOK := false;
					tempFile := curOpenDir^^[curDirPos - 1];
					if (tempFile.flName <> '') and (tempFile.fileStat = 'F') then
					begin
						if (tempFile.uploaderNum = thisUser.userNum) or (thisUser.coSysop) then
							ThisOK := true;
					end
					else if (tempFile.flName <> '') then
						ThisOK := true;

					if ThisOK then
					begin
						fListedCurDir := fListedCurDir + 1;
						flsListed := flsListed + 1;
						if fListedCurDir = 1 then
						begin
							bCR;
							NumToString(tempSubDir, s2);
							NumToString(curNumFiles, s3);
							tempString := stringof(forumIdx^^.name[TempDir], ', ', forums^^[tempDir].dr[tempSubDir].dirName, ' - #', s2, ', ', s3, ' files');
							s2 := '';
							for i := 1 to length(tempString) do
								s2 := concat(s2, '=');
							OutLine(tempString, true, 2);
							OutLine(s2, true, 2);
							bCR;
						end;
						s3 := tempFile.flName;
						if length(S3) < forums^^[tempDir].dr[tempSubDir].fileNameLength then
							for i := length(s3) to (forums^^[tempDir].dr[tempSubDir].fileNameLength - 1) do
								s3 := concat(s3, ' ');
						if length(S3) > forums^^[tempDir].dr[tempSubDir].fileNameLength then
						begin
							s3[forums^^[tempDir].dr[tempSubDir].fileNameLength] := '*';
							s3[0] := char(forums^^[tempDir].dr[tempSubDir].fileNameLength);
						end;
						if tempFile.fileStat <> 'F' then
						begin
							tempInt := tempFile.byteLen div 1024;
							if (tempInt < 1) and (tempFile.bytelen <> 0) then
							begin
								s2 := '    1k'
							end
							else if (tempFile.byteLen = -1) then
								s2 := '   ASK'
							else
							begin
								s2 := stringOf(tempInt : 5, 'k');
							end;
						end
						else
						begin
							s2 := '  FRAG';
						end;
						outLine(s3, true, 1);
						outLine(':', false, 2);
						OutLine(s2, false, 3);
						outLine(':', false, 2);
						tempString := tempFile.flDesc;
						i := length(tempstring) + 7 + forums^^[tempDir].dr[tempSubDir].fileNameLength;
						if i > 80 then
							delete(tempstring, length(tempstring) - (i - 80), i - 80);
						OutLine(tempString, false, 5);
						if (thisUser.extendedLines > 0) and (tempFile.hasExtended) then
						begin
							ReadExtended(tempFile, tempDir, tempSubDir);
							if curWriting <> nil then
								PrintExtended(forums^^[tempDir].dr[tempSubDir].fileNameLength);
						end;
					end;
					FDescDo := FDesc6;
				end;

(*************)
				otherwise
					;
			end;
		end;
	end;


end.