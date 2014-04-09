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

package com.gemioli.io;

import com.gemioli.io.events.TransportEvent;
import haxe.Utf8;
import com.gemioli.io.utils.Utils;

#if openfl
	import flash.events.EventDispatcher;
#else 
	import nme.events.EventDispatcher;	
#end


class Transport extends EventDispatcher
{
	public static var counter(get_counter, null) : Int = 0;
	public var name(default, null) : String;
	
	public function new(host : String, port : String, secure : Bool, sessionId : String) 
	{
		super();
		_host = host;
		_port = port;
		_secure = secure;
		_sessionId = sessionId;
		_data = "";
		_dataLength = -1;
		var encodeTerminator = new Utf8();
		encodeTerminator.addChar(0xfffd);
		_encodeTerminator = encodeTerminator.toString();
	}	
	
	public function send(message : String) : Void
	{
	}
	
	public function open() : Void
	{	
	}
	
	public function close() : Void
	{	
	}
	
	private function decode(?data : String) : Void
	{
		if (data != null)
			_data += data;
		while (_data.length > 0)
		{
			if (_dataLength == -1)
			{
				var dataLengthString : String = "";
				for (i in 0...Utf8.length(_data))
				{
					var ch = Utf8.charCodeAt(_data, i);
					if (i == 0)
					{
						if (ch != 0xfffd)
						{
							var message = _data;
							_data = "";
							dispatchEvent(new TransportEvent(TransportEvent.MESSAGE, false, false, message));
							break;
						}
					}
					else if (i > 0)
					{
						if (ch == 0xfffd)
						{
							_data = Utils.Utf8Substr(_data, i + 1, Utf8.length(_data) - i - 1);
							_dataLength = Std.parseInt(dataLengthString);
							break;
						}
						else
							dataLengthString += String.fromCharCode(ch);
					}
				}
			}
			else
			{
				if (_dataLength <= Utf8.length(_data))
				{
					var message = Utils.Utf8Substr(_data, 0, _dataLength);
					_data = Utils.Utf8Substr(_data, _dataLength, Utf8.length(_data) - _dataLength);
					_dataLength = -1;
					dispatchEvent(new TransportEvent(TransportEvent.MESSAGE, false, false, message));
				}
			}
		}
	}
	
	private function encode(messages : Array<String>) : String
	{
		if (messages.length == 1)
			return messages[0];
		var encodedString = "";
		for (message in messages)
			encodedString += (_encodeTerminator + Std.string(message.length) + _encodeTerminator + message);
		return encodedString;
	}
	
	private static function get_counter() : Int
	{
		return counter++;
	}
	
	private var _host : String;
	private var _port : String;
	private var _secure : Bool;
	private var _sessionId : String;
	private var _data : String;
	private var _dataLength : Int;
	private var _encodeTerminator : String;
}