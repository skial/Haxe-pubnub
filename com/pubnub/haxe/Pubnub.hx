/**
 * ...
 * @author Skial Bainn
 */

 /*
  * Based on PubNub python code - http://github.com/pubnub/pubnub-api/blob/master/python/Pubnub.py
  */

package pubnub.haxe;

#if !cpp
import chx.formats.json.JSON;
#else
import formats.json.JSON;
#end

import haxe.Http;
import haxe.io.BytesOutput;

class Pubnub {
	
	public static inline var ORIGIN:String = 'http://pubnub-prod.appspot.com';
	public static inline var LIMIT:Int = 1700;
	public var PUBLISH_KEY:String;
	public var SUBSCRIBE_KEY:String;
	
	private static var args:Dynamic = { };

	public function new(publish_key:String, subscribe_key:String) {
		this.PUBLISH_KEY = publish_key;
		this.SUBSCRIBE_KEY = subscribe_key;
	}
	
	public function publish(_channel:String, _message:String):Dynamic {
		// Fail is bad input
		if (_channel == null || _message == null) {
			throw 'Method publish : Missing Channel or Message';
			return false;
		}
		
		// Capture user input
		var channel:String = this.SUBSCRIBE_KEY + '/' + _channel;
		var message:String = JSON.encode(_message);
		
		// Fail if message to long
		if (message.length > LIMIT) {
			throw 'Method publish : Message TOO LONG ( ' + LIMIT + ' LIMIT)';
			return false;
		}
		
		// Send message
		var response = this._request(ORIGIN + '/pubnub-publish', { 
				publish_key:this.PUBLISH_KEY,
				channel:channel,
				message:message
			}
		);
		
		return response;
		
	}
	
	public function subscribe(_channel:String, _handler:Dynamic) {
		// Fail is missing channel
		if (_channel == null) {
			throw 'Method subscribe : Missing Channel';
			return false;
		}
		
		// Fail if missing callback (_handler)
		if (_handler == null) {
			throw 'Method subscribe : Missing Callback (param _handler)';
			return false;
		}
		
		// Capture user input
		var channel:String = this.SUBSCRIBE_KEY + '/' + _channel;
		var handler:Dynamic = _handler;
		var timetoken:String = (Reflect.hasField(args, 'timetoken') == true) ? new String(args.timetoken) : '0';
		var server:Dynamic = (Reflect.hasField(args, 'server') == true) ? args.server : false;
		var listening:Bool = true;
		
		// Find Server
		if (!server) {
			var resp_for_server = this._request(ORIGIN + '/pubnub-subscribe', { channel:channel } ).data;
			
			if (Reflect.hasField(resp_for_server, 'server') == false) {
				throw 'Method subscribe : ' + args + ' Incorrect API Keys *OR* Out of PubNub Credits\n' +
						'Account API Keys http://www.pubnub.com/account\n' +
						'Buy Credits http://www.pubnub.com/account-buy-credit\n';
				return false;
			}
			
			server = resp_for_server.server;
			args.server = server;
		}
		
		try {
			// Wait for message
			var response = this._request('http://' + server + '/', {
				channel:channel,
				timetoken:timetoken
			}).data;
			
			// If we lost a server connection
			if (!Reflect.hasField(response, 'messages') && !response.messages[0]) {
				args.server = false;
				return this.subscribe(_channel, _handler);
			}
			
			// If it was a timeout
			if (Reflect.field(response, 'messages')[0] == 'xdr.timeout') {
				args.timetoken = response.timetoken;
				return this.subscribe(_channel, _handler);
			}
			
			// Run user callback (_handler) and reconnect if user permits
			for (message in response.messages) {
				listening = handler(message);
			}
			
			// If ok to keep listening
			if (listening) {
				args.timetoken = response.timetoken;
				return this.subscribe(_channel, _handler);
			}
		} catch (e:Dynamic) {
			args.server = false;
			return this.subscribe(_channel, _handler);
		}
		
		// Done Listening
		return true;
	}
	
	public function history(_channel:String, ?_limit:Int = 10):Dynamic {
		if (_channel == null) {
			throw 'Method history : Missing Channel';
			return false;
		}
		
		// Capture User Input Channel
		var channel:String = this.SUBSCRIBE_KEY + '/' + _channel;
		
		// Get History
		var response = this._request(ORIGIN + '/pubnub-history', {
			channel:channel,
			limit:_limit
		}).data;
		
		return response.messages;
	}
	
	private function _request(_request:String, _args:Dynamic) {
		// Give _args unique time stamp
		Reflect.setField(_args, 'unique', Date.now().toString());
		
		// Format URL params
		var params:Array<String> = [];
		var args:Array<Dynamic> = Reflect.fields(_args);
		
		for (arg in args) {
			params.unshift(
								StringTools.urlEncode(Std.string(arg))
								+ '=' + 
								StringTools.urlEncode(Std.string(Reflect.field(_args, arg)))
			); 
		}
		
		// Append params
		var request:String = _request + '?' + params.join('&');
		
		// Send request expecting JSONP response
		var usock = new Http(request);
		var response:Dynamic = { }
		
		usock.onData = function (data:String) {
			response.data = JSON.decode(data.substr(data.indexOf('(')+1, data.length-1));
		}
		
		usock.onStatus = function (status:Int) {
			response.status = status;
		}
		
		usock.onError = function (msg:String) {
			response.error = msg;
		}
		
		usock.request(false);
		
		return response;
	}
	
}