{ Segments: HermesUtils_1 }
unit HermesUtils;

interface
	uses
		AppleTalk, ADSP, Serial, Sound, TCPTypes, Initial, LoadAndSave, NodePrefs2, NodePrefs, SystemPrefs, Message_Editor, User, inpOut4, Quoter, inpOut, MessNTextOutput, FileTrans3;

	procedure DoEMail;
	procedure DoMailCommand (Pres: str255);
	procedure DoPosting;
	procedure DoQScan;
	procedure NScanCalc;
	procedure DoRemove;
	function MakeInternetAddress (TheLine: str255): str255;
	procedure MakeNetAddress;

implementation


{$S HermesUtils_1}
	procedure GetTitle (mess: integer; var tit: str255; var poser: integer);
	begin
		with curglobs^ do
		begin
			if mess <= curNumMess then
			begin
				tit := curBase^^[mess - 1].title;
				poser := curBase^^[mess - 1].fromUserNum;
			end
			else
				tit := '';
		end;
	end;

	function GoodForum (whichFor: integer): boolean;
		var
			a: boolean;
			i: integer;
	begin
		with curglobs^ do
		begin
			a := false;
			goodForum := false;
			if (MForumOk(whichFor)) and (InitSystHand^^.numMForums >= whichFor) then
			begin
				for i := 1 to MForum^^[whichFor].NumConferences do
					if (thisUser.whatNScan[whichFor, i]) and (MConferenceOk(whichFor, i)) then
						a := true;
				if a then
					GoodForum := true;
			end;
		end;
	end;

	procedure NScanCalc;
		var
			FoundConferenceNum, onConf: integer;
			ttt1, ttt2: str255;
			gotAForum, tb2: boolean;
	begin
		with curglobs^ do
		begin
			lnsPause := 0;
			FoundConferenceNum := -1;
			onConf := inConf;
			repeat
				onConf := onConf + 1;
				tb2 := true;
				if MConferenceOk(inForum, onConf) and (thisUser.whatNScan[inForum, onConf]) and (MForum^^[inForum].NumConferences >= onConf) then
					FoundConferenceNum := onConf
				else if (MForum^^[inForum].NumConferences < onConf) then
				begin
					if inForum < (InitSystHand^^.numMForums) then
					begin
						gotAForum := false;
						repeat
							inForum := inForum + 1;
							if GoodForum(inForum) then
								gotAForum := true;
						until gotAForum or (inForum >= InitSystHand^^.numMForums);
						if gotAForum then
						begin
							OutLine(concat('<< ', RetInStr(9), ' ', MForum^^[inForum].Name, ' >>'), true, 3);
							bCR;
							lnsPause := 0;
							onConf := 0;
						end
						else
						begin
							OutLine(RetInStr(61), true, 3);
							lnsPause := 0;
							inNScan := false;
							inZScan := false;
							inForum := saveInForum;
							inConf := saveInSub;
							fromQScan := false;
							GoHome;
							FoundConferenceNum := 101;
							if (thisUser.NTransAfterMess) and not (InitSystHand^^.closedTransfers) then
							begin
								ListDo := ListFive;
								BoardSection := ListFiles;
								bCR;
								IUTimeString(lastFScan, TRUE, ttt2);
								bCR;
								OutLine(concat(RetInStr(60), getDate(lastFScan), ' at ', ttt2, '.'), true, 1);
								curPrompt := 'Y';
							end;
						end;
					end
					else
					begin
						OutLine(RetInStr(61), true, 3);
						lnsPause := 0;
						inNScan := false;
						inZScan := false;
						inForum := saveInForum;
						inConf := saveInSub;
						GoHome;
						fromQScan := false;
						FoundConferenceNum := 101;
						if thisUser.NTransAfterMess and not (InitSystHand^^.closedTransfers) then
						begin
							lnsPause := 0;
							ListDo := ListFive;
							BoardSection := ListFiles;
							bCR;
							IUTimeString(lastFScan, TRUE, ttt2);
							bCR;
							OutLine(concat(RetInStr(60), getDate(lastFScan), ' at ', ttt2, '.'), true, 1);
							curPrompt := 'Y';
						end;
					end;
				end;
			until FoundConferenceNum <> -1;
			if FoundConferenceNum < 51 then
			begin
				inConf := onConf;
				BoardSection := QScan;
				QDo := QOne;
			end;
		end;
	end;

	procedure MakeNetAddress;
		var
			SizeOfText, i, x: longint;
			foundit: boolean;
			TheAddr: str255;
	begin
		with curglobs^ do
		begin
			x := 0;
			foundit := false;
			TheAddr := char(0);
			curWriting := ReadMessage(curmesgrec.storedAs, inForum, inConf);
			SizeOfText := GetHandleSize(handle(curWriting));
			for i := SizeOfText downto (SizeOfText - 80) do
				if (curWriting^^[i] = ':') and ((curWriting^^[i - 1] > char(47)) and (curWriting^^[i - 1] < char(58))) then
				begin
					foundit := true;
					x := i - 1;
					leave;
				end;
			if foundit then
			begin
				while (curWriting^^[x] > char(47)) and (curWriting^^[x] < char(58)) do
					x := x - 1;
				for i := (x + 1) to SizeOfText do
				begin
					if (curWriting^^[i] > char(45)) and (curWriting^^[i] < char(59)) then
						TheAddr := concat(TheAddr, curWriting^^[i])
					else
						leave;
				end;
				curPrompt := concat(curprompt, ', ', TheAddr);
				OutLine(RetInStr(137), true, 6);
				bCR;
			end;
			if curWriting <> nil then
			begin
				DisposHandle(handle(curWriting));
				curWriting := nil;
			end;
		end;
	end;

	function MakeInternetAddress (TheLine: str255): str255;
		var
			i, TheAt, x, Start, Finish: integer;
			TheAddress: str255;
	begin
		TheAddress := char(0);
		if (pos('@', TheLine) <> 0) then
		begin
			TheAt := pos('@', TheLine);
			x := TheAt;
			repeat
				x := x - 1;
			until (TheLine[x] = ' ') or (TheLine[x] = '(') or (TheLine[x] = '<') or (x = 0);
			if (TheLine[x] = ' ') or (TheLine[x] = '(') or (TheLine[x] = '<') then
			begin
				Start := x + 1;
				x := TheAt;
				repeat
					x := x + 1;
				until (TheLine[x] = ' ') or (TheLine[x] = ')') or (TheLine[x] = '>') or (x = length(TheLine));
				if (x = length(TheLine)) and ((TheLine[x] <> ')') and (TheLine[x] <> '>') and (TheLine[x] <> ' ')) then
					x := x + 1;
				Finish := x;
				Finish := Finish - Start;
				TheAddress := copy(TheLine, Start, Finish);
			end;
		end;
		MakeInternetAddress := TheAddress;
	end;

	procedure DoQScan;
		const
			spaces = '                                                                            ';
		var
			tempString, tempString2, s1, s2, ts: str255;
			tempLong: longint;
			temppt: point;
			repo: sfreply;
			aborteds, tb: boolean;
			tempInt, i, hiMs, hold2, numreply, dm: integer;
			s40: string[40];
			s30: string[30];
			s26: string[26];
			s31: string[31];
	begin
		with curglobs^ do
		begin
			case QDo of
				Qone: 
				begin
					if (inNScan) and (inConf = 0) then
						NScanCalc;
					if inConf > 0 then
					begin
						OpenBase(inForum, inConf, false);
						NumToString(curNumMess, s1);
						displayConf := FigureDisplayConf(inForum, inConf);
						NumToString(displayConf, s2);
						i := 1;
						inMessage := 1;
						if curNumMess > 0 then
						begin
							while (i <= curNumMess) and (curBase^^[i - 1].DateEn <= thisUser.lastMsgs[inforum, inConf]) do
								i := i + 1;
							if (i <= curNumMess) and (curBase^^[i - 1].DateEn > thisUser.lastMsgs[inforum, inConf]) then
								inmessage := i
							else
								inMessage := curnummess + 1;
						end;
						if (inMessage > curNumMess) then
						begin
							OutLine(concat(RetInStr(62), MConference[inForum]^^[inConf].Name, ' #', s2, ' >'), true, 1);
							bCR;
							GoHome;
						end
						else
						begin
							if (thisUser.MessHeader = MessOn) then
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
							QDo := QEight;
						end;
					end
					else
						GoHome;
				end;
				QTwo: 
				begin
					if not inZScan then
					begin
						if curNumMess > 0 then
						begin
							HelpNum := 16;
							curMesgRec := curBase^^[inMessage - 1];
							NumToString(curNumMess, s1);
							NumToString(inMessage, s2);
							if not MConference[inForum]^^[inConf].Threading then
							begin
								OutLine('[', true, 3);
								OutLine(MConference[inForum]^^[inConf].Name, false, 4);
								OutLine('] ', false, 3);
								if (curBase^^[inMessage - 1].FileAttached) then
									NumbersPrompt(stringOf('Read:(1-', s1, ',^', s2, '), [D]ownload, ? :'), 'A+-<>RBC=TQDNMVEU?K', curnumMess, 1)
								else
									NumbersPrompt(stringOf('Read:(1-', s1, ',^', s2, '), ? :'), 'A+-<>RBC=TQNMVEU?K', curnumMess, 1);
							end
							else
							begin
								OutLine('Conf', true, 4);
								OutLine(': ', false, 0);
								OutLine(concat(MConference[inForum]^^[inConf].Name, '   '), false, 3);
								if threadmode then
									OutLine('THREAD', false, 6);
								if thisUser.TerminalType = 1 then
									OutLine('', false, 0);
								OutLine('Read', true, 4);
								OutLine(': ', false, 0);
								OutLine(concat('(1-', s1, ')'), false, 5);
								OutLine(', ', false, 0);
								OutLine(concat('Message#', s2), false, 2);
								if threadmode then
								begin
									OutLine(', ', false, 0);
									OutLine('[F]orward, [L]ast, [Q]uit', false, 5);
									OutLine(', ', false, 0);
									OutLine('?', false, 1);
									OutLine('', false, 0);
									NumbersPrompt(' :', 'A+-<>RBC=TQFLDNMVEU?K', curnumMess, 1);
									myPrompt.PromptLine := stringOf('Read: (1-', s1, '), Message#', s2, ', [F]orward, [L]ast, [Q]uit, ? :');
								end
								else
								begin
									hold2 := inmessage;
									numreply := 0;
									tempstring := curBase^^[inmessage - 1].title;
									if (pos('RE: ', tempString) <> 2) and (pos('Re: ', tempString) <> 2) then
										tempstring := concat(char(0), 'Re: ', tempstring);
									while (hold2 < curNumMess) do
									begin
										hold2 := hold2 + 1;
										if tempstring = curBase^^[hold2 - 1].title then
											numReply := numreply + 1;
									end;
									OutLine(', ', false, 0);
									OutLine(stringOf('Replies=', numreply : 0), false, 1);
									OutLine(', ', false, 0);
									if (curBase^^[inMessage - 1].FileAttached) then
									begin
										OutLine('[D]ownload', false, 4);
										OutLine(', ', false, 0);
									end;
									OutLine('[C/R]=Next Msg', false, 2);
									OutLine(', ', false, 0);
									OutLine('?', false, 1);
									OutLine('', false, 0);
									if (curBase^^[inMessage - 1].FileAttached) then
									begin
										myPrompt.PromptLine := stringOf('Read: (1-', s1, '), Message#', s2, ', Replies=', numReply : 0, ', [D]ownload, [C/R]=Next Msg, ? :');
										NumbersPrompt(' :', 'A+-<>RBC=TQFLDNMVEU?K', curnumMess, 1);
									end
									else
									begin
										myPrompt.PromptLine := stringOf('Read: (1-', s1, '), Message#', s2, ', Replies=', numReply : 0, ', [C/R]=Next Msg, ? :');
										NumbersPrompt(' :', 'A+-<>RBC=TQFLNMVEU?K', curnumMess, 1);
									end;
								end;
							end;
							Qdo := QThree;
						end
						else
						begin
							OutLine(RetInStr(151), true, 0);
							bCR;
							endQScan := true;
							GoHome;
						end;
					end
					else
					begin
						curPrompt := '';
						continuous := true;
						QDo := Qthree;
					end;
				end;
				QThree: 
				begin
					if (length(curprompt) >= 1) and (curprompt[1] = ' ') then
						delete(curprompt, 1, 1);
					if (curPrompt = '') or (CurPrompt = '+') or (curprompt = '>') then
					begin
						if curNumMess > inMessage then
						begin
							inMessage := inMessage + 1;
							if continuous then
							begin
								bCR;
								bCR;
								bCR;
							end;
							PrintCurMessage(true);
							if not continuous then
								QDo := QTwo;
						end
						else
						begin
							continuous := false;
							QDo := QFour;
							bCR;
							threadMode := false;
							if not ThisUser.CantPost and (thisUser.SL >= MConference[inForum]^^[inConf].SLtoPost) and not inZScan then
							begin
								YesNoQuestion(concat(RetInStr(11), ' ', MConference[inForum]^^[inConf].Name, '? '), false);
							end
							else
								curPrompt := 'N';
						end;
					end
					else if (curPrompt = 'D') then		{Download File Attachment}
					begin
						if (curBase^^[inMessage - 1].FileAttached) then
						begin
							WasAttach := true;
							AttachFName := curBase^^[inMessage - 1].FileName;
							WasAttachMac := curBase^^[inMessage - 1].isAMacFile;
							bCR;
							YesNoQuestion(RetInStr(126), true);
							QDo := QSeven;
						end
						else
							QDo := QTwo;
					end
					else if (curPrompt = 'C') then
					begin
						curPrompt := '';
						continuous := true;
						QDo := Qthree;
						if inMessage < curNumMess then
						begin
							inMessage := inMessage + 1;
						end;
						PrintCurMessage(true);
					end
					else if (curPrompt[1] > '0') and (curPrompt[1] <= '9') then
					begin
						StringToNum(curprompt, tempLong);
						if (templong <= curNumMess) and (templong > 0) then
						begin
							inMessage := templong;
						end;
						QDo := QTwo;
						PrintCurMessage(true);
					end
					else if (CurPrompt = 'Q') then
					begin
						if not threadMode then
						begin
							Outline(concat('< ', MConference[inForum]^^[inConf].Name, ' ', RetInStr(152), ' >'), true, 1);
							bCR;
							GoHome;
							if inNScan then
							begin
								OutLine(RetInStr(61), true, 3);
								inForum := saveInForum;
								inConf := saveInSub;
								inNScan := false;
								inZScan := false;
							end;
						end
						else
						begin
							OutLine(RetInStr(153), true, 2);
							bCR;
							bCR;
							threadMode := false;
							inMessage := headMessage;
							PrintCurMessage(true);
							QDo := QTwo;
						end;
					end
					else if (CurPrompt = '-') or (curprompt = '<') then
					begin
						if inMessage > 1 then
							inMessage := inMessage - 1;
						PrintCurMessage(true);
						QDo := QTwo;
					end
					else if (curPrompt = 'V') and (MConference[inForum]^^[inConf].ConfType = 0) then
					begin
						QDo := QTwo;
						if thisUser.coSysop then
						begin
							SysopLog('      @Ran Uedit', 0);
							BoardSection := UEdit;
							UEDo := U23;
							MaxLines := -525;
						end;
					end
					else if (curprompt = 'E') then
					begin
						if (thisUser.cosysop) or (MConferenceOp(inForum, inConf, ThisUser)) or (MForumOp(InForum, ThisUser)) then
						begin
							if sysopLogon then
							begin
								SetPt(tempPt, 40, 40);
								SFPutFile(tempPt, RetInStr(154), curBase^^[inMessage - 1].title, nil, repo); {Please name extract file:}
								if repo.good then
								begin
									if curWriting <> nil then
									begin
										DisposHandle(handle(curWriting));
										curWriting := nil;
									end;
									curWriting := ReadMessage(curbase^^[inMessage - 1].storedAs, inforum, inConf);
									result := FSDelete(repo.fName, repo.vrefNum);
									result := Create(repo.fname, repo.vrefnum, 'HRMS', 'TEXT');
									result := FSOpen(repo.fname, repo.vrefnum, tempint);
									templong := gethandleSize(handle(curWriting));
									result := FSWrite(tempint, templong, pointer(curWriting^));
									result := FSClose(tempint);
								end;
							end
							else
								OutLine(RetInStr(155), true, 0);				{Cannot extract remotely.}
						end;
						QDo := QTwo;
					end
					else if (curPrompt = '=') then
					begin
						PrintCurMessage(true);
						QDo := QTwo;
					end
					else if (curPrompt = 'U') then
					begin
						if (thisUser.cosysop) or (MConferenceOp(inForum, inConf, ThisUser)) or (MForumOp(InForum, ThisUser)) then
						begin
							OpenBase(inforum, inConf, false);
							if curBase^^[inMessage - 1].anonyFrom then
								curBase^^[inMessage - 1].anonyFrom := false;
							OutLine(RetInStr(156), true, 0);							{Message is not anonymous now.}
							SaveBase(inForum, inConf);
						end;
						QDo := QTwo;
					end
					else if (curPrompt = 'N') then
					begin
						if (thisUser.cosysop) or (MConferenceOp(inForum, inConf, ThisUser)) or (MForumOp(InForum, ThisUser)) then
						begin
							OpenBase(inforum, inConf, false);
							if curBase^^[inMessage - 1].deletable then
							begin
								curBase^^[InMessage - 1].deletable := False;
								OutLine(RetInStr(158), true, 2);			{Message will NOT be auto-purged.}
							end
							else
							begin
								curBase^^[InMessage - 1].deletable := True;
								OutLine(RetInStr(157), true, 2)				{Message CAN now be auto-purged.}
							end;
							SaveBase(inForum, inConf);
						end;
						QDo := QTwo;
					end
					else if (CurPrompt = 'K') then		{Kill Message}
					begin
						if (thisUser.cosysop) or (MConferenceOp(inForum, inConf, ThisUser)) or (MForumOp(InForum, ThisUser)) then
						begin
							DeletePost(inForum, inConf, inMessage, true);
							if inMessage > curNumMess then
								inMessage := inMessage - 1;
							curMesgRec := curBase^^[inMessage - 1];
						end;
						Qdo := QTwo;
					end
					else if (curprompt = 'L') then
					begin
						if MConference[inForum]^^[inConf].Threading then
						begin
							if not threadMode then
							begin
								threadMode := true;
								headMessage := inMessage;
							end;
							hold2 := inMessage;
							if inMessage <= 1 then
							begin
								OutLine(RetInStr(159), true, 2);  {There are no messages before this one.}
								bCR;
								bCR;
								QDo := QTwo;
								Exit(doQScan);
							end;
							numreply := 0;
							tempstring := curBase^^[inmessage - 1].title;
							if tempstring[1] <> char(0) then
								tempstring := concat(char(0), 'Re: ', tempstring);
							aborteds := false;
							while not aborteds do
							begin
								inMessage := inMessage - 1;
								if (inMessage < 1) then
								begin
									OutLine(RetInStr(160), true, 2);	{That was the first message available in this thread.}
									BCR;
									BCR;
									inMessage := hold2;
									PrintCurMessage(true);
									QDo := QTwo;
									exit(doQScan);
								end;
								tempstring2 := curBase^^[inMessage - 1].title;
								if tempstring2[1] <> char(0) then
									tempstring2 := concat(char(0), 'Re: ', tempstring2);
								if tempstring2 = tempstring then
								begin
									aborteds := true;
									PrintCurMessage(true);
									QDo := QTwo;
								end;
							end;
						end
						else
							QDo := QTwo;
					end
					else if (curprompt = 'F') then
					begin
						if MConference[inForum]^^[inConf].Threading then
						begin
							if not threadmode then
							begin
								headMessage := inMessage;
								threadmode := true;
							end;
							hold2 := inMessage;
							if inMessage >= curNumMess then
							begin
								OutLine(RetInStr(161), true, 2);{That was the last message in this sub.}
								bCR;
								bCR;
								QDo := QTwo;
								Exit(doQScan);
							end;
							numreply := 0;
							tempstring := curBase^^[inmessage - 1].title;
							if tempstring[1] <> char(0) then
								tempstring := concat(char(0), 'Re: ', tempstring);
							aborteds := false;
							while not aborteds do
							begin
								inMessage := inMessage + 1;
								if (inMessage > curNumMess) then
								begin
									OutLine(RetInStr(162), true, 2);	{There are no more messages available in this thread.}
									BCR;
									BCR;
									inMessage := hold2;
									PrintCurMessage(true);
									QDo := QTwo;
									exit(doQScan);
								end;
								if curBase^^[inMessage - 1].title = tempstring then
								begin
									aborteds := true;
									PrintCurMessage(true);
									QDo := QTwo;
								end;
							end;
						end
						else
							QDo := QTwo;
					end
					else if (curPrompt = 'B') then
					begin
						if not threadMode then
						begin
							endQScan := true;
							GoHome;
						end
						else
							QDo := QTwo;
					end
					else if (curPrompt = 'T') then
					begin
						getTitle(inMessage + 1, tempString, tempint);
						if (tempString[1] = char(0)) then
							Delete(tempString, 1, 1);
						s40 := concat(tempString, spaces);
						if (curBase^^[inMessage].FileAttached) then
							s40 := concat('*FILE* ', s40);
						if s40[1] <> char(0) then
							s40[0] := char(39);
						if tempString <> '' then
						begin
							thisUser.foregrounds[17] := 5;
							thisUser.backgrounds[17] := 0;
							thisUser.intense[17] := false;
							thisUser.underlines[17] := false;
							thisUser.blinking[17] := false;
							i := 1;
							bCR;
							repeat
								NumToString(inmessage + i, s1);
								tempstring2 := curBase^^[inMessage + i - 1].fromUserName;
								s30 := tempString2;
								if (curBase^^[inMessage + i - 1].anonyFrom) and (thisUser.CantReadAnon) then
									s30 := '>>UNKNOWN<<'
								else if (curBase^^[inMessage + i - 1].anonyFrom) and (not thisUser.CantReadAnon) then
									s30 := concat('<<', s30, '>>');
								if tempInt <> thisUser.UserNum then
								begin
									if length(s1) = 1 then
										s1 := concat('(', s1, ')   ')
									else if length(s1) = 2 then
										s1 := concat('(', s1, ')  ')
									else
										s1 := concat('(', s1, ') ');
									if thisUser.TerminalType = 1 then
									begin
										if curBase^^[inMessage + i - 1].DateEn <= thisUser.lastMsgs[inForum, inConf] then
											bufferIt(concat('  ', s1), false, 2)
										else
											bufferIt(concat('* ', s1), false, 2);
										bufferIt(concat(s40, ' '), false, 1);
										bufferIt(char(186), false, 1);
										bufferIt(concat(' ', s30), false, 5);
									end
									else
									begin
										if curBase^^[inMessage + i - 1].DateEn <= thisUser.lastMsgs[inForum, inConf] then
											bufferIt(concat('  ', s1, s40, ' | ', s30), false, 0)
										else
											bufferIt(concat('* ', s1, s40, ' | ', s30), false, 0);

									end;
								end
								else
								begin
									if length(s1) = 1 then
										s1 := concat('[', s1, ']   ')
									else if length(s1) = 2 then
										s1 := concat('[', s1, ']  ')
									else
										s1 := concat('[', s1, '] ');
									if thisUser.TerminalType = 1 then
									begin
										if curBase^^[inMessage + i - 1].DateEn <= thisUser.lastMsgs[inForum, inConf] then
											bufferIt(concat('  ', s1), false, 2)
										else
											bufferIt(concat('* ', s1), false, 2);
										bufferIt(concat(s40, ' '), false, 1);
										bufferIt(char(186), false, 1);
										bufferIt(concat(' ', s30), false, 5);

									end
									else
									begin
										if curBase^^[inMessage + i - 1].DateEn <= thisUser.lastMsgs[inForum, inConf] then
											bufferIt(concat('  ', s1, s40, ' | ', s30), false, 0)
										else
											bufferIt(concat('* ', s1, s40, ' | ', s30), false, 0);
									end;
								end;
								bufferbCR;
								i := i + 1;
								GetTitle(inMessage + i, tempString, tempInt);
								if tempString[1] = char(0) then
									Delete(tempstring, 1, 1);
								s40 := concat(tempString, spaces);
								if (curBase^^[inMessage + i - 1].FileAttached) then
									s40 := concat('*FILE* ', tempString, spaces);

								if s40[1] <> char(0) then
									s40[0] := char(39);
							until (tempString = '') or (i = 21);
							releaseBuffer;
							inMessage := inMessage + i - 1;
						end;
						if inMessage = 0 then
							inMessage := 1;
						if (curBase^^[inMessage - 1].DateEn > thisuser.lastMsgs[inforum, inConf]) then
							thisuser.lastmsgs[inforum, inConf] := curBase^^[inMessage - 1].DateEn;
						QDo := QTwo;
					end
					else if (CurPrompt = 'R') then
					begin
						if MConference[inForum]^^[inConf].SLtoPost <= thisUser.SL then
						begin
							fromQScan := true;
							PostDo := postOne;
							BoardSection := post;
							wasSearching := false;
							reply := true;
							newmsg := true;
							if MConference[inForum]^^[inConf].ConfType = 2 then
							begin
								replyToStr := 'All';
								replyToNum := TABBYTOID;
							end
							else
							begin
								replyToStr := curBase^^[inMessage - 1].fromuserName;
								replyToNum := curBase^^[inMessage - 1].fromUserNum;
							end;
							if curBase^^[inMessage - 1].anonyFrom then
							begin
								wasAnonymous := true;
								replyToAnon := true;
							end
							else
							begin
								replyToAnon := false;
								wasAnonymous := false;
							end;
							SetUpQuoteText(curBase^^[inMessage - 1].fromuserName, CurMesgRec.storedAs, inForum, inConf);
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
							if MConference[inForum]^^[inConf].Threading then
							begin
								if (curBase^^[inMessage - 1].title[1] <> char(0)) then
									replyStr := concat(char(0), 'Re: ', curBase^^[inMessage - 1].title)
								else
									replyStr := curBase^^[inMessage - 1].title;
							end
							else
								replyStr := concat('Re: ', curBase^^[inMessage - 1].title);
						end
						else
						begin
							OutLine(RetInStr(163), true, 0);		{You can't post on this sub.}
							bCR;
							QDo := QTwo;
						end;
					end
					else if (curPrompt = 'A') then
					begin
						if not curMesgRec.anonyFrom then
						begin
							reply := True;
							replyStr := curMesgRec.Title;
							UprString(replyStr, false);
							if (pos('RE:', replyStr) = 0) then
								replyStr := concat('Re: ', curMesgRec.Title)
							else
								replyStr := curMesgRec.Title;
							newmsg := true;
							BoardSection := EMail;
							EmailDo := EmailOne;
							if (MConference[inForum]^^[inConf].ConfType = 1) and (curMesgRec.fromUserNum = -100) then
							begin
								curPrompt := curMesgRec.fromUserName;
								MakeNetAddress;
							end
							else if (MConference[inForum]^^[inConf].ConfType = 2) and (curMesgRec.fromUserNum = -100) then
							begin
								curWriting := ReadMessage(curmesgrec.storedAs, inForum, inConf);
								tempstring := takeMsgTop;
								tempString := takeMsgTop;
								tempString := takeMsgTop;
								tempString := MakeInternetAddress(tempString);
								if tempString <> char(0) then
									curPrompt := tempString
								else
								begin
									curPrompt := curMesgRec.fromUserName;
									MakeNetAddress;
								end;
							end
							else
								NumToString(curMesgRec.fromUserNum, curprompt);
							if curMesgRec.anonyFrom then
							begin
								wasAnonymous := true;
								sentanon := true;
							end
							else
							begin
								sentAnon := false;
								wasAnonymous := false;
							end;
							callFMail := false;
							fromQScan := true;
							SetUpQuoteText(curMesgRec.fromUserName, curMesgRec.StoredAs, inForum, inConf);
							if (MConference[inForum]^^[inConf].AnonID = 0) then
								tb := false
							else
								tb := true;
							if (MConference[inForum]^^[inConf].RealNames) then
								tempString := thisUser.RealName
							else
								tempString := thisUser.UserName;
							if wasAnonymous then
								TheQuote.Header := MakeQuoteHeader('>>UNKNOWN<<', tempString, curMesgRec.title, tb)
							else
								TheQuote.Header := MakeQuoteHeader(curMesgRec.fromUserName, tempString, curMesgRec.title, tb);
						end
						else
						begin
							OutLine('No Auto-Replies to anonymous messages!', true, 0);
							bcr;
							qDo := Qtwo;
						end;
					end
					else if (curprompt = 'M') then
					begin
						if (thisUser.cosysop) or (MConferenceOp(inForum, inConf, ThisUser)) or (MForumOp(InForum, ThisUser)) then
						begin
							QDo := QMove;
							if InitSystHand^^.numMForums > 1 then
								NumbersPrompt(RetInStr(165), '?', 10, 1)			{Move to which forum?}
							else
								curprompt := '1';
						end
						else
							QDo := QTwo;
					end
					else if (CurPrompt = '?') then
					begin
						if (thisUser.cosysop) or (MConferenceOp(inForum, inConf, ThisUser)) or (MForumOp(InForum, ThisUser)) then
						begin
							bufferIt(RetInStr(166), true, 2);		{SYSOP Commands:}
							bufferIt(RetInStr(167), true, 1);		{D:elete Message        M:ove Message}
							bufferIt(RetInStr(168), true, 1);  {N: Permanent Message   U:Make not anonymous}
							bufferIt(RetInStr(169), true, 1);	{E:xtract Message to text file}
							releasebuffer;
						end;
						if LoadSpecialText(helpFile, 37) then
						begin
							if thisUser.TerminalType = 1 then
								doM(0);
							BoardAction := ListText;
							bCR;
						end;
						QDo := QTwo;
					end
					else
					begin
						Qdo := QTwo;
					end;
				end;
				QMove: 
				begin
					if length(curprompt) > 0 then
					begin
						if curPrompt = '?' then
						begin
							PrintForumList;
							QDo := QThree;
							Curprompt := 'M';
						end
						else
						begin
							StringToNum(curprompt, tempLong);
							if (tempLong <= InitSystHand^^.numMForums) and (templong > 0) then
							begin
								crossInt := tempLong;
								QDo := QMove2;
								NumbersPrompt(concat(RetInStr(170), ' '), '?', MForum^^[tempLong].NumConferences, 1);  {Which sub?}
							end
							else
								QDo := QTwo;
						end;
					end
					else
						QDo := QTwo;
				end;
				QMove2: 
				begin
					if length(curprompt) > 0 then
					begin
						if CurPrompt = '?' then
						begin
							PrintConfList(crossInt);
							QDo := QMove;
							numToString(crossInt, curprompt);
							bCR;
						end
						else
						begin
							StringToNum(curprompt, tempLong);
							if (tempLong > 0) and (tempLong <= MForum^^[crossint].NumConferences) and ((tempLong <> inConf) or (crossInt <> inForum)) then
							begin
								bCR;
								curMesgRec := curBase^^[inMessage - 1];
								if curWriting <> nil then
									DisposHandle(handle(curWriting));
								curWriting := nil;
								curWriting := ReadMessage(curMesgRec.storedAs, inForum, inConf);
								RemoveMessage(curMesgRec.storedAs, inForum, inConf);
								SetHandleSize(handle(curWriting), GetHandleSize(handle(curWriting)) + 1);
								curWriting^^[getHandleSize(handle(curWriting)) - 1] := char(26);
								curMesgRec.storedAs := SaveMessage(curWriting, crossInt, tempLong);
								if (curMesgRec.storedAs <> -1) then
								begin
									OpenBase(crossInt, tempLong, true);
									i := 0;
									if curNumMess > 0 then
									begin
										repeat
											i := i + 1;
										until (i = curNumMess) or (curBase^^[i - 1].DateEn > curMesgRec.DateEn);
										if not (curBase^^[i - 1].DateEn > curMesgRec.DateEn) then
											CurBase^^[i] := curMesgRec
										else
										begin
											for hiMs := curNumMess downto i do
												CurBase^^[hiMs] := curBase^^[hiMs - 1];
											CurBase^^[i - 1] := curMesgRec;
										end;
									end
									else
									begin
										i := 1;
										curBase^^[i - 1] := curMesgRec;
									end;
									curNumMess := curNumMess + 1;
									SaveBase(crossInt, tempLong);
									if curNumMess > MConference[crossInt]^^[tempLong].MaxMessages then
									begin
										dm := 0;
										i := 1;
										while (dm = 0) and (i <= curNumMess) do
										begin
											if curBase^^[i - 1].deletable then
												dm := i;
											i := i + 1;
										end;
										if dm = 0 then
											dm := 1;
										CloseBase;
										DeletePost(crossInt, tempLong, dm, true);
									end;
									DeletePost(inForum, inConf, inMessage, false);
									OpenBase(inForum, inConf, false);
									if inMessage > curNumMess then
										inMessage := curNumMess;
									OutLine(RetInStr(171), true, 0);		{Message moved.}
									bCR;
								end
								else
								begin
									OutLine(RetInStr(172), true, 0);		{Error; the sub you are moving to is full.}
									bCR;
								end;
								QDo := QTwo;
							end
							else
								QDo := QTwo;
						end;
					end
					else
						QDO := QTwo;
				end;
				QFour: 
				begin
					if curprompt = 'N' then
					begin
						EndQScan := true;
						GoHome;
					end
					else
					begin
						EndQScan := true;
						reply := false;
						replyToStr := 'All';
						BoardSection := Post;
						PostDo := PostOne;
						wasSearching := false;
					end;
				end;
				QFive: 
				begin
					OpenBase(inForum, inConf, false);
					tempint := curNumMess;
					if (tempint > 0) and (MForumOk(inForum)) and (MConferenceOk(inForum, inConf)) then
					begin
						tempString := StringOf(tempint : 0, ' messages on ', MConference[inForum]^^[inConf].Name, '.');
						OutLine(tempString, false, 2);
						bCR;
						NumbersPrompt(RetInStr(173), '', curNumMess, 1);		{Start listing at? }
						QDo := QSix;
					end
					else
					begin
						OutLine(RetInStr(174), true, 0);			{No messages here.}
						GoHome;
					end;
				end;
				QSix: 
				begin
					StringToNum(curPrompt, templong);
					if (templong <= curNumMess) and (tempLong > 0) then
					begin
						inMessage := tempLong - 1;
						curprompt := 'T';
						QDo := QThree;
					end
					else
						GoHome;
				end;
				QSeven: 
				begin
					if (curPrompt = 'Y') then
					begin
						FromDetach := true;
						WasEMail := false;
						wasSearching := false;
						DetachDo := Detach1;
						BoardSection := DetachFile;
					end;
					QDo := QTwo;
				end;
				QEight: 
				begin
					OutLine(concat('< ', RetInStr(10), ' ', MConference[inForum]^^[inConf].Name, ' #', s2, ' - ', s1, ' msgs >'), true, 1);
					PrintCurMessage(true);
					Qdo := QTwo;
				end;
				otherwise
			end;
		end;
	end;

	procedure DoPosting;
		var
			tempString, tempString2: str255;
			tempLong: longint;
			tempint, i, dm: integer;
	begin
		with curglobs^ do
		begin
			case PostDo of
				PostOne: 
				begin
					bCR;
					if (thisUser.mesgDay >= thisUser.MPostedToday) then
					begin
						if (FreeK(InitSystHand^^.msgsPath) > 100) then
						begin
							if (MConferenceOk(inForum, inConf)) and (MForum^^[inForum].NumConferences >= inConf) and (MConference[inForum]^^[inConf].SLtoPost <= ThisUser.SL) and (not ThisUser.CantPost) then
							begin
								curprompt := '';
								if MConference[inForum]^^[inConf].Threading and not reply and (MConference[inForum]^^[inConf].ConfType <> 2) then
								begin
									LettersPrompt(RetInStr(175), '', 31, false, false, false, char(0));	{To (<CR> for all): }
									myprompt.wrapsOnCR := false;
								end;
								PostDo := PostTwo;
							end
							else
							begin
								OutLine(RetInStr(63), false, 0);	{You can't post here.}
								GoHome;
							end;
						end
						else
						begin
							OutLine(RetInStr(64), false, 0);	{Sorry, not enough disk space left.}
							GoHome;
						end;
					end
					else
					begin
						OutLine(RetInStr(65), false, 0);	{Too many messages posted today.}
						GoHome;
					end;
				end;
				PostTwo: 
				begin
					curMesgRec.toUserNum := 0;
					curMesgrec.toUserName := 'All';
					curMesgRec.FileAttached := false;
					curMesgRec.FileName := char(0);
					if MConference[inForum]^^[inConf].Threading and not reply then
					begin
						NumToString(gBBSwindows[activeNode]^.cursor.h, tempstring);
						if FindUser(curPrompt, tempuser) and not tempuser.DeletedUser then
						begin
							curMesgRec.touserNum := tempuser.userNum;
							curMesgRec.toUserName := tempUser.userName;
							NumToString(tempuser.UserNum, tempstring2);
							if thisUser.TerminalType = 1 then
							begin
								OutLine(concat(char(27), '[', tempstring, 'D', char(27), '[K'), false, -1);
								OutLine('To   ', false, 4);
								OutLine(concat(': ', tempUser.userName, ' #', tempString2), false, 0);
							end;
						end
						else
						begin
							if MConference[inForum]^^[inConf].ConfType <> 0 then
							begin
								if length(curPrompt) = 0 then
									curPrompt := 'All';
								if MConference[inForum]^^[inConf].ConfType = 2 then
									curPrompt := 'All';
								curMesgRec.toUserName := curprompt;
								curMesgRec.touserNum := TABBYTOID;
							end;
							if thisUser.TerminalType = 1 then
							begin
								OutLine(concat(char(27), '[', tempstring, 'D', char(27), '[K'), false, -1);
								OutLine('To   ', false, 4);
								if curMesgRec.toUserNum = TABBYTOID then
									OutLine(concat(': ', curPrompt), false, 0)
								else
									OutLine(': All', false, 0);
							end;
						end;
					end;
					if not MConference[inForum]^^[inConf].Threading or not reply then
					begin
						if not (thisUser.TerminalType = 1) and not thisUser.ColorTerminal then
							OutLine(RetInStr(722), true, 0);{       (---=----=----=----=----=----=----=----=--)}
						bCR;
						LettersPrompt(RetInStr(176), '', 43, false, false, false, char(0));
						ANSIPrompter(43);
						PostDo := PostThree;
					end
					else
					begin
						if thisUser.TerminalType = 1 then
							doM(0);
						bCR;
						PostDo := PostThree;
						curprompt := replyStr;
					end;
				end;
				PostThree: 
				begin
					if thisUser.TerminalType = 1 then
						doM(0);
					if length(CurPrompt) > 0 then
					begin
						if MConference[inForum]^^[inConf].Threading and not reply then
						begin
							OpenBase(inForum, inConf, false);
							if checktitle(curPrompt) then
							begin
								OutLine(RetInStr(354), true, 2);	{Title is already in use.}
								bCR;
								if curMesgRec.touserNum = TABBYTOID then
									curprompt := curMesgRec.toUserName
								else
									NumToString(curMesgRec.touserNum, curprompt);
								PostDo := PostTwo;
								exit(doPosting);
							end;
						end;
						CurMesgRec.title := CurPrompt;
						curMesgRec.fromUserNum := thisUser.UserNum;
						if newhand^^.realname and newhand^^.handle and MConference[inForum]^^[inConf].RealNames and (thisUser.realname <> '•') then
							curMesgrec.fromUserName := thisUser.realname
						else
							curMesgrec.fromuserName := thisUser.userName;
						curMesgrec.anonyTo := false;
						wasAnonymous := false;
						if reply and ((MConference[inForum]^^[inConf].Threading) or (MConference[inForum]^^[inConf].ConfType = 2)) then
						begin
							curMesgRec.toUserNum := replyToNum;
							curMesgrec.toUserName := replyToStr;
							if replyToAnon then
							begin
								curMesgRec.AnonyTo := true;
								wasAnonymous := true;
							end;
						end;
						if useWorkspace = 0 then
						begin
							maxLines := thisUser.lnsMessage;
							EnterMessage(maxLines);
							PostDo := PostFour;
							myTrans.startTime := tickCount;
						end
						else
						begin
							UseWorkspace := 0;
							LoadFileAsMsg(StringOf(sharedPath, 'Misc:Local Workspace ', activeNode : 0));
							OutLine(RetInStr(177), true, 3);		{Workspace text inserted.}
							bCR;
							myTrans.startTime := 0;
							bCR;
							PostDo := PostFour;
						end;
					end
					else
					begin
						OutLine(RetInStr(178), false, 3);				{Aborted.}
						bCR;
						GoHome;
					end;
				end;
				PostFour: 
				begin
					if curWriting <> nil then
					begin
						if (MConference[inForum]^^[inConf].ConfType = 0) then
						begin
							if (not ThisUser.CantPostAnon) and (MConference[inForum]^^[inConf].AnonID = -1) and (endAnony = 0) then
							begin
								bCR;
								YesNoQuestion(RetInStr(179), false);			{Anonymous? }
							end
							else
							begin
								CurPrompt := 'N';
								if (not ThisUser.CantPostAnon) and (EndAnony = 1) then
									curprompt := 'Y'
								else if (not ThisUser.CantPostAnon) and (EndAnony = -1) then
									curprompt := 'N';
								if (MConference[inForum]^^[inConf].AnonID = 0) then
									curprompt := 'N';
								if (MConference[inForum]^^[inConf].AnonID = 1) then
									curprompt := 'Y';
							end;
						end
						else
							curPrompt := 'N';
						PostDo := PostFive;
					end
					else
					begin
						OutLine(RetInStr(178), true, 3);			{Aborted.}
						bCR;
						GoHome;
					end;
				end;
				PostFive: 
				begin
					OutLine(RetInStr(180), true, 0);				{Saving...}
					if MConference[inForum]^^[inConf].ConfType <> 0 then
						SaveNetpost;
					if reply and not MConference[inForum]^^[inConf].Threading then
					begin
						AddLine('');
						AddLine(replyStr);
					end;
					if curPrompt = 'Y' then
						curMesgRec.anonyFrom := true
					else
						curMesgRec.anonyFrom := false;
					curMesgRec.deletable := true;
					GetDateTime(tempLong);
					curMesgRec.DateEn := templong;
					for i := 0 to 5 do
						curMesgRec.reserved[i] := char(0);
					IUDateString(tempLong, abbrevdate, tempstring);
					IUTimeString(templong, true, tempstring2);
					AddLine(concat(tempstring, ' ', tempstring2));
					if not SavePost(inForum, inConf) then
						OutLine(RetInStr(181), true, 6);		{ERROR: SUB DATABASE FULL}
					if curWriting <> nil then
						DisposHandle(handle(curWriting));
					curWriting := nil;
					OpenBase(inForum, inConf, false);
					if curNumMess > MConference[inForum]^^[inConf].MaxMessages then
					begin
						dm := 0;
						i := 1;
						while (dm = 0) and (i <= curNumMess) do
						begin
							if curBase^^[i - 1].deletable then
								dm := i;
							i := i + 1;
						end;
						if dm = 0 then
							dm := 1;
						CloseBase;
						DeletePost(inForum, inConf, dm, true);
						inMessage := inMessage - 1;
					end;
					readMsgs := true;
					thisUser.messagesPosted := thisUser.messagesPosted + 1;
					thisUser.MPostedToday := thisUser.MPostedToday + 1;
					InitSystHand^^.mPostedToday[activeNode] := InitSystHand^^.mPostedToday[activeNode] + 1;
					GetDateTime(InitSystHand^^.LastPost);
					doSystRec(true);
					sysopLog(concat('      +', curMesgRec.title, ' posted on ', MConference[inForum]^^[inConf].Name), 0);
					OutLine(concat(RetInStr(626), MConference[inForum]^^[inConf].Name), false, 0);	{Posted on }
					bCR;
					if (thisUser.messComp > 0) and (myTrans.startTime > 0) then
						GiveTime((tickcount - myTrans.startTime), thisUser.messcomp, true);
					OpenBase(inforum, inConf, false);
					GoHome;
				end;
				otherwise
			end;
		end;
	end;

	procedure DoRemove;
		var
			tempString, tempString2: str255;
			num, i, tempint, pos: integer;
			templong: longInt;
	begin
		with curglobs^ do
		begin
			case RmvDo of
				rmvOne: 
				begin
					OpenBase(inForum, inConf, false);
					num := curNumMess;
					if num > 0 then
					begin
						i := 0;
						tempint := 0;
						repeat
							i := i + 1;
							GetTitle(i, tempString, pos);
							if pos = thisUser.UserNum then
							begin
								if tempInt = 0 then
								begin
									Outline(concat(RetInStr(182), MConference[inForum]^^[inConf].Name), true, 0);   {Posts by you on }
									bCR;
								end;
								tempint := tempint + 1;
								OutLine(StringOf(i : 0, ': ', tempString), true, 0);
							end;
						until (i = num);
						bCR;
						if tempint > 0 then
						begin
							bCR;
							NumbersPrompt(RetInStr(183), '', 999, 1);			{Remove which? }
							RmvDo := RmvTwo;
						end
						else
						begin
							OutLine(RetInStr(184), true, 0);	{You have no messages here.}
							GoHome;
						end;
					end
					else
					begin
						OutLine(RetInStr(185), true, 0);			{No messages here.}
						GoHome;
					end;
				end;
				rmvTwo: 
				begin
					if (curprompt <> '') and (curPrompt <> 'Q') then
					begin
						StringToNum(curPrompt, templong);
						if templong <= curNumMess then
						begin
							GetTitle(tempLong, tempString, tempint);
							if tempInt = thisUser.UserNum then
							begin
								DeletePost(inForum, inConf, tempLong, true);
								OutLine(RetInStr(186), true, 0);				{Message removed.}
								thisUser.messagesPosted := thisUser.messagesPosted - 1;
							end
							else
								Outline(RetInStr(187), true, 0);	{Message was not posted by you.}
						end;
						GoHome;
					end
					else
					begin
						GoHome;
						bCR;
					end;
				end;
				otherwise
			end;
		end;
	end;

	procedure DoMailCommand (Pres: str255);
		var
			tempString, tempString2, fName, ts: str255;
			tempInt, tempInt2, i, totEm, index, b: integer;
			tempEMa: eMailRec;
			tempPt: point;
			repo: SFReply;
			tempLong: longint;
			tURec: UserRec;
	begin
		with curglobs^ do
		begin
			if length(pres) > 0 then
			begin
				case pres[1] of
					'?': 
					begin
						if (thisUser.coSysop) then
						begin
							OutLine(RetInStr(188), true, 3);	 {SYSOP:   Z)Delete with no acknowledge     E)xtract to file}
							Outline(RetInStr(189), true, 3);   {         V)alidate user                   O)Send form letter}
							OutLine(' ', false, 0);
						end;
						if LoadSpecialText(helpFile, 36) then
						begin
							if thisUser.TerminalType = 1 then
								doM(0);
							BoardAction := ListText;
							bCR;
						end;
						bCR;
						ReadDo := readFour;
					end;
					'V': 
					begin
						readDo := readFour;
						if thisUser.coSysop and (theEmail^^[myEmailList^^[atEmail]].fromUser <> TABBYTOID) then
						begin
							SysopLog('      @Ran Uedit', 0);
							BoardSection := UEdit;
							UEDo := U23;
							MaxLines := -425;
							FindMyEMail(thisUser.UserNum);
							crossInt := theEmail^^[myEmailList^^[atEmail]].fromUser;
						end;
					end;
					'F': 
					begin
						LettersPrompt(RetInStr(190), '', 31, false, false, false, char(0));		{Forward to which user? }
						ReadDo := ReadSeven;
					end;
					'A', 'O': 
					begin
						if pres[1] = 'O' then
						begin
							MailOp := 4;
							ReadDo := Read15;
						end
						else
						begin
							Reply := True;
							replyStr := theEmail^^[myEmailList^^[atEmail]].Title;
							UprString(replyStr, false);
							if (pos('RE:', replyStr) = 0) then
								replyStr := concat('Re: ', theEmail^^[myEmailList^^[atEmail]].Title)
							else
								replyStr := theEmail^^[myEmailList^^[atEmail]].Title;
							MailOp := 3;
							ReadDo := ReadEleven;
						end;
					end;
					'S': 
					begin
						Reply := True;
						replyStr := theEmail^^[myEmailList^^[atEmail]].Title;
						UprString(replyStr, false);
						if (pos('RE:', replyStr) = 0) then
							replyStr := concat('Re: ', theEmail^^[myEmailList^^[atEmail]].Title)
						else
							replyStr := theEmail^^[myEmailList^^[atEmail]].Title;
						newmsg := true;
						FindMyEmail(thisUser.UserNum);
						tempEma := theEmail^^[myEmailList^^[atEmail]];
						BoardSection := EMail;
						EmailDo := EMailOne;
						CallFMail := true;
						if not (tempEma.fromUser = TABBYTOID) then
						begin
							NumToString(tempEma.fromUser, curPrompt);
							if FindUser(curPrompt, tURec) then
								ts := tURec.UserName;
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
						ReadDo := ReadFour;
					end;
					'E': 
					begin
						if sysopLogon then
						begin
							SetPt(tempPt, 40, 40);
							SFPutFile(tempPt, RetInStr(154), 'Text File', nil, repo);			{Please name extract file:}
							if repo.good then
							begin
								tempEma := theEmail^^[myEmailList^^[atEmail]];
								if curWriting <> nil then
								begin
									DisposHandle(handle(curWriting));
									curWriting := nil;
								end;
								curWriting := ReadMessage(tempEma.storedAs, 0, 0);
								result := FSDelete(repo.fName, repo.vrefNum);
								result := Create(repo.fname, repo.vrefnum, 'HRMS', 'TEXT');
								result := FSOpen(repo.fname, repo.vrefnum, tempint);
								templong := gethandleSize(handle(curWriting));
								result := FSWrite(tempint, templong, pointer(curWriting^));
								result := FSClose(tempint);
							end;
						end
						else
							OutLine(RetInStr(155), true, 0);		{Cannot extract remotely.}
						ReadDo := readFour;
					end;
					'D', 'Z': 
					begin
						if pres[1] = 'Z' then
							MailOp := 2
						else
							MailOp := 1;
						ReadDo := ReadEleven;
					end;
					'Q': 
					begin
						GoHome;
					end;
					'R': 
					begin
						PrintCurEMail;
						if (WasAttach) then
							ReadDo := ReadNine
						else
							ReadDo := ReadFour;
					end;
					'+', 'I': 
					begin
						FindMyEmail(thisUser.UserNum);
						totEm := GetHandleSize(handle(myEmailList)) div 2;
						if (atEmail + 1) < totEm then
						begin
							atEMail := atEMail + 1;
							PrintCurEMail;
						end
						else
							goHome;
						if (WasAttach) then
							ReadDo := ReadNine
						else
							ReadDo := ReadFour;
					end;
					'-': 
					begin
						if (atEmail > 0) then
						begin
							atEMail := atEMail - 1;
							PrintCurEMail;
						end
						else
							goHome;
						if (WasAttach) then
							ReadDo := ReadNine
						else
							ReadDo := ReadFour;
					end;
					'G': 
					begin
						FindMyEmail(thisUser.UserNum);
						totEm := GetHandleSize(handle(myEmailList)) div 2;
						readDo := readSix;
						NumbersPrompt(StringOf(RetInStr(191), totEm : 0, ') ? '), '', totEm, 1);	{Go to which (1-}
					end;
					otherwise
				end;
			end
			else
			begin
				FindMyEmail(thisUser.UserNum);
				totEm := GetHandleSize(handle(myEmailList)) div 2;
				if totEm > (atEMail + 1) then
					atEMail := atEmail + 1
				else
					atEmail := 0;
				PrintCurEmail;
				if (WasAttach) then
					ReadDo := ReadNine
				else
					ReadDo := ReadFour;
			end;
		end;
	end;

	procedure DoEMail;
		var
			tempString, tempString2: str255;
			tempLong: longInt;
			result: OSerr;
	begin
		with curglobs^ do
		begin
			if (FreeK(InitSystHand^^.msgsPath) > 100) then
			begin
				if (not ThisUser.CantSendEmail and ((thisuser.emSentToday + thisUser.mPostedToday) <= thisUser.mesgDay)) or newfeed or (curprompt = '1') then
				begin
					if (pos(',', curPrompt) <> 0) or (pos('@', curPrompt) <> 0) then
					begin
						if (not Mailer^^.MailerAware) and (pos(',', curPrompt) <> 0) then
						begin
							OutLine(RetInStr(594), true, 6);	{Sorry, fidonet mail not enabled on this BBS.}
							GoHome;
							Exit(DoEMail);
						end
						else if (pos('@', curPrompt) <> 0) and (Mailer^^.InternetMail = NoMail) then
						begin
							OutLine(RetInStr(217), true, 6);	{Sorry, internet mail not enabled on this BBS.}
							GoHome;
							Exit(DoEMail);
						end
						else
						begin
							netMail := FidoNetAccount(curprompt);
							if netMail then
								INetMail := false
							else
								INetMail := InternetAccount(curPrompt);
							if (netMail or INetMail) and thisUser.CantNetMail then
							begin
								OutLine(RetInStr(135), true, 6);
								GoHome;
								Exit(doEMail);
							end;
						end;
					end
					else
					begin
						INetMail := false;
						netMail := false;
					end;
					if FindUser(curPrompt, MailingUser) or (netMail or INetMail) then
					begin
						if (not (mailingUser.DeletedUser)) or (netMail or INetMail) then
						begin
							if (thisUser.UserNum <> MailingUser.UserNum) or (netMail or INetMail) then
							begin
								if (MailingUser.Mailbox) and (not netmail) and (not INetMail) then
								begin
									if (pos(',', MailingUser.ForwardedTo) = 0) and (pos('@', MailingUser.ForwardedTo) = 0) then
									begin
										if FindUser(mailingUser.forwardedTo, tempuser) then
										begin
											if not tempUser.mailbox and not tempuser.DeletedUser then
												OutLine(RetInStr(192), true, 0)				{Mail Forwarded.}
											else
											begin
												OutLine(RetInStr(193), true, 6);	{Can't forward to a forwarding user!}
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
									end
									else
									begin
										netMail := FidoNetAccount(MailingUser.ForwardedTo);
										if netMail then
											INetMail := false
										else
											INetMail := InternetAccount(MailingUser.ForwardedTo);
									end;
								end;
								if (not netmail) and (not INetMail) then
								begin
									NumToString(MailingUser.UserNum, tempString2);
									if not SentAnon or (thisUser.coSysop) then
										tempString := concat(RetInStr(194), ' ', MailingUser.UserName, ' #', tempString2)   {E-mailing}
									else
										tempString := concat(RetInStr(194), ' >UNKNOWN<');
								end
								else if netMail then
									tempString := concat(RetInStr(194), ' ', myFido.name, ' at node ', myFido.atNode, '.')
								else if INetMail then
									tempString := concat(RetInStr(194), ' ', myFido.name);
								OutLine(tempString, true, 0);
								bCR;
								if not newfeed and (useWorkspace <= 1) then
								begin
									if not reply then
									begin
										if (thisUser.TerminalType = 0) and not thisUser.ColorTerminal then
											OutLine(RetInStr(722), true, 0);{       (---=----=----=----=----=----=----=----=--)}
										bCR;
										LettersPrompt(RetInStr(195), '', 40, false, false, false, char(0));	{Title: }
										ANSIPrompter(40);
									end
									else
										curPrompt := replyStr;
								end
								else
								begin
									OutLine(RetInStr(195), true, 2);
									if (useWorkspace > 1) then
										OutLine(RetInStr(196), false, 4)			{Loading...}
									else
										OutLine(RetInStr(197), false, 4);		{Validation Feedback}
									if thisUser.TerminalType = 1 then
										doM(0);
									curPrompt := RetInStr(723);{VALIDATION FEEDBACK}
									bCR;
									lnsPause := 0;
								end;
								CurEMailRec.fromuser := thisUser.Usernum;
								curEmailRec.toUser := mailingUser.usernum;
								CurEMailRec.FileAttached := False;
								CurEMailRec.FileName := char(0);
								if netMail then
									curEmailRec.toUser := TABBYTOID
								else if INetMail then
									curEMailRec.toUser := TABBYTOID;
								CurEMailRec.MType := 1;
								curEmailRec.multiMail := false;
								GetDateTime(curEMailRec.dateSent);
								numMultiUsers := 0;
								EMailDo := EmailEight;
							end
							else
							begin
								OutLine(RetInStr(198), true, 0);		{You can't send E-mail to yourself.}
								bCR;
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
						end
						else
						begin
							if MailingUser.DeletedUser then
								OutLine(RetInStr(199), true, 0)		{Deleted user.}
							else
								OutLine(RetInStr(200), true, 0);	{Mailbox full.}
							bCR;
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
					end
					else
					begin
						OutLine(RetInStr(201), true, 0);			{No such user.}
						bCR;
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
				end
				else
				begin
					OutLine(RetInStr(202), true, 0);		{You can''t send mail.}
					bCR;
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
			end
			else
			begin
				OutLine(RetInStr(64), true, 0);
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
	end;
end.