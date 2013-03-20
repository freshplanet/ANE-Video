package com.freshplanet.ane.AirVideo.functions;

import java.io.InputStream;

import android.util.Log;

import com.adobe.fre.FREContext;
import com.adobe.fre.FREFunction;
import com.adobe.fre.FREObject;
import com.freshplanet.ane.AirVideo.CreateFileTask;
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
		
		Log.d(TAG, "fetching stream");
		InputStream input = Extension.context.getStreamAtPosition(position);
	    
		CreateFileTask task = new CreateFileTask();
		task.execute(input);
		
		Log.d(TAG, "reading file");
		
		
		return null;
	}

}
