{ Segments: FileTrans_1 }
unit FileTrans;

interface
	uses
		AppleTalk, ADSP, Serial, Sound, TCPTypes, Initial, InpOut4, InpOut3, FileTrans2, FileTrans3, inpOut2, InpOut, User, terminal, SystemPrefs, Message_Editor, NodePrefs, NodePrefs2;

	procedure DoUpload;
	procedure DoGFiles;
	procedure ListFil;
	procedure DoDownload;
	function GetProtMenStr: str255;
	procedure DoSort;
	procedure ReadAutoMessage;
	procedure enterLastUser;
	procedure MamaPrompt (var MaPro: str255);
	procedure OutANSItest;
	procedure doKillMail;
	procedure ScanOpenFiles;
	function isDAWindow (window: WindowPtr): BOOLEAN;
	function isAppWindow (window: WindowPtr): BOOLEAN;
	procedure AdjustCursor (mouse: Point; region: RgnHandle);
	procedure GetGlobalMouse (var mouse: Point);
	procedure DeleteFileAttachment (IsItMail: boolean; FileName: str255);

implementation

	var
		n1, n2: integer;

{$S FileTrans_1}
	function isDAWindow (window: WindowPtr): BOOLEAN;
	begin
		if window = nil then
			IsDAWindow := FALSE
		else
			IsDAWindow := (WindowPeek(window)^.windowKind < 0);
	end;


	function isAppWindow (window: WindowPtr): BOOLEAN;
	begin
		if window = nil then
			IsAppWindow := FALSE
		else
			with WindowPeek(window)^ do
				IsAppWindow := (windowKind = userKind);
	end;
	procedure GetGlobalMouse (var mouse: Point);
		var
			event: EventRecord;
	begin
		if OSEventAvail(kNoEvents, event) then
			;	{we aren't interested in any events}
		mouse := event.where;					{just the mouse position}
	end;



	procedure AdjustCursor (mouse: Point; region: RgnHandle);

{Change the cursor's shape, depending on its position. This also calculates the region}
{ where the current cursor resides (for WaitNextEvent). If the mouse is ever outside of}
{ that region, an event is generated, causing this routine to be called. This}
{ allows us to change the region to the region the mouse is currently in. If}
{ there is more to the event than just “the mouse moved”, we get called before the}
{ event is processed to make sure the cursor is the right one. In any (ahem) event,}
{ this is called again before we fall back into WNE.}
		var
			window: WindowPtr;
			arrowRgn: RgnHandle;
			iBeamRgn: RgnHandle;
			crossHairRgn: rgnHandle;
			iBeamRect: Rect;
			windI: integer;
	begin
		window := FrontWindow;	{we only adjust the cursor when we are in front}
		if (not gInBackground) and (not IsDAWindow(window)) then
		begin
		{calculate regions for different cursor shapes}
			arrowRgn := NewRgn;
			iBeamRgn := NewRgn;

		{start with a big, big rectangular region}
			SetRectRgn(arrowRgn, -32767, -32767, 32765, 32765);

		{calculate iBeamRgn}
			windI := isMyTextWindow(window);
			if IsAppWindow(window) and (windI >= 0) and textWinds[windI].editable then
			begin
				with textWinds[windI] do
				begin
					iBeamRect := t^^.viewRect;
					SetPort(w);					{make a global version of the viewRect}
					with iBeamRect do
					begin
						LocalToGlobal(topLeft);
						LocalToGlobal(botRight);
					end;
					RectRgn(iBeamRgn, iBeamRect);
					with w^.portBits.bounds do
						SetOrigin(-left, -top);
					SectRgn(iBeamRgn, w^.visRgn, iBeamRgn);
					SetOrigin(0, 0);
				end;
			end;
			windI := ismyBBSwindow(window);
			if isAppWindow(window) and (windI >= 1) then
			begin
				iBeamRect := gBBSwindows[windI]^.ansiRect;
				SetPort(window);
				with iBeamRect do
				begin
					LocalToGlobal(topLeft);
					LocalToGlobal(botRight);
				end;
				RectRgn(iBeamRgn, iBeamRect);
				with window^.portBits.bounds do
					SetOrigin(-left, -top);
				SetOrigin(0, 0);
			end;

		{subtract other regions from arrowRgn}
			DiffRgn(arrowRgn, iBeamRgn, arrowRgn);

		{change the cursor and the region parameter}
			if PtInRgn(mouse, iBeamRgn) then
			begin
				SetCursor(GetCursor(iBeamCursor)^^);
				CopyRgn(iBeamRgn, region);
			end
			else
			begin
				SetCursor(arrow);
				CopyRgn(arrowRgn, region);
			end;

		{get rid of our local regions}
			DisposeRgn(arrowRgn);
			DisposeRgn(iBeamRgn);
		end;
	end; {AdjustCursor}


	procedure ScanOpenFiles;
		var
			myFCBPBRec: FCBPBRec;
			t1: str255;
	begin
		with myFCBPBRec do
		begin
			ioCompletion := nil;
			ioNamePtr := @t1;
			ioVRefNum := 0;
			ioRefNum := 0;
			ioFCBIndx := 1;
		end;
		repeat
			result := PBGetFCBInfo(@myFCbPBRec, false);
			myFCbPBRec.ioFCBIndx := myFCbPBRec.ioFCBIndx + 1;
		until result <> noerr;
	end;

	procedure DeleteFileAttachment (IsItMail: boolean; FileName: str255);
		var
			i: integer;
			tempString: str255;
			printMail: EMailRec;
	begin
		with curGlobs^ do
		begin
			AttachFName := FileName;
			if IsItMail then
				tempString := 'Mail Attachments'
			else
				tempString := 'Message Attachments';
			for i := 1 to forumIdx^^.numDirs[0] do
				if (forums^^[0].dr[i].DirName = tempString) then
					tempSubDir := i;
			tempInDir := 0;

			if OpenDirectory(tempInDir, tempSubDir) then
			begin
				curDirPos := 0;
				allDirSearch := false;
				descSearch := false;
				fileMask := concat(AttachFName, '*');

				GetNextFile(tempInDir, tempSubDir, fileMask, curDirPos, curFil, 0);
				if curFil.flName <> '' then
				begin
					RemoveIt;
					deleteExtDesc(curFil, tempInDir, tempSubDir);
					if (pos(':', curFil.realFName) = 0) then
						tempString := concat(forums^^[tempInDir].dr[tempSubDir].path, curFil.realFName)
					else
						tempString := curFil.realFName;
					result := FSDelete(tempString, 0);
				end
				else
				begin
					if enteredPass2 <> 'Midnight_Turnover' then
						OutLine(RetInStr(127), true, 1); {Attached file not found.}
					Exit(DeleteFileAttachment);
				end;
			end
			else
			begin
				if enteredPass2 <> 'Midnight_Turnover' then
					OutLine(RetInStr(59), true, 0);
			end;
			CloseDirectory;
		end;
	end;

	procedure FindEmailKill;
		var
			i: integer;
			numOfEm: integer;
	begin
		with curGlobs^ do
		begin
			if myEmailList <> nil then
				SetHandleSize(handle(myEmailList), 0)
			else
				myEmailList := intListHand(NewHandle(0));
			HNoPurge(handle(myEmailList));
			if (theEmail <> nil) and (availEmails > 0) then
			begin
				numOfEm := 0;
				for i := 1 to availEmails do
				begin
					if (theEmail^^[i - 1].fromUser = thisUser.userNum) and (theEmail^^[i - 1].MType = 1) then
					begin
						numOfEm := numOfEm + 1;
						SetHandleSize(handle(myEmailList), getHandleSize(handle(myEmailList)) + 2);
						myEmailList^^[numOfEm - 1] := i - 1;
					end;
				end;
			end;
		end;
	end;

	procedure doKillMail;
		var
			t1: str255;
			templong: longint;
			totEm: integer;
			printEmail: emailrec;
	begin
		with curglobs^ do
		begin
			case KillDo of
				KillOne: 
				begin
					bCR;
					OutLine('A) ', true, 2);
					OutLine('Delete mail you''ve sent.', false, 1);
					OutLine('B) ', true, 2);
					OutLine('Delete messages you''ve posted in this conference.', false, 1);
					OutLine('Q) ', true, 2);
					OutLine('Quit.', false, 1);
					bCR;
					bCR;
					LettersPrompt('Choice [A, B, Q]: ', 'ABQ', 1, true, false, true, char(0));
					KillDo := KillSix;
				end;
				KillTwo: 
				begin
					FindEmailKill;
					totEm := GetHandleSize(handle(myEmailList)) div 2;
					atEmail := 0;
					if totEm > 0 then
					begin
						if curPrompt = 'Y' then
						begin
							atEmail := totEm - 1;
							crossInt3 := 1;
						end
						else
						begin
							atEmail := 0;
							crossInt3 := -1;
						end;
						KillDo := KillThree;
					end
					else
					begin
						OutLine('No mail.', true, 0);
						goHome;
					end;
				end;
				KillThree: 
				begin
					FindEmailKill;
					printEmail := theEmail^^[myEmailList^^[atEmail]];
					bCR;
					NumToString(printEmail.toUser, t1);
					if not printEmail.anonyTo then
						OutLine(concat('To   : ', myUsers^^[printEmail.toUser - 1].Uname, ' #', t1), true, 0)
					else
						OutLine('To   : >>UNKNOWN<<', true, 0);
					OutLine(concat('Title: ', printEmail.title), true, 0);
					getDateTime(templong);
					templong := (tempLong - printEmail.dateSent) div 60 div 60 div 24;
					NumToString(templong, t1);
					OutLine(concat('Sent : ', t1, ' days ago.'), true, 0);
					isMM := false;
					if printEMail.multimail then
						isMM := true;
					WasAttach := false;
					if printEMail.FileAttached then
					begin
						WasAttach := true;
						OutLine(concat('FILE ATTACHMENT: ', printEMail.FileName), true, 0);
					end;
					bCR;
					bCR;
					LettersPrompt(RetInStr(357), 'RDNQ', 1, true, false, true, char(0));	{R:ead, D:elete, N:ext, Q:uit : }
					KillDo := KillFour;
				end;
				KillFour: 
				begin
					if length(curprompt) > 0 then
					begin
						case curPrompt[1] of
							'Q': 
								GoHome;
							'D': 
							begin
								FindEmailKill;
								if (WasAttach) and (not isMM) then
									DeleteFileAttachment(true, theEMail^^[myEmailList^^[atEMail]].FileName);
								DeleteMail(myEmailList^^[atEmail]);
								OutLine(RetInStr(622), true, 0);{Mail deleted.}
								SysopLog('      Deleted mail.', 0);
								FindEmailKill;
								totEm := GetHandleSize(handle(myEmailList)) div 2;
								if totEm > 0 then
								begin
									if crossInt3 < 0 then
										atEmail := atEmail + 1
									else
										atEmail := atEmail - 1;
									KillDo := KillThree;
									if (atEmail < 0) or (atEmail > totEm - 1) then
										GoHome;
								end
								else
									GoHome;
							end;
							'N': 
							begin
								FindEmailKill;
								totEm := GetHandleSize(handle(myEmailList)) div 2;
								if crossInt3 < 0 then
									atEmail := atEmail + 1
								else
									atEmail := atEmail - 1;
								KillDo := KillThree;
								if (atEmail < 0) or (atEmail > totEm - 1) then
									GoHome;
							end;
							'R': 
							begin
								if textHnd <> nil then
								begin
									disposHandle(handle(textHnd));
									texthnd := nil;
								end;
								FindEmailKill;
								Outline(concat('Title: ', theEmail^^[myEmailList^^[atEmail]].title), true, 0);
								bCR;
								textHnd := textHand(ReadMessage(theEmail^^[myEmailList^^[atEmail]].storedAs, 0, 0));
								if textHnd <> nil then
								begin
									curtextPos := 0;
									OpenTextSize := GethandleSize(handle(textHnd));
									BoardAction := ListText;
									ListTextFile;
								end
								else
									OutLine('Message not found.', true, 0);
								KillDo := KillFive;
							end;
							otherwise
								KillDo := KillThree;
						end;
					end
					else
						KillDo := KillThree;
				end;
				KillFive: 
				begin
					bCR;
					bCR;
					LettersPrompt(RetInStr(357), 'RDNQ', 1, true, false, true, char(0));	{R:ead, D:elete, N:ext, Q:uit : }
					KillDo := KillFour;
				end;
				KillSix: 
				begin
					if (curPrompt = '') or (curPrompt = 'Q') then
						GoHome
					else if (curPrompt = 'A') then
					begin
						bCR;
						YesNoQuestion(RetInStr(653), true);{List mail starting at most recent? }
						KillDo := KillTwo;
					end
					else
					begin
						HelpNum := 15;
						if (MForumOk(inForum)) and (MForum^^[inForum].NumConferences >= inConf) then
						begin
							BoardSection := Rmv;
							RmvDo := RmvOne;
						end
						else
						begin
							OutLine(RetInStr(249), true, 0);	{Sub not available.}
							GoHome;
						end;
					end;
				end;
				otherwise
			end;
		end;
	end;

	procedure OutANSItest;
	begin
		ansiCode('0;34;3m');
		OutLine('TEST', false, -1);
		ansiCode('C');
		ansiCode('0;30;45m');
		OutLine('TEST', false, -1);
		ansiCode('C');
		ansiCode('0;1;31;44m');
		OutLine('TEST', false, -1);
		ansiCode('C');
		ansiCode('0;32;7m');
		OutLine('TEST', false, -1);
		ansiCode('C');
		ansiCode('0;1;5;33;46m');
		OutLine('TEST', false, -1);
		ansiCode('C');
		ansiCode('0;4m');
		Outline('TEST', false, -1);
		ansiCode('0m');
	end;


	procedure MamaPrompt (var MaPro: str255);
		var
			tempString, tempString2, tempString3: str255;
			tb2: boolean;
	begin
		with curglobs^ do
		begin
			if not inTransfer then
			begin
				HelpNum := 1;
				MaPro := RetInStr(358);	{[] No Subs Available :}
				displayConf := FigureDisplayConf(inForum, inConf);
				if MForumOk(inForum) then
				begin
					if MForum^^[inForum].NumConferences >= inConf then
					begin
						tb2 := true;
						if MConferenceOk(inForum, inConf) then
							tb2 := true
						else
							tb2 := false;
						if tb2 then
						begin
							NumToString(displayConf, tempString);
							tempString3 := MConference[inForum]^^[inConf].Name;
							maPro := concat('[', tempString, '] [', tempString3, '] :');
						end;
					end;
				end;
			end
			else
			begin
				HelpNum := 2;
				MaPro := RetInStr(623);{() No Dirs Available :}
				if ForumIdx^^.numDirs[InRealDir] >= inRealSubDir then
				begin
					tb2 := true;
					if forums^^[InRealDir].dr[inRealSubDir].restriction <> char(0) then
						if thisUser.AccessLetter[(byte(forums^^[InRealDir].dr[inRealSubDir].restriction) - byte(64))] then
							tb2 := true
						else
							tb2 := false;
					if tb2 and (forums^^[InRealDir].dr[inRealSubDir].minDSL <= thisUser.DSL) and (ageOk(-1, forums^^[InRealDir].dr[inRealSubDir].minAge)) then
						maPro := stringOf('[', InSubDir : 0, '] [', forums^^[InRealDir].dr[InRealSubDir].DirName, '] :');
				end;
			end;
		end;
	end;

	function GFileOk (Which: integer): boolean;
		var
			b: boolean;
	begin
		with curGlobs^ do
		begin
			if Which <= intGFileRec^^.numSecs then
			begin
				b := true;
				if intGFileRec^^.sections[Which].restrict <> char(0) then
					if thisUser.AccessLetter[(byte(intGFileRec^^.sections[Which].restrict) - byte(64))] then
						b := true
					else
						b := false;
				if b and (intGFileRec^^.sections[Which].minSL <= thisUser.SL) and (ageOk(-1, intGFileRec^^.sections[Which].minAge)) then
					GFileOk := True
				else
					GFileOk := False;
			end
			else
				GFileOk := false;
		end;
	end;

	procedure PrintGFileSections (var AvailSec: integer);
		var
			i, x, y, z, NumSecs: integer;
			tempString, BColor, YColor: str255;
			tb2: boolean;
			TheList: array[1..99] of string[47];
	begin
		with curGlobs^ do
		begin
			helpNum := 34;
			OutLine(RetInStr(359), true, 0);	{G-File sections available:}
			bCR;
			if (thisUser.TerminalType = 1) then
			begin
				DecodeM(1, gBBSwindows[activeNode]^.bufStyle, BColor);
				DecodeM(2, gBBSwindows[activeNode]^.bufStyle, YColor);
			end
			else
			begin
				BColor := char(0);
				YColor := char(0);
			end;
			if (thisUser.columns) and (intGFileRec^^.numSecs > 5) then
			begin
				x := 0;
				y := -1;
				z := 0;
				for i := 1 to intGFileRec^^.numSecs do
					if GFileOk(i) then
						x := x + 1;
				NumSecs := x;
				if (x < 99) then
					TheList[x + 1] := char(0);
				if (not odd(x)) then
					x := x - 1;
				for i := 1 to intGFileRec^^.numSecs do
					if GFileOk(i) then
					begin
						if y >= x then
							y := 0;
						y := y + 2;
						z := z + 1;
						if z < 10 then
							TheList[y] := StringOf(' ', YColor, z : 0, '. ', BColor, intGFileRec^^.sections[i].secName, '                                                ')
						else
							TheList[y] := stringOf(YColor, z : 0, '. ', BColor, intGFileRec^^.sections[i].secName, '                                                ');
						if (thisUser.TerminalType = 0) or (not thisUser.ColorTerminal) then
							TheList[y][0] := char(39);
					end;
				z := 1;
				x := x + 1;
				repeat
					OutLine(concat(TheList[z], '  ', TheList[z + 1]), true, -1);
					z := z + 2;
				until z >= x;
				if odd(x) then
					OutLine(TheList[x], true, -1)
			end
			else
			begin
				x := 0;
				for i := 1 to intGFileRec^^.numSecs do
					if GFileOk(i) then
					begin
						x := x + 1;
						OutLine(StringOf(x : 2, '. '), true, 2);
						OutLine(intGFileRec^^.sections[i].secName, false, 1);
					end;
				NumSecs := x;
			end;
			AvailSec := NumSecs;
		end;
	end;

	procedure PrintGFileFiles;
		var
			i, x, y, z, index: integer;
			tempString, BColor, YColor: str255;
			tb2: boolean;
			TheList: array[1..99] of string[47];
			Holder: array[1..99] of string[31];
			myCPB: CInfoPBRec;
			myHPB: HParamBlockRec;
			fName: str255;
	begin
		with curGlobs^ do
		begin
			fName := concat(InitSystHand^^.GFilePath, intGFileRec^^.sections[crossInt].secName, ':');
			myHPB.ioCompletion := nil;
			myHPB.ioNamePtr := @fName;
			myHPB.ioVRefNum := 0;
			myHPB.ioVolIndex := -1;
			result := PBHGetVInfo(@myHPB, false);
			fName := concat(InitSystHand^^.GFilePath, intGFileRec^^.sections[crossInt].secName, ':');
			myCPB.ioCompletion := nil;
			myCPB.ioNamePtr := @fname;
			myCPB.ioVRefNum := myHPB.ioVRefNum;
			myCPB.ioFDirIndex := 0;
			result := PBGetCatInfo(@myCPB, false);
			myCPB.ioNamePtr := @fName;
			crossLong := myCPB.ioDrDirID;
			crossInt2 := myHPB.ioVRefNum;
			index := 1;
			n2 := 0;
			repeat
				FName := '';
				myCPB.ioFDirIndex := index;
				myCPB.ioDrDirID := crossLong;
				myCPB.ioVrefNum := crossInt2;
				result := PBGetCatInfo(@myCPB, FALSE);
				if result = noErr then
				begin
					if index = 99 then
						result := 1;
					n2 := n2 + 1;
					Holder[index] := fName;
				end;
				index := index + 1;
			until (result <> noErr);

			x := n2;
			bCR;
			OutLine(concat(RetInStr(363), intGFileRec^^.sections[crossInt].secName, ':'), true, 0);	{G-Files in }
			bCR;
			if (thisUser.TerminalType = 1) then
			begin
				DecodeM(1, gBBSwindows[activeNode]^.bufStyle, BColor);
				DecodeM(2, gBBSwindows[activeNode]^.bufStyle, YColor);
			end
			else
			begin
				BColor := char(0);
				YColor := char(0);
			end;
			if (thisUser.columns) and (index > 5) then
			begin
				y := -1;
				z := 0;
				if (x < 99) then
					TheList[x + 1] := char(0);
				if (not odd(x)) then
					x := x - 1;
				for i := 1 to n2 do
				begin
					if y >= x then
						y := 0;
					y := y + 2;
					z := z + 1;
					if z < 10 then
						TheList[y] := StringOf(' ', YColor, z : 0, '. ', BColor, Holder[i], '                                                ')
					else
						TheList[y] := stringOf(YColor, z : 0, '. ', BColor, Holder[i], '                                                ');
					if (thisUser.TerminalType = 0) or (not thisUser.ColorTerminal) then
						TheList[y][0] := char(39);
				end;
				z := 1;
				x := x + 1;
				repeat
					OutLine(concat(TheList[z], '  ', TheList[z + 1]), true, -1);
					z := z + 2;
				until z >= x;
				if odd(x) then
					OutLine(TheList[x], true, -1);
			end
			else
			begin
				x := 0;
				for i := 1 to n2 do
				begin
					x := x + 1;
					OutLine(StringOf(x : 2, '. '), true, 2);
					OutLine(Holder[i], false, 1);
				end;
			end;
		end;
	end;

	procedure DoGFiles;
		var
			i, index: integer;
			t1: str255;
			tl: longint;
			tb2: Boolean;
			fName: str255;
			myCPB: CInfoPBRec;
	begin
		with curglobs^ do
		begin
			case GFileDo of
				G1: 
				begin
					if intGFileRec^^.numSecs > 0 then
					begin
						PrintGFileSections(n1);
						GFileDo := G2;
					end
					else
					begin
						OutLine(RetInStr(360), true, 0);	{No G-File sections available.}
						GoHome;
					end;
				end;
				G2: 
				begin
					bCR;
					bCR;
					NumbersPrompt(RetInStr(361), 'Q? ', n1, 1);	{Which section (Q=Quit) ? }
					GFileDo := G3;
				end;
				G3: 
				begin
					if curPrompt = '?' then
						GFileDo := G1
					else if (length(curPrompt) > 0) and (curprompt <> 'Q') then
					begin
						StringToNum(curprompt, tl);
						i := 1;
						n2 := 0;
						while (i <= intGFileRec^^.numSecs) and (n2 <> tl) do
						begin
							tb2 := true;
							if intGFileRec^^.sections[i].restrict <> char(0) then
								if thisUser.AccessLetter[(byte(intGFileRec^^.sections[i].restrict) - byte(64))] then
									tb2 := true
								else
									tb2 := false;
							if tb2 and (intGFileRec^^.sections[i].minSL <= thisUser.SL) and (ageOk(-1, intGFileRec^^.sections[i].minAge)) then
								n2 := n2 + 1;
							i := i + 1;
						end;
						tl := i - 1;
						if (tl > 0) and (tl <= intGFileRec^^.numSecs) and (intGFileRec^^.sections[tl].minSL <= thisUser.SL) and (ageOk(-1, intGFileRec^^.sections[tl].minAge)) then
						begin
							crossInt := tl;
							GFileDo := G4;
						end
						else
						begin
							GFileDo := G2;
							OutLine(RetInStr(362), true, 0);	{Invalid section.}
						end;
					end
					else
					begin
						GoHome;
					end;
				end;
				G4: 
				begin
					PrintGFileFiles;
					GFileDo := G5;
				end;
				G5: 
				begin
					bCR;
					bCR;
					NumbersPrompt(RetInStr(364), 'Q?', n2, 1);	{Which G-File (Q=Quit) ? }
					GFileDo := G6;
				end;
				G6: 
				begin
					if curprompt = '?' then
						GFileDO := G4
					else if (curprompt <> '') and (curprompt <> 'Q') then
					begin
						GFileDo := G5;
						StringToNum(curPrompt, tl);
						index := tl;
						if (index > 0) and (index < 100) then
						begin
							myCPB.ioCompletion := nil;
							myCPB.ioNamePtr := @fName;
							myCPB.ioFDirIndex := index;
							myCPB.ioDrDirID := crossLong;
							myCPB.ioVrefNum := crossInt2;
							result := PBGetCatInfo(@myCPB, FALSE);
							if result = noErr then
							begin
								if readTextFile(concat(InitSystHand^^.GFilePath, intGFileRec^^.sections[crossInt].secName, ':', fName), 2, false) then
								begin
									BoardAction := ListText;
									noPause := false;
								end
								else
									OutLine('File not found.', true, 0);
							end;
						end;
					end
					else
						GFileDo := G1;
				end;
				otherwise
			end;
		end;
	end;

	procedure enterLastUser;
		var
			t2, t1, tempString, tempString2: str255;
			templong, tl2, tl3: longint;
			tempDate: DateTimeRec;
			i: integer;
			luRef, luCount: integer;
			luText: CharsHandle;
	begin
		with curglobs^ do
		begin
			if thisUser.userNum > 1 then
			begin
				LUText := nil;
				t1 := concat(sharedpath, 'Misc:Last Users');
				result := FSOpen(t1, 0, luRef);
				if (result <> noErr) then
				begin
					result := Create(t1, 0, 'HRMS', 'DATA');
					result := FSOpen(t1, 0, luRef);
					t1 := '';
					t2 := '0: ';
					t2[3] := char(13);
					for i := 1 to 8 do
						t1 := concat(t2, t1);
					templong := length(t1);
					result := FSWrite(luref, templong, @t1[1]);
					result := SetFPos(luref, fsFromStart, 0);
				end;
				if result = noErr then
				begin
					LUcount := 0;
					result := GetEOF(luRef, tempLong);
					LUtext := CharsHandle(NewHandle(tempLong));
					HLock(handle(LUtext));
					result := FSRead(luRef, tempLong, pointer(LUtext^));
					repeat
						LUcount := LUcount + 1;
					until (LUtext^^[LUcount] = char(13)) or (LUcount = tempLong);
					GetTime(tempDate);
					NumToString(tempDate.hour, tempString2);
					tempString := '';
					if length(tempString2) = 1 then
						tempstring2 := concat('0', tempstring2);
					tempString := concat(tempString, ' ', tempString2, ':');
					NumToString(tempDate.minute, tempString2);
					if length(tempString2) = 1 then
						tempstring2 := concat('0', tempstring2);
					tempString := concat(tempString, tempString2, ':');
					NumToString(tempDate.second, tempString2);
					if length(tempString2) = 1 then
						tempstring2 := concat('0', tempstring2);
					tempString := StringOf(callno : 6, ' ', tempString, tempString2, '  ');
					tempString2 := stringOf(copy(thisUser.UserName, 1, 22));
					tempString := concat(tempString, StringOf(activeNode : 2, '  ', thisUser.OnToday : 2, '  ', thisUser.UserNum : 4, '  '));
					tempString := concat(tempString, tempString2);
					tempString := StringOf(tempString, ' ' : (27 - length(tempString2)));
					if currentBaud > 0 then
						tempString2 := curBaudNote
					else
						tempString2 := 'KB';
					tempString := StringOf(tempString, tempString2, char(13));
					result := SetFPos(luRef, fsFromStart, 0);
					tl3 := tempLong - (LUcount + 1);
					result := FSWrite(luRef, tl3, pointer(ord4(LUtext^) + (LUcount + 1)));
					tl2 := length(tempString);
					result := FSWrite(luRef, tl2, pointer(ord4(@tempstring) + 1));
					result := SetEOF(luRef, tl3 + tl2);
					result := FSClose(luRef);
					DisposHandle(handle(LUText));
					result := FSOpen(concat(sharedPath, 'Misc:Brief Log'), 0, luRef);
					if result = noErr then
					begin
						result := GetEOF(luRef, tempLong);
						result := SetFPos(luRef, fsFromLEOF, 0);
						result := FSWrite(luRef, tl2, pointer(ord4(@tempstring) + 1));
						result := FSClose(luRef);
					end;
				end;
			end;
		end;
	end;

	procedure ReadAutoMessage;
		var
			tempString, tempString2: str255;
			result: OSerr;
			tempInt, AutoRef: integer;
	begin
		with curglobs^ do
		begin
			if InitSystHand^^.AnonyAuto and thisUser.CantReadAnon then
				tempString := '>UNKNOWN<'
			else
			begin
				NumToString(InitSystHand^^.anonyUser, tempString2);
				if FindUser(tempString2, tempUser) then
				begin
					NumToString(tempUser.UserNum, tempString2);
					tempString := concat(tempUser.UserName, ' #', tempString2);
				end
				else
					tempString := '>>>USER NOT FOUND<<<';
			end;
			if InitSystHand^^.AnonyAuto and not thisUser.CantReadAnon then
				tempString := concat('<<< ', tempString, ' >>>');
			OutLine(concat(RetInStr(365), tempString), false, 0);	{Auto message by: }
			bCR;
			bCR;
			if ReadTextFile('Misc:Auto Message', 2, true) then
			begin
				if thisUser.TerminalType = 1 then
					noPause := true;
				boardAction := ListText;
				listTextFile;
			end
			else
				OutLine(RetInStr(366), true, 0);	{No auto-message.}
		end;
	end;

	function NumFilesinDir (dirNum, dirSub: integer): integer;
		var
			templong: longInt;
			tempRef: integer;
			result: OSerr;
			tempString: str255;
	begin
		NumToString(dirNum, tempString);
		result := FSOpen(concat(InitSystHand^^.DataPath, forumIdx^^.name[dirNum], ':', forums^^[dirNum].dr[dirSub].dirname), 0, tempRef);
		if result = noErr then
		begin
			result := GetEOF(tempRef, tempLong);
			result := FSClose(tempRef);
			numFilesinDir := tempLong div SizeOf(filEntryRec);
		end
		else
			NumFilesInDir := 0;
	end;


	procedure ListFil;
		var
			tempInt, i: integer;
{tempFile: filEntryRec;}
			tempString, s2, s3, t5, t6: Str255;
			tb2: boolean;
			s26: string[26];
			s31: string[31];
	begin
		with curglobs^ do
		begin
			case ListDo of
				ListOne: 
				begin
					tb2 := true;
					if forums^^[inRealDir].dr[InRealSubDir].restriction <> char(0) then
						if thisUser.AccessLetter[(byte(forums^^[inRealDir].dr[InRealSubDir].restriction) - byte(64))] then
							tb2 := true
						else
							tb2 := false;
					if tb2 and (thisUser.DSL >= forums^^[inRealDir].dr[InRealSubDir].minDSL) and (ageOk(-1, forums^^[inRealDir].dr[InRealSubDir].minAge)) then
					begin
						CloseDirectory;
						bCR;
						HelpNum := 9;
						LettersPrompt(RetInStr(274), '', forums^^[inRealDir].dr[InRealSubDir].fileNameLength, false, false, false, char(0));{Enter full or partial filename: }
						ListDo := ListTwo;
						inNScan := false;
					end
					else
					begin
						OutLine(RetInStr(120), true, 0);
						GoHome;
					end;
				end;
				ListTwo: 
				begin
					UprString(curPrompt, true);
					fileMask := curPrompt;
					tempDir := inRealDir;
					tempSubDir := InRealSubDir;
					ListDo := ListThree;
					allDirSearch := false;
					descSearch := false;
					flsListed := 0;
				end;
				ListThree: 
				begin
					ListDo := ListFour;
					curDirPos := 0;
					if (inNScan) and (forums^^[tempDir].dr[tempSubDir].mode = 1) then
					begin
						if OpenDirectory(tempDir, tempSubDir) then
						begin
							curTextPos := 0;
							fListedCurDir := 0;
						end;
					end
					else if ((InNScan) and ((forumidx^^.lastupload[tempDir, tempSubDir] < lastFScan) or (forumidx^^.lastupload[tempDir, tempSubDir] = 0) or (forums^^[tempDir].dr[tempSubDir].mode = -1))) then
					begin
						if (not allDirSearch) or (curtextPos = -100) then
						begin
							bCR;
							OutLine(concat(RetInStr(380), doNumber(flsListed)), true, 2);	{Files listed: }
							inNScan := false;
							GoHome;
						end
						else
						begin
							tb2 := false;
							repeat
								while not tb2 and (tempSubDir < forumIdx^^.NumDirs[tempDir]) do
								begin
									tempSubDir := tempSubDir + 1;
									tb2 := SubDirOk(tempDir, tempSubDir);
								end;
								while not tb2 and (tempDir < ForumIdx^^.numForums) do
								begin
									tempDir := tempDir + 1;
									tb2 := ForumOk(tempDir);
									tempSubDir := 0;
								end;
								if tempSubDir = 0 then
									tb2 := false;
							until (tb2) or (tempDir >= ForumIdx^^.numForums);
							if tb2 and (tempDir < ForumIdx^^.numforums) then
							begin
								ListDo := ListThree;
							end
							else
							begin
								bCR;
								OutLine(concat(RetInStr(380), doNumber(flsListed)), true, 2);	{Files listed: }
								inNScan := false;
								GoHome;
							end;
						end
					end
					else if OpenDirectory(tempDir, tempSubDir) then
					begin
						curTextPos := 0;
						fListedCurDir := 0;
					end;
				end;
				ListEight: 
				begin
					ListDo := ListFour;
					if (curFil.flName <> '') then
					begin
						if fListedCurDir = 1 then
						begin
							bCR;
							NumToString(tempSubDir, s2);
							NumToString(curNumFiles, s3);
							tempString := stringof(forumIdx^^.name[TempDir], ', ', forums^^[tempDir].dr[tempSubDir].dirName, ' - #', s2, ', ', s3, ' files');
							S2 := '';
							for i := 1 to length(tempString) do
								s2 := concat(s2, '=');
							OutLine(tempString, true, 2);
							OutLine(s2, true, 2);
							bCR;
						end;
						s3 := curFil.flName;
						if length(S3) < forums^^[tempDir].dr[tempSubDir].fileNameLength then
							for i := length(s3) to (forums^^[tempDir].dr[tempSubDir].fileNameLength - 1) do
								s3 := concat(s3, ' ');
						if length(S3) > forums^^[tempDir].dr[tempSubDir].fileNameLength then
						begin
							s3[forums^^[tempDir].dr[tempSubDir].fileNameLength] := '*';
							s3[0] := char(forums^^[tempDir].dr[tempSubDir].fileNameLength);
						end;
						if curFil.fileStat <> 'F' then
						begin
							tempInt := curFil.byteLen div 1024;
							if (tempInt < 1) and (curFil.bytelen <> 0) then
							begin
								s2 := '    1k'
							end
							else if (curFil.byteLen = -1) then
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
						tempString := curFil.flDesc;
						i := length(tempstring) + 7 + forums^^[tempDir].dr[tempSubDir].fileNameLength;
						if i > 80 then
							delete(tempstring, length(tempstring) - (i - 80), i - 80);
						OutLine(tempString, false, 5);
						if (thisUser.extendedLines > 0) and (curFil.hasExtended) then
						begin
							ReadExtended(curFil, tempDir, tempSubDir);
							if curWriting <> nil then
							begin
								PrintExtended(forums^^[tempDir].dr[tempSubDir].fileNameLength);
							end;
						end;
					end
					else
					begin
						if (not allDirSearch) or (curtextPos = -100) then
						begin
							bCR;
							OutLine(concat(RetInStr(380), doNumber(flsListed)), true, 2);	{Files listed: }
							inNScan := false;
							GoHome;
						end
						else
						begin
							tb2 := false;
							while not tb2 and (tempSubDir < forumIdx^^.NumDirs[tempDir]) do
							begin
								tempSubDir := tempSubDir + 1;
								tb2 := SubDirOk(tempDir, tempSubDir);
							end;
							while not tb2 and (tempDir < ForumIdx^^.numForums) do
							begin
								tempDir := tempDir + 1;
								tb2 := ForumOk(tempDir);
								tempSubDir := 1;
							end;
							if tb2 and (tempDir < ForumIdx^^.numforums) then
							begin
								ListDo := ListThree;
							end
							else
							begin
								bCR;
								OutLine(concat(RetInStr(380), doNumber(flsListed)), true, 2);	{Files listed: }
								inNScan := false;
								GoHome;
							end;
						end;
					end;
				end;
				ListFour: 
				begin
					BoardAction := repeating;
					if (myBlocker.ioResult <> 1) or (curTextPos = -100) then
					begin
						if not inNScan then
							GetNextFile(tempDir, tempSubDir, fileMask, curDirPos, curFil, 0)
						else
						begin
							if forums^^[tempDir].dr[tempSubDir].mode = 0 then
								GetNextFile(tempDir, tempSubDir, fileMask, curDirPos, curFil, lastFScan)
							else if forums^^[tempDir].dr[tempSubDir].mode = -1 then
								curFil.flName := ''
							else
								GetNextFile(tempDir, tempSubDir, fileMask, curDirPos, curFil, 0);
						end;
						if (curFil.flName <> '') then
						begin
							fListedCurDir := fListedCurDir + 1;
							flsListed := flsListed + 1;
							if fListedCurDir = 1 then
								if (thisUser.TransHeader = TransOn) and (inNScan) then
								begin
									s26 := forums^^[TempDir].dr[tempSubDir].dirName;
									s31 := forumIdx^^.name[TempDir];
									if thisUser.TerminalType = 1 then
										s2 := concat('Data:', s31, ':', s26, ' AHDR')
									else
										s2 := concat('Data:', s31, ':', s26, ' HDR');
									if ReadTextFile(s2, 0, true) then
									begin
										if thisUser.TerminalType = 1 then
											noPause := true;
										BoardAction := ListText;
									end;
								end;
						end;
						ListDo := ListEight;
					end;
				end;
				ListFive: 
				begin
					tb2 := true;
					if forums^^[inRealDir].dr[InRealSubDir].restriction <> char(0) then
						if thisUser.AccessLetter[(byte(forums^^[inRealDir].dr[InRealSubDir].restriction) - byte(64))] then
							tb2 := true
						else
							tb2 := false;
					if tb2 and (thisUser.DSL >= forums^^[inRealDir].dr[InRealSubDir].minDSL) and (AgeOk(-1, forums^^[inRealDir].dr[InRealSubDir].minAge)) then
					begin
						inNScan := true;
						fileMask := '';
						flsListed := 0;
						fListedCurDir := 0;
						descSearch := false;
						if curprompt = 'Y' then
							allDirSearch := true
						else
							allDirSearch := false;
						if (thisUser.coSysop) and allDirSearch then
						begin
							tempDir := 0;
							tempSubDir := 1;
						end
						else if allDirSearch then
						begin
							tempDir := 1;
							tempSubDir := 1;
						end
						else
						begin
							tempDir := inRealDir;
							tempSubDir := inRealSubDir;
						end;
						GetDateTime(thisUser.lastFileScan);
						ListDo := ListThree;
					end
					else
					begin
						OutLine(RetInStr(120), true, 0);
						gohome;
					end;
				end;
				ListSix: 
				begin
					tb2 := SubDirOk(InRealDir, InRealSubDir);
					if tb2 and (thisUser.DSL >= forums^^[inRealDir].dr[InRealSubDir].minDSL) and (AgeOk(-1, forums^^[inRealDir].dr[InRealSubDir].minAge)) then
					begin
						inNScan := false;
						fileMask := curPrompt;
						flsListed := 0;
						fListedCurDir := 0;
						descSearch := false;
						allDirSearch := true;
						if (thisUser.coSysop) and allDirSearch then
							tempDir := 0
						else if allDirSearch then
							tempDir := 1;
						tempSubDir := 1;
						ListDo := ListThree;
					end
					else
					begin
						OutLine(RetInStr(120), true, 0);
						gohome;
					end;
				end;
				ListSeven: 
				begin
					tb2 := SubDirOk(InRealDir, InRealSubDir);
					if tb2 and (thisUser.DSL >= forums^^[inRealDir].dr[InRealSubDir].minDSL) and (AgeOk(-1, forums^^[inRealDir].dr[InRealSubDir].minAge)) then
					begin
						inNScan := false;
						fileMask := curPrompt;
						flsListed := 0;
						fListedCurDir := 0;
						allDirSearch := true;
						descSearch := true;
						if (thisUser.coSysop) then
							tempDir := 0
						else
							tempDir := 1;
						tempSubDir := 1;
						ListDo := ListThree;
					end
					else
					begin
						OutLine(RetInStr(120), true, 0);
						gohome;
					end;
				end;
				otherwise
			end;
		end;
	end;

	function GetProtMenStr: str255;
		var
			tempString: str255;
	begin
		with curglobs^ do
		begin
			if (thisUser.defaultProtocol > 0) and (thisUser.defaultProtocol <= theProts^^.numProtocols) and (BoardSection <> DetachFile) then
			begin
				tempstring := theProts^^.prots[thisUser.defaultProtocol].ProtoName;
				GetProtMenStr := concat(RetInStr(381), tempstring, ') : ');	{Protocol (?=list, <C/R>=}
			end
			else if (BoardSection = DetachFile) then
			begin
				if (thisUser.defaultProtocol <> 3) and (thisUser.defaultProtocol <> 6) and (thisUser.defaultProtocol > 0) and (thisUser.defaultProtocol <= theProts^^.numProtocols) then
				begin
					tempstring := theProts^^.prots[thisUser.defaultProtocol].ProtoName;
					GetProtMenStr := concat(RetInStr(381), tempstring, '):'); {Protocol (?=list,<C/R>=}
				end
				else
					GetProtMenStr := RetInStr(382); {Protocol (?=list) : }
			end
			else
				GetProtMenStr := concat(RetInStr(382))	{Protocol (?=list) : }
		end;
	end;

	procedure DoUpload;
		var
			abg: point;
			dere: SFtypeList;
			repo: SFReply;
			tempFName, tempString, tempstring2: str255;
			NoteDilg: Dialogptr;
			result: OSerr;
			i, tempint: integer;
			templong: longInt;
			fragged: boolean;
	begin
		with curglobs^ do
		begin
			case UploadDo of
				UpOne: 
				begin
					HelpNum := 17;
					descSearch := false;
					if numFilesInDir(tempinDir, tempSubDir) >= forums^^[tempInDir].dr[tempSubDir].maxFiles then
					begin
						OutLine(RetInStr(383), true, 0);	{This directory is currently full.}
						bCR;
						GoHome;
						exit(doUpload);
					end;
					if (thisUser.DSL < forums^^[tempInDir].dr[tempSubDir].DSLtoUL) then
					begin
						OutLine(RetInStr(384), true, 0);	{Uploads are not allowed to this directory.}
						bCR;
						GoHome;
						exit(doUpload);
					end;
					tempLong := (FreeK(forums^^[tempInDir].dr[tempSubDir].path) div 1024);
					OutLine(concat(RetInStr(385), DoNumber(tempLong), 'K free.'), true, 0);	{Upload - }
					bCR;
					if tempLong < 250 then
					begin
						OutLine(RetInStr(64), true, 0);
						bCR;
						GoHome;
						exit(doUpload);
					end;
					bCR;
					if readTextFile('Upload Message', 1, false) then
					begin
						if thisUser.TerminalType = 1 then
							noPause := true;
						BoardAction := ListText;
						ListTextFile;
					end;
					UploadDo := UpTwo;
				end;
				UpTwo: 
				begin
					bCR;
					LettersPrompt(RetInStr(386), '', forums^^[tempInDir].dr[tempSubDir].fileNameLength, false, false, false, char(0));
					ANSIPrompter(forums^^[tempInDir].dr[tempSubDir].fileNameLength);
					UploadDo := UpThree;
				end;
				UpThree: 
				begin
					if (length(curprompt) > 0) then
					begin
						if (pos(':', curprompt) = 0) and (pos('.', curPrompt) <> 1) then
						begin
							curFil.flName := curPrompt;
							curFil.realFName := curprompt;
							GetDateTime(curFil.whenUL);
							curFil.uploaderNum := thisUser.userNum;
							curFil.numDLoads := 0;
							curFil.hasExtended := false;
							curFil.fileStat := char(0);
							curFil.lastDL := 0;
							for i := 1 to 50 do
								curFil.reserved[i] := char(0);
							curfil.Version := '';
							curfil.FileType := '';
							curfil.FileNumber := 0;
							bCR;
							YesNoQuestion(concat('Upload ''', curprompt, ''' to ', forums^^[tempInDir].dr[tempSubDir].dirName, '? '), false);
							UploadDo := UpFour;
						end
						else
						begin
							GoHome;
							OutLine(RetInStr(387), true, 0);	{Illegal character in filename.}
						end;
					end
					else
					begin
						OutLine(RetInStr(388), true, 0);{File transmission aborted.}
						GoHome;
					end;
				end;
				UpFour: 
				begin
					if (curprompt = 'Y') then
					begin
						if (pos(':', curFil.realFName) = 0) then
							tempstring := concat(forums^^[tempInDir].dr[tempSubDir].path, curFil.realFname)
						else
							tempstring := curFil.realFName;
						fragged := FragFile(tempstring);
						if FExist(tempstring) and not fragged then
						begin
							bCR;
							OutLine(RetInStr(389), true, 0);	{That file is already here.}
							GoHome;
							exit(doUpload);
						end
						else
						begin
							if fragged then
							begin
								bCR;
								OutLine(RetInStr(390), true, 2);	{Completing fragmented upload...}
								bCR;
							end;
							curPrompt := 'Y';
							uploadDo := upFive;
							if fragged then
								uploadDo := upSeven;
						end;
					end
					else
						GoHome;
				end;
				UpFive: 
				begin
					if curPrompt = 'Y' then
					begin
						OutLine(RetInStr(391), true, 0);	{Please enter a one line description.}
						bCR;
						LettersPrompt(': ', '', 72 - forums^^[tempInDir].dr[tempSubDir].fileNameLength, false, false, false, char(0));
						ANSIPrompter(72 - forums^^[tempInDir].dr[tempSubDir].fileNameLength);
						UploadDo := UpSix;
					end
					else
						GoHome;
				end;
				UpSix: 
				begin
					curFil.flDesc := curPrompt;
					bCR;
					curFil.hasExtended := false;
					YesNoQuestion(RetInStr(392), false);	{Enter an extended description? }
					BoardSection := Ext;
					ExtenDo := ex1;
					maxLines := -981;
					UploadDo := UpSeven;
				end;
				UpSeven: 
				begin
					if theProts^^.numProtocols > 0 then
					begin
						crossint := theprots^^.numprotocols;
						tempstring := ' 0Q?';
						tempString[1] := char(13);
						crossInt := 0;
						for i := 1 to theProts^^.numProtocols do
						begin
							if theProts^^.prots[i].pFlags[CANRECEIVE] or theProts^^.prots[i].pFlags[CANBRECEIVE] then
								if (nodeType <> 3) or ((nodeType = 3) and (theProts^^.prots[i].pFlags[CANTCPRECEIVE])) then
								begin
									crossInt := crossInt + 1;
									NumToString(crossint, tempstring2);
									tempString := concat(tempString, tempstring2);
								end;
						end;
						bCR;
						bCR;
						NumbersPrompt(getProtMenStr, 'Q?', crossInt, 0);
						UploadDo := UpEight;
					end
					else
						GoHome;
				end;
				UpEight: 
				begin
					if curPrompt = '?' then
					begin
						OutLine(RetInStr(309), true, 0);	{Q: Abort Transfer(s)}
						OutLine(RetInStr(310), true, 0);	{0: Don't Transfer}
						crossInt := 0;
						tempstring := ' 0Q?';
						tempString[1] := char(13);
						for i := 1 to theProts^^.numProtocols do
						begin
							if theProts^^.prots[i].pFlags[CANRECEIVE] or theProts^^.prots[i].pFlags[CANBRECEIVE] then
								if (nodeType <> 3) or ((nodeType = 3) and (theProts^^.prots[i].pFlags[CANTCPRECEIVE])) then
								begin
									crossInt := crossInt + 1;
									NumToString(crossInt, tempstring2);
									OutLine(concat(tempstring2, ': ', theProts^^.prots[i].ProtoName), true, 0);
									tempString := concat(tempString, tempstring2);
								end;
						end;
						bCR;
						bCR;
						NumbersPrompt(getProtMenStr, 'Q?', crossInt, 0);
						Exit(doUpload);
					end
					else if (curPrompt = 'Q') or (curPrompt = '0') then
					begin
						GoHome;
						Exit(doUpload);
					end
					else
					begin
						StringToNum(curPrompt, tempLong);
						activeProtocol := 0;
						crossInt := 0;
						for i := 1 to theProts^^.numProtocols do
						begin
							if theProts^^.prots[i].pFlags[CANRECEIVE] or theProts^^.prots[i].pFlags[CANBRECEIVE] then
								if (nodeType <> 3) or ((nodeType = 3) and (theProts^^.prots[i].pFlags[CANTCPRECEIVE])) then
								begin
									crossInt := crossInt + 1;
									if crossInt = tempLong then
										activeProtocol := i;
								end;
						end;
						if length(curPrompt) = 0 then
							activeProtocol := thisUser.defaultProtocol;
						if (theProts^^.prots[activeProtocol].pFlags[CANRECEIVE] or theProts^^.prots[activeProtocol].pFlags[CANBRECEIVE]) and (activeProtocol > 0) then
						begin
							if (nodeType <> 3) or ((nodeType = 3) and (theProts^^.prots[activeProtocol].pFlags[CANTCPRECEIVE])) then
							begin
								if not sysopLogon then
								begin
									bCR;
									bCR;
									bCR;
									if (theProts^^.prots[activeProtocol].pFlags[CANBRECEIVE]) then
									begin
										if FileTransit^^.numFiles < 50 then
										begin
											lastBatch := activeProtocol;
											if (fileTransit^^.sendingBatch and (fileTransit^^.numFiles > 0)) then
											begin
												FileTransit^^.numFiles := 0;
												FileTransit^^.batchTime := 0;
												FileTransit^^.batchKBytes := 0;
												OutLine(RetInStr(394), true, 0);	{Download batch cleared.}
												bCR;
											end;
											FileTransit^^.filesGoing[fileTransit^^.numFiles + 1].theFile := curFil;
											FileTransit^^.filesGoing[fileTransit^^.numFiles + 1].fromDir := tempInDir;
											FileTransit^^.filesGoing[fileTransit^^.numFiles + 1].fromSub := tempSubDir;
											FileTransit^^.numFiles := FileTransit^^.numFiles + 1;
											OutLine(RetInStr(624), true, 0);{File added to batch queue.}
											NumToString(fileTransit^^.numFiles, tempString);
											OutLine(concat(RetInStr(393), tempstring), true, 0);{Batch UL: Files - }
											fileTransit^^.sendingBatch := false;
											bCR;
											goHome;
										end;
									end
									else
									begin
										myTrans.active := true;
										myTrans.sending := false;
										StartTrans;
									end;
								end
								else
								begin
									OutLine(RetInStr(395), true, 0);	{Cannot upload locally.}
									GoHome;
								end;
							end
							else
							begin
								OutLine(RetInStr(396), true, 0);	{Protocol not valid for uploading.}
								goHome;
							end
						end
						else
						begin
							OutLine(RetInStr(396), true, 0);	{Protocol not valid for uploading.}
							goHome;
						end;
					end;
				end;
				otherwise
			end;
		end;
	end;

	procedure DoSort;
		var
			numF: integer;
			t1: str255;
			l: longint;
	begin
		with curglobs^ do
		begin
			case SortDo of
				SortOne: 
				begin
					if curPrompt = 'Y' then       { sort all dirs question is asked in DoMainMenu for speed  }
						alldirSearch := true
					else
						allDirSearch := false;
					bCR;
					OutLine('Sort By:', true, 2);
					bCR;
					OutLine('1. File Name', true, 1);
					OutLine('2. Date Uploaded', true, 1);
					OutLine('3. Number of Downloads', true, 1);
					OutLine('4. File Size', true, 1);
					OutLine('5. Date of Last Download', true, 1);
					bCR;
					bCR;
					NumbersPrompt('(1-5), (Q)uit: ', 'Q', 5, 1);
					SortDo := SortTwo;
				end;
				SortTwo: 
				begin
					if alldirSearch then
					begin
						tempInDir := 0;
						tempSubDir := 1;
					end
					else
					begin
						tempInDir := inRealDir;
						tempSubDir := inRealSubDir;
					end;
					crossLong := 0;
					BoardAction := Repeating;
					SortDo := SortThree;
				end;
				SortThree: 
				begin
					numF := 0;
					if (curPrompt = '') or (curPrompt = 'Q') then
					begin
						BoardAction := none;
						GoHome;
					end
					else
					begin
						OutLine(concat(RetInStr(398), forumIdx^^.name[tempInDir], ', ', forums^^[tempInDir].dr[tempSubDir].dirName, '.'), true, 0);{Sorting }
						StringToNum(curPrompt, l);
						numF := SortDir(tempInDir, tempSubDir, l);

						SaveDirectory;
						OutLine(concat('..', doNumber(numF), ' files.'), false, 0);
						crossLong := crossLong + numF;
						tempSubDir := tempSubDir + 1;
						if ForumIdx^^.numDirs[tempInDir] < (tempSubDir) then
						begin
							tempInDir := tempInDir + 1;
							tempSubDir := 1;
						end;
						if ForumIdx^^.numForums <= tempInDir then
							allDirSearch := false;
						if not alldirsearch or aborted then
						begin
							OutLine(concat(RetInStr(399), doNumber(crossLong)), true, 3);{Total files sorted: }
							aborted := false;
							BoardAction := None;
							GoHome;
						end;
					end;
				end;
				otherwise
			end;
		end;
	end;

	function RestDir (which, whichSub: integer): boolean;
		var
			tb2: boolean;
	begin
		with curGlobs^ do
		begin
			tb2 := true;
			if forums^^[which].dr[whichSub].restriction <> char(0) then
				if thisUser.AccessLetter[(byte(forums^^[which].dr[whichSub].restriction) - byte(64))] then
					tb2 := true
				else
					tb2 := false;
			RestDir := tb2;
		end;
	end;

	procedure DoDownload;
		label
			999;
		var
			tempString, t2: str255;
			tempFil: filEntryRec;
			tempLong: longInt;
			repo: SFReply;
			i: integer;
			tempBool, tb2: boolean;
	begin
		with curglobs^ do
		begin
			case DownDo of
				DownOne: 
				begin
					tb2 := true;
					if forums^^[tempInDir].dr[tempSubDir].restriction <> char(0) then
						if thisUser.AccessLetter[(byte(forums^^[tempInDir].dr[tempSubDir].restriction) - byte(64))] then
							tb2 := true
						else
							tb2 := false;
					if tb2 and (thisUser.DSL >= forums^^[tempInDir].dr[tempSubDir].minDSL) and (AgeOk(-1, forums^^[tempInDir].dr[tempSubDir].minAge)) then
					begin
						if (thisUser.DSL >= forums^^[tempInDir].dr[tempSubDir].DSLtoDL) then
						begin
							descSearch := false;
							listedOneFile := false;
							bCR;
							if readTextFile('Download', 1, false) then
							begin
								if thisUser.TerminalType = 1 then
									noPause := true;
								BoardAction := ListText;
								ListTextFile;
							end
							else
								OutLine(RetInStr(400), true, 0);{Download -}
							DownDo := Down2;
						end
						else
						begin
							OutLine(RetInStr(401), true, 0);{You can''t download from this directory.}
							GoHome;
						end;
					end
					else
					begin
						OutLine(RetInStr(120), true, 0);
						GoHome;
					end;
				end;
				Down2: 
				begin
					bCR;
					LettersPrompt(RetInStr(402), '', forums^^[tempInDir].dr[tempSubDir].fileNameLength, false, false, false, char(0)); {Filename: }
					ANSIPrompter(forums^^[tempInDir].dr[tempSubDir].fileNameLength);
					DownDo := DownTwo;
				end;
				DownTwo: 
				begin
					if length(curPrompt) > 0 then
					begin
						if forums^^[inRealDir].dr[InRealSubDir].freeDir or DLRatioOK then
						begin
							curDirPos := 0;
							if OpenDirectory(inRealDir, InRealSubDir) then
							begin
								DownDo := DownThree;
								tempInDir := inRealDir;
								tempSubDir := InRealSubDir;
								allDirSearch := false;
								descSearch := false;
								fileMask := curPrompt;
							end
							else
							begin
								OutLine('Problem opening directory.', true, 0);
								GoHome;
							end;
						end
						else
						begin
							DLRatioStr(tempString, activeNode);
							GoodRatioStr(t2);
							bCR;
							OutLine(concat(RetInStr(403), tempString, RetInStr(404), t2, RetInStr(405)), true, 0);
							GoHome;
						end;
					end
					else
						GoHome;
				end;
				DownThree: 
				begin
					GetNextFile(tempInDir, tempSubDir, fileMask, curDirPos, curFil, 0);
					if curFil.flName <> '' then
					begin
						listedOneFile := true;
						i := PrintFileInfo(curFil, tempInDir, tempSubDir, true);
						if i = 0 then
							DownDo := DownFour
						else if i = -1 then
							DownDo := DownRequest;
					end
					else
					begin
						if not listedOneFile and ((not forums^^[inRealDir].dr[InRealSubDir].freeDir) or DLRatioOK) then
						begin
							allDirSearch := true;
							if (thisUser.coSysop) then
								tempInDir := 0
							else
								tempInDir := 1;
							tempSubDir := 0;
							OutLine(RetInStr(625), true, 1);	{Searching all directories.}
							bCR;
							listedOneFile := true;
							goto 999;
						end
						else if alldirSearch then
						begin
999:
							tempSubDir := tempSubDir + 1;
							tb2 := DownloadOk(tempInDir, TempSubDir);
							if tempSubDir > forumIdx^^.NumDirs[TempInDir] then
								tb2 := false;
							while not tb2 and (tempInDir < ForumIdx^^.numForums) do
							begin
								tempInDir := tempInDir + 1;
								tb2 := ForumOk(tempInDir);
								tempSubDir := 1;
								while tb2 and not DownloadOk(tempInDir, TempSubDir) do
								begin
									tempSubDir := TempSubDir + 1;
									if tempSubDir > forumIdx^^.NumDirs[TempInDir] then
										tb2 := false;
								end;
							end;
							if tempInDir >= forumIdx^^.numForums then
								GoHome;
							if OpenDirectory(tempInDir, tempSubDir) then
								;
							curDirPos := 0;
						end
						else
							GoHome;
					end;
				end;
				DownRequest: 
					if (curPrompt[1] = 'Y') then
					begin
						DownDo := DownRequest;
						CurEmailRec.Title := '** File Request **';
						CurEmailRec.FromUser := ThisUser.UserNum;
						CurEmailRec.ToUser := 1;
						CurEmailRec.AnonyFrom := False;
						CurEmailRec.AnonyTo := False;
						CurEMailRec.FileAttached := False;
						CurEMailRec.FileName := char(0);
						GetDateTime(CurEmailRec.DateSent);
						CurEmailRec.MType := 1;
						CurEmailRec.MultiMail := False;
						CurWriting := nil;
						curWriting := TextHand(NewHandle(0));
						AddLine(concat('Filename     : ', char(3), '1', CurFil.flname));
						AddLine(concat('Sub-Directory: ', forums^^[TempInDir].dr[TempSubDir].dirname));
						AddLine(concat('Directory    : ', forumIdx^^.name[TempInDir]));
						AddLine('');
						AddLine('A request for a file has been made:');
						AddLine('');
						curWriting^^[GetHandleSize(handle(curWriting)) - 1] := char(26);
						if not SaveMessAsEmail then
							OutLine(RetInStr(298), true, 6)	{Error: Email database full.}
						else
						begin
							OutLine('Request Sent.', true, 1);
							bcr;
						end;
						DownDo := DownThree;
					end
					else if (curPrompt[1] = 'Q') then
						GoHome
					else
						DownDo := DownThree;
				DownFour: 
				begin
					bCR;
					bCR;
					if theprots^^.numProtocols > 0 then
					begin
						crossint := theprots^^.numprotocols;
						tempstring := ' 0Q?';
						tempString[1] := char(13);
						crossInt := 0;
						for i := 1 to theProts^^.numProtocols do
						begin
							if theProts^^.prots[i].pFlags[CANSEND] or theProts^^.prots[i].pFlags[CANBSEND] then
								if (nodeType <> 3) or ((nodeType = 3) and (theProts^^.prots[i].pFlags[CANTCPSEND])) then
								begin
									crossInt := crossInt + 1;
									NumToString(crossint, t2);
									tempString := concat(tempString, t2);
								end;
						end;
						NumbersPrompt(getprotMenStr, 'Q?', crossInt, 0);
						DownDo := DownFive;
					end
					else
						GoHome;
				end;
				DownFive: 
				begin
					if curPrompt = '?' then
					begin
						OutLine(RetInStr(309), true, 0);	{Q: Abort Transfer(s)}
						OutLine(RetInStr(310), true, 0);	{0: Don''t Transfer}
						crossInt := 0;
						for i := 1 to theProts^^.numProtocols do
						begin
							if theProts^^.prots[i].pFlags[CANSEND] or theProts^^.prots[i].pFlags[CANBSEND] then
								if (nodeType <> 3) or ((nodeType = 3) and (theProts^^.prots[i].pFlags[CANTCPSEND])) then
								begin
									crossInt := crossInt + 1;
									NumToString(crossInt, t2);
									OutLine(concat(t2, ': ', theProts^^.prots[i].ProtoName), true, 0);
								end;
						end;
						bCR;
						bCR;
						crossint := theprots^^.numprotocols;
						tempstring := ' 0Q?';
						tempString[1] := char(13);
						crossInt := 0;
						for i := 1 to theProts^^.numProtocols do
						begin
							if theProts^^.prots[i].pFlags[CANSEND] or theProts^^.prots[i].pFlags[CANBSEND] then
								if (nodeType <> 3) or ((nodeType = 3) and (theProts^^.prots[i].pFlags[CANTCPSEND])) then
								begin
									crossInt := crossInt + 1;
									NumToString(crossint, t2);
									tempString := concat(tempString, t2);
								end;
						end;
						NumbersPrompt(getprotMenStr, 'Q?', crossInt, 0);
						DownDo := DownFive;
					end
					else if (curPrompt = 'Q') or (curPrompt = 'q') then
					begin
						GoHome;
						Exit(doDownload);
					end
					else if (curPrompt = '0') then
						DownDo := DownThree
					else
					begin
						StringToNum(curPrompt, tempLong);
						crossInt := 0;
						for i := 1 to theProts^^.numProtocols do
						begin
							if theProts^^.prots[i].pFlags[CANSEND] or theProts^^.prots[i].pFlags[CANBSEND] then
								if (nodeType <> 3) or ((nodeType = 3) and (theProts^^.prots[i].pFlags[CANTCPSEND])) then
								begin
									crossInt := crossInt + 1;
									if crossInt = tempLong then
										tempLong := i;
								end;
						end;
						if length(curPrompt) = 0 then
							tempLong := thisUser.defaultProtocol;
						if not sysopLogon then
						begin
							if ((nodeType <> 2) or ((tempLong <> 2) and (templong <> 3))) and (tempLong > 0) and (theProts^^.numProtocols >= tempLong) and ((theProts^^.prots[tempLong].pFlags[CANSEND]) or (theProts^^.prots[tempLong].pFlags[CANBSEND])) then
							begin
								if (nodeType <> 3) or ((nodeType = 3) and (theProts^^.prots[tempLong].pFlags[CANTCPSEND])) then
								begin
									if not theProts^^.prots[templong].pFlags[CANBSEND] then
									begin
										activeProtocol := templong;
										BoardSection := SlowDevice;
										SlowDo := SlowOne;
										WasBatch := false;
									end
									else
									begin
										activeProtocol := tempLong;
										DownDo := DownSeven;
									end;
								end
								else
								begin
									OutLine(RetInStr(409), true, 1);	{Protocol not valid for downloading.}
									BCR;
									downDo := downThree;
								end;
							end
							else
							begin
								OutLine(RetInStr(409), true, 1);	{Protocol not valid for downloading.}
								BCR;
								downDo := downThree;
							end;
						end
						else
						begin
							OutLine(RetInStr(113), true, 0);	{Cannot download locally}
							GoHome;
						end;
					end;
				end;
				DownSix: 
				begin
					bCR;
					bCR;
					bCR;
					myTrans.active := true;
					myTrans.sending := true;
					StartTrans;
				end;
				DownSeven: 
				begin
					if FileTransit^^.numFiles < 50 then
					begin
						lastBatch := activeProtocol;
						if (currentBaud <> 0) and (nodeType = 1) then
							tempLong := (fileTransit^^.batchTime + (curFil.bytelen div (modemDrivers^^[modemID].rs[rsIndex].effRate div 10)))
						else
							tempLong := 0;
						if tempLong <= (ticksLeft(activeNode) div 60) then
						begin
							if not forums^^[tempInDir].dr[tempSubDir].freeDir then
							begin
								thisUser.downloadedK := thisUser.downloadedK + fileTransit^^.batchKBytes;
								tempBool := DLRatioOK;
								thisUser.downloadedK := thisUser.downloadedK - fileTransit^^.batchKBytes;
							end
							else
								tempBool := true;
							if tempBool then
							begin
								if (not fileTransit^^.sendingBatch and (fileTransit^^.numFiles > 0)) then
								begin
									FileTransit^^.numFiles := 0;
									FileTransit^^.batchTime := 0;
									FileTransit^^.batchKBytes := 0;
									OutLine('Upload batch cleared.', true, 0);
									bCR;
								end;
								FileTransit^^.filesGoing[fileTransit^^.numFiles + 1].theFile := curFil;
								FileTransit^^.filesGoing[fileTransit^^.numFiles + 1].fromDir := tempInDir;
								FileTransit^^.filesGoing[fileTransit^^.numFiles + 1].fromSub := tempSubDir;
								FileTransit^^.numFiles := FileTransit^^.numFiles + 1;
								if (currentBaud <> 0) and (nodeType = 1) then
									FileTransit^^.batchTime := fileTransit^^.batchTime + (curFil.bytelen div (modemDrivers^^[modemID].rs[rsIndex].effRate div 10))
								else
									FileTransit^^.batchTime := 0;
								FileTransit^^.batchKBytes := fileTransit^^.batchKBytes + (curFil.byteLen div 1024);
								OutLine(RetInStr(624), true, 0);{File Added to batch Queue}
								NumToString(fileTransit^^.numFiles, tempString);
								t2 := secs2time(fileTransit^^.batchTime);
								OutLine(stringOf('Batch DL: Files - ', tempstring, '  Time - ', t2, '  KBytes - ', DoNumber(FileTransit^^.BatchKbytes), 'k'), true, 0);
								fileTransit^^.sendingBatch := true;
								bCR;
							end
							else
							begin
								OutLine(RetInStr(406), true, 0);	{Sorry, your ratio is too low to add that.}
								bCR;
							end;
						end
						else
						begin
							Outline(RetInStr(407), true, 0);	{Not enough time left in queue.}
							bCR;
						end;
					end
					else
					begin
						OutLine(RetInStr(408), true, 0);	{No room left in batch queue.}
						bCR;
					end;
					DownDo := DownThree;
				end;
				otherwise
			end;
		end;
	end;
end.