package com.freshplanet.ane.AirVideo.functions;

import android.util.Log;

import com.adobe.fre.FREContext;
import com.adobe.fre.FREFunction;
import com.adobe.fre.FREInvalidObjectException;
import com.adobe.fre.FREObject;
import com.adobe.fre.FRETypeMismatchException;
import com.adobe.fre.FREWrongThreadException;
import com.freshplanet.ane.AirVideo.CreateFileTask;
import com.freshplanet.ane.AirVideo.Extension;

public class ResumeVideoFunction implements FREFunction {

	private static String TAG = "ResumeVideo";
	
	@Override
	public FREObject call(FREContext arg0, FREObject[] arg1) {
		Log.d(TAG, "resuming video");
		Log.d(TAG, "fetching stream");
		
		int timePosition = 0;
		int position = 0;
		try {
			timePosition = arg1[1].getAsInt();
			position = arg1[0].getAsInt();
		} catch (IllegalStateException e) {
			e.printStackTrace();
		} catch (FRETypeMismatchException e) {
			e.printStackTrace();
		} catch (FREInvalidObjectException e) {
			e.printStackTrace();
		} catch (FREWrongThreadException e) {
			e.printStackTrace();
		}
		
		Extension.context.disposeVideo();
		Extension.context.showPlayer();
		Extension.context.resizeVideo();
		
		byte[] input = Extension.context.getStreamAtPosition(position);
		CreateFileTask task = new CreateFileTask();
		task.setParams(position, timePosition, arg0.getActivity().getCacheDir());
		// delete previous file first
		String previousFileName = task.getPreviousFileName();
		if (previousFileName != null)
		{
			arg0.getActivity().deleteFile(previousFileName);
		}
		task.execute(input);
		
		return null;
	}

}
