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

import android.util.Log;

import com.adobe.fre.FREContext;
import com.adobe.fre.FREExtension;

public class AirVideoExtension implements FREExtension
{
	public static AirVideoExtensionContext context;
	public static boolean doLogging = true;
	
	@Override
	public FREContext createContext(String arg0)
	{
		context = new AirVideoExtensionContext();
		return context;
	}

	@Override
	public void dispose()
	{
		context = null;
	}

	@Override
	public void initialize() { }
	
	public static void LogInfo(String tag, String message)
	{
		if(doLogging)
			Log.i(tag, message);
	}
	
	public static void LogDebug(String tag, String message)
	{
		if(doLogging)
			Log.d(tag, message);
	}
	
	public static void LogWarning(String tag, String message)
	{
		if(doLogging)
			Log.w(tag, message);
	}
}