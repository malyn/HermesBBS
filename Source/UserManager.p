{ Segments: UserManager_1, UserManager_2 }
unit UserManager;

interface
	uses
		AppleTalk, ADSP, Serial, Sound, initial, LoadAndSave, NodePrefs2, Message_Editor, User;

	procedure Open_GlobalUEdit;
	procedure Update_GlobalUEdit (theWindow: WindowPtr);
	procedure Do_GlobalUEdit (theEvent: EventRecord; itemHit: integer);
	procedure Close_GlobalUEdit;

implementation

{$S UserManager_1 }
	procedure ResetGlobalSearchOnOff;
		var
			i: integer;
	begin
		if GUSearchV <> nil then
		begin
			with GUSearchV^^ do
			begin
				SecurityLevel.OnOff := false;
				SecurityLevel.Operator := 1;
				SecurityLevel.Value := -1;
				DownloadSL.OnOff := false;
				DownloadSL.Operator := 1;
				DownloadSL.Value := -1;
				AccessLetters.OnOff := false;
				AccessLetters.Operator := 1;
				for i := 1 to 26 do
				begin
					AccessLetters.Value[i] := '[';
					Restrictions.Value[i] := '[';
				end;
				Restrictions.OnOff := false;
				Restrictions.Operator := 1;
				TimeAllowed.OnOff := false;
				TimeAllowed.Operator := 1;
				TimeAllowed.Value := -1;
				FirstCall.OnOff := false;
				FirstCall.Operator := 1;
				FirstCall.Value := -1;
				LastCall.OnOff := false;
				LastCall.Operator := 1;
				LastCall.Value := -1;
				MessagesPosted.OnOff := false;
				MessagesPosted.Operator := 1;
				MessagesPosted.Value := -1;
				EMailSent.OnOff := false;
				EMailSent.Operator := 1;
				EMailSent.Value := -1;
				TotalCalls.OnOff := false;
				TotalCalls.Operator := 1;
				TotalCalls.Value := -1;
				NumUploads.OnOff := false;
				NumUploads.Operator := 1;
				NumUploads.Value := -1;
				UploadK.OnOff := false;
				UploadK.Operator := 1;
				UploadK.Value := -1;
				NumDownloads.OnOff := false;
				NumDownloads.Operator := 1;
				NumDownloads.Value := -1;
				DownloadK.OnOff := false;
				DownloadK.Operator := 1;
				DownloadK.Value := -1;
				KCredit.OnOff := false;
				KCredit.Operator := 1;
				KCredit.Value := -1;
				City.OnOff := false;
				City.Operator := 1;
				City.Value := char(0);
				State.OnOff := false;
				State.Operator := 1;
				State.Value := char(0);
				Zip.OnOff := false;
				Zip.Operator := 1;
				Zip.Value := char(0);
				Country.OnOff := false;
				Country.Operator := 1;
				Country.Value := char(0);
				Company.OnOff := false;
				Company.Operator := 1;
				Company.Value := char(0);
				Age.OnOff := false;
				Age.Operator := 1;
				Age.Value := -1;
				MaleFemale.OnOff := false;
				MaleFemale.Operator := 1;
				MaleFemale.Value := 0;
				Computer.OnOff := false;
				Computer.Operator := 1;
				Computer.Value := char(0);
				Misc1.OnOff := false;
				Misc1.Operator := 1;
				Misc1.Value := char(0);
				Misc2.OnOff := false;
				Misc2.Operator := 1;
				Misc2.Value := char(0);
				Misc3.OnOff := false;
				Misc3.Operator := 1;
				Misc3.Value := char(0);
				NormAltText.OnOff := false;
				NormAltText.Operator := 1;
				NormAltText.Value := -1;
				Password.OnOff := false;
				Password.Operator := 1;
				Password.Value := char(0);
				VoicePhone.OnOff := false;
				VoicePhone.Operator := 1;
				VoicePhone.Value := char(0);
				DataPhone.OnOff := false;
				DataPhone.Operator := 1;
				DataPhone.Value := char(0);
				Sysop.OnOff := false;
				Sysop.Operator := 1;
				Sysop.Value := -1;
				Alert.OnOff := false;
				Alert.Operator := 1;
				Alert.Value := -1;
				Delete.OnOff := false;
				Delete.Operator := 1;
				Delete.Value := -1;
				DLRatioOneTo.OnOff := false;
				DLRatioOneTo.Operator := 1;
				DLRatioOneTo.Value := -1;
				PostRatioOneTo.OnOff := false;
				PostRatioOneTo.Operator := 1;
				PostRatioOneTo.Value := -1;
				XferComp.OnOff := false;
				XferComp.Operator := 1;
				XferComp.Value := -1.0;
				MessComp.OnOff := false;
				MessComp.Operator := 1;
				MessComp.Value := -1.0;
				MesgDay.OnOff := false;
				MesgDay.Operator := 1;
				MesgDay.Value := -1;
				LnsMessage.OnOff := false;
				LnsMessage.Operator := 1;
				LnsMessage.Value := -1;
				CallsPrDay.OnOff := false;
				CallsPrDay.Operator := 1;
				CallsPrDay.Value := -1;
				UseDayOrCall.OnOff := false;
				UseDayOrCall.Operator := 1;
				UseDayOrCall.Value := -1;
				Alias.OnOff := false;
				Alias.Operator := 1;
				Alias.Value := char(0);
				RealName.OnOff := false;
				RealName.Operator := 1;
				RealName.Value := char(0);
			end;
		end;
	end;

	function BuildSearchText (index: integer): str255;
		var
			s, s1, TheValue: str255;
			OnOff: boolean;
			TheOperator, i, DType: integer;
			DItem: handle;
			tempRect: rect;
			CItem: ControlHandle;
			myPop: PopUpHand;
			s23: string[24];
			s8: string[8];
			s15: string[15];
	begin
		with GUSearchV^^ do
		begin
			OnOff := false;
			TheValue := char(0);
			GetIndString(s, 400, index);
			s23 := concat(s, '                                           ');
			case index of
				1: 
				begin
					OnOff := SecurityLevel.OnOff;
					TheOperator := SecurityLevel.Operator;
					NumToString(SecurityLevel.Value, TheValue);
					if (GetCheckBox(GlobalUSearch, 4)) then
					begin
						if (SecLevels^^[SecurityLevel.Value].active) then
							s15 := concat(TheValue, '-', SecLevels^^[SecurityLevel.Value].Class)
						else
							s15 := concat(TheValue, '-Unclassified');
						TheValue := s15;
					end;
				end;
				2: 
				begin
					OnOff := DownloadSL.OnOff;
					TheOperator := DownloadSL.Operator;
					NumToString(DownloadSL.Value, TheValue);
				end;
				3: 
				begin
					OnOff := AccessLetters.OnOff;
					TheOperator := AccessLetters.Operator;
					for i := 1 to 26 do
						if AccessLetters.Value[i] <> '[' then
							TheValue := concat(TheValue, AccessLetters.Value[i]);
				end;
				4: 
				begin
					OnOff := Restrictions.OnOff;
					TheOperator := Restrictions.Operator;
					for i := 1 to 15 do
						if Restrictions.Value[i] = 'A' then
						begin
							numtostring(i, s1);
							TheValue := concat(TheValue, s1, ',');
						end;
					i := length(TheValue);
					TheValue[i] := char(0);
				end;
				5: 
				begin
					OnOff := TimeAllowed.OnOff;
					TheOperator := TimeAllowed.Operator;
					NumToString(TimeAllowed.Value, TheValue);
				end;
				6: 
				begin
					OnOff := FirstCall.OnOff;
					TheOperator := FirstCall.Operator;
					NumToString(FirstCall.Value, TheValue);
				end;
				7: 
				begin
					OnOff := LastCall.OnOff;
					TheOperator := LastCall.Operator;
					NumToString(LastCall.Value, TheValue);
				end;
				8: 
				begin
					OnOff := MessagesPosted.OnOff;
					TheOperator := MessagesPosted.Operator;
					NumToString(MessagesPosted.Value, TheValue);
				end;
				9: 
				begin
					OnOff := EMailSent.OnOff;
					TheOperator := EMailSent.Operator;
					NumToString(EMailSent.Value, TheValue);
				end;
				10: 
				begin
					OnOff := TotalCalls.OnOff;
					TheOperator := TotalCalls.Operator;
					NumToString(TotalCalls.Value, TheValue);
				end;
				11: 
				begin
					OnOff := NumUploads.OnOff;
					TheOperator := NumUploads.Operator;
					NumToString(NumUploads.Value, TheValue);
				end;
				12: 
				begin
					OnOff := UploadK.OnOff;
					TheOperator := UploadK.Operator;
					NumToString(UploadK.Value, TheValue);
				end;
				13: 
				begin
					OnOff := NumDownloads.OnOff;
					TheOperator := NumDownloads.Operator;
					NumToString(NumDownloads.Value, TheValue);
				end;
				14: 
				begin
					OnOff := DownloadK.OnOff;
					TheOperator := DownloadK.Operator;
					NumToString(DownloadK.Value, TheValue);
				end;
				15: 
				begin
					OnOff := KCredit.OnOff;
					TheOperator := KCredit.Operator;
					NumToString(KCredit.Value, TheValue);
				end;
				16: 
				begin
					OnOff := City.OnOff;
					TheOperator := City.Operator;
					TheValue := City.Value;
				end;
				17: 
				begin
					OnOff := State.OnOff;
					TheOperator := State.Operator;
					TheValue := State.Value;
				end;
				18: 
				begin
					OnOff := Zip.OnOff;
					TheOperator := Zip.Operator;
					TheValue := Zip.Value;
				end;
				19: 
				begin
					OnOff := Country.OnOff;
					TheOperator := Country.Operator;
					TheValue := Country.Value;
				end;
				20: 
				begin
					OnOff := Company.OnOff;
					TheOperator := Company.Operator;
					TheValue := Company.Value;
				end;
				21: 
				begin
					OnOff := Age.OnOff;
					TheOperator := Age.Operator;
					NumToString(Age.Value, TheValue);
				end;
				22: 
				begin
					OnOff := MaleFemale.OnOff;
					TheOperator := MaleFemale.Operator;
					if MaleFemale.Value = 0 then
						TheValue := 'Male'
					else
						TheValue := 'Female';
				end;
				23: 
				begin
					OnOff := Computer.OnOff;
					TheOperator := Computer.Operator;
					TheValue := Computer.Value;
				end;
				24: 
				begin
					OnOff := Misc1.OnOff;
					TheOperator := Misc1.Operator;
					TheValue := Misc1.Value;
				end;
				25: 
				begin
					OnOff := Misc2.OnOff;
					TheOperator := Misc2.Operator;
					TheValue := Misc2.Value;
				end;
				26: 
				begin
					OnOff := Misc3.OnOff;
					TheOperator := Misc3.Operator;
					TheValue := Misc3.Value;
				end;
				27: 
				begin
					OnOff := NormAltText.OnOff;
					TheOperator := NormAltText.Operator;
					if NormAltText.Value = 0 then
						TheValue := 'Normal'
					else
						TheValue := 'Alternate';
				end;
				28: 
				begin
					OnOff := Password.OnOff;
					TheOperator := Password.Operator;
					TheValue := Password.Value;
				end;
				29: 
				begin
					OnOff := VoicePhone.OnOff;
					TheOperator := VoicePhone.Operator;
					TheValue := VoicePhone.Value;
				end;
				30: 
				begin
					OnOff := DataPhone.OnOff;
					TheOperator := DataPhone.Operator;
					TheValue := DataPhone.Value;
				end;
				31: 
				begin
					OnOff := Sysop.OnOff;
					TheOperator := Sysop.Operator;
					if Sysop.Value = 0 then
						TheValue := 'Sysop On'
					else
						TheValue := 'Sysop Off';
				end;
				32: 
				begin
					OnOff := Alert.OnOff;
					TheOperator := Alert.Operator;
					if Alert.Value = 0 then
						TheValue := 'Alert On'
					else
						TheValue := 'Alert Off';
				end;
				33: 
				begin
					OnOff := Delete.OnOff;
					TheOperator := Delete.Operator;
					if Delete.Value = 0 then
						TheValue := 'Delete On'
					else
						TheValue := 'Delete Off';
				end;
				34: 
				begin
					OnOff := DLRatioOneTo.OnOff;
					TheOperator := DLRatioOneTo.Operator;
					NumToString(DLRatioOneTo.Value, TheValue);
				end;
				35: 
				begin
					OnOff := PostRatioOneTo.OnOff;
					TheOperator := PostRatioOneTo.Operator;
					NumToString(PostRatioOneTo.Value, TheValue);
				end;
				36: 
				begin
					OnOff := XferComp.OnOff;
					TheOperator := XferComp.Operator;
					TheValue := StringOf(XFerComp.Value : 1 : 1);
				end;
				37: 
				begin
					OnOff := MessComp.OnOff;
					TheOperator := MessComp.Operator;
					TheValue := StringOf(MessComp.Value : 1 : 1);
				end;
				38: 
				begin
					OnOff := MesgDay.OnOff;
					TheOperator := MesgDay.Operator;
					NumToString(MesgDay.Value, TheValue);
				end;
				39: 
				begin
					OnOff := LnsMessage.OnOff;
					TheOperator := LnsMessage.Operator;
					NumToString(LnsMessage.Value, TheValue);
				end;
				40: 
				begin
					OnOff := CallsPrDay.OnOff;
					TheOperator := CallsPrDay.Operator;
					NumToString(CallsPrDay.Value, TheValue);
				end;
				41: 
				begin
					OnOff := UseDayOrCall.OnOff;
					TheOperator := UseDayOrCall.Operator;
					if UseDayOrCall.Value = 0 then
						TheValue := 'Per Day'
					else
						TheValue := 'Per Call';
				end;
				42: 
				begin
					OnOff := Alias.OnOff;
					TheOperator := Alias.Operator;
					TheValue := Alias.Value;
				end;
				43: 
				begin
					OnOff := RealName.OnOff;
					TheOperator := RealName.Operator;
					TheValue := RealName.Value;
				end;
				otherwise
					;
			end;
		end;
		if OnOff then
		begin
			s := concat('On    ', s23);
			GetDItem(GlobalUSearch, 13, DType, DItem, tempRect);
			CItem := ControlHandle(DItem);
			myPop := popupHand(CItem^^.contrlData);
			GetItem(myPop^^.mHandle, TheOperator, s1);
			s8 := concat(s1, '        ');
			s := concat(s, ' ', s8);
			s := concat(s, '  ', TheValue);
		end
		else
			s := concat('      ', s23);
		BuildSearchText := s;
	end;

	procedure RemoveButtons;
	begin
		case GUSearchItem of
			4: 
			begin
				HideDItem(GlobalUSearch, 18);
				HideDItem(GlobalUSearch, 19);
				ShowDItem(GlobalUSearch, 14);
			end;
			22, 27, 41: 
			begin
				HideDItem(GlobalUSearch, 23);
				HideDItem(GlobalUSearch, 24);
				ShowDItem(GlobalUSearch, 14);
			end;
			31, 32, 33: 
			begin
				HideDItem(GlobalUSearch, 25);
				ShowDItem(GlobalUSearch, 14);
			end;
		end;
	end;

	procedure SetMyText (Which: boolean; TheText: str255; TheNum: longint);
		var
			dType: integer;
			dItem: handle;
			temprect: rect;
			s1: str255;
	begin
		if Which then
		begin
			NumToString(TheNum, s1);
			if (TheNum = -1) then
				s1 := char(0);
		end
		else
			s1 := TheText;
		GetDItem(GlobalUSearch, 14, dType, dItem, tempRect);
		SetIText(dItem, s1);
	end;

	procedure SetButtons (whichItem: integer);
		var
			dType, NumMItems, i, OperatorItem: integer;
			dItem: handle;
			temprect: rect;
			s1, s2: str255;
			myPop, myPop2: popupHand;
			CItem, CItem2: ControlHandle;
			HiliteIt: boolean;
	begin
		GetIndString(s1, 400, whichItem);
		s1 := concat('          ', s1);
		GetDItem(GlobalUSearch, 12, dType, dItem, tempRect);
		SetCTitle(ControlHandle(dItem), s1);

		GetDItem(GlobalUSearch, 13, DType, DItem, tempRect);
		CItem := ControlHandle(DItem);
		myPop := popupHand(CItem^^.contrlData);
		NumMItems := CountMItems(myPop^^.mHandle);
		for i := NumMItems downto 1 do
			DelMenuItem(myPop^^.mHandle, i);
		HiliteIt := true;
		CheckUEditAlpha := false;
		RemoveButtons;
		GUSearchItem := whichItem;
		if GetCheckBox(GlobalUSearch, 3) then  {Search}
		begin
			case whichitem of
				1, 2, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 21, 34, 35, 36, 37, 38, 39, 40: 
				begin
					AppendMenu(myPop^^.mHandle, '=');
					AppendMenu(myPop^^.mHandle, '≠');
					AppendMenu(myPop^^.mHandle, 'ANYTHING');
					SetItem(myPop^^.mHandle, 3, '<');  {Have to do this because < is a Metacharacter}
					AppendMenu(myPop^^.mHandle, '>');
					CheckUEditN := true;
				end;
				3, 4, 22, 27, 31, 32, 33, 41: 
				begin
					AppendMenu(myPop^^.mHandle, '=');
					AppendMenu(myPop^^.mHandle, '≠');
					CheckUEditN := false;
				end;
				16, 17, 18, 19, 20, 23, 24, 25, 26, 28, 29, 30, 42, 43: 
				begin
					AppendMenu(myPop^^.mHandle, 'Exact');
					AppendMenu(myPop^^.mHandle, 'Partial');
					CheckUEditN := false;
				end;
			end;
		end
		else {Replace}
		begin
			case whichitem of
				1, 2, 5..43: 
					AppendMenu(myPop^^.mHandle, 'Set To');
				3, 4: 
				begin
					AppendMenu(myPop^^.mHandle, 'Turn On');
					AppendMenu(myPop^^.mHandle, 'Turn Off');
				end;
			end;
			case whichitem of
				1, 2, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 21, 34, 35, 38, 39, 40: 
					CheckUEditN := true;
				3, 4, 22, 27, 31, 32, 33, 41, 16, 17, 18, 19, 20, 23, 24, 25, 26, 28, 29, 30, 42, 43, 36, 37: 
					CheckUEditN := false;
			end;
		end;
		case whichitem of
			1: 
			begin
				SetCheckBox(GlobalUSearch, 12, GUSearchV^^.SecurityLevel.OnOff);
				OperatorItem := GUSearchV^^.SecurityLevel.Operator;
				SetMyText(True, char(0), GUSearchV^^.SecurityLevel.Value);
				CheckUEditLength := 3;
			end;
			2: 
			begin
				SetCheckBox(GlobalUSearch, 12, GUSearchV^^.DownloadSL.OnOff);
				OperatorItem := GUSearchV^^.DownloadSL.Operator;
				SetMyText(True, char(0), GUSearchV^^.DownloadSL.Value);
				CheckUEditLength := 3;
			end;
			3: 
			begin
				SetCheckBox(GlobalUSearch, 12, GUSearchV^^.AccessLetters.OnOff);
				OperatorItem := GUSearchV^^.AccessLetters.Operator;
				s2 := char(0);
				for i := 1 to 26 do
					if GUSearchV^^.AccessLetters.Value[i] <> '[' then
						s2 := concat(s2, GUSearchV^^.AccessLetters.Value[i]);
				SetMyText(False, s2, -1);
				CheckUEditAlpha := true;
				CheckUEditLength := 26;
			end;
			4: 
			begin
				SetCheckBox(GlobalUSearch, 12, GUSearchV^^.Restrictions.OnOff);
				OperatorItem := GUSearchV^^.Restrictions.Operator;
				HideDItem(GlobalUSearch, 14);
				ShowDItem(GlobalUSearch, 19);
				GetDItem(GlobalUSearch, 19, DType, DItem, tempRect);
				CItem2 := ControlHandle(DItem);
				SetCtlValue(CItem2, 1);
				ShowDItem(GlobalUSearch, 18);
				GetDItem(GlobalUSearch, 18, DType, DItem, tempRect);
				myPop2 := popupHand(CItem2^^.contrlData);
				for i := 1 to 15 do
				begin
					GetItem(myPop2^^.mHandle, i, s1);
					if GUSearchV^^.Restrictions.Value[i] = 'A' then
						s1[1] := '√'
					else
						s1[1] := ' ';
					SetItem(myPop2^^.mHandle, i, s1);
				end;
				GetItem(myPop2^^.mHandle, 1, s1);
				SetCTitle(ControlHandle(dItem), s1);
				if GUSearchV^^.Restrictions.Value[1] = 'A' then
					SetCheckBox(GlobalUSearch, 18, true)
				else
					SetCheckBox(GlobalUSearch, 18, false);
				HiliteIt := false;
			end;
			5: 
			begin
				SetCheckBox(GlobalUSearch, 12, GUSearchV^^.TimeAllowed.OnOff);
				OperatorItem := GUSearchV^^.TimeAllowed.Operator;
				SetMyText(True, char(0), GUSearchV^^.TimeAllowed.Value);
				CheckUEditLength := 3;
			end;
			6: 
			begin
				SetCheckBox(GlobalUSearch, 12, GUSearchV^^.FirstCall.OnOff);
				OperatorItem := GUSearchV^^.FirstCall.Operator;
				SetMyText(True, char(0), GUSearchV^^.FirstCall.Value);
				CheckUEditLength := 3;
			end;
			7: 
			begin
				SetCheckBox(GlobalUSearch, 12, GUSearchV^^.LastCall.OnOff);
				OperatorItem := GUSearchV^^.LastCall.Operator;
				SetMyText(True, char(0), GUSearchV^^.LastCall.Value);
				CheckUEditLength := 3;
			end;
			8: 
			begin
				SetCheckBox(GlobalUSearch, 12, GUSearchV^^.MessagesPosted.OnOff);
				OperatorItem := GUSearchV^^.MessagesPosted.Operator;
				SetMyText(True, char(0), GUSearchV^^.MessagesPosted.Value);
				CheckUEditLength := 5;
			end;
			9: 
			begin
				SetCheckBox(GlobalUSearch, 12, GUSearchV^^.EMailSent.OnOff);
				OperatorItem := GUSearchV^^.EMailSent.Operator;
				SetMyText(True, char(0), GUSearchV^^.EMailSent.Value);
				CheckUEditLength := 5;
			end;
			10: 
			begin
				SetCheckBox(GlobalUSearch, 12, GUSearchV^^.TotalCalls.OnOff);
				OperatorItem := GUSearchV^^.TotalCalls.Operator;
				SetMyText(True, char(0), GUSearchV^^.TotalCalls.Value);
				CheckUEditLength := 5;
			end;
			11: 
			begin
				SetCheckBox(GlobalUSearch, 12, GUSearchV^^.NumUploads.OnOff);
				OperatorItem := GUSearchV^^.NumUploads.Operator;
				SetMyText(True, char(0), GUSearchV^^.NumUploads.Value);
				CheckUEditLength := 4;
			end;
			12: 
			begin
				SetCheckBox(GlobalUSearch, 12, GUSearchV^^.UploadK.OnOff);
				OperatorItem := GUSearchV^^.UploadK.Operator;
				SetMyText(True, char(0), GUSearchV^^.UploadK.Value);
				CheckUEditLength := 5;
			end;
			13: 
			begin
				SetCheckBox(GlobalUSearch, 12, GUSearchV^^.NumDownloads.OnOff);
				OperatorItem := GUSearchV^^.NumDownloads.Operator;
				SetMyText(True, char(0), GUSearchV^^.NumDownloads.Value);
				CheckUEditLength := 4;
			end;
			14: 
			begin
				SetCheckBox(GlobalUSearch, 12, GUSearchV^^.DownloadK.OnOff);
				OperatorItem := GUSearchV^^.DownloadK.Operator;
				SetMyText(True, char(0), GUSearchV^^.DownloadK.Value);
				CheckUEditLength := 5;
			end;
			15: 
			begin
				SetCheckBox(GlobalUSearch, 12, GUSearchV^^.KCredit.OnOff);
				OperatorItem := GUSearchV^^.KCredit.Operator;
				SetMyText(True, char(0), GUSearchV^^.KCredit.Value);
				CheckUEditLength := 5;
			end;
			16: 
			begin
				SetCheckBox(GlobalUSearch, 12, GUSearchV^^.City.OnOff);
				OperatorItem := GUSearchV^^.City.Operator;
				SetMyText(False, GUSearchV^^.City.Value, 0);
				CheckUEditLength := 30;
			end;
			17: 
			begin
				SetCheckBox(GlobalUSearch, 12, GUSearchV^^.State.OnOff);
				OperatorItem := GUSearchV^^.State.Operator;
				SetMyText(False, GUSearchV^^.State.Value, 0);
				CheckUEditLength := 2;
			end;
			18: 
			begin
				SetCheckBox(GlobalUSearch, 12, GUSearchV^^.Zip.OnOff);
				OperatorItem := GUSearchV^^.Zip.Operator;
				SetMyText(False, GUSearchV^^.Zip.Value, 0);
				CheckUEditLength := 10;
			end;
			19: 
			begin
				SetCheckBox(GlobalUSearch, 12, GUSearchV^^.Country.OnOff);
				OperatorItem := GUSearchV^^.Country.Operator;
				SetMyText(False, GUSearchV^^.Country.Value, 0);
				CheckUEditLength := 10;
			end;
			20: 
			begin
				SetCheckBox(GlobalUSearch, 12, GUSearchV^^.Company.OnOff);
				OperatorItem := GUSearchV^^.Company.Operator;
				SetMyText(False, GUSearchV^^.Company.Value, 0);
				CheckUEditLength := 30;
			end;
			21: 
			begin
				SetCheckBox(GlobalUSearch, 12, GUSearchV^^.Age.OnOff);
				OperatorItem := GUSearchV^^.Age.Operator;
				SetMyText(True, char(0), GUSearchV^^.Age.Value);
				CheckUEditLength := 3;
			end;
			22: 
			begin
				SetCheckBox(GlobalUSearch, 12, GUSearchV^^.MaleFemale.OnOff);
				OperatorItem := GUSearchV^^.MaleFemale.Operator;
				HideDItem(GlobalUSearch, 14);
				GetDItem(GlobalUSearch, 23, dType, dItem, tempRect);
				SetCTitle(ControlHandle(dItem), 'Male');
				GetDItem(GlobalUSearch, 24, dType, dItem, tempRect);
				SetCTitle(ControlHandle(dItem), 'Female');
				ShowDItem(GlobalUSearch, 23);
				ShowDItem(GlobalUSearch, 24);
				if GUSearchV^^.MaleFemale.Value = 0 then
				begin
					SetCheckBox(GlobalUSearch, 23, true);
					SetCheckBox(GlobalUSearch, 24, false);
				end
				else
				begin
					SetCheckBox(GlobalUSearch, 23, false);
					SetCheckBox(GlobalUSearch, 24, true);
				end;
			end;
			23: 
			begin
				SetCheckBox(GlobalUSearch, 12, GUSearchV^^.Computer.OnOff);
				OperatorItem := GUSearchV^^.Computer.Operator;
				SetMyText(False, GUSearchV^^.Computer.Value, 0);
				CheckUEditLength := 23;
			end;
			24: 
			begin
				SetCheckBox(GlobalUSearch, 12, GUSearchV^^.Misc1.OnOff);
				OperatorItem := GUSearchV^^.Misc1.Operator;
				SetMyText(False, GUSearchV^^.Misc1.Value, 0);
				CheckUEditLength := 60;
			end;
			25: 
			begin
				SetCheckBox(GlobalUSearch, 12, GUSearchV^^.Misc2.OnOff);
				OperatorItem := GUSearchV^^.Misc2.Operator;
				SetMyText(False, GUSearchV^^.Misc2.Value, 0);
				CheckUEditLength := 60;
			end;
			26: 
			begin
				SetCheckBox(GlobalUSearch, 12, GUSearchV^^.Misc3.OnOff);
				OperatorItem := GUSearchV^^.Misc3.Operator;
				SetMyText(False, GUSearchV^^.Misc3.Value, 0);
				CheckUEditLength := 60;
			end;
			27: 
			begin
				SetCheckBox(GlobalUSearch, 12, GUSearchV^^.NormAltText.OnOff);
				OperatorItem := GUSearchV^^.NormAltText.Operator;
				HideDItem(GlobalUSearch, 14);
				GetDItem(GlobalUSearch, 23, dType, dItem, tempRect);
				SetCTitle(ControlHandle(dItem), 'Normal');
				GetDItem(GlobalUSearch, 24, dType, dItem, tempRect);
				SetCTitle(ControlHandle(dItem), 'Alternate');
				ShowDItem(GlobalUSearch, 23);
				ShowDItem(GlobalUSearch, 24);
				if GUSearchV^^.NormAltText.Value = 0 then
				begin
					SetCheckBox(GlobalUSearch, 23, true);
					SetCheckBox(GlobalUSearch, 24, false);
				end
				else
				begin
					SetCheckBox(GlobalUSearch, 23, false);
					SetCheckBox(GlobalUSearch, 24, true);
				end;
			end;
			28: 
			begin
				SetCheckBox(GlobalUSearch, 12, GUSearchV^^.Password.OnOff);
				OperatorItem := GUSearchV^^.Password.Operator;
				SetMyText(False, GUSearchV^^.Password.Value, 0);
				CheckUEditLength := 9;
			end;
			29: 
			begin
				SetCheckBox(GlobalUSearch, 12, GUSearchV^^.VoicePhone.OnOff);
				OperatorItem := GUSearchV^^.VoicePhone.Operator;
				SetMyText(False, GUSearchV^^.VoicePhone.Value, 0);
				CheckUEditLength := 12;
			end;
			30: 
			begin
				SetCheckBox(GlobalUSearch, 12, GUSearchV^^.DataPhone.OnOff);
				OperatorItem := GUSearchV^^.DataPhone.Operator;
				SetMyText(False, GUSearchV^^.DataPhone.Value, 0);
				CheckUEditLength := 12;
			end;
			31: 
			begin
				SetCheckBox(GlobalUSearch, 12, GUSearchV^^.Sysop.OnOff);
				OperatorItem := GUSearchV^^.Sysop.Operator;
				HideDItem(GlobalUSearch, 14);
				GetDItem(GlobalUSearch, 25, dType, dItem, tempRect);
				SetCTitle(ControlHandle(dItem), 'Sysop');
				ShowDItem(GlobalUSearch, 25);
				if GUSearchV^^.Sysop.Value = 0 then
					SetCheckBox(GlobalUSearch, 25, true)
				else
					SetCheckBox(GlobalUSearch, 25, false);
			end;
			32: 
			begin
				SetCheckBox(GlobalUSearch, 12, GUSearchV^^.Alert.OnOff);
				OperatorItem := GUSearchV^^.Alert.Operator;
				HideDItem(GlobalUSearch, 14);
				GetDItem(GlobalUSearch, 25, dType, dItem, tempRect);
				SetCTitle(ControlHandle(dItem), 'Alert');
				ShowDItem(GlobalUSearch, 25);
				if GUSearchV^^.Alert.Value = 0 then
					SetCheckBox(GlobalUSearch, 25, true)
				else
					SetCheckBox(GlobalUSearch, 25, false);
			end;
			33: 
			begin
				SetCheckBox(GlobalUSearch, 12, GUSearchV^^.Delete.OnOff);
				OperatorItem := GUSearchV^^.Delete.Operator;
				HideDItem(GlobalUSearch, 14);
				GetDItem(GlobalUSearch, 25, dType, dItem, tempRect);
				SetCTitle(ControlHandle(dItem), 'Delete');
				ShowDItem(GlobalUSearch, 25);
				if GUSearchV^^.Delete.Value = 0 then
					SetCheckBox(GlobalUSearch, 25, true)
				else
					SetCheckBox(GlobalUSearch, 25, false);
			end;
			34: 
			begin
				SetCheckBox(GlobalUSearch, 12, GUSearchV^^.DLRatioOneTo.OnOff);
				OperatorItem := GUSearchV^^.DLRatioOneTo.Operator;
				SetMyText(True, char(0), GUSearchV^^.DLRatioOneTo.Value);
				CheckUEditLength := 3;
			end;
			35: 
			begin
				SetCheckBox(GlobalUSearch, 12, GUSearchV^^.PostRatioOneTo.OnOff);
				OperatorItem := GUSearchV^^.PostRatioOneTo.Operator;
				SetMyText(True, char(0), GUSearchV^^.PostRatioOneTo.Value);
				CheckUEditLength := 3;
			end;
			36: 
			begin
				CheckUEditN := false;
				SetCheckBox(GlobalUSearch, 12, GUSearchV^^.XferComp.OnOff);
				OperatorItem := GUSearchV^^.XferComp.Operator;
				if GUSearchV^^.XferComp.Value <> -1.0 then
					s1 := stringof(GUSearchV^^.XferComp.Value : 1 : 1)
				else
					s1 := char(0);
				SetMyText(False, s1, 0);
				CheckUEditLength := 4;
			end;
			37: 
			begin
				CheckUEditN := false;
				SetCheckBox(GlobalUSearch, 12, GUSearchV^^.MessComp.OnOff);
				OperatorItem := GUSearchV^^.MessComp.Operator;
				if GUSearchV^^.MessComp.Value <> -1.0 then
					s1 := stringof(GUSearchV^^.MessComp.Value : 1 : 1)
				else
					s1 := char(0);
				SetMyText(False, s1, 0);
				CheckUEditLength := 4;
			end;
			38: 
			begin
				SetCheckBox(GlobalUSearch, 12, GUSearchV^^.MesgDay.OnOff);
				OperatorItem := GUSearchV^^.MesgDay.Operator;
				SetMyText(True, char(0), GUSearchV^^.MesgDay.Value);
				CheckUEditLength := 3;
			end;
			39: 
			begin
				SetCheckBox(GlobalUSearch, 12, GUSearchV^^.LnsMessage.OnOff);
				OperatorItem := GUSearchV^^.LnsMessage.Operator;
				SetMyText(True, char(0), GUSearchV^^.LnsMessage.Value);
				CheckUEditLength := 3;
			end;
			40: 
			begin
				SetCheckBox(GlobalUSearch, 12, GUSearchV^^.CallsPrDay.OnOff);
				OperatorItem := GUSearchV^^.CallsPrDay.Operator;
				SetMyText(True, char(0), GUSearchV^^.CallsPrDay.Value);
				CheckUEditLength := 3;
			end;
			41: 
			begin
				SetCheckBox(GlobalUSearch, 12, GUSearchV^^.UseDayOrCall.OnOff);
				OperatorItem := GUSearchV^^.UseDayOrCall.Operator;
				HideDItem(GlobalUSearch, 14);
				GetDItem(GlobalUSearch, 23, dType, dItem, tempRect);
				SetCTitle(ControlHandle(dItem), 'Per Day');
				GetDItem(GlobalUSearch, 24, dType, dItem, tempRect);
				SetCTitle(ControlHandle(dItem), 'Per Call');
				ShowDItem(GlobalUSearch, 23);
				ShowDItem(GlobalUSearch, 24);
				if GUSearchV^^.UseDayOrCall.Value = 0 then
				begin
					SetCheckBox(GlobalUSearch, 23, true);
					SetCheckBox(GlobalUSearch, 24, false);
				end
				else
				begin
					SetCheckBox(GlobalUSearch, 23, false);
					SetCheckBox(GlobalUSearch, 24, true);
				end;
			end;
			42: 
			begin
				SetCheckBox(GlobalUSearch, 12, GUSearchV^^.Alias.OnOff);
				OperatorItem := GUSearchV^^.Alias.Operator;
				SetMyText(False, GUSearchV^^.Alias.Value, 0);
				CheckUEditLength := 31;
			end;
			43: 
			begin
				SetCheckBox(GlobalUSearch, 12, GUSearchV^^.RealName.OnOff);
				OperatorItem := GUSearchV^^.RealName.Operator;
				SetMyText(False, GUSearchV^^.RealName.Value, 0);
				CheckUEditLength := 21;
			end;
		end;
		if HiliteIt then
			SelIText(GlobalUSearch, 14, 0, 32767);
		InsertMenu(myPop^^.mHandle, -1);
		DrawDialog(GlobalUSearch);
		SetCtlValue(CItem, OperatorItem);
	end;

	procedure Open_GlobalUEdit;
		var
			DType, i: integer;
			DItem: handle;
			tempRect, tr2: rect;
			cSize: cell;
			s1: str255;
			CItem: ControlHandle;
			myPop: popUphand;
	begin
		if (GlobalUSearch = nil) then
		begin
			if GUSearchV <> nil then
			begin
				HPurge(handle(GUSearchV));
				DisposHandle(handle(GUSearchV));
				GUSearchV := nil;
			end;
			GUSearchV := GlobalSearchHdl(NewHandleClear(SizeOf(GlobalSearchRec)));
			MoveHHi(handle(GUSearchV));
			HNoPurge(handle(GUSearchV));
			HLock(handle(GUSearchV));
			ResetGlobalSearchOnOff;
			GlobalUSearch := GetNewDialog(150, nil, Pointer(-1));
			SetPort(GlobalUSearch);
			SetGeneva(GlobalUSearch);
			DrawDialog(GlobalUSearch);
			HideDItem(GlobalUSearch, 18);
			HideDItem(GlobalUSearch, 19);
			HideDItem(GlobalUSearch, 21);
			HideDItem(GlobalUSearch, 22);
			HideDItem(GlobalUSearch, 23);
			HideDItem(GlobalUSearch, 24);
			HideDItem(GlobalUSearch, 25);
			SetCheckBox(GlobalUSearch, 3, true);
			GetDItem(GlobalUSearch, 4, DType, DItem, tempRect);
			HiliteControl(ControlHandle(DItem), 255);
			GetDItem(GlobalUSearch, 5, DType, DItem, tempRect);
			HiliteControl(ControlHandle(DItem), 255);
			GetDItem(GlobalUSearch, 7, DType, DItem, tempRect);
			HiliteControl(ControlHandle(DItem), 255);
			GetDItem(GlobalUSearch, 15, DType, DItem, tempRect);
			HiliteControl(ControlHandle(DItem), 255);
			GetDItem(GlobalUSearch, 17, DType, DItem, tempRect);
			HiliteControl(ControlHandle(DItem), 255);
			HideDItem(GlobalUSearch, 20); {Unused, was Forums}

			{User List}
			GetDItem(GlobalUSearch, 2, DType, DItem, tempRect);
			TempRect.right := tempRect.right - 15;
			InsetRect(tempRect, -1, -1);
			FrameRect(tempRect);
			InsetRect(tempRect, 1, 1);
			SetRect(tr2, 0, 0, 1, 0);
			cSize.h := tempRect.right - tempRect.left;
			cSize.v := 12;
			GUList := LNew(tempRect, tr2, cSize, 0, GlobalUSearch, false, false, false, true);
			GUList^^.selFlags := lOnlyOne;
			LDoDraw(true, GUList);

      {Search List}
			GetDItem(GlobalUSearch, 11, DType, DItem, tempRect);
			TempRect.right := tempRect.right - 15;
			InsetRect(tempRect, -1, -1);
			FrameRect(tempRect);
			InsetRect(tempRect, 1, 1);
			SetRect(tr2, 0, 0, 1, 0);
			cSize.h := tempRect.right - tempRect.left;
			cSize.v := 12;
			GSearchList := LNew(tempRect, tr2, cSize, 2070, GlobalUSearch, false, false, false, true);
			GSearchList^^.selFlags := lOnlyOne + lNoNilHilite;
			cSize.v := LAddRow(43, 9000, GSearchList);
			cSize.v := 0;
			cSize.h := 0;
			for i := 1 to 43 do
			begin
				cSize.h := 0;
				cSize.v := i - 1;
				s1 := BuildSearchText(i);
				LSetCell(Pointer(ord(@s1) + 1), length(s1), cSize, GSearchList);
			end;
			LDoDraw(true, GSearchList);
			cSize.v := 0;
			cSize.h := 0;
			LSetSelect(true, cSize, GSearchList);
			SetButtons(1);

			ShowWindow(GlobalUSearch);
		end
		else
			SelectWindow(GlobalUSearch);
		HUnlock(handle(GUSearchV));
	end;

	procedure Update_GlobalUEdit;
		var
			SavedPort: GrafPtr;
			tempRect: rect;
			DType: integer;
			DItem: handle;
	begin
		if (GlobalUSearch <> nil) and (theWindow = GlobalUSearch) then
		begin
			GetPort(SavedPort);

			SetPort(GlobalUSearch);
			GetDItem(GlobalUSearch, 22, DType, DItem, tempRect);
			SetIText(DItem, 'Status :');

			GetDItem(GlobalUSearch, 2, DType, DItem, tempRect);
			tempRect.Right := tempRect.Right - 15;
			InsetRect(tempRect, -1, -1);
			FrameRect(tempRect);
			if (GUList <> nil) then
				LUpdate(GlobalUSearch^.visRgn, GUList);

			GetDItem(GlobalUSearch, 11, DType, DItem, tempRect);
			tempRect.Right := tempRect.Right - 15;
			InsetRect(tempRect, -1, -1);
			FrameRect(tempRect);
			if (GSearchList <> nil) then
				LUpdate(GlobalUSearch^.visRgn, GSearchList);
			DrawDialog(GlobalUSearch);

			SetPort(SavedPort);
		end;
	end;

	procedure ChangeVarStatus;
		var
			DType: integer;
			DItem: handle;
			tempRect: rect;
			CItem: ControlHandle;
			myPop: PopUpHand;
			OnOff: boolean;
			TheOperator, i, n: integer;
			TheText: str255;
			TheNum: longint;
			TheReal: real;
			ThePoint, Good: boolean;
	begin
		OnOff := GetCheckBox(GlobalUSearch, 12);
		GetDItem(GlobalUSearch, 13, DType, DItem, tempRect);
		CItem := ControlHandle(DItem);
		TheOperator := GetCtlValue(CItem);
		case GUSearchItem of
			1, 2, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 21, 34, 35, 38, 39, 40: 
			begin
				TheText := GetTextBox(GlobalUSearch, 14);
				StringToNum(TheText, TheNum);
			end;
			3, 16, 17, 18, 19, 20, 23, 24, 25, 26, 28, 29, 30, 42, 43: 
				TheText := GetTextBox(GlobalUSearch, 14);
			36, 37: 
			begin
				ThePoint := false;
				Good := True;
				TheText := GetTextBox(GlobalUSearch, 14);
				for i := 1 to length(TheText) do
				begin
					if TheText[i] = '.' then
					begin
						if not ThePoint then
							ThePoint := true
						else
						begin
							Good := false;
							leave;
						end;
					end
					else if (TheText[i] > '9') or (TheText[i] < '0') then
					begin
						Good := false;
						leave;
					end;
				end;
				if not Good then
				begin
					OnOff := false;
					TheReal := -1.0;
				end
				else
					ReadString(TheText, TheReal);
			end;
		end;

		with GUSearchV^^ do
		begin
			case GUSearchItem of
				1: 
				begin
					SecurityLevel.OnOff := OnOff;
					SecurityLevel.Operator := TheOperator;
					SecurityLevel.Value := TheNum;
					if (GetCheckBox(GlobalUSearch, 4)) and (GetCheckBox(GlobalUSearch, 18)) then
						SecurityLevel.Value := SecurityLevel.Value * (-1);
				end;
				2: 
				begin
					DownloadSL.OnOff := OnOff;
					DownloadSL.Operator := TheOperator;
					DownloadSL.Value := TheNum;
				end;
				3: 
				begin
					AccessLetters.OnOff := OnOff;
					AccessLetters.Operator := TheOperator;
					for i := 1 to 26 do
						AccessLetters.Value[i] := '[';
					for i := 1 to length(TheText) do
					begin
						if (Ord(TheText[i]) > 96) then
							AccessLetters.Value[Ord(TheText[i]) - 96] := Chr(Ord(TheText[i]) - 32)
						else
							AccessLetters.Value[Ord(TheText[i]) - 64] := TheText[i];
					end;
				end;
				4: 
				begin
					Restrictions.OnOff := OnOff;
					Restrictions.Operator := TheOperator;
					GetDItem(GlobalUSearch, 19, DType, DItem, tempRect);
					CItem := ControlHandle(DItem);
					myPop := popupHand(CItem^^.contrlData);
					for i := 1 to 15 do
						Restrictions.Value[i] := '[';
					for i := 1 to 15 do
					begin
						GetItem(myPop^^.mHandle, i, TheText);
						if TheText[1] = '√' then
							Restrictions.Value[i] := 'A';
					end;
				end;
				5: 
				begin
					TimeAllowed.OnOff := OnOff;
					TimeAllowed.Operator := TheOperator;
					TimeAllowed.Value := TheNum;
				end;
				6: 
				begin
					FirstCall.OnOff := OnOff;
					FirstCall.Operator := TheOperator;
					FirstCall.Value := TheNum;
				end;
				7: 
				begin
					LastCall.OnOff := OnOff;
					LastCall.Operator := TheOperator;
					LastCall.Value := TheNum;
				end;
				8: 
				begin
					MessagesPosted.OnOff := OnOff;
					MessagesPosted.Operator := TheOperator;
					MessagesPosted.Value := TheNum;
				end;
				9: 
				begin
					EMailSent.OnOff := OnOff;
					EMailSent.Operator := TheOperator;
					EMailSent.Value := TheNum;
				end;
				10: 
				begin
					TotalCalls.OnOff := OnOff;
					TotalCalls.Operator := TheOperator;
					TotalCalls.Value := TheNum;
				end;
				11: 
				begin
					NumUploads.OnOff := OnOff;
					NumUploads.Operator := TheOperator;
					NumUploads.Value := TheNum;
				end;
				12: 
				begin
					UploadK.OnOff := OnOff;
					UploadK.Operator := TheOperator;
					UploadK.Value := TheNum;
				end;
				13: 
				begin
					NumDownloads.OnOff := OnOff;
					NumDownloads.Operator := TheOperator;
					NumDownloads.Value := TheNum;
				end;
				14: 
				begin
					DownloadK.OnOff := OnOff;
					DownloadK.Operator := TheOperator;
					DownloadK.Value := TheNum;
				end;
				15: 
				begin
					KCredit.OnOff := OnOff;
					KCredit.Operator := TheOperator;
					KCredit.Value := TheNum;
				end;
				16: 
				begin
					City.OnOff := OnOff;
					City.Operator := TheOperator;
					City.Value := TheText;
				end;
				17: 
				begin
					State.OnOff := OnOff;
					State.Operator := TheOperator;
					State.Value := TheText;
				end;
				18: 
				begin
					Zip.OnOff := OnOff;
					Zip.Operator := TheOperator;
					Zip.Value := TheText;
				end;
				19: 
				begin
					Country.OnOff := OnOff;
					Country.Operator := TheOperator;
					Country.Value := TheText;
				end;
				20: 
				begin
					Company.OnOff := OnOff;
					Company.Operator := TheOperator;
					Company.Value := TheText;
				end;
				21: 
				begin
					Age.OnOff := OnOff;
					Age.Operator := TheOperator;
					Age.Value := TheNum;
				end;
				22: 
				begin
					MaleFemale.OnOff := OnOff;
					MaleFemale.Operator := TheOperator;
					OnOff := GetCheckBox(GlobalUSearch, 23);
					if OnOff then
						MaleFemale.Value := 0
					else
						MaleFemale.Value := 1;
				end;
				23: 
				begin
					Computer.OnOff := OnOff;
					Computer.Operator := TheOperator;
					Computer.Value := TheText;
				end;
				24: 
				begin
					Misc1.OnOff := OnOff;
					Misc1.Operator := TheOperator;
					Misc1.Value := TheText;
				end;
				25: 
				begin
					Misc2.OnOff := OnOff;
					Misc2.Operator := TheOperator;
					Misc2.Value := TheText;
				end;
				26: 
				begin
					Misc3.OnOff := OnOff;
					Misc3.Operator := TheOperator;
					Misc3.Value := TheText;
				end;
				27: 
				begin
					NormAltText.OnOff := OnOff;
					NormAltText.Operator := TheOperator;
					OnOff := GetCheckBox(GlobalUSearch, 23);
					if OnOff then
						NormAltText.Value := 0
					else
						NormAltText.Value := 1;
				end;
				28: 
				begin
					Password.OnOff := OnOff;
					Password.Operator := TheOperator;
					Password.Value := TheText;
				end;
				29: 
				begin
					VoicePhone.OnOff := OnOff;
					VoicePhone.Operator := TheOperator;
					VoicePhone.Value := TheText;
				end;
				30: 
				begin
					DataPhone.OnOff := OnOff;
					DataPhone.Operator := TheOperator;
					DataPhone.Value := TheText;
				end;
				31: 
				begin
					Sysop.OnOff := OnOff;
					Sysop.Operator := TheOperator;
					OnOff := GetCheckBox(GlobalUSearch, 25);
					if OnOff then
						Sysop.Value := 0
					else
						Sysop.Value := 1;
				end;
				32: 
				begin
					Alert.OnOff := OnOff;
					Alert.Operator := TheOperator;
					OnOff := GetCheckBox(GlobalUSearch, 25);
					if OnOff then
						Alert.Value := 0
					else
						Alert.Value := 1;
				end;
				33: 
				begin
					Delete.OnOff := OnOff;
					Delete.Operator := TheOperator;
					OnOff := GetCheckBox(GlobalUSearch, 25);
					if OnOff then
						Delete.Value := 0
					else
						Delete.Value := 1;
				end;
				34: 
				begin
					DLRatioOneTo.OnOff := OnOff;
					DLRatioOneTo.Operator := TheOperator;
					DLRatioOneTo.Value := TheNum;
				end;
				35: 
				begin
					PostRatioOneTo.OnOff := OnOff;
					PostRatioOneTo.Operator := TheOperator;
					PostRatioOneTo.Value := TheNum;
				end;
				36: 
				begin
					XferComp.OnOff := OnOff;
					XferComp.Operator := TheOperator;
					XferComp.Value := TheReal;
				end;
				37: 
				begin
					MessComp.OnOff := OnOff;
					MessComp.Operator := TheOperator;
					MessComp.Value := TheReal;
				end;
				38: 
				begin
					MesgDay.OnOff := OnOff;
					MesgDay.Operator := TheOperator;
					MesgDay.Value := TheNum;
				end;
				39: 
				begin
					LnsMessage.OnOff := OnOff;
					LnsMessage.Operator := TheOperator;
					LnsMessage.Value := TheNum;
				end;
				40: 
				begin
					CallsPrDay.OnOff := OnOff;
					CallsPrDay.Operator := TheOperator;
					CallsPrDay.Value := TheNum;
				end;
				41: 
				begin
					UseDayOrCall.OnOff := OnOff;
					UseDayOrCall.Operator := TheOperator;
					OnOff := GetCheckBox(GlobalUSearch, 23);
					if OnOff then
						UseDayOrCall.Value := 0
					else
						UseDayOrCall.Value := 1;
				end;
				42: 
				begin
					Alias.OnOff := OnOff;
					Alias.Operator := TheOperator;
					Alias.Value := TheText;
				end;
				43: 
				begin
					RealName.OnOff := OnOff;
					RealName.Operator := TheOperator;
					RealName.Value := TheText;
				end;
				otherwise
					;
			end;
		end;
	end;

	function SearchNum (UValue, SValue: longint; Operator: integer): boolean;
	begin
		case Operator of
			1: 
				if UValue = SValue then
					SearchNum := true
				else
					SearchNum := false;
			2: 
				if UValue <> SValue then
					SearchNum := true
				else
					SearchNum := false;
			3: 
				if UValue < SValue then
					SearchNum := true
				else
					SearchNum := false;
			4: 
				if UValue > SValue then
					SearchNum := true
				else
					SearchNum := false;
			otherwise
				SearchNum := false;
		end;
	end;

	function SearchReal (UValue, SValue: real; Operator: integer): boolean;
	begin
		case Operator of
			1: 
				if UValue = SValue then
					SearchReal := true
				else
					SearchReal := false;
			2: 
				if UValue <> SValue then
					SearchReal := true
				else
					SearchReal := false;
			3: 
				if UValue < SValue then
					SearchReal := true
				else
					SearchReal := false;
			4: 
				if UValue > SValue then
					SearchReal := true
				else
					SearchReal := false;
			otherwise
				SearchReal := false;
		end;
	end;

	function SearchAL (MyTempUser: UserRec): boolean;
		var
			i, TheLetter: integer;
			Good: boolean;
			s, t: str255;
	begin
		Good := True;
		for i := 1 to 26 do
			if GUSearchV^^.AccessLetters.Value[i] <> '[' then
				case GUSearchV^^.AccessLetters.Operator of
					1: {Has it}
						if (not MyTempUser.AccessLetter[i]) then
							Good := False;
					2: {Does Not Have It}
						if (MyTempUser.AccessLetter[i]) then
							Good := False;
				end;
		SearchAL := Good;
	end;

	function SearchRest (tUser: UserRec): boolean;
		var
			i: integer;
			b: boolean;
	begin
		b := true;
		for i := 1 to 15 do
		begin
			if GUSearchV^^.Restrictions.Value[i] = 'A' then
				case i of
					1: 
						if (tUser.CantPost) and (GUSearchV^^.Restrictions.Operator = 1) then
							b := true
						else if (not tUser.CantPost) and (GUSearchV^^.Restrictions.Operator = 2) then
							b := true
						else
							b := false;
					2: 
						if (tUser.CantChat) and (GUSearchV^^.Restrictions.Operator = 1) then
							b := true
						else if (not tUser.CantChat) and (GUSearchV^^.Restrictions.Operator = 2) then
							b := true
						else
							b := false;
					3: 
						if (tUser.UDRatioOn) and (GUSearchV^^.Restrictions.Operator = 1) then
							b := true
						else if (not tUser.UDRatioOn) and (GUSearchV^^.Restrictions.Operator = 2) then
							b := true
						else
							b := false;
					4: 
						if (tUser.PCRatioOn) and (GUSearchV^^.Restrictions.Operator = 1) then
							b := true
						else if (not tUser.PCRatioOn) and (GUSearchV^^.Restrictions.Operator = 2) then
							b := true
						else
							b := false;
					5: 
						if (tUser.CantPostAnon) and (GUSearchV^^.Restrictions.Operator = 1) then
							b := true
						else if (not tUser.CantPostAnon) and (GUSearchV^^.Restrictions.Operator = 2) then
							b := true
						else
							b := false;
					6: 
						if (tUser.CantSendEmail) and (GUSearchV^^.Restrictions.Operator = 1) then
							b := true
						else if (not tUser.CantSendEmail) and (GUSearchV^^.Restrictions.Operator = 2) then
							b := true
						else
							b := false;
					7: 
						if (tUser.CantChangeAutoMsg) and (GUSearchV^^.Restrictions.Operator = 1) then
							b := true
						else if (not tUser.CantChangeAutoMsg) and (GUSearchV^^.Restrictions.Operator = 2) then
							b := true
						else
							b := false;
					8: 
						if (tUser.CantListUser) and (GUSearchV^^.Restrictions.Operator = 1) then
							b := true
						else if (not tUser.CantListUser) and (GUSearchV^^.Restrictions.Operator = 2) then
							b := true
						else
							b := false;
					9: 
						if (tUser.CantAddToBBSList) and (GUSearchV^^.Restrictions.Operator = 1) then
							b := true
						else if (not tUser.CantAddToBBSList) and (GUSearchV^^.Restrictions.Operator = 2) then
							b := true
						else
							b := false;
					10: 
						if (tUser.CantSeeULInfo) and (GUSearchV^^.Restrictions.Operator = 1) then
							b := true
						else if (not tUser.CantSeeULInfo) and (GUSearchV^^.Restrictions.Operator = 2) then
							b := true
						else
							b := false;
					11: 
						if (tUser.CantReadAnon) and (GUSearchV^^.Restrictions.Operator = 1) then
							b := true
						else if (not tUser.CantReadAnon) and (GUSearchV^^.Restrictions.Operator = 2) then
							b := true
						else
							b := false;
					12: 
						if (tUser.RestrictHours) and (GUSearchV^^.Restrictions.Operator = 1) then
							b := true
						else if (not tUser.RestrictHours) and (GUSearchV^^.Restrictions.Operator = 2) then
							b := true
						else
							b := false;
					13: 
						if (tUser.CantSendPPFile) and (GUSearchV^^.Restrictions.Operator = 1) then
							b := true
						else if (not tUser.CantSendPPFile) and (GUSearchV^^.Restrictions.Operator = 2) then
							b := true
						else
							b := false;
					14: 
						if (tUser.CantNetMail) and (GUSearchV^^.Restrictions.Operator = 1) then
							b := true
						else if (not tUser.CantNetMail) and (GUSearchV^^.Restrictions.Operator = 2) then
							b := true
						else
							b := false;
					15: 
						if (tUser.ReadBeforeDL) and (GUSearchV^^.Restrictions.Operator = 1) then
							b := true
						else if (not tUser.ReadBeforeDL) and (GUSearchV^^.Restrictions.Operator = 2) then
							b := true
						else
							b := false;
				end;
			if not b then
				leave;
		end;
		SearchRest := b;
	end;

	function SearchLastCall (DaysBack, LastCall: longint; Operator: integer): boolean;
		var
			ADTRec, BDTRec: dateTimeRec;
	begin
		Secs2Date(DaysBack, ADTRec);
		Secs2Date(LastCall, BDTRec);
		case Operator of
			1: 
				if (ADTRec.Year = BDTRec.Year) and (ADTRec.Month = BDTRec.Month) and (ADTRec.Day = BDTRec.Day) then
					SearchLastCall := true
				else
					SearchLastCall := false;
			2: 
				if (ADTRec.Day <> BDTRec.Day) then
					SearchLastCall := true
				else
					SearchLastCall := false;
			3: 
				if LastCall > DaysBack then
					SearchLastCall := true
				else
					SearchLastCall := false;
			4: 
				if LastCall < DaysBack then
					SearchLastCall := true
				else
					SearchLastCall := false;
			otherwise
				SearchLastCall := false;
		end;
	end;

	function SearchMyText (TheText, SearchText: str255; Operator: integer): boolean;
		var
			i: integer;
	begin
		case Operator of
			1: 
				if (TheText = SearchText) then
					SearchMyText := true
				else
					SearchMyText := false;
			2: 
			begin
				for i := 1 to length(SearchText) do
					if (Ord(SearchText[i]) < 91) and (Ord(SearchText[i]) > 64) then
						SearchText[i] := Chr(Ord(SearchText[i]) + 32);
				for i := 1 to length(TheText) do
					if (Ord(TheText[i]) < 91) and (Ord(TheText[i]) > 64) then
						TheText[i] := Chr(Ord(TheText[i]) + 32);
				if (Pos(SearchText, TheText) <> 0) then
					SearchMyText := true
				else
					SearchMyText := false;
			end;
			otherwise
				SearchMyText := false;
		end;
	end;

	function SearchRadioButton (OnOff: boolean; TheValue: longint; Operator: integer): boolean;
	begin
		case Operator of
			1: 
				if OnOff and (TheValue = 0) then
					SearchRadioButton := true
				else if not OnOff and (TheValue = 1) then
					SearchRadioButton := true
				else
					SearchRadioButton := false;
			2: 
				if OnOff and (TheValue = 1) then
					SearchRadioButton := true
				else if not OnOff and (TheValue = 0) then
					SearchRadioButton := true
				else
					SearchRadioButton := false;
			otherwise
				SearchRadioButton := false;
		end;
	end;

	procedure GiveAccessLetter (var MyTempUser: UserRec; Operator: integer);
		var
			i: integer;
	begin
		for i := 1 to 26 do
			if GUSearchV^^.AccessLetters.Value[i] <> '[' then
				case GUSearchV^^.AccessLetters.Operator of
					1: {Give It}
						MyTempUser.AccessLetter[i] := true;
					2: {Take It}
						MyTempUser.AccessLetter[i] := false;
				end;
	end;

	procedure GiveRestrictions (var tUser: UserRec; Operator: integer);
		var
			i: integer;
			b: boolean;
	begin
		if Operator = 1 then
			b := true
		else
			b := false;
		for i := 1 to 15 do
			if GUSearchV^^.Restrictions.Value[i] = 'A' then
				case i of
					1: 
						tUser.CantPost := b;
					2: 
						tUser.CantChat := b;
					3: 
						tUser.UDRatioOn := b;
					4: 
						tUser.PCRatioOn := b;
					5: 
						tUser.CantPostAnon := b;
					6: 
						tUser.CantSendEmail := b;
					7: 
						tUser.CantChangeAutoMsg := b;
					8: 
						tUser.CantListUser := b;
					9: 
						tUser.CantAddToBBSList := b;
					10: 
						tUser.CantSeeULInfo := b;
					11: 
						tUser.CantReadAnon := b;
					12: 
						tUser.RestrictHours := b;
					13: 
						tUser.CantSendPPFile := b;
					14: 
						tUser.CantNetMail := b;
					15: 
						tUser.ReadBeforeDL := b;
				end;
	end;

	procedure GiveLastCall (var TempUser: UserRec; DaysBack: longint);
		var
			TheDaysBack: longint;
	begin
		TheDaysBack := CheckDays(DaysBack);
		TempUser.lastOn := TheDaysBack;
	end;

	procedure GiveSLClass (var TempUser: UserRec);
		var
			i: integer;
			t1: str255;
			TempLong: longint;
	begin
		TempLong := ABS(GUSearchV^^.SecurityLevel.Value);
		if SecLevels^^[TempLong].active then
		begin
			tempUser.SL := TempLong;
			NumToString(tempUser.UserNum, t1);
			if UserOnSystem(concat('@', t1)) then
				for i := 1 to InitSystHand^^.numNodes do
					if (theNodes[i]^.thisUser.userNum = tempUser.UserNum) then
						theNodes[i]^.realSL := TempLong;

			tempUser.DSL := SecLevels^^[tempLong].TransLevel;
			for i := 1 to 26 do
				tempUser.AccessLetter[i] := SecLevels^^[tempLong].Restrics[i];
			tempUser.CantReadAnon := SecLevels^^[TempLong].ReadAnon;
			tempUser.CantPost := SecLevels^^[TempLong].PostMessage;
			tempUser.CantAddToBBSList := SecLevels^^[TempLong].BBSList;
			tempUser.CantSeeULInfo := SecLevels^^[TempLong].Uploader;
			tempUser.UDRatioOn := SecLevels^^[TempLong].UDRatio;
			tempUser.CantChat := SecLevels^^[TempLong].Chat;
			tempUser.CantSendEmail := SecLevels^^[TempLong].Email;
			tempUser.CantListUser := SecLevels^^[TempLong].ListUser;
			tempUser.CantChangeAutoMsg := SecLevels^^[TempLong].AutoMsg;
			tempUser.CantPostAnon := SecLevels^^[TempLong].AnonMsg;
			tempUser.RestrictHours := SecLevels^^[TempLong].EnableHours;
			tempUser.CantSendPPFile := SecLevels^^[TempLong].PPFile;
			tempUser.CantNetMail := SecLevels^^[TempLong].CantNetMail;
			tempUser.PCRatioOn := SecLevels^^[TempLong].PCRatio;
			tempUser.XferComp := SecLevels^^[TempLong].XferComp;
			tempUser.messcomp := SecLevels^^[TempLong].MessComp;
			tempUser.UseDayOrCall := SecLevels^^[TempLong].UseDayOrCall;
			tempUser.TimeAllowed := SecLevels^^[TempLong].TimeAllowed;
			tempUser.MesgDay := SecLevels^^[TempLong].MesgDay;
			tempUser.DLRatioOneTo := SecLevels^^[TempLong].DLRatioOneTo;
			tempUser.PostRatioOneTo := SecLevels^^[TempLong].PostRatioOneTo;
			tempUser.CallsPrDay := SecLevels^^[TempLong].CallsPrDay;
			tempUser.LnsMessage := SecLevels^^[TempLong].LnsMessage;
			tempUser.AlternateText := SecLevels^^[TempLong].AlternateText;
		end
		else
		begin
			tempUser.SL := Templong;
			NumToString(tempUser.UserNum, t1);
			if UserOnSystem(concat('@', t1)) then
				for i := 1 to InitSystHand^^.numNodes do
					if (theNodes[i]^.thisUser.userNum = tempUser.UserNum) then
						theNodes[i]^.realSL := tempLong;
		end;
	end;

	procedure DrawUMStatus (Value, TotalNum: integer);
		var
			dType, tempint: integer;
			dItem: handle;
			tempRect: rect;
			SavePort: GrafPtr;
	begin
		GetPort(SavePort);
		SetPort(GlobalUSearch);
		if Value = -1 then {Initial Setup}
		begin
			SetCursor(GetCursor(watchCursor)^^);
			ShowDItem(GlobalUSearch, 21);
			ShowDItem(GlobalUSearch, 22);
			SetTextBox(GlobalUSearch, 22, 'Status :');
			GetDItem(GlobalUSearch, 21, dType, dItem, tempRect);
			ForeColor(blackColor);
			EraseRect(tempRect);
			FrameRect(tempRect);
		end
		else if Value = -99 then {Completed Hide Items}
		begin
			HideDItem(GlobalUSearch, 21);
			HideDItem(GlobalUSearch, 22);
			SetCursor(arrow);
		end
		else {Increase Bar}
		begin
			GetDItem(GlobalUSearch, 21, dType, dItem, tempRect);
			ForeColor(BlackColor);
			FrameRect(tempRect);
			ForeColor(BlueColor);
			if Value = -55 then
				tempInt := tempRect.right
			else if TotalNum <= tempRect.right - tempRect.left then
				tempInt := ((tempRect.right - tempRect.left) * Value) div TotalNum
			else
				tempInt := Value;
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

	procedure RefreshList (Deleted: boolean);
		var
			i, offset, bytesRead: integer;
			s1: str255;
			NumUsers: longint;
			tempCell: cell;
			myPtr: ptr;
			c: char;
	begin
		if Deleted then
			c := '•'
		else
			c := char($CA);
		s1 := GetTextBox(GlobalUSearch, 9);
		StringToNum(s1, NumUsers);
		for i := 1 to NumUsers do
		begin
			tempCell.h := 0;
			tempCell.v := i - 1;
			LFind(offset, bytesRead, tempCell, GUList);
			HLockHi(handle(GUList^^.cells));
			myPtr := Ptr(ORD4(GUList^^.cells^) + offset);
			s1 := Str255PtrType(myPtr)^;
			s1[0] := char(bytesRead - 1);
			s1 := concat(c, s1);
			LSetCell(Pointer(ord(@s1) + 1), length(s1), tempCell, GUList);
		end;
	end;

	procedure doSearch;
		var
			n1, n2, n3, dType, i: integer;
			dItem: handle;
			tempRect: rect;
			ByOne, MatchingUser: boolean;
			DrawUMStatusNum, TheDaysBack1, TheDaysBack2: longint;
			TempUser: UserRec;
			s1: str255;
	begin
		LDelRow(0, 0, GUList);
		SetTextBox(GlobalUSearch, 9, '0');
		DrawUMStatus(-1, 0);
		GetDItem(GlobalUSearch, 21, dType, dItem, tempRect);
		n1 := tempRect.right - tempRect.left;
		if numUserRecs <= n1 then
			ByOne := false
		else
			ByOne := true;
		DrawUMStatusNum := round((numUserRecs / n1));
		if GUSearchV^^.LastCall.OnOff then
			TheDaysBack1 := CheckDays(GUSearchV^^.LastCall.Value);
		if GUSearchV^^.FirstCall.OnOff then
			TheDaysBack2 := CheckDays(GUSearchV^^.FirstCall.Value);
		n1 := 0;
		n2 := 0;
		n3 := 0;
		with GUSearchV^^ do
		begin
			for i := 1 to numUserRecs do
			begin
				MatchingUser := true;
				if FindUser(StringOf(i : 0), TempUser) then
					;
				if SecurityLevel.OnOff then
					MatchingUser := SearchNum(TempUser.SL, SecurityLevel.Value, SecurityLevel.Operator);
				if (DownloadSL.OnOff) and (MatchingUser) then
					MatchingUser := SearchNum(TempUser.DSL, DownloadSL.Value, DownloadSL.Operator);
				if (AccessLetters.OnOff) and (MatchingUser) then
					MatchingUser := SearchAL(TempUser);
				if (Restrictions.OnOff) and (MatchingUser) then
					MatchingUser := SearchRest(TempUser);
				if (TimeAllowed.OnOff) and (MatchingUser) then
					MatchingUser := SearchNum(TempUser.TimeAllowed, TimeAllowed.Value, TimeAllowed.Operator);
				if (FirstCall.OnOff) and (MatchingUser) then
					MatchingUser := SearchLastCall(TheDaysBack2, TempUser.FirstOn, FirstCall.Operator);
				if (LastCall.OnOff) and (MatchingUser) then
					MatchingUser := SearchLastCall(TheDaysBack1, TempUser.LastOn, LastCall.Operator);
				if (MessagesPosted.OnOff) and (MatchingUser) then
					MatchingUser := SearchNum(TempUser.MessagesPosted, MessagesPosted.Value, MessagesPosted.Operator);
				if (EMailSent.OnOff) and (MatchingUser) then
					MatchingUser := SearchNum(TempUser.EMailSent, EMailSent.Value, EMailSent.Operator);
				if (TotalCalls.OnOff) and (MatchingUser) then
					MatchingUser := SearchNum(TempUser.TotalLogons, TotalCalls.Value, TotalCalls.Operator);
				if (NumUploads.OnOff) and (MatchingUser) then
					MatchingUser := SearchNum(TempUser.NumUploaded, NumUploads.Value, NumUploads.Operator);
				if (UploadK.OnOff) and (MatchingUser) then
					MatchingUser := SearchNum(TempUser.UploadedK, UploadK.Value, UploadK.Operator);
				if (NumDownloads.OnOff) and (MatchingUser) then
					MatchingUser := SearchNum(TempUser.NumDownloaded, NumDownloads.Value, NumDownloads.Operator);
				if (DownloadK.OnOff) and (MatchingUser) then
					MatchingUser := SearchNum(TempUser.DownloadedK, DownloadK.Value, DownloadK.Operator);
				if (KCredit.OnOff) and (MatchingUser) then
					MatchingUser := SearchNum(TempUser.DLCredits, KCredit.Value, KCredit.Operator);
				if (City.OnOff) and (MatchingUser) then
					MatchingUser := SearchMyText(TempUser.City, City.Value, City.Operator);
				if (State.OnOff) and (MatchingUser) then
					MatchingUser := SearchMyText(TempUser.State, State.Value, State.Operator);
				if (Zip.OnOff) and (MatchingUser) then
					MatchingUser := SearchMyText(TempUser.Zip, Zip.Value, Zip.Operator);
				if (Country.OnOff) and (MatchingUser) then
					MatchingUser := SearchMyText(TempUser.Country, Country.Value, Country.Operator);
				if (Company.OnOff) and (MatchingUser) then
					MatchingUser := SearchMyText(TempUser.Company, Company.Value, Company.Operator);
				if (Age.OnOff) and (MatchingUser) then
					MatchingUser := SearchNum(TempUser.age, Age.Value, Age.Operator);
				if (MaleFemale.OnOff) and (MatchingUser) then
					MatchingUser := SearchRadioButton(TempUser.sex, MaleFemale.Value, MaleFemale.Operator);
				if (Computer.OnOff) and (MatchingUser) then
					MatchingUser := SearchMyText(TempUser.ComputerType, Computer.Value, Computer.Operator);
				if (Misc1.OnOff) and (MatchingUser) then
					MatchingUser := SearchMyText(TempUser.MiscField1, Misc1.Value, Misc1.Operator);
				if (Misc2.OnOff) and (MatchingUser) then
					MatchingUser := SearchMyText(TempUser.MiscField2, Misc2.Value, Misc2.Operator);
				if (Misc3.OnOff) and (MatchingUser) then
					MatchingUser := SearchMyText(TempUser.MiscField3, Misc3.Value, Misc3.Operator);
				if (NormAltText.OnOff) and (MatchingUser) then
					MatchingUser := SearchRadioButton(not TempUser.AlternateText, NormAltText.Value, NormAltText.Operator);
				if (Password.OnOff) and (MatchingUser) then
					MatchingUser := SearchMyText(TempUser.Password, Password.Value, Password.Operator);
				if (VoicePhone.OnOff) and (MatchingUser) then
					MatchingUser := SearchMyText(TempUser.Phone, VoicePhone.Value, VoicePhone.Operator);
				if (DataPhone.OnOff) and (MatchingUser) then
					MatchingUser := SearchMyText(TempUser.DataPhone, DataPhone.Value, DataPhone.Operator);
				if (Sysop.OnOff) and (MatchingUser) then
					MatchingUser := SearchRadioButton(TempUser.CoSysop, Sysop.Value, Sysop.Operator);
				if (Alert.OnOff) and (MatchingUser) then
					MatchingUser := SearchRadioButton(TempUser.AlertOn, Alert.Value, Alert.Operator);
				if (Delete.OnOff) and (MatchingUser) then
					MatchingUser := SearchRadioButton(TempUser.DeletedUser, Delete.Value, Delete.Operator);
				if (DLRatioOneTo.OnOff) and (MatchingUser) then
					MatchingUser := SearchNum(TempUser.DLRatioOneTo, DLRatioOneTo.Value, DLRatioOneTo.Operator);
				if (PostRatioOneTo.OnOff) and (MatchingUser) then
					MatchingUser := SearchNum(TempUser.PostRatioOneTo, PostRatioOneTo.Value, PostRatioOneTo.Operator);
				if (XferComp.OnOff) and (MatchingUser) then
					MatchingUser := SearchReal(TempUser.XferComp, XferComp.Value, XferComp.Operator);
				if (MessComp.OnOff) and (MatchingUser) then
					MatchingUser := SearchReal(TempUser.MessComp, MessComp.Value, MessComp.Operator);
				if (MesgDay.OnOff) and (MatchingUser) then
					MatchingUser := SearchNum(TempUser.MesgDay, MesgDay.Value, MesgDay.Operator);
				if (LnsMessage.OnOff) and (MatchingUser) then
					MatchingUser := SearchNum(TempUser.LnsMessage, LnsMessage.Value, LnsMessage.Operator);
				if (CallsPrDay.OnOff) and (MatchingUser) then
					MatchingUser := SearchNum(TempUser.CallsPrDay, CallsPrDay.Value, CallsPrDay.Operator);
				if (UseDayOrCall.OnOff) and (MatchingUser) then
					MatchingUser := SearchRadioButton(TempUser.UseDayOrCall, UseDayOrCall.Value, UseDayOrCall.Operator);
				if (Alias.OnOff) and (MatchingUser) then
					MatchingUser := SearchMyText(TempUser.Alias, Alias.Value, Alias.Operator);
				if (RealName.OnOff) and (MatchingUser) then
					MatchingUser := SearchMyText(TempUser.RealName, RealName.Value, RealName.Operator);

				if MatchingUser then
				begin
					if TempUser.DeletedUser then
						s1 := concat('•', TempUser.UserName, '/#', StringOf(TempUser.UserNum : 0))
					else
						s1 := concat(char($CA), TempUser.UserName, '/#', StringOf(TempUser.UserNum : 0));
					AddListString(s1, GUList);
					n1 := n1 + 1;
					NumToString(n1, s1);
					SetTextBox(GlobalUSearch, 9, s1);
				end;
				n2 := n2 + 1;
				if n2 >= DrawUMStatusNum then
				begin
					n3 := n3 + 1;
					if ByOne then
						DrawUMStatus(n3, NumUserRecs)
					else
						DrawUMStatus(i, NumUserRecs);
					n2 := 0;
				end;
				giveBBSTime;
			end;
			if n1 > 0 then
			begin
				GetDItem(GlobalUSearch, 15, DType, DItem, tempRect);
				HiliteControl(ControlHandle(DItem), 0);
				GetDItem(GlobalUSearch, 5, DType, DItem, tempRect);
				HiliteControl(ControlHandle(DItem), 0);
				GetDItem(GlobalUSearch, 4, DType, DItem, tempRect);
				HiliteControl(ControlHandle(DItem), 0);
			end
			else
			begin
				GetDItem(GlobalUSearch, 15, DType, DItem, tempRect);
				HiliteControl(ControlHandle(DItem), 255);
				GetDItem(GlobalUSearch, 5, DType, DItem, tempRect);
				HiliteControl(ControlHandle(DItem), 255);
				GetDItem(GlobalUSearch, 4, DType, DItem, tempRect);
				HiliteControl(ControlHandle(DItem), 255);
			end;
			DrawUMStatus(-55, 0);
			delay(60, DrawUMStatusNum);
		end;
		DrawUMStatus(-99, 0);
	end;

	procedure doReplace;
		var
			dType, i, n1, n2, offset, bytesRead, x: integer;
			dItem: handle;
			tempRect: rect;
			ByOne: boolean;
			s1: str255;
			NumFound, DrawUMStatusNum: longint;
			TempUser: UserRec;
			tempCell: cell;
			myPtr: ptr;
	begin
		DrawUMStatus(-1, 0);
		s1 := GetTextBox(GlobalUSearch, 9);
		StringToNum(s1, NumFound);
		GetDItem(GlobalUSearch, 21, dType, dItem, tempRect);
		n1 := tempRect.right - tempRect.left;
		if NumFound <= n1 then
			ByOne := false
		else
			ByOne := true;
		DrawUMStatusNum := round((NumFound / n1));
		n1 := 0;
		n2 := 0;
		with GUSearchV^^ do
		begin
			for i := 1 to NumFound do
			begin
				tempCell.h := 0;
				tempCell.v := i - 1;
				LFind(offset, bytesRead, tempCell, GUList);
				HLockHi(handle(GUList^^.cells));
				myPtr := Ptr(ORD4(GUList^^.cells^) + offset);
				s1 := Str255PtrType(myPtr)^;
				s1[0] := char(bytesRead - 1);
				x := Pos('/#', s1);
				s1 := copy(s1, x + 2, length(s1));
				HUnlock(handle(GUList^^.cells));
				if FindUser(s1, TempUser) then
				begin
					if SecurityLevel.OnOff then
						GiveSLClass(TempUser);
					if DownloadSL.OnOff then
						TempUser.DSL := DownloadSL.Value;
					if AccessLetters.OnOff then
						GiveAccessLetter(TempUser, AccessLetters.Operator);
					if Restrictions.OnOff then
						GiveRestrictions(TempUser, Restrictions.Operator);
					if TimeAllowed.OnOff then
						TempUser.TimeAllowed := TimeAllowed.Value;
					if FirstCall.OnOff then
						GiveLastCall(TempUser, FirstCall.Value);
					if LastCall.OnOff then
						GiveLastCall(TempUser, LastCall.Value);
					if MessagesPosted.OnOff then
						TempUser.MessagesPosted := MessagesPosted.Value;
					if EMailSent.OnOff then
						TempUser.EMailSent := EMailSent.Value;
					if TotalCalls.OnOff then
						TempUser.TotalLogons := TotalCalls.Value;
					if NumUploads.OnOff then
						TempUser.NumUploaded := NumUploads.Value;
					if UploadK.OnOff then
						TempUser.UploadedK := UploadK.Value;
					if NumDownloads.OnOff then
						TempUser.NumDownloaded := NumDownloads.Value;
					if DownloadK.OnOff then
						TempUser.DownloadedK := DownloadK.Value;
					if KCredit.OnOff then
						TempUser.DLCredits := KCredit.Value;
					if City.OnOff then
						TempUser.City := City.Value;
					if State.OnOff then
						TempUser.State := State.Value;
					if Zip.OnOff then
						TempUser.Zip := Zip.Value;
					if Country.OnOff then
						TempUser.Country := Country.Value;
					if Company.OnOff then
						TempUser.Company := Company.Value;
					if Age.OnOff then
					begin
						x := TempUser.age - Age.Value;
						TempUser.BirthYear := Char(byte(TempUser.birthYear) + x);
						TempUser.age := Age.Value;
					end;
					if MaleFemale.OnOff then
						if MaleFemale.Value = 0 then
							TempUser.sex := true
						else
							TempUser.sex := false;
					if Computer.OnOff then
						TempUser.ComputerType := Computer.Value;
					if Misc1.OnOff then
						TempUser.MiscField1 := Misc1.Value;
					if Misc2.OnOff then
						TempUser.MiscField2 := Misc2.Value;
					if Misc3.OnOff then
						TempUser.MiscField3 := Misc3.Value;
					if NormAltText.OnOff then
						if NormAltText.Value = 0 then
							TempUser.AlternateText := false
						else
							TempUser.AlternateText := true;
					if Password.OnOff then
						TempUser.Password := Password.Value;
					if VoicePhone.OnOff then
						TempUser.Phone := VoicePhone.Value;
					if DataPhone.OnOff then
						TempUser.DataPhone := DataPhone.Value;
					if Sysop.OnOff then
						if Sysop.Value = 0 then
							TempUser.CoSysop := true
						else
							TempUser.CoSysop := false;
					if Alert.OnOff then
						if Alert.Value = 0 then
							TempUser.AlertOn := true
						else
							TempUser.AlertOn := false;
					if Delete.OnOff then
						if Delete.Value = 0 then
						begin
							TempUser.DeletedUser := true;
							if TempUser.UserName[1] <> '~' then
								TempUser.UserName := concat('~', TempUser.UserName);
							if tempUser.Alias[1] <> '•' then
								tempUser.alias := tempUser.UserName
							else
								tempUser.RealName := tempUser.UserName;
						end
						else
						begin
							TempUser.DeletedUser := false;
							if TempUser.UserName[1] = '~' then
								TempUser.UserName := Copy(TempUser.UserName, 2, length(TempUser.UserName));
							if tempUser.Alias[1] <> '•' then
								tempUser.alias := tempUser.UserName
							else
								tempUser.RealName := tempUser.UserName;
						end;
					if DLRatioOneTo.OnOff then
						TempUser.DLRatioOneTo := DLRatioOneTo.Value;
					if PostRatioOneTo.OnOff then
						TempUser.PostRatioOneTo := PostRatioOneTo.Value;
					if XferComp.OnOff then
						TempUser.XferComp := XferComp.Value;
					if MessComp.OnOff then
						TempUser.MessComp := MessComp.Value;
					if MesgDay.OnOff then
						TempUser.MesgDay := MesgDay.Value;
					if LnsMessage.OnOff then
						TempUser.LnsMessage := LnsMessage.Value;
					if CallsPrDay.OnOff then
						TempUser.CallsPrDay := CallsPrDay.Value;
					if UseDayOrCall.OnOff then
						if UseDayOrCall.Value = 0 then
							TempUser.UseDayOrCall := true
						else
							TempUser.UseDayOrCall := false;
					if Alias.OnOff then
						TempUser.Alias := Alias.Value;
					if RealName.OnOff then
						TempUser.RealName := RealName.Value;

					WriteUser(TempUser);
				end;
				n2 := n2 + 1;
				if n2 >= DrawUMStatusNum then
				begin
					n1 := n1 + 1;
					if ByOne then
						DrawUMStatus(n1, NumFound)
					else
						DrawUMStatus(i, NumFound);
					n2 := 0;
				end;
				giveBBSTime;
			end;
			if Delete.OnOff then
				if Delete.Value = 0 then
					RefreshList(true)
				else
					RefreshList(false);
		end;
		MakeUserList;
		DrawUMStatus(-55, 0);
		delay(60, NumFound);
		DrawUMStatus(-99, 0);
	end;

	procedure DoUserExport (senario: integer);
	external;

{$S UserManager_2}
	procedure Do_GlobalUEdit (theEvent: EventRecord; itemHit: integer);
		var
			DType: integer;
			DItem: handle;
			temprect: rect;
			CItem: ControlHandle;
			myPop: PopUpHand;
			i, x, n1, n2, n3, n4, n5: integer;
			myPt: Point;
			s1: str255;
			tempCell: cell;
			b: boolean;
			tempLong, DrawUMStatusNum: longint;
			myPtr: ptr;
			TempUser: UserRec;
	begin
		HLock(handle(GUSearchV));
		if (GlobalUSearch <> nil) then
			if (GlobalUSearch = FrontWindow) then
			begin
				SetPort(GlobalUSearch);
				myPt := theEvent.where;
				GlobalToLocal(myPt);
				case itemHit of
					2: {User Manager User List}
					begin
						tempCell.v := 0;
						tempCell.h := 0;
						if LClick(myPt, theEvent.modifiers, GUList) then
						begin
							if LGetSelect(true, tempCell, GUList) then
							begin
								LFind(n1, n2, tempCell, GUList);
								HLockHi(handle(GUList^^.cells));
								myPtr := Ptr(ORD4(GUList^^.cells^) + n1);
								s1 := Str255PtrType(myPtr)^;
								s1[0] := char(n2 - 1);
								n3 := Pos('/#', s1);
								s1 := copy(s1, n3 + 2, length(s1));
								HUnlock(handle(GUList^^.cells));
								if FindUser(s1, EditingUser) then
									if GetUSelection = nil then
										Open_User_Edit
									else
									begin
										SelectWindow(GetUSelection);
										SetPort(GetUSelection);
										PutInUser;
									end;
							end;
						end;
						if LGetSelect(true, tempCell, GUList) then
						begin
							GetDItem(GlobalUSearch, 7, DType, DItem, tempRect);
							HiliteControl(ControlHandle(DItem), 0);
							GetDItem(GlobalUSearch, 17, DType, DItem, tempRect);
							HiliteControl(ControlHandle(DItem), 0);
						end
						else
						begin
							GetDItem(GlobalUSearch, 7, DType, DItem, tempRect);
							HiliteControl(ControlHandle(DItem), 255);
							GetDItem(GlobalUSearch, 17, DType, DItem, tempRect);
							HiliteControl(ControlHandle(DItem), 255);
						end;
					end;
					3, 4: {Search/Replace Radio Buttons}
					begin
						SetCheckBox(GlobalUSearch, 3, false);
						SetCheckBox(GlobalUSearch, 4, false);
						SetCheckBox(GlobalUSearch, itemHit, true);
						ResetGlobalSearchOnOff;
						for i := 1 to 43 do
						begin
							s1 := BuildSearchText(i);
							tempCell.h := 0;
							tempCell.v := i - 1;
							LSetCell(Pointer(ord(@s1) + 1), length(s1), tempCell, GSearchList);
						end;
						tempCell.h := 0;
						tempCell.v := GUSearchItem - 1;
						LSetSelect(false, tempCell, GSearchList);
						tempCell.v := 0;
						LSetSelect(true, tempCell, GSearchList);
						SetButtons(1);
					end;
					5: {Export}
					begin
						s1 := GetTextBox(GlobalUSearch, 9);
						StringToNum(s1, templong);
						DoUserExport(templong);
					end;
					6: {Reset On/Offs}
					begin
						ResetGlobalSearchOnOff;
						for i := 1 to 43 do
						begin
							s1 := BuildSearchText(i);
							tempCell.h := 0;
							tempCell.v := i - 1;
							LSetCell(Pointer(ord(@s1) + 1), length(s1), tempCell, GSearchList);
						end;
						tempCell.h := 0;
						tempCell.v := GUSearchItem - 1;
						LSetSelect(false, tempCell, GSearchList);
						tempCell.v := 0;
						LSetSelect(true, tempCell, GSearchList);
						SetButtons(1);
					end;
					7: {Remove}
					begin
						tempCell.v := 0;
						tempCell.h := 0;
						if LGetSelect(true, tempCell, GUList) then
						begin
							LDelRow(1, tempCell.v, GUList);
							s1 := GetTextBox(GlobalUSearch, 9);
							StringToNum(s1, templong);
							templong := templong - 1;
							if templong <= 0 then
							begin
								templong := 0;
								GetDItem(GlobalUSearch, 15, DType, DItem, tempRect);
								HiliteControl(ControlHandle(DItem), 255);
								GetDItem(GlobalUSearch, 5, DType, DItem, tempRect);
								HiliteControl(ControlHandle(DItem), 255);
								GetDItem(GlobalUSearch, 4, DType, DItem, tempRect);
								HiliteControl(ControlHandle(DItem), 255);
								SetCheckBox(GlobalUSearch, 3, true);
								SetCheckBox(GlobalUSearch, 4, false);
								ResetGlobalSearchOnOff;
								for i := 1 to 43 do
								begin
									s1 := BuildSearchText(i);
									tempCell.h := 0;
									tempCell.v := i - 1;
									LSetCell(Pointer(ord(@s1) + 1), length(s1), tempCell, GSearchList);
								end;
								tempCell.h := 0;
								tempCell.v := GUSearchItem - 1;
								LSetSelect(false, tempCell, GSearchList);
								tempCell.v := 0;
								LSetSelect(true, tempCell, GSearchList);
								SetButtons(1);
							end;
							GetDItem(GlobalUSearch, 7, DType, DItem, tempRect);
							HiliteControl(ControlHandle(DItem), 255);
							GetDItem(GlobalUSearch, 17, DType, DItem, tempRect);
							HiliteControl(ControlHandle(DItem), 255);
							NumToString(templong, s1);
							SetTextBox(GlobalUSearch, 9, s1);
						end;
					end;
					11: {Click In Search List Items}
					begin
						tempCell.v := 0;
						tempCell.h := 0;
						if LClick(myPt, theEvent.modifiers, GSearchList) then
							;
						if LGetSelect(true, TempCell, GSearchList) then
							SetButtons(TempCell.v + 1);
					end;
					12: {Search On/Off}
					begin
						if GetCheckBox(GlobalUSearch, 12) then
							SetCheckBox(GlobalUSearch, 12, false)
						else
							SetCheckBox(GlobalUSearch, 12, true);
					end;
					15: {Delete Users}
					begin
						if ModalQuestion('Are you sure you want to delete all users in the list?', false, true) = 1 then
						begin
							DrawUMStatus(-1, 0);
							s1 := GetTextBox(GlobalUSearch, 9);
							StringToNum(s1, templong);
							GetDItem(GlobalUSearch, 21, dType, dItem, tempRect);
							n1 := tempRect.right - tempRect.left;
							if templong <= n1 then
								b := false
							else
								b := true;
							n4 := 0;
							n5 := 0;
							DrawUMStatusNum := round((templong / n1));
							for i := 1 to templong do
							begin
								tempCell.h := 0;
								tempCell.v := i - 1;
								LFind(n1, n2, tempCell, GUList);
								HLockHi(handle(GUList^^.cells));
								myPtr := Ptr(ORD4(GUList^^.cells^) + n1);
								s1 := Str255PtrType(myPtr)^;
								s1[0] := char(n2 - 1);
								n3 := Pos('/#', s1);
								s1 := copy(s1, n3 + 2, length(s1));
								HUnlock(handle(GUList^^.cells));
								if FindUser(s1, TempUser) then
								begin
									x := 0;
									while (x < availEmails) do
									begin
										if (theEMail^^[x].toUser = TempUser.userNum) or (theEMail^^[x].FromUser = TempUser.userNum) then
											DeleteMail(x)
										else
											x := x + 1;
									end;
									TempUser.DeletedUser := true;
									if TempUser.UserName[1] <> '~' then
										TempUser.UserName := concat('~', TempUser.UserName);
									if TempUser.Alias[1] <> '•' then
										TempUser.alias := TempUser.UserName
									else
										TempUser.RealName := TempUser.UserName;
									WriteUser(TempUser);
								end;
								n4 := n4 + 1;
								if (n4 >= DrawUMStatusNum) then
								begin
									n5 := n5 + 1;
									if b then
										DrawUMStatus(n5, templong)
									else
										DrawUMStatus(i, templong);
									n4 := 0;
								end;
								giveBBSTime;
							end;
							RefreshList(true);
							DrawUMStatus(-55, 0);
							delay(60, templong);
							DrawUMStatus(-99, 0);
						end;
					end;
					16: {Add}
					begin
						ChangeVarStatus;
						s1 := BuildSearchText(GUSearchItem);
						tempCell.h := 0;
						tempCell.v := GUSearchItem - 1;
						LSetCell(Pointer(ord(@s1) + 1), length(s1), tempCell, GSearchList);
					end;
					17: {User Edit}
					begin
						tempCell.h := 0;
						tempCell.v := 0;
						if LGetSelect(true, tempCell, GUList) then
						begin
							LFind(n1, n2, tempCell, GUList);
							HLockHi(handle(GUList^^.cells));
							myPtr := Ptr(ORD4(GUList^^.cells^) + n1);
							s1 := Str255PtrType(myPtr)^;
							s1[0] := char(n2 - 1);
							n3 := Pos('/#', s1);
							s1 := copy(s1, n3 + 2, length(s1));
							HUnlock(handle(GUList^^.cells));
							if FindUser(s1, EditingUser) then
								if GetUSelection = nil then
									Open_User_Edit
								else
								begin
									SelectWindow(GetUSelection);
									SetPort(GetUSelection);
									PutInUser;
								end;
						end;
					end;
					18: {PopUp Menu On/Off}
					begin
						GetDItem(GlobalUSearch, GUSearchItem + 15, DType, DItem, tempRect);
						CItem := ControlHandle(DItem);
						i := GetCtlValue(CItem);
						myPop := popupHand(CItem^^.contrlData);
						GetItem(myPop^^.mHandle, i, s1);
						if GetCheckBox(GlobalUSearch, 18) then
						begin
							SetCheckBox(GlobalUSearch, 18, false);
							s1[1] := ' ';
						end
						else
						begin
							SetCheckBox(GlobalUSearch, 18, true);
							s1[1] := '√';
						end;
						SetItem(myPop^^.mHandle, i, s1);
						GetDItem(GlobalUSearch, 18, dType, dItem, tempRect);
						SetCTitle(ControlHandle(dItem), s1);
					end;
					19: {Restrictions}
					begin
						GetDItem(GlobalUSearch, 19, DType, DItem, tempRect);
						CItem := ControlHandle(DItem);
						i := GetCtlValue(CItem);
						myPop := popupHand(CItem^^.contrlData);
						GetItem(myPop^^.mHandle, i, s1);
						GetDItem(GlobalUSearch, 18, dType, dItem, tempRect);
						SetCTitle(ControlHandle(dItem), s1);
						if s1[1] = '√' then
							SetCheckBox(GlobalUSearch, 18, true)
						else
							SetCheckBox(GlobalUSearch, 18, false);
					end;
					20: {UnUsed}
					begin
					end;
					23, 24: {Radio Buttons}
					begin
						SetCheckBox(GlobalUSearch, 23, false);
						SetCheckBox(GlobalUSearch, 24, false);
						if itemHit = 23 then
							SetCheckBox(GlobalUSearch, 23, true)
						else
							SetCheckBox(GlobalUSearch, 24, true);
					end;
					25: 
					begin
						b := GetCheckBox(GlobalUSearch, 25);
						SetCheckBox(GlobalUSearch, 25, not b);
					end;
					26: 
					begin
						if GetCheckBox(GlobalUSearch, 3) then
							doSearch
						else if (ModalQuestion('Do you really want to change these users?', false, true) = 1) then
							doReplace;
					end;
					otherwise
						;
				end;
			end;
		HUnLock(handle(GUSearchV));
	end;

	procedure Close_GlobalUEdit;
	begin
		if GUSearchV <> nil then
		begin
			HPurge(handle(GUSearchV));
			DisposHandle(handle(GUSearchV));
			GUSearchV := nil;
		end;
		if (GlobalUSearch <> nil) then
		begin
			DisposDialog(GlobalUSearch);
			GlobalUSearch := nil;
		end;
	end;

end.