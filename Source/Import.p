{ Segments: Import_1 }
unit Import;

interface
	uses
		AppleTalk, ADSP, Serial, Sound, TCPTypes, Initial, LoadAndSave, Message_Editor, NodePrefs2, NodePrefs, SystemPrefs2;

	procedure doDetermineZMH;
	procedure doCheckForGeneric;
	procedure doMailerImport;
	procedure DrawImportStatus (Increase: boolean; NumBytes: integer);
	procedure WriteNetUsageRecord;
	procedure DoAddToDailyTotal (NumIm, NumEx: integer);

implementation
	type
		NetTotalRec = record
				Calls: integer;
				NumImported: longint;
				NumExported: longint;
			end;

		NetSubRec = record
				Forum: integer;
				Sub: integer;
				Category: integer;
				NumImported: integer;
			end;

{$S Import_1 }
	procedure WriteNetLog (what: str255);
		var
			tempString: str255;
			LogRef, i, tempUserNum: integer;
			templong: longInt;
			result, myOSerr: OSerr;
			myUserHand: UserHand;
	begin
		tempString := concat(sharedPath, 'Misc:Network Today Log');
		result := FSOpen(tempString, 0, LogRef);
		if result <> noErr then
		begin
			result := FSDelete(tempString, 0);
			result := Create(tempString, 0, 'HRMS', 'TEXT');
			result := FSOpen(tempString, 0, LogRef);
		end;
		if result = noErr then
		begin
			what := concat(what, char(13));
			result := SetFPos(LogRef, fsFromLEOF, 0);
			templong := length(what);
			result := FSWrite(LogRef, templong, @what[1]);
		end;
		result := FSClose(LogRef);
	end;

	procedure WriteNetLogTotals;
		var
			result: OSErr;
			templong, NumEntries, TotalImported: longint;
			TheFile, LowEntryFor, LowEntrySub, LowEntryPos, i: integer;
			NetEntry: NetSubRec;
			done: boolean;
			tempstring, tempString2: str255;
			s34: string[34];
	begin
		result := FSOpen(concat(sharedPath, 'Logs:Network:Temp Net'), 0, TheFile);
		if result <> noErr then
			Exit(WriteNetLogTotals);

		WriteNetLog('AREANAME                            FORUM    CON     CAT     MSGS');
		WriteNetLog('----------------------------------  -----    ---     ----    ----');
		result := GetEOF(TheFile, templong);
		NumEntries := templong div SizeOf(NetSubRec);
		templong := SizeOf(NetSubRec);
		done := false;
		while not done do
		begin
			LowEntryFor := 32766;
			LowEntrySub := 32766;
			LowEntryPos := 0;
			result := SetFPos(TheFile, fsFromStart, 0);
			for i := 1 to NumEntries do
			begin
				result := FSRead(TheFile, templong, @NetEntry);
				if (NetEntry.Forum < LowEntryFor) then
					LowEntryFor := NetEntry.Forum;
			end;

			result := SetFPos(TheFile, fsFromStart, 0);
			for i := 1 to NumEntries do
			begin
				result := FSRead(TheFile, templong, @NetEntry);
				if (NetEntry.Forum = LowEntryFor) and (NetEntry.Sub < LowEntrySub) then
				begin
					LowEntrySub := NetEntry.Sub;
					LowEntryPos := i - 1;
				end;
			end;

			if (LowEntrySub <> 32766) and (LowEntryFor <> 32766) then
			begin
				result := SetFPos(TheFile, fsFromStart, templong * LowEntryPos);
				result := FSRead(TheFile, templong, @NetEntry);
				if (NetEntry.Sub = 0) and (NetEntry.Forum = 0) then
					s34 := concat('Network Mail', '                                  ')
				else
					s34 := concat(MConference[NetEntry.Forum]^^[NetEntry.Sub].Name, '                                  ');
				tempstring := concat(s34, '  ');
				NumToString(NetEntry.Forum, tempstring2);
				if (length(tempString2) = 1) then
					tempString2 := concat('00', tempstring2)
				else if (length(tempstring2) = 2) then
					tempString2 := concat('0', tempString2);
				tempString := concat(tempString, ' ', tempString2);

				NumToString(NetEntry.Sub, tempstring2);
				if (length(tempString2) = 1) then
					tempString2 := concat('00', tempstring2)
				else if (length(tempstring2) = 2) then
					tempString2 := concat('0', tempString2);
				tempString := concat(tempString, '     ', tempString2);

				NumToString(NetEntry.Category, tempstring2);
				if (length(tempString2) = 1) then
					tempString2 := concat('000', tempstring2)
				else if (length(tempstring2) = 2) then
					tempString2 := concat('00', tempString2)
				else if (length(tempstring2) = 3) then
					tempString2 := concat('0', tempString2);
				tempString := concat(tempString, '     ', tempString2);

				NumToString(NetEntry.NumImported, tempstring2);
				for i := 4 downto length(tempstring2) do
					tempstring2 := concat(' ', tempstring2);
				tempstring := concat(tempstring, '   ', tempstring2);

				WriteNetLog(tempstring);

				NetEntry.Forum := 32766;
				NetEntry.Sub := 32766;
				result := SetFPos(TheFile, fsFromStart, templong * LowEntryPos);
				result := FSWrite(TheFile, templong, @NetEntry);
			end
			else
				done := true;
		end;
		result := FSClose(TheFile);
	end;

	procedure WriteToUsage (what: str255);
		var
			result: OSErr;
			templong, count, count2: longint;
			TheFile, TheFile2: integer;
			tempstring, tempstring2: str255;
			TheText: handle;
	begin
		result := FSOpen(concat(sharedPath, 'Misc:Network Usage Record'), 0, TheFile);
		if result <> noErr then
		begin
			result := Create(concat(sharedPath, 'Misc:Network Usage Record'), 0, 'HRMS', 'TEXT');
			result := FSOpen(concat(sharedPath, 'Misc:Network Usage Record'), 0, TheFile);
			tempstring := concat('DATE        DAY   CALLS   IMPORTED   EXPORTED', char(13));
			tempstring := concat(tempstring, '--------    ---   -----   --------   --------', char(13));
			templong := length(tempstring);
			result := FSWrite(TheFile, templong, @tempstring[1]);
			what := concat(what, char(13));
			result := SetFPos(TheFile, fsFromLEOF, 0);
			templong := length(what);
			result := FSWrite(TheFile, templong, @what[1]);
			result := FSClose(TheFile);
		end
		else
		begin
			tempstring := concat('DATE        DAY   CALLS   IMPORTED   EXPORTED', char(13));
			tempstring := concat(tempstring, '--------    ---   -----   --------   --------', char(13));
			tempstring2 := concat(tempstring, what, char(13));
			templong := length(tempstring2);

			result := Create(concat(sharedPath, 'Misc:TNetwork Usage Record'), 0, 'HRMS', 'TEXT');
			result := FSOpen(concat(sharedPath, 'Misc:TNetwork Usage Record'), 0, TheFile2);
			result := SetEOF(TheFile2, count);
			result := SetFPos(TheFile2, fsFromStart, 0);
			result := FSWrite(TheFile2, templong, @tempString2[1]);

			count := length(tempstring);
			result := GetEOF(TheFile, count2);
			count2 := count2 - count;
			result := SetFPos(TheFile, fsFromStart, count);
			TheText := NewHandle(count2);
			result := FSRead(TheFile, count2, pointer(TheText^));
			result := FSClose(TheFile);
			result := FSDelete(concat(sharedPath, 'Misc:Network Usage Record'), 0);
			result := SetEOF(TheFile2, templong + count2);
			result := SetFPos(TheFile2, fsFromStart, templong);
			result := FSWrite(TheFile2, count2, pointer(TheText^));
			DisposHandle(TheText);

			result := GetEOF(TheFile2, count2);
			count := 13549;
			if count2 > count then
				result := SetEOF(TheFile2, count);
			result := FSClose(TheFile2);
			result := Rename(concat(sharedPath, 'Misc:TNetwork Usage Record'), 0, concat(sharedPath, 'Misc:Network Usage Record'));
		end;
	end;

	procedure WriteNetUsageRecord;
		var
			result: OSErr;
			templong: longint;
			TheFile, i: integer;
			NetTotal: NetTotalRec;
			tempstring, tempstring2: str255;
	begin
		templong := SizeOf(NetTotalRec);
		result := FSOpen(concat(sharedPath, 'Logs:Network:Temp Usage Net'), 0, TheFile);
		result := FSRead(TheFile, templong, @NetTotal);
		result := FSClose(TheFile);
		NumToString(InitSystHand^^.lastmaint.month, tempString);
		if length(tempString) = 1 then
			tempString := concat('0', tempString);
		NumToString(InitSystHand^^.lastMaint.day, tempString2);
		if length(tempString2) = 1 then
			tempString2 := concat('0', tempString2);
		tempString := concat(tempString, '/', tempString2);
		NumToString(InitSystHand^^.lastMaint.year, tempString2);
		tempString2[1] := tempString2[3];
		tempString2[2] := tempString2[4];
		tempString2[0] := char(2);
		tempString := concat(tempString, '/', tempString2, '    ');
		whatDay(InitSystHand^^.lastmaint, tempString2);
		tempString2[0] := char(3);
		tempString := concat(tempString, tempString2, '  ');
		NumToString(NetTotal.Calls, tempstring2);
		for i := 5 downto length(tempstring2) do
			tempstring2 := concat(' ', tempstring2);
		tempstring := concat(tempstring, tempstring2, '  ');
		NumToString(NetTotal.NumImported, tempstring2);
		for i := 8 downto length(tempstring2) do
			tempstring2 := concat(' ', tempstring2);
		tempstring := concat(tempstring, tempstring2, '  ');
		NumToString(NetTotal.NumExported, tempstring2);
		for i := 8 downto length(tempstring2) do
			tempstring2 := concat(' ', tempstring2);
		tempstring := concat(tempstring, tempstring2);
		WriteToUsage(tempstring);

		result := FSDelete(concat(sharedPath, 'Logs:Network:Temp Usage Net'), 0);
		result := Create(concat(sharedPath, 'Logs:Network:Temp Usage Net'), 0, 'HRMS', 'DATA');
		result := FSOpen(concat(sharedPath, 'Logs:Network:Temp Usage Net'), 0, TheFile);
		NetTotal.Calls := 0;
		NetTotal.NumImported := 0;
		NetTotal.NumExported := 0;
		result := FSWrite(TheFile, templong, @NetTotal);
		result := FSClose(TheFile);
	end;

	procedure doDetermineZMH;
		var
			result: OSErr;
			tabRef: integer;
			templong, templong2: longint;
			nextTime: OSType;
			nextTimeFull: DateTimeRec;
			tempStr: str255;
	begin
		result := FSOpen(concat(Mailer^^.EventPath, 'Next Event'), 0, tabref);
		if result = noErr then
		begin
			templong := 4;
			result := FSRead(tabRef, templong, @nextTime);
			GetDateTime(templong);
			templong2 := templong;
			Secs2Date(templong2, nextTimeFull);
			tempStr := copy(nextTime, 1, 2);
			StringToNum(tempStr, templong2);
			nextTimeFull.hour := templong2;
			tempStr := copy(nextTime, 3, 2);
			StringToNum(tempStr, templong2);
			nextTimeFull.minute := templong2;
			Date2Secs(nextTimeFull, templong2);
			if templong2 < templong then
				templong2 := templong2 + 86400;
			dailyTabbyTime := templong2;
			result := FSClose(tabRef);
			with curglobs^ do
			begin
			end;
		end
		else
			dailyTabbyTime := 0;
	end;

	procedure DrawImportStatus (Increase: boolean; NumBytes: integer);
		var
			itemType, tempint, tempint2: integer;
			itemHandle: handle;
			tempRect: rect;
			s: str255;
			templong, templong2: longint;
			SavePort: GrafPtr;
	begin
		if ImportStatusDlg <> nil then
		begin
			GetPort(SavePort);
			SetPort(ImportStatusDlg);
			if increase then
				NumImported := NumImported + 1;
			GetDItem(ImportStatusDlg, 2, itemType, itemHandle, tempRect);
			NumToString(NumImported, s);
			SetIText(itemHandle, s);
			GetDItem(ImportStatusDlg, 7, itemType, itemHandle, tempRect);
			GetIText(itemHandle, s);
			StringToNum(s, templong);
			if NumBytes > 0 then
			begin
				templong := templong + NumBytes;
				if tempLong > GBytes then
					tempLong := GBytes;
				NumToString(templong, s);
				SetIText(itemHandle, s);
			end
			else if NumBytes = -1 then
			begin
				NumToString(GBytes, s);
				templong := GBytes;
				SetIText(itemHandle, s);
			end
			else if NumBytes = -99 then {Update}
			begin
				SetIText(itemHandle, s);
				SetTextBox(ImportStatusDlg, 1, 'Importing Message :');
				NumToString(NumImported, s);
				SetTextBox(ImportStatusDlg, 2, s);
				SetTextBox(ImportStatusDlg, 4, 'Bytes processed :');
				NumToString(GBytes, s);
				SetTextBox(ImportStatusDlg, 5, s);
				SetTextBox(ImportStatusDlg, 6, 'File size :');
				if ImportLoopTime = 0 then
					s := 'Very Fast'
				else if ImportLoopTime = 8 then
					s := 'Fast'
				else if ImportLoopTime = 20 then
					s := 'Slow'
				else if ImportLoopTime = 40 then
					s := 'Very Slow';
				SetTextBox(ImportStatusDlg, 8, concat('Import Speed: ', s));
				GetDItem(ImportStatusDlg, 3, itemType, itemHandle, tempRect);
				ForeColor(blackColor);
				EraseRect(tempRect);
				FrameRect(tempRect);
				ForeColor(GreenColor);
				tempInt := ((tempRect.right - tempRect.left) * templong) div GBytes;
				if tempInt > (tempRect.right - tempRect.left) then
					tempint := (tempRect.right - tempRect.left);
				tempRect.right := tempRect.left + tempInt;
				if tempRect.right > temprect.left then
				begin
					InsetRect(tempRect, 1, 1);
					PaintRect(tempRect);
				end;
				ForeColor(blackColor);

				templong := -99;
			end;

			if templong > 0 then
			begin
				if ImportLoopTime = 0 then
					s := 'Very Fast'
				else if ImportLoopTime = 8 then
					s := 'Fast'
				else if ImportLoopTime = 20 then
					s := 'Slow'
				else if ImportLoopTime = 40 then
					s := 'Very Slow';
				SetTextBox(ImportStatusDlg, 8, concat('Import Speed: ', s));
				GetDItem(ImportStatusDlg, 3, itemType, itemHandle, tempRect);
				ForeColor(BlackColor);
				FrameRect(tempRect);
				ForeColor(GreenColor);
				tempInt := ((tempRect.right - tempRect.left) * templong) div GBytes;
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
			SetPort(SavePort);
		end;
	end;

	function doCompareFileSize (theRef: integer): boolean;
		var
			result: OSErr;
			tempBytes: longint;
	begin
		result := GetEOF(theRef, tempBytes);
		if GBytes = tempBytes then
			doCompareFileSize := true
		else
		begin
			GBytes := tempBytes;
			doCompareFileSize := false;
		end;
	end;

	procedure doCheckForGeneric;
		var
			result: OSErr;
			i: integer;
			templong: longint;
			tempString: str255;
	begin
		lastGenericCheck := tickcount;
		result := FSOpen(concat(mailer^^.GenericPath, 'Generic Import'), 0, i);
		if result = noErr then
		begin
			if doCompareFileSize(i) then
			begin
				ImportRef := i;
				GenericImport := charsHandle(NewHandle(HANDLE_SIZE));
				if memError = noErr then
				begin
					HLock(handle(GenericImport));
					result := GetEOF(ImportRef, FileSize);
					if FileSize > 20 then
					begin
						PlaceInFile := 0;
						DataLeft := 0;
						NumImported := 0;
						BreakMessage := NoBreak;
						isGeneric := true;
						if Mailer^^.ImportSpeed = 1 then
							ImportLoopTime := 0
						else if Mailer^^.ImportSpeed = 2 then
							ImportLoopTime := 8
						else if Mailer^^.ImportSpeed = 3 then
							ImportLoopTime := 20
						else
							ImportLoopTime := 40;
						HandleEmpty := true;
						result := FSClose(ImportRef);
						result := FSDelete(concat(Mailer^^.GenericPath, 'Working GenImport'), 0);
						result := Rename(concat(Mailer^^.GenericPath, 'Generic Import'), 0, concat(mailer^^.GenericPath, 'Working GenImport'));
						result := FSDelete(concat(Mailer^^.GenericPath, 'Old GenImport'), 0);
						result := FSOpen(concat(Mailer^^.GenericPath, 'Working GenImport'), 0, ImportRef);
						result := FSOpen(concat(sharedPath, 'Logs:Network:Any File'), 0, i);
						if result = -120 then
							result := DirCreate(0, 0, concat(sharedPath, 'Logs:Network'), templong);
						result := FSClose(i);
						WriteNetLog(concat('Import started at : ', whattime(-1)));
						result := FSDelete(concat(sharedPath, 'Logs:Network:Temp Net'), 0);
						result := Create(concat(sharedPath, 'Logs:Network:Temp Net'), 0, 'HRMS', 'DATA');
						result := FSOpen(concat(sharedPath, 'Logs:Network:Temp Net'), 0, NetRef);
						NumNets := 0;
						ImportStatusDlg := GetNewDialog(200, nil, pointer(-1));
						SetPort(ImportStatusDlg);
						SetGeneva(ImportStatusDlg);
						NumToString(GBytes, tempstring);
						SetTextBox(ImportStatusDlg, 5, tempstring);
						DrawDialog(ImportStatusDlg);
						DrawImportStatus(false, -99);
					end
					else
					begin
						HUnlock(handle(GenericImport));
						DisposHandle(handle(GenericImport));
						GenericImport := nil;
						result := FSClose(ImportRef);
					end;
				end
				else
				begin
					DisposHandle(handle(GenericImport));
					GenericImport := nil;
					result := FSClose(ImportRef);
					WriteNetLog('** Unable to create Handle Generic Import **');
				end;
			end
			else
				result := FSClose(i);
		end;
	end;

	procedure AddToNetRef (F, S, C: integer);
		var
			NetData, NetEntry: NetSubRec;
			i: integer;
			result: OSErr;
			templong: longint;
	begin
		NetData.Forum := F;
		NetData.Sub := S;
		NetData.Category := C;
		i := 0;
		result := SetFPos(NetRef, fsFromStart, 0);
		tempLong := SizeOf(NetSubRec);
		for i := 1 to NumNets do
		begin
			result := FSRead(NetRef, templong, @NetEntry);
			if (NetEntry.Forum = NetData.Forum) and (NetEntry.Sub = NetData.Sub) then
			begin
				NetEntry.NumImported := NetEntry.NumImported + 1;
				result := SetFPos(NetRef, fsFromStart, templong * (i - 1));
				result := FSWrite(NetRef, templong, @NetEntry);
				Exit(AddToNetRef);
			end;
		end;
		NetData.NumImported := 1;
		result := SetFPos(NetRef, fsFromLEOF, 0);
		result := FSWrite(NetRef, templong, @NetData);
		NumNets := NumNets + 1;
	end;

	procedure DoAddToDailyTotal (NumIm, NumEx: integer);
		var
			result: OSErr;
			templong: longint;
			TheFile: integer;
			NetRec: NetTotalRec;
	begin
		templong := SizeOf(NetTotalRec);
		result := FSOpen(concat(sharedPath, 'Logs:Network:Temp Usage Net'), 0, TheFile);
		if result <> noErr then
		begin
			result := Create(concat(sharedPath, 'Logs:Network:Temp Usage Net'), 0, 'HRMS', 'DATA');
			result := FSOpen(concat(sharedPath, 'Logs:Network:Temp Usage Net'), 0, TheFile);
			NetRec.Calls := 1;
			NetRec.NumImported := NumIm;
			NetRec.NumExported := NumEx;
		end
		else
		begin
			result := FSRead(TheFile, templong, @NetRec);
			NetRec.Calls := NetRec.Calls + 1;
			NetRec.NumImported := NetRec.NumImported + NumIm;
			NetRec.NumExported := NetRec.NumExported + NumEx;
			result := SetFPos(TheFile, fsFromStart, 0);
		end;
		result := FSWrite(TheFile, templong, @NetRec);
		result := FSClose(TheFile);
	end;

	procedure doMailerImport;
		var
			i, dm, theFile, savedinForum, savedinSub: integer;
			tempStr, fromStr, toStr, t9, s: str255;
			templong, Category: longint;
			tempEMailRec: EMailRec;
			tempMessRec: MesgRec;
	begin
		with curGlobs^ do
		begin
			case MailerDo of
				MailerOne: (* Read Data Into GenericImport *)
				begin
					if HandleEmpty then
					begin
						NextRead := HANDLE_SIZE - dataLeft;
						if NextRead + PlaceInFile > FileSize then
							NextRead := FileSize - PlaceInFile;
						result := FSRead(ImportRef, NextRead, @GenericImport^^[DataLeft]);
						DataLeft := NextRead + DataLeft;
						PlaceInFile := PlaceInFile + NextRead;
						HandleEmpty := false;
					end;
					MailerDo := MailerTwo;
				end;
				MailerTwo: 
				begin
					for i := 0 to DataLeft do
						if GenericImport^^[i] = char(0) then	{End of Message}
							leave;

					curPlace := i + 1;
					if (curPlace >= 25000) and (PlaceInFile <= FileSize) and (GenericImport^^[25000] <> char(0)) then
					begin
						if (BreakMessage = NoBreak) then
						begin
							BreakMessage := FirstPass;
							BreakNumber := 1;
						end;
						i := 25000;
						if (GenericImport^^[i] <> char(13)) then
							for i := 25000 downto 24500 do
								if GenericImport^^[i] = char(13) then
									leave;
						curPlace := i;

						MailerDo := MailerThree;
					end
					else if (GenericImport^^[curPlace - 1] = char(0)) then
					begin
						if (BreakMessage <> NoBreak) then
							BreakMessage := LastPass;
						MailerDo := MailerThree;
					end
					else
					begin
						HandleEmpty := true;
						if (PlaceInFile >= FileSize) then
							MailerDo := MailerFive
						else
							MailerDo := MailerOne;
					end;
				end;
				MailerThree: 
				begin
					if (BreakMessage = FirstPass) or (BreakMessage = NoBreak) then
					begin
						if GenericImport^^[1] = 'M' then
							if GenericImport^^[7] = char(13) then	{Support for Aeouls using 000 instead of 0}
								i := 27
							else
								i := 24
						else if GenericImport^^[7] = char(13) then
							i := 26
						else
							i := 27;
						BlockMove(@GenericImport^^[0], @MessHeader[1], i);
					end
					else
						i := 0;

					MessageLen := curPlace - i;
					curWriting := TextHand(newHandle(MessageLen + 10));
					BlockMove(@GenericImport^^[i], pointer(curWriting^), MessageLen);
					s := concat('--------------------------------- CUT HERE ---------------------------------', char(13));
					templong := length(s);
					if (BreakMessage = FirstPass) or (BreakMessage = OtherPass) then
					begin
						SetHandleSize(handle(curWriting), GetHandleSize(handle(curWriting)) + templong);
						curWriting^^[MessageLen] := char(13);
						curWriting^^[MessageLen + 1] := char(13);
						MessageLen := MessageLen + 1;
						for i := 1 to templong do
							curWriting^^[MessageLen + i] := s[i];
						MessageLen := MessageLen + tempLong + 1;
					end;
					if (BreakMessage = LastPass) or (BreakMessage = OtherPass) then
					begin
						SetHandleSize(handle(curWriting), GetHandleSize(handle(curWriting)) + (templong));
						BlockMove(@curWriting^^[0], @curWriting^^[tempLong + 1], MessageLen);
						for i := 1 to tempLong do
							curWriting^^[i - 1] := s[i];
						curWriting^^[templong] := char(13);
						MessageLen := MessageLen + tempLong + 1;
					end;
					if (BreakMessage = FirstPass) or (BreakMessage = OtherPass) then
						curWriting^^[MessageLen] := char(0);

					realLen := 0;
					dm := 0;
					for i := 0 to MessageLen do
					begin
						if (curWriting^^[i] = char(0)) then  (* Is it the end of the message? *)
						begin
							realLen := i;  (* Actual num of chars till char(0) *)
							i := MessageLen;  (* to break out of while do loop *)
						end
						else  (* If not the end of the message then *)
						begin
							if (curWriting^^[i] = char(1)) then  (* Removing Control A's *)
							begin
								dm := i;
								repeat
									dm := dm + 1;
								until (curWriting^^[dm] = char(13)) or (curWriting^^[dm] = char(0));
								BlockMove(@curWriting^^[dm + 1], @curWriting^^[i], MessageLen - (dm + 1));
								i := i - 1;
								dm := 0;
							end;
							if (curWriting^^[i] <> char(13)) then  (* Proper Line Length *)
								dm := dm + 1
							else
								dm := 0;
							if (dm = 80) then  (* End of Line, go back and find space to word wrap *)
							begin
								for dm := 80 downto 40 do
									if (curWriting^^[i] = ' ') then
									begin
										curWriting^^[i] := char(13);
										leave;
									end
									else
										i := i - 1;
								dm := 0;
							end;
						end;
					end;
					MailerDo := MailerFour;
				end;
				MailerFour: 
				begin
					curWriting^^[realLen] := char(26);  (* Making Last char be Hermes end of message char *)
					SetHandleSize(handle(curWriting), realLen + 1);
					tempEMailRec := curEMailRec;
					tempMessRec := curMesgRec;
					savedinForum := inForum;
					savedinSub := inConf;

					(* Now figure out what type of message we imported M is EMail & E is Post *)
					if (MessHeader[2] = 'M') and (MessHeader[1] <> 'D') then
					begin
						if (BreakMessage = NoBreak) or (BreakMessage = FirstPass) then
						begin
							tempStr := TakeMsgTop;	{Fido Address}
							fromStr := TakeMsgTop;	{From Name}
							fromStr := concat(fromStr, ', ', tempStr);
							toStr := TakeMsgTop;		{To Name}
							tempStr := takeMsgTop;	{Title}
							if (tempstr = char(0)) or (tempstr = ' ') or (tempStr[1] = char(0)) then
								tempstr := '<UNTITLED>';
							curEmailRec.title := tempStr;
							if curWriting^^[0] = char(1) then
								t9 := takeMsgTop;	{Remove the offending characater}

							curEmailRec.FileAttached := false;
							curEmailRec.FileName := char(0);
							curEmailRec.anonyFrom := false;
							curEmailRec.anonyTo := false;
							curEmailRec.fromUser := TABBYTOID;
							if newHand^^.Handle and newHand^^.realName then
								s := '%'
							else
								s := '';
							if FindUser(concat(s, toStr), tempUser) then
								curEmailRec.toUser := tempuser.userNum
							else
							begin
								curEmailRec.toUser := 1;
								if FindUser('1', tempUser) then
									;
							end;

							ForwardedToNet := false;
							if tempUser.MailBox then
							begin
								if (pos(',', tempUser.ForwardedTo) = 0) and (pos('@', tempUser.ForwardedTo) = 0) then {Not to Net Address}
								begin
									StringToNum(tempUser.ForwardedTo, tempLong);
									curEMailRec.toUser := tempLong;
								end
								else
								begin
									ForwardedToNet := true;
									BreakToName := tempUser.ForwardedTo;
								end;
							end;

							GetDateTime(curEmailRec.dateSent);
							curEmailRec.MType := 1;
							curEmailRec.multiMail := false;
							for i := 0 to 15 do
								curMesgRec.reserved[i] := char(0);

							if BreakMessage = FirstPass then
							begin
								BreakMessage := OtherPass;
								BreakTitle := curEmailRec.title;
								curEmailRec.title := concat('[1] ', curEmailRec.title);
								BreakFrom := fromStr;
								BreakToNum := curEMailRec.toUser;
							end;
						end
						else
						begin
							BreakNumber := BreakNumber + 1;
							curEMailRec.title := StringOf('[', BreakNumber : 0, '] ', BreakTitle);
							curEMailRec.toUser := BreakToNum;
							curEmailRec.FileAttached := false;
							curEmailRec.FileName := char(0);
							curEmailRec.anonyFrom := false;
							curEmailRec.anonyTo := false;
							curEmailRec.fromUser := TABBYTOID;
							GetDateTime(curEmailRec.dateSent);
							curEmailRec.MType := 1;
							curEmailRec.multiMail := false;
							fromStr := BreakFrom;
							for i := 0 to 15 do
								curMesgRec.reserved[i] := char(0);
						end;

						AddLine('');
						AddLine(fromStr);
						if ForwardedToNet then
						begin
							if FidoNetAccount(BreakToName) then
							begin
								NetMail := true;
								INetMail := false;
								tempStr := takeMsgTop;
								SaveNetMail(tempStr);
								DrawImportStatus(true, realLen);
							end
							else if InternetAccount(BreakToName) then
							begin
								NetMail := false;
								INetMail := true;
								tempStr := takeMsgTop;
								SaveNetMail(tempStr);
								DrawImportStatus(true, realLen);
							end
							else
							begin
								if SaveMessAsEmail then
									DrawImportStatus(true, realLen)
								else
									WriteNetLog('IMPORT ERROR: EMAIL DATABASE IS FULL');
							end;
						end
						else
						begin
							if SaveMessAsEmail then
								DrawImportStatus(true, realLen)
							else
								WriteNetLog('IMPORT ERROR: EMAIL DATABASE IS FULL');
						end;
						AddToNetRef(0, 0, 0);
					end
					else if (MessHeader[2] = 'E') and (MessHeader[1] <> 'D') then
					begin
						if (BreakMessage = NoBreak) or (BreakMessage = FirstPass) then
						begin
							if MessHeader[8] = char(13) then
								tempStr := copy(MessHeader, 5, 3)
							else
								tempStr := copy(MessHeader, 5, 4);
							StringToNum(tempStr, Category);
							inForum := Category div 100;
							inConf := (Category - (inforum * 100));
							tempStr := takeMsgTop;
							fromStr := TakeMsgTop;
							if length(tempStr) > 0 then
								fromStr := concat(fromStr, ', ', tempStr);
							toStr := TakeMsgTop;
							if curWriting^^[0] = char(1) then
								t9 := takeMsgTop;
							tempStr := takeMsgTop;
							if (tempstr = char(0)) or (tempstr = ' ') or (tempStr[1] = char(0)) then
								tempstr := '<UNTITLED>';
							if curWriting^^[0] = char(1) then
								t9 := takeMsgTop;
							if curWriting^^[0] = char(1) then
								t9 := takeMsgTop;

							curMesgRec.title := tempStr;
							if (pos('RE: ', tempStr) = 1) or (pos('Re: ', tempStr) = 1) then
								curMesgRec.title := concat(char(0), curMesgRec.title);
							curMesgRec.AnonyFrom := false;
							curMesgRec.anonyTo := false;
							curMesgRec.fromUserNum := TABBYTOID;
							curMesgRec.fromUserName := fromStr;
							if newHand^^.Handle and newHand^^.realName then
								s := '%'
							else
								s := '';
							if FindUser(concat(s, toStr), editingUser) then
								curMesgRec.toUserNum := editingUser.userNum
							else
								curMesgRec.toUserNum := TABBYTOID;
							curMesgRec.touserName := toStr;
							curMesgRec.deletable := true;
							curMesgRec.FileAttached := false;
							curMesgRec.FileName := char(0);
							GetDateTime(curMesgRec.DateEn);
							for i := 0 to 20 do
								curMesgRec.reserved[i] := char(0);

							if MessHeader[8] = char(13) then			{Date}
								tempStr := copy(MessHeader, 9, 17)
							else
								tempStr := copy(MessHeader, 10, 17);
							tempStr[9] := ' ';

							if (BreakMessage = FirstPass) then
							begin
								BreakMessage := OtherPass;
								if (curMesgRec.title[1] = char(0)) then
									Delete(curMesgRec.title, 1, 1);
								BreakTitle := curMesgRec.title;
								curMesgRec.title := concat('[1] ', curMesgRec.title);
								BreakInForum := inForum;
								BreakInConf := inConf;
								BreakFrom := curMesgRec.fromUserName;
								BreakToNum := curMesgRec.toUserNum;
								BreakToName := curMesgRec.toUserName;
								BreakDate := tempStr;
							end;
						end
						else
						begin
							BreakNumber := BreakNumber + 1;
							curMesgRec.title := StringOf('[', BreakNumber : 0, '] ', BreakTitle);
							curMesgRec.toUserNum := BreakToNum;
							curMesgRec.toUserName := BreakToName;
							curMesgRec.fromUserName := BreakFrom;
							curMesgRec.AnonyFrom := false;
							curMesgRec.anonyTo := false;
							curMesgRec.fromUserNum := TABBYTOID;
							curMesgRec.deletable := true;
							curMesgRec.FileAttached := false;
							curMesgRec.FileName := char(0);
							GetDateTime(curMesgRec.DateEn);
							for i := 0 to 20 do
								curMesgRec.reserved[i] := char(0);
							tempStr := BreakDate;
							inForum := BreakInForum;
							inConf := BreakInConf;
						end;

						if (inForum <= InitSystHand^^.numMForums) and (inConf <= MForum^^[inForum].NumConferences) then
						begin
							AddLine('');
							AddLine(tempStr);
							if SavePost(inforum, inConf) then
								DrawImportStatus(true, realLen)
							else
								WriteNetLog(StringOf('IMPORT ERROR: FORUM ', inForum : 0, ', CONF ', inConf : 0, ' MESSAGE TOO LARGE.'));
							AddToNetRef(inForum, inConf, Category);
							OpenBase(inForum, inConf, false);
							if curNumMess > MConference[inForum]^^[inConf].MaxMessages then
							begin
								dm := 0;
								i := 1;
								while (dm = 0) and (i <= curNumMess) do
								begin
									if curBase^^[i - 1].deletable then
										dm := i;
									i := i + 1;
								end;
								if dm = 0 then
									dm := 1;
								CloseBase;
								DeletePost(inForum, inConf, dm, true);
							end;
						end;
					end;

					HUnlock(handle(curWriting));
					HPurge(handle(curWriting));
					DisposHandle(handle(curWriting));
					curWriting := nil;

					if (BreakMessage = LastPass) then
						BreakMessage := NoBreak;
					if (BreakMessage = NoBreak) then
						curPlace := curPlace + 1;
					if dataLeft - curPlace > 0 then (* Move the block the size of the last import *)
						BlockMove(@GenericImport^^[curPlace], @GenericImport^^[0], dataLeft - curPlace);
					dataLeft := dataLeft - curPlace;  (* Subtract from what was read in the size of the message imported *)

					SavedImport := true;
					curEMailRec := tempEMailRec;
					curMesgRec := tempMessRec;
					inForum := savedinForum;
					inConf := savedinSub;
				end;
				MailerFive: 
				begin
					DrawImportStatus(false, -1);
					HPurge(handle(GenericImport));
					HUnlock(Handle(GenericImport));
					DisposHandle(handle(GenericImport));
					result := FSClose(ImportRef);
					result := Rename(concat(Mailer^^.GenericPath, 'Working GenImport'), 0, concat(Mailer^^.GenericPath, 'Old GenImport'));
					result := FSClose(NetRef);
					NumToString(numImported, tempStr);
					WriteNetLog(concat('Imported ', tempStr, ' network messages.'));
					WriteNetLog('Imported message breakdown:');
					WriteNetLog(' ');
					WriteNetLogTotals;
					DoAddToDailyTotal(numImported, 0);
					WriteNetLog(' ');
					result := FSOpen(concat(mailer^^.GenericPath, 'Old GenImport'), 0, i);
					result := GetEOF(i, templong);
					result := FSClose(i);
					NumToString(templong, tempStr);
					WriteNetLog(concat('Import file size : ', tempStr, ' bytes.'));
					WriteNetLog(concat('Import ended at : ', whattime(-1)));
					WriteNetLog(' ');
					doSystRec(true);
					isGeneric := false;
					savedImport := true;
					lastGenericCheck := tickCount + 3600;
					GBytes := 0;
					DisposDialog(ImportStatusDlg);
					ImportStatusDlg := nil;
				end;
				otherwise
					;
			end;
		end;
	end;


end.