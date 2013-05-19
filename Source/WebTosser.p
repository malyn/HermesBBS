{ Segments: WebTosser_1 }
unit WebTosser;

interface
	uses
		Processes, AppleTalk, ADSP, Serial, Sound, TCPTypes, Initial, NodePrefs, InpOut4;

	procedure DoWebTosser;

implementation
	const
		WebTosserTimeout = 60; { ticks }

{$S WebTosser_1}
	procedure LogWebTosser (logStr: Str255);
		var
			path: str255;
			logRef: integer;
			logStrSize: longInt;
			result: OSerr;
	begin
	{ Display to the SysOp. }
		if DebugWebTosser then
			OutLineSysop(logStr, true);

	{ Write to the file if requested. }
		if DebugWebTosserToFile then
		begin
			path := concat(sharedPath, 'Misc:Web Tosser Log');
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

	procedure DoWebTosser;
		label
			1;
		const
		{ Timeouts. }
			CONNECT_TIMEOUT = 30;
			SEND_TIMEOUT = 30;
			RECEIVE_TIMEOUT = 30;
		{ Buffer sizes. }
			RECEIVE_BUFFER = 8192;
		{ Header constants. }
			NODENUMBER_PART_HEADER = 'Content-Disposition: form-data; name="nodenumber"';
			PASSWORD_PART_HEADER = 'Content-Disposition: form-data; name="password"';
			AREASBBS_PART_HEADER1 = 'Content-Disposition: form-data; name="areasbbs!"; filename="areas.bbs"';
			AREASBBS_PART_HEADER2 = 'Content-Type: text/plain';
			GE_PART_HEADER1 = 'Content-Disposition: form-data; name="genericexport!"; filename="Generic Export"';
			GE_PART_HEADER2 = 'Content-Type: application/octet-stream';
			GE_PART_HEADER3 = 'Content-Transfer-Encoding: binary';
		var
		{ Temporary vars. }
			result: OSErr;
			i, writeCnt, giPos: longint;
			tempString: Str255;
			receiveBuffer: Ptr;

		{ General variables. }
			areasBbsLength, genericExportLength: longint;
			contentLength: longint;
	begin
		case webTosserDo of
			WebTosserConnect: 
			begin
				{ Initialize the web tosser. }
				webTosserAreasBbsRefNum := -1;
				webTosserGenericExportRefNum := -1;
				webTosserGenericImportRefNum := -1;

				{ Create a new Generic Import file, which must not already exist. }
				result := FSOpen(Concat(Mailer^^.GenericPath, 'Generic Import'), fsRdPerm, webTosserGenericImportRefNum);
				if result = noErr then
				begin
					webTosserGenericImportRefNum := -1;
					LogWebTosser('Generic Import file already exists; aborting Web Tosser poll.');
					webTosserDo := WebTosserDone;
					Exit(DoWebTosser);
				end;

				result := Create(Concat(Mailer^^.GenericPath, 'Generic Import'), 0, 'HRMS', 'TEXT');
				if result <> noErr then
				begin
					LogWebTosser(Concat('Error creating Generic Import file: ', StringOf(result : 0), '.'));
					webTosserDo := WebTosserDone;
					Exit(DoWebTosser);
				end;

				result := FSOpen(Concat(Mailer^^.GenericPath, 'Generic Import'), fsRdWrPerm, webTosserGenericImportRefNum);
				if result <> noErr then
				begin
					webTosserGenericImportRefNum := -1;
					LogWebTosser(Concat('Error opening Generic Import file: ', StringOf(result : 0), '.'));
					webTosserDo := WebTosserDone;
					Exit(DoWebTosser);
				end;

				{ Open the Areas.BBS and Generic Export files. }
				result := FSOpen(Concat(sharedPath, 'Misc:Areas.BBS'), fsRdPerm, webTosserAreasBbsRefNum);
				if result <> noErr then
				begin
					webTosserAreasBbsRefNum := -1;
					LogWebTosser(Concat('Error opening Areas.BBS file: ', StringOf(result : 0), '.'));
					webTosserDo := WebTosserDone;
					Exit(DoWebTosser);
				end;

				result := FSOpen(Concat(Mailer^^.GenericPath, 'Generic Export'), fsRdPerm, webTosserGenericExportRefNum);
				if result <> noErr then
					webTosserGenericExportRefNum := -1;

				{ Create the TCP stream. }
				result := CreateTCPStream(@webTosserTCP);
				if result <> noErr then
				begin
					webTosserDo := WebTosserDone;
					Exit(DoWebTosser);
				end;

				{ Initiate the connection to the Hermes Web Tosser. }
				LogWebTosser('Opening connection to Hermes Web Tosser at TODO...');
				InitiateTCPConnection(@webTosserTCP, $4537e4ed, 80, CONNECT_TIMEOUT);
				webTosserDo := WebTosserConnectWait;
			end;

			WebTosserConnectWait: 
			begin
				{ Keep waiting if the connection has not yet been opened. }
				if webTosserTCP.tcpPBPtr^.ioResult = 1 then
					Exit(DoWebTosser);

				{ Connection open; see if there was an error. }
				if webTosserTCP.tcpPBPtr^.ioResult <> noErr then
				begin
					LogWebTosser(Concat('Connection failed with error ', StringOf(webTosserTCP.tcpPBPtr^.ioResult : 0), '.'));
					DestroyTCPStream(@webTosserTCP);
					webTosserDo := WebTosserDone;
					Exit(DoWebTosser);
				end;

				{ The connection was opened successfully; build and send the POST arguments. }
				LogWebTosser('Connection opened; building POST request...');

				{ Generate a MIME boundary without the "--" prefix. }
				webTosserMimeBoundary := Concat('-------------------------', StringOf(TickCount : 0), '-', Mailer^^.hwtPassword);

				{ Get the lengths of the Areas.BBS and Generic Export files. }
				result := GetEOF(webTosserAreasBbsRefNum, areasBbsLength);
				if webTosserGenericExportRefNum <> -1 then
					result := GetEOF(webTosserGenericExportRefNum, genericExportLength)
				else
					genericExportLength := 0;

				{ Calculate the content length. }
				contentLength := 0;
				contentLength := contentLength + (2 + Length(webTosserMimeBoundary) + 2) + (Length(NODENUMBER_PART_HEADER) + 2) + 2 + (Integer(Mailer^^.hwtNodeNumber[0]) + 2);
				contentLength := contentLength + (2 + Length(webTosserMimeBoundary) + 2) + (Length(PASSWORD_PART_HEADER) + 2) + 2 + (Integer(Mailer^^.hwtPassword[0]) + 2);
				contentLength := contentLength + (2 + Length(webTosserMimeBoundary) + 2) + (Length(AREASBBS_PART_HEADER1) + 2) + (Length(AREASBBS_PART_HEADER2) + 2) + 2 + areasBbsLength + 2;
				contentLength := contentLength + (2 + Length(webTosserMimeBoundary) + 2) + (Length(GE_PART_HEADER1) + 2) + (Length(GE_PART_HEADER2) + 2) + (Length(GE_PART_HEADER3) + 2) + 2 + genericExportLength + 2;
				contentLength := contentLength + (2 + Length(webTosserMimeBoundary) + 2 + 2);

				{ Build the HTTP POST request. }
				webTosserSending := Concat('POST / HTTP/1.0', Char(13), Char(10), 'Host: tosser.hermesbbs.com', Char(13), Char(10), 'Content-Type: multipart/form-data; boundary=', webTosserMimeBoundary, Char(13), Char(10), 'Content-Length: ', StringOf(contentLength : 0), Char(13), Char(10), Char(13), Char(10));
				webTosserTCP.tcpWDSPtr^.size := Length(webTosserSending);
				webTosserTCP.tcpWDSPtr^.buffer := Ptr(LongInt(@webTosserSending) + 1);
				webTosserTCP.tcpWDSPtr^.term := 0;

				{ Send the request. }
				LogWebTosser('Sending POST request...');
				webTosserDo := WebTosserSend;
				webTosserDoNext := WebTosserSendNodeNumber;
			end;

			WebTosserSendNodeNumber: 
			begin
				{ Build the nodenumber part. }
				webTosserSending := Concat('--', webTosserMimeBoundary, Char(13), Char(10), NODENUMBER_PART_HEADER, Char(13), Char(10), Char(13), Char(10), Mailer^^.hwtNodeNumber, Char(13), Char(10));
				webTosserTCP.tcpWDSPtr^.size := Length(webTosserSending);
				webTosserTCP.tcpWDSPtr^.buffer := Ptr(LongInt(@webTosserSending) + 1);
				webTosserTCP.tcpWDSPtr^.term := 0;

				{ Send the part. }
				LogWebTosser('Sending nodenumber part...');
				webTosserDo := WebTosserSend;
				webTosserDoNext := WebTosserSendPassword;
			end;

			WebTosserSendPassword: 
			begin
				{ Build the password part. }
				webTosserSending := Concat('--', webTosserMimeBoundary, Char(13), Char(10), PASSWORD_PART_HEADER, Char(13), Char(10), Char(13), Char(10), Mailer^^.hwtPassword, Char(13), Char(10));
				webTosserTCP.tcpWDSPtr^.size := Length(webTosserSending);
				webTosserTCP.tcpWDSPtr^.buffer := Ptr(LongInt(@webTosserSending) + 1);
				webTosserTCP.tcpWDSPtr^.term := 0;

				{ Send the part. }
				LogWebTosser('Sending password part...');
				webTosserDo := WebTosserSend;
				webTosserDoNext := WebTosserSendAreasBBSHeader;
			end;

			WebTosserSendAreasBBSHeader: 
			begin
				{ Build the Areas.BBS part header. }
				webTosserSending := Concat('--', webTosserMimeBoundary, Char(13), Char(10), AREASBBS_PART_HEADER1, Char(13), Char(10), AREASBBS_PART_HEADER2, Char(13), Char(10), Char(13), Char(10));
				webTosserTCP.tcpWDSPtr^.size := Length(webTosserSending);
				webTosserTCP.tcpWDSPtr^.buffer := Ptr(LongInt(@webTosserSending) + 1);
				webTosserTCP.tcpWDSPtr^.term := 0;

				{ Send the part header. }
				LogWebTosser('Sending Areas.BBS part header...');
				webTosserDo := WebTosserSend;
				webTosserDoNext := WebTosserSendAreasBBSFile;
			end;

			WebTosserSendAreasBBSFile: 
			begin
				{ Send the Areas.BBS file. }
				LogWebTosser('Sending Areas.BBS file...');
				webTosserSendingRefNum := webTosserAreasBbsRefNum;
				webTosserDo := WebTosserSendFile;
				webTosserDoNextFile := WebTosserSendGenericExportHeader;
			end;

			WebTosserSendGenericExportHeader: 
			begin
				{ Build the Generic Export part header (including the CRLF prefix that completes the Areas.BBS part. }
				webTosserSending := Concat(Char(13), Char(10), '--', webTosserMimeBoundary, Char(13), Char(10), GE_PART_HEADER1, Char(13), Char(10), GE_PART_HEADER2, Char(13), Char(10), GE_PART_HEADER3, Char(13), Char(10), Char(13), Char(10));
				webTosserTCP.tcpWDSPtr^.size := Length(webTosserSending);
				webTosserTCP.tcpWDSPtr^.buffer := Ptr(LongInt(@webTosserSending) + 1);
				webTosserTCP.tcpWDSPtr^.term := 0;

				{ Send the part header. }
				LogWebTosser('Sending Generic Export part header...');
				webTosserDo := WebTosserSend;

				{ Only send the Generic Export file if we have one. }
				if webTosserGenericExportRefNum <> -1 then
					webTosserDoNext := WebTosserSendGenericExportFile
				else
					webTosserDoNext := WebTosserSendRequestTrailer;
			end;

			WebTosserSendGenericExportFile: 
			begin
				{ Send the Generic Export file. }
				LogWebTosser('Sending Generic Export file...');
				webTosserSendingRefNum := webTosserGenericExportRefNum;
				webTosserDo := WebTosserSendFile;
				webTosserDoNextFile := WebTosserSendRequestTrailer;
			end;

			WebTosserSendRequestTrailer: 
			begin
 				{ Build the request trailer (including the CRLF prefix that completes the Generic Export part. }
				webTosserSending := Concat(Char(13), Char(10), '--', webTosserMimeBoundary, '--', Char(13), Char(10));
				webTosserTCP.tcpWDSPtr^.size := Length(webTosserSending);
				webTosserTCP.tcpWDSPtr^.buffer := Ptr(LongInt(@webTosserSending) + 1);
				webTosserTCP.tcpWDSPtr^.term := 0;

				{ Send the part. }
				LogWebTosser('Sending request trailer...');
				webTosserDo := WebTosserSend;
				webTosserDoNext := WebTosserReceiveGenericImport;
				webTosserParseGenericImportState := wtpgiSkippingHeader;
			end;

			WebTosserReceiveGenericImport: 
			begin
				{ Receive the next RECEIVE_BUFFER bytes of the file. }
				receiveBuffer := NewPtr(RECEIVE_BUFFER);
				with webTosserTCP.tcpPBPtr^ do
				begin
					ioResult := 1;
					ioCompletion := nil;

					ioCRefNum := ippDrvrRefNum;
					csCode := TCPcsRcv;
					tcpStream := webTosserTCP.tcpStreamPtr;

					receive.commandTimeoutValue := 0;
					receive.markFlag := 0;
					receive.urgentFlag := 0;
					receive.rcvBuff := receiveBuffer;
					receive.rcvBuffLength := RECEIVE_BUFFER;
					receive.userDataPtr := nil;
				end;

				result := PBControl(ParmBlkPtr(webTosserTCP.tcpPBPtr), false);

				{ Write out the bytes if data was received, otherwise close the connection or fail the }
				{ transfer depending on the error code. }
				if result = noErr then
				begin
					writeCnt := webTosserTCP.tcpPBPtr^.receive.rcvBuffLength;
					LogWebTosser(Concat('Received ', StringOf(writeCnt : 0), ' bytes of the Generic Import file.'));

					{ Process the data according to our parse state. }
					for giPos := 1 to writeCnt do
						case webTosserParseGenericImportState of
							wtpgiSkippingHeader: 
							begin
1:
								if Ptr(Longint(receiveBuffer) + (giPos - 1))^ = 13 then
									webTosserParseGenericImportState := wtpgiSkippingLF1;
							end;

							wtpgiSkippingLF1: 
							begin
								if Ptr(LongInt(receiveBuffer) + (giPos - 1))^ = 10 then
								begin
									webTosserParseGenericImportState := wtpgiSkippingCR2;
								end
								else
								begin
									webTosserParseGenericImportState := wtpgiSkippingHeader;
									goto 1;
								end;
							end;

							wtpgiSkippingCR2: 
							begin
								if Ptr(LongInt(receiveBuffer) + (giPos - 1))^ = 13 then
								begin
									webTosserParseGenericImportState := wtpgiSkippingLF2;
								end
								else
								begin
									webTosserParseGenericImportState := wtpgiSkippingHeader;
									goto 1;
								end;
							end;

							wtpgiSkippingLF2: 
							begin
								if Ptr(LongInt(receiveBuffer) + (giPos - 1))^ = 10 then
								begin
									webTosserParseGenericImportState := wtpgiReadingFile;
								end
								else
								begin
									webTosserParseGenericImportState := wtpgiSkippingHeader;
									goto 1;
								end;
							end;

							wtpgiReadingFile: 
							begin
								writeCnt := writeCnt - (giPos - 1);
								result := FSWrite(webTosserGenericImportRefNum, writeCnt, Ptr(LongInt(receiveBuffer) + (giPos - 1)));
								DisposPtr(receiveBuffer);

								if result <> noErr then
								begin
									LogWebTosser(Concat('Error writing Generic Import file: ', StringOf(result : 0), '.'));
									webTosserDo := WebTosserDisconnect;
								end;

								Exit(DoWebTosser);
							end;
						end;

					{ Free the receive buffer. }
					DisposPtr(receiveBuffer);
				end
				else if result = connectionClosingErr then
				begin
					DisposPtr(receiveBuffer);

					LogWebTosser('Done receiving Generic Import file.');
					result := GetEOF(webTosserGenericImportRefNum, writeCnt);
					result := FSClose(webTosserGenericImportRefNum);
					webTosserGenericImportRefNum := -1;

					{ Delete empty Generic Import files; process non-empty Generic Import files. }
					if writeCnt = 0 then
					begin
						LogWebTosser('Deleting empty Generic Import file.');
						result := FSDelete(Concat(Mailer^^.GenericPath, 'Generic Import'), 0);
					end
					else
					begin
						{ Check for a Generic Import file now (since we just finished receiving one). }
						lastGenericCheck := 0;
					end;

					webTosserDo := WebTosserDisconnect;
				end
				else if result <> noErr then
				begin
					DisposPtr(receiveBuffer);
					LogWebTosser(Concat('Error receiving Generic Import file: ', StringOf(result : 0), '.'));
					webTosserDo := WebTosserDisconnect;
					Exit(DoWebTosser);
				end;
			end;

			WebTosserSendFile: 
			begin
				{ Read the next 250 bytes of the file. }
				result := FSRead(webTosserSendingRefNum, writeCnt, @webTosserSending);
				if result = noErr then
				begin
					webTosserTCP.tcpWDSPtr^.size := writeCnt;
					webTosserTCP.tcpWDSPtr^.buffer := @webTosserSending;
					webTosserTCP.tcpWDSPtr^.term := 0;
					webTosserDo := WebTosserSend;
					webTosserDoNext := WebTosserSendFile;
				end
				else if result = eofErr then
				begin
					webTosserTCP.tcpWDSPtr^.size := writeCnt;
					webTosserTCP.tcpWDSPtr^.buffer := @webTosserSending;
					webTosserTCP.tcpWDSPtr^.term := 0;
					webTosserDo := WebTosserSend;
					webTosserDoNext := webTosserDoNextFile
				end
				else
				begin
					LogWebTosser(Concat('Error reading file in state ', StringOf(webTosserDoNextFile : 0), ': ', StringOf(result : 0), '.'));
					webTosserDo := WebTosserDisconnect;
					Exit(DoWebTosser);
				end;
			end;

			WebTosserSend: 
			begin
				with webTosserTCP.tcpPBPtr^ do
				begin
					ioResult := 1;
					ioCompletion := nil;

					ioCRefNum := ippDrvrRefNum;
					csCode := TCPcsSend;
					tcpStream := webTosserTCP.tcpStreamPtr;

					send.ulpTimeoutValue := SEND_TIMEOUT;
					send.ulpTimeoutAction := -1;
					send.validityFlags := $c0;
					send.pushFlag := 0;
					send.urgentFlag := 0;
					send.wds := webTosserTCP.tcpWDSPtr;
					send.userDataPtr := nil;
				end;

				result := PBControl(ParmBlkPtr(webTosserTCP.tcpPBPtr), true);
				webTosserDo := WebTosserSendWait;
			end;

			WebTosserSendWait: 
			begin
				{ Keep waiting if the request has not yet been sent. }
				if webTosserTCP.tcpPBPtr^.ioResult = 1 then
					Exit(DoWebTosser);

				{ See if the request was sent successfully. }
				if webTosserTCP.tcpPBPtr^.ioResult <> noErr then
				begin
					LogWebTosser(Concat('Send failed with error ', StringOf(webTosserTCP.tcpPBPtr^.ioResult : 0), '.'));
					webTosserDo := WebTosserDisconnect;
					Exit(DoWebTosser);
				end;

				{ Next state. }
				webTosserDo := webTosserDoNext;
			end;

			WebTosserDisconnect: 
			begin
				{ Close the connection. }
				LogWebTosser('Closing connection...');
				CloseTCPConnection(@webTosserTCP);
				webTosserDo := WebTosserDisconnectWait;
			end;

			WebTosserDisconnectWait: 
			begin
				{ Keep waiting if the connection has not yet been closed. }
				if webTosserTCP.tcpPBPtr^.ioResult = 1 then
					Exit(DoWebTosser);

				{ Connection closed, we're done. }
				LogWebTosser('Connection closed.');
				DestroyTCPStream(@webTosserTCP);
				webTosserDo := WebTosserDone;
			end;

			WebTosserDone: 
			begin
				{ We're done polling. }
				if webTosserAreasBbsRefNum <> -1 then
				begin
					result := FSClose(webTosserAreasBbsRefNum);
					webTosserAreasBbsRefNum := -1;
				end;
				if webTosserGenericExportRefNum <> -1 then
				begin
					result := FSClose(webTosserGenericExportRefNum);
					webTosserAreasBbsRefNum := -1;
				end;

				{ Delete the (partially-received) Generic Import file if it is still open. }
				if webTosserGenericImportRefNum <> -1 then
				begin
					result := FSClose(webTosserGenericImportRefNum);
					webTosserGenericImportRefNum := -1;
					result := FSDelete(Concat(Mailer^^.GenericPath, 'Generic Import'), 0);
				end;

				shouldPollWebTosser := false;
				arePollingWebTosser := false;
			end;
		end;
	end;

end.