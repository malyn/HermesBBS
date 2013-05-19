{ Segments: HUtils5_1 }
unit HUtils5;

interface
	uses
		AppleTalk, ADSP, Serial, Sound, Notification, PPCToolbox, Processes, EPPC, AppleEvents, TCPTypes, Initial, LoadAndSave, NodePrefs2, NodePrefs, SystemPrefs, Message_Editor, Import, Terminal, inpOut4, inpOut3, inpOut, ChatroomUtils, Chatroom, FileTrans, HUtils2, HUtils3, HUtils4;

	procedure doSysopKey (key: char; isControl: boolean);
	procedure DoKeyDetect (event: eventRecord);
	procedure CheckForChars;
	procedure doSerialChar (SerKe: char);
	procedure DoDailyMaint;
	procedure LaunchMailer (CrashMail: boolean);

implementation

{$S HUtils5_1}
	function Launchit (pLnch: pLaunchStruct): OSErr;
	inline
		$205F, $A9F2, $3E80;

	procedure LaunchMailer (CrashMail: boolean);
		var
			pMyLaunch: pLaunchStruct;
			myLaunch: LaunchStruct;
			MyPB: CInfoPBRec;
			LaunchString: str255;
	begin
		if CrashMail then
			LaunchString := Mailer^^.CrashMailPath
		else
			LaunchString := Mailer^^.Application;
		with MyPB do
		begin
			ioNamePtr := @LaunchString;
			ioVRefNum := 0;
			ioFDirIndex := 0;
			ioDirID := 0;
		end;	{	with	}
		result := PBGetCatInfo(@MyPB, false);
		pMyLaunch := @myLaunch;
		with pMyLaunch^ do
		begin
			pfName := @LaunchString;
			param := 0;
			LC[0] := 'L';
			LC[1] := 'C';
			extBlockLen := 6;
			fFlags := myPB.ioFlFndrInfo.fdFlags;
			if mailer^^.MailerAware and (TabbyQuit = NotTabbyQuit) then
				LaunchFlags := $C0000000
			else
				LaunchFlags := $00000000;
		end;		{	with pMyLaunch^	}
		result := Launchit(pMyLaunch);
	end;

	procedure DoChatroomPrompt (pressedKey: char);
		var
			endPrompt, AutoAccepted: boolean;
			toOutput: str255;
			tempPos, ScreenHight: integer;
	begin
		with curGlobs^ do
		begin
			if thisUser.ScrnHght < 24 then
				ScreenHight := thisUser.ScrnHght
			else
				ScreenHight := 24;
			with myPrompt do
			begin
				endPrompt := false;
				AutoAccepted := false;
				toOutput := char(0);
				if pressedKey = char(127) then
					pressedKey := char(8);
				if (pressedKey <> char(13)) and (pressedKey <> char(8)) then
				begin
					if (length(curPrompt) < numericLow) then
					begin
						toOutPut := pressedKey;
						curPrompt := concat(curPrompt, pressedKey);
						if (curPrompt[1] = '/') and (length(curPrompt) = 2) then
							case curPrompt[2] of
								'Q', 'q': 
								begin
									endPrompt := true;
									AutoAccepted := true;
								end;
								'U', 'u', '?', 'M', 'm', 'S', 's', 'B', 'b', 'T', 't', '-', 'L', 'l', 'P', 'p': 
									if (TheChat.Status <> SendingMessage) then
									begin
										endPrompt := true;
										AutoAccepted := true;
									end;
								'R', 'r': 
									if (TheChat.ChatMode = ANSIChat) and (TheChat.Status <> SendingMessage) then
									begin
										endPrompt := true;
										AutoAccepted := true;
									end;
								otherwise
							end;
					end
					else {length curprompt > numericLow}
					begin
						excess := ' ';
						excess[1] := pressedKey;
						tempPos := length(curPrompt);
						while (curPrompt[tempPos] <> char(32)) and (tempPos > 5) do
						begin
							excess := concat(curPrompt[tempPos], excess);
							tempPos := tempPos - 1;
						end;
						if length(excess) > 1 then
							delete(curPrompt, length(curPrompt) - length(excess) + 1, length(excess));
						if tempPos > 5 then
						begin
							BackSpace(length(excess));
						end;
						endPrompt := true;
					end;
				end
				else if (pressedKey = char(13)) then
				begin
					endPrompt := true
				end
				else if (pressedKey = char(8)) and (length(curPrompt) > 0) then
				begin
					Delete(curPrompt, length(curPrompt), 1);
					if TheChat.ChatMode = ANSIChat then
						ChatroomBackSpace(1)
					else
						BackSpace(1);
				end
				else if (pressedKey = char(8)) and (length(curPrompt) = 0) and (ScreenHight - TheChat.InputPos.v < 3) and (TheChat.ChatMode = ANSIChat) then
				begin
					if TheChat.InputPos.v - 1 = ScreenHight - 3 then
					begin
						tempPos := length(TheChat.TheMessage[1]);
						Delete(TheChat.TheMessage[1], length(TheChat.TheMessage[1]), 1);
						curPrompt := TheChat.TheMessage[1];
						ChatRoomDo := ChatAEM2;
					end
					else if TheChat.InputPos.v - 1 = ScreenHight - 2 then
					begin
						tempPos := length(TheChat.TheMessage[2]);
						Delete(TheChat.TheMessage[2], length(TheChat.TheMessage[2]), 1);
						curPrompt := TheChat.TheMessage[2];
						ChatRoomDo := ChatAEM3;
					end;
					MoveCursor(TheChat.InputPos.v - 1, tempPos + 2, true);
					Backspace(1);
				end;
				if toOutput <> char(0) then
				begin
					OutLine(toOutPut, false, inputColor);
					TheChat.InputPos.h := TheChat.InputPos.h + 1;
				end;
				if endPrompt then
				begin
					if (TheChat.ChatMode = TextChat) and (AutoAccepted) then
						BackSpace(length(promptLine) + length(curPrompt))
					else if TheChat.ChatMode = TextChat then
						bCR;
					OutLine('', false, 0);
					boardaction := None;
					prompting := false;
				end;
			end; {End with myPrompt}
		end; {End with curGlobs}
	end; {End Procedure}

	procedure DoQuotePrompt (pressedKey: char);
		var
			endPrompt: boolean;
			toOutput, ts: str255;
	begin
		with curGlobs^ do
		begin
			with myPrompt do
			begin
				endPrompt := false;
				toOutput := char(0);
				if pressedKey = char(127) then
					pressedKey := char(8);
				if (pressedKey <> char(13)) and (pressedKey <> char(8)) then
				begin
					ts := pressedKey;
					if (capitalize) and (pos(ts, 'qnpb') > 0) then
					begin
						UprString(ts, true);
						pressedKey := ts[1];
					end;
					if (length(curPrompt) < numericLow) then
						case pressedKey of
							'Q': 
								if length(curPrompt) = 0 then
								begin
									toOutPut := 'Quit';
									curPrompt := 'Q';
									endPrompt := true;
								end
								else
								begin
									toOutPut := 'Q';
									curPrompt := concat(curPrompt, 'Q');
									endPrompt := true;
								end;
							'N': 
								if (length(curPrompt) = 0) and (pos('N', allowedChars) > 0) then
								begin
									toOutPut := 'Next Page';
									curPrompt := 'N';
									endPrompt := true;
								end
								else if (pos('N', allowedChars) > 0) then
								begin
									toOutPut := 'N';
									curPrompt := concat(curPrompt, 'N');
									endPrompt := true;
								end;
							'P': 
								if (length(curPrompt) = 0) and (pos('P', allowedChars) > 0) then
								begin
									toOutPut := 'Previous Page';
									curPrompt := 'P';
									endPrompt := true;
								end
								else if (pos('P', allowedChars) > 0) then
								begin
									toOutPut := 'P';
									curPrompt := concat(curPrompt, 'P');
									endPrompt := true;
								end;
							'B': 
							begin
								toOutPut := 'B';
								curPrompt := concat(curPrompt, 'B');
							end;
							'-': 
								if (length(curPrompt) > 0) then
								begin
									toOutPut := '-';
									curPrompt := concat(curPrompt, '-');
								end;
							' ': 
								if (length(curPrompt) > 0) then
								begin
									toOutPut := ' ';
									curPrompt := concat(curPrompt, ' ');
								end;
							',': 
								if (length(curPrompt) > 0) then
								begin
									toOutPut := ',';
									curPrompt := concat(curPrompt, ',');
								end;
							'0', '1', '2', '3', '4', '5', '6', '7', '8', '9': 
							begin
								toOutput := pressedKey;
								curPrompt := concat(curPrompt, pressedKey);
							end;
							otherwise
						end; {End Case}
				end
				else if (pressedKey = char(13)) then
				begin
					if length(curPrompt) = 0 then
						toOutput := 'Quit';
					endPrompt := true
				end
				else if (pressedKey = char(8)) and (length(curPrompt) > 0) then
				begin
					Delete(curPrompt, length(curPrompt), 1);
					BackSpace(1);
				end;
				if toOutput <> char(0) then
					OutLine(toOutPut, false, inputColor);
				if endPrompt then
				begin
					OutLine('', false, 0);
					bCR;
					boardaction := None;
					prompting := false;
					if (boardsection = MainMenu) then
						DoMainMenu;
				end;
			end; {End with myPrompt}
		end; {End with curGlobs}
	end; {End Procedure}

	procedure DoDatePrompt (pressedKey: char);
		var
			endPrompt: boolean;
			ts, toOutput: str255;
			tl, tempPos: longint;
			i, sz: integer;
	begin
		with curglobs^ do
		begin
			with myPrompt do
			begin
				endprompt := false;
				if pressedKey = char(127) then
					pressedKey := char(8);
				tooutput := char(0);
				if (pressedKey <> char(13)) and (pos(pressedkey, '0123456789') > 0) and (pressedKey <> char(8)) and (pressedKey <> char(25)) then
				begin
					sz := length(curprompt);
					if (sz < 9) and ((pressedKey <> char(8)) and (pressedKey <> char(25))) then
					begin
						if (sz = 0) and (pos(pressedkey, '01') > 0) then
						begin
							tooutput := pressedkey;
							curprompt := concat(curprompt, pressedkey);
						end
						else if (sz = 0) and (pos(pressedkey, '23456789') > 0) then
						begin
							tooutput := concat('0', pressedkey);
							curPrompt := concat('0', pressedkey, '/');
						end
						else if ((sz = 1) and (curprompt[1] = '1') and (pos(pressedKey, '012') > 0)) or ((sz = 1) and (curprompt[1] = '0') and (pos(pressedKey, '123456789') > 0)) then
						begin
							tooutput := pressedKey;
							curprompt := concat(curprompt, pressedkey);
							curprompt := concat(curprompt, '/');
						end
						else if (sz = 3) and (pos(pressedkey, '0123') > 0) then
						begin
							tooutput := pressedkey;
							curprompt := concat(curprompt, pressedkey);
						end
						else if (sz = 3) and (pos(pressedkey, '456789') > 0) then
						begin
							tooutput := concat('0', pressedkey);
							curprompt := concat(curprompt, '0', pressedkey, '/');
						end
						else if ((sz = 4) and (pos(curprompt[4], '012') > 0) and (pos(pressedKey, '1234567890') > 0)) or ((sz = 4) and (curprompt[4] = '3') and (pos(pressedKey, '01') > 0)) then
						begin
							if (curprompt[4] = '0') and (pressedKey <> '0') or (curprompt[4] <> '0') then
							begin
								tooutput := pressedKey;
								curprompt := concat(curprompt, pressedkey);
								curprompt := concat(curprompt, '/');
							end;
						end
						else if (sz = 6) and (pos(pressedkey, '0123456789') > 0) then
						begin
							tooutput := pressedkey;
							curprompt := concat(curprompt, pressedkey);
						end
						else if (sz = 7) and (pos(pressedkey, '0123456789') > 0) then
						begin
							tooutput := pressedkey;
							curprompt := concat(curprompt, pressedkey);
						end;
					end;
				end;
				if pressedKey = char(25) then
				begin
					if length(curPrompt) > 0 then
						BackSpace(length(curPrompt));
					curPrompt := '';
				end;
				if pressedkey = char(8) then
				begin
					if length(curprompt) > 0 then
					begin
						if curprompt[length(curprompt)] = '/' then
						begin
							delete(curPrompt, length(curprompt), 1);
							BackSpace(1);
						end;
						delete(curPrompt, length(curprompt), 1);
						backspace(1);
					end;
				end;
				if (tooutput <> char(0)) then
				begin
					OutLine(toOutPut, false, inputColor);
					if (length(curPrompt) = 3) or (length(curPrompt) = 6) then
						OutLine('/', false, inputColor);
				end;
			end;
			if (length(curprompt) = 8) or (myPrompt.autoAccept and (pressedKey = char(13))) then
			begin
				OutLine('', false, 0);
				bCR;
				boardaction := None;
				prompting := false;
				if (boardsection = MainMenu) then
					DoMainMenu;
			end;
		end;
	end;

	procedure DoPhonePrompt (pressedKey: char);
		var
			toOutput: char;
			endPrompt: boolean;
			ts: str255;
			tl, tempPos: longint;
			i: integer;
	begin
		with curglobs^ do
		begin
			with myPrompt do
			begin
				tooutput := char(0);
				endprompt := false;
				if pressedKey = char(127) then
					pressedKey := char(8);
				if (pressedKey <> char(13)) then
				begin
					if (length(curprompt) < 12) and (pressedKey <> char(8)) and (pressedKey <> char(25)) then
					begin
						if (length(curPrompt) >= 0) and (length(curPrompt) < 3) and (pos(pressedkey, '0123456789') > 0) then
						begin
							curPrompt := concat(curprompt, pressedkey);
							toOutPut := pressedkey;
						end;
						if (length(curPrompt) > 3) and (length(curPrompt) < 7) and (pos(pressedkey, '0123456789') > 0) then
						begin
							curPrompt := concat(curprompt, pressedkey);
							toOutPut := pressedkey;
						end;
						if (length(curPrompt) > 7) and (length(curPrompt) < 12) and (pos(pressedkey, '0123456789') > 0) then
						begin
							curPrompt := concat(curprompt, pressedkey);
							toOutPut := pressedkey;
						end;
					end;
				end;
				if pressedKey = char(25) then
				begin
					if length(curPrompt) > 1 then
						BackSpace(length(curPrompt) - 1);
				end;
				if (pressedkey = char(8)) and (length(curprompt) > 0) then
				begin
					if curprompt[length(curprompt)] = '-' then
					begin
						delete(curPrompt, length(curprompt), 1);
						BackSpace(1);
					end;
					delete(curPrompt, length(curprompt), 1);
					backspace(1);
				end;
				if (tooutput <> char(0)) then
				begin
					OutLine(toOutPut, false, -1);
					if length(curPrompt) = 3 then
					begin
						curprompt := concat(curprompt, '-');
						OutLine('-', false, -1);
					end;
					if length(curPrompt) = 7 then
					begin
						curprompt := concat(curprompt, '-');
						OutLine('-', false, -1);
					end;
					if (length(curprompt) = 12) then
					begin
						OutLine('', false, 0);
						bCR;
						boardaction := None;
						prompting := false;
						if (boardsection = MainMenu) then
							DoMainMenu;
					end;
				end;
			end;
		end;
	end;

	procedure DoPrompt (pressedKey: char);
		label
			300;
		var
			toOutput: char;
			endPrompt: boolean;
			ts: str255;
			tl, tempPos: longint;
			i: integer;
	begin
		with curglobs^ do
		begin
			with myPrompt do
			begin
				endprompt := false;
				if inPause then
				begin
					if (pressedKey <> 'Q') and (pressedKey <> 'q') then
						pressedKey := char(13);
					endprompt := true;
					goto 300;
				end;
				if pressedKey = char(127) then
					pressedKey := char(8);
				toOutput := pressedKey;
				if (ansiAllowed) and (pressedKey = char(16)) then
				begin
					if (curPrompt[length(curPrompt)]) <> char(3) then
						CurPrompt := Concat(CurPrompt, char(3));
				end
				else if (AnsiAllowed) and (curPrompt[length(curPrompt)] = char(3)) then
				begin
					if ((pressedKey > char(96)) and (pressedKey < char(103))) then
						pressedKey := chr(ord(pressedKey) - 32);
					if ((pressedKey > char(47)) and (pressedKey < char(58))) then
					begin
						curPrompt := concat(curPrompt, pressedKey);
						doM(USERCOLORBASE + ord(pressedKey) - 48);
					end
					else if ((pressedKey > char(64)) and (pressedKey < char(71))) then
					begin
						curPrompt := concat(curPrompt, pressedKey);
						doM(USERCOLORBASE + ord(pressedKey) - 55);
					end
					else
					begin
						curPrompt := concat(curPrompt, '0');
						doM(0);
					end;
				end
				else if pressedKey <> char(13) then
				begin
					if pressedkey = char(2) then
					begin
						curPrompt[1] := char(2);
					end
					else if (pressedkey = char(2)) then
						CurPrompt := '';
					if (pressedkey = char(25)) and (CurPrompt[1] = char(2)) and (lastKey = char(2)) then
					begin
						CurPrompt[2] := char(25);
					end
					else if (pressedkey = char(25)) then
						CurPrompt := '';
					if (pressedkey = char(9)) and (CurPrompt[1] = char(2)) and (CurPrompt[2] = char(25)) and (lastKey = char(25)) then
					begin
						CurPrompt[3] := char(9);
					end
					else if (pressedkey = char(9)) then
						CurPrompt := '';
					if (pressedkey = char(10)) then
						CurPrompt := '';
					if (length(curprompt) < maxChars) or (pressedKey = char(8)) then
					begin
						ts := ' ';
						ts[1] := pressedKey;
						if capitalize then
							UprString(ts, true);
						pressedKey := ts[1];
						toOutput := PressedKey;
						if (replaceChar <> char(0)) and (replaceChar <> char(13)) then
							toOutput := replaceChar;
						if (BoardSection = MainMenu) and (pos('/', curPrompt) = 1) and (length(curPrompt) = 1) and (pressedKey = 'O') then
						begin
							HangUpAndReset;
							exit(doPrompt);
						end;
						if ((pressedKey >= char(48)) and (pressedKey <= char(57))) and (curPrompt[length(curPrompt)] <> char(3)) then
						begin
							StringToNum(concat(curprompt, pressedKey), tl);
							if ((tl >= numericLow) and (tl <= numericHigh)) or not enforceNumeric then
							begin
								curprompt := concat(curprompt, pressedKey);
								if (length(curprompt) = 1) and (thisUser.TerminalType = 1) and (inputColor >= 0) then
									dom(inputColor);
								if (replaceChar <> char(0)) then
								begin
									ts := pressedKey;
									ProcessData(activeNode, @ts[1], 1);
									tempPos := 1;
									ts := toOutput;
									if not sysopLogon then
										result := AsyncMWrite(outputRef, tempPos, @ts[1]);
								end
								else
									OutLine(toOutput, false, -1);
								if autoAccept and enforceNumeric then
								begin
									if ((numericHigh - 9) < tl) or ((tl * 10) > numericHigh) or ((numericLow = 0) and (tl = 0)) then
									begin
										endPrompt := true;
										goto 300;
									end;
								end;
							end;
						end
						else if ((allowedChars = '') and not enforceNumeric) or (pos(pressedKey, allowedChars) > 0) or ((length(curPrompt) > 0) and (pos(breakChar, curPrompt) = 1)) then
						begin
							if pressedKey <> char(8) then
							begin
								if autoAccept and (pressedKey <> breakChar) and (pos(breakChar, curPrompt) <> 1) then
								begin
									if ((pressedKey < char(48)) or (pressedKey > char(57))) then
									begin
										if (boardsection = mainmenu) and not intransfer then
											OutLine(Menuhand^^.Name[pos(PressedKey, MenuCmds)], false, inputColor)
										else if (boardsection = mainmenu) and intransfer then
											OutLine(Transhand^^.Name[pos(PressedKey, MenuCmds)], false, inputColor)
										else
											OutLine(pressedKey, false, inputColor);
										if keyString1[1] = char(13) then
											delete(keyString1, 1, 1);
										if keyString2[1] = char(13) then
											delete(keyString2, 1, 1);
										if keyString3[1] = char(13) then
											delete(keyString3, 1, 1);
										if pressedKey = keyString1[1] then
											OutLine(copy(keyString1, 2, length(keyString1) - 1), false, -1);
										if pressedKey = keyString2[1] then
											OutLine(copy(keyString2, 2, length(keyString2) - 1), false, -1);
										if pressedKey = keyString3[1] then
											OutLine(copy(keyString3, 2, length(keyString3) - 1), false, -1);
										endPrompt := true;
										curprompt := concat(curprompt, pressedKey);
										goto 300;
									end
									else
									begin
										StringToNum(curPrompt, tl);
										if (tl <= numericHigh) and (tl >= numericLow) then
										begin
											endprompt := true;
										end;
									end;
								end;
								curprompt := concat(curprompt, pressedKey);
								if (length(curprompt) = 1) and (thisUser.TerminalType = 1) and (inputColor >= 0) then
									dom(inputColor);
								if (replaceChar <> char(0)) then
								begin
									ts := pressedKey;
									ProcessData(activeNode, @ts[1], 1);
									tempPos := 1;
									ts := toOutput;
									if not sysopLogon then
										result := AsyncMWrite(outputRef, tempPos, @ts[1]);
								end
								else
									OutLine(toOutput, false, -1);
							end
							else
							begin
								if (AnsiAllowed) and (CurPrompt[Length(CurPrompt) - 1] = Char(3)) then
								begin
									delete(curPrompt, length(CurPrompt) - 1, 2);
									if thisUser.TerminalType = 1 then
										doM(0);
								end
								else if (ansiAllowed) and (CurPrompt[Length(CurPrompt)] = Char(3)) then
								begin
									delete(curPrompt, length(CurPrompt) - 1, 2);
									if thisUser.TerminalType = 1 then
										doM(0);
								end
								else if length(curprompt) > 0 then
								begin
									delete(curPrompt, length(curprompt), 1);
									backSpace(1);
								end;
							end;
						end
						else if (pressedKey = char(8)) then
						begin
							if (AnsiAllowed) and (CurPrompt[Length(CurPrompt) - 1] = Char(3)) then
							begin
								delete(curPrompt, length(CurPrompt) - 1, 2);
								if thisUser.TerminalType = 1 then
									doM(0);
							end
							else if (ansiAllowed) and (CurPrompt[Length(CurPrompt)] = Char(3)) then
							begin
								delete(curPrompt, length(CurPrompt) - 1, 2);
								if thisUser.TerminalType = 1 then
									doM(0);
							end
							else if length(curprompt) > 0 then
							begin
								delete(curPrompt, length(curprompt), 1);
								backSpace(1);
							end;
						end;
					end
					else if wrapAround then
					begin
						excess := ' ';
						excess[1] := pressedKey;
						tempPos := length(curPrompt);
						while (curPrompt[tempPos] <> char(32)) and (tempPos > 5) do
						begin
							excess := concat(curPrompt[tempPos], excess);
							tempPos := tempPos - 1;
						end;
						if length(excess) > 1 then
							delete(curprompt, length(curPrompt) - length(excess) + 1, length(excess));
						if tempPos > 5 then
						begin
							backSpace(length(excess));
						end;
						endPrompt := true;
					end;
				end
				else
				begin
					if (char(13) = keyString1[1]) and (length(keyString1) > 0) and (replacechar <> char(13)) then
					begin
						OutLine(copy(keyString1, 2, length(keyString1) - 1), false, inputColor);
						curPrompt := keyString1[2];
					end;
					if (char(13) = keyString2[1]) and (length(keyString2) > 0) and (replacechar <> char(13)) then
					begin
						OutLine(copy(keyString2, 2, length(keyString2) - 1), false, inputColor);
						curPrompt := keyString2[2];
					end;
					if (char(13) = keyString3[1]) and (length(keyString3) > 0) and (replacechar <> char(13)) then
					begin
						OutLine(copy(keyString3, 2, length(keyString3) - 1), false, inputColor);
						curprompt := keyString3[2];
					end;
					if ((replacechar <> char(13)) and (numericHigh <> -666)) or (length(curPrompt) > 0) then
						endprompt := true;
				end;
				if endprompt then
				begin
300:
					OutLine('', false, 0);
					if wrapsonCR then
						bCR;
					BoardAction := none;
					if inPause then
					begin
						backSpace(length(promptLine));
						BoardAction := SavedBDaction;
						if BoardAction <> ListText then
							negateBCR := true;
						InPause := false;
						noPause := false;
						if (pressedKey <> char(13)) then
						begin
							aborted := true;
							if (BoardSection = ListFiles) and (ListDo = ListFour) then
								curTextPos := -100
							else if continuous then
							begin
								inZScan := false;
								continuous := false;
							end
							else if (BoardAction = ListText) then
							begin
								ClearInBuf;
								CurTextPos := OpenTextSize + 1;
								ListTextFile;
							end;
						end;
					end;
					prompting := false;
					if (BoardSection = MainMenu) then
						DoMainMenu;
				end;
				lastkey := pressedkey;
			end;
		end;
	end;

	procedure UpdateExternals (tl2: longint; r, p: integer);
	begin
	end;

	procedure DoDailyMaint;
		var
			tempString, tempString2: str255;
			result: OSerr;
			tempDate: DateTimeRec;
			a, b, c, d, e, f, g, h, i, j, k: integer;
			templong, templong2, tl2: longint;
			tempM: menuHandle;
	begin
		GetDateTime(templong);
		tempString := concat(sharedPath, 'Misc:Brief Log');
		result := FSDelete(tempString, 0);
		result := Create(tempString, 0, 'HRMS', 'DATA');
		writeDirectToLog := true;
		LogThis('', 0);
		LogThis(StringOf('Calls Today: ', TotalCalls : 0, '     Active Today: ', TotalMins : 0), 0);
		LogThis('----------------------------------', 0);
		LogThis(StringOf('Posts Today: ', TotalPosts : 0), 0);
		LogThis(StringOf('Email Today: ', TotalEmail : 0), 0);
		LogThis(StringOf('Uplds Today: ', TotalUls : 0, '/', TotalFuls : 0), 0);
		LogThis(StringOf('Dnlds Today: ', TotalDls : 0, '/', TotalFDls : 0), 0);
		writeDirectToLog := false;
		Write2ZLog(99, True);
		if not InitSystHand^^.totals then
		begin
			for i := InitSystHand^^.numNodes downto 1 do
				Write2ZLog(i, False);
		end;
		for i := 1 to MAX_NODES do
		begin
			InitSystHand^^.callsToday[i] := 0;
			InitSystHand^^.mPostedToday[i] := 0;
			InitSystHand^^.eMailToday[i] := 0;
			InitSystHand^^.uploadsToday[i] := 0;
			InitSystHand^^.kuploaded[i] := 0;
			InitSystHand^^.minsToday[i] := 0;
			InitSystHand^^.dlsToday[i] := 0;
			InitSystHand^^.kdownloaded[i] := 0;
			InitSystHand^^.failedULs[i] := 0;
			InitSystHand^^.failedDLs[i] := 0;
		end;
		Date2Secs(InitSystHand^^.lastmaint, tempLong);
		IUDateString(tempLong, shortDate, tempstring);
		tempstring2 := concat(sharedPath, 'Misc:Today Log');
		result := copy1File(tempstring2, concat(sharedPath, 'Logs:', tempstring));
		result := FSDelete(tempstring2, 0);
		tempM := GetMHandle(mLog);
		GetItem(tempM, countMItems(tempM), tempstring2);
		result := FSDelete(concat(sharedPath, 'Logs:', tempstring2), 0);
		DelMenuItem(tempM, countMItems(tempM));
		InsMenuItem(tempM, ' ', 3);
		SetItem(tempM, 4, tempstring);
		if Mailer^^.MailerAware then
		begin
			Date2Secs(InitSystHand^^.lastmaint, tempLong);
			IUDateString(tempLong, shortDate, tempstring);
			tempstring2 := concat(sharedPath, 'Misc:Network Today Log');
			result := copy1File(tempstring2, concat(sharedPath, 'Logs:Network:', tempstring));
			result := FSDelete(tempstring2, 0);
			tempM := GetMHandle(mNetLog);
			GetItem(tempM, countMItems(tempM), tempstring2);
			result := FSDelete(concat(sharedPath, 'Logs:Network:', tempstring2), 0);
			DelMenuItem(tempM, countMItems(tempM));
			InsMenuItem(tempM, ' ', 3);
			SetItem(tempM, 4, tempstring);
			WriteNetUsageRecord;
		end;
		GetTime(tempDate);
		theNodes[activeNode]^.enteredPass2 := 'Midnight_Turnover';
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
			if templong2 > 0 then
				for i := 1 to templong2 do
				begin
					if (theEMail^^[0].FileAttached) and (not theEMail^^[0].MultiMail) then
						DeleteFileAttachment(true, theEMail^^[0].FileName);
					DeleteMail(0);
				end;
		end;
		theNodes[activeNode]^.enteredPass2 := char(0);
		Date2Secs(InitSystHand^^.lastMaint, tempLong);
		templong2 := InitSystHand^^.StartDate;
		GetDateTime(tl2);
		e := 37;
		InitSystHand^^.Lastmaint := tempDate;
		f := length(InitSystHand^^.EndString);
		UpdateExternals(templong2, e, f);
		doSystRec(true);
		for i := 1 to InitSystHand^^.numNodes do
		begin
			with theNodes[i]^ do
			begin
				thisUser.onToday := 1;
				thisUser.minOnToday := 0;
				thisUser.EMsentToday := 0;
				thisUser.MPostedToday := 0;
				thisUser.NumUlToday := 0;
				thisUser.NumDlToday := 0;
				thisUser.KBULToday := 0;
				thisUser.KBDLToday := 0;
				if (thisUser.userNum > 0) and (boardMode = User) and (thisUser.useDayorCall) then
				begin
					SubtractOn := tickCount - timeBegin;
				end;
			end;
		end;
	end;

	procedure doSerialChar (SerKe: char);
		var
			count, tempint2: longInt;
			i, tempPos, tempint: integer;
			dumRect, tempRect: rect;
			yaba, tempString: str255;
			flipped, didTwoCol: boolean;
			myByte: byte;
	begin
		with curglobs^ do
		begin
			if (serKe <> char(17)) and (serKe <> char(19)) then
				lastKeyPressed := tickCount;
			didTwoCol := false;
			flipped := false;
			timeFlagged := false;
			if (BoardMode = User) then
			begin
				if (BoardSection = EXTERNAL) and (activeUserExternal > 0) and rawStdin then
				begin
					curPrompt := SerKe;
					CallUserExternal(RAWCHAR, activeUserExternal);
				end
				else if (serKe = char(15)) then (*Control + O*)
				begin
					if (BoardSection <> Chatroom) then
					begin
						if (BoardAction = Prompt) and (HelpNum > 0) then
						begin
							if LoadSpecialText(HelpFile, HelpNum) then
							begin
								if thisUser.TerminalType = 1 then
									doM(0);
								BoardAction := ListText;
								ListingHelp := true;
								Prompting := false;
								bCR;
								ListTextFile;
							end;
						end;
					end
					else
						DoShowChatMenuORHelp(false);
				end
				else if (serKe = char(19)) then  (*Control+S*)
				begin
					if ((((BoardSection = ListFiles) and (ListDo = ListFour)) or continuous or (BoardAction = Repeating) or (BoardAction = ListText))) then
						if SysOpStop then
							SysOpStop := False
						else
							SysOpStop := True;
				end
				else if (serKe = char(17)) then		(*Control+Q*)
				begin
					sysopStop := false;
				end
				else if (serKe = char(20)) then		(*Control+T*)
				begin
					if (BoardSection <> Logon) and (BoardSection <> NewUser) then
					begin
						GetDateTime(count);
						IUDateString(count, abbrevDate, yaba);
						IUTimeString(count, true, tempString);

						if (BoardSection = Chatroom) then
						begin
							ChatroomSingle(activeNode, false, false, concat(yaba, '  ', tempstring));
							ChatroomSingle(activeNode, false, false, concat(RetInStr(283), tickToTime(tickCount - timeBegin)));
							ChatroomSingle(activeNode, false, false, concat(RetInStr(284), TickToTime(ticksLeft(activeNode))));
						end
						else
						begin
							savedBDAction := BoardAction;
							BoardAction := none;
							bCR;
							OutLine(concat(yaba, '  ', tempstring), true, 0);
							OutLine(concat(RetInStr(283), tickToTime(tickCount - timeBegin)), true, 0);	{Time on  : }
							OutLine(concat(RetInStr(284), TickToTime(ticksLeft(activeNode))), true, 0);	{Time Left: }
							bCR;
							bCR;
							BoardAction := savedBDAction;
							if prompting then
								ReprintPrompt
							else if (BoardAction = Writing) then
								ListLine(online);
						end;
					end;
				end
				else if ((serKe = char($AE)) or ((Mailer^^.UseEMSI) and (Pos('EMSI_INQ', curPrompt) <> 0))) and (BoardSection = Logon) and ((LogonStage = Welcome) or (LogonStage = Name)) then
				begin
					if mailer^^.MailerAware and doCrashmail then
					begin
						result := SetVol(nil, homeVol);
						result := Create(concat(mailer^^.eventpath, 'connect.bbs'), 0, 'HRMS', 'CNCT');
						result := FSOpen(concat(mailer^^.eventpath, 'connect.bbs'), 0, tempint);
						NumToString(currentBaud, tempstring);
						NumToBaud(maxBaud, tempint2);
						if not matchInterface then
							NumToString(tempint2, tempstring);
						if inportName = '.AIn' then
							tempstring := concat('a', tempstring)
						else
							tempstring := concat('b', tempstring);
						tempint2 := length(tempstring);
						result := FSWrite(tempint, tempint2, @tempstring[1]);
						result := FSClose(tempint);
						LogThis(RetInStr(8), 6);
						if mailer^^.SubLaunchMailer = 1 then
						begin
							TabbyQuit := NotTabbyQuit;
							CloseComPort;
							TabbyPaused := true;
							SavedInPort := InportName;
							InPortName := '';
							OpenComPort;
							GoWaitMode;
							LaunchMailer(True);
						end
						else if mailer^^.SubLaunchMailer = 2 then
						begin
							HandleAECrashMail;
						end
						else if (mailer^^.SubLaunchMailer = 0) and (not isGeneric) then
						begin
							TabbyQuit := CrashMail;
							quit := 1;
						end
						else
							HangUpAndReset;
					end;
				end
				else if (BoardAction = Writing) then		(*Entering Message*)
				begin
					LineChar(serKe);
				end
				else if (BoardAction = Chat) then			(*Chatting*)
				begin
					DoChatShow(false, false, serKe);
				end
				else if ((serKe = char(24)) or ((serKe = char(32)) and (BoardAction <> chat) and (BoardAction <> writing))) and ((BoardAction = ListText) or (BoardAction = Repeating) or continuous or (BoardAction = Writing) or (BoardAction = Chat)) then
				begin
					if (BoardSection = ListFiles) and (ListDo = ListFour) then
						curTextPos := -100
					else if continuous then
					begin
						inZScan := false;
						continuous := false;
					end
					else if (BoardAction = ListText) then
					begin
						ClearInBuf;
						CurTextPos := OpenTextSize;
						ListTextFile;
					end;
					aborted := true;
				end
				else if (BoardAction = Prompt) and ((serKe > char(31)) or (serKe = char(14)) or (serKe = char(18)) or (serKe = char(11)) or (serKe = char(13)) or (serKe = char(8))) or (serKe = char(10)) or (serKe = char(25)) or (serKe = char(9)) or (serKe = char(2)) or ((serKe = Char(16)) and (myPrompt.AnsiAllowed)) then
				begin
					if myprompt.maxChars = -1 then
						DoDatePrompt(serKe)
					else if myprompt.maxChars = -2 then
						DoPhonePrompt(serKe)
					else if myPrompt.maxChars = -3 then
						DoQuotePrompt(serKe)
					else if myPrompt.maxChars = -4 then
						DoChatroomPrompt(serKe)
					else
						DoPrompt(serKe);
				end;
			end
			else if (BoardMode = Waiting) then
			begin
				BoardMode := Waiting;
				if ((serKe = '2')) and not inDownTime then
					AnswerCall
			end
			else if (BoardMode = Answering) then
			begin
				ConnectMade(serKe);
			end;
		end;
	end;

	procedure CheckforChars;
		label
			100;
		var
			count: longInt;
			b, i: integer;
			dumRect: rect;
			yaba: str255;
			tc1: char;
			Hermes: integer;
			cb: TCPControlBlock;
	begin
		with curglobs^ do
		begin
			if nodeType = 3 then
			begin
				if (BoardMode = User) then
				begin
					i := TCPBytesToRead;
					if (i > 0) then
					begin
						b := 250 - length(typeBuffer);
						if i > b then
							i := b;
						with cb do
						begin
							ioResult := 1;
							ioCompletion := nil;

							ioCRefNum := ippDrvrRefNum;
							csCode := TCPcsRcv;
							tcpStream := StreamPtr(nodeTCPStreamPtr);

							receive.commandTimeoutValue := 0;
							receive.markFlag := 0;
							receive.urgentFlag := 0;
							receive.rcvBuff := @incoming;
							receive.rcvBuffLength := i;
							receive.userDataPtr := nil;
						end;
						result := PBControl(ParmBlkPtr(@cb), false);
						if (result = noErr) then
						begin
							count := cb.receive.rcvBuffLength;
							goto 100;
						end;
					end;
				end;
			end
			else if nodeType = 2 then
			begin
				if (BoardMode = User) then
				begin
					i := ADSPBytesToRead;
					if (i > 0) then
					begin
						b := 250 - length(typeBuffer);
						if i > b then
							i := b;
						with nodeDSPPBPtr^ do
						begin
							ioCompletion := nil;
							csCode := dspRead;
							reqCount := i;
							dataPtr := @incoming;
							ioCRefNum := dspDrvrRefNum;
							ccbRefNum := nodeCCBRefNum;
						end;
						result := PBControl(ParmBlkPtr(nodeDSPPBPtr), false);
						if (result = noErr) then
						begin
							count := nodeDSPPBPtr^.actCount;
							goto 100;
						end;
					end;
				end;
			end
			else if nodeType = 1 then
			begin
				result := mySDGetBuf(count);
				if count > 0 then
				begin
					if count > 3072 then
						count := 3072;
					i := 250 - length(typeBuffer);
					if (BoardMode = User) and (count > i) then
						count := i;
					if (mySyncRead(inputRef, count, @incoming) = noErr) then
					begin
						if (BoardMode <> Terminal) then
						begin
100:
							if (batDo = BatSeven) and (BoardSection = Batch) and (boardMode = User) then
								lastKeypressed := tickCount;
							for i := 0 to (count - 1) do
							begin
								if (BoardSection = EXTERNAL) and (activeUserExternal > 0) and rawStdin then
								begin
									curPrompt := incoming[i];
									CallUserExternal(RAWCHAR, activeUserExternal);
								end
								else
								begin
									if incoming[i] = char(127) then
										incoming[i] := char(8);
									if incoming[i] <> char(10) then
										if ((incoming[i] > char(31)) or ((incoming[i] = char(8)) or (incoming[i] = char(13)))) and (BoardMode = User) and (BoardAction <> ListText) then
											typeBuffer := concat(typeBuffer, incoming[i])
										else
										begin
											DoSerialChar(incoming[i]);
										end;
								end;
							end;
						end
						else if (BoardMode = Terminal) then
						begin
							if not in8BitTerm then
								for i := 0 to (count - 1) do
									incoming[i] := char(BitAnd(ord(incoming[i]), $7F));
							ProcessData(activeNode, @incoming[0], count);
						end;
					end;
				end;
			end;
		end;
	end;

	procedure doSysopKey (key: char; isControl: boolean);
		var
			yaba, tempString, TEMPST: str255;
			strLeng, count: longInt;
			i, tempPos: integer;
	begin
		with curglobs^ do
		begin
			if (BoardMode = Answering) then
			begin
				if (Key = 'H') or (Key = 'h') then
				begin
					HangupAndReset;
				end;
			end
			else if (BoardMode = Waiting) or (BoardMode = Failed) then
			begin
				if (Key = char(13)) then
				begin
					HangupAndReset;
				end;
			end
			else if (BoardMode = Terminal) then
			begin
				count := 1;
				yaba := key;
				result := FSWrite(outputRef, count, @yaba[1]);
				if inHalfDuplex then
					ProcessData(activeNode, @yaba[1], 1);
			end
			else if not (myTrans.active) and (Key = char(15)) and (isControl) then
			begin
				if (BoardSection <> ChatRoom) then
				begin
					if (BoardAction = Prompt) and (helpNum > 0) then
					begin
						if LoadSpecialText(HelpFile, HelpNum) then
						begin
							if thisUser.TerminalType = 1 then
								doM(0);
							BoardAction := ListText;
							ListingHelp := true;
							Prompting := false;
							bCR;
							ListTextFile;
						end;
					end;
				end
				else
					DoShowChatMenuORHelp(false);
			end
			else if not (myTrans.active) and (((Key = char(24)) and isControl) or ((key = char(32)) and (BoardAction <> chat))) and ((BoardAction = Chat) or (BoardAction = ListText) or (BoardAction = Repeating) or continuous) and (BoardMode = User) then
			begin
				if continuous then
				begin
					inZScan := false;
					continuous := false;
				end
				else if (BoardAction = ListText) then
				begin
					if not sysopLogon then
					begin
						ClearInBuf;
					end;
					CurTextPos := OpenTextSize;
					ListTextFile;
				end
				else if (BoardSection = ListFiles) and (ListDo = ListFour) then
				begin
					curTextPos := -100;
				end;
				aborted := true;
			end
			else if not (myTrans.active) and ((Key = char(19)) and (isControl)) and ((BoardAction = Repeating) or (BoardAction = ListText) or ((BoardSection = ListFiles) and (ListDo = ListFour))) then
			begin
				if SysOpStop then
					SysOpStop := False
				else
					SysOpStop := True;
			end
			else if not (myTrans.active) and (Key = char(17)) and isControl then
			begin
				SysopStop := false;
			end
			else if not (myTrans.active) and (Key = char(20)) and IsControl and (BoardMode = User) then
			begin
				GetDateTime(count);
				IUDateString(count, abbrevDate, yaba);
				IUTimeString(count, true, tempString);

				if (BoardSection = Chatroom) then
				begin
					ChatroomSingle(activeNode, false, false, concat(yaba, '  ', tempstring));
					ChatroomSingle(activeNode, false, false, concat(RetInStr(283), tickToTime(tickCount - timeBegin)));
					ChatroomSingle(activeNode, false, false, concat(RetInStr(284), TickToTime(ticksLeft(activeNode))));
				end
				else
				begin
					savedBDAction := BoardAction;
					BoardAction := none;
					bCR;
					OutLine(concat(yaba, '  ', tempstring), true, 0);
					OutLine(concat(RetInStr(283), tickToTime(tickCount - timeBegin)), true, 0);	{Time on  : }
					OutLine(concat(RetInStr(284), TickToTime(ticksLeft(activeNode))), true, 0);	{Time Left: }
					bCR;
					bCR;
					BoardAction := savedBDAction;
					if prompting then
						ReprintPrompt
					else if (BoardAction = Writing) then
						ListLine(online);
				end;
			end
			else if (BoardAction = Writing) then
			begin
				LineChar(key);
				exit(doSysopKey);
			end
			else if (BoardAction = Chat) then
			begin
				DoChatShow(false, true, key);
				exit(doSysopKey);
			end
			else if (BoardAction = Prompt) then
				if myprompt.maxChars = -1 then
					DoDatePrompt(key)
				else if myprompt.maxChars = -2 then
					DoPhonePrompt(key)
				else if myPrompt.maxChars = -3 then
					DoQuotePrompt(key)
				else if myPrompt.maxChars = -4 then
					DoChatroomPrompt(key)
				else
					DoPrompt(key)
		end;
	end;

	procedure DoKeyDetect (event: eventRecord);
		var
			isControl: boolean;
			altKey, key: char;
			yaba, tempString, TEMPST: str255;
			strLeng, count: longInt;
			dumRect: Rect;
			i, tempPos: integer;
	begin
		with curglobs^ do
		begin
			if BAnd(event.modifiers, cmdKey) <> 0 then
			begin
				if event.what = keyDown then
				begin
					key := CHR(BAnd(event.message, charCodeMask));
					if BAnd(event.modifiers, optionKey) <> 0 then
						SwitchNode(conopt2Num(key))
					else
						DoMenuCommand(MenuKey(key));
					exit(doKeyDetect);
				end;
			end;
			ObscureCursor;
			i := isMyTextWindow(frontWindow);
			if (i >= 0) then
			begin
				with textWinds[i] do
				begin
					if editable then
					begin
						key := CHR(BAnd(event.message, charCodeMask));
						if (key = CHR(8)) | (t^^.teLength - (t^^.selEnd - t^^.selStart) + 1 < 32000) then
						begin	{but check haven't gone past}
							dirty := true;
							TEKey(key, t);
							AdjustScrollbars(i, FALSE);
							AdjustTE(i);
						end
						else
							SysBeep(10);
						exit(doKeyDetect);
					end;
				end;
			end;
			bullbool := false;
			strLeng := event.message;
			strLeng := BitShift(strLeng, -8);
			AltKey := CHR(BAnd(strLeng, $000000FF));
			case ord(altkey) of
				$7A: 
					SwitchNode(1);
				$78: 
					Switchnode(2);
				$63: 
					switchnode(3);
				$76: 
					switchnode(4);
				$60: 
					switchnode(5);
				$61: 
					switchnode(6);
				$62: 
					switchnode(7);
				$64: 
					switchnode(8);
				$65: 
					switchnode(9);
				$6D: 
					switchnode(10);
				otherwise
			end;
			if bullBool then
				exit(doKeyDetect);
			if (BAnd(event.modifiers, controlKey) <> 0) then
				isControl := true
			else
				isControl := false;
			key := CHR(BAnd(event.message, charCodeMask));
			if (gMac.keyboardType < 4) and (BAnd(event.modifiers, optionKey) <> 0) and not (BAnd(event.modifiers, shiftKey) <> 0) then
			begin
				ConOpt2Con(key);
				if key <> ' ' then
					isControl := true;
			end;
			if (ismyBBSwindow(frontWindow) = activeNode) then
			begin
				if not gBBSwindows[activeNode]^.scrollFreeze then
				begin
					if myTrans.active then
					begin
						if (key = char(3)) then
							AbortTrans;
					end
					else
					begin
						lastKeyPressed := tickCount;
						timeFlagged := false;
						if (BoardMode = User) and (BoardSection = EXTERNAL) and (activeUserExternal > 0) and rawStdin then
						begin
							curPrompt := key;
							CallUserExternal(RAWCHAR, activeUserExternal);
						end
						else if ((key > char(31)) or ((key = char(8)) or (key = char(13)))) and (BoardMode = User) and (BoardAction <> ListText) then
						begin
							SetHandleSize(handle(sysopKeyBuffer), GetHandleSize(handle(sysopKeyBuffer)) + 1);
							sysopKeyBuffer^^[getHandleSize(handle(sysopKeyBuffer)) - 1] := key;
						end
						else
							doSysopKey(key, isControl);
					end;
				end
				else
				begin
					SetPort(gBBSwindows[activeNode]^.ansiPort);
					SetCtlValue(gBBSwindows[activeNode]^.ansiVScroll, GetCtlMax(gBBSwindows[activeNode]^.ansiVScroll));
					InvalRect(gBBSwindows[activeNode]^.ansiPort^.portRect);
					gBBSwindows[activeNode]^.scrnTop := 24 - gBBSwindows[activeNode]^.scrnLines;
					gBBSwindows[activeNode]^.scrnBottom := 24;
					gBBSwindows[activeNode]^.scrollFreeze := false;
				end;
			end;
		end;
	end;
end.