{ Segments: HUtils4_1, HUtils4_2 }
unit HUtils4;


interface

	uses
		AppleTalk, ADSP, Serial, Sound, TCPTypes, Initial, SystemPrefs, User, InpOut4, InpOut3, inpOut2, Quoter, InpOut, MessNTextOutput, HUtils2, HermesUtils, FileTrans, FileTrans2, FileTrans3, Message_Editor, nodeprefs, nodeprefs2, terminal, notification, PPCToolbox, Processes, EPPC, AppleEvents, HUtils3, Misc2;

	procedure DoListUsers;
	procedure DoAllRead;
	procedure DoMainMenu;
	procedure ScanNewMess;
	procedure DoSysopCommands;

implementation

{$S HUtils4_1}
	procedure ScanNewMess;
		var
			scanF, scanS, cou1, i, tempint: integer;
			tb, tb2, goodSub: boolean;
			ts, tempstring: Str255;
			tempLong: longint;
			tempsub: subdyhand;
	begin
		with curGlobs^ do
		begin
			case ScanNewDo of
				Scan1: 
				begin
					if curprompt = 'Y' then
					begin
						crossInt := 1;
						while not (MForumOk(crossint)) and (crossint <= InitSystHand^^.numMForums) do
							crossint := crossint + 1;
						crossInt2 := 0;
						ScanNewDo := Scan2;
					end
					else
						GoHome;
				end;
				Scan2: 
				begin
					if crossint <= InitSystHand^^.numMForums then
					begin
						repeat
							crossInt2 := crossInt2 + 1;
							goodSub := false;
							if MConferenceOk(crossint, crossint2) and (thisUser.whatNScan[crossint, crossint2]) and (MForum^^[crossInt].NumConferences >= crossint2) then
								goodSub := true;
						until (crossint2 >= MForum^^[crossInt].NumConferences) or goodSub;
						if goodSub then
						begin
							OutLine(concat(RetInStr(100), MConference[crossInt]^^[crossInt2].Name, '...'), true, 1);
							OpenBase(crossInt, crossInt2, false);
							inMessage := 1;
							crossInt3 := 1;
							ScanNewDo := Scan3;
						end
						else
						begin
							crossInt2 := 0;
							crossInt := crossInt + 1;
							while not (MForumOk(crossint)) and (crossint <= InitSystHand^^.numMForums) do
								crossint := crossint + 1;
						end;
					end
					else
						GoHome;
				end;
				Scan3: 
				begin
					if curNumMess > 0 then
					begin
						i := crossInt3;
						while (i <= curNumMess) and ((curBase^^[i - 1].DateEn <= thisUser.lastMsgs[crossInt, crossint2]) or ((curBase^^[i - 1].toUserNum <> thisUser.userNum) and (curBase^^[i - 1].toUserName <> thisUser.userName)) or (curBase^^[i - 1].HasRead)) do
							i := i + 1;

						if (i <= curNumMess) and (curBase^^[i - 1].DateEn > thisUser.lastMsgs[crossInt, crossInt2]) and (curBase^^[i - 1].toUserNum = thisUser.userNum) and (curBase^^[i - 1].toUserName = thisUser.userName) and (not curBase^^[i - 1].HasRead) then
							inmessage := i
						else if (i <= curNumMess) and (curBase^^[i - 1].DateEn > thisUser.lastMsgs[crossInt, crossInt2]) and (curBase^^[i - 1].toUserNum = thisUser.userNum) and (curBase^^[i - 1].toUserName = thisUser.RealName) and ((MConference[crossInt]^^[crossInt2].RealNames) and (MConference[crossInt]^^[crossInt2].ConfType > 0)) and (newhand^^.handle) and (not curBase^^[i - 1].HasRead) then
							inMessage := i
						else
							inMessage := curnummess + 1;
					end;
					if (curNumMess = 0) or (inMessage > curNumMess) then
					begin
						SaveBase(crossInt, crossInt2);
						ScanNewDo := Scan2;
					end
					else
					begin
						crossint3 := i + 1;
						scanf := inForum;
						scanS := inConf;
						inForum := crossint;
						inConf := crossInt2;
						PrintCurMessage(false);
						curBase^^[i - 1].HasRead := true;
						inForum := scanF;
						inConf := scanS;
						ScanNewDo := Scan4;
					end;
				end;
				Scan4: 
				begin
					OutLine('[', true, 3);
					OutLine(MConference[crossInt]^^[crossint2].Name, false, 4);
					OutLine('] ', false, 3);
					if thisUser.SL >= MConference[crossInt]^^[crossint2].SLtoPost then
						LettersPrompt(RetInStr(636), 'RQ', 1, true, false, true, char(0)){ <CR> = Next, R:eply, Q:uit  : }
					else
						LettersPrompt(RetInStr(637), 'Q', 1, true, false, true, char(0));	{ <CR> = Next, Q:uit  : }
					ScanNewDo := Scan5;
				end;
				Scan5: 
				begin
					if curprompt = 'Q' then
						GoHome
					else if (curPrompt = 'R') then
					begin
						fromQScan := true;
						fromMsgScan := true;
						saveInForum := inForum;
						saveInSub := inConf;
						crossInt3 := inMessage;
						inForum := crossInt;
						inConf := crossInt2;
						PostDo := postOne;
						BoardSection := post;
						wasSearching := false;
						reply := true;
						newmsg := true;
						replyToStr := curBase^^[inMessage - 1].fromuserName;
						replyToNum := curBase^^[inMessage - 1].fromUserNum;
						if curBase^^[inMessage - 1].anonyFrom then
						begin
							wasAnonymous := true;
							replyToAnon := true;
						end
						else
						begin
							wasAnonymous := false;
							replyToAnon := false;
						end;
						SetUpQuoteText(curBase^^[inMessage - 1].fromuserName, curBase^^[inMessage - 1].StoredAs, inForum, inConf);
						if (MConference[inForum]^^[inConf].AnonID = 0) then
							tb := false
						else
							tb := true;
						if (MConference[inForum]^^[inConf].RealNames) then
							tempString := thisUser.RealName
						else
							tempString := thisUser.UserName;
						if wasAnonymous then
							TheQuote.Header := MakeQuoteHeader('>>UNKNOWN<<', tempString, curBase^^[inMessage - 1].title, tb)
						else
							TheQuote.Header := MakeQuoteHeader(replyToStr, tempString, curBase^^[inMessage - 1].title, tb);

						if MConference[crossInt]^^[crossint2].Threading then
						begin
							if (curBase^^[inMessage - 1].title[1] <> char(0)) then
								replyStr := concat(char(0), 'Re: ', curBase^^[inMessage - 1].title)
							else
								replyStr := curBase^^[inMessage - 1].title;
						end
						else
							replyStr := concat('Re: ', curBase^^[inMessage - 1].title);
					end;
					ScanNewDo := Scan3;
				end;
				otherwise
			end;
		end;
	end;

	function NextMess: boolean;
		var
			gotOne: boolean;
	begin
		with curglobs^ do
		begin
			gotOne := false;
			while ((not gotOne) and (FromBeg) and ((atEMail + 1) <= availEmails)) or ((not gotOne) and (not FromBeg) and ((atEMail - 1) >= 0)) do
			begin
				if FromBeg then
					atEMail := atEMail + 1
				else
					atEmail := atEmail - 1;
				if (theEmail^^[atEMail].MType = 1) and (theEmail^^[atEMail].toUser > 0) then
					gotOne := true;
			end;
		end;
		if gotOne then
			nextmess := true
		else
			nextmess := false;
	end;

	function LastMess: boolean;
		var
			gotOne: boolean;
	begin
		with curglobs^ do
		begin
			gotOne := false;
			while ((not gotOne) and (FromBeg) and ((atEMail - 1) >= 0)) and ((not gotOne) and (not FromBeg) and ((atEMail + 1) >= 0)) do
			begin
				if FromBeg then
					atEmail := atEmail - 1
				else
					atEMail := atEMail + 1;
				if (theEmail^^[atEMail].MType = 1) and (theEmail^^[atEMail].toUser > 0) then
					gotOne := true;
			end;
		end;
		if gotOne then
			lastMess := true
		else
			lastmess := false;
	end;

	procedure AllMaPrint;
		var
			ts1, ts2: str255;
			printMail: emailRec;
	begin
		with curglobs^ do
		begin
			if textHnd <> nil then
			begin
				disposHandle(handle(textHnd));
				textHnd := nil;
			end;
			printMail := theEmail^^[atEmail];
			OutLine(concat('Title: ', printMail.title), true, 0);
			NumToString(printMail.fromUser, ts1);
			OutLine(concat('From : ', myUsers^^[printMail.fromUser - 1].UName, ' #', ts1), true, 0);
			NumToString(printMail.touser, ts1);
			OutLine(concat('To   : ', myUsers^^[printMail.toUser - 1].UName, ' #', ts1), true, 0);
			OutLine(concat('Date : ', getDate(printMail.dateSent)), true, 0);
			isMM := false;
			if printMail.multimail then
				isMM := true;
			WasAttach := false;
			if printMail.FileAttached then
			begin
				WasAttach := true;
				OutLine(concat('FILE ATTACHED: ', printMail.FileName), true, 0);
			end;
			bCR;
			textHnd := textHand(ReadMessage(printMail.storedAs, 0, 0));
			if textHnd <> nil then
			begin
				curtextPos := 0;
				OpenTextSize := GethandleSize(handle(textHnd));
				BoardAction := ListText;
				ListTextFile;
			end
			else
				OutLine('Message not found.', true, 0);
		end;
	end;

	procedure DoAllRead;
		var
			ts: str255;
			printEma: emailrec;
	begin
		with curglobs^ do
		begin
			case AllDo of
				AllOne: 
				begin
					if EqualString(curprompt, InitSystHand^^.overridePass, false, false) or sysoplogon then
					begin
						AllDo := AllOneA;
						bCR;
						YesNoQuestion(RetInStr(726), true);{Read All Mail From Most Recent? }
					end
					else
					begin
						OutLine('Incorrect.', true, 0);
						GoHome;
					end;
				end;
				AllOneA: 
				begin
					if curPrompt[1] = 'Y' then
					begin
						fromBeg := False;
						atEmail := AvailEmails;
					end
					else
					begin
						fromBeg := True;
						atEMail := -1
					end;
					if nextmess then
					begin
						AllMaPrint;
						AllDo := AllTwo;
					end
					else
					begin
						Outline('No mail.', true, 0);
						GoHome;
					end;
				end;
				AllTwo: 
				begin
					bCR;
{P-revious Removed}
					LettersPrompt(RetInStr(638), 'NDRQ', 1, true, false, true, char(0));	{N-ext, P-revious, D-elete, R-ead, Q-uit :}
					AllDo := AllThree;
				end;
				AllThree: 
				begin
					if curPrompt = '' then
					begin
						if nextMess then
						begin
							AllDo := AllTwo;
							AllMaPrint;
						end
						else
							GoHome;
					end
					else
						case curprompt[1] of
							'R': 
							begin
								AllDo := AllTwo;
								AllMaPrint;
							end;
							'Q': 
							begin
								GoHome;
							end;
							'P': 
							begin
								if not lastmess then
									if nextMess then
										;
								AllDo := AllTwo;
								AllMaPrint;
							end;
							'N': 
							begin
								if nextMess then
								begin
									AllDo := AllTwo;
									AllMaPrint;
								end
								else
									GoHome;
							end;
							'D': 
							begin
								if (WasAttach) and (not isMM) then
									DeleteFileAttachment(true, theEmail^^[atEMail].FileName);
								DeleteMail(atEmail);
								if (frombeg) and (atEMail - 1 > 0) then
									atEMail := atEMail - 1
								else if (not frombeg) and (atEMail + 1 <= availEMails) then
									atEmail := atEmail + 1;
								if nextMess then
								begin
									AllDo := AllTwo;
									AllMaPrint;
								end
								else
									GoHome;
							end;
						end;
				end;
				otherwise
			end;
		end;
	end;

	procedure DoListUsers;
		var
			tss: str255;
			tb, tb2: boolean;
	begin
		with curglobs^ do
		begin
			tb2 := false;
			if crossInt = 0 then
			begin
				crossInt := 1;
				BoardAction := repeating;
				if curPrompt = 'Y' then
					crossInt2 := 1
				else
					crossInt2 := 0;
			end
			else
			begin
				if not sysopStop and not aborted then
				begin
					repeat
						crossInt3 := crossInt3 + 1;
						tb := true;
						if (crossInt2 = 1) then
						begin
							tb := true;
							if MForum^^[inForum].AccessLetter <> char(0) then
								if (myUsers^^[crossInt3 - 1].AccessLetter[(byte(MForum^^[inForum].AccessLetter) - byte(64))]) and (myUsers^^[crossInt3 - 1].SL >= MForum^^[inForum].MinSL) and (AgeOk(myUsers^^[crossInt3 - 1].age, MForum^^[inForum].MinAge)) then
									tb := true
								else
									tb := false;
							if tb and (MConference[inForum]^^[inConf].AccessLetter <> char(0)) then
								if myUsers^^[crossInt3 - 1].AccessLetter[(byte(MConference[inForum]^^[inConf].AccessLetter) - byte(64))] then
									tb := true
								else
									tb := false;
							if tb and (MConference[inForum]^^[inConf].SLtoRead <= myUsers^^[crossInt3 - 1].SL) and (AgeOk(myUsers^^[crossInt3 - 1].age, MConference[inForum]^^[inConf].MinAge)) then
								tb := true
							else
								tb := false;
						end;
						if (not myUsers^^[crossInt3 - 1].dltd) and tb then
						begin
							NumToString(crossInt3, tss);
							OutLine(concat(myUsers^^[crossInt3 - 1].UName, ' #', tss), true, 0);
							tb2 := true;
						end;
					until tb2 or (crossInt3 = numUserRecs);
				end;
				if (crossInt3 = numUserRecs) or aborted then
				begin
					BoardAction := none;
					GoHome;
				end;
			end;
		end;
	end;

	procedure DoSysopCommands;
		var
			Accepted: str255;
	begin
		with curGlobs^ do
		begin
			crossint9 := crossint9 + 1;
			case crossint9 of
				1: 
				begin
					BufferbCR;
					Accepted := 'ABCDEFGHIJKLMN';
					if not inTransfer then
						BufferIt('//SYSOP  (MESSAGE Section)', true, 2)
					else
						BufferIt('//SYSOP  (TRANSFER Section)', true, 2);
					BufferbCR;
					BufferIt('A', true, 0);
					BufferIt('] Today''s BBS Stats                 //STATS', false, 1);
					BufferIt('B', true, 0);
					BufferIt('] Usage record                      //ZLOG', false, 1);
					BufferIt('C', true, 0);
					BufferIt('] BBS Log for Today                 //LOG', false, 1);
					BufferIt('D', true, 0);
					BufferIt('] BBS Log for Yesterday             //YLOG', false, 1);
					BufferIt('E', true, 0);
					BufferIt('] Network Log for Today             //NLOG', false, 1);
					BufferIt('F', true, 0);
					BufferIt('] Network Usage Log                 //NUSE', false, 1);
					BufferIt('G', true, 0);
					BufferIt('] Mail Auto-Deletion Stats          //DELETEMAILSTAT', false, 1);
					BufferIt('H', true, 0);
					BufferIt('] Free Transfer space               //FREEK', false, 1);
					BufferIt('I', true, 0);
					BufferIt('] List Mail Items                   //LISTMAIL', false, 1);
					BufferIt('J', true, 0);
					BufferIt('] List Directory Administrators     //LISTDA', false, 1);
					BufferIt('K', true, 0);
					BufferIt('] List Forum Moderators             //LISTFM', false, 1);
					BufferIt('L', true, 0);
					BufferIt('] List Conference Moderators        //LISTCM', false, 1);
					BufferIt('M', true, 0);
					BufferIt('] User editor                       //UEDIT', false, 1);
					BufferIt('N', true, 0);
					BufferIt('] System colors                     //COLORS', false, 1);
					if thisUser.SL = 255 then
					begin
						BufferIt('O', true, 0);
						BufferIt('] Emergency Quit                    //EQUIT', false, 1);
						BufferIt('P', true, 0);
						BufferIt('] Read all mail                     //MAILR', false, 1);
						BufferIt('Q', true, 0);
						BufferIt('] Change into a user                //CHUSER', false, 1);
						Accepted := concat(Accepted, 'OPQ');
					end;
					if inTransfer then
					begin
						if thisUser.SL = 255 then
						begin
							Accepted := concat(Accepted, 'RST');
							BufferIt('R', true, 0);
							BufferIt('] Rename files                      //REN', false, 1);
							BufferIt('S', true, 0);
							BufferIt('] Move files                        //MOVE', false, 1);
							BufferIt('T', true, 0);
							BufferIt('] Sort Transfer Directories         //SORT', false, 1);
						end
						else
						begin
							Accepted := concat(Accepted, 'OPQ');
							BufferIt('O', true, 0);
							BufferIt('] Rename files                      //REN', false, 1);
							BufferIt('P', true, 0);
							BufferIt('] Move files                        //MOVE', false, 1);
							BufferIt('Q', true, 0);
							BufferIt('] Sort Transfer Directories         //SORT', false, 1);
						end;
						if sysoplogon and (thisUser.SL = 255) then
						begin
							BufferIt('U', true, 0);
							BufferIt('] Upload entire directory           //UPLOADALL', false, 1);
							Accepted := concat(Accepted, 'U');
						end
						else if sysoplogon and (thisUser.SL <> 255) then
						begin
							BufferIt('R', true, 0);
							BufferIt('] Upload entire directory           //UPLOADALL', false, 1);
							Accepted := concat(Accepted, 'Q');
						end;
					end;
					bufferbCR;
					BufferIt('<CR>', true, 0);
					BufferIt(' to Quit', false, 1);
					BufferbCR;
					BufferbCR;
					ReleaseBuffer;
					LettersPrompt('Sysop Command : ', Accepted, 1, true, false, true, char(0));
				end;
				2: 
				begin
					if ((curPrompt[1] = 'O') and (thisUser.SL = 255)) then
					begin
						begin
							bCR;
							YesNoQuestion('Are you sure you want to shutdown the BBS (Y/N)? ', false);
						end;
					end
					else
					begin
						case curPrompt[1] of
							'A': 
								curPrompt := '//STATS';
							'B': 
								curPrompt := '//ZLOG';
							'C': 
								curPrompt := '//LOG';
							'D': 
								curPrompt := '//YLOG';
							'E': 
								curPrompt := '//NLOG';
							'F': 
								curPrompt := '//NUSE';
							'G': 
								curPrompt := '//DELETEMAILSTAT';
							'H': 
								curPrompt := '//FREEK';
							'I': 
								curPrompt := '//LISTMAIL';
							'J': 
								curPrompt := '//LISTDA';
							'K': 
								curPrompt := '//LISTFM';
							'L': 
								curPrompt := '//LISTCM';
							'M': 
								curPrompt := '//UEDIT';
							'N': 
								curPrompt := '//COLORS';
							'O': 
								if thisUser.SL = 255 then
{ //EQUIT, but handled above }
								else
									curPrompt := '//REN';
							'P': 
								if thisUser.SL = 255 then
									curPrompt := '//MAILR'
								else
									curPrompt := '//MOVE';
							'Q': 
								if thisUser.SL = 255 then
									curPrompt := '//CHUSER'
								else
									curPrompt := '//SORT';
							'R': 
								if thisUser.SL = 255 then
									curPrompt := '//REN'
								else
									curPrompt := '//UPLOADALL';
							'S': 
								curPrompt := '//MOVE';
							'T': 
								curPrompt := '//SORT';
							'U': 
								curPrompt := '//UPLOADALL';
							otherwise
							begin
								curPrompt[0] := char(0);
								GoHome;
							end;
						end;
						BoardSection := MainMenu;
						DoMainMenu;
					end;
				end;
				3: {//EQUIT}
				begin
					if curPrompt = 'Y' then
					begin
						bCR;
						curPrompt := '//EQUIT';
						BoardSection := MainMenu;
						DoMainMenu;
					end
					else
					begin
						curPrompt[0] := char(0);
						GoHome;
					end;
				end;
				otherwise
				begin
					OutLine('ERROR!', true, 6);
					GoHome;
				end;
			end;
		end;
	end;

	procedure CheckForExternalLaunch;
		var
			i, x, y: integer;
			s: str255;
	begin
		with curGlobs^ do
		begin
			x := -99;
			if crossLong = InitSystHand^^.UnUsed1 then
			begin
				for i := 1 to numExternals do
					if (myExternals^^[i].CheckMenu) and (myExternals^^[i].MenuCommand = curPrompt) then
					begin
						x := i;
						leave;
					end;
				InitSystHand^^.UnUsed1 := 0;
				ExternVars := 0;
				if x <> -99 then
					CallUserExternal(CALLMENU, x);
			end;
		end;
	end;

{$S HUtils4_2}
	procedure DoMainMenu;
		type
			NetSubRec = record
					Forum: integer;
					Sub: integer;
					NumImported: integer;
				end;
		var
			yaba, tempString2, tempString: str255;
			count, tempInt, tempInt2, tempint3: LongInt;
			dumRect: rect;
			abg: point;
			dere: sfTypeList;
			repo: SFReply;
			tempChar, keyPr: char;
			doneit, gotit, tempBool, tb2: boolean;
			i, b: integer;
			tempReal, tempReal2, tempReal3: real;
			therealPort: grafPtr;
			fnd: boolean;
			ttuser: userrec;
			tempLong, templong2: longint;
			TheFile, x: integer;
			result: OSErr;
			s26: string[26];
			s31: string[31];
	begin
		with curglobs^ do
		begin
			keyPr := curPrompt[1];
			if length(curPrompt) > 0 then
			begin
				MenuCommands := concat(MenuCommands, CurPrompt, ' ');
				if (keyPr >= char(48)) and (keyPr <= char(57)) and not inTransfer then
				begin
					StringToNum(curPrompt, tempInt);
					inConf := FindConference(inForum, tempInt);
					if inConf = 0 then
						OutLine(RetInStr(249), true, 0)  {Sub not available.}
					else
					begin
						if (thisUser.MessHeader <> MessOff) then
						begin
							s26 := MConference[inForum]^^[inConf].Name;
							s31 := MForum^^[inForum].Name;
							if thisUser.TerminalType = 1 then
							begin
								tempString := concat('Messages:', s31, ':', s26, ' AHDR');
								noPause := true;
							end
							else
								tempString := concat('Messages:', s31, ':', s26, ' HDR');
							if ReadTextFile(tempString, 0, true) then
							begin
								if thisUser.TerminalType = 1 then
									noPause := true;
								BoardAction := ListText;
							end;
						end;
					end;
					MainStage := Menutext;
					exit(doMainMenu);
				end
				else if (keyPr >= char(48)) and (keyPr <= char(57)) and inTransfer then
				begin
					StringToNum(curPrompt, tempInt);
					if SubDirOk(inRealDir, FindSub(InRealDir, tempint)) then
					begin
						inSubDir := tempint;
						InRealSubDir := FindSub(inRealDir, tempint);

						if (thisUser.TransHeader <> TransOff) then
						begin
							s26 := forums^^[inRealDir].dr[InRealSubDir].dirName;
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
					exit(doMainMenu);
				end;
				if length(MenuCommands) > 50 then
				begin
					SysOpLog(StringOf(RetInStr(570), MenuCommands), 0);	{      Menu Cmds: }
					MenuCommands := '';
				end;
				if length(curPrompt) = 2 then
				begin
					if curPrompt[2] = 'E' then
					begin
						HelpNum := 5;
						BoardSection := MultiMail;
						MultiDo := MultiOne;
					end;
					if (curPrompt[2] = 'F') and (thisUser.CoSysop) then
					begin
						bCR;
						LettersPrompt(RetInStr(251), '', 30, false, false, false, char(0));	{Send Form Letter To User: }
						CurEMailRec.fromuser := thisUser.Usernum;
						CurEMailRec.MType := 1;
						curEmailRec.multiMail := false;
						CurEMailRec.FileAttached := false;
						CurEMailRec.FileName := char(0);
						GetDateTime(curEMailRec.dateSent);
						numMultiUsers := 0;
						BoardSection := EMail;
						EmailDo := EmailFive;
						CallFMail := False;
					end;
				end
				else if length(CurPrompt) > 2 then
				begin
					UprString(Curprompt, false);
					if (curPrompt = '//SORT') and (inTransfer) then
					begin
						if (thisUser.coSysop) or DirOp(inRealDir, InRealSubDir, thisUser) or AreaOp(InRealDir, ThisUser) and inTransfer then
						begin
							if thisUser.CoSysOp then
							begin
								bCR;
								YesNoQuestion(RetInStr(252), false)	{Sort all dirs? }
							end
							else
								CurPrompt := 'N';
							BoardSection := Sort;
							SortDo := SortOne;
						end
						else
						begin
							MainStage := MenuText;
						end;
					end
					else if ((curPrompt = '//UEDIT') or (curPrompt = '//USEREDIT')) and (thisUser.coSysop) then
					begin
						SysopLog(RetInStr(253), 0);	{      @Ran Uedit}
						BoardSection := UEdit;
						UEDo := EnterUE;
						MaxLines := 0;
						crossint := thisUser.userNum;
					end
					else if (curprompt = '//MAILR') then
					begin
						if thisUser.SL = 255 then
						begin
							if not sysoplogon then
								LettersPrompt('SY: ', '', 9, false, false, true, 'X');
							BoardSection := ReadAll;
							AllDo := AllOne;
						end
						else
							GoHome;
					end
					else if (curPrompt = '//SYSOP') and (thisUser.coSysop) then
					begin
						BoardSection := SysopComm;
						crossint9 := 0;
					end
					else if (curPrompt = '//DELETEMAILSTAT') then
					begin
						if AvailEMails > 0 then
						begin
							templong := CheckDays(InitSystHand^^.MailDeleteDays);
							templong2 := 0;
							for i := (AvailEMails - 1) downto 0 do
								if (templong >= theEMail^^[i].dateSent) then
									if i - 1 > 0 then
									begin
										if templong >= theEMail^^[i - 1].dateSent then
										begin
											templong2 := i;
											leave;
										end;
									end
									else
									begin
										templong2 := i;
										leave;
									end;
							bCR;
							OutLine(concat('Number of EMails - ', stringOf(AvailEMails : 0)), true, 0);
							OutLine(StringOf('Number Of EMails To Delete - ', templong2 : 0), true, 0);
							OutLine(concat('Date Right Now - ', GetDate(-1)), true, 0);
							OutLine(concat('Calculated Deletion Date - ', GetDate(tempLong)), true, 0);
						end;
					end
					else if (curPrompt = '//LISTMAIL') and (thisUser.CoSysOp) then
					begin
						BoardSection := ListMail;
						crossInt3 := 0;
						crossInt := 0;
					end
					else if (curPrompt = '//LISTDA') and (thisUser.CoSysOp) then
					begin
						OutLine('## Directory Name                Directory Administrator(s)', true, 0);
						OutLine('-- ----------------------------  -----------------------------------------------', true, 0);
						for i := 1 to ForumIdx^^.numDirs[InRealSubDir] do
						begin
							if FindUser(stringOf(forums^^[InRealDir].dr[i].Operators[1] : 0), ttuser) then
								OutLine(stringOf(i : 2, ' ', forums^^[InRealDir].dr[i].dirName, ' ' : 28 - Length(forums^^[InRealDir].dr[i].dirName), '  ', ttuser.username, ' #', ttuser.usernum : 0), true, 2);
							if FindUser(stringOf(forums^^[InRealDir].dr[i].Operators[2] : 0), ttuser) then
								OutLine(stringOf(i : 2, ' ', forums^^[InRealDir].dr[i].dirName, ' ' : 28 - Length(forums^^[InRealDir].dr[i].dirName), '  ', ttuser.username, ' #', ttuser.usernum : 0), true, 2);
							if FindUser(stringOf(forums^^[InRealDir].dr[i].Operators[3] : 0), ttuser) then
								OutLine(stringOf(i : 2, ' ', forums^^[InRealDir].dr[i].dirName, ' ' : 28 - Length(forums^^[InRealDir].dr[i].dirName), '  ', ttuser.username, ' #', ttuser.usernum : 0), true, 2);
						end;
					end
					else if (curPrompt = '//FREEK') and (thisUser.CoSysOp) then
					begin
						OutLine('## Area Name               ## Directory Name           KBytes Free  Last U/l', true, 0);		{(FreeK(intDLStuff^^.sdirs^^[i, x].path) div 1024) : 9, 'K')}
						OutLine('-- ----------------------- -- -----------------------  -----------  --------', true, 0);
						for i := 1 to forumIdx^^.numforums do
						begin
							for tempint := 1 to forumIdx^^.numDirs[i - 1] do
								OutLine(stringOf(i - 1 : 2, ' ', copy(forumIdx^^.name[i - 1], 1, 22), ' ' : 23 - length(forumIdx^^.name[i - 1]), ' ', tempint : 2, ' ', copy(forums^^[i - 1].dr[tempint].dirName, 1, 22), ' ' : 23 - Length(forums^^[i - 1].dr[tempint].dirName), '  ', (FreeK(forums^^[i - 1].dr[tempint].path) div 1024) : 10, 'K  ', getdate(forumIdx^^.lastupload[i - 1, tempint])), true, 2);
						end;
					end
					else if (curPrompt = '//LISTFM') and (thisUser.CoSysop) then
					begin
						OutLine('Forum                  Forum Moderator(s)', true, 0);
						OutLine('---------------------  ------------------------------', true, 0);
						for i := 1 to InitSystHand^^.numMForums do
						begin
							if FindUser(stringOf(MForum^^[i].Moderators[1] : 0), ttuser) then
								OutLine(stringOf(copy(MForum^^[i].Name, 1, 20), ' ' : 21 - length(MForum^^[i].Name), '  ', ttuser.username, ' #', ttuser.usernum : 0), true, 2);
							if FindUser(stringOf(MForum^^[i].Moderators[2] : 0), ttuser) then
								OutLine(stringOf(copy(MForum^^[i].Name, 1, 20), ' ' : 21 - length(MForum^^[i].Name), '  ', ttuser.username, ' #', ttuser.usernum : 0), true, 2);
							if FindUser(stringOf(MForum^^[i].Moderators[3] : 0), ttuser) then
								OutLine(stringOf(copy(MForum^^[i].Name, 1, 20), ' ' : 21 - length(MForum^^[i].Name), '  ', ttuser.username, ' #', ttuser.usernum : 0), true, 2);
						end;
					end
					else if (curPrompt = '//LISTCM') and (thisUser.CoSysOp) then
					begin
						OutLine('Forum                  Conference                 Conference Moderator(s)', true, 0);
						OutLine('---------------------  -------------------------  ------------------------------', true, 0);
						for i := 1 to InitSystHand^^.numMForums do
						begin
							for tempint := 1 to MForum^^[i].NumConferences do
							begin
								if FindUser(stringOf(MConference[i]^^[tempInt].Moderators[1] : 0), ttuser) then
									OutLine(stringOf(copy(MForum^^[i].Name, 1, 20), ' ' : 21 - length(MForum^^[i].Name), '  ', copy(MConference[i]^^[tempInt].Name, 1, 25), ' ' : 26 - Length(MConference[i]^^[tempInt].Name), ' ', ttuser.username, ' #', ttuser.usernum : 0), true, 2);
								if FindUser(stringOf(MConference[i]^^[tempInt].Moderators[2] : 0), ttuser) then
									OutLine(stringOf(copy(MForum^^[i].Name, 1, 20), ' ' : 21 - length(MForum^^[i].Name), '  ', copy(MConference[i]^^[tempInt].Name, 1, 25), ' ' : 26 - Length(MConference[i]^^[tempInt].Name), ' ', ttuser.username, ' #', ttuser.usernum : 0), true, 2);
								if FindUser(stringOf(MConference[i]^^[tempInt].Moderators[3] : 0), ttuser) then
									OutLine(stringOf(copy(MForum^^[i].Name, 1, 20), ' ' : 21 - length(MForum^^[i].Name), '  ', copy(MConference[i]^^[tempInt].Name, 1, 25), ' ' : 26 - Length(MConference[i]^^[tempInt].Name), ' ', ttuser.username, ' #', ttuser.usernum : 0), true, 2);
							end;
						end;
					end
					else if (curPrompt = '//CHUSER') and (thisUser.SL = 255) then
					begin
						LettersPrompt(RetInStr(254), '', 30, false, false, true, char(0));	{User to change to? }
						BoardSection := ChUser;
					end
					else if (curPrompt = '//EQUIT') then
					begin
						if (thisUser.coSysop) and (thisUser.SL = 255) then
						begin
							OutLine(RetInStr(255), true, 6); {Emergency quit engaged.}
							quit := 2;
							BoardAction := none;
						end
						else
							GoHome;
					end
					else if (CurPrompt = '//VER') or (CurPrompt = '//VERSION') then
					begin
						OutLineC(concat('Hermes II Bulletin Board System Version ', HERMES_VERSION), true, 2);
						OutLineC('Copyright 1989-2009 by Michael Alyn Miller.  All rights reserved.', true, 2);
						OutLineC('Original version of Hermes by Will Price.', true, 2);
						bCR;
						OutLineC('http://www.HermesBBS.com/', true, 1);
						bCR;
						OutLineC(concat('Compiled on ', compdate, ' at ', comptime), true, 2);
						bCR;
						bCR;
						PAUSEPrompt(RetInStr(7));
						savedBdAction := none;
					end
					else if curPrompt = '//RESETC' then
					begin
						ResetUserColors(thisUser)
					end
					else if (curPrompt = '//COLOR') or (curPrompt = '//COLORS') then
					begin
						if thisUser.CoSysop then
						begin
							BoardSection := Colors;
							DefaultDo := DefaultOne;
						end;
					end
					else if (curPrompt = '//UPLOADALL') and (inTransfer) then
					begin
						if inTransfer and sysopLogon then
						begin
							if ModalQuestion(RetInStr(256), false, false) = 1 then	{Upload entire directory?}
							begin
								tempString := forums^^[inRealDir].dr[InRealSubDir].path;
								tempInDir := inRealDir;
								tempSubDir := InRealSubDir;
								UploadVref(tempString);
							end;
						end;
						goHome;
						boardAction := none;
					end
					else if (curPrompt = '//QSCAN') then
					begin
						crossint9 := 15;
						BoardSection := CatchUp;
					end
					else if (curPrompt = '//CATCHUP') then
					begin
						crossint9 := 0;
						BoardSection := CatchUp;
					end
					else if (curPrompt = '//STATS') then
					begin
						if thisUser.CoSysop then
						begin
							printSysopStats;
							bCR;
						end;
					end
					else if (curprompt = '//MOVE') then
					begin
						if inTransfer and ((thisUser.CoSysop) or DirOp(inRealDir, InRealSubDir, thisUser) or AreaOp(InRealDir, ThisUser)) then
						begin
							MoveDo := MoveOne;
							BoardSection := MoveFiles;
						end
						else
							GoHome;
					end
					else if (curprompt = '//REN') then
					begin
						if inTransfer and ((thisUser.CoSysop) or DirOp(inRealDir, InRealSubDir, thisUser) or AreaOp(InRealDir, ThisUser)) then
						begin
							HelpNum := 32;
							RenDo := RenOne;
							BoardSection := RenFiles;
						end
						else
							GoHome;
					end
					else if (curPrompt = '//UPLOAD') then
					begin
						if not inTransfer then
						begin
							OutLine(RetInStr(258), true, 0);	{You may now upload a message, max 30000 bytes.}
							bCR;
							UpMess := MessUpOne;
							BoardSection := MessUp;
						end
						else
							GoHome;
					end
					else if (curPrompt = '//LOAD') then
					begin
						if not inTransfer and sysopLogon then
						begin
							SetPT(abg, 40, 40);
							dere[0] := 'TEXT';
							SFGetFile(abg, 'Load which file?', nil, 1, dere, nil, repo);
							if repo.good then
							begin
								result := FSDelete(StringOf(sharedPath, 'Misc:Local Workspace ', activeNode : 0), 0);
								useWorkspace := 1;
								tempString := PathNameFromWD(repo.vRefNum);
								tempString := concat(tempString, repo.fName);
								if copy1File(tempString, StringOf(sharedPath, 'Misc:Local Workspace ', activeNode : 0)) = noErr then
									;
								OutLine(RetInStr(259), true, 0);	{Message loaded.  The next post or email will contain that text.}
								bCR;
							end;
							goHome;
						end
						else
							goHome;
					end
					else if (CurPrompt = '//NLOG') then
					begin
						if thisUser.CoSysop then
						begin
							if ReadTextFile('Misc:Network Today Log', 0, true) then
							begin
								BoardAction := ListText;
								prompting := false;
								ListTextFile;
							end
							else
							begin
								OutLine('Network today log not found.', true, 0);
							end;
						end;
					end
					else if (CurPrompt = '//NUSE') then
					begin
						if thisUser.CoSysop then
						begin
							if ReadTextFile('Misc:Network Usage Record', 0, true) then
							begin
								BoardAction := ListText;
								prompting := false;
								ListTextFile;
							end
							else
							begin
								OutLine('Network usage record not found.', true, 0);
							end;
						end;
					end
					else if (CurPrompt = '//LOG') then
					begin
						if thisUser.CoSysop then
						begin
							if ReadTextFile('Misc:Today Log', 0, true) then
							begin
								BoardAction := ListText;
								prompting := false;
								ListTextFile;
							end
							else
							begin
								OutLine(RetInStr(260), true, 0);		{Today Log file not found.}
							end;
						end;
					end
					else if (curPrompt = '//CHECKUSAGE') then
					begin
						OutLine(StringOf('Forum #: ', inForum : 0), true, 0);
						for i := 1 to MForum^^[inForum].numConferences do
						begin
							OutLine(concat('  Conference: ', MConference[inForum]^^[i].Name), true, 0);
							TheFile := OpenMData(inForum, i, true);
							result := FSClose(TheFile);
							templong := GetHandleSize(handle(curIndex));
							templong := templong div 2;
							OutLine(StringOf('    Number Indexes: ', templong : 0), true, 0);
							templong2 := 0;
							for x := 1 to templong do
								if curIndex^^[x] = 0 then
									templong2 := templong2 + 1;
							OutLine(StringOf('    Number Un-used Indexes: ', templong2 : 0), true, 0);
							OutLine(StringOf('    Bytes Wasted in Indx file: ', templong2 * 2 : 0), true, 0);
							templong2 := templong - templong2;
							TheFile := OpenMData(inForum, i, false);
							result := GetEOF(TheFile, templong);
							result := FSClose(TheFile);
							templong2 := templong2 * 512;
							if templong > templong2 then
								templong2 := templong - templong2
							else
								templong2 := 0;
							OutLine(StringOf('    Bytes Wasted in Text file: ', templong2 : 0), true, 0);
						end;
					end
					else if (curprompt = '//LISTPTR') then
					begin
						for i := 1 to MForum^^[inForum].numConferences do
						begin
							OpenBase(inForum, i, false);
							OutLine(StringOf(i : 0, ' QScanPtr: ', thisUser.LastMsgs[inForum, i] : 0, ' Conf QScanPtr: ', curBase^^[curNumMess - 1].DateEn : 0), true, 0);
						end;
					end
					else if (CurPrompt = '//ZLOG') then
					begin
						if thisUser.CoSysop then
						begin
							if ReadTextFile('Misc:Usage Record', 0, true) then
							begin
								BoardAction := ListText;
								prompting := false;
								ListTextFile;
							end
							else
							begin
								OutLine(RetInStr(261), true, 0);	{Usage Record file not found.}
							end;
						end;
					end
					else if (CurPrompt = '//YLOG') then
					begin
						if thisUser.CoSysop then
						begin
							Date2Secs(InitSystHand^^.lastMaint, tempint);
							IUDateString(tempint - 86400, shortDate, tempstring);
							if ReadTextFile(concat(sharedPath, 'Logs:', tempstring), 0, false) then
							begin
								BoardAction := ListText;
								prompting := false;
								ListTextFile;
							end
							else
							begin
								OutLine(RetInStr(262), true, 0);	{Yesterday Log file not found.}
							end;
						end;
					end
					else
					begin
						crosslong := InitSystHand^^.UnUsed1;
						crossint3 := 699;
						CheckForExternalLaunch;
					end;
				end
				else if length(curPrompt) = 1 then
					if not inTransfer then
					begin
						case keyPr of
							'$': 
							begin
								BoardSection := MessageSearcher;
								MessSearchDo := MSearch1;
							end;
							'O': 
							begin
								BoardSection := OffStage;
								OffDo := SureQuest;
								HelpNum := 12;
							end;
							'*': 
								PrintConfList(inForum);
							'K': 
							begin
								BoardSection := Killmail;
								KillDo := KillOne;
								HelpNum := 23;
							end;
							'G': 
							begin
								BoardSection := GFiles;
								GFileDo := G1;
								HelpNum := 23;
							end;
							'S': 
							begin
								BoardSection := ChatStage;
								ChatDo := ChatOne;
								HelpNum := 39;
							end;
							'R': 
							begin
								tb2 := true;
								if MConferenceOk(inForum, inConf) then
									tb2 := true
								else
									tb2 := false;
								if tb2 and (MForumOk(inForum)) then
								begin
									BoardSection := QScan;
									QDo := QFive;
									threadMode := false;
									HelpNum := 11;
								end
								else
								begin
									OutLine(RetInStr(263), true, 0);    {You can''t read the messages here.}
									GoHome;
								end;
							end;
							']': 
								if (inForum + 1 <= InitSystHand^^.numMForums) then
								begin
									tempInt := 0;
									for i := inForum + 1 to InitSystHand^^.numMForums do
										if MForumOk(i) then
										begin
											tempInt := i;
											Leave;
										end;
									if tempInt <> 0 then
									begin
										inForum := tempInt;
										inConf := 51;
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
												tempString := concat('Messages:', s31, ':', s26, ' AHDR')
											else
												tempString := concat('Messages:', s31, ':', s26, ' HDR');
											if ReadTextFile(tempString, 0, true) then
											begin
												if thisUser.TerminalType = 1 then
													noPause := true;
												BoardAction := ListText;
											end;
										end;
									end;
								end;
							'[': 
								if (inForum - 1 > 0) then
								begin
									tempInt := 0;
									for i := inForum - 1 downto 1 do
										if MForumOk(i) then
										begin
											tempInt := i;
											Leave;
										end;
									if tempInt <> 0 then
									begin
										inForum := tempInt;
										inConf := 51;
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
												tempString := concat('Messages:', s31, ':', s26, ' AHDR')
											else
												tempString := concat('Messages:', s31, ':', s26, ' HDR');
											if ReadTextFile(tempString, 0, true) then
											begin
												if thisUser.TerminalType = 1 then
													noPause := true;
												BoardAction := ListText;
											end;
										end;
									end;
								end;
							'+', '>': 
							begin
								if (MForum^^[inForum].NumConferences > inConf) and (MForumOk(inForum)) then
								begin
									i := inConf;
									gotit := false;
									repeat
										i := i + 1;
										if MConferenceOk(inForum, i) then
										begin
											inConf := i;
											gotIt := true;
										end;
									until (i = MForum^^[inForum].NumConferences) or GotIt;
									if not GotIt then
										OutLine(RetInStr(249), true, 0)
									else if (thisUser.MessHeader <> MessOff) then
									begin
										s26 := MConference[inForum]^^[inConf].Name;
										s31 := MForum^^[inForum].Name;
										if thisUser.TerminalType = 1 then
											tempString := concat('Messages:', s31, ':', s26, ' AHDR')
										else
											tempString := concat('Messages:', s31, ':', s26, ' HDR');
										if ReadTextFile(tempString, 0, true) then
										begin
											if thisUser.TerminalType = 1 then
												noPause := true;
											BoardAction := ListText;
										end;
									end;
								end
								else
									OutLine(RetInStr(249), true, 0);
								GoHome;
							end;
							'-', '<': 
							begin
								if (inConf > 1) and (MForumOk(inForum)) then
								begin
									i := inConf;
									gotit := false;
									repeat
										i := i - 1;
										if MConferenceOk(inForum, i) then
										begin
											inConf := i;
											GotIt := True;
										end;
									until (i = 1) or GotIt;
									if not GotIt then
										OutLine(RetInStr(249), true, 0)
									else if (thisUser.MessHeader <> MessOff) then
									begin
										s26 := MConference[inForum]^^[inConf].Name;
										s31 := MForum^^[inForum].Name;
										if thisUser.TerminalType = 1 then
											tempString := concat('Messages:', s31, ':', s26, ' AHDR')
										else
											tempString := concat('Messages:', s31, ':', s26, ' HDR');
										if ReadTextFile(tempString, 0, true) then
										begin
											if thisUser.TerminalType = 1 then
												noPause := true;
											BoardAction := ListText;
										end;
									end;
								end
								else
									OutLine(RetInStr(249), true, 0);
								GoHome;
							end;
							'I': 
							begin
								bCR;
								bCR;
								if ReadTextFile('BBS Info', 1, false) then
								begin
									if thisUser.TerminalType = 1 then
										noPause := true;
									ClearScreen;
									boardAction := ListText;
									ListTextFile;
								end
								else
								begin
									OutLine('''BBS Info'' file not found.', true, 0);
								end;
							end;
							'N', 'Z': 
							begin
								if KeyPr = 'Z' then
									inZScan := true
								else
									inZScan := false;
								if MForumOk(inForum) then
								begin
									OutLine(RetInStr(264), true, 3);	{<< Q-Scan All >>}
									bCR;
									BoardSection := QScan;
									QDo := Qone;
									saveInForum := inForum;
									saveInsub := inConf;
									threadMode := false;
									inNScan := true;
									inConf := 0;
									inForum := 0;
									repeat
										inforum := inforum + 1;
									until (MForumOk(inForum)) or (inForum = 20);
									readMsgs := true;
								end
								else
								begin
									OutLine(RetInStr(263), true, 0);
									GoHome;
								end;
							end;
							'Q': 
							begin
								tb2 := true;
								if MConferenceOk(inForum, inConf) then
								begin
									threadMode := false;
									saveInforum := inForum;
									saveInSub := inConf;
									BoardSection := QScan;
									QDo := Qone;
								end
								else
								begin
									OutLine(RetInStr(263), true, 0);
									GoHome;
								end;
							end;
							'@': 
							begin
								BoardSection := ScanNew;
								ScanNewDo := Scan1;
								curPrompt := 'Y';
							end;
							'W': 
							begin
								BoardSection := Noder;
								NodeDo := NodeOne;
							end;
							'.': 
							begin
								BoardSection := EXTERNAL;
								activeuserExternal := -1;
							end;
							'J': 
							begin
								PrintForumList;
								bCR;
								NumbersPrompt(RetInStr(265), '', crossint1, 1);	{Jump to ? }
								BoardSection := ReadMail;
								ReadDo := JumpForum;
							end;
							'U': 
							begin
								if not ThisUser.CantListUser then
								begin
									bCR;
									BoardSection := USList;
									crossInt3 := 0;
									crossInt := 0;
									YesNoQuestion(RetInStr(266), false);	{List only users with access to this sub? }
								end;
							end;
							'X': 
							begin
								if thisUser.Expert then
									thisUser.Expert := false
								else
									thisUser.Expert := True;
							end;
							'T': 
							begin
								closeBase;
								if not InitSystHand^^.closedTransfers then
								begin
									if isPostRatioOK or (not ThisUser.PCRatioOn) then
									begin
										if (thisUser.onToday = 1) and ((not readMsgs) and thisUser.ReadBeforeDL) and not (thisUser.coSysop) then
										begin
											Outline(RetInStr(115), true, 6);
											Outline(RetInStr(116), true, 6);
											Outline(RetInStr(117), true, 6);
											GoHome;
										end
										else
										begin
											inTransfer := true;
											bCR;
										end;
									end
									else
									begin
										OutLine(StringOf(RetInStr(118), (1 / thisUser.postRatioOneTo) : 0 : 2, '.'), true, 0);
										GoHome;
									end;
								end
								else
								begin
									OutLine(RetInStr(119), true, 0);
									GoHome;
								end;
							end;
							'Y': 
							begin
								ClearScreen;
								PrintUserStuff;
							end;
							'A': 
							begin
								BoardSection := Amsg;
								AutoDo := AutoOne;
								HelpNum := 19;
							end;
							'L': 
							begin
								OutLine(RetInStr(639), true, 0);	{Call #    Time    Nd  CT   ##   Username                   Speed}
								OutLine(RetInStr(640), true, 0);	{======  ========  ==  ==  ====  =========================  ================}
								bCR;
								if ReadTextFile('Misc:Brief Log', 0, true) then
								begin
									boardAction := ListText;
									ListTextFile;
								end
								else
								begin
									OutLine(RetInStr(267), true, 0);	{Brief Log file not found.}
									GoHome;
								end;
							end;
							'B': 
							begin
								BoardSection := BBSlist;
								BBSldo := Bone;
								HelpNum := 25;
							end;
							'F': 
							begin
								BoardSection := EMail;
								EmailDo := EmailOne;
								Reply := False;
								if InitFBHand^^.numfeedbacks > 0 then
								begin
									OutLine(RetInStr(268), true, 0);		{Feedback Options: }
									bcr;
									OutLine(RetInStr(269), true, 0); {##### Username                         Speciality}
									OutLine(RetInStr(270), true, 0); {===== ================================ ========================================}
									for i := 1 to InitFBHand^^.numfeedbacks do
									begin
										OutLine(stringof(InitFBHand^^.userNum[i] : 5, ' ', myUsers^^[InitFBHand^^.userNum[i] - 1].Uname, ' ' : 32 - length(myUsers^^[InitFBHand^^.userNum[i] - 1].Uname), ' ', InitFBHand^^.speciality[i]), true, 2);
									end;
									bCR;
									bCR;
									NumbersPrompt(RetInStr(271), 'Q', numuserrecs, 1);	{Select A User [Q=Quit]: }
									EmailDo := EmailCheck;
								end
								else
									CurPrompt := '1';
								sentAnon := false;
								callFMail := false;
							end;
							'=': 
							begin
								OutLine('Forum Moderators', true, 2);
								OutLine('-------------------------', true, 2);
								if FindUser(stringOf(MForum^^[inForum].Moderators[1] : 0), ttuser) then
									OutLine(stringOf(ttuser.username, ' #', ttuser.usernum : 0), true, 1);
								if FindUser(stringOf(MForum^^[inForum].Moderators[2] : 0), ttuser) then
									OutLine(stringOf(ttuser.username, ' #', ttuser.usernum : 0), true, 1);
								if FindUser(stringOf(MForum^^[inForum].Moderators[3] : 0), ttuser) then
									OutLine(stringOf(ttuser.username, ' #', ttuser.usernum : 0), true, 1);
								bCR;
								OutLine('Conference Moderators', true, 2);
								OutLine('-------------------------', true, 2);
								if FindUser(stringOf(MConference[inForum]^^[inConf].Moderators[1] : 0), ttuser) then
									OutLine(stringOf(ttuser.username, ' #', ttuser.usernum : 0), true, 1);
								if FindUser(stringOf(MConference[inForum]^^[inConf].Moderators[2] : 0), ttuser) then
									OutLine(stringOf(ttuser.username, ' #', ttuser.usernum : 0), true, 1);
								if FindUser(stringOf(MConference[inForum]^^[inConf].Moderators[3] : 0), ttuser) then
									OutLine(stringOf(ttuser.username, ' #', ttuser.usernum : 0), true, 1);
							end;
							'C': 
							begin
								BoardSection := ChatRoom;
								ChatRoomDo := EnterMain;
								HelpNum := 3;
							end;
							'D': 
							begin
								BoardSection := Defaults;
								DefaultDo := DefaultOne;
								HelpNum := 4;
							end;
							'E': 
							begin
								BoardSection := Email;
								EmailDo := WhichUser;
								HelpNum := 14;
							end;
							'P': 
							begin
								HelpNum := 6;
								BoardSection := Post;
								PostDo := PostOne;
								wasSearching := false;
								reply := false;
								replytoStr := 'All';
							end;
							'M': 
							begin
								BoardSection := ReadMail;
								ReadDo := ReadOne;
							end;
							'?': 
							begin
								MainStage := TextForce;
							end;
							otherwise
							begin
								crosslong := InitSystHand^^.UnUsed1;
								crossint3 := 703;
								CheckForExternalLaunch;
							end;
						end;
					end
					else
					begin
						case keyPr of
							'?': 
								MainStage := TextForce;
							'=': 
							begin
								OutLine('Area Administrators', true, 2);
								OutLine('-------------------', true, 2);
								if FindUser(stringOf(forumIdx^^.Ops[InRealDir, 1] : 0), ttuser) then
									OutLine(stringOf(ttuser.username, ' #', ttuser.usernum : 0), true, 1);
								if FindUser(stringOf(forumIdx^^.Ops[InRealDir, 2] : 0), ttuser) then
									OutLine(stringOf(ttuser.username, ' #', ttuser.usernum : 0), true, 1);
								if FindUser(stringOf(forumIdx^^.Ops[InRealDir, 3] : 0), ttuser) then
									OutLine(stringOf(ttuser.username, ' #', ttuser.usernum : 0), true, 1);
								bCR;
								OutLine('Directory Administrators', true, 2);
								OutLine('------------------------', true, 2);
								if FindUser(stringOf(forums^^[InRealDir].dr[inRealSubDir].Operators[1] : 0), ttuser) then
									OutLine(stringOf(ttuser.username, ' #', ttuser.usernum : 0), true, 1);
								if FindUser(stringOf(forums^^[InRealDir].dr[inRealSubDir].Operators[2] : 0), ttuser) then
									OutLine(stringOf(ttuser.username, ' #', ttuser.usernum : 0), true, 1);
								if FindUser(stringOf(forums^^[InRealDir].dr[inRealSubDir].Operators[3] : 0), ttuser) then
									OutLine(stringOf(ttuser.username, ' #', ttuser.usernum : 0), true, 1);
							end;
							']': 
								if (InRealDir + 1 <= forumidx^^.numforums) then
								begin
									tempInt := 0;
									for i := inRealDir + 1 to forumidx^^.numforums do
										if ForumOk(i) then
										begin
											tempInt := i;
											Leave;
										end;
									if tempInt <> 0 then
									begin
										inDir := inDir + 1;
										inRealDir := tempInt;
										InSubDir := 1;
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
							'[': 
							begin
								if (InRealDir - 1 >= 0) then
								begin
									tempInt := -1;	{Support for Sysop Area}
									for i := inRealDir - 1 downto 0 do
										if ForumOk(i) then
										begin
											tempInt := i;
											Leave;
										end;
									if tempInt <> -1 then
									begin
										inDir := inDir - 1;
										inRealDir := tempInt;
										InSubDir := 1;
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
							'+', '>': 
							begin
								if ForumIdx^^.numDirs[inRealDir] >= (inRealSubDir + 1) then
								begin
									tb2 := true;
									if SubDirOk(InRealDir, InRealSubDir + 1) then
									begin
										InRealSubDir := InRealSubDir + 1;
										inSubDir := FindSub(InRealDir, InRealSubDir);

										if (thisUser.TransHeader <> TransOff) then
										begin
											s26 := forums^^[inRealDir].dr[InRealSubDir].dirName;
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
									end
									else
										Outline(RetInStr(120), true, 0);
								end
								else
									OutLine(RetInStr(120), true, 0);
								GoHome;
								bCR;
							end;
							'.': 
							begin
								BoardSection := EXTERNAL;
								activeuserExternal := -1;
							end;
							'I': 
							begin
								bCR;
								bCR;
								if ReadTextFile('BBS Info', 1, false) then
								begin
									if thisUser.TerminalType = 1 then
										noPause := true;
									ClearScreen;
									boardAction := ListText;
									ListTextFile;
								end
								else
								begin
									OutLine('''BBS Info'' file not found.', true, 0);
								end;
							end;
							'W': 
							begin
								BoardSection := Noder;
								NodeDo := NodeOne;
							end;
							'H': 
							begin
								BoardSection := PrintXFerTree;
								crossint9 := 0;
							end;
							'-', '<': 
							begin
								if inRealSubDir > 1 then
								begin
									if SubDirOk(InRealDir, InRealSubDir - 1) then
									begin
										InRealSubDir := InRealSubDir - 1;
										inSubDir := FindSub(InRealDir, InRealSubDir);

										if (thisUser.TransHeader <> TransOff) then
										begin
											s26 := forums^^[inRealDir].dr[InRealSubDir].dirName;
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
									end
									else
										Outline(RetInStr(120), true, 0);
								end
								else
									OutLine(RetInStr(120), true, 0);
								MainStage := MenuText;
								bCR;
							end;
							'P': 
							begin
								IUTimeString(lastFScan, TRUE, tempString2);
								Outline(concat(RetInStr(12), getDate(lastFScan), ' at ', tempString2), true, 0);
								OutLine(RetInStr(121), true, 0);
								OutLine(RetInStr(122), true, 0);
								bCR;
								HelpNum := 13;
								LettersPrompt(': ', '', -1, true, false, false, char(0));
								BoardSection := limDate;
							end;
							'L': 
							begin
								BoardSection := ListFiles;
								sysopStop := false;
								ListDo := ListOne;
							end;
							'F': 
							begin
								sysopStop := false;
								BoardSection := FindDesc;
								FDescDo := FDesc1;
								OutLine(RetInStr(272), true, 0);	{Find description - Enter string to search for in file description:}
								bCR;
								LettersPrompt(': ', '', 58, false, false, false, char(0));
								HelpNum := 21;
							end;
							'S': 
							begin
								BoardSection := ListFiles;
								sysopStop := false;
								ListDo := ListSix;
								OutLine(RetInStr(273), true, 3);	{Search all directories.}
								bCR;
								bCR;
								LettersPrompt(RetInStr(274), '', 20, false, false, false, char(0));	{Enter full or partial filename: }
							end;
							'J': 
							begin
								PrintDirList(true);
								BoardSection := ReadMail;
								ReadDo := JumpForum;
							end;
							'N': 
							begin
								ListDo := ListFive;
								BoardSection := ListFiles;
								bCR;
								YesNoQuestion(RetInStr(275), false);	{Search all directories? }
							end;
							'Y': 
							begin
								bCR;
								ClearScreen;
								OutLine(stringOf(RetInStr(727), doNumber(thisUser.numUploaded)), true, 0);{Total Number Of Files Uploaded        : }
								OutLine(stringOf(RetInStr(728), doNumber(thisUser.uploadedk), 'k'), true, 0);{Total Number Of KBytes Uploaded       : }
								if thisUser.numUploaded > 0 then
									OutLine(stringOf(RetInStr(729), doNumber((thisUser.uploadedk div thisUser.numUploaded)), 'k'), true, 0);{Average KBytes Per Upload             : }
								OutLine(stringOf(RetInStr(730), doNumber(thisUser.NumDownloaded)), true, 0);{Total Number Of Files Downloaded      : }
								OutLine(stringOf(RetInStr(731), doNumber(thisUser.DownLoadedK), 'k'), true, 0);{Total Number Of KBytes Downloaded     : }
								if thisUser.numDownloaded > 0 then
									OutLine(stringOf(RetInStr(732), doNumber((thisUser.DownLoadedK div thisUser.NumDownLoaded)), 'k'), true, 0);{Average KBytes Per Download           : }
								OutLine(stringOf(RetInStr(733), doNumber(thisUser.DlsByOther)), true, 0);{Number Of Uploads Downloaded By Others: }
								OutLine(stringOf(RetInStr(734), doNumber(thisUser.DLCredits), 'k'), true, 0);{Amount Of DL Credits Available        : }
								OutLine(stringOf(RetInStr(735), doNumber(thisUser.NumULToday)), true, 0);{Number Of Files Uploaded Today        : }
								OutLine(stringOf(RetInStr(736), doNumber(thisUser.KBULToday), 'k'), true, 0);{Number Of KBytes Uploaded Today       : }
								OutLine(stringOf(RetInStr(737), doNumber(thisUser.NumDLToday)), true, 0);{Number Of Files Downloaded Today      : }
								OutLine(stringOf(RetInStr(738), doNumber(thisUser.KBDLToday), 'k'), true, 0);{Number Of KBytes Downloaded Today     : }
								DLRatioStr(tempString2, activeNode);
								OutLine(stringOf(RetInStr(739), tempString2), true, 0);{Your Upload/Download Ratio Is         : }
								if (ThisUser.UDRatioOn) then
								begin
									GoodRatioStr(tempString2);
									OutLine(stringOf(RetInStr(740), tempString2), true, 0);{Required Ratio To Download Is         : }
								end;
								OutLine(stringOf(RetInStr(741), thisUser.DSL : 0), true, 0);	{Your Download Security Level Is       : }
								bCR;
								MainStage := MenuText;
							end;
							'D': 
							begin
								BoardSection := Download;
								DownDo := DownOne;
								tempInDir := inRealDir;
								tempSubDir := inRealSubDir;
								HelpNum := 20;
							end;
							'U': 
							begin
								tempInDir := inRealDir;
								tempSubDir := inRealSubDir;
								BoardSection := Upload;
								UploadDo := UpOne;
							end;
							'Z': 
							begin
								tempInDir := 0;
								tempSubDir := 1;
								BoardSection := Upload;
								UploadDo := UpOne;
								OutLine(RetInStr(282), true, 0);	{Sending file to sysop :-}
							end;
							'T': 
							begin
								BoardSection := TranDef;
								TransDo := TrOne;
								helpnum := 33;
							end;
							'C': 
							begin
								BoardSection := ChatRoom;
								ChatRoomDo := EnterMain;
{BoardSection := ChatStage;}
{ChatDo := ChatOne;}
							end;
							'R': 
							begin
								BoardSection := RmvFiles;
								RFDo := RFone;
								HelpNum := 31;
							end;
							'M': 
							begin
								Helpnum := 26;
								if (thisUser.coSysop) or DirOp(inRealDir, InRealSubDir, thisUser) or AreaOp(InRealDir, ThisUser) then
								begin
									BoardSection := MoveFiles;
									MoveDo := MoveOne;
								end
								else
									GoHome;
							end;
							'O': 
							begin
								BoardSection := OffStage;
								OffDo := SureQuest;
							end;
							'X': 
							begin
								if thisUser.Expert then
									thisUser.Expert := false
								else
									thisUser.Expert := True;
							end;
							'B': 
							begin
								BoardSection := Batch;
								BatDo := BatOne;
								HelpNum := 22;
							end;
							'*': 
							begin
								PrintSubDirList(inRealDir);
								MainStage := MenuText;
							end;
							'Q': 
							begin
								inTransfer := false;
								MainStage := MenuText;
								CloseDirectory;
							end;
							otherwise
							begin
								crosslong := InitSystHand^^.UnUsed1;
								crossint3 := 766;
								CheckForExternalLaunch;
							end;
						end;
					end;
			end;
		end;
	end;

end.