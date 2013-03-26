package com.freshplanet.ane.AirVideo;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.net.HttpURLConnection;
import java.net.URL;

import android.os.AsyncTask;

public class FetchVideoTask extends AsyncTask<URL, Integer, Long> {

	private int mPosition;
	private byte[] mVideoBytes;
	
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
	        InputStream videoStream = connection.getInputStream();
	        
	        ByteArrayOutputStream buffer = new ByteArrayOutputStream();
	        
	        int nRead;
	        byte[] data = new byte[16384];

	        while ((nRead = videoStream.read(data, 0, data.length)) != -1) {
	          buffer.write(data, 0, nRead);
	        }

	        buffer.flush();
	        mVideoBytes = buffer.toByteArray();
	        
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
			Extension.context.setStreamAtPosition(mVideoBytes, mPosition);
		}
	}

	
}
