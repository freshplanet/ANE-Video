package com.freshplanet.ane.AirVideo.functions;

import com.adobe.fre.FREContext;
import com.adobe.fre.FREFunction;
import com.adobe.fre.FREInvalidObjectException;
import com.adobe.fre.FREObject;
import com.adobe.fre.FRETypeMismatchException;
import com.adobe.fre.FREWrongThreadException;
import com.freshplanet.ane.AirVideo.Extension;

public class SetViewDimensionsFunction implements FREFunction {

	@Override
	public FREObject call(FREContext arg0, FREObject[] arg1) {

		double x = 0;
		double y = 0;
		double width = 0;
		double height = 0;
		
		
		try {
			x 	= arg1[0].getAsDouble();
			y 	= arg1[1].getAsDouble();
			width = arg1[2].getAsDouble();
			height = arg1[3].getAsDouble();

		} catch (IllegalStateException e) {
			e.printStackTrace();
		} catch (FRETypeMismatchException e) {
			e.printStackTrace();
		} catch (FREInvalidObjectException e) {
			e.printStackTrace();
		} catch (FREWrongThreadException e) {
			e.printStackTrace();
		}
		
		Extension.context.setViewDimensions(x, y, width, height);
		
		
		return null;
	}

}
