{ Segments MesEdit2_1 }
unit Message_Editor2;
interface
	uses
		AppleTalk, ADSP, Serial, Sound, TCPTypes, Initial, LoadAndSave, NodePrefs2;

	procedure Open_Message_Setup;
	procedure Update_Message_Setup (theWindow: WindowPtr);
	procedure Do_Message_Setup (theEvent: EventRecord; theWindow: WindowPtr; itemHit: integer);
	procedure Close_Message_SetUp (theWindow: WindowPtr);

implementation
	var
		curForum, r, n1: integer;
		MForumList, ConferenceList: ListHandle;
		StatusBarDlg: DialogPtr;
		ByOne: boolean;
		q: longint;

{$S MesEdit2_1}
	procedure DrawUserStatus (UserOn: integer);
		var
			itemType, tempInt: integer;
			itemHandle: handle;
			tempRect: rect;
			l: longint;
	begin
		if UserOn = -1 then	{Initial Setup}
		begin
			SetCursor(GetCursor(watchCursor)^^);
			StatusBarDlg := GetNewDialog(200, nil, pointer(-1));
			SetPort(StatusBarDlg);
			SetGeneva(StatusBarDlg);
			SetTextBox(StatusBarDlg, 1, '              User :');
			SetTextBox(StatusBarDlg, 2, '0');
			SetTextBox(StatusBarDlg, 4, 'Total Users :');
			SetTextBox(StatusBarDlg, 7, StringOf(numUserRecs : 0));
			SetTextBox(StatusBarDlg, 6, '');
			SetTextBox(StatusBarDlg, 5, '');
			SetTextBox(StatusBarDlg, 8, '');
			GetDItem(StatusBarDlg, 3, itemType, itemHandle, tempRect);
			ForeColor(blackColor);
			EraseRect(tempRect);
			FrameRect(tempRect);
			SetWTitle(WindowPtr(StatusBarDlg), 'Update Message Pointers');
			tempInt := tempRect.right - tempRect.left;
			if numUserRecs <= tempInt then
				ByOne := false
			else
				ByOne := true;
			q := round((numUserRecs / tempint));
			r := 0;
			n1 := 0;
			DrawDialog(StatusBarDlg);
		end
		else if UserOn = -99 then	{Finished}
		begin
			SetPort(StatusBarDlg);
			GetDItem(StatusBarDlg, 3, itemType, itemHandle, tempRect);
			ForeColor(BlackColor);
			FrameRect(tempRect);
			ForeColor(BlueColor);
			InsetRect(tempRect, 1, 1);
			PaintRect(tempRect);
			ForeColor(BlackColor);
			delay(90, l);
			DisposDialog(StatusBarDlg);
			StatusBarDlg := nil;
			SetCursor(arrow);
			SetPort(MessSetup);
			Update_Message_SetUp(WindowPtr(MessSetUp));
		end
		else
		begin
			r := r + 1;
			if r >= q then
			begin
				if ByOne then
					n1 := n1 + 1
				else
					n1 := UserOn;
				r := 0;

				SetPort(StatusBarDlg);
				GetDItem(StatusBarDlg, 3, itemType, itemHandle, tempRect);
				ForeColor(BlackColor);
				FrameRect(tempRect);
				ForeColor(BlueColor);

				if NumUserRecs <= tempRect.right - tempRect.left then
					tempInt := ((tempRect.right - tempRect.left) * n1) div NumUserRecs
				else
					tempInt := n1;
				if tempInt > (tempRect.right - tempRect.left) then
					tempint := (tempRect.right - tempRect.left);
				tempRect.right := tempRect.left + tempInt;
				if tempRect.right > temprect.left then
				begin
					InsetRect(tempRect, 1, 1);
					PaintRect(tempRect);
				end;
				ForeColor(blackColor);
			end;
			SetTextBox(StatusBarDlg, 2, StringOf(UserOn : 0));
		end;
		giveBBSTime;
	end;

{$D-}
	function FindCell (TheList: ListHandle; mousPos: point): cell;
		var
			startCell, selCell: cell;
			temprect: rect;
	begin
		StartCell := cell($00000000);
		selCell := cell($FFFFFFFF);
		repeat
			LRect(temprect, startCell, TheList);
			if PtInRect(mousPos, tempRect) then
				selCell := startCell;
		until not LNextCell(false, true, startCell, TheList);
		FindCell := selcell;
	end;

	function MouseVSSelected (aList: listHandle; aCell: cell): boolean;
		var
			curPoint: point;
			bCell: cell;
	begin
		GetMouse(curPoint);
		bCell := FindCell(aList, cell(curPoint));
		if longint(bCell) = longint(aCell) then
			MouseVSSelected := true
		else
			MouseVSSelected := false;
	end;

	function ForumLDragger: boolean;
		var
			myCell, myCell2: cell;
			tempRect: rect;
			tempBool: boolean;
			curMouse: point;
			i, x, y, z, useddiff, savedNumBoards: integer;
			movedTo, hDiff, vDiff, l: longint;
			takeThis, toHere, wasOnline: integer;
			dragged: rgnHandle;
			s1: str255;
			tUser: UserRec;
			SavedForum: ForumRec;
			MovingConfs: FiftyConferencesHand;
			MessPtrs: array[1..50] of longint;
			MessQScans: array[1..50] of boolean;
	begin
		SetPort(MessSetup);
		myCell := cell($00000000);
		GetMouse(curMouse);
		tempbool := LGetSelect(true, myCell, MForumList);
		tempBool := MouseVSSelected(MForumList, myCell);
		if (myCell.v >= 0) and (myCell.v < MForumList^^.dataBounds.bottom) and tempBool then
		begin
			LRect(temprect, myCell, MForumList);
			MForumList^^.clikLoc.v := curMouse.v;
			dragged := NewRgn;
			OpenRgn;
			FrameRect(tempRect);
			CloseRgn(dragged);
			movedTo := DragGrayRgn(dragged, MForumList^^.clikLoc, MForumList^^.rView, MessSetup^.portRect, vAxisOnly, nil);
			DisposeRgn(dragged);
			vDiff := hiWord(movedTo);
			hDiff := LoWord(movedTo);
			usedDiff := temprect.top + abs(vDiff);
			if ((vDiff <> $8000) and (hDiff <> $8000)) and (abs(usedDiff - tempRect.top) > 8) then
			begin
				curMouse.v := MForumList^^.clikLoc.v + vDiff;
				curmouse.h := MForumList^^.clikLoc.h + hDiff;
				myCell2.h := 0;
				myCell2.v := 0;
				myCell2 := FindCell(MForumList, curMouse);

				if (longint(mycell2) <> $FFFFFFFF) and (longint(mycell2) <> longint(myCell)) then
				begin
					takeThis := myCell.v + 1;
					toHere := myCell2.v + 1;
					if ModalQuestion('All of the users high message pointers will have to be reset, continue?', false, true) = 1 then
					begin
						DrawUserStatus(-1);
						for i := 1 to numUserRecs do
						begin
							s1 := StringOf(i : 0);
							DrawUserStatus(i);
							if FindUser(s1, tUser) then
							begin
								wasOnline := 0;
								for z := 1 to InitSystHand^^.numNodes do
									if (theNodes[z]^.thisUser.userNum > 0) and (theNodes[z]^.thisUser.userNum = tUser.UserNum) and (theNodes[z]^.boardMode = user) then
									begin
										for x := 1 to InitSystHand^^.numMForums do
											for y := 1 to 50 do
											begin
												tUser.LastMsgs[x, y] := theNodes[z]^.thisUser.LastMsgs[x, y];
												tUser.WhatNScan[x, y] := theNodes[z]^.thisUser.WhatNScan[x, y];
											end;
										wasOnline := z;
										leave;
									end;

								for x := 1 to 50 do
								begin
									MessPtrs[x] := tUser.LastMsgs[takeThis, x];
									MessQScans[x] := tUser.WhatNScan[takeThis, x];
								end;
								if toHere < takeThis then
									for x := takeThis downto toHere + 1 do
									begin
										for y := 1 to 50 do
										begin
											tUser.LastMsgs[x, y] := tUser.LastMsgs[x - 1, y];
											tUser.WhatNScan[x, y] := tUser.WhatNScan[x - 1, y];
										end;
									end
								else if tohere > takeThis then
								begin
									for x := takeThis to toHere - 1 do
										for y := 1 to 50 do
										begin
											tUser.LastMsgs[x, y] := tUser.LastMsgs[x + 1, y];
											tUser.WhatNScan[x, y] := tUser.WhatNScan[x + 1, y];
										end;
								end;

								for x := 1 to 50 do
								begin
									tUser.LastMsgs[toHere, x] := MessPtrs[x];
									tUser.WhatNScan[toHere, x] := MessQScans[x];
								end;

								if wasOnline <> 0 then
									for x := 1 to InitSystHand^^.numMForums do
										for y := 1 to 50 do
										begin
											theNodes[wasOnline]^.thisUser.LastMsgs[x, y] := tUser.LastMsgs[x, y];
											theNodes[wasOnline]^.thisUser.WhatNScan[x, y] := tUser.WhatNScan[x, y];
										end;

								WriteUser(tUser);
							end;
						end;
						DrawUserStatus(-99);

						savedForum := MForum^^[takeThis];
						MovingConfs := FiftyConferencesHand(NewHandleClear(SizeOf(FiftyConferences)));
						HNoPurge(handle(MovingConfs));

						MovingConfs^^ := MConference[takeThis]^^;
						if toHere < takethis then
						begin
							for i := takeThis downto toHere + 1 do
							begin
								MForum^^[i] := MForum^^[i - 1];
								MConference[i]^^ := MConference[i - 1]^^;
							end;
						end
						else if toHere > takethis then
						begin
							for i := takeThis to toHere - 1 do
							begin
								MForum^^[i] := MForum^^[i + 1];
								MConference[i]^^ := MConference[i + 1]^^;
							end;
						end;
						MForum^^[toHere] := savedForum;
						for i := 1 to 50 do
							MConference[toHere]^^ := MovingConfs^^;
						HPurge(handle(MovingConfs));
						DisposHandle(handle(MovingConfs));
						MovingConfs := nil;
						LDelRow(0, 0, MForumList);
						for i := 1 to InitSystHand^^.numMForums do
						begin
							AddListString(MForum^^[i].Name, MForumList);
						end;
					end;
				end;
			end;
		end;
		ForumLDragger := true;
	end;

	function ConferenceLDragger: boolean;
		var
			myCell, myCell2: cell;
			tempRect: rect;
			DItem: handle;
			tempBool: boolean;
			tempConf: ConferenceRec;
			curMouse: point;
			i, x, z, savedNode, useddiff, DType: integer;
			movedTo, hDiff, vDiff, l: longint;
			takeThis, toHere, wasOnline: integer;
			dragged: rgnHandle;
			s1: str255;
			tUser: UserRec;
	begin
		SetPort(MessSetup);
		GetMouse(curMouse);
		myCell := cell($00000000);
		tempbool := LGetSelect(true, myCell, ConferenceList);
		tempBool := MouseVSSelected(ConferenceList, myCell);
		if ((myCell.v >= 0) and (myCell.v < ConferenceList^^.dataBounds.bottom)) and tempBool then
		begin
			LRect(temprect, myCell, ConferenceList);
			ConferenceList^^.clikLoc.v := curMouse.v;
			dragged := NewRgn;
			OpenRgn;
			FrameRect(tempRect);
			CloseRgn(dragged);
			movedTo := DragGrayRgn(dragged, ConferenceList^^.clikLoc, ConferenceList^^.rView, MessSetup^.portRect, vAxisOnly, nil);
			DisposeRgn(dragged);
			vDiff := hiWord(movedTo);
			hDiff := LoWord(movedTo);

			usedDiff := temprect.top + abs(vDiff);
{if usedDiff >= 247 then}
{LScroll(0, 1, ConferenceList);}
			if ((vDiff <> $8000) and (hDiff <> $8000)) and (abs(usedDiff - tempRect.top) > 8) then
			begin
				curMouse.v := ConferenceList^^.clikLoc.v + vDiff;
				curmouse.h := ConferenceList^^.clikLoc.h + hDiff;
				myCell2.h := 0;
				myCell2.v := 0;
				myCell2 := FindCell(ConferenceList, curMouse);

				if (longint(mycell2) <> $FFFFFFFF) and (longint(mycell2) <> longint(myCell)) then
				begin
					takeThis := myCell.v + 1;
					toHere := myCell2.v + 1;
					if ModalQuestion('All of the users high message pointers will have to be reset, continue?', false, true) = 1 then
					begin
						DrawUserStatus(-1);
						for i := 1 to numUserRecs do
						begin
							s1 := StringOf(i : 0);
							DrawUserStatus(i);
							if FindUser(s1, tUser) then
							begin
								wasOnline := 0;
								for z := 1 to InitSystHand^^.numNodes do
									if (theNodes[z]^.thisUser.userNum > 0) and (theNodes[z]^.thisUser.userNum = tUser.UserNum) and (theNodes[z]^.boardMode = user) then
									begin
										for x := 1 to MForum^^[curForum].numConferences do
										begin
											tUser.LastMsgs[curForum, x] := theNodes[z]^.thisUser.LastMsgs[curForum, x];
											tUser.WhatNScan[curForum, x] := theNodes[z]^.thisUser.WhatNScan[curForum, x];
										end;
										wasOnline := z;
										leave;
									end;

								l := tUser.LastMsgs[curForum, takeThis];
								tempBool := tUser.WhatNScan[curForum, takeThis];
								if toHere < takeThis then
								begin
									for x := takeThis downto toHere + 1 do
									begin
										tUser.LastMsgs[curForum, x] := tUser.LastMsgs[curForum, x - 1];
										tUser.WhatNScan[curForum, x] := tUser.WhatNScan[curForum, x - 1];
									end;
								end
								else if tohere > takeThis then
								begin
									for x := takeThis to toHere - 1 do
									begin
										tUser.LastMsgs[curForum, x] := tUser.LastMsgs[curForum, x + 1];
										tUser.WhatNScan[curForum, x] := tUser.WhatNScan[curForum, x + 1];
									end;
								end;
								tUser.LastMsgs[curForum, toHere] := l;
								tUser.WhatNScan[curForum, toHere] := tempBool;
								if wasOnline <> 0 then
									for x := 1 to MForum^^[curForum].numConferences do
									begin
										theNodes[wasOnline]^.thisUser.LastMsgs[curForum, x] := tUser.LastMsgs[curForum, x];
										theNodes[wasOnline]^.thisUser.WhatNScan[curForum, x] := tUser.WhatNScan[curForum, x];
									end;

								WriteUser(tUser);
							end;
						end;
						DrawUserStatus(-99);

						tempConf := MConference[curForum]^^[takeThis];
						if toHere < takethis then
						begin
							for i := takeThis downto toHere + 1 do
								MConference[curForum]^^[i] := MConference[curForum]^^[i - 1];
						end
						else if toHere > takethis then
						begin
							for i := takeThis to toHere - 1 do
								MConference[curForum]^^[i] := MConference[curForum]^^[i + 1];
						end;
						MConference[curForum]^^[toHere] := tempConf;

						LDelRow(0, 0, ConferenceList);
						LDoDraw(False, ConferenceList);
						for i := 1 to MForum^^[curForum].NumConferences do
						begin
							AddListString(MConference[curForum]^^[i].Name, ConferenceList);
						end;
						LDoDraw(True, ConferenceList);
						GetDItem(MessSetup, 8, DType, DItem, tempRect);
						tempRect.Right := tempRect.Right - 15;
						InsetRect(tempRect, -1, -1);
						FrameRect(tempRect);
						LUpdate(ConferenceList^^.port^.visRgn, ConferenceList);
					end;
				end;
			end;
		end;
		ConferenceLDragger := true;
	end;
{$D+}

	procedure Open_Message_SetUp;
		var
			DType, i: integer;
			DItem: handle;
			tempRect, tempRect2: rect;
			cSize: cell;
	begin
		if (MessSetup = nil) then
		begin
			MessSetup := GetNewDialog(175, nil, pointer(-1));
			SetPort(MessSetup);
			SetGeneva(MessSetup);

			(* Setup Forum List *)
			GetDItem(MessSetup, 4, DType, DItem, tempRect);
			tempRect.right := tempRect.right - 15;
			InsetRect(tempRect, -1, -1);
			FrameRect(tempRect);
			InsetRect(tempRect, 1, 1);
			SetRect(tempRect2, 0, 0, 1, 0);
			cSize.h := tempRect.right - tempRect.left;
			cSize.v := 15;
			MForumList := LNew(tempRect, tempRect2, cSize, 0, MessSetup, FALSE, FALSE, FALSE, TRUE);
			MForumList^^.selFlags := lOnlyOne + lNoNilHilite;
			MForumList^^.lClikLoop := @ForumLDragger;
			if InitSystHand^^.numMForums > 0 then
				for i := 1 to InitSystHand^^.numMForums do
					AddListString(MForum^^[i].Name, MForumList);

			cSize.v := 0;
			cSize.h := 0;
			LSetSelect(True, cSize, MForumList);
			LDoDraw(true, MForumList);
			curForum := 1;

			(* Setup Conference List *)
			GetDItem(MessSetup, 8, DType, DItem, tempRect);
			tempRect.right := tempRect.right - 15;
			InsetRect(tempRect, -1, -1);
			FrameRect(tempRect);
			InsetRect(tempRect, 1, 1);
			SetRect(tempRect2, 0, 0, 1, 0);
			cSize.h := tempRect.right - tempRect.left;
			cSize.v := 15;
			ConferenceList := LNew(tempRect, tempRect2, cSize, 0, MessSetup, FALSE, FALSE, FALSE, TRUE);
			ConferenceList^^.selFlags := lOnlyOne + lNoNilHilite;
			ConferenceList^^.lClikLoop := @ConferenceLDragger;
			if InitSystHand^^.numMForums > 0 then
				for i := 1 to MForum^^[curForum].numConferences do
					AddListString(MConference[curForum]^^[i].Name, ConferenceList);

			cSize.v := 0;
			cSize.h := 0;
			LSetSelect(True, cSize, ConferenceList);
			LDoDraw(true, ConferenceList);
			ShowWindow(MessSetup);
		end
		else
			SelectWindow(MessSetup);
	end;

	procedure Update_Message_Setup;
		var
			SavedPort: GrafPtr;
			DType: integer;
			DItem: handle;
			tempRect: rect;
	begin
		if (MessSetup <> nil) and (theWindow = MessSetup) then
		begin
			GetPort(SavedPort);
			SetPort(MessSetup);
			DrawDialog(MessSetUp);

			(* Update MForumList *)
			GetDItem(MessSetup, 4, DType, DItem, tempRect);
			tempRect.Right := tempRect.Right - 15;
			InsetRect(tempRect, -1, -1);
			FrameRect(tempRect);
			if (MForumList <> nil) then
				LUpdate(MForumList^^.port^.visRgn, MForumList);

			(* Update ConferenceList *)
			GetDItem(MessSetup, 8, DType, DItem, tempRect);
			tempRect.Right := tempRect.Right - 15;
			InsetRect(tempRect, -1, -1);
			FrameRect(tempRect);
			if (ConferenceList <> nil) then
				LUpdate(ConferenceList^^.port^.visRgn, ConferenceList);
			SetPort(SavedPort);
		end;
	end;

	function EditMessageForum (Which: integer): boolean;
		var
			ForumDlg, ModeratorDlg: DialogPtr;
			itemHit, DType, i, adder: integer;
			DItem: handle;
			tempRect: rect;
			s1: str255;
			tUser: UserRec;
	begin
		ForumDlg := GetNewDialog(176, nil, Pointer(-1));
		SetPort(ForumDlg);
		SetGeneva(ForumDlg);
		SetTextBox(ForumDlg, 2, MForum^^[Which].Name);
		SetTextBox(ForumDlg, 4, StringOf(MForum^^[Which].MinSL : 0));
		SetTextBox(ForumDlg, 13, StringOf(MForum^^[Which].MinAge : 0));
		if MForum^^[Which].AccessLetter <> char(0) then
			SetTextBox(ForumDlg, 9, MForum^^[Which].AccessLetter);
		if FindUser(stringOf(MForum^^[Which].Moderators[1] : 0), tUser) then
			SetTextBox(ForumDlg, 23, stringOf(tUser.username, ' #', tUser.usernum : 0));
		if FindUser(stringOf(MForum^^[Which].Moderators[2] : 0), tUser) then
			SetTextBox(ForumDlg, 22, stringOf(tUser.username, ' #', tUser.usernum : 0));
		if FindUser(stringOf(MForum^^[Which].Moderators[3] : 0), tUser) then
			SetTextBox(ForumDlg, 21, stringOf(tUser.username, ' #', tUser.usernum : 0));
		GetDItem(ForumDlg, 1, DType, DItem, tempRect);
		InsetRect(tempRect, -4, -4);
		PenSize(3, 3);
		FrameRoundRect(tempRect, 16, 16);
		SelIText(ForumDlg, 2, 0, 32767);
		DrawDialog(ForumDlg);
		repeat
			ModalDialog(@useModalTime, itemHit);
			if optiondown then
				adder := 1
			else
				adder := 10;
			case itemHit of
				5, 6: 
				begin
					if (itemHit = 5) then
						adder := adder * (-1);
					MForum^^[Which].MinSL := UpDown(ForumDlg, 4, MForum^^[Which].MinSL, Adder, 255, 0);
				end;
				14, 15: 
				begin
					if (itemHit = 14) then
						adder := adder * (-1);
					MForum^^[Which].MinAge := UpDown(ForumDlg, 13, MForum^^[Which].MinAge, adder, 99, 0);
				end;
				21, 22, 23: 
				begin
					ModeratorDlg := GetNewDialog(178, nil, pointer(-1));
					SetPort(ModeratorDlg);
					SetGeneva(ModeratorDlg);
					i := 24 - itemHit;
					if FindUser(stringOf(MForum^^[Which].Moderators[i] : 0), tUser) then
						ParamText(StringOf('Current Administrator: ', tUser.UserName, ' #', tUser.UserNum : 0), 'Enter name or number, * wildcard allowed.', 'To remove a moderator enter a 0', '')
					else
						ParamText('Current Administrator: None', 'Enter name or number, * wildcard allowed.', 'To remove an administrator enter a 0.', '');
					DrawDialog(ModeratorDlg);
					repeat
						ModalDialog(@useModalTime, i)
					until (i = 1) or (i = 4);
					s1 := GetTextBox(ModeratorDlg, 3);
					DisposDialog(ModeratorDlg);
					SetPort(ForumDlg);
					if i = 1 then
					begin
						i := 24 - itemHit;
						if FindUser(s1, tUser) and (s1 <> '0') then
						begin
							MForum^^[Which].Moderators[i] := tUser.UserNum;
							SetTextBox(ForumDlg, itemHit, stringOf(tUser.username, ' #', tUser.usernum : 0));
						end
						else if s1 = '0' then
						begin
							MForum^^[Which].Moderators[i] := 0;
							SetTextBox(ForumDlg, itemHit, ' ');
						end;
					end;
					DrawDialog(ForumDlg);
				end;
			end;
		until (itemHit = 1) or (itemHit = 11);
		if itemHit = 1 then
		begin
			s1 := GetTextBox(ForumDlg, 2);
			if ((length(s1) < 1) or (length(s1) > 41)) or (s1[1] <= char(32)) then
			begin
				ProblemRep('The name of your forum must be from 1 to 41 characters long. The forum name will not be changed.');
				s1 := MForum^^[Which].Name;
			end
			else if (pos(':', s1) <> 0) then
			begin
				ProblemRep('The name of your forum cannot contain a colon. The forum name will not be changed.');
				s1 := MForum^^[Which].Name;
			end
			else
			begin
				for i := 1 to InitSystHand^^.numMForums do
					if (s1 = MForum^^[i].Name) and (i <> Which) then
					begin
						ProblemRep('Duplicate forum name.  The forum name will not be changed.');
						s1 := MForum^^[Which].Name;
						leave;
					end;
			end;
			MForum^^[Which].Name := s1;
			s1 := GetTextBox(ForumDlg, 9);
			if ((ord(s1[1]) > 64) and (ord(s1[1]) < 91)) or ((ord(s1[1]) > 96) and (ord(s1[1]) < 123)) then
			begin
				if ord(s1[1]) > 96 then
					s1[1] := chr(ord(s1[1]) - 32)
				else if (length(s1) < 1) then
					s1[1] := char(0);
			end
			else
				s1[1] := char(0);
			MForum^^[Which].AccessLetter := s1;
			EditMessageForum := true;
		end
		else
			EditMessageForum := false;
		DisposDialog(ForumDlg);
		ForumDlg := nil;
	end;

	procedure WriteAreasBBS;
		var
			result: OSErr;
			refNum: integer;
			count: longint;
			areaNum, areaLine: Str255;
			forumNum, confNum: integer;
	begin
	{ Delete any pre-existing Areas.BBS file. }
		result := FSDelete(concat(sharedPath, 'Misc:Areas.BBS'), 0);

	{ Write out a new Areas.BBS file. }
		result := Create(concat(sharedPath, 'Misc:Areas.BBS'), 0, 'HRMS', 'DATA');
		if result = noErr then
		begin
			result := FSOpen(concat(sharedPath, 'Misc:Areas.BBS'), fsRdWrPerm, refNum);
			if result = noErr then
			begin
			{ Write out the origin line. }
				areaLine := concat(mailer^^.hwtOriginLine, Char(10));
				count := longint(areaLine[0]);
				result := FSWrite(refNum, count, @areaLine[1]);

			{ Write out all of the area lines. }
				for forumNum := 1 to ForumIdx^^.numForums do
					for confNum := 1 to MForum^^[forumNum].numConferences do
						if MConference[forumNum]^^[confNum].ConfType = 1 then
						begin
							NumToString((forumNum * 100) + confNum, areaNum);
							areaLine := concat(areaNum, ' ', MConference[forumNum]^^[confNum].EchoName, Char(10));
							count := longint(areaLine[0]);
							result := FSWrite(refNum, count, @areaLine[1]);
						end;

			{ Close the new Areas.BBS file. }
				result := FSClose(refNum);
			end;
		end;
	end;

	function EditMessageConference (Which: integer; New: boolean): boolean;
		var
			ConferenceDlg, ModeratorDlg: DialogPtr;
			itemHit, DType, adder, i, j, DirNum: integer;
			DItem: handle;
			tempRect: rect;
			s1: str255;
			tUser: UserRec;
			l: longint;
			FileForum: boolean;
			newForum: ReadDirHandle;
	begin
		ConferenceDlg := GetNewDialog(177, nil, Pointer(-1));
		SetPort(ConferenceDlg);
		SetGeneva(ConferenceDlg);
		if New then
		begin
			MConference[curForum]^^[Which].Name := StringOf('Conference #', Which : 0);
			if (Which > 1) then
			begin
				MConference[curForum]^^[Which].SLtoRead := MConference[curForum]^^[Which - 1].SLtoRead;
				MConference[curForum]^^[Which].SLtoPost := MConference[curForum]^^[Which - 1].SLtoPost;
				MConference[curForum]^^[Which].MaxMessages := MConference[curForum]^^[Which - 1].MaxMessages;
				MConference[curForum]^^[Which].AnonID := MConference[curForum]^^[Which - 1].AnonID;
				MConference[curForum]^^[Which].MinAge := MConference[curForum]^^[Which - 1].MinAge;
				MConference[curForum]^^[Which].AccessLetter := MConference[curForum]^^[Which - 1].AccessLetter;
				MConference[curForum]^^[Which].Threading := MConference[curForum]^^[Which - 1].Threading;
				MConference[curForum]^^[Which].ConfType := MConference[curForum]^^[Which - 1].ConfType;
				MConference[curForum]^^[Which].RealNames := MConference[curForum]^^[Which - 1].RealNames;
				MConference[curForum]^^[Which].ShowCity := MConference[curForum]^^[Which - 1].ShowCity;
				MConference[curForum]^^[Which].FileAttachments := MConference[curForum]^^[Which - 1].FileAttachments;
				MConference[curForum]^^[Which].DLCost := MConference[curForum]^^[Which - 1].DLCost;
				MConference[curForum]^^[Which].EchoName := MConference[curForum]^^[Which - 1].EchoName;
				MConference[curForum]^^[Which].Moderators[1] := 0;
				MConference[curForum]^^[Which].Moderators[2] := 0;
				MConference[curForum]^^[Which].Moderators[3] := 0;
				MConference[curForum]^^[Which].NewUserRead := MConference[curForum]^^[Which - 1].NewUserRead;
				for i := 1 to 25 do
					MConference[curForum]^^[Which].reserved[i] := char(0);
			end
			else
			begin
				MConference[curForum]^^[Which].SLtoRead := 5;
				MConference[curForum]^^[Which].SLtoPost := 30;
				MConference[curForum]^^[Which].MaxMessages := 50;
				MConference[curForum]^^[Which].AnonID := 0;
				MConference[curForum]^^[Which].MinAge := 0;
				MConference[curForum]^^[Which].AccessLetter := char(0);
				MConference[curForum]^^[Which].Threading := true;
				MConference[curForum]^^[Which].ConfType := 0;
				MConference[curForum]^^[Which].RealNames := false;
				MConference[curForum]^^[Which].ShowCity := false;
				MConference[curForum]^^[Which].FileAttachments := false;
				MConference[curForum]^^[Which].DLCost := 0.0;
				MConference[curForum]^^[Which].EchoName := char(0);
				MConference[curForum]^^[Which].Moderators[1] := 0;
				MConference[curForum]^^[Which].Moderators[2] := 0;
				MConference[curForum]^^[Which].Moderators[3] := 0;
				MConference[curForum]^^[Which].NewUserRead := false;
				for i := 1 to 25 do
					MConference[curForum]^^[Which].reserved[i] := char(0);
			end;
		end;
		SetTextBox(ConferenceDlg, 10, MConference[curForum]^^[Which].Name);
		if MConference[curForum]^^[Which].AccessLetter <> char(0) then
			SetTextBox(ConferenceDlg, 11, MConference[curForum]^^[Which].AccessLetter);
		SetTextBox(ConferenceDlg, 22, StringOf(MConference[curForum]^^[Which].SLToRead : 0));
		SetTextBox(ConferenceDlg, 23, StringOf(MConference[curForum]^^[Which].SLToPost : 0));
		SetTextBox(ConferenceDlg, 26, StringOf(MConference[curForum]^^[Which].MaxMessages : 0));
		SetTextBox(ConferenceDlg, 29, StringOf(MConference[curForum]^^[Which].MinAge : 0));
		SetCheckBox(ConferenceDlg, 17, False);
		SetCheckBox(ConferenceDlg, 18, False);
		SetCheckBox(ConferenceDlg, 35, False);
		SetCheckBox(ConferenceDlg, 50, MConference[curForum]^^[Which].FileAttachments);
		SetCheckBox(ConferenceDlg, 32, MConference[curForum]^^[Which].NewUserRead);
		case MConference[curForum]^^[Which].AnonID of
			0: {Never, Disallow}
				SetCheckBox(ConferenceDlg, 18, True);
			1: {Force}
				SetCheckBox(ConferenceDlg, 35, True);
			otherwise	{Allow}
				SetCheckBox(ConferenceDlg, 17, True);
		end;
		SetCheckBox(ConferenceDlg, 30, MConference[curForum]^^[Which].Threading);
		if NewHand^^.Handle and NewHand^^.RealName then
			SetCheckBox(ConferenceDlg, 36, MConference[curForum]^^[Which].RealNames)
		else
		begin
			GetDItem(ConferenceDlg, 36, DType, DItem, tempRect);
			HiLiteControl(ControlHandle(DItem), 255);
		end;
		if Newhand^^.City then
			SetCheckBox(ConferenceDlg, 44, MConference[curForum]^^[Which].ShowCity)
		else
		begin
			GetDItem(ConferenceDlg, 44, DType, DItem, tempRect);
			HiLiteControl(ControlHandle(DItem), 255);
		end;
		SetCheckBox(ConferenceDlg, 34, False);
		SetCheckBox(ConferenceDlg, 45, False);
		SetCheckBox(ConferenceDlg, 46, False);
		if Mailer^^.MailerAware then
		begin
			if MConference[curForum]^^[Which].ConfType = 1 then
				SetCheckBox(ConferenceDlg, 45, True)
			else if MConference[curForum]^^[Which].ConfType = 2 then
				SetCheckBox(ConferenceDlg, 46, True)
			else
				SetCheckBox(ConferenceDlg, 34, True);
			if (MConference[curForum]^^[Which].ConfType = 1) or (MConference[curForum]^^[Which].ConfType = 2) then
			begin
				if MConference[curForum]^^[Which].EchoName <> char(0) then
					SetTextBox(ConferenceDlg, 49, MConference[curForum]^^[Which].EchoName)
				else
					SetTextBox(ConferenceDlg, 49, '');
			end
			else
			begin
				HideDItem(ConferenceDlg, 48);
				HideDItem(ConferenceDlg, 49);
			end;
		end
		else
		begin
			GetDItem(ConferenceDlg, 45, DType, DItem, tempRect);
			HiLiteControl(ControlHandle(DItem), 255);
			GetDItem(ConferenceDlg, 46, DType, DItem, tempRect);
			HiLiteControl(ControlHandle(DItem), 255);
			SetCheckBox(ConferenceDlg, 34, True);
			HideDItem(ConferenceDlg, 48);
			HideDItem(ConferenceDlg, 49);
		end;
		if FindUser(stringOf(MConference[curForum]^^[Which].Moderators[1] : 0), tUser) then
			SetTextBox(ConferenceDlg, 40, stringOf(tUser.username, ' #', tUser.usernum : 0));
		if FindUser(stringOf(MConference[curForum]^^[Which].Moderators[2] : 0), tUser) then
			SetTextBox(ConferenceDlg, 39, stringOf(tUser.username, ' #', tUser.usernum : 0));
		if FindUser(stringOf(MConference[curForum]^^[Which].Moderators[3] : 0), tUser) then
			SetTextBox(ConferenceDlg, 38, stringOf(tUser.username, ' #', tUser.usernum : 0));
		SelIText(ConferenceDlg, 10, 0, 32767);
		ShowWindow(ConferenceDlg);
		GetDItem(ConferenceDlg, 1, DType, DItem, tempRect);
		InsetRect(tempRect, -4, -4);
		PenSize(3, 3);
		FrameRoundRect(tempRect, 16, 16);
		repeat
			ModalDialog(@useModalTime, itemHit);
			if optiondown then
				adder := 1
			else
				adder := 10;
			case itemHit of
				2, 3: 
				begin
					if (itemHit = 2) then
						adder := adder * (-1);
					MConference[curForum]^^[Which].MinAge := UpDown(ConferenceDlg, 29, MConference[curForum]^^[Which].MinAge, Adder, 99, 0);
				end;
				4, 5: 
				begin
					if (itemHit = 4) then
						adder := adder * (-1);
					MConference[curForum]^^[Which].MaxMessages := UpDown(ConferenceDlg, 26, MConference[curForum]^^[Which].MaxMessages, Adder, 999, 1);
				end;
				6, 7: 
				begin
					if (itemHit = 6) then
						adder := adder * (-1);
					MConference[curForum]^^[Which].SLToPost := UpDown(ConferenceDlg, 23, MConference[curForum]^^[Which].SLToPost, Adder, 255, 0);
				end;
				8, 9: 
				begin
					if (itemHit = 8) then
						adder := adder * (-1);
					MConference[curForum]^^[Which].SLToRead := UpDown(ConferenceDlg, 22, MConference[curForum]^^[Which].SLToRead, Adder, 255, 0);
				end;
				17, 18, 35: 
				begin
					SetCheckBox(ConferenceDlg, 17, False);
					SetCheckBox(ConferenceDlg, 18, False);
					SetCheckBox(ConferenceDlg, 35, False);
					case itemHit of
						18: {Never, Disallow}
						begin
							SetCheckBox(ConferenceDlg, 18, True);
							MConference[curForum]^^[Which].AnonID := 0;
						end;
						35: {Force}
						begin
							SetCheckBox(ConferenceDlg, 35, True);
							MConference[curForum]^^[Which].AnonID := 1;
						end;
						otherwise	{Allow}
						begin
							SetCheckBox(ConferenceDlg, 17, True);
							MConference[curForum]^^[Which].AnonID := -1;
						end;
					end;
				end;
				30: 
				begin
					MConference[curForum]^^[Which].Threading := not MConference[curForum]^^[Which].Threading;
					SetCheckBox(ConferenceDlg, 30, MConference[curForum]^^[Which].Threading);
				end;
				32: 
				begin
					MConference[curForum]^^[Which].NewUserRead := not MConference[curForum]^^[Which].NewUserRead;
					SetCheckBox(ConferenceDlg, 32, MConference[curForum]^^[Which].NewUserRead);
				end;
				34, 45, 46: 
				begin
					SetCheckBox(ConferenceDlg, 34, False);
					SetCheckBox(ConferenceDlg, 45, False);
					SetCheckBox(ConferenceDlg, 46, False);
					case itemHit of
						34: 
						begin
							MConference[curForum]^^[Which].ConfType := 0;
							MConference[curForum]^^[Which].EchoName := char(0);
							HideDItem(ConferenceDlg, 48);
							HideDItem(ConferenceDlg, 49);
						end;
						45: 
						begin
							MConference[curForum]^^[Which].ConfType := 1;
							MConference[curForum]^^[Which].EchoName := char(0);
							ShowDItem(ConferenceDlg, 48);
							ShowDItem(ConferenceDlg, 49);
						end;
						46: 
						begin
							MConference[curForum]^^[Which].ConfType := 2;
							MConference[curForum]^^[Which].EchoName := char(0);
							ShowDItem(ConferenceDlg, 48);
							ShowDItem(ConferenceDlg, 49);
						end;
					end;
					SetCheckBox(ConferenceDlg, itemHit, True);
				end;
				36: 
				begin
					MConference[curForum]^^[Which].RealNames := not MConference[curForum]^^[Which].RealNames;
					SetCheckBox(ConferenceDlg, 36, MConference[curForum]^^[Which].RealNames);
				end;
				50: 
				begin
					MConference[curForum]^^[Which].FileAttachments := not MConference[curForum]^^[Which].FileAttachments;
					SetCheckBox(ConferenceDlg, 50, MConference[curForum]^^[Which].FileAttachments);
					if (MConference[curForum]^^[Which].FileAttachments) then
					begin
						FileForum := false;
						for i := 1 to forumIdx^^.numDirs[0] do
							if (forums^^[0].dr[i].DirName = 'Message Attachments') then
								FileForum := true;
						if (not FileForum) and (ForumIdx^^.numDirs[0] + 1 < 65) then
						begin
							ForumIdx^^.numDirs[0] := ForumIdx^^.numDirs[0] + 1;
							DirNum := ForumIdx^^.numDirs[0];
							forums^^[0].dr[DirNum].DirName := 'Message Attachments';
							s1 := concat(InitSystHand^^.DataPath, forumIdx^^.name[0], ':', forums^^[0].dr[DirNum].dirName);
							result := Create(s1, 0, 'HRMS', 'DATA');
							CreateResFile(s1);
							CloseResFile(OpenResFile(s1));
							forums^^[0].dr[DirNum].Path := forums^^[0].dr[1].Path;
							forums^^[0].dr[DirNum].MinDSL := 255;
							forums^^[0].dr[DirNum].DSLtoUL := 10;
							forums^^[0].dr[DirNum].DSLtoDL := 255;
							forums^^[0].dr[DirNum].MaxFiles := 1000;
							forums^^[0].dr[DirNum].Restriction := char(0);
							forums^^[0].dr[DirNum].NonMacFiles := 0;
							forums^^[0].dr[DirNum].mode := 0;
							forums^^[0].dr[DirNum].MinAge := 0;
							forums^^[0].dr[DirNum].FileNameLength := 31;
							forums^^[0].dr[DirNum].freeDir := false;
							forums^^[0].dr[DirNum].AllowUploads := false;
							forums^^[0].dr[DirNum].Handles := false;
							forums^^[0].dr[DirNum].ShowUploader := true;
							forums^^[0].dr[DirNum].Color := 0;
							forums^^[0].dr[DirNum].TapeVolume := false;
							forums^^[0].dr[DirNum].SlowVolume := false;
							for i := 1 to 3 do
								forums^^[0].dr[DirNum].Operators[i] := 0;
							forums^^[0].dr[DirNum].DLCost := 1.0;
							forums^^[0].dr[DirNum].ULCost := 0.0;
							forums^^[0].dr[DirNum].DLCreditor := 0.0;
							forums^^[0].dr[DirNum].HowLong := 0;
							forums^^[0].dr[DirNum].UploadOnly := false;
							i := OpenRFPerm(concat(SharedFiles, 'Directories'), 0, fsRdWrPerm);
							newForum := ReadDirHandle(GetNamedResource('Dirs', forumIdx^^.name[0]));
							RmveResource(handle(newForum));
							DisposeHandle(handle(newForum));
							newForum := ReadDirHandle(NewHandleClear(SizeOf(DirDataFile)));
							HLock(handle(newForum));
							newForum^^ := forums^^[0];
							AddResource(handle(newForum), 'Dirs', UniqueId('Dirs'), ForumIdx^^.name[0]);
							WriteResource(handle(newForum));
							DetachResource(handle(newForum));
							HUnlock(handle(newForum));
							DisposHandle(handle(newForum));
							CloseResFile(i);
							DoForumRec(True);
						end
						else if (not FileForum) and (ForumIdx^^.numDirs[0] + 1 > 64) then
						begin
							ProblemRep('Aborted, you will exceed the 64 directory limit.');
							MConference[curForum]^^[Which].FileAttachments := False;
							SetCheckBox(ConferenceDlg, 50, MConference[curForum]^^[Which].FileAttachments);
						end;
					end;
				end;
				38, 39, 40: 
				begin
					ModeratorDlg := GetNewDialog(178, nil, pointer(-1));
					SetPort(ModeratorDlg);
					SetGeneva(ModeratorDlg);
					i := 41 - itemHit;
					if FindUser(stringOf(MConference[curForum]^^[Which].Moderators[i] : 0), tUser) then
						ParamText(StringOf('Current Administrator: ', tUser.UserName, ' #', tUser.UserNum : 0), 'Enter name or number, * wildcard allowed.', 'To remove a moderator enter a 0', '')
					else
						ParamText('Current Administrator: None', 'Enter name or number, * wildcard allowed.', 'To remove an administrator enter a 0.', '');
					DrawDialog(ModeratorDlg);
					repeat
						ModalDialog(@useModalTime, i)
					until (i = 1) or (i = 4);
					s1 := GetTextBox(ModeratorDlg, 3);
					DisposDialog(ModeratorDlg);
					SetPort(ConferenceDlg);
					if i = 1 then
					begin
						i := 41 - itemHit;
						if FindUser(s1, tUser) and (s1 <> '0') then
						begin
							if (tUser.usernum <> MConference[curForum]^^[Which].Moderators[1]) and (tUser.usernum <> MConference[curForum]^^[Which].Moderators[2]) and (tUser.usernum <> MConference[curForum]^^[Which].Moderators[3]) then
							begin
								MConference[curForum]^^[Which].Moderators[i] := tUser.UserNum;
								SetTextBox(ConferenceDlg, itemHit, stringOf(tUser.username, ' #', tUser.usernum : 0));
							end
							else
								ProblemRep('That user is already an administrator for this directory.');
						end
						else if s1 = '0' then
						begin
							MConference[curForum]^^[Which].Moderators[i] := 0;
							SetTextBox(ConferenceDlg, itemHit, ' ');
						end
						else
							ProblemRep('No Such User.');
					end;
					DrawDialog(ConferenceDlg);
				end;
				44: 
				begin
					MConference[curForum]^^[Which].ShowCity := not MConference[curForum]^^[Which].ShowCity;
					SetCheckBox(ConferenceDlg, 44, MConference[curForum]^^[Which].ShowCity);
				end;
			end;
		until (itemHit = 1);
		if itemHit = 1 then
		begin
			s1 := GetTextBox(ConferenceDlg, 10);
			if ((length(s1) < 1) or (length(s1) > 41)) or (s1[1] <= char(32)) then
			begin
				ProblemRep('Your conference name has to be 1 to 41 characters long. The conference name will not be changed.');
				s1 := MConference[curForum]^^[Which].Name;
			end
			else if (pos(':', s1) <> 0) then
			begin
				ProblemRep('The name of your conference cannot contain a colon. The conference name will not be changed.');
				s1 := MConference[curForum]^^[Which].Name;
			end
			else
			begin
				for i := 1 to MForum^^[curForum].numConferences do
					if (s1 = MConference[curForum]^^[i].Name) and (i <> Which) then
					begin
						ProblemRep('Duplicate conference name.  The conference name will not be changed.');
						s1 := MConference[curForum]^^[Which].Name;
						leave;
					end;
			end;
			MConference[curForum]^^[Which].Name := s1;
			s1 := char(0);
			s1 := GetTextBox(ConferenceDlg, 11);
			if ((ord(s1[1]) > 64) and (ord(s1[1]) < 91)) or ((ord(s1[1]) > 96) and (ord(s1[1]) < 123)) then
			begin
				if ord(s1[1]) > 96 then
					s1[1] := chr(ord(s1[1]) - 32)
				else if (length(s1) < 1) then
					s1[1] := char(0);
			end
			else
				s1[1] := char(0);
			MConference[curForum]^^[Which].AccessLetter := s1[1];
			s1 := GetTextBox(ConferenceDlg, 49);
			if MConference[curForum]^^[Which].ConfType = 1 then
			begin
				if ((length(s1) < 1) or (length(s1) > 64)) or (s1[1] <= char(32)) then
				begin
					ProblemRep('Your echo name has to be 1 to 64 characaters long. The echo name will not be changed.');
					s1 := MConference[curForum]^^[Which].EchoName;
					if length(s1) < 1 then
						MConference[curForum]^^[Which].ConfType := 0;
				end
				else if (pos(' ', s1) <> 0) then
				begin
					ProblemRep('Your echo name cannot contain a space. The echo name will not be changed.');
					s1 := MConference[curForum]^^[Which].EchoName;
				end
				else
				begin
					for i := 1 to ForumIdx^^.numForums do
						for j := 1 to MForum^^[i].numConferences do
							if (s1 = MConference[i]^^[j].EchoName) and (i <> curForum) and (j <> Which) then
							begin
								ProblemRep('Duplicate echo name.  The echo name will not be changed.');
								s1 := MConference[curForum]^^[Which].EchoName;
								if length(s1) < 1 then
									MConference[curForum]^^[Which].ConfType := 0;
								leave;
							end;
				end;
				MConference[curForum]^^[Which].EchoName := s1;
			end
			else
			begin
				MConference[curForum]^^[Which].EchoName := char(0);
			end;
			WriteAreasBBS;
			EditMessageConference := True;
		end
		else
			EditMessageConference := False;
		DisposDialog(ConferenceDlg);
		ConferenceDlg := nil;
	end;

	procedure FreeORAllocateConference (Which: integer; Free: boolean);
	begin
		if Free then
		begin
			if MConference[Which] <> nil then
			begin
				HPurge(handle(MConference[Which]));
				DisposHandle(handle(MConference[Which]));
				MConference[Which] := nil;
			end
			else
				SysBeep(0);
		end
		else if not Free then
		begin
			MConference[Which] := FiftyConferencesHand(NewHandleClear(SizeOf(FiftyConferences)));
			MoveHHi(handle(MConference[Which]));
			HNoPurge(handle(MConference[Which]));
		end;
	end;

	procedure Do_Message_Setup;
		var
			i, x, y, DType: integer;
			DItem: handle;
			tempRect: rect;
			myPt: point;
			tempCell: cell;
			s1, s2, s3: str255;
			tUser: UserRec;
			result: OSErr;
			s31: string[31];
			s26: string[26];
	begin
		if (MessSetup <> nil) and (MessSetup = FrontWindow) and (theWindow = MessSetUp) then
		begin
			SetPort(MessSetup);
			tempCell.h := 0;
			tempCell.v := 0;
			myPt := theEvent.where;
			GlobalToLocal(myPt);
			case itemHit of
				2: {New Forum}
				begin
					if InitSystHand^^.numMForums + 1 < 21 then
					begin
						MForum^^[InitSystHand^^.numMForums + 1].Name := StringOf('Forum #', InitSystHand^^.numMForums + 1 : 0);
						if EditMessageForum(InitSystHand^^.numMForums + 1) then
						begin
							InitSystHand^^.numMForums := InitSystHand^^.numMForums + 1;
							curForum := InitSystHand^^.numMForums;
							AddListString(MForum^^[InitSystHand^^.numMForums].Name, MForumList);
							FreeORAllocateConference(InitSystHand^^.numMForums, False);
							if LGetSelect(true, tempCell, MForumList) then
								LSetSelect(False, tempCell, MForumList);
							tempCell.h := 0;
							tempCell.v := InitSystHand^^.numMForums - 1;
							LSetSelect(True, tempCell, MForumList);
							LDelRow(0, 0, ConferenceList);
							s31 := MForum^^[InitSystHand^^.numMForums].Name;
							result := MakeADir(concat(InitSystHand^^.msgsPath, s31));
							s26 := MForum^^[InitSystHand^^.numMForums].Name;
							s1 := concat(InitSystHand^^.msgsPath, s31, ':', s26, ' AHDR');
							result := Create(s1, 0, 'HRMS', 'TEXT');
							s1 := concat(InitSystHand^^.msgsPath, s31, ':', s26, ' HDR');
							result := Create(s1, 0, 'HRMS', 'TEXT');
							DoSystRec(True);
							DoMForumRec(true);
						end;
					end
					else
						ProblemRep('Sorry you can only have 20 forums.');
				end;
				3: {Delete Forum}
					if LGetSelect(true, tempCell, MForumList) then
					begin
						if tempCell.v + 1 < InitSystHand^^.numMForums then
						begin
							if ModalQuestion('Are you sure you want to delete this forum?', false, true) = 1 then
								if ModalQuestion('All of the users high message pointers will have to be reset, continue?', false, true) = 1 then
								begin
									DrawUserStatus(-1);
									for i := 1 to numUserRecs do
									begin
										s1 := StringOf(i : 0);
										DrawUserStatus(i);
										if FindUser(s1, tUser) then
										begin
											for x := tempCell.v + 1 to (InitSystHand^^.numMForums - 1) do
												for y := 1 to MForum^^[x].NumConferences do
													tUser.LastMsgs[x, y] := tUser.LastMsgs[x + 1, y];
											for y := 1 to 30 do
												tUser.LastMsgs[InitSystHand^^.numMForums, y] := 0;
											WriteUser(tUser);
										end;
									end;
									DrawUserStatus(-99);
									if ModalQuestion('Do you want to delete the files associated with this forum?', false, true) = 1 then
									begin
										s31 := MForum^^[curForum].Name;
										for i := 1 to MForum^^[curForum].NumConferences do
										begin
											s26 := MConference[curForum]^^[i].Name;
											result := FSDelete(concat(InitSystHand^^.MsgsPath, s31, ':', s26, ' Indx'), 0);
											result := FSDelete(concat(InitSystHand^^.MsgsPath, s31, ':', s26, ' Text'), 0);
											result := FSDelete(concat(InitSystHand^^.MsgsPath, s31, ':', s26, ' Data'), 0);
											result := FSDelete(concat(InitSystHand^^.MsgsPath, s31, ':', s26, ' AHDR'), 0);
											result := FSDelete(concat(InitSystHand^^.MsgsPath, s31, ':', s26, ' HDR'), 0);
										end;
										s26 := MForum^^[curForum].Name;
										result := FSDelete(concat(InitSystHand^^.MsgsPath, s31, ':', s26, ' AHDR'), 0);
										result := FSDelete(concat(InitSystHand^^.MsgsPath, s31, ':', s26, ' HDR'), 0);
										result := FSDelete(concat(InitSystHand^^.MsgsPath, s31), 0);
									end;
									LDelRow(1, tempCell.v, MForumList);
									MForum^^[tempCell.v + 1].NumConferences := 0;
									if tempCell.v + 1 <> InitSystHand^^.numMForums then
										for i := (tempCell.v + 1) to InitSystHand^^.numMForums do
										begin
											MForum^^[i] := MForum^^[i + 1];
											MConference[i]^^ := MConference[i + 1]^^;
										end;
									FreeORAllocateConference(InitSystHand^^.numMForums, True);
									InitSystHand^^.numMForums := InitSystHand^^.numMForums - 1;
									if InitSystHand^^.numMForums > 0 then
									begin
										curForum := 1;
										LDelRow(0, 0, ConferenceList);
										LDoDraw(False, ConferenceList);
										if MForum^^[curForum].NumConferences > 0 then
										begin
											for i := 1 to MForum^^[curForum].NumConferences do
											begin
												AddListString(MConference[curForum]^^[i].Name, ConferenceList);
											end;
											tempCell.v := 0;
											tempCell.h := 0;
											LSetSelect(True, tempCell, ConferenceList);
											LSetSelect(True, tempCell, MForumList);
										end;
										LDoDraw(True, ConferenceList);
										GetDItem(MessSetup, 8, DType, DItem, tempRect);
										tempRect.Right := tempRect.Right - 15;
										InsetRect(tempRect, -1, -1);
										FrameRect(tempRect);
										LUpdate(ConferenceList^^.port^.visRgn, ConferenceList);
									end;
									DoSystRec(true);
									DoMForumRec(true);
									for i := 1 to InitSystHand^^.numMForums do
										DoMConferenceRec(true, i);
								end;
						end
						else
						begin
							if ModalQuestion('Are you sure you want to delete this forum.', false, true) = 1 then
							begin
								if ModalQuestion('Do you want to delete the files associated with this forum?', false, true) = 1 then
								begin
									s31 := MForum^^[curForum].Name;
									for i := 1 to MForum^^[curForum].NumConferences do
									begin
										s26 := MConference[curForum]^^[i].Name;
										result := FSDelete(concat(InitSystHand^^.MsgsPath, s31, ':', s26, ' Indx'), 0);
										result := FSDelete(concat(InitSystHand^^.MsgsPath, s31, ':', s26, ' Text'), 0);
										result := FSDelete(concat(InitSystHand^^.MsgsPath, s31, ':', s26, ' Data'), 0);
										result := FSDelete(concat(InitSystHand^^.MsgsPath, s31, ':', s26, ' AHDR'), 0);
										result := FSDelete(concat(InitSystHand^^.MsgsPath, s31, ':', s26, ' HDR'), 0);
									end;
									s26 := MForum^^[curForum].Name;
									result := FSDelete(concat(InitSystHand^^.MsgsPath, s31, ':', s26, ' AHDR'), 0);
									result := FSDelete(concat(InitSystHand^^.MsgsPath, s31, ':', s26, ' HDR'), 0);
									result := FSDelete(concat(InitSystHand^^.MsgsPath, s31), 0);
								end;
								LDelRow(1, tempCell.v, MForumList);
								MForum^^[tempCell.v + 1].NumConferences := 0;
								FreeORAllocateConference(InitSystHand^^.numMForums, True);
								InitSystHand^^.numMForums := InitSystHand^^.numMForums - 1;
								if InitSystHand^^.numMForums > 0 then
								begin
									curForum := 1;
									LDelRow(0, 0, ConferenceList);
									LDoDraw(False, ConferenceList);
									if MForum^^[curForum].NumConferences > 0 then
									begin
										for i := 1 to MForum^^[curForum].NumConferences do
										begin
											AddListString(MConference[curForum]^^[i].Name, ConferenceList);
										end;
										tempCell.v := 0;
										tempCell.h := 0;
										LSetSelect(True, tempCell, ConferenceList);
										LSetSelect(True, tempCell, MForumList);
									end;
									LDoDraw(True, ConferenceList);
									GetDItem(MessSetup, 8, DType, DItem, tempRect);
									tempRect.Right := tempRect.Right - 15;
									InsetRect(tempRect, -1, -1);
									FrameRect(tempRect);
									LUpdate(ConferenceList^^.port^.visRgn, ConferenceList);
								end;
								DoSystRec(true);
								DoMForumRec(true);
							end;
						end;
					end
					else
						SysBeep(0);
				4: {The Forum List}
					if LClick(myPt, theEvent.modifiers, MForumList) then
					begin
						tempCell.v := 0;
						tempCell.h := 0;
						if LGetSelect(true, tempCell, MForumList) then
						begin
							s1 := MForum^^[tempCell.v + 1].Name;
							if EditMessageForum(tempCell.v + 1) then
							begin
								s31 := MForum^^[tempCell.v + 1].Name;
								if s1 <> MForum^^[tempCell.v + 1].Name then
								begin
									s26 := s1;
									s2 := concat(InitSystHand^^.msgsPath, s1, ':', s26, ' AHDR');
									s26 := MForum^^[tempCell.v + 1].Name;
									s3 := concat(InitSystHand^^.msgsPath, s1, ':', s26, ' AHDR');
									result := Rename(s2, 0, s3);
									s26 := s1;
									s2 := concat(InitSystHand^^.msgsPath, s1, ':', s26, ' HDR');
									s26 := MForum^^[tempCell.v + 1].Name;
									s3 := concat(InitSystHand^^.msgsPath, s1, ':', s26, ' HDR');
									result := Rename(s2, 0, s3);
									result := Rename(concat(InitSystHand^^.MsgsPath, s1), 0, concat(InitSystHand^^.MsgsPath, s31));
								end;
								LSetCell(Pointer(ord(@MForum^^[tempCell.v + 1].Name) + 1), length(MForum^^[tempCell.v + 1].Name), tempCell, MForumList);
								DoMForumRec(true);
							end;
						end;
					end
					else if LGetSelect(true, tempCell, MForumList) and (tempCell.v + 1 <> curForum) then
					begin
						if LGetSelect(true, tempCell, MForumList) then
							curForum := tempCell.v + 1;
						LDelRow(0, 0, ConferenceList);
						LDoDraw(False, ConferenceList);
						if MForum^^[curForum].NumConferences > 0 then
						begin
							for i := 1 to MForum^^[curForum].NumConferences do
							begin
								AddListString(MConference[curForum]^^[i].Name, ConferenceList);
							end;
							tempCell.v := 0;
							tempCell.h := 0;
							LSetSelect(True, tempCell, ConferenceList);
						end;
						LDoDraw(True, ConferenceList);
						GetDItem(MessSetup, 8, DType, DItem, tempRect);
						tempRect.Right := tempRect.Right - 15;
						InsetRect(tempRect, -1, -1);
						FrameRect(tempRect);
						LUpdate(ConferenceList^^.port^.visRgn, ConferenceList);
					end;
				6: {New Conference}
					if MForum^^[curForum].NumConferences < 50 then
					begin
						if EditMessageConference(MForum^^[curForum].NumConferences + 1, true) then
						begin
							MForum^^[curForum].NumConferences := MForum^^[curForum].NumConferences + 1;
							AddListString(MConference[curForum]^^[MForum^^[curForum].NumConferences].Name, ConferenceList);
							DoMForumRec(true);
							DoMConferenceRec(true, curForum);
						end;
					end
					else
						ProblemRep('Sorry you can only have 50 conferences per forum.');
				7: {Delete a Conference}
					if LGetSelect(true, tempCell, ConferenceList) then
					begin
						if tempCell.v + 1 < MForum^^[curForum].NumConferences then
						begin
							if ModalQuestion('Are you sure you want to delete this conference?', false, true) = 1 then
								if ModalQuestion('All of the users high message pointers will have to be reset, continue?', false, true) = 1 then
								begin
									DrawUserStatus(-1);
									for i := 1 to numUserRecs do
									begin
										s1 := StringOf(i : 0);
										DrawUserStatus(i);
										if FindUser(s1, tUser) then
										begin
											for x := tempCell.v + 1 to (MForum^^[curForum].NumConferences - 1) do
												tUser.LastMsgs[curForum, x] := tUser.LastMsgs[curForum, x + 1];
											tUser.LastMsgs[curForum, MForum^^[curForum].NumConferences] := 0;
											WriteUser(tUser);
										end;
									end;
									DrawUserStatus(-99);
									if ModalQuestion('Do you want to delete the files associated with this conference?', false, true) = 1 then
									begin
										s31 := MForum^^[curForum].Name;
										s26 := MConference[curForum]^^[tempCell.v + 1].Name;
										result := FSDelete(concat(InitSystHand^^.MsgsPath, s31, ':', s26, ' Indx'), 0);
										result := FSDelete(concat(InitSystHand^^.MsgsPath, s31, ':', s26, ' Data'), 0);
										result := FSDelete(concat(InitSystHand^^.MsgsPath, s31, ':', s26, ' Mess'), 0);
										result := FSDelete(concat(InitSystHand^^.MsgsPath, s31, ':', s26, ' AHDR'), 0);
										result := FSDelete(concat(InitSystHand^^.MsgsPath, s31, ':', s26, ' HDR'), 0);
									end;
									LDelRow(1, tempCell.v, ConferenceList);
									if tempCell.v + 1 < 50 then
										for i := (tempCell.v + 1) to (MForum^^[curForum].NumConferences - 1) do
											MConference[curForum]^^[i] := MConference[curForum]^^[i + 1];
									MForum^^[curForum].NumConferences := MForum^^[curForum].NumConferences - 1;
									DoMForumRec(true);
									DoMConferenceRec(true, curForum);
								end;
						end
						else
						begin
							if ModalQuestion('Are you sure you want to delete this conference?', false, true) = 1 then
							begin
								if ModalQuestion('Do you want to delete the files associated with this conference?', false, true) = 1 then
								begin
									s31 := MForum^^[curForum].Name;
									s26 := MConference[curForum]^^[tempCell.v + 1].Name;
									result := FSDelete(concat(InitSystHand^^.MsgsPath, s31, ':', s26, ' Indx'), 0);
									result := FSDelete(concat(InitSystHand^^.MsgsPath, s31, ':', s26, ' Data'), 0);
									result := FSDelete(concat(InitSystHand^^.MsgsPath, s31, ':', s26, ' Mess'), 0);
									result := FSDelete(concat(InitSystHand^^.MsgsPath, s31, ':', s26, ' AHDR'), 0);
									result := FSDelete(concat(InitSystHand^^.MsgsPath, s31, ':', s26, ' HDR'), 0);
								end;
								LDelRow(1, tempCell.v, ConferenceList);
								MForum^^[curForum].NumConferences := MForum^^[curForum].NumConferences - 1;
								DoMForumRec(true);
							end;
						end;
					end
					else
						SysBeep(0);
				8: {The Conference List}
					if LClick(myPt, theEvent.modifiers, ConferenceList) then
					begin
						if LGetSelect(true, tempCell, ConferenceList) then
						begin
							s1 := MConference[curForum]^^[tempCell.v + 1].Name;
							if EditMessageConference(tempCell.v + 1, false) then
							begin
								if s1 <> MConference[curForum]^^[tempCell.v + 1].Name then
								begin
									s31 := MForum^^[curForum].Name;
									s26 := s1;
									s1 := concat(InitSystHand^^.MsgsPath, s31, ':', s26);
									s26 := MConference[curForum]^^[tempCell.v + 1].Name;
									s2 := concat(InitSystHand^^.MsgsPath, s31, ':', s26);
									result := Rename(concat(s1, ' Data'), 0, concat(s2, ' Data'));
									result := Rename(concat(s1, ' Indx'), 0, concat(s2, ' Indx'));
									result := Rename(concat(s1, ' Text'), 0, concat(s2, ' Text'));
									result := Rename(concat(s1, ' AHDR'), 0, concat(s2, ' AHDR'));
									result := Rename(concat(s1, ' HDR'), 0, concat(s2, ' HDR'));
								end;
								LSetCell(Pointer(ord(@MConference[curForum]^^[tempCell.v + 1].Name) + 1), length(MConference[curForum]^^[tempCell.v + 1].Name), tempCell, ConferenceList);
								DoMConferenceRec(true, curForum);
							end;
						end;
					end;


			end;
		end;
	end;

	procedure Close_Message_Setup;
	begin
		if (theWindow = MessSetup) and (MessSetup <> nil) then
		begin
			DisposDialog(MessSetup);
			MessSetup := nil;
		end;
	end;


end.