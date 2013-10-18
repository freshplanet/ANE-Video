package com.freshplanet.ane.AirVideo
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.StatusEvent;
	import flash.external.ExtensionContext;
	import flash.geom.Rectangle;
	import flash.system.Capabilities;

	public class AirVideo extends EventDispatcher
	{
		// --------------------------------------------------------------------------------------//
		//																						 //
		// 									   PUBLIC API										 //
		// 																						 //
		// --------------------------------------------------------------------------------------//
		
		/** Event dispatched each time the currently played video changes. */
		public static const CURRENT_VIDEO_CHANGED : String = "CURRENT_VIDEO_CHANGED";
		public static const VIDEO_PLAYBACK_ERROR  : String = "VIDEO_PLAYBACK_ERROR";
		public static const YOUTUBE_EXTRACTION_ERROR : String = "YOUTUBE_EXTRACTION_ERROR";
		public static const VIDEO_LOADED_EVENT : String = "VIDEO_LOADED_EVENT";
		
		private static const SHOW_VIDEO:String = "airVideoShowPlayer";
		private static const HIDE_VIDEO:String = "airVideoHidePlayer";
		private static const LOAD_VIDEO:String = "airVideoLoadVideo";
		private static const LOAD_YOUTUBE:String = "airVideoLoadYoutube";
		private static const RESIZE_VIDEO:String = "airVideoResizeVideo";
		
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
		
		/** Add the video player to the display list */
		public function showPlayer():void
		{
			if (!isSupported) 
				return;
			
			_context.call(SHOW_VIDEO);
		}
		
		/** Remove the video player from the display list. */
		public function hidePlayer():void
		{
			if (!isSupported) 
				return;
			
			_context.call(HIDE_VIDEO);
		}
		
		/** Return the URL of the video being played currently, or <code>null</code> nothing is playing. */
		public function get currentVideo():String
		{
			return _currentVideo ? _currentVideo.concat() : null;
		}
		
		/**
		 * Load and play a given video URL.<br><br>
		 *
		 * If another video is currently being played, it will stop. If there are videos in the queue,
		 * they will remain in the queue to be played after this new video is played.
		 * 
		 * @param url the url of the video.  it can be a local file on the device.
		 * @param isLocalFile set this flag to true when playing a video stored locally, not on the web. 
		 * default value is false
		 */
		public function loadVideo(url:String, isLocalFile:Boolean = false):void
		{
			if (!isSupported) 
				return;

			_context.call(LOAD_VIDEO, url, isLocalFile);
			setCurrentVideo(url);
		}
		
		public function loadYoutubeVideo(id:String):void
		{
			if (!isSupported) 
				return;
			
			_context.call(LOAD_YOUTUBE, id);
			setCurrentVideo(id);
		}
		
		public function resizeVideo(displayArea:Rectangle):void
		{
			if (!isSupported) 
				return;
			
			_context.call(RESIZE_VIDEO, displayArea.x, displayArea.y, displayArea.width, displayArea.height);
		}
		
		/**
		 * Return an array containing the URLs of the videos currently in the queue. The video currently
		 * played is not part of the queue.
		 */
		public function get queue():Array
		{
			return _queue.concat();
		}
		
		/**
		 * Append a video URL to the queue.<br><br>
		 * 
		 * If no video is currently played, and the queue is empty, the video is loaded and played directly.
		 */
		public function addVideoToQueue(url:String):void
		{
			if (_currentVideo == null && _queue.length == 0) loadVideo(url);
			else _queue.push(url);
		}
		
		/** Remove all videos from the queue. This doesn't stop the video being played currently, if any. */
		public function clearQueue():void
		{
			_queue.splice(0);
		}
		
		/** Stop the video being played currently, if any, and start the first video in the queue, if any. */
		public function next():void
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
		
		private function setCurrentVideo(url:String):void
		{
			if (url != _currentVideo)
			{
				_currentVideo = url ? url.concat() : null;
				dispatchEvent(new Event(CURRENT_VIDEO_CHANGED));
			}
		}
		
		private function onStatus(event:StatusEvent):void
		{
			if (event.code == "PLAYBACK_DID_FINISH")
				next();
			else if (event.code == "LOGGING")
				log(event.level);
			else
				dispatchEvent(new Event(event.code));
		}
		
		private function log(message:String):void
		{
			if (_logEnabled) 
				trace("[AirVideo] " + message);
		}
	}
}