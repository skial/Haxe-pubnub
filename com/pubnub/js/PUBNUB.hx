/**
 * ...
 * @author Skial Bainn
 */

package com.pubnub.js;

@:native('PUBNUB')
extern class PUBNUB {
	
	static public function __init__():Void untyped{
		window['PUBNUB'] = PUBNUB;
	}
	
	/**
	 * 
	 * @param	options	-	takes an anonymous object eg { channel:my_channel }
	 * @param	?handler
	 */
	public static function subscribe(options:Dynamic, ?handler:Dynamic):Void;
	
	/**
	 * 
	 * @param	options	-	takes an anonymous object eg {channel:my_channel, message:your_message }
	 * @param	?handler
	 */
	public static function publish(options:Dynamic, ?handler:Dynamic):Void;
	
}