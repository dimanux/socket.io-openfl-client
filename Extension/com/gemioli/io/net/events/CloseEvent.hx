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

package com.gemioli.io.net.events;

#if openfl
	import flash.events.Event;
#else 
	import nme.events.Event;	
#end

class CloseEvent extends Event
{
	public inline static var CLOSE_NORMAL : Int = 1000;
	public inline static var CLOSE_GOING_AWAY : Int = 1001;
	public inline static var CLOSE_PROTOCOL_ERROR : Int = 1002;
	public inline static var CLOSE_UNSUPPORTED : Int = 1003;
	public inline static var CLOSE_NO_STATUS : Int = 1005;
	public inline static var CLOSE_ABNORMAL : Int = 1006;
	public inline static var CLOSE_TOO_LARGE : Int = 1009;
		
	public var code(default, null) : Int;
	public var reason(default, null) : String;
	public var wasClean(default, null) : Bool;
	
	public function new(code : Int, reason : String, wasClean : Bool) 
	{
		super(Event.CLOSE, false, false);
		
		this.code = code;
		this.reason = reason;
		this.wasClean = wasClean;
	}
}