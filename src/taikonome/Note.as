package taikonome
{
	import flash.utils.ByteArray;
	import org.as3wavsound.WavSound;
	import org.as3wavsound.sazameki.format.wav.Wav;
	/**
	 * Represents one note in the metronome
     * 
	 * Use AS3WavSound to read a wav file
	 */
	public class Note
	{
		protected var _index	:int;
		protected var _duration	:int;
		protected var _frequency:Number;
		protected var _amp		:Number;
		
		[Embed(source = "../assets/shime67.wav", mimeType = "application/octet-stream")]
		public const WavFile:Class;
		public const sound:WavSound = new WavSound(new WavFile() as ByteArray);
		
		public function Note( duration:int, freq:Number, maxAmplitude:Number = 1 )
		{
			_index = 0;
			_duration = sound.samples.length;
			_frequency = sound.playbackSettings.sampleRate;
			_amp = maxAmplitude;
		}
		
		public function getNext():int {
			return _index + 1 < _duration ? _index++ : _index;
		}
		
		public function getNextFloat():Number {
			return _index + 1 < _duration ? sound.samples.left[_index++]: 0;
		}
		
		public function get frequency():Number {
			return _frequency;
		}
		
		public function hasNext():Boolean {
			return _index + 1 < _duration;
		}
		
		// -- do a little fade out here to prevent pop
		public function get amplitude():Number {
			return ( 1 - ( _index / _duration ) ) * _amp;
		}

	}
}