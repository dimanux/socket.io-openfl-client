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

import com.gemioli.io.events.SocketProxyEvent;
import com.gemioli.io.SocketProxy;
import com.gemioli.io.events.SocketEvent;
import com.gemioli.io.utils.URLParser;
import com.gemioli.io.utils.Utils;
import nme.events.EventDispatcher;
import haxe.Json;
import haxe.Utf8;
import nme.events.TimerEvent;
import nme.utils.Timer;

class Socket extends EventDispatcher
{
	public var connectionStatus(default, null) : SocketConnectionStatus;
	public var host(default, null) : String;
	public var port(default, null) : String;
	public var secure(default, null) : Bool;
	public var endpoint(default, null) : String;
	
	public function new(uri : String, options : Dynamic = null) 
	{
		super();
		
		connectionStatus = SocketConnectionStatus.DISCONNECTED;
		var uriParsed = new URLParser(uri);
		host = (uriParsed.host == null ? "localhost" : uriParsed.host);
		port = (uriParsed.port == null ? "80" : uriParsed.port);
		secure = uriParsed.secure;
		endpoint = uriParsed.path;
		_uri = uri;
		_buffer = new Array<String>();
		_ack = 0;
		_callbacks = new Hash < Dynamic->Void > ();
						
		if (options != null)
		{
			if (Std.is(options.reconnect, Bool))
				_reconnect = options.reconnect;
			if (Std.is(options.reconnectionAttempts, Int))
				_maxReconnectionAttempts = options.reconnectionAttempts;
			if (Std.is(options.reconnectionDelay, Int))
				_reconnectionDelay = options.reconnectionDelay;
		}
		
		_reconnectionAttemptsLeft = _maxReconnectionAttempts;
		_reconnectTimer = new Timer(_reconnectionDelay);
		_reconnectTimer.addEventListener(TimerEvent.TIMER, onReconnect);
	}
	
	private function isReconnecting() : Bool
	{
		return _reconnectionAttemptsLeft != _maxReconnectionAttempts;
	}
	
	public function connect() : Void
	{
		if (_reconnectTimer.running)
		{
			_reconnectTimer.reset();
			_reconnectionAttemptsLeft = _maxReconnectionAttempts;
		}
		if (connectionStatus != SocketConnectionStatus.DISCONNECTED)
			return;
		connectionStatus = SocketConnectionStatus.CONNECTING;
		if (isReconnecting())
			dispatchEvent(new SocketEvent(SocketEvent.RECONNECTING));
		else
			dispatchEvent(new SocketEvent(SocketEvent.CONNECTING));
		
		_proxy = SocketProxy.connectSocket(this);
		if (_proxy == null)
		{
			connectionStatus = SocketConnectionStatus.DISCONNECTED;
			if (isReconnecting())
			{
				_reconnectTimer = new Timer(_reconnectionDelay);
				_reconnectTimer.addEventListener(TimerEvent.TIMER_COMPLETE, onReconnect);
			}
			else
				dispatchEvent(new SocketEvent(SocketEvent.CONNECT_FAILED));
		}
		else
		{
			_proxy.addEventListener(endpoint, onMessage);
			if (_proxy.connectionStatus == SocketConnectionStatus.CONNECTED)
				_proxy.sendMessage("1::" + endpoint);
		}
	}
	
	public function disconnect() : Void
	{
		if (_reconnectTimer.running)
		{
			_reconnectTimer.reset();
			_reconnectionAttemptsLeft = _maxReconnectionAttempts;
		}
		if (connectionStatus == SocketConnectionStatus.DISCONNECTED || _proxy == null)
			return;
		connectionStatus = SocketConnectionStatus.DISCONNECTING;
		dispatchEvent(new SocketEvent(SocketEvent.DISCONNECTING));
		if (endpoint != "")
		{
			_proxy.sendMessage("0::" + endpoint);
		}
		_proxy.removeEventListener(endpoint, onMessage);
		SocketProxy.disconnectSocket(this);
		_proxy = null;
		connectionStatus = SocketConnectionStatus.DISCONNECTED;
		dispatchEvent(new SocketEvent(SocketEvent.DISCONNECT));
	}
	
	public function send(message : Dynamic, ?callbackFunction : Dynamic->Void = null) : Void
	{
		if (Std.is(message, String))
		{
			if (callbackFunction != null)
			{
				var ack = Std.string(_ack++);
				_callbacks.set(ack, callbackFunction);
				_buffer.push("3:" + ack + "+:" + endpoint + ":" + Std.string(message));
			}
			else
				_buffer.push("3::" + endpoint + ":" + Std.string(message));
		}
		else
		{
			if (callbackFunction != null)
			{
				var ack = Std.string(_ack++);
				_callbacks.set(ack, callbackFunction);
				_buffer.push("4:" + ack + "+:" + endpoint + ":" + Json.stringify(message));
			}
			else
				_buffer.push("4::" + endpoint + ":" + Json.stringify(message));
		}
		sendMessages();
	}
	
	public function emit(event : String, ?data : Dynamic = null, ?callbackFunction : Dynamic->Void = null) : Void
	{
		if (callbackFunction != null)
		{
			var ack = Std.string(_ack++);
			_callbacks.set(ack, callbackFunction);
			_buffer.push("5:" + ack + "+:" + endpoint + ":" + Json.stringify( { "name" : event, "args" : data } ));
		}
		else
			_buffer.push("5::" + endpoint + ":" + Json.stringify( { "name" : event, "args" : data } ));
		sendMessages();
	}
	
	private function sendMessages() : Void
	{
		if (connectionStatus == SocketConnectionStatus.CONNECTED)
		{
			for (message in _buffer)
				_proxy.sendMessage(message);
			_buffer.splice(0, _buffer.length);
		}
	}
	
	private function onMessage(message : SocketProxyEvent) : Void
	{
		switch (message.id)
		{
			case 0: // disconnect
			{
				_proxy.removeEventListener(endpoint, onMessage);
				SocketProxy.disconnectSocket(this);
				_proxy = null;
				
				switch (connectionStatus)
				{
					case SocketConnectionStatus.CONNECTING:
					{
						connectionStatus = SocketConnectionStatus.DISCONNECTED;
						if (isReconnecting())
						{
							if (_reconnectionAttemptsLeft == 0)
								dispatchEvent(new SocketEvent(SocketEvent.RECONNECT_FAILED));
							else
							{
								_reconnectTimer.start();
							}
						}
						else
							dispatchEvent(new SocketEvent(SocketEvent.CONNECT_FAILED));
					}
					case SocketConnectionStatus.CONNECTED:
					{
						connectionStatus = SocketConnectionStatus.DISCONNECTED;
						dispatchEvent(new SocketEvent(SocketEvent.DISCONNECT));
						
						if (_reconnect && _maxReconnectionAttempts > 0)
						{
							_reconnectionAttemptsLeft = _maxReconnectionAttempts;
							_reconnectTimer.start();
						}
					}
					default: null;
				}
			}
			case 1: // connect
			{
				if (connectionStatus == SocketConnectionStatus.CONNECTING)
				{
					connectionStatus = SocketConnectionStatus.CONNECTED;
					if (isReconnecting())
						dispatchEvent(new SocketEvent(SocketEvent.RECONNECT));
					else
						dispatchEvent(new SocketEvent(SocketEvent.CONNECT));
				}
			}
			case 2: // heartbeat
			{
				_proxy.sendMessage("2::");
			}
			case 3: // message
			{
				dispatchEvent(new SocketEvent(SocketEvent.MESSAGE, message.data));
			}
			case 4: // Json message
			{
				var data : Dynamic = null;
				try
				{
					data = Json.parse(message.data);
				}
				catch (unknown : Dynamic)
				{
					data = null;
				}
				if (data != null)
					dispatchEvent(new SocketEvent(SocketEvent.MESSAGE, data));
			}
			case 5: // Event
			{
				var data : Dynamic = null;
				try
				{
					data = Json.parse(message.data);
				}
				catch (unknown : Dynamic)
				{
					data = null;
				}
				if (data != null)
					dispatchEvent(new SocketEvent(data.name, data.args));
			}
			case 6: // ACK
			{
				var plus = message.data.indexOf("+");
				if (plus != -1)
				{
					var ack = Utils.Utf8Substr(message.data, 0, plus);
					var data = Utils.Utf8Substr(message.data, plus + 1, Utf8.length(message.data) - plus - 1);
					if (_callbacks.exists(ack))
					{
						var func = _callbacks.get(ack);
						_callbacks.remove(ack);
						var args = null;
						try
						{
							args = Json.parse(data);
						}
						catch (unknown : Dynamic)
						{
							args = null;
						}
						func(args);
					}
				}
			}
			case 7: // Error
			{
				var plus = message.data.indexOf("+");
				if (plus != -1)
				{
					var reasonString = Utils.Utf8Substr(message.data, 0, plus);
					var adviceString = Utils.Utf8Substr(message.data, plus + 1, Utf8.length(message.data) - plus - 1);
					dispatchEvent(new SocketEvent(SocketEvent.ERROR, {reason : reasonString, advice : adviceString}));
				}
			}
		}
	}
	
	private function onReconnect(event : TimerEvent) : Void
	{
		_reconnectTimer.reset();
		_reconnectionAttemptsLeft--;
		connect();
	}
	
	private var _uri : String;
	private var _buffer : Array<String>;
	private var _reconnectionAttemptsLeft : Int;
	private var _proxy : SocketProxy;
	private var _ack : Int;
	private var _callbacks : Hash < Dynamic->Void > ;
	private var _reconnectTimer : Timer;
	
	// Options default values
	private var _reconnect : Bool = true;
	private var _maxReconnectionAttempts : Int = 10;
	private var _reconnectionDelay : Float = 500; // ms
}