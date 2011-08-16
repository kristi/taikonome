package taikonome
{
	import com.adobe.utils.IntUtil;
	import com.bit101.components.PushButton;
	import com.bit101.components.Style;
	import flash.display.DisplayObjectContainer;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.ui.Mouse;
	import com.spikything.utils.MouseWheelTrap;
	
	/**
	 * ...
	 * @author Kristi Tsukida
	 */
	public class NoteButton extends PushButton 
	{
		public static const SELECTED_CHANGED:String = "selectedChanged";
		public static var BITS_PER_NOTE:int = 2;
		public static var MAX_LEVEL:int = (1 << BITS_PER_NOTE) - 1;
		public static var NUM_LEVELS:int = (1 << BITS_PER_NOTE);
		public static var volumeLevels:Vector.<Number> = new <Number>[0, 0.2, 0.5, 1];
		public static var dragLevel:int = MAX_LEVEL;
		public var color:uint = 0xDDDDDD;
		public var colorActive:uint = 0x00C6FF;
		
		public var index:int = 0;
		public var _level:int = 0;  // 0 off, 1 low, 2 normal, 3 accented
		
		/**
		 * Constructor
		 * @param	parent
		 * @param	xpos
		 * @param	ypos
		 * @param	label
		 * @param	defaultHandler
		 */
		public function NoteButton(parent:DisplayObjectContainer = null, xpos:Number = 0, ypos:Number =  0, label:String = "", defaultHandler:Function = null)
		{
			super(parent, xpos, ypos);
			if(defaultHandler != null)
			{
				addEventListener(MouseEvent.CLICK, defaultHandler);
			}
			this.label = label;
			// Make note buttons togglable
			this.toggle = true;
			
			addEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel);
		}
		
		public function set level(value:int):void {
			var oldLevel:int = _level;
			_level = Math.max(0, Math.min(MAX_LEVEL, value));
			if (oldLevel != _level) {
				drawFace();
				dispatchEvent(new Event(SELECTED_CHANGED));
			}
		}
		public function get level():int {
			return _level;
		}
		public function get volume():Number {
			return NoteButton.volumeLevels[_level];
		}
		// this is a hack, remove selected
		override public function get selected():Boolean {
			return (_level > 0);
		}
		override public function set selected(value:Boolean):void {
			_level = 2;
		}
		
		/**
		 * Draws the face of the button, color based on state.
		 */
		override protected function drawFace():void
		{
			_face.graphics.clear();

			if(_level > 0 ) {
				_face.graphics.beginFill(colorActive);
			} else {
				_face.graphics.beginFill(color);
			}
			_face.graphics.drawRoundRect(0, (_height - 2)*(1-volume), _width - 2, (_height - 2)*volume, 3, 3);
			_face.graphics.endFill();
		}
		
		public function onMouseWheel(event:MouseEvent):void {
			if (event.buttonDown) {
				return;
			}
			var d:int = (event.delta > 0) ? 1 : -1;
			level = (level + d + NUM_LEVELS) % NUM_LEVELS;
		}
		
		// 
		// Mouse handlers
		// Overridden to allow click+drag selection
		//
		override protected function onMouseOver(event:MouseEvent):void
		{
			_over = true;
			if (_toggle && event.buttonDown) {
				level = dragLevel;
			}
			addEventListener(MouseEvent.ROLL_OUT, onMouseOut);
		}
		
		/**
		 * Internal mouseOut handler.
		 * @param event The MouseEvent passed by the system.
		 */
		//override protected function onMouseOut(event:MouseEvent):void
		//{
			//_over = false;
			//if(!_down)
			//{
				//_face.filters = [getShadow(1)];
			//}
			//removeEventListener(MouseEvent.ROLL_OUT, onMouseOut);
		//}
		
		/**
		 * Internal mouseOut handler.
		 * @param event The MouseEvent passed by the system.
		 */
		override protected function onMouseGoDown(event:MouseEvent):void
		{
			if(_toggle)
			{
				if (event.shiftKey) {
					//level = (level > 0) ? 0 : MAX_LEVEL;
					level = dragLevel;
				} else {
					level = (level + MAX_LEVEL) % NUM_LEVELS;
					dragLevel = level;
				}
				
			}
			stage.addEventListener(MouseEvent.MOUSE_UP, onMouseGoUp);
		}
		
		/**
		 * Internal mouseUp handler.
		 * @param event The MouseEvent passed by the system.
		 */
		override protected function onMouseGoUp(event:MouseEvent):void
		{
			stage.removeEventListener(MouseEvent.MOUSE_UP, onMouseGoUp);
		}
	}
	
	
}