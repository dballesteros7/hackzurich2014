package com.qualcomm.vuforia.samples.Books.app.Books;

public class Note {
	private String title;
	private String content;
	private String noteUrl;
	
	public String getTitle(){
		return title;
	}
	
	public String getContent(){
		return content;
	}
	
	public String getNoteUrl(){
		return noteUrl;
	}
	
	public void setTitle(String nTitle){
		title = nTitle;
	}
	
	public void setContent(String nContent){
		content = nContent;
	}
	
	public void setNoteUrl(String nNoteUrl){
		noteUrl = nNoteUrl;
	}
}
