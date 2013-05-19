{ Segments: Telnet_1 }
unit Telnet;

interface
	uses
		Processes, AppleTalk, ADSP, Serial, Sound, TCPTypes, Initial, NodePrefs, InpOut4;

	procedure DoTelnetNegotiation;

implementation
	const
		TelnetTimeout = 60; { ticks }

	{ Telnet sequences. }
		telnetSE = 240;
		telnetNOP = 241;
		telnetDataMark = 242;
		telnetBreak = 243;
		telnetInterruptProcess = 244;
		telnetAbortOutput = 245;
		telnetAreYouThere = 246;
		telnetEraseCharacter = 247;
		telnetEraseLine = 248;
		telnetGoAhead = 249;
		telnetSB = 250;
		telnetWILL = 251;
		telnetWONT = 252;
		telnetDO = 253;
		telnetDONT = 254;
		telnetIAC = 255;

	{ The telnet options we process. }
		TRANSMIT_BINARY = $00;
		ECHO = $01;
		SUPPRESS_GO_AHEAD = $03;

	type
	{ Telnet state. }
		eTelnetState = (waitingIAC, waitingCommand, waitingCode);

	{ Q Method types. }
		eUsHim = (NO, WANTNO, WANTYES, YES);
		eUsQHimQ = (EMPTY, OPPOSITE);
		qOptionPtr = ^qOption;
		qOption = record
				us: eUsHim;
				usq: eUsQHimQ;
				him: eUsHim;
				himq: eUsQHimQ;
			end;
		qOptionListPtr = ^qOptionList;
		qOptionList = record
				options: array[0..3] of qOption;
			end;

{$S Telnet_1}
	function GetTelnetString (command, code: byte): Str255;
		var
			tempString, tempString2: Str255;
	begin
		tempString := '<IAC ';

		if command = telnetWILL then
			tempString := concat(tempString, 'WILL ')
		else if command = telnetWONT then
			tempString := concat(tempString, 'WONT ')
		else if command = telnetDO then
			tempString := concat(tempString, 'DO ')
		else if command = telnetDONT then
			tempString := concat(tempString, 'DONT ');

		if code = TRANSMIT_BINARY then
			tempString := concat(tempString, 'TRANSMIT-BINARY')
		else if code = ECHO then
			tempString := concat(tempString, 'ECHO')
		else if code = SUPPRESS_GO_AHEAD then
			tempString := concat(tempString, 'SUPPRESS-GO-AHEAD')
		else
		begin
			NumToString(code, tempString2);
			tempString := concat(tempString, '#', tempString2);
		end;

		tempString := concat(tempString, '>');
		GetTelnetString := tempString;
	end;

	procedure LogTelnet (logStr: Str255);
		var
			path: str255;
			logRef: integer;
			logStrSize: longInt;
			result: OSerr;
	begin
	{ Display to the SysOp. }
		OutLineSysop(logStr, true);

	{ Write to the file if requested. }
		if InitSystHand^^.DebugTelnetToFile then
		begin
			path := concat(sharedPath, 'Misc:Telnet Log');
			result := FSOpen(path, 0, logRef);
			if result <> noErr then
			begin
				result := FSDelete(path, 0);
				result := Create(path, 0, 'HRMS', 'TEXT');
				result := FSOpen(path, 0, LogRef);
			end;
			if result = noErr then
			begin
				logStr := concat(logStr, char(13));
				result := SetFPos(logRef, fsFromLEOF, 0);
				logStrSize := length(logStr);
				result := FSWrite(logRef, logStrSize, @logStr[1]);
				result := FSClose(logRef);
			end;
		end;
	end;

	procedure SendTelnet (command, code: byte);
		var
		{ Temporary vars. }
			result: OSErr;

		{ General vars. }
			writeBytes: packed array[0..2] of byte;
	begin
		with curGlobs^ do
		begin
			if InitSystHand^^.DebugTelnet then
				LogTelnet(concat('Telnet: sending ', GetTelnetString(command, code)));

		{ Prepare our sequence. }
			writeBytes[0] := telnetIAC;
			writeBytes[1] := command;
			writeBytes[2] := code;

		{ Send the sequence. }
			nodeTCP.tcpWDSPtr^.size := 3;
			nodeTCP.tcpWDSPtr^.buffer := @writeBytes;
			nodeTCP.tcpWDSPtr^.term := 0;

			with nodeTCP.tcpPBPtr^ do
			begin
				ioResult := 1;
				ioCompletion := nil;

				ioCRefNum := ippDrvrRefNum;
				csCode := TCPcsSend;
				tcpStream := nodeTCP.tcpStreamPtr;

				send.ulpTimeoutValue := 0;
				send.ulpTimeoutAction := -1;
				send.validityFlags := $c0;
				send.pushFlag := 1;
				send.urgentFlag := 0;
				send.wds := nodeTCP.tcpWDSPtr;
				send.userDataPtr := nil;
			end;

			result := PBControl(ParmBlkPtr(nodeTCP.tcpPBPtr), false);
		end;
	end;

	procedure DoTelnetNegotiation;
		label
			2;

		var
		{ Temporary vars. }
			result: OSErr;
			tempString: Str255;

		{ General variables. }
			readCnt: integer;
			readBytes: packed array[0..1] of byte;
			cb: TCPControlBlock;
			opt: qOptionPtr;
			useANSI: Boolean;

		{ State variables. }
			options: qOptionListPtr;
			state: eTelnetState;
			curCommand: byte;
	begin
		with curGlobs^ do
		begin
		{ crossint7 is the current telnet command.  crossint8 is the state variable. }
		{ crosslong is used to hold the options pointer. }
			curCommand := crossint7;
			state := eTelnetState(crossint8);
			options := qOptionListPtr(crosslong);

			case crossint of
				1: { Enter telnet negotiation stage. }
				begin
					if InitSystHand^^.DebugTelnet then
						LogTelnet('Telnet: beginning telnet negotiation..');

				{ Initialize our telnet state and set our timeout counter.  If we don't receive any telnet}
				{ negotiation codes in TelnetTimeout seconds, then we conclude negotiation. }
					state := waitingIAC;
					lastKeyPressed := TickCount;

				{ Initialize our option state.  We only will process options that we know about. }
				{ Everything else gets ignored. }
					options := qOptionListPtr(NewPtrClear(sizeof(qOptionList)));

					{ Things we ask for. }
					options^.options[TRANSMIT_BINARY].us := YES;
					options^.options[TRANSMIT_BINARY].usq := EMPTY;
					options^.options[TRANSMIT_BINARY].him := WANTYES;
					options^.options[TRANSMIT_BINARY].himq := EMPTY;
					SendTelnet(telnetDO, TRANSMIT_BINARY);

					options^.options[ECHO].us := WANTYES;
					options^.options[ECHO].usq := EMPTY;
					options^.options[ECHO].him := NO;
					options^.options[ECHO].himq := EMPTY;
					SendTelnet(telnetWILL, ECHO);

					{ Things we are asked. }
					options^.options[SUPPRESS_GO_AHEAD].us := YES;
					options^.options[SUPPRESS_GO_AHEAD].usq := EMPTY;
					options^.options[SUPPRESS_GO_AHEAD].him := NO;
					options^.options[SUPPRESS_GO_AHEAD].himq := EMPTY;

				{ Start reading characters. }
					crossint := 2;
				end;

				2: 
				begin { Telnet negotiation loop. }
2:				{ Only continue if there is data to read. }
					readCnt := TCPBytesToRead(@nodeTCP);
					if readCnt <> 0 then
					begin
					{ Read a byte. }
						with cb do
						begin
							ioResult := 1;
							ioCompletion := nil;

							ioCRefNum := ippDrvrRefNum;
							csCode := TCPcsRcv;
							tcpStream := nodeTCP.tcpStreamPtr;

							receive.commandTimeoutValue := 0;
							receive.markFlag := 0;
							receive.urgentFlag := 0;
							receive.rcvBuff := @readBytes;
							receive.rcvBuffLength := 1;
							receive.userDataPtr := nil;
						end; { with cb }
						result := PBControl(ParmBlkPtr(@cb), false);
						if result = noErr then
						begin
						{ Reset our telnet timeout. }
							lastKeyPressed := TickCount;

						{ Store the amount of data read. }
							readCnt := cb.receive.rcvBuffLength;
							if InitSystHand^^.DebugTelnet then
							begin
								NumToString(readBytes[0], tempString);
								LogTelnet(concat('Telnet: received character #', tempString));
							end;

						{ Process this byte through our state machine. }
							case state of
								waitingIAC: 
									case readBytes[0] of
										telnetIAC: 
										begin
										{ Look for a telnet command. }
											state := waitingCommand;
										end;
										otherwise
										begin
										{ We received an out of state character; telnet negotiation must be over. }
											crossint := 99;
											if InitSystHand^^.DebugTelnet then
												LogTelnet('Telnet: out of state character; concluding negotiation.');
										end;
									end;

								waitingCommand: 
								begin
									curCommand := readBytes[0];
									if (readBytes[0] = telnetWILL) or (readBytes[0] = telnetWONT) or (readBytes[0] = telnetDO) or (readBytes[0] = telnetDONT) then
										state := waitingCode
									else
									begin
											{ We received an out of state character; telnet negotiation must be over. }
										crossint := 99;
										if InitSystHand^^.DebugTelnet then
											LogTelnet('Telnet: out of state character; concluding negotiation.');
									end;
								end;

								waitingCode: 
								begin
									if InitSystHand^^.DebugTelnet then
										LogTelnet(concat('Telnet: received ', GetTelnetString(curCommand, readBytes[0])));
									if (readBytes[0] = TRANSMIT_BINARY) or (readBytes[0] = ECHO) or (readBytes[0] = SUPPRESS_GO_AHEAD) then
									begin
									{ Process this code according to the command. }
										opt := @options^.options[readBytes[0]];

										if InitSystHand^^.DebugTelnet then
										begin
											tempString := 'Telnet:';
											if opt^.us = YES then
												tempString := concat(tempString, ' us=YES;')
											else
												tempString := concat(tempString, ' us=NO;');
											if opt^.usq = EMPTY then
												tempString := concat(tempString, ' usq=EMPTY;')
											else
												tempString := concat(tempString, ' usq=OPPOSITE;');
											if opt^.him = YES then
												tempString := concat(tempString, ' him=YES;')
											else
												tempString := concat(tempString, ' him=NO;');
											if opt^.himq = EMPTY then
												tempString := concat(tempString, ' himq=EMPTY;')
											else
												tempString := concat(tempString, ' himq=OPPOSITE;');
											LogTelnet(tempString);
										end;

										case curCommand of
											telnetWILL: 
											begin
												if opt^.him = NO then
												begin
													if opt^.us = YES then
													begin
														opt^.him := YES;
														SendTelnet(telnetDO, readBytes[0]);
													end
													else
														SendTelnet(telnetDONT, readBytes[0]);
												end
												else if opt^.him = YES then
													{ ignore }
												else if (opt^.him = WANTNO) and (opt^.himq = EMPTY) then
												begin
													opt^.him := NO;
													if InitSystHand^^.DebugTelnet then
														LogTelnet('Telnet: error; DONT answered by WILL.')
												end
												else if (opt^.him = WANTNO) and (opt^.himq = OPPOSITE) then
												begin
													opt^.him := YES;
													opt^.himq := EMPTY;
													if InitSystHand^^.DebugTelnet then
														LogTelnet('Telnet: error; DONT answered by WILL.');
												end
												else if (opt^.him = WANTYES) and (opt^.himq = EMPTY) then
												begin
													opt^.him := YES;
												end
												else if (opt^.him = WANTNO) and (opt^.himq = OPPOSITE) then
												begin
													opt^.him := WANTNO;
													opt^.himq := EMPTY;
													SendTelnet(telnetDONT, readBytes[0]);
												end;
											end;
										end;
									end
									else
									begin
									{ Unknown code. }
										if InitSystHand^^.DebugTelnet then
											LogTelnet('Telnet: unknown telnet code; ignoring.');
									end;

									{ Wait for the next code. }
									state := waitingIAC;
								end;

								otherwise
								begin
								{ We received random data; telnet negotiation must be over. }
									crossint := 99;
									if InitSystHand^^.DebugTelnet then
										LogTelnet('Telnet: unknown character received; concluding negotiation.');
								end;
							end; { case state }
						end; { result = noErr }
					end
					else { readCnt <> 0 }
					begin
						if TickCount > (lastKeyPressed + TelnetTimeout) then
						begin
								{ We received random data; telnet negotiation must be over. }
							crossint := 99;
							if InitSystHand^^.DebugTelnet then
								LogTelnet('Telnet: telnet negotiation timed out; concluding negotiation.');
						end;
					end;
				end;

				99: { Telnet negotiation complete. }
				begin
				{ Determine if this user supports ANSI. }
					useANSI := true;

				{ Free our option pointer. }
					DisposPtr(Ptr(options));

				{ Log the user in. }
					if InitSystHand^^.DebugTelnet then
						LogTelnet('Telnet: telnet negotiation complete.');
					DoLogon(useANSI);
				end;
			end;

		{ crossint7 is the current telnet command.  crossint8 is the state variable. }
		{ crosslong is used to hold the options pointer. }
			crossint7 := curCommand;
			crossint8 := integer(state);
			crosslong := longint(options);
		end;
	end;

end.