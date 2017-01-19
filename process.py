# Shrink images and videos in a folder. Rename files to match folder name.
# File naming convention: FOLDERNAME_NUMBER

# TODO: Possiblity of using ffmpeg to do jpeg compressions too? It works in basic tests

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
        name = path + "_other" + ext
    return name

class Media(object):

    TAGS = re.compile(r"\[.+?\]") # Extract information from tags square brackets (Tagspaces)

    def __init__(s, dir_entry):
        """ A media file """
        s.path = s.origin = dir_entry.path
        s.name, s.ext = os.path.splitext(dir_entry.name)
        try:
            s.tags = s.TAGS.search(s.name).group(0)
        except AttributeError:
            s.tags = ""

    def _file_check(s, dest):
        """ utility """
        if os.path.isfile(dest):
            raise IOError("File already exists: %s" % dest)

    def compress(s, dest_dir):
        """ Compress media to destination folder """

        # Determine which type of media this is, add extension and compress it
        dest = os.path.join(dest_dir, s.name)
        lower_ext = s.ext.lower()
        if lower_ext in IMAGES and IMAGEMIN:
            dest += lower_ext
            s._file_check(dest)
            s._compress_image(dest)
        elif lower_ext in VIDEO and FFMPEG:
            dest += ".mp4"
            lower_ext = ".mp4"
            s._file_check(dest)
            s._compress_video(dest)
        else:
            dest += s.ext
            s._file_check(dest)
            s._compress_generic(dest)
        s.path = dest
        s.ext = lower_ext

    def _compress_generic(s, dest):
        """ just link a file instead of doing anything else to it """
        os.link(s.origin, dest)

    def _compress_image(s, dest):
        """ Compress image losslessly using imagemin """
        command = [
            "imagemin.cmd",     # Command
            "--plugin=mozjpeg", # Plugin! Better compression
            s.origin            # Source!
            ]
        with subprocess.Popen(command, stdout=subprocess.PIPE) as com:
            with open(dest, "wb") as f_dest:
                f_dest.write(com.stdout.read())
                # while True:
                #     buff = com.stdout.read(4096)
                #     if not buff:
                #         break
                #     f_dest.write(buff)

    def _compress_video(s, dest):
        """ Compress video, visually lossless using ffmpeg """
        # rotation = "rotate='90*PI/180:ow=ih:oh=iw'" # Rotation command
        command = [
            "ffmpeg.exe",       # Command
            "-v", "quiet",      # Don't need to see stuff
            "-i", s.origin,       # Source
            "-crf", "18",       # Quality (lower number = higher quality)
            "-c:v", "libx264",  # codec
            dest                # Output
            ]
        with subprocess.Popen(command, stdout=subprocess.DEVNULL) as com:
            pass # Block process

def get_candidates(root):
    """
    Given a directory. Pull out file names that do not match our naming convention.
    Return a multi array. [OLD_NAME, NEW_NAME]
    """

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
                "o_path" : os.path.join(root, media.name)
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
        _, new_name["ext"] = os.path.splitext(media["o_name"])
        media["n_name"] = NAMING_CONVENTION.format(**new_name)
        media["n_path"] = os.path.join(root, media["n_name"])

    return candidates


def DO_IT(root):
    """ Lets get to it! """
    if depend_check():

        # Get possible files to work on
        candidates = get_candidates(root)
        if candidates:

            # Backup directory path
            b_dir = os.path.join(root, BACKUP_DIR)

            # Check that there are no files already in place
            for media in candidates:
                media["b_path"] = os.path.join(b_dir, media["o_name"])

                if os.path.isfile(media["b_path"]):
                    raise FileExistsError("File exists. Please fix and try again. %s" % media["b_path"])
                if not os.path.isfile(media["o_path"]):
                    raise FileNotFoundError("File missing. Please fix and try again. %s" % media["o_path"])

            # Create a working directory
            with tempfile.TemporaryDirectory(dir=root) as w_dir:

                # Compress files! Woo!
                for media in candidates:
                    media["w_path"] = os.path.join(w_dir, media["o_name"])

                    # PERFORM COMPRESSION #####
                    os.link(media["o_path"], media["w_path"])
                    # REPLACE WITH COMPRESSION CODE ####

                # So far so good. Make a backup folder for original files
                if not os.path.isdir(b_dir):
                    os.mkdir(b_dir)

                # Finally move out our original files
                # and replace with new ones
                for media in candidates:
                    shutil.move(media["o_path"], media["b_path"])
                    shutil.move(media["w_path"], media["n_path"])

                # And we're done!


class Main(object):

    def __init__(s):
        """ Main window! """
        # s.last_location = os.getcwd() # Where to start browsing.
        s.last_location = os.path.realpath(os.path.dirname(__file__))

        window = tkinter.Tk()
        window.title("Rename and Compress all media files.")

        # Add a descriptive label
        desc_label = tkinter.Label(window, text="Rename and Compress all media files.")

        # Add a textbox and button
        browse_button = tkinter.Button(window, text="Browse Folder", command=s.browse_path)

        # Put it all together!
        desc_label.pack()
        browse_button.pack(side=tkinter.BOTTOM)

        # Lets go!
        window.mainloop()

    def browse_path(s):
        """ Browse to find a path """
        path = tkinter.filedialog.askdirectory(initialdir=s.last_location)
        if path:
            s.last_location = path
            print(path)



if __name__ == '__main__':
    # Main()
    TEMPROOT = os.path.join(TEMPROOT, "temp")
    DO_IT(TEMPROOT)
