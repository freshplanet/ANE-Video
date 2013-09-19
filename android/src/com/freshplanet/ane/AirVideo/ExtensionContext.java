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

import java.io.File;
import java.util.HashMap;
import java.util.Map;

import android.media.MediaPlayer;
import android.media.MediaPlayer.OnCompletionListener;
import android.net.Uri;
import android.util.Log;
import android.view.Gravity;
import android.view.SurfaceHolder;
import android.view.View;
import android.view.ViewGroup;
import android.view.ViewGroup.LayoutParams;
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
	private static String TAG = "ExtensionCon";
	
	private FrameLayout.LayoutParams videoLayoutParams;
	private FrameLayout.LayoutParams videoContainerLayoutParams;

	private MyVideoView _videoView = null;
	private ViewGroup _videoContainer = null;
	private ViewGroup _rootContainer = null;

	private HashMap<String, byte[]> videosData = null;
	
	private int mStyle = 0;

	
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
	
	/**
	 * GETTER
	 */

	public ViewGroup getRootContainer()
	{
//		if (_rootContainer == null)
//		{
			Log.d(TAG, "create new root container");
			ViewGroup viewGroup = (ViewGroup)getActivity().findViewById(android.R.id.content);
			Log.d(TAG, "num children "+Integer.toString(viewGroup.getChildCount()));
			_rootContainer = (ViewGroup)((ViewGroup)getActivity().findViewById(android.R.id.content)).getChildAt(0);
//		}
		return _rootContainer;
	}
	
	private ViewGroup getVideoContainer()
	{
		if (_videoContainer == null)
		{
			Log.d(TAG, "create new video container");
			_videoContainer = new FrameLayout(getActivity());
			if (videoLayoutParams == null)
			{
				videoLayoutParams = new FrameLayout.LayoutParams(FrameLayout.LayoutParams.FILL_PARENT, FrameLayout.LayoutParams.FILL_PARENT);
				videoLayoutParams.gravity = Gravity.CENTER;
			}
			_videoContainer.addView(getVideoView(), videoLayoutParams);
			Log.d(TAG, _videoContainer.toString());
		}
		
		return _videoContainer;
	}
	
	private VideoView getVideoView()
	{
		if (_videoView == null)
		{
			Log.d(TAG, "create new video view");

			_videoView = new MyVideoView(getActivity());
			_videoView.setZOrderOnTop(true);
			_videoView.setMediaController(new MediaController(getActivity()));
			_videoView.setOnCompletionListener(this);
			_videoView.setOnErrorListener(new MediaPlayer.OnErrorListener() {
				@Override
				public boolean onError(MediaPlayer mp, int what, int extra) {
			    	Log.d("ExtensionCon", "Error : "+Integer.toString(what));
					return false;
				}
			});
			_videoView.setOnPreparedListener(new MediaPlayer.OnPreparedListener() {
			    @Override
			    public void onPrepared(MediaPlayer arg0) {
			    	Log.d("ExtensionCon", "ready to be displayed");
					dispatchStatusEventAsync("READY_TO_DISPLAY", "OK");
			    }
			});
			
			_videoView.getHolder().addCallback(new SurfaceHolder.Callback() {
				
				@Override
				public void surfaceDestroyed(SurfaceHolder arg0) {
					// TODO Auto-generated method stub
					Log.d("ExtensionCon", "surface destroyed "+arg0.toString());
				}
				
				@Override
				public void surfaceCreated(SurfaceHolder arg0) {
					// TODO Auto-generated method stub
					Log.d("ExtensionCon", "surface created "+arg0.toString());

				}
				
				@Override
				public void surfaceChanged(SurfaceHolder arg0, int arg1, int arg2, int arg3) {
					// TODO Auto-generated method stub
					Log.d("ExtensionCon", "surface changed "+arg0.toString()+" format "+Integer.toString(arg1)+", width "+Integer.toString(arg2)+", height "+Integer.toString(arg3) );

				}
			});
			
		}
		return _videoView;
	}
	
	/**
	 * ON COMPLETION LISTENER
	 */

	@Override
	public void onCompletion(MediaPlayer mp)
	{
		Log.d(TAG, "playback did finish");
		dispatchStatusEventAsync("PLAYBACK_DID_FINISH", "OK");
	}
	
	/**
	 * STREAM STORAGE
	 */

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
	
	/**
	 * STYLE
	 */

	public void setStyle(int style)
	{
		mStyle = style;
		updateStyle();
	}
	
	private void updateStyle()
	{
		Log.d(TAG, "update style");
		if (mStyle == 1)
		{
			getVideoView().setMediaController(null);
			getVideoView().setClickable(false);
		} else
		{
			getVideoView().setMediaController(new MediaController(getActivity()));
			getVideoView().setClickable(true);
		}
		getVideoView().setZOrderOnTop(true);
	}
	
	public void setViewDimensions(double x, double y, double width, double height)
	{
		videoContainerLayoutParams = new FrameLayout.LayoutParams((int) width, (int)height);
		videoContainerLayoutParams.gravity = Gravity.LEFT | Gravity.TOP;
		videoContainerLayoutParams.leftMargin = (int) x;
		videoContainerLayoutParams.topMargin = (int) y;
		if (_videoContainer != null)
		{
			getVideoContainer().setLayoutParams(videoContainerLayoutParams);
		}
	}
	
	/**
	 * VIDEO ACTIONS
	 */

	public void startVideo()
	{
		Log.d(TAG, "start video");
		getVideoView().start();
	}
	
	public void startVideo(int seekTime)
	{
		Log.d(TAG, "seeking to "+Integer.toString(seekTime));
		getVideoView().seekTo(seekTime);
		startVideo();
	}

	public void setVideoPath(String filePath)
	{
		getVideoView().setVideoURI(Uri.parse(filePath));
	}
	
	public void pauseVideo()
	{
		Log.d(TAG, "pause video");
		getVideoView().pause();
	}
	
	public void resizeVideo()
	{
		Log.d(TAG, "resize video");
		getVideoView().setLayoutParams(videoLayoutParams);
	}
	
	/**
	 * PLAYER
	 */
	
	public void createPlayer()
	{
		Log.d(TAG, "creating player");
		ViewGroup rootContainer = getRootContainer();
		ViewGroup videoContainer = getVideoContainer();
		ViewGroup parent = (ViewGroup) videoContainer.getParent();
		if (parent != null)
		{
			Log.d(TAG, "video container has already a parent...");
			//parent.removeView(videoContainer);
			videoContainer.setLayoutParams(videoContainerLayoutParams);
		} else
		{
			_videoView.setZOrderOnTop(true);
			if (videoContainerLayoutParams != null)
			{
				Log.d(TAG, "video container with custom layout");
				rootContainer.addView(videoContainer, videoContainerLayoutParams);
			} else
			{
				Log.d(TAG, "video container with default layout");
				rootContainer.addView(videoContainer, new FrameLayout.LayoutParams(200, 200, Gravity.TOP));
			}
			Log.d(TAG, "set visibility to false");
			
			videoContainer.setVisibility(View.INVISIBLE);
		}
		updateStyle();
	}
	
	public void showPlayer()
	{
		Log.d(TAG, "show player");
		if (_videoContainer != null)
		{
			makeContainerVisible();
		} else
		{
			createPlayer();
			resizeVideo();
			showPlayer();
		}
	}
	
	public void makeContainerVisible()
	{
		if (_videoContainer != null)
		{
			Log.d(TAG, "set visibility to true "+getVideoContainer().toString());
			getVideoContainer().setVisibility(View.VISIBLE);
			getVideoView().setZOrderOnTop(true);
		}
	}
	
	public void hidePlayer()
	{
		Log.d(TAG, "hide Player");
//		ViewGroup rootContainer = getRootContainer();
//		ViewGroup videoContainer = getVideoContainer();
//		rootContainer.removeView(videoContainer);
		
		disposeVideo();
	}
	
	public void disposeVideo()
	{
		Log.d(TAG, "dispose view");
		if (_videoContainer != null)
		{
			_videoContainer.removeAllViews();
			getRootContainer().removeView(_videoContainer);
			Log.d(TAG, "removing view "+_videoContainer.toString());
			_videoContainer = null;
		}
		_videoView = null;
	}
	
	public void cleanUp(File movieDirectory)
	{
		videosData = null;
		if (movieDirectory.isDirectory()) {
	        String[] children = movieDirectory.list();
	        for (int i = 0; i < children.length; i++) {
	            new File(movieDirectory, children[i]).delete();
	        }
	    }
	}
	
	/**
	 * DEBUG
	 */
	
	private void debug()
	{
		Log.d(TAG, "------------------------");
		if (_rootContainer != null)
		{
			printViewGroup(getRootContainer(), "rootContainer");
		} else
		{
			Log.d(TAG, "root container is null");
		}
		if (_videoContainer != null)
		{
			printViewGroup(getVideoContainer(), "videoContainer");
		} else
		{
			Log.d(TAG, "video container is null");
		}
		if (_videoView != null)
		{
			printViewInformation(getVideoView());
		} else
		{
			Log.d(TAG, "video view is null");
		}

		Log.d(TAG, "------------------------");
	}
	
	private void printViewInformation(VideoView view)
	{
		Log.d(TAG, "video view "+view.toString());
		Log.d(TAG, "visibility "+Integer.toString(view.getVisibility()));
		LayoutParams params = view.getLayoutParams();
		if (params != null)
		{
			Log.d(TAG, "params "+Integer.toString(params.width) + " x "+Integer.toString(params.height));
		}
		SurfaceHolder sH = view.getHolder();
		if (sH != null)
		{
			Log.d(TAG, "surface holder "+sH.toString());
			Log.d(TAG, "surface holder "+sH.getSurfaceFrame().toShortString());
		}

		
		
	}
	
	private void printViewGroup(ViewGroup viewGroup, String type)
	{
		Log.d(TAG, type+" "+viewGroup.toString());
		Log.d(TAG, "visibility "+Integer.toString(viewGroup.getVisibility()));
		LayoutParams params = viewGroup.getLayoutParams();
		Log.d(TAG, "params "+Integer.toString(params.width) + " x "+Integer.toString(params.height));
		for(int i = 0; i < viewGroup.getChildCount(); i++)
	    {
	        View child = viewGroup.getChildAt(i);
	        Log.d(TAG, "child - " +child.toString());
	    }
	}
	
}
