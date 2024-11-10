# encoding: utf-8
#!/usr/bin/python
# 仓库地址https://github.com/ytdl-org/youtube-dl
# 可以用这种方式下载最新版 python3.9 -m pip install --force-reinstall https://github.com/yt-dlp/yt-dlp/archive/master.tar.gz
import argparse
import json, time
from subprocess import Popen, PIPE


def readfile(path):
    stdout = []
    with open(path) as f:
        while True:
            line = f.readline()
            if line:
                stdout.append(line)
            else:
                break
    return stdout


def parse_line_to_list(path):
    stdout = readfile(path)
    return [x.strip() for x in stdout]


def process(command, deploy_path="/"):
    stdout = []
    stderr = []
    success = True

    try:
        pipe = Popen(command, stdout=PIPE, stderr=PIPE, shell=True, cwd=deploy_path)

        while True:
            line = pipe.stdout.readline()
    	    if line:
                    stdout.append(line.strip("\n"))
            else:
                line = pipe.stderr.readline()
                if line:
                    stderr.append(line.strip("\n"))
                else:
                    break
    except Exception:
        pass

    if len(stdout) <= 0 and len(stderr) > 0:
        success = False

    return success, stdout, stderr


def main():
    ap = argparse.ArgumentParser(description='A tool which use to spider video.')
    ap.add_argument('path', help='The urls path.')
    args = ap.parse_args()

    path = args.path
    data = parse_line_to_list(path)
    for url in data:
        cmd = 'youtube-dl -F {0}'.format(url)
        success, stdout, stderr = process(cmd, '/Users/sunjianchun/Downloads/youtube/music/split')
        print stdout


if __name__ == '__main__':
    main()
