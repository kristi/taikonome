package taikonome
{
	import com.adobe.crypto.MD5;
	import com.bit101.components.HUISlider;
	import com.bit101.components.InputText;
	import com.bit101.components.Label;
	import com.bit101.components.PushButton;
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.events.FocusEvent;
	import flash.events.MouseEvent;
	import flash.events.SampleDataEvent;
	import flash.external.ExternalInterface;
	import flash.media.Sound;
	import flash.media.SoundChannel;
	import flash.utils.ByteArray;
	import flash.utils.clearTimeout;
	import flash.utils.setTimeout;
	import mx.utils.Base64Decoder;
	import mx.utils.Base64Encoder;
	import mx.utils.StringUtil;
	
	/**
	 * Taikonome (http://taikonome.com)
	 * A Simple Taiko Metronome
	 * 
	 * Based on note visualization code by Jeremy Brown
	 * http://labs.makemachine.net/2010/11/visualizing-notes-and-timing/
	 * GUI uses MinimalComponents by Keith Peters
	 * http://www.minimalcomps.com/
	 * Wav reading uses As3wavsound library released by Benny Bottema
	 * and based on code by Takaaki Yamazaki
	 * http://code.google.com/p/as3wavsound/
	 * Taiko sound files generously provided by David Cheetham
	 * 
	 * Open Source License: AGPL (http://www.gnu.org/licenses/agpl.txt)
	 * (Distributions and application servers are required to release source code)
	 * 
	 * Copyright (C) 2011 Kristi Tsukida
     *
	 * This program is free software: you can redistribute it and/or modify
	 * it under the terms of the GNU Affero General Public License as published by
	 * the Free Software Foundation, either version 3 of the License, or
	 * (at your option) any later version.
	 * 
	 * This program is distributed in the hope that it will be useful,
	 * but WITHOUT ANY WARRANTY; without even the implied warranty of
	 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	 * GNU Affero General Public License for more details.
	 * 
	 * You should have received a copy of the GNU Affero General Public License
	 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
	 *
	 * @author Kristi Tsukida
	 */
	[SWF(backgroundColor="0xFDF8F2",width="770",height="300",frameRate="60")]
	public class Taikonome extends Sprite
	{
		public static const VERSION:String = "0.3";
		public static const BUFFER_SIZE:int = 8192;
		public static const SAMPLE_RATE:int = 44100;
		public static const MILS_PER_SEC:int = 1000;
		public static const SECONDS_PER_MINUTE :int = 60;
		
		public static const WIDTH:int = 700;
		public static const NOTEBUTTON_HEIGHT:int = 25;
		
		public static const NOTE_DURATION  :int = 700; // in samples
		public static const LATENCY_FUDGE:int = 30; // milliseconds
		public static const TIME_3_4   :String = '3/4';
		public static const TIME_4_4   :String = '4/4';
		
		public static const ALPHA_PLAY:Number = 0.8;
		public static const ALPHA_OFF:Number = 0.3;
		
		public var eighthnotes :Boolean;
		public var sxthnnotes :Boolean;
		
		protected var _outsound:Sound;
		protected var _channel:SoundChannel;
		protected var _isPlaying:Boolean;
		protected var _latency:int; // milliseconds (how far ahead the sound buffer is)
		
		protected var _tempo:int;
		protected var _signature :String;
		protected var _step   :int;
		protected var _noteQueue  :Array;
		protected var _isTempoChanged:Boolean = false;
		
		protected var _quarterNoteButton:Vector.<NoteButton>;
		protected var _wholeNoteButton:Vector.<NoteButton>;
		protected var _shimeNoteButton:Vector.<NoteButton>;
		
		protected var _gridContainer:Sprite;
		protected var _timeClockLabel:Label;
		protected var _musicClockLabel:Label;
		protected var _playButton:PushButton;
		protected var _inputText:InputText;
		
		protected var _tempoSlider:HUISlider
		protected var _volumeSlider:HUISlider
		
		protected var _doUpdateHash:Boolean = true;
		protected var _hashChangeTime:uint = 0;
		protected var _base64Encoder:Base64Encoder;
		protected var _base64Decoder:Base64Decoder;
		
		// Debug clicking
		public function onClickStage(e:MouseEvent):void{
			trace(e.target,e.target.name);
		}
		
		/**
		 * Constructor
		 */
		public function Taikonome()
		{
			eighthnotes = true;
			sxthnnotes = false;
			_signature = TIME_4_4;
			_step = -1;
			_noteQueue = [];
			_outsound = new Sound();
			_base64Encoder = new Base64Encoder();
			_base64Encoder.insertNewLines = false;
			_base64Decoder = new Base64Decoder();
			
			if (stage)
				init();
			else
				addEventListener(Event.ADDED_TO_STAGE, init);
		}

		public function getExternalHash():String {
			var h:String = ExternalInterface.call("getHash");
			// Strip leading # sign
			if (h!=null && h.charAt(0) == "#") {
				h = h.substr(1);
			}
			return h;
		}
		public function setExternalHash(s:String):void {
			ExternalInterface.call("setHash",sanitize(s));
		}

		public function hashExternalChange():void {
			hashToBeat(getExternalHash());
		}
		
		public function batchHashChange():void {
			if (_hashChangeTime != 0) {
				clearTimeout(_hashChangeTime);
			}
			_hashChangeTime = setTimeout(setExternalHash, 300, beatToHash());
		}
		
		private function init(e:Event = null):void
		{
			removeEventListener(Event.ADDED_TO_STAGE, init);
			// entry point
			stage.align = StageAlign.TOP;
			stage.scaleMode = StageScaleMode.NO_SCALE;
			createDisplay();
			
			ExternalInterface.addCallback("flashHash", hashExternalChange);
			hashExternalChange();
		}
		
		
		// ----------------------------------------------
		//
		// 	-- sound
		//
		// ----------------------------------------------
		/**
		 * Toggles between play and stop
		 */
		protected function togglePlayback(event:Event = null):void
		{
			if (_isPlaying)
			{
				stop();
			}
			else
			{
				play();
			}
		}
		
		/**
		 * Stops playback, updates UI
		 */
		protected function stop():void
		{
			if (_channel && _isPlaying)
			{
				_isPlaying = false;
				_playButton.label = 'Play';
				_outsound.removeEventListener(SampleDataEvent.SAMPLE_DATA, onSampleData);
				_channel.stop();
				_channel = null;
				removeEventListener(Event.ENTER_FRAME, onPlaybackEnterFrame);
			}
		}
		
		/**
		 * Starts playback, updates UI
		 */
		protected function play():void
		{
			if (!_isPlaying)
			{
				_isPlaying = true;
				_playButton.label = 'Stop';
				addEventListener(Event.ENTER_FRAME, onPlaybackEnterFrame);
				_outsound.addEventListener(SampleDataEvent.SAMPLE_DATA, onSampleData);
				_channel = _outsound.play();
			}
		}
		
		/**
		 * Fill the sound buffer with data
		 */
		public function onSampleData( event:SampleDataEvent ):void
		{
			var position:int;
            if (_channel)
            {
                // latency is the number of milliseconds it will take from now
                // for the sound to play.
                _latency = ((event.position / 44.1) - _channel.position);
            }
			
			for( var i:int = 0; i < BUFFER_SIZE; i++ )
			{
				position = event.position + i;
				
				// -- hope to find a better way to determine timing vars
				// -- approach for adding notes to the queue seems to work well though
				
				var n:int;
				
				// -- 3/4 time
				if( _signature == TIME_3_4 )
				{
					n  = position / ( SAMPLE_RATE / _tempo * SECONDS_PER_MINUTE / 12 );
					if( n != _step )
					{
						_step = n;
						
						if( _step % 24 == 0 ) {
							_noteQueue.push( new Note( NOTE_DURATION, 1760 ) );
						} else if( _step % 8 == 0 ) {
							_noteQueue.push( new Note( NOTE_DURATION * .25, 880, .5 ) );
						}
					}
				}
				
				// -- 4/4 time
				if( _signature  == TIME_4_4 )
				{
					n  = position / ( SAMPLE_RATE / _tempo * SECONDS_PER_MINUTE / 32  );
					
					if( n != _step )
					{
						_step = n;
						// 16 steps per eighth note, 32 eighth notes per line
						if (_shimeNoteButton[int(_step/16) % 32].selected)
						{
							// -- whole note
							if( _step % 128 == 0 ) {
								_noteQueue.push( new Note( NOTE_DURATION, 1760 ) );
								// -- quater
							} else if( _step % 32 == 0 )  {
								_noteQueue.push( new Note( NOTE_DURATION, 880, .7 ) );
								// -- 8th notes
							} else if( eighthnotes && _step % 16 == 0 )  {
								_noteQueue.push( new Note( NOTE_DURATION, 440, .5 ) );
								// -- 16th notes
							}else if( ( _step % 8 == 0  ) && sxthnnotes ) {
								_noteQueue.push( new Note( NOTE_DURATION * .5, 220, .5 ) );
							}
						}
					}
				}
				
				// -- create the samples, if there are multiple notes in the queue we us addition to merge them
				var sample:Number = 0;
				for each( note in _noteQueue )  {
					if( note.hasNext() ) {
						sample += note.getNextFloat();
					}
				}
				
				// Change volume
				// Use squared to get a better dynamic range
				// TODO fade volume change so you don't get little pops when changing
				sample *= Math.pow(_volumeSlider.value / 100, 1.8) * 2; // 1.8 seems ok experimentally
				
				event.data.writeFloat( sample * .8 ); //L?
				event.data.writeFloat( sample * .8 ); //R?
			}
			
			// -- store left over notes in new array for next iteration
			// -- notes can be left over if not all positions were written to the buffer
			// -- for instance, if a note with a duration of 1000 samples starts writing to the buffer @
			// -- iteration 8000, only 192 samples are written
			var temp:Array = [];
			var note:Note;
			
			for each( note in _noteQueue ) {
				if( note.hasNext() ) {
					temp.push( note );
				}
			}
			
			_noteQueue = temp;
		}
		protected function onSampleDataDummy(event:SampleDataEvent):void
		{
			var bytes:ByteArray = new ByteArray();
			
			for (var i:int = 0; i < BUFFER_SIZE; i++)
			{
				bytes.writeFloat(0);
			}
			
			event.data.writeBytes(bytes);
		}
		
		/**
		 * Updates the grid of squares to reflect the current 1/8, 1/4 and measure
		 * Updates the timecode clocks
		 * Not optimized
		 */
		protected function onPlaybackEnterFrame(event:Event):void
		{
			if (_channel)
			{
				var samplesElapsed:int = ((_channel.position + LATENCY_FUDGE) / 1000) * SAMPLE_RATE;
				
				var eighthNoteLength:int = SAMPLE_RATE * .5 * 60 / _tempo; // eighth note is half a beat
				var quarterNoteLength:int = eighthNoteLength * 2;
				var measureLength:int = quarterNoteLength * 4;
				
				var eighth:int = Math.floor(samplesElapsed / eighthNoteLength % 32);
				var quarter:int = Math.floor((samplesElapsed / quarterNoteLength % 16));
				var measure:int = Math.floor((samplesElapsed / measureLength % 4));
				
				var current:int;
				var i:int = 0;
				
				// -- current 1/8 note
				for (i = 0; i < _shimeNoteButton.length; i++)
				{
					if (i == eighth)
					{
						_shimeNoteButton[i].alpha = ALPHA_PLAY
					}
					else
					{
						_shimeNoteButton[i].alpha = ALPHA_OFF;
					}
				}
				
				// -- current 1/4 note
				for (i = 0; i < _quarterNoteButton.length; i++)
				{
					if (i == quarter)
					{
						_quarterNoteButton[i].alpha = ALPHA_PLAY;
					}
					else
					{
						_quarterNoteButton[i].alpha = ALPHA_OFF;
					}
				}
				
				// -- current measure
				for (i = 0; i < _wholeNoteButton.length; i++)
				{
					if (i == measure)
					{
						_wholeNoteButton[i].alpha = ALPHA_PLAY;
					}
					else
					{
						_wholeNoteButton[i].alpha = ALPHA_OFF;
					}
				}
				
				// -- clocks
				_timeClockLabel.text = 'Time: ' + toTimecode(String(Math.floor(_channel.position / 1000 / 60))) + ':' + toTimecode(String(Math.floor(_channel.position / 1000 % 60))) + ':' + toTimecode(String(Math.floor(_channel.position / 10 % 100)));
				
				//_musicClockLabel.text = 'Music Time: ' + toTimecode(String(measure + 1)) + ':' + toTimecode(String(quarter + 1)) + ':' + toTimecode(String(eighth + 1));
			}
		}
		
		/**
		 * Update the value of the tempo
		 */
		protected function onTempoChange(event:Event):void
		{
			_tempo = Math.round(_tempoSlider.value);
			_isTempoChanged = true;
		}
		
		
		/**
		 * Creates rows of squares indicating 1/8, 1/4 and measures
		 * Also creates button and text fields
		 */
		public function createDisplay():void
		{
			var i:int;
			var w:Number;
			var noteButton:NoteButton;
			var button:PushButton;
			var label:Label;
			var padding:int = 4;
			
			_gridContainer = new Sprite();
			
			w = (WIDTH / 32) - padding;
			_shimeNoteButton = new Vector.<NoteButton>();
			
			// -- eighth note squares
			for (i = 0; i < 32; i++)
			{
				noteButton = new NoteButton(_gridContainer);
				//if (int(i / 8) % 2 ) noteButton.color = 0xCCCCCC;
				//else noteButton.color = 0xEEEEEE;
				
				noteButton.width = w;
				noteButton.height = NOTEBUTTON_HEIGHT;
				noteButton.x = (i * w) + (i * padding);
				noteButton.y = 22;
				noteButton.alpha = ALPHA_OFF;
				noteButton.index = i;
				noteButton.addEventListener(NoteButton.SELECTED_CHANGED, function(...u):void {
						if (_doUpdateHash) {
							batchHashChange();
						}
					});
				
				_shimeNoteButton.push(noteButton);
			}
			
			// -- quarter note squares
			w = (WIDTH / 16) - padding;
			_quarterNoteButton = new Vector.<NoteButton>();
			for (i = 0; i < 16; i++)
			{
				noteButton = new NoteButton(_gridContainer);
				if (i% 2 ) noteButton.color = 0xCCCCCC;
				else noteButton.color = 0xEEEEEE;
				noteButton.width = w;
				noteButton.height = 6;
				noteButton.y = 10;
				noteButton.x = (i * w) + (i * padding);
				noteButton.alpha = ALPHA_OFF;
				noteButton.index = i;
				
				_quarterNoteButton.push(noteButton);
				noteButton.mouseEnabled = false; // Disable mouse clicks
			}
			
			// -- whole note squares
			w = (WIDTH / 4) - padding;
			_wholeNoteButton = new Vector.<NoteButton>();
			for (i = 0; i < 4; i++)
			{
				//noteButton = getNoteSprite(w, 0x00C6FF);
				noteButton = new NoteButton(_gridContainer);
				noteButton.color = 0xEEEEEE;
				noteButton.y = 0;
				noteButton.x = (i * w) + (i * padding);
				noteButton.width = w;
				noteButton.height = 6;
				noteButton.alpha = ALPHA_OFF;
				noteButton.index = i;
				noteButton.mouseEnabled = false; // Disable mouse clicks
				
				_wholeNoteButton.push(noteButton);
			}
			
			_gridContainer.x = 40;
			_gridContainer.y = 10;
			
			addChild(_gridContainer);
			
			var y:int = 90;
			_timeClockLabel = new Label(this, 40, y, 'Time: 00:00:00');
			//_musicClockLabel = new Label(this, 150, y, 'Music Time: 01:04:16');
			
			_volumeSlider = new HUISlider(this, 130, y, 'Volume', null);
			_volumeSlider.minimum = 0;
			_volumeSlider.maximum = 100;
			_volumeSlider.value = 50;
			_volumeSlider.width = 160;
			_volumeSlider.labelPrecision = 0;
			
			_tempoSlider = new HUISlider(this, 270, y, 'Tempo', onTempoChange);
			_tempoSlider.minimum = 20;
			_tempoSlider.maximum = 400;
			_tempoSlider.value = _tempo = 160;
			_tempoSlider.width = 250;
			_tempoSlider.labelPrecision = 0;
			
			_playButton = new PushButton(this, 507, y, 'Play', togglePlayback);
			_playButton.toggle = true;
			
			button = new PushButton(this, 630, y, 'Clear', clearBeat);
			
			y = 150;
			label = new Label(this, 40, y, 'Presets');
			button = new PushButton(this, 90, y, 'Straight', setupStraight);
			button = new PushButton(this, 200, y, 'Horsebeat', setupHorsebeat);
			button = new PushButton(this, 310, y, 'Matsuri', setupMatsuri);
			
			y = 180;
			button = new PushButton(this, 40, y, 'Random Beat', setRandom);
			_inputText = new InputText(this, 160, y, 'Input some text', setFromInput);
			_inputText.height = 20;
			_inputText.width = 285;
			_inputText.addEventListener(FocusEvent.FOCUS_IN, clearInput);
			button = new PushButton(this, 450, y, 'Generate from text', setFromInput);
			
			label = new Label(this, 660, y+5, 'Taikonome v'+VERSION);
		}
		public function setRandom(event:Event=null):void {
			var b:ByteArray = new ByteArray();
			var v:Vector.<int> = new Vector.<int>();
			// Note probabilities
			var p:Vector.<Number> = new <Number>[.8, .5, .5, .5, .6, .5, .5, .5, .6, .5, .5, .5, .6, .5, .5, .5, 
			                                     .7, .5, .5, .5, .6, .5, .5, .5, .6, .5, .5, .5, .6, .5, .5, .5, ];
			_doUpdateHash = false;
			for (var i:int = 0; i < _shimeNoteButton.length; i++) {
				_shimeNoteButton[i].selected = (Math.random() < p[i]);
			}
			// Generate from md5
			//for (var i:int = 0; i < 3; i++) {
				//b.writeUnsignedInt(Math.random() * uint.MAX_VALUE);
			//}
			//hashToBeat(MD5.hashBytes(b))
			setExternalHash(beatToHash());
			_doUpdateHash = true;
		}
		
		public function clearInput(event:Event=null):void {
			_inputText.text = "";
			_inputText.removeEventListener(FocusEvent.FOCUS_IN, clearInput);
		}
		public function setFromInput(event:Event=null):void {
			//hashToBeat(_inputText.text);
			setExternalHash(_inputText.text);
		}
		
		/**
		 * Make sure our timecode string has at least two digits
		 */
		protected function toTimecode(value:String):String
		{
			if (value.length < 2)
			{
				return '0' + value;
			}
			return value;
		}
		
		public function clearBeat(event:Event=null):void {
			var button:NoteButton;
			for (var i:int = 0; i < 32; i++)
			{
				button = _shimeNoteButton[i];
				button.selected = false;
			}
		}
		
		public function setupHorsebeat(event:Event=null):void {
			var button:NoteButton;
			for (var i:int = 0; i < 32; i++)
			{
				button = _shimeNoteButton[i];
				button.selected = (i % 4 != 1);
			}
		}
		
		public function setupStraight(event:Event=null):void {
			var button:NoteButton;
			for (var i:int = 0; i < 32; i++)
			{
				button = _shimeNoteButton[i];
				button.selected = (i % 2 == 0);
			}
		}
		
		public function setupMatsuri(event:Event=null):void {
			var button:NoteButton;
			for (var i:int = 0; i < _shimeNoteButton.length; i++)
			{
				button = _shimeNoteButton[i];
				button.selected = (i % 4 != 1) && (i % 8 != 7);
			}
		}
		
		
		
		/**
		 * Convert beats into hash string
		 */
		public function beatToHash(bits:uint = 1):String {
			if (32 % bits != 0) { throw new Error("bits must be factor of 32"); };
			var str:String;
			// Convert vector to ByteArray
			var b:ByteArray = new ByteArray();
			var num:uint = 0;
			var shift:uint = 0;
			var s:int = 0;
			var num_selected:int = 0;
			var len:int = _shimeNoteButton.length;
			for (var i:uint = 0; i < len; i ++) {
				s = uint(_shimeNoteButton[i].selected);
				if (s > 0) { num_selected++; }
				num += s << (bits * shift++);
				if (shift * bits >= 32 || i + 1 == len) { // 32-bit ints
					b.writeInt(num);
					shift = 0;
					num = 0;
				}
			}
			if (num_selected == 0) { return ""; }
			b.deflate();  // Compress byte array
			_base64Encoder.encodeBytes(b);
			str = _base64Encoder.toString();
			
			// Substitute chars to make url-friendly
			var char62:RegExp = /\+/g; 
			var char63:RegExp = /\//g; 
			str = str.replace(char62, '-');
			str = str.replace(char63, '_');
			
			// Remove trailing equals
			var equals:RegExp = /=*$/;
			str = str.replace(equals, '');
			
			return str;
		}
		public function sanitize(str:String):String {
			if (str == null || str.length == 0) { return str; }
			str = StringUtil.restrict(str, "a-zA-Z0-9\\-_");
			return str;
		}
		/**
		 * Convert a hash string into beats
		 */
		public function hashToBeat(str:String = null, bits:int = 1):String {
			var b:ByteArray;
			var i:int = 0;
			var num:uint;
			
			if (str == null) { return str; }
			if (32 % bits != 0) { throw new Error("bits must be factor of 32"); };
			
			_doUpdateHash = false;
			
			if (str.length == 0) {
				// Set all to zero
				for (i = 0; i < _shimeNoteButton.length; i++) {
					_shimeNoteButton[i].selected = false;
				}
				_doUpdateHash = true;
				return str;
			}
			
			str = sanitize(str);
			
			
			
			// Undo url substitutions
			var char62:RegExp = /-/g; 
			var char63:RegExp = /_/g; 
			str = str.replace(char62, '+');
			str = str.replace(char63, '/');
			
			// Decode base64
			var base64Success:Boolean = false;
			for (i = 2; i >= 0; i-- ) {
				try {
					// String may need trailing equals
					_base64Decoder.decode(str + StringUtil.repeat('=', i));
					b = _base64Decoder.toByteArray();
					base64Success = true;
					break;
				} catch (e:Error) { trace(e); }
			}
			var inflateSuccess:Boolean = false;
			if (base64Success) {
				//throw(new Error("Unable to decode hash string"));
				
				// Make sure there are a whole number of ints
				b.position = b.length;
				for (i = 0; i < (b.position % 4); i++) {
					b.writeByte(0);
				}
				
				// Decompress
				try {
					b.inflate();
					inflateSuccess = true;
				} catch (e:Error) {
					// Do nothing
					// Probably random user input string
				}
			}
			if (!inflateSuccess) {
				// Use md5 hash
				MD5.hash(str);
				b = MD5.digest;
			}
			
			// Convert ByteArray to beats
			var mask:uint = (1 << bits) - 1;  // e.g. if bits=4, mask=0...01111 (in binary)
			var len:int = _shimeNoteButton.length;
			i = 0;
			b.position = 0; // reset b so we can read from it
			while (b.position < b.length) {
				num = b.readUnsignedInt();
				for (var shift:int = 0; shift < 32; shift+=bits) {
					var val:Boolean = ((num >> shift) & mask) > 0;
					if (i < len) { 
						_shimeNoteButton[i++].selected = val;
					} else if (val) {
						// Toggle selected if value is true
						_shimeNoteButton[i % len].selected = !_shimeNoteButton[i++ % len].selected;
					}
				}
			}
			_doUpdateHash = true;
			return str;
		}
	}
}