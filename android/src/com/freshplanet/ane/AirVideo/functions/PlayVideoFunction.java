package com.freshplanet.ane.AirVideo.functions;

import com.adobe.fre.FREContext;
import com.adobe.fre.FREFunction;
import com.adobe.fre.FREObject;
import com.freshplanet.ane.AirVideo.Extension;

public class PlayVideoFunction implements FREFunction {

	private static String TAG = "playVideo";
	
	@Override
	public FREObject call(FREContext arg0, FREObject[] args) {

		int position = 0;
		try
		{
			position = args[0].getAsInt();
		}
		catch (Exception e)
		{
			e.printStackTrace();
			return null;
		}
		
		Extension.context.showPlayer();
		Extension.context.startVideo();
		return null;
	}

}
