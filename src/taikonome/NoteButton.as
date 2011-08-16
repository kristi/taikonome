package taikonome
{
	import com.bit101.components.PushButton;
	import com.bit101.components.Style;
	import flash.display.DisplayObjectContainer;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	
	/**
	 * ...
	 * @author Kristi Tsukida
	 */
	public class NoteButton extends PushButton 
	{
		public static const SELECTED_CHANGED:String = "selectedChanged";
		public static const LEVEL_BITS:int = 2;
		public static const MAX_LEVEL:int = (1 << LEVEL_BITS) - 1;
		public static var volumeLevels:Vector.<Number> = new <Number>[0, 0.2, 0.5, 1];
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
		
		// 
		// Mouse handlers
		// Overridden to allow click+drag selection
		//
		override protected function onMouseOver(event:MouseEvent):void
		{
			_over = true;
			if (_toggle && event.buttonDown) { 
				level = (level + MAX_LEVEL) % (1 << LEVEL_BITS);  // (level - 1) % 4
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
				level = (level + MAX_LEVEL) % (1 << LEVEL_BITS);
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