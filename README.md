this project needs to be re-worked, its a mess :(
=
---
old readme below
-
haXe client (JS) code for the pubnub service. PubNub is a massively scalable
real-time service for web and mobile games.

INFO
------
http://www.pubnub.com/
http://github.com/pubnub/pubnub-api/tree/master/javascript/

UPDATE on 08 October 2010
------
I have re-written the haXe pubnub class, its based on PubNub's python class, link -
http://github.com/pubnub/pubnub-api/blob/master/python/Pubnub.py
The old class still exists, now named Old_Pubnub.hx.

SERVER
------
You can publish and subscribe with neko. The publish method work with both js and flash,
but I've set the native haxe class to only allow the neko target. If you want to subscribe to
channels through flash, use external interface for now :(.

CLIENT
------
Use compile.hxml to create javascript source. Then open example/client_example/subscribe/hx_sub.html
and replace <!-- Paste the url to pubnub js file --> with the code found at 
http://www.pubnub.com/account-javascript-api-include as this includes your pub_key and
sub_key. If you cant be bothered signing (why not?) just launch the demo, it users pubnub demo keys,
THE DEMO KEY'S ARE NOT TO BE USED IN PRODUCTION, JUST FOR LIGHT TESTING.

Then launch it.

Then do the same for example/client_example/subscribe/hx_pub.html which will
send the message 'hello skial bainn' to hx_sub.html.