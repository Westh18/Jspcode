<%@page import="java.io.FileInputStream"%>
<%@page import="java.io.File"%>
<%@page import="java.io.InputStreamReader"%>
<%@page import="java.net.URL"%>
<%@page import="java.io.FileReader"%>
<%@page import="java.io.BufferedReader"%>
<%@page import="org.json.simple.JSONArray"%>
<%@page import="org.json.simple.JSONObject"%>
<%@page import="org.json.simple.parser.JSONParser"%>
<%@page import="org.json.simple.parser.ParseException"%>
<%@page import="org.json.simple.*"%>
<%@page import="com.fileCreater.FileReaderMiniStatement"%>
<%@page import="com.constants.Constants"%>
<%@page import="com.utils.ReadProperties"%>
<%@page import="java.io.IOException"%>
<%@page import="java.io.InputStream"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="org.apache.log4j.Logger"%>
<%@page import="java.util.ResourceBundle"%>
<%@page language="java" import="java.util.*"%>
<!DOCTYPE html>
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
<title>Read Text</title>
</head>
<body>
	<%
		Logger logger = Logger.getLogger(Constants.MINI_STATEMENT_JSP);
		ReadProperties readProp = new ReadProperties(
				Constants.PROP_FILENAME);
		logger.info("===========len========="
				+ readProp.getPropValues(Constants.COMMON_CACHE_FOLDER));
		//ResourceBundle resource = ResourceBundle.getBundle(Constants.STR_CONFIG);
		//String[] fileTypeValue = { "", Constants.STR_DATA,
		//		Constants.STR_SMS, Constants.STR_CALL, Constants.STR_RECH };
		//To get the param value from the url passed
		String parameterValues = request.getParameter(Constants.STR_PARAM);
		String[] paramList = parameterValues.split("\\-");
		//String typeFlag = paramList[0];
		//int typeFlagValue = Integer.parseInt(typeFlag);
		String subscriberId = paramList[0];
		String fileType = paramList[1];
		String msisdn = paramList[2];
		String sessionID= paramList[3];
		String opco= paramList[4];
		String emailID = null;
		String groupid = null;
		String apiCallType = "";
		String fileName = "";
		int downloadFileFlag=2;
		int noOfCall=0;
		
			fileName = Constants.MINI_STATEMENT_FILE_NAME;
			apiCallType = Constants.STR_CAP_DAT;
		//paramList.length >= 5 signifies that the file after generation has to be send over mail
		if (paramList.length >= 6) {
			emailID = paramList[5];
			if (paramList.length >= 7) {
				groupid = paramList[6];
			}
		}
		logger.info("===========Param value=========" + paramList[1]);
		logger.info("===========Param value=========" + groupid);
		FileReaderMiniStatement fileRead = new FileReaderMiniStatement();
		//int fileExceptionFlag=fileRead.readFileData(typeFlagValue, subscriberId, fileType,emailID,readProp);
		int fileExceptionFlag = fileRead.readFileDataForMiniStatement(subscriberId, fileType, emailID,opco, readProp, msisdn,downloadFileFlag,groupid); 
		logger.info("===========Param value fileExceptionFlag=========" + fileExceptionFlag);
		if (fileExceptionFlag == 1) {
			try
			{
				fileRead.sendPost(sessionID, fileName, subscriberId, msisdn,opco, readProp,groupid); 
				fileExceptionFlag = fileRead.readFileDataForMiniStatement(subscriberId, fileType, emailID,opco, readProp, msisdn,downloadFileFlag,groupid);
			}
			catch(Exception e)
			{
				logger.debug("===========CreateFile.JSP Exception========="+e+" - "+e.getMessage() );
			}
		}
		if (emailID == null || emailID.equalsIgnoreCase("null")) {
			logger.info("===========Param value=========" + paramList[1]);
			String filename = "";
			/*
				fileType gives the different types of files that can be downloaded
				0-excel
				1-text
				2-docx
				3-pdf
			 */
			if (fileType.equals("0")) {
				filename = Constants.MINI_STATEMENT_FILE_NAME
						+ Constants.EXCEL_EXTENSION;
			} else if (fileType.equals("1")) {
				filename = Constants.MINI_STATEMENT_FILE_NAME
						+ Constants.TEXT_EXTENSION;
			} else if (fileType.equals("2")) {
				filename = Constants.MINI_STATEMENT_FILE_NAME
						+ Constants.DOCX_EXTENSION;
			} else if (fileType.equals("3")) {
				filename = Constants.MINI_STATEMENT_FILE_NAME
						+ Constants.PDF_EXTENSION;
			}
			//getting folder name from the subscriber ID
			String firstFolder = subscriberId.substring(0, 3);
			String secFolder = subscriberId.substring(3, 7);
			String thirdFolder = subscriberId.substring(7, 11);
			String widgetID = "";
			if(groupid != null){
				widgetID =readProp.getPropValues("MINI_STATEMENT_CACHE_WIDGET_ID_"+groupid+"");
			}else{
				widgetID=readProp.getPropValues("MINI_STATEMENT_CACHE_WIDGET_ID");
			}
			String filepath = readProp
					.getPropValues(Constants.COMMON_CACHE_FOLDER)
					+ firstFolder
					+ "/"
					+ secFolder
					+ "/"
					+ thirdFolder
					+ "/"
					+ subscriberId
					+ "/"
					+ widgetID
					+ "/" + filename;
			//String filepath = "/home/server/temp/cache_data/M30/3AD5/1D7D/M303AD51D7D3/241651399/"+filename;   
			//String filepath = "D:\\report\\"+filename;
			File file = null;
			try
			{
				file = new File(filepath);
			}
			catch(Exception e)
			{
				logger.debug("===========CreateFile.JSP Exception========="+e+" - "+e.getMessage() );
			}
			//to get the file size
			byte[] fileSize = getBytesFromFile(file, logger);
			if(fileSize!=null)
			{
				int len = fileSize.length;
				logger.info("===========len=========" + len);
				response.reset();
				//to help the app in finding the right app to open each file
				if (fileType.equals("0")) {
					response.setContentType("application/vnd.ms-excel");
				} else if (fileType.equals("1")) {
					response.setContentType("text/plain");
				} else if (fileType.equals("2")) {
					response.setContentType("application/vnd.ms-word");
				} else if (fileType.equals("3")) {
					response.setContentType("application/pdf");
				}
				response.setHeader("Content-Disposition",
						"attachment; filename=" + filename + "");
				response.setContentLength(len);
				response.getOutputStream().write(fileSize, 0, len);
				response.getOutputStream().flush();
				response.getOutputStream().close();
			}
		}
	%>
	<%!private byte[] getBytesFromFile(File file, Logger logger)
			throws IOException {
		InputStream is =null;
		byte[] bytes = null;
		try
		{
			is = new FileInputStream(file);
		
			
			long length = file.length();
			if (length > Integer.MAX_VALUE) {
				// File is too large
			}
			// Create the byte array to hold the data
			bytes = new byte[(int) length];
			// Read in the bytes
			int offset = 0;
			int numRead = 0;
			while (offset < bytes.length
					&& (numRead = is.read(bytes, offset, bytes.length - offset)) >= 0) {
				offset += numRead;
			}
			// Ensure all the bytes have been read in
			if(is != null)
				is.close();
			if (offset < bytes.length) {
				logger.error("Could not completely read file " + file.getName());
				throw new IOException("Could not completely read file "
						+ file.getName());
			}
			// Close the input stream and return bytes
			is.close();
			
		}
		catch(Exception e)
		{
			logger.debug("===========CreateFile.JSP getBytesFromFile Exception========="+e+" - "+e.getMessage() );
		}
		finally
		{
			return bytes;
		}
	}%>

</body>
</html>
