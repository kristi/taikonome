package taikonome {
	import flash.net.URLVariables;
	import mx.utils.OrderedObject;
	dynamic public class OrderedURLVariables extends OrderedObject {
		public function OrderedURLVariables(str:String = null){
			decode(str);
		}
		
		public function decode(str:String):void {
			if (str == null) {
				return;
			}
			for each (var pair:String in str.split('&')){
				var keyVal:Array = pair.split('=');
				this[keyVal[0]] = keyVal[1];
			}
		}
		
		public function toString():String {
			var str:String = null;
			for (var key:String in this) {
				var val:String = this[key];
				if (val == null) { val = ''; }
				if (str == null){
					str = key + '=' + val;
				} else {
					str += '&' + key + '=' + val
					;
				}
			}
			return str;
		}
	}
}

