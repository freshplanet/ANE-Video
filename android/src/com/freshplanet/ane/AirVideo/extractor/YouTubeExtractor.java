package com.freshplanet.ane.AirVideo.extractor;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.UnsupportedEncodingException;
import java.util.HashMap;
import java.util.Map;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import org.apache.commons.lang3.StringEscapeUtils;
import org.apache.http.HttpResponse;
import org.apache.http.HttpStatus;
import org.apache.http.StatusLine;
import org.apache.http.client.ClientProtocolException;
import org.apache.http.client.HttpClient;
import org.apache.http.client.methods.HttpGet;
import org.apache.http.client.methods.HttpUriRequest;
import org.apache.http.impl.client.DefaultHttpClient;
import org.jsoup.Jsoup;
import org.jsoup.nodes.Document;
import org.jsoup.select.Elements;

import com.freshplanet.ane.AirVideo.AirVideoExtension;
import com.freshplanet.ane.AirVideo.AirVideoExtensionContext;

import android.os.AsyncTask;

public class YouTubeExtractor implements OnTaskCompleted
{
	private static String TAG = "[AirVideo] YouTubeExtractor - ";
	
	private AirVideoExtensionContext context;
	private ConnectToYouTubeTask task;
	private int loopCount;
	
	public YouTubeExtractor(AirVideoExtensionContext context)
	{
		this.context = context;
	}
	
	public void extract( String videoId ) throws Exception
	{
		extract(videoId, 0);
	}
		
	public void extract(String videoId, int loopCount)
	{
		AirVideoExtension.LogDebug(TAG, "extracting from video: "+videoId);
		
		this.loopCount = loopCount;
		task = new ConnectToYouTubeTask(this);
		task.execute(videoId);
	}
	
	@Override
	public void onTaskCompleted() throws Exception
	{
		String extractedURL = null;
		ConnectToYouTubeResult result = null;

		result = task.get();
		if (result.error != null)
		{
			throw result.error;
		} 
		else 
		{
			extractedURL = doExtract(result.htmlFile, loopCount);
		}
		
		if(extractedURL == null)
			context.dispatchStatusEventAsync("YOUTUBE_EXTRACTION_ERROR", "MediaURL is null");
		else
			context.playUrl(extractedURL);
	}
	
	private String doExtract( String content, int loopCount ) throws Exception 
	{
		AirVideoExtension.LogInfo(TAG, "Entering extract()");
		
		String extractedURL = null;
		
		Document doc = Jsoup.parse(content);
		Elements foo = doc.select("#player");
		
		// Unescape (unicode) and use regex to extract videoId, videoTicket and video Formats
		String unescapedContent = unescapeString(foo.html());
		
		String videoTicket	= regExpMatch(unescapedContent, "\"t\":[ \t]*\"([^\"]+)\"", 1);
	    String videoFormats = regExpMatch(unescapedContent, "\"url_encoded_fmt_stream_map\":[ \t]*\"([^\"]+)\"", 1);
	    
	    // Abort if data is missing
	    if (videoTicket == null || videoFormats == null)
	    {
	    	AirVideoExtension.LogInfo(TAG, "extract() : ERROR - Incomplete data from RegExp.  YouTube server change?");
	    	
			if (loopCount == 0)
			{
				String anotherVideoId = regExpMatch(unescapedContent, "\"ypc_vid\":[ \t]*\"([^\"]+)\"", 1);
				loopCount +=1;
				
				if (anotherVideoId == null)
					throw new Exception("Incomplete data from RegExp.  YouTube server change?");
				
				extract(anotherVideoId, loopCount);
			}
			else
				throw new Exception("Incomplete data from RegExp.  YouTube server change?");
		}
	    
	    // Structure to store the videoURLS we build.
	    Map<String, String> videoURLS = new HashMap<String, String>();
	    
	    // Go over the data and extract the information needed to build each URL
	    String[] videoFormatGroups = videoFormats.split(",");
	    for (String videoFormatGroup : videoFormatGroups) 
	    {
	    	// Structure where we will hold the data we find
	    	Map<String, String> videoFormatData = new HashMap<String, String>();
	    	
	    	// Iterate over the structure and insert data into the dictionary
			String[] videoFormatElements = videoFormatGroup.split("&");
			for (String videoFormatElement : videoFormatElements) 
			{
				String[] data = videoFormatElement.split("=");
				
				AirVideoExtension.LogInfo(TAG, "extract() : data : " + data[0] + " - " + data[1] );
				
				videoFormatData.put(data[0], data[1]);
			}
			
			// Build an URL for the current videoFormatGroup (the current loop iterator)
			// Only proceed if the current videoFormatGroup corresponds to a video format
			// supported by Android.
			String itag = videoFormatData.get("itag");
			if ( itag.equals("18") || itag.equals("22") || itag.equals("37") || itag.equals("38")) 
			{
				String signature = videoFormatData.get("sig") ;
				if (signature != null) 
				{
					String videoURL = unescapeHTML( videoFormatData.get("url") )+"?signature="+signature;
					videoURLS.put(itag, videoURL);
				}
			}
			
		}
			    
		// Abort if we do not have available videos
		if ( videoURLS.size() <= 0 ) 
		{
			AirVideoExtension.LogInfo(TAG, "extract() : ERROR - The video is not available in an Android Friendly format.");
			throw new Exception("The video is not available in an Android Friendly format.");
		}
		
		// Return the highest quality video found
		String options[] = {"38","37","22","18"};
		for (String key : options) 
		{
			extractedURL = videoURLS.get(key); 
			if ( extractedURL != null )
				break;
		}
		
		extractedURL = java.net.URLDecoder.decode(extractedURL) ;
		
		AirVideoExtension.LogInfo(TAG, "Exiting extract() - URL is " + extractedURL );
		
		return extractedURL;
	}
	
	private class ConnectToYouTubeResult 
	{
		public String htmlFile = null;
		public Exception error = null;
	}
	
	private class ConnectToYouTubeTask extends AsyncTask<String, Void, ConnectToYouTubeResult>
	{
		private OnTaskCompleted listener;

	    public ConnectToYouTubeTask(OnTaskCompleted listener)
	    {
	        this.listener=listener;
	    }
	    
	    @Override
	    protected void onPostExecute(ConnectToYouTubeResult result)
	    {
	    	try 
			{
	    		listener.onTaskCompleted();
			}
	    	catch(Exception e)
	    	{
				// Sends data back to AS3 as Event.
	    		AirVideoExtension.LogWarning(TAG, "caught exception : " + e.toString());
				context.dispatchStatusEventAsync("YOUTUBE_EXTRACTION_ERROR", e.toString());
			}
	    }
	    
		@Override 
		protected ConnectToYouTubeResult doInBackground(String... params)
		{
			ConnectToYouTubeResult result = new ConnectToYouTubeResult();
            
			String videoId = params[0];
			
            HttpResponse response = null;
            StatusLine statusLine = null;
            HttpUriRequest request = new HttpGet("http://www.youtube.com/watch?v="+videoId);
            
            HttpClient httpClient = new DefaultHttpClient();
            try 
            {
                response = httpClient.execute(request);
                if (response != null) 
                {
                    statusLine = response.getStatusLine();
                }
                
                // A successful connection
                if (statusLine.getStatusCode() == HttpStatus.SC_OK) 
                {
                    ByteArrayOutputStream out = new ByteArrayOutputStream();
                    response.getEntity().writeTo(out);
                    out.close();
                    
                    // Our HTML File
                    result.htmlFile = out.toString();
                    
                    // HTML File cannot be empty.
                    if (result.htmlFile.length() <= 0)
                        result.error = new Exception( "Couldn't download the HTML source code.  URL might be invalid" );
                }
                // No success.
                else  
                {    
                    response.getEntity().getContent().close(); // Closes the connection
                    result.error = new Exception( statusLine.getReasonPhrase() );
                }
            } 
            catch (ClientProtocolException e) 
            {
                result.error = e;
            } 
            catch (IOException e) 
            {
                result.error = e;
            } 
            catch (Exception e) 
            {
                result.error = e;
            }

            return result;
		}
	}
	
	private String regExpMatch( String target, String pattern, int group ) 
	{
		String result = null;
		
		Pattern p = Pattern.compile(pattern);
		Matcher m = p.matcher(target);
		if (m.find()) {
			result = m.group( group );
		}

		return result;
	}
	
	private String esc1;
	private String esc2;
	private String esc3;
	private String esc4;
	private String esc5;
	private String esc6;
	private String unescapeHTML(String string)
	{
	    // %253A ----> :
	    esc1 = string.replaceAll("%253A", ":");
	    
	    // %252F ----> /
	    esc2 = esc1.replaceAll("%252F", "/");
	    
	    // %253f ----> ?
	    esc3 = esc2.replaceAll("%253F", "?");
	    
	    // %253D ----> =
	    esc4 = esc3.replaceAll("%253D", "=");
	    
	    // %2526 ----> &
	    esc5 = esc4.replaceAll("%2526", "&");
	    
	    // %25252C ----> %2C
	    esc6 = esc5.replaceAll("%25252C", "%2C");
	    
	    return esc6;
	}
	
	/** Unescape Unicode characters.
	 * 
	 *  http://stackoverflow.com/questions/5479728/unescape-unicode-from-input 
	 *  Comment:  "StringEscapeUtils.unescapeHtml4() will do the work"
	 **/
	private String unescapeString(String toEscape) throws UnsupportedEncodingException
	{
		return StringEscapeUtils.unescapeJava(toEscape);
	}
}
