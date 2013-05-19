program Hermes;

	uses
		AppleTalk, ADSP, Serial, Sound, Notification, AppleTalk, PPCToolbox, Processes, EPPC, AppleEvents, TCPTypes, Initial, LoadAndSave, NodePrefs2, NodePrefs, SystemPrefs2, SystemPrefs, Message_Editor, Message_Editor2, Import, User, UserManager, Misc, Misc2, Terminal, inpOut4, inpOut3, inpOut2, Quoter, inpOut, MessNTextOutput, ChatRoomUtils, Chatroom, FileTrans3, FileTrans2, FileTrans, HUtilsOne, HUtils2, HUtils3, HUtils5, HUtils7;

{$S Initial_1}
	procedure Initial_1;
	begin
	end;

{$S CreateNewFiles_1}
	procedure CreateNewFiles_1;
	begin
	end;

{$S LoadAndSave_1}
	procedure LoadAndSave_1;
	begin
	end;

{$S NodePrefs2_1}
	procedure NodePrefs2_1;
	begin
	end;

{$S NodePrefs_1}
	procedure NodePrefs_1;
	begin
	end;

{$S NodePrefs_2}
	procedure NodePrefs_2;
	begin
	end;

{$S SystPrefs2_1}
	procedure SystPrefs2_1;
	begin
	end;

{$S SystPref_1}
	procedure SystPref_1;
	begin
	end;

{$S MesEdit_1}
	procedure MesEdit_1;
	begin
	end;

{$S Import_1}
	procedure Import_1;
	begin
	end;

{$S User_1}
	procedure User_1;
	begin
	end;

{$S UserManager_1}
	procedure UserManager_1;
	begin
	end;

{$S UserManager_2}
	procedure UserManager_2;
	begin
	end;

{$S Misc_1}
	procedure Misc_1;
	begin
	end;

{$S Misc2_1}
	procedure Misc2_1;
	begin
	end;

{$S Terminal_1}
	procedure Terminal_1;
	begin
	end;

{$S InpOut4_1}
	procedure InpOut4_1;
	begin
	end;

{$S InpOut3_1}
	procedure InpOut3_1;
	begin
	end;

{$S InpOut2_1}
	procedure InpOut2_1;
	begin
	end;

{$S Quoter_1}
	procedure Quoter_1;
	begin
	end;

{$S InpOut_1}
	procedure InpOut_1;
	begin
	end;

{$S MessNTextOutput_1}
	procedure MessNTextOutput_1;
	begin
	end;

{$S MessageSearcher_1}
	procedure MessageSearcher_1;
	begin
	end;

{$S ChatroomUtils_1}
	procedure ChatroomUtils_1;
	begin
	end;

{$S Chatroom_1}
	procedure Chatroom_1;
	begin
	end;

{$S FileTrans3_1}
	procedure FileTrans3_1;
	begin
	end;

{$S FileTrans2_1}
	procedure FileTrans2_1;
	begin
	end;

{$S FileTrans_1}
	procedure FileTrans_1;
	begin
	end;

{$S NewUser_1}
	procedure NewUser_1;
	begin
	end;

{$S HermesUtils_1}
	procedure HermesUtils_1;
	begin
	end;

{$S HUtils1_1}
	procedure HUtils1_1;
	begin
	end;

{$S HUtils1_2}
	procedure HUtils1_2;
	begin
	end;

{$S HUtils2_1}
	procedure HUtils2_1;
	begin
	end;

{$S HUtils3_1}
	procedure HUtils3_1;
	begin
	end;

{$S HUtils4_1}
	procedure HUtils4_1;
	begin
	end;

{$S HUtils4_2}
	procedure HUtils4_2;
	begin
	end;

{$S HUtils5_1}
	procedure HUtils5_1;
	begin
	end;

{$S HUtils6_1}
	procedure HUtils6_1;
	begin
	end;

{$S HUtils7_1}
	procedure HUtils7_1;
	begin
	end;

	procedure LoadSegments;
	begin
		Initial_1;
		CreateNewFiles_1;
		LoadAndSave_1;
		NodePrefs2_1;
		NodePrefs_1;
		NodePrefs_2;
		SystPrefs2_1;
		SystPref_1;
		MesEdit_1;
		Import_1;
		User_1;
		UserManager_1;
		UserManager_2;
		Misc_1;
		Misc2_1;
		Terminal_1;
		InpOut4_1;
		InpOut3_1;
		InpOut2_1;
		Quoter_1;
		InpOut_1;
		MessNTextOutput_1;
		MessageSearcher_1;
		ChatroomUtils_1;
		Chatroom_1;
		FileTrans3_1;
		FileTrans2_1;
		FileTrans_1;
		NewUser_1;
		HermesUtils_1;
		HUtils1_1;
		HUtils1_2;
		HUtils2_1;
		HUtils3_1;
		HUtils4_1;
		HUtils4_2;
		HUtils5_1;
		HUtils6_1;
		HUtils7_1;
	end;

{$S Main}
	function DoCloseWindow (window: WindowPtr): BOOLEAN;
	begin
		DoCloseWindow := TRUE;
		if IsDAWindow(window) then
			CloseDeskAcc(WindowPeek(window)^.windowKind)
		else if IsAppWindow(window) then
			CloseWindow(window);
	end;

	procedure DoActivate (window: WindowPtr; becomingActive: boolean);
		var
			tempRgn, clipRgn: RgnHandle;
			growRect: Rect;
			indWind, id2: integer;
	begin
		if IsAppWindow(window) then
			if becomingActive then
			begin
				indWind := isMyTextWindow(window);
				id2 := isMyBBSwindow(window);
				if indWind >= 0 then
				begin
					with textWinds[indWind] do
					begin
						SetPort(w);
						TEActivate(t);
						ShowControl(s);
						growRect := w^.portRect;
						with growRect do
						begin
							top := bottom - 15;		{adjust for the scrollbars}
							left := right - 15;
						end;
						InvalRect(growRect);
					end;
				end
				else if id2 > 0 then
				begin
					if id2 <> visibleNode then
						SwitchNode(id2);
					ActivateBBSwind(true, id2);
				end;
			end
			else
			begin
				indWind := isMyTextWindow(window);
				id2 := isMyBBSwindow(window);
				if indWind >= 0 then
				begin
					with textWinds[indWind] do
					begin
						TEDeactivate(t);
						HideControl(s);
						DrawGrowIcon(w);
					end;
				end
				else if id2 > 0 then
				begin
					ActivateBBSwind(false, id2);
				end;
			end;
	end;


	procedure DoEvent (event: EventRecord; isDil: boolean);
		label
			2;
		var
			err, keyInt, itemHit, tempint, part, value, tempEventWhat, i, dType: INTEGER;
			window, whichwindow, theWindow: WindowPtr;
			hit, b: BOOLEAN;
			isADialog, shiftDown, ignoreresult: boolean;
			key, keytwo: char;
			tempRgn: rgnHandle;
			aPoint: Point;
			result: OSerr;
			count, StrLeng, templong, growResult: longInt;
			yaba, tempString, gUEditText: str255;
			dumrect, teRect, tempRect: rect;
			control: controlHandle;
			tvMenu: menuHandle;
			h, dItem: handle;
	begin
		tempEventWhat := event.what;
		part := FindWindow(event.where, window);
		if (isDil) and (event.what = KeyDown) and (BAnd(event.modifiers, cmdKey) <> 0) then
			goto 2;
		if isDil then
		begin
			if (event.what = activateEvt) then
			begin
				if (windowPtr(event.message) = SysConfig) and (sysConfig <> nil) then
				begin
					LActivate((BAnd(event.modifiers, activeFlag) <> 0), extList);
					if (BAnd(event.modifiers, activeFlag) <> 0) then
						CallSysopExternal(activDev, -1, event)
					else
						CallSysopExternal(deActivDev, -1, event);
				end;
			end;

			if (Event.what = KeyDown) then
			begin
				b := false;
				key := Char(BAnd(event.message, charCodeMask));
				whichWindow := FrontWindow;
				if (whichWindow = SearchSelection) then
				begin
					if (key = char(13)) then
					begin
						GetDItem(SearchSelection, 1, tempInt, h, tempRect);
						HiliteControl(ControlHandle(h), 10);
						Delay(8, templong);
						HiliteControl(ControlHandle(h), 0);
						itemHit := -99;
						DoUserSearch(event, ItemHit);
						b := true;
					end
				end
				else if (whichWindow = SSLockDlg) then
				begin
					if (key <> char(13)) and (key <> char(8)) then
					begin
						tempstring := GetTextBox(SSLockDlg, 4);
						tempString := concat(TempString, key);
						SetTextBox(SSLockDlg, 4, tempString);
						event.message := $00A5;
					end
					else if (key = char(13)) then
					begin
						GetDItem(SSLockDlg, 1, tempInt, h, tempRect);
						itemHit := 1;
						DoSSLock(event, ItemHit);
						b := true;
					end
					else if (key = char(8)) then
					begin
						tempString := GetTextBox(SSLockDlg, 4);
						Delete(tempstring, length(tempstring), 1);
						SetTextBox(SSLockDlg, 4, tempString);
					end
				end
				else if (whichWindow = GetUSelection) then
				begin
					if (CheckUEditAlpha) then
						if (key >= 'a') and (key <= 'z') then
						begin
							key := chr(ord(key) - 32);
							event.message := ord(key);
						end;
				end
				else if (whichWindow = GlobalUSearch) then
				begin
					GetDItem(GlobalUSearch, 14, dType, dItem, tempRect);
					GetIText(dItem, gUEditText);
					if (key = char(13)) then
					begin
						b := true;
					end
					else if (CheckUEditAlpha) then
					begin
						if (key >= 'A') and (key <= 'z') then
						begin
							if (length(gUEditText) + 1 > CheckUEditLength) then
								b := true;
						end
						else if key <> char(8) then
							b := true;
					end
					else if (CheckUEditN) then
					begin
						if (key <= '9') and (key >= '0') then
						begin
							if (length(gUEditText) + 1 > CheckUEditLength) then
								b := true;
						end
						else if (key <> char(8)) then
							b := true;
					end
					else if (not CheckUEditN) and (length(gUEditText) + 1 > CheckUEditLength) and (key <> char(8)) then
						b := true;
				end;

				if (not b) then
				begin
					b := DialogSelect(event, theWindow, itemHit);
					if (whichWindow = GetUSelection) and (itemHit = 37) then
						CheckUEditAlpha := true
					else
						CheckUEditAlpha := false;
				end;
				if (whichWindow = GlobalUSearch) then
				begin
					gUEditText := GetTextBox(GlobalUSearch, 14);
					if gUEditText[1] = char(0) then
					begin
						Delete(gUEditText, 1, 1);
						SetTextBox(GlobalUSearch, 14, gUEditText);
					end;
				end;
			end
			else if (Event.what = AutoKey) and (FrontWindow = GlobalUSearch) then
			begin
				key := Char(BAnd(event.message, charCodeMask));
				if key = char(8) then
					b := DialogSelect(event, theWindow, itemHit);
			end
			else if (Event.what = UpDateEvt) then
			begin
				whichWindow := windowPtr(event.message);
				BeginUpdate(whichWindow);
				if whichWindow = sysConfig then
					UpdateSysConfig(event)
				else if whichWindow = GetUSelection then
					Update_User_Edit(whichWindow)
				else if whichWindow = GetFBSelection then
					Update_FB_Edit
				else if whichWindow = MessSetUp then
					Update_Message_Setup(whichwindow)
				else if whichWindow = NodeDilg then
					UpdateNodePrefs
				else if whichWindow = SystPrefs then
					UpdateSystemPrefs
				else if whichWindow = StringDilg then
					UpdateStrings
				else if WhichWindow = NodeDilg5 then
					UpdateMenuPrefs
				else if WhichWindow = MailDilg then
					UpdateMailPrefs
				else if WhichWindow = NodeDilg6 then
					UpdateTransPrefs
				else if whichWindow = GetSelection then
					Update_Security
				else if whichWindow = AccessDilg then
					Update_Access
				else if whichWindow = DialDialog then
					UpdateDialer
				else if whichWindow = NewDilg then
					Update_New
				else if whichWindow = GFileSelection then
					Update_Gfiles
				else if whichWindow = SearchSelection then
					UpdateUserSearch(whichWindow)
				else if whichWindow = GetULSelection then
					UpdateUserList(whichWindow)
				else if whichWindow = GetDSelection then
					UpdateTransferSections(whichWindow)
				else if whichWindow = BroadDilg then
					UpdateBroadCast
				else if whichwindow = GlobalUSearch then
					Update_GlobalUEdit(whichWindow)
				else if whichwindow = SSLockDlg then
					UpdateSSLock(whichWindow)
				else if whichWindow = ImportStatusDlg then
					DrawImportStatus(false, -99)
				else if whichWindow = ErrorDlg then
					UpdateErrorWindow(whichWindow)
				else if whichWindow = ChatroomDlg then
					UpdateChatroomSetup
				else if whichWindow = QuoterDlg then
					UpdateQuoterSetup
				else if whichWindow = theNodes[visibleNode]^.transDilg then
				begin
					DrawDialog(theNodes[visibleNode]^.transDilg);
					UpdateProgress;
				end;
				EndUpdate(whichWindow);
			end
			else if (DialogSelect(event, theWindow, itemhit)) and (event.what = mouseDown) then
			begin
				if theWindow = SysConfig then
					ClickSystemConfig(event, itemHit)
				else if theWindow = GetUSelection then
					Do_User_Edit(event, itemHit)
				else if theWindow = GetFBSelection then
					Do_FB_Edit(event, itemHit)
				else if theWindow = GetSelection then
					Do_Security(event, itemHit)
				else if theWindow = MessSetup then
					Do_Message_Setup(event, window, itemHit)
				else if theWindow = NodeDilg then
					ClickInNodePrefs(event, itemHit)
				else if theWindow = SystPrefs then
					DoSystemPrefs(event, itemHit)
				else if theWindow = BroadDilg then
					DoBroadCast(event, itemHit)
				else if theWindow = GFileSelection then
					Do_Gfiles(event, itemHit)
				else if theWindow = StringDilg then
					ClickStrings(event, itemHit)
				else if theWindow = NodeDilg5 then
					ClickInMenuPrefs(event, itemHit)
				else if theWindow = MailDilg then
					ClickInMailPrefs(event, itemHit)
				else if theWindow = NodeDilg6 then
					ClickInTransPrefs(event, itemHit)
				else if theWindow = AccessDilg then
					Do_Access(event, itemHit)
				else if theWindow = DialDialog then
					DoDialer(event, itemHit)
				else if theWindow = NewDilg then
					Do_New(Event, itemHit)
				else if theWindow = GetULSelection then
					DoUserList(event, ItemHit)
				else if theWindow = GlobalUSearch then
					Do_GlobalUEdit(event, itemHit)
				else if thewindow = GetDSelection then
					DoTransferSections(event, window, itemHit)
				else if theWindow = SearchSelection then
					DoUserSearch(event, ItemHit)
				else if theWindow = SSLockDlg then
					DoSSLock(event, ItemHit)
				else if theWindow = ErrorDlg then
					DoErrorWindow(event, ItemHit)
				else if theWindow = ChatroomDlg then
					DoChatroomSetup(event, ItemHit)
				else if theWindow = QuoterDlg then
					DoQuoterSetup(event, ItemHit)
				else if theWindow = theNodes[visibleNode]^.transDilg then
					if itemHit = 1 then
						AbortTrans;
			end;
		end
		else if not IsDil then
2:
			case tempEventWhat of
				mouseDown: 
				begin
					case part of
						inMenuBar: 
						begin
							if SysopAvailable then
								CheckItem(GetMHandle(mSysop), 3, true)
							else
								CheckItem(GetMHandle(mSysop), 3, false);
							if (theNodes[visibleNode]^.triedChat) then
								SetItemStyle(GetMHandle(mUser), 1, [bold])
							else
								SetItemStyle(GetMHandle(mUser), 1, []);
							for i := 15 to countMItems(getMHandle(mSysOp)) do
								DelMenuItem(getMHandle(mSysOp), 16);
							tvMenu := GetMHandle(mSysOp);
							if (theNodes[visibleNode]^.nodeType <= 0) then
								DisableItem(getMHandle(mSysop), 14)
							else
								EnableItem(getMHandle(mSysop), 14);
							for i := 1 to InitSystHand^^.numNodes do
							begin
								if (theNodes[i]^.boardMode = User) and (thenodes[i]^.thisUser.userNum > 0) then
								begin
									tempstring := stringOf(i : 0, ': ', theNodes[i]^.thisUser.userName);
									if theNodes[i]^.triedChat then
										tempstring := concat(tempstring, '  CHAT');
								end
								else
									tempstring := stringOf(i : 0, ': ', theNodes[i]^.nodename);
								AppendMenu(tvMenu, ' ');
								SetItem(tvMenu, countMItems(tvMenu), tempstring);
							end;
							CheckItem(tvMenu, visibleNode + 15, true);
							AppendMenu(tvMenu, '(-');
							AppendMenu(tvMenu, 'Status Window/\');
							if BAnd(event.modifiers, optionkey) <> 0 then
							begin
								InitSystHand^^.WUsers.top := 41;
								InitSystHand^^.WUsers.left := 365;
							end;
							DoMenuCommand(MenuSelect(event.where));
						end;
						inSysWindow: 
							SystemClick(event, window);
						inContent: 
						begin
							tempInt := isMyTextWindow(window);
							keyInt := isMyBBSWindow(window);
							if window <> FrontWindow then
							begin
								SelectWindow(window);
							end
							else if keyInt > 0 then
								DoANSIClick(keyInt, event.where, BAnd(event.modifiers, shiftKey) <> 0)
							else if (tempint >= 0) then
							begin
								with textWinds[tempint] do
								begin
									SetPort(w);
									aPoint := event.where;
									GlobalToLocal(aPoint);
									if PtInRect(aPoint, t^^.viewRect) then
									begin
										if textWinds[tempint].editable then
										begin
											shiftDown := BAnd(event.modifiers, shiftKey) <> 0;	{extend if Shift is down}
											TEClick(aPoint, shiftDown, t);
										end;
									end
									else
									begin
										part := FindControl(aPoint, w, control);
										case part of
											0: 
												;											{do nothing for viewRect case}
											inThumb: 
											begin
												value := GetCtlValue(control);
												part := TrackControl(control, aPoint, nil);
												if part <> 0 then
												begin
													value := value - GetCtlValue(control);
													if value <> 0 then
														if control = s then
															TEPinScroll(0, value * t^^.lineHeight, t);
												end;
											end;
											otherwise									{must be page or button}
												if control = s then
													value := TrackControl(control, aPoint, @VactionProc);
										end;
									end;
								end;
							end;
						end;
						inZoomIn, inZoomOut: 
						begin
							i := isMyBBSWindow(window);
							if i > 0 then
							begin
								if TrackBox(window, event.where, part) then
								begin
									with gBBSwindows[i]^ do
									begin
										SetPort(window);
										tempRect := ansiPort^.portRect;
										LocalToGlobal(tempRect.topLeft);
										LocalToGlobal(tempRect.botRight);
										GrowBBSwindow(i, savedWPos.right - savedWPos.left, savedWPos.bottom - savedWPos.top);
										MoveWindow(window, savedWPos.left, savedWPos.top, false);
										savedWPos := tempRect;
									end;
								end;
							end;
						end;
						inGoAway: 
							if TrackGoAway(Window, Event.where) then
							begin
								i := isMyTextWindow(window);
								part := ismyBBSwindow(window);
								if (part > 0) then
								begin
									CloseANSIWindow(part);
								end
								else if i >= 0 then
								begin
									CloseTextWindow(i);
								end
								else if window = statWindow then
									CloseStatWindow
								else if (GetWRefCon(window) = 4444) then
									CloseNodePrefs
								else if window = SysConfig then
									CloseSystemConfig
								else if (GetWRefCon(window) = 8888) then
								begin
									Close_User_Edit(window, false);
									statChanged := true;
								end
								else if (GetWRefCon(window) = 150) then
									Close_GlobalUEdit
								else if (GetWRefCon(window) = 277) then
									CloseSystemPrefs
								else if (GetWRefCon(window) = 992) then
									Close_FB_Edit
								else if (GetWRefCon(window) = 72469) then
									Close_Security
								else if (GetWRefCon(window) = 101364) then
									Close_Access
								else if (GetWRefCon(window) = 818) then
									CloseDialer
								else if (GetWRefCon(window) = 800) then
									Close_New
								else if (GetWRefCon(window) = 1590) then
									CloseBroadCast
								else if (GetWRefCon(window) = 4321) then
									CloseStrings
								else if (GetWRefCon(window) = 4440) then
									CloseMenuPrefs
								else if (GetWRefCon(window) = 4439) then
									CloseTransPrefs
								else if (GetWRefCon(window) = 250) then
									CloseMailPrefs
								else if (GetWRefCon(window) = 1993) then
									Close_GFiles
								else if (GetWRefCon(window) = 4995) then
									CloseUserList
								else if (GetWRefCon(window) = 3467) then
									CloseUserSearch
								else if (GetWRefCon(window) = 5555) then
									CloseTransferSections(window)
								else if (GetWRefCon(window) = 270) then
									CloseErrorWindow
								else if (GetWRefCon(window) = 265) then
									CloseChatroomSetup
								else if (GetWRefCon(window) = 235) then
									CloseQuoterSetup
								else if (GetWRefCon(window) = 175) then
								begin
									DoMForumRec(true);
									for i := 1 to InitSystHand^^.numMForums do
										DoMConferenceRec(true, i);
									doSystRec(true);
									Close_Message_SetUp(window);
								end;
							end;
						inDrag: 
						begin
							if window <> FrontWindow then
							begin
								SelectWindow(window);
							end
							else
							begin
								dumrect := screenbits.bounds;
								SetRect(dumRect, dumRect.Left + 5, dumRect.Top + 25, dumRect.Right - 5, dumRect.Bottom - 5);
								DragWindow(window, event.where, dumRect);
							end;
						end;
						inGrow: 
						begin
							tempInt := isMyTextWindow(window);
							keyInt := isMyBBSWindow(window);
							if window = GetULSelection then
							begin
								with screenBits.bounds do
									SetRect(tempRect, 140, 20, 140, 560);
								growResult := GrowWindow(window, event.where, tempRect);
								if growResult <> 0 then
								begin
									SizeWindow(window, LoWrd(growResult), HiWrd(growResult), TRUE);
								end;
							end
							else if window = statWindow then
							begin
								with screenBits.bounds do
									SetRect(tempRect, 64, 20, 768, 560);
								growResult := GrowWindow(window, event.where, tempRect);
								if growResult <> 0 then
								begin
									SizeWindow(window, LoWrd(growResult), HiWrd(growResult), TRUE);
								end;
							end
							else if (KeyInt > 0) then
							begin
								with screenBits.bounds do
									SetRect(tempRect, HERMESFONTWIDTH * 20 + NOTHINGSPACE * 2 + 16, HERMESFONTHEIGHT * 7 + NOTHINGSPACE * 2, HERMESFONTWIDTH * 80 + NOTHINGSPACE * 2 + 16, bottom);
								growResult := GrowWindow(window, event.where, tempRect);
								if growResult <> 0 then
								begin
									GrowBBSWindow(keyInt, loWrd(growResult), hiWrd(growResult));
								end;
							end
							else if (tempInt >= 0) then
							begin
								with textWinds[tempint] do
								begin
									with screenBits.bounds do
										SetRect(tempRect, 150, 64, 501, bottom);
									growResult := GrowWindow(w, event.where, tempRect);
									if growResult <> 0 then
									begin											{see if changed size}
										tempRect := t^^.viewRect;
										SizeWindow(w, LoWrd(growResult), HiWrd(growResult), TRUE);
										SetPort(w);
										t^^.viewRect.bottom := (HiWord(growResult) - 18);
										t^^.viewRect.right := (LoWord(growResult) - 18);
										AdjustViewRect(t);
										MoveControl(s, w^.portRect.right - 15, -1);
										SizeControl(s, 16, (w^.portRect.bottom - w^.portRect.top) - 13);
										AdjustScrollbars(tempInt, TRUE);
										AdjustTE(tempInt);
										HiLiteControl(s, 0);
										if ((t^^.viewRect.bottom - t^^.viewRect.top) div 11) > t^^.nLines then
											HiLiteControl(s, 255);
										InvalRect(w^.portRect);
									end;
								end;
							end;
						end;
					end;
				end;
				driverEvt: 
				begin

				end;
				keyDown, autoKey: 
				begin
					if not isDAWindow(frontWindow) then
					begin
						if screenSaver and InitSystHand^^.SSLock then
							Exit(DoEvent)
						else
							DoKeyDetect(event);
					end;
				end;
				activateEvt: 
					DoActivate(WindowPtr(event.message), BAnd(event.modifiers, activeFlag) <> 0);
				updateEvt: 
					DoUpdate(WindowPtr(event.message));
				diskEvt: 
					if HiWrd(event.message) <> noErr then
					begin
						SetPt(aPoint, kDILeft, kDITop);
						err := DIBadMount(aPoint, event.message);
					end;
				kHighLevelEvent: 
				begin
					result := AEProcessAppleEvent(event);
				end;
				kOSEvent: 
					case BAnd(BRotL(event.message, 8), $FF) of	{high byte of message}
						kSuspendResumeMessage: 
						begin
							gInBackground := BAnd(event.message, kResumeMask) = 0;
							DoActivate(FrontWindow, not gInBackground);
						end;
					end;
			end;
	end;

	procedure EventLoop;
		var
			gotEvent, isDil, noUsersOn, recognizedZero, anyoneOn, goodADSPNode: boolean;
			event: EventRecord;
			mouse, saveMouse: Point;
			tempDate, tempDate2: DateTimeRec;
			tempLong, tempLong2, lastActEvent: longInt;
			i, b, ImportCount: integer;
			t1, t2: str255;
	begin
		lastidle := tickCount;
		lastActEvent := tickCount;
		recognizedZero := false;
		if InitSystHand^^.SSLock then
			StartSS;
		repeat
			curGlobs := theNodes[visibleNode];
			activeNode := visibleNode;
			noUsersOn := true;
			for i := 1 to InitSystHand^^.numNodes do
				if (theNodes[i]^.boardMode = User) or ((theNodes[i]^.boardMode = Answering) and (theNodes[i]^.boardSection = TelnetNegotiation)) then
					noUsersOn := false;
			GetGlobalMouse(mouse);
			if not screenSaver then
			begin
				if (InitSystHand^^.screenSaver[0] = 1) then
				begin
					if not recognizedZero and (((mouse.h = 0) and (mouse.v = 0)) or (tickCount - lastActEvent > (longint(InitSystHand^^.screenSaver[1]) * longint(60) * longint(60)))) then
					begin
						if sshigh < tickCount then
						begin
							SSLow := TickCount + 180;
							SSHigh := TickCount + 360;
						end;
						if (tickCount > ssLow) and (tickCount < ssHigh) or (tickCount - lastActEvent > (longint(InitSystHand^^.screenSaver[1]) * longint(60) * longint(60))) then
						begin
							recognizedZero := true;
							saveMouse := mouse;
							SSLow := 0;
							SSHigh := 0;
							StartSS;
						end;
					end;
					AdjustCursor(mouse, cursorRgn);
				end;
			end
			else
			begin
				if (TickCount - lastSSDraw > 420) then
					DrawSSInfo;
			end;
			if (noUsersOn) and (not isGeneric) then
				gotEvent := WaitNextEvent(everyEvent, event, 10, cursorRgn)
			else
				gotEvent := WaitNextEvent(everyEvent, event, 0, cursorRgn);
			if not EqualPt(saveMouse, event.where) or ((event.what <> nullEvent) and (event.what <> activateEvt) and (event.what <> updateEvt) and (event.what <> app4Evt)) then
			begin
				if (event.where.h <> 0) or (event.where.v <> 0) then
					recognizedZero := false;
				lastActEvent := tickCount;
				saveMouse := event.where;
				if screenSaver and (not InitSystHand^^.SSLock) then
					EndSS
				else if screenSaver and InitSystHand^^.SSLock then
					OpenSSLock;
			end;
			if (InitSystHand^^.SSLock) and (SSCount + 900 < tickcount) and (screenSaver) and (SSCount <> 0) then
				CloseSSLock(false);

			if frontWindow <> nil then
			begin
				if isDialogEvent(event) then
					isDil := true
				else
					isDil := false;
			end
			else
				isDil := false;
			if (event.what = nullEvent) and (sysConfig <> nil) then
				CallSysopExternal(nulDev, -1, event);
			if gotEvent or isDil then
			begin
				AdjustCursor(event.where, cursorRgn);
				DoEvent(event, isDil);
			end;
			if (not gotEvent or ((lastIdle + 15) < tickCount)) and (quit = 0) then
			begin
				GetTime(tempDate);
				if InitSystHand^^.LastMaint.day <> tempDate.day then
				begin
					DoDailyMaint;
					for i := 1 to numExternals do
						if (myExternals^^[i].userExternal) then
							CallUserExternal(DOMAINTENCE, i);
				end;
				i := isMytextWindow(frontWindow);
				if i >= 0 then
					if textWinds[i].editable then
						TEIdle(textWinds[i].t);
				for i := 1 to numExternals do
					if (myExternals^^[i].userExternal) and (myExternals^^[i].allTheTime) then
						CallUserExternal(IDLE, i);

			{ Dispatch incoming ADSP connections. }
				if ((mppDrvrRefNum <> -1) and (gDSP.ioResult <> 1)) then
				begin
					goodADSPNode := false;
					for i := 1 to InitSystHand^^.NumNodes do
						if (theNodes[i]^.boardMode = Waiting) and (theNodes[i]^.nodeType = 2) then
						begin
							goodADSPNode := true;
							leave;
						end;
					if (i <= InitSystHand^^.numNodes) and answerCalls and goodADSPNode then
					begin
						curGlobs := theNodes[i];
						with curGlobs^ do
						begin
							activeNode := i;
							with nodeDSPPBPtr^ do
							begin
								ioCRefNum := dspDrvrRefNum;
								csCode := dspOpen;
								ccbRefNum := nodeCCBRefNum;
								ocMode := ocAccept;
								ocInterval := 0;
								ocMaximum := 0;
								remoteCID := gDSP.remoteCID;
								remoteAddress := gDSP.remoteAddress;
								sendSeq := gDSP.sendSeq;
								sendWindow := gDSP.sendWindow;
								attnSendSeq := gDSP.attnSendSeq;
							end;
							result := PBControl(ParmBlkPtr(nodeDSPPBPtr), false);
							if (result = noErr) then
							begin
								currentBaud := 57600;
								curBaudNote := ADSPNAME;
								sysopLogon := false;
								GetDateTime(tempLong);
								IUTimeString(tempLong, true, t1);
								LogThis(concat('ADSP connection made at ', t1), 0);
								DoLogon(true);
							end;
						end;
					end
					else
					begin
						with gDSP do
						begin
							csCode := dspCLDeny;
							ioCRefNum := dspDrvrRefNum;
							ccbRefNum := gCCBRef;
						end;
						result := PBControl(ParmBlkPtr(@gDSP), false);
						if result <> noErr then
							sysBeep(10);
					end;
					StartADSPListener;
				end;

			{ Accept incoming TCP connections. }
				if (ippDrvrRefNum <> -1) then
				begin
					for i := 1 to InitSystHand^^.NumNodes do
						if (theNodes[i]^.boardMode = Waiting) and (theNodes[i]^.nodeType = 3) then
							if ((TCPControlBlockPtr(theNodes[i]^.nodeTCPPBPtr)^.ioResult <> 1) and (TCPControlBlockPtr(theNodes[i]^.nodeTCPPBPtr)^.open.localport <> 0)) then
							begin
								curGlobs := theNodes[i];
								activeNode := i;
								if ((TCPControlBlockPtr(curGlobs^.nodeTCPPBPtr)^.ioResult = 0) and answerCalls) then
								begin
									curGlobs^.currentBaud := 57600;
									curGlobs^.curBaudNote := TCPNAME;
									curGlobs^.sysopLogon := false;
									IPAddrToString(TCPControlBlockPtr(curGlobs^.nodeTCPPBPtr)^.open.remotehost, t1);
									GetDateTime(tempLong);
									IUTimeString(tempLong, true, t2);
									LogThis(concat('TCP connection from ', t1, ' made at ', t2), 0);
									curGlobs^.BoardAction := None;
									curGlobs^.BoardMode := Answering;
									curGlobs^.BoardSection := TelnetNegotiation;
									curGlobs^.crossint := 1; { Telnet negotiation substage variable. }
								end
								else
								begin
									AbortTCPConnection;
									StartTCPListener;
								end;
							end;
				end;

				for i := 1 to InitSystHand^^.numNodes do
				begin
					curGlobs := theNodes[i];
					activeNode := i;
					IdleUser;
				end;
				if statChanged then
				begin
					UpdateStatWindow;
					statChanged := false;
				end;
				lastIdle := tickCount;
			end;

			if mailer^^.MailerAware then
			begin
				templong := tickcount;
				if (lastGenericCheck + 1200 < tempLong) and (not isGeneric) then {was 3600}
				begin
					doCheckForGeneric;	(* Check for a generic file *)
					if isGeneric then (* Generic File Was There *)
						ImportCount := 1;
				end
				else if isGeneric then
				begin
					ImportCount := ImportCount + 1;
					if lastGenericCheck + 600 < templong then
					begin
						lastGenericCheck := tickCount;
						anyoneOn := false;
						for i := 1 to InitSystHand^^.numNodes do
							if theNodes[i]^.BoardMode = User then
								anyoneOn := true;
						if anyoneOn and ((ImportLoopTime = 0) and (Mailer^^.ImportSpeed <> 1)) then
						begin
							if Mailer^^.ImportSpeed = 2 then
								ImportLoopTime := 8
							else if Mailer^^.ImportSpeed = 3 then
								ImportLoopTime := 20
							else
								ImportLoopTime := 40;
						end
						else if not anyoneOn then
							ImportLoopTime := 0;
					end;
					if ImportCount >= ImportLoopTime then
					begin
						for i := 1 to InitSystHand^^.numNodes do (* Find an available node *)
						begin
							curGlobs := theNodes[i];
							activeNode := i;
							with curglobs^ do
							begin
								if (curWriting = nil) and (BoardSection <> post) and (BoardSection <> ScanNew) and (BoardSection <> QScan) and (UseNode) then
								begin
									MailerDo := MailerOne;
									SavedImport := false;
									while not SavedImport do
										doMailerImport;	(* Import A Message *)
									ImportCount := 0;
									leave;
								end;
							end;
						end;
					end;
				end
				else
				begin
					GetDateTime(tempLong);
					if dailytabbyTime <> 0 then
					begin
						if (tempLong > dailytabbyTime) and (theNodes[Mailer^^.MailerNode]^.BoardMode = Waiting) then
						begin
							if Mailer^^.SubLaunchMailer = 1 then  {Shutdown Node}
							begin
								curGlobs := theNodes[Mailer^^.MailerNode];
								activeNode := Mailer^^.MailerNode;
								with curglobs^ do
								begin
									dailytabbyTime := dailytabbytime + 86400;
									TabbyQuit := NotTabbyQuit;
									TabbyPaused := true;
									CloseComPort;
									SavedInPort := InportName;
									InPortName := '';
									OpenComPort;
									GoWaitMode;
									LaunchMailer(False);
								end;
							end
							else if (Mailer^^.SubLaunchMailer = 2) then {Apple Events}
							begin
								;
							end
							else {Shutdown BBS}
							begin
								for i := 1 to InitSystHand^^.numNodes do
								begin
									curGlobs := theNodes[i];
									activeNode := i;
									with curglobs^ do
									begin
										if myTrans.active then
										begin
											repeat
												extTrans^^.flags[carrierLoss] := true;
												ContinueTrans;
											until not myTrans.active;
										end;
									end;
									HangUpandReset;
								end;
								tabbyQuit := MailerEvent;
								quit := 1;
							end;
						end;
					end;
				end;
			end;
			if (quit = 1) and (TabbyQuit = NotTabbyQuit) then
			begin
				b := 0;
				for i := 1 to InitSystHand^^.numNodes do
					if (theNodes[i]^.boardMode = User) then
						b := 1;
				if (b = 1) then
					quit := ModalQuestion(RetInStr(1), false, false);
			end;
		until quit > 0;
	end;

	procedure GetFinderFiles;
		var
			fftype, ffnum, i: integer;
			theFile: AppFile;
			ts: str255;
	begin
		CountAppFiles(fftype, ffnum);
		if (ffnum > 0) and (fftype = 0) then
		begin
			for i := 1 to ffnum do
			begin
				GetAppFiles(i, theFile);
				if thefile.ftype = 'TEXT' then
				begin
					ts := PathnameFromWD(thefile.vRefNum);
					OpenTextWindow(ts, thefile.fName, false, true);
				end
				else if theFile.fType = 'MODR' then
				begin

				end;
			end;
		end;
	end;

	function CheckMessagePath: boolean;
		var
			sTemp: str255;
			pbBlock: CInfoPBRec;
	begin
		checkMessagePath := true;
		sTemp := InitSystHand^^.msgsPath;
		with pbBlock do
		begin
			ioCompletion := nil;
			ioNamePtr := @sTemp;
			ioVRefNum := 0;
			ioFDirIndex := 0;
		end;
		result := PBGetCatInfo(@pbBlock, false);
		if (result <> noErr) then
		begin
			sTemp := concat(sharedPath, 'Messages:');
			result := PBGetCatInfo(@pbBlock, false);
			if (result = noErr) then
			begin
				InitSystHand^^.msgsPath := sTemp;
				InitSystHand^^.dataPath := concat(sharedPath, 'Data:');
				InitSystHand^^.gfilePath := concat(sharedPath, 'GFiles:');
				DoSystRec(true);
			end;
		end;
		if (result <> noErr) or OptionDown then
		begin
			globalStr := 'Select Messages directory:';
			stemp := doGetDirectory;
			if sTemp <> '' then
			begin
				InitSystHand^^.msgsPath := sTemp;
				DoSystRec(true);
			end
			else
				CheckMessagePath := false;
		end;
	end;

	procedure FindModemDriver;
		var
			i: integer;
	begin
		for i := 1 to numModemDrivers do
		begin
			if EqualString(modemDrivers^^[i - 1].name, curGlobs^.mDriverName, false, false) then
				curGlobs^.modemID := i - 1;
		end;
	end;

begin
	LoadSegments;
	ReserveMem(SizeOf(SystRec));
	InitSystHand := SystHand(NewHandleClear(SizeOf(SystRec)));
	HLock(handle(InitSystHand));
	InitHermes;
	OpenAboutBox;
	PrintStatus('Initializing Hermes...');
	if CheckMessagePath then
	begin
		MForum := MForumHand(NewHandleClear(SizeOf(MForumArray)));
		MoveHHi(handle(MForum));
		HNoPurge(handle(MForum));
		if (InitSystHand^^.numMForums > 0) and (InitSystHand^^.numMForums <= 20) then
			for i := 1 to InitSystHand^^.numMForums do
			begin
				MConference[i] := FiftyConferencesHand(NewHandleClear(SizeOf(FiftyConferences)));
				MoveHHi(handle(MConference[i]));
				HNoPurge(handle(MConference[i]));
			end
		else
			InitSystHand^^.numMForums := 0;
		intGFileRec := GFileSecHand(NewHandle(SizeOf(GFileSecRec)));
		MoveHHi(handle(intGFileRec));
		HNoPurge(handle(intGFileRec));
		InitFBHand := FeedBackHand(NewHandle(SizeOf(FeedBackRec)));
		MoveHHi(handle(InitFBHand));
		HNoPurge(handle(InitFBHand));
		MenuHand := NodeMenuHand(NewHandle(SizeOf(NodeMenuRec)));
		MoveHHi(handle(MenuHand));
		HNoPurge(handle(MenuHand));
		TransHand := TransMenuHand(NewHandle(SizeOf(TransMenuRec)));
		MoveHHi(handle(TransHand));
		HNoPurge(handle(TransHand));
		ForumIdx := ForumIdxHand(NewHandleClear(SizeOf(ForumIdxRec)));
		MoveHHi(handle(ForumIdx));
		HNoPurge(handle(ForumIdx));
		NewHand := NewUserHand(NewHandleClear(SizeOf(NewUserRec)));
		MoveHHi(handle(NewHand));
		HNoPurge(handle(NewHand));
		Mailer := MailerHand(NewHandleClear(SizeOf(MailerRec)));
		MoveHHi(handle(Mailer));
		HNoPurge(handle(Mailer));
		SecLevels := SecLevHand(NewHandleClear(SizeOf(NewSecurity)));
		MoveHHi(handle(SecLevels));
		HNoPurge(handle(SecLevels));
		ChatHand := ChatHandle(NewHandle(sizeOf(ChatRec)));
		MoveHHi(handle(ChatHand));
		for i := 1 to InitSystHand^^.numNodes do
		begin
			theNodes[i]^.AddressBook := AddressBookHand(NewHandleClear(sizeOf(AddressBookArray)));
			MoveHHi(handle(theNodes[i]^.AddressBook));
		end;
		PrintStatus('Loading Messages...');
		DoMForumRec(false);
		HLock(handle(MForum));
		if InitSystHand^^.numMForums > 0 then
			for i := 1 to InitSystHand^^.numMForums do
				DoMConferenceRec(false, i);
		PrintStatus('Loading Transfers...');
		DoForumRec(False);
		LoadDirectories;
		PrintStatus('Loading Mailer Preferences...');
		DoMailerRec(False);
		for i := 1 to InitSystHand^^.numNodes do
			theNodes[i]^.doCrashMail := false;
		if Mailer^^.MailerAware then
			theNodes[Mailer^^.MailerNode]^.doCrashMail := Mailer^^.AllowCrashMail
		else
			DisableItem(getMHandle(mSysop), 11);
		PrintStatus('Loading G-Files...');
		DoGFileRec(false);
		PrintStatus('Loading Main Menu...');
		DoMenuRec(false);
		PrintStatus('Loading Transfer Menu...');
		DoTransRec(false);
		PrintStatus('Loading New User Preferences');
		LoadNewUser(false);
		PrintStatus('Loading Security Levels...');
		DoSecRec(False);
		PrintStatus('Loading System Preferences...');
		DoSystRec(true);
		PrintStatus('Loading Feedback...');
		DoFBRec(false);
		PrintStatus('Loading Help...');
		LoadHelpFile;
		theNodes[1]^.invalidSerialJump := nil;
		theNodes[1]^.expiredJump := nil;
		PrintStatus('Making User List...');
		MakeUserList;
		PrintStatus('Analyzing External Protocols...');
		AnalyzeProtocols;
		PrintStatus('Loading Modem Drivers...');
		LoadModemDrivers;
		PrintStatus('Loading Externals...');
		MakeExtList;
		if (not EscDown) then
		begin
			PrintStatus('Checking Paths...');
			CheckSomePaths;
			if not InitSystHand^^.NoXFerPathChecking then
			begin
				PrintStatus('Checking Transfer Paths...');
				CheckTransferPaths;
			end;
		end;
		PrintStatus('Loading Action Words...');
		ChatHand^^.NumActionWords := 0;
		ChatHand^^.NumChannels := 1;
		ChatHand^^.Channels[0].Active := true;
		ChatHand^^.Channels[0].ChannelName := RetInStr(762); {Main Chatroom}
		ChatHand^^.Channels[0].NumInChannel := 0;
		LoadActionWordList;
		PrintStatus('Opening Windows...');
		if InitSystHand^^.wIsOpen[0] then
			OpenStatWindow;
		if InitSystHand^^.WuserOpen then
			OpenUserList;
		for i := 1 to InitSystHand^^.numNodes do
		begin
			theNodes[i]^.invalidSerialJump := theNodes[1]^.invalidSerialJump;
			theNodes[i]^.expiredJump := theNodes[1]^.expiredJump;
		end;
		PrintStatus('Setting Up Fonts...');
		SetFontVars;
		for i := 1 to InitSystHand^^.numNodes do
			AllocateANSIWindow(i);
		PrintStatus('Setting Up Nodes...');
		for i := 1 to InitSystHand^^.numNodes do
		begin
			with theNodes[i]^ do
			begin
				activeNode := i;
				curGlobs := theNodes[i];
				OpenComPort;
				FindModemDriver;
				sendingNow := NewPtr(SENDNOWBUFSIZE);
				myBlocker.ioResult := noErr;
				toBeSent := nil;
				extTrans := nil;
				ExternVars := 0;
				HangupAndReset;
			end;
		end;
		theSysExtRec := HermDataPtr(NewPtr(SizeOf(HermDataRec) + (4 * 30)));
		with theSysExtRec^ do
		begin
			SysPrivates := nil;
			HEMail := theEMail;
			NumHermUsers := @numUserRecs;
			extantEmails := @availEmails;
			emailUnclean := @emailDirty;
			procs[0] := @SetGeneva;						(* Mac Interface Stuff/Sysop Externals *)
			procs[1] := @SetTextBox;
			procs[2] := @GetTextBox;
			procs[3] := @SetCheckBox;
			procs[4] := @GetCheckBox;
			procs[5] := @SetControlBox;
			procs[6] := @UpDown;
			procs[7] := @UpDownReal;
			procs[8] := @OptionDown;
			procs[9] := @CmdDown;
			procs[10] := @AddListString;
			procs[11] := @ModalQuestion;
			procs[12] := @FrameIt;
			procs[13] := @ProblemRep;
			procs[14] := @DoSystRec;					(* Load And Save Stuff *)
			procs[15] := @DoMenuRec;
			procs[16] := @DoTransRec;
			procs[17] := @DoForumRec;
			procs[18] := @DoGFileRec;
			procs[19] := @DoMailerRec;
			procs[20] := @DoSecRec;
			procs[21] := @LoadNewUser;
			procs[22] := @DoFBRec;
			procs[23] := @DoMForumRec;
			procs[24] := @DoMConferenceRec;
			procs[25] := @FindUser;						(* User Stuff *)
			procs[26] := @WriteUser;
			procs[27] := @Copy1File;					(* Misc. Stuff *)
			procs[28] := @StartMySound;
			procs[29] := @SaveText;
		end;

		theExtRec := UserXIPtr(NewPtr(SizeOf(UserXInfoRec) + (4 * 174)));
		with theExtRec^ do
		begin
			prefs := nil;
			privates := nil;
			totalNodes := InitSystHand^^.numNodes;
			message := 0;
			curNode := @activeNode;
			curUGlobs := @curGlobs;
			filesPath := @sharedPath;
			HEMail := theEMail;
			NumHermUsers := @numUserRecs;
			extantEmails := @availEmails;
			emailUnclean := @emailDirty;
			externals := myExternals;
			numExternal := numExternals;
			for i := 1 to MAX_NODES do
				n[i] := theNodes[i];
			procs[0] := @bCR;									(* OutLine Stuff *)
			procs[1] := @OutLine;
			procs[2] := @OutLineC;
			procs[3] := @OutLineSysOp;
			procs[4] := @BufferIt;
			procs[5] := @BufferBcr;
			procs[6] := @BufClearScreen;
			procs[7] := @ReleaseBuffer;
			procs[8] := @OutChr;
			procs[9] := @ANSICode;
			procs[10] := @DoM;
			procs[11] := @ClearScreen;
			procs[12] := @BackSpace;
			procs[13] := @SingleNodeOutput;
			procs[14] := @Broadcast;
			procs[15] := @LettersPrompt;			(* Prompt Stuff *)
			procs[16] := @NumbersPrompt;
			procs[17] := @YesNoQuestion;
			procs[18] := @PromptUser;
			procs[19] := @PAUSEPrompt;
			procs[20] := @ANSIPrompter;
			procs[21] := @ReprintPrompt;
			procs[22] := @FindUser;						(* User Stuff *)
			procs[23] := @WriteUser;
			procs[24] := @InitUserRec;
			procs[25] := @UserAllowed;
			procs[26] := @ResetUserColors;
			procs[27] := @PrintUserStuff;
			procs[28] := @YearsOld;
			procs[29] := @UserOnSystem;
			procs[30] := @WhatNode;
			procs[31] := @WhatUser;
			procs[32] := @GiveTime;
			procs[33] := @TicksLeft;
			procs[34] := @TickToTime;
			procs[35] := @DoSystRec;					(* Load And Save Stuff *)
			procs[36] := @DoMenuRec;
			procs[37] := @DoTransRec;
			procs[38] := @DoForumRec;
			procs[39] := @DoGFileRec;
			procs[40] := @DoMailerRec;
			procs[41] := @DoSecRec;
			procs[42] := @LoadNewUser;
			procs[43] := @DoFBRec;
			procs[44] := @DoMForumRec;
			procs[45] := @DoMConferenceRec;
			procs[46] := @PrintConfList;			(* Message Stuff *)
			procs[47] := @PrintForumList;
			procs[48] := @FindConference;
			procs[49] := @FigureDisplayConf;
			procs[50] := @OpenMData;
			procs[51] := @SaveMessage;
			procs[52] := @ReadMessage;
			procs[53] := @PrintCurMessage;
			procs[54] := @RemoveMessage;
			procs[55] := @SavePost;
			procs[56] := @SaveNetPost;
			procs[57] := @AddLine;
			procs[58] := @DeletePost;
			procs[59] := @TakeMsgTop;
			procs[60] := @EnterMessage;
			procs[61] := @MForumOp;
			procs[62] := @MConferenceOp;
			procs[63] := @MForumOk;
			procs[64] := @MConferenceOk;
			procs[65] := @OpenBase;
			procs[66] := @SaveBase;
			procs[67] := @CloseBase;
			procs[68] := @LoadFileAsMsg;
			procs[69] := @ReadTextFile;
			procs[70] := @IsPostRatioOk;
			procs[71] := @ReadAutoMessage;
			procs[72] := @OpenEMail;					(* E-Mail Stuff *)
			procs[73] := @CloseEMail;
			procs[74] := @FindMyEmail;
			procs[75] := @SaveMessAsEmail;
			procs[76] := @SaveEMailData;
			procs[77] := @HeReadIt;
			procs[78] := @DeleteMail;
			procs[79] := @DeleteFileAttachment;
			procs[80] := @AreaOp;							(* Transfer Stuff *)
			procs[81] := @DirOp;
			procs[82] := @ForumOk;
			procs[83] := @SubDirOk;
			procs[84] := @DownloadOk;
			procs[85] := @FindSub;
			procs[86] := @FindArea;
			procs[87] := @HowManySubs;
			procs[88] := @PrintDirList;
			procs[89] := @PrintSubDirList;
			procs[90] := @PrintTree;
			procs[91] := @PrintExtended;
			procs[92] := @ReadExtended;
			procs[93] := @AddExtended;
			procs[94] := @DeleteExtDesc;
			procs[95] := @OpenDirectory;
			procs[96] := @SaveDirectory;
			procs[97] := @CloseDirectory;
			procs[98] := @SortDir;
			procs[99] := @GetNextFile;
			procs[100] := @FileEntry;
			procs[101] := @PrintFileInfo;
			procs[102] := @FExist;
			procs[103] := @ListFil;
			procs[104] := @FileOKMask;
			procs[105] := @DoUpload;
			procs[106] := @DoDownload;
			procs[107] := @DoRename;
			procs[108] := @DLRatioOK;
			procs[109] := @OpenComPort;				(* Serial Port Stuff *)
			procs[110] := @CloseComPort;
			procs[111] := @Get1ComPort;
			procs[112] := @TellModem;
			procs[113] := @ClearInBuf;
			procs[114] := @AppleTalk;
			procs[115] := @ADSPBytesToRead;
			procs[116] := @StartADSPListener;
			procs[117] := @OpenADSPListener;
			procs[118] := @CloseADSPListener;
			procs[119] := @LogError;						(* Utility Procs *)
			procs[120] := @GoHome;
			procs[121] := @HangupandReset;
			procs[122] := @EndUser;
			procs[123] := @LogThis;
			procs[124] := @GetDate;
			procs[125] := @WhatTime;
			procs[126] := @Secs2Time;
			procs[127] := @DoCapsName;
			procs[128] := @DoNumber;
			procs[129] := @AsyncMWrite;
			procs[130] := @mySDGetBuf;
			procs[131] := @mySyncRead;
			procs[132] := @Copy1File;						(* Misc. Stuff *)
			procs[133] := @OpenCapture;
			procs[134] := @CloseCapture;
			procs[135] := @InTrash;
			procs[136] := @SaveText;
			procs[137] := @AgeOk;
			procs[138] := @RetInStr;
			procs[139] := @MakeADir;
			procs[140] := @StartMySound;
			procs[141] := @OutAnsiTest;
			procs[142] := @SysOpAvailable;
			procs[143] := @Freek;
			procs[144] := @PrintSysOpStats;
			procs[145] := @DoMailerImport;
			procs[146] := @DoDetermineZMH;
			procs[147] := @LaunchMailer;
			procs[148] := @DecodeM;
			procs[149] := @MakeColorSequence;
			procs[150] := @DoAddressBooks;
			procs[151] := @UpdateANSIInChannel;	(* Chat Room Stuff *)
			procs[152] := @DoShowUserActivity;
			procs[153] := @ScrollBackNForward;
			procs[154] := @ScrollHome;
			procs[155] := @ChatroomScrollClear;
			procs[156] := @ChatroomEnterExit;
			procs[157] := @ChatroomBroadcast;
			procs[158] := @ChatroomSingle;
			procs[159] := @GetNodeNumber;
			procs[160] := @DisposeChatRoom;
			procs[161] := @ChatroomUserSetup;
			procs[162] := @ChatroomBackSpace;
			procs[163] := @MoveCursor;
			procs[164] := @DrawChatroom;
			procs[165] := @ClearBox;
			procs[166] := @ClearANSIRoom;
			procs[167] := @ListActionWords;
			procs[168] := @ResetPrivateData;
			procs[169] := @SortActionWordList;
			procs[170] := @LoadActionWordList;
			procs[171] := @SaveRemoveActionWord;
			procs[172] := @DecipherActionWord;
			procs[173] := @WrapActionText;
		end;

{ See if we need to install the color table for version 3.5.9 and above. }
		if (InitSystHand^^.version < 359) then
		begin
			InitSystHand^^.version := SYSTREC_VERSION;
			ResetSystemColors(InitSystHand);
			InitSystHand^^.DebugTelnet := false;
			InitSystHand^^.DebugTelnetToFile := false;
			DoSystRec(true);
		end;

		if InitSystHand^^.startDate = 0 then
			GetDateTime(InitSystHand^^.startDate);
		for i := 1 to numExternals do
			if (myExternals^^[i].userExternal) then
				CallUserExternal(DOINITILIZE, i);
		cursorRgn := NewRgn;
		result := CallUtility(BUILDMENU, pointer(@theNodes[visibleNode]^.myProcMenu), longint($03F10001));
		if theNodes[visibleNode]^.nodeType = -1 then
			DisableItem(getMHandle(mSysop), 14);
		DrawMenuBar;
		CloseAboutBox;
		writeDirectToLog := true;
		LogThis('', 0);
		LogThis(stringOf('***** Hermes ', HERMES_VERSION, ' started up at ', whattime(-1), ' on ', getdate(-1), '.'), 0);
		LogThis('', 0);
		writeDirectToLog := false;
		if mailer^^.MailerAware then
		begin
			GBytes := 0;
			lastGenericCheck := 0;
			isGeneric := false;
			doDetermineZMH;
		end;
		for i := 1 to InitSystHand^^.numNodes do
		begin
			curGlobs := theNodes[i];
			activeNode := i;
			RemoveSlowDeviceFiles;
		end;

		if (gMac.systemVersion < $0700) then
			GetFinderFiles
		else
		begin
			result := AEInstallEventHandler(kCoreEventClass, kAEOpenDocuments, @HandleAEOpenDoc, 0, false);
			result := AEInstallEventHandler(kCoreEventClass, kAEQuitApplication, @HandleAEQuitApp, 0, false);
			result := AEInstallEventHandler('HRMS', 'Logo', @HandleAEHLogoff, 0, false);
			result := AEInstallEventHandler(Fido_Class, Fido_ReleaseNode, @HandleAEReleaseNode, 0, false);
			result := AEInstallEventHandler(Fido_Class, Fido_NeedNode, @HandleAENeedNode, 0, false);
		end;

		EventLoop;

		if myExternals <> nil then
		begin
			for i := 1 to numExternals do
			begin
				if myExternals^^[i].userExternal then
				begin
					for nameorDesc := 1 to InitSystHand^^.numNodes do
					begin
						curGlobs := theNodes[nameorDesc];
						activeNode := nameorDesc;
						CallUserExternal(CLOSEEXTERNAL, i);
					end;
					if not myExternals^^[i].runtimeExternal then
					begin
						HUnlock(handle(myExternals^^[i].codeHandle));
						ReleaseResource(myExternals^^[i].codeHandle);
						CloseResFile(myExternals^^[i].UResoFile);
					end;
				end;
				if myExternals^^[i].iconHandle <> nil then
				begin
					HPurge(myExternals^^[i].iconHandle);
					DisposHandle(myExternals^^[i].iconhandle);
				end;
			end;
			DisposHandle(handle(myExternals));
			myExternals := nil;
		end;

		DisposeRgn(cursorRgn);
		CloseNodePrefs;
		for i := 1 to InitSystHand^^.numNodes do
			DisposeANSIWindow(i);
		CloseStatWindow;
		CloseEmail;
		result := CallUtility(DISPOSETMENU, ptr(theNodes[visibleNode]^.myProcMenu), 0);

		Close_Message_SetUp(MessSetUp);
		CloseSystemConfig;
		CloseSystemPrefs;
		Close_User_Edit(getUSelection, true);
		Close_FB_Edit;
		CloseStrings;
		CloseTransPrefs;
		CloseMailPrefs;
		CloseMenuPrefs;
		Close_Security;
		Close_Access;
		Close_New;
		Close_GFiles;
		CloseUserList;
		CloseUserSearch;
		CloseDialer;
		CloseBroadcast;
		CloseTransferSections(GetDSelection);
		Close_GlobalUEdit;
		CloseErrorWindow;
		CloseChatroomSetup;
		CloseQuoterSetup;

		DisposHandle(handle(ActionWordHand));
		ActionWordHand := nil;
		DisposeChatRoom(-1);	{-1 = All Rooms}

		if numTextWinds > 0 then
		begin
			for i := 1 to numtextWinds do
				CloseTextWindow(0);
		end;
		CloseAboutBox;
		for i := 1 to InitSystHand^^.numNodes do
			if theNodes[i]^.AddressBook <> nil then
			begin
				DisposHandle(handle(theNodes[i]^.AddressBook));
				theNodes[i]^.AddressBook := nil;
			end;

		for i := 1 to InitSystHand^^.numNodes do
		begin
			curGlobs := theNodes[i];
			activeNode := i;
			with curglobs^ do
			begin
				result := FSDelete(StringOf(sharedPath, 'Misc:Local Workspace ', activeNode : 0), 0);
				if (BoardMode = User) and (thisUser.userNum > 0) then
					writeUser(thisUser);
				if (nodeType = 1) and answerCalls then
					TellModem('ATZ');
				TerminateRun;
			end;
		end;
		if (mppDrvrRefNum <> -1) then
			CloseADSPListener;
		DisposHandle(handle(modemDrivers));
		if (setNewNodes > 0) then
		begin
			InitSystHand^^.numNodes := setNewNodes;
			DoSystRec(true);
		end;

		DisposHandle(handle(myUsers));
	end;
	CloseResFile(StringsRes);
	CloseResFile(TextRes);
	DoSystRec(True);
	HUnLock(handle(MForum));
	DisposHandle(handle(MForum));
	HUnlock(handle(initSystHand));
	DisposHandle(handle(initSystHand));
	if (TabbyQuit = CrashMail) then
		LaunchMailer(True)
	else if (TabbyQuit = MailerEvent) then
		LaunchMailer(False);
end.