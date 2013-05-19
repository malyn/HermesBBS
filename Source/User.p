{ Segments: User_1 }
unit User;


interface
	uses
		AppleTalk, ADSP, Serial, Sound, CTBUtilities, TCPTypes, Initial, LoadAndSave, NodePrefs2, SystemPrefs, Message_Editor;

	procedure EndUser;
	function UserOnSystem (name: str255): boolean;
	function WhatNode (name: Str255): Integer;
	procedure Update_User_Edit (theWindow: WindowPtr);
	procedure Open_User_Edit;
	procedure Do_User_Edit (theEvent: EventRecord; itemHit: integer);
	procedure PutInUser;
	procedure Close_User_Edit (theWindow: WindowPtr; Cancelled: boolean);
	procedure MakeUserList;
	function checkTitle (thetit: str255): boolean;
	procedure yearsOld (var theUser: userRec);
	function UserHungUp: boolean;
	procedure MakeFullNames (whichWay: integer);
	procedure OpenUserList;
	procedure UpdateUserList (theWindow: WindowPtr);
	procedure DoUserList (theEvent: EventRecord; itemHit: integer);
	procedure CloseUserList;
	procedure OpenUserSearch;
	procedure UpdateUserSearch (theWindow: WindowPtr);
	procedure DoUserSearch (theEvent: EventRecord; itemHit: integer);
	procedure CloseUserSearch;

implementation

	var
		ExitDialog: Boolean;
		tempRect: Rect;
		DType: Integer;
		Index: Integer;
		DItem: Handle;
		CItem, CTempItem: controlhandle;
		itemHit: Integer;
		temp: Integer;
		chCode, SLstat, DSLstat, theSL, theDSL, LOstat, ALstat, firstStat, lastDays, count, firstDays, numAddedItems: integer;
		pass1, pass2, pass3, pass4, pass5, pass6: boolean;

{$S User_1 }
	procedure GetStuff;
		var
			tempString, tempString2, tempString3: str255;
			tempDate: DateTimeRec;
			i, tempLong: longInt;
			tempRect: Rect;
			DType, tempInt: Integer;
			DItem: Handle;
			CItem, CTempItem: controlhandle;
			day, month, year: byte;
	begin
		if page = 3 then
		begin
			EditingUser.SysopNote := GetTextBox(GetUSelection, 26);
			EditingUser.Donation := GetTextBox(GetUSelection, 65);
			EditingUser.LastDonation := GetTextBox(GetUSelection, 66);
			EditingUser.ExpirationDate := GetTextBox(GetUSelection, 67);
		end
		else if page = 5 then
		begin
			EditingUser.DeletedUser := GetCheckBox(GetUSelection, 115);
		end
		else if page = 6 then
		begin
			EditingUser.UserName := GetTextBox(GetUSelection, 35);
			EditingUser.Alias := GetTextBox(GetUSelection, 15);
			EditingUser.Password := GetTextBox(GetUSelection, 37);
			EditingUser.RealName := GetTextBox(GetUSelection, 16);
			EditingUser.Phone := GetTextBox(GetUSelection, 17);
			EditingUser.DataPhone := GetTextBox(GetUSelection, 18);
			EditingUser.Street := GetTextBox(GetUSelection, 19);
			EditingUser.City := GetTextBox(GetUSelection, 20);
			EditingUser.State := GetTextBox(GetUSelection, 21);
			EditingUser.Zip := GetTextBox(GetUSelection, 22);
			EditingUser.Country := GetTextBox(GetUSelection, 23);
			EditingUser.Company := GetTextBox(GetUSelection, 24);
			EditingUser.MiscField1 := GetTextBox(GetUSelection, 25);
			EditingUser.MiscField2 := GetTextBox(GetUSelection, 26);
			EditingUser.MiscField3 := GetTextBox(GetUSelection, 27);
			EditingUser.computerType := GetTextBox(GetUSelection, 31);
			tempString := GetTextBox(GetUSelection, 33);
			if (pos('/', tempstring) > 0) and (length(tempString) > 5) and (length(tempString) < 9) then
			begin
				tempstring2 := copy(tempString, 1, pos('/', tempString) - 1);
				StringToNum(tempString2, i);
				integer(editingUser.birthmonth) := i;
				delete(tempString, 1, pos('/', tempString));
				tempstring2 := copy(tempString, 1, pos('/', tempString) - 1);
				StringToNum(tempString2, i);
				integer(editingUser.birthday) := i;
				delete(tempString, 1, pos('/', tempString));
				StringToNum(tempString, i);
				integer(editingUser.birthyear) := i;
				yearsOld(editingUser);
			end
			else
				ProblemRep('Birthdate not entered correctly!  Try MM/DD/YY');
			if newHand^^.handle then
			begin
				if EditingUser.Alias[1] <> '•' then
					EditingUser.UserName := EditingUser.alias
				else
					EditingUser.UserName := EditingUser.RealName
			end
			else
			begin
				if EditingUser.RealName[1] <> '•' then
					EditingUser.UserName := EditingUser.RealName
				else
					EditingUser.UserName := EditingUser.UserName
			end;
		end;
		WriteUser(EditingUser);
		with theNodes[visibleNode]^ do
		begin
			if (thisUser.userNum = editingUser.userNum) then
			begin
				realSL := EditingUser.SL;
				thisUser := EditingUser;
			end;
		end;
		myUsers^^[editingUser.userNum - 1].UName := editingUser.UserName;
		myUsers^^[editingUser.userNum - 1].dltd := editingUser.DeletedUser;
		myUsers^^[editingUser.userNum - 1].real := editingUser.realName;
		myUsers^^[editingUser.userNum - 1].SL := editingUser.SL;
		myUsers^^[editingUser.userNum - 1].DSL := editingUser.DSL;
		myUsers^^[editingUser.userNum - 1].age := editingUser.age;
		for i := 1 to 26 do
			myUsers^^[editingUser.userNum - 1].AccessLetter[i] := editingUser.AccessLetter[i];
		myUsers^^[editingUser.userNum - 1].city := editingUser.city;
		myUsers^^[editingUser.userNum - 1].state := editingUser.state;
	end;

	procedure EndUser;
		var
			tempString, tempString2: str255;
			tempLong, timehere, tempdong: longint;
			sharedRef: integer;
	begin
		with curglobs^ do
		begin
			if (thisUser.userNum > 1) then
				InitSystHand^^.callsToday[activeNode] := InitSystHand^^.callsToday[activeNode] + 1;
			if (thisUser.userNum >= 0) and validLogon then
			begin
				InitSystHand^^.LastUser := thisUser.userName;
				thisUser.illegalLogons := 0;
				thisUser.SL := realSL;
				if wasMadeTempSysop then
					thisUser.coSysOp := False;
				GetDateTime(tempLong);
				thisUser.lastOn := tempLong;
				myUsers^^[thisUser.userNum - 1].last := tempLong;
				if Length(MenuCommands) > 0 then
					SysOpLog(StringOf(RetInStr(570), MenuCommands), 0);	{      Menu Cmds: }
				tempString := RetInStr(571);	{      Read: }
				NumToString(mesRead, tempString2);
				tempString := concat(tempString, tempString2);
				tempString2 := tickToTime(tickCount - timeBegin);
				sysopLog(concat(tempString, RetInstr(572), tempString2, char(13)), 2);	{    Time on: }
				timeHere := ((tickCount - timeBegin) div 60 div 60) + 1;
				if subtractOn > 0 then
					subtractOn := subtractOn div 60 div 60;
				thisUser.totalTimeOn := thisUser.totalTimeOn + timeHere;
				thisUser.minOnToday := thisUser.minOnToday + timeHere - subtractOn;
				if (extraTime > 0) and thisUser.useDayorCall then
					thisUser.BonusTime := extraTime
				else
					thisUser.BonusTime := 0;
				InitSystHand^^.minsToday[activeNode] := InitSystHand^^.minsToday[activeNode] + timeHere - subtractOn;
				WriteUser(thisUser);
				thisUser.userNum := -1;
				if gBBSwindows[activeNode]^.ansiPort <> nil then
					SetWTitle(gBBSwindows[activeNode]^.ansiPort, nodename);
			end;
			WriteTempLog2Log;
			GetDateTime(tempdong);
			doSystRec(true);
		end;
	end;


	function WhatNode (name: Str255): Integer;
		var
			i: integer;
	begin
		WhatNode := 0;
		for i := 1 to InitSystHand^^.numNodes do
			if (theNodes[i]^.thisUser.userNum > 0) and (theNodes[i]^.thisUser.userName = name) and (theNodes[i]^.boardMode = user) then
				WhatNode := i;
	end;

	function UserOnSystem (name: str255): boolean;
		var
			tempBool: boolean;
			i: integer;
			ts: str255;
			tUNum: longint;
	begin
		tempBool := false;
		if (name[1] = '@') then
		begin
			ts := copy(name, 2, length(name));
			StringToNum(ts, tUNum);
		end
		else
			tUNum := -99;
		for i := 1 to InitSystHand^^.numNodes do
			if (theNodes[i]^.thisUser.userNum > 0) and (theNodes[i]^.thisUser.userName = name) and (theNodes[i]^.boardMode = user) then
				tempBool := true
			else if (theNodes[i]^.thisUser.userNum > 0) and (theNodes[i]^.thisUser.userNum = tUNum) and (theNodes[i]^.boardMode = user) then
				tempBool := true;
		userOnSystem := tempBool;
	end;

	procedure yearsOld (var theUser: userRec);
		var
			tempDate2: dateTimeRec;
	begin
		getTime(tempdate2);
		if byte(theUser.birthYear) > 5 then
			theUser.age := tempDate2.year - (byte(theUser.birthYear) + 1900)
		else
			theUser.age := tempDate2.year - (byte(theUser.birthYear) + 2000);
		if (tempDate2.month < integer(theUser.birthMonth)) or ((tempDate2.day < integer(theUser.birthDay)) and (tempDate2.month = integer(theUser.birthMonth))) then
			theUser.age := theUser.age - 1;
		if theUser.age < 0 then
			theUser.age := 0;
	end;

	function UserHungUp: boolean;
		var
			TempStat: SerStaRec;
			result: OSerr;
			ffd: longInt;
			slot, port, val: Integer;
			scc, pleaseWait, waitAck: Ptr;
			myPDCD: ParamBlockRec;
			DCDhold: byte;
			cb: TCPControlBlock;
	begin
		with curGlobs^ do
		begin
			if (nodeType = 1) then
			begin
				case carrierDetect of
					CTS5: 
					begin
						result := SerStatus(inputRef, TempStat);
						if tempStat.ctsHold <> 0 then
							UserHungUp := true
						else
							userHungUp := false;
					end;
					DCDchip: 
					begin
						if inputRef = ainRefNum then
							UserHungUp := (Ptr(PtrToLong(SccRd)^ + aCtl)^ div 8 mod 2 = 0)
						else if inputRef = binRefNum then
							UserHungUp := (Ptr(PtrToLong(SccRd)^ + bCtl)^ div 8 mod 2 = 0)
						else
							UserHungUp := true;
					end;
					DCDdriver: 
					begin
						myPDCD.ioCompletion := nil;
						myPDCD.ioRefNum := inputRef;
						myPDCD.ioVRefNum := 0;
						myPDCD.csCode := 256;
						result := PBStatus(parmBlkPtr(StripAddress(@myPDCD)), false);
						if result = noErr then
						begin
							DCDHold := ptr(ord4(@myPDCD.csParam) + 6)^;
							if DCDhold <> 0 then
								UserHungUp := false
							else
								UserHungUp := true;
						end
						else
							UserHungUp := true;
					end;
					otherwise
				end;
			end
			else if (nodeType = 2) then
			begin
				with nodeCCBPtr^ do
				begin
					userHungUp := false;
					if (BAND(userFlags, eClosed) <> 0) then
						userHungUp := true;
					if (BAND(userFlags, eTearDown) <> 0) then
						userHungUp := true;
					userFlags := 0;
				end;
			end
			else if (nodeType = 3) then
			begin
				with cb do
				begin
					ioResult := 1;
					ioCompletion := nil;

					ioCRefNum := ippDrvrRefNum;
					csCode := TCPcsStatus;
					tcpStream := nodeTCP.tcpStreamPtr;

					status.userDataPtr := nil;
				end;
				result := PBControl(ParmBlkPtr(@cb), false);

				UserHungUp := true;
				if (result = noErr) then
					if (cb.status.connectionState = CState_Established) then
						UserHungUp := false;
			end;
		end;
	end;

	procedure SetSearch;
	begin
		SetCheckBox(SearchSelection, 9, false);
		SetCheckBox(SearchSelection, 10, false);
		SetCheckBox(SearchSelection, 11, true);
		SetCheckBox(SearchSelection, 12, false);
		SetCheckBox(SearchSelection, 13, false);
		SetCheckBox(SearchSelection, 14, true);
		SetCheckBox(SearchSelection, 16, false);
		SetCheckBox(SearchSelection, 17, true);
		SetCheckBox(SearchSelection, 21, false);
		SetCheckBox(SearchSelection, 22, true);
		SetCheckBox(SearchSelection, 27, false);
		SetCheckBox(SearchSelection, 28, false);
		SetCheckBox(SearchSelection, 29, true);
		SetTextBox(SearchSelection, 3, '');
		SetTextBox(SearchSelection, 7, '');
		SetTextBox(SearchSelection, 8, '');
		SetTextBox(SearchSelection, 18, '');
		SetTextBox(SearchSelection, 23, '');
		SetTextBox(SearchSelection, 26, '');
		SLstat := 2;
		DSLstat := 2;
		LOstat := 1;
		firstStat := 1;
		ALstat := 2;
	end;

	procedure Update_User_Edit;
		var
			SavedPort: GrafPtr;
			tempRect: rect;
			i: integer;
	begin
		if (GetUSelection <> nil) and (theWindow = GetUSelection) then
		begin
			GetPort(SavedPort);
			SetPort(GetUSelection);
{    EraseRect(getUSelection^.portrect);}
			DrawDialog(GetUSelection);

			SetPort(SavedPort);
		end;
	end;


	procedure putNamesIn;
		var
			i: integer;
			dType: integer;
			dItem: handle;
			tempRect: rect;
			ds: str255;
	begin
		ds := ' ';
		for i := 1 to (numUserRecs) do
		begin
			if (fullNames^^[i].del) then
				ds[1] := '•'
			else
				ds[1] := char($CA);
			AddListString(concat(ds, fullNames^^[i].n), Userlist);
		end;
		SetTextBox(GetULSelection, 7, 'All');
	end;

	procedure PutInUser;
		var
			tempString, tempString2, tempString3: str255;
			tempDate, tempDate2: DateTimeRec;
			bbc: longInt;
			tempRect, tr2: Rect;
			myC: Point;
			DType, i: Integer;
			DItem: Handle;
			CItem, CTempItem: controlhandle;
	begin
		if page = 6 then
		begin
			SetTextBox(GetUSelection, 35, stringOf(EditingUser.UserName, ' #', editingUser.UserNum : 0));
			SetTextBox(GetUSelection, 15, EditingUser.Alias);
			SetTextBox(GetUSelection, 37, EditingUser.Password);
			SetTextBox(GetUSelection, 16, EditingUser.RealName);
			SetTextBox(GetUSelection, 17, EditingUser.Phone);
			SetTextBox(GetUSelection, 18, EditingUser.DataPhone);
			SetTextBox(GetUSelection, 19, EditingUser.Street);
			SetTextBox(GetUSelection, 20, EditingUser.City);
			SetTextBox(GetUSelection, 21, EditingUser.State);
			SetTextBox(GetUSelection, 22, EditingUser.Zip);
			SetTextBox(GetUSelection, 23, EditingUser.Country);
			SetTextBox(GetUSelection, 24, EditingUser.Company);
			if newHand^^.SysOp[1] then
				SetTextBox(GetUSelection, 12, newHand^^.SysOpText[1]);
			if newHand^^.SysOp[2] then
				SetTextBox(GetUSelection, 13, newHand^^.SysOpText[2]);
			if newHand^^.SysOp[3] then
				SetTextBox(GetUSelection, 14, newHand^^.SysOpText[3]);
			SetTextBox(GetUSelection, 25, EditingUser.MiscField1);
			SetTextBox(GetUSelection, 26, EditingUser.MiscField2);
			SetTextBox(GetUSelection, 27, EditingUser.MiscField3);

			SetTextBox(GetUSelection, 31, editingUser.computerType);

			YearsOld(editingUser);

			SetTextBox(GetUSelection, 30, stringOf(editingUser.age));

			tempString := '';
			if integer(editingUser.birthMonth) < 10 then
				TempString := '0';
			TempString := stringOf(TempString, integer(editingUser.birthMonth) : 0, '/');
			if integer(editingUser.birthDay) < 10 then
				TempString := concat(TempString, '0');
			TempString := stringOf(TempString, integer(editingUser.birthDay) : 0, '/');
			if integer(editingUser.birthYear) < 10 then
				TempString := concat(TempString, '0');
			TempString := stringOf(TempString, integer(editingUser.birthYear) : 0);

			SetTextBox(GetUSelection, 33, tempString);

			SetTextBox(GetUSelection, 30, stringOf(EditingUser.Age : 0));

			SetCheckBox(GetUSelection, 38, false);
			SetCheckBox(GetUSelection, 39, false);

			if editingUser.sex then
				SetCheckBox(GetUSelection, 38, true)
			else
				SetCheckBox(GetUSelection, 39, true);

		end
		else if page = 3 then
		begin
			SetTextBox(GetUSelection, 12, stringOf(EditingUser.UserName, ' #', editingUser.UserNum : 0));
			if newhand^^.handle and newhand^^.realname then
			begin
				SetTextBox(GetUSelection, 3, 'Realname:');
				SetTextBox(GetUSelection, 14, editingUser.RealName);
			end
			else
			begin
				SetTextBox(GetUSelection, 3, 'City,State:');
				SetTextBox(GetUSelection, 14, stringOf(editingUser.City, ', ', editingUser.State));
			end;

			tempString2 := GetDate(editingUser.lastOn);
			tempString := GetDate(editingUser.firstOn);

			tempstring := concat(tempstring2, '  First: ', tempstring);
			SetTextBox(GetUSelection, 17, tempString);

			SetTextBox(GetUSelection, 23, DoNumber(editingUser.DownloadedK));
			SetTextBox(GetUSelection, 22, DoNumber(editingUser.UploadedK));
			SetTextBox(GetUSelection, 26, editingUser.SysOpNote);
			SetTextBox(GetUSelection, 25, editingUser.lastBaud);
			SetTextBox(GetUSelection, 18, DoNumber(editingUser.MessagesPosted));
			SetTextBox(GetUSelection, 52, DoNumber(editingUser.EMailSent));
			SetTextBox(GetUSelection, 24, DoNumber(editingUser.numDownloaded));
			SetTextBox(GetUSelection, 19, DoNumber(editingUser.TotalLogons));
			getTime(tempDate);
			Secs2Date(EditingUser.lastOn, tempdate2);
			if tempDate.day <> tempDate2.day then
				EditingUser.OnToday := 0;
			SetTextBox(GetUselection, 61, DoNumber(editingUser.onToday));
			SetTextBox(GetUselection, 21, DoNumber(editingUser.numUploaded));
			SetTextBox(GetUSelection, 42, DoNumber(editingUser.DLCredits));

			SetTextBox(GetUSelection, 65, editingUser.Donation);
			SetTextBox(GetUSelection, 66, editingUser.LastDonation);
			SetTextBox(GetUSelection, 67, editingUser.ExpirationDate);

			SetTextBox(GetUSelection, 71, DrawTime(EditingUser.StartHour));
			SetTextBox(GetUSelection, 72, DrawTime(EditingUser.EndHour));

			SetCheckBox(GetUSelection, 81, editingUser.DeletedUser);
			SetCheckBox(GetUSelection, 82, editingUser.alertOn);

		end
		else if page = 5 then
		begin
			SetCheckBox(GetUSelection, 119, false);
			SetCheckBox(GetUSelection, 118, false);
			if editingUser.AlternateText then
				SetCheckBox(GetUSelection, 119, true)
			else
				SetCheckBox(GetUSelection, 118, true);
			SetTextBox(GetUSelection, 42, stringOf(EditingUser.UserName, ' #', editingUser.UserNum : 0));
			if newhand^^.handle and newhand^^.realname then
			begin
				SetTextBox(GetUSelection, 40, 'Realname:');
				SetTextBox(GetUSelection, 43, editingUser.RealName);
			end
			else
			begin
				SetTextBox(GetUSelection, 40, 'City,State:');
				SetTextBox(GetUSelection, 43, stringOf(editingUser.City, ', ', editingUser.State));
			end;
			for i := 13 to 38 do
				SetCheckBox(GetUSelection, i, editingUser.AccessLetter[i - 12]);
			SetCheckBox(GetUSelection, 2, editingUser.CantPost);
			SetCheckBox(GetUSelection, 3, editingUser.CantChat);
			SetCheckBox(GetUSelection, 4, editingUser.UDRatioOn);
			SetCheckBox(GetUSelection, 5, editingUser.PCRatioOn);
			SetCheckBox(GetUSelection, 6, editingUser.CantPostAnon);
			SetCheckBox(GetUSelection, 7, editingUser.CantSendEmail);
			SetCheckBox(GetUSelection, 8, editingUser.CantChangeAutoMsg);
			SetCheckBox(GetUSelection, 9, editingUser.CantListUser);
			SetCheckBox(GetUSelection, 10, editingUser.CantAddToBBSList);
			SetCheckBox(GetUSelection, 11, editingUser.CantSeeULInfo);
			SetCheckBox(GetUSelection, 12, editingUser.CantReadAnon);
			SetCheckBox(GetUSelection, 117, editingUser.RestrictHours);
			SetCheckBox(GetUSelection, 120, EditingUser.CantSendPPFile);
			SetCheckBox(GetUSelection, 45, EditingUser.CantNetMail);
			SetCheckBox(GetUSelection, 100, EditingUser.ReadBeforeDL);

			SetCheckBox(GetUSelection, 101, editingUser.CoSysOp);

			SetTextBox(GetUSelection, 49, stringOf(EditingUser.DLRatioOneTo : 0));
			SetTextBox(GetUSelection, 69, stringOf(EditingUser.PostRatioOneTo : 0));
			SetTextBox(GetUSelection, 71, stringOf(EditingUser.MesgDay : 0));
			SetTextBox(GetUSelection, 73, stringOf(EditingUser.LnsMessage : 0));
			SetTextBox(GetUSelection, 75, stringOf(EditingUser.CallsPrDay : 0));
			SetTextBox(GetUSelection, 77, stringOf(EditingUser.TimeAllowed : 0));
			SetTextBox(GetUSelection, 82, stringOf(EditingUser.DSL : 0));
			SetTextBox(GetUSelection, 107, stringof(EditingUser.messcomp : 1 : 1));
			SetTextBox(GetUSelection, 108, stringof(EditingUser.xfercomp : 1 : 1));
			SetCheckBox(GetUSelection, 85, False);
			SetCheckBox(GetUSelection, 83, False);
			if EditingUser.UseDayOrCall then
				SetCheckBox(GetUSelection, 83, true)
			else
				SetCheckBox(GetUSelection, 85, true);

			if SecLevels^^[editingUser.SL].active then
				SetTextBox(GetUSelection, 88, SecLevels^^[editingUser.SL].class)
			else
				SetTextBox(GetUSelection, 88, stringOf(editingUser.SL : 0, ' - Unclassified'));
			SetCheckBox(GetUSelection, 115, editingUser.DeletedUser);
			SetCheckBox(GetUSelection, 116, editingUser.alertOn);
		end;
	end;

	procedure QuickSortUsers (Start, Finish: integer);
		var
			left, right: integer;
			starterValue, temp: FullUNamesRec;
	begin
		with curglobs^ do
		begin
			left := start;
			right := finish;
			StarterValue := fullnames^^[(start + finish) div 2];
			repeat
				while (IUCompString(fullnames^^[left].n, starterValue.n) = -1) do
					left := left + 1;
				while (IUCompString(starterValue.n, fullnames^^[right].n) = -1) do
					right := right - 1;
				if left <= right then
				begin
					temp := fullnames^^[left];
					fullnames^^[left] := fullnames^^[right];
					fullnames^^[right] := temp;
					left := left + 1;
					right := right - 1;
				end;
			until right <= left;
			if start < right then
				QuickSortUsers(start, right);
			if left < finish then
				QuickSortUsers(left, finish);
		end;
	end;

	procedure QuickSortUsersLO (Start, Finish: integer);
		var
			left, right: integer;
			starterValue, temp: FullUNamesRec;
	begin
		with curglobs^ do
		begin
			left := start;
			right := finish;
			StarterValue := fullnames^^[(start + finish) div 2];
			repeat
				while fullnames^^[left].lo > starterValue.lo do
					left := left + 1;
				while starterValue.lo > fullnames^^[right].lo do
					right := right - 1;
				if left <= right then
				begin
					temp := fullnames^^[left];
					fullnames^^[left] := fullnames^^[right];
					fullnames^^[right] := temp;
					left := left + 1;
					right := right - 1;
				end;
			until right <= left;
			if start < right then
				QuickSortUsersLO(start, right);
			if left < finish then
				QuickSortUsersLO(left, finish);
		end;
	end;

	procedure MakeFullNames (whichWay: integer);
		var
			i: integer;
	begin
		SetCursor(GetCursor(watchCursor)^^);
		if FullNames <> nil then
		begin
			DisposHandle(handle(fullnames));
			fullNames := nil;
		end;
		fullNames := FullNameHand(NewHandle(SizeOf(FullUNamesRec) * longint(numUserRecs)));
		MoveHHi(handle(fullNames));
		HNoPurge(handle(fullNames));
		for i := 1 to numUserRecs do
		begin
			fullNames^^[i].n := myUsers^^[i - 1].UName;
			fullnames^^[i].lo := myUsers^^[i - 1].last;
			fullNames^^[i].del := myUsers^^[i - 1].dltd;
		end;
		case whichway of
			2: 
			begin
				QuickSortUsers(1, numUserRecs);
			end;
			3: 
			begin
				QuickSortUsersLO(1, numUserRecs);
			end;
			otherwise
		end;
	end;

	procedure DoUserSearch;
		var
			tempint, i, j, hm: integer;
			myPt: Point;
			doubleClick, pass1, pass2, pass3, pass4, pass5, pass6: boolean;
			temprect: rect;
			ttUser: userRec;
			tempString, t1, t2, searchName, searchAL: str255;
			tempInt2, result, tempLong: longInt;
			tempEMa: EMailRec;
			adder, adder2: integer;
			tempMenu, pimpMenu: MenuHandle;
			KBNunc: keyMap;
			charnum2, bitnum2: integer;
	begin
		ExitDialog := FALSE;
		if (SearchSelection <> nil) then
		begin
			if (SearchSelection = FrontWindow) then
			begin
				SetPort(SearchSelection);
				if (itemHit <> -99) then
				begin
					myPt := theEvent.where;
					GlobalToLocal(myPt);
					GetDItem(SearchSelection, itemHit, DType, DItem, tempRect);
					CItem := Pointer(DItem);
					i := ItemHit;
				end
				else
					i := 1;
				case i of
					27, 28, 29: 
					begin
						for tempint := 1 to 3 do
						begin
							GetDItem(SearchSelection, 26 + tempint, DType, DItem, tempRect);
							SetCtlValue(controlHandle(DItem), 0);
						end;
						ALstat := i - 27;
						GetDItem(SearchSelection, i, DType, DItem, tempRect);
						SetCtlValue(controlHandle(DItem), 1);
					end;
					9, 10, 11: 
					begin
						for tempint := 1 to 3 do
						begin
							GetDItem(SearchSelection, 8 + tempint, DType, DItem, tempRect);
							SetCtlValue(controlHandle(DItem), 0);
						end;
						SLstat := i - 9;
						GetDItem(SearchSelection, i, DType, DItem, tempRect);
						SetCtlValue(controlHandle(DItem), 1);
					end;
					12, 13, 14: 
					begin
						for tempint := 1 to 3 do
						begin
							GetDItem(SearchSelection, 11 + tempint, DType, DItem, tempRect);
							SetCtlValue(controlHandle(DItem), 0);
						end;
						DSLstat := i - 12;
						GetDItem(SearchSelection, i, DType, DItem, tempRect);
						SetCtlValue(controlHandle(DItem), 1);
					end;
					16, 17: 
					begin
						for tempint := 1 to 2 do
						begin
							GetDItem(SearchSelection, 15 + tempint, DType, DItem, tempRect);
							SetCtlValue(controlHandle(DItem), 0);
						end;
						LOstat := i - 16;
						GetDItem(SearchSelection, i, DType, DItem, tempRect);
						SetCtlValue(controlHandle(DItem), 1);
					end;
					21, 22: 
					begin
						for tempint := 1 to 2 do
						begin
							GetDItem(SearchSelection, 20 + tempint, DType, DItem, tempRect);
							SetCtlValue(controlHandle(DItem), 0);
						end;
						firstStat := i - 21;
						GetDItem(SearchSelection, i, DType, DItem, tempRect);
						SetCtlValue(controlHandle(DItem), 1);
					end;
					1: 
					begin
						searchName := GetTextBox(SearchSelection, 3);
						UprString(searchName, true);
						tempString := GetTextBox(SearchSelection, 7);
						StringToNum(tempstring, tempLong);
						theSL := templong;
						tempString := GetTextBox(SearchSelection, 8);
						StringToNum(tempstring, tempLong);
						theDSL := templong;
						tempString := GetTextBox(SearchSelection, 18);
						StringToNum(tempstring, tempLong);
						lastDays := templong;
						tempString := GetTextBox(SearchSelection, 23);
						StringToNum(tempstring, tempLong);
						firstDays := templong;
						searchAL := GetTextBox(SearchSelection, 26);
						count := 0;
						if GetULSelection = nil then
							OpenUserList;
						if (length(searchname) > 0) and (searchName[1] > char(47)) and (searchName[1] < char(58)) then
						begin
							if GetUSelection <> nil then
								GetStuff;
							if FindUser(searchName, ttUser) then
							begin
								SetSearch;
								editingUser := ttUser;
								Open_User_Edit;
								PutInUser;
							end;
						end
						else if (length(searchName) > 0) or (theSL > 0) or (theDSL > 0) or (lastDays > 0) or (firstDays > 0) or (length(SearchAl) > 0) then
						begin
							SetCursor(GetCursor(watchCursor)^^);
							LDoDraw(false, UserList);
							LDelRow(0, 0, UserList);
							for i := 1 to numUserRecs do
							begin
								pass1 := false;
								pass2 := false;
								pass3 := false;
								pass4 := false;
								pass5 := false;
								pass6 := false;
								if length(searchname) > 0 then
								begin
									tempstring := myUsers^^[i - 1].UName;
									UprString(tempstring, true);
									if pos(searchName, tempstring) > 0 then
										pass1 := true;
								end
								else
									pass1 := true;
								if theSL > 0 then
								begin
									case SLstat of
										0: 
											if myUsers^^[i - 1].SL > theSL then
												pass2 := true;
										1: 
											if myUsers^^[i - 1].SL < theSL then
												pass2 := true;
										2: 
											if myUsers^^[i - 1].SL = theSL then
												pass2 := true;
										otherwise
									end;
								end
								else
									pass2 := true;
								if theDSL > 0 then
								begin
									case DSLstat of
										0: 
											if myUsers^^[i - 1].DSL > theDSL then
												pass3 := true;
										1: 
											if myUsers^^[i - 1].DSL < theDSL then
												pass3 := true;
										2: 
											if myUsers^^[i - 1].DSL = theDSL then
												pass3 := true;
										otherwise
									end;
								end
								else
									pass3 := true;
								if lastDays > 0 then
								begin
									GetDateTime(tempLong);
									case LOstat of
										0: 
											if (tempLong - myUsers^^[i - 1].last) > (lastDays * 86400) then
												pass4 := true;
										1: 
											if (tempLong - myUsers^^[i - 1].last) < (lastDays * 86400) then
												pass4 := true;
										otherwise
									end;
								end
								else
									pass4 := true;
								if firstDays > 0 then
								begin
									GetDateTime(tempLong);
									case FirstStat of
										0: 
											if (tempLong - myUsers^^[i - 1].first) > (firstDays * 86400) then
												pass5 := true;
										1: 
											if (tempLong - myUsers^^[i - 1].first) < (firstDays * 86400) then
												pass5 := true;
										otherwise
									end;
								end
								else
									pass5 := true;
								if length(searchAL) > 0 then
								begin
									UprString(SearchAL, true);
									case ALstat of
										0: 
											if (myUsers^^[i - 1].AccessLetter[(byte(searchAl[1]) - byte(64))]) then
												pass6 := true;
										1: 
											if not (myUsers^^[i - 1].AccessLetter[(byte(searchAl[1]) - byte(64))]) then
												pass6 := true;
										2: 
											pass6 := true;
										otherwise
									end;
								end
								else
									pass6 := true;
								if pass1 and pass2 and pass3 and pass4 and pass5 and pass6 then
								begin
									t1 := ' ';
									if (myUsers^^[i - 1].dltd) then
										t1[1] := '•'
									else
										t1[1] := char($CA);
									AddListString(concat(t1, myUsers^^[i - 1].uName), UserList);
									count := count + 1;
								end;
							end;
							SetSearch;
							SetPort(GetULSelection);
							SetTextBox(GetULSelection, 7, StringOf(count : 0));
							tempRect := UserList^^.rView;
							tempRect.right := tempRect.right + 16;
							InvalRect(tempRect);
							LDoDraw(true, UserList);
							DrawDialog(GetULSelection);
							SelectWindow(GetULSelection);
						end;
					end;
					otherwise
				end;
			end;
		end;
	end;

	procedure DoUserList;
		var
			tempint, i, j, hm, chCode, SLstat, DSLstat, theSL, theDSL, LOstat, ALstat, firstStat, lastDays, count, firstDays: integer;
			myPt: Point;
			doubleClick, pass1, pass2, pass3, pass4, pass5, pass6: boolean;
			temprect: rect;
			ttUser: userRec;
			tempString, t1, t2, searchName, searchAL: str255;
			tempInt2, result, tempLong: longInt;
			tempEMa: EMailRec;
			adder, adder2: integer;
			tempMenu, pimpMenu: MenuHandle;
			KBNunc: keyMap;
			charnum2, bitnum2: integer;
	begin
		ExitDialog := FALSE;
		if (GetULSelection <> nil) then
		begin
			if (GetULSelection = FrontWindow) then
			begin
				SetPort(GetULSelection);
				myPt := theEvent.where;
				GlobalToLocal(myPt);
				GetDItem(GetULSelection, itemHit, DType, DItem, tempRect);
				CItem := Pointer(DItem);
				case itemHit of
					2: 
					begin
						namesDisplay := 1;
						temprect := UserList^^.rView;
						temprect.top := temprect.bottom - 20;
						OffsetRect(temprect, 0, 20);
						InvalRect(temprect);
						LDoDraw(false, UserList);
						LDelRow(0, 0, UserList);
						MakeFullNames(1);
						PutNamesIn;
						InvalRect(UserList^^.rView);
						LDoDraw(true, UserList);
						DrawDialog(GetULSelection);
					end;
					3: 
					begin
						namesDisplay := 2;
						LDoDraw(false, UserList);
						LDelRow(0, 0, UserList);
						MakeFullNames(2);
						PutNamesIn;
						temprect := UserList^^.rView;
						temprect.bottom := temprect.bottom + 20;
						InvalRect(temprect);
						LDoDraw(true, UserList);
						DrawDialog(GetULSelection);
					end;
					4: 
					begin
						namesDisplay := 3;
						LDoDraw(false, UserList);
						LDelRow(0, 0, UserList);
						MakeFullNames(3);
						PutNamesIn;
						temprect := UserList^^.rView;
						temprect.bottom := temprect.bottom + 20;
						InvalRect(temprect);
						LDoDraw(true, UserList);
						DrawDialog(GetULSelection);
					end;
					5: 
						OpenUserSearch;
					1: 
					begin
						DoubleClick := LClick(myPt, theEvent.modifiers, UserList);
						UserCell.h := 0;
						UserCell.v := 0;
						if LGetSelect(true, UserCell, UserList) then
						begin
							tempint := 50;
							LGetCell(@tempString[1], tempint, UserCell, UserList);
							tempString[0] := char(tempint);
							delete(tempString, 1, 1);
							if (tempstring <> editingUser.userName) then
							begin
								if GetUSelection <> nil then
									GetStuff
								else
									Open_User_Edit;
								if FindUser(tempString, ttUser) then
								begin
									editingUser := ttUser;
									PutInUser;
{    DrawDialog(GetUSelection);}
								end;
							end;
						end;
					end;
					otherwise
				end;
			end
			else
				SelectWindow(GetULSelection);
		end;
	end;

	procedure UpdateUserSearch;
		var
			SavedPort: GrafPtr;
			tempRect: rect;
			i: integer;
	begin
		if (SearchSelection <> nil) and (theWindow = SearchSelection) then
		begin
			GetPort(SavedPort);
			SetPort(SearchSelection);
			GetDItem(SearchSelection, 1, DType, DItem, tempRect);
			InsetRect(tempRect, -4, -4);
			PenSize(3, 3);
			FrameRoundRect(tempRect, 16, 16);
			DrawDialog(SearchSelection);

			SetPort(SavedPort);
		end;
	end;

	procedure DrawTheGrowIcon (Dilg: DialogPtr);
		var
			tempRect: rect;
			aClip: RgnHandle;
	begin
		tempRect := Dilg^.portRect;
		tempRect.left := tempRect.right - 15;
		tempRect.top := tempRect.bottom - 15;
		aClip := NewRgn;
		GetClip(aClip);
		ClipRect(tempRect);
		DrawGrowIcon(Dilg);
		SetClip(aClip);
		DisposeRgn(aClip);
	end;

	procedure UpdateUserList;
		var
			SavedPort: GrafPtr;
			ItemRect: rect;
			i, ItemType: integer;
			ItemHandle: handle;
	begin
		if (GetULSelection <> nil) and (theWindow = GetULSelection) then
		begin
			GetPort(SavedPort);
			SetPort(GetULSelection);
			EraseRect(getULSelection^.portrect);

			GetDItem(GetULSelection, 1, ItemType, ItemHandle, ItemRect);
			ItemRect.right := ItemRect.right - 14;
			InsetRect(ItemRect, -1, -1);
			FrameRect(ItemRect);
			if (UserList <> nil) then
				LUpdate(GetULSelection^.visRgn, UserList);
{DrawTheGrowIcon(GetULSelection);}
			DrawDialog(GetULSelection);

			SetPort(SavedPort);
		end;
	end;

	procedure CloseUserList;
	begin
		if (GetULSelection <> nil) then
		begin
			SetPort(GetULSelection);
			InitSystHand^^.wusers := GetULSelection^.portRect;
			LocalToGlobal(InitSystHand^^.wusers.topLeft);
			LocalToGlobal(InitSystHand^^.wusers.botRight);
			if quit = 0 then
				InitSystHand^^.WuserOpen := false;
			LDispose(UserList);
			UserList := nil;
			DisposDialog(GetULSelection);
			GetULSelection := nil;
			if FullNames <> nil then
			begin
				DisposHandle(handle(fullnames));
				fullNames := nil;
			end;
		end;
	end;


	procedure OpenUserList;
		var
			tempRect, tr2: Rect;
			myC: Point;
			DType, i: Integer;
			DItem: Handle;
	begin
		if (GetULSelection = nil) then
		begin
			namesdisplay := 1;
			makeFullNames(1);
			GetULSelection := GetNewDialog(4995, nil, Pointer(-1));
			SetPort(GetULSelection);
			SetGeneva(GetULSelection);
			MoveWindow(GetULSelection, InitSystHand^^.Wusers.left, InitSystHand^^.Wusers.top, true);
{DrawTheGrowIcon(GetULSelection);}

			GetDItem(GetULSelection, 1, dType, dItem, tempRect);
			TempRect.right := tempRect.right - 14;
			SetRect(tr2, 0, 0, 1, 0);
			SetPt(myC, tempRect.right - tempRect.left, 12);
			UserList := LNew(tempRect, tr2, myC, 0, GetULSelection, false, false, false, true);
			PutNamesIn;
			LDoDraw(true, UserList);
			ShowWindow(GetULSelection);
			InitSystHand^^.WuserOpen := true;
		end
		else
			SelectWindow(GetULSelection);
	end;

	procedure Old_OpenUserList;
		var
			tempRect, tr2: Rect;
			myC: Point;
			DType, i: Integer;
			DItem: Handle;
	begin
		if (GetULSelection = nil) then
		begin
			namesdisplay := 1;
			makeFullNames(1);
			GetULSelection := GetNewDialog(4995, nil, Pointer(-1));
			SetPort(GetULSelection);
			SetGeneva(GetULSelection);
			MoveWindow(GetULSelection, InitSystHand^^.Wusers.left, InitSystHand^^.Wusers.top, true);
{DrawTheGrowIcon(GetULSelection);}

			GetDItem(GetULSelection, 1, dType, dItem, tempRect);
			TempRect.right := tempRect.right - 14;
			SetRect(tr2, 0, 0, 1, 0);
			SetPt(myC, tempRect.right - tempRect.left, 12);
			UserList := LNew(tempRect, tr2, myC, 0, GetULSelection, false, false, false, true);
			PutNamesIn;
			LDoDraw(true, UserList);
			ShowWindow(GetULSelection);
			InitSystHand^^.WuserOpen := true;
		end
		else
			SelectWindow(GetULSelection);
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
			LUpdate(theWindow^.visRgn, UList);
		end;
	end;

	procedure OpenSysopPage (num: integer);
		var
			DITLhandle: handle;
			sizeMinusNum, numItems: integer;
			theEvent: eventRecord;
			TheDialogPtr: DialogPeek;
			temprect: rect;
	begin
		ShortenDITL(GetUSelection, numAddedItems);
		DITLHandle := Get1Resource('DITL', num);
		AppendDITL(GetUSelection, DITLHandle, overlayDITL);
		ReleaseResource(DITLHandle);
		SetPort(GetUSelection);
		numAddedItems := CountDITL(GetUSelection) - 1;
		InvalRect(GetUSelection^.portRect);
	end;

	procedure Open_User_Edit;
		type
			myIconDataRec = record
					IconNumber: integer;
					IconTitle: str255;
				end;

		var
			Dtype, j, i, therow: integer;
			DItem: handle;
			tempRect, dataBounds, tr2: rect;
			cSize: cell;
			theDialogPtr: dialogPeek;
			stemp: str255;
			myHandle: handle;
			myIconData: myIconDataRec;
	begin
		i := 0;
		if GetUSelection = nil then
		begin
			page := 5;
			numAddedItems := 0;

			GetUSelection := GetNewDialog(2, nil, pointer(-1));
			SetPort(GetUSelection);
			SetGeneva(GetUSelection);

			GetDItem(GetUSelection, 1, DType, DItem, tempRect);
			tr2 := temprect;
			tempRect.right := tempRect.right - 15;
			SetRect(dataBounds, 0, 0, 1, 0);
			cSize.h := tempRect.right - tempRect.left;
			cSize.v := 58;
			Ulist := LNew(tempRect, dataBounds, cSize, 1000, GetUSelection, FALSE, FALSE, FALSE, TRUE);
			UList^^.selFlags := lOnlyOne + lNoNilHiLite;
			SetDItem(GetUSelection, 1, DType, @DrawExternalsList, tr2);
			theRow := LAddRow(5, 200, UList);
{Icon 0}
			cSize.v := 0;
			cSize.h := 0;
			myIconData.IconNumber := 7001;
			myIconData.IconTitle := 'Security';
			LSetCell(@myIconData, SizeOf(myIconDataRec), cSize, UList);
{Icon 1}
			cSize.v := 1;
			cSize.h := 0;
			myIconData.IconNumber := 7000;
			myIconData.IconTitle := 'Stats';
			LSetCell(@myIconData, SizeOf(myIconDataRec), cSize, UList);
{Icon 2}
			cSize.v := 2;
			cSize.h := 0;
			myIconData.IconNumber := 7002;
			myIconData.IconTitle := 'Information';
			LSetCell(@myIconData, SizeOf(myIconDataRec), cSize, UList);
{Icon 3}
			cSize.v := 3;
			cSize.h := 0;
			myIconData.IconNumber := 7004;
			myIconData.IconTitle := 'User List';
			LSetCell(@myIconData, SizeOf(myIconDataRec), cSize, UList);
{Icon 4}
			cSize.v := 4;
			cSize.h := 0;
			myIconData.IconNumber := 7005;
			myIconData.IconTitle := 'User Search';
			LSetCell(@myIconData, SizeOf(myIconDataRec), cSize, UList);

			ShowWindow(GetUSelection);
			OpenSysOpPage(page);
			PutInUser;
			cSize.h := 0;
			cSize.v := 0;
			LSetSelect(TRUE, cSize, UList);
			LDoDraw(true, UList);
		end
		else
			SelectWindow(GetUSelection);
	end;

	procedure OpenUserSearch;
		var
			TheDialogPtr: DialogPeek;
			tempRect, tr2: Rect;
			myC: Point;
			DType, i: Integer;
			DItem: Handle;
	begin
		if (SearchSelection = nil) then
		begin
			SearchSelection := GetNewDialog(3467, nil, Pointer(-1));
			SetPort(SearchSelection);
			SetSearch;
			GetDItem(SearchSelection, 1, DType, DItem, tempRect);
			InsetRect(tempRect, -4, -4);
			PenSize(3, 3);
			FrameRoundRect(tempRect, 16, 16);
			DrawDialog(SearchSelection);
			ShowWindow(SearchSelection);
		end
		else
			SelectWindow(SearchSelection);
	end;

	procedure CloseUserSearch;
	begin
		if (SearchSelection <> nil) then
		begin
			DisposDialog(SearchSelection);
			SearchSelection := nil;
		end;
	end;

	procedure Close_User_Edit;
		var
			cSize: Point;
	begin
		if (theWindow = GetUSelection) and (GetUSelection <> nil) then
		begin
			if not Cancelled then
				GetStuff;
			LDispose(UList);
			DisposDialog(GetUSelection);
			GetUSelection := nil;
			EditingUser.UserName := '';
			csize := cell($00000000);
			if LGetSelect(true, cSize, UserList) then
			begin
				LSetSelect(false, cSize, UserList);
			end;
			if FullNames <> nil then
			begin
				DisposHandle(handle(fullnames));
				fullNames := nil;
			end;
		end;
	end;

	procedure Do_User_Edit;
		var
			tempint, i, j, hm, chCode, SLstat, DSLstat, theSL, theDSL, LOstat, firstStat, lastDays, count, firstDays: integer;
			myPt: Point;
			doubleClick, pass1, pass2, pass3, pass4, pass5: boolean;
			temprect: rect;
			ttUser: userRec;
			tempString, t1, t2, searchName: str255;
			tempInt2, result, tempLong: longInt;
			tempEMa: EMailRec;
			adder, adder2, adder4: integer;
			adder3: real;
			tempMenu, pimpMenu: MenuHandle;
			KBNunc: keyMap;
			charnum2, bitnum2: integer;
			tc2: cell;
	begin
		ExitDialog := FALSE;
		if (GetUSelection <> nil) then
		begin
			if (getUSelection = FrontWindow) then
			begin
				SetPort(GetUSelection);
				myPt := theEvent.where;
				GlobalToLocal(myPt);
				GetDItem(GetUSelection, itemHit, DType, DItem, tempRect);
				CItem := Pointer(DItem);
				adder2 := 1000;
				adder := 100;
				adder4 := 3600;
				GetKeys(KBnunc);
				charnum2 := 55 div 8;
				bitnum2 := 7 - (55 mod 8);
				if (bitTst(@KBNunc, 8 * charnum2 + bitnum2)) then
				begin
					adder2 := 1;
					adder := 1;
				end;
				if optiondown then
				begin
					adder2 := 100;
					adder := 10;
					adder4 := 60;
				end;
				if (optiondown) and (bitTst(@KBNunc, 8 * charnum2 + bitnum2)) then
					adder2 := 10;
				if itemhit = 1 then
				begin
					UserCell := cell($00000000);
					if LGetSelect(true, UserCell, UList) then
						;
					DoubleClick := LClick(myPt, theEvent.modifiers, UList);
					tc2 := cell($00000000);
					if not LGetSelect(true, tc2, UList) then
						LSetSelect(true, UserCell, UList)
					else
					begin
						if (tc2.v = 0) and (page <> 5) then
						begin
							GetStuff;
							page := 5;
							OpenSysOpPage(page);
							PutInUser;
						end
						else if (tc2.v = 1) and (page <> 3) then
						begin
							GetStuff;
							page := 3;
							OpenSysOpPage(page);
							PutInUser;
						end
						else if (tc2.v = 2) and (page <> 6) then
						begin
							GetStuff;
							page := 6;
							OpenSysOpPage(page);
							PutInUser;
						end
						else if (tc2.v = 3) then
						begin
							OpenUserList;
						end
						else if (tc2.v = 4) then
						begin
							OpenUserSearch;
						end;
					end;
				end;
				if (((itemHit = 40) and (page = 6)) or ((itemHit = 79) and (page = 3))) and (GetULSelection <> nil) then
				begin
					ProblemRep('Hit It!');
				end;
				if page = 6 then
				begin
					CheckUEditAlpha := false;
					case itemHit of
						37: 
							CheckUEditAlpha := true;
						38, 39: 
						begin
							if not ((ItemHit = 38) and (GetCheckBox(GetUSelection, 38)) or (ItemHit = 39) and (GetCheckBox(GetUSelection, 39))) then
							begin
								SetCheckBox(GetUSelection, 38, false);
								SetCheckBox(GetUSelection, 39, false);
								if ItemHit = 38 then
								begin
									SetCheckBox(GetUSelection, 38, true);
									editingUser.sex := True;
								end
								else
								begin
									SetCheckBox(GetUSelection, 39, true);
									editingUser.sex := False;
								end;
							end;
						end;
					end;
				end
				else if page = 3 then
				begin
					case itemHit of
						43, 44: 
						begin
							if (itemHit = 43) then
								adder2 := adder2 * (-1);
							EditingUser.DLCredits := UpDown(GetUSelection, 42, EditingUser.DLCredits, Adder2, 9999999, 0);
						end;
						38, 39: 
						begin
							if (itemHit = 38) then
								adder2 := adder2 * (-1);
							EditingUser.downloadedK := UpDown(GetUSelection, 23, EditingUser.downloadedK, Adder2, 9999999, 0);
						end;
						35, 36: 
						begin
							if (itemHit = 35) then
								adder := adder * (-1);
							EditingUser.numDownloaded := UpDown(GetUSelection, 24, EditingUser.numDownloaded, Adder, 99999, 0);
						end;
						32, 33: 
						begin
							if (itemHit = 32) then
								adder2 := adder2 * (-1);
							EditingUser.Uploadedk := UpDown(GetUSelection, 22, EditingUser.Uploadedk, Adder2, 9999999, 0);
						end;
						29, 30: 
						begin
							if (itemHit = 29) then
								adder := adder * (-1);
							EditingUser.numUploaded := UpDown(GetUSelection, 21, EditingUser.numUploaded, Adder, 99999, 0);
						end;
						57, 58: 
						begin
							if (itemHit = 57) then
								adder := adder * (-1);
							EditingUser.OnToday := UpDown(GetUSelection, 61, EditingUser.OnToday, Adder, 99999, 0);
						end;
						54, 55: 
						begin
							if (itemHit = 54) then
								adder := adder * (-1);
							EditingUser.TotalLogons := UpDown(GetUSelection, 19, EditingUser.TotalLogons, Adder, 99999, 0);
						end;
						48, 49: 
						begin
							if (itemHit = 48) then
								adder := adder * (-1);
							EditingUser.MessagesPosted := UpDown(GetUSelection, 18, EditingUser.MessagesPosted, Adder, 99999, 0);
						end;
						74: 
							if EditingUser.RestrictHours then
							begin
								if ((EditingUser.StartHour + adder4) < 86400) then
								begin
									EditingUser.StartHour := EditingUser.StartHour + adder4
								end
								else
									EditingUser.StartHour := (EditingUser.StartHour + adder4) - 86400;
								SetTextBox(GetUSelection, 71, DrawTime(EditingUser.StartHour));
							end;
						73: 
							if EditingUser.RestrictHours then
							begin
								if ((EditingUser.StartHour - adder4) > 0) then
								begin
									EditingUser.StartHour := EditingUser.StartHour - adder4
								end
								else
									EditingUser.StartHour := (EditingUser.StartHour - adder4) + 86400;
								SetTextBox(GetUSelection, 71, DrawTime(EditingUser.StartHour));
							end;
						77: 
							if EditingUser.RestrictHours then
							begin
								if ((EditingUser.EndHour + adder4) < 86400) then
								begin
									EditingUser.EndHour := EditingUser.EndHour + adder4
								end
								else
									EditingUser.EndHour := (EditingUser.EndHour + adder4) - 86400;
								SetTextBox(GetUSelection, 72, DrawTime(EditingUser.EndHour));
							end;
						76: 
							if EditingUser.RestrictHours then
							begin
								if ((EditingUser.EndHour - adder4) > 0) then
								begin
									EditingUser.EndHour := EditingUser.EndHour - adder4
								end
								else
									EditingUser.EndHour := (EditingUser.EndHour - adder4) + 86400;
								SetTextBox(GetUSelection, 72, DrawTime(EditingUser.EndHour));
							end;
						82: 
						begin
							if EditingUser.alertOn then
								EditingUser.alertOn := False
							else
								EditingUser.alertOn := True;
							SetCheckBox(GetUSelection, 82, EditingUser.alertOn);
						end;
						81: 
						begin
							temp := GetCtlValue(CItem);
							SetCtlValue(CItem, (temp + 1) mod 2);
							if temp = 0 then
							begin
								InitSystHand^^.numUsers := InitSystHand^^.numUsers - 1;
								doSystRec(true);
								with curglobs^ do
								begin
									i := 0;
									while (i < availEmails) do
									begin
										if (theEmail^^[i].toUser = editingUser.userNum) or (theEmail^^[i].FromUser = editingUser.userNum) then
											DeleteMail(i)
										else
											i := i + 1;
									end;
									if EditingUser.UserName[1] <> '~' then
										EditingUser.UserName := concat('~', EditingUser.UserName);
									if EditingUser.Alias[1] <> '•' then
										EditingUser.alias := EditingUser.UserName
									else
										EditingUser.RealName := EditingUser.UserName;
									EditingUser.DeletedUser := True;
								end;
							end
							else
							begin
								InitSystHand^^.numUsers := InitSystHand^^.numUsers + 1;
								EditingUser.DeletedUser := False;
								if EditingUser.UserName[1] = '~' then
									Delete(EditingUser.UserName, 1, 1);
								if EditingUser.Alias[1] <> '•' then
									EditingUser.alias := EditingUser.UserName
								else
									EditingUser.RealName := EditingUser.UserName;
								doSystRec(true);
							end;
						end;
					end;
				end
				else if page = 5 then
				begin
					adder := 10;
					adder3 := 1.0;
					if optiondown then
					begin
						adder := 1;
						adder3 := 0.1;
					end;
					case itemHit of
						100: 
						begin
							if EditingUser.ReadBeforeDL then
								EditingUser.ReadBeforeDL := false
							else
								EditingUser.ReadBeforeDL := true;
							SetCheckBox(GetUSelection, 100, EditingUser.ReadBeforeDL);
						end;
						120: 
						begin
							if EditingUser.CantSendPPFile then
								EditingUser.CantSendPPFile := false
							else
								EditingUser.CantSendPPFile := true;
							SetCheckBox(GetUSelection, 120, EditingUser.CantSendPPFile);
						end;
						45: 
						begin
							if EditingUser.CantNetMail then
								EditingUser.CantNetMail := false
							else
								EditingUser.CantNetMail := true;
							SetCheckBox(GetUSelection, 45, EditingUser.CantNetMail);
						end;
						118: 
						begin
							EditingUser.AlternateText := false;
							SetCheckBox(GetUSelection, 119, false);
							SetCheckBox(GetUSelection, 118, true);
						end;
						119: 
						begin
							EditingUser.AlternateText := true;
							SetCheckBox(GetUSelection, 118, false);
							SetCheckBox(GetUSelection, 119, true);
						end;
						117: 
						begin
							if EditingUser.RestrictHours then
								EditingUser.RestrictHours := False
							else
								EditingUser.RestrictHours := True;
							SetCheckBox(GetUSelection, 117, EditingUser.RestrictHours);
						end;
						116: 
						begin
							if EditingUser.alertOn then
								EditingUser.alertOn := False
							else
								EditingUser.alertOn := True;
							SetCheckBox(GetUSelection, 116, EditingUser.alertOn);
						end;
						115: 
						begin
							temp := GetCtlValue(CItem);
							SetCtlValue(CItem, (temp + 1) mod 2);
							if temp = 0 then
							begin
								InitSystHand^^.numUsers := InitSystHand^^.numUsers - 1;
								doSystRec(true);
								with curglobs^ do
								begin
									i := 0;
									while (i < availEmails) do
									begin
										if (theEmail^^[i].toUser = editingUser.userNum) or (theEmail^^[i].FromUser = editingUser.userNum) then
											DeleteMail(i)
										else
											i := i + 1;
									end;
									if EditingUser.UserName[1] <> '~' then
										EditingUser.UserName := concat('~', EditingUser.UserName);
									if EditingUser.Alias[1] <> '•' then
										EditingUser.alias := EditingUser.UserName
									else
										EditingUser.RealName := EditingUser.UserName;
									EditingUser.DeletedUser := True;
								end;
							end
							else
							begin
								InitSystHand^^.numUsers := InitSystHand^^.numUsers + 1;
								EditingUser.DeletedUser := False;
								if EditingUser.UserName[1] = '~' then
									Delete(EditingUser.UserName, 1, 1);
								if EditingUser.Alias[1] <> '•' then
									EditingUser.alias := EditingUser.UserName
								else
									EditingUser.RealName := EditingUser.UserName;
								doSystRec(true);
							end;
						end;
						88: 
						begin
							if CmdDown then
								SetTextBox(GetUSelection, 103, 'Combine Access & Restrictions')
							else if optiondown then
								SetTextBox(GetUSelection, 103, 'Change Security Level & DSL')
							else
								SetTextBox(GetUSelection, 103, 'Change Everything');
							pimpMenu := NewMenu(62, 'Security Levels');
							if (pimpMenu <> nil) then
								for i := 1 to 255 do
								begin
									if SecLevels^^[i].active then
									begin
										AppendMenu(pimpMenu, ' ');
										SetITem(pimpMenu, countMItems(pimpMenu), SecLevels^^[i].Class);
									end;
								end;
							insertMenu(pimpMenu, -1);
							myPt.v := tempRect.top;
							myPt.h := tempRect.left;
							LocalToGlobal(myPt);
							tempint := Security(editingUser.SL);
							CheckItem(pimpMenu, tempint, true);
							result := PopUpMenuSelect(pimpMenu, myPt.v, myPt.h, tempint);
							if (LoWord(Result) > 0) then
							begin
								tempint := LoWord(Result);
								hm := 0;
								for i := 1 to 255 do
								begin
									if SecLevels^^[i].active then
									begin
										hm := hm + 1;
										if (hm = tempint) and (EditingUser.SL <> i) then
										begin
											GetStuff;
											EditingUser.SL := i;
											EditingUser.DSL := SecLevels^^[i].TransLevel;
											EditingUser.XferComp := SecLevels^^[i].XferComp;
											EditingUser.messcomp := SecLevels^^[i].MessComp;
											EditingUser.UseDayOrCall := SecLevels^^[i].UseDayOrCall;
											EditingUser.TimeAllowed := SecLevels^^[i].TimeAllowed;
											EditingUser.MesgDay := SecLevels^^[i].MesgDay;
											EditingUser.DLRatioOneTo := SecLevels^^[i].DLRatioOneTo;
											EditingUser.PostRatioOneTo := SecLevels^^[i].PostRatioOneTo;
											EditingUser.CallsPrDay := SecLevels^^[i].CallsPrDay;
											EditingUser.LnsMessage := SecLevels^^[i].LnsMessage;
											EditingUser.AlternateText := SecLevels^^[i].AlternateText;
											if CmdDown then
											begin
												for j := 1 to 26 do
												begin
													if SecLevels^^[i].Restrics[j] then
														EditingUser.AccessLetter[j] := SecLevels^^[i].Restrics[j];
												end;
												if SecLevels^^[i].ReadAnon then
													EditingUser.CantReadAnon := SecLevels^^[i].ReadAnon;
												if SecLevels^^[i].PostMessage then
													EditingUser.CantPost := SecLevels^^[i].PostMessage;
												if SecLevels^^[i].BBSList then
													EditingUser.CantAddToBBSList := SecLevels^^[i].BBSList;
												if SecLevels^^[i].Uploader then
													EditingUser.CantSeeULInfo := SecLevels^^[i].Uploader;
												if SecLevels^^[i].UDRatio then
													EditingUser.UDRatioOn := SecLevels^^[i].UDRatio;
												if SecLevels^^[i].Chat then
													EditingUser.CantChat := SecLevels^^[i].Chat;
												if SecLevels^^[i].Email then
													EditingUser.CantSendEmail := SecLevels^^[i].Email;
												if SecLevels^^[i].ListUser then
													EditingUser.CantListUser := SecLevels^^[i].ListUser;
												if SecLevels^^[i].AutoMsg then
													EditingUser.CantChangeAutoMsg := SecLevels^^[i].AutoMsg;
												if SecLevels^^[i].AnonMsg then
													EditingUser.CantPostAnon := SecLevels^^[i].AnonMsg;
												if SecLevels^^[i].PCRatio then
													EditingUser.PCRatioOn := SecLevels^^[i].PCRatio;
												if SecLevels^^[i].EnableHours then
													EditingUser.RestrictHours := SecLevels^^[i].EnableHours;
												if SecLevels^^[i].PPFile then
													EditingUser.CantSendPPFile := SecLevels^^[i].PPFile;
												if SecLevels^^[i].CantNetMail then
													EditingUser.CantNetMail := SecLevels^^[i].CantNetMail;
												if SecLevels^^[i].MustRead then
													EditingUser.ReadBeforeDL := SecLevels^^[i].MustRead;
											end
											else if not optiondown then
											begin
												for j := 1 to 26 do
													EditingUser.AccessLetter[j] := SecLevels^^[i].Restrics[j];
												EditingUser.CantReadAnon := SecLevels^^[i].ReadAnon;
												EditingUser.CantPost := SecLevels^^[i].PostMessage;
												EditingUser.CantAddToBBSList := SecLevels^^[i].BBSList;
												EditingUser.CantSeeULInfo := SecLevels^^[i].Uploader;
												EditingUser.UDRatioOn := SecLevels^^[i].UDRatio;
												EditingUser.CantChat := SecLevels^^[i].Chat;
												EditingUser.CantSendEmail := SecLevels^^[i].Email;
												EditingUser.CantListUser := SecLevels^^[i].ListUser;
												EditingUser.CantChangeAutoMsg := SecLevels^^[i].AutoMsg;
												EditingUser.CantPostAnon := SecLevels^^[i].AnonMsg;
												EditingUser.PCRatioOn := SecLevels^^[i].PCRatio;
												EditingUser.RestrictHours := SecLevels^^[i].EnableHours;
												EditingUser.CantSendPPFile := SecLevels^^[i].PPFile;
												EditingUser.CantNetMail := SecLevels^^[i].CantNetMail;
												EditingUser.ReadBeforeDL := SecLevels^^[i].MustRead;
											end;
											PutInUser;
										end;
									end;
								end;
								SetTextBox(GetUSelection, 88, SecLevels^^[editingUser.SL].class);
							end;
							DeleteMenu(62);
							DisposeMenu(pimpMenu);
							SetTextBox(GetUSelection, 103, '');
						end;
						50, 51: 
						begin
							if (itemHit = 50) then
								adder := adder * (-1);
							editingUser.DLRatioOneTo := UpDown(GetUSelection, 49, editingUser.DLRatioOneTo, Adder, 99, 0);
						end;
						53, 54: 
						begin
							if (itemHit = 53) then
								adder := adder * (-1);
							editingUser.PostRatioOneTo := UpDown(GetUSelection, 69, editingUser.PostRatioOneTo, Adder, 99, 0);
						end;
						109, 110: 
						begin
							if (itemHit = 109) then
								adder3 := adder3 * (-1);
							editingUser.messcomp := UpDownReal(GetUSelection, 107, editingUser.messcomp, adder3, 99.9, 0.00);
						end;
						112, 113: 
						begin
							if (itemHit = 112) then
								adder3 := adder3 * (-1);
							editingUser.xfercomp := UpDownReal(GetUSelection, 108, editingUser.xfercomp, adder3, 99.9, 0.00);
						end;
						85, 83: 
						begin
							if not ((ItemHit = 85) and (GetCheckBox(GetUSelection, 85)) or (ItemHit = 83) and (GetCheckBox(GetUSelection, 83))) then
							begin
								SetCheckBox(GetUSelection, 85, false);
								SetCheckBox(GetUSelection, 83, false);
								if ItemHit = 83 then
								begin
									SetCheckBox(GetUSelection, 83, true);
									editingUser.UseDayOrCall := True;
								end
								else
								begin
									SetCheckBox(GetUSelection, 85, true);
									editingUser.UseDayOrCall := False;
								end;
							end;
						end;
						56, 57: 
						begin
							if (itemHit = 56) then
								adder := adder * (-1);
							editingUser.MesgDay := UpDown(GetUSelection, 71, editingUser.MesgDay, Adder, 999, 0);
						end;
						59, 60: 
						begin
							if (itemHit = 59) then
								adder := adder * (-1);
							editingUser.LnsMessage := UpDown(GetUSelection, 73, editingUser.LnsMessage, Adder, 200, 0);
						end;
						62, 63: 
						begin
							if (itemHit = 62) then
								adder := adder * (-1);
							editingUser.CallsPrDay := UpDown(GetUSelection, 75, editingUser.CallsPrDay, Adder, 999, 0);
						end;
						78, 79: 
						begin
							if (itemHit = 78) then
								adder := adder * (-1);
							editingUser.DSL := UpDown(GetUSelection, 82, editingUser.DSL, Adder, 255, 0);
						end;
						65, 66: 
						begin
							if (itemHit = 65) then
								adder := adder * (-1);
							editingUser.TimeAllowed := UpDown(GetUSelection, 77, editingUser.TimeAllowed, Adder, 999, 0);
						end;
						13..38: 
						begin
							if editingUser.AccessLetter[itemHit - 12] then
								editingUser.AccessLetter[itemHit - 12] := false
							else
								editingUser.AccessLetter[itemHit - 12] := true;
							SetCheckBox(GetUSelection, ItemHit, editingUser.AccessLetter[itemHit - 12]);
						end;
						12: 
						begin
							if EditingUser.CantReadAnon then
								EditingUser.CantReadAnon := False
							else
								EditingUser.CantReadAnon := True;
							SetCheckBox(GetUSelection, 12, EditingUser.CantReadAnon);
						end;
						101: 
						begin
							if EditingUser.coSysOp then
								EditingUser.coSysOp := False
							else
								EditingUser.coSysOp := True;
							SetCheckBox(GetUSelection, 101, EditingUser.coSysOp);
						end;
						104: 
							;
						2: 
						begin
							if EditingUser.CantPost then
								EditingUser.CantPost := False
							else
								EditingUser.CantPost := True;
							SetCheckBox(GetUSelection, 2, EditingUser.CantPost);
						end;
						3: 
						begin
							if EditingUser.CantChat then
								EditingUser.CantChat := False
							else
								EditingUser.CantChat := True;
							SetCheckBox(GetUSelection, 3, EditingUser.CantChat);
						end;
						4: 
						begin
							if EditingUser.UDRatioOn then
								EditingUser.UDRatioOn := False
							else
								EditingUser.UDRatioOn := True;
							SetCheckBox(GetUSelection, 4, EditingUser.UDRatioOn);
						end;
						5: 
						begin
							if EditingUser.PCRatioOn then
								EditingUser.PCRatioOn := False
							else
								EditingUser.PCRatioOn := True;
							SetCheckBox(GetUSelection, 5, EditingUser.PCRatioOn);
						end;
						6: 
						begin
							if EditingUser.CantPostAnon then
								EditingUser.CantPostAnon := False
							else
								EditingUser.CantPostAnon := True;
							SetCheckBox(GetUSelection, 6, EditingUser.CantPostAnon);
						end;
						7: 
						begin
							if EditingUser.CantSendEmail then
								EditingUser.CantSendEmail := False
							else
								EditingUser.CantSendEmail := True;
							SetCheckBox(GetUSelection, 7, EditingUser.CantSendEmail);
						end;
						8: 
						begin
							if EditingUser.CantChangeAutoMsg then
								EditingUser.CantChangeAutoMsg := False
							else
								EditingUser.CantChangeAutoMsg := True;
							SetCheckBox(GetUSelection, 8, EditingUser.CantChangeAutoMsg);
						end;
						9: 
						begin
							if EditingUser.CantListUser then
								EditingUser.CantListUser := False
							else
								EditingUser.CantListUser := True;
							SetCheckBox(GetUSelection, 9, EditingUser.CantListUser);
						end;
						10: 
						begin
							if EditingUser.CantAddToBBSList then
								EditingUser.CantAddToBBSList := False
							else
								EditingUser.CantAddToBBSList := True;
							SetCheckBox(GetUSelection, 10, EditingUser.CantAddToBBSList);
						end;
						11: 
						begin
							if EditingUser.CantSeeULInfo then
								EditingUser.CantSeeULInfo := False
							else
								EditingUser.CantSeeULInfo := True;
							SetCheckBox(GetUSelection, 11, EditingUser.CantSeeULInfo);
						end;
					end;
				end
				else
					SelectWindow(getUSelection);
			end;
		end;
	end;

	procedure MakeUserList;
		type
			UserArrPtr = ^UserArrRec;
			UserArrRec = array[0..31] of UserRec;
		var
			tempString, tempString2: str255;
			tempInt, SizeOfAUser, UserNum, ListRef, i, c, j, UsersRes: integer;
			tempLong, AllUsersSize, b: longInt;
			result: OSerr;
			myUserArr: UserArrPtr;
	begin
		doSystRec(false);
		if myUsers <> nil then
		begin
			HPurge(handle(myUsers));
			DisposHandle(handle(myUsers));
			myUsers := nil;
		end;
		InitSystHand^^.numUsers := 0;
		numUserRecs := 0;
		result := FSOpen(concat(SharedFiles, 'Users'), 0, UsersRes);
		if result <> noErr then
		begin
			result := Create(concat(SharedFiles, 'Users'), 0, 'HRMS', 'DATA');
			result := FSOpen(concat(SharedFiles, 'Users'), 0, UsersRes);
		end;
		result := GetEOF(UsersRes, AllUsersSize);
		SizeofAUser := SizeOf(UserRec);
		if AllUsersSize >= SizeOfAUser then
		begin
			numUserRecs := AllusersSize div SizeOf(userRec);
			myUsers := UListHand(NewHandle((AllUsersSize div SizeOf(userRec)) * SizeOf(ULR)));
			MoveHHi(handle(myUsers));
			HNoPurge(handle(myUsers));
			SizeOfAUser := SizeOf(UserRec);
			myUserArr := UserArrPtr(NewPtr(SizeOf(UserArrRec)));
			result := SetFPos(UsersRes, fsFromStart, 0);
			i := 0;
			while (i < (allusersSize div SizeOfAUser)) do
			begin
				tempLong := SizeOf(UserRec) * longint(32);
				result := FSRead(UsersRes, tempLong, pointer(myUserArr));
				b := tempLong div SizeOf(UserRec);
				if b > 0 then
				begin
					for c := 1 to b do
					begin
						i := i + 1;
						if newHand^^.handle then
						begin
							if myUserArr^[c - 1].userName[1] <> '•' then
								myUsers^^[i - 1].UName := myUserArr^[c - 1].userName
							else
								myUsers^^[i - 1].UName := myUserArr^[c - 1].RealName;
						end
						else
						begin
							if myUserArr^[c - 1].RealName[1] <> '•' then
								myUsers^^[i - 1].UName := myUserArr^[c - 1].RealName
							else
								myUsers^^[i - 1].UName := myUserArr^[c - 1].userName;
						end;
						myUsers^^[i - 1].dltd := myUserArr^[c - 1].DeletedUser;
						myUsers^^[i - 1].last := myUserArr^[c - 1].lastOn;
						myUsers^^[i - 1].first := myUserArr^[c - 1].firstOn;
						myUsers^^[i - 1].SL := myUserArr^[c - 1].SL;
						myUsers^^[i - 1].DSL := myUserArr^[c - 1].DSL;
						myUsers^^[i - 1].real := myUserArr^[c - 1].realName;
						myUsers^^[i - 1].age := myUserArr^[c - 1].age;
						myUsers^^[i - 1].city := myUserArr^[c - 1].city;
						myUsers^^[i - 1].state := myUserArr^[c - 1].state;
						for j := 1 to 26 do
							myUsers^^[i - 1].AccessLetter[j] := myUserArr^[c - 1].AccessLetter[j];
						if not myUserArr^[c - 1].DeletedUser then
							InitSystHand^^.numUsers := InitSystHand^^.numUsers + 1;
					end;
				end;
			end;
			DisposPtr(ptr(myUserArr));
		end;
		Result := FSClose(UsersRes);
	end;



	function checktitle (thetit: str255): boolean;
		var
			i: integer;
	begin
		with curglobs^ do
		begin
			i := 1;
			while (i < curNumMess) and (curBase^^[i - 1].title <> thetit) do
				i := i + 1;
			if curbase^^[i - 1].title = theTit then
				checktitle := true
			else
				checktitle := false;
		end;
	end;
end.