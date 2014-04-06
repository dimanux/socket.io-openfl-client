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

import com.gemioli.io.events.SocketEvent;
import com.gemioli.io.events.SocketProxyEvent;
import com.gemioli.io.events.TransportEvent;
import com.gemioli.io.Transport;
import com.gemioli.io.transports.WebSocketTransport;
import com.gemioli.io.transports.XHRPollingTransport;
import com.gemioli.io.utils.Utils;
import haxe.Utf8;

#if openfl
	import flash.events.EventDispatcher;
	import flash.events.SecurityErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.HTTPStatusEvent;
#else 
	import nme.events.EventDispatcher;
	import nme.events.SecurityErrorEvent;
	import nme.net.URLLoader;
	import nme.net.URLRequest;
	import nme.net.URLRequestMethod;
	import nme.events.Event;
	import nme.events.IOErrorEvent;
	import nme.events.HTTPStatusEvent;	
#end




class SocketProxy extends EventDispatcher
{
	public var connectionStatus(default, null) : SocketConnectionStatus;
	
	public static function connectSocket(socket : Socket) : SocketProxy
	{
		var proxy = getProxy(socket.host, socket.port, socket.secure, socket.transport, socket.query);
		for (endpoint in proxy._endpoints)
			if (endpoint == socket.endpoint)
				return null;
		proxy._endpoints.push(socket.endpoint);
		proxy.connect();
		return proxy;
	}
	
	public static function disconnectSocket(socket : Socket) : Void
	{
		var proxy = getProxy(socket.host, socket.port, socket.secure, socket.transport, socket.query);
		for (endpoint in proxy._endpoints)
			if (endpoint == socket.endpoint)
			{
				proxy._endpoints.remove(socket.endpoint);
				break;
			}
		if (proxy._endpoints.length == 0)
		{
			_proxies.remove(proxy._name);
			proxy.disconnect();
		}
	}
	
	public function sendMessage(message : String) : Void
	{
		if (connectionStatus == SocketConnectionStatus.CONNECTED && _transport != null)
		{
			_transport.send(message);
		}
	}
	
	private static function getProxy(host : String, port : String, secure : Bool, transport : String, query: String) : SocketProxy
	{
		var name = (secure ? "https" : "http") + "://" + host + (port == "" ? "" : (":" + port)) + "/" + transport;
		if (!_proxies.exists(name))
			_proxies.set(name, new SocketProxy(name, host, port, secure, transport, query));
		return _proxies.get(name);
	}
	
	private function new(name : String, host : String, port : String, secure : Bool, transport : String, query: String)
	{
		super();
		
		_name = name;
		_host = host;
		_port = port;
		_secure = secure;
        _query = query;
		_transportName = transport;
		_endpoints = new Array<String>();
		connectionStatus = SocketConnectionStatus.DISCONNECTED;
		_transport = null;
	}
	
	private function connect() : Void
	{
		if (connectionStatus != SocketConnectionStatus.DISCONNECTED)
			return;
		connectionStatus = SocketConnectionStatus.CONNECTING;
		
		var handshakeRequest = new URLRequest();
		handshakeRequest.url = (_secure ? "https://" : "http://") + _host + (_port == "" ? "" : (":" + _port)) + "/socket.io/1/?t=" + Transport.counter;
		handshakeRequest.method = URLRequestMethod.GET;
		_handshakeLoader = new URLLoader();
		_handshakeLoader.addEventListener(Event.COMPLETE, onHandshake);
		_handshakeLoader.addEventListener(HTTPStatusEvent.HTTP_STATUS, onHandshakeStatus);
		_handshakeLoader.addEventListener(IOErrorEvent.IO_ERROR, onHandshakeError);
		_handshakeLoader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onHandshakeSecurityError);
		_handshakeLoader.load(handshakeRequest);
	}
	
	private function onHandshake(event : Event) : Void
	{
		var responseData : String = event.target.data;
		var responseArray = responseData.split(":");
		if (responseArray.length != 4)
		{
			disconnectEndpoints();
			return;
		}
		_sessionId = responseArray[0];
		_heartbeatTimeout = Std.parseInt(responseArray[1]);
		_closeTimeout = Std.parseInt(responseArray[2]);
		var transports = responseArray[3].split(",");
		for (transport in transports)
			if (transport == _transportName)
			{
				tryTransport();
				return;
			}
		disconnectEndpoints();
	}
	
	private function onHandshakeStatus(event : HTTPStatusEvent) : Void
	{
		if (event.status != 200 && connectionStatus == SocketConnectionStatus.CONNECTING)
		{
			dispatchErrorEvent("Handshake status error [" + event.status + "]", "Check server status.");
			disconnectEndpoints();
		}
	}
	
	private function onHandshakeError(event : IOErrorEvent) : Void
	{
		if (connectionStatus == SocketConnectionStatus.CONNECTING)
		{
			dispatchErrorEvent("Handshake IO error.", "Check connection.");
			disconnectEndpoints();
		}
	}
	
	private function onHandshakeSecurityError(event : SecurityErrorEvent) : Void
	{
		if (connectionStatus == SocketConnectionStatus.CONNECTING)
		{
			dispatchErrorEvent("Handshake security error [" + event.text + "].", "Check flash policy server.");
			disconnectEndpoints();
		}
	}
	
	private function dispatchErrorEvent(reason : String, advice : String) : Void
	{
		var message = "[" + _transportName + "] " + reason + "+" + advice;
		var endpoints = _endpoints.copy();
		for (endpoint in endpoints)
			dispatchEvent(new SocketProxyEvent(endpoint, 7, "", message));
	}
	
	private function disconnectEndpoints() : Void
	{
		connectionStatus = SocketConnectionStatus.DISCONNECTED;
		var endpoints = _endpoints.copy();
		for (endpoint in endpoints)
			dispatchEvent(new SocketProxyEvent(endpoint, 0, "", ""));
	}
	
	private function disconnect() : Void
	{
		if (connectionStatus == SocketConnectionStatus.DISCONNECTED)
			return;
		connectionStatus = SocketConnectionStatus.DISCONNECTING;
		if (_transport != null)
		{
			_transport.close();
		}
	}
	
	private function tryTransport() : Void
	{
		switch (_transportName)
		{
			case "websocket":
				_transport = new WebSocketTransport(_host, _port, _secure, _sessionId, _query);
			case "xhr-polling":
				_transport = new XHRPollingTransport(_host, _port, _secure, _sessionId, _query);
			default:
				{
					disconnectEndpoints();
					return;
				}
		}
		
		_transport.addEventListener(TransportEvent.OPENED, onTransportOpened);
		_transport.addEventListener(TransportEvent.CLOSED, onTransportClosed);
		_transport.addEventListener(TransportEvent.MESSAGE, onTransportMessage);
		_transport.open();
	}
	
	private function onTransportOpened(event : TransportEvent) : Void
	{
		connectionStatus = SocketConnectionStatus.CONNECTED;
	}
	
	private function onTransportClosed(event : TransportEvent) : Void
	{
		_transport.removeEventListener(TransportEvent.OPENED, onTransportOpened);
		_transport.removeEventListener(TransportEvent.CLOSED, onTransportClosed);
		_transport.removeEventListener(TransportEvent.MESSAGE, onTransportMessage);
		_transport = null;
		disconnectEndpoints();
	}
	
	private function onTransportMessage(event : TransportEvent) : Void
	{
		var messageParts = new Array<String>();
		var dotsPosition = -1;
		var lastPosition = 0;
		for (i in 0...3)
		{
			dotsPosition = event.message.indexOf(":", lastPosition);
			if (dotsPosition != -1)
			{
				messageParts.push(Utils.Utf8Substr(event.message, lastPosition, dotsPosition - lastPosition));
				lastPosition = dotsPosition + 1;
			}
		}
		messageParts.push(Utils.Utf8Substr(event.message, lastPosition, Utf8.length(event.message) - lastPosition));
		
		var messageId = Std.parseInt(messageParts[0]);
		if (messageParts.length < 3 || messageId == null)
			// Unknown message
			return;
		if (messageId == 1 && messageParts[2] == "")
		{
			for (endpoint in _endpoints)
				if (endpoint != "")
					sendMessage("1::" + endpoint);
		}
		else if (messageId == 0 && messageParts[2] == "")
		{
			var endpoints = _endpoints.copy();
			for (endpoint in endpoints)
				dispatchEvent(new SocketProxyEvent(endpoint, 0, "", ""));
		} 
		else if (messageId == 2 && messageParts[2] == "") //heartbeat without endpoint
		{
			var endpoints = _endpoints.copy();
			for (endpoint in endpoints)
				dispatchEvent(new SocketProxyEvent(endpoint, Std.parseInt(messageParts[0]), messageParts[1], messageParts.length > 3 ? messageParts[3] : ""));
		}
		dispatchEvent(new SocketProxyEvent(messageParts[2], Std.parseInt(messageParts[0]), messageParts[1], messageParts.length > 3 ? messageParts[3] : ""));
	}
	
	private var _name : String;
	private var _host : String;
	private var _port : String;
    private var _query : String;
	private var _secure : Bool;
	private var _endpoints : Array<String>;
	private var _handshakeLoader : URLLoader;
	private var _transportName : String;
	private var _transport : Transport;
	
	private var _sessionId : String;
	private var _heartbeatTimeout : Int;
	private var _closeTimeout : Int;
	
	// Static proxies
	private static var _proxies : Map<String, SocketProxy> = new Map<String, SocketProxy>();
}