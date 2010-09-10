/**
 * ...
 * @author Skial Bainn
 */

package pubnub.haxe;

#if !cpp
import chx.formats.json.JSON;
#else
import formats.json.JSON;
#end
import haxe.Http;
import haxe.io.BytesOutput;

using StringTools;

class Pubnub {
	
	private static inline var ORIGIN:String = 'http://pubnub-prod.appspot.com';
	private static inline var LIMIT:Int = 1700;
	private static var PUBLISH_KEY:String = '';
	private static var SUBSCRIBE_KEY:String = '';
	
	private static var _hash_:Hash<Dynamic> = new Hash<Dynamic>();
	
	/**
	 * Init the Pubnub Client API
	 * @param	publish_key		-	required key to send messages
	 * @param	subscribe_key	-	required key to receive messages
	 */
	public function new(publish_key:String, subscribe_key:String) {
		PUBLISH_KEY = publish_key;
		SUBSCRIBE_KEY = subscribe_key;
	}
	
	/**
	 * Publish
	 * 
	 * Send a message to a channel
	 * @param	channel
	 * @param	message
	 * @return	either String or Int
	 */
	public function publish(channel:String, message:String):Dynamic {
		// Capture User Input
		var _channel_:String = SUBSCRIBE_KEY + '/' + channel;
		var _message_:String = JSON.encode(message);
		
		// Fail if message too long
		if (_message_.length > LIMIT) {
			throw 'Message TOO LONG (' + LIMIT + ' LIMIT)';
		}
		
		// Send message
		var _hash_:Hash<Dynamic> = new Hash<Dynamic>();
		_hash_.set('publish_key', PUBLISH_KEY);
		_hash_.set('channel', _channel_);
		_hash_.set('message', _message_);
		var _resp_:Dynamic = this._request(ORIGIN + '/pubnub-publish', _hash_);
		
		return _resp_;
	}
	
	/**
	 * Subscribe
	 * 
	 * This is blocking
	 * Listen for a message on a channel
	 * 
	 * @param	channel
	 * @param	handler	-	handler must return a Bool value, true to continue listening, false to cut connection
	 */
	public function subscribe(channel:String, handler:Dynamic) {
		_hash_.set('channel', channel);
		_hash_.set('callback', handler);
		var _channel_:String 	= SUBSCRIBE_KEY + '/' + channel;
		var _timetoken_:String 	= (_hash_.exists('timetoken')==true)	? new String(_hash_.get('timetoken')) 	: '0'; 
		// new String() - above - is needed to get around neko error (__s)
		var _server_:String		= (_hash_.exists('server') == true)		? _hash_.get('server')		: null;
		var _continue_:Bool 		= true;
		var _resp_:Dynamic;
		
		// Find server
		if (_server_ == null) {
			var __hash__:Hash<Dynamic> = new Hash<Dynamic>();
			__hash__.set('channel', _channel_);
			_resp_ = this._request(ORIGIN + '/pubnub-subscribe', __hash__);
			
			if (_resp_.data.server == null) {
				trace('Incorrect API Keys *OR* Out of PubNub Credits');
				trace('Account API Keys http://www.pubnub.com/account');
				trace('Buy Credits http://www.pubnub.com/account-buy-credit');
				return false;
			}
			
			_server_ = _resp_.data.server;
			_hash_.set('server', _server_);
		}
		
		try {
			// Wait for message
			var ___hash___:Hash<Dynamic> = new Hash<Dynamic>();
			___hash___.set('channel', _channel_);
			___hash___.set('timetoken', _timetoken_);
			
			var __resp__:Dynamic 				= this._request('http://' + _server_ + '/', ___hash___);
			var _messages_:Array<Dynamic> 	= __resp__.data.messages;
			var __timetoken__:String 			= __resp__.data.timetoken;
			
			// If we lost a server connection
			if (_messages_[0] == null) {
				_hash_.remove('server');
				subscribe(channel, handler);
			}
			
			// If it was a timeout
			if (_messages_[0] == 'xdr.timeout') {
				_hash_.set('timetoken', __timetoken__);
				subscribe(channel, handler);
			}
			// Run user handler and reconnect if user permits 
			for (m in _messages_) {
				_continue_ = handler(m);
			}
			
			// If okay to keep listening
			if (_continue_) {
				_hash_.set('timetoken', __timetoken__);
				subscribe(channel, handler);
			}
			
		} catch (e:Dynamic) {
			_hash_.remove('server');
			subscribe(channel, handler);
		}
		
		// Done listening
		return true;
	}
	
	/**
	 * History
	 * 
	 * Load history from a channel
	 * 
	 * Messages remain in hostory for up to 30 days.
	 * Up to 100 messages returnable.
	 * Messages order by most recent first
	 * 
	 * @param	channel
	 * @param	?limit
	 * @return
	 */
	public function history(channel:String, ?limit:Int = 10):Dynamic {
		if (limit > 100) {
			limit = 100;
		}
		
		var _channel_:String = SUBSCRIBE_KEY + '/' + channel;
		var _hash_:Hash<Dynamic> = new Hash<Dynamic>();
		_hash_.set('channel', _channel_);
		_hash_.set('limit', limit);
		var _resp_:Dynamic = this._request(ORIGIN + '/pubnub-history', _hash_);
		
		return _resp_;
	}
	
	/**
	 * 
	 * @param	request
	 * @param	args
	 * @return	Can return either string or int
	 */
	private function _request(request:String, args:Hash<Dynamic>):Dynamic {
		args.set('unique', Date.now().toString());
		
		// Format URL Params
		var _params_:Array<String> = new Array<String>();
		for (key in args.keys()) {
			_params_.push('' + StringTools.urlEncode(key) + '=' + StringTools.urlEncode(args.get(key)));
		}
		
		// Append Params
		request += '?' + _params_.join('&');
		
		var _resp_:Dynamic = { };
		//var _http_:Request = new Request(request);
		var _http_:Http = new Http(request);
		
		_http_.onData = function (data:String) {
			_resp_.data = JSON.decode(data.replace(data.substr(0, data.indexOf(']') + 1), '').substr(1, data.length - 1));
		}
		_http_.onStatus = function (status:Int) {
			_resp_.status = status;
		}
		_http_.onError = function (msg:String) {
			_resp_.error = msg;
		}
		_http_.request(false);
		
		return _resp_;
	}
	
}