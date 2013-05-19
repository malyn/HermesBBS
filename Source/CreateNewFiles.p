{$Segments: CreateNewFiles_1}
unit CreateNewFiles;

interface

	uses
		AppleTalk, ADSP, Serial, Sound, CommResources, CRMSerialDevices, TCPTypes, Initial, NodePrefs2;

	procedure CreateSystemPrefs (Path, HFPath: str255);
	procedure CreateMessage (Path: str255);
	procedure CreateMailer (Path, HDPath: str255);
	procedure CreateNewUser (Path: str255);
	procedure CreateSecurityLevels (Path: str255);
	procedure CreateForumInformation (Path: str255);
	procedure CreateDirectories (Path, HFPath: str255);
	procedure CreateAddressBooks (Path: str255);
	procedure CreateActionWords (Path: str255);

implementation

{$S CreateNewFiles_1}
	procedure CreateSystemPrefs;
		var
			freshSyst: SystHand;
			templong: longint;
			i, TheFile: integer;
	begin
		freshSyst := SystHand(NewHandleClear(SizeOf(SystRec)));
		with freshSyst^^ do
		begin
			BBSName := 'Unnamed BBS';
			OverridePass := 'SYSOP';
			NewUserPass := 'NUP';
			NumCalls := 0;
			NumUsers := 0;
			OpStartHour := 0;
			OpEndHour := 0;
			Closed := false;
			NumNodes := 1;
			GetDateTime(templong);
			Secs2Date(templong, LastMaint);
			LastUL := 0;
			LastDL := 0;
			LastPost := 0;
			LastEmail := 0;
			AnonyUser := 0;
			AnonyAuto := false;
			SerialNumber := '';{char(0)}
			SerialNumber[0] := char(0);
			GfilePath := concat(HFPath, ':GFiles:');
			LastUser := 'UNKNOWN';
			MsgsPath := concat(HFPath, ':Messages:');
			DataPath := concat(HFPath, ':Data:');
			numMForums := 1;
			for i := 1 to MAX_NODES do
			begin
				callsToday[i] := 0;
				mPostedToday[i] := 0;
				eMailToday[i] := 0;
				uploadsToday[i] := 0;
				kuploaded[i] := 0;
				minsToday[i] := 0;
				dlsToday[i] := 0;
				kdownloaded[i] := 0;
				failedULs[i] := 0;
				failedDLs[i] := 0;
			end;
			MailDLCost := 1.0;
			UnUsed1 := 0;
			TwoWayChat := true;
			UseXWind := false;
			ninePoint := true;
			FreeMailDL := false;
			FreePhone := false;
			ClosedTransfers := false;
			protocolTime := 8;
			BlackOnWhite := 1;
			MailDeleteDays := 60;
			twoColorChat := true;
			UsePauses := false;
			DLCredits := 0;
			logDays := 10;
			logDetail := 0;
			realSerial := '';
			realSerial[0] := char(0);
			GetDateTime(startDate);
			screenSaver[0] := 1;
			screenSaver[1] := 5;
			NumNNodes := 0;
			for i := 0 to MAX_NODES_M_1 do
			begin
				Bbsnames[i] := char(0);
				Bbsnumbers[i] := char(0);
				BbsdialIt[i] := false;
				Bbsdialed[i] := false;
				WnodesStd[i + 1].top := 0;
				WnodesStd[i + 1].left := 0;
				WnodesStd[i + 1].right := 0;
				WnodesStd[i + 1].bottom := 0;
				WNodesUser[i + 1].top := 0;
				WNodesUser[i + 1].left := 0;
				WNodesUser[i + 1].right := 0;
				WNodesUser[i + 1].bottom := 0;
				wIsOpen[i + 1] := true;
			end;
			Bbsnames[0] := 'Olympus';
			Bbsnumbers[0] := '1-206-643-2874';
			wIsOpen[0] := false;
			WnodesStd[1].top := 40;
			WnodesStd[1].left := 2;
			WnodesStd[1].right := 502;
			WnodesStd[1].bottom := 330;
			WNodesUser[1].top := 40;
			WNodesUser[1].left := 2;
			WNodesUser[1].right := 502;
			WNodesUser[1].bottom := 330;
			Wstatus.top := 569;
			Wstatus.left := 5;
			Wstatus.right := 505;
			Wstatus.bottom := 619;
			for i := 1 to 26 do
				Restrictions[i] := char(0);
			Totals := false;
			EndString := '';{char(0)}
			EndString[0] := char(0);
			UseBold := false;
			version := SYSTREC_VERSION;
			Wusers.top := 41;
			Wusers.left := 365;
			Wusers.right := 502;
			Wusers.bottom := 339;
			WUserOpen := false;
			Quoter := true;
			MailAttachments := true;
			SSLock := false;
			NoANSIDetect := false;
			NoXFerPathChecking := false;
			QuoteHeader := 'On %date, %sender quoted %receiver: %title.';
			QuoteHeaderAnon := 'On %date, %receiver was quoted: %title.';
			UseQuoteHeader := true;
			QuoteHeaderOptions := UseNormal;
{ Added in 3.5.9b1 }
			ResetSystemColors(freshSyst);
			DebugTelnet := false;
			DebugTelnetToFile := false;
{ Reserved bytes for expansion. }
			for i := 1 to 470 do
				reserved[i] := char(0);
		end;
		result := Create(Path, 0, 'HRMS', 'DATA');
		CreateResFile(Path);
		TheFile := OpenRFPerm(Path, 0, fsRdWrPerm);
		AddResource(handle(freshSyst), 'Sprf', 0, 'System Prefs');
		CloseResFile(TheFile);
	end;

	procedure CreateMessage;
		var
			i, x, TheFile: integer;
			result: OSErr;
			freshFb: feedbackHand;
			freshForum: MForumHand;
			freshConference: MConferencesArray;
	begin
		freshForum := MForumHand(NewHandleClear(SizeOf(MForumArray)));
		with freshForum^^[1] do
		begin
			Name := 'Forum #1';
			numConferences := 15;
			MinSL := 5;
			MinAge := 0;
			AccessLetter := char(0);
			Moderators[1] := 0;
			Moderators[2] := 0;
			Moderators[3] := 0;
			for i := 1 to 25 do
				reserved[i] := char(0);
		end;
		for i := 2 to 20 do
			with freshForum^^[i] do
			begin
				Name := StringOf('Forum #', i : 0);
				numConferences := 0;
				MinSL := 5;
				MinAge := 0;
				AccessLetter := char(0);
				Moderators[1] := 0;
				Moderators[2] := 0;
				Moderators[3] := 0;
				for x := 1 to 25 do
					reserved[x] := char(0);
			end;
		for i := 1 to 20 do
		begin
			freshConference[i] := FiftyConferencesHand(NewHandleClear(SizeOf(FiftyConferences)));
		end;
		for i := 1 to freshForum^^[1].numConferences do
			with freshConference[1]^^[i] do
			begin
				Name := StringOf('Conference #', i : 0);
				SLtoRead := 5;
				SLtoPost := 30;
				MaxMessages := 50;
				AnonID := 0;
				MinAge := 0;
				AccessLetter := char(0);
				Threading := true;
				ConfType := 0;
				RealNames := false;
				ShowCity := false;
				FileAttachments := true;
				DLCost := 0.0;
				EchoName := char(0);
				Moderators[1] := 0;
				Moderators[2] := 0;
				Moderators[3] := 0;
				for x := 1 to 27 do
					reserved[x] := char(0);
			end;
		result := Create(Path, 0, 'HRMS', 'DATA');
		CreateResFile(Path);
		TheFile := OpenRFPerm(Path, 0, fsRdWrPerm);
		AddResource(handle(freshForum), 'MFor', 0, 'MForum Information');
		for i := 1 to 20 do
			AddResource(handle(freshConference[i]), 'Conf', i, '');
		freshFB := FeedBackhand(NewHandleClear(SizeOf(FeedBackRec)));
		AddResource(handle(freshFB), 'MFor', 1, 'Feedback');
		CloseResFile(TheFile);
	end;

	procedure CreateMailer;
		var
			freshMailer: MailerHand;
			result: OSErr;
			TheFile: integer;
	begin
		freshMailer := MailerHand(NewHandleClear(SizeOf(MailerRec)));
		with freshMailer^^ do
		begin
			Application := HDPath;
			GenericPath := HDPath;
			MailerAware := false;
			SubLaunchMailer := 2;
			EventPath := concat(HDPath, 'System Folder:Preferences:');
			MailerNode := 1;
			AllowCrashMail := false;
			ImportSpeed := 4;
			UseRealNames := false;
			CrashMailPath := HDPath;
			UseEMSI := false;
		end;
		result := Create(Path, 0, 'HRMS', 'DATA');
		CreateResFile(Path);
		TheFile := OpenRFPerm(Path, 0, fsRdWrPerm);
		AddResource(handle(freshMailer), 'Info', 0, 'Mailer Information');
		CloseResFile(TheFile);
	end;

	procedure CreateNewUser;
		var
			freshNewUser: NewUserHand;
			result: OSErr;
			TheFile: integer;
	begin
		freshNewUser := NewUserHand(NewHandleClear(SizeOf(NewUserRec)));
		with freshNewUser^^ do
		begin
			Handle := false;
			Gender := true;
			RealName := true;
			BirthDay := true;
			City := true;
			Country := false;
			DataPN := false;
			Company := false;
			Street := true;
			Computer := true;
			Sysop[1] := false;
			Sysop[2] := false;
			Sysop[3] := false;
			SysopText[1] := char(0);
			SysopText[2] := char(0);
			SysopText[3] := char(0);
			NoVFeedback := false;
			QScanBack := 30;
			NoAutoCapital := false;
		end;
		result := Create(Path, 0, 'HRMS', 'DATA');
		CreateResFile(Path);
		TheFile := OpenRFPerm(Path, 0, fsRdWrPerm);
		AddResource(handle(freshNewUser), 'NEWu', 0, 'New User Options');
		CloseResFile(TheFile);
	end;

	procedure CreateSecurityLevels;
		var
			freshSecLevels: SecLevHand;
			result: OSErr;
			TheFile, i: integer;
	begin
		freshSecLevels := SecLevHand(NewHandleClear(SizeOf(NewSecurity)));
		with freshSecLevels^^[5] do
		begin
			Active := true;
			Class := 'Limited';
			TransLevel := 5;
			PostMessage := true;
			UDRatio := true;
			PCRatio := true;
			AnonMsg := true;
			AutoMsg := true;
			Listuser := true;
			BBSList := true;
			Uploader := true;
			ReadAnon := true;
			PPFile := true;
			DLRatioOneTo := 10;
			PostRatioOneTo := 4;
			MessComp := 1.0;
			XferComp := 1.0;
			MesgDay := 4;
			LnsMessage := 40;
			CallsPrDay := 2;
			TimeAllowed := 10;
		end;
		with freshSecLevels^^[10] do
		begin
			Active := true;
			Class := 'New User';
			TransLevel := 10;
			PostMessage := true;
			UDRatio := true;
			AnonMsg := true;
			AutoMsg := true;
			Listuser := true;
			BBSList := true;
			Uploader := true;
			ReadAnon := true;
			PPFile := true;
			DLRatioOneTo := 99;
			PostRatioOneTo := 4;
			MessComp := 1.0;
			XferComp := 1.0;
			MesgDay := 4;
			LnsMessage := 40;
			CallsPrDay := 3;
			TimeAllowed := 10;
		end;
		with freshSecLevels^^[30] do
		begin
			Active := true;
			Class := 'Validated';
			TransLevel := 30;
			UDRatio := true;
			PCRatio := true;
			AnonMsg := true;
			AutoMsg := true;
			ReadAnon := true;
			DLRatioOneTo := 5;
			PostRatioOneTo := 4;
			MessComp := 1.0;
			XferComp := 1.0;
			MesgDay := 10;
			LnsMessage := 100;
			CallsPrDay := 8;
			TimeAllowed := 40;
		end;
		with freshSecLevels^^[60] do
		begin
			Active := true;
			Class := 'Hi Access';
			TransLevel := 60;
			AnonMsg := true;
			AutoMsg := true;
			ReadAnon := true;
			DLRatioOneTo := 0;
			PostRatioOneTo := 4;
			MessComp := 1.0;
			XferComp := 1.0;
			MesgDay := 20;
			LnsMessage := 100;
			CallsPrDay := 12;
			TimeAllowed := 60;
		end;
		with freshSecLevels^^[200] do
		begin
			Active := true;
			Class := 'CoSysOp';
			TransLevel := 200;
			DLRatioOneTo := 0;
			PostRatioOneTo := 0;
			MessComp := 1.0;
			XferComp := 1.0;
			MesgDay := 99;
			LnsMessage := 200;
			CallsPrDay := 99;
			TimeAllowed := 180;
		end;
		with freshSecLevels^^[255] do
		begin
			Active := true;
			Class := 'SysOp';
			TransLevel := 255;
			DLRatioOneTo := 0;
			PostRatioOneTo := 0;
			MessComp := 1.0;
			XferComp := 1.0;
			MesgDay := 99;
			LnsMessage := 200;
			CallsPrDay := 99;
			TimeAllowed := 180;
			for i := 1 to 26 do
				Restrics[i] := true;
		end;
		result := Create(Path, 0, 'HRMS', 'DATA');
		CreateResFile(Path);
		TheFile := OpenRFPerm(Path, 0, fsRdWrPerm);
		AddResource(handle(freshSecLevels), 'Lvls', 0, 'Security Levels');
		CloseResFile(TheFile);
	end;

	procedure CreateForumInformation;
		var
			freshForum: ForumIdxHand;
			result: OSErr;
			TheFile: integer;
	begin
		freshForum := ForumIdxHand(NewHandleClear(SizeOf(ForumIdxRec)));
		with freshForum^^ do
		begin
			NumForums := 2;
			Name[0] := 'Sysop';
			Name[1] := 'Area #1';
			MinDsl[0] := 200;
			MinDsl[1] := 0;
			numDirs[0] := 3;
			numDirs[1] := 15;
		end;
		result := Create(Path, 0, 'HRMS', 'DATA');
		CreateResFile(Path);
		TheFile := OpenRFPerm(Path, 0, fsRdWrPerm);
		AddResource(handle(freshForum), 'Info', 0, 'Forum Information');
		CloseResFile(TheFile);
	end;

	procedure CreateDirectories;
		var
			freshDir: ReadDirHandle;
			result: OSErr;
			TheFile, i: integer;
			s: str255;
	begin
		TheFile := OpenRFPerm(Path, 0, fsRdWrPerm);
		if resError <> noErr then
		begin
			result := Create(Path, 0, 'HRMS', 'DATA');
			CreateResFile(Path);
			TheFile := OpenRFPerm(Path, 0, fsRdWrPerm);
		end;

		freshDir := ReadDirHandle(NewHandleClear(SizeOf(DirDataFile)));
		with freshDir^^.Dr[1] do
		begin
			DirName := 'Sysop Uploads';
			Path := concat(HFPath, ':Files:Sysop:01:');
			MinDSL := 200;
			DSLtoUL := 10;
			DSLtoDL := 200;
			MaxFiles := 200;
			Restriction := char(0);
			NonMacFiles := 0;
			mode := 0;
			MinAge := 0;
			FileNameLength := 20;
			freeDir := false;
			AllowUploads := false;
			Handles := false;
			ShowUploader := false;
			Color := 0;
			TapeVolume := false;
			SlowVolume := false;
			Operators[1] := 0;
			Operators[2] := 0;
			Operators[3] := 0;
			DLCost := 1.0;
			ULCost := 1.0;
			DLCreditor := 0.0;
			HowLong := 0;
			UploadOnly := false;
		end;
		with freshDir^^.Dr[2] do
		begin
			DirName := 'Mail Attachments';
			Path := concat(HFPath, ':Files:Sysop:02:');
			MinDSL := 200;
			DSLtoUL := 10;
			DSLtoDL := 200;
			MaxFiles := 1000;
			Restriction := char(0);
			NonMacFiles := 0;
			mode := 0;
			MinAge := 0;
			FileNameLength := 31;
			freeDir := false;
			AllowUploads := false;
			Handles := false;
			ShowUploader := false;
			Color := 0;
			TapeVolume := false;
			SlowVolume := false;
			Operators[1] := 0;
			Operators[2] := 0;
			Operators[3] := 0;
			DLCost := 1.0;
			ULCost := 0.0;
			DLCreditor := 0.0;
			HowLong := 0;
			UploadOnly := false;
		end;
		with freshDir^^.Dr[3] do
		begin
			DirName := 'Message Attachments';
			Path := concat(HFPath, ':Files:Sysop:03:');
			MinDSL := 200;
			DSLtoUL := 10;
			DSLtoDL := 200;
			MaxFiles := 1000;
			Restriction := char(0);
			NonMacFiles := 0;
			mode := 0;
			MinAge := 0;
			FileNameLength := 31;
			freeDir := false;
			AllowUploads := false;
			Handles := false;
			ShowUploader := false;
			Color := 0;
			TapeVolume := false;
			SlowVolume := false;
			Operators[1] := 0;
			Operators[2] := 0;
			Operators[3] := 0;
			DLCost := 1.0;
			ULCost := 0.0;
			DLCreditor := 0.0;
			HowLong := 0;
			UploadOnly := false;
		end;
		AddResource(handle(freshDir), 'Dirs', UniqueID('Dirs'), 'Sysop');
		ReleaseResource(handle(freshDir));

		freshDir := ReadDirHandle(NewHandleClear(SizeOf(DirDataFile)));
		for i := 1 to 15 do
			with freshDir^^.Dr[i] do
			begin
				DirName := StringOf('Directory', i : 0);
				if i < 10 then
					s := StringOf('0', i : 0)
				else
					s := StringOf(i : 0);
				Path := concat(HFPath, ':Files:Area #1:', s, ':');
				MinDSL := 10;
				DSLtoUL := 10;
				DSLtoDL := 30;
				MaxFiles := 500;
				Restriction := char(0);
				NonMacFiles := 0;
				mode := 0;
				MinAge := 0;
				FileNameLength := 20;
				freeDir := false;
				AllowUploads := false;
				Handles := false;
				ShowUploader := false;
				Color := 0;
				TapeVolume := false;
				SlowVolume := false;
				Operators[1] := 0;
				Operators[2] := 0;
				Operators[3] := 0;
				DLCost := 1.0;
				ULCost := 1.0;
				DLCreditor := 0.0;
				HowLong := 0;
				UploadOnly := false;
			end;
		AddResource(handle(freshDir), 'Dirs', UniqueID('Dirs'), 'Area #1');
		CloseResFile(TheFile);
	end;

	procedure CreateAddressBooks;
		var
			ABFile, UFile, i: integer;
			result: OSErr;
			BlankBook: AddressBookHand;
			UFileSize, SizeOfBook: longint;
	begin
		BlankBook := AddressBookHand(NewHandle(sizeOf(AddressBookArray)));
		for i := 1 to 40 do
			BlankBook^^[i] := char(0);

		result := FSOpen(concat(sharedPath, 'Shared Files:Users'), 0, UFile);
		if result = noErr then
		begin
			result := GetEOF(UFile, UFileSize);
			if UFileSize >= SizeOf(UserRec) then
			begin
				UFileSize := UFileSize div SizeOf(UserRec);
				result := Create(Path, 0, 'HRMS', 'DATA');
				result := FSOpen(Path, 0, ABFile);
				SizeOfBook := SizeOf(AddressBookArray);
				for i := 1 to UFileSize do
					result := FSWrite(ABFile, SizeOfBook, pointer(BlankBook^));
				result := FSClose(ABFile);
			end
			else
				result := Create(Path, 0, 'HRMS', 'DATA');
		end
		else
			result := Create(Path, 0, 'HRMS', 'DATA');
		result := FSClose(UFile);
		if BlankBook <> nil then
		begin
			DisposHandle(handle(BlankBook));
			BlankBook := nil;
		end;
	end;

	procedure CreateActionWords;
		var
			TheFile: integer;
			result: OSErr;
			SizeOfThis: longint;
			AW: ActionWordRec;	{Action Word}
	begin
		result := Create(Path, 0, 'HRMS', 'DATA');
		result := FSOpen(Path, 0, TheFile);
		SizeOfThis := SizeOf(ActionWordRec);
		AW.ActionWord := 'BORING';
		AW.TargetUser := '[U] says, "You are boring me to tears."';
		AW.OtherUser := '[T] has bored [U] to tears.';
		AW.Initiating := 'You tell [T], "You''re boring me to tears.';
		AW.Unspecified := '[U] is bored to tears.';
		result := FSWrite(TheFile, SizeOfThis, @AW);
		AW.ActionWord := 'BYE';
		AW.TargetUser := '[U] tells you goodbye as [U:he/she] heads out the door.';
		AW.OtherUser := '[U] tells [T] bye as [U:he/she] heads out the door.';
		AW.Initiating := 'You say "Goodbye [T]."';
		AW.Unspecified := '[U] says "Goodbye everyone."';
		result := FSWrite(TheFile, SizeOfThis, @AW);
		AW.ActionWord := 'CALL';
		AW.TargetUser := '[U] says, "Can I call you later?"';
		AW.OtherUser := '[U] says, "[T] can I call you later?"';
		AW.Initiating := 'You ask [T] if you can call them later.';
		AW.Unspecified := '[U] says "Can I call all of you?"';
		result := FSWrite(TheFile, SizeOfThis, @AW);
		AW.ActionWord := 'CUSS';
		AW.TargetUser := '[U] cusses you out in disgust.';
		AW.OtherUser := '[U] is cussing at [T] in disgust.';
		AW.Initiating := 'You start swearing at [T] in disgust.';
		AW.Unspecified := '[U] says, "@#%!#@$!@%@."';
		result := FSWrite(TheFile, SizeOfThis, @AW);
		AW.ActionWord := 'DANCE';
		AW.TargetUser := '[U] is spinning you around the dance floor.';
		AW.OtherUser := '[U] is spinning [T] around the dance floor.';
		AW.Initiating := 'You take [T] for a spin around the dance floor.';
		AW.Unspecified := '[U] would like to dance with someone.';
		result := FSWrite(TheFile, SizeOfThis, @AW);
		AW.ActionWord := 'DATE';
		AW.TargetUser := '[U] asks you, "Would you like to go out sometime soon?"';
		AW.OtherUser := '[U] asks [T] if [T:he/she] would like to go out.';
		AW.Initiating := 'You ask [T] to accompany you on a date.';
		AW.Unspecified := '[U] wants to know if anyone wants to go on a date.';
		result := FSWrite(TheFile, SizeOfThis, @AW);
		AW.ActionWord := 'DRINK';
		AW.TargetUser := '[U] hands you a drink.';
		AW.OtherUser := '[U] hands [T] a drink.';
		AW.Initiating := 'You hand [T] a refreshing beverage.';
		AW.Unspecified := '[U] says, "Drinks for everyone."';
		result := FSWrite(TheFile, SizeOfThis, @AW);
		AW.ActionWord := 'EMAIL';
		AW.TargetUser := '[U] says, "Send me the details in E-mail."';
		AW.OtherUser := '[U] tells [T] to send [U:him/her] the details in E-mail.';
		AW.Initiating := 'You tell [T] to send the details in E-mial.';
		AW.Unspecified := '[U] says, "I''ll send everyone the details in E-mail."';
		result := FSWrite(TheFile, SizeOfThis, @AW);
		AW.ActionWord := 'EYES';
		AW.TargetUser := '[U] says "Your eyes light up this room."';
		AW.OtherUser := '[U] thinks [T]''s eyes light up the room.	';
		AW.Initiating := 'You tell [T] that [T:his/her] eyes light up the room.';
		AW.Unspecified := '[U] looks into everyone''s eyes.';
		result := FSWrite(TheFile, SizeOfThis, @AW);
		AW.ActionWord := 'FUNNY';
		AW.TargetUser := '[U] thinks you are a funny [T:guy/lady]!';
		AW.OtherUser := '[U] thinks [T] is funny!';
		AW.Initiating := 'You think they are funny!!!!';
		AW.Unspecified := '[U] thinks you all are funny!!!';
		result := FSWrite(TheFile, SizeOfThis, @AW);
		AW.ActionWord := 'GRIN';
		AW.TargetUser := '[U] is grinning slyly at you.';
		AW.OtherUser := '[U] is grinning slyly at [T].';
		AW.Initiating := 'You grin slyly at [T].';
		AW.Unspecified := '[U] is grinning from ear to ear.';
		result := FSWrite(TheFile, SizeOfThis, @AW);
		AW.ActionWord := 'HIGH5';
		AW.TargetUser := '[U] says, "ALL RIGHT [T:MAN/GIRL]!!!!"';
		AW.OtherUser := '[U] yells at [T], "All RIGHT!!!"';
		AW.Initiating := 'You yell at [T], "ALL RIGHT [T:MAN/GIRL]!!!!"';
		AW.Unspecified := '[U] runs around the room and high fives'' everyone.';
		result := FSWrite(TheFile, SizeOfThis, @AW);
		AW.ActionWord := 'HUG';
		AW.TargetUser := '[U] is hugging you.';
		AW.OtherUser := '[U] is hugging [T].';
		AW.Initiating := 'You are hugging [T].';
		AW.Unspecified := '[U] needs a group hug.';
		result := FSWrite(TheFile, SizeOfThis, @AW);
		AW.ActionWord := 'KICK';
		AW.TargetUser := '[U] kicks you on your butt.';
		AW.OtherUser := '[U] kicks [T] on [T:his/her] butt.';
		AW.Initiating := 'You are kicking [T] on [T:his/her] butt.';
		AW.Unspecified := '[U] says, "I''m going to kick all of you."';
		result := FSWrite(TheFile, SizeOfThis, @AW);
		AW.ActionWord := 'KISS';
		AW.TargetUser := '[U] kisses you lightly on your cheek.';
		AW.OtherUser := '[U] kisses [T] lightly on [T:his/her] cheek.';
		AW.Initiating := 'You kiss [T] lightly on [T:his/her] cheek.';
		AW.Unspecified := '[U] blows kisses to everyone.';
		result := FSWrite(TheFile, SizeOfThis, @AW);
		AW.ActionWord := 'LAUGH';
		AW.TargetUser := '[U] is laughing at you.';
		AW.OtherUser := '[U] laughs at [T].';
		AW.Initiating := 'You laugh at [T].';
		AW.Unspecified := '[U] laughs out loud.';
		result := FSWrite(TheFile, SizeOfThis, @AW);
		AW.ActionWord := 'LISTEN';
		AW.TargetUser := '[U] is listening intensely to your every word.';
		AW.OtherUser := '[U] listens intently to what [T] has to say.';
		AW.Initiating := 'You listen intently to what [T] has to say.';
		AW.Unspecified := '[U] is listening to what everyone has to say.';
		result := FSWrite(TheFile, SizeOfThis, @AW);
		AW.ActionWord := 'LOVE';
		AW.TargetUser := '[U] says, "I love you [T]."';
		AW.OtherUser := '[U] says [U:he/she] loves [T].';
		AW.Initiating := 'You tell [T], "I love you."';
		AW.Unspecified := '[U] exclaims, "I''m in love."';
		result := FSWrite(TheFile, SizeOfThis, @AW);
		AW.ActionWord := 'PRETTY';
		AW.TargetUser := '[U] says, "I think you are very pretty."';
		AW.OtherUser := '[U] tells [T], "You are very pretty."';
		AW.Initiating := 'You say to [T], "You are very pretty."';
		AW.Unspecified := '[U] asks, "Am I pretty?"';
		result := FSWrite(TheFile, SizeOfThis, @AW);
		AW.ActionWord := 'PUNCH';
		AW.TargetUser := '[U] punches you on the nose.';
		AW.OtherUser := '[U] punches [T] on the nose.';
		AW.Initiating := 'You punch [T] on the nose.';
		AW.Unspecified := '[U] punches everyone.';
		result := FSWrite(TheFile, SizeOfThis, @AW);
		AW.ActionWord := 'SAD';
		AW.TargetUser := '[U] frowns and says, "You are making me sad."';
		AW.OtherUser := '[T] has made [U] very sad.';
		AW.Initiating := 'You tell [T] that [T:he/she] is making you sad.';
		AW.Unspecified := '[U] is very sad.';
		result := FSWrite(TheFile, SizeOfThis, @AW);
		AW.ActionWord := 'SMILE';
		AW.TargetUser := '[U] is smiling at you.';
		AW.OtherUser := '[U] is smiling at [T].';
		AW.Initiating := 'You smile at [T].';
		AW.Unspecified := '[U] is smiling at everyone.';
		result := FSWrite(TheFile, SizeOfThis, @AW);
		AW.ActionWord := 'SORRY';
		AW.TargetUser := '"I''m really sorry", [U] says.';
		AW.OtherUser := '[U] tells [T] that [U:he/she] is sorry.';
		AW.Initiating := 'You tell [T] you are sorry.';
		AW.Unspecified := '[U] says, "I''m sorry all."';
		result := FSWrite(TheFile, SizeOfThis, @AW);
		AW.ActionWord := 'TICKLE';
		AW.TargetUser := '[U] is tickling your side.';
		AW.OtherUser := '[U] is tickling [T]''s side.';
		AW.Initiating := 'You tickle [T]''s sides.';
		AW.Unspecified := '[U] wants to tickle someone.';
		result := FSWrite(TheFile, SizeOfThis, @AW);
		AW.ActionWord := 'TIME';
		AW.TargetUser := '[U] asks you, "What time is it?"';
		AW.OtherUser := '[U] asks [T] "What time is it."';
		AW.Initiating := 'You ask [T] for the time.';
		AW.Unspecified := '[U] exclaims, "Time....take five."';
		result := FSWrite(TheFile, SizeOfThis, @AW);
		AW.ActionWord := 'WAIT';
		AW.TargetUser := '[U] wants you to wait just a second.';
		AW.OtherUser := '[U] wants [T] to wait just a second.';
		AW.Initiating := 'You ask [T] to wait just a second.';
		AW.Unspecified := '[U] is asking everybody to wait just a second.';
		result := FSWrite(TheFile, SizeOfThis, @AW);
		AW.ActionWord := 'WAVE';
		AW.TargetUser := '[U] is waving at you.';
		AW.OtherUser := '[U] is waving at [T].';
		AW.Initiating := 'You wave at [T].';
		AW.Unspecified := '[U] is waving to everybody.';
		result := FSWrite(TheFile, SizeOfThis, @AW);
		AW.ActionWord := 'WELCOME';
		AW.TargetUser := '[U] welcomes you to the chat room.';
		AW.OtherUser := '[U] welcomes [T] to the chat room.';
		AW.Initiating := 'You welcome [T] to the chat room.';
		AW.Unspecified := '[U] says, "Welcome all!!"';
		result := FSWrite(TheFile, SizeOfThis, @AW);
		AW.ActionWord := 'WINK';
		AW.TargetUser := '[U] is winking at you from across the room.';
		AW.OtherUser := '[U] winks at [T] from across the room.';
		AW.Initiating := 'You wink at [T] from across the room.';
		AW.Unspecified := '[U] winks at everyone.';
		result := FSWrite(TheFile, SizeOfThis, @AW);
		AW.ActionWord := 'YELL';
		AW.TargetUser := '[U] yells at you to get your attention.';
		AW.OtherUser := '[U] yells at [T] to get [T:his/her] attention.';
		AW.Initiating := 'You yell at [T] to get [T:his/her] attention.';
		AW.Unspecified := '[U] is yelling at the top of [U:his/her] lungs.';
		result := FSWrite(TheFile, SizeOfThis, @AW);
		result := FSClose(TheFile);
	end;

end.