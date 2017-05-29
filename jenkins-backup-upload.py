#!/usr/bin/env python
# -*- coding: utf-8 -*-

# Written by Daniel Bachler (daniel@douglasconnect.com) for OpenRiskNet 

from __future__ import absolute_import, division, print_function
import os
import tarfile
import sys
import subprocess
import logging

logger = logging.getLogger()


def create_tar_gz(source_directory, target_filename):
    """Compresses a folder into a .tar.gz file"""
    if os.path.exists(source_directory):
        logger.info("Compressing directory {0} into file {1}".format(source_directory, target_filename))
        compress_tar = tarfile.open(target_filename, "w:gz")
        compress_tar.add(source_directory)
        compress_tar.close()
    else:
        logger.error("Could not find directory {0}".format(source_directory))
        raise Exception(" (ZipFile)No Such Folder %s" % source_directory)


def zip_all_uncompressed(work_dir):
    """Compresses all as yet ncompressed folders into .tar.gz files in the same directory"""
    dirs = [d for d in os.listdir(work_dir) if os.path.isdir(d)]
    dirs_to_zip = [d for d in dirs if not os.path.isfile(d + ".tar.gz")]
    for d in dirs_to_zip:
        create_tar_gz(d, d + ".tar.gz")


def get_most_current(work_dir):
    """Returns the last .tar.gz file (alphabetcial sort, so make sure any date format sorts well)"""
    files = [f for f in os.listdir(work_dir) if os.path.isfile(f) and f.endswith(".tar.gz")]
    logger.info("Found {0} .tar.gz files".format(len(files)))
    sorted_files = sorted(files)
    logger.info("Returning file {0} as most current".format(sorted_files[-1]))
    return sorted_files[-1]


def upload_file_to_google_storage(filename, bucket_id):
    """Upload a file to google storage by using the gsutil. Assumes valid authorization is present."""
    return subprocess.call("gsutil cp {1} gs://{0}/{1}".format(bucket_id, filename), shell=True)


def compress_all_and_upload_latest(work_dir, bucket_id):
    """Zips all directories in a given directory, then uploads the last (by alphabetcial sort of the list) .tar.gz file
    to google storage"""
    zip_all_uncompressed(work_dir)
    most_current_file = get_most_current(work_dir)
    return upload_file_to_google_storage(most_current_file, bucket_id)


if __name__ == '__main__':
    logger.setLevel(logging.INFO)
    logging.basicConfig()

    if len(sys.argv) < 2:
        print("Usage: {0} google-storage-bucket-id [directory]".format(sys.argv[0]))
        exit(1)

    directory = sys.argv[2] if len(sys.argv) > 2 else os.getcwd()
    logger.info("Processing jenkins backup dir at {0}".format(directory))

    # reuse exit code of upload command for exit code of script
    sys.exit(compress_all_and_upload_latest(directory, sys.argv[1]))
