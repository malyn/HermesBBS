{ Segments: Chatroom_1 }
unit Chatroom;

interface
	uses
		AppleTalk, ADSP, Serial, Sound, TCPTypes, Initial, LoadAndSave, NodePrefs2, NodePrefs, SystemPrefs2, SystemPrefs, inpOut4, ChatroomUtils;

	function DecipherActionWord (User: str255; TargetNode: integer; TheString: str255; NodeAimedAt: integer): str255;
	procedure WrapActionText (TheText: str255);
	procedure DoChatRoom;
	procedure DoPrivateRequest;
	procedure OpenChatroomSetup;
	procedure UpdateChatroomSetup;
	procedure DoChatroomSetup (theEvent: EventRecord; ItemHit: integer);
	procedure CloseChatroomSetup;
	procedure SortActionWordList;

implementation
	var
		AWList: ListHandle;
		curAWord: integer;

{$S Chatroom_1}
	procedure ChatroomPrompt (Prompt: str255; wrap: boolean);
		var
			t1: str255;
			i: integer;
	begin
		with curglobs^ do
		begin
			with myPrompt do
			begin
				statChanged := true;
				promptLine := Prompt;
				AllowedChars := '';
				AllowedChars := '';
				replaceChar := char(0);
				ansiAllowed := False;
				Capitalize := false;
				enforceNumeric := false;
				autoAccept := false;
				wrapAround := wrap;
				wrapsonCR := true;
				breakChar := char(0);
				HermesColor := 2;
				InputColor := 0;
				numericLow := 77;
				numericHigh := 0;
				maxChars := -4;
				KeyString1 := '';
				KeyString2 := '';
				KeyString3 := '';
				PromptUser(activeNode);
			end;
		end;
	end;

	function DecipherActionWord (User: str255; TargetNode: integer; TheString: str255; NodeAimedAt: integer): str255;
		var
			s, s1: str255;
			i, Start, x, WhichUsersSex, y: integer;
	begin
		s := TheString;
		i := pos('[U]', s);
		if i = 0 then
			i := pos('[u]', s);
		if i <> 0 then
		begin
			Delete(s, i, 3);
			Insert(User, s, i);
		end;
		i := pos('[T]', s);
		if i = 0 then
			i := pos('[t]', s);
		if i <> 0 then
		begin
			Delete(s, i, 3);
			Insert(theNodes[TargetNode]^.thisUser.UserName, s, i);
		end;

		if NodeAimedAt = 999 then
			NodeAimedAt := TargetNode;
		Start := 0;
		for i := 1 to length(s) do
			if s[i] = '[' then
				Start := i
			else if (s[i] = ']') and (Start <> 0) then
				if (i - Start > 3) then
				begin
					s1 := copy(s, Start, i - (Start - 1));

					if (pos('U:', s1) <> 0) or (pos('u:', s1) <> 0) then
					begin
						WhichUsersSex := activeNode;
						Delete(s1, 2, 2);
					end
					else if (pos('T:', s1) <> 0) or (pos('t:', s1) <> 0) then
					begin
						WhichUsersSex := NodeAimedAt;
						Delete(s1, 2, 2);
					end
					else
						WhichUsersSex := TargetNode;

					x := pos('/', s1);
					if x <> 0 then
					begin
						if (theNodes[WhichUsersSex]^.thisUser.Sex) then	{Male}
							s1 := Copy(s1, 2, x - 2)
						else	{Female}
							s1 := Copy(s1, x + 1, length(s1) - (x + 1));
						Delete(s, Start, i - (Start - 1));
						Insert(s1, s, Start);
						i := Start;
						Start := 0;
					end;
				end
				else
					Start := 0;

		DecipherActionWord := s;
	end;

	procedure WrapActionText (TheText: str255);
		var
			i, x: integer;
			s: str255;
	begin
		with curGlobs^ do
		begin
			TheChat.TheMessage[1] := char(0);
			TheChat.TheMessage[2] := char(0);
			TheChat.TheMessage[3] := char(0);
			for x := 1 to 3 do
				if length(TheText) >= 78 then
				begin
					if TheText[78] = char(32) then
					begin
						TheChat.TheMessage[x] := copy(TheText, 1, 78);
						Delete(TheText, 1, 78);
					end
					else
					begin
						for i := 78 downto 40 do
							if TheText[i] = char(32) then
								leave;
						TheChat.TheMessage[x] := copy(TheText, 1, i);
						Delete(TheText, 1, i);
					end;
				end
				else if (length(TheText) > 0) then
				begin
					TheChat.TheMessage[x] := copy(TheText, 1, length(TheText));
					leave;
				end;
		end;
	end;

	procedure DoChatRoom;
		var
			s: str255;
			i, TheFile: integer;
			l: longint;
			b: boolean;
			AW: ActionWordRec;
			result: OSErr;
	begin
		with curGlobs^ do
		begin
			case ChatRoomDo of
				EnterMain: 
				begin
					ChatroomUserSetup(0);	{Setup for channel zero, the main channel}
					TheChat.WhereFrom := InChatroom;
					DrawChatroom;
					ChatroomEnterExit(true);
					if TheChat.ChatMode = ANSIChat then
					begin
						MoveCursor(-2, 0, true);
						ChatRoomDo := ChatAEM1;
					end
					else
						ChatRoomDo := ChatEM1;
				end;
				ChatAEM1: 
				begin
					MoveCursor(-2, 0, true);
					ChatroomPrompt(char(0), true);
					excess := '';
					ChatRoomDo := ChatAEM2;
				end;
				ChatAEM2: 
				begin
					if curPrompt = '' then
					begin
						MoveCursor(-2, 0, true);
						ChatRoomDo := ChatAEM1;
					end
					else if (length(curPrompt) > 0) and (length(excess) = 0) then
					begin
						TheChat.TheMessage[1] := curPrompt;
						ChatRoomDo := ChatCheckPrompt;
					end
					else if (curPrompt[1] = '/') and (length(curPrompt) = 2) then
						ChatRoomDo := ChatCheckPrompt
					else
					begin
						if thisUser.ScrnHght < 24 then
							MoveCursor(thisUser.ScrnHght - 2, 2, true)
						else
							MoveCursor(22, 2, true);

						TheChat.TheMessage[1] := curPrompt;
						ChatroomPrompt(char(0), true);
						if length(excess) > 0 then
						begin
							OutLine(excess, false, 0);
							TheChat.InputPos.h := length(excess) + 2;
						end;
						curPrompt := excess;
						excess := '';
						ChatRoomDo := ChatAEM3;
					end;
				end;
				ChatAEM3: 
				begin
					if (curPrompt = '') then
						ChatRoomDo := ChatCheckPrompt
					else if (length(curPrompt) > 0) and (length(excess) = 0) then
					begin
						TheChat.TheMessage[2] := curPrompt;
						ChatRoomDo := ChatCheckPrompt;
					end
					else if (curPrompt[1] = '/') and (length(curPrompt) = 2) then
						ChatRoomDo := ChatCheckPrompt
					else
					begin
						if thisUser.ScrnHght < 24 then
							MoveCursor(thisUser.ScrnHght - 1, 2, true)
						else
							MoveCursor(23, 2, true);
						TheChat.TheMessage[2] := curPrompt;
						ChatroomPrompt(char(0), false);
						if length(excess) > 0 then
						begin
							OutLine(excess, false, 0);
							TheChat.InputPos.h := length(excess) + 2;
						end;
						curPrompt := excess;
						excess := '';
						ChatRoomDo := ChatAEM4;
					end;
				end;
				ChatAEM4: 
				begin
					if (curPrompt <> '') and not ((curPrompt[1] = '/') and (length(curPrompt) = 2)) then
						TheChat.TheMessage[3] := curPrompt;
					ChatRoomDo := ChatCheckPrompt;
				end;
				ChatEM1: 
				begin
					ChatroomPrompt(RetInStr(763), true);
					excess := '';
					ChatRoomDo := ChatEM2;
				end;
				ChatEM2: 
				begin
					if curPrompt = '' then
						ChatRoomDo := ChatEM1
					else if (length(curPrompt) > 0) and (length(excess) = 0) then
					begin
						TheChat.TheMessage[1] := curPrompt;
						ChatRoomDo := ChatCheckPrompt;
					end
					else if (curPrompt[1] = '/') and (length(curPrompt) = 2) then
						ChatRoomDo := ChatCheckPrompt
					else
					begin
						TheChat.TheMessage[1] := curPrompt;
						ChatroomPrompt(RetInStr(764), true);
						if length(excess) > 0 then
							OutLine(excess, false, 0);
						curPrompt := excess;
						excess := '';
						ChatRoomDo := ChatEM3;
					end;
				end;
				ChatEM3: 
				begin
					if curPrompt = '' then
						ChatRoomDo := ChatCheckPrompt
					else if (length(curPrompt) > 0) and (length(excess) = 0) then
					begin
						TheChat.TheMessage[2] := curPrompt;
						ChatRoomDo := ChatCheckPrompt;
					end
					else if (curPrompt[1] = '/') and (length(curPrompt) = 2) then
						ChatRoomDo := ChatCheckPrompt
					else
					begin
						TheChat.TheMessage[2] := curPrompt;
						ChatroomPrompt(RetInStr(765), false);
						if length(excess) > 0 then
							OutLine(excess, false, 0);
						curPrompt := excess;
						excess := '';
						ChatRoomDo := ChatEM4;
					end;
				end;
				ChatEM4: 
				begin
					if (curPrompt <> '') and not ((curPrompt[1] = '/') and (length(curPrompt) = 2)) then
						TheChat.TheMessage[3] := curPrompt;
					ChatRoomDo := ChatCheckPrompt;
				end;
				ChatCheckPrompt: 
				begin
					if TheChat.ChatMode = ANSIChat then
						ChatRoomDo := ChatAEM1
					else
						ChatRoomDo := ChatEM1;
					if (curPrompt[1] = '/') and (length(curPrompt) = 2) and (TheChat.Status <> SendingMessage) then
					begin
						ClearBox;
						case curPrompt[2] of
							'U', 'u': 
								DoShowUserActivity;
							'B', 'b': 
							begin
								if TheChat.BlockWho > -1 then
								begin
									TheChat.BlockWho := -1;
									ChatRoomSingle(activeNode, false, false, RetInStr(766));
								end
								else
								begin
									TheChat.InputPos.h := length(RetInStr(767)) + 2;
									LettersPrompt(RetInStr(767), '', 31, false, false, false, char(0));
									ChatRoomDo := ChatBlockWho;
								end;
							end;
							'?': 
								DoShowChatMenuORHelp(true);
							'R', 'r': 
							begin
								TheChat.OutputPos := 2;
								DrawChatRoom;
							end;
							'L', 'l': 
								ListActionWords;
							'-': 
							begin
								ScrollBackNForward(true);
								if TheChat.Scrolling then
									ChatroomDo := ChatScroll;
							end;
							'Q', 'q': 
							begin
								ChatroomEnterExit(false);
								if (Chathand^^.Channels[TheChat.ChannelNumber].NumInChannel <= 0) and (TheChat.ChannelNumber > 0) then
									DisposeChatroom(TheChat.ChannelNumber);
								if TheChat.ChatMode = ANSIChat then
									MoveCursor(ThisUser.ScrnHght, 1, false);
								bCR;
								bCR;
								bCR;
								if TheChat.WhereFrom = Somewhere then
								begin
									TheChat.WhereFrom := NoWhere;
									BoardSection := Logon;
									while ord(BoardSection) <> TheChat.PrivateData.SavedSection do
										BoardSection := succ(BoardSection);
									BoardAction := TheChat.PrivateData.SavedAction;
									if BoardSection = MainMenu then
									begin
										BoardAction := none;
										MainStage := MenuText;
										ResetPrivateData(activeNode);
										TheChat.ChannelNumber := -1;
									end
									else
									begin
										if BoardAction = Prompt then
										begin
											myPrompt := TheChat.PrivateData.SavedPrompt;
											if TheChat.PrivateData.SavedcurPrompt <> char(0) then
												curPrompt := TheChat.PrivateData.SavedcurPrompt;
											ReprintPrompt;
										end
										else if BoardAction = Writing then
											ListLine(online);
										ResetPrivateData(activeNode);
										TheChat.ChannelNumber := -1;
									end;
								end
								else if (TheChat.ChannelNumber <> 0) and (TheChat.WhereFrom = InChatroom) then
									ChatroomDo := EnterMain
								else
								begin
									TheChat.ChannelNumber := -1;
									TheChat.WhereFrom := NoWhere;
									GoHome;
								end
							end;
							'P', 'p': 
							begin
								TheChat.InputPos.h := length(RetInStr(768)) + 2;
								LettersPrompt(RetInStr(768), '', 31, false, false, false, char(0));
								ChatRoomDo := ChatPrivate1;
							end;
							'T', 't': 
							begin
								if TheChat.ChatMode = ANSIChat then
								begin
									TheChat.ChatMode := TextChat;
									ChatRoomDo := ChatEM1;
								end
								else
								begin
									TheChat.ChatMode := ANSIChat;
									ChatRoomDo := ChatAEM1;
									TheChat.OutputPos := 2;
									TheChat.InputPos.h := 1;
									if thisUser.ScrnHght < 24 then
										TheChat.InputPos.v := thisUser.ScrnHght - 3
									else
										TheChat.InputPos.v := 21;
								end;
								DrawChatRoom;
							end;
							'M', 'm': 
							begin
								TheChat.InputPos.h := length(RetInStr(769)) + 2;
								LettersPrompt(RetInStr(769), '', 31, false, false, false, char(0));
								ChatRoomDo := ChatSendTo;
							end;
							'S', 's': 
							begin
								if triedChat then
								begin
									triedChat := false;
									ChatRoomSingle(activeNode, false, false, RetInStr(88));
								end
								else
									ChatRoomDo := ChatSysop1;
							end;
							otherwise
							begin
								ChatRoomSingle(activeNode, false, false, RetInStr(770));
							end;
						end;
					end
					else if (curPrompt[1] = '/') and ((curPrompt[2] = 'A') or (curPrompt[2] = 'a')) and ((curPrompt[3] = '/') or (curPrompt[3] = ' ')) and (TheChat.Status <> SendingMessage) then
					begin
						TheChat.Status := ActionWord;
						Delete(curPrompt, 1, 3);
						if (length(curPrompt) > 0) then
						begin
							if (pos('/', curPrompt) > 0) then
							begin
								s := Copy(curPrompt, pos('/', curPrompt) + 1, length(curPrompt) - pos('/', curPrompt));
								TheChat.ToNode := GetNodeNumber(s);
								if (TheChat.ToNode <> 0) then
									if (theNodes[TheChat.ToNode]^.boardMode = User) and (theNodes[TheChat.ToNode]^.thisUser.userNum > 0) then
										if (theNodes[TheChat.ToNode]^.TheChat.ChannelNumber <> TheChat.ChannelNumber) or (theNodes[TheChat.ToNode]^.BoardSection <> ChatRoom) then
											TheChat.ToNode := 0;
								Delete(curPrompt, pos('/', curPrompt), length(curPrompt) - (pos('/', curPrompt) - 1));
							end
							else if (pos(' ', curPrompt) > 0) then
							begin
								s := Copy(curPrompt, pos(' ', curPrompt) + 1, length(curPrompt) - pos(' ', curPrompt));
								TheChat.ToNode := GetNodeNumber(s);
								if (TheChat.ToNode <> 0) then
									if (theNodes[TheChat.ToNode]^.boardMode = User) and (theNodes[TheChat.ToNode]^.thisUser.userNum > 0) then
										if (theNodes[TheChat.ToNode]^.TheChat.ChannelNumber <> TheChat.ChannelNumber) or (theNodes[TheChat.ToNode]^.BoardSection <> ChatRoom) then
											TheChat.ToNode := 0;
								Delete(curPrompt, pos(' ', curPrompt), length(curPrompt) - (pos(' ', curPrompt) - 1));
							end
							else
								TheChat.ToNode := 999;
							if (TheChat.ToNode <> 0) then {and ((theNodes[TheChat.ToNode]^.boardMode = User) and (theNodes[TheChat.ToNode]^.thisUser.userNum > 0) and (TheChat.ToNode <> activeNode))}
							begin
								AW.ActionWord := 'NOACTIONWORD';
								UprString(curPrompt, true);
								for i := 0 to ChatHand^^.NumActionWords do
									if ActionWordHand^^[i].ActionWord = curPrompt then
									begin
										l := SizeOf(ActionWordRec);
										result := FSOpen(concat(sharedPath, 'Shared Files:Action Words'), 0, TheFile);
										result := SetFPos(TheFile, fsFromStart, ActionWordHand^^[i].Offset);
										result := FSRead(TheFile, l, @AW);
										result := FSClose(TheFile);
										leave;
									end;
								if AW.ActionWord <> 'NOACTIONWORD' then
								begin
									for i := 1 to InitSystHand^^.NumNodes do
									begin
										if (theNodes[i]^.BoardMode = User) and (theNodes[i]^.BoardSection = ChatRoom) and (theNodes[i]^.TheChat.ChannelNumber = TheChat.ChannelNumber) then
										begin
											if (i = activeNode) and (TheChat.ToNode <> 999) then
												s := DecipherActionWord(thisUser.UserName, TheChat.ToNode, AW.Initiating, TheChat.ToNode)
											else if (i = TheChat.ToNode) and (TheChat.ToNode <> 999) then
												s := DecipherActionWord(thisUser.UserName, i, AW.TargetUser, TheChat.ToNode)
											else if (TheChat.ToNode = 999) then
												s := DecipherActionWord(thisUser.UserName, activeNode, AW.Unspecified, TheChat.ToNode)
											else
												s := DecipherActionWord(thisUser.UserName, TheChat.ToNode, AW.OtherUser, TheChat.ToNode);
											if length(s) > 78 then
											begin
												WrapActionText(s);
												ChatroomSingle(i, false, false, char(0));
											end
											else
												ChatroomSingle(i, false, false, s);
										end;
									end;
								end
								else
									ChatRoomSingle(activeNode, false, false, RetInStr(771));
							end
							else if (TheChat.ToNode = activeNode) then
								ChatroomSingle(activeNode, false, false, RetInStr(432))	{You cannot send a message to yourself.}
							else
								ChatRoomSingle(activeNode, false, false, RetInStr(772));
						end
						else
							ChatRoomSingle(activeNode, false, false, RetInStr(770));
						ClearBox;
						TheChat.Status := Chatting;
					end
					else if (TheChat.Status = SendingMessage) then
					begin
						if ((curPrompt = '/Q') or (curPrompt = '/q')) then
						begin
							ClearBox;
							if TheChat.ToNode = 999 then
								ChatRoomSingle(activeNode, false, false, RetInStr(773))
							else
								ChatRoomSingle(activeNode, false, false, RetInStr(774));
							TheChat.Status := Chatting;
						end
						else
						begin
							TheChat.Status := Chatting;
							if TheChat.ToNode <> 999 then
								ChatRoomSingle(TheChat.ToNode, true, true, char(0))
							else
							begin
								for i := 1 to InitSystHand^^.NumNodes do
									if (theNodes[i]^.boardMode = User) and (theNodes[i]^.thisUser.userNum > 0) and (i <> activeNode) then
										ChatRoomSingle(i, true, true, char(0))
							end;
							ClearBox;
						end;
					end
					else
					begin
						ChatroomBroadcast(true, true);
						ClearBox;
					end;
				end;
				ChatSendTo: 
				begin
					if TheChat.ChatMode = ANSIChat then
						ChatRoomDo := ChatAEM1
					else
						ChatRoomDo := ChatEM1;
					ClearBox;
					if curPrompt <> '' then
					begin
						if curPrompt = '*' then
							l := 999
						else
							l := GetNodeNumber(curPrompt);

						b := true;
						if (l = 999) then
							s := RetInStr(775)
						else if (l <> 0) then
						begin
							s := StringOf(theNodes[l]^.thisUser.UserName, ' #', theNodes[l]^.thisUser.UserNum : 0);
							if (theNodes[l]^.TheChat.BlockWho = ThisUser.UserNum) then
							begin
								b := false;
								s := concat(s, RetInStr(776));
							end
							else if (theNodes[l]^.TheChat.BlockWho = 0) then
							begin
								b := false;
								s := concat(s, RetInStr(777));
							end;
						end;

						if (l <> 0) and (l <> 999) and b then
						begin
							if (theNodes[l]^.boardMode = User) and (theNodes[l]^.thisUser.userNum > 0) and (l <> activeNode) then
							begin
								TheChat.ToNode := l;
								TheChat.Status := SendingMessage;
								ChatRoomSingle(activeNode, false, false, concat(RetInStr(778), s, RetInStr(779)));
							end
							else if l = activeNode then
							begin
								ChatRoomSingle(activeNode, false, false, RetInStr(432));	{You cannot send a message to yourself.}
							end
							else
							begin
								ChatRoomSingle(activeNode, false, false, RetInStr(430));	{That is an inactive node.}
							end;
						end
						else if l = 999 then
						begin
							TheChat.ToNode := l;
							TheChat.Status := SendingMessage;
							ChatRoomSingle(activeNode, false, false, concat(RetInStr(778), s, RetInStr(779)));
						end
						else if not b then
							ChatRoomSingle(activeNode, false, false, s)
						else
							ChatRoomSingle(activeNode, false, false, RetInStr(772));
					end;
				end;
				ChatSysop1: 
				begin
					if (SysopAvailable and not ThisUser.CantChat) or ((menuHand^^.Options[pos('S', menuCmds), 1]) and (MenuHand^^.SecLevel2[pos('S', menuCmds)] <= thisUser.SL)) then
					begin
						TheChat.InputPos.h := length(RetInStr(85)) + 17 + 2;
						LettersPrompt(concat(RetInStr(780), RetInStr(85)), '', 30, false, false, false, char(0));
						ChatRoomDo := ChatSysop2;
					end
					else
					begin
						sysopLog(RetInStr(305), 0);	{      Tried Chatting.}
						ChatRoomSingle(activeNode, false, false, RetInStr(86));
						ChatRoomSingle(activeNode, false, false, RetInStr(87));
						curPrompt := '1';
						reply := false;
						if FindUser(curPrompt, tempuser) then
						begin
							ClearBox;
							TheChat.InputPos.h := length(concat(RetInStr(781), tempUser.UserName, RetInStr(782))) + 2;
							YesNoQuestion(concat(RetInStr(781), tempUser.UserName, RetInStr(782)), false);
						end;
						ChatRoomDo := ChatSysop3;
					end;
				end;
				ChatSysop2: 
				begin
					if length(curPrompt) > 0 then
					begin
						s := concat(RetInStr(306), CurPrompt);	{      Chat: }
						sysopLog(s, 0);
						ChatRoomSingle(activeNode, false, false, RetInStr(89));
						triedChat := true;
						chatReason := CurPrompt;
						NumToString(activeNode, s);
						s := concat('Chat ', s);
						if GetNamedResource('snd ', s) <> nil then
							StartMySound(s, false)
						else
							for i := 1 to 4 do
								SysBeep(1);
						ChatRoomSingle(activeNode, false, false, RetInStr(90));
					end;
					ClearBox;
					if TheChat.ChatMode = ANSIChat then
						ChatRoomDo := ChatAEM1
					else
						ChatRoomDo := ChatEM1;
				end;
				ChatSysop3: 
				begin
					if curPrompt = 'Y' then
					begin
						ClearScreen;
						CurPrompt := '1';
						BoardSection := EMail;
						EmailDo := EmailOne;
					end
					else
					begin
						ClearBox;
						if TheChat.ChatMode = ANSIChat then
							ChatRoomDo := ChatAEM1
						else
							ChatRoomDo := ChatEM1;
					end;
				end;
				ChatBlockWho: 
				begin
					if TheChat.ChatMode = ANSIChat then
						ChatRoomDo := ChatAEM1
					else
						ChatRoomDo := ChatEM1;
					ClearBox;
					if curPrompt <> '' then
					begin
						if curPrompt = '*' then
							l := -999
						else
							l := GetNodeNumber(curPrompt);

						if (l = -999) then
							s := RetInStr(775)
						else
							s := StringOf(theNodes[l]^.thisUser.UserName, ' #', theNodes[l]^.thisUser.UserNum : 0);

						if (l > 0) then
						begin
							if (theNodes[l]^.boardMode = User) and (theNodes[l]^.thisUser.userNum > 0) and (l <> activeNode) then
							begin
								TheChat.BlockWho := theNodes[l]^.thisUser.UserNum;
								ChatRoomSingle(activeNode, false, false, concat(RetInStr(783), s));
							end
							else if l = activeNode then
							begin
								ChatRoomSingle(activeNode, false, false, RetInStr(784));	{You cannot send a message to yourself.}
							end
							else
							begin
								ChatRoomSingle(activeNode, false, false, RetInStr(430));	{That is an inactive node.}
							end;
						end
						else if l = -999 then
						begin
							TheChat.BlockWho := 0;
							ChatRoomSingle(activeNode, false, false, concat(RetInStr(783), s));
						end
						else
							ChatRoomSingle(activeNode, false, false, RetInStr(772));
					end
					else
					begin
						TheChat.BlockWho := -1;
						ChatRoomSingle(activeNode, false, false, RetInStr(766));
					end;
				end;
				ChatScroll: 
				begin
					ClearBox;
					TheChat.InputPos.h := length(RetInStr(785)) + 2;
					LettersPrompt(RetInStr(785), 'BFH', 1, true, false, true, char(0));
					ChatRoomDo := ChatScrollCheckP;
				end;
				ChatScrollCheckP: 
				begin
					ChatroomDo := ChatScroll;
					if (curPrompt = '') or (curPrompt = 'H') then
					begin
						ScrollHome;
						ClearBox;
						if TheChat.ChatMode = ANSIChat then
							ChatRoomDo := ChatAEM1
						else
							ChatRoomDo := ChatEM1;
					end
					else if curPrompt = 'F' then
					begin
						ScrollBackNForward(false);
						if not TheChat.Scrolling then
						begin
							ClearBox;
							if TheChat.ChatMode = ANSIChat then
								ChatRoomDo := ChatAEM1
							else
								ChatRoomDo := ChatEM1;
						end;
					end
					else if curPrompt = 'B' then
						ScrollBackNForward(true);
				end;
				ChatPrivate1: 
				begin
					ClearBox;
					if TheChat.ChatMode = ANSIChat then
						ChatRoomDo := ChatAEM1
					else
						ChatRoomDo := ChatEM1;
					if curPrompt <> '' then
					begin
						l := GetNodeNumber(curPrompt);
						if (l <> 0) and ((theNodes[l]^.TheChat.BlockWho <> ThisUser.UserNum) and (theNodes[l]^.TheChat.BlockWho <> 0)) and (theNodes[l]^.BoardSection <> PrivateRequest) and (l <> activeNode) then
						begin
							TheChat.PrivateRequest := l;
							TheChat.InputPos.h := length(RetInStr(786)) + 2;
							LettersPrompt(RetInStr(786), '', 78 - length(RetInStr(786)), false, false, false, char(0));
							ChatRoomDo := ChatPrivate2;
						end
						else if (l = activeNode) then
							ChatroomSingle(activeNode, false, false, RetInStr(787))
						else if (theNodes[l]^.BoardSection = PrivateRequest) then
							ChatroomSingle(activeNode, false, false, RetInStr(788))
						else if (theNodes[l]^.TheChat.BlockWho = ThisUser.UserNum) or (theNodes[l]^.TheChat.BlockWho = 0) then
							ChatroomSingle(activeNode, false, false, RetInStr(789))
						else
						begin
							ChatroomSingle(activeNode, false, false, RetInStr(772));
						end;
					end
					else
						ChatroomSingle(activeNode, false, false, RetInStr(790));
				end;
				ChatPrivate2: 
				begin
					ClearBox;
					if TheChat.ChatMode = ANSIChat then
						ChatRoomDo := ChatAEM1
					else
						ChatRoomDo := ChatEM1;
					if curPrompt <> '' then
					begin
						if (theNodes[TheChat.PrivateRequest]^.BoardMode = User) and not (theNodes[TheChat.PrivateRequest]^.mytrans.active) then
						begin
							theNodes[TheChat.PrivateRequest]^.TheChat.PrivateData.WhoRequested := activeNode;
							theNodes[TheChat.PrivateRequest]^.TheChat.PrivateData.Reason := curPrompt;
							if theNodes[TheChat.PrivateRequest]^.TheChat.WhereFrom <> Somewhere then
							begin
								if theNodes[TheChat.PrivateRequest]^.BoardAction = Prompt then
								begin
									theNodes[TheChat.PrivateRequest]^.TheChat.PrivateData.SavedPrompt := theNodes[TheChat.PrivateRequest]^.myPrompt;
									theNodes[TheChat.PrivateRequest]^.TheChat.PrivateData.SavedcurPrompt := theNodes[TheChat.PrivateRequest]^.curPrompt;
								end
								else
									theNodes[TheChat.PrivateRequest]^.TheChat.PrivateData.SavedcurPrompt := char(0);
								theNodes[TheChat.PrivateRequest]^.TheChat.PrivateData.SavedSection := ord(theNodes[TheChat.PrivateRequest]^.BoardSection);
								theNodes[TheChat.PrivateRequest]^.TheChat.PrivateData.SavedAction := theNodes[TheChat.PrivateRequest]^.BoardAction;
							end
							else
								theNodes[TheChat.PrivateRequest]^.TheChat.WhereFrom := AlreadyIn;
							theNodes[TheChat.PrivateRequest]^.BoardSection := PrivateRequest;
							theNodes[TheChat.PrivateRequest]^.PrivateDo := PR1;
							theNodes[TheChat.PrivateRequest]^.BoardAction := None;
							ChatroomSingle(activeNode, false, false, RetInStr(791));
						end
						else
							ChatroomSingle(activeNode, false, false, RetInStr(789));
					end
					else
						ChatroomSingle(activeNode, false, false, RetInStr(790));
				end;
				otherwise
			end;
		end;
	end;

	procedure DoPrivateRequest;
		const
			Spaces78 = '                                                                              ';
		var
			ScreenHight, savedNode, i: integer;
			DelayedEnter: boolean;
	begin
		with curGlobs^ do
		begin
			case PrivateDo of
				PR1: 
				begin
					PrivateDo := PR2;
					if (TheChat.PrivateData.SavedSection = 50) or (TheChat.WhereFrom = AlreadyIn) then
					begin
						ChatroomSingle(activeNode, false, false, StringOf(theNodes[TheChat.PrivateData.WhoRequested]^.thisUser.UserName, ' #', theNodes[TheChat.PrivateData.WhoRequested]^.thisUser.UserNum : 0, ' requests a private chat with you.'));
						ChatroomSingle(activeNode, false, false, concat(RetInStr(786), TheChat.PrivateData.Reason));
						if (TheChat.ChatMode = ANSIChat) then
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
						end
						else
							BackSpace(length(myPrompt.promptLine) + length(curPrompt));

						TheChat.InputPos.h := length(RetInStr(792)) + 2;
						YesNoQuestion(RetInStr(792), false);
					end
					else
					begin
						bCR;
						OutLine(StringOf(theNodes[TheChat.PrivateData.WhoRequested]^.thisUser.UserName, ' #', theNodes[TheChat.PrivateData.WhoRequested]^.thisUser.UserNum : 0, ' requests a private chat with you.'), true, 5);
						OutLine(concat(RetInStr(786), TheChat.PrivateData.Reason), true, 1);
						bCR;
						YesNoQuestion(RetInStr(792), false);
					end;
				end;
				PR2: 
				begin
					if (curPrompt = 'N') then
					begin
						TheChat.ToNode := -1;	{So we don't get the Message Sent to xxxx string}
						ChatroomSingle(TheChat.PrivateData.WhoRequested, false, true, StringOf(thisUser.UserName, ' #', thisUser.UserNum : 0, ' declines the private chat invitation.'));
						if TheChat.WhereFrom = AlreadyIn then
						begin
							ClearBox;
							BoardSection := Chatroom;
							if TheChat.ChatMode = ANSIChat then
							begin
								MoveCursor(-2, 0, true);
								ChatRoomDo := ChatAEM1;
							end
							else
								ChatRoomDo := ChatEM1;
							TheChat.WhereFrom := Somewhere;
						end
						else
						begin
							BoardSection := Logon;
							while ord(BoardSection) <> TheChat.PrivateData.SavedSection do
								BoardSection := succ(BoardSection);
							BoardAction := TheChat.PrivateData.SavedAction;
							if BoardSection = Chatroom then
							begin
								ClearBox;
								if TheChat.ChatMode = ANSIChat then
								begin
									MoveCursor(-2, 0, true);
									ChatRoomDo := ChatAEM1;
								end
								else
									ChatRoomDo := ChatEM1;
							end
							else if BoardSection = MainMenu then
							begin
								BoardAction := none;
								MainStage := MenuText;
								TheChat.WhereFrom := Nowhere;
							end
							else
							begin
								bCR;
								if BoardAction = Prompt then
								begin
									myPrompt := TheChat.PrivateData.SavedPrompt;
									if TheChat.PrivateData.SavedcurPrompt <> char(0) then
										curPrompt := TheChat.PrivateData.SavedcurPrompt;
									ReprintPrompt;
								end
								else if BoardAction = Writing then
									ListLine(online);
								TheChat.WhereFrom := Nowhere;
							end;
							ResetPrivateData(activeNode);
						end;
					end
					else
					begin
						if TheChat.ChatMode = ANSIChat then
						begin
							MoveCursor(-2, 0, true);
							ChatRoomDo := ChatAEM1;
						end
						else
							ChatRoomDo := ChatEM1;

						{This is going to be long and redundant just so it's simple to keep straight}
						if (theNodes[TheChat.PrivateData.WhoRequested]^.BoardSection <> Chatroom) then
						begin
							ChatroomSingle(activeNode, false, false, '');
							ChatroomSingle(activeNode, false, false, '');
							ChatroomSingle(activeNode, false, true, RetInStr(793));
							if TheChat.WhereFrom = AlreadyIn then
							begin
								ClearBox;
								BoardSection := Chatroom;
								if TheChat.ChatMode = ANSIChat then
								begin
									MoveCursor(-2, 0, true);
									ChatRoomDo := ChatAEM1;
								end
								else
									ChatRoomDo := ChatEM1;
								TheChat.WhereFrom := Somewhere;
							end
							else
							begin
								BoardSection := Logon;
								while ord(BoardSection) <> TheChat.PrivateData.SavedSection do
									BoardSection := succ(BoardSection);
								BoardAction := TheChat.PrivateData.SavedAction;
								if BoardSection = Chatroom then
								begin
									ClearBox;
									if TheChat.ChatMode = ANSIChat then
									begin
										MoveCursor(-2, 0, true);
										ChatRoomDo := ChatAEM1;
									end
									else
										ChatRoomDo := ChatEM1;
								end
								else if BoardSection = MainMenu then
								begin
									BoardAction := none;
									MainStage := MenuText;
									TheChat.WhereFrom := Nowhere;
								end
								else
								begin
									bCR;
									if BoardAction = Prompt then
									begin
										myPrompt := TheChat.PrivateData.SavedPrompt;
										if TheChat.PrivateData.SavedcurPrompt <> char(0) then
											curPrompt := TheChat.PrivateData.SavedcurPrompt;
										ReprintPrompt;
									end
									else if BoardAction = Writing then
										ListLine(online);
									TheChat.WhereFrom := Nowhere;
								end;
								ResetPrivateData(activeNode);
							end;
						end
						else
						begin
							if TheChat.WhereFrom = AlreadyIn then
								TheChat.WhereFrom := Somewhere;
							if (theNodes[TheChat.PrivateData.WhoRequested]^.TheChat.ChannelNumber = 0) and (TheChat.WhereFrom = NoWhere) then
							begin
							{User Requesting is in Main Chatroom and User Answering is not in any chatroom}
							{Create new chatroom and put both in it}

								{Answering User}
								DelayedEnter := true;
								ChatroomUserSetUp(-1);
								TheChat.WhereFrom := Somewhere;
								BoardSection := Chatroom;
								DrawChatroom;

								{Requesting User}
								i := TheChat.PrivateData.WhoRequested;
								curGlobs := theNodes[i];
								savedNode := activeNode;
								activeNode := i;
								with curglobs^ do
								begin
									BoardAction := none;
									ChatroomUserSetup(theNodes[savedNode]^.TheChat.ChannelNumber);
									DrawChatroom;
									ChatroomEnterExit(true);
									if TheChat.ChatMode = ANSIChat then
									begin
										MoveCursor(-2, 0, true);
										ChatRoomDo := ChatAEM1;
									end
									else
										ChatRoomDo := ChatEM1;
								end;
								curGlobs := theNodes[savedNode];
								activeNode := savedNode;
							end
							else if (theNodes[TheChat.PrivateData.WhoRequested]^.TheChat.ChannelNumber > 0) and (TheChat.WhereFrom = NoWhere) then
							begin
							{User Requesting is in a Private Chatroom and User Answering is not in any chatroom}
							{Add user answering to Private Chatroom}

								{Answering User}
								DelayedEnter := true;
								ChatroomUserSetUp(theNodes[TheChat.PrivateData.WhoRequested]^.TheChat.ChannelNumber);
								TheChat.WhereFrom := Somewhere;
								BoardSection := Chatroom;
								DrawChatroom;
							end
							else if (theNodes[TheChat.PrivateData.WhoRequested]^.TheChat.ChannelNumber = 0) and (TheChat.WhereFrom = InChatroom) and (TheChat.ChannelNumber = 0) then
							begin
							{User Requesting is in Main Chatroom and User Answering is in Main Chatroom}
							{Put both users in a Private Chatroom}

								{Answering User}
								DelayedEnter := true;
								ChatroomUserSetUp(-1);
								BoardSection := Chatroom;
								DrawChatroom;

								{Requesting User}
								i := TheChat.PrivateData.WhoRequested;
								curGlobs := theNodes[i];
								savedNode := activeNode;
								activeNode := i;
								with curglobs^ do
								begin
									BoardAction := none;
									ChatroomUserSetup(theNodes[savedNode]^.TheChat.ChannelNumber);
									DrawChatroom;
									ChatroomEnterExit(true);
									if TheChat.ChatMode = ANSIChat then
									begin
										MoveCursor(-2, 0, true);
										ChatRoomDo := ChatAEM1;
									end
									else
										ChatRoomDo := ChatEM1;
								end;
								curGlobs := theNodes[savedNode];
								activeNode := savedNode;
							end
							else if (theNodes[TheChat.PrivateData.WhoRequested]^.TheChat.ChannelNumber = 0) and (theNodes[TheChat.PrivateData.WhoRequested]^.TheChat.WhereFrom = InChatroom) and (TheChat.ChannelNumber > 0) and (TheChat.WhereFrom <> NoWhere) then
							begin
							{User Requesting is in Main Chatroom and User Answering is in Private Chatroom}
							{Add Requesting user to Private Chatroom}

								{Answering User}
								BoardSection := Chatroom;

								{Requesting User}
								i := TheChat.PrivateData.WhoRequested;
								curGlobs := theNodes[i];
								savedNode := activeNode;
								activeNode := i;
								with curglobs^ do
								begin
									ChatroomEnterExit(false);
									BoardAction := none;
									ChatroomUserSetup(theNodes[savedNode]^.TheChat.ChannelNumber);
									DrawChatroom;
									ChatroomEnterExit(true);
									if TheChat.ChatMode = ANSIChat then
									begin
										MoveCursor(-2, 0, true);
										ChatRoomDo := ChatAEM1;
									end
									else
										ChatRoomDo := ChatEM1;
								end;
								curGlobs := theNodes[savedNode];
								activeNode := savedNode;
							end
							else if (theNodes[TheChat.PrivateData.WhoRequested]^.TheChat.ChannelNumber > 0) and (TheChat.WhereFrom = InChatroom) and (TheChat.ChannelNumber = 0) then
							begin
							{User Requesting is in Private Chatroom and User Answering is in Main Chatroom}
							{Add answering user to Private Chatroom}

								{Answering User}
								ChatroomEnterExit(false);
								DelayedEnter := true;
								ChatroomUserSetUp(theNodes[TheChat.PrivateData.WhoRequested]^.TheChat.ChannelNumber);
								BoardSection := Chatroom;
								DrawChatroom;
							end
							else if (theNodes[TheChat.PrivateData.WhoRequested]^.TheChat.ChannelNumber > 0) and (TheChat.WhereFrom <> NoWhere) and (TheChat.ChannelNumber > 0) and (theNodes[TheChat.PrivateData.WhoRequested]^.TheChat.ChannelNumber <> TheChat.ChannelNumber) then
							begin
							{User Requesting is in a Private Chatroom and User Answering is in another Private Chatroom}
							{Remove Answering User from Private Chatroom and and Add to Requesting User's chatroom}

								{Answering User}
								ChatroomEnterExit(false);
								DelayedEnter := true;
								ChatroomUserSetUp(theNodes[TheChat.PrivateData.WhoRequested]^.TheChat.ChannelNumber);
								BoardSection := Chatroom;
								DrawChatroom;
							end
							else if (theNodes[TheChat.PrivateData.WhoRequested]^.TheChat.ChannelNumber = TheChat.ChannelNumber) and (TheChat.WhereFrom <> NoWhere) then
							begin
							{User Requesting is in the same Private Chatroom as User Answering}
							{Remove Both Users from Private chatroom and Create and Add both to new Private Chatroom}

								{Answering}
								ChatroomEnterExit(false);
								DelayedEnter := true;
								ChatroomUserSetUp(-1);
								BoardSection := Chatroom;
								DrawChatroom;

								{Requesting User}
								i := TheChat.PrivateData.WhoRequested;
								curGlobs := theNodes[i];
								savedNode := activeNode;
								activeNode := i;
								with curglobs^ do
								begin
									ChatroomEnterExit(false);
									BoardAction := none;
									ChatroomUserSetup(theNodes[savedNode]^.TheChat.ChannelNumber);
									DrawChatroom;
									ChatroomEnterExit(true);
									if TheChat.ChatMode = ANSIChat then
									begin
										MoveCursor(-2, 0, true);
										ChatRoomDo := ChatAEM1;
									end
									else
										ChatRoomDo := ChatEM1;
								end;
								curGlobs := theNodes[savedNode];
								activeNode := savedNode;
							end;

							if DelayedEnter then
								ChatroomEnterExit(true);
						end;
					end;
				end;

				otherwise
			end;
		end;
	end;

	procedure FillActionWordData;
		var
			SizeOfAW: longint;
			TheFile: integer;
			result: OSErr;
			AW: ActionWordRec;
	begin
		if ChatroomDlg <> nil then
		begin
			SizeOfAW := SizeOf(ActionWordRec);
			result := FSOpen(concat(sharedPath, 'Shared Files:Action Words'), 0, TheFile);
			result := SetFPos(TheFile, fsFromStart, ActionWordHand^^[curAWord].Offset);
			result := FSRead(TheFile, SizeOfAW, @AW);
			result := FSClose(TheFile);
			SetTextBox(ChatroomDlg, 6, AW.ActionWord);
			SetTextBox(ChatroomDlg, 7, AW.TargetUser);
			SetTextBox(ChatroomDlg, 8, AW.OtherUser);
			SetTextBox(ChatroomDlg, 9, AW.Initiating);
			SetTextBox(ChatroomDlg, 10, AW.Unspecified);
			SelIText(ChatroomDlg, 6, 0, 32767);
		end;
	end;

	procedure OpenChatroomSetup;
		var
			ItemType, i: integer;
			ItemHandle: handle;
			ItemRect, tempRect: rect;
			cSize: cell;
	begin
		if ChatroomDlg = nil then
		begin
			ChatroomDlg := GetNewDialog(265, nil, pointer(-1));
			SetPort(ChatroomDlg);
			SetGeneva(ChatroomDlg);

			(* Set up Action Word List *)
			GetDItem(ChatroomDlg, 5, ItemType, ItemHandle, ItemRect);
			ItemRect.right := ItemRect.right - 15;
			InsetRect(ItemRect, -1, -1);
			FrameRect(ItemRect);
			InsetRect(ItemRect, 1, 1);
			SetRect(tempRect, 0, 0, 1, 0);
			cSize.h := ItemRect.right - ItemRect.left;
			cSize.v := 15;
			AWList := LNew(ItemRect, tempRect, cSize, 0, ChatroomDlg, TRUE, FALSE, FALSE, TRUE);
			AWList^^.selFlags := lOnlyOne + lNoNilHilite;
			if ChatHand^^.NumActionWords > 0 then
			begin
				for i := 1 to ChatHand^^.NumActionWords do
					AddListString(ActionWordHand^^[i - 1].ActionWord, AWList);
				cSize.v := 0;
				cSize.h := 0;
				LSetSelect(True, cSize, AWList);
				curAWord := 0;
				FillActionWordData;
			end
			else
				curAWord := -1;

			ShowWindow(ChatroomDlg);
		end
		else
			SelectWindow(ChatroomDlg);
	end;

	procedure UpdateChatroomSetup;
		var
			SavedPort: GrafPtr;
			ItemType: integer;
			ItemHandle: handle;
			ItemRect: rect;
	begin
		if ChatroomDlg <> nil then
		begin
			GetPort(SavedPort);
			SetPort(ChatroomDlg);
			DrawDialog(ChatroomDlg);

			(* Update AWList *)
			GetDItem(ChatroomDlg, 5, ItemType, ItemHandle, ItemRect);
			ItemRect.Right := ItemRect.Right - 15;
			InsetRect(ItemRect, -1, -1);
			FrameRect(ItemRect);
			if (AWList <> nil) then
				LUpdate(AWList^^.port^.visRgn, AWList);
			SetPort(SavedPort);
		end;
	end;

	procedure DoChatroomSetup (theEvent: EventRecord; ItemHit: integer);
		var
			ItemType: integer;
			ItemHandle: handle;
			ItemRect: rect;
			cSize: cell;
			myPt: point;
			AW: ActionWordRec;
			s: str255;
	begin
		if (ChatroomDlg <> nil) and (ChatroomDlg = FrontWindow) then
		begin
			SetPort(ChatroomDlg);
			cSize.h := 0;
			cSize.v := 0;
			myPt := theEvent.where;
			GlobalToLocal(myPt);
			case ItemHit of
				1:	{OK}
					CloseChatroomSetUp;
				2:	{Add}
				begin
					AW.ActionWord := GetTextBox(ChatroomDlg, 6);
					AW.TargetUser := GetTextBox(ChatroomDlg, 7);
					AW.OtherUser := GetTextBox(ChatroomDlg, 8);
					AW.Initiating := GetTextBox(ChatroomDlg, 9);
					AW.Unspecified := GetTextBox(ChatroomDlg, 10);
					if (length(AW.ActionWord) > 0) and (length(AW.TargetUser) > 0) and (length(AW.OtherUser) > 0) and (length(AW.Initiating) > 0) and (length(AW.Unspecified) > 0) then
					begin
						s := AW.ActionWord;
						UprString(s, true);
						AW.ActionWord := s;
						SaveRemoveActionWord(true, AW, -1);
						cSize.v := curAWord;
						cSize.h := 0;
						LSetSelect(false, cSize, AWList);
						curAWord := ChatHand^^.NumActionWords - 1;
						cSize.v := curAWord;
						cSize.h := 0;
						AddListString(ActionWordHand^^[curAWord].ActionWord, AWList);
						LSetSelect(True, cSize, AWList);
						LAutoScroll(AWList);
						FillActionWordData;
					end
					else
						ProblemRep('Unable to add. All fields must be filled.');
				end;
				3:	{Change}
				begin
					AW.ActionWord := GetTextBox(ChatroomDlg, 6);
					AW.TargetUser := GetTextBox(ChatroomDlg, 7);
					AW.OtherUser := GetTextBox(ChatroomDlg, 8);
					AW.Initiating := GetTextBox(ChatroomDlg, 9);
					AW.Unspecified := GetTextBox(ChatroomDlg, 10);
					if (length(AW.ActionWord) > 0) and (length(AW.TargetUser) > 0) and (length(AW.OtherUser) > 0) and (length(AW.Initiating) > 0) and (length(AW.Unspecified) > 0) then
					begin
						if ModalQuestion('Are you sure you want to change this action word?', false, true) = 1 then
						begin
							s := AW.ActionWord;
							UprString(s, true);
							AW.ActionWord := s;
							ActionWordHand^^[curAWord].ActionWord := AW.ActionWord;
							SaveRemoveActionWord(true, AW, ActionWordHand^^[curAWord].Offset);
							cSize.v := curAWord;
							cSize.h := 0;
							LSetCell(@AW.ActionWord[1], length(AW.ActionWord), cSize, AWList);
						end;
					end
					else
					begin
						ProblemRep('Unable to change. All fields must be filled.');
						if length(AW.ActionWord) <= 0 then
							SetTextBox(ChatroomDlg, 6, ActionWordHand^^[curAWord].ActionWord);
					end;
				end;
				4:	{Delete}
				begin
					if ModalQuestion('Are you sure you want to delete this action word?', false, true) = 1 then
					begin
						SaveRemoveActionWord(false, AW, ActionWordHand^^[curAWord].Offset);
						LDelRow(1, curAWord, AWList);
						if ChatHand^^.NumActionWords > 0 then
						begin
							curAWord := 0;
							cSize.v := 0;
							cSize.h := 0;
							LSetSelect(True, cSize, AWList);
							LAutoScroll(AWList);
							FillActionWordData;
						end
						else
						begin
							curAWord := -1;
							SetTextBox(ChatroomDlg, 6, '');
							SetTextBox(ChatroomDlg, 7, '');
							SetTextBox(ChatroomDlg, 8, '');
							SetTextBox(ChatroomDlg, 9, '');
							SetTextBox(ChatroomDlg, 10, '');
							SelIText(ChatroomDlg, 6, 0, 32767);
						end;
					end;
				end;
				5: {AWList}
				begin
					if LClick(myPt, theEvent.modifiers, AWList) then
						;
					if LGetSelect(true, cSize, AWList) and (cSize.v <> curAWord) then
					begin
						curAWord := cSize.v;
						FillActionWordData;
					end;
				end;
				otherwise
					;
			end;
		end;
	end;

	procedure CloseChatroomSetup;
	begin
		if AWList <> nil then
		begin
			DisposHandle(handle(AWList));
			AWList := nil;
		end;
		if ChatroomDlg <> nil then
		begin
			DisposDialog(ChatroomDlg);
			ChatroomDlg := nil;
			SortActionWordList;
		end;
	end;

	procedure SortActionWordList;
		var
			i, WhereFrom, counter: integer;
			LowWord: ActionWordListRec;
	begin
		if ChatHand^^.NumActionWords > 0 then
		begin
			i := 0;
			counter := 0;
			LowWord := ActionWordHand^^[i];
			WhereFrom := 0;
			repeat
				counter := counter + 1;
				if (counter > (ChatHand^^.NumActionWords - 1)) then
				begin
					ActionWordHand^^[WhereFrom] := ActionWordHand^^[i];
					ActionWordHand^^[i] := LowWord;
					i := i + 1;
					counter := i;
					LowWord := ActionWordHand^^[counter];
					WhereFrom := counter;
				end
				else if ActionWordHand^^[counter].ActionWord < LowWord.ActionWord then
				begin
					LowWord := ActionWordHand^^[counter];
					WhereFrom := counter;
				end;
			until (i = (ChatHand^^.NumActionWords - 1));
		end;
	end;

end.