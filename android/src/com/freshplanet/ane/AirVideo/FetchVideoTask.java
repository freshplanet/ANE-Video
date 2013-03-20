package com.freshplanet.ane.AirVideo;

import java.io.IOException;
import java.io.InputStream;
import java.net.HttpURLConnection;
import java.net.URL;

import android.os.AsyncTask;

public class FetchVideoTask extends AsyncTask<URL, Integer, Long> {

	
	private int mPosition;
	private InputStream mVideoStream;
	
	public void setParams(int position)
	{
		mPosition = position;
	}

	
	@Override
	protected Long doInBackground(URL... urls) {
		HttpURLConnection connection;
		try {
			connection = (HttpURLConnection) urls[0].openConnection();
	        connection.setDoInput(true);
	        connection.connect();
	        mVideoStream = connection.getInputStream();
		} catch (IOException e) {
			e.printStackTrace();
		}
		return null;
	}

	@Override
    protected void onPostExecute(Long result) {
		
		
		if (Extension.context != null)
		{
			Extension.context.dispatchStatusEventAsync("LOAD_STATE_COMPLETE", Integer.toString(mPosition));
			Extension.context.setStreamAtPosition(mVideoStream, mPosition);
		}
		
	}

	
}
