{ Segments: HUtils2_1 }
unit HUtils2;

interface
	uses
		AppleTalk, ADSP, Serial, Sound, TCPTypes, Initial, LoadAndSave, NodePrefs2, NodePrefs, SystemPrefs2, SystemPrefs, Message_Editor2, User, UserManager, Misc, Misc2, Terminal, inpOut4, inpOut3, inpOut2, Quoter, InpOut, ChatroomUtils, Chatroom, FileTrans2, FileTrans, HUtilsOne;


	procedure DoMenuCommand (menuResult: LONGINT; modifiers: integer);
	procedure UnCheckTerm;
	procedure DoMultiMail;
	procedure DoUpMess;
	procedure doTransDefs;
	procedure SwitchNode (toWhich: integer);
	procedure DoDialIdle;


implementation


{$S HUtils2_1}
	procedure SwitchNode (toWhich: integer);
		var
			tempString, t2, t3: str255;
			ThisEditText: TEHandle;
			TheDialogPtr: DialogPeek;
			tempInt, i: integer;
			aHandle: handle;
			temprect: rect;
	begin
		bullBool := true;
		if (toWhich <= InitSystHand^^.numNodes) and (toWhich > 0) then
		begin
			if gBBSwindows[toWhich]^.ansiPort <> nil then
				SelectWindow(gBBSwindows[toWhich]^.ansiPort)
			else
				OpenANSIWindow(toWhich);
			if toWhich <> visibleNode then
			begin
				closeNodePrefs;
				statChanged := true;
				if (theNodes[visibleNode]^.myTrans.active) and (theNodes[visibleNode]^.transDilg <> nil) then
				begin
					DisposDialog(theNodes[visibleNode]^.transDilg);
					theNodes[visibleNode]^.transDilg := nil;
				end;
				result := CallUtility(DISPOSETMENU, ptr(theNodes[visibleNode]^.myProcMenu), 0);
				theNodes[visibleNode]^.myProcMenu := nil;
				visibleNode := toWhich;
				NumToString(visibleNode, tempString);
				curGlobs := theNodes[visibleNode];
				activeNode := visibleNode;
				if gBBSwindows[activeNode]^.ansiPort <> FrontWindow then
					SelectWindow(gBBSwindows[activeNode]^.ansiPort);
				if (theNodes[visibleNode]^.myTrans.active) and InitSystHand^^.useXWind and (gBBSwindows[activeNode]^.ansiPort <> nil) then
				begin
					theNodes[visibleNode]^.TransDilg := GetNewDialog(982, nil, pointer(-1));
					SetPort(theNodes[visibleNode]^.transDilg);
					TextFont(monaco);
					TextSize(9);
					TheDialogPtr := DialogPeek(theNodes[visibleNode]^.transDilg);
					ThisEditText := TheDialogPtr^.textH;
					HLock(Handle(ThisEditText));
					ThisEditText^^.txSize := 9;
					ThisEditText^^.txFont := 4;
					ThisEditText^^.fontAscent := 9;
					ThisEditText^^.lineHeight := 9 + 2 + 0;
					HUnLock(Handle(ThisEditText));

					tempstring := theProts^^.prots[theNodes[visibleNode]^.activeProtocol].ProtoName;
					if theNodes[visibleNode]^.myTrans.sending then
						tempstring := concat(tempstring, ' Send')
					else
						tempstring := concat(tempstring, ' Receive');
					SetWTitle(theNodes[visibleNode]^.transdilg, tempstring);
					GetDItem(theNodes[visibleNode]^.transDilg, 6, tempInt, aHandle, tempRect);
					t2 := theNodes[visibleNode]^.extTrans^^.fPaths[theNodes[visibleNode]^.extTrans^^.filesDone + 1].fname^^;
					i := length(t2);
					t3 := '';
					while (t2[i] <> ':') and (i > 0) do
					begin
						i := i - 1;
					end;
					if t2[i] = ':' then
						t3 := copy(t2, i + 1, length(t2) - i)
					else
						t3 := t2;
					SetIText(aHandle, t3);
					GetDItem(theNodes[visibleNode]^.transDilg, 9, tempInt, aHandle, tempRect);
					SetIText(aHandle, theNodes[visibleNode]^.lastTransError);
					ShowWindow(theNodes[visibleNode]^.transDilg);
					DrawDialog(theNodes[visibleNode]^.transDilg);
					UpdateProgress;
					DisableItem(getMHandle(mDisconnects), 0);
				end
				else
					EnableItem(getMHandle(mDisconnects), 0);
				if (curglobs^.boardMode = Terminal) then
					result := CallUtility(BUILDMENU, pointer(@curglobs^.myProcMenu), longint($03F10000))
				else
					result := CallUtility(BUILDMENU, pointer(@curglobs^.myProcMenu), longint($03F10001));
				if curglobs^.boardMode = User then
					EnableItem(getMHandle(mUser), 0)
				else
					DisableItem(getMHandle(mUser), 0);
				if (curglobs^.boardMode = User) and (curglobs^.triedChat) then
					SetItemStyle(GetMHandle(mUser), 1, [bold])
				else
					SetItemStyle(GetMHandle(mUser), 1, []);
				if curglobs^.boardMode = terminal then
				begin
					EnableItem(getMHandle(mTerminal), 0);
					DisableItem(getMHandle(mSysop), 1);
					DisableItem(getMHandle(mSysop), 2);
					if curglobs^.myTrans.active then
					begin
						DisableItem(getMHandle(1009), 0);
						DisableItem(getMHandle(mTerminal), 0);
					end
					else
					begin
						EnableItem(getMHandle(1009), 0);
						EnableItem(getMHandle(mTerminal), 0);
					end;
				end
				else
				begin
					DisableItem(getMHandle(mTerminal), 0);
					EnableItem(getMHandle(mSysop), 1);
					EnableItem(getMHandle(mSysop), 2);
				end;
				if curglobs^.nodeType = 1 then
					EnableItem(getMHandle(mSysop), 15)
				else
					DisableItem(getMHandle(mSysop), 15);
				if curglobs^.capturing then
					CheckItem(GetMHandle(mFile), 8, true)
				else
					CheckItem(GetMHandle(mFile), 8, false);
				DrawMenuBar;
			end;
		end;
	end;

	procedure UncheckTerm;
		var
			i: integer;
	begin
		for i := 1 to 19 do
			CheckItem(getMHandle(55), i, false);
	end;


	function HU2ProtocolCall (message: integer; ExtRecPtr: ptr; refcon: longint; PP: procptr): OSerr;
	inline
		$205f,  	{   movea.l (a7)+,a0  }
		$4e90;	{	jsr(a0)			   }


	procedure DoDialIdle;
		label
			400;
		var
			alreadyHere: boolean;
			ts: str255;
			i: integer;
	begin
		with curGlobs^ do
		begin
			alreadyHere := false;
400:
			i := 0;
			while (i < MAX_NODES) and ((InitSystHand^^.Bbsdialed[i]) or not (InitSystHand^^.BBsdialIt[i])) do
				i := i + 1;
			if i = MAX_NODES then
			begin
				for i := 0 to MAX_NODES_M_1 do
					InitSystHand^^.Bbsdialed[i] := false;
				if alreadyHere then
					dialing := false
				else
				begin
					alreadyHere := true;
					goto 400;
				end;
			end;
			if dialing and (dialDelay < (tickCount - 200)) then
			begin
				InitSystHand^^.BBsdialed[i] := true;
{    OutLineSysOp(concat('Dialing ', InitSystHand^^.BBsnames[i], '...'), true);}
				ts := concat('ATDT', InitSystHand^^.BBsnumbers[i], char(13));
				result := AsyncMWrite(outputRef, length(ts), @ts[1]);
				waitDialResponse := true;
				frontCharElim := 5;
				crossInt := i;
			end;
		end;
	end;

	procedure PasteSysopBuffer;
		type
			twoChar = packed array[0..1] of char;
			twoChPtr = ^twoChar;
		var
			p, e, lp: twoChPtr;
			l1: longint;
			i: integer;
	begin
		with curGlobs^ do
		begin
			p := pointer(@sysopKeyBuffer^^);
			lp := p;
			e := pointer(ord4(@sysopKeyBuffer^^) + GetHandleSize(handle(sysopKeyBuffer)));
			while (longint(p) < longint(e)) do
			begin
				l1 := 0;
				while (p^[0] <> char(13)) and (longint(p) < longint(e)) do
				begin
					p := pointer(ord4(p) + 1);
					l1 := l1 + 1;
				end;
				if l1 > 0 then
				begin
					for i := 1 to l1 do
						curMessage^^[online] := concat(curMessage^^[online], twoChPtr(ord4(lp) + (i - 1))^[0]);
					ProcessData(activeNode, ptr(lp), l1);
				end;
				if p^[0] = char(13) then
				begin
					p := pointer(ord4(p) + 1);
					bCR;
					onLine := onLine + 1;
					curMessage^^[onLine] := '';
					if (online + 1) > maxLines then
					begin
						e := p;
						OutLine('-= No more lines =-', false, 0);
						OutLine('/ES to save.', true, 0);
						bCR;
						online := online - 1;
					end;
				end;
				lp := p;
			end;
			SetHandleSize(handle(sysopKeyBuffer), 0);
		end;
	end;

	procedure CloseSSLock (GotIt: boolean);
	external;

	procedure errorSerial;
	begin
		ProblemRep('Valid serial number not found.');
	end;

	function RegistrationFilter (dp: DialogPtr; var event: EventRecord; var item: INTEGER): Boolean;
		var
			key: char;
			itemType: INTEGER;
			itemRect: Rect;
			itemHandle: Handle;
			dummy: LONGINT;
	begin
		RegistrationFilter := false;
		if (event.what = keyDown) then
		begin
			key := char(BAnd(event.message, charCodeMask));
			if ((key = char(10)) or (key = char(13))) then
			begin
				item := 5;

				GetDItem(dp, 5, itemType, itemHandle, itemRect);
				if (itemHandle <> nil) then
				begin
					HiliteControl(ControlHandle(itemHandle), inButton);
					Delay(8, dummy);
					HiliteControl(ControlHandle(itemHandle), inButton);
				end;
				RegistrationFilter := true;
			end;
		end;
	end;

	procedure DoMenuCommand;
		label
			47;
		var
			menuID, menuItem, tempint: integer;
			daName, freeMemStr, tempString: Str255;
			daRefNum: integer;
			handledByDA: boolean;
			userPickDilg: DialogPtr;
			tempLong, tempLong2: LongInt;
			tempRect, tempRect2: Rect;
			dType, i: Integer;
			dItem, aHandle: Handle;
			tempPt: point;
			repo: SFReply;
			typeList: SFTypeList;
			mySavedBD: BDAct;
			oldSize, newSize: LongInt;
			tvMenu: menuHandle;
	begin
		with curglobs^ do
		begin
			menuID := HiWrd(menuResult);
			menuItem := LoWrd(menuResult);
			if menuID <> 0 then
			begin
				case menuID of
					mApple: 
						case menuItem of
							1: 
							begin
								OpenAboutBox;
								repeat
								until Button;
								CloseAboutBox;
							end;
							otherwise
							begin
								GetItem(GetMHandle(mApple), menuItem, daName);
								daRefNum := OpenDeskAcc(daName);
							end;
						end;
					mFile: 
						case menuItem of
							1: 
							begin
								SetPt(tempPt, 40, 40);
								SFPutFile(tempPt, 'Please name your text file:', 'Text File', nil, repo);
								if repo.good then
								begin
									result := FSDelete(repo.fName, repo.vrefNum);
									result := Create(repo.fname, repo.vrefnum, 'HRMS', 'TEXT');
									freeMemStr := PathnameFromWD(repo.vRefNum);
									OpenTextWindow(freeMemStr, repo.fName, false, true);
								end
								else
								begin
									HiLiteMenu(0);
									exit(doMenuCommand);
								end;
							end;
							2: 
							begin
								SetPt(tempPt, 40, 40);
								typeList[0] := 'TEXT';
								if optionDown then
									SFGetFile(tempPt, 'What file?', nil, -1, typeList, nil, repo)
								else
									SFGetFile(tempPt, 'What file?', nil, 1, typeList, nil, repo);
								if repo.good then
								begin
									tempString := '';
								end
								else
								begin
									HiLiteMenu(0);
									exit(doMenuCommand);
								end;
								if (tempString <> '') then
									OpenTextWindow('', tempstring, true, true)
								else
								begin
									freeMemStr := PathnameFromWD(repo.vRefNum);
									OpenTextWindow(freeMemStr, repo.fName, false, true);
								end;
							end;
							4: 
							begin
								i := isMyTextWindow(frontwindow);
								dtype := ismyBBSwindow(frontwindow);
								if i >= 0 then
									CloseTextWindow(i)
								else if dtype > 0 then
									CloseANSIWindow(dtype)
								else if FrontWindow = statWindow then
									CloseStatWindow
								else if (GetWRefCon(FrontWindow) = 4444) then
									CloseNodePrefs
								else if FrontWindow = SysConfig then
									CloseSystemConfig
								else if (GetWRefCon(FrontWindow) = 8888) then
								begin
									Close_User_Edit(FrontWindow, false);
									statChanged := true;
								end
								else if (GetWRefCon(FrontWindow) = 150) then
									Close_GlobalUEdit
								else if (GetWRefCon(FrontWindow) = 277) then
									CloseSystemPrefs
								else if (GetWRefCon(FrontWindow) = 992) then
									Close_FB_Edit
								else if (GetWRefCon(FrontWindow) = 72469) then
									Close_Security
								else if (GetWRefCon(FrontWindow) = 101364) then
									Close_Access
								else if (GetWRefCon(FrontWindow) = 818) then
									CloseDialer
								else if (GetWRefCon(FrontWindow) = 800) then
									Close_New
								else if (GetWRefCon(FrontWindow) = 1590) then
									CloseBroadCast
								else if (GetWRefCon(FrontWindow) = 4995) then
									CloseUserList
								else if (GetWRefCon(FrontWindow) = 3467) then
									CloseUserSearch
								else if (GetWRefCon(FrontWindow) = 4321) then
									CloseStrings
								else if (GetWRefCon(FrontWindow) = 5555) then
									CloseTransferSections(FrontWindow)
								else if (GetWRefCon(FrontWindow) = 4440) then
									CloseMenuPrefs
								else if (GetWRefCon(FrontWindow) = 4439) then
									CloseTransPrefs
								else if (GetWRefCon(FrontWindow) = 250) then
									CloseMailPrefs
								else if (GetWRefCon(FrontWindow) = 1993) then
									Close_GFiles
								else if (GetWRefCon(FrontWindow) = 270) then
									CloseErrorWindow
								else if (GetWRefCon(FrontWindow) = 265) then
									CloseChatroomSetup
								else if (GetWRefCon(FrontWindow) = 235) then
									CloseQuoterSetup
								else if (GetWRefCon(FrontWindow) = 175) then
								begin
									DoMForumRec(true);
									for i := 1 to InitSystHand^^.numMForums do
										DoMConferenceRec(true, i);
									DoSystRec(true);
									Close_Message_SetUp(FrontWindow);
								end;
							end;
							5: 
							begin
								i := isMyTextWindow(frontwindow);
								if i >= 0 then
									SaveTextWindow(i);
							end;
							6: 
							begin
								i := isMyTextWindow(frontwindow);
								if i >= 0 then
								begin
									getWTitle(textWinds[i].w, tempstring);
									SetPt(tempPt, 40, 40);
									SFPutFile(tempPt, 'Save text file as', tempstring, nil, repo);
									if repo.good then
									begin
										result := FSDelete(repo.fName, repo.vrefNum);
										result := Create(repo.fname, repo.vrefnum, 'HRMS', 'TEXT');
										freeMemStr := PathnameFromWD(repo.vRefNum);
										SetWTitle(textWinds[i].w, repo.fname);
										textWinds[i].origPath := freeMemStr;
										textWinds[i].wasResource := false;
										textWinds[i].dirty := true;
										SaveTextWindow(i);
									end;
								end;
							end;
							8: 
							begin
								if capturing then
									CloseCapture
								else if (BoardMode = Terminal) or (BoardMode = User) then
								begin
									OpenCapture(char(0));
									CheckItem(GetMHandle(mFile), 8, capturing);
								end
								else
									SysBeep(10);
							end;
							10: 
							begin
								TabbyQuit := NotTabbyQuit;
								quit := 1;
							end;
							otherwise
						end;
					1008: 
						case menuItem of
							1: 
							begin
								userPickDilg := GetNewDialog(128, nil, pointer(-1));
								SetDItemText(userPickDilg, 1, BBSName);
								SetDItemText(userPickDilg, 2, Copy(InitSystHand^^.realSerial, 1, 8));
								repeat
									ModalDialog(@RegistrationFilter, i);
								until (i = 5);

								{ set the registered to: string }
								GetDItemText(userPickDilg, 1, tempString);
								InitSystHand^^.bbsname := tempString;
								BBSName := tempString;

								{ set the short serial number }
								GetDItemText(userPickDilg, 2, tempString);
								if (length(InitSystHand^^.realSerial) < 8) then
									InitSystHand^^.realSerial[0] := char(8);
								if (length(tempString) < 40) then
									for tempInt := 1 to length(tempString) do
										InitSystHand^^.realSerial[tempInt] := tempString[tempInt];

								DoSystRec(true);
								DisposDialog(userPickDilg);
							end;
							2: 
							begin
								userPickDilg := GetNewDialog(415, nil, pointer(-1));
								NumToString(InitSystHand^^.numNodes, tempString);
								ParamText(tempString, '', '', '');
								repeat
									ModalDialog(nil, i);
								until (i = 1);
								GetDItem(userPickDilg, 3, DType, DItem, tempRect);
								GetIText(DItem, tempString);
								DisposDialog(userPickDilg);
								StringToNum(tempString, tempLong);
								i := tempLong;
								if (i > 0) and (i < (MAX_NODES + 1)) then
									setNewNodes := i
								else
									ProblemRep('Number of nodes invalid; not changed.');
							end;
							4: 
								Open_FB_Edit;
							5: 
								Open_Security;
							6: 
								Open_New;
							7: 
								OpenSystemPrefs;
							8: 
								OpenMailPrefs;
							9: 
								OpenChatroomSetup;
							10: 
								OpenQuoterSetup;
							12: 
								OpenMenuPrefs;
							13: 
								OpenTransPrefs;
							19: 
								Open_GFiles;
							17: 
								OpenTransferSections;
							18: 
								Open_Message_SetUp;
							20: 
								OpenNodePrefs;
							otherwise
						end;
					mEdit: 
					begin
						if menuItem <= 6 then
							handledbyDA := SystemEdit(menuItem - 1)
						else
							handledbyDA := false;
						if not handledbyDA then
						begin
							i := isMyTextWindow(frontWindow);
							if (ismyBBSwindow(frontWindow) > 0) then
							begin
								if (menuItem = 3) or (menuItem = 4) then
								begin
									result := ZeroScrap;
									if gBBSwindows[activeNode]^.selectActive then
										CopySelection(activeNode);
								end
								else if (menuItem = 5) and ((BoardMode = User) or (BoardMode = Terminal)) then
								begin
									if GetScrap(handle(sysopKeyBuffer), 'TEXT', tempLong) > 0 then
									begin
										if ((BoardMode = User) and (BoardAction = Writing)) then
										begin
											PasteSysopBuffer;
										end
										else if BoardMode = Terminal then
										begin
											result := AsyncMWrite(outputRef, getHandleSize(handle(sysopKeyBuffer)), ptr(sysopKeyBuffer^));
											if inHalfDuplex then
												ProcessData(activeNode, ptr(sysopKeyBuffer^), getHandleSize(handle(sysopKeyBuffer)));
											SetHandleSize(handle(sysopKeyBuffer), 0);
										end;
									end;
								end
								else
									SysBeep(10);
							end
							else if (i >= 0) then
							begin
								case menuitem of
									3: 
									begin
										with textWinds[i] do
										begin
											if ZeroScrap = noErr then
											begin
												PurgeSpace(tempLong, tempLong2);
												if (t^^.selEnd - t^^.selStart) + 1024 > tempLong2 then   {1024 is just for safety}
												begin
													SysBeep(10);
													SysBeep(10);
												end
												else
												begin
													dirty := true;
													TECut(t);
													if TEToScrap <> noErr then
													begin
														SysBeep(10);
														if ZeroScrap = noErr then
															;
													end;
												end;
											end;
										end;
									end;
									4: 
									begin
										if ZeroScrap = noErr then
										begin
											TECopy(textWinds[i].t);
											if TEToScrap <> noErr then
											begin
												SysBeep(10);
												if ZeroScrap = noErr then
													;
											end;
										end;
									end;
									5: 
									begin
										with textWinds[i] do
										begin
											if TEFromScrap = noErr then
											begin
												if TEGetScrapLen + (t^^.teLength - (t^^.selEnd - t^^.selStart)) > 32000 then
													SysBeep(10)
												else
												begin
													aHandle := Handle(TEGetText(t));
													oldSize := GetHandleSize(aHandle);
													newSize := oldSize + TEGetScrapLen + 1024;  {1024 just for safety}
													SetHandleSize(aHandle, newSize);
													result := MemError;
													SetHandleSize(aHandle, oldSize);
													dirty := true;
													if result <> noErr then
														SysBeep(10)
													else
														TEPaste(t);
												end;
											end
											else
												SysBeep(10);
										end;
									end;
									6: 
									begin
										textWinds[i].dirty := true;
										TEDelete(textWinds[i].t);
									end;
									7: 
										TESetSelect(0, 32767, textWinds[i].t);
									9: 
										DoTextSearch(i);
									10: 
										mySearchTE(i, true);
									otherwise
								end;
							end
							else
								SysBeep(10);
						end;
					end;
					10: 
					begin
						GetItem(GetMHandle(10), menuItem, tempString);
						if (tempString <> '') then
							OpenTextWindow('HTxt', tempstring, true, true)
						else
						begin
							freeMemStr := PathnameFromWD(repo.vRefNum);
							OpenTextWindow(freeMemStr, repo.fName, false, true);
						end;
					end;
					11: 
					begin
						GetItem(GetMHandle(11), menuItem, tempString);
						if (tempString <> '') then
							OpenTextWindow('ATxt', tempstring, true, true)
						else
						begin
							freeMemStr := PathnameFromWD(repo.vRefNum);
							OpenTextWindow(freeMemStr, repo.fName, false, true);
						end;
					end;
					12: 
					begin
						case menuitem of
							1: 
							begin
								StringSet := 1;
								OpenStrings(1);
							end;
							2: 
							begin
								StringSet := 3;
								OpenStrings(3);
							end;
						end;
					end;
					mUser: 
						case menuitem of
							1: 
							begin
								if BoardAction <> chat then
								begin
									if not myTrans.active then
									begin
										SavedBD2 := BoardAction;
										BoardAction := chat;
										bCR;
										prompting := false;
										CheckItem(GetMHandle(mUser), 1, true);
										StartedChat := tickCount;
										triedChat := false;
										if BoardSection = ChatRoom then
										begin
											TheChat.BlockWho := 0;
											ChatroomEnterExit(false);
										end;
										DoChatShow(true, true, '0');
									end;
								end
								else
								begin
									CheckItem(GetMHandle(mUser), 1, false);
									GiveTime((tickCount - startedchat), 1, false);
									BoardAction := savedBD2;
									if (BoardSection = ChatRoom) then
									begin
										BoardAction := none;
										ChatroomUserSetUp(0);
										DrawChatroom;
										ChatroomEnterExit(true);
										TheChat.BlockWho := -1;
										ChatRoomSingle(ActiveNode, false, false, 'Sysop chat over.');
										if thisUser.TerminalType = 1 then
											ChatRoomDo := ChatAEM1
										else
											ChatRoomDo := ChatEM1;
									end
									else
									begin
										bCR;
										if thisUser.TerminalType = 1 then
										begin
											ANSICode('2J');
											ANSICode('H');
										end;
										OutLine('Sysop chat over.', false, 1);
										bCR;
										if thisUser.TerminalType = 1 then
											dom(0);
										if BoardAction = Writing then
											ListLine(online)
										else if boardAction = Prompt then
											ReprintPrompt;
									end;
								end;
							end;
							2: 
							begin
								if getUSelection = nil then
								begin
									Single := true;
									if thisUser.UserNum > 0 then
									begin
										EditingUser := thisUser;
										Open_User_Edit;
									end
									else
										SysBeep(10);
								end
								else
									SelectWindow(getUSelection);
							end;
							3: 
							begin
								if not sysopLogon then
								begin
									if not stopRemote then
									begin
										stopRemote := true;
										SavedBDaction := BoardAction;
										BoardAction := none;
										OutLineSysop(RetInStr(629), true);	{< REMOTE KB DISABLED >}
										BoardAction := savedBDaction;
									end
									else
									begin
										stopRemote := false;
										if not sysopLogon then
										begin
											clearInBuf;
										end;
										SavedBDaction := BoardAction;
										BoardAction := none;
										OutLineSysop(RetInStr(630), true);{< REMOTE KB ENABLED >}
										BoardAction := savedBDaction;
									end;
								end;
							end;
							4: 
							begin
								if thisUser.UserNum > -1 then
								begin
									GiveTime(-18000, 1, false);
									statChanged := true;
								end;
							end;
							5: 
							begin
								if thisUser.UserNum > -1 then
								begin
									GiveTime(18000, 1, false);
									statChanged := true;
								end;
							end;
							6: 
							begin
								if (thisUser.UserNum > 1) and (RealSL > 0) then
								begin
									if wasMadeTempSysOp then
										WasMadeTempSysop := False
									else
										WasMadeTempSysop := True;
									if ThisUser.CoSysOp then
										ThisUser.CoSysOp := False
									else
										ThisUser.CoSysOp := True;
									if thisUser.SL <> RealSL then
										thisUser.SL := RealSL
									else
										thisUser.SL := 255;
									statChanged := true;
								end;
							end;
							7: 
								openBroadCast;
							otherwise
						end;
					mDisconnects: 
						if (boardMode = User) then
							case menuitem of
								1: 
								begin
									HangupAndReset;
								end;
								2: 
								begin
									mySavedBD := BoardAction;
									BoardAction := none;
									bCR;
									OutLine(concat(char(7), RetInStr(68)), false, 6);
									if thisUser.TerminalType = 1 then
										dom(0);
									bCR;
									BoardAction := mySavedBD;
									ShutdownSoon := true;
									extraTime := extraTime + 18000 - ticksLeft(activeNode);
									if BoardAction = Writing then
										ListLine(online)
									else if boardAction = Prompt then
										ReprintPrompt;
								end;
								3: 
								begin
									tempInt := (ABS(Random) mod 40) + 1;
									for i := 1 to tempInt do
										OutLine(char((ABS(Random) mod 100) + 27), false, -1);
									Delay(45, tempLong);
									HangupAndReset;
								end;
								4: 
								begin
									OutLine(RetInStr(631), true, 0);	{Time expired.}
									delay(60, tempLong);
									HangUpAndReset;
								end;
								otherwise
							end;
					55: 
					begin
						doBaudReset(menuItem);
						UnCheckTerm;
						CheckItem(GetMHandle(55), menuItem, true);
						NumToBaud(menuItem, currentBaud);
						statChanged := true;
					end;
					50: 
						case menuItem of
							1: 
							begin
								ANSIterm := false;
								thisUser.TerminalType := 0;
								thisUser.ColorTerminal := False;
								checkItem(getMHandle(50), 1, true);
								checkItem(getMHandle(50), 2, false);
								statChanged := true;
								gBBSwindows[activeNode]^.ansiEnable := false;
							end;
							2: 
							begin
								ANSIterm := true;
								thisUser.TerminalType := 1;
								thisUser.ColorTerminal := True;
								checkItem(getMHandle(50), 1, false);
								checkItem(getMHandle(50), 2, true);
								statChanged := true;
								gBBSwindows[activeNode]^.ansiEnable := true;
							end;
							otherwise
						end;
					mTerminal: 
					begin
						if menuitem = 3 then
						begin
							checkItem(GetMHandle(mTerminal), 3, not inHalfDuplex);
							inHalfDuplex := not inHalfDuplex;
							statChanged := true;
						end
						else if menuItem = 4 then
						begin
							checkItem(GetMHandle(mTerminal), 4, in8BitTerm);
							in8BitTerm := not in8BitTerm;
							statChanged := true;
						end
						else if menuItem = 5 then
						begin
							if dialing then
							begin
								dialing := false;
								waitDialResponse := false;
								CheckItem(GetMHandle(mTerminal), 5, dialing);
							end
							else
								OpenDialer;
						end;
					end;
					mLog: 
					begin
						case menuItem of
							1: 
								OpenTextWindow(sharedPath, 'Misc:Usage Record', false, false);
							2: 
								OpenTextWindow(sharedPath, 'Misc:Today Log', false, false);
							otherwise
							begin
								GetItem(getMHandle(mLog), menuItem, tempstring);
								OpenTextWindow(concat(sharedPath, 'Logs:'), tempstring, false, false);
							end;
						end;
					end;
					mNetLog: 
					begin
						case menuItem of
							1: 
								OpenTextWindow(sharedPath, 'Misc:Network Usage Record', false, false);
							2: 
								OpenTextWindow(sharedPath, 'Misc:Network Today Log', false, false);
							otherwise
							begin
								GetItem(getMHandle(mNetLog), menuItem, tempstring);
								OpenTextWindow(concat(sharedPath, 'Logs:Network:'), tempstring, false, false);
							end;
						end;
					end;
					mSysop: 
					begin
						case menuitem of
							1: 
							begin
47:
								if ((BoardMode = Failed) or (BoardMode = Waiting)) and (ismyBBSwindow(frontWindow) > 0) then
								begin
									sysopLogon := true;
									ClearScreen;
									curBaudNote := '';
									currentBaud := 0;
									if goOffinLocal then
										TellModem('ATM0H1');
									DoLogon(true);
									ClearInBuf;
								end
								else
									SysBeep(10);
							end;
							2: 
							begin
								if (InitSystHand^^.numUsers > 0) then
								begin
									if (not UserOnSystem(myUsers^^[0].Uname)) and ((BoardMode = Failed) or (BoardMode = Waiting)) and (ismyBBSwindow(frontWindow) > 0) then
									begin
										if FindUser('1', thisUser) then
										begin
											DoAddressBooks(AddressBook, thisUser.UserNum, false);
											SysopLogOn := true;
											if goOffinLocal then
												TellModem('ATM0H1');
											CurBaudNote := '';
											currentBaud := 0;
											ClearScreen;
											boardmode := user;
											EnableItem(GetMHandle(mUser), 0);
											DrawMenuBar;
											lastKeyPressed := TickCount;
											BoardAction := none;
											BoardSection := Logon;
											LogonStage := ChkSysPass;
											EnteredPass := thisUser.password;
											ClearinBuf;
											realSL := 255;
										end;
									end
									else
										SysBeep(10);
								end
								else
									goto 47;
							end;
							3: 
							begin
								if SysOpAvailC then
									SysOpAvailC := False
								else
									SysOpAvailC := True;
							end;
							4: 
							begin
								if AnswerCalls then
									AnswerCalls := False
								else
									AnswerCalls := True;
								CheckItem(getMHandle(mSysop), 4, not answerCalls);
								if not answerCalls then
									for i := 1 to MAX_NODES do
										held[i] := false;
							end;
							6: 
							begin
								if GetULSelection = nil then
								begin
									Single := false;
									OpenUserList;
								end
								else
								begin
									SelectWindow(getULSelection);
									Sysbeep(10);
								end;
							end;
							7: 
								Open_GlobalUEdit;
							8: 
							begin
								SysopFileConfigure;
							end;
							9: 
								if ErrorDlg = nil then
									LogError('OpenFromSysopMenu', true, 0)
								else
									SelectWindow(ErrorDlg);
							14: 
							begin
								if (Mailer^^.MailerAware) and (Mailer^^.SubLaunchMailer = 3) and (not arePollingWebTosser) then
								begin
									shouldPollWebTosser := true;
									if (BAnd(modifiers, optionKey) <> 0) then
									begin
										debugWebTosserOnce := true;
										if BAnd(modifiers, shiftKey) <> 0 then
											debugWebTosserToFileOnce := true
										else
											debugWebTosserToFileOnce := false;
									end
									else
									begin
										debugWebTosserOnce := false;
										debugWebTosserToFileOnce := false;
									end;
								end;
							end;
							15: 
							begin
								if (ismyBBSwindow(frontWindow) > 0) and ((BoardMode = Waiting) or (BoardMode = Failed)) and (nodeType >= 0) then
								begin
									BoardMode := Terminal;
									Flowie(true);
									EnableItem(GetMHandle(mTerminal), 0);
									UnCheckTerm;
									NumToBaud(maxBaud, currentBaud);
									CheckItem(getMHandle(55), maxBaud, true);
									CheckItem(GetMHandle(mTerminal), 4, false);
									CheckItem(GetMHandle(mTerminal), 3, false);
									checkItem(getMHandle(50), 2, true);
									inHalfDuplex := false;
									in8BitTerm := true;
									ANSIterm := true;
									thisUser.TerminalType := 1;
									thisUser.ColorTerminal := True;
									DisableItem(GetMHandle(mSysop), 1);
									DisableItem(getMHandle(mSysop), 2);
									result := CallUtility(DISPOSETMENU, ptr(myProcMenu), 0);
									myProcMenu := nil;
									result := CallUtility(BUILDMENU, pointer(@myProcMenu), longint($03F10000));
									DrawMenuBar;
									freeMemStr := modemDrivers^^[modemID].termInit;
									freememstr := concat(freeMemStr, char(13));
									templong := length(freememStr);
									Result := AsyncMWrite(outputRef, tempLong, @freeMemStr[1]);
									statChanged := true;
								end
								else if BoardMode = Terminal then
								begin
									gBBSwindows[activeNode]^.ansiEnable := true;
									currentBaud := 0;
									dialing := false;
									waitDialResponse := false;
									UncheckTerm;
									DisableItem(GetMHandle(mTerminal), 0);
									EnableItem(GetMHandle(mSysop), 1);
									EnableItem(getMHandle(mSysop), 2);
									result := CallUtility(DISPOSETMENU, ptr(myProcMenu), 0);
									myProcMenu := nil;
									result := CallUtility(BUILDMENU, pointer(@myProcMenu), longint($03F10001));
									DrawMenuBar;
									HangupAndReset;
								end;
							end;
							13: 
								OpenSystemConfig(1);
							17..118:  {Nodes 1 through 100 + separator + status window}
							begin
								if menuItem = (InitSystHand^^.numNodes + 18) then
									OpenStatWindow
								else
									SwitchNode(menuItem - 16);
							end;

							otherwise
						end;
					end;
					otherwise
					begin
						result := CallUtility(DOMENU, ptr(myProcMenu), menuResult);
						if myProcMenu^^.proto <> nil then
						begin
							tempLong := -1;
							for i := 1 to theProts^^.numProtocols do
							begin
								if (myProcMenu^^.theProcList[myProcMenu^^.transIndex].itemID = theProts^^.prots[i].resID) and (myProcMenu^^.transRefCon = theProts^^.prots[i].refCon) then
									tempLong := i;
							end;
							if tempLong > 0 then
							begin
								activeProtocol := templong;
								if myProcMenu^^.transMessage = 2 then
								begin
									myProcMenu^^.proto^^.modemInput := inputRef;
									myProcMenu^^.proto^^.modemOutput := outputRef;
									myProcMenu^^.proto^^.timeout := InitSystHand^^.protocolTime;
									theProts^^.prots[activeProtocol].ProtHand := Get1Resource('PROC', theProts^^.prots[activeProtocol].resID);
									theprots^^.prots[activeprotocol].protMode := theprots^^.prots[activeprotocol].protMode + 1;
									if theprots^^.prots[activeProtocol].protMode = 1 then
									begin
										MoveHHi(theProts^^.prots[activeProtocol].ProtHand);
										Hlock(theProts^^.prots[activeProtocol].ProtHand);
									end;
									result := HU2ProtocolCall(2, pointer(myProcMenu^^.proto^), theprots^^.prots[activeProtocol].refCon, StripAddress(pointer(theProts^^.prots[activeProtocol].protHand^)));
									theProts^^.prots[activeprotocol].protMode := theProts^^.prots[activeProtocol].protMode - 1;
									if theProts^^.prots[activeProtocol].protMode <= 0 then
										HUnlock(theProts^^.prots[activeProtocol].protHand);
									result := CallUtility(DISPOSEPREC, ptr(myProcMenu), 0);
								end
								else
								begin
									if myProcMenu^^.transMessage = UPLOADCALL then
										myTrans.sending := false
									else
										myTrans.sending := true;
									myTrans.active := true;
									KillXFerRec;
									extTrans := myProcMenu^^.proto;
									extTrans^^.modemInput := inputRef;
									extTrans^^.modemOutput := outputRef;
									extTrans^^.timeout := InitSystHand^^.protocolTime;
									StartTrans;
								end;
							end;
						end;
					end;
				end;
				HiliteMenu(0);					{unhighlight what MenuSelect (or MenuKey) hilited}
			end;
		end;
	end;

	procedure DoUpMess;
		var
			tempString, tempstring2: str255;
			result: OSErr;
			i, TheFile: integer;
			tempLong: longint;
	begin
		with curglobs^ do
		begin
			case upMess of
				MessUpOne: 
				begin
					if not sysopLogon then
					begin
						bCR;
						bCR;
						bCR;
						if theProts^^.numProtocols > 0 then
						begin
							tempstring := concat(char(13), '0Q?');
							crossInt := 0;
							for i := 1 to theProts^^.numProtocols do
							begin
								if theProts^^.prots[i].pFlags[CANRECEIVE] then
								begin
									crossInt := crossInt + 1;
									NumToString(crossint, tempstring2);
									tempString := concat(tempString, tempstring2);
								end;
							end;
							NumbersPrompt(getProtMenStr, 'Q?', crossInt, 0);
						end
						else
							GoHome;
						UpMess := MessUpTwo;
					end
					else
					begin
						OutLine(RetInStr(220), true, 0);{  In local mode, please use //LOAD to put a file in the workspace.}
						GoHome;
					end;
				end;
				MessUpTwo: 
				begin
					if curPrompt = '?' then
					begin
						OutLine(RetInStr(309), true, 0);	{Q: Abort Transfer(s)}
						OutLine(RetInStr(310), true, 0);	{0: Don''t Transfer}
						crossInt := 0;
						tempstring := concat(char(13), '0Q?');
						for i := 1 to theProts^^.numProtocols do
						begin
							if theProts^^.prots[i].pFlags[CANRECEIVE] then
							begin
								crossInt := crossInt + 1;
								NumToString(crossInt, tempstring2);
								OutLine(concat(tempstring2, ': ', theProts^^.prots[i].ProtoName), true, 0);
								tempString := concat(tempString, tempstring2);
							end;
						end;
						bCR;
						bCR;
						NumbersPrompt(getProtMenStr, 'Q?', crossInt, 0);
						Exit(doUpMess);
					end
					else if (curPrompt = 'Q') or (curPrompt = '0') then
					begin
						GoHome;
						Exit(doUpMess);
					end
					else
					begin
						StringToNum(curPrompt, tempLong);
						crossInt := 0;
						for i := 1 to theProts^^.numProtocols do
						begin
							if theProts^^.prots[i].pFlags[CANRECEIVE] then
							begin
								crossInt := crossInt + 1;
								if crossInt = tempLong then
									tempLong := i;
							end;
						end;
						if length(curPrompt) = 0 then
							tempLong := thisUser.defaultProtocol;
						if (tempLong > 0) and (tempLong <= theProts^^.numProtocols) and (theProts^^.prots[templong].pFlags[CANRECEIVE]) then
						begin
							activeProtocol := templong;
							bCR;
							bCR;
							tempString := StringOf(sharedPath, 'Misc:Local Workspace ', activeNode : 0);
							result := FSDelete(tempString, 0);
							myTrans.active := true;
							myTrans.sending := false;
							upMess := MessUpThree;
							StartTrans;
						end
						else
						begin
							OutLine(RetInStr(311), true, 0);	{Protocol not valid for uploading.}
							upMess := MessUpOne;
						end;
					end;
				end;
				MessUpThree: 
				begin
					if crossInt > 0 then
					begin
						tempString := StringOf(sharedPath, 'Misc:Local Workspace ', activeNode : 0);
						result := FSOpen(tempString, 0, TheFile);
						if result = noErr then
						begin
							result := GetEOF(TheFile, tempLong);
							if tempLong < 30000 then
							begin
								OutLine(RetInStr(221), true, 0);	{Message uploaded.  The next post or email will contain that text.}
								useWorkspace := 1;
							end
							else
							begin
								OutLine(RetInStr(222), true, 0);	{Sorry, your message is too long.  Not saved.}
								result := FSDelete(tempString, 0);
								useWorkspace := 0;
							end;
							result := FSClose(TheFile);
						end
						else
							OutLine(RetInStr(223), true, 0); {Problem with message upload.}
					end
					else
						OutLine(RetInStr(224), true, 0); {Message receive failed.}
					GoHome;
				end;
				otherwise
			end;
		end;
	end;

	procedure DoTransDefs;
		var
			t1, T8: str255;
			tempint: longint;
			i: integer;
	begin
		with curglobs^ do
		begin
			case TransDo of
				TrOne: 
				begin
					BufClearScreen;
					bufferIt(concat('1. ', RetInStr(225)), false, 0);   {Set Default Protocol}
					if thisUser.nTransAfterMess then
						t1 := 'Yes'
					else
						T1 := 'No';
					bufferIt(concat('2. ', RetInStr(226), '(', t1, ')'), true, 0);  {N-Scan Transfer after Message Base}
					if thisUser.extendedLines > 0 then
						t1 := 'Yes'
					else
						t1 := 'No';
					bufferIt(concat('3. ', RetInStr(227), '(', t1, ')'), true, 0);		{Print Extended Descriptions in Listing}
					if thisUser.ExtDesc then
						t1 := 'Yes'
					else
						T1 := 'No';
					bufferIt(concat('4. ', RetInStr(228), '(', t1, ')'), true, 0);	{Search Extended Descriptions}
					bufferIt('Q. Quit', true, 0);
					bufferbCR;
					bufferbCR;
					ReleaseBuffer;
					NumbersPrompt(RetInStr(229), 'Q', 4, 1);
					TransDo := TrTwo;
				end;
				trFour: 
				begin

				end;
				TrTwo: 
				begin
					if length(curPrompt) > 0 then
					begin
						case curprompt[1] of
							'3': 
							begin
								if thisUser.extendedLines <> 0 then
									thisUser.extendedLines := 0
								else
									thisUser.extendedLines := 1;
								TransDo := TrThree;
							end;
							'2': 
							begin
								if thisUser.NTransAfterMess then
									thisUser.NTransAfterMess := False
								else
									thisUser.NTransAfterMess := True;
								TransDo := TrOne;
							end;
							'4': 
							begin
								if thisUser.ExtDesc then
									thisUser.ExtDesc := False
								else
									thisUser.ExtDesc := True;
								TransDo := TrOne;
							end;
							'1': 
							begin
								bCR;
								OutLine(RetInStr(230), true, 0);	{Enter your Default Protocol, 0 for none.}
								bCR;
								NumbersPrompt(RetInStr(231), '?', theProts^^.numprotocols, 0);		{Protocol (?=list) : }
								TransDo := TrThree;
							end;
							'Q': 
								GoHome;
							otherwise
						end;
					end
					else
						GoHome;
				end;
				TrThree: 
				begin
					if length(curprompt) > 0 then
					begin
						case curPrompt[1] of
							'?': 
							begin
								bufferIt(RetInStr(312), true, 0);	{0: No default}
								for i := 1 to theProts^^.numProtocols do
								begin
									NumToString(i, t1);
									bufferIt(concat(t1, ': ', theProts^^.prots[i].ProtoName), true, 0);
								end;
								bufferbCR;
								ReleaseBuffer;
								curPrompt := '1';
								TransDo := TrTwo;
							end;
							otherwise
							begin
								StringToNum(curPrompt, tempint);
								if (tempInt > 0) and (tempInt <= theProts^^.numProtocols) then
									thisUser.defaultProtocol := tempint
								else
									thisUser.defaultProtocol := 0;
								TransDo := TrOne;
							end;
						end;
					end
					else
						GoHome;
				end;
				otherwise
			end;
		end;
	end;

	procedure DoMultiMail;
		var
			i: integer;
			tempBool: boolean;
			temps1: str255;
	begin
		with curglobs^ do
		begin
			case MultiDo of
				MultiOne: 
				begin
					netMail := false;
					if (thisuser.emSentToday + thisUser.mPostedToday) > thisUser.mesgDay then
					begin
						OutLine(RetInStr(232), true, 0);		{You have sent too many messages today.}
						GoHome;
						exit(doMultiMail);
					end;
					if freeK(InitSystHand^^.msgsPath) < 50 then
					begin
						OutLine(RetInStr(64), true, 0);
						GoHome;
						exit(doMultiMail);
					end;
					if (ThisUser.CantSendEmail) then
					begin
						OutLine(RetInStr(233), true, 0);	{You cannot send e-mail.}
						GoHome;
						exit(doMultiMail);
					end;
					OutLine(RetInStr(66), true, 0);
					MultiDo := MultiTwo;
					numMultiUsers := 0;
					for i := 1 to 20 do
						multiUsers[i] := 0;
				end;
				MultiTwo: 
				begin
					if ((thisuser.emSentToday + thisUser.mPostedToday) + numMultiUsers) <= thisUser.mesgDay then
					begin
						if numMultiUsers < 20 then
						begin
							bCR;
							LettersPrompt('> ', '', 31, false, false, true, char(0));
							myPrompt.wrapsonCR := false;
							MultiDo := MultiThree;
						end
						else
						begin
							OutLine(RetInStr(234), true, 0);	{List full.}
							MultiDo := MultiFour;
						end;
					end
					else
					begin
						OutLine(RetInStr(235), true, 0);	{Sorry, you have reached your message limit for today.}
						MultiDo := MultiFour;
					end;
				end;
				MultiThree: 
				begin
					if length(curPrompt) > 0 then
					begin
						if FindUser(curPrompt, tempUser) then
						begin
							if not tempuser.DeletedUser then
							begin
								if not tempUser.mailbox and not (tempUser.usernum = thisuser.usernum) then
								begin
									tempBool := false;
									if numMultiUsers > 0 then
									begin
										i := 1;
										while (i <= crossint) and (multiUsers[i] <> tempUser.userNum) do
											i := i + 1;
										if (i < 21) and (multiUsers[i] = tempuser.userNum) then
											tempBool := true;
									end;
									if not tempBool then
									begin
										BackSpace(gBBSwindows[activeNode]^.cursor.h - 2);
										NumToString(tempUser.userNum, temps1);
										OutLine(concat('     -> ', tempUser.userName, ' #', temps1), false, 0);
										numMultiUsers := numMultiUsers + 1;
										multiUsers[numMultiUsers] := tempUser.userNum;
										MultiDo := MultiTwo;
									end
									else
									begin
										OutLine(RetInStr(236), true, 0);	{Already in list, not added.}
										MultiDo := MultiTwo;
									end;
								end
								else
								begin
									if (tempuser.usernum = thisuser.usernum) then
										OutLine(RetInStr(198), true, 0)	{Cannot send E-Mail to yourself}
									else
										OutLine(RetInStr(237), true, 0);	{Cannot send multi-mail to a user forwarding mail.}
									MultiDo := MultiTwo;
								end;
							end
							else
							begin
								OutLine(RetInStr(199), true, 0);		{Deleted user.}
								MultiDo := MultiTwo;
							end;
						end
						else
						begin
							OutLine(RetInStr(17), true, 0);		{Unknown user.}
							MultiDo := MultiTwo;
						end;
					end
					else
						MultiDo := MultiFour;
				end;
				MultiFour: 
				begin
					if numMultiUsers > 0 then
					begin
						Outline('E-mailing:', true, 0);
						for i := 1 to numMultiUsers do
						begin
							NumToString(multiUsers[i], temps1);
							OutLine(concat('     ', myUsers^^[multiUsers[i] - 1].UName, ' #', temps1), true, 0);
						end;
						bCR;
						if (thisUser.TerminalType = 0) and not thisUser.ColorTerminal then
							OutLine(RetInStr(722), true, 0);{       (---=----=----=----=----=----=----=----=--)}
						bCR;
						LettersPrompt(RetInStr(176), '', 43, false, false, false, char(0));	{Title: }
						ANSIPrompter(43);
						CurEMailRec.fromuser := thisUser.Usernum;
						curEmailRec.toUser := -1;
						curEMailRec.anonyTo := false;
						curEmailRec.anonyFrom := false;
						CurEMailRec.MType := 1;
						CurEMailRec.FileAttached := false;
						CurEMailRec.FileName := char(0);
						curEmailRec.multimail := true;
						GetDateTime(CurEMailRec.dateSent);
						for i := 0 to 15 do
							curEmailRec.reserved[i] := char(0);
						sentAnon := false;
						callFMail := false;
						EMailDo := EmailEight;
						BoardSection := Email;
					end
					else
					begin
						OutLine(RetInStr(313), true, 0);	{No users specified.}
						GoHome;
					end;
				end;
				otherwise
			end;
		end;
	end;
end.