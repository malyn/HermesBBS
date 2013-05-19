{ Segments: HUtils6_1, HUtils6_2 }
unit HUtils6;

interface
	uses
		AppleTalk, ADSP, Serial, Sound, Notification, PPCToolbox, Processes, EPPC, AppleEvents, TCPTypes, NewUser, Initial, LoadAndSave, NodePrefs2, NodePrefs, SystemPrefs2, SystemPrefs, Message_Editor, User, Terminal, inpOut4, inpOut3, Quoter, inpOut, MessNTextOutput, MessageSearcher, Chatroom, FileTrans3, FileTrans2, FileTrans, HermesUtils, HUtilsOne, HUtils2, HUtils3, HUtils4;

	procedure SetBookmark;

implementation

{$S HUtils6_1}
	procedure DoCatchup;
		var
			WelcomeName, tempstring, tempString2, tempString3, tempString4, ts, MsgLine, fName: str255;
			tempInt, tempLong, col, tl: longInt;
			tempDate, tempDate2, tempDate3: DateTimeRec;
			tempChar: char;
			tempShort, i, LastRef, tempnumem, tempInt2, tempInt3, w, index, b, wnode, totEm, x: integer;
			teEM, tempEMa: eMailRec;
			tempBool, tb2, gotit, FoundUser: boolean;
			myCPB: CInfoPBRec;
			myHPB: HParamBlockRec;
			aUser: UserRec;
			s31: string[31];
			s26: string[26];
	begin
		with curglobs^ do
		begin
			begin
				case crossint9 of
					0: {//CATCHUP}
					begin
						OutLine(RetInStr(257), true, 0);			{Newscan for all conferences set to: }
						GetDateTime(templong);
						for i := 1 to 20 do
						begin
							for x := 1 to 50 do
							begin
								thisUser.LastMsgs[i, x] := templong;
							end;
						end;
						OutLine(GetDate(templong), false, 0);
						GoHome;
					end;
					15: {//QSCAN}
					begin
						OutLine(RetInStr(204), true, 0);	{Enter message "Newscan Date" in the format:}
						OutLine(RetInStr(122), true, 0);	{ MM/DD/YY}
						bCR;
						LettersPrompt(': ', '', -1, true, false, false, char(0));
						crossint9 := 17;
					end;
					17: {End //QSCAN}
					begin
						if length(curPrompt) = 8 then
						begin
							GetDateTime(templong);
							Secs2Date(templong, tempdate);
							StringToNum(copy(curprompt, 1, 2), tempint);
							tempDate.month := tempInt;
							StringToNum(copy(curprompt, 4, 2), tempInt);
							tempDate.day := tempInt;
							StringToNum(copy(curprompt, 7, 2), tempInt);
							if tempint > 80 then
								tempDate.year := tempint + 1900
							else
								tempDate.year := tempint + 2000;
							tempdate.hour := 0;
							tempdate.minute := 1;
							tempdate.second := 0;
							Date2Secs(tempDate, templong);
							for i := 1 to 20 do
							begin
								for x := 1 to 50 do
								begin
									thisUser.LastMsgs[i, x] := templong;
								end;
							end;
							Outline(concat(RetInStr(257), getDate(templong)), true, 0);	{Newscan for all conferences set to: }
						end
						else
							OutLine(RetInStr(147), true, 2);{Newscan date not reset.}
						GoHome;
					end;
					20: {Password Change}
					begin
						OutLine(RetInStr(634), true, 0);	{You must now enter your current password.}
						bCR;
						LettersPrompt(': ', '', 9, false, false, true, char(0));
						crossint9 := 21;
					end;
					21: 
						if curPrompt = thisUser.password then
						begin
							bCR;
							OutLine(RetInStr(711), true, 0);	{Enter your new password, 3 to 9 characters long.}
							bCR;
							LettersPrompt(': ', '', 9, false, false, true, 'X');
							crossint9 := 22;
						end
						else
						begin
							OutLine('Incorrect.', true, 0);
							bCR;
							bCR;
							crossint9 := 24;
						end;
					22: 
						if length(curPrompt) < 3 then
						begin
							Outline(RetInStr(719), true, 0);	{Your password must be at least 3 characters.}
							bCR;
							curPrompt := thisUser.password;
							crossint9 := 21;
						end
						else
						begin
							EnteredPass := CurPrompt;
							OutLine(RetInStr(243), true, 0);	{Repeat password for verification.}
							bCR;
							LettersPrompt(': ', '', 9, false, false, true, 'X');
							crossint9 := 23;
						end;
					23: 
						if EnteredPass = CurPrompt then
						begin
							thisUser.password := CurPrompt;
							OutLine(RetInStr(244), true, 0);	{Password changed.}
							sysopLog('      Changed Password.', 0);
							bCR;
							bCR;
							crossint9 := 24;
						end
						else
						begin
							OutLine(RetInStr(635), true, 0);	{VERIFY FAILED.}
							OutLine(RetInStr(245), true, 0);	{Password not changed.}
							bCR;
							bCR;
							crossint9 := 24;
						end;
					24: {End Password Change}
					begin
						curPrompt := 'N';
						BoardSection := Logon;
						LogonStage := Trans3;
					end;
					otherwise
				end;
			end;
		end;
	end;

	procedure DoLimDate;
		var
			WelcomeName, tempstring, tempString2, tempString3, tempString4, ts, MsgLine, fName: str255;
			tempInt, tempLong, col, tl: longInt;
			tempDate, tempDate2, tempDate3: DateTimeRec;
			tempChar: char;
			tempShort, i, LastRef, tempnumem, tempInt2, tempInt3, w, index, b, wnode, totEm, x: integer;
			teEM, tempEMa: eMailRec;
			tempBool, tb2, gotit, FoundUser: boolean;
			myCPB: CInfoPBRec;
			myHPB: HParamBlockRec;
			aUser: UserRec;
			s31: string[31];
			s26: string[26];
	begin
		with curglobs^ do
		begin
			if length(curPrompt) = 8 then
			begin
				Secs2Date(lastFScan, tempDate);
				StringToNum(copy(curprompt, 1, 2), tempint);
				tempDate.month := tempInt;
				StringToNum(copy(curprompt, 4, 2), tempInt);
				tempDate.day := tempInt;
				StringToNum(copy(curprompt, 7, 2), tempInt);
				if tempint > 80 then
					tempDate.year := tempint + 1900
				else
					tempDate.year := tempint + 2000;
				tempdate.hour := 0;
				tempdate.minute := 0;
				tempdate.second := 0;
				Date2Secs(tempDate, lastFScan);
				Outline(concat(RetInStr(12), getDate(LastFScan)), true, 0);
			end
			else
				OutLine(RetInStr(742), true, 2);{Limiting date not changed.}
			GoHome;
		end;
	end;

	procedure DoLogonStuff;
		var
			WelcomeName, tempstring, tempString2, tempString3, tempString4, ts, MsgLine, fName: str255;
			tempInt, tempLong, col, tl: longInt;
			tempDate, tempDate2, tempDate3: DateTimeRec;
			tempChar: char;
			tempShort, i, LastRef, tempnumem, tempInt2, tempInt3, w, index, b, wnode, totEm, x: integer;
			teEM, tempEMa: eMailRec;
			tempBool, tb2, gotit, FoundUser: boolean;
			myCPB: CInfoPBRec;
			myHPB: HParamBlockRec;
			aUser: UserRec;
			s31: string[31];
			s26: string[26];
	begin
		with curglobs^ do
		begin
			LogonStage := succ(LogonStage);
			case LogonStage of
				Name: 
				begin
					InitUserRec;
					if gettingANSI then
						ANSIcode('0;37;40m');
					bCR;
					thisUser.UserNum := -1;
					thisUser.AlternateText := WelcomeAlternate;
					OutLine(RetInStr(13), false, 0);
					bCR;
					if isTwoByteScript then
						LettersPrompt(RetInStr(14), '', 31, false, false, false, char(0))
					else
						LettersPrompt(RetInStr(14), '', 31, false, false, true, char(0));
				end;
				CheckName: 
				begin
					if EqualString(CurPrompt, RetInStr(15), false, false) then
					begin
						crossint8 := 7;
						crossint7 := 1;
						InitUserRec;
						Quiz := Q60;
						BoardSection := AskQuestions;
					end
					else
					begin
						if (curPrompt[length(curPrompt)] = '*') then
							delete(curPrompt, length(curPrompt), 1);
						tempBool := FindUser(CurPrompt, tempUser);
						tb2 := UserOnSystem(tempUser.userName);
						if not tempBool then
							tb2 := false;

								(* Check See if they have logged on and not sent Feedback *)
						if (tempUser.TotalLogons = 0) and (tempUser.EMailSent = 0) and (not NewHand^^.NoVFeedback) then
						begin
							tempUser.DeletedUser := true;
							if tempUser.UserName[1] <> '~' then
								TempUser.UserName := concat('~', TempUser.UserName);
							if TempUser.Alias[1] <> '•' then
								TempUser.alias := TempUser.UserName
							else
								TempUser.RealName := TempUser.UserName;
							WriteUser(tempUser);
						end;
						if tempBool and not tempUser.DeletedUser and not tb2 then
						begin
							thisUser := tempUser;
							DoAddressBooks(AddressBook, thisUser.UserNum, false);
							if thisUser.ChatANSI then
								TheChat.ChatMode := ANSIChat
							else
								TheChat.ChatMode := TextChat;
							statChanged := true;
						end
						else
						begin
							if tb2 then
								OutLine(RetInStr(16), false, -1)
							else
								OutLine(RetInStr(17), false, -1);
							bCR;
							thisUser.userNum := -1;
							bCR;
							NumRptPrompt := NumRptPrompt - 1;
							if numRptPrompt <> 0 then
							begin
								OutLine(RetInStr(13), false, 2);
								bCR;
								LettersPrompt(RetInStr(14), '', 31, false, false, true, char(0));
								LogonStage := Name;
							end
							else
							begin
								HangupAndReset;
							end;
						end;
					end;
				end;
				Password: 
				begin
					RealSL := thisUser.SL;
					if isTwoByteScript then
						LettersPrompt(RetInStr(18), '', 9, false, false, false, 'X')
					else
						LettersPrompt(RetInStr(18), '', 9, false, false, true, 'X');
				end;
				SysPass: 
				begin
					EnteredPass := CurPrompt;
					if (thisUser.SL = 255) and not SysopLogon then
					begin
						if isTwoByteScript then
							LettersPrompt(RetInStr(20), '', 9, false, false, false, 'X')
						else
							LettersPrompt(RetInStr(20), '', 9, false, false, true, 'X');
					end;
				end;
				ChkSysPass: 
				begin
					if (thisUser.SL = 255) and not SysopLogon then
					begin
						if not EqualString(curPrompt, InitSystHand^^.overridePass, false, false) then
							EnteredPass := '';
					end;
				end;
				CheckStuff: 
				begin
					if (enteredPass = thisUser.password) then
					begin
						if thisUser.AutoSense then
							if gettingANSI then
							begin
								thisUser.ColorTerminal := true;
								thisUser.TerminalType := 1;
							end
							else
							begin
								thisUser.ColorTerminal := false;
								thisUser.TerminalType := 0;
							end;

						validLogon := true;
						thisUser.totalLogons := thisUser.totalLogons + 1;
						thisUser.lastBaud := curBaudNote;
						timebegin := tickCount;
						GetDateTime(tempLong);
						getTime(tempDate);
						Secs2Date(thisUser.lastOn, tempdate2);
						if tempDate.day = tempDate2.day then
							thisuser.OnToday := thisUser.OnToday + 1
						else
						begin
							thisUser.onToday := 1;
							thisUser.minOnToday := 0;
							thisUser.EMsentToday := 0;
							thisUser.MPostedToday := 0;
							thisUser.NumUlToday := 0;
							thisUser.NumDlToday := 0;
							thisUser.KBULToday := 0;
							thisUser.KBDLToday := 0;
							thisUser.BonusTime := 0;
						end;
						sendLogOff := thisUser.NotifyLogon;
						if thisUser.useDayorCall and (thisuser.BonusTime > 0) then
							extraTime := thisUser.BonusTime;
						thisUser.BonusTime := 0;
						if not thisUser.cosysop then
						begin
							if thisUser.CallsPrDay < (thisUser.onToday) then
							begin
								bCR;
								OutLine(RetInStr(21), false, -1);
								LogThis(StringOf(thisUser.Username, ' #', thisUser.UserNum : 0, RetInStr(286), ' Node #', ActiveNode : 0), 0);{ tried logging on.}
								WriteUser(thisUser);
								thisUser.UserNum := -1;
								delay(60, templong);
								HangupAndReset;
							end;
							if ThisUser.SL < SecLevel then
							begin
								bCR;
								OutLine(RetInStr(605), false, -1);	{Security Level Is To Low For This Node.}
								LogThis(StringOf(thisUser.Username, ' #', thisUser.UserNum : 0, RetInStr(286), ' Node #', ActiveNode : 0), 0);
								WriteUser(thisUser);
								thisUser.UserNum := -1;
								delay(60, templong);
								HangupAndReset;
							end;
							if (NodeRest <> char(0)) and not (thisUser.AccessLetter[(byte(NodeRest) - byte(64))]) then
							begin
								bCR;
								OutLine(RetInStr(606), false, -1);	{You Do Not Have Access To This Node.}
								LogThis(StringOf(thisUser.Username, ' #', thisUser.UserNum : 0, RetInStr(286), ' Node #', ActiveNode : 0), 0);
								WriteUser(thisUser);
								thisUser.UserNum := -1;
								delay(60, templong);
								HangupAndReset;
							end;
							if not userallowed then
							begin
								bCR;
								OutLine('You do not have access to the BBS at this time.', false, -1);
								LogThis(StringOf(thisUser.Username, ' #', thisUser.UserNum : 0, ' Restricted Hours - Node #', ActiveNode : 0), 0);
								thisUser.UserNum := -1;
								delay(60, templong);
								HangupAndReset;
							end;
						end;
						if thisUser.UserNum > 0 then
						begin
							if thisUser.userNum > 1 then
							begin
								InitSystHand^^.numCalls := InitSystHand^^.numCalls + 1;
								InitSystHand^^.UnUsed1 := InitSystHand^^.UnUsed1 + 1;
								callno := InitSystHand^^.NumCalls;
								doSystRec(true);
							end;
							getDateTime(templong);
							NumToString(InitSystHand^^.numCalls, tempString);
							tempString := concat(tempString, ':  ', thisUser.userName, ' #');
							NumToString(thisUser.UserNum, tempString2);
							tempString := concat(tempString, tempString2, '   ');
							IUTimeString(tempLong, false, tempstring2);
							tempString := concat(tempString, tempString2, ' ');
							tempString := concat(tempString, getDate(-1), ' ');
							tempString := concat(tempString, curBaudNote);
							NumToString(thisUser.ontoday, tempstring2);
							tempString := concat(tempstring, ' - ', tempstring2);
							if InitSystHand^^.numNodes > 1 then
								tempstring := StringOf(tempstring, '  Node #', ActiveNode : 0);
							sysopLog('', 0);
							sysopLog(tempString, 1);
						end;
					end
					else
					begin
						bCR;
						OutLine(RetInStr(22), false, -1);
						if sysopLogon then
							SysBeep(10)
						else
							OutChr(char(7));
						bCR;
						sysopLog(StringOf(RetInStr(287), thisUser.UserName, ' #', thisUser.UserNum : 0, ' Tried PW: ', EnteredPass, ' Node #', ActiveNode : 0), 0);	{### ILLEGAL LOGON for }
						thisUser.illegalLogons := thisUser.illegalLogons + 1;
						WriteUser(thisUser);
						thisUser.UserNum := -1;
						NumRptPrompt := NumRptPrompt - 1;
						if NumRptPrompt > 0 then
							LogonStage := Welcome
						else
						begin
							HangupAndReset;
						end;
					end;
				end;
				Hello: 
				begin
					crossint9 := 1;
					crossint8 := 15;
					crossint6 := 0;
					GetDateTime(templong);
					NumToString(activeNode, tempString);
					if gBBSwindows[activeNode]^.ansiPort <> nil then
						SetWTitle(gBBSwindows[activeNode]^.ansiPort, concat(tempString, ': ', thisUser.userName));
					lastFScan := thisUser.lastFileScan;
					statChanged := true;
					OutLine('', false, 0);
					ClearScreen;
					if ReadTextFile('Log On', 1, false) then
					begin
						if thisUser.TerminalType = 1 then
							noPause := true;
						BoardAction := ListText;
						ListTextFile;
					end;
					if not sysopLogon and sendLogoff then
						MultinodeOutput(concat('< ', thisUser.userName, RetInStr(41), ' >'));
				end;
				CheckInfo: 
					case crossint9 of
						1: 
						begin
							if (newhand^^.handle) and (thisUser.username = '•') then
							begin
								quiz := GetAlias;
								boardsection := NewUser;
								if crossint6 = 0 then
								begin
									OutLine(RetInStr(745), true, 2);{The SysOp is requesting the following information:}
									bCR;
									crossint6 := 1;
								end;
							end
							else
							begin
								crossint9 := crossint9 + 1;
								boardsection := Logon;
								LogonStage := Hello;
							end;
						end;
						2: 
						begin
							if (newhand^^.Realname) and (thisUser.realname = '•') then
							begin
								quiz := GetReal;
								boardsection := NewUser;
								if crossint6 = 0 then
								begin
									OutLine(RetInStr(745), true, 2);{The SysOp is requesting the following information:}
									bCR;
									crossint6 := 1;
								end;
							end
							else
							begin
								crossint9 := crossint9 + 1;
								boardsection := Logon;
								LogonStage := Hello;
							end;
						end;
						3: 
						begin
							if (newhand^^.VoicePN) and (thisUser.phone = '•') then
							begin
								quiz := GetVoice;
								boardsection := NewUser;
								if crossint6 = 0 then
								begin
									OutLine(RetInStr(745), true, 2);{The SysOp is requesting the following information:}
									bCR;
									crossint6 := 1;
								end;
							end
							else
							begin
								crossint9 := crossint9 + 1;
								boardsection := Logon;
								LogonStage := Hello;
							end;
						end;
						4: 
						begin
							if (newhand^^.DataPN) and (thisUser.dataphone = '•') then
							begin
								quiz := GetData;
								boardsection := NewUser;
								if crossint6 = 0 then
								begin
									OutLine(RetInStr(745), true, 2);{The SysOp is requesting the following information:}
									bCR;
									crossint6 := 1;
								end;
							end
							else
							begin
								crossint9 := crossint9 + 1;
								boardsection := Logon;
								LogonStage := Hello;
							end;
						end;
						5: 
						begin
							if (newhand^^.Computer) and (thisUser.ComputerType = '•') then
							begin
								quiz := GetComputer;
								boardsection := NewUser;
								if crossint6 = 0 then
								begin
									OutLine(RetInStr(745), true, 2);{The SysOp is requesting the following information:}
									bCR;
									crossint6 := 1;
								end;
							end
							else
							begin
								crossint9 := crossint9 + 1;
								boardsection := Logon;
								LogonStage := Hello;
							end;
						end;
						6: 
						begin
							if (newhand^^.Company) and (thisUser.company = '•') then
							begin
								quiz := GetCompany;
								boardsection := NewUser;
								if crossint6 = 0 then
								begin
									OutLine(RetInStr(745), true, 2);{The SysOp is requesting the following information:}
									bCR;
									crossint6 := 1;
								end;
							end
							else
							begin
								crossint9 := crossint9 + 1;
								boardsection := Logon;
								LogonStage := Hello;
							end;
						end;
						7: 
						begin
							if (newhand^^.Street) and (thisUser.street = '•') then
							begin
								quiz := GetStreet;
								boardsection := NewUser;
								if crossint6 = 0 then
								begin
									OutLine(RetInStr(745), true, 2);{The SysOp is requesting the following information:}
									bCR;
									crossint6 := 1;
								end;
							end
							else
							begin
								crossint9 := crossint9 + 1;
								boardsection := Logon;
								LogonStage := Hello;
							end;
						end;
						8: 
						begin
							if (newhand^^.City) and (thisUser.City = '•') then
							begin
								quiz := GetCity;
								boardsection := NewUser;
								if crossint6 = 0 then
								begin
									OutLine(RetInStr(745), true, 2);{The SysOp is requesting the following information:}
									bCR;
									crossint6 := 1;
								end;
							end
							else
							begin
								crossint9 := crossint9 + 1;
								boardsection := Logon;
								LogonStage := Hello;
							end;
						end;
						9: 
						begin
							if (newhand^^.City) and (thisUser.state = '•') then
							begin
								quiz := GetState;
								boardsection := NewUser;
								if crossint6 = 0 then
								begin
									OutLine(RetInStr(745), true, 2);{The SysOp is requesting the following information:}
									bCR;
									crossint6 := 1;
								end;
							end
							else
							begin
								crossint9 := crossint9 + 1;
								boardsection := Logon;
								LogonStage := Hello;
							end;
						end;
						10: 
						begin
							if (newhand^^.City) and (thisUser.zip = '•') then
							begin
								quiz := GetZip;
								boardsection := NewUser;
								if crossint6 = 0 then
								begin
									OutLine(RetInStr(745), true, 2);{The SysOp is requesting the following information:}
									bCR;
									crossint6 := 1;
								end;
							end
							else
							begin
								crossint9 := crossint9 + 1;
								boardsection := Logon;
								LogonStage := Hello;
							end;
						end;
						11: 
						begin
							if (newhand^^.Country) and (thisUser.country = '•') then
							begin
								quiz := GetCountry;
								boardsection := NewUser;
								if crossint6 = 0 then
								begin
									OutLine(RetInStr(745), true, 2);{The SysOp is requesting the following information:}
									bCR;
									crossint6 := 1;
								end;
							end
							else
							begin
								crossint9 := crossint9 + 1;
								boardsection := Logon;
								LogonStage := Hello;
							end;
						end;
						12: 
						begin
							if (newhand^^.SysOp[1]) and (thisUser.miscField1 = '•') then
							begin
								quiz := GetMF1;
								boardsection := NewUser;
								if crossint6 = 0 then
								begin
									OutLine(RetInStr(745), true, 2);{The SysOp is requesting the following information:}
									bCR;
									crossint6 := 1;
								end;
							end
							else
							begin
								crossint9 := crossint9 + 1;
								boardsection := Logon;
								LogonStage := Hello;
							end;
						end;
						13: 
						begin
							if (newhand^^.SysOp[2]) and (thisUser.miscField2 = '•') then
							begin
								quiz := GetMF2;
								boardsection := NewUser;
								if crossint6 = 0 then
								begin
									OutLine(RetInStr(745), true, 2);{The SysOp is requesting the following information:}
									bCR;
									crossint6 := 1;
								end;
							end
							else
							begin
								crossint9 := crossint9 + 1;
								boardsection := Logon;
								LogonStage := Hello;
							end;
						end;
						14: 
						begin
							if (newhand^^.SysOp[3]) and (thisUser.miscField3 = '•') then
							begin
								quiz := GetMF3;
								boardsection := NewUser;
								if crossint6 = 0 then
								begin
									OutLine(RetInStr(745), true, 2);{The SysOp is requesting the following information:}
									bCR;
									crossint6 := 1;
								end;
							end
							else
							begin
								crossint9 := crossint9 + 1;
								boardsection := Logon;
								LogonStage := Hello;
							end;
						end;
						otherwise
						begin
							crossint8 := 0;
						end;
					end;
				Stats: 
				begin
					if (thisUser.alertOn) and not alerted then
					begin
						if (GetNamedResource('snd ', 'Alert User')) <> nil then
							StartMySound('Alert User', false)
						else
							for i := 1 to 5 do
								SysBeep(1);
						alerted := true;
					end;
					if Menuhand^^.Options[pos('L', MenuCmds), 1] then
					begin
						OutLineC(RetInStr(23), true, 1);
						bCR;
						OutLine(RetInStr(639), true, 0);{Call #    Time    Nd  CT   ##   Username                   Speed}
						OutLine(RetInStr(640), true, 0);{======  ========  ==  ==  ====  =========================  ================}
						bCR;
						if ReadTextFile('Misc:Last Users', 0, true) then
						begin
							if not (thisUser.coSysop) then
							begin
								i := 0;
								if OpenTextSize > 8 then
								begin
									curTextPos := openTextSize;
									repeat
										repeat
											curTextPos := curTextPos - 1;
										until (textHnd^^[curTextPos] = char(13)) or (curTextPos = 0);
										i := i + 1;
									until i = 5;
									curTextPos := curTextPos + 1;
								end;
							end;
							if curTextPos < OpenTextSize then
							begin
								BoardAction := ListText;
								ListTextFile;
							end
							else
							begin
								BoardAction := none;
								OutLine(RetInStr(24), true, 0);
							end;
						end
						else
						begin
							BoardAction := none;
							OutLine(RetInStr(24), true, 0);
						end;
					end;
				end;
				StatAuto: 
				begin
					if InitSystHand^^.numNodes > 1 then
					begin
						tempInt := 0;
						for i := 1 to InitSystHand^^.numNodes do
						begin
							if not (theNodes[i]^.nodeType < 0) and (theNodes[i]^.boardMode = User) and (i <> activeNode) and (theNodes[i]^.thisUser.userNum > 1) then
							begin
								if tempInt = 0 then
								begin
									bCR;
									OutLine(RetInStr(25), true, 0);
									tempint := 1;
									bCR;
								end;
								OutLine(StringOf(RetInStr(743), i : 0, ' : ', theNodes[i]^.thisUser.userName, ' #', theNodes[i]^.thisUser.userNum : 0), true, 0);{Node: }
							end;
						end;
						if tempint = 1 then
							bCR;
					end;
					EnterLastUser;
					bCR;
					bCR;
					if Menuhand^^.Options[pos('A', MenuCmds), 1] then
						ReadAutoMessage;
				end;
				Transition: 
				begin
					bCR;
					bCR;
					OutLine(stringOf(RetInStr(26), thisUser.UserName, ' #', thisUser.UserNum : 0), false, 0);
					OutLine(concat(RetInStr(288), SecLevels^^[thisUser.SL].class), true, 0);{Classification : }
					if thisUser.useDayorCall then
					begin
						if extraTime > 0 then
							NumToString(thisUser.timeAllowed - thisUser.minOnToday + (extraTime div 60 div 60), tempString2)
						else
							NumToString(thisUser.timeAllowed - thisUser.minOnToday, tempString2);
					end
					else
						NumToString(thisUser.timeAllowed, tempString2);
					tempString := concat(RetInStr(27), tempString2);
					OutLine(tempString, true, 0);
					if thisUser.illegalLogons > 0 then
					begin
						NumToString(thisUser.IllegalLogons, tempString);
						tempString := concat(RetInStr(28), tempString);
						OutLine(tempString, true, 0);
						if sysopLogon then
							SysBeep(10)
						else
							OutLine(char(7), false, -1);
					end;
					thisUser.illegalLogons := 0;
					FindMyEmail(thisUser.UserNum);
					tempInt := GetHandleSize(handle(myEmailList)) div 2;
					if tempint > 0 then
					begin
						NumToString(tempInt, tempString);
						tempString := concat(RetInStr(29), tempString);
						OutLine(tempString, true, 0);
					end;
					if thisUser.onToday = 1 then
					begin
						if thisUser.totalLogons > 1 then
						begin
							IUTimeString(thisUser.lastOn, TRUE, tempString3);
							tempString2 := concat(getDate(thisUser.lastOn), ' at ', tempstring3);
						end
						else
							tempString2 := RetInStr(31);
						tempString := concat(RetInStr(30), tempString2);
						OutLine(tempString, true, 0);
					end
					else
					begin
						NumToString(thisUser.onToday, tempString);
						tempString := concat(RetInStr(32), tempString);
						OutLine(tempString, true, 0);
					end;
					if SysopAvailable and not ThisUser.CantChat then
						OutLine(RetInStr(33), true, 0)
					else
						OutLine(RetInStr(34), true, 0);
					if (ThisUser.UDRatioOn) and not (thisUser.coSysop) then
					begin
						DLratioStr(tempString2, activeNode);
						tempString := concat(RetInStr(35), tempstring2);
						OutLine(tempString, true, 0);
						OutLine(stringOf(RetInStr(36), (1 / (thisUser.DLRatioOneTo)) : 0 : 3), true, 0);
					end;
					if (ThisUser.PCRatioOn) and (not thisUser.coSysop) then
						OutLine(StringOf(RetInStr(37), (thisUser.messagesPosted / thisUser.totalLogons) : 0 : 2), true, 0);
					if InitSystHand^^.numNodes > 1 then
						OutLine(concat(RetInStr(38), StringOf(ActiveNode : 0, ' - ', nodename)), true, 0);
					if length(InitSystHand^^.realSerial) > 0 then
						tempstring := copy(InitSystHand^^.realSerial, 1, 8)
					else
						tempstring := concat('Un', 're', 'gi', 'st', 'er', 'ed');
					doM(0);
					OutLine(concat('System is      : Hermes II v', HERMES_VERSION, ' #', tempstring), true, 0);
					doM(0);
					OutLine(concat('Registered To  : ', BBSName), true, 0);
					if thisUser.mailbox then
						OutLine(concat(RetInStr(39), thisUser.forwardedTo, '.'), true, 0);
					yearsOld(thisUser);
					getTime(tempdate);
					if (tempdate.month = integer(thisUser.birthMonth)) and (tempdate.day = integer(thisUser.birthDay)) then
					begin
						OutLine(RetInStr(40), true, 6);
						OutLine(char(7), false, -1);
						OutLine(char(7), false, -1);
						OutLine('', false, 0);
					end;
				end;
				Trans1: 
				begin
					bCR;
					i := 0;
					while (i < availEmails) do
					begin
						if (theEmail^^[i].MType = 0) and (theEmail^^[i].toUser = thisUser.userNum) then
						begin
							if not theEmail^^[i].anonyFrom then
							begin
								tempString := MyUsers^^[theEmail^^[i].fromUser - 1].UName;
							end
							else
								tempString := '>UNKNOWN<';
							tempString2 := getdate(theEmail^^[i].dateSent);
							NumToString(theEmail^^[i].fromUser, tempString4);
							IUTimeString(theEmail^^[i].dateSent, True, tempString3);
							if (length(theEmail^^[i].title) > 0) and (theEmail^^[i].multimail) then
							begin
								if not theEmail^^[i].anonyFrom or (not thisUser.CantReadAnon) or (thisUser.coSysop) then
									tempString3 := concat(tempString, ' #', tempString4, ' read your mail RE: ', theEmail^^[i].title, ' on ', tempString2)
								else
									tempString3 := concat(tempString, RetInStr(69), tempString2);
							end
							else if length(theEmail^^[i].title) = 0 then
							begin
								if not theEmail^^[i].anonyFrom or (not thisUser.CantReadAnon) or (thisUser.coSysop) then
									tempString3 := concat(tempString, ' #', tempString4, RetInStr(69), tempString2, ' at ', tempString3)
								else
									tempString3 := concat(tempString, RetInStr(69), tempString2);
							end
							else
								tempString3 := concat(tempString, ' #', tempstring4, ' downloaded ', theEmail^^[i].title, ' on ', tempstring2, ' at ', tempString3);
							if (thisUser.FirstOn < theEmail^^[i].dateSent) and (theEmail^^[i].fromUser <= NumUserRecs) then
								OutLine(tempString3, true, 0);
							if (availEmails - 1) > i then
							begin
								BlockMove(@theEmail^^[i + 1], @theEmail^^[i], longint(availEmails - 1 - i) * SizeOf(emailRec));
							end;
							SetHandleSize(handle(theEmail), GetHandleSize(handle(theEmail)) - SizeOf(emailRec));
							availEmails := availEmails - 1;
						end
						else
							i := i + 1;
					end;
					emailDirty := true;
					SaveEmailData;
					emailDirty := false;
					if thisUser.useDayorCall then
						templong := (longint(thisUser.timeAllowed - (thisUser.minOnToday div 60 div 60)) * 60 * 60)
					else
						templong := (longint(thisUser.timeAllowed) * 60 * 60) + extraTime;
					tempint := tickCount - timebegin;
					templong := Templong - tempint;
					if (templong > nextDownTicks) and (nextdownticks > 0) then
					begin
						if (Mailer^^.MailerNode = activeNode) and (Mailer^^.SubLaunchMailer <> 0) then
						begin
							tempLong := nextdownticks div 60 div 60;
							bCR;
							NumToString(templong, tempstring);
							outChr(char(7));
							OutLine(concat(RetInStr(70), tempstring, RetInStr(71)), true, 6);
							OutLine('', false, 0);
							shutdownsoon := true;
						end
						else if (Mailer^^.SubLaunchMailer = 0) then
						begin
							tempLong := nextdownticks div 60 div 60;
							bCR;
							NumToString(templong, tempstring);
							outChr(char(7));
							OutLine(concat(RetInStr(134), tempstring, RetInStr(71)), true, 6);
							OutLine('', false, 0);
							shutdownsoon := true;
						end;
					end;
					bCR;
					bCR;
					i := 1;
					while not (MForumOk(i)) and (i < 10) do
						i := i + 1;
					inForum := i;

					gotit := false;
					i := 0;

					repeat
						i := i + 1;
						if MConferenceOk(inForum, i) then
						begin
							inConf := i;
							gotIt := true;
						end;
						if (i = MForum^^[inForum].NumConferences) and (not gotIt) then
						begin
							inConf := 51;
							gotIt := true;
						end;
					until GotIt;
					if inConf <> 51 then
						displayConf := FigureDisplayConf(inForum, inConf)
					else
						displayConf := 0;
					inTransfer := false;

					tempint := 1;
					if (tempint < forumidx^^.numforums) then
					begin
						tempint2 := FindArea(tempInt);
						if forumOk(tempint2) then
						begin
							inDir := tempint;
							inRealDir := FindArea(inDir);
							inSubDir := 1;
							InRealSubDir := FindSub(InRealDir, InSubDir);
						end;
					end;
					if not (MForumOk(inForum)) then
						inForum := 1;
					crossint9 := 1;
				end;
				DoExternalStage: 
				begin
					for i := crossint9 to numExternals do
						if (myExternals^^[i].userExternal) and (myExternals^^[i].CheckLogon) then
						begin
							CallUserExternal(CALLLOGON, i);
							if GetHandleSize(handle(ExternVars)) > 0 then
								leave;
						end;
				end;
				Trans2: 
				begin
					FindMyEmail(thisUser.UserNum);
					tempint := GetHandleSize(handle(myEmailList)) div 2;
					if tempInt > 0 then
					begin
						bCR;
						YesNoQuestion(RetInStr(72), false);
					end
					else
						curPrompt := 'N';
				end;
				Trans3: 
				begin
					if curPrompt = 'Y' then
					begin
						bCR;
						goBackToLogon := true;
						LogonStage := Trans2;
						Read_Mail;
					end
					else
					begin
						curPrompt := 'N';
						tempLong := CheckDays(90);
						if templong > thisUser.lastPWChange then
						begin
							bCR;
							tempString := getDate(thisUser.lastPWChange);
							if thisUser.lastPWChange = 0 then
								OutLine(concat(RetInStr(290)), true, 0)  {Your last password update is unrecorded.}
							else
								OutLine(concat(RetInStr(291), tempstring), true, 0);	{Your last password update was: }
							bCR;
							OutLine(RetInStr(292), true, 0);	{You should update it now.}
							bCR;
							YesNoQuestion(RetInStr(150), false);
							GetDateTime(thisUser.lastPWChange);
						end;
					end;
				end;
				Trans4: 
				begin
					if (curPrompt = 'Y') then
					begin
						BoardSection := CatchUp;
						crossint9 := 20;
					end
					else
					begin
						BoardSection := ScanNew;
						ScanNewDo := Scan1;
						if (thisUser.ScanAtLogon) and (thisUser.totalLogons > 1) then
						begin
							bCR;
							YesNoQuestion(RetInStr(73), false);
						end
						else
							curPrompt := 'N';
					end;
				end;
				otherwise
			end;
		end;
	end;


{$S HUtils6_2}
	procedure SetBookmark;
		var
			WelcomeName, tempstring, tempString2, tempString3, tempString4, ts, MsgLine, fName, internetAddress: str255;
			tempInt, tempLong, col, tl: longInt;
			tempDate, tempDate2, tempDate3: DateTimeRec;
			tempChar: char;
			tempShort, i, LastRef, tempnumem, tempInt2, tempInt3, w, index, b, wnode, totEm, x: integer;
			teEM, tempEMa: eMailRec;
			tempBool, tb2, gotit, FoundUser: boolean;
			myCPB: CInfoPBRec;
			myHPB: HParamBlockRec;
			aUser: UserRec;
			s31: string[31];
			s26: string[26];
	begin
		with curglobs^ do
		begin
			case BoardSection of
				MessageSearcher: 
					DoMessageSearch;
				PrivateRequest: 
					DoPrivateRequest;
				AddrBook: 
					DoAddressBook;
				SlowDevice: 
					DoSlowDevice;
				ScanNew: 
					ScanNewMess;
				ext: 
					EnterExtended;
				MultiChat: 
					MultiNodeChat;
				GFiles: 
					DoGFiles;
				batch: 
					DoBatchCommands;
				MultiMail: 
					doMultiMail;
				Noder: 
					DoNodeStuff;
				MessUp: 
					DoUpMess;
				tranDef: 
					DOTransDefs;
				renFiles: 
					DoRename;
				KillMail: 
					doKillMail;
				MoveFiles: 
					doMove;
				ReadAll: 
					DoAllRead;
				AttachFile: 
					DoAttachFile;
				DetachFile: 
					DoDetachFile;
				SysopComm: 
					DoSysopCommands;
				FindDesc: 
					DoFindDesc;
				PrintXFerTree: 
					PrintTree;
				Post: 
					DoPosting;
				Defaults: 
					ChangeDefaults;
				Colors: 
					ChangeColors;
				QScan: 
					DoQScan;
				Sort: 
					DoSort;
				Quote: 
					DoQuoter;
				BBSlist: 
					doBBSlist;
				Upload: 
					doUpload;
				ListFiles: 
					ListFil;
				UEdit: 
					DoUserEdit;
				Download: 
					DoDownload;
				rmv: 
					DoRemove;
				USList: 
					DoListUsers;
				ListMail: 
					DoListMail;
				RmvFiles: 
					RemoveFiles;
				ChatRoom: 
					DoChatRoom;
				CatchUp: 
					DoCatchUp;
				limDate: 
					DoLimDate;
				chUser: 
				begin
					if FindUser(curprompt, tempUser) then
					begin
						if not tempUser.DeletedUser then
						begin
							thisUser.SL := realSL;
							WriteUser(thisUser);
							thisUser := tempUser;
							DoAddressBooks(AddressBook, thisUser.UserNum, false);
							timebegin := tickCount;
							realSL := thisUser.SL;
							thisUser.SL := 255;
						end
						else
						begin
							OutLine(RetInStr(199), true, 0);	{Deleted User}
							GoHome;
						end;
					end
					else
						OutLine(RetInStr(17), true, 0);	{Unknown user.}
					GoHome;
				end;
				Logon: 
					DoLogonStuff;
				AskQuestions: 
				begin
					case crossint7 of
						1: 
						begin
							statChanged := true;
							WelcomeName := '';
							if InitSystHand^^.closed then
							begin
								crossint8 := 7;
								crossint7 := 1;
								bCR;
								if ReadTextFile('No New User', 1, false) then
								begin
									ListTextFile;
									BoardAction := ListText;
								end
								else
								begin
									BoardAction := none;
									OutLine('''No New User'' file not found.', true, 0);
								end;
								Quiz := NUP;
							end
							else
							begin
								Quiz := CheckNup;
								curPrompt := InitSystHand^^.newUserPass;
							end;
							boardSection := NewUser;
						end;
						2: 
							if newHand^^.Handle then
							begin
								Quiz := GetAlias;
								boardsection := NewUser;
								NumRptPrompt := 3;
							end
							else
								goHome;
						3: 
							if newHand^^.RealName then
							begin
								Quiz := GetReal;
								boardsection := NewUser;
								NumRptPrompt := 3;
							end
							else
								goHome;
						4: 
						begin
							if newHand^^.VoicePN then
							begin
								Quiz := GetVoice;
								boardsection := NewUser;
							end
							else
								goHome;
						end;
						5: 
							if newHand^^.DataPN then
							begin
								Quiz := GetData;
								boardsection := NewUser;
							end
							else
								goHome;
						6: 
							if newHand^^.Gender then
							begin
								Quiz := GetGender;
								boardsection := NewUser;
							end
							else
								goHome;
						7: 
							if newHand^^.company then
							begin
								Quiz := GetCompany;
								boardsection := NewUser;
								NumRptPrompt := 3;
							end
							else
								goHome;
						8: 
							if newHand^^.Street then
							begin
								Quiz := GetStreet;
								boardsection := NewUser;
								NumRptPrompt := 3;
							end
							else
								goHome;
						9: 
							if newHand^^.City then
							begin
								Quiz := GetCity;
								boardsection := NewUser;
								NumRptPrompt := 3;
							end
							else
								goHome;
						10: 
							if newHand^^.City then
							begin
								Quiz := GetState;
								boardsection := NewUser;
								NumRptPrompt := 3;
							end
							else
								goHome;
						11: 
							if newHand^^.City then
							begin
								Quiz := GetZip;
								boardsection := NewUser;
								NumRptPrompt := 3;
							end
							else
								goHome;
						12: 
							if newHand^^.Country then
							begin
								Quiz := GetCountry;
								boardsection := NewUser;
								NumRptPrompt := 3;
							end
							else
								goHome;
						13: 
							if newHand^^.SysOp[1] then
							begin
								Quiz := GetMF1;
								boardsection := NewUser;
								NumRptPrompt := 3;
							end
							else
								goHome;
						14: 
							if newHand^^.SysOp[2] then
							begin
								Quiz := GetMF2;
								boardsection := NewUser;
								NumRptPrompt := 3;
							end
							else
								goHome;
						15: 
							if newHand^^.SysOp[3] then
							begin
								Quiz := GetMF3;
								boardsection := NewUser;
								NumRptPrompt := 3;
							end
							else
								goHome;
						16: 
							if newHand^^.Birthday then
							begin
								Quiz := GetBirthDate;
								boardSection := NewUser;
							end
							else
								goHome;
						17: 
							if newHand^^.Computer then
							begin
								Quiz := GetComputer;
								boardSection := NewUser;
								NumRptPrompt := 3;
							end
							else
								goHome;
						18: 
						begin
							quiz := GetWidth;
							boardSection := NewUser;
						end;
						19: 
						begin
							quiz := GetHght;
							boardSection := NewUser;
						end;
						20: 
						begin
							quiz := GetAnsi;
							boardSection := NewUser;
						end;
						21: 
						begin
							quiz := GetClearing;
							boardSection := NewUser;
						end;
						22: 
						begin
							quiz := GetPause;
							boardSection := NewUser;
						end;
						23: 
						begin
							quiz := GetColumns;
							boardSection := NewUser;
						end;
						24: 
						begin
							quiz := ShowEntries;
							boardSection := NewUser;
						end;
						otherwise
						begin
							boardsection := MainMenu;
							GoHome;
						end;
					end;
				end;
				NewUser: 
				begin
					case quiz of
						NUP..Q59: 
							doQuiz;
						otherwise
						begin
							if crossint8 = 15 then
							begin
								crossint9 := crossint9 + 1;
								boardsection := Logon;
								LogonStage := Hello;
							end
							else if (crossint8 = 7) then
							begin
								if crossint7 <> 24 then
									crossint7 := crossint7 + 1;
								boardSection := AskQuestions;
							end
							else if (crossint8 = 8) then
							begin
								quiz := ShowEntries;
								boardsection := NewUser;
							end
							else
							begin
								boardsection := Mainmenu;
								Gohome;
							end;
						end;
					end;
				end;
				Amsg: 
				begin
					case AutoDo of
						AutoOne: 
						begin
							bCR;
							if not ThisUser.CantChangeAutoMsg then
							begin
								LettersPrompt(RetInStr(293), 'RAWQ', 1, true, false, true, char(0));	{A-msg: R:ead, W:rite, A:uto-reply, Q:uit  : }
							end
							else
							begin
								LettersPrompt(RetInStr(294), 'RAQ', 1, true, false, true, char(0));		{A-msg: R:ead, A:uto-reply, Q:uit  : }
							end;
							AutoDo := AutoTwo;
						end;
						AutoTwo: 
						begin
							case curPrompt[1] of
								'R': 
								begin
									bCR;
									ReadAutoMessage;
									GoHome;
								end;
								'W': 
								begin
									OutLine(RetInStr(74), true, 0);
									bCR;
									WasAMsg := true;
									EnterMessage(thisUser.LnsMessage);
									reply := false;
									AutoDo := AutoSix;
								end;
								'A': 
								begin
									sentAnon := InitSystHand^^.anonyAuto;
									CallFMail := false;
									NumToString(InitSystHand^^.anonyUser, curPrompt);
									Reply := False;
									EmailDo := EmailOne;
									BoardSection := EMail;
								end;
								'Q': 
								begin
									GoHome;
								end;
								otherwise
									autoDo := autoOne;
							end;
						end;
						AutoThree: 
						begin
						end;
						AutoFour: 
						begin
						end;
						AutoFive: 
						begin
						end;
						AutoSix: 
						begin
							if CurWriting <> nil then
							begin
								if curPrompt = 'Y' then
									retob := true
								else
									retob := false;
								bCR;
								bCR;
								YesNoQuestion(RetInStr(76), true);
								AutoDo := AutoSeven;
							end
							else
							begin
								OutLine(RetInStr(141), true, 2);	{No auto message entered.}
								GoHome;
							end;
						end;
						AutoSeven: 
						begin
							if curprompt = 'Y' then
							begin
								InitSystHand^^.anonyUser := thisUser.UserNum;
								InitSystHand^^.anonyAuto := retob;
								doSystRec(true);
								sysopLog('      Changed auto-message.', 0);
								tempString := concat(SharedPath, 'Misc:Auto Message');
								result := FSDelete(tempString, 0);
								result := Create(tempString, 0, 'HRMS', 'TEXT');
								result := FSOpen(tempString, 0, tempShort);
								tempLong := GetHandleSize(handle(curWriting));
								HLock(handle(curWriting));
								result := SetEOF(tempShort, tempLong);
								result := SetFPos(tempShort, fsFromStart, 0);
								result := FSWrite(tempShort, templong, pointer(curWriting^));
								HUnlock(handle(curWriting));
								result := FSClose(tempShort);
							end;
							DisposHandle(handle(curWriting));
							curWriting := nil;
							WasAMsg := false;
							GoHome;
						end;
						otherwise
					end;
				end;
				EXTERNAL: 
				begin
					if activeUserExternal = -1 then
					begin
						tempint := PrintExternalList;
						if tempint > 0 then
						begin
							crossInt := tempInt;
							bCR;
							bCR;
							NumbersPrompt(RetInStr(78), 'Q?', tempInt, 1);
							activeUserExternal := -2;
						end
						else
						begin
							GoHome;
							bCR;
							OutLine(RetInStr(79), true, 0);
						end;
					end
					else if activeUserExternal = -2 then
					begin
						if curPrompt = '?' then
							activeUserExternal := -1
						else if curPrompt = 'Q' then
							GoHome
						else
						begin
							StringToNum(curPrompt, tempLong);
							if (tempLong > 0) and (tempLong <= crossint) then
							begin
								tempShort := 0;
								i := 0;
								repeat
									i := i + 1;
									tempBool := true;
									if myExternals^^[i].AccessLetter <> char(0) then
										if thisUser.AccessLetter[byte(myExternals^^[i].AccessLetter) - 64] then
											tempBool := true
										else
											tempBool := false;
									if (myExternals^^[i].userExternal) and tempBool and (thisUser.SL >= myExternals^^[i].minSLforMenu) then
										tempShort := tempShort + 1;
								until (tempShort = tempLong);
								activeUserExternal := -3;
								crossint8 := i;
							end
							else
								activeUserExternal := -1;
						end;
					end
					else if activeUserExternal = -3 then
					begin
						ExternVars := 0;
						CallUserExternal(CREATENODEVARS, crossint8);
						activeUserExternal := crossint8;
					end
					else if activeUserExternal > 0 then
					begin
						CallUserExternal(ACTIVEEXT, activeUserExternal);
					end;
				end;
				Email: 
				begin
					case EmailDo of
						WhichUser: 
						begin
							CallFMail := false;
							SentAnon := false;
							OutLine(RetInStr(80), true, 0);
							bCR;
							reply := false;
							LettersPrompt(': ', '', 45, false, false, false, char(0));
							EmailDo := EmailNine;
						end;
						EmailCheck: 
						begin
							if (CurPrompt <> 'Q') and (curPrompt <> '') then
							begin
								StringToNum(CurPrompt, tempint);
								tb2 := False;
								for i := 1 to InitFBHand^^.numfeedbacks do
								begin
									if tempint = InitFBHand^^.userNum[i] then
										tb2 := true;
								end;
							end
							else
								GoHome;
							if (CurPrompt = 'Q') or (CurPrompt = '') then
								OutLine('Aborted.', true, 0)
							else if tb2 then
								EmailDo := EmailOne
							else
							begin
								OutLine(RetInStr(295), true, 0);	{User Not In Feedback List.}
								GoHome;
							end;
						end;
						EmailOne: 
						begin
							DoEMail;
						end;
						EmailEight: 
						begin
							if length(CurPrompt) > 0 then
							begin
								CurEMailRec.title := CurPrompt;
								if useWorkspace = 0 then
								begin
									maxLines := thisUser.lnsMessage;
									EnterMessage(maxLines);
									prompting := false;
									endAnony := 0;
								end;
								EmailDo := EmailTwo;
							end
							else
							begin
								OutLine(RetInStr(82), false, 3);
								bCR;
								if not callFMail then
								begin
									GoHome;
								end
								else
								begin
									BoardSection := ReadMail;
									bCR;
									PrintCurEmail;
								end;
							end;
						end;
						EmailTwo: 
						begin
							if (useWorkspace = 1) then
							begin
								LoadFileAsMsg(StringOf(sharedPath, 'Misc:Local Workspace ', activeNode : 0));
								OutLine(RetInStr(81), true, 0);
							end
							else if (useWorkSpace > 1) then
							begin
								index := useWorkspace - 1;
								myCPB.ioCompletion := nil;
								myCPB.ioNamePtr := @fName;
								myCPB.ioFDirIndex := index;
								myCPB.ioDrDirID := crossLong;
								myCPB.ioVrefNum := crossInt2;
								result := PBGetCatInfo(@myCPB, FALSE);
								if result = noErr then
								begin
									LoadFileAsMsg(concat(sharedPath, 'Forms:', fname));
									tempstring := takeMsgTop;
									if (length(tempstring) > 70) then
										tempstring[0] := char(70);
									curEMailRec.title := tempstring;
									OutLine(RetInStr(296), true, 0);	{Form letter enclosed.}
								end
								else
									OutLine(RetInStr(297), true, 0);	{Form letter error.}
							end;
							useWorkspace := 0;
							bCR;
							bCR;
							EmailDo := EmailThree;
						end;
						EmailThree: 
						begin
							if curWriting <> nil then
							begin
								bCR;
								if netMail or INetMail then
									endAnony := -1;
								if (not ThisUser.CantPostAnon) and (endAnony = 0) then
								begin
									YesNoQuestion(RetInStr(75), false);
								end
								else
								begin
									CurPrompt := 'N';
									if (not ThisUser.CantPostAnon) and (EndAnony = 1) then
										curprompt := 'Y'
									else if (not ThisUser.CantPostAnon) and (EndAnony = -1) then
										curprompt := 'N';
								end;
								EMailDo := EmailFour;
							end
							else
							begin
								bCR;
								if wasSearching then
									BoardSection := MessageSearcher
								else if not callFMail then
								begin
									GoHome;
								end
								else
								begin
									BoardSection := ReadMail;
									bCR;
									PrintCurEmail;
								end;
							end;
						end;
						EMailFour: 
						begin
							FromDetach := false;
							if CurPrompt = 'Y' then
								CurEMailRec.AnonyFrom := true
							else
								CurEMailRec.AnonyFrom := false;
							if sentAnon then
								curEmailRec.anonyTo := true;
							OutLine(RetInStr(83), false, 0);
							if (MailingUser.Mailbox) and (not NetMail) and (not INetMail) then
							begin
								if (pos(',', MailingUser.ForwardedTo) = 0) and (pos('@', MailingUser.ForwardedTo) = 0) then
								begin
									if FindUser(MailingUser.ForwardedTo, tempuser) then
									begin
										if not tempUser.DeletedUser then
										begin
											curEmailRec.toUser := tempuser.userNum;
											NumToString(mailingUser.userNum, tempstring2);
											AddLine(concat(RetInStr(84), mailinguser.username, ' #', tempstring2, char(13)));
										end;
									end
									else
										AddLine('');
								end
								else
								begin
									netMail := FidoNetAccount(thisUser.ForwardedTo);
									if netMail then
										INetMail := false
									else
										INetMail := InternetAccount(thisUser.ForwardedTo);
								end;
							end
							else if (not netMail) and (not INetmail) then
								AddLine('');
							if (not netMail) and (not INetMail) then
							begin
								if not SaveMessasEmail then
									OutLine(RetInStr(298), true, 6);	{Error: Email database full.}
							end
							else if netMail then
								SaveNetMail(char(0))
							else if INetMail then
							begin
								{ We have to save the Internet address because it will get obliterated in }
								{ SaveNetMail and replaced with the FidoNet<->Internet gateway address }
								{ if this BBS uses gated Internet e-mail. }
								internetAddress := myFido.name;

								SaveNetMail(char(0));
							end;
							if not NewFeed then
							begin
								if not curEmailRec.multiMail then
								begin
									NumToString(mailingUser.UserNum, tempString2);
									if netmail then
										tempstring := concat(RetInStr(299), myFido.name, ' at node ', myFido.atNode, '.') {      Mail sent to }
									else if inetmail then
										tempstring := concat(RetInStr(299), internetAddress)
									else
										tempString := concat(RetInStr(299), mailingUser.UserName, ' #', tempString2);
									sysopLog(tempString, 0);
									wnode := WhatNode(MailingUser.UserName);
									if (wnode > 0) and (not NetMail) then
										SingleNodeOutput(stringOf(char(7), RetInStr(642), myUsers^^[CurEmailRec.FromUser - 1].Uname), wnode);	{You just received Email From }
								end
								else
								begin
									SysopLog(RetInStr(300), 0);	{      Sent Multi-Mail to:}
									for i := 1 to numMultiUsers do
									begin
										NumToString(multiUsers[i], tempstring);
										SysopLog(concat('        ', myUsers^^[multiUsers[i] - 1].UName, ' #', tempstring), 0);
										wnode := WhatNode(MailingUser.UserName);
										if wnode > 0 then
											SingleNodeOutput(stringOf(char(7), RetInStr(642), CurEmailRec.FromUser : 0), wnode);
									end;
								end;
							end;
							if curEmailRec.multiMail then
							begin
								thisUser.EMsentToday := thisUser.EMsentToday + numMultiUsers;
								thisUser.EMailSent := thisUser.EMailSent + numMultiUsers;
								InitSystHand^^.eMailToday[activeNode] := InitSystHand^^.eMailToday[activeNode] + numMultiUsers;
							end
							else
							begin
								thisUser.EMsentToday := thisUser.EMsentToday + 1;
								thisUser.EMailSent := thisUser.EMailSent + 1;
								InitSystHand^^.eMailToday[activeNode] := InitSystHand^^.eMailToday[activeNode] + 1;
							end;
							GetDateTime(InitSystHand^^.lastEmail);
							doSystRec(true);
							Writeuser(thisUser);
							NumToString(mailingUser.UserNum, tempString2);
							if netMail then
							begin
								tempstring := concat(RetInStr(301), myFido.name, ' at node ', myFido.atNode, '.');	{Mail sent to }
							end
							else if INetMail then
							begin
								tempstring := concat(RetInStr(301), internetAddress);	{Mail sent to }
							end
							else
							begin
								if not curEmailRec.multiMail then
								begin
									if (not SentAnon) or (thisUser.coSysop) then
										tempString := concat(RetInStr(301), mailingUser.UserName, ' #', tempString2)
									else
										tempString := concat(RetInStr(301), '>UNKNOWN<');
								end
								else
									tempstring := RetInStr(302);
							end;
							OutLine(tempString, false, 0);
							bCR;
							if wasSearching then
								BoardSection := MessageSearcher
							else if not callFMail then
							begin
								GoHome;
							end
							else
							begin
								BoardSection := ReadMail;
								bCR;
								PrintCurEmail;
							end;
						end;
						EmailFive: 
						begin
							if length(curPrompt) = 0 then
								GoHome
							else
							begin
								ReplyStr := curPrompt;
								FoundUser := FindUser(curPrompt, MailingUser);
								bCR;
								YesNoQuestion(concat(RetInStr(205), MailingUser.UserName, RetInStr(206)), true);
								EMailDo := EMailEleven;
							end;
						end;
						EmailEleven: 
						begin
							if curPrompt = 'Y' then
							begin
								index := PrintFormLetters;
								NumbersPrompt(RetInStr(304), 'Q', index - 2, 1);	{Send which form letter: }
								EmailDo := EmailSix;
							end
							else
								GoHome;
						end;
						EmailSix: 
						begin
							if curPrompt = '' then
								GoHome
							else
							begin
								StringToNum(curprompt, tempInt);
								if (tempInt > 0) and (tempInt < 99) and (curPrompt <> 'Q') then
								begin
									useWorkspace := tempInt + 1;
									bCR;
									EmailDo := EmailOne;
									curPrompt := replyStr;
								end
								else
									EmailDo := EmailOne;
							end;
						end;
						EmailNine: 
						begin
							if (curPrompt[1] <> '!') and ((pos(',', curPrompt) = 0) and (pos('@', curPrompt) = 0)) then
							begin
								UprString(curPrompt, true);
								x := 0;
								FoundUser := false;
								if FindUser(curPrompt, tempUser) then
									FoundUser := true;
								if ((curprompt[length(curPrompt)] = '*') and FoundUser and (curPrompt[1] > char(64))) then
								begin
									enteredPass2 := curPrompt;
									Delete(enteredPass2, Length(enteredPass2), 1);
									for i := 1 to numUserRecs do
									begin
										ts := myUsers^^[i - 1].UName;
										UprString(ts, true);
										if pos(enteredPass2, ts) > 0 then
										begin
											x := x + 1;
											NumToString(x, tempString2);
											if (length(tempString2) = 1) then
												tempString2 := concat('   ', tempString2, ' - ', myUsers^^[i - 1].UName)
											else if (length(tempString2) = 2) then
												tempString2 := concat('  ', tempString2, ' - ', myUsers^^[i - 1].UName)
											else if (length(tempString2) = 3) then
												tempString2 := concat(' ', tempString2, ' - ', myUsers^^[i - 1].UName)
											else
												tempString2 := concat(tempString2, ' - ', myUsers^^[i - 1].UName);
											if (x = 1) then
												tempstring3 := tempString2
											else if (x = 2) then
											begin
												OutLine('Matching Users:', true, 1);
												bCR;
												OutLine(tempstring3, true, 0);
												OutLine(tempString2, true, 0);
											end
											else
												OutLine(tempString2, true, 0);
										end;
									end;
									if (x > 1) then
									begin
										bCR;
										bCR;
										NumbersPrompt('Which user: ', '1234567890', x, 1);
									end
									else
										FoundUser := false;
								end;

								if FoundUser and (x > 1) then
								begin
									EMailDo := EMailTen;
								end
								else
								begin
									EMailDo := EMailOne;
								end;
							end
							else if (curPrompt[1] = '!') then
							begin
								BoardSection := AddrBook;
								ABDo := AB12;
								wasEMail := true;
								wasSearching := false;
							end
							else
								EMailDo := EMailOne;
						end;
						EMailTen: 
						begin
							x := 0;
							StringToNum(curPrompt, templong);
							crossint4 := templong;
							for i := 1 to numUserRecs do
							begin
								ts := myUsers^^[i - 1].UName;
								UprString(ts, true);
								if pos(enteredPass2, ts) > 0 then
								begin
									x := x + 1;
									if (x = crossint4) then
									begin
										NumToString(i, tempstring2);
										curPrompt := tempString2;
										leave;
									end;
								end;
							end;
							EMailDo := EMailOne;
						end;
						otherwise
					end;
				end;
				ChatStage: 
				begin
					case ChatDo of
						ChatOne: 
						begin
							if not triedChat then
							begin
								if (SysopAvailable and not ThisUser.CantChat) or ((menuHand^^.Options[pos('S', menuCmds), 1]) and (MenuHand^^.SecLevel2[pos('S', menuCmds)] <= thisUser.SL)) then
								begin
									bCR;
									LettersPrompt(RetInStr(85), '', 30, false, false, false, char(0));
									ChatDo := ChatTwo;
								end
								else
								begin
									sysopLog(RetInStr(305), 0);	{      Tried Chatting.}
									bCR;
									OutLine(RetInStr(86), false, 0);
									OutLine(RetInStr(87), true, 0);
									bCR;
									CurPrompt := '1';
									reply := false;
									if FindUser(curPrompt, tempuser) then
										YesNoQuestion(concat('E-mail ', tempUser.UserName, ' #1? '), false);
									ChatDo := ChatThree;
								end;
							end
							else
							begin
								triedChat := false;
								OutLine(RetInStr(88), false, 0);
								bCR;
								bCR;
								GoHome;
							end;
						end;
						ChatTwo: 
						begin
							if length(curPrompt) > 0 then
							begin
								tempString := concat(RetInStr(306), CurPrompt);	{      Chat: }
								sysopLog(tempString, 0);
								bCR;
								OutLine(RetInStr(89), false, 0);
								triedChat := true;
								chatReason := CurPrompt;
								bCR;
								bCR;
								NumToString(activeNode, tempstring);
								tempstring := concat('Chat ', tempString);
								if GetNamedResource('snd ', tempstring) <> nil then
									StartMySound(tempString, false)
								else
									for i := 1 to 4 do
										SysBeep(1);
								OutLine(RetInStr(90), true, 0);
							end;
							bCR;
							bCR;
							GoHome;
						end;
						ChatThree: 
						begin
							if curPrompt = 'Y' then
							begin
								CurPrompt := '1';
								BoardSection := EMail;
								EmailDo := EmailOne;
							end
							else
							begin
								bCR;
								GoHome;
							end;
						end;
						otherwise
					end;
				end;
				OffStage: 
				begin
					case OffDo of
						SureQuest: 
						begin
							bCR;
							bCR;
							OffDo := OffText;
							if ((thisUser.totallogons = 1) and (menuHand^^.Options[pos('O', menuCmds), 1])) then
							begin
								NewYesNoQuestion(RetInStr(129));
								OffDo := KeepNew;
							end
							else
								YesNoQuestion(RetInStr(91), false);
						end;
						KeepNew: 
						begin
							if CurPrompt = 'N' then
							begin
								OutLine('Account Deleted.', true, 0);
								i := 0;
								while (i < availEmails) do
									if (theEMail^^[i].toUser = thisUser.userNum) or (theEMail^^[i].fromUser = thisUser.userNum) then
										DeleteMail(i)
									else
										i := i + 1;
								thisUser.DeletedUser := true;
								if thisUser.UserName[1] <> '~' then
									thisUser.UserName := concat('~', thisUser.UserName);
								if thisUser.Alias[1] <> '•' then
									thisUser.alias := thisUser.UserName
								else
									thisUser.RealName := thisUser.UserName;
								thisUser.coSysop := false;
								myUsers^^[thisUser.userNum - 1].dltd := true;
								myUsers^^[thisUser.userNum - 1].Uname := thisUser.UserName;
								if thisUser.RealName[1] <> '•' then
									myUsers^^[thisUser.userNum - 1].real := thisuser.RealName;
								InitSystHand^^.numUsers := InitSystHand^^.numUsers - 1;
								doSystRec(true);
								curPrompt := 'Y';
								bCR;
							end
							else
							begin
								bCR;
								YesNoQuestion(RetInStr(91), false);
							end;
							OffDo := OffText;
						end;
						OffText: 
						begin
							if CurPrompt = 'Y' then
							begin
								ClearScreen;
								tempString := concat(RetInStr(307), tickToTime(tickCount - timeBegin));	{Time on = }
								OutLine(tempString, false, 0);
								bCR;
								bCR;
								if ReadTextFile('Log Off', 1, false) then
								begin
									if thisUser.TerminalType = 1 then
										noPause := true;
									BoardAction := ListText;
									ListTextFile;
								end
								else
								begin
									bCR;
									OutLine('Can''t find Logoff file', true, 0);
								end;
								OffDo := Hanger;
							end
							else
								GoHome;
						end;
						Hanger: 
						begin
							Delay(50, tempLong);
							HangupAndReset;
						end;
						otherwise
					end;
				end;
				ReadMail: 
				begin
					case ReadDo of
						readOne: 
						begin
							Read_Mail;
						end;
						readTwo: 
						begin
							FindMyEmail(thisUser.UserNum);
							tempint2 := GetHandleSize(handle(myEmailList)) div 2;
							bCR;
							HelpNum := 10;
							OutLine(RetInStr(92), true, 0);
							bCR;
							NumbersPrompt(':', 'Q', tempInt2, 1);
							ReadDo := ReadThree;
						end;
						readThree: 
						begin
							if curprompt = 'Q' then
							begin
								GoHome;
							end
							else
							begin
								FindMyEmail(thisUser.UserNum);
								tempint2 := GetHandleSize(handle(myEmailList)) div 2;
								if curprompt <> '' then
								begin
									StringToNum(curPrompt, tempInt);
									if (tempint2 >= tempInt) and (tempInt > 0) then
									begin
										atEMail := tempInt - 1;
									end
									else
										atEMail := tempint2 - 1;
								end
								else
									atEMail := 0;
								PrintCurEMail;
								if (WasAttach) then
									ReadDo := ReadNine
								else
									ReadDo := ReadFour;
							end;
						end;
						readFour: 
						begin
							FromDetach := false;
							FindMyEmail(thisUser.UserNum);
							tempint := GetHandleSize(handle(myEmailList)) div 2;
							if tempint > 0 then
							begin
								tempString := 'AFGRQDISE?+-';
								if (thisUser.coSysop) then
									tempString := 'AFGRQZDISVOE?+-';
								bCR;
								HelpNum := 28;
								NumbersPrompt(RetInStr(93), tempstring, -1, 0);
								ReadDo := readFive;
							end
							else
								GoHome;
						end;
						readFive: 
						begin
							bCR;
							DoMailCommand(curprompt);
						end;
						ReadSix: 
						begin
							FindMyEmail(thisUser.UserNum);
							tempint := GetHandleSize(handle(myEmailList)) div 2;
							StringToNum(curprompt, tempLong);
							if (templong <= tempint) and (tempLong > 0) then
								atEMail := tempLong - 1;
							PrintCurEMail;
							if (WasAttach) then
								ReadDo := ReadNine
							else
								ReadDo := ReadFour;
						end;
						ReadSeven: 
						begin
							if FindUser(curPrompt, tempUser) then
							begin
								if tempUser.UserNum <> thisUser.UserNum then
								begin
									if not tempUser.DeletedUser then
									begin
										NumToString(tempuser.UserNum, tempString);
										YesNoQuestion(concat(RetInStr(94), tempUser.UserName, ' #', tempString, ' ?'), false);
										if WasAttach then
											ReadDo := Read16
										else
											ReadDo := ReadEight;
									end
									else
									begin
										OutLine(RetInStr(95), true, 0);
										ReadDo := ReadFour;
									end;
								end
								else
								begin
									OutLine(RetInStr(96), true, 0);
									ReadDo := ReadFour;
								end;
							end
							else
							begin
								OutLine(RetInStr(97), true, 0);
								ReadDo := ReadFour;
							end;
						end;
						ReadEight: 
						begin
							FindMyEmail(thisUser.UserNum);
							bCR;
							if (curPrompt = 'Y') then
							begin
								curEmailRec := theEmail^^[myEmailList^^[atEmail]];
								theEmail^^[myEmailList^^[atEmail]].toUser := tempuser.userNum;
								if curWriting <> nil then
									DisposHandle(handle(curWriting));
								curWriting := nil;
								curWriting := ReadMessage(curEmailrec.storedAs, 0, 0);
								tempString := takeMsgTop;
								if curWriting^^[0] <> char(13) then
									AddLine(char(13));
								NumToString(thisUser.userNum, tempstring2);
								AddLine(concat(RetInStr(84), thisuser.username, ' #', tempstring2));
								RemoveMessage(curemailrec.storedAs, 0, 0);
								SetHandleSize(handle(curWriting), GetHandleSize(handle(curWriting)) + 1);
								curWriting^^[GetHandleSize(handle(curWriting)) - 1] := char(26);

								emaildirty := true;
								if tempUser.Mailbox then
								begin
									if (pos(',', tempUser.ForwardedTo) = 0) and (pos('@', tempUser.ForwardedTo) = 0) then {Not to Net Address}
									begin
										StringToNum(tempUser.ForwardedTo, tempLong);
										theEmail^^[myEmailList^^[atEmail]].toUser := tempLong;
										theEmail^^[myEmailList^^[atEmail]].storedAs := SaveMessage(curWriting, 0, 0);
									end
									else
									begin
										DeleteFileAttachment(true, theEmail^^[myEmailList^^[atEmail]].FileName);
										theEmail^^[myEmailList^^[atEmail]].FileAttached := false;
										theEmail^^[myEmailList^^[atEmail]].FileName := char(0);

										if FidoNetAccount(tempUser.ForwardedTo) then
										begin
											if FindUser(StringOf(curEmailRec.FromUser : 0), aUser) then
												;
											SaveNetMail(aUser.userName);
											DeleteMail(myEmailList^^[atEmail]);
											if curWriting <> nil then
											begin
												DisposHandle(handle(curWriting));
												curWriting := nil;
											end;
										end
										else
											theEmail^^[myEmailList^^[atEmail]].storedAs := SaveMessage(curWriting, 0, 0);
									end;
								end
								else
									theEmail^^[myEmailList^^[atEmail]].storedAs := SaveMessage(curWriting, 0, 0);
								OutLine(RetInStr(98), true, 0);
								bCR;
							end;
							ReadDo := ReadFour;
						end;
						JumpForum: 
						begin
							if not intransfer then
							begin
								StringToNum(curPrompt, tempInt);
								if tempint > 0 then
								begin
									tempint3 := 0;
									tempshort := 0;
									lastref := 0;
									for tempint2 := 1 to InitSystHand^^.numMForums do
									begin
										if MForumOk(tempint2) then
											tempInt3 := tempInt3 + 1;
										if (tempInt3 = tempInt) and (lastRef = 0) then
										begin
											lastref := 1;
											tempShort := tempint2;
										end;
									end;
									if tempShort > 0 then
									begin
										if (tempshort <= InitSystHand^^.numMForums) and (tempshort > 0) then
										begin
											if (MForumOk(tempshort)) then
											begin
												inForum := tempshort;
												gotit := false;
												i := 0;
												repeat
													i := i + 1;
													if MConferenceOk(inForum, i) then
													begin
														inConf := i;
														gotIt := true;
													end;
													if (i = MForum^^[inForum].NumConferences) and (not gotIt) then
													begin
														inConf := 51;
														gotIt := true;
													end;
												until GotIt;
												if inConf <> 51 then
													displayConf := FigureDisplayConf(inForum, inConf)
												else
													displayConf := 0;

												if (thisUser.MessHeader <> MessOff) then
												begin
													s26 := MForum^^[inForum].Name;
													s31 := MForum^^[inForum].Name;
													if thisUser.TerminalType = 1 then
														ts := concat('Messages:', s31, ':', s26, ' AHDR')
													else
														ts := concat('Messages:', s31, ':', s26, ' HDR');
													if ReadTextFile(ts, 0, true) then
													begin
														if thisUser.TerminalType = 1 then
															noPause := true;
														BoardAction := ListText;
													end;
												end;
											end
											else
												OutLine(RetInStr(99), true, 0);
										end
										else
											OutLine(RetInStr(99), true, 0);
									end
									else
										OutLine(RetInStr(99), true, 0);
								end;
								GoHome;
							end
							else
							begin
								if curPrompt <> '' then
								begin
									StringToNum(curPrompt, tempInt);
									if (tempint < forumidx^^.numforums) then
									begin
										tempint2 := FindArea(tempInt);
										if forumOk(tempint2) then
										begin
											inDir := tempint;
											inRealDir := FindArea(inDir);
											inSubDir := 1;
											InRealSubDir := FindSub(InRealDir, InSubDir);

											if (thisUser.TransHeader <> TransOff) then
											begin
												s26 := forumIdx^^.name[InRealDir];
												s31 := forumIdx^^.name[InRealDir];
												if thisUser.TerminalType = 1 then
													tempString := concat('Data:', s31, ':', s26, ' AHDR')
												else
													tempString := concat('Data:', s31, ':', s26, ' HDR');
												if ReadTextFile(tempString, 0, true) then
												begin
													if thisUser.TerminalType = 1 then
														noPause := true;
													BoardAction := ListText;
												end;
											end;
										end;
									end;
								end;
								GoHome;
							end;
						end;
						ReadNine: 
						begin
							if not sysopLogon then
							begin
								bCR;
								YesNoQuestion(RetInStr(126), true);
								ReadDo := ReadTen;
							end
							else
								ReadDo := ReadFour;
						end;
						ReadTen: 
						begin
							if (curPrompt = '') or (curPrompt = 'Y') then
							begin
								FromDetach := true;
								ReadDo := ReadFour;
								DetachDo := Detach1;
								WasEMail := true;
								wasSearching := false;
								BoardSection := DetachFile;
							end;
							ReadDo := ReadFour;
						end;
						ReadEleven: 
						begin
							FindMyEmail(thisUser.UserNum);
							tempEma := theEmail^^[myEmailList^^[atEmail]];
							if tempEma.FileAttached and (MailOp <> 4) then
							begin
								bCR;
								YesNoQuestion(RetInStr(128), false);  {This command will also delete the attached file. Continue? }
								ReadDo := ReadTwelve;
							end
							else
							begin
								case MailOp of
									1, 2: {D & Z}
										ReadDo := Read14;
									3, 4: {A & O}
										ReadDo := Read15;
									otherwise
										ReadDo := ReadFour;
								end;
							end;
						end;
						ReadTwelve: 
						begin
							bCR;
							if (curPrompt = 'Y') and (not isMM) then
							begin
								tempString := 'Mail Attachments';
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
									ReadDo := Read13;
								end
								else
								begin
									OutLine(RetInStr(59), true, 0);
									case MailOp of
										1, 2: {D & Z}
											ReadDo := Read14;
										3, 4: {A & O}
											ReadDo := Read15;
										otherwise
											ReadDo := ReadFour;
									end;
								end;
							end
							else if (curPrompt = 'Y') and (isMM) then
							begin
								case MailOp of
									1, 2: {D & Z}
										ReadDo := Read14;
									3, 4: {A & O}
										ReadDo := Read15;
									otherwise
										ReadDo := ReadFour;
								end;
							end
							else
								ReadDo := ReadFour;
						end;
						Read13: 
						begin
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
								case MailOp of
									1, 2: {D & Z}
										ReadDo := Read14;
									3, 4: {A & O}
										ReadDo := Read15;
									otherwise
										ReadDo := ReadFour;
								end;
							end
							else
							begin
								OutLine(RetInStr(127), true, 1); {Attached file not found.}
								case MailOp of
									1, 2: {D & Z}
										ReadDo := Read14;
									3, 4: {A & O}
										ReadDo := Read15;
									otherwise
										ReadDo := ReadFour;
								end;
							end;
							CloseDirectory;
						end;
						Read14: 
						begin
							if (MailOp <> 2) or (thisUser.coSysop) then
							begin
								FindMyEmail(thisUser.UserNum);
								tempEma := theEmail^^[myEmailList^^[atEmail]];
								if (MailOp <> 2) and (tempEma.fromUser <> TABBYTOID) then
									HeReadIt(tempEma);
								DeleteMail(myEmailList^^[atEmail]);
								if MailOp <> 2 then
									OutLine(RetInStr(627), true, 0)	{Deleted.}
								else
									OutLine(RetInStr(628), true, 0);	{Deleted, not acknowledged.}
								bCR;
								FindMyEmail(thisUser.UserNum);
								totEm := GetHandleSize(handle(myEmailList)) div 2;
								if atEmail >= totEm then
									atEmail := atEmail - 1
								else if atEmail < 0 then
									atEmail := 0;
								if totEm > 0 then
									PrintCurEMail
								else
									GoHome;
								if (WasAttach) then
									ReadDo := ReadNine
								else
									ReadDo := ReadFour;
							end
							else
								readDo := readFour;
						end;
						Read15: 
						begin
							FindMyEmail(thisUser.UserNum);
							tempEma := theEmail^^[myEmailList^^[atEmail]];
							if not (tempEma.fromUser = TABBYTOID) then
							begin
								if not myUsers^^[tempEma.fromUser - 1].dltd then
								begin
									if (MailOp = 3) then
										HeReadIt(tempEma);
									NumToString(tempEma.fromUser, curPrompt);
									if FindUser(curPrompt, aUser) then
										ts := aUser.UserName;
								end
								else
									curPrompt := '';
							end
							else
							begin
								if curwriting <> nil then
								begin
									DisposHandle(handle(curWriting));
								end;
								CurWriting := nil;
								curWriting := ReadMessage(tempEma.storedAs, 0, 0);
								curPrompt := takeMsgTop;
								tempint := pos(' #', curprompt);
								if tempint > 0 then
									delete(curPrompt, tempint, 80);
								ts := curPrompt;
								tempString := takeMsgTop;
								tempString := takeMsgTop;
								tempString := MakeInternetAddress(tempString);
								if tempString <> char(0) then
									curPrompt := tempString;
							end;
							SentAnon := tempEma.anonyFrom;
							WasAnonymous := tempEma.anonyFrom;
							SetUpQuoteText(ts, tempEma.storedAs, 0, 0);
							if wasAnonymous then
								TheQuote.Header := MakeQuoteHeader('>>UNKNOWN<<', thisUser.UserName, tempEma.title, false)
							else
								TheQuote.Header := MakeQuoteHeader(ts, thisUser.UserName, tempEma.title, false);

							if MailOp = 3 then
							begin
								DeleteMail(myEmailList^^[atEmail]);
								Reply := True;
								newmsg := true;
							end;
							BoardSection := EMail;
							EmailDo := EMailOne;
							CallFMail := true;
							ReadDo := ReadFour;
							if MailOp = 4 then
								EmailDo := EmailFive;
						end;
						Read16: 
						begin
							if (curPrompt = 'Y') then
							begin
								bCR;
								YesNoQuestion(RetInStr(130), true);
								ReadDo := ReadEight;
							end
							else
								ReadDo := ReadFour;
						end;
						otherwise
					end;
				end;
				MainMenu: 
				begin
					case MainStage of
						MenuText: 
						begin
							if endQScan then
							begin
								OutLine(concat('< ', MConference[inForum]^^[inConf].Name, ' ', RetInStr(152), ' >'), false, 1);	{Q-Scan Done}
								bCR;
								lnsPause := 0;
								endQScan := false;
							end;
							if not inNScan or fromQScan then
							begin
								if not newFeed and not fromQScan then
								begin
									bCR;
									if not thisUser.Expert then
									begin
										if inTransfer then
											welcomeName := 'Transfer Menu'
										else
											WelcomeName := 'Main Menu';
										if ReadTextFile(WelcomeName, 1, false) then
										begin
											if thisUser.TerminalType = 1 then
												noPause := true;
											BoardAction := ListText;
											ListTextFile;
										end
										else
										begin
											OutLine('Menu file not found.', true, 0);
										end;
									end;
									MainStage := MainPrompt;
								end
								else if newFeed then
								begin
									newFeed := false;
									BoardSection := Logon;
									LogonStage := Password;
									curPrompt := thisUser.Password;
									RealSL := thisUser.SL;
								end
								else if fromQScan then
								begin
									if fromMsgScan then
									begin
										BoardSection := ScanNew;
										inConf := saveInSub;
										inForum := saveInForum;
										inMessage := crossInt3;
										fromMsgScan := false;
									end
									else
									begin
										BoardSection := Qscan;
										QDo := QTwo;
									end;
									fromQScan := false;
								end;
							end
							else
								NScanCalc;
						end;
						MainPrompt: 
						begin
							if (CountTimeWarn > 4) and (ticksLeft(activeNode) <= 18000) then
							begin
								OutChr(char(7));
								OutLine(concat(RetInStr(207), tickToTime(ticksLeft(activeNode)), RetInStr(208)), true, 6);
								CountTimeWarn := 0;
							end
							else
								OutLine(concat(RetInStr(308), tickToTime(ticksLeft(activeNode))), true, 0);	{T - }
							if (InitSystHand^^.numMForums > 1) and (MForumOk(inForum)) and not inTransfer then
							begin
								OutLine(concat('[', MForum^^[inForum].Name, ']'), true, 1);
							end
							else if intransfer then
							begin
								OutLine(RetInStr(744), true, 5);{[Area]: }
								OutLine(concat('[', forumIdx^^.name[inRealDir], ']'), false, 1);
							end;
							bcr;
							MamaPrompt(tempString);
							MainMenuPrompt(tempString);
							MainStage := MenuText;
						end;
						TextForce: 
						begin
							bCR;
							if inTransfer then
								welcomeName := 'Transfer Menu'
							else
								WelcomeName := 'Main Menu';
							ClearScreen;
							if ReadTextFile(welcomeName, 1, false) then
							begin
								if thisUser.TerminalType = 1 then
									noPause := true;
								BoardAction := ListText;
								ListTextFile;
							end
							else
							begin
								OutLine('File not found.', true, 0);
								BoardAction := none;
							end;
							MainStage := MainPrompt;
						end;
						otherwise
					end;
				end;
				otherwise
			end;
			aborted := false;
		end;
	end;
end.