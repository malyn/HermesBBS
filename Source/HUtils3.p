{ Segments: HUtils3_1 }
unit HUtils3;


interface

	uses
		AppleTalk, ADSP, Serial, Sound, TCPTypes, Initial, LoadAndSave, SystemPrefs, Import, User, InpOut4, InpOut3, inpOut2, Quoter, InpOut, HUtils2, HermesUtils, FileTrans, FileTrans2, FileTrans3, Message_Editor, nodeprefs, nodeprefs2, terminal, notification, PPCToolbox, Processes, EPPC, AppleEvents;

	procedure ChangeDefaults;
	procedure MultiNodeChat;
	procedure DoBatchCommands;
	procedure ChangeColors;
	function HandleAEOpenDoc (theAppleEvent, reply: AppleEvent; handlerRefcon: LongInt): OSErr;
	function HandleAEQuitApp (theAppleEvent, reply: AppleEvent; handlerRefcon: LongInt): OSErr;
	function HandleAEHLogoff (theAppleEvent, reply: AppleEvent; handlerRefcon: LongInt): OSErr;
	function HandleAEReleaseNode (theAppleEvent, reply: AppleEvent; handlerRefcon: LongInt): OSErr;
	function HandleAENeedNode (theAppleEvent, reply: AppleEvent; handlerRefcon: LongInt): OSErr;
	procedure HandleAENodeAvail;
	procedure HandleAECrashmail;

implementation

{$S HUtils3_1 }
	function HandleAEQuitApp (theAppleEvent, reply: AppleEvent; handlerRefcon: LongInt): OSErr;
	begin
		quit := 2;
		HandleAEQuitApp := 0;
	end;

	function HandleAEHLogoff (theAppleEvent, reply: AppleEvent; handlerRefcon: LongInt): OSErr;
		var
			i: integer;
	begin
		for i := 1 to InitSystHand^^.numNodes do
		begin
			curGlobs := theNodes[i];
			activeNode := i;
			with curGlobs^ do
			begin
				if myTrans.active then
				begin
					extTrans^^.flags[carrierLoss] := true;
					ClearInBuf;
					repeat
						ContinueTrans;
					until not myTrans.active;
				end;
				if (thisUser.userNum) > 0 then
					sysopLog('      Logged off by AppleEvent.', 6);
				HangupAndReset;
			end;
		end;
		HandleAEHLogoff := 0;
	end;

	function HandleAEOpenDoc (theAppleEvent, reply: AppleEvent; handlerRefcon: LongInt): OSErr;
		var
			myFSS: FSSpec;
			docList: AEDescList;
			myErr: OSErr;
			index, itemsInList: LongInt;
			actualSize: Size;
			keywd: AEKeyword;
			returnedType: DescType;
			t1: str255;
			myFInfo: FInfo;
	begin
		myErr := AEGetParamDesc(theAppleEvent, keyDirectObject, typeAEList, docList);
{    myErr := MyGotRequiredParams(theAppleEvent);}
		if myErr <> noErr then
		begin
			HandleAEOpenDoc := myErr;
			Exit(HandleAEOpenDoc);
		end;
		myErr := AECountItems(docList, itemsInList);
		for index := 1 to itemsInList do
		begin
			myErr := AEGetNthPtr(docList, index, typeFSS, keywd, returnedType, @myFSS, Sizeof(myFSS), actualSize);
			t1 := PathNameFromDirID(myFSS.parID, myFSS.vRefNum);
			result := GetFInfo(concat(t1, myFSS.name), 0, myFInfo);
			if (myFInfo.fdType = 'MODR') then
			begin
				OpenModemFile(concat(t1, myFSS.name));
			end
			else if (myFInfo.fdType = 'TEXT') then
				OpenTextWindow(t1, myFSS.name, false, true);
		end;
		myErr := AEDisposeDesc(docList);
		HandleAEOpenDoc := noErr;
	end;

	function HandleAEReleaseNode (theAppleEvent, reply: AppleEvent; handlerRefcon: LongInt): OSErr;
	begin
		{The node is available reclaim}
		curGlobs := theNodes[Mailer^^.MailerNode];
		activeNode := Mailer^^.MailerNode;
		with curglobs^ do
		begin
			CloseComPort;

			InPortName := SavedInPort;
			SavedInPort := '';

			OpenComPort;
			TabbyPaused := false;
			HangUpAndReset;
			doDetermineZMH;
		end;
		HandleAEReleaseNode := noErr;
	end;

	function HandleAENeedNode (theAppleEvent, reply: AppleEvent; handlerRefcon: LongInt): OSErr;
	begin
		dailytabbyTime := dailytabbytime + 86400;
		curGlobs := theNodes[Mailer^^.MailerNode];
		activeNode := Mailer^^.MailerNode;
		if (curglobs^.BoardMode <> Waiting) then
		begin
			with curGlobs^ do
			begin
				if myTrans.active then
				begin
					repeat
						extTrans^^.flags[carrierLoss] := true;
						ContinueTrans;
					until not myTrans.active;
				end;
				HangUpAndReset;
			end;
		end;
		HandleAENodeAvail;
		HandleAENeedNode := noErr;
	end;

	procedure HandleAENodeAvail;
		var
			targetAddress: AEAddressDesc;
			result: OSErr;
			TheEvent, reply: AppleEvent;
			MySig: OSType;
			finalTicks: longint;
	begin
		curGlobs := theNodes[Mailer^^.MailerNode];
		activeNode := Mailer^^.MailerNode;
		with curglobs^ do
		begin
			TabbyQuit := NotTabbyQuit;
			TabbyPaused := true;
			CloseComPort;
			Delay(15, finalTicks);
			SavedInPort := InportName;
			InPortName := '';
			OpenComPort;
			GoWaitMode;
		end;
		MySig := 'SRC9';
		result := AECreateDesc(typeApplSignature, @MySig, SizeOf(MySig), targetAddress);
		result := AECreateAppleEvent(Fido_Class, Fido_NodeAvail, targetAddress, kAutoGenerateReturnID, kAnyTransactionID, TheEvent);
		result := AESend(TheEvent, reply, kAENoReply, kAENormalPriority, kAEDefaultTimeOut, nil, nil);
		result := AEDisposeDesc(targetAddress);
	end;

	procedure HandleAECrashmail;
		var
			targetAddress: AEAddressDesc;
			result: OSErr;
			TheEvent, reply: AppleEvent;
			MySig: OSType;
			finalTicks: longint;
	begin
		with curglobs^ do
		begin
			TabbyQuit := NotTabbyQuit;
			CloseComPort;
			Delay(15, finalTicks);
			TabbyPaused := true;
			SavedInPort := InportName;
			InPortName := '';
			OpenComPort;
			GoWaitMode;
		end;
		MySig := 'SRC9';
		result := AECreateDesc(typeApplSignature, @MySig, SizeOf(MySig), targetAddress);
		result := AECreateAppleEvent(Fido_Class, Fido_CrashMail, targetAddress, kAutoGenerateReturnID, kAnyTransactionID, TheEvent);
		result := AESend(TheEvent, reply, kAENoReply, kAENormalPriority, kAEDefaultTimeOut, nil, nil);
		result := AEDisposeDesc(targetAddress);
	end;

	procedure MultiNodeChat;
		var
			te1, te2: str255;
			i: integer;
	begin
		with curglobs^ do
		begin
			case MultiChatDo of
				Mult1: 
				begin
					i := length(thisUser.userName) + 2;
					LettersPrompt('> ', '', 79 - i, false, true, false, char(0));
					curprompt := excess;
					OutLine(excess, false, 0);
					excess := '';
					MultiChatDo := Mult2;
				end;
				Mult2: 
				begin
					if length(curPrompt) > 0 then
					begin
						if curPrompt[1] = '/' then
						begin
							if equalString('/X', curPrompt, false, false) then
							begin
								numToString(thisUser.userNum, te1);
								MultiChatOut(concat(thisUser.userName, ' #', te1, ' has left.'), false);
								OutLine(RetInStr(101), true, 1);
								goHome;
							end
							else if equalString('/U', curPrompt, false, false) then
							begin
								OutLine(RetInStr(102), true, 2);
								for i := 1 to InitSystHand^^.numNodes do
								begin
									if not (theNodes[i]^.nodeType < 0) then
									begin
										if (theNodes[i]^.boardMode = User) and (theNodes[i]^.thisUser.userNum > 0) then
										begin
											te1 := theNodes[i]^.thisUser.userName;
											NumToString(i, te2);
											OutLine(concat(te2, '. ', te1), true, 0);
											if (theNodes[i]^.BoardSection = MultiChat) then
												OutLine(RetInStr(103), false, 1);
										end;
									end;
								end;
								bCR;
								MultiChatDo := Mult1;
							end
							else if equalString('/H', curprompt, false, false) then
							begin
								bufferIt(RetInStr(104), true, 2);
								bufferIt(RetInStr(105), true, 1);
								bufferIt(RetInStr(106), true, 1);
								bufferIt(RetInStr(107), true, 1);
								bufferbCR;
								ReleaseBuffer;
								MultiChatDo := Mult1;
							end
							else
								MultiChatDo := Mult1;
						end
						else
						begin
							MultiChatOut(curPrompt, true);
							MultiChatDo := Mult1;
						end;
					end
					else
						MultiChatDo := Mult1;
				end;
				otherwise
			end;
		end;
	end;

	procedure DoBatchCommands;
		label
			100;
		var
			tstr, t2: str255;
			tempLong: longint;
			i: integer;
	begin
		with curglobs^ do
		begin
			case BatDo of
				BatOne: 
				begin
					if FileTransit^^.numFiles > 0 then
					begin
						bCR;
						BCR;
						if (fileTransit^^.sendingbatch) then
							LettersPrompt(RetInStr(108), 'LDRCQ', 1, true, false, true, char(0))
						else
							LettersPrompt(RetInStr(148), 'LURCQ', 1, true, false, true, char(0));
						BatDo := BatTwo;
					end
					else
					begin
						OutLine(RetInStr(109), true, 0);
						GoHome;
					end;
				end;
				BatTwo: 
				begin
					if length(curPrompt) > 0 then
					begin
						case curprompt[1] of
							'D', 'U': 
							begin
								if not sysopLogon then
								begin
									if (fileTransit^^.sendingBatch) then
									begin
										if DLratioOK then
										begin
											if (fileTransit^^.batchTime * 60) <= ticksLeft(activeNode) then
											begin
100:
												bCR;
												YesNoQuestion(RetInStr(110), false);
												BatDo := BatEight;
											end
											else
											begin
												OutLine(RetInStr(111), true, 0);
												BatDo := BatOne;
											end;
										end
										else
										begin
											BatDo := BatOne;
											OutLine(RetInStr(112), true, 0);
										end;
									end
									else
										goto 100;
								end
								else
								begin
									OutLine(RetInStr(113), true, 0);
									BatDo := BatOne;
								end;
							end;
							'R': 
							begin
								bCR;
								NumbersPrompt(stringOf('Remove which(1-', FileTransit^^.numFiles : 0, ') ?'), '', fileTransit^^.numFiles, 1);
								BatDo := BatFour;
							end;
							'C': 
							begin
								bCR;
								YesNoQuestion(RetInStr(149), false);
								BatDo := BatThree;
							end;
							'L': 
							begin
								NumToString(fileTransit^^.numFiles, tstr);
								t2 := secs2time(fileTransit^^.batchTime);
								if (fileTransit^^.sendingBatch) then
									OutLine(concat('Batch: Files - ', tstr, '  Time - ', t2), true, 0)
								else
									OutLine(concat('Batch: Files - ', tstr), true, 0);
								bCR;
								for i := 1 to fileTransit^^.numFiles do
								begin
									t2 := FileTransit^^.FilesGoing[i].theFile.flName;
									while length(t2) < 32 do
										t2 := concat(t2, ' ');
									t2 := stringOf(i : 2, '. ', t2);
									if not (fileTransit^^.sendingBatch) then
										OutLine(concat(t2, ': ', forums^^[fileTransit^^.filesGoing[i].fromDir].dr[fileTransit^^.filesGoing[i].fromSub].dirname), true, 0)
									else if (currentBaud <> 0) and (nodeType = 1) then
										OutLine(stringOf(t2, secs2Time(fileTransit^^.filesGoing[i].theFile.byteLen div (modemDrivers^^[modemID].rs[rsIndex].effRate div 10)), '   ', (fileTransit^^.filesGoing[i].theFile.byteLen div 1024) : 8, 'k'), true, 0)
									else
										OutLine(StringOf(t2, '00:00:00', '   ', (fileTransit^^.filesGoing[i].theFile.byteLen div 1024) : 8, 'k'), true, 0);
									BatDo := BatOne;
								end;
								OutLine('--- ------------------------------  --------  ----------', true, 0);
								OutLine('                                    ', true, 0);
								if (currentBaud <> 0) and (NodeType = 1) then
									OutLine(stringOf(secs2time(fileTransit^^.BatchTime), '  ', fileTransit^^.batchKBytes : 9, 'k'), false, 0)
								else
									OutLine(StringOf('00:00:00   ', fileTransit^^.batchKBytes : 9, 'k'), false, 0);
							end;
							'Q': 
								GoHome;
							otherwise
								BatDo := BatOne;
						end;
					end
					else
						BatDo := BatOne;
				end;
				BatEight: 
				begin
					if curPrompt = 'Y' then
						AfterHangup := true
					else
						AfterHangup := false;
					if (fileTransit^^.sendingBatch) then
					begin
						crossint1 := -99;
						BoardSection := SlowDevice;
						SlowDo := SlowTwo;
						WasBatch := true;
						crossInt9 := 0;
					end
					else
						BatDo := BatFive;
				end;
				BatFive: 
				begin
					bCR;
					NumToString(fileTransit^^.numFiles, tstr);
					if (fileTransit^^.sendingBatch) then
					begin
						t2 := secs2time(fileTransit^^.batchTime);
						OutLine(concat('Transmitting:  Files - ', tstr, '  Time - ', t2), true, 0);
						bCR;
						myTrans.sending := true;
					end
					else
					begin
						OutLine(concat('Receiving:  Files - ', tstr), true, 0);
						myTrans.sending := false;
						bCR;
					end;
					myTrans.active := true;
					activeProtocol := lastBatch;
					StartTrans;
				end;
				BatSix: 
				begin
					statChanged := true;
					if AFTERhangup then
					begin
						bCR;
						bCR;
						ClearScreen;
						OutLine(RetInStr(114), true, 2);
						BatDo := BatSeven;
						crossInt := 0;
						lastKeyPressed := tickCount;
						lastLastPressed := lastKeyPressed;
						bCR;
					end
					else
						goHome;
				end;
				BatSeven: 
				begin
					if lastKeyPressed = lastlastPressed then
					begin
						if tickCount > (lastkeypressed + (crossInt * 60)) then
						begin
							crossInt := crossInt + 1;
							NumToString(crossint, t2);
							for i := 1 to 5 do
								backspace(1);
							OutLine(concat(t2, '...'), false, 0);
							if crossInt = 10 then
								HangUpandReset;
						end;
					end
					else
						GoHome;
				end;
				BatFour: 
				begin
					StringToNum(curprompt, tempLong);
					if (tempLong > 0) and (tempLong <= FileTransit^^.numFiles) then
					begin
						if (fileTransit^^.sendingBatch) then
						begin
							fileTransit^^.batchKBytes := fileTransit^^.batchKBytes - (fileTransit^^.filesGoing[tempLong].theFile.byteLen div 1024);
							if (currentBaud <> 0) and (nodeType = 1) then
								FileTransit^^.batchTime := fileTransit^^.batchTime - (fileTransit^^.filesGoing[tempLong].theFile.byteLen div (modemDrivers^^[modemID].rs[rsIndex].effRate div 10))
							else
								FileTransit^^.batchTime := 0;
						end;
						FileTransit^^.numFiles := FileTransit^^.numFiles - 1;
						if (tempLong <= FileTransit^^.numFiles) and (fileTransit^^.numFiles > 0) then
						begin
							for i := (tempLong + 1) to (fileTransit^^.numFiles + 1) do
								FileTransit^^.filesGoing[i - 1] := fileTransit^^.filesGoing[i];
						end;
						OutLine('Removed.', true, 0);
						BatDo := BatOne;
					end
					else
					begin
						OutLine('Not in queue.', true, 0);
						BatDo := BatOne;
					end;
				end;
				BatThree: 
				begin
					if curPrompt = 'Y' then
					begin
						FileTransit^^.numFiles := 0;
						FileTransit^^.batchTime := 0;
						FileTransit^^.batchKBytes := 0;
						OutLine('Queue cleared.', true, 0);
						bCR;
					end;
					BatDo := BatOne;
				end;
				otherwise
			end;
		end;
	end;

	procedure ShowDefaults;
		var
			tempString: str255;
	begin
		with curGlobs^ do
		begin
			bCR;
			ClearScreen;
			OutLine(StringOf(RetInStr(367), thisUser.scrnWdth : 0, ' X ', thisUser.scrnHght : 0), false, 0);	{1.  Screen size           : }
			if thisUser.AutoSense then
				tempString := 'Auto Sense'
			else if thisUser.TerminalType = 1 then
				if thisUser.ColorTerminal then
					tempString := 'ANSI Color'
				else
					tempString := 'ANSI Monochrome'
			else
				tempString := 'No ANSI';
			OutLine(concat(RetInStr(368), tempString), true, 0);	{2.  ANSI                  : }
			if thisUser.PauseScreen then
				tempString := 'Yes'
			else
				tempString := 'No';
			OutLine(concat(RetInStr(369), tempString), true, 0);	{3.  Pause on screen       : }
			if thisUser.MailBox then
			begin
				if (pos(',', thisUser.ForwardedTo) = 0) and (pos('@', thisUser.ForwardedTo) = 0) then
				begin
					if FindUser(thisUser.ForwardedTo, tempUser) then
						tempString := StringOf('Forwarded to: ', tempUser.UserName, ' #', tempUser.UserNum : 0)
					else
					begin
						thisUser.MailBox := false;
						tempString := 'No Forwarding';
					end;
				end
				else
					tempString := concat('Forwarded to: ', thisUser.ForwardedTo);
			end
			else
				tempString := 'No Forwarding';
			OutLine(concat(RetInStr(370), tempString), true, 0);	{4.  Mailbox               : }
			if thisUser.screenClears then
				tempString := 'Yes'
			else
				tempString := 'No';
			OutLine(concat(RetInStr(371), tempString), true, 0);	{5.  Screen Clears         : }
			OutLine(RetInStr(372), true, 0);	{6.  Configure Q-scan}
			OutLine(RetInStr(373), true, 0);	{7.  Change password}
			if thisUser.NotifyLogon then
				tempString := 'Yes'
			else
				tempString := 'No';
			OutLine(concat(RetInStr(374), tempString), true, 0);	{8.  Notify login/out      : }
			OutLine(concat(RetInStr(375), thisUser.ComputerType), true, 0);	{9.  Computer type         : }
			if thisUser.ScanAtLogon then
				tempString := 'Yes'
			else
				tempString := 'No';
			OutLine(concat(RetInStr(376), tempString), true, 0);	{10. Scan New Msgs At Logon: }
			OutLine(RetInStr(377), true, 0);	{11. Change Signature}
			if thisUser.Columns then
				tempString := '2 Column'
			else
				tempString := '1 Column';
			OutLine(concat(RetInStr(575), tempString), true, 0);	{12. Column Display Mode   : }
			OutLine(RetInStr(218), true, 0);	{13. Edit Address Book}
			if thisUser.ChatANSI then
				tempString := 'ANSI Chatroom'
			else
				tempString := 'Text Chatroom';
			OutLIne(Concat(RetInStr(219), tempString), true, 0);	{14. Chatroom Type         : }
			if thisUser.MessHeader = MessOn then
				tempString := 'On'
			else if thisUser.MessHeader = MessOff then
				tempString := 'Off'
			else
				tempString := 'On except in Newscan.';
			OutLine(concat(RetInStr(794), tempString), true, 0);	{15. Message Headers       : }
			if thisUser.TransHeader = TransOn then
				tempString := 'On'
			else if thisUser.TransHeader = TransOff then
				tempString := 'Off'
			else
				tempString := 'On except in Newscan.';
			OutLine(concat(RetInStr(795), tempString), true, 0);	{16. Transfer Headers      : }
			if thisUser.TerminalType = 1 then
			begin
				OutLine(RetInStr(378), true, 0);	{17. Change colors}
				Outline(RetInStr(144), true, 0);	{18. Message Text Color    : }
				OutLine('This Color', false, 16);
			end;
			OutLine(RetInStr(379), true, 0);	{Q.  Quit to main menu}
		end;
	end;

	procedure ListColors;
		var
			t11, t12: str255;
	begin
		ANSIcode('0;30;47m');
		Outline('0. Color #0', true, -1);
		ANSICode('0;31;40m');
		OutLine('1. Color #1', true, -1);
		ANSIcode('0;32;40m');
		OutLine('2. Color #2', true, -1);
		ANSIcode('0;33;40m');
		OutLine('3. Color #3', true, -1);
		ANSIcode('0;34;40m');
		OutLine('4. Color #4', true, -1);
		ANSIcode('0;35;40m');
		OutLine('5. Color #5', true, -1);
		ANSIcode('0;36;40m');
		OutLine('6. Color #6', true, -1);
		ANSIcode('0;37;40m');
		OutLine('7. Color #7', true, -1);
		ANSICode('0m');
	end;

	procedure ListSystemColors;
		var
			tempstring, tempstring2: str255;
	begin
		with curGlobs^ do
		begin
			ClearScreen;
			NumToString(InitSystHand^^.foregrounds[0], tempstring);
			NumToString(InitSystHand^^.backGrounds[0], tempString2);
			OutLine(concat(' 0. Default          Color #', tempString, ' on Color #', tempString2), true, 0);
			if InitSystHand^^.intense[0] then
				OutLine(', Intense', false, 0);
			if InitSystHand^^.underlines[0] then
				OutLine(', Underlined', false, 0);
			dom(0);
			NumToString(InitSystHand^^.foregrounds[1], tempstring);
			NumToString(InitSystHand^^.backGrounds[1], tempString2);
			OutLine(concat(' 1. Yes/No           Color #', tempString, ' on Color #', tempString2), true, 1);
			if InitSystHand^^.intense[1] then
				OutLine(', Intense', false, 1);
			if InitSystHand^^.underlines[1] then
				OutLine(', Underlined', false, 1);
			dom(0);
			NumToString(InitSystHand^^.foregrounds[2], tempstring);
			NumToString(InitSystHand^^.backGrounds[2], tempString2);
			OutLine(concat(' 2. Prompt           Color #', tempString, ' on Color #', tempString2), true, 2);
			if InitSystHand^^.intense[2] then
				OutLine(', Intense', false, 2);
			if InitSystHand^^.underlines[2] then
				OutLine(', Underlined', false, 2);
			dom(0);
			NumToString(InitSystHand^^.foregrounds[3], tempstring);
			NumToString(InitSystHand^^.backGrounds[3], tempString2);
			OutLine(concat(' 3. Note             Color #', tempString, ' on Color #', tempString2), true, 3);
			if InitSystHand^^.intense[3] then
				OutLine(', Intense', false, 3);
			if InitSystHand^^.underlines[3] then
				OutLine(', Underlined', false, 3);
			dom(0);
			NumToString(InitSystHand^^.foregrounds[4], tempstring);
			NumToString(InitSystHand^^.backGrounds[4], tempString2);
			OutLine(concat(' 4. Input Line       Color #', tempString, ' on Color #', tempString2), true, 4);
			if InitSystHand^^.intense[4] then
				OutLine(', Intense', false, 4);
			if InitSystHand^^.underlines[4] then
				OutLine(', Underlined', false, 4);
			dom(0);
			NumToString(InitSystHand^^.foregrounds[5], tempstring);
			NumToString(InitSystHand^^.backGrounds[5], tempString2);
			OutLine(concat(' 5. Yes/No Question  Color #', tempString, ' on Color #', tempString2), true, 5);
			if InitSystHand^^.intense[5] then
				OutLine(', Intense', false, 5);
			if InitSystHand^^.underlines[5] then
				OutLine(', Underlined', false, 5);
			dom(0);
			NumToString(InitSystHand^^.foregrounds[6], tempstring);
			NumToString(InitSystHand^^.backGrounds[6], tempString2);
			OutLine(concat(' 6. Notice!          Color #', tempString, ' on Color #', tempString2), true, 6);
			if InitSystHand^^.intense[6] then
				OutLine(', Intense', false, 6);
			if InitSystHand^^.underlines[6] then
				OutLine(', Underlined', false, 6);
			dom(0);
		end;
	end;

	procedure ChangeColors;
		var
			tempInt: longInt;
			tempString, tempString2: Str255;
	begin
		with curglobs^ do
		begin
			case DefaultDo of
				DefaultOne: 
				begin
					ListSystemColors;
					bCR;
					bCR;
					HelpNum := 30;
					NumbersPrompt('Change which (0-6, R=Reset, Q=Quit) : ', 'RQ', 6, 0);
					DefaultDo := DefaultTwo;
				end;
				DefaultTwo: 
				begin
					if length(curPrompt) > 0 then
					begin
						if curPrompt = 'Q' then
						begin
							DoSystRec(true);
							GoHome;
						end
						else if curPrompt = 'R' then
						begin
							YesNoQuestion('Are you sure you wish to reset the system colors? ', false);
							DefaultDo := DefaultEight;
						end
						else
						begin
							StringToNum(curPrompt, tempint);
							if (tempint >= 0) and (tempint <= 6) then
							begin
								crossInt := tempInt;
								ListColors;
								bCR;
								bCR;
								NumbersPrompt('Foreground?', '', 7, 0);
								DefaultDo := DefaultThree;
							end
							else
								GoHome;
						end
					end
					else
						GoHome;
				end;
				DefaultThree: 
				begin
					if length(curPrompt) = 0 then
						DefaultDo := DefaultOne
					else
					begin
						StringToNum(curPrompt, tempInt);
						thisUser.foregrounds[17] := tempint;
						thisUser.blinking[17] := false;
						NumbersPrompt('Background?', '', 7, 0);
						DefaultDo := DefaultFour;
					end;
				end;
				DefaultFour: 
				begin
					if length(curPrompt) = 0 then
						DefaultDo := DefaultOne
					else
					begin
						StringToNum(curPrompt, tempInt);
						thisUser.backGrounds[17] := tempint;
						YesNoQuestion('Intense?', false);
						DefaultDo := DefaultFive;
					end;
				end;
				DefaultFive: 
				begin
					if curPrompt = 'Y' then
						thisUser.intense[17] := true
					else
						thisUser.intense[17] := false;
					YesNoQuestion('Underlined?', false);
					DefaultDo := DefaultSix;
				end;
				DefaultSix: 
				begin
					if curPrompt = 'Y' then
						thisUser.underlines[17] := true
					else
						thisUser.underlines[17] := false;
					bCR;
					NumToString(thisUser.foregrounds[17], tempString);
					NumToString(thisUser.backgrounds[17], tempString2);
					OutLine(concat('Color #', tempString, ' on Color #', tempString2), true, 17);
					if thisUser.intense[17] then
						OutLine(', Intense', false, 17);
					if thisUser.underlines[17] then
						OutLine(', Underlined', false, 17);
					OutLine(' ', false, 0);
					bCR;
					bCR;
					YesNoQuestion('Is this OK? ', false);
					DefaultDo := DefaultSeven;
				end;
				DefaultSeven: 
				begin
					if curPrompt = 'Y' then
					begin
						InitSystHand^^.foregrounds[crossInt] := thisUser.foregrounds[17];
						InitSystHand^^.backgrounds[crossInt] := thisUser.backgrounds[17];
						if thisUser.intense[17] then
							InitSystHand^^.intense[crossInt] := true
						else
							InitSystHand^^.intense[crossint] := false;
						if thisUser.underlines[17] then
							InitSystHand^^.underlines[crossInt] := true
						else
							InitSystHand^^.underlines[crossint] := false;
						if thisUser.blinking[17] then
							InitSystHand^^.blinking[crossInt] := true
						else
							InitSystHand^^.blinking[crossint] := false;
						OutLine('Color saved.', true, 0);
					end
					else
						OutLine('Not saved.', true, 0);
					bCR;
					DefaultDo := DefaultOne;
				end;
				DefaultEight: 
				begin
					if curPrompt = 'Y' then
						ResetSystemColors(InitSystHand);
					DefaultDo := DefaultOne;
				end;
			end;
		end;
	end;

	procedure ListUserColors;
		var
			tempstring, tempstring2: str255;
			i: integer;
	begin
		with curGlobs^ do
		begin
			ClearScreen;
			for i := 0 to 15 do
			begin
				NumToString(thisuser.foregrounds[i], tempstring);
				NumToString(thisUser.backGrounds[i], tempString2);
				if i < 10 then
					OutLine(StringOf(' ', i : 0, '. User Defined     Color #', tempString, ' on Color #', tempString2), true, USERCOLORBASE + i)
				else
					OutLine(StringOf(i : 0, '. User Defined     Color #', tempString, ' on Color #', tempString2), true, USERCOLORBASE + i);
				if thisUser.intense[i] then
					OutLine(', Intense', false, USERCOLORBASE + i);
				if thisUser.underlines[i] then
					OutLine(', Underlined', false, USERCOLORBASE + i);
				dom(0);
			end;
		end;
	end;

	procedure ChangeDefaults;
		var
			tempString, tempString2, ts, BColor, YColor: str255;
			i, x, y, z: integer;
			tempint, col: longInt;
			tempuser2: userRec;
			tb2: boolean;
			TheList: array[1..50] of string[49];
	begin
		with curglobs^ do
		begin
			case DefaultDo of
				DefaultOne: 
				begin
					ShowDefaults;
					bCR;
					bCR;
					DefaultDo := DefaultTwo;
				end;
				DefaultTwo: 
				begin
					HelpNum := 4;
					if thisUser.TerminalType = 1 then
						NumbersPrompt(RetInStr(211), '?Q', 18, 1)
					else
						NumbersPrompt(RetInStr(212), '?Q', 16, 1);
					DefaultDo := DefaultThree;
				end;
				DefaultThree: 
				begin
					DefaultDo := DefaultOne;
					if length(CurPrompt) > 0 then
					begin
						if curPrompt = 'Q' then
							GoHome
						else if curPrompt = '?' then
							DefaultDo := DefaultOne
						else if curPrompt = '1' then
						begin
							bCR;
							NumbersPrompt(RetInStr(700), '', 200, 1);
							DefaultDo := Def14;
						end
						else if curPrompt = '2' then
						begin
							bCR;
							OutLine(RetInStr(578), true, 0);
							OutLine(RetInStr(579), true, 0);
							OutLine(RetInStr(580), true, 0);
							OutLine(RetInStr(581), true, 0);
							OutLine(RetInStr(582), true, 0);
							bCR;
							bCR;
							NumbersPrompt(RetInStr(583), '', 5, 1);
							DefaultDo := Def16;
						end
						else if curPrompt = '3' then
						begin
							YesNoQuestion(RetInStr(238), false);		{Pause each screenfull? }
							DefaultDo := DefaultFour;
						end
						else if curPrompt = '4' then
						begin
							HelpNum := 29;
							YesNoQuestion(RetInStr(239), false);		{Do you want to forward your mail? }
							DefaultDo := DefaultFive;
						end
						else if curPrompt = '5' then
						begin
							if thisUser.screenClears then
								thisUser.screenClears := false
							else
								thisUser.screenClears := True;
							bCR;
							DefaultDo := DefaultOne;
						end
						else if curPrompt = '6' then
						begin
							x := 0;
							PrintForumList;
							bCR;
							bCR;
							HelpNum := 7;
							NumbersPrompt(RetInStr(240), 'Q', crossint1, 1);      {Configure Q-scan for which forum ? }
							DefaultDo := DefaultEleven;
						end
						else if curPrompt = '7' then
						begin
							YesNoQuestion(RetInStr(241), false);	{Change password? }
							DefaultDo := DefaultSeven;
						end
						else if curPrompt = '8' then
						begin
							if thisUser.notifyLogon then
								thisUser.notifyLogon := false
							else
								thisUser.notifyLogon := True;
							bCR;
							DefaultDo := DefaultOne;
						end
						else if curPrompt = '9' then
						begin
							OutLine(RetInStr(213), true, -1);
							bCR;
							LettersPrompt(': ', '', 23, false, false, false, char(0));
							DefaultDo := D25;
						end
						else if curPrompt = '10' then
						begin
							OutLine(RetInStr(215), true, 0);
							bCR;
							bCR;
							if thisUser.ScanAtLogon then
								thisUser.ScanAtLogon := false
							else
								thisUser.ScanAtLogon := True;
							DefaultDo := DefaultOne;
						end
						else if curPrompt = '11' then
						begin
							OutLine(RetInStr(216), true, 0);
							for i := 1 to length(thisUser.Signature) do
							begin
								if thisUser.Signature[i] = char(3) then
								begin
									ts := ThisUser.Signature[i + 1];
									case ts[1] of
										'A': 
											col := 10;
										'B': 
											col := 11;
										'C': 
											col := 12;
										'D': 
											col := 13;
										'E': 
											col := 14;
										'F': 
											col := 15;
										otherwise
											StringToNum(ts, col);
									end;
									i := i + 2;
								end;
								OutLine(ThisUser.Signature[i], false, USERCOLORBASE + col);
							end;
							bcr;
							OutLine(RetInStr(602), true, 0);	{Enter New Signature, Or Return To Abort.  Use Ctrl-P And # For Color.}
							if (ThisUser.TerminalType = 1) and (ThisUser.ColorTerminal) then
								OutputColorBar;
							bcr;
							AnsiPrompt(': ', '', 78, false, false, false, char(0));
							DefaultDo := D26;
						end
						else if curPrompt = '12' then
						begin
							bCR;
							if not thisUser.Columns then
							begin
								OutLine(RetInStr(603), false, 0);	{2 Column Mode Set}
								thisUser.Columns := true;
							end
							else
							begin
								OutLine(RetInStr(604), false, 0);	{1 Column Mode Set}
								thisUser.Columns := false;
							end;
							bCR;
							bCR;
							DefaultDo := DefaultOne;
						end
						else if curPrompt = '13' then
						begin
							HelpNum := 40;
							wasEMail := false;
							wasSearching := false;
							BoardSection := AddrBook;
							ABDo := AB1;
						end
						else if curPrompt = '14' then
						begin
							if thisUser.ChatANSI then
								thisUser.ChatANSI := false
							else
								thisUser.ChatANSI := true
						end
						else if curPrompt = '15' then
						begin
							HelpNum := 41;
							bCR;
							OutLine('Message Headers', true, 2);
							bCR;
							OutLine(RetInStr(796), true, 1);
							OutLine(RetInStr(797), true, 1);
							OutLine(RetInStr(798), true, 1);
							bCR;
							bCR;
							NumbersPrompt(RetInStr(799), '', 3, 1);
							DefaultDo := D29;
						end
						else if curPrompt = '16' then
						begin
							HelpNum := 42;
							bCR;
							OutLine('Transfer Headers', true, 2);
							bCR;
							OutLine(RetInStr(796), true, 1);
							OutLine(RetInStr(797), true, 1);
							OutLine(RetInStr(798), true, 1);
							bCR;
							bCR;
							NumbersPrompt(RetInStr(799), '', 3, 1);
							DefaultDo := D30;
						end
						else if curPrompt = '17' then
						begin
							ListUserColors;
							bCR;
							bCR;
							HelpNum := 30;
							NumbersPrompt(RetInStr(214), 'Q', 15, 0);
							DefaultDo := D18;
						end
						else if curPrompt = '18' then
						begin
							ListColors;
							bCR;
							bCR;
							NumbersPrompt('Foreground: ', '', 7, 0);
							DefaultDo := D24;
						end
						else
							DefaultDo := DefaultOne;
					end
					else
						DefaultDo := DefaultOne;
				end;
				DefaultFour: 
				begin
					if CurPrompt = 'Y' then
						thisUser.PauseScreen := true
					else
						thisUser.PauseScreen := false;
					bCR;
					DefaultDo := DefaultOne;
				end;
				DefaultFive: 
				begin
					if CurPrompt = 'N' then
					begin
						thisUser.MailBox := false;
						thisUser.ForwardedTo := char(0);
						DefaultDo := DefaultOne;
					end
					else
					begin
						bCR;
						if Mailer^^.MailerAware then
							OutLine(RetInStr(242), true, 0)		{Enter User #, Name or Network Address. }
						else
							OutLine(RetInStr(19), true, 0);	{Enter User # or Name.}
						bCR;
						LettersPrompt(': ', '', 45, false, false, true, char(0));
						DefaultDo := DefaultSix;
					end;
				end;
				DefaultSix: 
				begin
					if (pos(',', curPrompt) = 0) and (pos('@', curPrompt) = 0) then
					begin
						if FindUser(CurPrompt, tempUser2) then
						begin
							if thisUser.UserNum = tempUser2.userNum then
								OutLine(RetInStr(632), true, 0)	{You Can Not Forward Mail To Yourself!}
							else
							begin
								thisUser.MailBox := true;
								thisUser.ForwardedTo := StringOf(tempUser2.UserNum : 0);
								OutLine('Saved.', true, 0);
							end;
						end
						else
						begin
							thisUser.MailBox := false;
							thisUser.ForwardedTo := char(0);
							OutLine(RetInStr(633), true, 0);	{Forwarding reset.}
						end;
					end
					else if (curPrompt <> '') and (Mailer^^.MailerAware) then
					begin
						if (pos('@', curPrompt) <> 0) and ((Mailer^^.InternetMail <> FidoGated) and (Mailer^^.InternetMail <> Direct)) then
							OutLine(RetInStr(217), true, 6)	{Sorry, internet mail is not enabled on this BBS}
						else
						begin
							thisUser.MailBox := true;
							thisUser.ForwardedTo := curPrompt;
							OutLine('Saved.', true, 0);
						end;
					end;
					bCR;
					bCR;
					DefaultDo := DefaultOne;
				end;
				DefaultSeven: 
				begin
					if CurPrompt = 'Y' then
					begin
						OutLine(RetInStr(634), true, 0);	{You must now enter your current password.}
						bCR;
						LettersPrompt(': ', '', 9, false, false, true, char(0));
						DefaultDo := DefaultEight;
					end
					else
					begin
						bCR;
						DefaultDo := DefaultOne;
					end;
				end;
				DefaultEight: 
				begin
					if CurPrompt = thisUser.password then
					begin
						bCR;
						OutLine(RetInStr(711), true, 0);	{Enter your new password, 3 to 9 characters long.}
						bCR;
						LettersPrompt(': ', '', 9, false, false, true, 'X');
						DefaultDo := DefaultNine;
					end
					else
					begin
						OutLine('Incorrect.', true, 0);
						bCR;
						bCR;
						DefaultDo := DefaultOne;
					end;
				end;
				DefaultNine: 
				begin
					if length(curPrompt) < 3 then
					begin
						Outline(RetInStr(719), true, 0);	{Your password must be at least 3 characters.}
						bCR;
						curPrompt := thisUser.password;
						DefaultDo := DefaultEight;
					end
					else
					begin
						EnteredPass := CurPrompt;
						OutLine(RetInStr(243), true, 0);	{Repeat password for verification.}
						bCR;
						LettersPrompt(': ', '', 9, false, false, true, 'X');
						DefaultDo := DefaultTen;
					end;
				end;
				DefaultTen: 
				begin
					if EnteredPass = CurPrompt then
					begin
						thisUser.password := CurPrompt;
						GetDateTime(thisUser.lastPWChange);
						OutLine(RetInStr(244), true, 0);	{Password changed.}
						sysopLog('      Changed Password.', 0);
						bCR;
						bCR;
						DefaultDo := DefaultOne;
					end
					else
					begin
						OutLine(RetInStr(635), true, 0);	{VERIFY FAILED.}
						OutLine(RetInStr(245), true, 0);	{Password not changed.}
						bCR;
						bCR;
						DefaultDo := DefaultOne;
					end;
				end;
				DefaultEleven: 
				begin
					if (curPrompt <> 'Q') and (curPrompt <> '') then
					begin
						StringToNum(curPrompt, tempint);
						x := 0;
						for i := 1 to initSystHand^^.numMForums do
							if MForumOk(i) then
							begin
								x := x + 1;
								if x = tempint then
								begin
									configForum := i;
									leave;
								end;
							end;
						if configForum = 0 then
							configForum := 10;
						if (MForumOk(configForum)) and (InitSystHand^^.numMForums >= configForum) then
						begin
							if (thisUser.TerminalType = 1) then
							begin
								BColor := concat(char(27), '[36m');
								YColor := concat(char(27), '[33m');
							end
							else
							begin
								BColor := char(0);
								YColor := char(0);
							end;
							OutLine(RetInStr(246), true, 0);	{Boards to q-scan marked with ''*'''}
							bCR;
							if (thisUser.columns) and (MForum^^[ConfigForum].NumConferences > 5) then
							begin
								x := 0;
								y := -1;
								z := 0;
								for i := 1 to MForum^^[ConfigForum].NumConferences do
									if MConferenceOk(ConfigForum, i) then
										x := x + 1;
								if (x < 50) then
									TheList[x + 1] := char(0);
								if (not odd(x)) then
									x := x - 1;
								for i := 1 to MForum^^[ConfigForum].NumConferences do
									if MConferenceOk(ConfigForum, i) then
									begin
										if y >= x then
											y := 0;
										y := y + 2;
										z := z + 1;
										if (z < 10) and thisUser.WhatNScan[configForum, i] then
											TheList[y] := StringOf('* ', YColor, z : 0, '. ', BColor, MConference[ConfigForum]^^[i].Name, '                                        ')
										else if (z < 10) and not thisUser.WhatNScan[configForum, i] then
											TheList[y] := StringOf('  ', YColor, z : 0, '. ', BColor, MConference[ConfigForum]^^[i].Name, '                                        ')
										else if (z >= 10) and thisUser.WhatNScan[configForum, i] then
											TheList[y] := stringOf('*', YColor, z : 0, '. ', BColor, MConference[ConfigForum]^^[i].Name, '                                        ')
										else
											TheList[y] := stringOf(' ', YColor, z : 0, '. ', BColor, MConference[ConfigForum]^^[i].Name, '                                        ');
										if (thisUser.TerminalType = 0) then
											TheList[y][0] := char(37);
									end;
								z := 1;
								x := x + 1;
								repeat
									bufferIt(concat(TheList[z], '  ', TheList[z + 1]), true, 1);
									z := z + 2;
								until z >= x;
								if odd(x) then
									bufferIt(TheList[x], true, 1);
							end
							else
							begin
								x := 0;
								for i := 1 to MForum^^[ConfigForum].NumConferences do
									if MConferenceOk(ConfigForum, i) then
									begin
										x := x + 1;
										if thisUser.WhatNScan[ConfigForum, i] then
											bufferIt(StringOf('*', x : 2, '. '), true, 2)
										else
											bufferIt(StringOf(' ', x : 2, '. '), true, 2);
										BufferIt(MConference[ConfigForum]^^[i].Name, false, 1);
									end;
							end;
							bufferbCR;
							ReleaseBuffer;
							crossint1 := x;
							DefaultDo := DefaultTwelve;
						end
						else
						begin
							OutLine(RetInStr(247), true, 0);		{Forum not available.}
							bCR;
							bCR;
							DefaultDo := DefaultOne;
						end;
					end
					else
						DefaultDo := DefaultOne;
				end;
				DefaultTwelve: 
				begin
					bCR;
					OutLine(RetInStr(248), true, 0);	{Enter sub-board identifier, or Q to Quit}
					bCR;
					NumbersPrompt('Config: ', 'Q?', crossint1, 1);
					DefaultDo := DefaultThrt;
				end;
				DefaultThrt: 
				begin
					if (CurPrompt <> 'Q') and (curPrompt <> '?') then
					begin
						StringToNum(curPrompt, tempint);
						if (MForum^^[configForum].NumConferences >= tempInt) then
						begin
							tempint := FindConference(configForum, tempint);
							if thisUser.whatNScan[configForum, tempInt] then
								thisUser.whatNScan[configForum, tempInt] := false
							else
								thisUser.whatNScan[configForum, tempInt] := true;
						end;
						DefaultDo := DefaultTwelve;
					end
					else if CurPrompt = 'Q' then
					begin
						curPrompt := '6';
						DefaultDo := DefaultThree;
					end
					else if curPrompt = '?' then
					begin
						NumToString(configForum, curprompt);
						DefaultDo := DefaultEleven;
					end;
				end;
				Def14: 
				begin
					if length(curPrompt) = 0 then
						thisUser.scrnWdth := 80
					else
					begin
						StringToNum(curprompt, tempInt);
						thisUser.scrnWdth := tempInt;
					end;
					bCR;
					NumbersPrompt(RetInStr(701), '', 80, 1);	{How tall is your screen (lines, <CR>=24) ?}
					DefaultDo := Def15;
				end;
				Def15: 
				begin
					if length(curPrompt) = 0 then
						thisUser.scrnHght := 24
					else
					begin
						StringToNum(curprompt, tempInt);
						thisUser.scrnHght := tempInt;
					end;
					bCR;
					bCR;
					DefaultDo := DefaultOne;
				end;
				Def16: 
				begin
					DefaultDo := DefaultOne;
					if (curPrompt = '1') then
					begin
						thisUser.AutoSense := true;
						thisUser.ColorTerminal := true;
						thisUser.TerminalType := 1;
					end
					else if (curPrompt = '2') then
					begin
						thisUser.AutoSense := false;
						thisUser.ColorTerminal := false;
						thisUser.TerminalType := 0;
					end
					else if (curPrompt = '3') then
					begin
						thisUser.AutoSense := false;
						thisUser.ColorTerminal := false;
						thisUser.TerminalType := 1;
					end
					else if (curPrompt = '4') then
					begin
						thisUser.AutoSense := false;
						thisUser.ColorTerminal := true;
						thisUser.TerminalType := 1;
					end
					else if (curPrompt = '5') then
					begin
						OutANSItest;
						bCR;
						OutLine(RetInStr(702), false, 5);		{Is the above line colored, italicized,}
						bCR;
						YesNoQuestion(RetInStr(703), false);	{intense, inversed, or blinking? }
						DefaultDo := Def17;
					end;
				end;
				Def17: 
				begin
					if (curPrompt = 'N') and (thisUser.TerminalType = 1) then
						ANSIcode('0m');
					if curPrompt = 'Y' then
						thisUser.TerminalType := 1
					else
						thisUser.TerminalType := 0;
					bCR;
					if thisUser.TerminalType = 1 then
					begin
						YesNoQuestion(RetInStr(704), false);	{Do you want color? }
					end
					else
						curprompt := 'N';
					DefaultDo := Def18;
				end;
				Def18: 
				begin
					if curPrompt = 'Y' then
						thisUser.ColorTerminal := true
					else
						thisUser.ColorTerminal := false;
					bCR;
					bCR;
					DefaultDo := DefaultOne;
				end;
				D18: 
				begin
					if length(curPrompt) > 0 then
					begin
						if curPrompt <> 'Q' then
						begin
							StringToNum(curPrompt, tempint);
							if (tempint > -1) and (tempint < 16) then
							begin
								crossInt := tempInt;
								ListColors;
								bCR;
								bCR;
								NumbersPrompt('Foreground?', '', 7, 0);
								DefaultDo := D19;
							end
							else
								DefaultDo := DefaultOne;
						end
						else
							DefaultDo := DefaultOne;
					end
					else
						DefaultDo := DefaultOne;
				end;
				D19: 
				begin
					if length(curPrompt) = 0 then
					begin
						curPrompt := '17';
						DefaultDo := DefaultThree;
					end
					else
					begin
						StringToNum(curPrompt, tempInt);
						thisUser.foregrounds[17] := tempint;
						thisUser.blinking[17] := false;
						NumbersPrompt('Background?', '', 7, 0);
						DefaultDo := D20;
					end;
				end;
				D20: 
				begin
					if length(curPrompt) = 0 then
					begin
						curPrompt := '17';
						DefaultDo := DefaultThree;
					end
					else
					begin
						StringToNum(curPrompt, tempInt);
						thisUser.backGrounds[17] := tempint;
						YesNoQuestion('Intense?', false);
						DefaultDo := D21;
					end;
				end;
				D21: 
				begin
					if curPrompt = 'Y' then
						thisUser.intense[17] := true
					else
						thisUser.intense[17] := false;
					YesNoQuestion('Underlined?', false);
					DefaultDo := D22;
				end;
				D22: 
				begin
					if curPrompt = 'Y' then
						thisUser.underlines[17] := true
					else
						thisUser.underlines[17] := false;
					bCR;
					NumToString(thisUser.foregrounds[17], tempString);
					NumToString(thisUser.backgrounds[17], tempString2);
					OutLine(concat('Color #', tempString, ' on Color #', tempString2), true, 17);
					if thisUser.intense[17] then
						OutLine(', Intense', false, 17);
					if thisUser.underlines[17] then
						OutLine(', Underlined', false, 17);
					OutLine(' ', false, 0);
					bCR;
					bCR;
					YesNoQuestion('Is this OK? ', false);
					DefaultDo := D23;
				end;
				D23: 
				begin
					if curPrompt = 'Y' then
					begin
						thisUser.foregrounds[crossInt] := thisUser.foregrounds[17];
						thisUser.backgrounds[crossInt] := thisUser.backgrounds[17];
						if thisUser.intense[17] then
							thisUser.intense[crossInt] := true
						else
							thisuser.intense[crossint] := false;
						if thisUser.underlines[17] then
							thisUser.underlines[crossInt] := true
						else
							thisuser.underlines[crossint] := false;
						if thisUser.blinking[17] then
							thisUser.blinking[crossInt] := true
						else
							thisuser.blinking[crossint] := false;
						OutLine('Color saved.', true, 0);
					end
					else
						OutLine('Not saved.', true, 0);
					bCR;
					DefaultDo := DefaultThree;
					Curprompt := '17';
				end;
				D24: 
				begin
					if curPrompt <> '' then
					begin
						StringToNum(curPrompt, tempint);
						if (tempint > -1) and (tempint < 8) then
						begin
							thisUser.Underlines[16] := false;
							thisUser.Blinking[16] := false;
							thisUser.Foregrounds[17] := tempInt;
							NumbersPrompt('Background?', '', 7, 0);
							DefaultDo := D27;
						end
					end
					else
						DefaultDo := DefaultOne;
				end;
				D25: 
				begin
					if (length(curPrompt) > 0) then
					begin
						thisUser.computerType := curPrompt;
						bCR;
					end;
					DefaultDo := DefaultOne;
				end;
				D26: 
				begin
					if length(curPrompt) > 0 then
						thisUser.Signature := curPrompt;
					DefaultDo := DefaultOne;
					bCR;
				end;
				D27: 
				begin
					if curPrompt <> '' then
					begin
						StringToNum(curPrompt, tempint);
						if (tempint > -1) and (tempint < 8) then
						begin
							thisUser.Backgrounds[16] := tempInt;
							YesNoQuestion('Intense?', false);
							DefaultDo := D28;
						end;
					end
					else
						DefaultDo := DefaultOne;
				end;
				D28: 
				begin
					if curPrompt = 'Y' then
						thisUser.Intense[16] := true
					else
						thisUser.Intense[16] := false;
					thisUser.Foregrounds[16] := thisUser.Foregrounds[17];
					DefaultDo := DefaultOne;
				end;
				D29: 
				begin
					if curPrompt = '1' then
						thisUser.MessHeader := MessOn
					else if curPrompt = '2' then
						thisUser.MessHeader := MessOff
					else if curPrompt = '3' then
						thisUser.MessHeader := MessOnNoNew;
					DefaultDo := DefaultOne;
				end;
				D30: 
				begin
					if curPrompt = '1' then
						thisUser.TransHeader := TransOn
					else if curPrompt = '2' then
						thisUser.TransHeader := TransOff
					else if curPrompt = '3' then
						thisUser.TransHeader := TransOnNoNew;
					DefaultDo := DefaultOne;
				end;
				otherwise
			end;
		end;
	end;
end.