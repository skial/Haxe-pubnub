package ;

#if neko
import neko.Lib;
#elseif js
import com.pubnub.js.PUBNUB;
import js.Lib;
#end

/**
 * ...
 * @author Skial Bainn
 */

class Main {
	
	/*
	 * You need to paste code from http://www.pubnub.com/account-javascript-api-include over 
	 * <!-- Paste the url to pubnub js file --> in both publish and subscribe html files in
	 * folder example/client_example
	 */
	
	static function main() {
		#if subscribe
		PUBNUB.subscribe( { channel:'skialbainn' }, incoming);
		trace('started subscribe method. Waiting for messages...');
		#elseif publish
		PUBNUB.publish( { channel:'skialbainn', message:'hello skial bainn' } );
		trace('started publish method. Sending message...');
		#end
	}
	
	#if subscribe
	private static function incoming(message) {
		trace('Receiving message: ' + message);
	}
	#end
	
}