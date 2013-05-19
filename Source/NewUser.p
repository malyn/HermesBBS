{ Segments: NewUser_1 }
unit NewUser;

interface
	uses
		AppleTalk, ADSP, Serial, Sound, TCPTypes, Initial, LoadAndSave, NodePrefs2, NodePrefs, SystemPrefs2, User, inpOut4, MessNTextOutput, FileTrans;

	procedure DoQuiz;
	procedure PrintUserEntry;
	function PrintExternalList: integer;

implementation

{$S NewUser_1}
	function ExternalOk (which: integer): boolean;
		var
			tb: boolean;
	begin
		with curGlobs^ do
		begin
			if which <= numExternals then
			begin
				tb := true;
				if myExternals^^[which].AccessLetter <> char(0) then
					if thisUser.AccessLetter[byte(myExternals^^[which].AccessLetter) - byte(64)] then
						tb := true
					else
						tb := false;
				if tb and (thisUser.SL >= myExternals^^[which].minSLForMenu) then
					tb := true
				else
					tb := false;
			end
			else
				tb := false;
			ExternalOk := tb;
		end;
	end;

	function PrintExternalList: integer;
		var
			i, x, y, z, r: integer;
			tempString, BColor, YColor: str255;
			TheList: array[1..50] of string[47];
	begin
		with curglobs^ do
		begin
			bCR;
			OutLine(RetInStr(77), true, 0);
			bCR;
			if (thisUser.TerminalType = 1) then
			begin
				BColor := concat(char(27), '[0;36;40m');
				YColor := concat(char(27), '[0;33;40m');
			end
			else
			begin
				BColor := char(0);
				YColor := char(0);
			end;
			if (thisUser.columns) and (numExternals > 5) then
			begin
				x := 0;
				y := -1;
				z := 0;
				r := 0;
				for i := 1 to numExternals do
					if ExternalOk(i) then
					begin
						x := x + 1;
						r := r + 1;
					end;
				if (x < 50) then
					TheList[x + 1] := char(0);
				if (not odd(x)) then
					x := x - 1;
				for i := 1 to numExternals do
					if ExternalOk(i) then
					begin
						if y >= x then
							y := 0;
						y := y + 2;
						z := z + 1;
						if z < 10 then
							TheList[y] := StringOf(' ', YColor, z : 0, '. ', BColor, myExternals^^[i].name, '                                                ')
						else
							TheList[y] := stringOf(YColor, z : 0, '. ', BColor, myExternals^^[i].name, '                                                ');
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
				r := 0;
				for i := 1 to numExternals do
					if ExternalOk(i) then
					begin
						x := x + 1;
						r := r + 1;
						OutLine(StringOf(x : 2, '. '), true, 2);
						OutLine(myExternals^^[i].name, false, 1);
					end;
			end;
			bCR;
			PrintExternalList := r;
		end;
	end;

	function NextNum: char;
		var
			s: str255;
			n: integer;
	begin
		curglobs^.crossint3 := curglobs^.crossint3 + 1;
		n := curglobs^.crossint3 + 64;
		s := char(n);

		GlobalStr := concat(GlobalStr, s);
		NextNum := s;
	end;

	procedure PrintUserEntry;
		var
			TempString, TempString2: Str255;
	begin
		with CurGlobs^ do
		begin
			globalStr := 'Y';
			crossint3 := 0;
			if newhand^^.handle then
				bufferIt(concat(NextNum, RetInStr(654), thisUser.Alias), true, 0);{] Handle/Alias     : }
			if newhand^^.realname then
				bufferIt(concat(NextNum, RetInStr(655), thisUser.RealName), true, 0);{] Realname         : }
			bufferIt(concat(NextNum, RetInStr(656), thisUser.Phone), true, 0);{] Phone Number     : }
			if newhand^^.DataPN then
				bufferIt(concat(NextNum, RetInStr(657), thisUser.DataPhone), true, 0);{] Data Phone Number: }
			if newHand^^.gender then
			begin
				tempString := 'Female';
				if thisUser.Sex then
					tempString := 'Male';
				bufferIt(concat(NextNum, RetInStr(658), tempString), true, 0);{] Gender           : }
			end;
			if newHand^^.Company then
				bufferIt(concat(NextNum, RetInStr(659), thisUser.company), true, 0);{] Company          : }
			if newhand^^.street then
				bufferIt(concat(NextNum, RetInStr(660), thisUser.street), true, 0);{] Street Address   : }
			if newHand^^.City then
			begin
				bufferIt(concat(NextNum, RetInStr(661), thisUser.city), true, 0);{] City             : }
				bufferIt(concat(NextNum, RetInStr(662), thisuser.state), true, 0);{] State            : }
				bufferIt(concat(NextNum, RetInStr(663), thisUser.Zip), true, 0);{] Zip Code         : }
			end;
			if newHand^^.Country then
				bufferIt(concat(NextNum, RetInStr(664), thisUser.Country), true, 0);	{] Country          : }
			if newHand^^.SysOp[1] then
				bufferIt(stringOf(NextNum, '] ', copy(newHand^^.SysOpText[1], 1, 16), ' ' : 17 - Length(NewHand^^.SysOpText[1]), ': ', thisUser.MiscField1), true, 0);
			if newHand^^.SysOp[2] then
				bufferIt(stringOf(NextNum, '] ', copy(newHand^^.SysOpText[2], 1, 16), ' ' : 17 - Length(NewHand^^.SysOpText[2]), ': ', thisUser.MiscField2), true, 0);
			if newHand^^.SysOp[3] then
				bufferIt(stringOf(NextNum, '] ', copy(newHand^^.SysOpText[3], 1, 16), ' ' : 17 - Length(NewHand^^.SysOpText[3]), ': ', thisUser.MiscField3), true, 0);
			if newHand^^.BirthDay then
			begin
				NumToString(integer(thisUser.birthMonth), tempString);
				tempString := concat(tempString, '/');
				NumToString(integer(thisUser.birthDay), tempString2);
				tempString := concat(tempString, tempString2, '/');
				NumToString(integer(thisUser.birthYear), tempString2);
				tempString := concat(tempString, tempString2);
				bufferIt(concat(NextNum, RetInStr(665), tempString), true, 0);{] Birthdate        : }
			end;
			if newHand^^.computer then
				bufferIt(concat(NextNum, RetInStr(666), thisUser.ComputerType), true, 0);{] Computer Type    : }
			bufferIt(StringOf(NextNum, RetInStr(667), thisUser.scrnHght : 0), true, 0);{] Screen Height    : }
			bufferIt(stringOf(NextNum, RetInStr(668), thisUser.scrnWdth : 0), true, 0);{] Screen Width     : }
			tempString := 'No';
			tempString2 := '';
			if thisUser.TerminalType = 1 then
				tempString := 'Yes';
			if (thisUser.TerminalType = 1) and thisUser.ColorTerminal then
				tempString2 := ', Color'
			else if thisUser.TerminalType = 1 then
				tempString2 := ', Mono';
			bufferIt(concat(NextNum, RetInStr(669), tempString, tempString2), true, 0);{] Ansi             : }
			if thisUser.screenclears then
				tempString := 'On'
			else
				tempString := 'Off';
			bufferIt(concat(NextNum, RetInStr(670), tempString), true, 0);{] Screen Clears    : }
			if thisUser.PauseScreen then
				tempString := 'On'
			else
				tempString := 'Off';
			bufferIt(concat(NextNum, RetInStr(671), tempString), true, 0);{] Screen Pausing   : }
			if thisUser.Columns then
				tempString := '2 Column'
			else
				tempString := '1 Column';
			bufferIt(concat(NextNum, RetInStr(672), tempString), true, 0);{] Column Mode      : }
			releaseBuffer;
		end;
	end;

	function DoACheck (theChar: char; tempint: integer): boolean;
		var
			ts: str255;
	begin
		ts := char(tempint + 64);
		if ts = theChar then
			DoACheck := true
		else
			DoACheck := false;
	end;

	function WhatKey (incomingChar: char): char;
		var
			tempint: integer;
			templ: longint;
	begin
		if (incomingChar = 'Y') then
			WhatKey := incomingChar
		else
		begin
			tempint := 0;
			if (newHand^^.handle) then
			begin
				tempint := tempint + 1;
				if DoACheck(incomingChar, tempint) then
				begin
					WhatKey := 'A';
					Exit(WhatKey);
				end;
			end;
			if (newHand^^.realName) then
			begin
				tempint := tempint + 1;
				if DoACheck(incomingChar, tempint) then
				begin
					WhatKey := 'B';
					Exit(WhatKey);
				end;
			end;
			tempint := tempint + 1;
			if DoACheck(incomingChar, tempint) then
			begin
				WhatKey := 'C';
				Exit(WhatKey);
			end;
			if (newHand^^.DataPN) then
			begin
				tempint := tempint + 1;
				if DoACheck(incomingChar, tempint) then
				begin
					WhatKey := 'D';
					Exit(WhatKey);
				end;
			end;
			if (newHand^^.gender) then
			begin
				tempint := tempint + 1;
				if DoACheck(incomingChar, tempint) then
				begin
					WhatKey := 'E';
					Exit(WhatKey);
				end;
			end;
			if (newHand^^.company) then
			begin
				tempint := tempint + 1;
				if DoACheck(incomingChar, tempint) then
				begin
					WhatKey := 'F';
					Exit(WhatKey);
				end;
			end;
			if (newHand^^.street) then
			begin
				tempint := tempint + 1;
				if DoACheck(incomingChar, tempint) then
				begin
					WhatKey := 'G';
					Exit(WhatKey);
				end;
			end;
			if (newHand^^.City) then
			begin
				tempint := tempint + 1;
				if DoACheck(incomingChar, tempint) then
				begin
					WhatKey := 'H';
					Exit(WhatKey);
				end;
			end;
			if (newHand^^.City) then
			begin
				tempint := tempint + 1;
				if DoACheck(incomingChar, tempint) then
				begin
					WhatKey := 'I';
					Exit(WhatKey);
				end;
			end;
			if (newHand^^.City) then
			begin
				tempint := tempint + 1;
				if DoACheck(incomingChar, tempint) then
				begin
					WhatKey := 'J';
					Exit(WhatKey);
				end;
			end;
			if (newHand^^.Country) then
			begin
				tempint := tempint + 1;
				if DoACheck(incomingChar, tempint) then
				begin
					WhatKey := 'K';
					Exit(WhatKey);
				end;
			end;
			if (newHand^^.SysOp[1]) then
			begin
				tempint := tempint + 1;
				if DoACheck(incomingChar, tempint) then
				begin
					WhatKey := 'L';
					Exit(WhatKey);
				end;
			end;
			if (newHand^^.SysOp[2]) then
			begin
				tempint := tempint + 1;
				if DoACheck(incomingChar, tempint) then
				begin
					WhatKey := 'M';
					Exit(WhatKey);
				end;
			end;
			if (newHand^^.SysOp[3]) then
			begin
				tempint := tempint + 1;
				if DoACheck(incomingChar, tempint) then
				begin
					WhatKey := 'N';
					Exit(WhatKey);
				end;
			end;
			if (newHand^^.BirthDay) then
			begin
				tempint := tempint + 1;
				if DoACheck(incomingChar, tempint) then
				begin
					WhatKey := 'O';
					Exit(WhatKey);
				end;
			end;
			if (newHand^^.computer) then
			begin
				tempint := tempint + 1;
				if DoACheck(incomingChar, tempint) then
				begin
					WhatKey := 'P';
					Exit(WhatKey);
				end;
			end;
			tempint := tempint + 1;
			if DoACheck(incomingChar, tempint) then
			begin
				WhatKey := 'Q';
				Exit(WhatKey);
			end;
			tempint := tempint + 1;
			if DoACheck(incomingChar, tempint) then
			begin
				WhatKey := 'R';
				Exit(WhatKey);
			end;
			tempint := tempint + 1;
			if DoACheck(incomingChar, tempint) then
			begin
				WhatKey := 'S';
				Exit(WhatKey);
			end;
			tempint := tempint + 1;
			if DoACheck(incomingChar, tempint) then
			begin
				WhatKey := 'T';
				Exit(WhatKey);
			end;
			tempint := tempint + 1;
			if DoACheck(incomingChar, tempint) then
			begin
				WhatKey := 'U';
				Exit(WhatKey);
			end;
			tempint := tempint + 1;
			if DoACheck(incomingChar, tempint) then
			begin
				WhatKey := 'V';
				Exit(WhatKey);
			end;
		end;
	end;

	procedure DoQuiz;
		var
			tempBool, gotIt: boolean;
			tempInt, tempLong: longInt;
			tempDate, tempDate2: DateTimeRec;
			tempString, tempstring2: Str255;
			tempShort, i, LastRef, tempnumem, tempInt2, tempInt3: integer;
	begin
		with curglobs^ do
		begin
			case Quiz of
				NUP: 
				begin
					bCR;
					NumRptPrompt := 4;
					Quiz := CheckNUP;
					if isTwoByteScript then
						LettersPrompt(RetInStr(673), '', 9, false, false, false, 'X') {New User Password: }
					else
						LettersPrompt(RetInStr(673), '', 9, false, false, true, 'X');{New User Password: }
					curprompt := '';
				end;
				CheckNUP: 
				begin
					if EqualString(CurPrompt, InitSystHand^^.NewUserPass, false, false) then
					begin
						statChanged := true;
						NumRptPrompt := 3;
						quiz := Q60;
						GoHome;
						bCR;
						ClearScreen;
						if ReadTextFile('New User', 1, false) then
						begin
							if thisUser.TerminalType = 1 then
								noPause := true;
							BoardAction := ListText;
							ListTextFile;
						end
						else
						begin
							BoardAction := none;
							OutLine(RetInStr(674), true, 0);{NewUser file not found.}
						end;
					end
					else
					begin
						if numRptPrompt > 0 then
						begin
							if (numRptPrompt < 5) and (length(curPrompt) > 0) then
								LogThis(concat(RetInStr(355), curprompt), 6);	{Wrong newuser password: }
							LettersPrompt(RetInStr(673), '', 9, false, false, true, 'X');
							numRptPrompt := numRptPrompt - 1;
						end
						else
						begin
							if (length(curPrompt) > 0) then
								LogThis(concat(RetInStr(355), curprompt), 6);
							HangupAndReset;
						end;
					end;
				end;
				GetAlias: 
				begin
					OutLine(RetInStr(675), true, 0);{Enter your handle or alias.}
					bCR;
					if isTwoByteScript then
						LettersPrompt(': ', '', 31, false, false, false, char(0))
					else
						LettersPrompt(': ', '', 31, false, false, true, char(0));
					Quiz := CheckAlias;
				end;
				CheckAlias: 
				begin
					if not isTwoByteScript then
						DoCapsName(curPrompt);
					tempbool := FindUser(curPrompt, tempUser);
					if not InTrash(curprompt) and not tempbool and (length(curPrompt) > 0) and ((curPrompt[1] > char(57)) or (curPrompt[1] < char(48))) then
					begin
						thisUser.Alias := curPrompt;
						Quiz := Q60;
						GoHome;
					end
					else
					begin
						OutLine(RetInStr(676), true, 0);{I'' m sorry, you can'' t use that alias.}
						bCR;
						NumRptPrompt := NumRptPrompt - 1;
						if ((NumRptPrompt <> 0) and (crossint8 <> 15)) or (crossint8 = 15) then
							Quiz := GetAlias
						else
							HangupAndReset;
					end;
				end;
				GetReal: 
				begin
					Outline(RetInStr(677), true, 0);{Enter your real first and last name.}
					bCR;
					if isTwoByteScript then
						LettersPrompt(': ', '', 21, false, false, false, char(0))
					else
						LettersPrompt(': ', '', 21, false, false, true, char(0));
					quiz := CheckReal;
				end;
				CheckReal: 
				begin
					if not isTwoByteScript then
						DoCapsName(curPrompt);
					tempbool := FindUser(curPrompt, tempUser);
					if newhand^^.handle then
						tempbool := FindUser(concat('%', curPrompt), tempUser);
					if not InTrash(curprompt) and not tempbool and (length(curPrompt) > 0) and ((curPrompt[1] > char(57)) or (curPrompt[1] < char(48))) and (pos(' ', CurPrompt) > 0) then
					begin
						thisUser.RealName := curPrompt;
						Quiz := Q60;
						GoHome;
					end
					else
					begin
						OutLine(RetInStr(678), true, 0);{I'' m sorry, you can'' t use that name.}
						bCR;
						NumRptPrompt := NumRptPrompt - 1;
						if ((NumRptPrompt <> 0) and (crossint8 <> 15)) or (crossint8 = 15) then
							Quiz := GetReal
						else
							HangupAndReset;
					end;
				end;
				GetVoice: 
				begin
					thisUser.coSysop := false;
					if InitSystHand^^.freePhone then
					begin
						OutLine(RetInStr(679), true, 0);{Enter your VOICE phone number.}
						bcr;
						LettersPrompt(': ', '', 12, false, false, true, char(0));
					end
					else
					begin
						OutLine(RetInStr(680), true, 0);{Enter your VOICE phone no. in the form:}
						OutLine('  ###-###-####', true, 0);
						bcr;
						LettersPrompt(': ', '', -2, false, false, true, char(0));
					end;
					quiz := CheckVoice;
				end;
				CheckVoice: 
				begin
					if ((Length(CurPrompt) = 12) and (CurPrompt[4] = '-') and (CurPrompt[8] = '-')) or (InitSystHand^^.freePhone) then
					begin
						thisUser.phone := curPrompt;
						Quiz := Q60;
						GoHome;
					end
					else
					begin
						Quiz := GetVoice;
						OutLine(RetInStr(681), true, 0);{Please enter a valid phone number}
						OutLine(RetInStr(682), true, 0);{in the correct format.}
						bCR;
					end;
				end;
				GetData: 
				begin
					if InitSystHand^^.freePhone then
					begin
						OutLine(RetInStr(683), true, 0);	{Enter your DATA phone number.}
						bcr;
						LettersPrompt(': ', '', 12, false, false, true, char(0));
					end
					else
					begin
						OutLine(RetInStr(684), true, 0);{Enter your DATA phone no. in the form:}
						OutLine('  ###-###-####', true, 0);
						bcr;
						LettersPrompt(': ', '', -2, false, false, true, char(0));
					end;
					quiz := CheckData;
				end;
				CheckData: 
				begin
					if ((Length(CurPrompt) = 12) and (CurPrompt[4] = '-') and (CurPrompt[8] = '-')) or (InitSystHand^^.freePhone) then
					begin
						thisUser.dataphone := curPrompt;
						Quiz := Q60;
						GoHome;
					end
					else
					begin
						Quiz := GetData;
						OutLine(RetInStr(681), true, 0);{Please enter a valid phone number}
						OutLine(RetInStr(682), true, 0);{in the correct format.}
						bCR;
					end;
				end;
				GetGender: 
				begin
					bCR;
					NumbersPrompt(RetInStr(685), 'MF', -666, 1);
					Quiz := CheckGender;
				end;
				CheckGender: 
				begin
					thisUser.sex := true;
					if (curPrompt = 'F') then
						thisUser.sex := false;
					Quiz := Q60;
					GoHome;
				end;
				GetCompany: 
				begin
					Outline(RetInStr(686), true, 0);{Enter your company.}
					bCR;
					if NewHand^^.NoAutoCapital then
						LettersPrompt(': ', '', 30, false, false, false, char(0))
					else
						LettersPrompt(': ', '', 30, false, false, true, char(0));
					quiz := CheckCompany;
				end;
				CheckCompany: 
				begin
					if not NewHand^^.NoAutoCapital then
						DoCapsName(curPrompt);
					thisUser.Company := CurPrompt;
					Quiz := Q60;
					GoHome;
				end;
				GetStreet: 
				begin
					Outline(RetInStr(687), true, 0);{Enter your street address (ex. 123 ABC St. #1).}
					bCR;
					if NewHand^^.NoAutoCapital then
						LettersPrompt(': ', '', 30, false, false, false, char(0))
					else
						LettersPrompt(': ', '', 30, false, false, true, char(0));
					quiz := CheckStreet;
				end;
				CheckStreet: 
				begin
					if length(curPrompt) > 0 then
					begin
						if not NewHand^^.NoAutoCapital then
							DoCapsName(curPrompt);
						thisUser.street := CurPrompt;
						Quiz := Q60;
						GoHome;
					end
					else
					begin
						OutLine(RetInStr(688), true, 0);{Please enter an address.}
						bCR;
						NumRptPrompt := NumRptPrompt - 1;
						if ((NumRptPrompt <> 0) and (crossint8 <> 15)) or (crossint8 = 15) then
							Quiz := GetStreet
						else
							HangupAndReset;
					end;
				end;
				GetCity: 
				begin
					Outline(RetInStr(689), true, 0);{Enter your city.}
					bCR;
					if NewHand^^.NoAutoCapital then
						LettersPrompt(': ', '', 30, false, false, false, char(0))
					else
						LettersPrompt(': ', '', 30, false, false, true, char(0));
					quiz := CheckCity;
				end;
				CheckCity: 
				begin
					if length(curPrompt) > 0 then
					begin
						if not NewHand^^.NoAutoCapital then
							DoCapsName(curPrompt);
						thisUser.City := CurPrompt;
						Quiz := Q60;
						GoHome;
					end
					else
					begin
						OutLine(RetInStr(690), true, 0);{Please enter your city.}
						bCR;
						NumRptPrompt := NumRptPrompt - 1;
						if ((NumRptPrompt <> 0) and (crossint8 <> 15)) or (crossint8 = 15) then
							Quiz := GetCity
						else
							HangupAndReset;
					end;
				end;
				GetState: 
				begin
					Outline(RetInStr(691), true, 0);{Enter your state (ex. CA).}
					bCR;
					if NewHand^^.NoAutoCapital then
						LettersPrompt(': ', '', 6, false, false, false, char(0))
					else
						LettersPrompt(': ', '', 6, false, false, true, char(0));
					quiz := CheckState;
				end;
				CheckState: 
				begin
					if length(curPrompt) > 1 then
					begin
						thisUser.state := CurPrompt;
						Quiz := Q60;
						GoHome;
					end
					else
					begin
						OutLine(RetInStr(692), true, 0);{Please enter your state.}
						bCR;
						NumRptPrompt := NumRptPrompt - 1;
						if ((NumRptPrompt <> 0) and (crossint8 <> 15)) or (crossint8 = 15) then
							Quiz := GetState
						else
							HangupAndReset;
					end;
				end;
				GetZip: 
				begin
					Outline(RetInStr(693), true, 0);{Enter your zip code (ex. 90000-0000).}
					bCR;
					LettersPrompt(': ', '', 10, false, false, false, char(0));
					quiz := CheckZip;
				end;
				CheckZip: 
				begin
					if length(curPrompt) > 0 then
					begin
						thisUser.Zip := CurPrompt;
						Quiz := Q60;
						GoHome;
					end
					else
					begin
						OutLine(RetInStr(694), true, 0);{Please enter your zip code.}
						bCR;
						NumRptPrompt := NumRptPrompt - 1;
						if ((NumRptPrompt <> 0) and (crossint8 <> 15)) or (crossint8 = 15) then
							Quiz := GetZip
						else
							HangupAndReset;
					end;
				end;
				GetCountry: 
				begin
					Outline(RetInStr(695), true, 0);{Enter your country (ex. USA).}
					bCR;
					LettersPrompt(': ', '', 10, false, false, false, char(0));
					quiz := CheckCountry;
				end;
				CheckCountry: 
				begin
					if length(curPrompt) > 0 then
					begin
						thisUser.Country := CurPrompt;
						Quiz := Q60;
						GoHome;
					end
					else
					begin
						OutLine(RetInStr(696), true, 0);{Please enter your country.}
						bCR;
						NumRptPrompt := NumRptPrompt - 1;
						if ((NumRptPrompt <> 0) and (crossint8 <> 15)) or (crossint8 = 15) then
							Quiz := GetCountry
						else
							HangupAndReset;
					end;
				end;
				GetMF1: 
				begin
					Outline(newHand^^.SysOpText[1], true, 0);
					bCR;
					LettersPrompt(': ', '', 60, false, false, false, char(0));
					quiz := CheckMF1;
				end;
				CheckMF1: 
				begin
					if length(curPrompt) > 0 then
					begin
						thisUser.MiscField1 := CurPrompt;
						Quiz := Q60;
						GoHome;
					end
					else
					begin
						OutLine(RetInStr(697), true, 0);{Please answer the question.}
						bCR;
						NumRptPrompt := NumRptPrompt - 1;
						if ((NumRptPrompt <> 0) and (crossint8 <> 15)) or (crossint8 = 15) then
							Quiz := GetMF1
						else
							HangupAndReset;
					end;
				end;
				GetMF2: 
				begin
					Outline(newHand^^.SysOpText[2], true, 0);
					bCR;
					LettersPrompt(': ', '', 60, false, false, false, char(0));
					quiz := CheckMF2;
				end;
				CheckMF2: 
				begin
					if length(curPrompt) > 0 then
					begin
						thisUser.MiscField2 := CurPrompt;
						Quiz := Q60;
						GoHome;
					end
					else
					begin
						OutLine(RetInStr(697), true, 0);{Please answer the question.}
						bCR;
						NumRptPrompt := NumRptPrompt - 1;
						if ((NumRptPrompt <> 0) and (crossint8 <> 15)) or (crossint8 = 15) then
							Quiz := GetMF2
						else
							HangupAndReset;
					end;
				end;
				GetMF3: 
				begin
					Outline(newHand^^.SysOpText[3], true, 0);
					bCR;
					LettersPrompt(': ', '', 60, false, false, false, char(0));
					quiz := CheckMF3;
				end;
				CheckMF3: 
				begin
					if length(curPrompt) > 0 then
					begin
						thisUser.MiscField3 := CurPrompt;
						Quiz := Q60;
						GoHome;
					end
					else
					begin
						OutLine(RetInStr(697), true, 0);{Please answer the question.}
						bCR;
						NumRptPrompt := NumRptPrompt - 1;
						if ((NumRptPrompt <> 0) and (crossint8 <> 15)) or (crossint8 = 15) then
							Quiz := GetMF3
						else
							HangupAndReset;
					end;
				end;
				GetBirthdate: 
				begin
					bCR;
					LettersPrompt(RetInStr(698), '', -1, false, false, true, char(0));{Enter Your Birthdate (MM/DD/YY): }
					quiz := CheckBirthDate;
				end;
				CheckBirthDate: 
				begin
					StringToNum(copy(curprompt, 1, 2), tempint);
					thisUser.birthMonth := char(tempInt);
					StringToNum(copy(curprompt, 4, 2), tempInt);
					thisUser.birthDay := char(tempInt);
					StringToNum(copy(curprompt, 7, 2), tempInt);
					thisUser.birthYear := char(tempInt);
					yearsOld(thisUser);
					quiz := Q60;
					GoHome;
				end;
				GetComputer: 
				begin
					OutLine(RetInStr(699), true, 0);{Enter your computer type.  (Max. 23 Chars)}
					bCR;
					LettersPrompt(': ', '', 23, false, false, false, char(13));
					Quiz := CheckComputer;
				end;
				CheckComputer: 
				begin
					if length(curPrompt) > 0 then
					begin
						thisUser.ComputerType := CurPrompt;
						Quiz := Q60;
						GoHome;
					end
					else
					begin
						OutLine('Please enter a computer type.', true, 0);
						bCR;
						NumRptPrompt := NumRptPrompt - 1;
						if ((NumRptPrompt <> 0) and (crossint8 <> 15)) or (crossint8 = 15) then
							Quiz := GetComputer
						else
							HangupAndReset;
					end;
				end;
				GetWidth: 
				begin
					OutLine(RetInStr(700), true, 0);{How wide is your screen (in CHARACTERS, <CR>=80)?}
					bCR;
					Numbersprompt(': ', '', 199, 1);
					Quiz := CheckWidth;
				end;
				CheckWidth: 
				begin
					if length(curPrompt) = 0 then
						thisUser.scrnWdth := 80
					else
					begin
						StringToNum(curprompt, tempInt);
						if tempInt < 20 then
							tempInt := 20
						else
							thisUser.scrnWdth := tempInt;
					end;
					Quiz := Q60;
					GoHome;
				end;
				GetHght: 
				begin
					OutLine(RetInStr(701), true, 0);{How tall is your screen (in LINES, <CR>=24)?}
					bCR;
					NumbersPrompt(': ', '', 90, 1);
					Quiz := CheckHght;
				end;
				CheckHght: 
				begin
					if length(curPrompt) = 0 then
						thisUser.scrnHght := 24
					else
					begin
						StringToNum(curprompt, tempInt);
						thisUser.scrnHght := tempInt;
					end;
					if thisUser.scrnHght < 5 then
						thisUser.scrnHght := 5;
					Quiz := Q60;
					GoHome;
				end;
				GetAnsi: 
				begin
					bCR;
					OutANSItest;
					bCR;
					OutLine(RetInStr(702), false, 0);  {Is the above line either colored, italicized,}
					bCR;
					NewYesNoQuestion(RetInStr(703));	{intense, inversed, or blinking? }
					Quiz := CheckAnsi;
				end;
				CheckAnsi: 
				begin
					if curPrompt = 'Y' then
					begin
						thisUser.TerminalType := 1;
						thisUser.ChatANSI := true;
					end
					else
					begin
						thisUser.TerminalType := 0;
						thisUser.ChatANSI := false;
					end;
					bCR;
					if thisUser.TerminalType = 1 then
					begin
						NewYesNoQuestion(RetInStr(704));  {Do you want color? }
					end
					else
						curprompt := 'N';
					Quiz := CheckAnsiColor;
				end;
				CheckAnsiColor: 
				begin
					if curPrompt = 'Y' then
						thisUser.ColorTerminal := true
					else
						thisUser.ColorTerminal := false;
					Quiz := Q60;
					GoHome;
				end;
				GetClearing: 
				begin
					bCR;
					NewYesNoQuestion(RetInStr(705));	{Do you want screen clearing? }
					Quiz := CheckClearing;
				end;
				CheckClearing: 
				begin
					if curPrompt = 'Y' then
						thisUser.screenClears := true
					else
						thisUser.screenClears := false;
					Quiz := Q60;
					GoHome;
				end;
				GetPause: 
				begin
					bCR;
					NewYesNoQuestion(RetInStr(706));	{Do you want pause each screenful? }
					Quiz := CheckPause;
				end;
				CheckPause: 
				begin
					if curPrompt = 'Y' then
						thisUser.pauseScreen := true
					else
						thisUser.pauseScreen := false;
					Quiz := Q60;
					GoHome;
				end;
				GetColumns: 
				begin
					bCR;
					NewYesNoQuestion(RetInStr(707));	{Would you like lists displayed in 2 columns?  }
					Quiz := CheckColumns;
				end;
				CheckColumns: 
				begin
					if curPrompt = 'Y' then
						thisUser.columns := true
					else
						thisUser.columns := false;
					Quiz := Q60;
					GoHome;
				end;
				ShowEntries: 
				begin
					PrintUserEntry;
					bCR;
					bCR;
					LettersPrompt(RetInStr(708), globalStr, 1, true, false, true, char(0));{Is The Above Correct?  [Y]es or Field to change? }
					curPrompt := '';
					Quiz := CheckEntries;
				end;
				CheckEntries: 
				begin
					crossint8 := 8;
					if length(curPrompt) > 0 then
					begin
						CurPrompt[1] := WhatKey(curPrompt[1]);
						case CurPrompt[1] of
							'Y': 
							begin
								Quiz := CheckPass;
							end;
							'A': 
							begin
								CrossInt7 := 2;
								boardSection := AskQuestions;
							end;
							'B': 
							begin
								CrossInt7 := 3;
								boardSection := AskQuestions;
							end;
							'C': 
							begin
								CrossInt7 := 4;
								boardSection := AskQuestions;
							end;
							'D': 
							begin
								CrossInt7 := 5;
								boardSection := AskQuestions;
							end;
							'E': 
							begin
								CrossInt7 := 6;
								boardSection := AskQuestions;
							end;
							'F': 
							begin
								CrossInt7 := 7;
								boardSection := AskQuestions;
							end;
							'G': 
							begin
								CrossInt7 := 8;
								boardSection := AskQuestions;
							end;
							'H': 
							begin
								CrossInt7 := 9;
								boardSection := AskQuestions;
							end;
							'I': 
							begin
								CrossInt7 := 10;
								boardSection := AskQuestions;
							end;
							'J': 
							begin
								CrossInt7 := 11;
								boardSection := AskQuestions;
							end;
							'K': 
							begin
								CrossInt7 := 12;
								boardSection := AskQuestions;
							end;
							'L': 
							begin
								CrossInt7 := 13;
								boardSection := AskQuestions;
							end;
							'M': 
							begin
								CrossInt7 := 14;
								boardSection := AskQuestions;
							end;
							'N': 
							begin
								CrossInt7 := 15;
								boardSection := AskQuestions;
							end;
							'O': 
							begin
								CrossInt7 := 16;
								boardSection := AskQuestions;
							end;
							'P': 
							begin
								CrossInt7 := 17;
								boardSection := AskQuestions;
							end;
							'Q': 
							begin
								CrossInt7 := 19;
								boardSection := AskQuestions;
							end;
							'R': 
							begin
								CrossInt7 := 18;
								boardSection := AskQuestions;
							end;
							'S': 
							begin
								CrossInt7 := 20;
								boardSection := AskQuestions;
							end;
							'T': 
							begin
								CrossInt7 := 21;
								boardSection := AskQuestions;
							end;
							'U': 
							begin
								CrossInt7 := 22;
								boardSection := AskQuestions;
							end;
							'V': 
							begin
								CrossInt7 := 23;
								boardSection := AskQuestions;
							end;
							otherwise
							begin
								Quiz := ShowEntries;
							end;
						end;
					end
					else
						Quiz := ShowEntries;
				end;
				CheckPass: {PassQuest:}
				begin
					GetTime(TempDate);
					NumToString(tempDate.second, tempString);
					if length(tempString) < 2 then
						tempString := concat(tempString, '0');
					tempInt := (ABS(RANDOM) mod 25) + 1;
					TempString[0] := char(6);
					TempString[3] := char(tempInt + 65);
					tempInt := (ABS(RANDOM) mod 25) + 1;
					TempString[4] := char(tempInt + 65);
					tempInt := (ABS(RANDOM) mod 25) + 1;
					TempString[5] := char(tempInt + 65);
					tempInt := (ABS(RANDOM) mod 25) + 1;
					TempString[6] := char(tempInt + 65);
					OutLine(concat(RetInStr(709), tempString), true, 0);		{Random password: }
					bCR;
					bCR;
					ThisUser.password := tempString;
					NewYesNoQuestion(RetInStr(710));	{Enter new password (Y/N)? }
					Quiz := EnterPass;
					thisUser.userNum := -1;
				end;
				EnterPass: {NewPassword:}
				begin
					if (CurPrompt = 'Y') then
					begin
						OutLine(RetInStr(711), true, 0);		{Please enter a password, 3-9 chars.}
						bCR;
						LettersPrompt(': ', '', 9, false, false, true, char(0));
					end
					else
						curPrompt := thisUser.password;
					Quiz := ShowInfo;
				end;
				ShowInfo: {GiveInfo:}
				begin
					if length(curPrompt) > 2 then
					begin
						OutLine(RetInStr(712), true, 0);			{Please wait...}
						if thisUser.userNum = -1 then
						begin
							thisUser.Password := curPrompt;
							if myUsers = nil then
							begin
								myUsers := UListHand(NewHandle(0));
								MoveHHi(handle(myUsers));
								HNoPurge(handle(myUsers));
							end;
							tempshort := 1;
							gotIt := false;
							while (tempshort <= numUserRecs) and not gotIt do
							begin
								if myUsers^^[tempShort - 1].dltd then
									gotIt := true
								else
									tempShort := tempShort + 1;
							end;
							if not gotIt then
							begin
								SetHandleSize(handle(myusers), getHandleSize(handle(myUsers)) + SizeOf(ULR));
								numUserRecs := numUserRecs + 1;
								tempShort := numUserRecs;
							end;
							thisUser.userNum := tempShort;
							if newhand^^.handle then
								thisUser.UserName := thisUser.Alias
							else
								thisUser.UserName := thisUser.realName;
							myUsers^^[tempshort - 1].UName := thisUser.UserName;
							myUsers^^[tempshort - 1].dltd := false;
							myUsers^^[tempshort - 1].real := thisUser.realName;
							GetDateTime(myUsers^^[tempshort - 1].last);
							myUsers^^[tempshort - 1].SL := thisUser.SL;
							myUsers^^[tempshort - 1].DSL := thisUser.DSL;
							myUsers^^[tempshort - 1].first := thisUser.firstOn;
							myUsers^^[tempshort - 1].age := thisUser.age;
							for i := 1 to 26 do
								myUsers^^[tempshort - 1].AccessLetter[i] := thisUser.AccessLetter[i];
							InitSystHand^^.numUsers := InitSystHand^^.numUsers + 1;
							thisUser.signature := thisUser.userName;
							doSystRec(true);
							WriteUser(thisUser);
						end;
						timebegin := tickCount;
						bCR;
						NumToString(thisUser.userNum, tempString);
						OutLine(concat(RetInStr(713), tempString, '.'), true, 0);		{Your user number is }
						OutLine(concat(RetInStr(714), thisUser.password, ''''), true, 0);	{Your password is '}
						bCR;
						bCR;
						OutLine(RetInStr(715), false, 0);	{Please write down this information, and}
						OutLine(RetInStr(716), true, 0);		{re-enter your password for verification.}
						OutLine(RetInStr(717), true, 0);		{You will need to know this password in}
						OutLine(RetInStr(718), true, 0);{order to log on again.}
						bCR;
						bCR;
						LettersPrompt(RetInStr(18), '', 9, false, false, true, char(0));{order to log on again.}
						Quiz := NewTrans;
					end
					else
					begin
						OutLine(RetInStr(719), true, 0);{Your password must be more than three characters.}
						Quiz := EnterPass;
						curPrompt := 'Y';
					end;
				end;
				NewTrans: {NewTransition:}
				begin
					if CurPrompt = thisUser.password then
					begin
						GetDateTime(templong);
						IUTimeString(tempLong, true, tempstring2);
						tempstring := concat(getDate(-1), ' ', tempstring2);
						NumToString(currentBaud, tempString2);
						sysopLog(concat(RetInStr(356), tempString2, '  ', tempString), 0);	{###   NEW USER  }
						bCR;
						if not newHand^^.NoVFeedback then
						begin
							if readTextFile('Feedback', 1, false) then
							begin
								if thisUser.TerminalType = 1 then
									noPause := true;
								boardAction := ListText;
								ListTextFile;
							end
							else
								OutLine(RetInStr(720), true, 0);{Can''t find ''Feedback'' file.}
						end;
						Quiz := NewTwoTrans;
					end
					else
					begin
						Quiz := ShowInfo;
						OutLine(RetInStr(721), true, 0);	{Please enter your password correctly.}
						curPrompt := thisUser.password;
					end;
				end;
				NewTwoTrans: {TwoTrans:}
				begin
					for i := 1 to 40 do
						AddressBook^^[i] := char(0);
					DoAddressBooks(AddressBook, thisUser.UserNum, true);
					if not newHand^^.NoVFeedback then
					begin
						CurPrompt := '1';
						if FindUser(curPrompt, tempuser) then
						begin
							BoardSection := EMail;
							EmailDo := EmailOne;
							CurPrompt := '1';
							sentAnon := false;
							callFMail := false;
							newFeed := true;
						end;
					end
					else
					begin
						newFeed := false;
						BoardSection := Logon;
						LogonStage := Password;
						curPrompt := thisUser.Password;
						RealSL := thisUser.SL;
					end;
				end;
			end;
		end;
	end;
end.