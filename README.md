# folder-process

Run on a folder to do the following:

* Rename files to the same name as the containing folder. Numbered.
* Compress files (images / video) to save space.
* Retain text within square brackets [] for compatability with Tagspaces.

Has two dependencies for compression.
* FFMPEG. Download from https://ffmpeg.org/
* IMAGEMIN. Download nodejs from http://nodejs.org and run the following code:

    npm install imagemin-cli -g && npm install imagemin-mozjpeg -g
