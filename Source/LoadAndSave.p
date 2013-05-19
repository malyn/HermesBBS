{$S LoadAndSave_1}
unit LoadAndSave;

interface

	uses
		AppleTalk, ADSP, Serial, Sound, Initial, CTBUtilities, CreateNewFiles;

	procedure WriteUser (theUser: UserRec);
	procedure DoSystRec (Save: boolean);
	procedure DoMenuRec (Save: boolean);
	procedure DoTransRec (Save: boolean);
	procedure DoForumRec (Save: boolean);
	procedure DoGFileRec (Save: boolean);
	procedure DoMailerRec (Save: boolean);
	procedure DoSecRec (Save: boolean);
	procedure LoadNewUser (Save: boolean);
	procedure DoFBRec (Save: boolean);
	procedure DoMForumRec (Save: boolean);
	procedure DoMConferenceRec (Save: Boolean; WhichOne: integer);
	procedure DoAddressBooks (var TheBook: AddressBookHand; TheUserNum: integer; Save: boolean);
	procedure LoadActionWordList;
	procedure SaveRemoveActionWord (Save: boolean; AW: ActionWordRec; Offset: longint);

implementation
{$S LoadAndSave_1}
	procedure WriteUser;
		var
			tempstring: str255;
			result: OSerr;
			SizeofAUser: LongInt;
			UsersRes: integer;
	begin
		SizeOfaUser := SizeOf(UserRec);
		result := FSOpen(concat(SharedFiles, 'Users'), 0, UsersRes);
		if result <> noErr then
		begin
			result := Create(concat(sharedFiles, 'Users'), 0, 'HRMS', 'DATA');
			result := FSOpen(concat(SharedFiles, 'Users'), 0, UsersRes);
		end;
		result := SetFPos(UsersRes, fsFromStart, (SizeOfaUser * longint(theUser.UserNum - 1)));
		Result := FSWrite(UsersRes, SizeofAUser, @theUser);
		Result := FSClose(UsersRes);
	end;

	procedure DoSystRec (Save: boolean);
		var
			SystemRes: integer;
			tempSystHand: SystHand;
	begin
		SystemRes := OpenRFPerm(concat(SharedFiles, 'System Prefs'), 0, fsRdWrPerm);
		if SystemRes = -1 then
			sysbeep(10);
		handle(tempSystHand) := Get1Resource('Sprf', 0);
		if reserror <> noErr then
			sysbeep(10);
		HNoPurge(handle(tempSystHand));
		if reserror <> noErr then
			sysbeep(10);
		if save then
			tempSystHand^^ := InitSystHand^^
		else
			InitSystHand^^ := tempSystHand^^;
		if save then
		begin
			ChangedResource(handle(tempSystHand));
			WriteResource(handle(tempSystHand));
		end;
		HPurge(handle(tempSystHand));
		CloseResFile(SystemRes);
		UseResFile(myResourceFile);
	end;

	procedure DoMenuRec (Save: boolean);
		var
			tempFileName: str255;
			sharedRef, GFilesRes: integer;
			initMenuHand: NodeMenuHand;
	begin
		GFilesRes := OpenRFPerm(concat(SharedFiles, 'Menus'), 0, fsRdWrPerm);
		handle(initMenuHand) := Get1Resource('MenU', 0);
		HNoPurge(handle(InitMenuHand));
		if reserror <> noErr then
			sysbeep(10);
		if save then
			initMenuHand^^ := MenuHand^^
		else
			MenuHand^^ := initMenuHand^^;
		if save then
		begin
			ChangedResource(handle(initMenuHand));
			WriteResource(handle(initMenuHand));
		end;
		HPurge(handle(initMenuHand));
		CloseResFile(GFilesRes);
		useResFile(myResourceFile);
	end;

	procedure DoTransRec (Save: boolean);
		var
			tempFileName: str255;
			sharedRef, GFilesRes: integer;
			initTransHand: TransMenuHand;
	begin
		GFilesRes := OpenRFPerm(concat(SharedFiles, 'Menus'), 0, fsRdWrPerm);
		handle(initTransHand) := Get1Resource('MenU', 1);
		HNoPurge(handle(initTransHand));
		if reserror <> noErr then
			sysbeep(10);
		if save then
			initTransHand^^ := transHand^^
		else
			transHand^^ := initTransHand^^;
		if save then
		begin
			ChangedResource(handle(initTransHand));
			WriteResource(handle(initTransHand));
		end;
		HPurge(handle(initTranshand));
		CloseResFile(GFilesRes);
		useResFile(myResourceFile);
	end;

	procedure DoForumRec (Save: boolean);
		var
			tempFileName: str255;
			sharedRef, Dirs: integer;
			initTransHand: ForumIdxHand;
			freshFm: ForumIdxHand;
	begin
		Dirs := OpenRFPerm(concat(SharedFiles, 'Directories'), 0, fsRdWrPerm);
		if Dirs = -1 then
		begin
			result := Create(concat(sharedFiles, 'Directories'), 0, 'HRMS', 'DATA');
			CreateResFile(concat(sharedFiles, 'Directories'));
			Dirs := OpenRFPerm(concat(SharedFiles, 'Directories'), 0, fsRdWrPerm);
			freshFm := ForumIdxHand(NewHandleClear(SizeOf(ForumIdxRec)));
			AddResource(handle(FreshFm), 'Info', 0, 'Forum Information');
		end;
		handle(initTransHand) := Get1Resource('Info', 0);
		HNoPurge(handle(initTransHand));
		if reserror <> noErr then
			sysbeep(10);
		if save then
			initTransHand^^ := forumIdx^^
		else
			forumIdx^^ := initTransHand^^;
		if save then
		begin
			ChangedResource(handle(initTransHand));
			WriteResource(handle(initTransHand));
		end;
		HPurge(handle(initTranshand));
		CloseResFile(Dirs);
		useResFile(myResourceFile);
	end;

	procedure DoGFileRec (Save: boolean);
		var
			tempFileName: str255;
			sharedRef, GFilesRes: integer;
			initGFileHand: GFileSecHand;
	begin
		GFilesRes := OpenRFPerm(concat(SharedFiles, 'GFiles'), 0, fsRdWrPerm);
		if (GfilesRes <> -1) then
		begin
			handle(initGFileHand) := Get1Resource('Gfil', 0);
			HNoPurge(handle(InitGFileHand));
			if reserror <> noErr then
				sysbeep(10);
			if save then
				initGFileHand^^ := intGFileRec^^
			else
				intGFileRec^^ := initGFileHand^^;
			if save then
			begin
				ChangedResource(handle(initGFileHand));
				WriteResource(handle(initGFileHand));
			end;
			HPurge(handle(initGFileHand));
			CloseResFile(GFilesRes);
			useResFile(myResourceFile);
		end;
	end;

	procedure DoMailerRec (Save: boolean);
		var
			tempFileName: str255;
			sharedRef, Dirs: integer;
			initmailerhand: mailerhand;
			freshFm: mailerhand;
	begin
		Dirs := OpenRFPerm(concat(SharedFiles, 'Mailer Prefs'), 0, fsRdWrPerm);
		handle(initMailerHand) := Get1Resource('Info', 0);
		HNoPurge(handle(initMailerHand));
		if reserror <> noErr then
			sysbeep(10);
		if save then
			initMailerHand^^ := mailer^^
		else
			mailer^^ := initMailerHand^^;
		if save then
		begin
			ChangedResource(handle(initMailerHand));
			WriteResource(handle(initMailerHand));
		end;
		HPurge(handle(initMailerHand));
		ReleaseResource(handle(initMailerHand));
		CloseResFile(Dirs);
		useResFile(myResourceFile);
	end;

	procedure DoSecRec (Save: boolean);
		var
			tempFileName: str255;
			sharedRef, GFilesRes: integer;
			initTransHand: SecLevHand;
	begin
		GFilesRes := OpenRFPerm(concat(SharedFiles, 'Security Levels'), 0, fsRdWrPerm);
		handle(initTransHand) := Get1Resource('Lvls', 0);
		HNoPurge(handle(initTranshand));
		if reserror <> noErr then
			sysbeep(10);
		if save then
			initTransHand^^ := secLevels^^
		else
			secLevels^^ := initTransHand^^;
		if save then
		begin
			ChangedResource(handle(initTransHand));
			WriteResource(handle(initTransHand));
		end;
		HPurge(handle(initTranshand));
		CloseResFile(GFilesRes);
		useResFile(myResourceFile);
	end;

	procedure LoadNewUser (Save: boolean);
		var
			i, sref: integer;
			OldUser: NewUserHand;
			t1, t2: Str255;
	begin
		sref := OpenRFPerm(concat(SharedFiles, 'New User'), 0, fsRdWrPerm);
		if sref = -1 then
			CreateNewUser(concat(SharedFiles, 'New User'))
		else
		begin
			handle(OldUser) := Get1Resource('NEWu', 0);
			HNoPurge(handle(OldUser));
			if reserror <> noErr then
				SysBeep(10);
			if save then
				OldUser^^ := NewHand^^
			else
				NewHand^^ := OldUser^^;
			if save then
			begin
				ChangedResource(handle(OldUser));
				WriteResource(handle(OldUser));
			end;
			HPurge(handle(OldUser));
			closeResFile(sref);
		end;
		useResFile(myResourceFile);
	end;

	procedure DoFBRec (Save: boolean);
		var
			tempFileName: str255;
			sharedRef, MessageRes: integer;
			InitFeedBack: FeedBackHand;
	begin
		MessageRes := OpenRFPerm(concat(SharedFiles, 'Message'), 0, fsRdWrPerm);
		handle(InitFeedBack) := Get1Resource('MFor', 1);
		HNoPurge(handle(InitFeedBack));
		if reserror <> noErr then
			sysbeep(10);
		if save then
			InitFeedBack^^ := InitFBHand^^
		else
			InitFBHand^^ := InitFeedBack^^;
		if save then
		begin
			ChangedResource(handle(InitFeedBack));
			WriteResource(handle(InitFeedBack));
		end;
		HPurge(handle(InitFeedBack));
		CloseResFile(MessageRes);
		useResFile(myResourceFile);
	end;

	procedure DoMForumRec (Save: boolean);
		var
			MForumRes: Integer;
			tempMForum: MForumHand;
	begin
		MForumRes := OpenRFPerm(concat(SharedFiles, 'Message'), 0, fsRdWrPerm);
		handle(tempMForum) := Get1Resource('MFor', 0);

		HNoPurge(handle(tempMForum));
		if resError <> noErr then
			sysBeep(0);
		if Save then
			tempMForum^^ := MForum^^
		else
			MForum^^ := tempMForum^^;
		if Save then
		begin
			ChangedResource(handle(tempMForum));
			WriteResource(handle(tempMForum));
		end;
		HPurge(handle(tempMForum));
		CloseResFile(MForumRes);
		UseResFile(myResourceFile);
	end;

	procedure DoMConferenceRec (Save: Boolean; WhichOne: integer);
		var
			MConfRes: integer;
			tempMConf: FiftyConferencesHand;
	begin
		MConfRes := OpenRFPerm(concat(SharedFiles, 'Message'), 0, fsRdWrPerm);
		handle(tempMConf) := Get1Resource('Conf', WhichOne);

		HNoPurge(handle(tempMConf));
		if resError <> noErr then
			sysBeep(0);
		if Save then
			tempMConf^^ := MConference[WhichOne]^^
		else
			MConference[WhichOne]^^ := tempMConf^^;
		if Save then
		begin
			ChangedResource(handle(tempMConf));
			WriteResource(handle(tempMConf));
		end;
		HPurge(handle(tempMConf));
		CloseResFile(MConfRes);
		UseResFile(myResourceFile);
	end;

	procedure DoAddressBooks (var TheBook: AddressBookHand; TheUserNum: integer; Save: boolean);
		var
			ABFile: integer;
			SizeOfBook: longint;
			result: OSErr;
	begin
		result := FSOpen(concat(sharedPath, 'Shared Files:Address Books'), 0, ABFile);
		if result = noErr then
		begin
			SizeOfBook := SizeOf(AddressBookArray);
			result := SetFPos(ABFile, fsFromStart, SizeOfBook * (TheUserNum - 1));
			if Save then
				result := FSWrite(ABFile, SizeOfBook, pointer(TheBook^))
			else
				result := FSRead(ABFile, SizeOfBook, pointer(TheBook^));
		end;
		result := FSClose(ABFile);
	end;

	procedure SortActionWordList;
	external;

	procedure LoadActionWordList;
		var
			result: OSErr;
			TheFile, i: integer;
			SizeOfThis, NumAWords: longint;
			AW: ActionWordRec;
	begin
		if ActionWordHand <> nil then
		begin
			DisposHandle(handle(ActionWordHand));
			ActionWordHand := nil;
		end;
		ChatHand^^.NumActionWords := 0;
		result := FSOpen(concat(sharedPath, 'Shared Files:Action Words'), 0, TheFile);
		if result = noErr then
		begin
			SizeOfThis := SizeOf(ActionWordRec);
			result := GetEOF(TheFile, NumAWords);
			NumAWords := NumAWords div SizeOfThis;
			if NumAWords > 0 then
			begin
				ChatHand^^.NumActionWords := NumAWords;
				ActionWordHand := ActionWordHandle(NewHandleClear(SizeOf(ActionWordRec) * NumAWords));
				MoveHHi(handle(ActionWordHand));
				for i := 1 to NumAWords do
				begin
					result := FSRead(TheFile, SizeOfThis, @AW);
					ActionWordHand^^[i - 1].ActionWord := AW.ActionWord;
					ActionWordHand^^[i - 1].Offset := (i - 1) * SizeOfThis;
				end;
				SortActionWordList;
			end
			else
				SysBeep(0);
			result := FSClose(TheFile);
		end
		else
			SysBeep(0);
	end;

	procedure SaveRemoveActionWord (Save: boolean; AW: ActionWordRec; Offset: longint);
		var
			result: OSErr;
			TheFile, TheFile2, i: integer;
			SizeOfAW, FilePos: longint;
			Done: boolean;
	begin
		result := FSOpen(concat(sharedPath, 'Shared Files:Action Words'), 0, TheFile);
		if result = noErr then
		begin
			SizeOfAW := SizeOf(ActionWordRec);
			if (Save) and (OffSet <> -1) then
			begin
				result := SetFPos(TheFile, fsFromStart, Offset);
				result := FSWrite(TheFile, SizeOfAW, @AW);
				result := FSClose(TheFile);
			end
			else if (Save) and (Offset = -1) then	{If Offset = -1 then New Action Word}
			begin
				result := SetFPos(TheFile, fsFromLEOF, 0);
				result := FSWrite(TheFile, SizeOfAW, @AW);
				SetHandleSize(handle(ActionWordHand), GetHandleSize(handle(ActionWordHand)) + SizeOfAW);
				ChatHand^^.NumActionWords := ChatHand^^.NumActionWords + 1;
				ActionWordHand^^[ChatHand^^.NumActionWords - 1].ActionWord := AW.ActionWord;
				result := GetFPos(TheFile, FilePos);
				FilePos := FilePos - SizeOfAW;
				ActionWordHand^^[ChatHand^^.NumActionWords - 1].Offset := FilePos;
				result := FSClose(TheFile);
			end
			else if not Save then
			begin
				if ChatHand^^.NumActionWords - 1 > 0 then
				begin
					result := Create(concat(sharedPath, 'Shared Files:Action Words Temp'), 0, 'HRMS', 'DATA');
					result := FSOpen(concat(sharedPath, 'Shared Files:Action Words Temp'), 0, TheFile2);
					FilePos := 0;
					for i := 1 to ChatHand^^.NumActionWords do
						if (SizeOfAW * (i - 1) <> Offset) then
						begin
							result := FSRead(TheFile, SizeOfAW, @AW);
							result := FSWrite(TheFile2, SizeOfAW, @AW);
						end
						else
							result := FSRead(TheFile, SizeOfAW, @AW);
					result := FSClose(TheFile);
					result := FSClose(TheFile2);
					result := FSDelete(concat(sharedPath, 'Shared Files:Action Words'), 0);
					result := Rename(concat(sharedPath, 'Shared Files:Action Words Temp'), 0, concat(sharedPath, 'Shared Files:Action Words'));
					LoadActionWordList;
				end
				else
				begin
					result := FSClose(TheFile);
					result := FSDelete(concat(sharedPath, 'Shared Files:Action Words'), 0);
				end;
			end;
		end;
	end;

end.