package com.bit101.components
{
    /**
     * This file is not part of the upstream minimalcomps library.
     * It has been added to allow minimalcomps to use mxml.
     * Original code and concept by Ryan Campbell
     * http://www.ryancampbell.com/2009/08/26/using-mxml-without-flex-example-and-source/
     */
	public class Application extends Container
	{
		public function Application()
		{
			super();
			Component.initStage( stage );
		}
	}
}