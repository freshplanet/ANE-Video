package com.freshplanet.ane.AirVideo;

import android.content.Context;
import android.widget.VideoView;

public class ResizeVideoView extends VideoView
{
	public int vidX;
	public int vidY;
	public int vidWidth;
	public int vidHeight;
	
	public ResizeVideoView(Context context)
	{
		super(context);
	}
	
	 @Override
	 protected void onMeasure(int widthMeasureSpec, int heightMeasureSpec) 
	 {
		 setX(vidX);
		 setY(vidY);
		 setMeasuredDimension(vidWidth, vidHeight);
		 
		 Extension.log("onMeasure: "+vidX+", "+vidY+", "+vidWidth+", "+vidHeight);
	 }
}