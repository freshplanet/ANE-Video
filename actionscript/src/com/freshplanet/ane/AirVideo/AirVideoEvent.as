package com.freshplanet.ane.AirVideo
{
	import flash.events.Event;
	
	public class AirVideoEvent extends Event
	{
		
		public static const LOAD_STATE_COMPLETE:String = "LOAD_STATE_COMPLETED";
		// todo handle errors
		
		public static const DID_FINISH_PLAYING:String = "DID_FINISH_PLAYING";
		
		
		public function AirVideoEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
		}
	}
}