package com.freshplanet.ane.AirVideo;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.net.HttpURLConnection;
import java.net.SocketTimeoutException;
import java.net.URL;

import android.os.AsyncTask;

public class FetchVideoTask extends AsyncTask<URL, Integer, Long> {
	
	private int mPosition;
	private double mWatchdogTime;
	private byte[] mVideoBytes;
	
	public void setParams(int position, double watchdog)
	{
		mPosition = position;
		mWatchdogTime = watchdog;
	}

	private Boolean downloadSuccess;
	
	@Override
	protected Long doInBackground(URL... urls) {
		
		getData(urls[0], mWatchdogTime);
		
		return null;
	}
	
	private void getData(URL url, double watchdog)
	{
		HttpURLConnection connection;
		try {
			connection = (HttpURLConnection) url.openConnection();
	        connection.setDoInput(true);
	        if (watchdog > 0)
	        	connection.setConnectTimeout((int)Math.round(watchdog*1000));
	        connection.connect();
	        InputStream videoStream = connection.getInputStream();
	        
	        ByteArrayOutputStream buffer = new ByteArrayOutputStream();
	        
	        int nRead;
	        byte[] data = new byte[16384];

	        while ((nRead = videoStream.read(data, 0, data.length)) != -1) {
	          buffer.write(data, 0, nRead);
	        }

	        buffer.flush();
	        mVideoBytes = buffer.toByteArray();
	        downloadSuccess = true;
		} catch (SocketTimeoutException e) {
			// retry once
			getData(url, 0);
		} catch (IOException e) {
			e.printStackTrace();
			downloadSuccess = false;
		}
	}
	
	@Override
    protected void onPostExecute(Long result) {
		if (Extension.context != null)
		{
			if (downloadSuccess)
			{
				Extension.context.dispatchStatusEventAsync("LOAD_STATE_COMPLETE", Integer.toString(mPosition));
				Extension.context.setStreamAtPosition(mVideoBytes, mPosition);
			} else
			{
				Extension.context.dispatchStatusEventAsync("ERROR", "download error");
			}
		}
	}

	
}
