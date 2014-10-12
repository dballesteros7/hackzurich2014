/*===============================================================================
Copyright (c) 2012-2014 Qualcomm Connected Experiences, Inc. All Rights Reserved.

Vuforia is a trademark of QUALCOMM Incorporated, registered in the United States 
and other countries. Trademarks of QUALCOMM Incorporated are used with permission.
===============================================================================*/

package com.qualcomm.vuforia.samples.Books.app.Books;

import com.qualcomm.vuforia.samples.Books.R;

import android.content.Context;
import android.util.AttributeSet;
import android.view.LayoutInflater;
import android.widget.RelativeLayout;
import android.widget.TextView;

// Custom View with Note Overlay Data
public class NoteOverlayView extends RelativeLayout
{
    public NoteOverlayView(Context context)
    {
        this(context, null);
    }
    
    
    public NoteOverlayView(Context context, AttributeSet attrs)
    {
        this(context, attrs, 0);
    }
    
    
    public NoteOverlayView(Context context, AttributeSet attrs, int defStyle)
    {
        super(context, attrs, defStyle);
        inflateLayout(context);
        
    }
    
    
    // Inflates the Custom View Layout
    private void inflateLayout(Context context)
    {
        
        final LayoutInflater inflater = LayoutInflater.from(context);
        
        // Generates the layout for the view
        inflater.inflate(R.layout.bitmap_layout, this, true);
    }
    
    
    public void setNoteTitle(String noteTitle){
    	TextView tv = (TextView) findViewById(R.id.post_note_title);
    	tv.setText(noteTitle);
    }
    
    public void setNoteContent(String noteContent)
    {
        TextView tv = (TextView) findViewById(R.id.post_note_content);
        tv.setText(noteContent);
    }
}
