package com.freshplanet.ane.AirVideo.functions;

import java.net.MalformedURLException;
import java.net.URL;

import android.util.Log;

import com.adobe.fre.FREArray;
import com.adobe.fre.FREContext;
import com.adobe.fre.FREFunction;
import com.adobe.fre.FREInvalidObjectException;
import com.adobe.fre.FREObject;
import com.adobe.fre.FRETypeMismatchException;
import com.adobe.fre.FREWrongThreadException;
import com.freshplanet.ane.AirVideo.FetchVideoTask;

public class BufferVideosFunction implements FREFunction
{
	private static String TAG = "BufferVideos";
	
	@Override
	public FREObject call(FREContext context, FREObject[] args)
	{
		FREArray inputArray = (FREArray) args[0];
		
		int len = 0 ;
		
		try {
			len = (int) inputArray.getLength();
		} catch (FREInvalidObjectException e) {
			e.printStackTrace();
		} catch (FREWrongThreadException e) {
			e.printStackTrace();
		}
		
		Log.d(TAG, "len -> "+Integer.toString(len));
		
		String[] outputArray = new String[len];
		
		for (int i=0; i < len; i++)
		{
			String url;
			try {
				url = inputArray.getObjectAt(i).getAsString();
				outputArray[i] = url;
				FetchVideoTask task = new FetchVideoTask();
				task.setParams(i);
				URL urlObject = new URL(url);
				task.execute(urlObject);
				
			} catch (IllegalStateException e) {
				e.printStackTrace();
			} catch (IllegalArgumentException e) {
				e.printStackTrace();
			} catch (FRETypeMismatchException e) {
				e.printStackTrace();
			} catch (FREInvalidObjectException e) {
				e.printStackTrace();
			} catch (FREWrongThreadException e) {
				e.printStackTrace();
			} catch (MalformedURLException e) {
				e.printStackTrace();
			}
		}
		
		
		
		return null;
	}

}
