package taikonome {
	import com.adobe.crypto.MD5;
	import com.bit101.components.HUISlider;
	import com.bit101.components.InputText;
	import com.bit101.components.Label;
	import com.bit101.components.PushButton;
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.events.FocusEvent;
	import flash.events.MouseEvent;
	import flash.events.ProgressEvent;
	import flash.events.SampleDataEvent;
	import flash.external.ExternalInterface;
	import flash.media.Sound;
	import flash.media.SoundChannel;
	import flash.net.FileReference;
	import flash.utils.ByteArray;
	import flash.utils.clearTimeout;
	import flash.utils.setTimeout;
	import fr.kikko.lab.ShineMP3Encoder;
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
	[SWF(backgroundColor="0xFDF8F2",width="770",height="500",frameRate="60")]
	
	public class Taikonome extends Sprite {
		public static const VERSION:String = "0.4";
		public static const BUFFER_SIZE:int = 8192;
		public static const SAMPLE_RATE:int = 44100;
		public static const MILS_PER_SEC:int = 1000;
		public static const SECONDS_PER_MINUTE:int = 60;
		
		public static const WIDTH:int = 700;
		public static const NOTEBUTTON_HEIGHT:int = 25;
		
		public static const LATENCY_FUDGE:int = 30; // milliseconds
		public static const TIME_3_4:String = '3/4';
		public static const TIME_4_4:String = '4/4';
		
		public static const ALPHA_PLAY:Number = 0.8;
		public static const ALPHA_OFF:Number = 0.3;
		
		public static const BITS_PER_BEAT:int = NoteButton.LEVEL_BITS; // 2
		
		public var eighthnotes:Boolean;
		public var sxthnnotes:Boolean;
		
		protected var _outsound:Sound;
		protected var _channel:SoundChannel;
		protected var _isPlaying:Boolean;
		protected var _latency:int; // milliseconds (how far ahead the sound buffer is)
		
		protected var _tempo:int;
		protected var _volume:Number;
		protected var _signature:String;
		protected var _step:int;
		protected var _noteQueue:Array;
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
		protected var _wavButton:PushButton;
		protected var _mp3Button:PushButton;
		protected var _linkButton:PushButton;
		protected var _urlText:InputText
		
		protected var _canNoteCallbackUpdateHash:Boolean = true;
		protected var _hashChangeTimer:uint = 0;
		protected var _varChangeTimer:uint = 0;
		protected var _base64Encoder:Base64Encoder;
		protected var _base64Decoder:Base64Decoder;
		protected var _currentHash:String = "";
		
		public var mp3Encoder:ShineMP3Encoder;
		public var wavData:ByteArray;
		protected var _mp3Converted:Boolean = false;
		protected var _wavConverted:Boolean = false;
		
		// Debug clicking
		public function onClickStage(e:MouseEvent):void {
			trace(e.target, e.target.name);
		}
		
		/**
		 * Constructor
		 */
		public function Taikonome(){
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
			var s:String = null;
			try {
				s = ExternalInterface.call("getHash");
			} catch (error:Error){
				trace(error);
			}
			if (s == null){
				return null;
			}
			;
			// Strip leading # sign
			s = s.replace(/^#/, '');
			if (s.length <= 1){
				return null;
			}
			;
			
			return s;
		}
		
		public function setExternalHash(str:String = null):void {
			
			if (str != null && str.length > 0){
				var currentHash:String = (_currentHash) ? _currentHash : '';
				currentHash = currentHash.replace(/^#/, '');
				var newHash:String = str;
				
				//newHash = newHash.replace(/%5F/g, "_").replace(/%2D/g, "-");
				if (newHash != currentHash){
					_currentHash = newHash;
					ExternalInterface.call("setHash", newHash);
				}
			}
		}
		
		/**
		 * Push beat updates back out to the url
		 * @param	h
		 */
		public function pushExternalBeatHash(h:String = null):void {
			if (h == null){
				h = beatToHash();
			}
			var str:String = _currentHash;
			var arg:OrderedURLVariables = new OrderedURLVariables();
			if (str != null && str.length > 0){
				arg.decode(str);
			}
			
			arg.v = VERSION.replace(/\./, "_");
			arg.b = _tempo.toString();
			arg.h = sanitizeBeatHash(h);
			//var str:String = "v=" +  + "&b=" + _tempo.toString() + "&h=" + sanitizeBeatHash(h);
			setExternalHash(arg.toString());
		}
		
		public function getURLVars(arg:OrderedURLVariables = null):OrderedURLVariables {
			var str:String;
			if (arg == null){
				str = _currentHash;
				arg = new OrderedURLVariables();
				if (str != null && str.length > 0){
					arg.decode(str);
				}
			}
			arg.v = VERSION.replace(/\./, "_");
			arg.b = _tempo.toString();
			return arg;
		}
		
		/**
		 * Push variable updates back out to the url
		 * Updates everything EXCEPT the beat hash.
		 * If arg is null, read the current hash.
		 * @param	arg
		 */
		public function pushURLVars(arg:OrderedURLVariables = null):void {
			setExternalHash(getURLVars(arg).toString());
		}
		
		// Called when the url hash has changed
		public function onExternalHashChange():void {
			updateFromExternalHash();
		}
		
		// Update taikonome vars and beat from hash
		public function updateFromExternalHash():void {
			
			var s:String = getExternalHash();
			_currentHash = s;
			
			if (s == null || s.length == 0){
				_canNoteCallbackUpdateHash = false;
				clearBeat();
				_canNoteCallbackUpdateHash = true;
				return;
			}
			// Parse string
			// Format: "v=0.3&b=160&h=HaShCoDe"
			var arg:OrderedURLVariables = new OrderedURLVariables(s);
			
			if (arg == null){
				trace("[Taikonome]Warning:Couldn't parse hash", s);
				return;
			}
			// Version check
			if (!arg.v){
				//trace("[Taikonome]Warning: no version param");
			} else if (arg.v != VERSION.replace(/\./, "_")){
				//TODO detect old versions?
				trace("[Taikonome]Warning: version string does not match")
			}
			
			// Beat hash
			if (arg.h){
				hashToBeat(arg.h);
			} else {
				_canNoteCallbackUpdateHash = false;
				clearBeat();
				_canNoteCallbackUpdateHash = true;
			}
			// Tempo (in bps)
			if (arg.b){
				var n:Number = Number(arg.b);
				if (!isNaN(n)){
					_tempoSlider.value = n;
					_tempo = Math.round(_tempoSlider.value);
					_isTempoChanged = true;
				}
			}
		}
		
		// Called if there have not been any beat changes for the last 300ms
		public function batchBeatHashUpdate(str:String = null):void {
			if (_hashChangeTimer != 0){
				clearTimeout(_hashChangeTimer);
			}
			if (str == null){
				str = beatToHash();
			}
			_hashChangeTimer = setTimeout(pushExternalBeatHash, 300, str);
		}
		
		public function batchVarHashUpdate(arg:OrderedURLVariables = null):void {
			if (_varChangeTimer != 0){
				clearTimeout(_varChangeTimer);
			}
			_varChangeTimer = setTimeout(pushURLVars, 400, arg);
		}
		
		private function init(e:Event = null):void {
			removeEventListener(Event.ADDED_TO_STAGE, init);
			// entry point
			stage.align = StageAlign.TOP;
			stage.scaleMode = StageScaleMode.NO_SCALE;
			createDisplay();
			
			ExternalInterface.addCallback("flashHash", onExternalHashChange);
			// Force update from url
			updateFromExternalHash();
		}
		
		// ----------------------------------------------
		//
		// 	-- sound
		//
		// ----------------------------------------------
		/**
		 * Toggles between play and stop
		 */
		protected function togglePlayback(event:Event = null):void {
			if (_isPlaying){
				stop();
			} else {
				play();
			}
		}
		
		/**
		 * Stops playback, updates UI
		 */
		protected function stop():void {
			if (_channel && _isPlaying){
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
		protected function play():void {
			if (!_isPlaying){
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
		public function onSampleData(event:SampleDataEvent = null, buffer_size:uint = BUFFER_SIZE):void {
			var position:int;
			if (_channel){
				// latency is the number of milliseconds it will take from now
				// for the sound to play.
				_latency = ((event.position / 44.1) - _channel.position);
			}
			
			for (var i:uint = 0; i < buffer_size; i++){
				position = event.position + i;
				
				// -- hope to find a better way to determine timing vars
				// -- approach for adding notes to the queue seems to work well though
				
				var n:int;
				
				// -- 4/4 time
				if (_signature == TIME_4_4){
					n = position / (SAMPLE_RATE / _tempo * SECONDS_PER_MINUTE / 32);
					
					if (n != _step){
						_step = n;
						if (_step % 16 == 0){
							// 16 steps per eighth note, 32 eighth notes per line
							var noteButton:NoteButton = _shimeNoteButton[int(_step / 16) % 32];
							if (noteButton.level > 0){
								_noteQueue.push(new Note(noteButton.volume));
							}
						}
					}
				}
				
				// -- create the samples, if there are multiple notes in the queue we us addition to merge them
				var sample:Number = 0;
				for each (note in _noteQueue){
					if (note.hasNext()){
						sample += note.getNextNumber();
					}
				}
				
				// Change volume
				// Use squared to get a better dynamic range
				// TODO fade volume change so you don't get little pops when changing
				sample *= _volume;
				
				event.data.writeFloat(sample * .8); //L?
				event.data.writeFloat(sample * .8); //R?
			}
			
			// -- store left over notes in new array for next iteration
			// -- notes can be left over if not all positions were written to the buffer
			// -- for instance, if a note with a duration of 1000 samples starts writing to the buffer @
			// -- iteration 8000, only 192 samples are written
			var temp:Array = [];
			var note:Note;
			
			for each (note in _noteQueue){
				if (note.hasNext()){
					temp.push(note);
				}
			}
			
			_noteQueue = temp;
		}
		
		/**
		 * Updates the grid of squares to reflect the current 1/8, 1/4 and measure
		 * Updates the timecode clocks
		 * Not optimized
		 */
		protected function onPlaybackEnterFrame(event:Event):void {
			if (_channel){
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
				for (i = 0; i < _shimeNoteButton.length; i++){
					if (i == eighth){
						_shimeNoteButton[i].alpha = ALPHA_PLAY
					} else {
						_shimeNoteButton[i].alpha = ALPHA_OFF;
					}
				}
				
				// -- current 1/4 note
				for (i = 0; i < _quarterNoteButton.length; i++){
					if (i == quarter){
						_quarterNoteButton[i].alpha = ALPHA_PLAY;
					} else {
						_quarterNoteButton[i].alpha = ALPHA_OFF;
					}
				}
				
				// -- current measure
				for (i = 0; i < _wholeNoteButton.length; i++){
					if (i == measure){
						_wholeNoteButton[i].alpha = ALPHA_PLAY;
					} else {
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
		protected function onTempoChange(event:Event = null):void {
			_tempo = Math.round(_tempoSlider.value);
			_isTempoChanged = true;
			// If we call onTempoChange manually, the event is null
			if (event != null){
				// Don't update the url on a manual tempo change
				// (e.g. from initialization)
				// Update the url, (but keep the same beat hash)
				batchVarHashUpdate();
			}
		}
		
		protected function onVolumeChange(event:Event = null):void {
			_volume = Math.pow(_volumeSlider.value / 100, 1.8) * 2;
		}
		
		/**
		 * Creates rows of squares indicating 1/8, 1/4 and measures
		 * Also creates button and text fields
		 */
		public function createDisplay():void {
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
			for (i = 0; i < 32; i++){
				noteButton = new NoteButton(_gridContainer);
				//if (int(i / 8) % 2 ) noteButton.color = 0xCCCCCC;
				//else noteButton.color = 0xEEEEEE;
				
				noteButton.width = w;
				noteButton.height = NOTEBUTTON_HEIGHT;
				noteButton.x = (i * w) + (i * padding);
				noteButton.y = 22;
				noteButton.alpha = ALPHA_OFF;
				noteButton.index = i;
				noteButton.addEventListener(NoteButton.SELECTED_CHANGED, function(... u):void {
						if (_canNoteCallbackUpdateHash){
							batchBeatHashUpdate();
						}
					});
				
				_shimeNoteButton.push(noteButton);
			}
			
			// -- quarter note squares
			w = (WIDTH / 16) - padding;
			_quarterNoteButton = new Vector.<NoteButton>();
			for (i = 0; i < 16; i++){
				noteButton = new NoteButton(_gridContainer);
				if (i % 2)
					noteButton.color = 0xCCCCCC;
				else
					noteButton.color = 0xEEEEEE;
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
			for (i = 0; i < 4; i++){
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
			
			_volumeSlider = new HUISlider(this, 130, y, 'Volume', onVolumeChange);
			_volumeSlider.minimum = 0;
			_volumeSlider.maximum = 100;
			_volumeSlider.value = 50;
			_volumeSlider.width = 160;
			_volumeSlider.labelPrecision = 0;
			// Sync _volume
			onVolumeChange();
			
			_tempoSlider = new HUISlider(this, 270, y, 'Tempo', onTempoChange);
			_tempoSlider.minimum = 20;
			_tempoSlider.maximum = 400;
			_tempoSlider.value = _tempo = 160;
			_tempoSlider.width = 250;
			_tempoSlider.labelPrecision = 0;
			// Sync _tempo
			onTempoChange();
			
			_playButton = new PushButton(controlContainer, 480, y, 'Play', togglePlayback);
			_playButton.toggle = true;
			
			button = new PushButton(controlContainer, 590, y, 'Clear', clearBeat);
			
			y = 40;
			_urlText = new InputText(controlContainer, 0, y + 2, "url");
			_urlText.width = 360;
			_urlText.visible = false;
			_wavButton = new PushButton(controlContainer, 480, y, 'Create wav', onSaveClick);
			_mp3Button = new PushButton(controlContainer, 590, y, 'Create mp3', onSaveMp3Click);
			_linkButton = new PushButton(controlContainer, 370, y, 'Create link', onLinkClick);
			
			y = 70;
			label = new Label(controlContainer, 00, y, 'Presets');
			button = new PushButton(controlContainer, 40, y, 'Straight', setupStraight);
			button = new PushButton(controlContainer, 150, y, 'Horsebeat', setupHorsebeat);
			button = new PushButton(controlContainer, 260, y, 'Matsuri', setupMatsuri);
			
			y = 100;
			button = new PushButton(controlContainer, 0, y, 'Random Beat', setRandom);
			_inputText = new InputText(controlContainer, 120, y, 'Input some text', setHashFromInputText);
			_inputText.height = 20;
			_inputText.width = 285;
			_inputText.enabled = true;
			_inputText.addEventListener(FocusEvent.FOCUS_IN, clearInput);
			_inputText.opaqueBackground = true;
			button = new PushButton(controlContainer, 410, y, 'Generate from text', setHashFromInputText);
			
			label = new Label(controlContainer, 620, y + 5, 'Taikonome v' + VERSION);
		}
		
		public function setRandom(event:Event = null):void {
			var v:Vector.<int> = new Vector.<int>();
			// Note probabilities
			var p:Vector.<Number> = new <Number>[.85, .7, .7, .7, .8, .7, .7, .7,  .85, .7, .7, .7, .8, .7, .7, .7, 
			                                     .85, .7, .7, .7, .8, .7, .7, .7,  .85, .7, .7, .7, .8, .7, .7, .7,];
			_canNoteCallbackUpdateHash = false;
			for (var i:int = 0; i < _shimeNoteButton.length; i++) {
				if (Math.random() < p[i]) {
					_shimeNoteButton[i].level = Math.round(Math.random() * NoteButton.MAX_LEVEL);
				} else {
					_shimeNoteButton[i].level = 0;
				}
				
			}
			// Generate from md5
			//var b:ByteArray = new ByteArray();
			//for (var i:int = 0; i < 3; i++) {
			//b.writeUnsignedInt(Math.random() * uint.MAX_VALUE);
			//}
			//var h:String = MD5.hashBytes(b);
			pushExternalBeatHash(beatToHash());
			_canNoteCallbackUpdateHash = true;
		}
		
		public function clearInput(event:Event = null):void {
			_inputText.text = "";
			_inputText.removeEventListener(FocusEvent.FOCUS_IN, clearInput);
		}
		
		public function setHashFromInputText(event:Event = null):void {
			var str:String = _inputText.text;
			var space:RegExp = /[ .,]/g;
			str = str.replace(space, '_');
			str = sanitizeBeatHash(str);
			hashToBeat(str);
			batchBeatHashUpdate(str);
		}
		
		/**
		 * Make sure our timecode string has at least two digits
		 */
		protected function toTimecode(value:String):String {
			if (value.length < 2){
				return '0' + value;
			}
			return value;
		}
		
		public function clearBeat(event:Event = null):void {
			for each (var button:NoteButton in _shimeNoteButton){
				button.level = 0;
			}
		}
		
		public function setupBeat(vec:Vector.<int>):void {
			for (var i:int = 0; i < 32; i++){
				_shimeNoteButton[i].level = vec[i % vec.length];
			}
		}
		
		public function setupHorsebeat(event:Event = null):void {
			setupBeat(new <int>[3, 0, 2, 2]);
		}
		
		public function setupStraight(event:Event = null):void {
			setupBeat(new <int>[2, 0, 2, 0]);
		}
		
		public function setupMatsuri(event:Event = null):void {
			setupBeat(new <int>[3, 0, 2, 2, 2, 0, 2, 0]);
		}
		
		/**
		 * Convert beats into hash string
		 */
		public function beatToHash(bits:uint = BITS_PER_BEAT):String {
			if (32 % bits != 0){
				throw new Error("bits must be factor of 32");
			}
			;
			var str:String;
			// Convert vector to ByteArray
			var b:ByteArray = new ByteArray();
			var num:uint = 0;
			var shift:uint = 0;
			var s:int = 0;
			var numSelected:int = 0;
			var len:int = _shimeNoteButton.length;
			for (var i:uint = 0; i < len; i++){
				s = uint(_shimeNoteButton[i].level);
				if (s > 0){
					numSelected++;
				}
				num += s << (bits * shift++);
				if (shift * bits >= 32 || i + 1 == len){ // 32-bit ints
					b.writeInt(num);
					shift = 0;
					num = 0;
				}
			}
			if (numSelected == 0){
				return "";
			}
			b.deflate(); // Compress byte array
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
		
		/**
		 * Remove invalid characters from the beat hash
		 * @param	str
		 * @return
		 */
		public function sanitizeBeatHash(str:String):String {
			if (str == null || str.length == 0){
				return null;
			}
			str = StringUtil.trim(str);
			str = StringUtil.restrict(str, "a-zA-Z0-9\\-_");
			return str;
		}
		
		/**
		 * Convert a hash string into beats
		 */
		public function hashToBeat(str:String = null, bits:int = BITS_PER_BEAT):String {
			var b:ByteArray;
			var i:int = 0;
			var num:uint;
			
			if (str == null){
				return str;
			}
			if (32 % bits != 0){
				throw new Error("bits must be factor of 32");
			}
			;
			
			_canNoteCallbackUpdateHash = false;
			
			if (str.length == 0){
				// Set all to zero
				clearBeat();
				_canNoteCallbackUpdateHash = true;
				return str;
			}
			
			str = sanitizeBeatHash(str);
			
			// Undo url substitutions
			var char62:RegExp = /-/g;
			var char63:RegExp = /_/g;
			str = str.replace(char62, '+');
			str = str.replace(char63, '/');
			
			// Decode base64
			var base64Success:Boolean = false;
			for (i = 0; i <= 2; i++){
				try {
					// String may need trailing equals
					_base64Decoder.decode(str + StringUtil.repeat('=', i));
					b = _base64Decoder.toByteArray();
					base64Success = true;
					break;
				} catch (e:Error){
					// Do nothing
				}
			}
			var inflateSuccess:Boolean = false;
			if (base64Success){
				// Decompress
				try {
					b.inflate();
					inflateSuccess = true;
				} catch (e:Error){
					// Probably random user input string
				}
			}
			if (!inflateSuccess){
				// Use md5 hash
				MD5.hash(str);
				b = MD5.digest;
			}
			// Make sure there are a whole number of ints
			b.position = b.length;
			while (b.length % 4 > 0){ // 4 bytes per int (32 bit ints)
				// pad with zeros
				b.writeByte(0);
			}
			
			// Convert ByteArray to beats
			var mask:uint = (1 << bits) - 1; // e.g. if bits=4, mask=0...01111 (in binary)
			var len:int = _shimeNoteButton.length;
			i = 0;
			b.position = 0; // reset b so we can read from it
			while (b.bytesAvailable >= 4){
				num = b.readUnsignedInt();
				for (var shift:int = 0; shift < 32; shift += bits){
					var val:int = ((num >>> shift) & mask);
					if (i < len){
						_shimeNoteButton[i++].level = val;
					} else if (val > 0){
						// Toggle selected if value is true
						_shimeNoteButton[i % len].level = (_shimeNoteButton[i++ % len].level + val) % (1<<BITS_PER_BEAT);
					}
				}
			}
			if (b.bytesAvailable > 0){
				trace("WARNING: Not all bytes read from buffer!");
			}
			_canNoteCallbackUpdateHash = true;
			return str;
		}
		
		/**
		 * Return ByteArray of floats generated by onSampleData
		 * @param	channels
		 * @return
		 */
		public function getSoundData(channels:int = 2):ByteArray {
			
			// We need enough samples for 32 eighth notes = 16 quarter notes = 16 beats
			var numBeats:uint = 16;
			var numSamples:uint = (SAMPLE_RATE * numBeats * 60) / _tempo;
			
			// Fake the SampleDataEvent
			var fakeEvent:SampleDataEvent = new SampleDataEvent(SampleDataEvent.SAMPLE_DATA);
			fakeEvent.data = new ByteArray();
			fakeEvent.position = 0;
			// Hijack variables used in onSampleData
			var previousNoteQueue:Array = _noteQueue;
			var previousStep:int = _step;
			var previousvolume:Number = _volume;
			_volume = 1.2;
			_noteQueue = [];
			
			onSampleData(fakeEvent, numSamples);
			
			// Restore variables
			_noteQueue = previousNoteQueue;
			_step = previousStep;
			_volume = previousvolume;
			// TODO true looping (check queue if there are any notes to overlap at the start
			
			return fakeEvent.data;
		}
		
		public function onSaveClick(event:MouseEvent):void {
			var channels:int = 2;
			
			//TESTING HACK:
			//var soundData:Vector.<Number> = getFakeSoundData(channels);
			//var wavData:ByteArray = WavUtil.encodeVector(soundData,channels);
			
			var soundDataFloats:ByteArray = getSoundData(channels);
			var wavData:ByteArray = WavUtil.encodeFloatByteArray(soundDataFloats, channels);
			
			var file:FileReference = new FileReference();
			
			file.save(wavData, 'taikonome_loop_' + _tempo + 'bps.wav');
		}
		
		public function mp3EncodeError(event:ErrorEvent):void {
			
			trace("[ERROR] : ", event.text);
		}
		
		private function mp3EncodeProgress(event:ProgressEvent):void {
			trace(event.bytesLoaded, event.bytesTotal);
		}
		
		public function mp3EncodeComplete(event:Event):void {
			_mp3Button.label = "Save mp3";
			_mp3Converted = true;
		}
		
		public function onSaveMp3Click(event:MouseEvent):void {
			var channels:int = 2;
			if (!_mp3Converted){
				_mp3Button.label = "converting...";
				
				var soundDataFloats:ByteArray = getSoundData(channels);
				wavData = WavUtil.encodeFloatByteArray(soundDataFloats, channels);
				wavData.position = 0;
				
				mp3Encoder = new ShineMP3Encoder(wavData);
				mp3Encoder.addEventListener(Event.COMPLETE, mp3EncodeComplete);
				mp3Encoder.addEventListener(ProgressEvent.PROGRESS, mp3EncodeProgress);
				mp3Encoder.addEventListener(ErrorEvent.ERROR, mp3EncodeError);
				mp3Encoder.start();
			} else {
				_mp3Button.label = "Create mp3";
				mp3Encoder.saveAs('taikonome_loop_' + _tempo + 'bps.mp3');
				_mp3Converted = false;
			}
		}
		
		public function onLinkClick(event:MouseEvent):void {
			var str:String = getURLVars().toString();
			_urlText.visible = true;
			_urlText.text = "taikonome.com/#" + str.replace(/%5F/g, "_").replace(/%2D/g, "-");
		}
	}
}