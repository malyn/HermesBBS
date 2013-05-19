{ Segments: MesEdit_1 }
unit Message_Editor;
interface
	uses
		AppleTalk, ADSP, Serial, Sound, TCPTypes, Initial, systemprefs, SystemPrefs2, NodePrefs, NodePrefs2;

	procedure OpenBase (whichForum, whichSub: integer; extraRec: boolean);
	procedure SaveBase (wForum, wSub: integer);
	procedure LoadFileAsMsg (name: str255);
	procedure AddLine (toAdd: str255);
	procedure DeletePost (wForum, wConf, wMesg: integer; delePost: boolean);
	function takeMsgTop: str255;
	procedure SaveNetMail (OtherName: str255);
	function SaveMessAsEmail: boolean;
	procedure LoadHelpFile;
	procedure HeReadIt (ReadMa: eMailRec);
	function LoadSpecialText (myText: charsHandle; which: integer): boolean;
	procedure DeleteMail (whichNum: longint);
	function isPostRatioOK: boolean;
	procedure FindMyEmail (userNum: integer);
	function FindMyDmail (userNum: integer): integer;
	function OpenMData (wForum, wConf: integer; Index: boolean): integer;
	function SaveMessage (charsToSave: TextHand; wForum, wConf: integer): longint;
	function ReadMessage (storedAs: longint; wForum, wConf: integer): TextHand;
	procedure RemoveMessage (storedAs: longint; wForum, wConf: integer);
	function SavePost (wForum, wConf: integer): boolean;
	procedure SaveNetPost;

implementation
	var
		NumIndexes: integer;

{$S MesEdit_1}
	procedure DeleteFileAttachment (IsItMail: boolean; FileName: str255);
	external;

	procedure DeleteMail;
		var
			tempStored: longint;
			i, theNum, twoNum: integer;
	begin
		theNum := whichNum;
		if (theEmail <> nil) and (theNum >= 0) and (theNum < availEmails) then
		begin
			if theEmail^^[theNum].multiMail then
			begin
				twoNum := -1;
				tempStored := theEmail^^[theNum].storedAs;
				for i := 1 to availEmails do
					if (theEmail^^[i - 1].storedAs = tempStored) and ((i - 1) <> theNum) then
						twoNum := i;
				if twoNum = -1 then
				begin
					if (theEmail^^[theNum].FileAttached) then
						DeleteFileAttachment(true, theEmail^^[theNum].FileName);
					RemoveMessage(theEmail^^[theNum].storedAs, 0, 0);
				end;
			end
			else if theEmail^^[theNum].MType = 1 then
				RemoveMessage(theEmail^^[theNum].storedAs, 0, 0);
			if (availEmails - 1) > theNum then
			begin
				BlockMove(@theEmail^^[theNum + 1], @theEmail^^[theNum], longint(availEmails - 1 - theNum) * SizeOf(emailRec));
			end;
			SetHandleSize(handle(theEmail), GetHandleSize(handle(theEmail)) - SizeOf(emailRec));
			availEmails := availEmails - 1;
			emailDirty := true;
			SaveEmailData;
			emailDirty := false;
		end;
	end;

	procedure FindMyEmail (userNum: integer);
		var
			i: integer;
			numOfEm: integer;
	begin
		with curGlobs^ do
		begin
			if myEmailList <> nil then
				SetHandleSize(handle(myEmailList), 0)
			else
				myEmailList := intListHand(NewHandle(0));
			HNoPurge(handle(myEmailList));
			if (theEmail <> nil) and (availEmails > 0) then
			begin
				numOfEm := 0;
				for i := 1 to availEmails do
				begin
					if (theEmail^^[i - 1].toUser = userNum) and (theEmail^^[i - 1].MType = 1) then
					begin
						numOfEm := numOfEm + 1;
						SetHandleSize(handle(myEmailList), getHandleSize(handle(myEmailList)) + 2);
						myEmailList^^[numOfEm - 1] := i - 1;
					end;
				end;
			end;
		end;
	end;

	function FindMyDmail (userNum: integer): integer;
		var
			i: integer;
			numOfEm: integer;
	begin
		numOfEm := 0;
		i := 0;
		with curGlobs^ do
		begin
			while (i < availEmails) do
			begin
				if (theEmail^^[i].MType = 0) and (theEmail^^[i].toUser = userNum) then
					numOfEm := numOfEm + 1;
				i := i + 1;
			end;
		end;
		FindMyDmail := NumOfEm;
	end;

	procedure DeletePost (wForum, wConf, wMesg: integer; delePost: boolean);
		var
			MessDataHnd: MesgHand;
			result: OSerr;
			tempString, tempString2, s2, s3: str255;
			MesgRef, tempInt, i: integer;
			AllRecsSize, tempLong: longint;
			tempBool: boolean;
			tempMesg: MesgRec;
			booshi: handle;
			s26: string[26];
			s31: string[31];
	begin
		with curglobs^ do
		begin
			s26 := MConference[wForum]^^[wConf].Name;
			s31 := MForum^^[wForum].Name;
			tempString := concat(InitSystHand^^.msgsPath, s31, ':', s26, ' Data');
			result := FSOpen(tempString, 0, mesgRef);
			if result = noErr then
			begin
				result := GetEOF(mesgRef, AllRecsSize);
				if (AllRecsSize div SizeOf(mesgRec)) >= wMesg then
				begin
					result := SetFPos(mesgRef, fsFromStart, longint(wMesg - 1) * SizeOf(mesgRec));
					tempLong := SizeOf(mesgrec);
					result := FSRead(mesgref, templong, @tempMesg);
					if (AllRecsSize - SizeOf(MesgRec) * longint(wMesg)) > 0 then
					begin
						booshi := NewHandle(AllRecsSize - SizeOf(MesgRec) * longint(wMesg));
						if memerror = 0 then
						begin
							HLock(handle(booshi));
							tempLong := AllRecsSize - SizeOf(MesgRec) * longint(wMesg);
							result := FSRead(mesgRef, tempLong, pointer(booshi^));
							result := SetFPos(mesgRef, fsFromStart, longint(wMesg - 1) * SizeOf(mesgRec));
							tempLong := AllRecsSize - SizeOf(MesgRec) * longint(wMesg);
							result := FSWrite(mesgRef, tempLong, pointer(booshi^));
							HUnlock(handle(booshi));
							DisposHandle(handle(booshi));
						end
						else
							SysBeep(1);
					end;
					result := SetEOF(mesgRef, AllRecsSize - SizeOf(mesgRec));
					result := FSClose(mesgRef);
					if allrecsSize - (SizeOf(MesgRec)) <= 0 then
						result := FSDelete(tempString, 0);
					if delePost then
					begin
						if tempMesg.FileAttached then
							DeleteFileAttachment(false, tempMesg.FileName);
						RemoveMessage(tempMesg.storedAs, wForum, wConf);
					end;
					if curBase <> nil then
					begin
						if wMesg <= curNumMess then
						begin
							if (wMesg < curNumMess) then
							begin
								BlockMove(@curBase^^[wMesg], @curBase^^[wMesg - 1], Sizeof(mesgRec) * longint(curNumMess - wMesg));
							end;
							curNumMess := curNumMess - 1;
						end;
					end;
				end
				else
					result := FSClose(mesgRef);
			end;
		end;
	end;

	function OpenMData (wForum, wConf: integer; Index: boolean): integer;
		var
			s1, s2: str255;
			myRef, i: integer;
			SizeOfFile: longint;
			s26: string[26];
			s31: string[31];
	begin
		with curglobs^ do
		begin
			if (curIndex <> nil) and (Index) then
			begin
				DisposHandle(handle(curIndex));
				curIndex := nil;
			end;
			if wForum > 0 then
			begin
				s26 := MConference[wForum]^^[wConf].Name;
				s31 := MForum^^[wForum].Name;
				if Index then
					s1 := concat(InitSystHand^^.msgsPath, s31, ':', s26, ' Indx')
				else
					s1 := concat(InitSystHand^^.msgsPath, s31, ':', s26, ' Text')
			end
			else
			begin
				if Index then
					s1 := concat(InitSystHand^^.msgsPath, 'Email:Email Indx')
				else
					s1 := concat(InitSystHand^^.msgsPath, 'Email:Email Text');
			end;

			result := FSOpen(s1, 0, myRef);
			if result <> noErr then
			begin
				s2 := concat(InitSystHand^^.msgsPath, s31, ':', s26, ' HDR');
				result := FSOpen(s2, 0, myRef);
				if result <> noErr then
					result := Create(s2, 0, 'HRMS', 'TEXT')
				else
					result := FSClose(myRef);
				s2 := concat(InitSystHand^^.msgsPath, s31, ':', s26, ' AHDR');
				result := FSOpen(s2, 0, myRef);
				if result <> noErr then
					result := Create(s2, 0, 'HRMS', 'TEXT')
				else
					result := FSClose(myRef);

				result := Create(s1, 0, 'HRMS', 'MESG');
				result := FSOpen(s1, 0, myRef);
				if Index then
				begin
					curIndex := MessIndexHand(NewHandle(0));
					MoveHHi(handle(curIndex));
					NumIndexes := 0;
				end;
			end
			else if (result = noErr) and (Index) then
			begin
				result := GetEOF(myRef, SizeOfFile);
				curIndex := MessIndexHand(NewHandle(SizeOfFile));
				MoveHHi(handle(curIndex));
				result := FSRead(myRef, SizeOfFile, pointer(curIndex^));
				NumIndexes := GetHandleSize(handle(curIndex)) div 2;
			end;
			OpenMData := myRef;
		end;
	end;

	procedure RemoveMessage (storedAs: longint; wForum, wConf: integer);
		var
			theRef: integer;
			csec, nsec, CurSize: longint;
	begin
		with curglobs^ do
		begin
			theRef := OpenMData(wForum, wConf, true);
			csec := storedas;
			while (csec > 0) and (csec <= NumIndexes) do
			begin
				nsec := curIndex^^[csec];
				curIndex^^[csec] := 0;
				csec := nsec;
			end;
			result := SetFPos(theRef, fsFromStart, 0);
			CurSize := GetHandleSize(handle(curIndex));
			result := FSWrite(theRef, CurSize, pointer(curIndex^));
			result := FSClose(theRef);
		end;
	end;

	function SaveMessage (charsToSave: TextHand; wForum, wConf: integer): longint;  {returns first block saved}
		var
			mLength, mWritten, mToWrite, CurSize, BlockSize: longint;
			theIRef, theMRef: integer;
			BlockCounter, BlocksNeeded, indexCounter, ExtraBlocks, i: integer;
			BlocksArray: array[1..50] of integer;
			NullBlock: packed array[1..512] of char;
	begin
		with curglobs^ do
		begin
			mLength := GetHandleSize(handle(charsToSave));
			theIRef := OpenMData(wForum, wConf, true);
			BlockCounter := 1;
			BlocksNeeded := (mLength + 511) div 512;
			if BlocksNeeded > 50 then
				BlocksNeeded := 50;
			indexCounter := 1;
			while (BlockCounter <= BlocksNeeded) and (indexCounter <= NumIndexes) do
			begin
				if (curIndex^^[indexCounter] = 0) then
				begin
					BlocksArray[BlockCounter] := indexCounter;
					BlockCounter := BlockCounter + 1;
				end;
				indexCounter := indexCounter + 1;
			end;
			if (indexCounter > NumIndexes) and (NumIndexes <> 15000) then
			begin
				ExtraBlocks := BlocksNeeded - (BlockCounter - 1);
				CurSize := GetHandleSize(handle(curIndex));
				SetHandleSize(handle(curIndex), CurSize + (ExtraBlocks * 2));
				for i := 1 to ExtraBlocks do
				begin
					BlocksArray[BlockCounter] := indexCounter;
					BlockCounter := BlockCounter + 1;
					indexCounter := indexCounter + 1;
				end;
			end
			else if (NumIndexes >= 15000) then
			begin
				SaveMessage := -1;
				Exit(SaveMessage);
			end;
			theMRef := OpenMData(wForum, wConf, false);
			BlocksArray[BlockCounter] := -1;
			BlockCounter := 1;
			BlockSize := 512;
			mWritten := 0;
			while (BlockCounter <= BlocksNeeded) do
			begin
				result := SetFPos(theMRef, fsFromStart, BlockSize * longint(BlocksArray[BlockCounter] - 1));
				if (mWritten + BlockSize) > mLength then
				begin
					mToWrite := mLength - mWritten;
					result := FSWrite(theMRef, mToWrite, @charsToSave^^[(BlockCounter - 1) * BlockSize]);
					mToWrite := BlockSize - (mLength - mWritten);
					for i := 1 to mToWrite do
						NullBlock[i] := char(0);
					result := FSWrite(theMRef, mToWrite, @NullBlock);
				end
				else
				begin
					result := FSWrite(theMRef, BlockSize, @charsToSave^^[(BlockCounter - 1) * BlockSize]);
					mWritten := mWritten + BlockSize;
				end;
				curIndex^^[BlocksArray[BlockCounter]] := BlocksArray[BlockCounter + 1];
				BlockCounter := BlockCounter + 1;
			end;
			result := FSClose(theMRef);
			result := SetFPos(theIRef, fsFromStart, 0);
			CurSize := GetHandleSize(handle(curIndex));
			result := FSWrite(theIRef, CurSize, pointer(curIndex^));
			result := FSClose(theIRef);

			SaveMessage := BlocksArray[1];
		end;
	end;

	function ReadMessage (storedAs: longint; wForum, wConf: integer): TextHand;
		var
			theIRef, theMRef: integer;
			BlocksNeeded, BlockCounter, indexCounter, ActualSize: integer;
			BlockSize: longint;
			tempchars: Texthand;
	begin
		with curglobs^ do
		begin
			BlockSize := 512;
			theIRef := OpenMData(wForum, wConf, true);
			indexCounter := storedAs;
			BlocksNeeded := 0;
			while (indexCounter > 0) and (indexCounter <= NumIndexes) do
			begin
				BlocksNeeded := BlocksNeeded + 512;
				indexCounter := curIndex^^[indexCounter];
			end;
			if BlocksNeeded = 0 then
			begin
				ReadMessage := nil;
				result := FSClose(theIRef);
				Exit(ReadMessage);
			end;
			tempChars := TextHand(NewHandle(BlocksNeeded));
			if MemError <> noErr then
			begin
				ReadMessage := nil;
				result := FSClose(theIRef);
				Exit(ReadMessage);
			end;
			indexCounter := storedAs;
			BlockCounter := 0;
			theMRef := OpenMData(wForum, wConf, false);
			while (indexCounter > 0) and (indexCounter <= NumIndexes) do
			begin
				result := SetFPos(theMRef, fsFromStart, BlockSize * (longint(indexCounter) - 1));
				result := FSRead(theMRef, BlockSize, @tempChars^^[BlockCounter]);
				BlockCounter := BlockCounter + BlockSize;
				indexCounter := curIndex^^[indexCounter];
			end;
			result := FSClose(theIRef);
			result := FSClose(theMRef);
			ActualSize := BlockCounter - 512;
			while (ActualSize < BlockCounter) and (tempchars^^[ActualSize] <> char(26)) do
				ActualSize := ActualSize + 1;
			SetHandleSize(handle(tempChars), ActualSize);
			MoveHHi(handle(tempChars));
		end;
		ReadMessage := tempchars;
	end;

	function SavePost (wForum, wConf: integer): boolean;
		var
			s, s2: str255;
			myRef: integer;
			templong: longint;
			s26: string[26];
			s31: string[31];
	begin
		with curglobs^ do
		begin
			curMesgRec.HasRead := false;
			curMesgRec.storedAs := SaveMessage(curWriting, wForum, wConf);
			if (curMesgRec.storedAs <> -1) then
			begin
				s26 := MConference[wForum]^^[wConf].Name;
				s31 := MForum^^[wForum].Name;
				s := concat(InitSystHand^^.msgsPath, s31, ':', s26, ' Data');
				result := FSOpen(s, 0, myRef);
				if result <> noErr then
				begin
					s2 := concat(InitSystHand^^.msgsPath, s31, ':', s26, ' HDR');
					result := FSOpen(s2, 0, myRef);
					if result <> noErr then
						result := Create(s2, 0, 'HRMS', 'TEXT')
					else
						result := FSClose(myRef);
					s2 := concat(InitSystHand^^.msgsPath, s31, ':', s26, ' AHDR');
					result := FSOpen(s2, 0, myRef);
					if result <> noErr then
						result := Create(s2, 0, 'HRMS', 'TEXT')
					else
						result := FSClose(myRef);

					result := Create(s, 0, 'HRMS', 'DATA');
					result := FSOpen(s, 0, myRef);
				end;
				result := SetFPos(myRef, fsFromLEOF, 0);
				tempLong := SizeOf(mesgRec);
				result := FSWrite(myRef, tempLong, @curMesgRec);
				result := FSClose(myRef);
				SavePost := true;
			end
			else
				SavePost := false;
		end;
	end;

	function isPostRatioOK: boolean;
		var
			tempReal, tempReal2, tempReal3: real;
	begin
		tempReal := curglobs^.thisUser.messagesPosted;
		tempReal2 := curglobs^.thisUser.totalLogons;
		tempReal3 := SecLevels^^[curglobs^.thisUser.SL].postRatioOneTo;
		if tempReal3 = 0 then
			tempreal3 := 1;
		if (tempReal / tempReal2) >= (1 / tempReal3) then
			isPostRatioOK := TRUE
		else
			isPostRatioOK := FALSE;
	end;

	function takeMsgTop: str255;
		var
			i, b, c: longint;
			ts: str255;
	begin
		with curglobs^ do
		begin
			i := GetHandleSize(handle(curWriting));
			b := 0;
			while (b < i) and (curWriting^^[b] <> char(13)) do
				b := b + 1;
			if curWriting^^[b] = char(13) then
			begin
				if (b < 80) then
				begin
					ts := '';
					for c := 1 to (b) do
						ts := concat(ts, '.');
					BlockMove(@curWriting^^[0], @ts[1], b);
					BlockMove(@curWriting^^[b + 1], @curWriting^^[0], i - (b + 1));
					SetHandleSize(handle(curWriting), i - (b + 1));
					takemsgTop := ts;
				end
				else
					takeMsgTop := '';
			end
			else
				takemsgtop := '';
		end;
	end;

	procedure AddLine (toAdd: str255);
		var
			i, b: longint;
	begin
		with curglobs^ do
		begin
			toAdd := concat(toAdd, char(13));
			i := length(toAdd);
			b := getHandleSize(handle(curWriting));
			SetHandleSize(handle(curWriting), b + i);
			BlockMove(@curWriting^^[0], @curWriting^^[i], b);
			BlockMove(@toAdd[1], pointer(curWriting^), i);
		end;
	end;

	function LoadSpecialText (myText: charsHandle; which: integer): boolean;
		var
			numChars, searchPos, i, searchPos2: integer;
			serialTemp, temp: str255;
			ck, ck2: longint;
	begin
		with curglobs^ do
		begin
			LoadSpecialText := false;
			if mytext <> nil then
			begin
				numChars := GetHandleSize(handle(myText));
				if textHnd <> nil then
				begin
					HPurge(handle(texthnd));
					DisposHandle(handle(textHnd));
				end;
				textHnd := nil;
				CurTextPos := 0;
				OpenTextSize := 0;
				SysopStop := false;
				SearchPos := 0;
				i := 0;
				while (i <> which) and (SearchPos < numChars) do
				begin
					if (myText^^[SearchPos] = char(24)) then
						i := i + 1;
					SearchPos := SearchPos + 1;
				end;
				if (i = which) then
				begin
					while (myText^^[searchPos] <> char(13)) and (searchPos < numChars) do
						SearchPos := searchPos + 1;
					SearchPos := SearchPos + 1;
					SearchPos2 := SearchPos;
					while (MyText^^[searchPos2] <> char(24)) and (SearchPos2 < numChars) do
					begin
						SearchPos2 := SearchPos2 + 1;
					end;
					SearchPos2 := SearchPos2 - 1;
					SearchPos2 := SearchPos2 - SearchPos;
					TextHnd := Texthand(NewHandle(SearchPos2));
					MoveHHi(handle(textHnd));
					HNoPurge(handle(textHnd));
					OpenTextSize := SearchPos2;
					curtextPos := 0;
					BlockMove(@myText^^[searchPos], @textHnd^^[0], SearchPos2);
					LoadSpecialText := true;
				end;
			end;
		end;
	end;

	procedure LoadHelpFile;
		var
			serialTemp, temp: str255;
			ck, ck2: longint;
			myTempStr: str255;
			sharedref, i, x: integer;
			myHUtils2: CharsHandle;
			LENGTH, cksm: longint;
	begin
		HelpFile := nil;
		UseResFile(TextRes);
		if not curGlobs^.thisUser.AlternateText then
			HelpFile := CharsHandle(GetNamedResource('HTxt', 'Help'))
		else
			HelpFile := CharsHandle(GetNamedResource('ATxt', 'Help'));
		if (ResError = noErr) and (HelpFile <> nil) then
		begin
			DetachResource(handle(HelpFile));
			MoveHHi(handle(HelpFile));
			HNoPurge(handle(HelpFile));
		end;
		useResFile(myResourceFile);
	end;

	procedure LoadFileAsMsg (name: str255);
		var
			tempint: integer;
			templong: longint;
	begin
		with curglobs^ do
		begin
			if curWriting <> nil then
			begin
				HPurge(handle(curWriting));
				DisposHandle(handle(curwriting));
			end;
			curwriting := nil;
			result := FSOpen(name, 0, tempint);
			if (result <> 0) then
			begin
				name := concat(sharedPath, 'misc:', name);
				result := FSOpen(name, 0, tempint);
			end;
			if (result = 0) then
			begin
				result := GetEOF(tempint, templong);
				curWriting := TextHand(NewHandle(templong));
				HNoPurge(handle(curWriting));
				MoveHHi(handle(curWriting));
				result := FSRead(tempint, templong, pointer(curWriting^));
				result := FSClose(tempint);
				SetHandleSize(handle(curWriting), getHandleSize(handle(curWriting)) + 1);
				curWriting^^[getHandleSize(handle(curWriting)) - 1] := char(26);
			end;
		end;
	end;

	procedure HeReadIt (ReadMa: eMailRec);
		var
			tempEM: emailrec;
			tempInt: integer;
	begin
		GetDateTime(tempEM.dateSent);
		tempEM.title := ReadMa.Title;
		if not myUsers^^[readMa.touser - 1].dltd then
		begin
			tempEM.fromUser := ReadMa.toUser;
			tempEM.touser := ReadMa.fromUser;
			tempEM.anonyFrom := false;
			if readma.anonyFrom then
				tempEM.anonyFrom := true;
			tempEM.anonyTo := false;
			tempEM.MType := 0;
			tempEM.multimail := true;
			tempEM.storedAs := 0;
			tempEM.FileAttached := false;
			tempEM.FileName := char(0);
			for tempInt := 0 to 15 do
				tempEM.reserved[tempint] := char(0);
			SetHandleSize(handle(theEmail), GetHandleSize(handle(theEmail)) + SizeOf(emailRec));
			BlockMove(@tempEm, @theEmail^^[availEmails], sizeof(emailrec));
			availEmails := availEmails + 1;
			emailDirty := true;
		end;
	end;

{$D-}

	procedure OpenBase (whichForum, whichSub: integer; extraRec: boolean);
		var
			s1, s2, tempString: str255;
			ref: integer;
			tempLong: longInt;
			s26: string[26];
			s31: string[31];
	begin
		with curglobs^ do
		begin
			CloseBase;
			s26 := MConference[whichForum]^^[whichSub].Name;
			s31 := MForum^^[whichForum].Name;
			tempString := concat(InitSystHand^^.msgsPath, s31, ':', s26, ' Data');
			result := FSOpen(tempString, 0, ref);
			if result = noErr then
			begin
				result := GetEOF(ref, tempLong);
				if tempLong > 0 then
				begin
					if not extraRec then
						curBase := SubDyHand(NewHandle(tempLong))
					else
						Curbase := SubDyHand(NewHandle(tempLong + SizeOf(mesgRec)));
					if MemError = noErr then
					begin
						HNoPurge(handle(curBase));
						MoveHHi(handle(curBase));
						curNumMess := tempLong div SizeOf(mesgRec);
						HLock(handle(curBase));
						result := SetFPos(ref, fsFromStart, 0);
						result := FSRead(ref, tempLong, pointer(curBase^));
						HUnlock(handle(curBase));
					end
					else
					begin
						curNumMess := 0;
					end;
				end
				else
					curNumMess := 0;
				result := FSClose(ref);
			end
			else
			begin
				curNumMess := 0;
				if extraRec then
					Curbase := SubDyHand(NewHandle(SizeOf(mesgRec)))
				else
					curBase := nil;
			end;
		end;
	end;

	procedure SaveBase (wForum, wSub: integer);
		var
			s1, s2, tempstring: str255;
			ref: integer;
			templong: longint;
			s26: string[26];
			s31: string[31];
	begin
		with curglobs^ do
		begin
			s26 := MConference[wForum]^^[wSub].Name;
			s31 := MForum^^[wForum].Name;
			tempString := stringOf(InitSystHand^^.msgsPath, s31, ':', s26, ' Data');
			result := FSDelete(tempString, 0);
			result := Create(tempstring, 0, 'HRMS', 'DATA');
			result := FSOpen(tempstring, 0, ref);
			templong := getHandleSize(handle(curBase));
			result := FSWrite(ref, templong, pointer(curBase^));
			result := FSClose(ref);
		end;
	end;

	procedure dToTabbyDate (theDate: dateTimeRec; var dater: str255; var time: str255);
		var
			t1: str255;
	begin
		NumToString(theDate.month, t1);
		if length(t1) = 1 then
			t1 := concat('0', t1);
		dater := t1;
		NumToString(theDate.day, t1);
		if length(t1) = 1 then
			t1 := concat('0', t1);
		dater := concat(dater, '/', t1);
		if theDate.year >= 2000 then
			NumToString(theDate.year - 2000, t1)
		else
			NumToString(theDate.year - 1900, t1);
		if length(t1) = 1 then
			t1 := concat('0', t1);
		dater := concat(dater, '/', t1);
		NumToString(theDate.hour, t1);
		if length(t1) = 1 then
			t1 := concat('0', t1);
		time := t1;
		NumToString(theDate.minute, t1);
		if length(t1) = 1 then
			t1 := concat('0', t1);
		time := concat(time, ':', t1);
		NumToString(theDate.second, t1);
		if length(t1) = 1 then
			t1 := concat('0', t1);
		time := concat(time, ':', t1);
	end;

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

	procedure CleanMessage;
		var
			tLen, posit, SPPos, Finish: integer;
	begin
		with curglobs^ do
		begin
			tLen := GetHandleSize(handle(curWriting)) - 1;
			posit := 0;
			if (tLen + 1) > 0 then
			begin
				while (posit <= tLen) do
				begin
					if curWriting^^[posit] = char(3) then
					begin
						Finish := CheckColorCodes(posit);
						BlockMove(@curWriting^^[Finish + 1], @curWriting^^[posit], tLen - (Finish + 1));
						SetHandleSize(handle(curWriting), GetHandleSize(handle(curWriting)) - ((Finish + 1) - posit));
						tLen := tLen - ((Finish + 1) - posit);
						posit := posit - 1;
					end
					else if (curWriting^^[posit] = char(8)) or (curWriting^^[posit] = char(11)) or (curWriting^^[posit] = char(9)) then
					begin
						BlockMove(@curWriting^^[posit + 1], @curWriting^^[posit], tLen - (posit + 1));
						SetHandleSize(handle(curWriting), GetHandleSize(handle(curWriting)) - 1);
						tLen := tlen - 1;
					end
					else if (curWriting^^[posit] = char(13)) then
					begin
						if (posit - 1 > 0) then
						begin
							SPPos := posit;
							repeat
								SPPos := SPPos - 1;
							until (SPPos = 0) or (curWriting^^[SPPos] <> char(32));
							if (posit - SPPos > 1) and (SPPos <> 0) then
							begin
								SPPos := SPPos + 1;
								BlockMove(@curWriting^^[posit], @curWriting^^[SPPos], tLen - posit);
								SetHandleSize(handle(curWriting), GetHandleSize(handle(curWriting)) - (posit - SPPos));
								tLen := tLen - (posit - SPPos);
								posit := SPPos;
							end;
						end;
					end;
					posit := posit + 1;
				end;
			end;
		end;
	end;

	procedure DoAddToDailyTotal (NumIm, NumEx: integer);
	external;

	procedure SaveNetPost;
		var
			tempTabby: tabbyHeader;
			tempdstr, temptstr, s: str255;
			myRef, i, x: integer;
			templong: longint;
			nowDate: dateTimeRec;
			TabHeader: string[31];
			holder: charsHandle;
	begin
		with curglobs^ do
		begin
			with tempTabby do
			begin
				holder := charsHandle(NewHandle(getHandleSize(handle(curWriting))));
				HNoPurge(handle(holder));
				BlockMove(pointer(curwriting^), pointer(holder^), GetHandleSize(handle(curWriting)));
				TabHeader := 'AEA N/A ';
				i := (inForum * 100) + inConf;
				NumToString(i, s);
				for i := 5 to length(s) + 5 do
					tabHeader[i] := s[i - 4];
				TabHeader[4] := char(13);
				GetTime(nowDate);
				dToTabbyDate(nowDate, tempdstr, temptstr);
				if length(s) = 4 then
					tabHeader := concat(tabHeader, char(13), tempdStr, char(13), temptStr, char(13))
				else
				begin
					tabHeader[8] := char(13);
					tabHeader := concat(tabHeader, tempdStr, char(13), temptStr, char(13));
				end;
				CleanMessage;
				SetHandleSize(handle(curWriting), GetHandleSize(handle(curWriting)) + 1);
				CurWriting^^[getHandleSize(handle(curWriting)) - 1] := char(13);
				CurWriting^^[getHandleSize(handle(curWriting)) - 2] := char(0);
				s := curMesgRec.title;
				if s[1] = char(0) then
					delete(s, 1, 1);
				AddLine(s);
				if curMesgRec.toUserNum = 0 then
					AddLine('All')
				else
					AddLine(curMesgRec.toUserName);
				if newhand^^.realname and newhand^^.handle and MConference[inForum]^^[inConf].RealNames and (thisUser.realname <> '•') then
					AddLine(thisUser.realname)
				else
					AddLine(thisUser.userName);
				AddLine('');
				s := concat(mailer^^.GenericPath, 'Generic Export');
				result := FSOpen(s, 0, myRef);
				if result <> noErr then
				begin
					result := Create(s, 0, 'HRMS', 'TEXT');
					result := FSOpen(s, 0, myRef);
				end;
				result := SetFPos(myRef, fsFromLEOF, 0);
				tempLong := length(tabHeader);
				result := FSWrite(myRef, tempLong, @tabHeader[1]);
				tempLong := GetHandleSize(handle(curWriting));
				HLock(handle(curWriting));
				result := FSWrite(myRef, templong, pointer(curWriting^));
				HUnlock(handle(curWriting));
				result := FSClose(myRef);
				DisposHandle(handle(curWriting));
				curWriting := TextHand(holder);
				DoAddToDailyTotal(0, 1);
			end;
		end;
	end;

	procedure SaveNetMail (OtherName: str255);
		var
			tempTabby: tabbyHeader;
			tempdstr, temptstr, s: str255;
			myRef, i: integer;
			templong: longint;
			nowDate: dateTimeRec;
			TabHeader: string[31];
	begin
		with curglobs^ do
		begin
			with tempTabby do
			begin
				TabHeader := 'AMA N/A ';
				TabHeader[4] := char(13);
				TabHeader[8] := char(13);
				GetTime(nowDate);
				dToTabbyDate(nowDate, tempdstr, temptstr);
				tabHeader := concat(tabHeader, tempdStr, char(13), temptStr, char(13));
				CleanMessage;
				SetHandleSize(handle(curWriting), GetHandleSize(handle(curWriting)) + 1);
				CurWriting^^[getHandleSize(handle(curWriting)) - 1] := char(13);
				CurWriting^^[getHandleSize(handle(curWriting)) - 2] := char(0);
				if INetMail and (Mailer^^.InternetMail = FidoGated) then
					AddLine(concat('to:  ', myFido.name));
				AddLine(curEmailRec.title);
				if (INetMail) and (Mailer^^.InternetMail = FidoGated) then
				begin
					if FidoNetAccount(Mailer^^.FidoAddress) then
						;
				end;
				AddLine(myFido.name);
				if OtherName <> char(0) then
					AddLine(OtherName)
				else
				begin
					if newHand^^.Handle and newHand^^.realName and Mailer^^.UseRealNames then
						AddLine(thisUser.RealName)
					else
						AddLine(thisUser.userName);
				end;

				AddLine(myFido.atNode);
				s := concat(mailer^^.GenericPath, 'Generic Export');
				result := FSOpen(s, 0, myRef);
				if result <> noErr then
				begin
					result := Create(s, 0, 'HRMS', 'TEXT');
					result := FSOpen(s, 0, myRef);
				end;
				result := SetFPos(myRef, fsFromLEOF, 0);
				tempLong := 26;
				result := FSWrite(myRef, tempLong, @tabHeader[1]);
				tempLong := GetHandleSize(handle(curWriting));
				HLock(handle(curWriting));
				result := FSWrite(myRef, templong, pointer(curWriting^));
				HUnlock(handle(curWriting));
				result := FSClose(myRef);
				DoAddToDailyTotal(0, 1);
			end;
		end;
	end;

	function SaveMessAsEmail: boolean;
		var
			s: str255;
			myRef, i: integer;
			templong: longint;
	begin
		with curglobs^ do
		begin
			curEmailrec.storedAs := SaveMessage(curWriting, 0, 0);
			if (curEmailRec.storedAs <> -1) then
			begin
				if curEmailRec.multimail then
					i := numMultiUsers
				else
					i := 1;
				SetHandleSize(handle(theEmail), GetHandleSize(handle(theEmail)) + (SizeOf(emailRec) * longint(i)));
				if not CurEmailRec.multiMail then
					BlockMove(@curEmailRec, @theEmail^^[availEmails], SizeOf(emailRec))
				else
				begin
					for i := 1 to numMultiUsers do
					begin
						curEmailRec.toUser := multiUsers[i];
						BlockMove(@curEmailRec, @theEmail^^[availEmails + (i - 1)], SizeOf(emailrec));
					end;
					i := numMultiusers;
				end;
				availEmails := availEmails + i;
				emailDirty := true;
				SaveEmailData;
				emailDirty := false;
				SaveMessAsEmail := true;
			end
			else
				SaveMessAsEmail := false;
		end;
	end;


end.