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

package com.gemioli.io.utils;

import haxe.Http;

/**
 * It's an URLParser by Mike Cann (http://haxe.org/doc/snip/uri_parser) with security part
 */
class URLParser
{
    // Publics
    public var url : String;
    public var source : String;
    public var protocol : String;
    public var authority : String;
    public var userInfo : String;
    public var user : String;
    public var password : String;
    public var host : String;
    public var port : String;
    public var relative : String;
    public var path : String;
    public var directory : String;
    public var file : String;
    public var query : String;
    public var anchor : String;
	public var secure : Bool;
 
    // Privates
    inline static private function _parts() : Array<String> {
        return ["source","protocol","authority","userInfo","user","password","host","port","relative","path","directory","file","query","anchor"];
    }
 
    public function new(url:String)
    {
        // Save for 'ron
        this.url = url;
 
        // The almighty regexp (courtesy of http://blog.stevenlevithan.com/archives/parseuri)
        var r : EReg = ~/^(?:(?![^:@]+:[^:@\/]*@)([^:\/?#.]+):)?(?:\/\/)?((?:(([^:@]*)(?::([^:@]*))?)?@)?([^:\/?#]*)(?::(\d*))?)(((\/(?:[^?#](?![^?#\/]*\.[^?#\/.]+(?:[?#]|$)))*\/?)?([^?#\/]*))(?:\?([^#]*))?(?:#(.*))?)/;
 
        // Match the regexp to the url
        r.match(url);
 
        // Use reflection to set each part
        for (i in 0..._parts().length)
        {
            Reflect.setField(this, _parts()[i],  r.matched(i));
        }
		
		if (protocol == "https" || protocol == "wss")
			secure = true;
		else
			secure = false;
			
		if (host == null)
			host = "localhost";
		if (port == null || Std.parseInt(port) == null)
			port = "";
    }
 
    public function toString() : String
    {
        var s : String = "For Url -> " + url + "\n";
        for (i in 0..._parts().length)
        {
            s += _parts()[i] + ": " + Reflect.field(this, _parts()[i]) + (i==_parts().length-1?"":"\n");
        }
		s += "\nsecure: " + secure;
        return s;
    }
 
    public static function parse(url:String) : URLParser
    {
        return new URLParser(url);
    }
}