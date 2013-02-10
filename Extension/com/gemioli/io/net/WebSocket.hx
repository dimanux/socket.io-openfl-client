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
	static function __init__() : Void
	{
		haxe.macro.Tools.includeFile("com/gemioli/io/net/WebSocket.js");
	}
	
	public function new(url : String) : Void;
	
	public function send(data : String) : Void;
	public function close() : Void;
	
	public var onopen : Void->Void;
	public var onmessage : {data : String}->Void;
	public var onclose : Void->Void;
	public var onerror : Void->Void;
}
#else

import nme.Lib;
import nme.events.Event;
import nme.events.EventDispatcher;

class WebSocket extends EventDispatcher
{
	public function new(url : String)
	{
		super();
		Lib.current.addEventListener(Event.ENTER_FRAME, onEnterFrame);
	}
	
	private function onEnterFrame(event : Event) : Void
	{
		Lib.current.removeEventListener(Event.ENTER_FRAME, onEnterFrame);
		close();
	}
	
	public function send(data : String) : Void
	{
		
	}
	
	public function close() : Void
	{
		if (onclose != null)
			onclose();
	}
	
	public var onopen : Void->Void;
	public var onmessage : {data : String}->Void;
	public var onclose : Void->Void;
	public var onerror : Void->Void;
}
#end