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

#if openfl
	import flash.events.EventDispatcher;
	import flash.events.TimerEvent;
	import flash.utils.Timer;
#else 
	import nme.events.EventDispatcher;
	import nme.events.TimerEvent;
	import nme.utils.Timer;
#end


import haxe.Json;
import haxe.Utf8;


#if !haxe3
typedef Hash<T> = Map<String, T>;
#end


class Socket extends EventDispatcher
{
	public var connectionStatus(default, null) : SocketConnectionStatus;
	public var host(default, null) : String;
	public var port(default, null) : String;
	public var transport(get_transport, null) : String;
	public var secure(default, null) : Bool;
	public var endpoint(default, null) : String;
    public var query(default, null) : String;
	
	private var onceMap:Map<String, Dynamic->Void> = new Map();
	
	public function new(uri : String, options : Dynamic = null) 
	{
		super();
		
		connectionStatus = SocketConnectionStatus.DISCONNECTED;
		var uriParsed = new URLParser(uri);
		secure = uriParsed.secure;
		host = uriParsed.host;
		port = uriParsed.port;
		endpoint = uriParsed.path;
        query = uriParsed.query;
		_uri = uri;
		_buffer = new Array<String>();
		_ack = 0;
		_callbacks = new Map <String, Dynamic->Void > ();
								
		if (options != null)
		{
			if (Std.is(options.reconnect, Bool))
				_reconnect = options.reconnect;
			if (Std.is(options.reconnectionAttempts, Int))
				_maxReconnectionAttempts = options.reconnectionAttempts;
			if (Std.is(options.reconnectionDelay, Int))
				_reconnectionDelay = options.reconnectionDelay;
			if (Std.is(options.connectTimeout, Int))
				_connectTimeout = options.connectTimeout;
			if (Std.is(options.transports, Array))
				_transports = options.transports;
			if (Std.is(options.flashPolicyPort, Int))
				_flashPolicyPort = options.flashPolicyPort;
			if (Std.is(options.flashPolicyUrl, String))
				_flashPolicyUrl = options.flashPolicyUrl;
		}
		
		#if flash
		flash.system.Security.allowDomain("*");
		if (_flashPolicyUrl == null)
			_flashPolicyUrl = "xmlsocket://" + uriParsed.host + ":" + _flashPolicyPort;
		flash.system.Security.loadPolicyFile(_flashPolicyUrl);
		#end
		
		if (_transports == null || _transports.length == 0)
		{
			_transports = new Array<String>();
			_transports.push("websocket");
			_transports.push("xhr-polling");
		}
		
		_connectTimer = new Timer(_connectTimeout);
		_connectTimer.addEventListener(TimerEvent.TIMER, onConnectTimeout);
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
		if (connectionStatus != SocketConnectionStatus.DISCONNECTED)
			return;
		if (_reconnectTimer.running)
		{
			_reconnectTimer.reset();
			_reconnectionAttemptsLeft = _maxReconnectionAttempts;
		}
		connectionStatus = SocketConnectionStatus.CONNECTING;
		if (isReconnecting())
			dispatchEvent(new SocketEvent(SocketEvent.RECONNECTING));
		else
			dispatchEvent(new SocketEvent(SocketEvent.CONNECTING));
		_currentTransports = _transports.copy();
		connectAttempt();
	}
	
	private function connectAttempt() : Void
	{
		_proxy = SocketProxy.connectSocket(this);
		if (_proxy == null)
			tryNextTransport();
		else
		{
			_connectTimer.reset();
			_connectTimer.start();
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
		if (_connectTimer.running)
			_connectTimer.stop();
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
	
	/**
	 * Convenience method for addEventListener
	 * @param	event
	 * @param	callbackFunction
	 */
	public function on(event : String, callbackFunction : Dynamic->Void) : Void
	{
		addEventListener(event, function(e:SocketEvent) {
			socketCallback(e, callbackFunction);
		});
	}
	
	/**
	 * Convenience method that only listens once to the specified event, then removes itself.
	 * WARNING: This method will override any previous uncalled listeners for the specified event name.
	 * @param	event
	 * @param	callbackFunction
	 */
	public function once(event : String, callbackFunction : Dynamic->Void) : Void
	{
		onceMap.set(event, callbackFunction);
		addEventListener(event, onceCallback);
	}
	function onceCallback(e : SocketEvent) : Void
	{
		var event = e.type;
		removeEventListener(event, onceCallback);
		var callbackFunction = onceMap.get(event);
		onceMap.remove(event);
		socketCallback(e, callbackFunction);
	}
	
	function socketCallback(e : SocketEvent, callbackFunction : Dynamic->Void) : Void
	{
		if (Std.is(e.args, Array)) {
			var a:Array<Dynamic> = cast e.args;
			if (a.length == 1) {
				callbackFunction(a[0]);
				return;
			}
		}
		callbackFunction(e.args);
	}
	
	/**
	 * WARNING: Only works for listeners added with once() for now.
	 * @param	event
	 */
	public function removeAllListeners( event : String) : Void {
		removeEventListener(event, onceCallback);
		onceMap.remove(event);
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
	
	private function get_transport() : String
	{
		if (_currentTransports == null || _currentTransports.length == 0)
			return "unknown";
		return _currentTransports[0];
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
						_connectTimer.stop();
						tryNextTransport();
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
					_connectTimer.stop();
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
				var ack : String = message.data;
				var args : Dynamic = null;
				var plus = message.data.indexOf("+");
				if (plus != -1)
				{
					ack = Utils.Utf8Substr(message.data, 0, plus);
					var data = Utils.Utf8Substr(message.data, plus + 1, Utf8.length(message.data) - plus - 1);
					try
					{
						args = Json.parse(data);
					}
					catch (unknown : Dynamic)
					{
					}
				}
				if (_callbacks.exists(ack))
				{
					var func = _callbacks.get(ack);
					_callbacks.remove(ack);
					func(args);
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
	
	private function onConnectTimeout(event : TimerEvent) : Void
	{
		_connectTimer.reset();
		_proxy.removeEventListener(endpoint, onMessage);
		SocketProxy.disconnectSocket(this);
		_proxy = null;
		tryNextTransport();
	}
	
	private function tryNextTransport()
	{
		_currentTransports.shift();
		if (_currentTransports.length > 0)
		{
			connectAttempt();
			return;
		}
		connectionStatus = SocketConnectionStatus.DISCONNECTED;
		if (isReconnecting())
		{
			if (_reconnectionAttemptsLeft == 0)
				dispatchEvent(new SocketEvent(SocketEvent.RECONNECT_FAILED));
			else
				_reconnectTimer.start();
		}
		else
			dispatchEvent(new SocketEvent(SocketEvent.CONNECT_FAILED));
	}
	
	private var _uri : String;
	private var _buffer : Array<String>;
	private var _reconnectionAttemptsLeft : Int;
	private var _proxy : SocketProxy;
	private var _ack : Int;
	private var _callbacks : Map <String,  Dynamic->Void > ;
	private var _connectTimer : Timer;
	private var _reconnectTimer : Timer;
	private var _transports : Array<String>;
	private var _currentTransports : Array<String>;
	
	// Options default values
	private var _connectTimeout : Int = 10000; // ms
	private var _reconnect : Bool = true;
	private var _maxReconnectionAttempts : Int = 10;
	private var _reconnectionDelay : Int = 500; // ms
	private var _flashPolicyPort : Int = 843;
	private var _flashPolicyUrl : String = null;
}