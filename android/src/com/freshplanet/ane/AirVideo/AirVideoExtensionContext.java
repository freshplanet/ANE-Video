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
import android.media.MediaPlayer.OnErrorListener;
import android.media.MediaPlayer.OnPreparedListener;
import android.net.Uri;
import android.view.Gravity;
import android.view.ViewGroup;
import android.widget.FrameLayout.LayoutParams;
import android.widget.MediaController;
import android.widget.VideoView;

import com.adobe.fre.FREContext;
import com.adobe.fre.FREFunction;
import com.freshplanet.ane.AirVideo.extractor.YouTubeExtractor;
import com.freshplanet.ane.AirVideo.functions.HidePlayerFunction;
import com.freshplanet.ane.AirVideo.functions.LoadVideoFunction;
import com.freshplanet.ane.AirVideo.functions.LoadYoutubeFunction;
import com.freshplanet.ane.AirVideo.functions.ResizePlayerFunction;
import com.freshplanet.ane.AirVideo.functions.ShowPlayerFunction;

public class AirVideoExtensionContext extends FREContext implements OnCompletionListener, OnErrorListener, OnPreparedListener
{
	private static String TAG = "[AirVideo] - ";
	
	public static String VIDEO_CHANGE_EVENT = "CURRENT_VIDEO_CHANGED";
	public static String VIDEO_PLAYBACK_ERROR = "VIDEO_PLAYBACK_ERROR";
	public static String YOUTUBE_EXTRACTION_ERROR = "YOUTUBE_EXTRACTION_ERROR";
	public static String VIDEO_LOADED_EVENT = "VIDEO_LOADED_EVENT";
	
	private VideoView _videoView = null;
	
	@Override
	public void dispose() {}

	@Override
	public Map<String, FREFunction> getFunctions()
	{
		Map<String, FREFunction> functions = new HashMap<String, FREFunction>();
		
		functions.put("airVideoShowPlayer", new ShowPlayerFunction());
		functions.put("airVideoHidePlayer", new HidePlayerFunction());
		functions.put("airVideoLoadVideo", new LoadVideoFunction());
		functions.put("airVideoLoadYoutube", new LoadYoutubeFunction());
		functions.put("airVideoResizeVideo", new ResizePlayerFunction());
		
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
			_videoView.setOnPreparedListener(this);
			_videoView.setOnCompletionListener(this);
			_videoView.setOnErrorListener(this);
		}
		
		return _videoView;
	}
	
	public void addToStage()
	{
		AirVideoExtension.LogDebug(TAG,  "Enter addToStage");
		
		ViewGroup rootContainer = getRootContainer();
		VideoView videoContainer = getVideoView();
		if(rootContainer.indexOfChild(videoContainer) == -1)
		{
			AirVideoExtension.LogDebug(TAG,  "adding to stage");
			LayoutParams params = new LayoutParams(LayoutParams.WRAP_CONTENT, LayoutParams.WRAP_CONTENT);
			params.gravity = Gravity.CENTER_HORIZONTAL;
			rootContainer.addView(videoContainer, params);
		}
		
		AirVideoExtension.LogDebug(TAG,  "Exit addToStage");
	}
	
	public void disposeVideoView()
	{
		AirVideoExtension.LogDebug(TAG,  "Enter disposeVideoView");
		
		ViewGroup rootContainer = AirVideoExtension.context.getRootContainer();
		rootContainer.removeView(_videoView);
		_videoView = null;
		
		AirVideoExtension.LogDebug(TAG,  "Exit disposeVideoView");
	}
	
	public void playUrl(String url)
	{
		AirVideoExtension.LogDebug(TAG,  "Enter playUrl");
		
		VideoView video = getVideoView();
		
		addToStage();
		
		video.setVideoURI(Uri.parse(url));
		video.requestFocus();
		video.start();
		
		AirVideoExtension.LogDebug(TAG,  "Exit playUrl");
	}
	
	public void loadVideoFromYouTubeID( String videoId )
	{
		AirVideoExtension.LogDebug(TAG,  "Enter loadVideoFromYouTubeID");
		
		try 
		{
			YouTubeExtractor extractor = new YouTubeExtractor(this);
			extractor.extract( videoId );
		}
		catch (Exception e)
		{
			dispatchStatusEventAsync(YOUTUBE_EXTRACTION_ERROR, e.toString());
		}
		
		AirVideoExtension.LogDebug(TAG,  "Exit loadVideoFromYouTubeID");
	}
	
	public void setDisplayRect(double x, double y, double width, double height)
	{
		AirVideoExtension.LogDebug(TAG,  "Enter setDisplayRect");
		
		VideoView vid = getVideoView();
		LayoutParams params = (LayoutParams)vid.getLayoutParams();
		AirVideoExtension.LogDebug(TAG,  "setDisplayRect1");
		params.leftMargin = (int)x;
		params.topMargin = (int)y;
		AirVideoExtension.LogDebug(TAG,  "setDisplayRect2");
		params.width = (int)width;
		params.height = (int)height;
		AirVideoExtension.LogDebug(TAG,  "setDisplayRect3");
		vid.setLayoutParams(params);
		AirVideoExtension.LogDebug(TAG,  "setDisplayRect4");
		vid.invalidate();
		
		AirVideoExtension.LogDebug(TAG,  "Exit setDisplayRect");
	}
	
	@Override
	public void onPrepared(MediaPlayer mp)
	{
		AirVideoExtension.LogDebug(TAG,  "VIDEO_LOADED_EVENT");
		dispatchStatusEventAsync(VIDEO_LOADED_EVENT, "Video Load Successful");
	}
	
	@Override
	public void onCompletion(MediaPlayer mp)
	{
		dispatchStatusEventAsync("PLAYBACK_DID_FINISH", "OK");
	}

	@Override
	public boolean onError(MediaPlayer mp, int what, int extra)
	{
		dispatchStatusEventAsync(VIDEO_PLAYBACK_ERROR, "OK");
		return false;
	}
}
