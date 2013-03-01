socket.io-nme-client
====================

Socket.io NME client extension.

###What's done:
* Interface of socket.io client (v.9) (http://socket.io/#how-to-use)
* Multiplexing of sockets
* Automatic reconnection of sockets
* WebSocket and xhr-polling transports
* Socket options: transports, reconnect, reconnectionAttempts, reconnectionDelay, connectTimeout, flashPolicyPort, flashPolicyUrl

###ToDo:
* Secure connections
* Optimizations

###Tested with HaXe 2.10, NME 3.5.5, HXCPP 2.10.3, nodejs 0.8.18 (or dotcloud) on platforms:
* Flash 11
* HTML5
* Windows
* Android
* iOS (not tested)
* Blackberry (not tested)

###Folders:
* Extension - extension code
* Project - example project files
* Server - simple nodeJS server code (run npm-install.bat, then run.bat)

###Example:
See [example](https://github.com/dimanux/socket.io-nme-client/blob/master/Project/Source/com/gemioli/ExtensionTest.hx)

###License:

(The MIT License)

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
