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
import android.util.Log;
import android.view.Gravity;
import android.view.View;
import android.view.ViewGroup;
import android.widget.FrameLayout;
import android.widget.MediaController;
import android.widget.VideoView;

import com.adobe.fre.FREContext;
import com.adobe.fre.FREFunction;
import com.freshplanet.ane.AirVideo.functions.BufferVideosFunction;
import com.freshplanet.ane.AirVideo.functions.CleanUpFunction;
import com.freshplanet.ane.AirVideo.functions.HidePlayerFunction;
import com.freshplanet.ane.AirVideo.functions.LoadVideoFunction;
import com.freshplanet.ane.AirVideo.functions.PauseVideoFunction;
import com.freshplanet.ane.AirVideo.functions.PlayVideoFunction;
import com.freshplanet.ane.AirVideo.functions.PrepareToPlayFunction;
import com.freshplanet.ane.AirVideo.functions.ResumeVideoFunction;
import com.freshplanet.ane.AirVideo.functions.SetControlStyleFunction;
import com.freshplanet.ane.AirVideo.functions.SetViewDimensionsFunction;
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
		
		functions.put("showPlayer", new ShowPlayerFunction());
		functions.put("hidePlayer", new HidePlayerFunction());
		functions.put("fetchVideo", new LoadVideoFunction());
		
		functions.put("bufferVideos", new BufferVideosFunction());
		functions.put("playVideo", new PlayVideoFunction());
		functions.put("setControlStyle", new SetControlStyleFunction());
		functions.put("setViewDimensions", new SetViewDimensionsFunction());
		functions.put("pauseCurrentVideo", new PauseVideoFunction());
		functions.put("resumeVideo", new ResumeVideoFunction());
		functions.put("cleanUp", new CleanUpFunction());
		functions.put("prepareToPlay", new PrepareToPlayFunction());
		return functions;
	}
	
	public ViewGroup getRootContainer()
	{
		return (ViewGroup)((ViewGroup)getActivity().findViewById(android.R.id.content)).getChildAt(0);
	}
	
	private FrameLayout.LayoutParams videoLayoutParams;
	
	private ViewGroup getVideoContainer()
	{
		if (_videoContainer == null)
		{
			_videoContainer = new FrameLayout(getActivity());
			if (videoLayoutParams == null)
			{
				videoLayoutParams = new FrameLayout.LayoutParams(FrameLayout.LayoutParams.FILL_PARENT, FrameLayout.LayoutParams.FILL_PARENT);
				videoLayoutParams.gravity = Gravity.CENTER;
			}
			_videoContainer.addView(getVideoView(), videoLayoutParams);
		}
		
		return _videoContainer;
	}
	
	public VideoView getVideoView()
	{
		if (_videoView == null)
		{
			_videoView = new VideoView(getActivity());
			_videoView.setZOrderOnTop(true);
			_videoView.setMediaController(new MediaController(getActivity()));
			_videoView.setOnCompletionListener(this);
			_videoView.setOnErrorListener(new MediaPlayer.OnErrorListener() {
				@Override
				public boolean onError(MediaPlayer mp, int what, int extra) {
			    	Log.d("test", "Error : "+Integer.toString(what));
					return false;
				}
			});
			_videoView.setOnPreparedListener(new MediaPlayer.OnPreparedListener() {
			    @Override
			    public void onPrepared(MediaPlayer arg0) {
			    	Log.d("test", "ready to be displayed");
					dispatchStatusEventAsync("READY_TO_DISPLAY", "OK");
			    }
			});
		}
		return _videoView;
	}
	
	@Override
	public void onCompletion(MediaPlayer mp)
	{
		Log.d(TAG, "playback did finish");
		dispatchStatusEventAsync("PLAYBACK_DID_FINISH", "OK");
	}
	
	private HashMap<String, byte[]> videosData = null;
	
	private int mStyle = 0;
	
	public void setStreamAtPosition(byte[] stream, int position)
	{
		if (videosData == null)
		{
			videosData = new HashMap<String, byte[]>();
		}
		videosData.put(Integer.toString(position), stream);
	}

	public byte[] getStreamAtPosition(int position)
	{
		if (videosData == null)
		{
			return null;
		}
		return videosData.get(Integer.toString(position));
	}
	
	
	public void setStyle(int style)
	{
		mStyle = style;
		updateStyle();
	}
	
	private void updateStyle()
	{
		if (mStyle == 1)
		{
			getVideoView().setMediaController(null);
			getVideoView().setClickable(false);
		} else
		{
			getVideoView().setMediaController(new MediaController(getActivity()));
			getVideoView().setClickable(true);
		}

	}
	
	private FrameLayout.LayoutParams videoContainerLayoutParams;
	
	public void setViewDimensions(double x, double y, double width, double height)
	{
		videoContainerLayoutParams = new FrameLayout.LayoutParams((int) width, (int)height);
		videoContainerLayoutParams.gravity = Gravity.LEFT | Gravity.TOP;
		videoContainerLayoutParams.leftMargin = (int) x;
		videoContainerLayoutParams.topMargin = (int) y;
		if (_videoContainer != null)
		{
			getVideoContainer().setLayoutParams(videoLayoutParams);
		}
	}
	
	public void pauseVideo()
	{
		getVideoView().pause();
	}
	
	public void resizeVideo()
	{
		getVideoView().setLayoutParams(videoLayoutParams);
	}
	
	public void showPlayer()
	{
		if (_videoContainer != null)
		{
			Log.d(TAG, "show player, visibility true");
			_videoContainer.setVisibility(View.VISIBLE);
		} else
		{
			createPlayer();
			showPlayer();
		}
	}
	
	private static String TAG = "ExtensionCon";
	
	public void createPlayer()
	{
		Log.d(TAG, "creating player");
		ViewGroup rootContainer = getRootContainer();
		ViewGroup videoContainer = getVideoContainer();
		if (videoContainerLayoutParams != null)
		{
			rootContainer.addView(videoContainer, videoContainerLayoutParams);
		} else
		{
			rootContainer.addView(videoContainer, new FrameLayout.LayoutParams(200, 200, Gravity.TOP));
		}
		updateStyle();
		videoContainer.setVisibility(View.INVISIBLE);
		Log.d(TAG, "set visibility");
	}
	
	public void hidePlayer()
	{
		ViewGroup rootContainer = getRootContainer();
		ViewGroup videoContainer = getVideoContainer();
		rootContainer.removeView(videoContainer);
	}
	
	public void disposeVideo()
	{
		if (_videoContainer != null)
		{
			getRootContainer().removeView(_videoContainer);
			_videoContainer.removeAllViews();
			_videoContainer = null;
		}
		_videoView = null;
	}
	
	public void cleanUp()
	{
		videosData = null;
	}

}
