{ Segments: SystPrefs2_1}
unit SystemPrefs2;

interface

	uses
		AppleTalk, ADSP, Serial, Sound, Initial, nodePrefs, nodePrefs2, CTBUtilities;

	procedure OpenStrings (which: integer);
	procedure CloseStrings;
	procedure UpdateStrings;
	procedure ClickStrings (theEvent: EventRecord; ItemHit: Integer);
	procedure WhatDay (myDate: DateTimeRec; var myDayString: str255);
	function InTrash (trashedName: str255): boolean;
	procedure OpenAboutBox;
	procedure CloseAboutBox;
	procedure PrintStatus (disp: Str255);
	procedure StartMySound (soundName: str255; async: boolean);

implementation

	var
		slist: ListHandle;
		tempCell: cell;
		EmptyCh: Char;
		TotalStrings: ^Integer;
		Hndl: Handle;
		offSet, theplace: Longint;
		theError, theRes: Integer;
		cSize: Point;

{$S SystPrefs2_1}
	procedure SlideTextIn (theText: str255; vert, size: integer; useColor: boolean);
		var
			isOdd: boolean;
			scrPos: array[1..80] of integer;
			rightChar, leftChar, baseCPos, i, whichPair, numPairs, curRH, curLH: integer;
	begin
		TextSize(size);
		baseCPos := screenBits.bounds.right div 2 - (StringWidth(theText) div 2);
		i := 1;
		scrPos[i] := baseCPos;
		while (i < length(theText)) do
		begin
			i := i + 1;
			scrPos[i] := scrPos[i - 1] + CharWidth(thetext[i - 1]);
		end;
		if (length(theText) mod 2) > 0 then
			isOdd := true
		else
			isOdd := false;
		if isOdd then
		begin
			curRH := screenBits.bounds.right;
			rightChar := length(theText) div 2 + 1;
			repeat
				if curRH > scrPos[rightChar] then
				begin
					ForeColor(blackColor);
					MoveTo(curRH, vert);
					DrawChar(theText[rightChar]);
					curRH := curRH - 25;
					if curRH < scrPos[rightChar] then
						curRH := scrPos[rightChar];
					if useColor then
						ForeColor(yellowColor)
					else
						ForeColor(whiteColor);
					MoveTo(curRH, vert);
					DrawChar(theText[rightChar]);
				end;
			until (curRH = scrPos[rightChar]);
			for i := (rightChar + 1) to length(theText) do
				scrPos[i - 1] := scrPos[i];
			delete(theText, rightChar, 1);
		end;
		numPairs := length(theText) div 2;
		whichPair := 1;
		repeat
			rightChar := length(theText) div 2 + 1;
			leftChar := length(theText) div 2;
			rightChar := rightChar + whichPair - 1;
			leftChar := leftChar - whichPair + 1;
			curRH := screenBits.bounds.right;
			curLH := 0;
			repeat
				if curRH > scrPos[rightChar] then
				begin
					ForeColor(blackColor);
					MoveTo(curRH, vert);
					DrawChar(theText[rightChar]);
					if size < 18 then
						curRH := curRH - 40
					else
						curRH := curRH - 25;
					if curRH < scrPos[rightChar] then
						curRH := scrPos[rightChar];
					if useColor then
						ForeColor(yellowColor)
					else
						ForeColor(whiteColor);
					MoveTo(curRH, vert);
					DrawChar(theText[rightChar]);
				end;
				if curLH < scrPos[leftChar] then
				begin
					ForeColor(blackColor);
					MoveTo(curLH, vert);
					DrawChar(theText[leftChar]);
					if size < 18 then
						curLH := curLH + 40
					else
						curLH := curLH + 25;
					if curLH > scrPos[leftChar] then
						curLH := scrPos[leftChar];
					if useColor then
						ForeColor(yellowColor)
					else
						ForeColor(whiteColor);
					MoveTo(curLH, vert);
					DrawChar(theText[leftChar]);
				end;
			until (curRH = scrPos[rightChar]) and (curLH = scrPos[leftChar]);
			whichPair := whichPair + 1;
		until (whichPair > numPairs);
	end;

	procedure EndMySound;
	begin
		if myChannel <> nil then
		begin
			result := SndDisposeChannel(myChannel, true);
			DisposPtr(ptr(myChannel));
			myChannel := nil;
			if mySound <> nil then
				HPurge(mySound);
			mySound := nil;
		end;
	end;

{$D-}

	procedure mySndCallBack (theChan: SndChannelPtr; theCmd: SndCommand);
		var
			myA5: longint;
	begin
		if theCmd.param1 = 1 then
		begin
			myA5 := SetA5(theCmd.param2);
			gSndCalledBack := true;
			myA5 := SetA5(myA5);
		end;
	end;

{$D+}

	procedure StartMySound (soundName: str255; async: boolean);
		var
			mySndCmd: SndCommand;
	begin
		myChannel := SndChannelPtr(NewPtrClear(SizeOf(SndChannel)));
		myChannel^.qLength := stdQLength;
		mySound := GetNamedResource('snd ', soundName);
		if (mySound <> nil) then
		begin
			if SndNewChannel(myChannel, 0, initMono, nil) <> noErr then
			begin
				ReleaseResource(mySound);
				mySound := nil;
				DisposPtr(ptr(myChannel));
				myChannel := nil;
			end
			else
			begin
				gSndCalledBack := false;
				if async then
					myChannel^.callBack := @mySndCallBack;
				result := SndPlay(myChannel, mySound, async);
				if async then
				begin
					mySndCmd.cmd := callBackCmd;
					mySndCmd.param1 := 1;
					mySndCmd.param2 := SetCurrentA5;
					result := SndDoCommand(myChannel, mySndCmd, TRUE);
				end
				else
					EndMySound;
			end;
		end;
	end;

	function RetStr (index: integer): str255;
		var
			ts: str255;
	begin
		UseResFile(StringsRes);
		GetIndString(RetStr, stringSet, index);
		UseResFile(myResourceFile);
	end;


	procedure OpenAboutBox;
		var
			freeMemoryStr: Str255;
			freeMemory: LONGINT;
			serialStr: Str255;
			statusStr: Str255;
	begin
		if AboutDilg = nil then
		begin
			AboutDilg := GetNewDialog(1539, nil, pointer(-1));

			freeMemory := MaxMem(freeMemory);
			NumToString(freeMemory, freeMemoryStr);

			if (length(InitSystHand^^.realSerial) > 0) then
				serialStr := copy(InitSystHand^^.realSerial, 1, 8)
			else
				serialStr := 'Unregistered';

			statusStr := 'Okay';

			SetDItemText(AboutDilg, 1, HERMES_VERSION);
			SetDItemText(AboutDilg, 2, freeMemoryStr);
			SetDItemText(AboutDilg, 3, serialStr);
			SetDItemText(AboutDilg, 4, statusStr);
			MoveWindow(AboutDilg, (screenbits.bounds.right - (AboutDilg^.portRect.right - AboutDilg^.portRect.left)) div 2, (screenbits.bounds.bottom - (AboutDilg^.portRect.bottom - AboutDilg^.portRect.Top)) div 2, true);
			ShowWindow(aboutDilg);
			SelectWindow(aboutDilg);
			DrawDialog(aboutDilg);
		end;
	end;

	procedure PrintStatus (disp: Str255);
		var
			itemRect: Rect;
			itemHandle: Handle;
			itemType: INTEGER;
			savedPort: GrafPtr;
	begin
		if (AboutDilg <> nil) then
		begin
			GetDItem(aboutDilg, 4, itemType, itemHandle, itemRect);
			if (itemHandle <> nil) then
			begin
				GetPort(savedPort);
				SetPort(aboutDilg);
				SetDItemText(AboutDilg, 4, disp);
				SetPort(savedPort);
			end;
		end;
	end;

	procedure CloseAboutBox;
	begin
		if AboutDilg <> nil then
		begin
			DisposDialog(AboutDilg);
			AboutDilg := nil;
			FlushEvents(mouseDown + mouseUp, 0);
		end;
	end;

	function InTrash (trashedName: str255): boolean;
		var
			trashRef, i, lastI: integer;
			lengTrash: longint;
			trashStuff: CharsHandle;
			checkStr: str255;
	begin
		inTrash := false;
		UprString(trashedName, true);
		result := FSOpen(concat(sharedPath, 'Misc:Trash Users'), 0, trashRef);
		if result = noErr then
		begin
			result := GetEOF(trashRef, lengTrash);
			if lengTrash > 0 then
			begin
				trashStuff := CharsHandle(NewHandle(lengTrash));
				if memError = noErr then
				begin
					result := FSRead(trashref, lengTrash, pointer(trashStuff^));
					i := 0;
					lastI := 0;
					while (i <= lengTrash) do
					begin
						if (trashStuff^^[i] = char(13)) then
						begin
							checkStr[0] := char(i - lastI);
							BlockMove(pointer(ord4(@trashStuff^^[lastI])), pointer(ord4(@checkStr[1])), i - lastI);
							if pos(checkStr, trashedName) > 0 then
								inTrash := true;
							lastI := i + 1;
						end;
						i := i + 1;
					end;
					DisposHandle(handle(trashStuff));
				end;
			end;
			result := FSClose(trashRef);
		end;
	end;

	procedure WhatDay;
	begin
		case myDate.dayOfWeek of
			1: 
				myDayString := 'Sun, ';
			2: 
				myDayString := 'Mon, ';
			3: 
				myDayString := 'Tue, ';
			4: 
				myDayString := 'Wed, ';
			5: 
				myDayString := 'Thu, ';
			6: 
				myDayString := 'Fri, ';
			7: 
				myDayString := 'Sat, ';
			otherwise
		end;
	end;

	procedure WriteString;
		var
			DType: integer;
			DItem: Handle;
			tempRect: rect;
			tempString: Str255;
			i: integer;
	begin
		if LGetSelect(true, tempCell, sList) then
		begin
			if (EditingString > 0) then
			begin
				GetDItem(StringDilg, 4, DType, DItem, tempRect);
				GetIText(DItem, TempString);
				EmptyCh := Char(0);
				UseResFile(StringsRes);
				Hndl := GetResource('STR#', stringSet);
				if Hndl <> nil then
				begin
					HNoPurge(Hndl);
					TotalStrings := Pointer(Ord4(Hndl^));
					offset := 2;
					for i := 1 to Pred(EditingString) do
						offset := offset + Succ(Length(RetStr(i)));
					theplace := Munger(Hndl, offset, nil, Succ(Length(RetStr(EditingString))), Pointer(Ord4(@TempString)), Succ(Length(TempString)));
					ChangedResource(Hndl);
					theError := ResError;
					if theError = noErr then
						WriteResource(Hndl);
					HPurge(Hndl);
					ReleaseResource(Hndl);
					UseResFile(MyResourceFile);
				end
				else
					ProblemRep(StringOf('Error #', reserror : 0, ' With String Resources.'));
			end;
		end;
	end;

	procedure CloseStrings;
	begin
		if (StringDilg <> nil) then
		begin
			WriteString;
			LDispose(slist);
			DisposDialog(StringDilg);
			StringDilg := nil;
		end;
	end;

	procedure UpDateStrings;
		var
			SavePort: WindowPtr;
			tempRect: rect;
	begin
		if (StringDilg <> nil) then
		begin
			GetPort(SavePort);
			SetPort(StringDilg);
			EraseRect(StringDilg^.portRect);
			DrawDialog(StringDilg);
			TempRect := sList^^.rView;
			InsetRect(TempRect, -1, -1);
			FrameRect(TempRect);

			LUpdate(StringDilg^.visRgn, sList);

			SetPort(SavePort);
		end;
	end;

	procedure ClickStrings (theEvent: EventRecord; itemHit: integer);
		var
			myPt: Point;
			code, tempInt, y, i, xx: integer;
			tempInt2, tempLong: longint;
			temprect: rect;
			tempstring, t1, textSearch: str255;
			DType: integer;
			DItem: Handle;
			Doubleclick: Boolean;
			tc2: cell;
			CItem, CTempItem: controlhandle;
			tempMenu: Menuhandle;
			adder: integer;
			adder2: real;
			SearchDilg: DialogPtr;
	begin
		if (StringDilg <> nil) and (frontWindow = StringDilg) then
		begin
			with theNodes[visibleNode]^ do
			begin
				SetPort(StringDilg);
				myPt := theEvent.where;
				GlobalToLocal(myPt);
				GetDItem(StringDilg, itemHit, DType, DItem, tempRect);
				CItem := Pointer(Ditem);
				case ItemHit of
					1: 
						CloseStrings;
					6: 
					begin
						searchDilg := GetNewDialog(3468, nil, pointer(-1));
						SetPort(searchDilg);
						ShowWindow(searchDilg);
						GetDItem(searchDilg, 1, Dtype, DItem, tempRect);
						InsetRect(tempRect, -4, -4);
						PenSize(3, 3);
						FrameRoundRect(tempRect, 16, 16);
						repeat
							ModalDialog(nil, i);
						until (i = 1) or (i = 2);
						if (i = 1) then
						begin
							GetDItem(searchDilg, 4, Dtype, Ditem, tempRect);
							GetIText(Ditem, textSearch);
							tempCell.v := 0;
							tempCell.h := 0;
							if length(textSearch) > 0 then
								if LSearch(Pointer(ord(@textsearch) + 1), Length(textsearch), nil, tempcell, sList) then
									LSetSelect(true, tempCell, sList);
						end;
						DisposDialog(searchDilg);
					end;
					2: 
					begin
						WriteString;
						DoubleClick := LClick(myPt, theEvent.modifiers, sList);
						tempCell.h := 0;
						tempCell.v := 0;
						if LGetSelect(true, tempCell, sList) then
						begin
							GetDItem(StringDilg, 4, DType, DItem, tempRect);
							SetIText(DItem, RetStr(tempCell.v + 1));
							SelIText(StringDilg, 4, 0, 32767);
							EditingString := TempCell.v + 1;
						end;
					end;
				end;
			end;
		end;
	end;

	procedure OpenStrings (which: integer);
		var
			ThisEditText: TEHandle;
			TheDialogPtr: DialogPeek;
			tempRect, tr2: Rect;
			tempString: Str255;
			myC: Point;
			DType, i: integer;
			DItem: Handle;
			DataBounds: Rect;
			CItem, CTempItem: controlhandle;
			templong: longint;
	begin
		with curglobs^ do
			if (StringDilg = nil) then
			begin
				theRes := which;
				StringDilg := GetNewDialog(80, nil, Pointer(-1));
				SetPort(StringDilg);
				TheDialogPtr := DialogPeek(StringDilg);
				ThisEditText := TheDialogPtr^.textH;
				HLock(Handle(ThisEditText));
				ThisEditText^^.txSize := 12;
				TextSize(12);
				ThisEditText^^.txFont := monaco;
				TextFont(monaco);
				ThisEditText^^.txFont := 4;
				ThisEditText^^.fontAscent := 12;
				ThisEditText^^.lineHeight := 12 + 4 + 0;
				HUnLock(Handle(ThisEditText));

				GetDItem(StringDilg, 4, DType, DItem, TempRect);
				TempRect.right := tempRect.Right - 15;
				InsetRect(TempRect, -1, -1);
				FrameRect(TempRect);
				InsetRect(TempRect, 1, 1);

				GetDItem(StringDilg, 2, DType, DItem, tempRect);
				TempRect.right := tempRect.Right - 15;
				InsetRect(TempRect, -1, -1);
				FrameRect(TempRect);
				InsetRect(TempRect, 1, 1);
				SetRect(dataBounds, 0, 0, 1, 0);
				csize.h := tempRect.Right - tempRect.Left;
				csize.v := 16;
				slist := LNew(tempRect, DataBounds, cSize, 0, StringDilg, false, false, false, true);
				slist^^.selFlags := lOnlyOne + lNoNilHilite;
				i := 0;
				repeat
					i := i + 1;
					GetIndString(TempString, 17, i);
					if length(tempString) > 0 then
						AddListString(tempString, slist);
				until (length(tempString) = 0);
				LDoDraw(True, slist);
				csize.h := 0;
				csize.v := 0;

				EditingString := 0;

				ShowWindow(StringDilg);
				SelectWindow(StringDilg);
			end
			else
				SelectWindow(StringDilg);
	end;
end.