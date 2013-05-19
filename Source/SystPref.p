{ Segments: SystPref_1 }
unit SystemPrefs;

interface

	uses
		AppleTalk, ADSP, Serial, Sound, TCPTypes, Initial, LoadAndSave, CTBUtilities, TCPTypes, NodePrefs, NodePrefs2, SystemPrefs2;

	procedure OpenSystemConfig (whichExternal: integer);
	procedure CloseSystemConfig;
	procedure CallSysopExternal (message, item: integer; var theEvent: eventRecord);
	procedure ClickSystemConfig (theEvent: EventRecord; itemHit: integer);
	procedure UpdateSysConfig (event: eventRecord);
	procedure DLratioStr (var loadStr: str255; whichNode: integer);
	function mySDGetBuf (var returned: longint): OSerr;
	function inDownTime: boolean;
	function PrepModem: boolean;
	function TickToTime (whichTicks: longint): str255;
	function ticksLeft (whichNode: integer): longint;
	function NextDownTicks: longint;
	function AsyncMWrite (myRefNum: integer; lengWrite: longint; WhatWrite: ptr): OSerr;
	function mySyncRead (modemRef: integer; lengWrite: longint; myBufPtr: ptr): OSerr;
	procedure Flowie (YesFlow: boolean);
	procedure NumToBaud (num: integer; var tempint: longint);
	procedure DoBaudReset (baudWanted: longint);
	function FExist (FNmPth: str255): boolean;
	function FreeK (pathOn: str255): longint;
	procedure GoodRatioStr (var loadStr: str255);
	procedure TerminateRun;
	procedure OpenCapture (path: str255);
	procedure CloseCapture;
	procedure TellModem (what: str255);
	procedure Write2ZLog (node: integer; total: boolean);
	procedure RestrictString (var THEUSER: USERREC; var te1: str255);
	function SexToTime (whichTicks: longint): str255;
	procedure MakeExtList;
	procedure OpenStatWindow;
	procedure CloseStatWindow;
	procedure UpdateStatWindow;
	function GetStatLine: str255;
	procedure OpenDialer;
	procedure CloseDialer;
	procedure UpdateDialer;
	procedure DoDialer (theEvent: EventRecord; itemHit: Integer);
	procedure DoTextSearch (textWindNum: integer);
	procedure mySearchTE (textWindNum: integer; startAtEndSel: boolean);
	procedure UserRestricts (var theUser: UserRec; var te1: str255);
	function Get1ComPort: char;

implementation

{$S SystPref_1}
	procedure mySearchTE (textWindNum: integer; startAtEndSel: boolean);
		label
			100;
		var
			sLen: integer;
			tend: longint;
			cmp: str255;
			myT: CharsHandle;
			c1, c2: char;
	begin
		sLen := length(textSearch);
		myT := charshandle(textWinds[textWindNum].t^^.hText);
		if startAtEndSel then
			i := textWinds[textWindNum].t^^.selEnd + 1
		else
			i := 0;
		tend := GetHandleSize(handle(myT));
		cmp[0] := char(sLen);
100:
		c1 := textSearch[1];
		if ((c1 >= 'a') and (c1 <= 'z')) then
			c1 := char(byte(c1) - (byte('a') - byte('A')));
		repeat
			c2 := myT^^[i];
			if ((c2 >= 'a') and (c2 <= 'z')) then
				c2 := char(byte(c2) - (byte('a') - byte('A')));
			i := i + 1;
		until (c2 = c1) or (i >= tend);
		if (i < tend) then
		begin
			i := i - 1;
			BlockMove(@myT^^[i], @cmp[1], sLen);
			if (EqualString(textSearch, cmp, false, false)) then
			begin
				TESetSelect(i, i + sLen, textWinds[textWindNum].t);
				TESelView(textWinds[textWindNum].t);
				AdjustScrollbars(textWindNum, false);
			end
			else
			begin
				i := i + 1;
				goto 100;
			end;
		end
		else
			SysBeep(10);
	end;

	procedure DoTextSearch (textWindNum: integer);
		var
			searchDilg: DialogPtr;
			i, kind, sLen: integer;
			tend: longint;
			h: handle;
			r: rect;
			cmp: str255;
			myT: CharsHandle;
	begin
		searchDilg := GetNewDialog(3468, nil, pointer(-1));
		SetPort(searchDilg);
		if textSearch <> '' then
		begin
			GetDItem(searchDilg, 4, kind, h, r);
			SetIText(h, textSearch);
		end;
		TESetSelect(0, 32767, DialogPeek(searchDilg)^.textH);
		ShowWindow(searchDilg);
		GetDItem(searchDilg, 1, kind, h, r);
		InsetRect(r, -4, -4);
		PenSize(3, 3);
		FrameRoundRect(r, 16, 16);
		repeat
			ModalDialog(nil, i);
		until (i = 1) or (i = 2);
		if (i = 1) then
		begin
			GetDItem(searchDilg, 4, kind, h, r);
			GetIText(h, textSearch);
			if length(textSearch) > 0 then
				mySearchTE(textWindNum, false);
		end;
		DisposDialog(searchDilg);
	end;

	procedure CloseDialer;
		var
			tempString: str255;
			tempRect, tr2: Rect;
			myC: Point;
			DType, i, kind: Integer;
			DItem: Handle;
	begin
		if (DialDialog <> nil) then
		begin
			DisposDialog(DialDialog);
			DialDialog := nil;
		end;
	end;

	procedure UpdateDialer;
		var
			SavedPort: GrafPtr;
			tempRect: rect;
			DType, i: Integer;
			DItem: Handle;
	begin
		if (DialDialog <> nil) then
		begin
			GetPort(SavedPort);
			SetPort(DialDialog);
			DrawDialog(DialDialog);
			setPort(savedPort);
		end;
	end;

	procedure OpenDialer;
		var
			i, a: integer;
			kind: integer;
			h: handle;
			r: rect;
			ts: str255;
	begin
		if (DialDialog = nil) then
		begin
			with curGlobs^ do
			begin
				dialDialog := GetNewDialog(2112, nil, pointer(-1));
				UseResFile(myResourceFile);
				a := 0;
				for i := 3 to 21 do
				begin
					SetTextBox(dialDialog, i, InitSystHand^^.bbsnames[a]);
					i := i + 1;
					a := a + 1;
				end;
				a := 0;
				for i := 4 to 22 do
				begin
					SetTextBox(dialDialog, i, InitSystHand^^.bbsnumbers[a]);
					i := i + 1;
					a := a + 1;
				end;
				for i := 23 to 32 do
					SetCheckBox(dialDialog, i, InitSystHand^^.BbsDialIt[i - 23]);
				for i := 0 to 9 do
					InitSystHand^^.Bbsdialed[i] := false;
				ShowWIndow(dialDialog);
			end;
		end
		else
			SelectWindow(DialDialog);
	end;

	procedure DoDialer (theEvent: EventRecord; ItemHit: Integer);
		var
			myPt: Point;
			doubleclick, hk: boolean;
			tempCell: cell;
			tempint: integer;
			tempString: str255;
			tempRect, tr2: Rect;
			myC: Point;
			DType, i, kind: Integer;
			DItem: Handle;
			ttUser: userRec;
			CItem: controlhandle;
	begin
		if (DialDialog <> nil) then
		begin
			SetPort(DialDialog);
			myPt := theEvent.where;
			GlobalToLocal(myPt);
			GetDItem(DialDialog, itemHit, DType, DItem, TempRect);
			CItem := Pointer(DItem);
			case itemHit of
				23, 24, 25, 26, 27, 28, 29, 30, 31, 32: 
				begin
					GetDItem(dialDialog, itemHit, Dtype, Ditem, TempRect);
					SetCtlValue(controlHandle(Ditem), (GetCtlValue(controlHandle(Ditem)) + 1) mod 2);
				end;
				33: 
				begin
					tempint := 0;
					for i := 3 to 21 do
					begin
						case i of
							3, 5, 7, 9, 11, 13, 15, 17, 19, 21: 
							begin
								InitSystHand^^.BbsNames[tempint] := GetTextBox(DialDialog, i);
								tempint := tempint + 1;
							end;
							otherwise
						end;
					end;
					tempint := 0;
					for i := 4 to 22 do
					begin
						case i of
							4, 6, 8, 10, 12, 14, 16, 18, 20, 22: 
							begin
								InitSystHand^^.BbsNumbers[tempint] := GetTextBox(DialDialog, i);
								tempint := tempint + 1;
							end;
							otherwise
						end;
					end;
					for i := 0 to MAX_NODES_M_1 do
					begin
{    InitSystHand^^.Bbsnames[i] := GetTextBox(DialDialog, i + 3);}
{    InitSystHand^^.Bbsnumbers[i] := GetTextBox(DialDialog, i + 13);}
						InitSystHand^^.BbsDialIt[i] := GetCheckBox(DialDialog, i + 23);
					end;
					CurGlobs^.dialing := true;
					CurGlobs^.waitdialresponse := false;
					CurGlobs^.dialDelay := tickCount - 300;
					CheckItem(GetMHandle(mTerminal), 5, CurGlobs^.dialing);
					CloseDialer;
				end;
				34: 
				begin
					CurGlobs^.dialing := false;
					CloseDialer;
				end;
			end;
		end;
	end;

	procedure OpenStatWindow;
		var
			defRect, tRect, t2: rect;
	begin
		if statWindow = nil then
		begin
			SetRect(defRect, 5, screenBits.bounds.bottom - 55, 505, screenBits.bounds.bottom - 5);
			SetRect(t2, 0, 0, 0, 0);
			tRect := InitSystHand^^.wStatus;
			if (tRect.top > screenbits.bounds.bottom) or (tRect.left > screenbits.bounds.right) or optiondown then
				SetRect(tRect, 5, screenBits.bounds.bottom - 55, 505, screenBits.bounds.bottom - 5);
			if (EqualRect(tRect, t2)) or not SectRect(tRect, screenBits.bounds, t2) then
				tRect := defRect;
			InitSystHand^^.wIsOpen[0] := true;
			statWindow := NewWindow(nil, tRect, 'Status', true, 0, pointer(-1), true, 0);
		end
		else
			SelectWindow(statwindow);
	end;

	procedure CloseStatWindow;
		var
			i: integer;
	begin
		if statWindow <> nil then
		begin
			SetPort(StatWindow);
			InitSystHand^^.wStatus := statWindow^.portRect;
			if quit = 0 then
				InitSystHand^^.wIsOpen[0] := false;
			LocalToGlobal(InitSystHand^^.wStatus.topLeft);
			LocalToGlobal(InitSystHand^^.wStatus.botRight);
			DisposeWindow(statWindow);
			statWindow := nil;
		end;
	end;

	function mySyncRead (modemRef: integer; lengWrite: longint; myBufPtr: ptr): OSerr;
		var
			myParamB: ParamBlockRec;
	begin
		myParamB.ioCompletion := nil;
		myParamB.ioRefNum := modemRef;
		myParamB.ioBuffer := StripAddress(myBufPtr);
		myParamB.ioReqCount := lengWrite;
		myParamB.ioPosMode := fsAtMark;
		myParamB.ioPosOffset := 0;
		mySyncRead := PBRead(parmBlkPtr(StripAddress(@myParamB)), false);
	end;

	function mySDGetBuf (var returned: longint): OSerr;
		var
			i: integer;
			t1: longint;
			myParmBlk: ParamBlockRec;
	begin
		with myParmBlk do
		begin
			ioCompletion := nil;
			ioVRefNum := 0;
			ioRefNum := curglobs^.inputRef;
			csCode := 2;
			for i := 1 to 10 do
				csParam[i] := 0;
		end;
		result := PBStatus(parmBlkPtr(StripAddress(@myParmBlk)), false);
		BlockMove(@myParmBlk.csParam, @t1, 4);
		returned := t1;
	end;

	function FExist (FNmPth: str255): boolean;
		var
			result: OSerr;
			tempRef: integer;
			myHParmer: HParamBlockRec;
			myParmer: ParamBlockRec;
	begin
		with myHParmer do
		begin
			ioCompletion := nil;
			ioNamePtr := @FNmPth;
			ioVRefNum := 0;
			ioDirID := 0;
			ioFDirIndex := -1;
		end;
		result := PBHGetFInfo(@myHParmer, false);
		if result = noErr then
			FExist := true
		else
			FExist := false;
	end;

	function AsyncMWrite (myRefNum: integer; lengWrite: longint; whatWrite: ptr): OSerr;
		var
			myTems: longint;
			IHatePascal: boolean;
	begin
		with curglobs^ do
		begin
			result := noErr;
			if lengWrite > 0 then
			begin
				if toBeSent = nil then
				begin
					toBeSent := NewHandle(lengWrite);
					HNoPurge(handle(toBesent));
					BlockMove(whatWrite, pointer(toBeSent^), lengWrite);
				end
				else
				begin
					myTems := GetHandleSize(toBeSent);
					SetHandleSize(toBeSent, myTems + lengWrite);
					BlockMove(whatWrite, pointer(ord4(toBeSent^) + myTems), lengWrite);
				end;
			end;
			if (toBeSent <> nil) then
			begin
				IHatePascal := false;
				if (nodeType = 2) then
					if (nodeDSPWritePtr^.ioResult <> 1) then
						IHatePascal := true
					else
				else if (nodeType = 3) then
					if (nodeTCP.tcpPBPtr^.ioResult <> 1) then
						IHatePascal := true;
				if ((myBlocker.ioResult <> 1) and (nodeType = 1)) or IHatePascal then
				begin
					myTems := GetHandleSize(toBeSent);
					if myTems > SENDNOWBUFSIZE then
					begin
						myTems := SENDNOWBUFSIZE;
						BlockMove(pointer(toBeSent^), sendingNow, myTems);
						BlockMove(pointer(ord4(toBeSent^) + longInt(SENDNOWBUFSIZE)), pointer(toBeSent^), GetHandleSize(toBeSent) - SENDNOWBUFSIZE);
						SetHandleSize(toBeSent, GetHandleSize(toBeSent) - SENDNOWBUFSIZE);
					end
					else
					begin
						BlockMove(pointer(toBeSent^), sendingNow, myTems);
						DisposHandle(toBeSent);
						toBeSent := nil;
					end;
					if (nodeType = 1) then
					begin
						with myBlocker do
						begin
							ioCompletion := nil;
							ioRefNum := myRefNum;
							ioBuffer := sendingNow;
							ioReqCount := myTems;
						end;
						result := PBWrite(parmBlkPtr(stripAddress(@myBlocker)), true);
					end
					else if (nodeType = 2) then
					begin
						with nodeDSPWritePtr^ do
						begin
							csCode := dspWrite;
							ioCompletion := nil;
							ioCRefNum := dspDrvrRefNum;
							ccbRefNum := nodeCCBRefNum;
							reqCount := myTems;
							dataPtr := sendingNow;
							eom := 0;
							flush := 1;
						end;
						result := PBControl(ParmBlkPtr(nodeDSPWritePtr), true);
					end
					else if (nodeType = 3) then
					begin
						nodeTCP.tcpWDSPtr^.size := myTems;
						nodeTCP.tcpWDSPtr^.buffer := sendingNow;
						nodeTCP.tcpWDSPtr^.term := 0;

						with nodeTCP.tcpPBPtr^ do
						begin
							ioResult := 1;
							ioCompletion := nil;

							ioCRefNum := ippDrvrRefNum;
							csCode := TCPcsSend;
							tcpStream := nodeTCP.tcpStreamPtr;

							send.ulpTimeoutValue := 0;
							send.ulpTimeoutAction := -1;
							send.validityFlags := $c0;
							send.pushFlag := 0;
							send.urgentFlag := 0;
							send.wds := nodeTCP.tcpWDSPtr;
							send.userDataPtr := nil;
						end;

						result := PBControl(ParmBlkPtr(curGlobs^.nodeTCP.tcpPBPtr), false);
					end;
				end;
			end;
			AsyncMWrite := result;
		end;
	end;


	procedure RestrictString (var theUser: UserRec; var te1: str255);
		var
			i: integer;
	begin
		te1 := 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
		for I := 1 to 26 do
			if not theUser.AccessLetter[i] then
				te1[i] := ' ';
	end;

	procedure UserRestricts (var theUser: UserRec; var te1: str255);
		var
			i: integer;
	begin
		te1 := '123456789012345';
		if not theUser.CantPost then
			te1[1] := '-';
		if not theUser.CantChat then
			te1[2] := '-';
		if not theUser.UDRatioOn then
			te1[3] := '-';
		if not theUser.PCRatioOn then
			te1[4] := '-';
		if not theUser.CantPostAnon then
			te1[5] := '-';
		if not theUser.CantSendEmail then
			te1[6] := '-';
		if not theUser.CantChangeAutoMsg then
			te1[7] := '-';
		if not theUser.CantListUser then
			te1[8] := '-';
		if not theUser.CantAddToBBSList then
			te1[9] := '-';
		if not theUser.CantSeeULInfo then
			te1[10] := '-';
		if not theUser.CantReadAnon then
			te1[11] := '-';
		if not theUser.RestrictHours then
			te1[12] := '-';
		if not theUser.CantSendPPFile then
			te1[13] := '-';
		if not theUser.CantNetMail then
			te1[14] := '-';
		if not theUser.ReadBeforeDL then
			te1[15] := '-';
	end;

	procedure ErrorRep (identity: str255; theResult: OSerr);
		var
			t1: str255;
	begin
		if theResult <> noErr then
			ProblemRep(StringOf('Error: ', identity, ' (', theResult : 0, ')'));
	end;

	procedure TerminateRun;
		var
			bbc: oserr;
			tempFileName: str255;
			tempLong, count: longInt;
			SharedRef, i: integer;
	begin
		with curglobs^ do
		begin
			if capturing then
				closeCapture;
			capturing := false;
			CloseComPort;
			if MForum <> nil then
			begin
				HPurge(handle(MForum));
				DisposHandle(handle(MForum));
				MForum := nil;
			end;
			for i := 1 to InitSystHand^^.numMForums do
				if MConference[i] <> nil then
				begin
					HPurge(handle(MConference[i]));
					DisposHandle(handle(MConference[i]));
					MConference[i] := nil;
				end;
			if intGFileRec <> nil then
			begin
				HPurge(handle(intGFileRec));
				DisposHandle(handle(intGFileRec));
				intGFileRec := nil;
			end;
			if curOpenDir <> nil then
			begin
				HPurge(handle(curOpenDir));
				DisposHandle(handle(curOpenDir));
				curopenDir := nil;
			end;
		end;
	end;

	procedure TellModem (what: str255);
		var
			count: longInt;
	begin
		if curglobs^.nodeType = 1 then
		begin
			count := length(what) + 1;
			what := concat(what, char(13));
			result := AsyncMWrite(curglobs^.outputRef, count, ptr(ord4(@what) + 1));
			Delay(60, count);
			result := mySDGetBuf(count);
			while count > 0 do
			begin
				if count > 255 then
				begin
					result := mySyncRead(curglobs^.inputRef, 255, ptr(ord4(@what) + 1));
					count := count - 255;
				end
				else
				begin
					result := mySyncRead(curglobs^.inputRef, count, ptr(ord4(@what) + 1));
					count := 0;
				end;
			end;
		end;
	end;

	procedure OpenCapture;
		var
			tems: str255;
			tI: integer;
			result: OSerr;
			capRep: SFReply;
			tp: point;
	begin
		with curglobs^ do
		begin
			capturing := false;
			SetPt(tp, 50, 50);
			if path = char(0) then
				SFPutFile(tp, 'Save captured text as:', 'Capture', nil, capRep)
			else
			begin
				capRep.good := true;
				capRep.fName := path;
				capRep.vRefNum := 0;
			end;
			if capRep.good then
			begin
				result := Create(caprep.fName, capRep.vRefNum, 'HRMS', 'TEXT');
				result := FSOpen(capRep.fName, capRep.vRefNum, captureRef);
				if result = noErr then
				begin
					result := SetFPos(captureRef, fsFromStart, 0);
					capturing := true;
				end
				else
					SysBeep(10);
			end;
		end;
	end;

	procedure CloseCapture;
	begin
		with curglobs^ do
		begin
			result := FSClose(captureref);
			capturing := false;
			if visibleNode = activeNode then
				CheckItem(getMHandle(mFile), 8, false);
		end;
	end;

	procedure NumToBaud (num: integer; var tempint: longint);
	begin
		case num of
			1: 
				tempint := 50;
			2: 
				tempint := 75;
			3: 
				tempint := 110;
			4: 
				tempint := 150;
			5: 
				tempint := 200;
			6: 
				tempint := 300;
			7: 
				tempint := 450;
			8: 
				tempint := 600;
			9: 
				tempint := 1200;
			10: 
				tempint := 1800;
			11: 
				tempint := 2000;
			12: 
				tempint := 2400;
			13: 
				tempint := 3600;
			14: 
				tempint := 4800;
			15: 
				tempint := 7200;
			16: 
				tempint := 9600;
			17: 
				tempint := 19200;
			18: 
				tempint := 38400;
			19: 
				tempint := 57600;
			otherwise
		end;
	end;

	procedure DoBaudReset (baudWanted: longint);
		var
			tempInt: integer;
			tl: longint;
			myPB: paramBlockRec;
	begin
		if baudWanted < 20 then
		begin
			NumToBaud(baudWanted, tl);
			baudWanted := tl;
		end;
		tempInt := baudWanted;
		if baudWanted = 38400 then
			tempInt := $9600
		else if baudWanted = 57600 then
			tempInt := $E100;
		with myPB do
		begin
			csCode := 13;
			ioCompletion := nil;
			ioVRefNum := 0;
			ioRefNum := curglobs^.inputRef;
		end;
		BlockMove(@tempint, @myPB.csParam, 2);
		result := PBControl(@myPB, false);
	end;


	procedure Write2ZLog (node: integer; total: boolean);
		var
			tempString, tempString2, ts3, ts4, ts5, m, n: str255;
			result: OSerr;
			count, count2: longint;
			ZLogRef, i, a, b, c, d, e, f, g, h, j, k: integer;
			bisho: handle;
			tempReal, tr2: real;
			myDate: DateTimeRec;
	begin
		if (node = 99) or (not theNodes[node]^.SysOpNode) then
		begin
			tempString2 := concat('##    Date    Day  Calls  Active  EMail  Posts  Uploads  Downlds  %Act  T/User', char(13), '--  --------  ---  -----  ------  -----  -----  -------  -------  ----  ------', char(13));
			count := length(tempString2);
			tempString := concat(sharedpath, 'Misc:Usage Record');
			result := FSOpen(tempString, 0, ZlogRef);
			if result <> noErr then
			begin
				result := FSDelete(tempString, 0);
				result := Create(tempString, 0, 'HRMS', 'TEXT');
				result := FSOpen(tempString, 0, ZLogRef);
				result := SetEOF(ZLogRef, count);
				result := SetFPos(ZLogRef, fsFromStart, 0);
				count2 := count;
				result := FSWrite(ZLogRef, count2, @tempString2[1]);
			end;
			result := GetEOF(ZLogRef, count2);
			NumToString(InitSystHand^^.lastmaint.month, tempString);
			if length(tempString) = 1 then
				tempString := concat('0', tempString);
			NumToString(InitSystHand^^.lastMaint.day, tempString2);
			if length(tempString2) = 1 then
				tempString2 := concat('0', tempString2);
			tempString := concat(tempString, '/', tempString2);
			NumToString(InitSystHand^^.lastMaint.year, tempString2);
			tempString2[1] := tempString2[3];
			tempString2[2] := tempString2[4];
			tempString2[0] := char(2);
			tempString := concat(tempString, '/', tempString2, '  ');
			whatDay(InitSystHand^^.lastmaint, tempString2);
			tempString2[0] := char(3);
			tempString := concat(tempString, tempString2, '  ');
			if not total then
			begin
				NumToString(InitSystHand^^.FailedUls[node], m);
				NumToString(InitSystHand^^.FailedDls[node], n);
				tempString := concat(tempString, stringOf(InitSystHand^^.CallsToday[node] : 5, '  ', InitSystHand^^.MinsToday[node] : 6, '  ', InitSystHand^^.emailToday[node] : 5, '  '));
				tempString := concat(tempString, stringOf(InitSystHand^^.mPostedToday[node] : 5, '  ', InitSystHand^^.uploadsToday[node] : 3, '/', InitSystHand^^.FailedUls[node] : 0, ' ' : 3 - length(m), '  '));
				tempString := concat(tempString, stringOf(InitSystHand^^.dlsToday[node] : 3, '/', InitSystHand^^.FailedDls[node] : 0, ' ' : 3 - length(n), '  '));
				if InitSystHand^^.minsToday[node] > 14 then
					tempReal := ((InitSystHand^^.minsToday[node] / 1440) * 100)
				else
					tempReal := 0;
				i := trunc(tempReal);
				tempString := concat(stringOf(node : 2), '  ', tempString, stringOf(i : 3), '%  ');
				if InitSystHand^^.callsToday[node] > 0 then
					i := InitSystHand^^.minsToday[node] div InitSystHand^^.callsToday[node]
				else
					i := 0;
				tempString := concat(tempString, stringOf(i : 6), char(13));
			end
			else
			begin
				NumToString(TotalFuls, m);
				NumToString(TotalFdls, n);
				tempString := concat(tempString, stringOf(TotalCalls : 5, '  ', TotalMins : 6, '  ', TotalEmail : 5, '  ', TotalPosts : 5, '  '));
				tempString := concat(tempString, stringOf(TotalUls : 3, '/', TotalFUls : 0, ' ' : 3 - length(m), '  ', TotalDLs : 3, '/', TotalFdls : 0, ' ' : 3 - length(n), '  '));
				a := 0;
				for i := 1 to InitSystHand^^.numnodes do
					if not theNodes[i]^.SysOpNode then
						a := a + 1;
				if TotalMins > 14 then
					tempReal := ((TotalMins / (1440 * a)) * 100)
				else
					tempReal := 0;
				i := trunc(tempReal);
				tempString := concat(' T  ', tempString, stringOf(i : 3), '%  ');
				if TotalCalls > 0 then
					i := TotalMins div TotalCalls
				else
					i := 0;
				tempString := concat(tempString, StringOf(i : 6), char(13));
				if not InitSystHand^^.Totals then
					tempString := concat(tempString, '------------------------------------------------------------------------------', char(13));
			end;
			if count2 > count then
			begin
				result := SetFPos(ZLogRef, fsFromStart, count);
				count2 := count2 - count;
				bisho := newHandle(count2);
				result := FSRead(ZLogRef, count2, pointer(bisho^));
				result := SetEOF(ZlogRef, count + count2 + length(tempString));
				result := SetFPos(Zlogref, fsFromStart, count + length(tempString));
				result := FSWrite(ZLogRef, count2, pointer(bisho^));
				DisposHandle(bisho);
			end
			else
				result := SetEOF(ZlogRef, count + length(tempString));
			result := SetFPos(Zlogref, fsFromStart, count);
			count := length(tempString);
			result := FSWrite(ZLogref, count, @tempString[1]);
			result := GetEOF(ZLogRef, count2);
			count := 10000;
			if count2 > count then
				result := SetEOF(ZLogRef, count);
			result := FSClose(ZlogRef);
		end;
	end;

	function FreeK (pathOn: str255): longint;
		var
			tempString: str255;
			tempLong: longint;
			myHParmer: HParmBlkPtr;
			result: OSerr;
	begin
		tempString := pathOn;
		myHParmer := HParmBlkPtr(NewPtr(SizeOf(HParamBlockRec)));
		myHParmer^.ioCompletion := nil;
		myHParmer^.ioNamePtr := @tempString;
		myHParmer^.ioVRefNum := 0;
		myHParmer^.ioVolIndex := -1;
		result := PBHGetVInfo(myHParmer, false);
		if result = noErr then
		begin
			tempLong := longInt(myHParmer^.ioVAlBlkSiz) * longInt(BAnd(myHParmer^.ioVFrBlk, $0000FFFF));
			FreeK := tempLong;
		end
		else
			FreeK := 0;
		DisposPtr(pointer(myHParmer));
	end;

	procedure DLRatioStr;
		var
			tempString2: str255;
	begin
		with theNodes[whichNode]^ do
		begin
			if (thisUser.DownloadedK <> 0) then
				tempString2 := stringOf((thisUser.uploadedk / thisUser.downloadedk) : 0 : 3)
			else
			begin
				if thisUser.uploadedK > 0 then
					tempString2 := '99.999'
				else
					tempString2 := '0.000';
			end;
			loadStr := tempString2;
		end;
	end;

	procedure GoodRatioStr (var loadStr: str255);
	begin
		loadStr := stringOf((1 / (curglobs^.thisUser.DLRatioOneTo)) : 0 : 2);
	end;

	function GetStatLine: str255;
	begin
		GetStatLine := stringOf('C: ', doNumber(TotalCalls), ' • T: ', doNumber(TotalMins), ' • P: ', TotalPosts : 0, ' • U: ', TotalUls : 0, '/', TotalFuls : 0, ' • D: ', TotalDls : 0, '/', TotalFDls : 0, ' • MF: ', doNumber(FreeMem div 1024), 'k • DF: ', doNumber(FreeK(sharedPath) div 1024), 'k • F: ', numFeedbacks : 0, ' • LU: ', InitSystHand^^.lastUser);
	end;

	procedure UpdateStatWindow;
		var
			tsr, t1, t2, t3, t4, t5, t6, t7: str255;
			i, curShow: integer;
			myP: point;
	begin
		if statWindow <> nil then
		begin
			SetPort(statWindow);
			ForeColor(blackColor);
			BackColor(whiteColor);
			EraseRect(statWindow^.portRect);
			TextSize(9);
			TextFont(geneva);
			TextFace([]);
			MoveTo(3, 10);
			tsr := GetStatLine;
			DrawString(tsr);
			GetPen(myP);
			myP.v := myP.v + 3;
			if myP.v > 5 then
			begin
				myP.h := 0;
				MoveTo(myP.h, myP.v);
				myP.h := statWindow^.portRect.right;
				LineTo(myP.h, myP.v);
			end;
			curShow := 1;	{visibleNode}
			repeat
				with theNodes[curshow]^ do
				begin
					if (BoardMode = User) and (thisUser.userNum > 0) then
					begin
						GetPen(myP);
						myP.v := myP.v + 11;{11}
						MoveTo(3, myP.v);
						if newhand^^.birthday then
						begin
							NumToString(thisUser.age, t4);
						end
						else
							t4 := '';
						if newhand^^.gender then
						begin
							if newhand^^.birthday then
								t4 := concat(t4, '/');
							if thisUser.sex then
								t4 := concat(t4, 'M')
							else
								t4 := concat(t4, 'F');
						end;
						if newhand^^.handle and newHand^^.realname then
							t7 := thisUser.Realname
						else if (newhand^^.city) and ((newhand^^.realname and not newhand^^.handle)) or ((newHand^^.handle and not newhand^^.realname)) then
							t7 := concat(thisUser.city, ', ', thisUser.state)
						else
							t7 := '';
						tsr := StringOf('Node ', curShow : 0, ' • ', thisUser.userName, ' #', thisUser.userNum : 0, ' • ', t7, ' (', t4, ') • ', thisUser.phone, ' • S:', thisUser.SL : 0, '/D:', thisUser.DSL : 0, '  (', thisUser.onToday : 0, ')');
						DrawString(tsr);
						if triedChat then
						begin
							TextFace([bold]);
							GetPen(myP);
							myP.h := myP.h + 12;
							MoveTo(myP.h, myP.v);
							ForeColor(greenColor);
							DrawString(chatreason);
							ForeColor(blackColor);
							TextFace([]);
						end;
						GetPen(myP);
						myP.v := myP.v + 11;
						MoveTo(3, myP.v);
						t2 := '';
						for i := 1 to 26 do
							if thisUser.AccessLetter[i] then
								t2 := concat(t2, char(64 + i));
						if length(t2) = 0 then
							t2 := 'None';
{t3 := 'XXXXXXXXXXXXXXXXXXXX';}
{for i := 1 to 10 do}
{if not thisUser.msgFrmAccess[i] then}
{t3[i] := '-';}
						if currentBaud = 0 then
							t4 := 'KB'
						else
							t4 := curBaudNote;
						UserRestricts(thisUser, t6);
						NumToString(ticksLeft(curShow) div longint(60) div longint(60), tsr);
						if (boardSection <> TelnetNegotiation) and (boardSection <> Logon) and (boardSection <> NewUser) then
						begin
							DrawString(concat('AL:', t2, ' • RS:', t6, ' • ', t4, ' • TL:', tsr));
							if thisUser.AlertOn then
							begin
								TextFace([bold]);
								GetPen(myP);
								myP.h := myP.h + 12;
								MoveTo(myP.h, myP.v);
								ForeColor(redColor);
								DrawString('*ALERT*');
								ForeColor(blackColor);
								TextFace([]);
							end;
						end
						else
							DrawString(concat('AL:', t2, ' • RS:', t6, ' • ', t4));
						myP.v := myP.v + 11;
						MoveTo(3, myP.v);
						if thisUser.UDRatioOn then
							DLRatioStr(t1, curShow)
						else
							t1 := 'N/A';
						if thisUser.PCRatioOn then
							t2 := stringOf((thisUser.messagesPosted / thisUser.TotalLogons) : 0 : 2)
						else
							t2 := 'N/A';
						t3 := stringOf(doNumber(thisUser.DownloadedK), 'k');
						t4 := stringOf(doNumber(thisUser.UploadedK), 'k');
						t5 := stringOf(doNumber(thisUser.MessagesPosted), '/', doNumber(thisUser.TotalLogons));
						t6 := stringOf(doNumber(thisUser.DLCredits), 'k');
						if (boardSection <> TelnetNegotiation) and (boardSection <> Logon) and (boardSection <> NewUser) then
							DrawString(stringOf('UDR:', t1, ' (', t4, '/', t3, ') <', doNumber(thisUser.numUploaded), '/', doNumber(thisUser.numDownloaded), '> • DLC: ', t6, ' • PCR: ', t2, ' (', t5, ')', ' • Note:', thisUser.SysOpNote));
						GetPen(myP);
						myP.v := myP.v + 3;
						if myP.v > 5 then
						begin
							myP.h := 0;
							MoveTo(myP.h, myP.v);
							myP.h := statWindow^.portRect.right;
							LineTo(myP.h, myP.v);
						end;
					end
					else if (BoardMode = Terminal) then
					begin
						GetPen(myP);
						myP.v := myP.v + 11;
						MoveTo(3, myP.v);
						NumToString(currentBaud, tsr);
						TSR := concat(tsr, '-N-8-1');
						if inhalfDuplex then
							TSR := concat(tsr, '-HALF')
						else
							TSR := concat(tsr, '-FULL');
						if ansiTerm then
							TSR := concat(tsr, '-ANSI')
						else
							TSR := concat(tsr, '-TTY');
						DrawString(tsr);
						GetPen(myP);
						myP.v := myP.v + 3;
						if myP.v > 5 then
						begin
							myP.h := 0;
							MoveTo(myP.h, myP.v);
							myP.h := statWindow^.portRect.right;
							LineTo(myP.h, myP.v);
						end;
					end
					else if (BoardMode = Failed) and (NumFails >= 3) then
					begin
						GetPen(myP);
						myP.v := myP.v + 11;
						MoveTo(3, myP.v);
						TextFace([bold]);
						ForeColor(redColor);
						NumToString(curShow, tsr);
						tsr := concat('WARNING! NODE ', tsr, ' - INITILIZATION FAILURE');
						DrawString(tsr);
						ForeColor(blackColor);
						TextFace([]);
						GetPen(myP);
						myP.v := myP.v + 3;
						if myP.v > 5 then
						begin
							myP.h := 0;
							MoveTo(myP.h, myP.v);
							myP.h := statWindow^.portRect.right;
							LineTo(myP.h, myP.v);
						end;
					end;
				end;
				curShow := curShow + 1;
			until curShow > InitSystHand^^.numNodes;
		end;
	end;

	function SexToTime (whichTicks: longint): str255;
		var
			ts, ts2, ts3: str255;
			l1, l2, l3: longint;
	begin
		l1 := whichTicks;{seconds}
		l2 := l1 div 60;{minutes}
		l1 := l1 - (l2 * 60);
		l3 := l2 div 60;  {hours}
		l2 := l2 - (l3 * 60);
		NumToString(l1, ts);
		NumToString(l2, ts2);
		NumToString(l3, ts3);
		if length(ts) < 2 then
			ts := concat('0', ts);
		if length(ts2) < 2 then
			ts2 := concat('0', ts2);
		if length(ts3) < 2 then
			ts3 := concat('0', ts3);
		SexToTime := concat(ts3, ':', ts2, ':', ts);
	end;

	function TickToTime (whichTicks: longint): str255;
		var
			ts, ts2, ts3: str255;
			l1, l2, l3: longint;
	begin
		l1 := whichTicks div 60;{seconds}
		l2 := l1 div 60;{minutes}
		l1 := l1 - (l2 * 60);
		l3 := l2 div 60;  {hours}
		l2 := l2 - (l3 * 60);
		NumToString(l1, ts);
		NumToString(l2, ts2);
		NumToString(l3, ts3);
		if length(ts) < 2 then
			ts := concat('0', ts);
		if length(ts2) < 2 then
			ts2 := concat('0', ts2);
		if length(ts3) < 2 then
			ts3 := concat('0', ts3);
		tickToTime := concat(ts3, ':', ts2, ':', ts);
	end;

	function NextDownTicks: longint;
		var
			tempdate, tempdate2, tempdate3: dateTimerec;
			timeNow: longint;
			tempLong, templong2, nextTabby, tempresult: longint;
	begin
		with curglobs^ do
		begin
			if mailer^^.MailerAware then
			begin
				if dailyTabbyTime = 0 then
					nextTabby := -1
				else
				begin
					GetDateTime(templong);
					nextTabby := (dailyTabbyTime - templong) * 60;
				end;
			end;
			GetTime(tempdate3);
			Secs2Date(downTime, tempdate);
			tempdate.year := tempdate3.year;
			tempdate.month := tempdate3.month;
			tempdate.day := tempdate3.day;
			tempdate.dayofWeek := tempdate3.dayofweek;
			Date2Secs(tempdate, downTime);
			Secs2Date(UPTime, tempdate);
			tempdate.year := tempdate3.year;
			tempdate.month := tempdate3.month;
			tempdate.day := tempdate3.day;
			tempdate.dayofWeek := tempdate3.dayofweek;
			Date2Secs(tempdate, UPTime);
			if upTime <> downtime then
			begin
				GetDateTime(timeNow);
				templong := downTime - timeNow;
				if tempLong < 0 then
				begin
					templong := downtime;
					templong := templong + 86400;
					tempLong := templong - timeNow;
					tempresult := templong * 60;
				end
				else
					tempresult := templong * 60;
			end
			else
				tempresult := -1;
			if (nextTabby <> 0) and (mailer^^.MailerAware) then
			begin
				if (tempResult > nextTabby) or (tempResult = -1) then
					tempresult := nextTabby;
			end;
			NextDownTicks := tempresult;
		end;
	end;

	function inDownTime: boolean;
		var
			TEMPDATE3, tempdate: dateTimerec;
			templong: longint;
	begin
		with curglobs^ do
		begin
			GetTime(tempdate3);
			Secs2Date(downTime, tempdate);
			tempdate.year := tempdate3.year;
			tempdate.month := tempdate3.month;
			tempdate.day := tempdate3.day;
			tempdate.dayofWeek := tempdate3.dayofweek;
			Date2Secs(tempdate, downTime);
			Secs2Date(UPTime, tempdate);
			tempdate.year := tempdate3.year;
			tempdate.month := tempdate3.month;
			tempdate.day := tempdate3.day;
			tempdate.dayofWeek := tempdate3.dayofweek;
			Date2Secs(tempdate, UPTime);
			GetDateTime(templong);
			if upTime <> downtime then
			begin
				if (templong < uptime) and (templong > downtime) then
					indowntime := true
				else if (templong < upTime) and (templong < downtime) and not (UPTIME > downtime) then
					inDownTime := true
				else if (uptime < downtime) then
				begin
					uptime := uptime + 86400;
					if (templong < uptime) and (templong > downtime) then
						indowntime := true
					else
						inDowntime := false;
				end
				else
					inDowntime := false;
			end
			else
				indowntime := false;
		end;
	end;

	function ticksLeft (whichNode: integer): longint;
		var
			l1, l2, templong: longint;
	begin
		with theNodes[whichNode]^ do
		begin
			if thisUser.useDayorCall then
				l1 := (longint(thisUser.timeAllowed - thisUser.minOnToday)) * 60 * 60
			else
				l1 := (longint(thisUser.timeAllowed) * 60 * 60);
			l1 := l1 + extratime;
			l2 := tickCount - timebegin;
			templong := l1 - l2;
			if (templong > nextDownticks) and (nextDownTicks > 0) then
				if ((Mailer^^.MailerNode = whichNode) and (Mailer^^.SubLaunchMailer <> 0)) or (Mailer^^.SubLaunchMailer = 0) then
				begin
					templong := nextdownticks;
					countingdown := true;
					lastleft := templong;
				end;
			if countingdown and (templong > lastleft) then
				templong := -1;
			ticksLeft := templong;
		end;
	end;

	procedure Flowie (YesFlow: boolean);
		var
			handshake: SerShk;
			myPB: ParamBlockRec;
	begin
		handshake.errs := 0;
  {$70 was what it was}
		handshake.evts := 0;
   {$08 for DCD, 32 for CTS^^^^}
		handshake.fInX := 0;
		handshake.fXOn := 0;
		handshake.fCTS := 0;
		handshake.fDTR := 0;
		if curglobs^.HWHH then
		begin
			handshake.fCTS := 1;
			handshake.fDTR := 1;
		end
		else
		begin
			if yesFlow then
			begin
				handshake.fInX := 1;  {receive flow control}
				handshake.fXOn := 1;
			end
			else
			begin
				handshake.fInX := 0;
				handshake.fXOn := 0;
			end;
		end;
		handshake.xOn := chr($11);
		handshake.xOff := chr($13);
		with myPB do
		begin
			csCode := 14;
			iocompletion := nil;
			ioVRefNum := 0;
			ioRefNum := curglobs^.inputRef;
		end;
		BlockMove(@handshake, @myPB.csParam, SizeOf(SerShk));
		result := PBControl(@myPB, false);
	end;

	function Get1ComPort: char;
		var
			strleng: longint;
	begin
		with curglobs^ do
		begin
			result := mySDGetBuf(strLeng);
			if strLeng > 0 then
			begin
				strLeng := 1;
				result := mySyncRead(inputRef, strLeng, StripAddress(pointer(@incoming)));
				Get1ComPort := incoming[0];
			end
			else
				Get1ComPort := char(0);
		end;
	end;

	function ComPeriod: boolean;
		var
			KBNunc: keymap;
			tempbool, tempbool2: boolean;
	begin
		GetKeys(KBnunc);
		charnum := 47 div 8;
		bitnum := 7 - (47 mod 8);
		if (BitTst(@KBNunc, 8 * charnum + bitnum)) then
			tempbool := true
		else
			tempbool := false;
		charnum := 55 div 8;
		bitnum := 7 - (55 mod 8);
		if (BitTst(@KBNunc, 8 * charnum + bitnum)) then
			tempbool2 := true
		else
			tempbool2 := false;
		if tempBool and tempBool2 then
			ComPeriod := true
		else
			comPeriod := false;
	end;

	function PrepModem: boolean;
		var
			q, l1, myTimer: longint;
			done: boolean;
			t1: str255;
			gotCh: char;
			i, b: integer;
	begin
		with curglobs^ do
		begin
			if nodeType = 1 then
			begin
				DoBaudReset(MaxBaud);
				Flowie(true);
				if HWHH then
					t1 := modemDrivers^^[modemID].hwOn
				else if (not HWHH) and (not MatchInterface) then
					t1 := modemDrivers^^[modemID].hwOff
				else if MatchInterface then
					t1 := char(0);

				if matchInterface then
					t1 := concat(t1, modemDrivers^^[modemID].lockOff)
				else
					t1 := concat(t1, modemDrivers^^[modemID].lockOn);
				t1 := concat(modemDrivers^^[modemID].bbsInit, t1, char(13));
				l1 := length(t1);
				done := false;
				i := 0;
				ClearInBuf;
				while not done do
				begin
					result := AsyncMWrite(outputRef, l1, ptr(ord4(@t1) + 1));
					myTimer := tickCount;
					gotCh := char(0);
					while ((myTimer + 240) > tickCount) and not ComPeriod and (gotCh <> char(13)) do
						gotCh := get1ComPort;
					i := i + 1;
					if (i > 2) or (gotCh = char(13)) or ComPeriod then
						done := true;
				end;
			end
			else
				gotCh := char(13);
			if gotCh = char(13) then
				PrepModem := true
			else
				PrepModem := false;
		end;
	end;

	procedure LogError (Error: str255; InFore: boolean; NumBeeps: integer);
	external;

	procedure MakeExtList;
		var
			myCPB: CInfoPBRec;
			myHPB: HParamBlockRec;
			fName: str255;
			index, fileRef: integer;
			theDirID, tl: longint;
			TempEx: HermesExDef;
			exInfo: eInfoHand;
			LoadThisExternal, DidAllocate: boolean;
			aHandle: handle;
			result, pbgciResult: OSErr;
	begin
		if myExternals <> nil then
		begin
			HPurge(handle(myExternals));
			DisposHandle(handle(myExternals));
		end;
		myExternals := nil;
		numExternals := 0;
		fName := concat(sharedPath, 'Externals:');
		myHPB.ioCompletion := nil;
		myHPB.ioNamePtr := @fName;
		myHPB.ioVRefNum := 0;
		myHPB.ioVolIndex := -1;
		ErrorRep('PBHGetVInfo', PBHGetVInfo(@myHPB, false));
		fName := concat(sharedPath, 'Externals:');
		myCPB.ioCompletion := nil;
		myCPB.ioNamePtr := @fname;
		myCPB.ioVRefNum := myHPB.ioVRefNum;
		myCPB.ioFDirIndex := 0;
		result := PBGetCatInfo(@myCPB, false);
		myCPB.iovRefNum := myHPB.ioVRefNum;
		myCPB.ioNamePtr := @fName;
		theDirID := myCPB.ioDrDirID;
		myExternals := ExternListHand(NewHandle(0));
		HNoPurge(handle(myExternals));
		index := 1;
		repeat
			fName := '';
			myCPB.ioNamePtr := @fname;
			myCPB.ioFDirIndex := index;
			myCPB.ioDrDirID := theDirID;
			myCPB.ioVrefNum := myHPB.ioVRefNum;
			pbgciResult := PBGetCatInfo(@myCPB, FALSE);
			if pbgciResult = noErr then
				if Pos(';', fName) <> 0 then
				begin
					{ We must have at least one external in the list in order to process this configuration file. }
					if numExternals > 0 then
					begin
						{ The name of the last external we processed must match the base name of this configuration file. }
						if myExternals^^[numExternals].name = Copy(fName, 1, Pos(';', fName) - 1) then
						begin
							{ Delete the base name from the configuration file name. }
							Delete(fName, 1, Pos(';', fName));

							{ If there is another ; in this filename, then use the letter after that ; as the restriction variable. }
							if Pos(';', fName) <> 0 then
							begin
								{ Get the access letter. }
								myExternals^^[numExternals].AccessLetter := Copy(fName, Pos(';', fName) + 1, 1);

								{ Strip the access letter from the file name by copying out the security level. }
								fName := Copy(fName, 1, Pos(';', fName) - 1);
							end;

							{ Decode the remaining portion of the file name to get the security level. }
							StringToNum(fName, tl);
							myExternals^^[numExternals].minSLForMenu := tl;
						end;
					end;
				end
				else if not (BitTst(@myCPB.ioFlAttrib, 3)) then
				begin {we have a file}
					if myCPB.ioFlFndrInfo.fdType = 'XHRM' then
					begin
						fileRef := OpenResFile(concat(sharedPath, 'Externals:', fName));
						if fileRef <> -1 then
						begin
							DidAllocate := false;
							UseResFile(fileRef);
							SetResLoad(false);
							if (Get1Resource('XHRM', 10000) <> nil) then
							begin
								DidAllocate := true;
								numExternals := numExternals + 1;
								SetHandleSize(handle(myExternals), GetHandleSize(handle(myExternals)) + SizeOf(HermesExDef));
								myExternals^^[numExternals].name := fName;
								myExternals^^[numExternals].allTheTime := false;
								myExternals^^[numExternals].GameIdle := false;
								myExternals^^[numExternals].CheckLogon := false;
								myExternals^^[numExternals].CheckMenu := false;
								myExternals^^[numExternals].MenuCommand := char(0);
								myExternals^^[numExternals].minSLForMenu := 1;
								myExternals^^[numExternals].AccessLetter := char(0);
								myExternals^^[numExternals].codeHandle := nil;
								myExternals^^[numExternals].UResoFile := 0;
								myExternals^^[numExternals].userExternal := false;
								myExternals^^[numExternals].sysopExternal := true;
								myExternals^^[numExternals].runtimeExternal := false;
								SetResLoad(true);
								myExternals^^[numExternals].IconHandle := Get1Resource('ICN#', 10000);
								if resError = noErr then
								begin
									DetachResource(myExternals^^[numExternals].iconHandle);
									HNoPurge(myExternals^^[numExternals].iconHandle);
								end;
							end;

							LoadThisExternal := false;
							SetResLoad(false);
							if (Get1Resource('HRMS', 100) <> nil) then
							begin
								SetResLoad(true);
								aHandle := Get1Resource('HRMS', 100);
								if GetHandleSize(aHandle) = sizeOf(eInfoRec) then
								begin
									ReleaseResource(aHandle);
									exInfo := eInfoHand(Get1Resource('HRMS', 100));
									HLock(handle(exInfo));
									if ((exInfo^^.CompiledForVers >= EXTERNALS_VERSION) and (InitSystHand^^.version >= exInfo^^.MinVersReq)) then
										LoadThisExternal := true;
									if LoadThisExternal then
									begin
										if not DidAllocate then
										begin
											numExternals := numExternals + 1;
											SetHandleSize(handle(myExternals), GetHandleSize(handle(myExternals)) + SizeOf(HermesExDef));
											myExternals^^[numExternals].name := fName;
											myExternals^^[numExternals].allTheTime := false;
											myExternals^^[numExternals].GameIdle := false;
											myExternals^^[numExternals].CheckLogon := false;
											myExternals^^[numExternals].CheckMenu := false;
											myExternals^^[numExternals].MenuCommand := char(0);
											myExternals^^[numExternals].minSLForMenu := 1;
											myExternals^^[numExternals].AccessLetter := char(0);
											myExternals^^[numExternals].codeHandle := nil;
											myExternals^^[numExternals].UResoFile := 0;
											myExternals^^[numExternals].userExternal := false;
											myExternals^^[numExternals].sysopExternal := false;
											myExternals^^[numExternals].runtimeExternal := false;
											myExternals^^[numExternals].IconHandle := nil;
										end;
										myExternals^^[numExternals].userExternal := true;
										myExternals^^[numExternals].allTheTime := exInfo^^.allTime;
										myExternals^^[numExternals].GameIdle := exInfo^^.GameIdle;
										myExternals^^[numExternals].CheckLogon := exInfo^^.CheckLogon;
										myExternals^^[numExternals].CheckMenu := exInfo^^.CheckMenu;
										myExternals^^[numExternals].MenuCommand := exInfo^^.MenuCommand;
										myExternals^^[numExternals].minSLForMenu := exInfo^^.minSLforMenu;
										myExternals^^[numExternals].AccessLetter := exInfo^^.AccessLetter;
										myExternals^^[numExternals].codeHandle := Get1Resource('XHRM', 10001);
										if myExternals^^[numExternals].codeHandle = nil then
											myExternals^^[numExternals].codeHandle := Get1Resource('XHRM', 63);
										MoveHHi(myExternals^^[numExternals].codeHandle);
										HLock(myExternals^^[numExternals].codeHandle);
									end
									else
										LogError(concat('@', WhatTime(-1), ' Newer external version required. Unable to load external: ', fName), false, 1);
									HUnlock(handle(exInfo));
									ReleaseResource(handle(exInfo));
								end
								else
								begin
									LogError(concat('@', WhatTime(-1), ' This external is too old to work with this version.'), false, 1);
									LogError(concat('@', ' Unable to load external: ', fName), false, 1);
									ReleaseResource(handle(aHandle));
								end;
								if DidAllocate or LoadThisExternal then
								begin
									myExternals^^[numExternals].UResoFile := fileRef;
									myExternals^^[numExternals].privatesNum := 0;
								end;
								UseResFile(myResourceFile);
								if not myExternals^^[numExternals].userExternal then
									CloseResFile(fileRef);
							end;
						end;
					end; {else}
				end
				else
				begin
					result := FSOpen(concat(sharedPath, 'Externals:', fName, ':main.py'), 0, fileRef);
					if result = noErr then
					begin
						{ Close the main.py file. }
						result := FSClose(fileRef);

						{ Add this external to the list of externals. }
						numExternals := numExternals + 1;
						SetHandleSize(handle(myExternals), GetHandleSize(handle(myExternals)) + SizeOf(HermesExDef));

						{ Initialize the external's base attributes. }
						myExternals^^[numExternals].name := fName;
						myExternals^^[numExternals].allTheTime := false;
						myExternals^^[numExternals].GameIdle := false;
						myExternals^^[numExternals].codeHandle := nil;
						myExternals^^[numExternals].UResoFile := 0;
						myExternals^^[numExternals].userExternal := true;
						myExternals^^[numExternals].sysopExternal := false;
						myExternals^^[numExternals].runtimeExternal := true;
						myExternals^^[numExternals].IconHandle := nil;

						{ Clear the external's other attributes.  These are set by a configuration file in the Externals folder. }
						{ Just in case a configuration file does not exist, we set these values to 'safe' defaults that ensure }
						{ a user will not be able to access an unconfigured external. }
						myExternals^^[numExternals].CheckLogon := false;
						myExternals^^[numExternals].CheckMenu := false;
						myExternals^^[numExternals].MenuCommand := char(0);
						myExternals^^[numExternals].minSLForMenu := 256;
						myExternals^^[numExternals].AccessLetter := char(0);
					end;
				end;
			index := index + 1;
		until (pbgciResult <> noErr);

	{ Try to load our runtime external. }
		fileRef := OpenResFile(concat(sharedPath, 'Runtime:', 'Hermes Python Runtime'));
		if fileRef <> -1 then
		begin
			UseResFile(fileRef);

			numExternals := numExternals + 1;
			runtimeExternalNum := numExternals;

			SetHandleSize(handle(myExternals), GetHandleSize(handle(myExternals)) + SizeOf(HermesExDef));
			myExternals^^[numExternals].name := fName;
			myExternals^^[numExternals].allTheTime := false;
			myExternals^^[numExternals].GameIdle := false;
			myExternals^^[numExternals].CheckLogon := false;
			myExternals^^[numExternals].CheckMenu := false;
			myExternals^^[numExternals].MenuCommand := char(0);
			myExternals^^[numExternals].minSLForMenu := 256;
			myExternals^^[numExternals].AccessLetter := char(0);
			myExternals^^[numExternals].UResoFile := fileRef;
			myExternals^^[numExternals].userExternal := true;
			myExternals^^[numExternals].sysopExternal := false;
			myExternals^^[numExternals].runtimeExternal := false;
			myExternals^^[numExternals].IconHandle := nil;
			myExternals^^[numExternals].privatesNum := 0;

			myExternals^^[numExternals].codeHandle := Get1Resource('XHRM', 63);
			MoveHHi(myExternals^^[numExternals].codeHandle);
			HLock(myExternals^^[numExternals].codeHandle);
		end
		else
			runtimeExternalNum := 0;

	{ Clean everything up. }
		UseResFile(myResourceFile);
		MoveHHi(handle(myExternals));
		if numexternals < 1 then
		begin
			DisposHandle(handle(myExternals));
			myExternals := nil;
		end;
	end;

	procedure DrawExternalsList (theWindow: WindowPtr; item: integer);
		var
			kind: integer;
			h: handle;
			r: rect;
	begin
		if item = 1 then
		begin
			SetPort(theWindow);
			GetDItem(theWindow, 1, kind, h, r);
			LUpdate(theWindow^.visRgn, ExtList);
		end;
	end;

	procedure SysopExternal (message, item: integer; var theEvent: EventRecord; myHerm: HermDataPtr; var XHRMrefcon: longint; ConfigDialog: DialogPtr; PP: procptr);
	inline
		$205f,  	{   movea.l (a7)+,a0  }
		$4e90;	{	jsr(a0)			   }

	procedure CallSysopExternal (message, item: integer; var theEvent: eventRecord);
		var
			temp: str255;
	begin
		temp := sharedPath;
		theSysExtRec^.SysPrivates := handle(SysPrivatesNum);
		theSysExtRec^.HSystPtr := @InitSystHand^^;
		theSysExtRec^.HMForumPtr := pointer(MForum^);
		theSysExtRec^.HMConfPtr := @MConference;
		theSysExtRec^.HTForumPtr := pointer(Forums^);
		theSysExtRec^.HTDirPtr := pointer(forumIdx^);
		theSysExtRec^.HGFilePtr := pointer(intGFileRec^);
		theSysExtRec^.HSecLevelsPtr := pointer(SecLevels^);
		theSysExtRec^.HMailerPtr := pointer(Mailer^);
		theSysExtRec^.filesPath := @temp;
		SetPort(sysConfig);
		UseResFile(myOpenEx.resourceFile);
		SysopExternal(message, item, theEvent, theSysExtRec, myOpenEx.exRefcon, SysConfig, pointer(myOpenEx.codeHandle^));
		UseResFile(myResourceFile);
		SysPrivatesNum := ord4(theSysExtRec^.SysPrivates);
	end;

	procedure CloseSysopExternal;
		var
			theEvent: EventRecord;
			tempInt: integer;
			exInfo: eInfoHand;
	begin
		CallSysopExternal(closeDev, 0, theEvent);
		HUnlock(myOpenEx.codeHandle);
		ReleaseResource(myOpenEx.codeHandle);
		ShortenDITL(sysConfig, myOpenEx.numAddedItems);
		if not myExternals^^[myOpenEx.numExt].userExternal then
			CloseResFile(myOpenEx.resourceFile)
		else
		begin
			UseResFile(myOpenEx.resourceFile);
			exInfo := eInfoHand(Get1Resource('HRMS', 100));
			if exInfo <> nil then
			begin
				HLock(handle(exInfo));
				myExternals^^[numExternals].allTheTime := exInfo^^.allTime;
				myExternals^^[numExternals].GameIdle := exInfo^^.GameIdle;
				myExternals^^[numExternals].CheckLogon := exInfo^^.CheckLogon;
				myExternals^^[numExternals].CheckMenu := exInfo^^.CheckMenu;
				myExternals^^[numExternals].MenuCommand := exInfo^^.MenuCommand;
				myExternals^^[numExternals].minSLForMenu := exInfo^^.minSLforMenu;
				myExternals^^[numExternals].AccessLetter := exInfo^^.AccessLetter;
				HUnlock(handle(exInfo));
				ReleaseResource(handle(exInfo));
			end;
		end;
		UseResFile(myResourceFile);
		SizeWindow(SysConfig, 356, 230, false);
	end;

	procedure UpdateSysConfig (event: eventRecord);
	begin
		DrawDialog(sysConfig);
		CallSysopExternal(updateDev, -1, event);
	end;

	procedure OpenSysopExternal (num: integer);
		var
			DITLhandle: handle;
			sizeMinusNum, numItems: integer;
			theEvent: eventRecord;
	begin
		myOpenEx.numExt := num;
		myOpenEx.number := num;
		myOpenEx.exRefCon := 0;
		if myExternals^^[num].userExternal then
			myOpenEx.resourceFile := myExternals^^[num].UResoFile
		else
			myOpenEx.resourceFile := OpenResFile(concat(sharedPath, 'Externals:', myExternals^^[num].name));
		if myOpenEx.resourceFile <> -1 then
		begin
			UseResFile(myOpenEx.resourceFile);
			myOpenEx.codeHandle := Get1Resource('XHRM', 10000);
			MoveHHi(myOpenEx.codeHandle);
			HLock(myOpenEx.codeHandle);
			DITLHandle := Get1Resource('DITL', 10000);
			AppendDITL(sysConfig, DITLHandle, overlayDITL);
			ReleaseResource(DITLHandle);
			myOpenEx.numAddedItems := CountDITL(sysConfig) - 1;
			CallSysopExternal(initDev, 0, theEvent);
			SetPort(sysConfig);
			InvalRect(sysConfig^.portRect);
		end;
		UseResFile(myResourceFile);
	end;

	procedure OpenSystemConfig (whichExternal: integer);
		type
			stuffLDEF = record
					oldIC: array[0..31] of LONGINT;
					oldMk: array[0..31] of LONGINT;
					name: str255;
				end;
		var
			Dtype, j, i, therow: integer;
			DItem: handle;
			tempRect, dataBounds, tr2: rect;
			cSize: cell;
			stuffer: stuffLDEF;
			theDialogPtr: dialogPeek;
	begin
		i := 0;
		for j := 1 to numExternals do
		begin
			if myExternals^^[j].SysopExternal then
				i := i + 1;
		end;
		if i > 0 then
		begin
			if SysConfig = nil then
			begin
				if numExternals > 0 then
				begin
					SysConfig := GetNewDialog(1541, nil, pointer(-1));
					SetPort(sysConfig);
					SetGeneva(sysConfig);

					GetDItem(SysConfig, 1, DType, DItem, tempRect);
					tr2 := temprect;
					tempRect.right := tempRect.right - 15;
					SetRect(dataBounds, 0, 0, 1, 0);
					cSize.h := tempRect.right - tempRect.left;
					cSize.v := 57;
					ExtList := LNew(tempRect, dataBounds, cSize, 10000, SysConfig, FALSE, FALSE, FALSE, TRUE);
					ExtList^^.selFlags := lOnlyOne + lNoNilHiLite;
					SetDItem(SysConfig, 1, DType, @DrawExternalsList, tr2);
					whichexternal := 0;
					for i := 1 to numExternals do
					begin
						if myExternals^^[i].sysopExternal then
						begin
							if whichexternal = 0 then
								whichexternal := i;
							theRow := LAddRow(1, 200, ExtList);
							cSize.v := theRow;
							cSize.h := 0;
							stuffer.name := myExternals^^[i].name;
							if myExternals^^[i].iconHandle <> nil then
								BlockMove(pointer(myExternals^^[i].iconHandle^), @stuffer, 256)
							else
							begin
								DItem := GetResource('ICN#', 6002);
								HLock(DItem);
								BlockMove(pointer(DItem^), @stuffer, 256);
								HUnlock(DItem);
								ReleaseResource(DItem);
							end;
							LSetCell(@stuffer, 257 + length(stuffer.name), cSize, ExtList);
						end;
					end;
					ShowWindow(SysConfig);
					cSize := Cell($00000000);
					cSize.v := 0;
					LSetSelect(TRUE, cSize, ExtList);
					LDoDraw(true, extList);
					OpenSysopExternal(whichExternal);
				end
				else
				begin
					ProblemRep(RetInStr(610));{There are no external modules installed!}
				end;
			end
			else
				SelectWindow(sysConfig);
		end
		else
			ProblemRep(RetInStr(611));{There are no SysOp externals installed!}
	end;

	procedure ClickSystemConfig (theEvent: EventRecord; itemHit: integer);
		var
			myPt: point;
			tempCell: cell;
			dType, i: integer;
			DItem: handle;
			tempRect: rect;
			got: boolean;
	begin
		setPort(SysConfig);
		myPt := theEvent.where;
		GlobalToLocal(myPt);
		if itemHit = 1 then
		begin
			if LClick(myPt, theEvent.modifiers, ExtList) then
				;
			tempCell.h := 0;
			tempCell.v := 0;
			if LGetSelect(true, tempCell, ExtList) then
			begin
				tempCell.v := tempCell.v + 1;
				dType := 0;
				i := 0;
				repeat
					i := i + 1;
					if myExternals^^[i].sysopExternal then
						DType := dType + 1;
				until (dType = tempCell.v);
				tempCell.v := i - 1;
				if (tempCell.v + 1) <> myOpenEx.number then
				begin
					CloseSysopExternal;
					SetPort(sysConfig);
					GetDItem(SysConfig, 1, DType, DItem, tempRect);
					tempRect.left := tempRect.right;
					tempRect.right := sysConfig^.portRect.right;
					EraseRect(tempRect);
					OpenSysopExternal(tempCell.v + 1);
				end;
			end
			else
			begin
				i := 0;
				dType := 0;
				repeat
					i := i + 1;
					if myExternals^^[i].sysopExternal then
						dType := dType + 1;
				until (i = myOpenEx.number);
				tempCell.v := dType - 1;
				tempCell.h := 0;
				LSetSelect(true, tempCell, ExtList);
			end;
		end
		else
		begin
			CallSysopExternal(hitDev, itemHit, theEvent);
		end;
	end;

	procedure CloseSystemConfig;
		var
			i: integer;
	begin
		if sysConfig <> nil then
		begin
			CloseSysopExternal;
			LDispose(ExtList);
			doSystRec(true);
			DisposDialog(SysConfig);
			SysConfig := nil;
		end;
	end;
end.