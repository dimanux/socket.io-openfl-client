package com.gemioli.io.utils;

#if haxe3
class Int32 {

	var val : Int;

	function new(val : Int) {
		this.val = val;
	}

	public static inline function ofInt(i : Int) : Int32 {
		return new Int32(i);
	}

	public static inline function add(a : Int32, b : Int32) : Int32 {
		return new Int32(a.val + b.val);
	}

	public static inline function toInt(a : Int32) : Int {
		return a.val;
	}

}
#end