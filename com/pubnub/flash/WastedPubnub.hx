/**
 * ...
 * @author Skial Bainn
 */

 /*
  * Based on PubNub python code - http://github.com/pubnub/pubnub-api/blob/master/python/Pubnub.py
  */

package pubnub.flash;

import formats.json.JSON;

import haxe.Http;
import haxe.io.BytesOutput;

class WastedPubnub {
	
	public static inline var ORIGIN:String = 'http://pubnub-prod.appspot.com';
	public static inline var LIMIT:Int = 1700;
	public var PUBLISH_KEY:String;
	public var SUBSCRIBE_KEY:String;
	
	private static var args:Dynamic = { };
	
	// INTERNAL VARIABLES METHOD SUBSCRIBE FLASH WORK AROUND
	
		private var channel:String;
		private var original_channel:String;
		private var handler:Dynamic;
		private var timetoken:String;
		private var server:Dynamic;
		private var listening:Bool;
	
	//

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
		}
		
		// Fail if missing callback (_handler)
		if (_handler == null) {
			throw 'Method subscribe : Missing Callback (param _handler)';
		}
		
		// Capture user input
		channel = this.SUBSCRIBE_KEY + '/' + _channel;
		original_channel = _channel;
		handler = _handler;
		timetoken = (Reflect.hasField(args, 'timetoken') == true) ? new String(args.timetoken) : '0';
		server = (Reflect.hasField(args, 'server') == true) ? args.server : false;
		listening = true;
		
		// Find Server
		findServer();
		
		// Done Listening
		//return true;
	}
	
	private inline function findServer() {
		if (!server) {
			#if !flash9
			var resp_for_server:Dynamic = this._request(ORIGIN + '/pubnub-subscribe', { channel:channel } ).data;
			
			checkServerResponse(resp_for_server);
			#elseif flash9
			this._request(ORIGIN + '/pubnub-subscribe', { channel:channel }, checkServerResponse );
			#end
			
		} 
	}
	
	private inline function checkServerResponse(_response:String) {
		var _resp = JSON.decode(_response.substr(_response.indexOf('(') + 1, _response.length - 1));
		
		if (Reflect.hasField(_resp, 'server') == false) {
			throw 'Method subscribe : ' + args + ' Incorrect API Keys *OR* Out of PubNub Credits\n' +
					'Account API Keys http://www.pubnub.com/account\n' +
					'Buy Credits http://www.pubnub.com/account-buy-credit\n';
		}
		
		server = _resp.server;
		args.server = server;
		
		tryAndCatch();
	}
	
	private inline function tryAndCatch() {
		try {
			// Wait for message
			#if !flash9
			var response = this._request('http://' + server + '/', { channel:channel, timetoken:timetoken } ).data;
			
			searchTryResponse(response);
			#elseif flash9
			this._request('http://' + server + '/', { channel:channel, timetoken:timetoken }, searchTryResponse);
			#end
			
		} catch (e:Dynamic) {
			args.server = false;
			#if !flash9
			subscribe(original_channel, handler);
			#elseif flash9
			new Pubnub(this.PUBLISH_KEY, this.SUBSCRIBE_KEY).subscribe(original_channel, handler);
			#end
		}
	}
	
	private inline function searchTryResponse(_response:Dynamic) {
		var _resp = JSON.decode(_response.substr(_response.indexOf('(') + 1, _response.length - 1));
		
		// If we lost a server connection
		if (!Reflect.hasField(_resp, 'messages') && !_resp.messages[0]) {
			args.server = false;
			#if !flash9
			subscribe(original_channel, handler);
			#elseif flash9
			new Pubnub(this.PUBLISH_KEY, this.SUBSCRIBE_KEY).subscribe(original_channel, handler);
			#end
		}
		
		// If it was a timeout
		if (Reflect.field(_resp, 'messages')[0] == 'xdr.timeout') {
			args.timetoken = _resp.timetoken;
			#if !flash9
			subscribe(original_channel, handler);
			#elseif flash9
			new Pubnub(this.PUBLISH_KEY, this.SUBSCRIBE_KEY).subscribe(original_channel, handler);
			#end
		}
		
		// Run user callback (_handler) and reconnect if user permits
		for (message in cast(_resp.messages, Array<Dynamic>)) {
			listening = handler(message);
		}
		
		// If ok to keep listening
		if (listening == true) {
			args.timetoken = _resp.timetoken;
			#if !flash9
			subscribe(original_channel, handler);
			#elseif flash9
			new Pubnub(this.PUBLISH_KEY, this.SUBSCRIBE_KEY).subscribe(original_channel, handler);
			#end
		}
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
	
	private function _request(_request:String, _args:Dynamic #if flash9 , ?ondata:Dynamic, ?onstatus:Dynamic, ?onerror:Dynamic#end) {
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
		
		#if !flash9
		usock.onData = function (data:String) {
			//response.data = JSON.decode(data.substr(data.indexOf('(') + 1, data.length - 1));
			response.data = data;
			trace('data: ' + response.data);
		}
		
		usock.onStatus = function (status:Int) {
			response.status = status;
			trace('status: ' + response.status);
		}
		
		usock.onError = function (msg:String) {
			response.error = msg;
			trace('error: ' + response.msg);
		}
		#elseif flash9
		usock.onData = ondata;
		#end
		
		usock.request(false);
		
		return response;
	}
	
}