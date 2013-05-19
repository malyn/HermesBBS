{ Segments: ChatroomUtils_1 }
unit ChatroomUtils;

interface
	uses
		AppleTalk, ADSP, Serial, Sound, TCPTypes, Initial, NodePrefs2, SystemPrefs, Message_Editor, Terminal, inpOut4;

	procedure DoShowChatMenuORHelp (Menu: boolean);
	procedure UpdateANSIInChannel (WhichChannel: integer);
	procedure DoShowUserActivity;
	procedure ScrollBackNForward (Back: boolean);
	procedure ScrollHome;
	procedure ChatroomScrollClear;
	procedure ChatroomEnterExit (Enter: boolean);
	procedure ChatroomBroadcast (OutputHeader, SendToOriginating: boolean);
	procedure ChatroomSingle (ToNode: integer; OutputHeader, Beep: boolean; OverrideMsg: str255);
	function GetNodeNumber (Name: str255): integer;
	procedure DisposeChatRoom (WhichRoom: integer);
	procedure ChatroomUserSetup (WhichChannel: integer);
	procedure ChatroomBackSpace (howMany: integer);
	procedure MoveCursor (v, h: integer; SetUserPos: boolean);
	procedure DrawChatroom;
	procedure ClearBox;
	procedure ClearANSIRoom;
	procedure ListActionWords;
	procedure ResetPrivateData (Which: integer);

implementation

{$S ChatroomUtils_1}
{---------------------------------------------------------------------------------}
{													Display ANSI or non-ANSI Chat Menu											}

	procedure DoShowChatMenuORHelp (Menu: boolean);
		var
			Start, curPos, TotalSize: integer;
			ALine: str255;
			Good: boolean;
	begin
		with curGlobs^ do
		begin
			if TheChat.ChatMode = ANSIChat then
				ClearANSIRoom;
			Good := false;

			if Menu then
			begin
				Good := ReadTextFile('Chat Menu', 1, false);
				if (Good) and (thisUser.TerminalType = 1) then
					noPause := true;
			end
			else
				Good := LoadSpecialText(HelpFile, 3);

			if Good then
			begin
				Start := 0;
				TotalSize := OpenTextSize;
				for curPos := 0 to TotalSize do
					if TextHnd^^[curPos] = char(13) then
					begin
						BlockMove(@TextHnd^^[Start], @ALine[1], curPos - Start);
						ALine[0] := char(curPos - Start);
						Start := curPos + 1;
						ChatroomSingle(activeNode, false, false, ALine);
					end;
				if TextHnd <> nil then
				begin
					DisposHandle(handle(TextHnd));
					TextHnd := nil;
				end;
			end
			else if Menu then
				ChatroomSingle(activeNode, false, false, 'Menu file not found.')
			else
				ChatroomSingle(activeNode, false, false, 'Help file not found.')

		end;
	end;

{---------------------------------------------------------------------------------}
{														Update Number of People In Channel										}

	procedure UpdateANSIInChannel (WhichChannel: integer);
		const
			Line = 'ÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕ';
		var
			i, savedNode, TempPos: integer;
			s: str255;
			mySavedBD: BDact;
	begin
		s := StringOf(RetInStr(748), ChatHand^^.Channels[WhichChannel].NumInChannel : 0, ' ');
		for i := 1 to InitSystHand^^.numNodes do
			if (theNodes[i]^.BoardMode = User) and (theNodes[i]^.BoardSection = ChatRoom) and (theNodes[i]^.TheChat.ChannelNumber = WhichChannel) and (theNodes[i]^.TheChat.ChatMode = ANSIChat) and (theNodes[i]^.BoardAction <> chat) then
			begin
				curGlobs := theNodes[i];
				savedNode := activeNode;
				activeNode := i;
				with curglobs^ do
				begin
					mySavedBD := BoardAction;
					BoardAction := none;

					{Set up Blue Color}
					thisUser.foregrounds[17] := 4;
					thisUser.backgrounds[17] := 0;
					thisUser.intense[17] := false;
					thisUser.underlines[17] := false;
					thisUser.blinking[17] := false;
					if ThisUser.ScrnHght < 24 then
						MoveCursor(ThisUser.ScrnHght, 39, false)
					else
						MoveCursor(24, 39, false);
					OutLine(Line, false, 17);

					{Set up Yellow Color}
					thisUser.foregrounds[17] := 3;
					thisUser.backgrounds[17] := 0;
					thisUser.intense[17] := false;
					thisUser.underlines[17] := false;
					thisUser.blinking[17] := false;

					if ThisUser.ScrnHght < 24 then
						MoveCursor(ThisUser.ScrnHght, 80 - (length(s) + 5), false)
					else
						MoveCursor(24, 80 - (length(s) + 5), false);
					Outline(s, false, 17);
					if myPrompt.maxChars <> -4 then
						TempPos := TheChat.InputPos.h + length(curPrompt)
					else
						TempPos := TheChat.InputPos.h;
					MoveCursor(TheChat.InputPos.v, TempPos, false);

					BoardAction := mySavedBD;
				end;
				curGlobs := theNodes[savedNode];
				activeNode := savedNode;
			end;
	end;

{---------------------------------------------------------------------------------}
{											Send Message of Entering & Exiting Chatroom									}

	procedure ChatroomEnterExit (Enter: boolean);
		var
			s: str255;
			i: integer;
	begin
		with curGlobs^ do
		begin
			i := TheChat.ChannelNumber;
			if TheChat.Buffer <> nil then
			begin
				DisposHandle(handle(TheChat.Buffer));
				TheChat.Buffer := nil;
			end;
			TheChat.BufferSize := 0;
			if Enter then
			begin
				ChatHand^^.Channels[TheChat.ChannelNumber].NumInChannel := ChatHand^^.Channels[TheChat.ChannelNumber].NumInChannel + 1;
				TheChat.TheMessage[1] := concat('<', thisUser.UserName, RetInStr(749));
				ChatroomBroadcast(false, false);
				TheChat.Buffer := BufferHand(NewHandleClear(SizeOf(BufferArray)));
			end
			else
			begin
				TheChat.TheMessage[1] := concat('<', thisUser.UserName, RetInStr(750));
				ChatroomBroadcast(false, false);
				ChatHand^^.Channels[TheChat.ChannelNumber].NumInChannel := ChatHand^^.Channels[TheChat.ChannelNumber].NumInChannel - 1;
				UpdateANSIInChannel(TheChat.ChannelNumber);
			end;
			TheChat.TheMessage[1] := char(0);
		end;
	end;

{---------------------------------------------------------------------------------}
{											Output NodeNumber/UserName/User#/User Activity							}

	procedure DoShowUserActivity;
		var
			i: integer;
			ts1, ts2, ts3: str255;
	begin
		with curGlobs^ do
		begin
			if (TheChat.ChatMode = ANSIChat) and (BoardSection = Chatroom) then
				ClearANSIRoom;
			ChatroomSingle(activeNode, false, false, RetInStr(751));
			ChatroomSingle(activeNode, false, false, RetInStr(752));
			for i := 1 to InitSystHand^^.numNodes do
			begin
				if (theNodes[i]^.boardMode = User) and (theNodes[i]^.thisUser.userNum > 0) then
				begin
					ts1 := theNodes[i]^.thisUser.userName;
					if theNodes[i]^.BoardSection = ChatRoom then
						ts2 := ChatHand^^.Channels[theNodes[i]^.TheChat.ChannelNumber].ChannelName
					else if (theNodes[i]^.thisUser.coSysop) and not (theNodes[i]^.thisUser.coSysop) then
						ts2 := ''
					else
						ts2 := WhatUser(i);
					ts3 := StringOf(theNodes[i]^.thisUser.userNum : 0);
					ChatroomSingle(activeNode, false, false, StringOf(i : 2, '     ', ts1, ' ' : 33 - Length(ts1), ts3, ' ' : 9 - Length(ts3), ts2))
				end;
			end;
			if TheChat.ChatMode = TextChat then
				ChatroomSingle(activeNode, false, false, ' ');
		end;
	end;

{---------------------------------------------------------------------------------}
{											Scroll Backwards and Forwards In User Buffer								}

	procedure ScrollBackNForward (Back: boolean);
		var
			i, ViewableLines, TopLine, Start, Finish, cursorPos, z: integer;
			s, s1: str255;
			color: longint;
	begin
		with curGlobs^ do
		begin
			if TheChat.ChatMode = ANSIChat then
			begin
				if thisUser.ScrnHght > 24 then
					ViewableLines := 17
				else
					ViewableLines := thisUser.ScrnHght - 7;
				if ((TheChat.BufferSize > ViewableLines) and (Back)) or ((not Back) and (TheChat.Scrolling)) then
				begin
					if not TheChat.Scrolling then
					begin
						TheChat.Scrolling := true;
						TheChat.ScrollPosition := TheChat.BufferSize - (TheChat.OutputPos - 2);
						TheChat.LastScrollBack := true;
					end;
					if Back then
					begin
						if not TheChat.LastScrollBack then
						begin
							TheChat.ScrollPosition := TheChat.ScrollPosition - ViewableLines;
							TheChat.LastScrollBack := true;
						end;
						if TheChat.ScrollPosition - ViewableLines > 0 then
							TopLine := TheChat.ScrollPosition - ViewableLines
						else if TheChat.ScrollPosition = 1 then
							TopLine := -99
						else
						begin
							TopLine := 1;
							if TopLine + ViewableLines > TheChat.BufferSize then
								TheChat.ScrollPosition := TheChat.BufferSize
							else
								TheChat.ScrollPosition := TopLine + ViewableLines;
						end;
					end
					else
					begin
						if TheChat.LastScrollBack then
						begin
							TheChat.ScrollPosition := TheChat.ScrollPosition + 1 + ViewableLines;
							TheChat.LastScrollBack := false;
						end;
						if TheChat.ScrollPosition + ViewableLines < TheChat.BufferSize then
							TopLine := TheChat.ScrollPosition + ViewableLines
						else if TheChat.ScrollPosition + ViewableLines >= TheChat.BufferSize then
						begin
							TheChat.ScrollPosition := TheChat.ScrollPosition + 1;
							TopLine := TheChat.BufferSize;
							TheChat.Scrolling := false;
						end;
					end;
					if TopLine <> -99 then
					begin
						ClearANSIRoom;
						if Back then
						begin
							Start := TopLine;
							Finish := TheChat.ScrollPosition;
							TheChat.ScrollPosition := Start;
						end
						else
						begin
							Start := TheChat.ScrollPosition;
							Finish := TopLine;
							TheChat.ScrollPosition := Finish;
						end;
						cursorPos := 1;
						for i := Start to Finish do
						begin
							cursorPos := cursorPos + 1;
							MoveCursor(cursorPos, 2, false);
							if (TheChat.Buffer^^[i][1] = '%') and (pos(TheChat.Buffer^^[i][2], '0123456789') <> 0) then
							begin
								StringToNum(TheChat.Buffer^^[i][2], color);
								s := TheChat.Buffer^^[i];
								Delete(s, 1, 2);
								OutLine(s, false, color);
							end
							else if (TheChat.Buffer^^[i][1] = '&') and (pos(TheChat.Buffer^^[i][2], '0123456789') <> 0) then
							begin
								StringToNum(TheChat.Buffer^^[i][2], color);
								s := TheChat.Buffer^^[i];
								Delete(s, 1, 2);
								z := pos(':', s);
								if z <> 0 then
								begin
									s1 := copy(s, 1, z);
									Delete(s, 1, z);
									OutLine(s1, false, color);
									OutLine(s, false, 0);
								end
								else
									OutLine(s, false, color);
							end
							else
								OutLine(TheChat.Buffer^^[i], false, 0);
						end;
						TheChat.OutputPos := cursorPos + 1
					end;

					MoveCursor(-1, 0, false);
				end
				else
					ChatroomSingle(activeNode, false, false, RetInStr(754));
			end
			else
				ChatroomSingle(activeNode, false, false, RetInStr(755));
		end;
	end;

{---------------------------------------------------------------------------------}
{											Scroll to End of buffer and resume chatroom									}

	procedure ScrollHome;
	begin
		with curGlobs^ do
		begin
			if TheChat.Scrolling then
			begin
				TheChat.Scrolling := false;
				ChatroomScrollClear;
			end
			else
				ChatroomSingle(activeNode, false, false, RetInStr(756));
		end;
	end;

{---------------------------------------------------------------------------------}
{															Save Message to Buffer															}

	procedure SaveToBuffer (What: str255);
		var
			i: integer;
			s135: string[135];
	begin
		with curGlobs^ do
		begin
			if TheChat.BufferSize + 1 > 180 then
				BlockMove(@TheChat.Buffer^^[2], @TheChat.Buffer^^[1], SizeOf(s135) * 179)
			else
				TheChat.BufferSize := TheChat.BufferSize + 1;
			TheChat.Buffer^^[TheChat.BufferSize] := What;
		end;
	end;

{---------------------------------------------------------------------------------}
{										Move Text up 1/2 Screen and clear bottom half									}

	procedure ChatroomScrollClear;
		const
			Spaces78 = '                                                                              ';
		var
			i, x, y, z, ScreenHight: integer;
			color: longint;
			s, s1: str255;
	begin
		with curGlobs^ do
		begin
			ClearANSIRoom;
			if thisUser.ScrnHght < 24 then
				ScreenHight := thisUser.ScrnHght
			else
				ScreenHight := 24;
			x := (ScreenHight - 5) div 2;
			if TheChat.BufferSize - x > 0 then
				y := TheChat.BufferSize - x
			else
				y := 0;
			if y > 0 then
			begin
				for i := 2 to x + 2 do
				begin
					MoveCursor(i, 2, false);
					if (TheChat.Buffer^^[y][1] = '%') and (pos(TheChat.Buffer^^[y][2], '0123456789') <> 0) then
					begin
						StringToNum(TheChat.Buffer^^[y][2], color);
						s := TheChat.Buffer^^[y];
						Delete(s, 1, 2);
						OutLine(s, false, color);
					end
					else if (TheChat.Buffer^^[y][1] = '&') and (pos(TheChat.Buffer^^[y][2], '0123456789') <> 0) then
					begin
						StringToNum(TheChat.Buffer^^[y][2], color);
						s := TheChat.Buffer^^[y];
						Delete(s, 1, 2);
						z := pos(':', s);
						if z <> 0 then
						begin
							s1 := copy(s, 1, z);
							Delete(s, 1, z);
							OutLine(s1, false, color);
							OutLine(s, false, 0);
						end
						else
							OutLine(s, false, color);
					end
					else
						OutLine(TheChat.Buffer^^[y], false, 0);
					y := y + 1;
				end;
				TheChat.OutputPos := x + 3;
			end
			else
			begin
				ClearANSIRoom;
				TheChat.OutputPos := 2;
			end;
			MoveCursor(0, -1, false);
		end;
	end;

{---------------------------------------------------------------------------------}
{									Output Message to everyone in TheChat.ChannelNumber							}

	procedure ChatroomBroadcast (OutputHeader, SendToOriginating: boolean);
		var
			i, xLines, x, SavedChannel, savedNode, TempNumInChan, ScreenHight, TempPos, Counter: integer;
			UserHeader: str255;
			mySavedBD: BDact;
	begin
		NumToString(theNodes[activeNode]^.thisUser.UserNum, UserHeader);
		UserHeader := concat(theNodes[activeNode]^.thisUser.userName, ' #', UserHeader, ':');
		SavedChannel := theNodes[activeNode]^.TheChat.ChannelNumber;

		if not SendToOriginating then
			TempNumInChan := 1
		else
			TempNumInChan := 0;
		xLines := 1;
		for i := 1 to 3 do
			if theNodes[activeNode]^.TheChat.TheMessage[i] <> char(0) then
				xLines := xLines + 1
			else
				leave;

		for i := 1 to InitSystHand^^.numNodes do
			if (theNodes[i]^.BoardMode = User) and ((theNodes[i]^.BoardSection = ChatRoom) or (theNodes[i]^.BoardSection = PrivateRequest)) and (theNodes[i]^.TheChat.ChannelNumber = SavedChannel) and (not theNodes[i]^.TheChat.Scrolling) and (theNodes[i]^.BoardAction <> chat) then
			begin
				if ((not SendToOriginating) and (i <> activeNode)) or (SendToOriginating) then
				begin
					TempNumInChan := TempNumInChan + 1;
					curGlobs := theNodes[i];
					savedNode := activeNode;
					activeNode := i;
					with curglobs^ do
					begin
						mySavedBD := BoardAction;
						BoardAction := none;
						if thisUser.ScrnHght < 24 then
							ScreenHight := thisUser.ScrnHght
						else
							ScreenHight := 24;
						if (TheChat.ChatMode = ANSIChat) and (not TheChat.Scrolling) then
						begin
							if myPrompt.maxChars <> -4 then
								TempPos := TheChat.InputPos.h + length(curPrompt)
							else
								TempPos := TheChat.InputPos.h;

							MoveCursor(0, -1, false);
							if (OutputHeader) and ((length(theNodes[savedNode]^.TheChat.TheMessage[1]) + length(UserHeader)) < 79) then
								xLines := xLines - 1;

							if TheChat.OutputPos + xLines > ScreenHight - 4 then
								ChatroomScrollClear;
							Counter := 1;
							if (OutputHeader) and ((length(theNodes[savedNode]^.TheChat.TheMessage[1]) + length(UserHeader)) < 79) then
							begin
								OutLine(UserHeader, false, 2);
								OutLine(theNodes[savedNode]^.TheChat.TheMessage[1], false, 0);
								xLines := xLines + 1;
								Counter := 2;
							end
							else if OutputHeader then
								OutLine(UserHeader, false, 2)
							else
								TheChat.OutputPos := TheChat.OutputPos - 1;

							for x := Counter to 3 do
								if theNodes[savedNode]^.TheChat.TheMessage[x] <> char(0) then
								begin
									TheChat.OutputPos := TheChat.OutPutPos + 1;
									MoveCursor(0, -1, false);
									OutLine(theNodes[savedNode]^.TheChat.TheMessage[x], false, 0);
								end;
							TheChat.OutputPos := TheChat.OutPutPos + 1;
							OutLine('', false, 0);
							BoardAction := mySavedBD;
							MoveCursor(TheChat.InputPos.v, TempPos, false);
						end
						else if (TheChat.ChatMode = TextChat) and (savedNode <> activeNode) then
						begin
							if (prompting) and (length(myPrompt.promptLine) + length(curPrompt) < 30) then
								BackSpace(length(myPrompt.promptLine) + length(curPrompt))
							else if prompting then
								bCR;
							Counter := 1;
							if (OutputHeader) and ((length(theNodes[savedNode]^.TheChat.TheMessage[1]) + length(UserHeader)) < 79) then
							begin
								OutLine(UserHeader, false, 2);
								OutLine(theNodes[savedNode]^.TheChat.TheMessage[1], false, 0);
								Counter := 2;
							end
							else if OutputHeader then
								OutLine(UserHeader, false, 2);
							for x := Counter to 3 do
								if theNodes[savedNode]^.TheChat.TheMessage[x] <> char(0) then
									OutLine(theNodes[savedNode]^.TheChat.TheMessage[x], true, 0);
							OutLine('', false, 0);
							bCR;
							BoardAction := mySavedBD;
							if prompting then
								ReprintPrompt
							else if BoardAction = Writing then
								ListLine(online);
						end;

						Counter := 1;
						if (OutputHeader) and ((length(theNodes[savedNode]^.TheChat.TheMessage[1]) + length(UserHeader)) < 79) then
						begin
							SaveToBuffer(concat('&2', UserHeader, theNodes[savedNode]^.TheChat.TheMessage[1]));
							Counter := 2;
						end
						else if OutputHeader then
							SaveToBuffer(concat('%2', UserHeader));

						for x := Counter to 3 do
							if theNodes[savedNode]^.TheChat.TheMessage[x] <> char(0) then
								SaveToBuffer(theNodes[savedNode]^.TheChat.TheMessage[x])
							else
								leave;
					end;
					curGlobs := theNodes[savedNode];
					activeNode := savedNode;
				end;
			end
			else if (theNodes[i]^.BoardMode = User) and ((theNodes[i]^.BoardSection = ChatRoom) or (theNodes[i]^.BoardSection = PrivateRequest)) and (theNodes[i]^.TheChat.ChannelNumber = SavedChannel) and (theNodes[i]^.TheChat.Scrolling) then
			begin
				curGlobs := theNodes[i];
				savedNode := activeNode;
				activeNode := i;
				TempNumInChan := TempNumInChan + 1;
				if OutputHeader then
					SaveToBuffer(concat('%2', UserHeader));
				for x := 1 to 3 do
					if theNodes[savedNode]^.TheChat.TheMessage[x] <> char(0) then
						SaveToBuffer(theNodes[savedNode]^.TheChat.TheMessage[x])
					else
						leave;
				curGlobs := theNodes[savedNode];
				activeNode := savedNode;
			end;

		if TempNumInChan <> ChatHand^^.Channels[theNodes[activeNode]^.TheChat.ChannelNumber].NumInChannel then
		begin
			ChatHand^^.Channels[theNodes[activeNode]^.TheChat.ChannelNumber].NumInChannel := TempNumInChan;
			UpdateANSIInChannel(theNodes[activeNode]^.TheChat.ChannelNumber);
		end;
		for i := 1 to 3 do
			theNodes[activeNode]^.TheChat.TheMessage[i] := char(0);
	end;

{---------------------------------------------------------------------------------}
{										Output Single Message to variable WhichNode										}

	procedure ChatroomSingle (ToNode: integer; OutputHeader, Beep: boolean; OverrideMsg: str255);
		var
			UserHeader, TheReply: str255;
			savedNode, xLines, x, ScreenHight, Counter: integer;
			mySavedBD: BDact;
			UserBlocking: boolean;
	begin
		if OutputHeader then
		begin
			NumToString(theNodes[activeNode]^.thisUser.UserNum, UserHeader);
			UserHeader := concat(RetInStr(427), theNodes[activeNode]^.thisUser.userName, ' #', UserHeader, ':');
		end
		else
			UserHeader := char(0);

		if OverrideMsg = char(0) then
		begin
			if OutputHeader then
				xLines := 1
			else
				xLines := 0;
			for x := 1 to 3 do
				if theNodes[activeNode]^.TheChat.TheMessage[x] <> char(0) then
					xLines := xLines + 1
				else
					leave;
		end
		else
			xLines := 1;

		UserBlocking := false;
		if (theNodes[ToNode]^.TheChat.BlockWho = theNodes[activeNode]^.ThisUser.UserNum) or ((theNodes[ToNode]^.TheChat.BlockWho = 0) and (ToNode <> activeNode)) then
			UserBlocking := true;

		if not UserBlocking then
		begin
			curGlobs := theNodes[ToNode];
			savedNode := activeNode;
			activeNode := ToNode;
			TheReply := concat(RetInStr(757), theNodes[ToNode]^.thisUser.UserName, ' #', StringOf(theNodes[ToNode]^.thisUser.UserNum : 0), '.');	{ String 428 Message sent.}
			with curGlobs^ do
			begin
				mySavedBD := BoardAction;
				BoardAction := none;
				if thisUser.ScrnHght < 24 then
					ScreenHight := thisUser.ScrnHght
				else
					ScreenHight := 24;
				if (BoardSection <> ChatRoom) and (TheChat.WhereFrom = Nowhere) and not (theNodes[ToNode]^.myTrans.active) then
				begin
					if TheChat.ChatMode = ANSIChat then
						doM(0);
					if Beep then
					begin
						bCR;
						OutChr(char(7));
					end;
					if OutputHeader then
						OutLine(UserHeader, true, 6);
					if OverrideMsg = char(0) then
					begin
						for x := 1 to 3 do
							if theNodes[savedNode]^.TheChat.TheMessage[x] <> char(0) then
								OutLine(theNodes[savedNode]^.TheChat.TheMessage[x], true, 0);
					end
					else
						OutLine(OverrideMsg, true, 0);
					OutLine('', false, 0);
					BoardAction := mySavedBD;
					if Beep then
					begin
						bCR;
						bCR;
					end;
					if prompting then
						ReprintPrompt
					else if BoardAction = Writing then
						ListLine(online);
				end
				else if (TheChat.ChatMode = ANSIChat) and ((BoardSection = ChatRoom) or (BoardSection = PrivateRequest)) and (not TheChat.Scrolling) then
				begin
					MoveCursor(0, -1, false);
					if TheChat.OutputPos + xLines > ScreenHight - 4 then
						ChatroomScrollClear;
					Counter := 1;
					if (OutputHeader) and (OverrideMsg = char(0)) and ((length(theNodes[savedNode]^.TheChat.TheMessage[1]) + length(UserHeader)) < 79) then
					begin
						OutLine(UserHeader, false, 6);
						OutLine(theNodes[savedNode]^.TheChat.TheMessage[1], false, 0);
						Counter := 2;
					end
					else if (OutputHeader) and (OverrideMsg <> char(0)) and (length(OverrideMsg) + length(UserHeader) < 79) then
					begin
						OutLine(UserHeader, false, 2);
						OutLine(OverrideMsg, false, 0);
						Counter := 2;
					end
					else if OutputHeader then
						OutLine(UserHeader, false, 2);

					if OverrideMsg = char(0) then
					begin
						if not OutputHeader then
							TheChat.OutputPos := TheChat.OutputPos - 1;
						for x := Counter to 3 do
							if theNodes[savedNode]^.TheChat.TheMessage[x] <> char(0) then
							begin
								TheChat.OutputPos := TheChat.OutPutPos + 1;
								MoveCursor(0, -1, false);
								OutLine(theNodes[savedNode]^.TheChat.TheMessage[x], false, 0);
							end;
					end
					else if (Counter = 1) then
						OutLine(OverrideMsg, false, 0);

					TheChat.OutputPos := TheChat.OutPutPos + 1;
					OutLine('', false, 0);
					MoveCursor(-1, 0, false);
					BoardAction := mySavedBD;
				end
				else if (TheChat.ChatMode = TextChat) and ((BoardSection = ChatRoom) or (BoardSection = PrivateRequest)) then
				begin
					if (prompting) and (length(myPrompt.promptLine) + length(curPrompt) < 41) then
						BackSpace(length(myPrompt.promptLine) + length(curPrompt))
					else if prompting then
						bCR;
					Counter := 1;
					if (OutputHeader) and (OverrideMsg = char(0)) and ((length(theNodes[savedNode]^.TheChat.TheMessage[1]) + length(UserHeader)) < 79) then
					begin
						OutLine(UserHeader, false, 6);
						OutLine(theNodes[savedNode]^.TheChat.TheMessage[1], false, 0);
						Counter := 2;
					end
					else if (OutputHeader) and (OverrideMsg <> char(0)) and (length(OverrideMsg) + length(UserHeader) < 79) then
					begin
						OutLine(UserHeader, false, 2);
						OutLine(OverrideMsg, false, 0);
						Counter := 2;
					end
					else if OutputHeader then
						OutLine(UserHeader, false, 2);

					if OverrideMsg = char(0) then
					begin
						for x := Counter to 3 do
							if theNodes[savedNode]^.TheChat.TheMessage[x] <> char(0) then
								OutLine(theNodes[savedNode]^.TheChat.TheMessage[x], true, 0);
					end
					else if (Counter = 1) then
						OutLine(OverrideMsg, false, 0);

					OutLine('', false, 0);
					bCR;
					BoardAction := mySavedBD;
					if prompting then
						ReprintPrompt
					else if BoardAction = Writing then
						ListLine(online);
				end
				else
					TheReply := RetInStr(429);	{Sorry, that user cannot be sent messages right now.}
			end;

			Counter := 1;
			if (OutputHeader) and (OverrideMsg = char(0)) and ((length(theNodes[savedNode]^.TheChat.TheMessage[1]) + length(UserHeader)) < 79) then
			begin
				SaveToBuffer(concat('&6', UserHeader, theNodes[savedNode]^.TheChat.TheMessage[1]));
				Counter := 2;
			end
			else if (OutputHeader) and (OverrideMsg <> char(0)) and (length(OverrideMsg) + length(UserHeader) < 79) then
			begin
				SaveToBuffer(concat('&6', UserHeader, OverrideMsg));
				Counter := 2;
			end
			else if OutputHeader then
				SaveToBuffer(concat('%6', UserHeader));
			if (theNodes[activeNode]^.TheChat.Buffer <> nil) then
			begin
				if OverrideMsg = char(0) then
				begin
					for x := Counter to 3 do
						if theNodes[activeNode]^.TheChat.TheMessage[x] <> char(0) then
							SaveToBuffer(theNodes[activeNode]^.TheChat.TheMessage[x])
						else
							leave;
				end
				else if (Counter = 1) then
					SaveToBuffer(OverrideMsg);
			end;

			curGlobs := theNodes[savedNode];
			activeNode := savedNode;
		end;

		if (theNodes[activeNode]^.TheChat.ToNode = 999) and (ToNode <> activeNode) then
			TheReply := RetInStr(758);
		if (theNodes[activeNode]^.TheChat.ToNode = -1) then
			ToNode := activeNode;

		if UserBlocking then
			if (theNodes[ToNode]^.TheChat.BlockWho = theNodes[activeNode]^.ThisUser.UserNum) then
				TheReply := StringOf(theNodes[ToNode]^.thisUser.UserName, ' #', theNodes[ToNode]^.thisUser.UserNum : 0, ' is blocking messages from you.')
			else if (theNodes[ToNode]^.TheChat.BlockWho = 0) then
				TheReply := StringOf(theNodes[ToNode]^.thisUser.UserName, ' #', theNodes[ToNode]^.thisUser.UserNum : 0, ' is blocking messages from all users.');



		if (ToNode <> activeNode) and (theNodes[activeNode]^.TheChat.Status <> ActionWord) then
			with curGlobs^ do
			begin
				if thisUser.ScrnHght < 24 then
					ScreenHight := thisUser.ScrnHght
				else
					ScreenHight := 24;
				if (BoardSection <> ChatRoom) then
				begin
					OutLine(TheReply, true, 5);
				end
				else if (TheChat.ChatMode = ANSIChat) and (BoardSection = ChatRoom) then
				begin
					MoveCursor(0, -1, false);
					if TheChat.OutputPos + 1 > ScreenHight - 4 then
						ChatroomScrollClear;
					OutLine(TheReply, false, 5);
					TheChat.OutputPos := TheChat.OutPutPos + 1;
					MoveCursor(-1, 0, false);
				end
				else if (TheChat.ChatMode = TextChat) and (BoardSection = ChatRoom) then
				begin
					OutLine(TheReply, false, 5);
					bCR;
				end;
				SaveToBuffer(concat('%5', TheReply));
			end;

		if (theNodes[activeNode]^.TheChat.ToNode = 999) and (ToNode <> activeNode) and (theNodes[activeNode]^.TheChat.Status <> ActionWord) then
			theNodes[activeNode]^.TheChat.ToNode := -1;
	end;

{---------------------------------------------------------------------------------}
{										Returns the Node number of User Name or User #								}

	function GetNodeNumber (Name: str255): integer;
		var
			i, TheNodeNum: integer;
			s: str255;
			l: longint;
	begin
		TheNodeNum := 0;
		if Name[1] = '#' then
		begin
			Delete(Name, 1, 1);
			if length(Name) > 0 then
			begin
				StringToNum(Name, l);
				if (l <= InitSystHand^^.NumNodes) then
					if (theNodes[l]^.BoardMode = User) then
						TheNodeNum := l;
			end;
		end
		else if pos(Name[1], '123456789') <> 0 then
		begin
			StringToNum(Name, l);
			for i := 1 to InitSystHand^^.NumNodes do
				if theNodes[i]^.BoardMode = User then
					if theNodes[i]^.thisUser.UserNum = l then
					begin
						TheNodeNum := i;
						leave;
					end;
		end
		else
		begin
			UprString(Name, true);
			for i := 1 to InitSystHand^^.NumNodes do
				if (theNodes[i]^.BoardMode = User) then
				begin
					s := theNodes[i]^.thisUser.UserName;
					UprString(s, true);
					if s = Name then
					begin
						TheNodeNum := i;
						leave;
					end;
				end;
			if (TheNodeNum = 0) then	{Search for first partial name match}
				for i := 1 to InitSysthand^^.NumNodes do
					if (theNodes[i]^.BoardMode = User) then
						if (length(theNodes[i]^.thisUser.UserName) >= length(Name)) then
						begin
							s := copy(theNodes[i]^.thisUser.UserName, 1, length(Name));
							UprString(s, true);
							if s = Name then
							begin
								TheNodeNum := i;
								leave;
							end;
						end;
		end;
		GetNodeNumber := TheNodeNum;
	end;

{---------------------------------------------------------------------------------}
{								Removes Chatroom(s) from Memory. -1 = All Chatrooms								}

	procedure DisposeChatRoom (WhichRoom: integer);
		var
			i, x: integer;
	begin
		if WhichRoom <> 0 then
		begin
			if WhichRoom = -1 then
			begin
				for i := 0 to (ChatHand^^.NumChannels - 1) do
					ChatHand^^.Channels[i].Active := false;
			end;

			if (ChatHand^^.NumChannels > 1) and (WhichRoom > 0) then
			begin
				x := ChatHand^^.NumChannels - 1;
				for i := x downto WhichRoom do
					if not ChatHand^^.Channels[i].Active then
					begin
						ChatHand^^.NumChannels := ChatHand^^.NumChannels - 1;
						SetHandleSize(handle(ChatHand), GetHandleSize(handle(ChatHand)) - SizeOf(ChannelRec));
					end
					else
						leave;
			end;

			if (WhichRoom > 0) and (WhichRoom < i) then
				ChatHand^^.Channels[WhichRoom].Active := false;

			if WhichRoom = -1 then
			begin
				DisposHandle(handle(ChatHand));
				ChatHand := nil;
			end;
		end;
	end;

{---------------------------------------------------------------------------------}
{											Set up a user's variables for specified channel							}

	procedure ChatroomUserSetUp (WhichChannel: integer);
		var
			i, x, y: integer;
			SomeoneIn: boolean;
	begin
		with curGlobs^ do
		begin
			if WhichChannel = -1 then
			begin
				if ChatHand^^.NumChannels > 1 then
				begin
					y := ChatHand^^.NumChannels - 1;
					for i := y downto 1 do
						if (ChatHand^^.Channels[i].Active) then
						begin
							SomeoneIn := false;
							for x := 1 to InitSystHand^^.NumNodes do
								if (theNodes[x]^.BoardMode = User) and (theNodes[x]^.BoardSection = ChatRoom) and (theNodes[x]^.TheChat.ChannelNumber = i) then
								begin
									SomeoneIn := true;
									leave;
								end;
							if not SomeoneIn then
							begin
								ChatHand^^.Channels[i].Active := false;
								DisposeChatroom(i);
							end;
						end;
				end;
			end;

			if WhichChannel = -1 then
			begin
				{FIRST, look for a already created/non-active channel.}
				if ChatHand^^.NumChannels > 1 then
				begin
					for i := 1 to (ChatHand^^.NumChannels - 1) do
						if not (ChatHand^^.Channels[i].Active) then
						begin
							WhichChannel := i;
							ChatHand^^.Channels[i].Active := true;
							leave;
						end;
				end;
				{SECOND, if no channel found/available then create one.}
				if WhichChannel = -1 then
				begin
					ChatHand^^.NumChannels := ChatHand^^.NumChannels + 1;
					WhichChannel := ChatHand^^.NumChannels - 1;
					SetHandleSize(handle(ChatHand), GetHandleSize(handle(ChatHand)) + SizeOf(ChannelRec));
					ChatHand^^.Channels[ChatHand^^.NumChannels - 1].Active := true;
					ChatHand^^.Channels[ChatHand^^.NumChannels - 1].ChannelName := StringOf(RetInStr(759), ChatHand^^.NumChannels - 1 : 0);
					ChatHand^^.Channels[ChatHand^^.NumChannels - 1].NumInChannel := 0;
				end;
			end;
			if TheChat.WhereFrom = NoWhere then
				if thisUser.ChatANSI then
					TheChat.ChatMode := ANSIChat
				else
					TheChat.ChatMode := TextChat;

			TheChat.Status := Chatting;
			TheChat.TheMessage[1] := char(0);
			TheChat.TheMessage[2] := char(0);
			TheChat.TheMessage[3] := char(0);
			TheChat.ChannelNumber := WhichChannel;
			TheChat.Scrolling := false;
			ChatHand^^.Channels[WhichChannel].NumInChannel := ChatHand^^.Channels[WhichChannel].NumInChannel + 1;
			if TheChat.ChatMode = ANSIChat then
			begin
				TheChat.OutputPos := 2;
				TheChat.InputPos.h := 1;
				if thisUser.ScrnHght < 24 then
					TheChat.InputPos.v := thisUser.ScrnHght - 3
				else
					TheChat.InputPos.v := 21;
			end
			else
			begin
				TheChat.OutputPos := 0;
				TheChat.InputPos.h := 0;
				TheChat.InputPos.v := 0;
			end;
		end;
	end;

{---------------------------------------------------------------------------------}
{																		Backspaces Cursor															}

	procedure ChatroomBackSpace (howMany: integer);
		var
			result: OSerr;
			count: longint;
			dumRect: rect;
			ts: str255;
			i: integer;
	begin
		with curglobs^ do
		begin
			ts := '';
			for i := 1 to (3 * howMany) do
				ts := concat(' ', ts);
			ts := '';
			count := 3 * howMany;
			for i := 1 to howmany do
				ts := concat(ts, char(8));
			for i := 1 to howmany do
				ts := concat(ts, char(32));
			for i := 1 to howmany do
				ts := concat(ts, char(8));
			if not sysopLogon then
				result := AsyncMWrite(outputRef, count, @ts[1]);
			ProcessData(activeNode, @ts[1], count);

			TheChat.InputPos.h := TheChat.InputPos.h - howMany;
		end;
	end;

{---------------------------------------------------------------------------------}
{																				Moves Cursor															}

	procedure MoveCursor (v, h: integer; SetUserPos: boolean);
		var
			sH, sV, sP: str255;
	begin
		with curGlobs^ do
			if TheChat.ChatMode = ANSIChat then
			begin
				if v = -1 then
				begin
					v := TheChat.InputPos.v;
					h := TheChat.InputPos.h;
				end
				else if h = -1 then
				begin
					v := TheChat.OutputPos;
					h := 2;
				end
				else if v = -2 then
				begin
					if thisUser.ScrnHght < 24 then
						v := thisUser.ScrnHght - 3
					else
						v := 21;
					h := 2;
				end;
				if SetUserPos then
				begin
					TheChat.InputPos.h := h;
					TheChat.InputPos.v := v;
				end;

				NumToString(h, sH);
				NumToString(v, sV);
				sP := concat(sV, ';', sH, 'H');
				ANSICode(sP);
			end;
	end;

{---------------------------------------------------------------------------------}
{																Draw appropriate chatroom													}

	procedure DrawChatroom;
		var
			i, ScreenHight: integer;
			s, s2: str255;
	begin
		with curGlobs^ do
		begin
			ClearScreen;
			if TheChat.ChatMode = ANSIChat then
			begin
				{Set up Blue Color}
				thisUser.foregrounds[17] := 4;
				thisUser.backgrounds[17] := 0;
				thisUser.intense[17] := false;
				thisUser.underlines[17] := false;
				thisUser.blinking[17] := false;

				if thisUser.ScrnHght < 24 then
					ScreenHight := thisUser.ScrnHght
				else
					ScreenHight := 24;

				MoveCursor(ScreenHight - 4, 2, false);
				s := char(0);
				for i := 2 to 79 do
					s := concat(s, char(205));
				OutLine(s, false, 17);

				MoveCursor(ScreenHight, 2, false);
				OutLine(s, false, 17);

				MoveCursor(1, 2, false);
				OutLine(s, false, 17);

				for i := 1 to 3 do
				begin
					MoveCursor(ScreenHight - i, 1, false);
					OutLine(char(186), false, 17);
					MoveCursor(ScreenHight - i, 80, false);
					OutLine(char(186), false, 17);
				end;

				for i := 2 to ScreenHight - 1 do
				begin
					if i = ScreenHight - 4 then
					begin
						MoveCursor(i, 1, false);
						OutLine(char(204), false, 17);
						MoveCursor(i, 80, false);
						OutLine(char(185), false, 17);
					end
					else
					begin
						MoveCursor(i, 1, false);
						OutLine(char(186), false, 17);
						MoveCursor(i, 80, false);
						OutLine(char(186), false, 17);
					end;
				end;

				MoveCursor(1, 1, false);
				OutLine(char(201), false, 17);
				MoveCursor(1, 80, false);
				OutLine(char(187), false, 17);
				MoveCursor(ScreenHight, 1, false);
				OutLine(char(200), false, 17);
				MoveCursor(ScreenHight, 80, false);
				OutLine(char(188), false, 17);

				{Set up Yellow Color}
				thisUser.foregrounds[17] := 3;
				thisUser.backgrounds[17] := 0;
				thisUser.intense[17] := false;
				thisUser.underlines[17] := false;
				thisUser.blinking[17] := false;

				i := length(ChatHand^^.Channels[TheChat.ChannelNumber].ChannelName) + 2;
				i := i div 2;
				i := 40 - i;
				MoveCursor(1, i, false);
				OutLine(concat(' ', ChatHand^^.Channels[TheChat.ChannelNumber].ChannelName, ' '), false, 17);

				s := RetInStr(760);
				s2 := RetInStr(761);
				i := length(s) + length(s2) + 9;
				i := i div 2;
				i := 40 - i;
				MoveCursor(ScreenHight - 4, i, false);
				OutLine(concat(' ', s, ' '), false, 17);
				MoveCursor(ScreenHight - 4, i + length(s) + 7, false);
				OutLine(concat(' ', s2, ' '), false, 17);
				MoveCursor(ScreenHight, 2, false);
			end
			else
			begin
				OutLine(RetInStr(413), true, 1);	{Entering chat room...}
				OutLine(concat('Chat room name: ', ChatHand^^.Channels[TheChat.ChannelNumber].ChannelName), true, 2);
				OutLine(RetInStr(414), true, 0);	{Type /X to exit, and /H for help.}
				bCR;
			end;
			UpdateANSIInChannel(TheChat.ChannelNumber);
			if not thisUser.Expert then
				DoShowChatMenuORHelp(true);
		end;
	end;

{---------------------------------------------------------------------------------}
{									Clears Text Box in ANSI Chatroom and Clears TheMessage					}

	procedure ClearBox;
		const
			Spaces78 = '                                                                              ';
		var
			ScreenHight: integer;
	begin
		with curGlobs^ do
		begin
			if TheChat.ChatMode = ANSIChat then
			begin
				if thisUser.ScrnHght < 24 then
					ScreenHight := thisUser.ScrnHght
				else
					ScreenHight := 24;
				MoveCursor(ScreenHight - 3, 2, false);
				OutLine(Spaces78, false, 0);
				MoveCursor(ScreenHight - 2, 2, false);
				OutLine(Spaces78, false, 0);
				MoveCursor(ScreenHight - 1, 2, false);
				OutLine(Spaces78, false, 0);
				MoveCursor(ScreenHight - 3, 2, true);
			end;
			TheChat.TheMessage[1] := char(0);
			TheChat.TheMessage[2] := char(0);
			TheChat.TheMessage[3] := char(0);
		end;
	end;

{---------------------------------------------------------------------------------}
{									Clears Receiving Text Box in ANSI Chatroom											}

	procedure ClearANSIRoom;
		const
			Spaces78 = '                                                                              ';
		var
			i, ScreenHight: integer;
	begin
		with curGlobs^ do
		begin
			if thisUser.ScrnHght < 24 then
				ScreenHight := thisUser.ScrnHght
			else
				ScreenHight := 24;
			for i := 2 to ScreenHight - 5 do
			begin
				MoveCursor(i, 2, false);
				OutLine(Spaces78, false, 0);
			end;
			TheChat.OutputPos := 2;
			MoveCursor(0, -1, false);
		end;
	end;

{---------------------------------------------------------------------------------}
{													List Action Words in 5 Columns													}

	procedure ListActionWords;
		const
			kSpaces = '              ';
		var
			i, Adder, count: integer;
			a: array[1..4] of integer;	{adjustor}
			s: str255;
			s14: array[1..5] of string[14];
	begin
		s := char(0);
		a[1] := 0;
		a[2] := 0;
		a[3] := 0;
		a[4] := 0;
		if (ChatHand^^.NumActionWords > 0) then
		begin
			Adder := ChatHand^^.NumActionWords div 5;
			if (Adder * 5 <> ChatHand^^.NumActionWords) then
			begin
				if ChatHand^^.NumActionWords - Adder * 5 >= 1 then
					a[1] := 1;
				if ChatHand^^.NumActionWords - Adder * 5 >= 2 then
					a[2] := 1;
				if ChatHand^^.NumActionWords - Adder * 5 >= 3 then
					a[3] := 1;
				if ChatHand^^.NumActionWords - Adder * 5 >= 4 then
					a[4] := 1;
			end;
		end
		else
			Adder := 0;
		if (Adder > 0) then
		begin
			count := 0;
			for i := 1 to Adder do
			begin
				s14[1] := concat(ActionWordHand^^[count].ActionWord, kSpaces);
				s14[2] := concat(ActionWordHand^^[count + Adder + a[1]].ActionWord, kSpaces);
				s14[3] := concat(ActionWordHand^^[count + (Adder * 2) + a[1] + a[2]].ActionWord, kSpaces);
				s14[4] := concat(ActionWordHand^^[count + (Adder * 3) + a[1] + a[2] + a[3]].ActionWord, kSpaces);
				s14[5] := concat(ActionWordHand^^[count + (Adder * 4) + a[1] + a[2] + a[3] + a[4]].ActionWord, kSpaces);
				s := concat(s14[1], ' ', s14[2], ' ', s14[3], ' ', s14[4], ' ', s14[5]);
				ChatroomSingle(activeNode, false, false, s);
				count := count + 1;
			end;
			if (Adder * 5 <> ChatHand^^.NumActionWords) then
			begin
				s14[1] := char(0);
				s14[2] := char(0);
				s14[3] := char(0);
				s14[4] := char(0);
				if ChatHand^^.NumActionWords - Adder * 5 >= 1 then
					s14[1] := concat(ActionWordHand^^[Adder].ActionWord, kSpaces);
				if ChatHand^^.NumActionWords - Adder * 5 >= 2 then
					s14[2] := concat(ActionWordHand^^[(Adder * 2) + 1].ActionWord, kSpaces);
				if ChatHand^^.NumActionWords - Adder * 5 >= 3 then
					s14[3] := concat(ActionWordHand^^[(Adder * 3) + 2].ActionWord, kSpaces);
				if ChatHand^^.NumActionWords - Adder * 5 >= 4 then
					s14[4] := ActionWordHand^^[(Adder * 4) + 3].ActionWord;
				s := concat(s14[1], ' ', s14[2], ' ', s14[3], ' ', s14[4]);
				ChatroomSingle(activeNode, false, false, s);
			end;
		end
		else if (ChatHand^^.NumActionWords > 0) then
		begin
			for i := 1 to ChatHand^^.NumActionWords do
				s := concat(s, ActionWordHand^^[i - 1].ActionWord, ' ');
			ChatroomSingle(activeNode, false, false, s);
		end;
	end;

{---------------------------------------------------------------------------------}
{											Resets the Private Data Vars for Which Node									}

	procedure ResetPrivateData (Which: integer);
	begin
		theNodes[which]^.TheChat.PrivateData.WhoRequested := 0;
		theNodes[which]^.TheChat.PrivateData.Reason := char(0);
		theNodes[which]^.TheChat.PrivateData.SavedcurPrompt := char(0);
		theNodes[which]^.TheChat.PrivateData.SavedSection := 0;
		theNodes[which]^.TheChat.PrivateData.SavedAction := none;
	end;

end.