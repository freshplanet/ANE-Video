package com.freshplanet.ane.AirVideo
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.StatusEvent;
	import flash.external.ExtensionContext;
	import flash.system.Capabilities;

	public class AirVideo extends EventDispatcher
	{
		// --------------------------------------------------------------------------------------//
		//																						 //
		// 									   PUBLIC API										 //
		// 																						 //
		// --------------------------------------------------------------------------------------//
		
		public static const CURRENT_VIDEO_CHANGED : String = "CURRENT_VIDEO_CHANGED";
		
		/** AirVideo is supported on iOS and Android devices. */
		public static function get isSupported() : Boolean
		{
			var isIOS:Boolean = (Capabilities.manufacturer.indexOf("iOS") != -1);
			var isAndroid:Boolean = (Capabilities.manufacturer.indexOf("Android") != -1)
			return isIOS || isAndroid;
		}
		
		public function AirVideo()
		{
			if (!_instance)
			{
				_context = ExtensionContext.createExtensionContext(EXTENSION_ID, null);
				if (!_context)
				{
					log("ERROR - Extension context is null. Please check if extension.xml is setup correctly.");
					return;
				}
				_context.addEventListener(StatusEvent.STATUS, onStatus);
				
				_instance = this;
			}
			else
			{
				throw Error("This is a singleton, use getInstance(), do not call the constructor directly.");
			}
		}
		
		public static function getInstance() : AirVideo
		{
			return _instance ? _instance : new AirVideo();
		}
		
		/**
		 * If <code>true</code>, logs will be displayed at the Actionscript level.
		 * If <code>false</code>, logs will be displayed only at the native level.
		 */
		public function get logEnabled() : Boolean
		{
			return _logEnabled;
		}
		
		public function set logEnabled( value : Boolean ) : void
		{
			_logEnabled = value;
		}
		
		public function showPlayer() : void
		{
			if (!isSupported) return;
			
			_context.call("showPlayer");
		}
		
		public function hidePlayer() : void
		{
			if (!isSupported) return;
			
			_context.call("hidePlayer");
		}
		
		public function get currentVideo() : String
		{
			return _currentVideo ? _currentVideo.concat() : null;
		}
		
		public function loadVideo( url : String ) : void
		{
			if (!isSupported) return;
			
			_context.call("loadVideo", url);
			setCurrentVideo(url);
		}
		
		public function get queue() : Array
		{
			return _queue.concat();
		}
		
		public function addVideoToQueue( url : String ) : void
		{
			if (_currentVideo == null) loadVideo(url);
			else _queue.push(url);
		}
		
		public function clearQueue() : void
		{
			_queue.splice(0);
		}
		
		public function next() : void
		{
			if (_queue.length > 0)
			{
				var nextVideo:String = _queue[0];
				_queue.splice(0, 1);
				loadVideo(nextVideo);
			}
			else setCurrentVideo(null);
		}
		
		
		// --------------------------------------------------------------------------------------//
		//																						 //
		// 									 	PRIVATE API										 //
		// 																						 //
		// --------------------------------------------------------------------------------------//
		
		private static const EXTENSION_ID : String = "com.freshplanet.AirVideo";
		
		private static var _instance : AirVideo;
		
		private var _context : ExtensionContext;
		private var _logEnabled : Boolean = false;
		private var _currentVideo : String;
		private var _queue : Array = [];
		
		private function setCurrentVideo( url : String ) : void
		{
			if (url != _currentVideo)
			{
				_currentVideo = url ? url.concat() : null;
				dispatchEvent(new Event(CURRENT_VIDEO_CHANGED));
			}
		}
		
		private function onStatus( event : StatusEvent ) : void
		{
			if (event.code == "PLAYBACK_DID_FINISH")
			{
				next();
			}
			else if (event.code == "LOGGING") // Simple log message
			{
				log(event.level);
			}
		}
		
		private function log( message : String ) : void
		{
			if (_logEnabled) trace("[AirVideo] " + message);
		}
	}
}