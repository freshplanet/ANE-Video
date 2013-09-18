package com.freshplanet.ane.AirVideo.functions;

import android.util.Log;

import com.adobe.fre.FREContext;
import com.adobe.fre.FREFunction;
import com.adobe.fre.FREObject;
import com.freshplanet.ane.AirVideo.CreateFileTask;
import com.freshplanet.ane.AirVideo.Extension;

public class PrepareToPlayFunction implements FREFunction {

	private static String TAG = "PrepareToPlay";
	
	@Override
	public FREObject call(FREContext arg0, FREObject[] arg1) {
		int position = 0;
		try
		{
			position = arg1[0].getAsInt();
		}
		catch (Exception e)
		{
			e.printStackTrace();
			return null;
		}
		
		Log.d(TAG, "fetching stream");
		byte[] input = Extension.context.getStreamAtPosition(position);
		CreateFileTask task = new CreateFileTask();
		task.setParams(position, 0, arg0.getActivity().getExternalCacheDir());
		task.execute(input);
		Log.d(TAG, "reading file");
		return null;
	}

}
