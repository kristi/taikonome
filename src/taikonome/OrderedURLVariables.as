package taikonome {
	import flash.net.URLVariables;
	import mx.utils.OrderedObject;
	dynamic public class OrderedURLVariables extends OrderedObject {
		public function OrderedURLVariables(str:String = null){
			if (str != null){
				decode(str);
			}
		}
		
		public function decode(str:String):void {
			for each (var pair:String in str.split('&')){
				var keyVal:Array = pair.split('=');
				this[keyVal[0]] = keyVal[1];
			}
		}
		
		public function toString():String {
			var str:String = null;
			for (var key:String in this){
				if (str == null){
					str = key + '=' + this[key];
				} else {
					str += '&' + key + '=' + this[key];
				}
			}
			return str;
		}
	}
}

