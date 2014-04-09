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

package com.gemioli.io.events;
#if openfl
	import flash.events.Event;
#else 
	import nme.events.Event;	
#end


class SocketEvent extends Event
{
	public static var CONNECT : String = "connect";
	public static var CONNECTING : String = "connecting";
	public static var DISCONNECT : String = "disconnect";
	public static var DISCONNECTING : String = "disconnecting";
	public static var CONNECT_FAILED : String = "connect_failed";
	public static var ERROR : String = "error";
	public static var MESSAGE : String = "message";
	public static var RECONNECT_FAILED : String = "reconnect_failed";
	public static var RECONNECT : String = "reconnect";
	public static var RECONNECTING : String = "reconnecting";
	
	public var args : Dynamic;
	
	public function new(type : String, args : Dynamic = null)
	{
		super(type, false, false);
		
		this.args = args;
	}
}