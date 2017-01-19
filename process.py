# Shrink images and videos in a folder. Rename files to match folder name.
# File naming convention: FOLDERNAME_NUMBER

import subprocess
import tkinter
import tkinter.messagebox
# from tkinter import filedialog
import tempfile
import shutil
import os.path
import os
import re


TEMPROOT = os.path.realpath(os.path.dirname(__file__))

IMAGES = (".jpg", ".jpeg", ".png")
VIDEO = (".mp4", ".mov", ".avi")
ORIGINALS = "Originals - Check before deleting" # Where to put original files

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
            message += "Imagemin missing. To compress images install nodejs and run the commands:\n>>>npm install imagemin-cli -g && npm install imagemin-mozjpeg -g\n"

        message += "\nContinue Anyway?"
        return tkinter.messagebox.askyesno(message=message)
    return True

def unique_name(name):
    """ If a file name exists, come up with a new name """
    while os.path.isfile(name):
        path, ext = os.path.splitext(name)
        name = path + "_copy" + ext
    return name

class Media(object):

    TAGS = re.compile(r"\[.+?\]") # Extract information from tags square brackets (Tagspaces)

    def __init__(s, dir_entry):
        """ A media file """
        s.path = s.working = dir_entry.path
        s.name, s.ext = os.path.splitext(dir_entry.name)
        try:
            s.tags = s.TAGS.search(s.name).group(0)
        except AttributeError:
            s.tags = ""

    def compress(s, dest):
        """ Compress media to destination """

        # First check that the destination doesn't exist
        if os.path.isfile(dest):
            raise IOError("File already exists: %s" % dest)

        # Determine which type of media this is and compress it
        lower_ext = s.ext.lower()
        if lower_ext in IMAGES:
            s._compress_image(dest)
        elif lower_ext in VIDEO:
            s._compress_video(dest)
        else:
            s._compress_generic(dest)
        s.working = dest

    def _compress_generic(s, dest):
        """ just link a file instead of doing anything else to it """
        os.link(s.path, dest)

    def _compress_image(s, dest):
        """ Compress image losslessly using imagemin """
        if os.path.isfile(dest):
            raise IOError("File already exists: %s" % dest)
        command = [
            "imagemin",         # Command
            "--plugin=mozjpeg", # Plugin! Better compression
            s.path              # Source!
            ]
        with subprocess.Popen(command, shell=True, stdout=subprocess.PIPE) as com:
            with open(dest, "wb") as f_dest:
                while True:
                    buff = com.stdout.read(4096)
                    if not buff:
                        break
                    f_dest.write(buff)

    def _compress_video(s, dest):
        """ Compress video, visually lossless using ffmpeg """
        if os.path.isfile(dest):
            raise IOError("File already exists: %s" % dest)
        # rotation = "rotate='90*PI/180:ow=ih:oh=iw'" # Rotation command
        command = [
            "ffmpeg",           # Command
            "-v", "quiet",      # Don't need to see stuff
            "-i", s.path,       # Source
            "-crf", "18",       # Quality (lower number = higher quality)
            "-c:v", "libx264",  # codec
            dest                # Output
            ]
        with subprocess.Popen(command) as com:
            pass # Block process


def DO_IT(root):
    """ Lets get to it! """
    if depend_check():

        num_start = 0 # Highest numbered file in folder, add more files from here
        root_name = os.path.basename(root) # Actual folder name of root
        naming_convention = re.compile(r"%s\_(\d+)" % re.escape(root_name))
        to_process = [] # Grab all files that need processing

        # Look through file and grab files that don't match the naming convention
        for media in (Media(f) for f in os.scandir(root) if f.is_file(follow_symlinks=False)):
            check = naming_convention.match(media.name) # Check the file matches naming convention

            # If we have a file that matches the naming convention
            # then take the digit of the file as out new starting point.
            # We assume that a file matching naming conventions has already
            # been processed. So we leave it at that.
            if check:
                num_start = max(num_start, int(check.group(1)))

            # We have a file that does not match the naming convention
            # so we assume it needs processing. Add it to our process list.
            else:
                to_process.append(media)

        # Assuming we have anything left to process
        if to_process:
            to_process.sort(key=lambda x: x.name) # Put our stuff in order

            # Make a temporary working directory!
            with tempfile.TemporaryDirectory(dir=root) as working_dir:

                for media in to_process:
                    print(media.tags)







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



                # original_dir = os.path.join(root, ORIGINALS)
                # if not os.path.isdir(original_dir):
                #     os.mkdir(original_dir)


if __name__ == '__main__':
    DO_IT(TEMPROOT)
