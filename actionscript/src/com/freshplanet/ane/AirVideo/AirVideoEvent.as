package com.freshplanet.ane.AirVideo
{
	import flash.events.Event;
	
	public class AirVideoEvent extends Event
	{
		
		public static const LOAD_STATE_COMPLETE:String = "LOAD_STATE_COMPLETED";
		// todo handle errors
		
		public static const DID_FINISH_PLAYING:String = "DID_FINISH_PLAYING";
		public static const READY_TO_DISPLAY:String = "READY_TO_DISPLAY";
		public static const ERROR:String = "ERROR";
		
		
		private var _position:int;
		private var _errorMessage:String;
		
		public function AirVideoEvent(type:String, aPosition:int = 0, anErrorMessage:String = null, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
			_position = aPosition;
			_errorMessage = anErrorMessage;
		}
		
		public function get position():int
		{
			return _position
		}
		
		public function get errorMessage():String
		{
			return _errorMessage;
		}
		
	}
}