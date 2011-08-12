#Taikonome

Taikonome is a free online taiko metronome.  

Taikonome will play a shime ji (aka base beat) for taiko players wishing to practice without needing a shime player.

I wrote this to have an easy way to practice and compose taiko songs.

Enjoy!

## Features

* Click and drag beat editing
* Presets for straight, horsebeat, and matsuri patterns
* Tempo adjustable from 20 to 400bps
* Volume control

## License

Taikonome is released under the AGPL license.  This means that you are free to modify and distribute code as long as you release your source code under AGPL.  This also means that if you host an application using this code, you also must release your source code under AGPL.

## Technical notes

Taikonome is written in Flash because it provides the most reliable online sound playback.  (Taikonome can play 300bps+ without skipping a beat!)  (Unfortunately, this means that iPhones and iPads won't work, but that's really Apple's fault.)  Although I think html5 is generally a better online interface, using html5 audio playing and javascript are imprecise about timing resulting in skipping sound and unsynchronized interfaces.

## Future features  (not implemented, this is more of a todo/wishlist)

* Add chu-daiko beats (don/ka)
* Swing beat
* Accenting beats
* Allow export to wav (or maybe to mp3?)
* Add/remove lines
* Beat detection (bps via mouse click)
* Save custom presets?
* Save/share songs?
