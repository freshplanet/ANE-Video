package com.freshplanet.ane.AirVideo
{
	import flash.events.Event;
	
	public class AirVideoEvent extends Event
	{
		
		public static const LOAD_STATE_COMPLETE:String = "LOAD_STATE_COMPLETED";
		// todo handle errors
		
		public static const DID_FINISH_PLAYING:String = "DID_FINISH_PLAYING";
		
		private var _position:int;
		
		public function AirVideoEvent(type:String, aPosition:int = 0, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
			_position = aPosition;
		}
		
		public function get position():int
		{
			return _position
		}
		
	}
}