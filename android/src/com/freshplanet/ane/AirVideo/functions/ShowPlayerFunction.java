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

package com.freshplanet.ane.AirVideo.functions;

import android.view.Gravity;
import android.view.ViewGroup;
import android.widget.FrameLayout.LayoutParams;
import android.widget.VideoView;

import com.adobe.fre.FREContext;
import com.adobe.fre.FREFunction;
import com.adobe.fre.FREObject;
import com.freshplanet.ane.AirVideo.Extension;

public class ShowPlayerFunction implements FREFunction
{
	@Override
	public FREObject call(FREContext context, FREObject[] args)
	{
		ViewGroup rootContainer = Extension.context.getRootContainer();
		VideoView videoContainer = Extension.context.getVideoView();
		
		LayoutParams params = new LayoutParams(LayoutParams.WRAP_CONTENT, LayoutParams.WRAP_CONTENT);
		params.gravity = Gravity.CENTER_HORIZONTAL;
		rootContainer.addView(videoContainer, params);
		
		videoContainer.clearFocus();
		
		return null;
	}
}