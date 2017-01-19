# Shrink images and videos in a folder. Rename files to match folder name.

import subprocess
import tkinter
import tkinter.messagebox
# from tkinter import filedialog
# from tkinter import messagebox
import tempfile
import shutil
import os.path
import os


TEMPROOT = os.path.realpath(os.path.dirname(__file__))

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

def compress_jpeg(src, dest):
    """ Compress image losslessly using imagemin """
    if os.path.isfile(dest):
        raise IOError("File already exists: %s" % dest)
    command = ["imagemin", "--plugin=mozjpeg", src]
    with subprocess.Popen(command, shell=True, stdout=subprocess.PIPE) as com:
        with open(dest, "wb") as f_dest:
            while True:
                buff = com.stdout.read(4096)
                if not buff:
                    break
                f_dest.write(buff)


def process(root):
    """ Lets get to it! """
    if depend_check():

        # Start with a temporary working directory!
        with tempfile.TemporaryDirectory(dir=root) as working_dir:

            testfile = os.path.join(TEMPROOT, "Ethan and Archer_33.jpg")
            testdest = os.path.join(TEMPROOT, "something.jpg")
            # testdest = os.path.join(working_dir, "something.jpg")

            print(compress_jpeg(testfile, testdest))


if __name__ == '__main__':
    process(TEMPROOT)
