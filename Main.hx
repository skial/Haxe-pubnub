package ;

#if native
import pubnub.haxe.Pubnub;
#end
#if neko
import neko.Lib;
import neko.Sys;
#elseif cpp
import cpp.Lib;
import cpp.Sys;
#elseif flash9
import flash.Lib;
#elseif js
	#if !native
	import com.pubnub.js.PUBNUB;
	#end
import js.Lib;
#end

// cacls [filename] /P -(change permission) [user:permission-type]
// cacls vc100.pdb /P Administrator:F

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
		#if native
		var ser:Pubnub = new Pubnub('pub_key', 'sub_key');
		var target:String = '';
			// set target to compile target
			#if neko
			target = 'NEKO';
			#elseif cpp
			target = 'CPP';
			#end
			#if subscribe
			trace('started ' + target +  ' subscribe method. Waiting for messages...');
			ser.subscribe('skialbainn', incoming);
			#elseif publish
				#if (neko || cpp)
				trace('press enter to continue');
				Sys.command('pause');
				#end
			trace('started ' + target + ' publish method. Sending message...');
			ser.publish('skialbainn', 'hello from the ' + target + ' language!');
			#end
		#elseif js
			#if wrapped
				#if subscribe
				PUBNUB.subscribe( { channel:'skialbainn' }, incoming);
				trace('started javascript wrapped subscribe method. Waiting for messages...');
				#elseif publish
				PUBNUB.publish( { channel:'skialbainn', message:'hello skial bainn' } );
				trace('started javascript wrapped publish method. Sending message...');
				#end
			#end
		#end
	}
	
	private static function incoming(message):Bool {
		trace('Receiving message: ' + message);
		return true;
	}
	
}