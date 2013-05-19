{ Segments: HUtils7_1 }
unit HUtils7;

interface
	uses
		Processes, AppleTalk, ADSP, Serial, Sound, TCPTypes, Initial, NodePrefs, NodePrefs2, InpOut4, InpOut3, inpout2, InpOut, ChatroomUtils, User, terminal, SystemPrefs, Message_Editor, Import, fileTrans, FileTrans2, HUtils2, HermesUtils, notification, PPCToolbox, Processes, EPPC, AppleEvents, HUtils3, HUtils5, HUtils6, Telnet;

	procedure IdleUser;
	procedure PixelToBBSPos (thePixel: point; var thetextpos: point);
	procedure HighlightChar (whichChar: point);
	procedure HandleSelection (aPoint: point; theEvent: EventRecord);
	procedure VActionProc (control: ControlHandle; part: INTEGER);
	procedure StartSS;
	procedure EndSS;
	procedure DrawSSInfo;
	procedure OpenSSLock;
	procedure UpdateSSLock (theWindow: windowPtr);
	procedure DoSSLock (theEvent: EventRecord; itemHit: integer);
	procedure CloseSSLock (GotIt: boolean);

implementation
	const
		GrayRgn = $09EE;
		MBarHeight = $0BAA;

	type
		RgnHdlPtr = ^RgnHandle;
		WordPtr = ^INTEGER;
	var
		ourProcess, savedFProcess: ProcessSerialNumber;

{$S HUtils7_1}
	procedure StartSS;
		var
			screenRgn, savedGray, newGray: RgnHandle;
			same: boolean;
	begin
		screenSaver := true;
		if (gMac.systemVersion >= $0700) then
		begin
			result := GetFrontProcess(savedFProcess);
			result := GetCurrentProcess(ourProcess);
			result := SameProcess(savedFProcess, ourProcess, same);
			if not same then
				result := SetFrontProcess(ourProcess);
		end;
		gMBarHeight := WordPtr(MBarHeight)^;
		WordPtr(MBarHeight)^ := 0;
		screenRgn := NewRgn;
		RectRgn(screenRgn, screenBits.bounds);
		savedGray := RgnHdlPtr(GrayRgn)^;
		newGray := NewRgn;
		UnionRgn(screenRgn, savedGray, newGray);
		RgnHdlPtr(GrayRgn)^ := newGray;
		ssWind := NewWindow(nil, screenBits.bounds, '', true, 2, pointer(-1), false, 0);
		SetPort(ssWind);
		BackColor(blackColor);
		EraseRect(screenBits.bounds);
		RgnHdlPtr(GrayRgn)^ := savedGray;
		DisposeRgn(newGray);
		HideCursor;
		lastSSDraw := 0;
	end;

	procedure EndSS;
		var
			clobberedRgn: RgnHandle;
			savePort: GrafPtr;
			wMgrPort: GrafPtr;
	begin
		screenSaver := false;
		WordPtr(MBarHeight)^ := gMBarHeight;
		if (gMac.systemVersion >= $0700) then
			result := SetFrontProcess(savedFProcess);
		DisposeWindow(ssWind);
		ssWind := nil;
		HiliteMenu(0);
		DrawMenuBar;
		ShowCursor;
	end;

	procedure DrawSSInfo;
		const
			maxNodesPerColumn = 25;
		var
			infoStr: array[1..MAX_NODES] of str255;
			ts: str255;
			i, maxLen, b, numUsersOn, nodesDrawn: integer;
			stp: point;
	begin
	{ Find out how many users are online. }
		numUsersOn := 0;
		for i := 1 to InitSystHand^^.numNodes do
			if (theNodes[i]^.boardMode = User) or (theNodes[i]^.boardMode = answering) then
				numUsersOn := numUsersOn + 1;

	{ Prepare ourselves for drawing. }
		SetPort(ssWind);
		BackColor(blackColor);
		ForeColor(whiteColor);
		EraseRect(screenBits.bounds);

	{ Set the font and size. }
		TextFont(0);
		TextSize(16);

	{ Draw the stat lines if there are no users online. }
		if numUsersOn = 0 then
		begin
		{ Build the stat strings. }
			infoStr[1] := stringOf('C: ', doNumber(TotalCalls), ' • T: ', doNumber(TotalMins), ' • P: ', TotalPosts : 0, ' • F: ', numFeedbacks : 0, ' • U: ', TotalUls : 0, '/', TotalFuls : 0, ' • D: ', TotalDls : 0, '/', TotalFDls : 0);
			infoStr[2] := stringOf('MF: ', doNumber(FreeMem div 1024), 'k • DF: ', doNumber(FreeK(sharedPath) div 1024), 'k • LU: ', InitSystHand^^.lastUser);

		{ Figure out which string is longer and set the maxLen. }
			if StringWidth(infoStr[1]) > StringWidth(infoStr[2]) then
				maxLen := StringWidth(infoStr[1])
			else
				maxLen := StringWidth(infoStr[2]);

		{ Position our text. }
			SetPt(stp, 0, 0);
			b := (screenbits.bounds.right - maxLen);
			if b > 0 then
				stp.h := (ABS(RANDOM) mod b) + 1;
			b := (screenbits.bounds.bottom - (2 * 20)); { 2 = num lines }
			if b > 0 then
				stp.v := (ABS(RANDOM) mod b) + 16;

		{ Draw our stat lines. }
			MoveTo(stp.h, stp.v);
			DrawString(infoStr[1]);
			stp.v := stp.v + 20;

			MoveTo(stp.h, stp.v);
			DrawString(infoStr[2]);
			stp.v := stp.v + 20;
		end
		else
	{ There are users online; draw the node information. }
		begin
		{ Get all of the info strings. }
			maxLen := 0;
			for i := 1 to InitSystHand^^.numNodes do
			begin
				NumToString(i, infoStr[i]);
				case (theNodes[i]^.boardMode) of
					waiting: 
						infoStr[i] := '';
					failed: 
						infoStr[i] := 'Initialization failed';
					terminal: 
						infoStr[i] := 'Terminal';
					answering: 
						infoStr[i] := concat(infoStr[i], ': Logon in progress');
					user: 
					begin
						if theNodes[i]^.thisUser.userNum > 0 then
						begin
							infoStr[i] := concat(infoStr[i], ': ', theNodes[i]^.thisUser.userName);
							ts := WhatUser(i);
							infoStr[i] := concat(infoStr[i], ' : ', ts);
							if theNodes[i]^.triedChat then
								infoStr[i] := concat(infoStr[i], ', CHAT: ', theNodes[i]^.chatreason);
						end
						else
							infoStr[i] := concat(infoStr[i], ': Logon in progress');
					end;
					otherwise
				end;

		{ Figure out which string is longer and set the maxLen. }
				b := StringWidth(infoStr[i]);
				if (b > maxLen) then
					maxLen := b;
			end;

		{ Position our text. }
			SetPt(stp, 0, 0);
			i := numUsersOn div maxNodesPerColumn;
			if numUsersOn mod maxNodesPerColumn <> 0 then
				i := i + 1;
			b := (screenbits.bounds.right - (i * (maxLen + 10)));
			if b > 0 then
				stp.h := (ABS(RANDOM) mod b) + 1;
			b := (screenbits.bounds.bottom - (maxNodesPerColumn * 20));
			if b > 0 then
				stp.v := (ABS(RANDOM) mod b) + 16;

		{ Draw our stat lines. }
			nodesDrawn := 0;
			for i := 1 to InitSystHand^^.numNodes do
			begin
				if infoStr[i] <> '' then
				begin
					MoveTo(stp.h, stp.v);
					DrawString(infoStr[i]);

				{ Add one to the nodes-drawn count and adjust the horizontal and vertical }
				{ position accordingly. }
					nodesDrawn := nodesDrawn + 1;
					if nodesDrawn mod maxNodesPerColumn = 0 then
					begin
						stp.h := stp.h + maxLen + 10;
						stp.v := stp.v - ((maxNodesPerColumn - 1) * 20);
					end
					else
						stp.v := stp.v + 20;
				end; { if }
			end; { for }
		end; { if }

	{ Update our lastSSDraw timer. }
		lastSSDraw := TickCount;
	end;

	procedure OpenSSLock;
	begin
		if SSLockDlg = nil then
		begin
			SSLockDlg := GetNewDialog(260, nil, Pointer(-1));
			SetPort(SSLockDlg);
			SetGeneva(SSLockDlg);
			DrawDialog(SSLockDlg);
			ForeColor(BlueColor);
			BackColor(WhiteColor);
			SetTextBox(SSLockDlg, 3, '• Hermes II Screen Saver Lock •');
			ForeColor(BlackColor);
			SelIText(SSLockDlg, 2, 0, 32767);
			SSCount := tickcount;
		end
		else
			SelectWindow(SSLockDlg);
	end;

	procedure UpdateSSLock;
		var
			SavedPort: GrafPtr;
	begin
		if (SSLockDlg <> nil) and (theWindow = SSLockDlg) then
		begin
			GetPort(SavedPort);
			SetPort(SSLockDlg);
			DrawDialog(SSLockDlg);
			ForeColor(BlueColor);
			BackColor(WhiteColor);
			SetTextBox(SSLockDlg, 3, '• Hermes II Screen Saver Lock •');
			ForeColor(BlackColor);
			SetPort(SavedPort);
		end;
	end;

	procedure CloseSSLock;
	begin
		if (SSLockDlg <> nil) then
		begin
			DisposDialog(SSLockDlg);
			SSLockDlg := nil;
		end;
		if GotIt then
			EndSS
		else
			DrawSSInfo;
		SSCount := 0;
	end;

	procedure DoSSLock;
		var
			s1, s2: str255;
			n: integer;
	begin
		n := 2;
		if (SSLockDlg <> nil) and (SSLockDlg = FrontWindow) then
		begin
			case itemHit of
				1: 
				begin
					s2 := copy(InitSystHand^^.realSerial, 1, 10);
					s1 := GetTextBox(SSLockDlg, 4);
					if s1 = InitSystHand^^.OverridePass then
						CloseSSLock(true)
					else if s1 = s2 then
						CloseSSLock(true)
					else
					begin
						SysBeep(0);
						CloseSSLock(false);
					end;
				end;
				otherwise
					;
			end;
		end;
	end;

	procedure VActionProc (control: ControlHandle; part: INTEGER);
		var
			amount: INTEGER;
			window: WindowPtr;
			theT: TEHandle;
	begin
		if part <> 0 then
		begin
			window := control^^.contrlOwner;
			theT := TEHandle(windowPeek(window)^.refCon);
			case part of
				inUpButton, inDownButton: 
					amount := 1;												{one line}
				inPageUp, inPageDown: 
					amount := (theT^^.viewRect.bottom - theT^^.viewRect.top) div theT^^.lineHeight;	{one page}
				otherwise
			end;
			if (part = inDownButton) | (part = inPageDown) then
				amount := -amount;												{reverse direction}
			CommonAction(control, amount);
			if amount <> 0 then
				TEPinScroll(0, amount * theT^^.lineHeight, theT);
		end;
	end; {VActionProc}


	procedure IdleUser;
		var
			tempLong, tempLong2: longint;
			i, b: integer;
			savePort: GrafPtr;
			tempstring: str255;
			mysavedBD: BDact;
	begin
		with curglobs^ do
		begin
			if (BoardMode = User) and not sysopLogon and (hangingUp < 0) then
			begin
				if UserHungUp then	(*Check to see if carrier was lost*)
				begin
					if myTrans.active then  (*If a x-fer was happening then quit sending and clear*)
					begin
						extTrans^^.flags[carrierLoss] := true;
						ClearInBuf;
						repeat
							ContinueTrans;
						until not myTrans.active;
					end;
					if (thisUser.userNum) > 0 then
						sysopLog(RetInStr(2), 6);
					HangupAndReset;
				end;
			end;
			if not myTrans.active then
			begin
				if TabbyPaused then  (* If Mailer Running then check for Activate Node Temp *)
				begin									(* If found Hermes takes control of port *)
					if (length(SavedInPort) > 0) then
					begin
						if FSOpen('ActivateNode.temp', 0, i) = noErr then
						begin
							result := FSClose(i);
							result := FSDelete('ActivateNode.temp', 0);
							CloseComPort;
							InPortName := SavedInPort;
							SavedInPort := '';
							TabbyPaused := false;
							OpenComPort;
							HangUpAndReset;
							doDetermineZMH;
						end;
					end;
				end;
				if hangingUp >= 0 then  (* if hanging up >=0 then User in hangup sequence.*)
					HangUpAndReset;				 (* Otherwise hangingUp := -1 *)
				if ((BoardMode = Failed) and (lastTry + 1800 < tickCount) and (NumFails < 3)) or ((BoardMode = Waiting) and (lastTry + 72000 < tickCount)) then
					HangUpAndReset;  			 (* Check for Modem Initilization Failure*)
				(* If users window is open then draw appropriate stuff in window *)
				i := isMyBBSwindow(frontWindow);
				if (i > 0) and (tickCount > (lastBlink + getCaretTime)) then
				begin
					if not gBBSwindows[i]^.scrollFreeze and (visibleNode = activeNode) then
					begin
						if (gBBSwindows[i]^.cursorRect.top > gBBSwindows[i]^.ansiRect.top) and (gBBSwindows[i]^.cursorRect.right <= gBBSwindows[i]^.ansiRect.right) then
						begin
							GetPort(savePort);
							with gBBSwindows[i]^ do
							begin
								SetPort(ansiPort);
								InvertRect(cursorRect);
								if cursorOn then
									cursorOn := False
								else
									cursorOn := True;
							end;
							lastBlink := tickCount;
							SetPort(savePort);
						end;
					end;
				end;
				if (toBeSent <> nil) then  (* Is there anything that has to be outputted *)
				begin
					if (nodeType = 3) then
					begin
						if (TCPControlBlockPtr(nodeTCPPBPtr)^.ioResult <> 1) then
							if AsyncMWrite(outputRef, 0, nil) <> noErr then
								;
					end
					else if (nodeType = 2) then
					begin
						if (nodeDSPWritePtr^.ioResult <> 1) then
							if AsyncMWrite(outputRef, 0, nil) <> noErr then
								;
					end
					else if (nodeType = 1) then
					begin
						if (myBlocker.ioResult <> 1) then
							if AsyncMWrite(outputRef, 0, nil) <> noErr then
								;
					end;
				end;
				if (BoardMode = Answering) then  (* Check for timeout when answering *)
				begin
					if (BoardSection = TelnetNegotiation) then
						DoTelnetNegotiation
					else if (tickCount > (lastKeyPressed + 14400)) then
						HangUpAndReset;
				end
				else if (BoardMode = Terminal) then
				begin
					if dialing and not waitdialresponse then
						doDialIdle;
				end
				else if (BoardMode = User) and (hangingUp < 0) then  (*Standard Conditions*)
				begin
					if BoardSection = External then
						if myExternals^^[activeUserExternal].GameIdle then
							if GameIdleOn then
								CallUserExternal(GAMEIDLE, activeUserExternal);
					if prompting then
					begin
						if (BoardSection <> Post) and (BoardSection <> Email) and (BoardSection <> NewUser) and (BoardSection <> Logon) then
						begin
							if (ticksLeft(activeNode) <= 0) then    (*Check out of time*)
							begin
								sysopLog(concat('      ', RetInStr(3)), 0);
								ClearScreen;
								bCR;
								OutLine(RetInStr(3), true, 0);
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
								BoardSection := OffStage;
								SetBookMark;
							end;
						end;
					end;
					tempLong := tickCount;
					if timeFlagged then		(* Check another timeout *)
					begin
						if (tempLong > (lastKeyPressed + longint(timeout * 60 * 60))) then
						begin
							timeFlagged := false;
							OutLine(RetInStr(6), true, 6);
							OutLine('', false, 0);
							bCR;
							Delay(30, tempLong);
							sysopLog('      ***TIMEOUT***', 0);
							HangupAndReset;
							exit(idleUser);
						end;
					end
					else if (tempLong > (lastkeyPressed + longint((timeOut * 60 * 60) div 2))) then
					begin  (* User Not Hit key within timeout time in NodePrefs *)
						if (sysopStop or (not inZScan and not continuous and not ((BoardSection = ListFiles) and (ListDo = ListFour)) and not (BoardAction = Repeating))) and not TimeFlagged then
						begin
							NumToString(timeout, tempstring);
							if (BoardSection = Chatroom) then
								ChatroomSingle(activeNode, false, true, concat(RetInStr(4), tempstring, RetInStr(5)))
							else
							begin
								mySavedBD := BoardAction;
								BoardAction := none;
								bCR;
								OutChr(char(7));
								OutLine(concat(RetInStr(4), tempstring, RetInStr(5)), false, 6);
								if thisUser.TerminalType = 1 then
									dom(0);
								bCR;
								BoardAction := mySavedBD;
								if (BoardAction = Writing) then
									ListLine(online)
								else if boardAction = Prompt then
									ReprintPrompt;
							end;
							timeFlagged := true;
						end;
					end;
					if (myBlocker.ioResult <> 1) and (BoardAction = ListText) then (* Output text file*)
						ListTextFile
					else if ((BoardAction = none) or (BoardAction = Repeating)) then
						if not SysopStop then    (*Run through BookMark*)
							SetBookmark;
					if ((BoardAction <> ListText) and (lnsPause >= thisUser.ScrnHght)) or ((BoardAction = ListText) and (lnsPause >= (thisUser.ScrnHght - 1))) then  (*Determine if pause needed *)
					begin
						if (thisUser.PauseScreen and not listingHelp and not continuous and not inZScan) or (lnsPause >= 29999) then
						begin
							if BoardAction <> ListText then
								bCR;
							savedBdAction := BoardAction;
							InPause := true;
							PAUSEPrompt(RetInStr(7));
						end;
					end;
				end;
				if (hangingUp < 0) then  (*Do incoming chars*)
				begin
					tempLong := GetHandleSize(handle(sysopkeyBuffer));
					if tempLong > 0 then  (*Check sysopkey buffer first *)
					begin
						i := 0;
						while (i < tempLong) and (BoardAction <> none) and (BoardAction <> ListText) do
						begin
							doSysopKey(sysopKeyBuffer^^[i], false);  (*Send individual keys to routine.*)
							i := i + 1;
						end;
						BlockMove(pointer(ord4(sysopKeyBuffer^) + i), pointer(sysopKeyBuffer^), GetHandleSize(handle(sysopKeyBuffer)) - i);
						SetHandleSize(handle(sysopKeyBuffer), getHandleSize(handle(sysopKeyBuffer)) - i);
					end;
					if not stopRemote then  (* If Squelch user from User Menu not selected *)
					begin
						if not sysopLogon then
							CheckForChars;				(* Read out of serial port buffer *)
						if (BoardMode = Terminal) and (XferAutoStart = 2) then
						begin
							if XFerAutoStart = 2 then
								DoMenuCommand(longint($03F10007));
							XferAutoStart := 0;
						end;
						i := length(typeBuffer);
						if i > 0 then
						begin
							if (i > 80) then  (* Only handle 80 chars at once for multiuser friendliness *)
								i := 80;
							b := 1;
							while (b <= i) and (BoardAction <> none) and (BoardAction <> ListText) do
							begin
								doSerialChar(typeBuffer[b]);	(*Check buffer 1 char at a time *)
								b := b + 1;
							end;
							if (b > 1) then
								delete(typeBuffer, 1, b - 1);  (*Delete checked chars from the buffer *)
						end;
					end;
				end;
			end
			else
				ContinueTrans;  (*If myTrans.active then continue transferring *)
		end;
	end;
end.