//////////////////////////////////////////////////////////////////////////////////////
//
//  Copyright 2012 Freshplanet (http://freshplanet.com | opensource@freshplanet.com)
//  
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//  
//    http://www.apache.org/licenses/LICENSE-2.0
//  
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//  
//////////////////////////////////////////////////////////////////////////////////////

package com.freshplanet.ane.AirCenterVideo;

import java.util.HashMap;
import java.util.Map;

import android.R.bool;
import android.media.MediaPlayer;
import android.media.MediaPlayer.OnCompletionListener;
import android.media.MediaPlayer.OnErrorListener;
import android.media.MediaPlayer.OnPreparedListener;
import android.view.ViewGroup;
import android.view.WindowManager;
import android.widget.FrameLayout;
import android.widget.MediaController;
import android.widget.VideoView;

import com.adobe.fre.FREContext;
import com.adobe.fre.FREFunction;
import com.freshplanet.ane.AirCenterVideo.functions.HidePlayerFunction;
import com.freshplanet.ane.AirCenterVideo.functions.LoadVideoFunction;
import com.freshplanet.ane.AirCenterVideo.functions.ResizePlayerFunction;
import com.freshplanet.ane.AirCenterVideo.functions.ShowPlayerFunction;

public class ExtensionContext extends FREContext implements OnCompletionListener, OnErrorListener, OnPreparedListener
{
	public final String TAG = "[AirVideo]";
	private VideoView _videoView = null;
	private int x = 0;
	private int y = 0;
	private int width = 0;
	private int height = 0;
	private boolean isDisplayRectSet = false;
	
	@Override
	public void dispose() {}

	@Override
	public Map<String, FREFunction> getFunctions()
	{
		Map<String, FREFunction> functions = new HashMap<String, FREFunction>();
		
		functions.put("airCenterVideoShowPlayer", new ShowPlayerFunction());
		functions.put("airCenterVideoHidePlayer", new HidePlayerFunction());
		functions.put("airCenterVideoLoadVideo", new LoadVideoFunction());
		functions.put("airCenterVideoResizeVideo", new ResizePlayerFunction());
		
		return functions;
	}
	
	public ViewGroup getRootContainer()
	{
		return (ViewGroup)((ViewGroup)getActivity().findViewById(android.R.id.content)).getChildAt(0);
	}
	
	public VideoView getVideoView()
	{
		if (_videoView == null)
		{
			_videoView = new VideoView(getActivity());
			_videoView.setZOrderOnTop(true);
			
			MediaController mediaController = new MediaController(getActivity());
			mediaController.setAnchorView(_videoView);
			
			_videoView.setMediaController(mediaController);
			_videoView.setOnCompletionListener(this);
			_videoView.setOnErrorListener(this);
			_videoView.setOnPreparedListener(this);
		}
		
		return _videoView;
	}
	
	public void setDisplayRect(double x, double y, double width, double height)
	{
		this.x = (int) x;
		this.y = (int) y;
		this.width = (int) width;
		this.height = (int) height;
		isDisplayRectSet = true;
		updateDisplayRect();
	}
	
	private void updateDisplayRect() 
	{
		if(!isDisplayRectSet) {
			return;
		}
		getVideoView();
		ViewGroup.LayoutParams params = _videoView.getLayoutParams();
		if(params == null) {
			return;
		}
		
		try {
			FrameLayout.LayoutParams frameParams = (FrameLayout.LayoutParams) params;
			frameParams.leftMargin = (int) x;
			frameParams.topMargin = (int) y;
		} catch (ClassCastException frameError) {
			try {
				WindowManager.LayoutParams windowParams = (WindowManager.LayoutParams) params;
				windowParams.horizontalMargin = (int) x;
				windowParams.verticalMargin = (int) y;
			} catch (ClassCastException windowError) {
				width += 2*x;
				height += 2*y;
			}
		}
		
		params.width = width;
		params.height = height;

		_videoView.setLayoutParams(params);
		_videoView.invalidate();
	}
	
	@Override
	public void onPrepared(MediaPlayer arg0) {
		if(isDisplayRectSet) {
			updateDisplayRect();
		}
		_videoView.start();
		_videoView.clearFocus();
	}
	
	public void onCompletion(MediaPlayer mp)
	{
		dispatchStatusEventAsync("PLAYBACK_DID_FINISH", "OK");
	}

	@Override
	public boolean onError(MediaPlayer mp, int what, int extra) 
	{
		dispatchStatusEventAsync("VIDEO_PLAYBACK_ERROR", "OK");
		isDisplayRectSet = false;
		return true;
	}

	
}
