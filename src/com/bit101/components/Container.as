package com.bit101.components
{
    /**
     * This file is not part of the upstream minimalcomps library.
     * It has been added to allow minimalcomps to use mxml.
     * Original code and concept by Ryan Campbell
     * http://www.ryancampbell.com/2009/08/26/using-mxml-without-flex-example-and-source/
     */
	import com.bit101.components.Component;
	
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.events.Event;

	[DefaultProperty( "children" )]
	public class Container extends Component
	{
		private var _children:Vector.<DisplayObject>;
		private var childrenChanged:Boolean = false;
		
		/**
		 * Array of DisplayObject instances to be added as children
		 */
		public function get children():Vector.<DisplayObject>
		{
			return _children;
		}
		
		public function set children( value:Vector.<DisplayObject> ):void
		{
			if ( _children != value )
			{
				_children = value;
				childrenChanged = true;
				invalidate();
			}
		}
		
		public function Container(parent:DisplayObjectContainer = null, xpos:Number = 0, ypos:Number =  0)
		{
			super(parent, xpos, ypos);
		}
		
		override protected function onInvalidate(event:Event) : void
		{
			if ( childrenChanged )
			{
				while ( numChildren > 0 )
				{
					removeChildAt( 0 );
				}
				
				for each ( var child:DisplayObject in children )
				{
					addChild( child );
				}
				
				childrenChanged = false;
			}
			
			super.onInvalidate(event);
		}
	}
}