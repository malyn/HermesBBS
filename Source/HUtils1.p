{ Segments: HUtils1_1, HUtils1_2 }
unit HUtilsOne;

interface
	uses
		AppleTalk, ADSP, Serial, Sound, Initial, LoadAndSave, NodePrefs2, NodePrefs, Message_Editor, User, inpOut4;

	procedure DoUserEdit;
	procedure doBBSlist;
	procedure OpenBroadCast;
	procedure CloseBroadCast;
	procedure DoBroadCast (theEvent: EventRecord; ItemHit: Integer);
	procedure DoListMail;
	procedure UpdateBroadCast;

implementation

{$S HUtils1_1}
	procedure DoListMail;
		var
			tss: str255;
			tb, tb2: boolean;
			tempInt, tempint2: longint;
	begin
		with curglobs^ do
		begin
			tb2 := false;
			if crossInt = 0 then
			begin
				OutLine(RetInStr(724), true, 2);{#### Username                                 Mail Notices}
				OutLine(RetInStr(725), true, 2);{---- ---------------------------------------- ---- -------}
				crossInt := 1;
				BoardAction := repeating;
				Crossint3 := 0;
			end
			else
			begin
				if not sysopStop and not aborted then
				begin
					crossInt3 := crossInt3 + 1;
					tb := true;
					FindMyEmail(crossInt3);
					tempInt := GetHandleSize(handle(myEmailList)) div 2;
					tempint2 := FindMyDMail(crossInt3);
					if (tempInt > 0) or (tempInt2 > 0) then
					begin
						OutLine(StringOf(crossInt3 : 4, ' ', copy(myUsers^^[crossInt3 - 1].UName, 1, 39), ' ' : 40 - Length(myUsers^^[crossInt3 - 1].UName), ' ', tempInt : 4, ' ', tempint2 : 7), true, 0);
						if myUsers^^[crossInt3 - 1].dltd then
							OutLine('  User Deleted', false, 5);
					end;
				end;
				if (crossInt3 = numUserRecs) or aborted then
				begin
					BoardAction := none;
					GoHome;
				end;
			end;
		end;
	end;

	procedure CloseBroadCast;
		var
			tempString: str255;
			tempRect, tr2: Rect;
			myC: Point;
			DType, i, kind: Integer;
			DItem: Handle;
	begin
		if (BroadDilg <> nil) then
		begin
			DisposDialog(BroadDilg);
			BroadDilg := nil;
		end;
	end;

	procedure UpdateBroadCast;
		var
			SavedPort: GrafPtr;
			tempRect: rect;
			DType, i: Integer;
			DItem: Handle;
	begin
		if (BroadDilg <> nil) then
		begin
			GetPort(SavedPort);
			SetPort(BroadDilg);
			DrawDialog(BroadDilg);
			setPort(savedPort);
		end;
	end;

	procedure OpenBroadCast;
		var
			tempRect, tr2: Rect;
			myC: Point;
			DType, i, kind: Integer;
			DItem: Handle;
			tempString: Str255;
	begin
		if (BroadDilg = nil) then
		begin
			BroadDilg := GetNewDialog(1590, nil, pointer(-1));
			SetPort(BroadDilg);
			ShowWindow(BroadDilg);
			SetGeneva(BroadDilg);
			SelectWindow(BroadDilg);
		end
		else
			SelectWindow(BroadDilg);
	end;

	procedure DoBroadCast (theEvent: EventRecord; ItemHit: Integer);
		var
			myPt: Point;
			doubleclick, hk: boolean;
			tempCell: cell;
			tempint: integer;
			tempString: str255;
			tempRect, tr2, r: Rect;
			myC: Point;
			DType, i, kind, hm: Integer;
			DItem: Handle;
			ttUser: userRec;
			adder: Integer;
			h: handle;
			result: longint;
			CItem: controlhandle;
	begin
		if (BroadDilg <> nil) then
		begin
			SetPort(BroadDilg);
			myPt := theEvent.where;
			GlobalToLocal(myPt);
			GetDItem(BroadDilg, itemHit, DType, DItem, TempRect);
			CItem := Pointer(DItem);
			case itemHit of
				1: 
				begin
					GetDItem(BroadDilg, 4, DType, DItem, tempRect);
					GetIText(DItem, tempString);
					if (length(tempString) > 0) then
					begin
						Broadcast(stringOf(char(7), 'Message From: ', myUsers^^[0].UName), 1);
						BroadCast(tempString, 2);
					end;
				end;
				5: 
				begin
					GetDItem(BroadDilg, 4, DType, DItem, tempRect);
					GetIText(DItem, tempString);
					if (length(tempString) > 0) then
						BroadCast(concat(char(7), tempString), 2);
				end;
				2: 
					CloseBroadCast;
			end;
		end;
	end;

	function NextNum: char;
		var
			s: str255;
			n: integer;
	begin
		if curglobs^.crossint3 < 9 then
		begin
			curglobs^.crossint3 := curglobs^.crossint3 + 1;
			NumToString(curglobs^.crossInt3, s);
		end
		else
		begin
			curglobs^.crossint3 := curglobs^.crossint3 + 1;
			n := curglobs^.crossint3 + 55;
			s := char(n);
		end;

		curglobs^.enteredPass2 := concat(curglobs^.enteredPass2, s);
		NextNum := s;
	end;

	procedure PrUserStuff (var theUser: UserRec);
		var
			te1, tempString, tempString2: Str255;
			l: longint;
			i: integer;
	begin
		with curglobs^ do
		begin
			BufClearScreen;
			crossint3 := 0;
			enteredPass2 := char(0);
			BufferbCR;
			case crossint2 of
				1: 
				begin
					BufferIt('USER STATS     ', false, 0);
					if theUser.DeletedUser then
						BufferIt(RetInStr(314), false, 0);	{>>> DELETED <<<}
					NumToString(theUser.UserNum, tempString);
					if UserOnSystem(concat('@', tempString)) then
						BufferIt(RetInStr(315), false, 0);	{<<< ONLINE >>>}
					NumToString(theUser.UserNum, te1);
					BufferIt(concat(theUser.UserName, ' #', te1, '              ', theUser.lastbaud), true, 0);
					TempString := GetDate(theUser.firstOn);
					BufferIt(concat('First On          : ', TempString, '  '), true, 0);
					TempString := GetDate(theUser.lastOn);
					BufferIt(concat('Last On: ', TempString, '  '), false, 0);
					BufferIt(concat('Illegal: ', stringOf(theUser.illegalLogons : 0)), false, 0);
					BufferIt('[', true, 1);
					BufferIt(NextNum, false, 0);
					BufferIt('] Total Messages : ', false, 1);
					BufferIt(stringOf(theUser.MessagesPosted : 0), false, 0);
					BufferIt('[', true, 1);
					BufferIt(NextNum, false, 0);
					BufferIt('] Messages Today : ', false, 1);
					BufferIt(stringOf(theUser.MPostedToday : 0), false, 0);
					BufferIt('[', true, 1);
					BufferIt(NextNum, false, 0);
					BufferIt('] E-Mail         : ', false, 1);
					BufferIt(stringOf(theUser.EMailSent : 0), false, 0);
					BufferIt('[', true, 1);
					BufferIt(NextNum, false, 0);
					BufferIt('] Total Calls    : ', false, 1);
					BufferIt(stringOf(theUser.TotalLogons : 0), false, 0);
					BufferIt('[', true, 1);
					BufferIt(NextNum, false, 0);
					BufferIt('] Calls Today    : ', false, 1);
					BufferIt(stringOf(theUser.onToday : 0), false, 0);
					BufferIt('[', true, 1);
					BufferIt(NextNum, false, 0);
					BufferIt('] # Uploads      : ', false, 1);
					BufferIt(stringOf(theUser.NumUploaded : 0), false, 0);
					BufferIt('[', true, 1);
					BufferIt(NextNum, false, 0);
					BufferIt('] Kb Uploaded    : ', false, 1);
					BufferIt(stringOf(theUser.UploadedK : 0), false, 0);
					BufferIt('[', true, 1);
					BufferIt(NextNum, false, 0);
					BufferIt('] # Downloads    : ', false, 1);
					BufferIt(stringOf(theUser.NumDownloaded : 0), false, 0);
					BufferIt('[', true, 1);
					BufferIt(NextNum, false, 0);
					BufferIt('] Kb Downloaded  : ', false, 1);
					BufferIt(stringOf(theUser.DownloadedK : 0), false, 0);
					BufferIt('[', true, 1);
					BufferIt(NextNum, false, 0);
					BufferIt('] Kb Credit      : ', false, 1);
					BufferIt(stringOf(theUser.DLCredits : 0), false, 0);
					BufferIt('[', true, 1);
					BufferIt(NextNum, false, 0);
					BufferIt('] Donation       : ', false, 1);
					BufferIt(theUser.Donation, false, 0);
					BufferIt('[', true, 1);
					BufferIt(NextNum, false, 0);
					BufferIt('] Last Donation  : ', false, 1);
					BufferIt(theUser.LastDonation, false, 0);
					BufferIt('[', true, 1);
					BufferIt(NextNum, false, 0);
					BufferIt('] Expiration Date: ', false, 1);
					BufferIt(theUser.ExpirationDate, false, 0);
					BufferIt('[', true, 1);
					BufferIt(NextNum, false, 0);
					BufferIt('] Notes          : ', false, 1);
					BufferIt(theUser.SysopNote, false, 0);
{Restrict Hours Start}
{Restrict Hours Stop}
				end;
				2: 
				begin
					BufferIt('USER SECURITY  ', false, 0);
					if theUser.DeletedUser then
						BufferIt(RetInStr(314), false, 0);	{>>> DELETED <<<}
					NumToString(theUser.UserNum, tempString);
					if UserOnSystem(concat('@', tempString)) then
						BufferIt(RetInStr(315), false, 0);	{<<< ONLINE >>>}
					NumToString(theUser.UserNum, te1);
					BufferIt(concat(theUser.UserName, ' #', te1), true, 0);
					NumToString(theUser.SL, TempString);
					BufferIt('[', true, 1);
					BufferIt(NextNum, false, 0);
					BufferIt('] Security Level  : ', false, 1);
					if SecLevels^^[theUser.SL].active then
						BufferIt(concat(TempString, ' - ', SecLevels^^[theUser.SL].class), false, 0)
					else
						BufferIt(stringOf(theUser.SL : 0, ' - Unclassified'), false, 0);
					NumToString(theUser.DSL, TempString);
					BufferIt('[', true, 1);
					BufferIt(NextNum, false, 0);
					BufferIt('] Download SL     : ', false, 1);
					BufferIt(TempString, false, 0);
					NumToString(theUser.DLRatioOneTo, TempString);
					BufferIt('[', true, 1);
					BufferIt(NextNum, false, 0);
					BufferIt('] UL/DL Ratio     : ', false, 1);
					BufferIt('1:', false, 0);
					BufferIt(TempString, false, 0);
					NumToString(theUser.PostRatioOneTo, TempString);
					BufferIt('[', true, 1);
					BufferIt(NextNum, false, 0);
					BufferIt('] Post/Call Ratio : ', false, 1);
					BufferIt('1:', false, 0);
					BufferIt(TempString, false, 0);
					BufferIt('[', true, 1);
					BufferIt(NextNum, false, 0);
					BufferIt('] Post Comp Time  : ', false, 1);
					BufferIt(stringof(theUser.messcomp : 1 : 1), false, 0);
					BufferIt('[', true, 1);
					BufferIt(NextNum, false, 0);
					BufferIt('] UL Comp Time    : ', false, 1);
					BufferIt(stringof(theUser.XFerComp : 1 : 1), false, 0);
					BufferIt('[', true, 1);
					BufferIt(NextNum, false, 0);
					BufferIt('] Max Posts/Day   : ', false, 1);
					BufferIt(stringOf(theUser.MesgDay : 0), false, 0);
					BufferIt('[', true, 1);
					BufferIt(NextNum, false, 0);
					BufferIt('] Max Lines/Post  : ', false, 1);
					BufferIt(stringOf(theUser.LnsMessage : 0), false, 0);
					BufferIt('[', true, 1);
					BufferIt(NextNum, false, 0);
					BufferIt('] Max Calls/Day   : ', false, 1);
					BufferIt(stringOf(theUser.CallsPrDay : 0), false, 0);
					BufferIt('[', true, 1);
					BufferIt(NextNum, false, 0);
					BufferIt('] Time Allowed On : ', false, 1);
					BufferIt(stringOf(theUser.TimeAllowed : 0), false, 0);
					BufferIt('[', true, 1);
					BufferIt(NextNum, false, 0);
					BufferIt('] Time Unit       : ', false, 1);
					if (theUser.UseDayOrCall) then
						BufferIt('Per Day', false, 0)
					else
						BufferIt('Per Call', false, 0);
					TempString := char(0);
					if (theUser.CantPost) then
						TempString := '1';
					if (theUser.CantChat) then
						TempString := concat(TempString, '2');
					if (theUser.UDRatioOn) then
						TempString := concat(TempString, '3');
					if (theUser.PCRatioOn) then
						TempString := concat(TempString, '4');
					if (theUser.CantPostAnon) then
						TempString := concat(TempString, '5');
					if (theUser.CantSendEmail) then
						TempString := concat(TempString, '6');
					if (theUser.CantChangeAutoMsg) then
						TempString := concat(TempString, '7');
					if (theUser.CantListUser) then
						TempString := concat(TempString, '8');
					if (theUser.CantAddToBBSList) then
						TempString := concat(TempString, '9');
					if (theUser.CantSeeULInfo) then
						TempString := concat(TempString, '10');
					if (theUser.CantReadAnon) then
						TempString := concat(TempString, '11');
					if (theUser.RestrictHours) then
						TempString := concat(TempString, '12');
					if (theUser.CantSendPPFile) then
						TempString := concat(TempString, '13');
					if (theUser.CantNetMail) then
						TempString := concat(TempString, '14');
					if (theUser.ReadBeforeDL) then
						TempString := concat(TempString, '15');
					BufferIt('[', true, 1);
					BufferIt(NextNum, false, 0);
					BufferIt('] Restrictions    : ', false, 1);
					BufferIt(TempString, false, 0);
					TempString := char(0);
					for i := 1 to 26 do
						if (theUser.AccessLetter[i]) then
							TempString := concat(TempString, chr(i + 64));
					BufferIt('[', true, 1);
					BufferIt(NextNum, false, 0);
					BufferIt('] Access Letters  : ', false, 1);
					BufferIt(TempString, false, 0);
					TempString := char(0);
					BufferIt('[', true, 1);
					BufferIt(NextNum, false, 0);
					BufferIt('] Sysop           : ', false, 1);
					if (theUser.coSysop) then
						BufferIt('Yes', false, 0)
					else
						BufferIt('No', false, 0);
					BufferIt('[', true, 1);
					BufferIt(NextNum, false, 0);
					BufferIt('] Alert           : ', false, 1);
					if (theUser.alertOn) then
						BufferIt('Yes', false, 0)
					else
						BufferIt('No', false, 0);
					BufferIt('[', true, 1);
					BufferIt(NextNum, false, 0);
					BufferIt('] Delete/Restore  : ', false, 1);
					if (theUser.DeletedUser) then
						BufferIt('Deleted', false, 0)
					else
						BufferIt('Active', false, 0);
					BufferIt('[', true, 1);
					BufferIt(NextNum, false, 0);
					BufferIt('] Text            : ', false, 1);
					if (theUser.AlternateText) then
						BufferIt('Alternate', false, 0)
					else
						BufferIt('Normal', false, 0);
				end;
				otherwise
				begin
					BufferIt('USER INFO      ', false, 0);
					if theUser.DeletedUser then
						BufferIt(RetInStr(314), false, 0);	{>>> DELETED <<<}
					NumToString(theUser.UserNum, tempString);
					if UserOnSystem(concat('@', tempstring)) then
						BufferIt(RetInStr(315), false, 0);	{<<< ONLINE >>>}
					NumToString(theUser.UserNum, te1);
					if (newHand^^.RealName) then
					begin
						BufferIt('[', true, 1);
						BufferIt(NextNum, false, 0);
						BufferIt('] Real Name: ', false, 1);
						if theuser.coSysop then
							BufferIt(concat(theUser.RealName, ' #', te1, '     SYSOP'), false, 0) {Name: }
						else
							BufferIt(concat(theUser.RealName, ' #', te1), false, 0);
					end;
					if (newHand^^.Handle) then
					begin
						BufferIt('[', true, 1);
						BufferIt(NextNum, false, 0);
						BufferIt('] Alias    : ', false, 1);
						BufferIt(theUser.Alias, false, 0);
					end;
					BufferIt('[', true, 1);
					BufferIt(NextNum, false, 0);
					BufferIt('] Password : ', false, 1);
					BufferIt(theUser.Password, false, 0);
					BufferIt('[', true, 1);
					BufferIt(NextNum, false, 0);
					BufferIt('] Voice PH : ', false, 1);
					BufferIt(theUser.Phone, false, 0);
					if (newHand^^.DataPN) then
					begin
						BufferIt('[', true, 1);
						BufferIt(NextNum, false, 0);
						BufferIt('] Data PH  : ', false, 1);
						BufferIt(theUser.DataPhone, false, 0);
					end;
					if (newHand^^.Street) then
					begin
						BufferIt('[', true, 1);
						BufferIt(NextNum, false, 0);
						BufferIt('] Street   : ', false, 1);
						BufferIt(theUser.Street, false, 0);
					end;
					if (newHand^^.City) then
					begin
						BufferIt('[', true, 1);
						BufferIt(NextNum, false, 0);
						BufferIt('] City     : ', false, 1);
						BufferIt(theUser.City, false, 0);
						BufferIt('[', true, 1);
						BufferIt(NextNum, false, 0);
						BufferIt('] State    : ', false, 1);
						BufferIt(theUser.State, false, 0);
						BufferIt('[', true, 1);
						BufferIt(NextNum, false, 0);
						BufferIt('] Zip Code : ', false, 1);
						BufferIt(theUser.Zip, false, 0);
					end;
					if (newHand^^.Country) then
					begin
						BufferIt('[', true, 1);
						BufferIt(NextNum, false, 0);
						BufferIt('] Country  : ', false, 1);
						BufferIt(theUser.Country, false, 0);
					end;
					if (newHand^^.BirthDay) then
					begin
						tempString := '';
						if integer(theUser.birthMonth) < 10 then
							TempString := '0';
						TempString := stringOf(TempString, integer(theUser.birthMonth) : 0, '/');
						if integer(theUser.birthDay) < 10 then
							TempString := concat(TempString, '0');
						TempString := stringOf(TempString, integer(theUser.birthDay) : 0, '/');
						if integer(theUser.birthYear) < 10 then
							TempString := concat(TempString, '0');
						TempString := stringOf(TempString, integer(theUser.birthYear) : 0);
						yearsOld(theUser);
						NumToString(longint(theUser.age), TempString2);
						BufferIt('[', true, 1);
						BufferIt(NextNum, false, 0);
						BufferIt('] Birthdate: ', false, 1);
						BufferIt(concat(TempString, '    Age: ', TempString2), false, 0);
					end;
					if (newHand^^.Gender) then
					begin
						BufferIt('[', true, 1);
						BufferIt(NextNum, false, 0);
						BufferIt('] Gender   : ', false, 1);
						if theUser.sex then
							BufferIt('Male', false, 0)
						else
							BufferIt('Female', false, 0);
					end;
					if (newHand^^.Company) then
					begin
						BufferIt('[', true, 1);
						BufferIt(NextNum, false, 0);
						BufferIt('] Company  : ', false, 1);
						BufferIt(theUser.Company, false, 0);
					end;
					if (newHand^^.Computer) then
					begin
						BufferIt('[', true, 1);
						BufferIt(NextNum, false, 0);
						BufferIt('] Computer : ', false, 1);
						BufferIt(theUser.ComputerType, false, 0);
					end;
					if (newHand^^.Sysop[1]) then
					begin
						BufferIt('[', true, 1);
						BufferIt(NextNum, false, 0);
						BufferIt('] Misc #1  : ', false, 1);
						BufferIt(theUser.MiscField1, false, 0);
					end;
					if (newHand^^.Sysop[2]) then
					begin
						BufferIt('[', true, 1);
						BufferIt(NextNum, false, 0);
						BufferIt('] Misc #2  : ', false, 1);
						BufferIt(theUser.MiscField2, false, 0);
					end;
					if (newHand^^.Sysop[3]) then
					begin
						BufferIt('[', true, 1);
						BufferIt(NextNum, false, 0);
						BufferIt('] Misc #3  : ', false, 1);
						BufferIt(theUser.MiscField3, false, 0);
					end;
				end;
			end;
			BufferbCR;
			BufferIt('Q', true, 0);
			BufferIt('-Quit,        ', false, 1);
			BufferIt('S', false, 0);
			BufferIt('-Security,     ', false, 1);
			BufferIt('T', false, 0);
			BufferIt('-Stats,      ', false, 1);
			BufferIt('U', false, 0);
			BufferIt('-Info', false, 1);
			BufferIt('W', true, 0);
			BufferIt('-What User    ', false, 1);
			BufferIt('>', false, 0);
			BufferIt('-Forward User  ', false, 1);
			BufferIt('<', false, 0);
			BufferIt('-Backward User', false, 1);
			BufferbCR;
			ReleaseBuffer;
			enteredPass2 := concat(enteredPass2, 'QSTUW><+-', char(30), char(31));
		end;
	end;

	procedure GetOnlineUser (var tobegat: UserRec);
		var
			i: integer;
	begin
		i := 1;
		while (i <= InitSystHand^^.numNodes) do
		begin
			if theNodes[i]^.thisUser.userNum = toBegat.userNum then
				toBegat := theNodes[i]^.thisUser;
			i := i + 1;
		end;
	end;

	function DoACheck (theChar: char; tempint: integer): boolean;
		var
			ts: str255;
	begin
		if tempint < 10 then
		begin
			NumToString(tempint, ts);
			if ts = theChar then
				DoACheck := true
			else
				DoACheck := false;
		end
		else
		begin
			ts := char(tempint + 55);
			if ts = theChar then
				DoACheck := true
			else
				DoACheck := false;
		end;
	end;

	function WhatKey (incomingChar: char): char;
		var
			tempint: integer;
	begin
		if (incomingChar = 'Q') or (incomingChar = 'S') or (incomingChar = 'T') or (incomingChar = 'U') or (incomingChar = 'W') or (incomingChar = '>') or (incomingChar = '<') or (incomingChar = '+') or (incomingChar = '-') then
			WhatKey := incomingChar
		else if (incomingChar = char(30)) then
			WhatKey := '+'
		else if (incomingChar = char(31)) then
			WhatKey := '-'
		else if (curglobs^.crossint2 = 1) or (curglobs^.crossint2 = 2) then
			WhatKey := incomingChar
		else
		begin
			tempint := 0;
			if (newHand^^.RealName) then
			begin
				tempint := tempint + 1;
				if DoACheck(incomingChar, tempint) then
				begin
					WhatKey := '1';
					Exit(WhatKey);
				end;
			end;
			if (newHand^^.Handle) then
			begin
				tempint := tempint + 1;
				if DoACheck(incomingChar, tempint) then
				begin
					WhatKey := '2';
					Exit(WhatKey);
				end;
			end;
			tempint := tempint + 1;
			if DoACheck(incomingChar, tempint) then
			begin
				WhatKey := '3';
				Exit(WhatKey);
			end;
			tempint := tempint + 1;
			if DoACheck(incomingChar, tempint) then
			begin
				WhatKey := '4';
				Exit(WhatKey);
			end;
			if (newHand^^.DataPN) then
			begin
				tempint := tempint + 1;
				if DoACheck(incomingChar, tempint) then
				begin
					WhatKey := '5';
					Exit(WhatKey);
				end;
			end;
			if (newHand^^.Street) then
			begin
				tempint := tempint + 1;
				if DoACheck(incomingChar, tempint) then
				begin
					WhatKey := '6';
					Exit(WhatKey);
				end;
			end;
			if (newHand^^.City) then
			begin
				tempint := tempint + 1;
				if DoACheck(incomingChar, tempint) then
				begin
					WhatKey := '7';
					Exit(WhatKey);
				end;
			end;
			if (newHand^^.City) then
			begin
				tempint := tempint + 1;
				if DoACheck(incomingChar, tempint) then
				begin
					WhatKey := '8';
					Exit(WhatKey);
				end;
			end;
			if (newHand^^.City) then
			begin
				tempint := tempint + 1;
				if DoACheck(incomingChar, tempint) then
				begin
					WhatKey := '9';
					Exit(WhatKey);
				end;
			end;
			if (newHand^^.Country) then
			begin
				tempint := tempint + 1;
				if DoACheck(incomingChar, tempint) then
				begin
					WhatKey := 'A';
					Exit(WhatKey);
				end;
			end;
			if (newHand^^.BirthDay) then
			begin
				tempint := tempint + 1;
				if DoACheck(incomingChar, tempint) then
				begin
					WhatKey := 'B';
					Exit(WhatKey);
				end;
			end;
			if (newHand^^.Gender) then
			begin
				tempint := tempint + 1;
				if DoACheck(incomingChar, tempint) then
				begin
					WhatKey := 'C';
					Exit(WhatKey);
				end;
			end;
			if (newHand^^.Company) then
			begin
				tempint := tempint + 1;
				if DoACheck(incomingChar, tempint) then
				begin
					WhatKey := 'D';
					Exit(WhatKey);
				end;
			end;
			if (newHand^^.Computer) then
			begin
				tempint := tempint + 1;
				if DoACheck(incomingChar, tempint) then
				begin
					WhatKey := 'E';
					Exit(WhatKey);
				end;
			end;
			if (newHand^^.Sysop[1]) then
			begin
				tempint := tempint + 1;
				if DoACheck(incomingChar, tempint) then
				begin
					WhatKey := 'F';
					Exit(WhatKey);
				end;
			end;
			if (newHand^^.Sysop[2]) then
			begin
				tempint := tempint + 1;
				if DoACheck(incomingChar, tempint) then
				begin
					WhatKey := 'G';
					Exit(WhatKey);
				end;
			end;
			if (newHand^^.Sysop[3]) then
			begin
				tempint := tempint + 1;
				if DoACheck(incomingChar, tempint) then
				begin
					WhatKey := 'H';
					Exit(WhatKey);
				end;
			end;
		end;
	end;

	procedure SetOnlineUser (var tobegat: UserRec);
		var
			i: integer;
	begin
		i := 1;
		while (i <= InitSystHand^^.numNodes) do
		begin
			if theNodes[i]^.thisUser.userNum = toBegat.userNum then
				theNodes[i]^.thisUser := toBegat;
			i := i + 1;
		end;
	end;

	procedure DoUserEdit;
		var
			t1, t2, t3, t4: str255;
			i, x: integer;
			TempEMa: eMailRec;
			templong, tempint: longint;
			s120, s220: string[20];
			b: boolean;
			r: real;
	begin
		with curglobs^ do
		begin
			case UEDo of
				EnterUE: 
				begin
					if thisUser.coSysop then
					begin
						if not sysoplogon and (thisUser.SL < 255) then
							LettersPrompt(RetInStr(20), '', 9, false, false, true, 'X')	{SY: }
						else
							curPrompt := InitSystHand^^.overridePass;
						UEDo := UOne;
						HelpNum := 35;
					end
					else
						GoHome;
				end;
				UOne: 
				begin
					if EqualString(curPrompt, InitSystHand^^.overridePass, false, false) then
					begin
						tempUser.userNum := -1;
						crossint2 := 2;
						curPrompt := 'W';
						UEDo := UThree;
					end
					else
						GoHome;
				end;
				UTwo: 
				begin
					if (length(enteredPass2) > 8) then
						i := 9
					else
						i := length(enteredPass2);
					bCR;
					NumbersPrompt('U-Edit : ', enteredPass2, i, 0);
					UEDo := UThree;
				end;
				UThree: 
				begin
					if (length(curPrompt) > 0) then
					begin
						curPrompt[1] := WhatKey(curPrompt[1]);
						case curPrompt[1] of
							'1': 
							begin
								bCR;
								case crossint2 of
									1: {Total Messages}
									begin
										NumbersPrompt('Enter messages posted: ', '1234567890 ', 9999, 0);
										ANSIPrompter(4);
									end;
									2: {Security Level}
									begin
										for i := 1 to 255 do
										begin
											if SecLevels^^[i].active then
											begin
												BufferIt(stringOf(i : 3), true, 0);
												BufferIt(concat(': ', SecLevels^^[i].class), false, 5);
											end;
										end;
										BufferbCR;
										BufferbCR;
										ReleaseBuffer;
										NumbersPrompt('Enter SL class: ', '', 255, 1);	{New Class? }
										ANSIPrompter(3);
									end;
									otherwise {Real Name}
									begin
										LettersPrompt('Enter real name: ', '', 21, false, false, true, char(0));
										ANSIPrompter(21);
									end;
								end;
								UEDo := UFour;
							end;
							'2': 
							begin
								case crossint2 of
									1: {Messages Today}
									begin
										NumbersPrompt('Enter messages posted today: ', '', 9999, 0);
										ANSIPrompter(4);
									end;
									2: {Download SL}
									begin
										NumbersPrompt('Enter download SL: ', '', 255, 1);
										ANSIPrompter(3);
									end;
									otherwise {Alias}
									begin
										LettersPrompt('Enter alias: ', '', 31, false, false, false, char(0));
										ANSIPrompter(31);
									end;
								end;
								UEDo := UFive;
							end;
							'3': 
							begin
								case crossint2 of
									1: {E-Mail}
									begin
										NumbersPrompt('Enter number of E-Mail sent: ', '', 9999, 0);
										ANSIPrompter(4);
									end;
									2: {UL/DL Ratio}
									begin
										NumbersPrompt('Upload/Download ratio: 1:', '', 99, 0);
										ANSIPrompter(2);
									end;
									otherwise {Password}
									begin
										LettersPrompt('Enter password: ', '', 9, false, false, true, char(0));	{Enter new password: }
										ANSIPrompter(9);
									end;
								end;
								UEDo := USix;
							end;
							'4': 
							begin
								case crossint2 of
									1: {TotalCalls}
									begin
										NumbersPrompt('Enter total logons: ', '', 9999, 0);
										ANSIPrompter(4);
									end;
									2: {Post/Call Ratio}
									begin
										NumbersPrompt('Post/Call ratio: 1:', '', 99, 0);
										ANSIPrompter(2);
									end;
									otherwise {Voice PH}
										if InitSystHand^^.freePhone then
										begin
											OutLine(RetInStr(679), true, -1);
											LettersPrompt(': ', '', 12, false, false, true, char(0));
											ANSIPrompter(12);
										end
										else
										begin
											OutLine(RetInStr(680), true, -1);
											LettersPrompt(': ', '', -2, false, false, true, char(0));
											ANSIPrompter(12);
										end;
								end;
								UEDo := USeven;
							end;
							'5': 
							begin
								case crossint2 of
									1: {Calls Today}
									begin
										NumbersPrompt('Enter calls today: ', '', 999, 0);
										ANSIPrompter(3);
									end;
									2:{Post Comp Time}
									begin
										LettersPrompt('Post Comp. Time: ', '1234567890.', 4, false, false, false, char(0));
										ANSIPrompter(4);
									end;
									otherwise {Data PH}
										if InitSystHand^^.freePhone then
										begin
											OutLine(RetInStr(683), true, -1);
											LettersPrompt(': ', '', 12, false, false, true, char(0));
											ANSIPrompter(12);
										end
										else
										begin
											OutLine(RetInStr(684), true, -1);
											LettersPrompt(': ', '', -2, false, false, true, char(0));
											ANSIPrompter(12);
										end;
								end;
								UEDo := UEight;
							end;
							'6': 
							begin
								case crossint2 of
									1: {# Uploads}
									begin
										NumbersPrompt('Enter # of Uploads: ', '', 32000, 0);
										ANSIPrompter(5);
									end;
									2:{UL Comp Time}
									begin
										LettersPrompt('UL Comp. Time: ', '1234567890.', 4, false, false, false, char(0));
										ANSIPrompter(4);
									end;
									otherwise {Street}
									begin
										LettersPrompt('Enter street: ', '', 30, false, false, false, char(0));
										ANSIPrompter(30);
									end;
								end;
								UEDo := UNine;
							end;
							'7': 
							begin
								case crossint2 of
									1: {kb Uploaded}
									begin
										LettersPrompt('Enter Kb Uploaded: ', '1234567890', 7, false, false, false, char(0));
										ANSIPrompter(7);
									end;
									2: {Max Posts/Day}
									begin
										NumbersPrompt('Enter max posts/day: ', '', 999, 0);
										ANSIPrompter(3);
									end;
									otherwise {City}
									begin
										LettersPrompt('Enter city: ', '', 30, false, false, false, char(0));
										ANSIPrompter(30);
									end;
								end;
								UEDo := UTen;
							end;
							'8': 
							begin
								case crossint2 of
									1: {# Downloads}
									begin
										NumbersPrompt('Enter # of Downloads: ', '', 32000, 0);
										ANSIPrompter(5);
									end;
									2: {Max Lines/Post}
									begin
										NumbersPrompt('Enter max lines/post: ', '', 200, 0);
										ANSIPrompter(3);
									end;
									otherwise {State}
									begin
										LettersPrompt('Enter state: ', '', 6, false, false, false, char(0));
										ANSIPrompter(2);
									end;
								end;
								UEDo := UEleven;
							end;
							'9': 
							begin
								case crossint2 of
									1: {kb Downloaded}
									begin
										LettersPrompt('Enter Kb Downloaded: ', '1234567890', 7, false, false, false, char(0));
										ANSIPrompter(7);
									end;
									2: {Max Calls/Day}
									begin
										NumbersPrompt('Enter max calls/day: ', '', 999, 0);
										ANSIPrompter(3);
									end;
									otherwise {Zip Code}
									begin
										LettersPrompt('Enter zip code: ', '1234567890-', 10, false, false, false, char(0));
										ANSIPrompter(10);
									end;
								end;
								UEDo := UTwelve;
							end;
							'A': 
							begin
								case crossint2 of
									1: {kb Credit}
									begin
										LettersPrompt('Enter Kb Credit: ', '1234567890', 7, false, false, false, char(0));
										ANSIPrompter(7);
									end;
									2: {Time Allowed On}
									begin
										NumbersPrompt('Enter time allowed on: ', '', 999, 0);
										ANSIPrompter(3);
									end;
									otherwise {Country}
									begin
										LettersPrompt('Enter country: ', '', 10, false, false, false, char(0));
										ANSIPrompter(10);
									end;
								end;
								UEDo := U13;
							end;
							'B': 
							begin
								case crossint2 of
									1: {Donation}
									begin
										LettersPrompt('Enter donation: ', '', 20, false, false, false, char(0));
										ANSIPrompter(20);
									end;
									2: {Time Unit}
									begin
										tempUser.UseDayOrCall := not tempUser.UseDayOrCall;
									end;
									otherwise {BirthDate}
									begin
										LettersPrompt('Enter birthdate: ', '', -1, false, false, true, char(0));
										ANSIPrompter(8);
									end;
								end;
								UEDo := U14;
							end;
							'C': 
							begin
								case crossint2 of
									1: {Last Donation}
									begin
										LettersPrompt('Enter last donation: ', '', 20, false, false, false, char(0));
										ANSIPrompter(20);
									end;
									2: {Restrictions}
									begin
										BufferIt('* = Restriction Turned On', true, 1);
										BufferbCR;
										if tempUser.CantPost then
											BufferIt('* 1', true, 0)
										else
											BufferIt('  1', true, 0);
										BufferIt(' - Can''t Post', false, 5);
										if tempUser.CantChat then
											BufferIt('* 2', true, 0)
										else
											BufferIt('  2', true, 0);
										BufferIt(' - Can''t Chat', false, 5);
										if tempUser.UDRatioOn then
											BufferIt('* 3', true, 0)
										else
											BufferIt('  3', true, 0);
										BufferIt(' - UL/DL Ratio On', false, 5);
										if tempUser.PCRatioOn then
											BufferIt('* 4', true, 0)
										else
											BufferIt('  4', true, 0);
										BufferIt(' - Post/Call Ratio On', false, 5);
										if tempUser.CantPostAnon then
											BufferIt('* 5', true, 0)
										else
											BufferIt('  5', true, 0);
										BufferIt(' - Can''t Post Anonymous', false, 5);
										if tempUser.CantSendEmail then
											BufferIt('* 6', true, 0)
										else
											BufferIt('  6', true, 0);
										BufferIt(' - Can''t Send E-Mail', false, 5);
										if tempUser.CantChangeAutoMsg then
											BufferIt('* 7', true, 0)
										else
											BufferIt('  7', true, 0);
										BufferIt(' - Can''t Change Auto-Message', false, 5);
										if tempUser.CantListUser then
											BufferIt('* 8', true, 0)
										else
											BufferIt('  8', true, 0);
										BufferIt(' - Can''t List Users', false, 5);
										if tempUser.CantAddToBBSList then
											BufferIt('* 9', true, 0)
										else
											BufferIt('  9', true, 0);
										BufferIt(' - Can''t Add To BBS List', false, 5);
										if tempUser.CantSeeULInfo then
											BufferIt('*10', true, 0)
										else
											BufferIt(' 10', true, 0);
										BufferIt(' - Can''t See Uploader Info', false, 5);
										if tempUser.CantReadAnon then
											BufferIt('*11', true, 0)
										else
											BufferIt(' 11', true, 0);
										BufferIt(' - Can''t Read Anonymous', false, 5);
										if tempUser.RestrictHours then
											BufferIt('*12', true, 0)
										else
											BufferIt(' 12', true, 0);
										BufferIt(' - Restrict Hours', false, 5);
										if tempUser.CantSendPPFile then
											BufferIt('*13', true, 0)
										else
											BufferIt(' 13', true, 0);
										BufferIt(' - Can''t Attach Files', false, 5);
										if tempUser.CantNetMail then
											BufferIt('*14', true, 0)
										else
											BufferIt(' 14', true, 0);
										BufferIt(' - Can''t Send Net Mail', false, 5);
										if tempUser.ReadBeforeDL then
											BufferIt('*15', true, 0)
										else
											BufferIt(' 15', true, 0);
										BufferIt(' - Read Before Download', false, 5);
										BufferbCR;
										BufferbCR;
										ReleaseBuffer;
										NumbersPrompt('Restriction: ', '', 15, 1);
										ANSIPrompter(2);
									end;
									otherwise {Gender}
									begin
										LettersPrompt('Gender - [M]ale  [F]emale: ', 'MF', 1, true, false, true, char(0));
										ANSIPrompter(1);
									end;
								end;
								UEDo := U15;
							end;
							'D': 
							begin
								case crossint2 of
									1: {Expiration Date}
									begin
										LettersPrompt('Enter Expiration Date: ', '', 20, false, false, false, char(0));
										ANSIPrompter(20);
									end;
									2: {Access Letters}
									begin
										BufferIt('* = Access Letter On', true, 1);
										BufferbCR;
										for i := 1 to 13 do
										begin
											t1 := chr(i + 64);
											t2 := chr((i + 13) + 64);
											s120 := concat(InitSystHand^^.Restrictions[i], '                    ');
											s220 := concat(InitSystHand^^.Restrictions[i + 13], '                    ');
											if (tempUser.AccessLetter[i]) then
												t1 := concat('*', t1)
											else
												t1 := concat(' ', t1);
											if (tempUser.AccessLetter[i + 13]) then
												t2 := concat('*', t2)
											else
												t2 := concat(' ', t2);
											BufferIt(t1, true, 0);
											BufferIt(concat(' - ', s120), false, 5);
											BufferIt(t2, false, 0);
											BufferIt(concat(' - ', s220), false, 5);
										end;
										BufferbCR;
										BufferbCR;
										ReleaseBuffer;
										LettersPrompt('Enter Access Letter to Toggle: ', 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 1, false, false, true, char(0));
										ANSIPrompter(1);
									end;
									otherwise {Company}
									begin
										LettersPrompt('Enter Company Name: ', '', 30, false, false, false, char(0));
										ANSIPrompter(30);
									end;
								end;
								UEDo := U16;
							end;
							'E': 
							begin
								case crossint2 of
									1: {Start Hour}
									begin
										LettersPrompt('Enter note: ', '', 41, false, false, false, char(0));
										ANSIPrompter(41);
									end;
									2: {Sysop}
										tempUser.coSysop := not tempUser.coSysop;
									otherwise {Computer}
									begin
										LettersPrompt('Enter Computer Type: ', '', 23, false, false, false, char(0));
										ANSIPrompter(23);
									end;
								end;
								UEDo := U17;
							end;
							'F': 
							begin
								case crossint2 of
									1: 
										;  {Unused}
									2: {Alert}
										tempUser.alertOn := not tempUser.alertOn;
									otherwise {Misc #1}
									begin
										LettersPrompt('Enter Misc #1: ', '', 60, false, false, false, char(0));
										ANSIPrompter(60);
									end;
								end;
								UEDo := U18;
							end;
							'G': 
							begin
								case crossint2 of
									1: 
										; {Unused}
									2: {Delete/Restore}
									begin
										if (tempUser.DeletedUser) then
											YesNoQuestion('Restore this user? ', false)
										else
											YesNoQuestion('Delete this user? ', false);
										ANSIPrompter(1);
									end;
									otherwise
									begin
										LettersPrompt('Enter Misc #2: ', '', 60, false, false, false, char(0));
										ANSIPrompter(60);
									end;
								end;
								UEDo := U19;
							end;
							'H': 
							begin
								case crossint2 of
									1: 
										; {Unused}
									2: {Normal/Alternate Text}
									begin
										if tempUser.AlternateText then
											tempUser.AlternateText := false
										else
											tempUser.AlternateText := true;
									end;
									otherwise {Misc #3}
									begin
										LettersPrompt('Enter Misc #3: ', '', 60, false, false, false, char(0));
										ANSIPrompter(60);
									end;
								end;
								UEDo := U20;
							end;
							'I': 
							begin
								case crossint2 of
									1: 
										; {Unused}
									2: 
										;	{Unused}
									otherwise
										; {Unused}
								end;
								PrUserStuff(tempUser);
								UEDo := UTwo;
							end;
							'Q': {Quit}
							begin
								WriteUser(tempuser);
								myUsers^^[tempuser.userNum - 1].UName := tempuser.userName;
								myUsers^^[tempuser.userNum - 1].dltd := tempuser.DeletedUser;
								myUsers^^[tempuser.userNum - 1].real := tempuser.realName;
								myUsers^^[tempuser.userNum - 1].SL := tempuser.SL;
								myUsers^^[tempuser.userNum - 1].DSL := tempuser.DSL;
								myUsers^^[tempuser.userNum - 1].age := tempuser.age;
								for i := 1 to 26 do
									myUsers^^[tempuser.userNum - 1].AccessLetter[i] := tempuser.AccessLetter[i];
								NumToString(tempUser.UserNum, t1);
								if UserOnSystem(concat('@', t1)) then
									SetOnlineUser(tempUser);
								GoHome;
							end;
							'S': {Security}
							begin
								crossint2 := 2;
								PrUserStuff(tempUser);
								UEDo := UTwo;
							end;
							'T': {Stats}
							begin
								crossint2 := 1;
								PrUserStuff(tempUser);
								UEDo := UTwo;
							end;
							'U': {Info}
							begin
								crossint2 := 0;
								PrUserStuff(tempUser);
								UEDo := UTwo;
							end;
							'W': {What User}
							begin
								LettersPrompt('User name/number: ', '', 30, false, false, true, char(0));{User name/number: }
								ANSIPrompter(30);
								UEDo := U21;
							end;
							'>', '+': {Forward User}
							begin
								WriteUser(tempuser);
								myUsers^^[tempuser.userNum - 1].UName := tempuser.userName;
								myUsers^^[tempuser.userNum - 1].dltd := tempuser.DeletedUser;
								myUsers^^[tempuser.userNum - 1].real := tempuser.realName;
								myUsers^^[tempuser.userNum - 1].SL := tempuser.SL;
								myUsers^^[tempuser.userNum - 1].DSL := tempuser.DSL;
								myUsers^^[tempuser.userNum - 1].age := tempuser.age;
								for i := 1 to 26 do
									myUsers^^[tempuser.userNum - 1].AccessLetter[i] := tempuser.AccessLetter[i];
								NumToString(tempUser.UserNum, t1);
								if UserOnSystem(concat('@', t1)) then
									SetOnlineUser(tempUser);
								tempInt := tempuser.UserNum + 1;
								NumToString(tempint, t1);
								if FindUser(t1, tempUser) then
								begin
									PrUserStuff(tempUser);
									UEDo := UTwo;
								end
								else
								begin
									t1 := '1';
									if FindUser(t1, tempuser) then
									begin
										PrUserStuff(tempuser);
										UEdo := UTwo;
									end
									else
										GoHome;
								end;
							end;
							'<', '-': {Back User}
							begin
								WriteUser(tempuser);
								myUsers^^[tempuser.userNum - 1].UName := tempuser.userName;
								myUsers^^[tempuser.userNum - 1].dltd := tempuser.DeletedUser;
								myUsers^^[tempuser.userNum - 1].real := tempuser.realName;
								myUsers^^[tempuser.userNum - 1].SL := tempuser.SL;
								myUsers^^[tempuser.userNum - 1].DSL := tempuser.DSL;
								myUsers^^[tempuser.userNum - 1].age := tempuser.age;
								for i := 1 to 26 do
									myUsers^^[tempuser.userNum - 1].AccessLetter[i] := tempuser.AccessLetter[i];
								NumToString(tempUser.UserNum, t1);
								if UserOnSystem(concat('@', t1)) then
									SetOnlineUser(tempUser);
								tempInt := tempuser.UserNum - 1;
								if tempInt < 1 then
									tempint := numUserRecs;
								NumToString(tempint, t1);
								if FindUser(t1, tempUser) then
								begin
									PrUserStuff(tempUser);
									UEDo := UTwo;
								end
								else
									goHome;
							end;

							otherwise
							begin
								PrUserStuff(tempUser);
								UEDo := UTwo;
							end;
						end;
					end
					else
					begin
						PrUserStuff(tempUser);
						UEDo := UTwo;
					end;
				end;
				UFour: 
				begin
					case crossint2 of
						1: 
							if length(curPrompt) > 0 then
							begin
								StringToNum(curPrompt, templong);
								tempUser.MessagesPosted := templong;
							end;
						2: 
							if length(curprompt) > 0 then
							begin
								StringToNum(curprompt, templong);
								if SecLevels^^[tempLong].active then
								begin
									tempUser.SL := tempLong;
									NumToString(tempUser.UserNum, t1);
									if UserOnSystem(concat('@', t1)) then
										for i := 1 to InitSystHand^^.numNodes do
											if (theNodes[i]^.thisUser.userNum = tempUser.UserNum) then
												theNodes[i]^.realSL := tempLong;

									tempUser.DSL := SecLevels^^[tempLong].TransLevel;
									for i := 1 to 26 do
										tempUser.AccessLetter[i] := SecLevels^^[tempLong].Restrics[i];
									tempUser.CantReadAnon := SecLevels^^[TempLong].ReadAnon;
									tempUser.CantPost := SecLevels^^[TempLong].PostMessage;
									tempUser.CantAddToBBSList := SecLevels^^[TempLong].BBSList;
									tempUser.CantSeeULInfo := SecLevels^^[TempLong].Uploader;
									tempUser.UDRatioOn := SecLevels^^[TempLong].UDRatio;
									tempUser.CantChat := SecLevels^^[TempLong].Chat;
									tempUser.CantSendEmail := SecLevels^^[TempLong].Email;
									tempUser.CantListUser := SecLevels^^[TempLong].ListUser;
									tempUser.CantChangeAutoMsg := SecLevels^^[TempLong].AutoMsg;
									tempUser.CantPostAnon := SecLevels^^[TempLong].AnonMsg;
									tempUser.RestrictHours := SecLevels^^[TempLong].EnableHours;
									tempUser.CantSendPPFile := SecLevels^^[TempLong].PPFile;
									tempUser.CantNetMail := SecLevels^^[TempLong].CantNetMail;
									tempUser.PCRatioOn := SecLevels^^[TempLong].PCRatio;
									tempUser.XferComp := SecLevels^^[TempLong].XferComp;
									tempUser.messcomp := SecLevels^^[TempLong].MessComp;
									tempUser.UseDayOrCall := SecLevels^^[TempLong].UseDayOrCall;
									tempUser.TimeAllowed := SecLevels^^[TempLong].TimeAllowed;
									tempUser.MesgDay := SecLevels^^[TempLong].MesgDay;
									tempUser.DLRatioOneTo := SecLevels^^[TempLong].DLRatioOneTo;
									tempUser.PostRatioOneTo := SecLevels^^[TempLong].PostRatioOneTo;
									tempUser.CallsPrDay := SecLevels^^[TempLong].CallsPrDay;
									tempUser.LnsMessage := SecLevels^^[TempLong].LnsMessage;
									tempUser.AlternateText := SecLevels^^[TempLong].AlternateText;
								end
								else
								begin
									OutLine(RetInstr(336), true, 2);	{Classification Not Active, But Security Level Changed.}
									tempUser.SL := tempLong;
									NumToString(tempUser.UserNum, t1);
									if UserOnSystem(concat('@', t1)) then
										for i := 1 to InitSystHand^^.numNodes do
											if (theNodes[i]^.thisUser.userNum = tempUser.UserNum) then
												theNodes[i]^.realSL := tempLong;
								end;
							end;
						otherwise
							if length(curPrompt) > 0 then
							begin
								DoCapsName(curPrompt);
								if FindUser(curPrompt, MailingUser) then
									OutLine(RetInStr(678), true, 0)
								else
								begin
									tempuser.RealName := curPrompt;
									if not newHand^^.Handle then
									begin
										tempuser.UserName := curPrompt;
										NumToString(tempUser.UserNum, t1);
										if UserOnSystem(concat('@', t1)) then
											SetOnlineUser(tempUser);
									end;
								end;
							end;
					end;
					PrUserStuff(tempUser);
					UEDo := UTwo;
				end;
				UFive: 
				begin
					case crossint2 of
						1: 
							if length(curPrompt) > 0 then
							begin
								StringToNum(curPrompt, templong);
								tempUser.MPostedToday := templong;
							end;
						2: 
							if length(curPrompt) > 0 then
							begin
								StringToNum(curprompt, templong);
								if (templong >= 0) and (templong <= thisUser.DSL) then
									tempUser.DSL := templong;
							end;
						otherwise
							if length(curPrompt) > 0 then
							begin
								tempUser.Alias := curPrompt;
								if newHand^^.Handle then
								begin
									tempuser.UserName := curPrompt;
									NumToString(tempUser.UserNum, t1);
									if UserOnSystem(concat('@', t1)) then
										SetOnlineUser(tempUser);
								end;
							end;
					end;
					PrUserStuff(tempUser);
					UEDo := UTwo;
				end;
				USix: 
				begin
					case crossint2 of
						1: 
							if length(curPrompt) > 0 then
							begin
								StringToNum(curPrompt, templong);
								tempUser.EMailSent := templong;
							end;
						2: 
							if length(curPrompt) > 0 then
							begin
								StringToNum(curPrompt, templong);
								tempUser.DLRatioOneTo := templong;
							end;
						otherwise
							if length(curPrompt) > 2 then
							begin
								tempuser.password := curprompt;
							end;
					end;
					PrUserStuff(tempUser);
					UEDo := UTwo;
				end;
				USeven: 
				begin
					case crossint2 of
						1: 
							if length(curPrompt) > 0 then
							begin
								StringToNum(curPrompt, templong);
								tempUser.TotalLogons := templong;
							end;
						2: 
							if length(curPrompt) > 0 then
							begin
								StringToNum(curPrompt, templong);
								tempUser.PostRatioOneTo := templong;
							end;
						otherwise
							tempUser.phone := curPrompt;
					end;
					PrUserStuff(tempUser);
					UEDo := UTwo;
				end;
				UEight: 
				begin
					case crossint2 of
						1: 
							if length(curPrompt) > 0 then
							begin
								StringToNum(curPrompt, templong);
								tempUser.onToday := templong;
							end;
						2: 
						begin
							b := true;
							t4 := curPrompt;
							x := 0;
							for i := 1 to length(t4) do
							begin
								if (t4[i] > '9') or ((t4[i] < '.') and (t4[i] <> '/')) then
									b := false;
								if (t4[i] = '.') then
									x := x + 1;
							end;
							if (b) and (length(t4) > 0) and (x <= 1) then
							begin
								ReadString(t4, r);
								if (r <= 99.9) and (r >= 0.0) then
									tempUser.MessComp := r;
							end;
						end;
						otherwise
							tempUser.DataPhone := curPrompt;
					end;
					PrUserStuff(tempUser);
					UEDo := UTwo;
				end;
				UNine: 
				begin
					case crossint2 of
						1: 
							if length(curPrompt) > 0 then
							begin
								StringToNum(curPrompt, templong);
								tempUser.NumUploaded := templong;
							end;
						2: 
						begin
							b := true;
							t4 := curPrompt;
							x := 0;
							for i := 1 to length(t4) do
							begin
								if (t4[i] > '9') or ((t4[i] < '.') and (t4[i] <> '/')) then
									b := false;
								if (t4[i] = '.') then
									x := x + 1;
							end;
							if (b) and (length(t4) > 0) and (x <= 1) then
							begin
								ReadString(t4, r);
								if (r <= 99.9) and (r >= 0.0) then
									tempUser.XferComp := r;
							end;
						end;
						otherwise
							if length(curPrompt) > 0 then
								tempUser.Street := curPrompt;
					end;
					PrUserStuff(tempUser);
					UEDo := UTwo;
				end;
				UTen: 
				begin
					case crossint2 of
						1: 
							if length(curPrompt) > 0 then
							begin
								StringToNum(curPrompt, templong);
								tempUser.UploadedK := templong;
							end;
						2: 
							if length(curPrompt) > 0 then
							begin
								StringToNum(curPrompt, templong);
								tempUser.MesgDay := templong;
							end;
						otherwise
							if length(curPrompt) > 0 then
								tempUser.City := curPrompt;
					end;
					PrUserStuff(tempUser);
					UEDo := UTwo;
				end;
				UEleven: 
				begin
					case crossint2 of
						1: 
							if length(curPrompt) > 0 then
							begin
								StringToNum(curPrompt, templong);
								tempUser.NumDownloaded := templong;
							end;
						2: 
							if length(curPrompt) > 0 then
							begin
								StringToNum(curPrompt, templong);
								tempUser.LnsMessage := templong;
							end;
						otherwise
							if length(curPrompt) > 0 then
								tempUser.State := curPrompt;
					end;
					PrUserStuff(tempUser);
					UEDo := UTwo;
				end;
				UTwelve: 
				begin
					case crossint2 of
						1: 
							if length(curPrompt) > 0 then
							begin
								StringToNum(curPrompt, templong);
								tempUser.DownloadedK := templong;
							end;
						2: 
							if length(curPrompt) > 0 then
							begin
								StringToNum(curPrompt, templong);
								tempUser.CallsPrDay := templong;
							end;
						otherwise
							if length(curPrompt) > 0 then
								tempUser.Zip := curPrompt;
					end;
					PrUserStuff(tempUser);
					UEDo := UTwo;
				end;
				U13: 
				begin
					case crossint2 of
						1: 
							if length(curPrompt) > 0 then
							begin
								StringToNum(curPrompt, templong);
								tempUser.DLCredits := templong;
							end;
						2: 
							if length(curPrompt) > 0 then
							begin
								StringToNum(curPrompt, templong);
								tempUser.TimeAllowed := templong;
							end;
						otherwise
							if length(curPrompt) > 0 then
							begin
								DoCapsName(curPrompt);
								tempUser.Country := curPrompt;
							end;
					end;
					PrUserStuff(tempUser);
					UEDo := UTwo;
				end;
				U14: 
				begin
					case crossint2 of
						1: 
							if length(curPrompt) > 0 then
								tempUser.Donation := curPrompt;
						2: 
							;
						otherwise
						begin
							StringToNum(copy(curprompt, 1, 2), tempint);
							tempUser.birthMonth := char(tempInt);
							StringToNum(copy(curprompt, 4, 2), tempInt);
							tempUser.birthDay := char(tempInt);
							StringToNum(copy(curprompt, 7, 2), tempInt);
							tempUser.birthYear := char(tempInt);
						end;
					end;
					PrUserStuff(tempUser);
					UEDo := UTwo;
				end;
				U15: 
				begin
					case crossint2 of
						1: 
							if length(curPrompt) > 0 then
								tempUser.LastDonation := curPrompt;
						2: 
						begin
							if length(curPrompt) > 0 then
							begin
								StringToNum(curPrompt, templong);
								case templong of
									1: 
										tempUser.CantPost := not tempUser.CantPost;
									2: 
										tempUser.CantChat := not tempUser.CantChat;
									3: 
										tempUser.UDRatioOn := not tempUser.UDRatioOn;
									4: 
										tempUser.PCRatioOn := not tempUser.PCRatioOn;
									5: 
										tempUser.CantPostAnon := not tempUser.CantPostAnon;
									6: 
										tempUser.CantSendEmail := not tempUser.CantSendEmail;
									7: 
										tempUser.CantChangeAutoMsg := not tempUser.CantChangeAutoMsg;
									8: 
										tempUser.CantListUser := not tempUser.CantListUser;
									9: 
										tempUser.CantAddToBBSList := not tempUser.CantAddToBBSList;
									10: 
										tempUser.CantSeeULInfo := not tempUser.CantSeeULInfo;
									11: 
										tempUser.CantReadAnon := not tempUser.CantReadAnon;
									12: 
										tempUser.RestrictHours := not tempUser.RestrictHours;
									13: 
										tempUser.CantSendPPFile := not tempUser.CantSendPPFile;
									14: 
										tempUser.CantNetMail := not tempUser.CantNetMail;
									15: 
										tempUser.ReadBeforeDL := not tempUser.ReadBeforeDL;
								end;
							end;
						end;
						otherwise
						begin
							if curprompt = 'M' then
								tempUser.sex := true
							else if curPrompt = 'F' then
								tempUser.sex := false;
						end;
					end;
					PrUserStuff(tempUser);
					UEDo := UTwo;
				end;
				U16: 
				begin
					case crossint2 of
						1: 
							if length(curPrompt) > 0 then
								tempUser.ExpirationDate := curPrompt;
						2: 
							if length(curPrompt) > 0 then
							begin
								tempint := ord(curPrompt[1]) - 64;
								tempUser.AccessLetter[tempint] := not tempUser.AccessLetter[tempint];
							end;
						otherwise
							if length(curPrompt) > 0 then
								tempUser.Company := curPrompt;
					end;
					PrUserStuff(tempUser);
					UEDo := UTwo;
				end;
				U17: 
				begin
					case crossint2 of
						1: 
							tempUser.SysopNote := curPrompt;
						2: 
							;
						otherwise
							if length(curPrompt) > 0 then
								tempUser.computerType := curPrompt;
					end;
					PrUserStuff(tempuser);
					UEDo := UTwo;
				end;
				U18: 
				begin
					case crossint2 of
						1: 
							;
						2: 
							;
						otherwise
							if length(curPrompt) > 0 then
								tempUser.MiscField1 := curPrompt;
					end;
					PrUserStuff(tempUser);
					UEDo := UTwo;
				end;
				U19: 
				begin
					case crossint2 of
						1: 
							;
						2: 
							if (curPrompt = 'Y') and (tempUser.DeletedUser) then
							begin
								tempUser.DeletedUser := false;
								InitSystHand^^.numUsers := InitSystHand^^.numUsers + 1;
								if tempUser.UserName[1] = '~' then
									Delete(tempUser.UserName, 1, 1);
								if tempUser.Alias[1] <> '•' then
									tempUser.alias := tempUser.UserName
								else
									tempUser.RealName := tempUser.UserName;
								doSystRec(true);
							end
							else if (curPrompt = 'Y') and not (tempUser.DeletedUser) then
							begin
								InitSystHand^^.numUsers := InitSystHand^^.numUsers - 1;
								doSystRec(true);
								tempUser.DeletedUser := true;
								i := 0;
								while (i < availEmails) do
									if (theEmail^^[i].toUser = tempUser.userNum) or (theEmail^^[i].FromUser = tempUser.userNum) then
										DeleteMail(i)
									else
										i := i + 1;
								if tempUser.UserName[1] <> '~' then
									tempUser.UserName := concat('~', tempUser.UserName);
								if tempUser.Alias[1] <> '•' then
									tempUser.alias := tempUser.UserName
								else
									tempUser.RealName := tempUser.UserName;
							end;
						otherwise
							if length(curPrompt) > 0 then
								tempUser.MiscField2 := curPrompt;
					end;
					PrUserStuff(tempUser);
					UEDo := UTwo;
				end;
				U20: 
				begin
					case crossint2 of
						1: 
							;
						2: 
							;
						otherwise
							if length(curPrompt) > 0 then
								tempUser.MiscField3 := curPrompt;
					end;
					PrUserStuff(tempUser);
					UEDo := UTwo;
				end;
				U21: 
				begin
					if (length(curPrompt) < 1) then
						curPrompt := '1';

					if tempUser.userNum <> -1 then
					begin
						tempInt := tempuser.userNum;
						writeuser(tempUser);
						myUsers^^[tempuser.userNum - 1].UName := tempuser.userName;
						myUsers^^[tempuser.userNum - 1].dltd := tempuser.DeletedUser;
						myUsers^^[tempuser.userNum - 1].real := tempuser.realName;
						myUsers^^[tempuser.userNum - 1].SL := tempuser.SL;
						myUsers^^[tempuser.userNum - 1].DSL := tempuser.DSL;
						myUsers^^[tempuser.userNum - 1].age := tempuser.age;
						for i := 1 to 26 do
							myUsers^^[tempuser.userNum - 1].AccessLetter[i] := tempuser.AccessLetter[i];
						NumToString(tempUser.UserNum, t1);
						if UserOnSystem(concat('@', t1)) then
							SetOnlineUser(tempUser);
					end;

					b := false;
					if FindUser(curPrompt, tempuser) then
						b := true
					else
					begin
						OutLine(RetInStr(17), true, 0);
						NumToString(tempint, t1);
						if FindUser(t1, tempUser) then
							;
					end;

					if (curPrompt[1] > char(64)) then
					begin
						Delete(curPrompt, Length(curPrompt), 1);
						enteredPass2 := curPrompt;
						x := 0;
						if b then
						begin
							for i := 1 to numUserRecs do
							begin
								t2 := myUsers^^[i - 1].UName;
								UprString(t2, true);
								if pos(curPrompt, t2) > 0 then
								begin
									x := x + 1;
									NumToString(x, t3);
									if (length(t3) = 1) then
										t3 := concat('   ', t3, ' - ', myUsers^^[i - 1].UName)
									else if (length(t3) = 2) then
										t3 := concat('  ', t3, ' - ', myUsers^^[i - 1].UName)
									else if (length(t3) = 3) then
										t3 := concat(' ', t3, ' - ', myUsers^^[i - 1].UName)
									else
										t3 := concat(t3, ' - ', myUsers^^[i - 1].UName);
									if (x = 1) then
										t4 := t3
									else if (x = 2) then
									begin
										OutLine(t4, true, 0);
										OutLine(t3, true, 0);
									end
									else
										OutLine(t3, true, 0);
								end;
							end;
							if (x > 1) then
							begin
								bCR;
								bCR;
								NumbersPrompt('Which user: ', '1234567890', x, 1);
							end
							else
								b := false;
						end;
					end;
					if b then
					begin
						UEDo := U22;
					end
					else
					begin
						if UserOnSystem(tempuser.userName) then
							GetOnlineUser(tempUser);
						PrUserStuff(tempUser);
						UEDo := UTwo;
					end;
				end;
				U22: 
				begin
					x := 0;
					StringToNum(curPrompt, templong);
					crossint4 := templong;
					for i := 1 to numUserRecs do
					begin
						t2 := myUsers^^[i - 1].UName;
						UprString(t2, true);
						if pos(enteredPass2, t2) > 0 then
						begin
							x := x + 1;
							if (x = crossint4) then
							begin
								NumToString(i, t3);
								b := FindUser(t3, tempUser);
								i := numUserRecs + 1;
							end;
						end;
					end;
					PrUserStuff(tempUser);
					UEDo := UTwo;
				end;
				U23: 
				begin
					if thisUser.coSysop then
					begin
						if not sysoplogon and (thisUser.SL < 255) then
							LettersPrompt(RetInStr(20), '', 9, false, false, true, 'X')	{SY: }
						else
							curPrompt := InitSystHand^^.overridePass;
						UEDo := U24;
						HelpNum := 35;
					end
					else
						GoHome;
				end;
				U24: 
				begin
					if EqualString(curPrompt, InitSystHand^^.overridePass, false, false) then
					begin
						tempUser.userNum := -1;
						crossint2 := 2;
						if maxLines = -425 then
							NumToString(theEmail^^[myEmailList^^[atEmail]].fromUser, curPrompt)
						else
							NumToString(curBase^^[inMessage - 1].fromUserNum, curPrompt);
						UEDo := U21;
					end
					else
						GoHome;
				end;
				otherwise
			end;
		end;
	end;

	function compareBBSEntry (first, second: BBSListEntry): boolean;
		var
			t1, t2: str255;
			tl1, tl2: longint;
			i: integer;
	begin
		compareBBSentry := false;
		t1 := '';
		t2 := '';
		for i := 1 to 12 do
		begin
			t1 := concat(t1, ' ');
			t2 := concat(t2, ' ');
		end;
		BlockMove(@first.number[0], @t1[1], 12);
		BlockMove(@second.number[0], @t2[1], 12);
		t1[0] := char(3);
		t2[0] := char(3);
		StringToNum(t1, tl1);
		StringToNum(t2, tl2);
		if (tl1 = tl2) then
		begin
			delete(t1, 1, 4);
			delete(t2, 1, 4);
			t1[0] := char(7);
			t2[0] := char(7);
			StringToNum(t1, tl1);
			StringToNum(t2, tl2);
			if (tl1 < tl2) then
				compareBBSentry := true;
		end
		else if (tl1 < tl2) then
			compareBBSentry := true;
	end;

	procedure BBSQuickSort (myBBSList: BBSListPtr; start, finish: integer);
		var
			left, right: integer;
			starterValue, temp: BBSListEntry;
	begin
		left := start;
		right := finish;
		starterValue := myBBSList^[(start + finish) div 2];
		repeat
			while compareBBSEntry(myBBSList^[left], starterValue) do
				left := left + 1;
			while compareBBSEntry(starterValue, myBBSList^[right]) do
				right := right - 1;
			if left <= right then
			begin
				temp := myBBSList^[left];
				myBBSList^[left] := myBBSList^[right];
				myBBSList^[right] := temp;
				left := left + 1;
				right := right - 1;
			end;
		until right <= left;
		if start < right then
			BBSQuickSort(myBBSList, start, right);
		if left < finish then
			BBSQuickSort(myBBSList, left, finish);
	end;

	function SortBBSList: boolean;
		var
			BBStemp: BBSListPtr;
			BBSRef, i, entries: integer;
			bbsListSize: longint;
			badFormat: boolean;
	begin
		badFormat := false;
		result := FSOpen(concat(sharedPath, 'Misc:BBS List'), 0, BBSRef);
		if result = noErr then
		begin
			result := GetEOF(BBSRef, bbsListSize);
			entries := ((bbsListSize div SizeOf(BBSListEntry)) - 1);
			BBSTemp := BBSListPtr(NewPtr(bbsListSize));
			if (memError = noErr) then
			begin
				result := FSRead(BBSRef, bbsListSize, ptr(BBStemp));
				for i := 0 to entries do
					if bbstemp^[i].theRest[67] <> char(13) then
						badFormat := true;
				if not badFormat then
					BBSQuickSort(bbsTemp, 0, entries);
				result := SetFPos(BBSref, fsFromStart, 0);
				result := FSWrite(BBSref, bbsListSize, ptr(BBStemp));
				DisposPtr(ptr(BBStemp));
			end
			else
				SysBeep(1);
			result := FSClose(BBSRef);
		end;
		sortBBSList := badFormat;
	end;

{$S HUtils1_2}
	function inBBSlist (theNum: str255): boolean;
		var
			result: OSerr;
			bbsLRef: integer;
			tempString: str255;
			place, tempLeng: longint;
			bbsListings: TextHand;
			found: boolean;
	begin
		inBBSlist := false;
		result := FSOpen(concat(sharedPath, 'Misc:BBS List'), 0, BBSlRef);
		if result <> noErr then
		begin
			result := FSDelete(concat(sharedPath, 'Misc:BBS List'), 0);
			result := Create(concat(sharedPath, 'Misc:BBS List'), 0, 'HRMS', 'TEXT');
			result := FSOpen(concat(sharedPath, 'Misc:BBS List'), 0, BBSlRef);
		end;
		if result = noErr then
		begin
			place := -1;
			result := GetEOF(BBSLRef, tempLeng);
			if tempLeng > 0 then
			begin
				bbsListings := TextHand(newHandle(tempLeng));
				if memError = noErr then
				begin
					HLock(handle(bbsListings));
					result := FSRead(BBSLref, tempLeng, pointer(bbsListings^));
					found := false;
					tempString := '            ';
					repeat
						repeat
							place := place + 1;
						until (bbsListings^^[place] = theNum[1]) or (place >= tempLeng - 1);
						if (place < tempLeng) then
						begin
							BlockMove(@bbsListings^^[place], @tempString[1], 12);
							if EqualString(theNum, tempString, false, false) then
								found := true;
						end;
					until found or (place >= tempLeng - 1);
					HUnlock(handle(BBSlistings));
					DisposHandle(handle(bbsListings));
					if found then
						inBBSlist := true;
				end;
			end;
			result := FSClose(BBSlRef);
		end
		else
		begin
			OutLine('Couldn''t open BBS list!', true, 6);
			GoHome;
		end;
	end;

	procedure doBBSlist;
		var
			tempString: str255;
			i, tempInt: integer;
			result: OSerr;
			count: longint;
	begin
		with curglobs^ do
		begin
			case BBSlDo of
				bone: 
				begin
					bCR;
					bCR;
					if (thisUser.coSysop) then
						LettersPrompt(RetInStr(337), 'RASQ', 1, true, false, true, char(0))	{BBS list: R:ead, A:dd, S:ort, Q:uit  : }
					else if (not ThisUser.CantAddToBBSList) then
						LettersPrompt(RetInStr(338), 'RAQ', 1, true, false, true, char(0))	{BBS list: R:ead, A:dd, Q:uit  : }
					else
						LettersPrompt(RetInStr(339), 'RQ', 1, true, false, true, char(0));	{BBS list: R:ead, Q:uit  : }
					BBSLDo := Btwo;
				end;
				BTwo: 
				begin
					if length(curPrompt) > 0 then
					begin
						case curPrompt[1] of
							'Q': 
								goHome;
							'S': 
							begin
								bCR;
								if (not SortBBSList) then
									OutLine('Sorted.', true, 0)
								else
									OutLine(RetInStr(340), true, 0);	{BBS List has a bad format.}
								BBSlDo := BOne;
							end;
							'R': 
							begin
								crosslong := InitSystHand^^.StartDate;
								bCR;
								crossint4 := 34;
								crossint3 := length(InitSystHand^^.EndString);
								if readTextFile('Misc:BBS List', 0, true) then
								begin
									BoardAction := ListText;
									ListTextFile;
								end
								else
									OutLine(RetInStr(341), true, 0);	{There are no entries in the BBS list.}
								BBSlDo := BOne;
							end;
							'A': 
							begin
								OutLine(RetInStr(342), true, 0);	{Please enter phone number:}
								if InitSystHand^^.freePhone then
								begin
									bCR;
									LettersPrompt(': ', '', 12, false, false, true, char(0));
								end
								else
								begin
									OutLine(RetInStr(343), true, 0);		{  ###-###-####}
									bCR;
									LettersPrompt(': ', '', -2, false, false, true, char(0));
								end;
								ANSIPrompter(12);
								BBSlDo := bThree;
							end;
							otherwise
								goHome;
						end;
					end
					else
						BBSLdo := BOne;
				end;
				bThree: 
				begin
					if not inBBSList(curprompt) then
					begin
						fileMask := curPrompt;
						OutLine(RetInStr(344), true, 0);		{Number not yet in BBS list.}
						bCR;
						OutLine(RetInStr(345), true, 0);	{Enter BBS name and comments:}
						bCR;
						LettersPrompt(': ', '', 50, false, false, false, char(0));
						ANSIPrompter(50);
						BBSlDo := BFour;
					end
					else
					begin
						OutLine(RetInStr(346), true, 0);	{It''s already in the BBS list.}
						bCR;
						BBSlDo := BOne;
					end;
				end;
				BFour: 
				begin
					fileMask := concat(fileMask, '  ', curPrompt);
					if length(filemask) < 67 then
						for i := 1 to (67 - length(filemask)) do
							fileMask := concat(fileMask, ' ');
					OutLine(RetInStr(348), true, 0);	{Enter maximum speed of the BBS:}
					OutLine(RetInStr(349), true, 0);	{ie, 300,1200,2400,9600,14.4,16.8,19.2}
					bCR;
					LettersPrompt(': ', '', 4, false, false, true, char(0));
					ANSIPrompter(4);
					BBSlDo := BFive;
				end;
				bFive: 
				begin
					if (length(curprompt) < 4) then
						for i := 1 to (4 - length(curprompt)) do
							curprompt := concat(' ', curprompt);
					fileMask := concat(fileMask, '[', curprompt, ']');
					OutLine(RetInStr(350), true, 0);	{Enter BBS type (ie, HRMS):}
					bCR;
					LettersPrompt(': ', '', 4, false, false, true, char(0));
					ANSIPrompter(4);
					BBSlDo := bSix;
				end;
				bSix: 
				begin
					if (length(curprompt) < 4) then
						for i := 1 to (4 - length(curprompt)) do
							curprompt := concat(' ', curprompt);
					fileMask := concat(fileMask, '(', curPrompt, ')');
					OutLine(fileMask, true, 0);
					bCR;
					bCR;
					YesNoQuestion(RetInStr(351), false);	{Is this correct? }
					BBSlDo := bSeven;
				end;
				bSeven: 
				begin
					if curprompt = 'N' then
						BBSlDO := bOne
					else
					begin
						result := FSOpen(concat(sharedPath, 'Misc:BBS List'), 0, tempint);
						if result = noErr then
						begin
							LogThis('      Added to BBS List:', 0);
							LogThis(fileMask, 0);
							fileMask := concat(fileMask, char(13));
							result := SetFPos(tempint, fsFromLEOF, 0);
							count := length(fileMask);
							result := FSWrite(tempInt, count, @fileMask[1]);
							result := FSClose(tempint);
							Outline(RetInStr(352), true, 0);	{Number added to BBS list.}
						end
						else
							OutLine(RetInStr(353), true, 6);	{Problem adding number to BBS list!}
						bbsLDo := bOne;
					end;
				end;
				otherwise
			end;
		end;
	end;
end.