package com.bit101.components
{
    import flash.events.MouseEvent;

    /**
     * ...
     * @author kristi
     */
    public class  RadioButtonHandler
    {
        [Bindable] public var selectedLabel:String;
        private var _buttons:Array = [];

        public function addRadioButton(button:RadioButton):void
        {
            _buttons.push(button);
            button.addEventListener(MouseEvent.CLICK, updateSelectedLabel);
        }
        private function updateSelectedLabel(m:MouseEvent):void
        {
            selectedLabel = (m.currentTarget as RadioButton).label;
        }
    }

}