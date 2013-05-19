{ Segments: MessageSearcher_1 }
unit MessageSearcher;

interface
	uses
		AppleTalk, ADSP, Serial, Sound, Initial, LoadAndSave, NodePrefs2, Message_Editor, inpOut4, Quoter, MessNTextOutput;

	procedure DoMessageSearch;

implementation

{$S MessageSearcher_1}
{-----------------------------------------------------------------------}
	function DisplayForumSearch: integer;
		var
			i, b: integer;
			tempString: str255;
	begin
		with curglobs^ do
		begin
			ClearScreen;
			OutLine(RetInStr(800), false, 2);	{Search which forums?}
			bCR;
			b := 0;
			for i := 1 to InitSystHand^^.numMForums do
				if MForumOk(i) then
				begin
					b := b + 1;
					if (not MessageSearch^^.SearchForums[21]) and (not MessageSearch^^.SearchForums[22]) and (not MessageSearch^^.SearchForums[23]) then
					begin
						if MessageSearch^^.SearchForums[i] then
							OutLine(StringOf('*', b : 2, '. '), true, 2)
						else
							OutLine(StringOf(' ', b : 2, '. '), true, 2);
						OutLine(MForum^^[i].Name, false, 1);
					end
					else
					begin
						OutLine(StringOf(' ', b : 2, '. '), true, 2);
						OutLine(MForum^^[i].Name, false, 1);
					end;
				end;
			if not MessageSearch^^.SearchForums[21] then
				OutLine(StringOf(' ', b + 1 : 2, '. '), true, 2)
			else
				OutLine(StringOf('*', b + 1 : 2, '. '), true, 2);
			OutLine(RetInStr(801), false, 1);	{All Forums}
			if not MessageSearch^^.SearchForums[22] then
				OutLine(StringOf(' ', b + 2 : 2, '. '), true, 2)
			else
				OutLine(StringOf('*', b + 2 : 2, '. '), true, 2);
			OutLine(concat(RetInStr(818), MConference[inForum]^^[inConf].Name), false, 1); {Search Conference: }
			if not MessageSearch^^.SearchForums[23] then
				OutLine(StringOf(' ', b + 3 : 2, '. '), true, 2)
			else
				OutLine(StringOf('*', b + 3 : 2, '. '), true, 2);
			OutLine(RetInStr(819), false, 1); {Search by default Q-Scan setup.}
			DisplayforumSearch := b + 3;
		end;
	end;

{-----------------------------------------------------------------------}
	function FigureForumSearch (whichForum: integer): integer;
		var
			i, b: integer;
			tempString: str255;
	begin
		with curglobs^ do
		begin
			b := 0;
			for i := 1 to InitSystHand^^.numMForums do
				if MForumOk(i) then
				begin
					b := b + 1;
					if b = whichForum then
						leave;
				end;
			FigureForumSearch := i;
		end;
	end;

{-----------------------------------------------------------------------}
	function CheckColorCodes (Position: integer): integer;
		var
			Finish: integer;
	begin
		with curGlobs^ do
		begin
			Finish := Position;
			repeat
				Finish := Finish + 1;
			until curWriting^^[Finish] <> char(3);
			if (pos(curWriting^^[Finish], '0123456789') <> 0) and (pos(curWriting^^[Finish + 1], '0123456789') <> 0) then
				Finish := Finish + 4;

			CheckColorCodes := Finish;
		end;
	end;

{-----------------------------------------------------------------------}
	procedure StripColorCodes;
		var
			NumChars, Position, Finish, Wrap: longint;
			OldInitials: string[4];
	begin
		with curGlobs^ do
		begin
			NumChars := GetHandleSize(handle(curWriting)) - 1;
			Position := 0;
			repeat
				if curWriting^^[Position] = char(3) then
				begin
					Finish := CheckColorCodes(Position);
					BlockMove(@curWriting^^[Finish + 1], @curWriting^^[Position], NumChars - (Finish + 1));
					SetHandleSize(handle(curWriting), GetHandleSize(handle(curWriting)) - ((Finish + 1) - Position));
					NumChars := NumChars - ((Finish + 1) - Position);
					Position := Position - 1;
				end
				else if (curWriting^^[Position] = char(8)) or (curWriting^^[Position] = char(26)) or (curWriting^^[Position] = char(13)) then
				begin
					BlockMove(@curWriting^^[Position + 1], @curWriting^^[Position], NumChars - (Position + 1));
					SetHandleSize(handle(curWriting), GetHandleSize(handle(curWriting)) - 1);
					NumChars := NumChars - 1;
					Position := Position - 1;
				end;
				Position := Position + 1;
			until Position >= NumChars;
		end;
	end;

{-----------------------------------------------------------------------}
	procedure MakeNetAddress;
	external;

	function MakeInternetAddress (TheLine: str255): str255;
	external;

{-----------------------------------------------------------------------}
	procedure DoMessageSearch;
		const
			spaces = '                                        ';
		var
			i, x, dm: integer;
			l, lcount, lcount2: longint;
			SetUp, Finished, tb: boolean;
			s, s2: str255;
			FirstLett, SecondLett: char;
			result: OSErr;
			s39: string[39];
			s30: string[30];
	begin
		with curGlobs^ do
		begin
			case MessSearchDo of
				MSearch1: {Setup Variables}
				begin
					if MessageSearch <> nil then
					begin
						DisposHandle(handle(MessageSearch));
						MessageSearch := nil;
					end;
					MessageSearch := MessageSearchHand(NewHandleClear(sizeOf(MessageSearchRec) + (sizeOf(integer) * 49)));
					MoveHHi(handle(MessageSearch));

					MessageSearch^^.SearchTo := true;
					MessageSearch^^.SearchFrom := true;
					MessageSearch^^.SearchSubject := true;
					MessageSearch^^.SearchText := false;
					MessageSearch^^.SearchAll := false;
					for i := 1 to 23 do
						MessageSearch^^.SearchForums[i] := false;
					MessageSearch^^.SearchForums[23] := true;
					MessageSearch^^.KeyWord := '';

					saveInForum := -99;	{So we can tell weather to restore or not.}
					saveInSub := -99;

					MessSearchDo := MSearch2;
				end;
				MSearch2:	{Display Search What? Menu}
				begin
					ClearScreen;
					OutLine('Search which parts of messages?', false, 2);
					bCR;
					if not MessageSearch^^.SearchAll then
					begin
						if MessageSearch^^.SearchTo then
							OutLine('* ', true, 2)
						else
							OutLine('  ', true, 2);
						OutLine(RetInStr(802), false, 1);	{1. To}
						if MessageSearch^^.SearchFrom then
							OutLine('* ', true, 2)
						else
							OutLine('  ', true, 2);
						OutLine(RetInStr(803), false, 1);	{2. From}
						if MessageSearch^^.SearchSubject then
							OutLine('* ', true, 2)
						else
							OutLine('  ', true, 2);
						OutLine(RetInStr(804), false, 1);	{3. Subject}
						if MessageSearch^^.SearchText then
							OutLine('* ', true, 2)
						else
							OutLine('  ', true, 2);
						OutLine(RetInStr(805), false, 1);	{4. Text}
						OutLine('  ', true, 2);
						OutLine(RetInStr(806), false, 1);	{5. All}
					end
					else
					begin
						OutLine(concat('  ', RetInStr(802)), true, 1);
						OutLine(concat('  ', RetInStr(803)), true, 1);
						OutLine(concat('  ', RetInStr(804)), true, 1);
						OutLine(concat('  ', RetInStr(805)), true, 1);
						OutLine('* ', true, 2);
						OutLine(RetInStr(806), false, 1);
					end;
					bCR;
					bCR;
					NumbersPrompt(RetInStr(807), 'CQ', 5, 1);	{(1 - 5), (C)ontinue, (Q)uit: }
					MessSearchDo := MSearch3;
				end;
				MSearch3: {Check Search What Prompt}
				begin
					MessSearchDo := MSearch2;
					if (curPrompt = 'C') or (curPrompt = '') then
					begin
						if (MessageSearch^^.SearchTo) or (MessageSearch^^.SearchFrom) or (MessageSearch^^.SearchSubject) or (MessageSearch^^.SearchText) or (MessageSearch^^.SearchAll) then
							MessSearchDo := MSearch4
						else
							OutChr(char(7));
					end
					else if (curPrompt = '1') then
					begin
						MessageSearch^^.SearchTo := not MessageSearch^^.SearchTo;
						MessageSearch^^.SearchAll := false;
					end
					else if (curPrompt = '2') then
					begin
						MessageSearch^^.SearchFrom := not MessageSearch^^.SearchFrom;
						MessageSearch^^.SearchAll := false;
					end
					else if (curPrompt = '3') then
					begin
						MessageSearch^^.SearchSubject := not MessageSearch^^.SearchSubject;
						MessageSearch^^.SearchAll := false;
					end
					else if (curPrompt = '4') then
					begin
						MessageSearch^^.SearchText := not MessageSearch^^.SearchText;
						MessageSearch^^.SearchAll := false;
					end
					else if (curPrompt = '5') then
					begin
						MessageSearch^^.SearchAll := not MessageSearch^^.SearchAll;
						if MessageSearch^^.SearchAll then
						begin
							MessageSearch^^.SearchTo := false;
							MessageSearch^^.SearchFrom := false;
							MessageSearch^^.SearchSubject := false;
							MessageSearch^^.SearchText := false;
						end;
					end
					else if (curPrompt = 'Q') then
						MessSearchDo := MSearch8;
				end;
				MSearch4:	{Search Which Forums?}
				begin
					crossInt1 := DisplayForumSearch;
					bCR;
					bCR;
					NumbersPrompt(StringOf('(1 - ', crossInt1 : 0, ')', RetInStr(808)), 'CQ', crossInt1, 1);	{, (C)ontinue, (Q)uit]: }
					MessSearchDo := MSearch5;
				end;
				MSearch5:	{Check Search Which Forums Prompt}
				begin
					MessSearchDo := MSearch4;
					if (curPrompt = 'C') or (curPrompt = '') then
					begin
						for i := 1 to 23 do
							if MessageSearch^^.SearchForums[i] then
							begin
								MessSearchDo := MSearch6;
								leave;
							end;
						if MessSearchDo <> MSearch6 then
							OutChr(char(7));
					end
					else if (curPrompt = 'Q') then
						MessSearchDo := MSearch8
					else
					begin
						if (curPrompt = StringOf(crossInt1 - 2 : 0)) then
						begin
							MessageSearch^^.SearchForums[21] := not MessageSearch^^.SearchForums[21];
							if MessageSearch^^.SearchForums[21] then
							begin
								for i := 1 to 20 do
									MessageSearch^^.SearchForums[i] := false;
								MessageSearch^^.SearchForums[22] := false;
								MessageSearch^^.SearchForums[23] := false;
							end;
						end
						else if (curPrompt = StringOf(crossInt1 - 1 : 0)) then
						begin
							MessageSearch^^.SearchForums[22] := not MessageSearch^^.SearchForums[22];
							if MessageSearch^^.SearchForums[22] then
							begin
								for i := 1 to 20 do
									MessageSearch^^.SearchForums[i] := false;
								MessageSearch^^.SearchForums[21] := false;
								MessageSearch^^.SearchForums[23] := false;
							end;
						end
						else if (curPrompt = StringOf(crossInt1 : 0)) then
						begin
							MessageSearch^^.SearchForums[23] := not MessageSearch^^.SearchForums[23];
							if MessageSearch^^.SearchForums[23] then
							begin
								for i := 1 to 20 do
									MessageSearch^^.SearchForums[i] := false;
								MessageSearch^^.SearchForums[21] := false;
								MessageSearch^^.SearchForums[22] := false;
							end;
						end
						else
						begin
							MessageSearch^^.SearchForums[21] := false;
							MessageSearch^^.SearchForums[22] := false;
							MessageSearch^^.SearchForums[23] := false;
							StringToNum(curPrompt, l);
							crossInt1 := FigureForumSearch(l);
							MessageSearch^^.SearchForums[crossInt1] := not MessageSearch^^.SearchForums[crossInt1];
						end;
					end;
				end;
				MSearch6: {Ask For Text to Search For}
				begin
					ClearScreen;
					OutLine(RetInStr(809), false, 2);	{Please enter the text to search for. Pressing return will begin the search.}
					bCR;
					LettersPrompt('', '', 40, false, false, false, char(0));
					ANSIPrompter(40);
					MessSearchDo := MSearch7;
				end;
				MSearch7: {Check Keyword Prompt}
				begin
					if curPrompt = '' then
						MessSearchDo := MSearch8
					else
					begin
						MessageSearch^^.KeyWord := curPrompt;
						MessSearchDo := MSearch9;
					end;
				end;
				MSearch8: {Dispose and GoHome}
				begin
					if MessageSearch <> nil then
					begin
						DisposHandle(handle(MessageSearch));
						MessageSearch := nil;
					end;
					if curWriting <> nil then
					begin
						DisposHandle(handle(curWriting));
						curWriting := nil;
					end;

					BoardAction := none;
					wasSearching := false;

					if (saveInForum <> -99) then
						inForum := saveInForum;
					if (saveInSub <> -99) then
						inConf := saveInSub;
					GoHome;
				end;
				MSearch9: {Init Search Variables & Branch}
				begin
					bCR;
					sysopStop := false;
					lastKeyPressed := tickCount;
					BoardAction := Repeating;
					if MessageSearch^^.KeyWord[length(MessageSearch^^.KeyWord)] = '*' then
						Delete(MessageSearch^^.KeyWord, length(MessageSearch^^.KeyWord), 1);
					if (length(MessageSearch^^.KeyWord) > 0) then
					begin
						s := MessageSearch^^.KeyWord;
						UprString(s, true);
						MessageSearch^^.KeyWord := s;
						MessSearchDo := MSearch10;
						saveInForum := inForum;
						saveInSub := inConf;
						inForum := 0;
						inConf := 0;
						OutLine(RetInStr(810), true, 1);	{Searching. Press any key to abort.}
						if MessageSearch^^.SearchForums[22] then
						begin
							inForum := saveInForum;
							inConf := saveInSub;
							OutLine(concat('<', RetInStr(813), MConference[inForum]^^[inConf].Name, '>'), true, 1);	{Searching Conference: }
							OpenBase(inForum, inConf, false);
							if curNumMess > 0 then
							begin
								inMessage := 1;
								MessSearchDo := MSearch12;
							end
							else
							begin
								CloseBase;
								MessSearchDo := MSearch8;
							end;
						end;
					end
					else
						MessSearchDo := MSearch8;
				end;
				MSearch10: {Setup search Forum Params}
				begin
					SetUp := false;
					Finished := false;
					repeat
						inForum := inForum + 1;
						if (inForum > InitSystHand^^.NumMForums) then
							Finished := true
						else if (MessageSearch^^.SearchForums[inForum]) or (((MessageSearch^^.SearchForums[21]) or (MessageSearch^^.SearchForums[23])) and (MForumOk(inForum))) then
						begin
							bCR;
							OutLine(concat('<', RetInStr(811), MForum^^[inForum].Name, '>'), true, 2); {Advancing to Forum: }
							inConf := 0;
							SetUp := true;
							MessSearchDo := MSearch11;
						end;
					until SetUp or Finished;
					if Finished then
					begin
						OutLine(RetInStr(812), true, 1);	{Search Completed.}
						MessSearchDo := MSearch8;
					end;
				end;
				MSearch11:	{Setup search Conf Params}
				begin
					if MessageSearch^^.SearchForums[22] then
					begin
						OutLine(RetInStr(812), true, 1);	{Search Completed.}
						MessSearchDo := MSearch8;
					end
					else
					begin
						SetUp := false;
						Finished := false;
						MessageSearch^^.NumFound := 0;
						SetHandleSize(handle(MessageSearch), SizeOf(MessageSearchRec) + (sizeOf(integer) * 49));
						crossInt8 := 50;
						repeat
							inConf := inConf + 1;
							if (inConf > MForum^^[inForum].numConferences) then
								Finished := true
							else if (MessageSearch^^.SearchForums[23]) and (MConferenceOk(inForum, inConf)) and (thisUser.WhatNScan[inForum, inConf]) then
							begin
								OutLine(concat('<', RetInStr(813), MConference[inForum]^^[inConf].Name, '>'), true, 1);	{Searching Conference: }
								OpenBase(inForum, inConf, false);
								if curNumMess > 0 then
								begin
									inMessage := 1;
									SetUp := true;
								end
								else
									CloseBase;
							end
							else if MConferenceOk(inForum, inConf) and (not MessageSearch^^.SearchForums[23]) then
							begin
								OutLine(concat('<', RetInStr(813), MConference[inForum]^^[inConf].Name, '>'), true, 1);	{Searching Conference: }
								OpenBase(inForum, inConf, false);
								if curNumMess > 0 then
								begin
									inMessage := 1;
									SetUp := true;
								end
								else
									CloseBase;
							end;
						until SetUp or Finished;
						if Finished then
							MessSearchDo := MSearch10
						else
							MessSearchDo := MSearch12;
					end;
				end;
				MSearch12: {Do SearchTo, SearchFrom, SearchSubject}
				begin
					lastKeyPressed := TickCount;
					MessageSearch^^.MatchedMessage := false;
					if not aborted then
					begin
						curMesgRec := curBase^^[inMessage - 1];
						if (MessageSearch^^.SearchTo) or (MessageSearch^^.SearchAll) then
						begin
							s := curMesgRec.toUserName;
							UprString(s, true);
							if (pos(MessageSearch^^.KeyWord, s) <> 0) then
								MessageSearch^^.MatchedMessage := true;
						end;
						if (not MessageSearch^^.MatchedMessage) and ((MessageSearch^^.SearchFrom) or (MessageSearch^^.SearchAll)) then
						begin
							s := curMesgRec.fromUserName;
							UprString(s, true);
							if (pos(MessageSearch^^.KeyWord, s) <> 0) then
								MessageSearch^^.MatchedMessage := true;
						end;
						if (not MessageSearch^^.MatchedMessage) and ((MessageSearch^^.SearchSubject) or (MessageSearch^^.SearchAll)) then
						begin
							s := curMesgRec.Title;
							UprString(s, true);
							if (pos(MessageSearch^^.KeyWord, s) <> 0) then
								MessageSearch^^.MatchedMessage := true;
						end;
					end
					else
						MessSearchDo := MSearch8;

					if (not aborted) and (not MessageSearch^^.MatchedMessage) and ((MessageSearch^^.SearchText) or (MessageSearch^^.SearchAll)) then
						MessSearchDo := MSearch13
					else if (not aborted) then
						MessSearchDo := MSearch16;
				end;
				MSearch13: {Break This Up so there is no noticable slow down when searching}
				begin
					if (curWriting <> nil) then
					begin
						DisposHandle(handle(curWriting));
						curWriting := nil;
					end;
					curWriting := ReadMessage(curmesgrec.storedAs, inForum, inConf);
					StripColorCodes;
					openTextSize := GetHandleSize(handle(curWriting));
					if (curWriting <> nil) and (openTextSize > 0) then
						MessSearchDo := MSearch14
					else
						MessSearchDo := MSearch16;
				end;
				MSearch14:	{Search the First 15000 characaters}
				begin
					if not (aborted) then
					begin
						if openTextSize > 15000 then
							l := 15000
						else
							l := openTextSize;
						FirstLett := Chr(Ord(MessageSearch^^.KeyWord[1]) + 32);
						if (length(MessageSearch^^.KeyWord) > 1) then
							SecondLett := Chr(Ord(MessageSearch^^.KeyWord[2]) + 32);
						for lcount := 0 to l do
						begin
							if (curWriting^^[lcount] = MessageSearch^^.KeyWord[1]) or (curWriting^^[lcount] = FirstLett) then
								if (length(MessageSearch^^.KeyWord) > 1) then
								begin
									if (curWriting^^[lcount + 1] = MessageSearch^^.KeyWord[2]) or (curWriting^^[lcount + 1] = SecondLett) then
									begin
										s[0] := char(0);
										for lcount2 := lcount to (lcount + (length(MessageSearch^^.KeyWord) - 1)) do
											if (curWriting^^[lcount2] >= char('a')) and (curWriting^^[lcount2] <= char('z')) then
												s := concat(s, chr(ord(curWriting^^[lcount2]) - 32))
											else
												s := concat(s, curWriting^^[lcount2]);
										if (MessageSearch^^.KeyWord = s) then
										begin
											MessageSearch^^.MatchedMessage := true;
											leave;
										end;
									end;
								end
								else
								begin
									MessageSearch^^.MatchedMessage := true;
									leave;
								end;
						end;

						if (MessageSearch^^.MatchedMessage) then
							MessSearchDo := MSearch16
						else if (l < openTextSize) then
							MessSearchDo := MSearch15
						else
							MessSearchDo := MSearch16;
					end
					else
						MessSearchDo := MSearch8;
				end;
				MSearch15:	{Search the Rest of the Text, go back the length of the Keyword to make sure we did not miss it.}
				begin
					if not (aborted) then
					begin
						l := 15000 - length(MessageSearch^^.KeyWord);
						FirstLett := Chr(Ord(MessageSearch^^.KeyWord[1]) + 32);
						if (length(MessageSearch^^.KeyWord) > 1) then
							SecondLett := Chr(Ord(MessageSearch^^.KeyWord[2]) + 32);
						for lcount := l to openTextSize do
						begin
							if (curWriting^^[lcount] = MessageSearch^^.KeyWord[1]) or (curWriting^^[lcount] = FirstLett) then
								if (length(MessageSearch^^.KeyWord) > 1) then
								begin
									if (curWriting^^[lcount + 1] = MessageSearch^^.KeyWord[2]) or (curWriting^^[lcount + 1] = SecondLett) then
									begin
										s[0] := char(0);
										for lcount2 := lcount to (lcount + (length(MessageSearch^^.KeyWord) - 1)) do
											if (curWriting^^[lcount2] >= char('a')) and (curWriting^^[lcount2] <= char('z')) then
												s := concat(s, chr(ord(curWriting^^[lcount2]) - 32))
											else
												s := concat(s, curWriting^^[lcount2]);
										if (MessageSearch^^.KeyWord = s) then
										begin
											MessageSearch^^.MatchedMessage := true;
											leave;
										end;
									end;
								end
								else
								begin
									MessageSearch^^.MatchedMessage := true;
									leave;
								end;
						end;

						MessSearchDo := MSearch16;
					end
					else
						MessSearchDo := MSearch8;
				end;
				MSearch16: {The Brancher and Adder??}
				begin
					if MessageSearch^^.MatchedMessage then
					begin
						MessageSearch^^.NumFound := MessageSearch^^.NumFound + 1;
						if (MessageSearch^^.NumFound > crossInt8) then
						begin
							SetHandleSize(handle(MessageSearch), GetHandleSize(handle(MessageSearch)) + (sizeOf(integer) * 49));
							crossInt8 := crossInt + 50;
						end;
						MessageSearch^^.MessageArray[MessageSearch^^.NumFound - 1] := inMessage - 1;
					end;

					inMessage := inMessage + 1;
					if (inMessage > curNumMess) and (not aborted) and (MessageSearch^^.NumFound = 0) then
						MessSearchDo := MSearch11
					else if (inMessage > curNumMess) and (not aborted) and (MessageSearch^^.NumFound > 0) then
					begin
						crossInt8 := 0;	{Our simulated inMessage}
						inMessage := MessageSearch^^.MessageArray[crossInt8] + 1;
						curMesgRec := curBase^^[inMessage - 1];
						curPrompt := 'T';
						MessSearchDo := MSearch18;
						BoardAction := none;
					end
					else if (inMessage <= curNumMess) and (not aborted) then
						MessSearchDo := MSearch12
					else if (aborted) then
						MessSearchDo := MSearch8;
				end;
				MSearch17:	{Message Prompt}
				begin
					HelpNum := 16;
					curMesgRec := curBase^^[MessageSearch^^.MessageArray[crossInt8]];
					OutLine('[', true, 3);
					OutLine(MConference[inForum]^^[inConf].Name, false, 4);
					OutLine('] ', false, 3);
					if (curBase^^[MessageSearch^^.MessageArray[crossInt8]].FileAttached) then
						NumbersPrompt(stringOf('Read:(1-', MessageSearch^^.NumFound : 0, ',^', crossInt8 + 1 : 0, ')', RetInStr(814)), 'A+-<>RC=TQD?', MessageSearch^^.NumFound, 1)	{, (D)ownload, (C)ontinue, (Q)uit, ? :}
					else
						NumbersPrompt(stringOf('Read:(1-', MessageSearch^^.NumFound : 0, ',^', crossInt8 + 1 : 0, ')', RetInStr(815)), 'A+-<>RC=TQ?', MessageSearch^^.NumFound, 1);	{, (C)ontinue, (Q)uit, ? :}
					MessSearchDo := MSearch18;
				end;
				MSearch18: {Check Message Prompt}
				begin
					MessSearchDo := MSearch17;
					if (curPrompt = 'A') then
					begin
						if not curMesgRec.anonyFrom then
						begin
							wasSearching := true;
							reply := True;
							replyStr := curMesgRec.Title;
							UprString(replyStr, false);
							if (pos('RE:', replyStr) = 0) then
								replyStr := concat('Re: ', curMesgRec.Title)
							else
								replyStr := curMesgRec.Title;
							newMsg := true;
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
								s := takeMsgTop;
								s := takeMsgTop;
								s := takeMsgTop;
								s := MakeInternetAddress(s);
								if s <> char(0) then
									curPrompt := s
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
							fromQScan := false;
							SetUpQuoteText(curMesgRec.fromUserName, curMesgRec.StoredAs, inForum, inConf);
							if (MConference[inForum]^^[inConf].AnonID = 0) then
								tb := false
							else
								tb := true;
							if (MConference[inForum]^^[inConf].RealNames) then
								s := thisUser.RealName
							else
								s := thisUser.UserName;
							if wasAnonymous then
								TheQuote.Header := MakeQuoteHeader('>>UNKNOWN<<', s, curMesgRec.title, tb)
							else
								TheQuote.Header := MakeQuoteHeader(curMesgRec.fromUserName, s, curMesgRec.title, tb);
						end
						else
						begin
							OutLine(RetInStr(816), true, 0);	{No Auto-Replies to anonymous messages!}
							bCR;
							MessSearchDo := MSearch17;
						end;
					end
					else if (curPrompt = '') or (curPrompt = '+') or (curprompt = '>') then
					begin
						if MessageSearch^^.NumFound > crossInt8 + 1 then
						begin
							crossInt8 := crossInt8 + 1;
							inMessage := MessageSearch^^.MessageArray[crossInt8] + 1;
							PrintCurMessage(false);
						end
						else
						begin
							bCR;
							YesNoQuestion(RetInStr(817), true);	{Continue Search (Y/N)? }
							MessSearchDo := MSearch19;
						end;
					end
					else if (curPrompt = '-') or (curprompt = '<') then
					begin
						if crossInt8 + 1 > 1 then
						begin
							crossInt8 := crossInt8 - 1;
							inMessage := MessageSearch^^.MessageArray[crossInt8] + 1;
						end;
						PrintCurMessage(false);
					end
					else if (curPrompt = 'R') then
					begin
						if MConference[inForum]^^[inConf].SLtoPost <= thisUser.SL then
						begin
							MessSearchDo := MSearch20;
							MessageSearch^^.MatchedDate := curBase^^[MessageSearch^^.MessageArray[0]].DateEn;
							fromQScan := false;
							PostDo := postOne;
							BoardSection := post;
							reply := true;
							newMsg := true;
							wasSearching := true;
							wasEmail := false;
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
							SetUpQuoteText(curBase^^[inMessage - 1].fromuserName, curMesgRec.storedAs, inForum, inConf);
							if (MConference[inForum]^^[inConf].AnonID = 0) then
								tb := false
							else
								tb := true;
							if (MConference[inForum]^^[inConf].RealNames) then
								s := thisUser.RealName
							else
								s := thisUser.UserName;
							if wasAnonymous then
								TheQuote.Header := MakeQuoteHeader('>>UNKNOWN<<', s, curBase^^[inMessage - 1].title, tb)
							else
								TheQuote.Header := MakeQuoteHeader(replyToStr, s, curBase^^[inMessage - 1].title, tb);
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
						end;
					end
					else if (curPrompt = 'C') then
					begin
						lastKeyPressed := TickCount;
						BoardAction := Repeating;
						MessSearchDo := MSearch11;
					end
					else if (curPrompt = '=') then
					begin
						PrintCurMessage(false);
					end
					else if (curPrompt = 'T') then
					begin
						thisUser.foregrounds[17] := 5;
						thisUser.backgrounds[17] := 0;
						thisUser.intense[17] := false;
						thisUser.underlines[17] := false;
						thisUser.blinking[17] := false;
						bCR;
						i := 1;
						repeat
							s39 := curBase^^[MessageSearch^^.MessageArray[crossInt8]].title;
							if (s39[1] = char(0)) then
								Delete(s39, 1, 1);
							s39 := concat(s39, spaces);
							if (curBase^^[MessageSearch^^.MessageArray[crossInt8]].FileAttached) then
								s39 := concat('*FILE* ', s39);
							s30 := curBase^^[MessageSearch^^.MessageArray[crossInt8]].fromUsername;
							if (curBase^^[MessageSearch^^.MessageArray[crossInt8]].anonyFrom) and (thisUser.CantReadAnon) then
								s30 := '>>UNKNOWN<<'
							else if (curBase^^[MessageSearch^^.MessageArray[crossInt8]].anonyFrom) and (not thisUser.CantReadAnon) then
								s30 := concat('<<', s30, '>>');
							NumToString(crossInt8 + 1, s);
							if (curBase^^[MessageSearch^^.MessageArray[crossInt8]].fromUserNum <> thisUser.UserNum) then
							begin
								if length(s) = 1 then
									s := concat('(', s, ')   ')
								else if length(s) = 2 then
									s := concat('(', s, ')  ')
								else
									s := concat('(', s, ') ');
								if thisUser.TerminalType = 1 then
								begin
									if curBase^^[MessageSearch^^.MessageArray[crossInt8]].DateEn <= thisUser.lastMsgs[inForum, inConf] then
										bufferIt(concat('  ', s), false, 2)
									else
										bufferIt(concat('* ', s), false, 2);
									bufferIt(concat(s39, ' '), false, 1);
									bufferIt(char(186), false, 1);
									bufferIt(concat(' ', s30), false, 5);
								end
								else
								begin
									if curBase^^[MessageSearch^^.MessageArray[crossInt8]].DateEn <= thisUser.lastMsgs[inForum, inConf] then
										bufferIt(concat('  ', s, s39, ' | ', s30), false, 0)
									else
										bufferIt(concat('* ', s, s39, ' | ', s30), false, 0);
								end;
							end
							else
							begin
								if length(s) = 1 then
									s := concat('[', s, ']   ')
								else if length(s) = 2 then
									s := concat('[', s, ']  ')
								else
									s := concat('[', s, '] ');
								if thisUser.TerminalType = 1 then
								begin
									if curBase^^[MessageSearch^^.MessageArray[crossInt8]].DateEn <= thisUser.lastMsgs[inForum, inConf] then
										bufferIt(concat('  ', s), false, 2)
									else
										bufferIt(concat('* ', s), false, 2);
									bufferIt(concat(s39, ' '), false, 1);
									bufferIt(char(186), false, 1);
									bufferIt(concat(' ', s30), false, 5);
								end
								else
								begin
									if curBase^^[MessageSearch^^.MessageArray[crossInt8]].DateEn <= thisUser.lastMsgs[inForum, inConf] then
										bufferIt(concat('  ', s, s39, ' | ', s30), false, 0)
									else
										bufferIt(concat('* ', s, s39, ' | ', s30), false, 0);
								end;
							end;
							crossInt8 := crossInt8 + 1;
							i := i + 1;
							bufferbCR;
						until (i >= 21) or (crossInt8 + 1 > MessageSearch^^.NumFound);
						crossInt8 := crossInt8 - 1;
						ReleaseBuffer;
					end
					else if (curPrompt = 'Q') then
						MessSearchDo := MSearch8
					else if (curPrompt = 'D') then
					begin
						if (curBase^^[inMessage - 1].FileAttached) then
						begin
							WasAttach := true;
							AttachFName := curBase^^[inMessage - 1].FileName;
							WasAttachMac := curBase^^[inMessage - 1].isAMacFile;
							bCR;
							YesNoQuestion(RetInStr(126), true);
							MessSearchDo := MSearch23;
						end;
					end
					else if (curPrompt = '?') then
					begin
						if LoadSpecialText(HelpFile, 37) then
						begin
							if thisUser.TerminalType = 1 then
								doM(0);
							BoardAction := ListText;
							bCR;
						end;
					end
					else if (curPrompt[1] > '0') and (curPrompt[1] <= '9') then
					begin
						StringToNum(curprompt, l);
						if (l <= MessageSearch^^.NumFound) and (l > 0) then
						begin
							crossInt8 := l - 1;
							inMessage := MessageSearch^^.MessageArray[crossInt8] + 1;
						end;
						PrintCurMessage(false);
					end;
				end;
				MSearch19: {Continue Search Check Prompt}
				begin
					if (curPrompt = 'Y') then
					begin
						lastKeyPressed := TickCount;
						BoardAction := Repeating;
						MessSearchDo := MSearch11;
					end
					else
						MessSearchDo := MSearch8;
				end;
				MSearch20: {Figure Anonymous}
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
						MessSearchDo := MSearch21;
					end
					else
					begin
						OutLine(RetInStr(178), true, 3);			{Aborted.}
						bCR;
						MessSearchDo := MSearch17;
					end;
				end;
				MSearch21: {Save The Message}
				begin
					OutLine(RetInStr(180), true, 0);				{Saving...}
					if MConference[inForum]^^[inConf].ConfType <> 0 then
						SaveNetPost;
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
					GetDateTime(l);
					curMesgRec.DateEn := l;
					for i := 0 to 5 do
						curMesgRec.reserved[i] := char(0);
					IUDateString(l, abbrevdate, s);
					IUTimeString(l, true, s2);
					AddLine(concat(s, ' ', s2));
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
						for i := 1 to MessageSearch^^.NumFound do
							if MessageSearch^^.MessageArray[i - 1] = dm then
							begin
								for x := 1 to MessageSearch^^.NumFound - 1 do
									MessageSearch^^.MessageArray[i - 1] := MessageSearch^^.MessageArray[i];
								MessageSearch^^.NumFound := MessageSearch^^.NumFound - 1;
{NEED TO ADJUST CROSSINT8 ???? }
								leave;
							end;
						for i := 1 to MessageSearch^^.NumFound do
							if MessageSearch^^.MessageArray[i - 1] > dm then
								MessageSearch^^.MessageArray[i - 1] := MessageSearch^^.MessageArray[i - 1] - 1;
						if crossInt8 + 1 > MessageSearch^^.NumFound then
							crossInt8 := crossInt8 - 1;
						inMessage := MessageSearch^^.MessageArray[crossInt8] + 1;
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
					MessSearchDo := MSearch22;
				end;
				MSearch22: {Return From Post Message}
				begin
					if (MessageSearch^^.NumFound = 0) then
					begin
						bCR;
						YesNoQuestion(RetInStr(817), true);	{Continue Search (Y/N)? }
						MessSearchDo := MSearch19;
					end
					else
					begin
						curPrompt := '=';
						MessSearchDo := MSearch18;
					end;
				end;
				MSearch23: {Check prompt for Downloading file attachment}
				begin
					if (curPrompt = 'Y') then
					begin
						FromDetach := true;
						WasEMail := false;
						wasSearching := true;
						DetachDo := Detach1;
						BoardSection := DetachFile;
					end;
					MessSearchDo := MSearch17;
				end;


				otherwise
			end;
		end;
	end;


end.