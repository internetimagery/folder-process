# Shrink images and videos in a folder. Rename files to match folder name.
# File naming convention: FOLDERNAME_NUMBER

import subprocess
import tkinter
import tkinter.messagebox
# from tkinter import filedialog
# from tkinter import messagebox
import tempfile
import shutil
import os.path
import os
import re


TEMPROOT = os.path.realpath(os.path.dirname(__file__))

IMAGES = (".jpg", ".jpeg", ".png")
VIDEO = (".mp4", ".mov", ".avi")

# Figure out what we can use
FFMPEG = True if shutil.which("ffmpeg") else False
IMAGEMIN = True if shutil.which("imagemin") else False

def depend_check():
    """ Ask if user wants to continue without depedencies """
    if not FFMPEG or not IMAGEMIN:
        message = ""
        if not FFMPEG:
            message += "Ffmpeg missing. To compress videos install from https://ffmpeg.org/\n"
        if not IMAGEMIN:
            message += "Imagemin missing. To compress images install nodejs and run the commands:\n>>>npm install imagemin-cli -g\n>>>npm install imagemin-mozjpeg -g\n"

        message += "\nContinue Anyway?"
        return tkinter.messagebox.askyesno(message=message)
    return True

def compress_image(src, dest):
    """ Compress image losslessly using imagemin """
    if os.path.isfile(dest):
        raise IOError("File already exists: %s" % dest)
    command = [
        "imagemin",         # Command
        "--plugin=mozjpeg", # Plugin! Better compression
        src                 # Source!
        ]
    with subprocess.Popen(command, shell=True, stdout=subprocess.PIPE) as com:
        with open(dest, "wb") as f_dest:
            while True:
                buff = com.stdout.read(4096)
                if not buff:
                    break
                f_dest.write(buff)

def compress_video(src, dest):
    """ Compress video, visually lossless using ffmpeg """
    if os.path.isfile(dest):
        raise IOError("File already exists: %s" % dest)
    # rotation = "rotate='90*PI/180:ow=ih:oh=iw'" # Rotation command
    command = [
        "ffmpeg",           # Command
        "-v", "quiet",      # Don't need to see stuff
        "-i", src,          # Source
        "-crf", "18",       # Quality
        "-c:v", "libx264",  # codec
        dest                # Output
        ]
    with subprocess.Popen(command) as com:
        pass # Block process

def DO_IT(root):
    """ Lets get to it! """
    if depend_check():

        # Start with a temporary working directory!
        with tempfile.TemporaryDirectory(dir=root) as working_dir:

            numbering_end = 0 # Highest numbered file in folder, add more files from here
            naming_convention = re.compile(r"%s\_(\d+)" % re.escape(root))

            # Look through file and grab files that don't match the naming convention
            for media in (f for f in os.scandir(root) if f.is_file(follow_symlinks=False)):

                print(media.name, naming_convention.match(media.name))

            # files = sorted((f for f in os.scandir(root) if f.is_file()), key=lambda x: x.name)




            # testfile = os.path.join(TEMPROOT, "MOV_0025.mp4")
            # testdest = os.path.join(TEMPROOT, "madeit.mp4")
            # testdest = os.path.join(working_dir, "something.jpg")
            # #
            # print(compress_video(testfile, testdest))

            # testfile = os.path.join(TEMPROOT, "Ethan and Archer_33.jpg")
            # # testdest = os.path.join(TEMPROOT, "something.jpg")
            # testdest = os.path.join(working_dir, "something.jpg")
            # #
            # print(compress_image(testfile, testdest))


if __name__ == '__main__':
    DO_IT(TEMPROOT)
