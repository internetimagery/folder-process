# Shrink images and videos in a folder. Rename files to match folder name.
# File naming convention: FOLDERNAME_NUMBER

# TODO: Investigate possiblity of using ffmpeg to do jpeg compressions too?
# It works in basic tests though not as well as mozjpeg. Can it be lossless? One less dependency.

from tkinter import *
from tkinter.ttk import *
from tkinter import messagebox
from tkinter import filedialog
import traceback
import subprocess
import tempfile
import shutil
import os.path
import os
import re

NAMING_CONVENTION = "{root}_{num}{tags}{ext}" # How we're going to name our files
IMAGES = (".jpg", ".jpeg", ".png")
VIDEO = (".mp4", ".mov", ".avi", ".wmv", ".rm", ".3gp", ".mkv", ".scm", ".vid", ".mpeg", ".avchd", ".m2ts")
BACKUP_DIR = "Originals - Check before deleting" # Where to put original files
FFMPEG = shutil.which("ffmpeg")
IMAGEMIN = shutil.which("imagemin")


def compress_image(src, dest):
    """ Compress image losslessly using imagemin """
    command = [
        IMAGEMIN,           # Command
        "--plugin=mozjpeg", # Plugin! Better compression
        src                 # Source!
        ]
    with subprocess.Popen(command, stdout=subprocess.PIPE) as com:
        with open(dest, "wb") as f_dest:
            f_dest.write(com.stdout.read())
            # while True:
            #     buff = com.stdout.read(4096)
            #     if not buff:
            #         break
            #     f_dest.write(buff)


def compress_video(src, dest):
    """ Compress video, visually lossless using ffmpeg """
    # rotation = "rotate='90*PI/180:ow=ih:oh=iw'" # Rotation command
    command = [
        FFMPEG,             # Command
        "-v", "quiet",      # Don't need to see stuff
        "-i", src,          # Source
        "-crf", "18",       # Quality (lower number = higher quality)
        "-c:v", "libx264",  # codec
        dest                # Output
        ]
    with subprocess.Popen(command, stdout=subprocess.DEVNULL) as com:
        pass # Block process


def get_candidates(root):
    """ Given a directory. Pull out file names that do not match our naming convention. """

    num_start = 0 # Highest numbered file in folder, add more files from here
    root_name = os.path.basename(root) # Actual folder name of root
    tags_convention = re.compile(r"\[.+?\]") # Extract information from tags square brackets (Tagspaces)
    naming_convention = re.compile(
        re.escape(
            NAMING_CONVENTION.format(
                root=root_name,
                num="PLACEHOLDER",
                tags="",
                ext=""
            )
        ).replace("PLACEHOLDER", r"(\d+)")
    )
    candidates = []

    # Look through file and grab files that don't match the naming convention
    # for media in (f f/or f in scandir(root) if f.is_file(follow_symlinks=False)):
    for m_name in os.listdir(root):
        m_path = os.path.join(root, m_name)
        if os.path.isfile(m_path):
            check = naming_convention.match(m_name) # Check the file matches naming convention

            # If we have a file that matches the naming convention
            # then take the digit of the file as out new starting point.
            # We assume that a file matching naming conventions has already
            # been processed. So we leave it at that.
            if check:
                num_start = max(num_start, int(check.group(1)))

            # We have a file that does not match the naming convention
            # so we assume it needs processing. Add it to our process list.
            else:
                candidates.append({
                    "o_name" : m_name,
                    "o_path" : m_path
                    })

    # Figure out the number of zeros (padding) to use for Numbering
    num_zeroes = len(str(num_start + len(candidates)))
    if num_zeroes < 3:
        num_zeroes = 3

    # Sort the list of files so our output remains in the same order.
    candidates.sort(key=lambda x: x["o_name"])

    # Assemble a new name for each file
    for media in candidates:

        new_name = {}
        new_name["root"] = root_name

        # Incriment our file count
        num_start += 1
        new_name["num"] = str(num_start).zfill(num_zeroes)

        # Pull out any tags
        tag_check = tags_convention.search(media["o_name"])
        new_name["tags"] = tag_check.group(0) if tag_check else ""

        # Create a new file name and append it to the original name
        new_name["ext"] = os.path.splitext(media["o_name"])[1].lower()
        if new_name["ext"] in IMAGES:
            media["type"] = 1
        elif new_name["ext"] in VIDEO:
            media["type"] = 2
            new_name["ext"] = ".mp4" # Converting all videos to mp4
        else:
            media["type"] = 0

        media["n_name"] = NAMING_CONVENTION.format(**new_name)
        media["n_path"] = os.path.join(root, media["n_name"])

    return candidates


def DO_IT(root):
    """ Lets get to it! """
    # Get possible files to work on
    candidates = get_candidates(root)
    if candidates:

        # Backup directory path
        b_dir = os.path.join(root, BACKUP_DIR)

        # Check that there are no files already in place
        for media in candidates:
            media["b_path"] = os.path.join(b_dir, media["o_name"])

            if os.path.isfile(media["b_path"]) or os.path.isfile(media["n_path"]):
                raise FileExistsError("File exists. Please fix and try again. %s" % media["b_path"])
            if not os.path.isfile(media["o_path"]):
                raise FileNotFoundError("File missing. Please fix and try again. %s" % media["o_path"])

        # Create our backup directory
        if not os.path.isdir(b_dir):
            os.mkdir(b_dir)

        # Create a working directory
        with tempfile.TemporaryDirectory(dir=root) as w_dir:

            total_files = len(candidates)
            curr_file = 0

            # Lets do some compressin'
            for media in candidates:
                media["w_path"] = os.path.join(w_dir, media["o_name"])

                # Make a placeholder file to lock in the spot
                placeholder = open(media["n_path"], "w")
                try:

                    # Work out which compression type to use.
                    # Compress into temporary working directory.
                    # For unknown file type, simply link to working directory.
                    curr_file += 1
                    print("[%s/%s] Compressing: %s => %s" % (curr_file, total_files, media["o_name"], media["n_name"]))
                    if media["type"] == 1 and IMAGEMIN:
                        compress_image(media["o_path"], media["w_path"])
                    elif media["type"] == 2 and FFMPEG:
                        compress_video(media["o_path"], media["w_path"])
                    else:
                        os.link(media["o_path"], media["w_path"])

                finally:
                    # Clean up the placeholder
                    placeholder.close()
                    os.unlink(media["n_path"])

                # TIME TO MAKE A CHOICE!
                # Pick the smallest file. Compressing a compressed file can lead to a larger one.
                size_old = os.stat(media["o_path"]).st_size
                size_new = os.stat(media["w_path"]).st_size

                if size_new and size_new < size_old:
                    # Move our compressed file to the root
                    shutil.move(media["w_path"], media["n_path"])
                else:
                    # Otherwise we didn't really accomplish much. Discard compressed file.
                    os.link(media["o_path"], media["n_path"])

                # Now that we have the compressed file safely complete.
                # Back up the original file.
                # If this fails, we will stop. But it's not a big deal as we're not overwriting it.
                shutil.move(media["o_path"], media["b_path"])

                # Done! Next file!
        print("="*20, "Done! :)")


class Main(object):

    def __init__(s):
        """ Main window! """
        # Where do we want to start browsing from?
        # s.last_location = os.getcwd()
        s.last_location = os.path.realpath(os.path.dirname(__file__))

        # Make the main window
        window = Tk()
        window.title("Rename and Compress Folder.")

        # Add a descriptive label
        desc_label = Label(window, text="Rename and Compress all files in folder.")

        # Add a progress bar
        # s.prog_bar = Progressbar(window, mode="indeterminate")

        # Add a button
        browse_button = Button(window, text="Browse Folder", command=s.browse_path, state=DISABLED)

        # Put it all together!
        desc_label.pack(side=TOP)
        # s.prog_bar.pack()
        browse_button.pack(side=BOTTOM)

        # Determine if we have the right dependencies. IF not, do we want to comtinue?
        if s.depend_check():
            browse_button.configure(state=ACTIVE)

        # Lets go!
        window.mainloop()

    def browse_path(s):
        """ Browse to find a path """
        path = filedialog.askdirectory(initialdir=s.last_location)
        if path:
            s.last_location = path
            if messagebox.askokcancel(message="Keep an eye on the console.\nAbout to process files in:\n\n%s" % path):
                import time
                # s.prog_bar.start()
                try:
                    DO_IT(os.path.realpath(path))
                except Exception as err:
                    # s.prog_bar.stop()
                    messagebox.showerror(
                        title="Oh no!",
                        message="The following error occurred.\n\n%s\n\n%s" % (err, traceback.format_exc())
                        )

    def depend_check(s):
        """ Ask if user wants to continue without depedencies """
        if not FFMPEG or not IMAGEMIN:
            message = ""
            if not FFMPEG:
                message += """
Ffmpeg missing. To compress videos install from https://ffmpeg.org/
"""
            if not IMAGEMIN:
                message += """
Imagemin missing. To compress images install nodejs from http://nodejs.org
Then run the following commands:

>>>npm install imagemin-cli -g
>>>npm install imagemin-mozjpeg -g
"""

            message += "\nContinue Anyway?"
            return messagebox.askyesno(message=message)
        return True


if __name__ == '__main__':
    Main()
