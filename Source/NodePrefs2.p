{Segments: NodePrefs2_1}
unit NodePrefs2;

interface

	uses
		AppleTalk, ADSP, Serial, Sound, CommResources, CRMSerialDevices, TCPTypes, Initial;

	procedure SetTextBox (theDialog: dialogPtr; item: integer; text: str255);
	function GetTextBox (theDialog: dialogPtr; item: integer): str255;
	procedure SetCheckBox (theDialog: dialogPtr; item: integer; up: boolean);
	function GetCheckBox (theDialog: dialogPtr; item: integer): boolean;
	procedure SetControlBox (Temp: DialogPtr; P: Integer; TempString: Str255; Toof: Boolean);
	procedure AddListString (theString: Str255; theList: ListHandle);
	procedure SetGeneva (Dlog: DialogPtr);
	function Security (which: integer): integer;
	function GetSecurity (which: integer): integer;
	function EscDown: boolean;
	function OptionDown: boolean;
	procedure ProblemRep (tellUser: str255);
	function ModalQuestion (askWhat: str255; saveBox, yesNo: boolean): integer;
	function RetInStr (index: integer): str255;
	function GetFNameFromPath (path: str255): str255;
	function TotalCalls: longint;
	function TotalMins: longint;
	function TotalEmail: longint;
	function TotalPosts: longint;
	function TotalUls: longint;
	function TotalDLs: longint;
	function TotalFUls: longint;
	function TotalFDls: longint;
	function TotalKUl: longint;
	function TotalKDl: longint;
	function makeADir (path: str255): OSerr;
	function WhatUser (node: integer): Str255;
	function DrawTime (well: longint): str255;
	function UpDown (Dlog: DialogPtr; Box: Integer; Value, Adder, Hi, Lo: LongInt): LongInt;
	function UpDownReal (Dlog: DialogPtr; Box: Integer; Value, Adder, Hi, Lo: Real): Real;
	procedure frameit (theDilg: dialogptr; item: integer);
	function usemodaltime (theDialog: dialogPtr; var theEvent: eventRecord; var itemHit: integer): boolean;
	procedure giveBBSTime;
	procedure giveBBSSpecialTime;
	function Appletalk: boolean;
	function DirOp (WhichDir, SubDir: Integer; DirUser: UserRec): Boolean;
	function AreaOp (WhichDir: Integer; DirUser: UserRec): Boolean;
	function MForumOp (Forum: Integer; DirUser: UserRec): Boolean;
	function MConferenceOp (Forum, Conf: Integer; DirUser: UserRec): Boolean;
	function FindUser (searchString: str255; var userFound: UserRec): boolean;
	function CmdDown: Boolean;
	function secs2Time (howmanysecs: longint): str255;
	procedure GoHome;
	procedure WriteTempLog2Log;
	procedure LogThis (LogIt: str255; color: integer);
	procedure SysopLog (toLog: str255; color: integer);
	procedure ReadExtended (theFil: filEntryRec; whichDir, whichSub: integer);
	function SysopReadExtended (theFil: filEntryRec; whichDir, whichSub: integer): CharsHandle;
	procedure InitUserRec;
	procedure InitAllVars;
	procedure ResetUserColors (var theUser: UserRec);
	procedure ResetSystemColors (syst: SystHand);
	procedure SaveEmailData;
	procedure OpenEmail;
	procedure CloseEmail;
	procedure CloseBase;
	procedure ClearInBuf;
	function ForumOk (dir: integer): Boolean;
	function SubDirOk (dir, sub: Integer): Boolean;
	function DownloadOk (dir, sub: Integer): Boolean;
	function MForumOk (Which: integer): boolean;
	function MConferenceOk (wForum, wConf: Integer): Boolean;
	function FindSub (dir, sub: Integer): Integer;
	function FindArea (dir: Integer): Integer;
	function HowManySubs (dir: integer): Integer;
	function getdate (well: longint): Str255;
	function whattime (well: longint): Str255;
	function DoNumber (t2: longint): Str255;
	function AgeOk (howold, isit: integer): Boolean;
	function CheckDays (DaysBack: integer): longint;
	procedure SaveText (ThePath, TheText: str255);
	function SetIndString (theID, index: Integer; newStr: Str255): OSErr;
	procedure SetDItemText (dialog: DialogPtr; item: INTEGER; text: Str255);
	procedure GetDItemText (dialog: DialogPtr; item: INTEGER; var text: Str255);

implementation

{$S NodePrefs2_1}


	procedure SetDItemText (dialog: DialogPtr; item: INTEGER; text: Str255);
		var
			itemRect: Rect;
			itemHandle: Handle;
			itemType: INTEGER;
	begin
		GetDItem(dialog, item, itemType, itemHandle, itemRect);
		if (itemHandle <> nil) then
			SetIText(itemHandle, text);
	end;

	procedure GetDItemText (dialog: DialogPtr; item: INTEGER; var text: Str255);
		var
			itemRect: Rect;
			itemHandle: Handle;
			itemType: INTEGER;
	begin
		GetDItem(dialog, item, itemType, itemHandle, itemRect);
		if (itemHandle <> nil) then
			GetIText(itemHandle, text)
		else
			text := '';
	end;

	function GetIndStr (theID, index: Integer): Str255;
		var
			theString: Str255;
	begin
		GetIndString(theString, theID, index);
		GetIndStr := theString;
	end;  { of func GetIndStr }

	function SetIndString (theID, index: Integer; newStr: Str255): OSErr;
		var
			offset, place: LongInt;
			Hndl: Handle;
			TotalStrings: ^Integer;
			i, theError: Integer;
			EmptyCh: char;
	begin
		EmptyCh := char(0);
		Hndl := GetResource('STR#', theID);			{ use Get1Resource to limit search to current resource fork }
		if Hndl <> nil then
		begin
			HNoPurge(Hndl);
			TotalStrings := Pointer(ord4(hndl^));
			if index > TotalStrings^ then			{ append string(s) }
			begin
				for i := Succ(TotalStrings^) to Pred(index) do
					place := PtrAndHand(Pointer(Ord4(@EmptyCh) + 1), Hndl, 1);		{ append nul to STR# }
				place := PtrAndHand(Pointer(Ord4(@newStr)), Hndl, Succ(Length(newStr)));	{ append string to STR# }
				TotalStrings^ := index;			{ set number of strings to reflect addition(s) }
			end
			else			{ replace existing string with new string }
			begin
				offset := 2;
				for i := 1 to Pred(index) do		{ get character offset of specified 'STR#' entry }
					offset := offset + Succ(Length(GetIndStr(theID, i)));
				place := Munger(Hndl, offset, nil, Succ(Length(GetIndStr(theID, index))), Pointer(Ord4(@newStr)), Succ(Length(newStr)));
			end;
			ChangedResource(Hndl);
			theError := ResError;
			if theError = noErr then
				WriteResource(Hndl);
			HPurge(Hndl);
			ReleaseResource(Hndl);
		end
		else
			theError := resNotFound;
		SetIndString := theError;
	end; {of func SetIndString}

	function CheckDays (DaysBack: integer): longint;
		var
			secs: longint;
			i: integer;
			tDate: DateTimeRec;
	begin
		GetDateTime(secs);
		Secs2Date(secs, tDate);
		for i := 1 to DaysBack do
		begin
			tDate.day := tDate.day - 1;
			tDate.dayOfWeek := tDate.dayOfWeek - 1;
			if (tDate.dayOfWeek <= 0) then
				tDate.dayOfWeek := 7;
			if (tDate.day <= 0) then
			begin
				tDate.month := tDate.month - 1;
				if (tDate.month <= 0) then
				begin
					tDate.month := 12;
					tDate.year := tDate.year - 1;
				end;
				case tDate.month of
					1, 3, 5, 7, 9, 11: 
						tDate.day := 31;
					2: 
						tDate.day := 28;
					4, 6, 8, 10, 12: 
						tDate.day := 30;
				end;
			end;
		end;
		Date2Secs(tDate, secs);
		CheckDays := secs;
	end;

	function AgeOk (howold, isit: integer): Boolean;
		var
			tb2: boolean;
	begin
		tb2 := true;
		if howold = -1 then
			howold := curGlobs^.thisUser.age;
		if (howOld >= isit) or (not NewHand^^.BirthDay) then
			tb2 := True
		else
			tb2 := False;
		AgeOk := Tb2;
	end;

	function DoNumber (t2: longint): Str255;
		var
			x, z: integer;
			a, b, c, d, t1: str255;
	begin
		t1 := stringOf(t2 : 0);
		if length(t1) > 9 then
		begin
			a := copy(t1, length(t1) - 2, 3);
			delete(t1, length(t1) - 2, 3);
			b := copy(t1, length(t1) - 2, 3);
			delete(t1, length(t1) - 2, 3);
			c := copy(t1, length(t1) - 2, 3);
			delete(t1, length(t1) - 2, 3);
			d := copy(t1, length(t1) - 2, 3);
			t1 := concat(d, ',', c, ',', b, ',', a);
		end
		else if length(t1) > 6 then
		begin
			a := copy(t1, length(t1) - 2, 3);
			delete(t1, length(t1) - 2, 3);
			b := copy(t1, length(t1) - 2, 3);
			delete(t1, length(t1) - 2, 3);
			c := copy(t1, length(t1) - 2, 3);
			t1 := concat(c, ',', b, ',', a);
		end
		else if length(t1) > 3 then
		begin
			a := copy(t1, length(t1) - 2, 3);
			delete(t1, length(t1) - 2, 3);
			b := copy(t1, length(t1) - 2, 3);
			t1 := concat(b, ',', a);
		end;
		DoNumber := t1;
	end;

	function HowManySubs (dir: integer): Integer;
		var
			tb2: Boolean;
			b, c, i: integer;
	begin
		b := 0;
		c := 0;
		with CurGlobs^ do
		begin
			for i := 1 to forumIdx^^.numDirs[dir] do
			begin
				b := b + 1;
				tb2 := true;
				if forumIdx^^.restriction[dir] <> char(0) then
					if thisUser.AccessLetter[byte(forumIdx^^.restriction[dir]) - byte(64)] then
						tb2 := true
					else
						tb2 := false;
				if tb2 and (thisUser.DSL >= forumIdx^^.minDSL[dir]) and (ageOk(-1, forumIdx^^.Age[dir])) then
				begin
					if forums^^[dir].dr[i].restriction <> char(0) then
						if thisUser.AccessLetter[(byte(forums^^[dir].dr[i].restriction) - byte(64))] then
							tb2 := true
						else
							tb2 := false;
				end
				else
					tb2 := false;
				if tb2 and (thisUser.DSL >= forums^^[dir].dr[i].minDSL) and (ageOk(-1, forums^^[dir].dr[i].minAge)) then
					c := c + 1;
			end;
		end;
		HowManySubs := c;
	end;

	function FindSub (dir, sub: Integer): Integer;
		var
			tb2: Boolean;
			b, c, i: integer;
	begin
		b := 0;
		c := 0;
		with CurGlobs^ do
		begin
			for i := 1 to forumIdx^^.numDirs[dir] do
			begin
				b := b + 1;
				tb2 := true;
				if forumIdx^^.restriction[dir] <> char(0) then
					if thisUser.AccessLetter[byte(forumIdx^^.restriction[dir]) - byte(64)] then
						tb2 := true
					else
						tb2 := false;
				if tb2 and (thisUser.DSL >= forumIdx^^.minDSL[dir]) and (AgeOk(-1, forumIdx^^.Age[dir])) then
				begin
					if forums^^[dir].dr[i].restriction <> char(0) then
						if thisUser.AccessLetter[(byte(forums^^[dir].dr[i].restriction) - byte(64))] then
							tb2 := true
						else
							tb2 := false;
				end
				else
					tb2 := false;
				if tb2 and (thisUser.DSL >= forums^^[dir].dr[i].minDSL) and (AgeOk(-1, forums^^[dir].dr[i].minAge)) then
				begin
					c := c + 1;
					if (c = sub) then
						FindSub := b;
				end;
			end;
		end;
	end;

	function ForumOk (dir: integer): Boolean;
		var
			tb2: Boolean;
	begin
		with CurGlobs^ do
		begin
			if dir < ForumIdx^^.NumForums then
			begin
				tb2 := true;
				if forumIdx^^.restriction[dir] <> char(0) then
					if thisUser.AccessLetter[byte(forumIdx^^.restriction[dir]) - byte(64)] then
						tb2 := true
					else
						tb2 := false;
				if tb2 and (thisUser.DSL >= forumIdx^^.minDSL[dir]) and (AgeOk(-1, forumIdx^^.Age[dir])) then
					ForumOk := True
				else
					ForumOk := False;
				if (dir = 0) and thisuser.CoSysop then
					ForumOk := true
				else if (dir = 0) then
					forumOk := False;
			end
			else
				ForumOk := False;
		end;
	end;

	function FindArea (dir: integer): Integer;
		var
			tb2: Boolean;
			b, c, i, d: integer;
	begin
		with CurGlobs^ do
		begin
			i := 1;
			b := 0;
			while (i < forumIdx^^.numforums) and (b <> dir) do
			begin
				tb2 := true;
				if forumIdx^^.restriction[i] <> char(0) then
					if thisUser.AccessLetter[byte(forumIdx^^.restriction[i]) - byte(64)] then
						tb2 := true
					else
						tb2 := false;
				if tb2 and (thisUser.DSL >= forumIdx^^.minDSL[i]) and (AgeOk(-1, forumIdx^^.Age[i])) then
					b := b + 1;
				i := i + 1;
			end;
			FindArea := i - 1;
		end;
	end;

	function DownloadOk (dir, sub: Integer): Boolean;
		var
			tb2: Boolean;
	begin
		with CurGlobs^ do
		begin
			if sub <= ForumIdx^^.NumDirs[dir] then
			begin
				tb2 := true;
				if forumIdx^^.restriction[dir] <> char(0) then
					if thisUser.AccessLetter[byte(forumIdx^^.restriction[dir]) - byte(64)] then
						tb2 := true
					else
						tb2 := false;
				if tb2 and (thisUser.DSL >= forumIdx^^.minDsl[dir]) and (AgeOk(-1, forumIdx^^.Age[dir])) then
				begin
					if forums^^[dir].dr[sub].restriction <> char(0) then
						if thisUser.AccessLetter[(byte(forums^^[dir].dr[sub].restriction) - byte(64))] then
							tb2 := true
						else
							tb2 := false;
				end
				else
					tb2 := false;
				if tb2 and (thisUser.DSL >= forums^^[dir].dr[sub].DSLtoDL) and (AgeOk(-1, forums^^[dir].dr[sub].minAge)) then
					DownloadOk := True
				else
					DownloadOk := False;
			end
			else
				DownloadOk := False;
		end;
	end;

	function SubDirOk (dir, sub: Integer): Boolean;
		var
			tb2: Boolean;
	begin
		with CurGlobs^ do
		begin
			if sub <= ForumIdx^^.NumDirs[dir] then
			begin
				tb2 := true;
				if forumIdx^^.restriction[dir] <> char(0) then
					if thisUser.AccessLetter[byte(forumIdx^^.restriction[dir]) - byte(64)] then
						tb2 := true
					else
						tb2 := false;
				if tb2 and (thisUser.DSL >= forumIdx^^.minDSL[dir]) and (AgeOk(-1, forumIdx^^.Age[dir])) then
				begin
					if forums^^[dir].dr[sub].restriction <> char(0) then
						if thisUser.AccessLetter[(byte(forums^^[dir].dr[sub].restriction) - byte(64))] then
							tb2 := true
						else
							tb2 := false;
				end
				else
					tb2 := false;
				if tb2 and (thisUser.DSL >= forums^^[dir].dr[sub].minDSL) and (AgeOk(-1, forums^^[dir].dr[sub].minAge)) then
					SubDirOk := True
				else
					SubDirOk := False;
			end
			else
				SubDirOk := False;
		end;
	end;

	function MForumOk (Which: integer): boolean;
		var
			tb: boolean;
	begin
		with CurGlobs^ do
		begin
			if Which <= InitSystHand^^.numMForums then
			begin
				tb := true;
				if MForum^^[Which].AccessLetter <> char(0) then
					if thisUser.AccessLetter[byte(MForum^^[Which].AccessLetter) - byte(64)] then
						tb := true
					else
						tb := false;
				if tb and (thisUser.SL >= MForum^^[Which].MinSL) and (AgeOk(-1, MForum^^[Which].MinAge)) then
					MForumOk := True
				else
					MForumOk := False;
			end
			else
				MForumOk := False;
		end;
	end;

	function MConferenceOk (wForum, wConf: Integer): Boolean;
		var
			tb: Boolean;
	begin
		with CurGlobs^ do
		begin
			if wConf <= MForum^^[wForum].NumConferences then
			begin
				tb := true;
				if MConference[wForum]^^[wConf].AccessLetter <> char(0) then
					if thisUser.AccessLetter[byte(MConference[wForum]^^[wConf].AccessLetter) - byte(64)] then
						tb := true
					else
						tb := false;
				if tb and (thisUser.SL >= MConference[wForum]^^[wConf].SLtoRead) then
					tb := true
				else
					tb := false;
				if tb and (AgeOk(-1, MConference[wForum]^^[wConf].MinAge)) then
					tb := true
				else
					tb := false;
			end
			else
				tb := false;
			MConferenceOk := tb;
		end;
	end;

	procedure IdleUser;
	external;

	procedure giveBBSTime;
		var
			savedNode, i: integer;
			savePort: GrafPtr;
	begin
		GetPort(savePort);
		if lastIdle + 15 < tickCount then
		begin
			savedNode := activeNode;
			for i := 1 to InitSystHand^^.numNodes do
			begin
				curGlobs := theNodes[i];
				activeNode := i;
				IdleUser;
			end;
			activeNode := savedNode;
			curGlobs := theNodes[activeNode];
			lastIdle := tickCount;
		end;
		SetPort(savePort);
	end;

	procedure giveBBSSpecialTime;
		var
			savedNode, i: integer;
			savePort: GrafPtr;
	begin
		GetPort(savePort);
		if lastIdle + 15 < tickCount then
		begin
			savedNode := activeNode;
			for i := 1 to InitSystHand^^.numNodes do
				if i <> savedNode then
				begin
					curGlobs := theNodes[i];
					activeNode := i;
					IdleUser;
				end;
			activeNode := savedNode;
			curGlobs := theNodes[activeNode];
			lastIdle := tickCount;
		end;
		SetPort(savePort);
	end;

	function usemodaltime (theDialog: dialogPtr; var theEvent: eventRecord; var itemHit: integer): boolean;
		var
			myPt: point;
			key: char;
			kind: integer;
			h: handle;
			r: rect;
	begin
		usemodaltime := false;
		if theEvent.what <> keydown then
			giveBBSTime
		else
			case BAnd(theevent.message, charCodeMask) of
				13, 3: 
				begin
					itemHit := ok;
					usemodaltime := true;
				end;
			end;
	end;

	procedure SetControlBox (Temp: DialogPtr; P: Integer; TempString: Str255; Toof: Boolean);
		var
			DType: Integer;
			DItem: Handle;
			CItem: controlhandle;
			tempRect: Rect;
	begin
		ShowDItem(Temp, P);
		GetDItem(Temp, P, DType, DItem, tempRect);
		SetCTitle(ControlHandle(DItem), tempString);
		CItem := Pointer(DItem);
		if Toof then
			SetCtlValue(CItem, 1)
		else
			SetCtlValue(CItem, 0);
	end;

	procedure clearInBuf;
		var
			result: OSerr;
	begin
		with curGlobs^ do
		begin
			if nodeType = 1 then
			begin
				result := Control(inputRef, 23, nil);
				result := Control(inputRef, 22, nil);
				result := KillIO(inputRef);
				result := KillIO(outputRef);
				typeBuffer := '';
				if toBeSent <> nil then
				begin
					HPurge(handle(toBeSent));
					DisposHandle(toBeSent);
				end;
				toBeSent := nil;
			end
			else if (nodeType = 2) then
			begin

			end;
		end;
	end;

	procedure CloseBase;
	begin
		with curglobs^ do
		begin
			if (curBase <> nil) then
			begin
				HPurge(handle(curBase));
				DisposHandle(handle(curBase));
			end;
			curNumMess := 0;
			curBase := nil;
		end;
	end;

	procedure SaveEmailData;
		var
			result: OSerr;
			MailRef, i: integer;
			count, tempLong: longInt;
			pathToEm: str255;
	begin
		with curglobs^ do
		begin
			if emailDirty and (theEmail <> nil) then
			begin
				HLock(handle(theEMail));
				pathToEm := concat(InitSystHand^^.MsgsPath, 'Email:EMail Data');
				result := FSDelete(pathToEm, 0);
				result := Create(pathToEm, 0, 'HRMS', 'DATA');
				result := FSOpen(pathToEm, 0, MailRef);
				if result = noErr then
				begin
					count := GetHandleSize(handle(theEmail));
					result := FSWrite(MailRef, count, pointer(theEmail^));
					result := FSClose(MailRef);
				end;
				HUnLock(handle(theEMail));
			end;
		end;
	end;

	procedure CloseEMail;
	begin
		with curglobs^ do
		begin
			if (theEmail <> nil) then
			begin
				if emailDirty then
					SaveEmailData;
				emailDirty := false;
				HUnlock(handle(theEmail));
			end;
		end;
	end;

	procedure OpenEMail;
		var
			result: OSerr;
			EMRef, b, i: integer;
			tempLong: longInt;
			numAvail: longint;
	begin
		if (theEmail = nil) then
		begin
			result := FSOpen(concat(InitSystHand^^.MsgsPath, 'Email:', 'EMail Data'), 0, EMRef);
			if result = noErr then
			begin
				result := GetEOF(EMref, tempLong);
				availEmails := tempLong div SizeOf(emailRec);
				theEmail := mesghand(NewHandle(longint(availEmails) * SizeOf(emailRec)));
				HNoPurge(handle(theEmail));
				if memError = noErr then
				begin
					tempLong := longint(availEmails) * SizeOf(emailRec);
					HLock(handle(theEmail));
					result := FSRead(emRef, tempLong, pointer(theEmail^));
					HUnlock(handle(theEmail));
					emailDirty := false;
				end
				else
				begin
					availEmails := 0;
					SysBeep(10);
				end;
				result := FSClose(EMref);
			end
			else
			begin
				theEmail := mesgHand(NewHandle(0));
				HNoPurge(handle(theEmail));
				emailDirty := false;
				availEmails := 0;
			end;
		end;
	end;

	procedure RemoveSlowDeviceFiles;
	external;

	procedure ResetPrivateData (Which: integer);
	external;

	procedure InitAllVars;
		var
			tempLong2, tempLong: longInt;
			i: integer;
	begin
		with curglobs^ do
		begin
			rawStdin := false;
			noPause := false;
			wasSearching := false;
			WasAMsg := false;
			CountTimeWarn := 0;
			GameIdleOn := false;
			NewMsg := False;
			Reply := False;
			wasAnonymous := False;
			FromBeg := False;
			MenuCommands := '';
			numrings := 1;
			savecolor := 0;
			SysopLogon := false;
			prompting := false;
			negateBCR := false;
			spying := 0;
			amSpying := false;
			subtracton := 0;
			thisUser.UserNum := 1;
			OpenEmail;
			numFeedbacks := 0;
			for i := 1 to AvailEmails do
				if (theEmail^^[i - 1].toUser = 1) and (theEmail^^[i - 1].mType = 1) then
					numFeedbacks := numFeedbacks + 1;
			CloseEmail;
			if myEmailList <> nil then
			begin
				DisposHandle(handle(myEmailList));
				myEmailList := nil;
			end;
			thisUser.UserNum := -1;
			thisUser.PauseScreen := false;
			thisUser.ScrnHght := 3000;
			thisUser.TerminalType := 0;
			thisUser.ColorTerminal := false;
			thisUser.SL := 10;
			thisUser.ScreenClears := true;
			validLogon := false;
			wasMadeTempSysop := false;
			typeBuffer := '';
			SetHandleSize(handle(sysopKeyBuffer), 0);
			HelpNum := 0;
			threadMode := false;
			lastleft := -1;
			hangingUp := -1;
			countingdown := false;
			ListingHelp := false;
			useWorkspace := 0;
			fromMsgScan := false;
			inScroll := false;
			UseNode := true;
			TheChat.ToNode := 0;
			TheChat.PrivateRequest := 0;
			ResetPrivateData(activeNode);
			TheChat.WhereFrom := Nowhere;
			TheChat.TheMessage[1] := char(0);
			TheChat.TheMessage[2] := char(0);
			TheChat.TheMessage[3] := char(0);
			TheChat.Status := Chatting;
			TheChat.ChannelNumber := -1;
			TheChat.InputPos.v := 0;
			TheChat.InputPos.h := 0;
			TheChat.OutputPos := 0;
			TheChat.BlockWho := -1;
			TheChat.BufferSize := 0;
			if TheChat.Buffer <> nil then
			begin
				DisposHandle(handle(TheChat.Buffer));
				TheChat.Buffer := nil;
			end;
			saveInForum := 1;
			FileTransit^^.numFiles := 0;
			FileTransit^^.batchTime := 0;
			FileTransit^^.batchKBytes := 0;
			sendLogOff := false;
			realSL := -1;
			triedChat := false;
			newFeed := false;
			goBackToLogon := false;
			FromDetach := false;
			inForum := 1;
			endQScan := false;
			continuous := false;
			fromQScan := false;
			stopRemote := false;
			gettingANSI := false;
			readMsgs := false;
			alerted := false;
			shutdownsoon := false;
			inNScan := false;
			inZScan := false;
			inTransfer := false;
			inDir := 1;
			inRealDir := 1;
			inSubDir := 1;
			inRealSubDir := 1;
			mesRead := 0;
			displayConf := 1;
			inConf := 1;
			inforum := 1;
			XFerAutoStart := 0;
			timeFlagged := false;
			BoardAction := none;
			BoardSection := MainMenu;
			Prompting := false;
			extraTime := 0;
			TimeBegin := 0;
			AnsInProgress := '';
			LnsPause := 0;
			quit := 0;
			CloseBase;
			HiLiteMenu(0);
			if curOpenDir <> nil then
			begin
				HPurge(handle(curOpenDir));
				DisposHandle(handle(curOpenDir));
			end;
			curOpenDir := nil;
			dirOpenNum := -1;
			subDirOpenNum := -1;
			inits := inits + 1;
			clearInBuf;
			RemoveSlowDeviceFiles;
		end;
	end;

	procedure ResetUserColors (var theUser: UserRec);
	begin
		with theUser do
		begin
			Foregrounds[0] := 7;
			Backgrounds[0] := 0;
			Intense[0] := false;
			Underlines[0] := false;
			Blinking[0] := false;
			foregrounds[1] := 6;
			backgrounds[1] := 0;
			Intense[1] := false;
			Underlines[1] := false;
			Blinking[1] := false;
			foregrounds[2] := 3;
			backgrounds[2] := 0;
			Intense[2] := false;
			underlines[2] := false;
			Blinking[2] := false;
			foregrounds[3] := 5;
			backgrounds[3] := 0;
			Intense[3] := false;
			underlines[3] := false;
			Blinking[3] := false;
			foregrounds[4] := 7;
			backgrounds[4] := 4;
			Intense[4] := true;
			underlines[4] := false;
			Blinking[4] := false;
			foregrounds[5] := 2;
			backgrounds[5] := 0;
			Intense[5] := true;
			underlines[5] := false;
			Blinking[5] := false;
			foregrounds[6] := 1;
			backgrounds[6] := 0;
			Intense[6] := false;
			underlines[6] := false;
			Blinking[6] := false;
			foregrounds[7] := 7;
			backgrounds[7] := 0;
			Intense[7] := true;
			underlines[7] := false;
			Blinking[7] := false;
			foregrounds[8] := 6;
			backgrounds[8] := 0;
			Intense[8] := true;
			underlines[8] := false;
			Blinking[8] := false;
			Foregrounds[9] := 5;
			Backgrounds[9] := 0;
			Intense[9] := true;
			Underlines[9] := false;
			Blinking[9] := false;
			Foregrounds[10] := 7;
			Backgrounds[10] := 1;
			Intense[10] := true;
			Underlines[10] := false;
			Blinking[10] := false;
			Foregrounds[11] := 0;
			Backgrounds[11] := 7;
			Intense[11] := false;
			Underlines[11] := false;
			Blinking[11] := false;
			Foregrounds[12] := 4;
			Backgrounds[12] := 5;
			Intense[12] := false;
			Underlines[12] := false;
			Blinking[12] := false;
			Foregrounds[13] := 4;
			Backgrounds[13] := 6;
			Intense[13] := false;
			Underlines[13] := false;
			Blinking[13] := false;
			Foregrounds[14] := 4;
			Backgrounds[14] := 3;
			Intense[14] := false;
			Underlines[14] := false;
			Blinking[14] := false;
			Foregrounds[15] := 3;
			Backgrounds[15] := 4;
			Intense[15] := true;
			Underlines[15] := false;
			Blinking[15] := false;
			Foregrounds[16] := 7;
			Backgrounds[16] := 0;
			Intense[16] := false;
			Underlines[16] := false;
			Blinking[16] := false;
		end;
	end;

	procedure ResetSystemColors (syst: SystHand);
	begin
		with syst^^ do
		begin
			Foregrounds[0] := 7;
			Backgrounds[0] := 0;
			Intense[0] := false;
			Underlines[0] := false;
			Blinking[0] := false;
			foregrounds[1] := 6;
			backgrounds[1] := 0;
			Intense[1] := false;
			Underlines[1] := false;
			Blinking[1] := false;
			foregrounds[2] := 3;
			backgrounds[2] := 0;
			Intense[2] := false;
			underlines[2] := false;
			Blinking[2] := false;
			foregrounds[3] := 5;
			backgrounds[3] := 0;
			Intense[3] := false;
			underlines[3] := false;
			Blinking[3] := false;
			foregrounds[4] := 7;
			backgrounds[4] := 4;
			Intense[4] := true;
			underlines[4] := false;
			Blinking[4] := false;
			foregrounds[5] := 2;
			backgrounds[5] := 0;
			Intense[5] := true;
			underlines[5] := false;
			Blinking[5] := false;
			foregrounds[6] := 1;
			backgrounds[6] := 0;
			Intense[6] := false;
			underlines[6] := false;
			Blinking[6] := false;
		end;
	end;

	procedure InitUserRec;
		var
			i, tempInt: integer;
			templong, l: longint;
	begin
		with curglobs^ do
		begin
			GetDateTime(thisUser.laston);
			GetDateTime(thisUser.firstOn);
			thisUser.BonusTime := 0;
			thisUser.DeletedUser := false;
			thisUser.mailbox := false;
			thisUser.forwardedTo := char(0);
			thisUser.defaultProtocol := 0;
			thisUser.PauseScreen := true;
			thisUser.ScrnWdth := 80;
			thisUser.ScrnHght := 24;
			thisUser.TerminalType := 0;
			thisUser.ColorTerminal := true;
			thisUser.ChatANSI := false;
			thisUser.AutoSense := false;
			ResetUserColors(thisUser);
			thisUser.Expert := false;
			thisUser.sysopNote := '';
			thisUser.MinOnToday := 0;
			thisUser.SL := NewSL;
			thisUser.DSL := SecLevels^^[NewSL].TransLevel;
			thisUser.illegalLogons := 0;
			for i := 1 to 26 do
			begin
				if SecLevels^^[NewSL].Restrics[i] then
					thisUser.AccessLetter[i] := true
				else
					thisUser.AccessLetter[i] := false;
			end;
			thisUser.onToday := 0;
			thisUser.MessagesPosted := 0;
			thisUser.EMailSent := 0;
			thisUser.UserNum := -1;
			thisUser.numUploaded := 0;
			thisUser.numdownloaded := 0;
			thisUser.uploadedK := 0;
			thisUser.EMsentToday := 0;
			thisUser.MPostedToday := 0;
			thisUser.downloadedK := 0;
			thisUser.birthDay := char(0);
			thisUser.birthMonth := char(0);
			thisUser.BirthYear := char(0);
			thisUser.lastFileScan := 0;
			thisUser.NTransAfterMess := false;
			thisUser.computerType := '';
			thisUser.extendedLines := 10;
			thisUser.totalLogons := 0;
			thisUser.lastBaud := curBaudNote;
			thisUser.coSysop := false;
			thisUser.screenClears := true;
			thisUser.notifyLogon := true;
			thisUser.totalTimeOn := 0;
			thisUser.alertOn := false;
			thisUser.UserName := '';
			thisUser.RealName := '•';
			thisUser.Phone := '•';
			thisUser.DataPhone := '•';
			thisUser.Company := '•';
			thisUser.Street := '•';
			thisUser.City := '•';
			thisUser.State := '•';
			thisUser.Zip := '•';
			thisUser.Country := '•';
			thisUser.MiscField1 := '•';
			thisUser.MiscField2 := '•';
			thisUser.MiscField3 := '•';
			thisUser.Alias := '•';
			thisUser.NumULToday := 0;
			thisUser.NumDLToday := 0;
			thisUser.KBULToday := 0;
			thisUser.KBDLToday := 0;
			thisUser.RestrictHours := False;
			thisUser.StartHour := 0;
			thisUser.EndHour := 0;
			thisUser.ScanAtLogon := True;
			thisUser.AllowInterruptions := False;
			thisuser.DlsByOther := 0;
			thisUser.XferComp := SecLevels^^[NewSL].XferComp;
			thisUser.messcomp := SecLevels^^[NewSL].MessComp;
			thisUser.UseDayOrCall := SecLevels^^[NewSL].UseDayOrCall;
			thisUser.TimeAllowed := SecLevels^^[NewSL].TimeAllowed;
			thisUser.MesgDay := SecLevels^^[NewSL].MesgDay;
			thisUser.DLRatioOneTo := SecLevels^^[NewSL].DLRatioOneTo;
			thisUser.PostRatioOneTo := SecLevels^^[NewSL].PostRatioOneTo;
			thisUser.CallsPrDay := SecLevels^^[NewSL].CallsPrDay;
			thisUser.LnsMessage := SecLevels^^[NewSL].LnsMessage;
			thisuser.CantReadAnon := SecLevels^^[NewSL].ReadAnon;
			thisuser.CantPost := SecLevels^^[NewSL].PostMessage;
			thisuser.CantAddToBBSList := SecLevels^^[NewSL].BBSList;
			thisuser.CantSeeULInfo := SecLevels^^[NewSL].Uploader;
			thisuser.UDRatioOn := SecLevels^^[NewSL].UDRatio;
			thisuser.CantChat := SecLevels^^[NewSL].Chat;
			thisuser.CantSendEmail := SecLevels^^[NewSL].Email;
			thisuser.CantListUser := SecLevels^^[NewSL].ListUser;
			thisuser.CantChangeAutoMsg := SecLevels^^[NewSL].AutoMsg;
			thisuser.CantPostAnon := SecLevels^^[NewSL].AnonMsg;
			thisuser.PCRatioOn := SecLevels^^[NewSL].PCRatio;
			thisUser.CantSendPPFile := SecLevels^^[NewSL].PPFile;
			thisuser.ReadBeforeDL := SecLevels^^[NewSL].MustRead;
			thisUser.RestrictHours := SecLevels^^[NewSL].EnableHours;
			thisUser.CantNetMail := SecLevels^^[NewSL].CantNetMail;
			thisUser.AlternateText := SecLevels^^[NewSL].AlternateText;
			thisUser.signature := thisUser.Username;
			thisUser.DLCredits := InitSystHand^^.DLCredits;
			thisUser.ExtDesc := false;
			thisUser.columns := false;
			thisUser.Alias := '•';
			thisUser.Donation := '';
			thisUser.LastDonation := '';
			thisUser.ExpirationDate := '';
			thisUser.MessHeader := MessOn;
			thisUser.TransHeader := TransOn;
			GetDateTime(thisUser.lastPWChange);
			templong := CheckDays(NewHand^^.QScanBack);
			l := CheckDays(7000);
			for i := 1 to 20 do
				for tempInt := 1 to 50 do
				begin
					thisUser.LastMsgs[i, tempInt] := 0;
					thisUser.WhatNScan[i, tempInt] := true;
				end;
			for i := 1 to InitSystHand^^.NumMForums do
			begin
				for tempInt := 1 to 50 do
				begin
					if (MConference[i]^^[tempInt].NewUserRead) then
						thisUser.LastMsgs[i, tempInt] := l
					else
						thisUser.LastMsgs[i, tempInt] := templong;
					thisUser.WhatNScan[i, tempInt] := true;
				end;
			end;

			for i := 0 to 49 do
				ThisUser.reserved[i] := char(0);
		end;
	end;

	function SysopReadExtended (theFil: filEntryRec; whichDir, whichSub: integer): CharsHandle;
		var
			tempint: integer;
			curWriting: charsHandle;
	begin
		CurWriting := nil;
		tempInt := OpenRFPerm(concat(InitSystHand^^.DataPath, forumIdx^^.name[whichDir], ':', forums^^[whichDir].dr[whichSub].dirName), 0, fsRdWrPerm);
		if tempint <> -1 then
		begin
			UseResFile(tempint);
			Handle(CurWriting) := Get1NamedResource('DESC', theFil.flName);
			DetachResource(Handle(CurWriting));
			CloseResFile(tempInt);
			UseResFile(myResourceFile);
		end;
		SysopReadExtended := curWriting;
	end;

	procedure ReadExtended (theFil: filEntryRec; whichDir, whichSub: integer);
		var
			tempint: integer;
	begin
		with curglobs^ do
		begin
			if curWriting <> nil then
				DisposHandle(handle(curWriting));
			CurWriting := nil;
			tempInt := OpenRFPerm(concat(InitSystHand^^.DataPath, forumIdx^^.name[whichDir], ':', forums^^[whichDir].dr[whichSub].dirName), 0, fsRdWrPerm);
			if tempint <> -1 then
			begin
				UseResFile(tempint);
				handle(CurWriting) := Get1NamedResource('DESC', theFil.flName);
				DetachResource(Handle(CurWriting));
				CloseResFile(tempInt);
				UseResFile(myResourceFile);
			end;
		end;
	end;

	procedure SysopLog (toLog: str255; color: integer);
	begin
		if (curglobs^.thisUser.userNum > 1) or not curglobs^.sysopLogon then
			LogThis(toLog, color);
	end;

	procedure LogThis;
		var
			tempString: str255;
			LogRef, i, tempUserNum: integer;
			AllUsersSize, SizeofAUser, templong: longInt;
			result, myOSerr: OSerr;
			myUserHand: UserHand;
	begin
		if writeDirectToLog then
			tempString := concat(sharedPath, 'Misc:Today Log')
		else
			tempString := StringOf(sharedPath, 'Misc:Temp Log', activeNode : 0);
		result := FSOpen(tempString, 0, LogRef);
		if result <> noErr then
		begin
			result := FSDelete(tempString, 0);
			result := Create(tempString, 0, 'HRMS', 'TEXT');
			result := FSOpen(tempString, 0, LogRef);
		end;
		if result = noErr then
		begin
			logit := concat(logit, char(13));
			result := GetEOF(LogRef, AllUsersSize);
			result := SetFPos(LogRef, fsFromStart, allUsersSize);
			sizeOfAUser := length(LogIt);
			result := FSWrite(LogRef, SizeOfAUser, @LogIt[1]);
			result := FSClose(LogRef);
		end;
	end;

	procedure WriteTempLog2Log;
		var
			tempString: str255;
			LogRef, i, tempUserNum: integer;
			AllUsersSize, SizeofAUser, ss2: longInt;
			result, myOSerr: OSerr;
			myUserHand: UserHand;
	begin
		with curglobs^ do
		begin
			tempString := StringOf(sharedPath, 'Misc:Temp Log', activeNode : 0);
			result := FSOpen(tempString, 0, LogRef);
			if result = noErr then
			begin
				result := GetEOF(LogRef, AllUsersSize);
				result := SetFPos(LogRef, fsFromStart, 0);
				SizeOfAUser := AllUsersSize;
				TextHnd := TextHand(NewHandle(SizeOfAUser));
				MoveHHi(handle(textHnd));
				HLock(handle(TextHnd));
				ss2 := AllUsersSize;
				result := FSRead(LogRef, SizeOfAUser, pointer(TextHnd^));
				result := FSClose(LogRef);
				result := FSDelete(tempstring, 0);
				tempString := concat(SharedPath, 'Misc:Today Log');
				result := FSOpen(tempString, 0, LogRef);
				if result <> noErr then
				begin
					result := Create(tempString, 0, 'HRMS', 'TEXT');
					result := FSOpen(tempString, 0, LogRef);
				end;
				if result = noErr then
				begin
					result := GetEOF(LogRef, AllUsersSize);
					result := SetFPos(LogRef, fsFromStart, AllUsersSize);
					result := FSWrite(LogRef, ss2, @TextHnd^^[0]);
					result := FSClose(LogRef);
				end;
				HUnlock(handle(textHnd));
				DisposHandle(handle(textHnd));
				TextHnd := nil;
			end;
		end;
	end;

	function FigureDisplayConf (whichFor, theConf: integer): integer;
	external;

	procedure GoHome;
		var
			check: boolean;
	begin
		with curGlobs^ do
		begin
			check := false;
			if (BoardSection = UEdit) then
				check := true;
			if (boardsection = Ext) and (maxLines = -981) then
				boardSection := Upload
			else if boardsection = AskQuestions then
				boardsection := NewUser
			else if boardSection = AttachFile then
			begin
				if endAnony = 1 then
					curPrompt := 'Y'
				else
					curPrompt := 'N';
				if wasEMail then
				begin
					EmailDo := EMailFourA;
					boardSection := EMail;
				end
				else if wasSearching then
					BoardSection := MessageSearcher
				else
					BoardSection := Post;
			end
			else if boardSection = DetachFile then
				if wasEMail then
					BoardSection := ReadMail
				else if wasSearching then
					BoardSection := MessageSearcher
				else
					BoardSection := QScan
			else if boardsection <> NewUser then
			begin
				BoardSection := MainMenu;
				MainStage := MenuText;
			end;
			if check and (maxLines = -425) then
				BoardSection := ReadMail
			else if check and (maxLines = -525) then
				BoardSection := QScan
			else if goBackToLogon and not FromDetach then
			begin
				curPrompt := 'N';
				goBackToLogon := false;
				BoardSection := Logon;
			end;
		end;
	end;

	function secs2Time (howmanysecs: longint): str255;
		var
			l1, l2, l3, l4: longInt;
			tempString, t3: str255;
	begin
		l1 := howManysecs;
		l2 := l1 div 60;         {minutes       }
		l1 := l1 - (l2 * 60);   {seconds       }
		l3 := l2 div 60;         {hours           }
		l4 := l2 - (l3 * 60);   {new minutes}

		NumToString(l3, tempString);
		if length(tempString) = 1 then
			tempString := concat('0', tempString);
		NumToString(l4, t3);
		if length(t3) = 1 then
			t3 := concat('0', t3);
		tempString := concat(tempString, ':', t3, ':');
		NumToString(l1, t3);
		if length(t3) = 1 then
			t3 := concat('0', t3);
		secs2Time := concat(tempString, t3);
	end;

	function AreaOp (WhichDir: Integer; DirUser: UserRec): Boolean;
	begin
		AreaOp := False;
		if (DirUser.usernum = forumIdx^^.ops[WhichDir, 1]) or (DirUser.usernum = forumIdx^^.ops[WhichDir, 2]) or (DirUser.usernum = forumIdx^^.ops[WhichDir, 3]) then
			AreaOp := True;
	end;

	function DirOp (WhichDir, SubDir: Integer; DirUser: UserRec): Boolean;
	begin
		DirOp := False;
		if (DirUser.usernum = forums^^[WhichDir].dr[SubDir].Operators[1]) or (DirUser.usernum = forums^^[WhichDir].dr[SubDir].Operators[2]) or (DirUser.usernum = forums^^[WhichDir].dr[SubDir].Operators[3]) then
			DirOp := True;
	end;

	function MForumOp (Forum: Integer; DirUser: UserRec): Boolean;
	begin
		MForumOp := false;
		if (DirUser.userNum = MForum^^[Forum].Moderators[1]) or (DirUser.userNum = MForum^^[Forum].Moderators[2]) or (DirUser.userNum = MForum^^[Forum].Moderators[3]) then
			MForumOp := True;
	end;

	function MConferenceOp (Forum, Conf: Integer; DirUser: UserRec): Boolean;
	begin
		MConferenceOp := False;
		if (DirUser.usernum = MConference[Forum]^^[Conf].Moderators[1]) or (DirUser.usernum = MConference[Forum]^^[Conf].Moderators[2]) or (DirUser.usernum = MConference[Forum]^^[Conf].Moderators[3]) then
			MConferenceOp := True;
	end;

	function GetUserNum (var ttUser: UserRec; getNum: integer): boolean;
		var
			tempString: str255;
			tempInt, SizeOfAUser, UserNum, UsersRes: integer;
			tempLong, AllUsersSize: longInt;
			result: OSerr;
			tempProcResult: boolean;
	begin
		UserNum := getNum;
		tempProcResult := false;
		if UserNum > 0 then
		begin
			result := FSOpen(concat(SharedFiles, 'Users'), 0, UsersRes);
			result := GetEOF(UsersRes, AllUsersSize);
			SizeOfAUser := SizeOf(UserRec);
			if ((AllUsersSize div SizeOfaUser) >= UserNum) then
			begin
				result := SetFPos(UsersRes, fsFromStart, SizeOf(UserRec) * (longInt(UserNum - 1)));
				tempLong := SizeOf(UserRec);
				Result := FSRead(UsersRes, tempLong, @ttUser);
				if ttUser.UserNum = UserNum then
					tempProcResult := true
				else
					tempProcResult := false;
			end
			else
				tempProcResult := false;
		end;
		GetUserNum := tempprocResult;
		Result := FSClose(UsersRes);
	end;

	function FindUser (searchString: str255; var userFound: UserRec): boolean;
		var
			tempString, tempString2: str255;
			tempInt, SizeOfAUser, UserNum, HermesRef, i: integer;
			tempLong, AllUsersSize: longInt;
			myHParmer: HParmBlkPtr;
			myParmer: ParmBlkPtr;
			result: OSerr;
			tempProcResult, foundit, WILD, SEARCHREAL: boolean;
			ListRefHand: TextHand;
			myUserHand: UserHand;
	begin
		tempProcResult := false;
		if (length(SearchString) > 0) then
		begin
			if (SearchString[1] > char(47)) and (SearchString[1] < char(58)) then
			begin
				tempString := SearchString;
				StringToNum(tempString, tempLong);
				UserNum := tempLong;
				if GetUserNum(UserFound, UserNum) then
					tempProcResult := true;
			end
			else
			begin
				WILD := false;
				FOUNDIT := FALSE;
				SEARCHREAL := FALSE;
				if searchString[1] = '%' then
				begin
					SEARCHREAL := TRUE;
					Delete(SearchString, 1, 1);
				end;
				if (searchString[length(searchString)] = '*') then
				begin
					WILD := true;
					SearchString[0] := char(length(searchString) - 1);
				end;
				if (numUserRecs > 0) then
				begin
					i := 0;
					repeat
						tempString := myUsers^^[i].UName;
						if WILD and (length(tempString) >= length(searchString)) then
							tempString[0] := char(length(SearchString));
						if EqualString(tempString, searchString, false, false) then
							foundIt := true;
						i := i + 1;
					until (i >= numUserRecs) or foundIt;
				end;
				if not foundIt and SEARCHREAL and (numUserRecs > 0) then
				begin
					i := 0;
					repeat
						tempString := myUsers^^[i].real;
						if WILD and (length(tempString) >= length(searchString)) then
							tempString[0] := char(length(searchString));
						if EqualString(tempString, searchString, false, false) then
							foundIt := true;
						i := i + 1;
					until (i >= numUserRecs) or foundIt;
				end;
				if foundIt then
				begin
					if GetUserNum(UserFound, i) then
						tempProcResult := true;
				end;
			end;
		end;
		FindUser := tempProcResult;
	end;

	function Appletalk: boolean;
		var
			tempLong: longint;
	begin
		AppleTalk := True;
		result := Gestalt(gestaltAppleTalkVersion, tempLong);
		if tempLong = 0 then
			AppleTalk := False;
	end;

	procedure frameit (theDilg: dialogptr; item: integer);
		var
			tempRect: Rect;
			Dtype: Integer;
			dItem: Handle;
	begin
		PenSize(1, 1);
		GetDItem(theDilg, item, dType, dItem, tempRect);
		FrameRect(tempRect);
	end;

	function UpDownReal (Dlog: DialogPtr; Box: Integer; Value, Adder, Hi, Lo: Real): Real;
	begin
		if (Value > Hi) or (Value < Lo) then
			Value := Hi;
		if ((Value + Adder) <= Hi) and ((Value + adder) >= Lo) then
			Value := Value + adder;
		UpDownReal := Value;
		SetTextBox(Dlog, Box, StringOf(Value : 0 : 1));
	end;

	function UpDown (Dlog: DialogPtr; Box: Integer; Value, Adder, Hi, Lo: LongInt): LongInt;
	begin
		if (Value > Hi) or (Value < Lo) then
			Value := Hi;
		if ((Value + Adder) <= Hi) and ((Value + adder) >= Lo) then
			Value := Value + adder;
		UpDown := Value;
		SetTextBox(Dlog, Box, DoNumber(Value));
	end;

	function DrawTime (well: longint): str255;
		var
			mytime: datetimeRec;
			tempString: Str255;
	begin
		TempString := '';
		Secs2Date(well, mytime);
		if mytime.hour < 10 then
			TempString := '0';
		TempString := stringOf(TempString, mytime.hour : 0, ':');
		if mytime.minute < 10 then
			TempString := concat(TempString, '0');
		TempString := stringOf(TempString, mytime.minute : 0);
		DrawTime := TempString;
	end;

	function getdate (well: longint): Str255;
		var
			mytime: datetimeRec;
			tempString, t2: Str255;
	begin
		if well <> 0 then
		begin
			if well = -1 then
				GetDateTime(well);
			TempString := '';
			Secs2Date(well, mytime);
			if mytime.month < 10 then
				TempString := '0';
			TempString := stringOf(TempString, mytime.month : 0, '/');
			if mytime.day < 10 then
				TempString := concat(TempString, '0');
			TempString := stringOf(TempString, mytime.day : 0, '/');
			NumToString(mytime.year, t2);
			TempString := concat(tempstring, copy(t2, 3, 2));
			getdate := TempString;
		end
		else
			getdate := 'Never.';
	end;

	function whattime (well: longint): Str255;
		var
			mytime: datetimeRec;
			tempString, t2: Str255;
	begin
		if well = -1 then
			GetDateTime(well);
		TempString := '';
		Secs2Date(well, mytime);
		if mytime.hour < 10 then
			TempString := '0';
		TempString := stringOf(TempString, mytime.hour : 0, ':');
		if mytime.minute < 10 then
			TempString := concat(TempString, '0');
		TempString := stringOf(TempString, mytime.minute : 0, ':');
		if mytime.second < 10 then
			TempString := concat(tempString, '0');
		TempString := stringOf(tempString, mytime.second : 0);
		whattime := TempString;
	end;

	function WhatUser (node: integer): Str255;
		var
			ts: Str255;
	begin
		case (theNodes[node]^.boardSection) of
			Logon: 
				ts := RetInStr(522);	{Logging on}
			NewUser: 
				ts := RetInStr(523);	{New User}
			Quote: 
				ts := RetInStr(607);	{Quoting Message}
			MainMenu: 
			begin
				if theNodes[node]^.intransfer then
					ts := RetInStr(608)	{Transfer Menu}
				else
					ts := RetInStr(524);	{Main Menu}
			end;
			PrintXFerTree: 
				ts := RetInStr(608);	{Transfer Menu}
			rmv: 
				ts := RetInStr(525);	{Removing Messages}
			MoveFiles: 
				ts := RetInStr(526);	{Moving Files}
			killMail: 
				ts := RetInStr(527);	{Killing Mail}
			Batch: 
				ts := RetInStr(528);	{Batch Transferring}
			MultiChat: 
				ts := RetInStr(529);	{Multiuser Chat}
			tranDef: 
				ts := RetInStr(530);	{Transfer Defaults}
			MultiMail: 
				ts := RetInStr(531);	{Multi-Mail}
			Noder: 
				ts := RetInStr(532);	{Examining Nodes}
			messUp: 
				ts := RetInStr(533);	{Uploading Message}
			renFiles: 
				ts := RetInStr(534);	{Renaming Files}
			readAll: 
				ts := RetInStr(535);	{Reading All Mail}
			RmvFiles: 
				ts := RetInStr(536);	{Removing Files}
			GFiles: 
				ts := RetInStr(537);	{Reading GFiles}
			UEdit: 
				ts := RetInStr(538);	{Editing Users}
			USList: 
				ts := RetInStr(539);	{Listing Users}
			BBSlist: 
				ts := RetInStr(540);	{BBS List}
			chUser: 
				ts := RetInStr(541);	{Switching User}
			limdate: 
				ts := RetInStr(542);	{Limiting Date}
			Download: 
				ts := RetInStr(543);	{Downloading}
			Sort: 
				ts := RetInStr(544);	{Sorting Files}
			Upload: 
				ts := RetInStr(545);	{Uploading Files}
			OffStage: 
				ts := RetInStr(546);	{Logging Off}
			ListFiles, FindDesc: 
				ts := RetInStr(547);	{Listing Files}
			post: 
				ts := RetInStr(548);	{Posting Message}
			ChatStage: 
				ts := RetInStr(549);	{Chatting}
			Defaults: 
				ts := RetInStr(550);	{Defaults}
			Email: 
				ts := RetInStr(609);	{Sending Email}
			ReadMail: 
				ts := RetInStr(551);	{Reading Mail}
			qscan: 
				ts := RetInStr(552);	{Reading Messages}
			Amsg: 
				ts := RetInStr(553);	{Setting Auto-message}
			TransferMenu: 
				ts := RetInStr(554);	{Transfer Menu}
			Ext: 
				ts := RetInStr(555);	{Selecting External}
			EXTERNAL: 
				ts := RetInStr(556);	{Using External}
			ScanNew: 
				ts := RetInStr(557);	{Scanning Messages}
			CatchUp: 
				ts := RetInStr(136);	{Catching Up}
			AttachFile: 
				ts := RetInStr(576);  {Attaching File}
			DetachFile: 
				ts := RetInStr(577);  {Detaching File}
			SysopComm: 
				ts := RetInStr(138);	{//SYSOP}
			ChatRoom: 
				ts := RetInStr(209);	{Chat Menu}
			AddrBook: 
				ts := RetInStr(210);	{Address Book}
			PrivateRequest: 
				ts := RetInStr(822); {Private Chat Request}
			MessageSearcher: 
				ts := RetInStr(823); {Searching Messages}
			Colors: 
				ts := RetInStr(824); {Editing System Colors}
			TelnetNegotiation: 
				ts := RetInStr(825); {Telnet Negotiation}
			otherwise
				NumToString(longint(theNodes[node]^.boardSection), ts);
		end;
		WhatUser := Ts;
	end;


	function makeADir (path: str255): OSerr;
		var
			myHParms: HParamBlockRec;
	begin
		myHParms.ioCompletion := nil;
		myHParms.ioNameptr := @path;
		myHParms.ioVRefNum := 0;
		myHParms.ioDirID := 0;
		result := PBDirCreate(@myHParms, false);
		makeADir := result;
	end;

	function TotalKDl: longint;
		var
			a, i: longint;
	begin
		a := 0;
		for i := 1 to InitSystHand^^.NumNodes do
			if not theNodes[i]^.SysOpNode then
				a := a + InitSystHand^^.kdownloaded[i];
		TotalKDl := a;
	end;

	function TotalKUl: longint;
		var
			a, i: longint;
	begin
		a := 0;
		for i := 1 to InitSystHand^^.NumNodes do
			if not theNodes[i]^.SysOpNode then
				a := a + InitSystHand^^.kuploaded[i];
		TotalKUl := a;
	end;

	function TotalFDls: longint;
		var
			a, i: longint;
	begin
		a := 0;
		for i := 1 to InitSystHand^^.NumNodes do
			if not theNodes[i]^.SysOpNode then
				a := a + InitSystHand^^.FailedDls[i];
		TotalFDls := a;
	end;

	function TotalFUls: longint;
		var
			a, i: longint;
	begin
		a := 0;
		for i := 1 to InitSystHand^^.NumNodes do
			if not theNodes[i]^.SysOpNode then
				a := a + InitSystHand^^.FailedUls[i];
		TotalFUls := a;
	end;

	function TotalDLs: longint;
		var
			a, i: longint;
	begin
		a := 0;
		for i := 1 to InitSystHand^^.NumNodes do
			if not theNodes[i]^.SysOpNode then
				a := a + InitSystHand^^.dlsToday[i];
		TotalDLs := a;
	end;

	function TotalCalls: longint;
		var
			a, i: longint;
	begin
		a := 0;
		for i := 1 to InitSystHand^^.NumNodes do
			if not theNodes[i]^.SysOpNode then
				a := a + InitSystHand^^.CallsToday[i];
		TotalCalls := a;
	end;

	function TotalMins: longint;
		var
			a, i: longint;
	begin
		a := 0;
		for i := 1 to InitSystHand^^.NumNodes do
			if not theNodes[i]^.SysOpNode then
				a := a + InitSystHand^^.MinsToday[i];
		TotalMins := a;
	end;

	function TotalEmail: longint;
		var
			a, i: longint;
	begin
		a := 0;
		for i := 1 to InitSystHand^^.NumNodes do
			if not theNodes[i]^.SysOpNode then
				a := a + InitSystHand^^.EmailToday[i];
		TotalEmail := a;
	end;

	function TotalPosts: longint;
		var
			a, i: longint;
	begin
		a := 0;
		for i := 1 to InitSystHand^^.NumNodes do
			if not theNodes[i]^.SysOpNode then
				a := a + InitSystHand^^.mPostedToday[i];
		TotalPosts := a;
	end;

	function TotalUls: longint;
		var
			a, i: longint;
	begin
		a := 0;
		for i := 1 to InitSystHand^^.NumNodes do
			if not theNodes[i]^.SysOpNode then
				a := a + InitSystHand^^.uploadsToday[i];
		TotalUls := a;
	end;

	function EscDown: boolean;
		var
			KBNunc: KeyMap;
	begin
		GetKeys(KBnunc);
		charnum := 53 div 8;
		bitnum := 7 - (53 mod 8);
		EscDown := false;			{(BitTst(@KBNunc, 8 * charnum + bitnum))}
		if (BitTst(@KBNunc, 8 * charnum + bitnum)) then
			EscDown := true;
	end;

	function OptionDown: boolean;
		var
			KBNunc: KeyMap;
	begin
		GetKeys(KBnunc);
		charnum := 58 div 8;
		bitnum := 7 - (58 mod 8);
		optiondown := false;			{(BitTst(@KBNunc, 8 * charnum + bitnum))}
		if (BitTst(@KBNunc, 8 * charnum + bitnum)) then
			optiondown := true;
	end;

	function CmdDown: Boolean;
		var
			KBNunc: KeyMap;
	begin
		GetKeys(KBnunc);
		charnum := 55 div 8;
		bitnum := 7 - (55 mod 8);
		CmdDown := false;
		if (BitTst(@KBNunc, 8 * charnum + bitnum)) then
			CmdDown := true;
	end;

	function Security (which: integer): integer;
		var
			i, w: integer;
	begin
		Security := 1;
		w := 0;
		for i := 1 to 255 do
		begin
			if SecLevels^^[i].active then
			begin
				w := w + 1;
				if i = which then
					Security := w;
			end;
		end;
	end;

	function GetSecurity (which: integer): integer;
		var
			i, w: integer;
	begin
		GetSecurity := 1;
		w := 0;
		for i := 1 to 255 do
		begin
			if SecLevels^^[i].active then
			begin
				w := w + 1;
				if which = w then
					GetSecurity := i;
			end;
		end;
	end;

	procedure SetGeneva (Dlog: DialogPtr);
		var
			ThisEditText: TEHandle;
			TheDialogPtr: DialogPeek;
	begin
		TheDialogPtr := DialogPeek(Dlog);
		ThisEditText := TheDialogPtr^.textH;
		HLock(Handle(ThisEditText));
		ThisEditText^^.txSize := 9;
		TextSize(9);
		ThisEditText^^.txFont := geneva;
		TextFont(geneva);
		ThisEditText^^.txFont := 3;
		ThisEditText^^.fontAscent := 9;
		ThisEditText^^.lineHeight := 9 + 3 + 0;
		HUnLock(Handle(ThisEditText));
	end;


	procedure AddListString (theString: Str255; theList: ListHandle);
		var
			theRow: integer;
			sTemp: str255;
			cSize, selectThis: Point;
	begin
		if (theList <> nil) then
		begin
			cSize.h := 0;
			theRow := LAddRow(1, 9000, theList);
			cSize.v := theRow;
			sTemp := theString;
			LSetCell(Pointer(ord(@sTemp) + 1), length(sTemp), cSize, theList);
		end;
	end;

	function RetInStr (index: integer): str255;
		var
			ts: str255;
	begin
		UseResFile(StringsRes);
		if curGlobs^.thisUser.AlternateText then
			GetIndString(RetInStr, 3, index)
		else
			GetIndString(RetInStr, 1, index);
		UseResFile(myResourceFile);
	end;

	function GetFNameFromPath (path: str255): str255;
		var
			marker: integer;
	begin
		marker := pos(':', path);
		while (marker > 0) do
		begin
			delete(path, 1, marker);
			marker := pos(':', path);
		end;
		GetFNameFromPath := path;
	end;

	procedure ProblemRep (tellUser: str255);
		var
			tempDilg: dialogPtr;
			a: integer;
			DItem: handle;
			temprect: rect;
			SavePort: GrafPtr;
	begin
		SysBeep(10);
		GetPort(savePort);
		tempDilg := GetNewDialog(1055, nil, pointer(-1));
		if tempDilg <> nil then
		begin
			setPort(tempdilg);
			GetDItem(tempdilg, 1, a, DItem, tempRect);
			InsetRect(tempRect, -4, -4);
			PenSize(3, 3);
			FrameRoundRect(tempRect, 16, 16);
			ParamText(tellUser, '', '', '');
			DrawDialog(tempDilg);
			repeat
				ModalDialog(nil, a);
			until (a = 1);
			DisposDialog(tempDilg);
		end;
		SetPort(savePort);
	end;

	procedure SetTextBox (theDialog: dialogPtr; item: integer; text: str255);
		var
			dType: integer;
			dItem: handle;
			tempRect: rect;
	begin
		GetDItem(theDialog, item, dType, dItem, tempRect);
		SetIText(dItem, text);
	end;

	function GetTextBox (theDialog: dialogPtr; item: integer): str255;
		var
			dType: integer;
			dItem: handle;
			tempRect: rect;
			t: str255;
	begin
		GetDItem(theDialog, item, dType, dItem, tempRect);
		GetIText(dItem, t);
		GetTextBox := t;
	end;

	procedure SetCheckBox (theDialog: dialogPtr; item: integer; up: boolean);
		var
			dType: integer;
			dItem: handle;
			tempRect: rect;
	begin
		GetDItem(theDialog, item, dType, dItem, tempRect);
		if up then
			SetCtlValue(controlHandle(dItem), 1)
		else
			SetCtlValue(controlHandle(dItem), 0);
	end;

	function GetCheckBox (theDialog: dialogPtr; item: integer): boolean;
		var
			dType: integer;
			dItem: handle;
			tempRect: rect;
	begin
		GetDItem(theDialog, item, dType, dItem, tempRect);
		if GetCtlValue(controlHandle(dItem)) = 1 then
			GetCheckBox := true
		else
			GetCheckBox := false;
	end;

	function ModalQuestion (askWhat: str255; saveBox, yesNo: boolean): integer;
		var
			myTempDilg: dialogPtr;
			tempint: integer;
			aHandle: handle;
			tempRect: rect;
			savePort: GrafPtr;
	begin
		GetPort(savePort);
		myTempDilg := GetNewDialog(610, nil, pointer(-1));
		SetPort(myTempDilg);
		ParamText(askWhat, '', '', '');
		GetDItem(myTempDilg, 1, tempInt, aHandle, tempRect);
		if saveBox then
		begin
			SetCTitle(controlHandle(aHandle), 'Save');
		end
		else if yesNo then
		begin
			SetCTitle(controlHandle(aHandle), 'Yes');
			GetDItem(myTempDilg, 2, tempInt, aHandle, tempRect);
			SetCTitle(controlHandle(aHandle), 'No');
		end;
		if not saveBox or (quit = 1) then
		begin
			GetDItem(myTempDilg, 5, tempInt, aHandle, tempRect);
			HideControl(controlHandle(aHandle));
		end;
		SetCursor(arrow);
		ShowWindow(myTempDilg);
		GetDItem(myTempDilg, 1, tempInt, aHandle, tempRect);
		InsetRect(tempRect, -4, -4);
		PenSize(3, 3);
		FrameRoundRect(tempRect, 16, 16);
		SysBeep(10);
		repeat
			modalDialog(nil, tempint);
		until (tempint = 1) or (tempInt = 2) or (tempint = 5);
		DisposDialog(myTempDilg);
		if tempInt = 1 then
			ModalQuestion := 1
		else if tempint = 2 then
			ModalQuestion := 0
		else if tempInt = 5 then
			ModalQuestion := 2;
		SetPort(savePort);
	end;

	procedure SaveText (ThePath, TheText: str255);
		var
			result: OSErr;
			TheFile, x: integer;
			SizeOfThis: longint;
	begin
		result := FSOpen(ThePath, 0, TheFile);
		if (result <> noErr) then
			result := Create(ThePath, 0, 'HRMS', 'TEXT');
		if (result <> noErr) then
			Exit(SaveText);

		result := FSOpen(ThePath, 0, TheFile);
		result := SetFPos(TheFile, fsFromLEOF, 0);

		TheText := concat(TheText, char(13));
		SizeOfThis := length(TheText);
		result := FSWrite(TheFile, SizeOfThis, pointer(ord(@TheText) + 1));
		result := FSClose(TheFile);
	end;

end.