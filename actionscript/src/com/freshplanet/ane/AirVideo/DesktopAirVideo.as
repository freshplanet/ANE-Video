package com.freshplanet.ane.AirVideo
{
	import flash.display.Stage;
	import flash.events.EventDispatcher;
	import flash.events.NetStatusEvent;
	import flash.events.StageVideoAvailabilityEvent;
	import flash.events.StageVideoEvent;
	import flash.events.StatusEvent;
	import flash.events.TimerEvent;
	import flash.external.ExtensionContext;
	import flash.media.StageVideoAvailability;
	import flash.media.Video;
	import flash.net.NetConnection;
	import flash.net.NetStream;
	import flash.utils.Timer;

	public class DesktopAirVideo extends EventDispatcher
	{
		private static const TIMER_TICK:int = 500;
		
		private var _netStreams:Array;
		private var _timer:Timer;
		
		private var _stage:Stage;
		private var _context:ExtensionContext;
		
		public function DesktopAirVideo(context:ExtensionContext, stage:Stage):void
		{
			_context = context;
			_stage = stage;
			_stage.addEventListener(StageVideoAvailabilityEvent.STAGE_VIDEO_AVAILABILITY, onStageVideoState);
			_stageVideo = new Video();
		}
		
		
		public function bufferVideos(urls:Array):void
		{
			_netStreams = [];
			
			if (_timer != null)
			{
				_timer.stop();
			}
			
			for each (var url:String in urls)
			{
				var connection:NetConnection = new NetConnection();
				connection.connect(null);
				var netstream:NetStream = new CustomNetStream(url, connection);
				netstream.addEventListener(NetStatusEvent.NET_STATUS, netStatusHandler);
				netstream.play(url);
				_netStreams.push(netstream);
			}
			
			_timer = new Timer(TIMER_TICK);
			_timer.reset();
			_timer.start();
			_timer.addEventListener(TimerEvent.TIMER, onTick);
		}
		
		
		public function setViewDimensions(x:Number, y:Number, width:Number, height:Number):void
		{
			_x = x;
			_y = y;
			_width = width;
			_height = height;
			resize();
		}
		
		public function playVideo(position:int):void
		{
			var netStream:CustomNetStream = _netStreams[position];
			_stageVideo.attachNetStream(netStream);
			netStream.play(netStream.url);
			resize();
		}
		
		public function showPlayer():void
		{
			_stage.addChildAt(_stageVideo, _stage.numChildren);
			_stageVideo.visible = true;
		}
		
		
		public function hidePlayer():void
		{
			if (_stageVideo)
			{
				_stageVideo.visible = false;
			}
		}
		
		public function pauseVideo(position:int):void
		{
			var netStream:CustomNetStream = _netStreams[position];
			netStream.pause();
		}
		
		
		
		
		
		private var _x:Number;
		private var _y:Number;
		private var _width:Number;
		private var _height:Number;
		private var _stageVideo:Video;
		
		
		
		private function resize():void
		{
			if (_stageVideo)
			{
				_stageVideo.x = _x;
				_stageVideo.y = _y;
				_stageVideo.width = _width;
				_stageVideo.height = _height;
			}
		}
		
		private function onTick(event:TimerEvent):void
		{
			for each (var ns:CustomNetStream in _netStreams)
			{
				if (!ns._isLoaded)
				{
					if (ns.bytesLoaded >= ns.bytesTotal)
					{
						ns._isLoaded = true;
						trace("NetStream.Load.State");
						_context.dispatchEvent(new StatusEvent(StatusEvent.STATUS, false, false, "LOAD_STATE_COMPLETE"));
					}
				}
			}
		}
		
		
		
		private function onStageVideoState(event:StageVideoAvailabilityEvent):void
		{
			trace("---> is available", (event.availability == StageVideoAvailability.AVAILABLE));
		}
		
		
		
		private function netStatusHandler(event:NetStatusEvent):void
		{
			var ns:CustomNetStream = event.currentTarget as CustomNetStream;
			
			
			trace(event.info.code);
			switch (event.info.code) {
				case "NetStream.Play.Start":
					if (!ns._isLoaded)
						ns.pause();
					break;
				case "NetStream.Play.Stop":
					trace("NetStream.Play.Stop");
					_context.dispatchEvent(new StatusEvent(StatusEvent.STATUS, false, false, "DID_FINISH_PLAYING"));
					break;
			}
		}
	}
	
}
import flash.net.NetConnection;
import flash.net.NetStream;

internal class CustomNetStream extends NetStream
{
	private var _url:String
	public var _isLoaded:Boolean;
	
	public function get url():String
	{
		return _url;
	}
	
	public function CustomNetStream(url:String, connection:NetConnection)
	{
		super(connection);
		_url = url;
		this.client = {};
		this.client.onMetaData = function(info:Object):void {trace("metadata: duration=" + info.duration + " width=" + info.width + " height=" + info.height + " framerate=" + info.framerate);};
		this.client.onCuePoint = function(info:Object):void {trace("cuepoint: time=" + info.time + " name=" + info.name + " type=" + info.type);};
	}
}
