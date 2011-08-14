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
		public var color:uint = 0xDDDDDD;
		public var colorActive:uint = 0x00C6FF;
		
		public var index:int = 0;
		public var state:int = 0;
		
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
		
		// Toggle the button selection and update button
		public function toggleSelect():void {
			this.selected = !this.selected;
			//_selected = !_selected;
			
			_down = _selected;
			drawFace();
			_face.filters = [getShadow(1, _selected)];
		}
		
		// Update button face when changing the selected value
		override public function set selected(value:Boolean):void
		{
			var old_selected:Boolean = _selected;
			if(!_toggle)
			{
				value = false;
			}
			
			_selected = value;
			_down = _selected;
			
			if (old_selected != _selected) {
				_face.filters = [getShadow(1, _selected)];
				drawFace();
				dispatchEvent(new Event(SELECTED_CHANGED));
			}
		}
		
		/**
		 * Draws the face of the button, color based on state.
		 */
		override protected function drawFace():void
		{
			_face.graphics.clear();
			//if(_selected && !_down) {
				//_face.graphics.beginFill(colorActive);
			//} else if(_down && !_selected) {
				//_face.graphics.beginFill(0x00ff00);
			//} else if (_selected && _down) {
				//_face.graphics.beginFill(0xff0000);
			//} else {
				//_face.graphics.beginFill(color);
			//}
			if(_selected ) {
				_face.graphics.beginFill(colorActive);
			} else {
				_face.graphics.beginFill(color);
			}
			//_face.graphics.drawRect(0, 0, _width - 2, _height - 2);
			_face.graphics.drawRoundRect(0, 0, _width - 2, _height - 2, 3, 3);
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
				selected = !selected; 
				//drawFace();
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
				selected = !selected;
			}
			//_down = true;
			//drawFace();
			//_face.filters = [getShadow(1, true)];
			stage.addEventListener(MouseEvent.MOUSE_UP, onMouseGoUp);
		}
		
		/**
		 * Internal mouseUp handler.
		 * @param event The MouseEvent passed by the system.
		 */
		override protected function onMouseGoUp(event:MouseEvent):void
		{
			//if(_toggle  && _over)
			//{
				//_selected = !_selected;
			//}
			//_down = _selected;
			//drawFace();
			//_face.filters = [getShadow(1, _selected)];
			stage.removeEventListener(MouseEvent.MOUSE_UP, onMouseGoUp);
		}
	}
	
	
}