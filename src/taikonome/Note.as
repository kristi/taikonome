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
		public var duration	:uint;
		public var volume		:Number;
		public var index:int;
		
		[Embed(source = "../assets/shime67.wav", mimeType = "application/octet-stream")]
		public static const WavFile:Class;
		public static const sound:WavSound = new WavSound(new WavFile() as ByteArray);
		
		public function Note( vol:Number = 1 )
		{
			index = 0;
			duration = sound.samples.length;
			//frequency = sound.playbackSettings.sampleRate;
			volume = vol
		}
		public function getNextNumber():Number {
			// TODO Stereo sounds
			return index + 1 < duration ? volume * sound.samples.left[index++]: 0;
		}
		
		public function hasNext():Boolean {
			return index + 1 < duration;
		}
		
		public function reset(vol:Number = 1):Note {
			index = 0;
			volume = vol;
			return this;
		}
	}
}