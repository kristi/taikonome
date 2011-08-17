/**
 * Window.as
 * Keith Peters
 * version 0.9.9
 * 
 * A draggable window. Can be used as a container for other components.
 * 
 * Copyright (c) 2011 Keith Peters
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */
 
package taikonome
{
	import com.bit101.components.TextArea;
	import com.bit101.components.Window;
	import flash.display.DisplayObjectContainer;
	import flash.events.Event;
	import flash.events.MouseEvent;

	public class PopupWindow extends Window
	{
		protected var _message:String = "";
		protected var _textArea:TextArea;
		
		/**
		 * Constructor
		 * @param parent The parent DisplayObjectContainer on which to add this Panel.
		 * @param xpos The x position to place this component.
		 * @param ypos The y position to place this component.
		 * @param title The string to display in the title bar.
		 */
		public function PopupWindow(parent:DisplayObjectContainer=null, xpos:Number=0, ypos:Number=0, title:String="Window")
		{
			super(parent, xpos, ypos,title);
		}
		
		/**
		 * Initializes the component.
		 */
		override protected function init():void
		{
			super.init();
			hasCloseButton = true;
			
			// Component is hacked to recursively set the doubleClickEnabled
			// property on all its children so that double clicking works properly
			titleBar.doubleClickEnabled = true;
			titleBar.addEventListener(MouseEvent.DOUBLE_CLICK, onCloseAction);
			
			_textArea = new TextArea(this, 7, 7, message);
			onResize();
			
			addEventListener(Event.RESIZE, onResize);
		}
		
		public function onResize(event:Event=void):void {
			_textArea.width = this.width - 12;
			_textArea.height = this.height - 12 - titleBar.height;
		}
		
		// for close button
		override protected function onClose(event:MouseEvent):void {
			if(parent)
				parent.removeChild(this);
			//super.onClose(event);
		}
		
		// for double-click
		protected function onCloseAction(event:Event):void {
			if(parent)
				parent.removeChild(this);
		}

		public function set message(value:String):void {
			_message = value;
			_textArea.text = _message;
		}
		public function get message():String { return _message; }
		
	}
}