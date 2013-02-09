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
import com.gemioli.io.events.TransportEvent;
import com.gemioli.io.Transport;
import nme.events.Event;
import nme.events.HTTPStatusEvent;
import nme.events.IOErrorEvent;
import nme.net.URLLoader;
import nme.net.URLRequest;
import nme.net.URLRequestMethod;

class XHRPollingTransport extends Transport
{
	public function new(host : String, port : String, secure : Bool, sessionId : String) 
	{
		super(host, port, secure, sessionId);
		name = "xhr-polling";
		_url = (_secure ? "https://" : "http://") + _host + ":" + _port + "/socket.io/1/xhr-polling/" + _sessionId + "/?t=";
		_messagesBuffer = new Array<String>();
	}
	
	override public function send(message : String) : Void
	{
		_messagesBuffer.push(message);
		nextSend();
	}
	
	override public function open() : Void
	{
		if (_recvLoader != null)
			return;
		
		_recvRequest = new URLRequest();
		_recvRequest.method = URLRequestMethod.GET;
		_recvLoader = new URLLoader();
		_recvLoader.addEventListener(Event.COMPLETE, onRecvComplete);
		_recvLoader.addEventListener(HTTPStatusEvent.HTTP_STATUS, onRecvStatus);
		_recvLoader.addEventListener(IOErrorEvent.IO_ERROR, onRecvError);
		
		_sendRequest = new URLRequest();
		_sendRequest.method = URLRequestMethod.POST;
		_sendLoader = new URLLoader();
		_sendLoader.addEventListener(HTTPStatusEvent.HTTP_STATUS, onSendStatus);
		_sendLoader.addEventListener(IOErrorEvent.IO_ERROR, onSendError);
		
		nextRecv();
		
		dispatchEvent(new TransportEvent(TransportEvent.OPENED));
	}
	
	override public function close() : Void
	{	
		if (_recvLoader != null)
		{
			_recvLoader = null;
		}
		if (_sendLoader != null)
		{
			_sendLoader = null;
		}
		dispatchEvent(new TransportEvent(TransportEvent.CLOSED));
	}
	
	private function nextRecv() : Void
	{
		if (_recvLoader != null)
		{
			_recvRequest.url = _url + Transport.counter;
			_recvLoader.load(_recvRequest);
		}
	}
	
	private function onRecvComplete(event : Event) : Void
	{
		if (_recvLoader != null)
		{
			decode(event.target.data);
			nextRecv();
		}
	}
	
	private function onRecvStatus(event : HTTPStatusEvent) : Void
	{
		if (event.status != 200 && _recvLoader != null)
			close();
	}
	
	private function onRecvError(event : IOErrorEvent) : Void
	{
		if (_recvLoader != null)
			close();
	}
	
	private function nextSend() : Void
	{
		if (_sendLoader == null)
			// Closed
			return;
		if (_sendLoader.hasEventListener(Event.COMPLETE))
			// Sending in progress
			return;
		if (_messagesBuffer.length == 0)
			// Nothing to send
			return;
		_sendRequest.url = _url + Transport.counter;
		_sendRequest.data = encode(_messagesBuffer);
		_messagesBuffer.splice(0, _messagesBuffer.length);
		_sendLoader.addEventListener(Event.COMPLETE, onSendComplete);
		_sendLoader.load(_sendRequest);
	}
	private function onSendComplete(event : Event) : Void
	{
		if (_sendLoader != null)
		{
			_sendLoader.removeEventListener(Event.COMPLETE, onSendComplete);
			nextSend();
		}
	}
	
	private function onSendStatus(event : HTTPStatusEvent) : Void
	{
		if (event.status != 200 && _sendLoader != null)
			close();
	}
	
	private function onSendError(event : IOErrorEvent) : Void
	{
		if (_sendLoader != null)
			close();
	}
	
	private var _url : String;
	private var _recvRequest : URLRequest;
	private var _recvLoader : URLLoader;
	private var _sendRequest : URLRequest;
	private var _sendLoader : URLLoader;
	private var _messagesBuffer : Array<String>;
}