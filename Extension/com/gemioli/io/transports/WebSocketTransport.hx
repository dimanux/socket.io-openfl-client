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

package com.gemioli.io.transports;

import com.gemioli.io.net.WebSocket;
import com.gemioli.io.Transport;
import com.gemioli.io.events.TransportEvent;

/**
 * ...
 * @author dimanux
 */

class WebSocketTransport extends Transport
{
	public function new(host : String, port : String, secure : Bool, sessionId : String, query : String)
	{
		super(host, port, secure, sessionId);
		name = "websocket";
        var queryPart = if (query != null && query.length > 0) '&'+query else '';
		_url = (_secure ? "wss://" : "ws://") + _host + (_port == "" ? (_secure ? "443" : ":80") : (":" + _port)) + "/socket.io/1/websocket/" + _sessionId + "/?t=" + Transport.counter + queryPart;
	}
	
	override public function send(message : String) : Void
	{
		if (_socket != null)
			_socket.send(message);
	}
	
	override public function open() : Void
	{
		if (_socket != null)
			return;
		_socket = new WebSocket(_url);
		_socket.onopen = onOpen;
		_socket.onmessage = onMessage;
		_socket.onclose = onClose;
		_socket.onerror = onError;
		#if !js
		_socket.connect();
		#end
	}
	
	override public function close() : Void
	{
		if (_socket == null)
			return;
		_socket.close();
		_socket = null;
	}
	
	private function onMessage(event : Dynamic) : Void
	{
		if (_socket != null)
			decode(event.data);
	}
	
	private function onOpen(event : Dynamic) : Void
	{
		if (_socket != null)
			dispatchEvent(new TransportEvent(TransportEvent.OPENED));
	}
	
	private function onClose(event : Dynamic) : Void
	{
		if (_socket != null)
		{
			trace("WebSocket transport closed: [" + event.code + "] " + event.reason);
			dispatchEvent(new TransportEvent(TransportEvent.CLOSED));
		}
	}
	
	private function onError(event : Dynamic) : Void
	{
		if (_socket != null)
			trace("WebSocket transport error: " + event.message);
	}
	
	private var _url : String;
	private var _socket : WebSocket;
}