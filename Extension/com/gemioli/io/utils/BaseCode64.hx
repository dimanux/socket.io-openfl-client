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


#if (haxe_211 || haxe3)
	import haxe.crypto.BaseCode;
#else
	import haxe.BaseCode;
#end


import haxe.io.Bytes;
#if openfl
	import flash.utils.ByteArray;
#else 
	import nme.utils.ByteArray;
#end


// Thanks to Richard Janicek (http://haxe.org/forum/thread/3395#nabble-td6608415)
class BaseCode64 {

	private static inline var BASE_64_ENCODINGS = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
	private static inline var BASE_64_PADDING = "=";
	
	public static function encodeByteArray( byteArray : ByteArray ) : String {
		#if flash
		var bytes = Bytes.ofData(byteArray);
		#else
		var bytes = byteArray;
		#end
		var encodings = Bytes.ofString(BASE_64_ENCODINGS);
		var base64 = new BaseCode(encodings).encodeBytes(bytes).toString();
		
		var remainder = base64.length % 4;

		if (remainder > 1) {
			base64 += BASE_64_PADDING;
		}

		if (remainder == 2) {
			base64 += BASE_64_PADDING;
		}
		
		return base64;
	}
	
}
