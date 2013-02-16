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

package com.gemioli;


import nme.display.Sprite;
import nme.display.StageAlign;
import nme.display.StageScaleMode;
import nme.events.Event;
import nme.Lib;

import com.gemioli.io.Socket;
import com.gemioli.io.events.SocketEvent;

class ExtensionTest extends Sprite
{
	public function new()
	{	
		super();
		addEventListener(Event.ADDED_TO_STAGE, init);
	}
	
	private function init(event : Event) : Void
	{
		removeEventListener(Event.ADDED_TO_STAGE, init);
		addEventListener(Event.ENTER_FRAME, onUpdate);
		Lib.current.graphics.beginFill(0x000000);
		Lib.current.graphics.drawRect(0, 0, Lib.current.stage.stageWidth, Lib.current.stage.stageHeight);
		Lib.current.graphics.endFill();
		graphics.beginFill(0xffffff);
		graphics.drawRect( -20, -20, 40, 40);
		graphics.endFill();
		
		_socket = new Socket("http://localhost:8080");
		//_socket = new Socket("http://socketioserver-dimanux.dotcloud.com");
		_socket.addEventListener(SocketEvent.CONNECTING, function(event : SocketEvent) : Void {
			trace("Connecting...");
		});
		_socket.addEventListener(SocketEvent.CONNECT, function(event : SocketEvent) : Void {
			trace("Connected");
		});
		_socket.addEventListener(SocketEvent.CONNECT_FAILED, function(event : SocketEvent) : Void {
			trace("Connect failed");
		});
		_socket.addEventListener(SocketEvent.DISCONNECTING, function(event : SocketEvent) : Void {
			trace("Disconnecting...");
		});
		_socket.addEventListener(SocketEvent.DISCONNECT, function(event : SocketEvent) : Void {
			trace("Disconnected");
		});
		_socket.addEventListener(SocketEvent.ERROR, function(event : SocketEvent) : Void {
			trace("Error: " + event.args.reason + " " + event.args.advice);
		});
		_socket.addEventListener(SocketEvent.MESSAGE, function(event : SocketEvent) : Void {
			trace("Message: [" + event.args + "]");
			if (event.args == "Hello")
				_socket.send("Hi");
			else if (event.args == "Pong")
				_socket.send("Ping");
		});
		_socket.addEventListener(SocketEvent.RECONNECTING, function(event : SocketEvent) : Void {
			trace("Reconnecting...");
		});
		_socket.addEventListener(SocketEvent.RECONNECT, function(event : SocketEvent) : Void {
			trace("Reconnected");
		});
		_socket.addEventListener(SocketEvent.RECONNECT_FAILED, function(event : SocketEvent) : Void {
			trace("Reconnect failed");
		});
		_socket.addEventListener("ServerEvent", function(event : SocketEvent) : Void {
			trace("Event [ServerEvent] Data [" + event.args[0].name + "]");
			_socket.emit("ClientEventEmpty");
			_socket.emit("ClientEventData", { myData : "Data" } );
			_socket.emit("ClientEventCallback", null, function(data : Dynamic) : Void {
				trace("Callback data[" + data[0] + "]");
				trace("Starting ping-pong...");
				_socket.send("Ping");
			});
		});
		_socket.connect();
		
		_socketChat = new Socket("http://localhost:8080/chat", {transports : ["xhr-polling"]});
		//_socketChat = new Socket("http://socketioserver-dimanux.dotcloud.com/chat", {transports : ["xhr-polling"]} );
		_socketChat.addEventListener(SocketEvent.CONNECTING, function(event : SocketEvent) : Void {
			trace("Chat Connecting...");
		});
		_socketChat.addEventListener(SocketEvent.CONNECT, function(event : SocketEvent) : Void {
			trace("Chat Connected");
			_socketChat.send("Hi chat!");
		});
		_socketChat.addEventListener(SocketEvent.CONNECT_FAILED, function(event : SocketEvent) : Void {
			trace("Chat Connect failed");
		});
		_socketChat.addEventListener(SocketEvent.DISCONNECTING, function(event : SocketEvent) : Void {
			trace("Chat Disconnecting...");
		});
		_socketChat.addEventListener(SocketEvent.DISCONNECT, function(event : SocketEvent) : Void {
			trace("Chat Disconnected");
		});
		_socketChat.addEventListener(SocketEvent.ERROR, function(event : SocketEvent) : Void {
			trace("Chat Error: " + event.args.reason + " " + event.args.advice);
		});
		_socketChat.addEventListener(SocketEvent.MESSAGE, function(event : SocketEvent) : Void {
			trace("Message from chat: [" + event.args + "]");
		});
		_socketChat.addEventListener(SocketEvent.RECONNECTING, function(event : SocketEvent) : Void {
			trace("Chat Reconnecting...");
		});
		_socketChat.addEventListener(SocketEvent.RECONNECT, function(event : SocketEvent) : Void {
			trace("Chat Reconnected");
		});
		_socketChat.addEventListener(SocketEvent.RECONNECT_FAILED, function(event : SocketEvent) : Void {
			trace("Chat Reconnect failed");
		});
		_socketChat.connect();
	}
	
	private function onUpdate(e:Event) : Void
	{
		x = Lib.current.stage.stageWidth / 2;
		y = Lib.current.stage.stageHeight / 2;
		rotation += 1;
	}
	
	private var _socket : Socket;
	private var _socketChat : Socket;
	
	public static function main()
	{
		var stage = Lib.current.stage;
		stage.scaleMode = nme.display.StageScaleMode.NO_SCALE;
		stage.align = nme.display.StageAlign.TOP_LEFT;
		
		Lib.current.addChild(new ExtensionTest ());
	}
}