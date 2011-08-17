package com.spikything.utils 
{
	import flash.display.DisplayObjectContainer;
	import flash.display.Stage;
	import flash.errors.IllegalOperationError;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.external.ExternalInterface;
	
	/**
	 * MouseWheelTrap - stops simultaneous browser/Flash mousewheel scrolling
	 * @author Liam O'Donnell
	 * @version 1.0
	 * @usage Simply call the static method MouseWheelTrap.setup(stage);
	 * @see http://www.spikything.com/blog/?s=mousewheeltrap for info/updates
	 * This software is released under the MIT License <http://www.opensource.org/licenses/mit-license.php>
	 * © 2009 spikything.com
	 */
	public class MouseWheelTrap
	{
		// CDATA hack for multi-line string
		static private const JAVASCRIPT :String = ( <![CDATA[
			var browserScrolling;
			
			function allowBrowserScroll(value) {
				browserScrolling = value;
			}
			function wheel(event) {
				if (!browserScrolling) {
					if (event.preventDefault && (navigator.userAgent.indexOf('Firefox') > 0)) {
						event.preventDefault();
					}
					event.returnValue = false;
				}
			}
			if (window.addEventListener) {
				var eventType = (navigator.userAgent.indexOf('Firefox') > 0)
						? 'DOMMouseScroll' : "mousewheel";
				
				window.addEventListener(eventType, wheel, false);
			}
			window.onmousewheel = document.onmousewheel = wheel;
			allowBrowserScroll(true);
				]]> ).toString();
		static private const JS_METHOD :String = "allowBrowserScroll";
		static private var _browserScrollEnabled :Boolean = true;
		static private var _mouseWheelTrapped :Boolean = false;
		private const INSTANTIATION_ERROR :String = "Don't instantiate com.spikything.utils.MouseWheelTrap directly. Just call MouseWheelTrap.setup(stage);";
		
		public function MouseWheelTrap()
		{
			throw new IllegalOperationError(INSTANTIATION_ERROR);
		}
		
		/// Sets up the Flash and the browser to deal with turning browser scrolling on/off as the mouse cursor enters and leaves the stage (a valid reference to stage is required)
		static public function setup(displayObjectContainer:DisplayObjectContainer):void 
		{
			displayObjectContainer.addEventListener(MouseEvent.ROLL_OVER, function(e:* = null):void { allowBrowserScroll(false); });
			displayObjectContainer.addEventListener(MouseEvent.ROLL_OUT, function(e:* = null):void { allowBrowserScroll(true); });
		}
		
		static public function allowBrowserScroll(allow:Boolean):void
		{
			createMouseWheelTrap();
			
			if (allow == _browserScrollEnabled)
				return;
			_browserScrollEnabled = allow;
			
			if (ExternalInterface.available) {
				ExternalInterface.call(JS_METHOD, _browserScrollEnabled);
				return;
			}
		}
		
		static private function createMouseWheelTrap():void
		{
			if (_mouseWheelTrapped) 
				return;
			_mouseWheelTrapped = true;
			
			if (ExternalInterface.available) {
				ExternalInterface.call("eval", JAVASCRIPT);
				return;
			}
		}
		
	}
	
}