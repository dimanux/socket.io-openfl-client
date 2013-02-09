socket.io-nme-client
====================

Socket.io NME client extension.

###What's done:
<ul>
<li>Interface of socket.io client (v.9) (http://socket.io/#how-to-use)</li>
<li>Multiplexing of sockets</li>
<li>Automatic reconnection of sockets</li>
<li>Only xhr-polling transport</li>
</ul>

###ToDo:
<ul>
<li>websocket transport</li>
<li>flashsocket transport</li>
<li>htmlfile transport</li>
<li>jsonp-polling transport</li>
</ul>

###Tested with HaXe 2.10, NME 3.5.5, HXCPP 2.10.3 on platforms:
<ul>
<li>Flash 11</li>
<li>HTML5</li>
<li>Windows</li>
<li>Android</li>
</ul>

###Folders:
<ul>
<li>Extension - extension code</li>
<li>Project - example project files</li>
<li>Server - simple nodeJS server code (run npm-install.bat, then run.bat)</li>
</ul>

###Example:
See [example](https://github.com/dimanux/socket.io-nme-client/blob/master/Project/Source/com/gemioli/ExtensionTest.hx)


Copyright (c) 2013, Dmitriy Kapustin (dimanux), gemioli.com

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.