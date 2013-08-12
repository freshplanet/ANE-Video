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

package com.freshplanet.ane.AirVideo;

import java.util.HashMap;
import java.util.Map;

import android.media.MediaPlayer;
import android.media.MediaPlayer.OnCompletionListener;
import android.view.ViewGroup;
import android.widget.RelativeLayout;
import android.widget.RelativeLayout.LayoutParams;
import android.widget.MediaController;
import android.widget.VideoView;

import com.adobe.fre.FREContext;
import com.adobe.fre.FREFunction;
import com.freshplanet.ane.AirVideo.functions.HidePlayerFunction;
import com.freshplanet.ane.AirVideo.functions.LoadVideoFunction;
import com.freshplanet.ane.AirVideo.functions.ResizePlayerFunction;
import com.freshplanet.ane.AirVideo.functions.ShowPlayerFunction;

public class ExtensionContext extends FREContext implements OnCompletionListener
{
	private VideoView _videoView = null;
	private ViewGroup _videoContainer = null;
	
	@Override
	public void dispose() {}

	@Override
	public Map<String, FREFunction> getFunctions()
	{
		Map<String, FREFunction> functions = new HashMap<String, FREFunction>();
		
		functions.put("airVideoShowPlayer", new ShowPlayerFunction());
		functions.put("airVideoHidePlayer", new HidePlayerFunction());
		functions.put("airVideoLoadVideo", new LoadVideoFunction());
		functions.put("airVideoResizeVideo", new ResizePlayerFunction());
		
		return functions;
	}
	
	public ViewGroup getRootContainer()
	{
		return (ViewGroup)((ViewGroup)getActivity().findViewById(android.R.id.content)).getChildAt(0);
	}
	
	public ViewGroup getVideoContainer()
	{
		if (_videoContainer == null)
		{
			_videoContainer = new RelativeLayout(getActivity());
			
			RelativeLayout.LayoutParams params = new RelativeLayout.LayoutParams(LayoutParams.WRAP_CONTENT, LayoutParams.WRAP_CONTENT);
			params.addRule(RelativeLayout.CENTER_VERTICAL, 1);
			params.addRule(RelativeLayout.CENTER_HORIZONTAL, 1); 
			_videoContainer.addView(getVideoView(), params);
		}
		
		return _videoContainer;
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
		}
		
		return _videoView;
	}
	
	public void setDisplayRect(double x, double y, double width, double height)
	{
		RelativeLayout.LayoutParams params = (RelativeLayout.LayoutParams)_videoView.getLayoutParams();
		params.leftMargin = (int)x;
		params.topMargin = (int)y;
		params.width = (int)width;
		params.height = (int)height;
		_videoView.setLayoutParams(params);
	}
	
	public void onCompletion(MediaPlayer mp)
	{
		dispatchStatusEventAsync("PLAYBACK_DID_FINISH", "OK");
	}
}
