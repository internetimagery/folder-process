# Shrink images and videos in a folder. Rename files to match folder name.
# File naming convention: FOLDERNAME_NUMBER

# TODO: Possiblity of using ffmpeg to do jpeg compressions too? It works in basic tests

import traceback
import subprocess
import tkinter
import tkinter.messagebox
import tkinter.filedialog
import tempfile
import shutil
import os.path
import os
import re


TEMPROOT = os.path.realpath(os.path.dirname(__file__))

NAMING_CONVENTION = "{root}_{num}{tags}{ext}" # How we're going to name our files
IMAGES = (".jpg", ".jpeg", ".png")
VIDEO = (".mp4", ".mov", ".avi")
BACKUP_DIR = "Originals - Check before deleting" # Where to put original files

# Figure out what we can use
FFMPEG = True if shutil.which("ffmpeg") else False
IMAGEMIN = True if shutil.which("imagemin") else False


def compress_image(src, dest):
    """ Compress image losslessly using imagemin """
    command = [
        "imagemin.cmd",     # Command
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
        "ffmpeg.exe",       # Command
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
    for media in (f for f in os.scandir(root) if f.is_file(follow_symlinks=False)):
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
            candidates.append({
                "o_name" : media.name,
                "o_path" : media.path
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

        # Create a working directory
        with tempfile.TemporaryDirectory(dir=root) as w_dir:

            # Lets do some compressin'
            for media in candidates:
                media["w_path"] = os.path.join(w_dir, media["o_name"])

                # Make a placeholder file to lock in the spot
                placeholder = open(media["n_path"], "w")
                try:

                    # Work out which compression type to use.
                    # Compress into temporary working directory.
                    # For unknown file type, simply link to working directory.
                    print("Compressing: %s => %s" % (media["o_name"], media["n_name"]))
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

                # Move our compressed file to the root
                shutil.move(media["w_path"], media["n_path"])

                # Now that we have the compressed file safely complete.
                # Back up the original file.
                # If this fails, we will stop. But it's not a big deal as we're not overwriting it.
                shutil.move(media["o_path"], media["b_path"])

                # Done! Next file!


class Main(object):

    def __init__(s):
        """ Main window! """
        # Where do we want to start browsing from?
        # s.last_location = os.getcwd()
        s.last_location = os.path.realpath(os.path.dirname(__file__))

        # Make the main window
        window = tkinter.Tk()
        window.title("Rename and Compress Folder.")

        # Add a descriptive label
        desc_label = tkinter.Label(window, text="Rename and Compress all files in folder.")

        # Add a textbox and button
        browse_button = tkinter.Button(window, text="Browse Folder", command=s.browse_path, state=tkinter.DISABLED)

        # Put it all together!
        desc_label.pack(side=tkinter.TOP)
        browse_button.pack(side=tkinter.BOTTOM)

        # Determine if we have the right dependencies. IF not, do we want to comtinue?
        if s.depend_check():
            browse_button.configure(state=tkinter.ACTIVE)
            browse_button.flash()

        # Lets go!
        window.mainloop()

    def browse_path(s):
        """ Browse to find a path """
        path = tkinter.filedialog.askdirectory(initialdir=s.last_location)
        if path:
            s.last_location = path
            try:
                DO_IT(path)
            except Exception as err:
                tkinter.messagebox.showerror(
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
            return tkinter.messagebox.askyesno(message=message)
        return True


if __name__ == '__main__':
    Main()
    # TEMPROOT = os.path.join(TEMPROOT, "temp")
    # DO_IT(TEMPROOT)
