package com.freshplanet.ane.AirVideo
{
	import flash.display.Stage;
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
		
		/** Event dispatched each time the currently played video changes. */
		public static const CURRENT_VIDEO_CHANGED : String = "CURRENT_VIDEO_CHANGED";
		
		public static const CONTROL_STYLE_DEFAULT_HUD:int = 0;
		public static const CONTROL_STYLE_NO_HUD:int = 1;
		
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
		
		/** Add the video player to the display list, at the center of the stage. */
		public function showPlayer() : void
		{
			if (!isSupported)
			{
				_desktopVideo.showPlayer();
			} else
			{
				_context.call("showPlayer");
			}
		}
		
		/** Remove the video player from the display list. */
		public function hidePlayer() : void
		{
			if (!isSupported)
			{
				_desktopVideo.hidePlayer();
			} else
			{
				_context.call("hidePlayer");
			}
		}
		
		/** Buffers the video data associated to the urls
		 * 
		 * @param videos: Array of url hosting mp4 videos
		 * */
		public function bufferVideos( videos:Array ):void
		{
			if (!isSupported) 
			{
				_desktopVideo.bufferVideos(videos);
			} else
			{
				_context.call("bufferVideos", videos);
			}
			
		}

		private var _stage:Stage;
		private var _desktopVideo:DesktopAirVideo;
		
		public function setStage(value:Stage):void
		{
			_desktopVideo = new DesktopAirVideo(_context, value);
		}
		

		/** Play a video at position i (from the list of buffered videos)*/
		public function playVideo(position:int):void
		{
			if (!isSupported) 
			{
				_desktopVideo.playVideo(position);
			} else
			{
				_context.call("playVideo", position);
			}
		}
		
		/** Play a video at position i (from the list of buffered videos)*/
		public function pauseVideo(position:int):void
		{
			if (!isSupported)
			{
				_desktopVideo.pauseVideo(position);
			} else
			{
				_context.call("pauseCurrentVideo");
			}
			
		}

		
		/** Set control style for video player. @see CONTROL_STYLE_DEFAULT_HUD, CONTROL_STYLE_NO_HUD*/
		public function setControlStyle(controlStyle:int):void
		{
			if (!isSupported) return;
			
			_context.call("setControlStyle", controlStyle);
		}
		
		/** Set the video player dimensions*/
		public function setViewDimensions(x:Number, y:Number, width:Number, height:Number):void
		{
			if (!isSupported)
			{
				_desktopVideo.setViewDimensions(x, y, width, height);
			} else
			{
				_context.call("setViewDimensions", x, y, width, height);
			}
		}

		
		public function resumeVideo(position:int, time:int):void
		{
			if (isSupported)
			{
				_context.call("resumeVideo", position, time);
			}
		}
		
		
		
		
		
		
		
		
		
		/** Return the URL of the video being played currently, or <code>null</code> nothing is playing. */
		public function get currentVideo() : String
		{
			return _currentVideo ? _currentVideo.concat() : null;
		}
		
		/**
		 * Load and play a given video URL.<br><br>
		 * 
		 * If another video is currently being played, it will stop. If there are videos in the queue,
		 * they will remain in the queue to be played after this new video is played.
		 */
		public function loadVideo( url : String ) : void
		{
			if (!isSupported) return;
			
			_context.call("fetchVideo", url);
			setCurrentVideo(url);
		}
		
		
		
		
		/**
		 * Return an array containing the URLs of the videos currently in the queue. The video currently
		 * played is not part of the queue.
		 */
		public function get queue() : Array
		{
			return _queue.concat();
		}
		
		/**
		 * Append a video URL to the queue.<br><br>
		 * 
		 * If no video is currently played, and the queue is empty, the video is loaded and played directly.
		 */
		public function addVideoToQueue( url : String ) : void
		{
			if (_currentVideo == null && _queue.length == 0) loadVideo(url);
			else _queue.push(url);
		}
		
		/** Remove all videos from the queue. This doesn't stop the video being played currently, if any. */
		public function clearQueue() : void
		{
			_queue.splice(0);
		}
		
		/** Stop the video being played currently, if any, and start the first video in the queue, if any. */
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
			if (event.code == "LOAD_STATE_COMPLETE")
			{
				this.dispatchEvent(new AirVideoEvent(AirVideoEvent.LOAD_STATE_COMPLETE, parseInt(event.level)));
			}
			else if (event.code == "PLAYBACK_DID_FINISH")
			{
				this.dispatchEvent(new AirVideoEvent(AirVideoEvent.DID_FINISH_PLAYING));
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