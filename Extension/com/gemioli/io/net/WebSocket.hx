/*
 * Copyright (c) 2013, Dmitriy Kapustin (dimanux), gemioli.com
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

package com.gemioli.io.net;

#if js

@:native("WebSocket")
extern class WebSocket
{
	public inline static var CONNECTING : Int = 0;
	public inline static var OPEN : Int = 1;
	public inline static var CLOSING : Int = 2;
	public inline static var CLOSED : Int = 3;
	
	static function __init__() : Void
	{
		haxe.macro.Compiler.includeFile("com/gemioli/io/net/WebSocket.js");
	}
	
	public var url(default, null) : String;
	public var readyState(default, null) : Int;
	public var extensions(default, null) : String;
	public var protocol(default, null) : String;
	
	public function new(url : String, ?protocols : Dynamic) : Void;
	
	public function send(data : Dynamic) : Void;
	public function close(?code : Int, ?reason : String) : Void;
	
	public var onopen : Dynamic->Void;
	public var onmessage : Dynamic->Void;
	public var onclose : Dynamic->Void;
	public var onerror : Dynamic->Void;
}
#else

import com.gemioli.io.net.events.CloseEvent;
import com.gemioli.io.net.events.MessageEvent;
import com.gemioli.io.utils.BaseCode64;
import com.gemioli.io.utils.URLParser;
import com.gemioli.io.net.events.ErrorEvent;

#if haxe3
	import com.gemioli.io.utils.Int32;
#end

import haxe.io.Eof;

#if (haxe_211 || haxe3)
	import haxe.crypto.Sha1;
#else
	import haxe.SHA1;
#end

#if openfl
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.Lib;
	import flash.utils.ByteArray;
	import flash.events.ProgressEvent;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
#else 
	import nme.events.Event;
	import nme.events.EventDispatcher;
	import nme.Lib;
	import nme.utils.ByteArray;
	import nme.events.ProgressEvent;
	import nme.events.IOErrorEvent;
	import nme.events.SecurityErrorEvent;
#end




#if flash
import flash.net.Socket;
#else // cpp
import sys.net.Host;
//import cpp.vm.Thread;
import haxe.io.Error;

private class Socket extends EventDispatcher
{
	public function new()
	{
		super();
		_socket = new sys.net.Socket();
		_running = false;
	}
	
	public function connect(host : String, port : Int) : Void
	{
		try
		{
			_socket.connect(new Host(host), port);
			_socket.setBlocking(false);
			Lib.current.stage.addEventListener(Event.ENTER_FRAME, socketLoop);
		}
		catch (e : Dynamic)
		{
			dispatchEvent(new IOErrorEvent(IOErrorEvent.IO_ERROR, false, false, "Socket can't connect to host[" + host + ":" + port + "]"));
			return;
		}
		_running = true;
		dispatchEvent(new Event(Event.CONNECT));
	}
	
	public function close() : Void
	{
		if (!_running)
		{
			dispatchEvent(new IOErrorEvent(IOErrorEvent.IO_ERROR, false, false, "Close failed - socket is not opened."));
			return;
		}
		Lib.current.stage.removeEventListener(Event.ENTER_FRAME, socketLoop);
		_socket.close();
		_running = false;
		dispatchEvent(new Event(Event.CLOSE));
	}
	
	public function writeBytes(bytes : ByteArray, offset : Int = 0, length : Int = 0) : Void
	{
		try
		{
			if (!_running)
			{
				dispatchEvent(new IOErrorEvent(IOErrorEvent.IO_ERROR, false, false, "Can't write bytes to socket - socket is closed."));
				return;
			}
			_socket.output.writeBytes(bytes, offset, length == 0 ? bytes.length - offset : length);
		}
		catch (e : Dynamic)
		{
			dispatchEvent(new IOErrorEvent(IOErrorEvent.IO_ERROR, false, false, "Can't write bytes to socket."));
		}
	}
	
	public function writeUTFBytes(value : String) : Void
	{
		try
		{
			if (!_running)
			{
				dispatchEvent(new IOErrorEvent(IOErrorEvent.IO_ERROR, false, false, "Can't write UTFBytes to socket - socket is closed."));
				return;
			}
			_socket.output.writeString(value);				
		}
		catch (e : Dynamic)
		{
			dispatchEvent(new IOErrorEvent(IOErrorEvent.IO_ERROR, false, false, "Can't write UTFBytes to socket."));
		}
	}
	
	public function flush() : Void
	{
		try
		{
			if (!_running)
			{
				dispatchEvent(new IOErrorEvent(IOErrorEvent.IO_ERROR, false, false, "Can't flush socket - socket is closed."));
				return;
			}
			_socket.output.flush();
		}
		catch (e : Dynamic)
		{
			dispatchEvent(new IOErrorEvent(IOErrorEvent.IO_ERROR, false, false, "Can't flush socket."));
		}
	}
	
	public function readBytes(bytes : ByteArray) : Void
	{
		try
		{
			if (!_running)
			{
				dispatchEvent(new IOErrorEvent(IOErrorEvent.IO_ERROR, false, false, "Can't read bytes from socket - socket is closed."));
				return;
			}
			var buf = new ByteArray(1 << 14);
			while (true)
			{
				try
				{
					var length = _socket.input.readBytes(buf, 0, 1 << 14);
					bytes.writeBytes(buf, 0, length);
				}
				catch (e : Eof)
				{
					close();
					break;
				}
				catch (e : Error)
				{
					if (e == Blocked)
						break;
					else
						throw e;
				}
			}
		}
		catch (e : Dynamic)
		{
			dispatchEvent(new IOErrorEvent(IOErrorEvent.IO_ERROR, false, false, "Can't read bytes from socket."));
		}
	}
	
	private function socketLoop(event : Event) : Void
	{
		dispatchEvent(new ProgressEvent(ProgressEvent.SOCKET_DATA));
	}
	
	private var _socket : sys.net.Socket;
	private var _running : Bool;
}
#end

// Thanks to gimite (https://github.com/gimite/web-socket-js)
class WebSocket extends EventDispatcher
{
	public inline static var CONNECTING : Int = 0;
	public inline static var OPEN : Int = 1;
	public inline static var CLOSING : Int = 2;
	public inline static var CLOSED : Int = 3;
	
	public var url(default, null) : String;
	public var readyState(default, null) : Int;
	public var extensions(default, null) : String;
	public var protocol(default, null) : String;
	
	public function new(url : String, ?protocols : Dynamic)
	{
		super();
		this.url = url;
		_protocols = new Array<String>();
		if (Std.is(protocols, String))
			_protocols.push(protocols);
		else if (Std.is(protocols, Array))
			_protocols = _protocols.concat(protocols);
		_uri = URLParser.parse(url);
		_socket = new Socket();
		_socket.addEventListener(ProgressEvent.SOCKET_DATA, onSocketData);
		_socket.addEventListener(Event.CONNECT, onSocketConnect);
		_socket.addEventListener(Event.CLOSE, onSocketClose);
		_socket.addEventListener(IOErrorEvent.IO_ERROR, onSocketIOError);
		_socket.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onSocketSecurityError);
		_buffer = new ByteArray();
		_framesQueue = new Array<WebSocketFrame>();
		_framesPayloadLength = Int32.ofInt(0);
		readyState = CLOSED;
		addEventListener(Event.OPEN, onOpen);
		addEventListener(Event.CLOSE, onClose);
		addEventListener(ErrorEvent.ERROR, onError);
		addEventListener(MessageEvent.MESSAGE, onMessage);
	}
	
	public function connect() : Void
	{
		if (readyState != CLOSED)
		{
			dispatchEvent(new ErrorEvent("Can't connect WebSocket - WebSocket not closed."));
			return;
		}
		readyState = CONNECTING;
		_socket.connect(_uri.host, Std.parseInt(_uri.port));
	}
	
	public function send(data : Dynamic) : Void
	{
		if (Std.is(data, String))
			sendFrame(WebSocketFrame.textFrame(cast(data, String)));
		else if (Std.is(data, ByteArray))
			sendFrame(WebSocketFrame.binaryFrame(cast(data, ByteArray)));
		else
			dispatchEvent(new ErrorEvent("Can't send data of unknown type - String and ByteArray only."));
	}
	
	public function close(?code : Int = CloseEvent.CLOSE_NO_STATUS, ?reason : String = "No reason.") : Void
	{
		if (readyState == CLOSED)
		{
			dispatchEvent(new ErrorEvent("Can't close WebSocket - WebSocket already closed."));
			return;
		}
		if (code == CloseEvent.CLOSE_ABNORMAL || readyState == CONNECTING)
		{
			closeSocket(code, reason, false);
			return;
		}
		if (readyState == OPEN)
		{
			readyState = CLOSING;
			sendFrame(WebSocketFrame.closeFrame(code, reason));
			closeSocket(code, reason, true);
		}
	}
	
	public var onopen : Dynamic->Void;
	public var onmessage : Dynamic->Void;
	public var onclose : Dynamic->Void;
	public var onerror : Dynamic->Void;
	
	private function closeSocket(code : Int, reason : String, wasClean : Bool) : Void
	{
		if (readyState == CLOSED)
			return;
		readyState = CLOSED;
		_buffer = new ByteArray();
		_framesQueue = new Array<WebSocketFrame>();
		_framesPayloadLength = Int32.ofInt(0);
		try
		{
			_socket.close();
		}
		catch (e : Dynamic)
		{
			// Do nothing
		}
		dispatchEvent(new CloseEvent(code, reason, wasClean));
	}
	
	private function sendFrame(frame : WebSocketFrame) : Void
	{
		if (readyState != OPEN && frame.opcode != 0x8)
		{
			dispatchEvent(new ErrorEvent("Can't send data while socket is not opened."));
			return;
		}
		#if flash
		var mask = new ByteArray();
		mask.length = 4;
		#else
		var mask = new ByteArray(4);
		#end
		for (i in 0...mask.length)
			mask[i] = Std.random(256);
		
		var payloadLength = frame.payload.length;
		var data = new ByteArray();
		data.writeByte((frame.fin ? 0x80 : 0x00) | (frame.rsv << 4) | frame.opcode);
		if (payloadLength <  126)
			data.writeByte(0x80 | payloadLength);
		else if (payloadLength < 65536)
		{
			data.writeByte(0x80 | 126);
			data.writeShort(payloadLength);
		}
		else if (payloadLength <= 4294967295)
		{
			data.writeByte(0x80 | 127);
			data.writeUnsignedInt(0);
			data.writeUnsignedInt(payloadLength);
		}
		else
			dispatchEvent(new ErrorEvent("Sended data is too long."));
		data.writeBytes(mask);
		
		#if flash
		var payload = new ByteArray();
		payload.length = payloadLength;
		#else
		var payload = new ByteArray(payloadLength);
		#end
		for (i in 0...payloadLength)
			payload[i] = frame.payload[i] ^ mask[i % 4];
			
		data.writeBytes(payload, 0, payloadLength);
		
		try
		{
			_socket.writeBytes(data);
			_socket.flush();
		}
		catch (e : Dynamic)
		{
			close(CloseEvent.CLOSE_ABNORMAL, "Socket sending error.");
		}
	}
	
	private function onSocketData(event : ProgressEvent) : Void
	{
		if (readyState == CLOSED)
			return;
			
		try
		{
			_socket.readBytes(_buffer);
		}
		catch (e : Dynamic)
		{
			close(CloseEvent.CLOSE_ABNORMAL, "Socket receiving data error.");
		}

		if (readyState == CONNECTING)
		{
			// Read handshake
			var headersDelimeter = _buffer.toString().indexOf("\r\n\r\n");
			if (headersDelimeter >= 0)
			{
				_buffer.position = 0;
				var headersArray : Array<String> = _buffer.readUTFBytes(headersDelimeter).split("\r\n");
				var newBuffer = new ByteArray();
				_buffer.readUTFBytes(4); // pass "\r\n\r\n"
				_buffer.readBytes(newBuffer);
				_buffer = newBuffer;
				
				if (headersArray.length == 0 || headersArray[0].substr(0, 12) != "HTTP/1.1 101")
				{
					close(CloseEvent.CLOSE_ABNORMAL, "Bad response: " + (headersArray.length == 0 ? "No headers." : headersArray[0]));
					return;
				}
				else
					headersArray.shift();
				
				var headers = new Map<String, String>();
				for (headerString in headersArray)
				{
					var delim = headerString.indexOf(":");
					if (delim == -1)
					{
						close(CloseEvent.CLOSE_ABNORMAL, "Bad header: " + headerString);
						return;
					}
					var name = StringTools.trim(headerString.substr(0, delim).toLowerCase());
					var value = StringTools.trim(headerString.substr(delim + 1));
					headers.set(name, value);
				}
				
				if (headers.get("upgrade").toLowerCase() != "websocket")
				{
					close(CloseEvent.CLOSE_ABNORMAL, "Bad upgrade header: " + headers.get("upgrade"));
					return;
				}
				
				if (headers.get("connection").toLowerCase() != "upgrade")
				{
					close(CloseEvent.CLOSE_ABNORMAL, "Bad connection header: " + headers.get("connection"));
					return;
				}

				var requestedKey = headers.get("sec-websocket-accept");
                #if neko
                if (requestedKey != null){
                    requestedKey = requestedKey.substr(0, requestedKey.length-2);
                    _expectedKey = _expectedKey.substr(0, requestedKey.length);
                    }

                #end
				if (requestedKey != _expectedKey)
				{
					close(CloseEvent.CLOSE_ABNORMAL, "Key [" + headers.get("sec-websocket-accept") + "] not equals to expected [" + _expectedKey + "].");
					return;
				}
				
				if (_protocols.length > 0)
				{
					protocol = headers.get("sec-websocket-protocol");
					if (!Lambda.has(_protocols, protocol))
					{
						close(CloseEvent.CLOSE_ABNORMAL, "Server protocol [" + headers.get("sec-websocket-protocol") + "] not equals to exprected protocols [" + _protocols.join(",") + "].");
						return;
					}
				}
				
				readyState = OPEN;
				dispatchEvent(new Event(Event.OPEN));
				parseFrames();
			}
		}
		else
		{
			parseFrames();
		}
	}
	
	private function parseFrames() : Void
	{
		while (WebSocketFrame.isFrameReady(_buffer))
		{
			var frame = WebSocketFrame.readFrame(_buffer);
			var newBuffer = new ByteArray();
			_buffer.readBytes(newBuffer);
			_buffer = newBuffer;
			if (frame.rsv != 0)
				close(CloseEvent.CLOSE_PROTOCOL_ERROR, "RSV must be 0.");
			else if (frame.mask)
				close(CloseEvent.CLOSE_PROTOCOL_ERROR, "Get masked frame from server.");
			else if (frame.overflow)
				close(CloseEvent.CLOSE_TOO_LARGE, "Frame length is too big.");
			else if (frame.opcode >= 0x08 && frame.opcode <= 0x0f && frame.payload.length >= 126)
				close(CloseEvent.CLOSE_TOO_LARGE, "Payload length of control frame more than 125 bytes.");
			else
			{
				switch (frame.opcode)
				{
					case 0x0: // Continuation frame
					{
						if (_framesQueue.length == 0)
						{
							close(CloseEvent.CLOSE_PROTOCOL_ERROR, "Received unexpected continuation frame.");
							continue;
						}
						_framesPayloadLength = Int32.add(_framesPayloadLength, Int32.ofInt(frame.payload.length));
						try
						{
							var messageLength = Int32.toInt(_framesPayloadLength);
						}
						catch (e : Dynamic)
						{
							// Overflow
							close(CloseEvent.CLOSE_TOO_LARGE, "Received message is too big.");
							_framesQueue.splice(0, _framesQueue.length);
							_framesPayloadLength = Int32.ofInt(0);
							continue;
						}
						_framesQueue.push(frame);
						if (frame.fin)
						{
							if (readyState == OPEN) // Dispatch Messages only in OPEN state
							{
								var payload = new ByteArray();
								for (queueFrame in _framesQueue)
									queueFrame.payload.readBytes(payload);
								switch (_framesQueue[0].opcode)
								{
									case 0x1: // Text frame
									{
										dispatchEvent(new MessageEvent(payload.readMultiByte(payload.length, "utf-8")));
									}
									case 0x2: // Binary frame
									{
										dispatchEvent(new MessageEvent(payload));
									}
								}
							}
							_framesQueue.splice(0, _framesQueue.length);
							_framesPayloadLength = Int32.ofInt(0);
						}
					}
					case 0x1: // Text frame
					{
						if (_framesQueue.length != 0)
						{
							close(CloseEvent.CLOSE_PROTOCOL_ERROR, "Received Text Frame during continuation.");
							continue;
						}
						if (frame.fin && (readyState == OPEN))
						{
							dispatchEvent(new MessageEvent(frame.payload.readMultiByte(frame.payload.length, "utf-8")));
						}
						else
							_framesQueue.push(frame);
					}
					case 0x2: // Binary frame
					{
						if (_framesQueue.length != 0)
						{
							close(CloseEvent.CLOSE_PROTOCOL_ERROR, "Received Binary Frame during continuation.");
							continue;
						}
						if (frame.fin && (readyState == OPEN))
						{
							dispatchEvent(new MessageEvent(frame.payload));
						}
						else
							_framesQueue.push(frame);
					}
					case 0x8: // Close frame
					{
						var code  = CloseEvent.CLOSE_NO_STATUS;
						var reason = "";
						if (frame.payload.length >= 2)
						{
							code = frame.payload.readUnsignedShort();
							reason = frame.payload.readMultiByte(frame.payload.bytesAvailable, "utf-8");
						}
						
						if (readyState == CLOSING)
						{
							closeSocket(code, reason, true);
						}
						else
						{
							close(code, reason);
							if (readyState != CLOSED)
								closeSocket(code, reason, true);
						}
					}
					case 0x9: // Ping
					{
						sendFrame(WebSocketFrame.pongFrame(frame.payload));
					}
					case 0xA: // Pong
					{
						
					}
					default:
						close(CloseEvent.CLOSE_PROTOCOL_ERROR, "Received unknown opcode[" + frame.opcode + "].");
				}
			}
		}
	}
	
	private function onSocketConnect(event : Event) : Void
	{
		if (readyState == CLOSED)
			return;
		#if flash
		var requestBytes = new ByteArray();
		requestBytes.length = 16;
		#else
		var requestBytes = new ByteArray(16);
		#end
		for (i in 0...requestBytes.length)
			requestBytes[i] = Std.random(256);
		var requestKey = BaseCode64.encodeByteArray(requestBytes);
		#if !haxe3
			var shaKey = SHA1.encode(requestKey + "258EAFA5-E914-47DA-95CA-C5AB0DC85B11");
		#else
			var shaKey = Sha1.encode(requestKey + "258EAFA5-E914-47DA-95CA-C5AB0DC85B11");
		#end
		requestBytes.clear();
		for (i in 0...Std.int(shaKey.length / 2))
			requestBytes.writeByte(Std.parseInt("0x" + shaKey.substr(i * 2, 2)));		
		_expectedKey = BaseCode64.encodeByteArray(requestBytes);
        var queryPart = if (_uri.query.length > 0) '?'+_uri.query else '';
		var request = "GET " + _uri.path + queryPart + " HTTP/1.1\r\n" +
		"Host: " + _uri.host + (_uri.port == "" ? "" : (":" + _uri.port)) + "\r\n" +
		"Upgrade: websocket\r\n" +
		"Connection: Upgrade\r\n" + 
		"Sec-WebSocket-Key: " + requestKey + "\r\n" + 
		"Origin: " + "socket.io-nme-client" + "\r\n" + // TODO: Get origin from host
		"Sec-WebSocket-Version: 13\r\n";
		if (_protocols.length > 0)
			request += "Sec-WebSocket-Protocol: " + _protocols.join(",") + "\r\n";
		request += "\r\n";
		try
		{
			_socket.writeUTFBytes(request);
			_socket.flush();
		}
		catch (e : Dynamic)
		{
			close(CloseEvent.CLOSE_ABNORMAL, "Socket sending handshake error.");
		}
	}
	
	private function onSocketClose(event : Event) : Void
	{
		if (readyState != CLOSED)
		{
			readyState = CLOSED;
			dispatchEvent(new CloseEvent(CloseEvent.CLOSE_ABNORMAL, "Closed without close handshake.", false));
		}
	}
	
	private function onSocketIOError(event : IOErrorEvent) : Void
	{
		if (readyState != CLOSED)
			close(CloseEvent.CLOSE_ABNORMAL, readyState == CONNECTING ? 
				"Can't connect to url[" + url + "]. IOError [" + event.text + "]." : 
				"Error communicating with url[" + url + "]. IOError [" + event.text + "].");
	}
	
	private function onSocketSecurityError(event : SecurityErrorEvent) : Void
	{
		if (readyState != CLOSED)
		{
			close(CloseEvent.CLOSE_ABNORMAL, readyState == CONNECTING ?
				"Can't connect to url[" + url + "]. SecurityError [" + event.text + "]." :
				"Error communicating with url[" + url + "]. SecurityError [" + event.text + "].");
		}
	}
	
	private function onOpen(event : Event) : Void
	{
		if (onopen != null)
			onopen(event);
	}
	
	private function onClose(event : CloseEvent) : Void
	{
		if (onclose != null)
			onclose(event);
	}
	
	private function onMessage(event : MessageEvent) : Void
	{
		if (onmessage != null)
			onmessage(event);
	}
	
	private function onError(event : ErrorEvent) : Void
	{
		if (onerror != null)
			onerror(event);
	}
	
	private var _protocols : Array<String>;
	private var _uri : URLParser;
	private var _socket : Socket;
	private var _buffer : ByteArray;
	private var _expectedKey : String;
	private var _framesQueue : Array<WebSocketFrame>;
	private var _framesPayloadLength : Int32;
}

private class WebSocketFrame
{
	public var fin : Bool;
	public var rsv : Int;
	public var opcode : Int;
	public var mask : Bool;
	public var overflow : Bool; // Data overflow
	public var payload : ByteArray;
		
	private function new()
	{
		fin = true;
		rsv = 0;
		opcode = 0;
		mask = true;
		overflow = false;
	}
	
	public static function readFrame(buffer : ByteArray) : WebSocketFrame
	{
		var frame = new WebSocketFrame();
		frame.fin = (buffer[0] & 0x80) != 0;
		frame.rsv = (buffer[0] & 0x70) >> 4;
		frame.opcode = buffer[0] & 0x0f;
		frame.mask = (buffer[1] & 0x80) != 0;
		var payloadLength = buffer[1] & 0x7f;
		buffer.position = 2;
		if (payloadLength == 126)
		{
			payloadLength = buffer.readUnsignedShort();
		}
		else if (payloadLength == 127)
		{
			var bigLength = buffer.readUnsignedInt();
			if (bigLength != 0)
				frame.overflow = true;
			payloadLength = buffer.readUnsignedInt();
		}
		frame.payload = new ByteArray();
		buffer.readBytes(frame.payload, 0, payloadLength);
		return frame;
	}
	
	public static function isFrameReady(buffer : ByteArray) : Bool
	{
		var headersLength : Int = 2; // Min length
		if (cast(buffer.length, Int) < headersLength)
			return false;
		var payloadLength : Int = buffer[1] & 0x7f;
		if (payloadLength == 126)
		{
			headersLength = 4;
			if (cast(buffer.length, Int) < headersLength)
				return false;
			buffer.position = 2;
			payloadLength = buffer.readUnsignedShort();
		}
		else if (payloadLength == 127)
		{
			headersLength = 10;
			if (cast(buffer.length, Int) < headersLength)
				return false;
			buffer.position = 2;
			buffer.readUnsignedInt();
			payloadLength = buffer.readUnsignedInt();
		}
		if (cast(buffer.length, Int) < headersLength + payloadLength)
			return false;
		return true;
	}
	
	public static function textFrame(text : String) : WebSocketFrame
	{
		var frame = new WebSocketFrame();
		frame.opcode = 0x1;
		frame.payload = new ByteArray();
		frame.payload.writeUTFBytes(text);
		return frame;
	}
	
	public static function binaryFrame(data : ByteArray) : WebSocketFrame
	{
		var frame = new WebSocketFrame();
		frame.opcode = 0x2;
		frame.payload = new ByteArray();
		frame.payload.writeBytes(data);
		return frame;
	}
	
	public static function pongFrame(ping : ByteArray) : WebSocketFrame
	{
		var frame = new WebSocketFrame();
		frame.opcode = 0xA;
		frame.payload = ping;
		return frame;
	}
	
	public static function closeFrame(code : Int, reason : String) : WebSocketFrame
	{
		var frame = new WebSocketFrame();
		frame.opcode = 0x8;
		frame.payload = new ByteArray();
		if (code != CloseEvent.CLOSE_NO_STATUS)
		{
			frame.payload.writeShort(code);
			frame.payload.writeUTFBytes(reason);
		}
		return frame;
	}
}

#end