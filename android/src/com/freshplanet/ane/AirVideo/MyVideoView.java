package com.freshplanet.ane.AirVideo;

import android.content.Context;
import android.util.AttributeSet;
import android.util.Log;
import android.widget.VideoView;

public class MyVideoView extends VideoView {

	private static String TAG = "MyVideoView"; 
	
	public MyVideoView(Context context) {
		super(context);
		setZOrderOnTop(true);
		// TODO Auto-generated constructor stub
	}

	public MyVideoView(Context context, AttributeSet attrs) {
		super(context, attrs);
		setZOrderOnTop(true);
		// TODO Auto-generated constructor stub
	}

	public MyVideoView(Context context, AttributeSet attrs, int defStyle) {
		super(context, attrs, defStyle);
		setZOrderOnTop(true);
		// TODO Auto-generated constructor stub
	}

	protected void onWindowVisibilityChanged(int visibility) {
		Log.d(TAG,"onWindowVisibilityChanged "+Integer.toString(visibility) );
		super.onWindowVisibilityChanged(visibility);
	}
	
	protected void onAttachedToWindow()
	{
		Log.d(TAG,"onAttachedToWindow ");
		super.onAttachedToWindow();
	}
	
	protected void onDetachedFromWindow()
	{
		Log.d(TAG,"onDetachedFromWindow ");
		super.onDetachedFromWindow();
	}

	
	
}
