package taikonome {
	import flash.events.Event;
	import flash.utils.ByteArray;
	import flash.utils.Endian;
	import org.as3wavsound.sazameki.core.AudioSamples;
	import org.as3wavsound.sazameki.core.AudioSetting;
	import org.as3wavsound.sazameki.format.wav.chunk.WavdataChunk;
	import org.as3wavsound.sazameki.format.wav.Wav;
	import fr.kikko.lab.ShineMP3Encoder;
	import flash.events.ErrorEvent;
	
	
	/**
	 * Hack together a class to generate a wav file from
	 * raw ByteArray data
	 * @author Kristi Tsukida
	 */
	public class WavUtil {
		
		/**
		 * Code based on makemachine.demos.audio.microphone.capture.WavEncoder
		 * Input is a ByteArray of floats
		 * @param	samples
		 * @return
		 */
		public static function encodeFloatByteArray( samples:ByteArray, channels:uint = 2, sampleRate:uint = 44100, bitRate:uint = 16):ByteArray {
			samples.position = 0;
			
			// 32 bit floats = 4 bytes per float
			// 16 bit shorts = 2 bytes per short
			var dataBytes:uint = samples.length >> 1; // # of bytes when data is in shorts
			var numSamples:uint = (samples.length >> 2 )/ channels;
			
			var output:ByteArray = new ByteArray();
			output.length = 0;
			output.endian = Endian.LITTLE_ENDIAN;
			// ChunkID
			output.writeUTFBytes( "RIFF" );
			// ChunkSize
			output.writeInt( uint( dataBytes + 44 ) );
			// Format
			output.writeUTFBytes( "WAVE" );
			
			// ==== "fmt " chunk ====
			output.writeUTFBytes( "fmt " );
			// fmt chunk size
			output.writeInt( uint( 16 ) );
			// Audio format (PCM=1)
			output.writeShort( uint( 1 ) );
			// NumChannels
			output.writeShort( channels );
			// SampleRate (samples per second)
			output.writeInt( sampleRate );
			// ByteRate (bytes per second)
			output.writeInt( uint( sampleRate * channels * ( bitRate >> 3 ) ) );
			// BlockAlign
			output.writeShort( uint( channels * ( bitRate >> 3 ) ) );
			// Bits per sample
			output.writeShort( bitRate );
			
			// ==== "data" chunk ====
			output.writeUTFBytes( "data" );
			output.writeInt( dataBytes );
			//output.writeBytes( input );
			
			// Convert data from floats to shorts
			var numReadSamples:int = 0;
			samples.position = 0;
			while ( samples.bytesAvailable > 0 ) {
				numReadSamples++;
				output.writeShort( samples.readFloat() * 0x7fff );
			}
			
			// Verify number of samples
			if (numReadSamples != numSamples * channels) {
				trace("WavUtil.encodeFloatByteArray: Error converting wav data. Expected " + numSamples + " samples but read " + numReadSamples + " samples");
			}
			
			return output;
		}
		
		
		/**
		 * Input ByteArray of shorts(bitRate=16) or bytes(bitRate=8)
		 */
		public static function encodeByteArray(rawData:ByteArray, channels:uint = 2, sampleRate:uint = 44100, bitRate:uint = 16):ByteArray {
			var WAV:Wav = new Wav();
			var setting:AudioSetting = new AudioSetting(channels, sampleRate, bitRate);
			var wavChunk:WavdataChunk = new WavdataChunk();
			
			var samples:AudioSamples = wavChunk.decodeData(rawData, setting);
			return WAV.encode(samples);
		}
		/**
		 * Input vector of floating point numbers ranging from -1 to 1.
		 * If 2-channels assume samples are interleaved so that
		 * the left samples are vec[0],vec[2],... 
		 * and the right samples are vec[1],vec[3],...
		 */
		public static function encodeVector(vec:Vector.<Number>, channels:uint = 2, sampleRate:uint = 44100, bitRate:uint = 16):ByteArray {
			var WAV:Wav = new Wav();
			var setting:AudioSetting = new AudioSetting(channels, sampleRate, bitRate);
			var samples:AudioSamples = new AudioSamples(setting);
			for (var i:int = 0; i < vec.length; i++) {
				if (i % channels == 0) {
					samples._left.push(vec[i]);
				} else {
					samples._right.push(vec[i]);
				}
			}
			return WAV.encode(samples);
		}
		
		// Just trying to figure how the code works
		// Don't actually run this function!
		//private function _encode_haxored(samples:AudioSamples):ByteArray {
			//var fmt:WavfmtChunk = new WavfmtChunk();
			//var data:WavdataChunk = new WavdataChunk();
//
			//_chunks = new Vector.<Chunk>;
			//_chunks.push(fmt);
			//_chunks.push(data);
//
			//data.setAudioData(samples);
			//fmt.setSetting(samples.setting);
			//
			//return toByteArray();//Chunk.toByteArray()
				//var result:ByteArray = new ByteArray();
				//result.endian = ENDIAN;
				//result.writeUTFBytes(_id); //WAVE
				//var data:ByteArray = encodeData(); //List.encodeData
					//var data:ByteArray = new ByteArray();
					//data.writeUTFBytes(_type);
					//for (var i:int = 0; i < _chunks.length; i++) {
						//data.writeBytes(_chunks[i].toByteArray()); // Chunk.toByteArray
							//var chunk:Chunk = _chunks[i]; 
							//var chunkResult:ByteArray = new ByteArray();
							//chunkResult.endian = ENDIAN;
							//chunkResult.writeUTFBytes(_id);
							//var chunkData:ByteArray = chunk.encodeData(); // Chunk.encodeData
							//chunkResult.writeUnsignedInt(chunkData.length);
							//chunkResult.writeBytes(chunkData);	
							//data.writeBytes(chunkResult);
					//}
					// end List.encodeData
				//result.writeUnsignedInt(data.length);
				//result.writeBytes(data);	
				//return result;
			//end Chunk.toByteArray
		//}
	}
	
}