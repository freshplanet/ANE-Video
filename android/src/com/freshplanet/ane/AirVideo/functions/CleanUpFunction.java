package com.freshplanet.ane.AirVideo.functions;

import com.adobe.fre.FREContext;
import com.adobe.fre.FREFunction;
import com.adobe.fre.FREObject;
import com.freshplanet.ane.AirVideo.CreateFileTask;
import com.freshplanet.ane.AirVideo.Extension;

public class CleanUpFunction implements FREFunction {

	@Override
	public FREObject call(FREContext arg0, FREObject[] arg1) {
		
		String previousFilePath = new CreateFileTask().getPreviousFileName();
		if (previousFilePath != null)
		{
			arg0.getActivity().deleteFile(previousFilePath);
		}

		Extension.context.cleanUp(arg0.getActivity().getExternalCacheDir());
		return null;
	}

}
