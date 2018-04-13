#!/usr/bin/python2.7
# -*- coding: utf-8 -*-

import json
import math

space_num =1
string = ""
file_directory = "./tmp1.txt"

def print_with_color(value):
    if value == "True":
        return "\033[0;32;46m%s\033[0m" % value
    elif value == "False":
        return "\033[0;31;46m%s\033[0m" % value
    else:
        return value


def get_max_length(keys=None):
    if keys is None:
        keys = []
    max_length = 0
    for key in keys:
        if len(list(str(key))) > max_length:
            max_length = len(list(str(key)))
    return max_length + space_num * 2


def get_single_decollator(max_length):
    return "+" + max_length * "-"


def get_single_value(value, max_length):
    #tmp = max_length - len(list(str(value)))
    #return "|" + int(math.floor((max_length - tmp - space_num) / 2)) * " " + str(value) + int(math.floor((max_length - tmp - space_num) / 2)) * " "
    return "|" + (max_length - len(list(str(value)))) * " " + print_with_color(str(value))


def get_cols_list(info, j):
    cols_list = []
    for i in xrange(0, len(info)):
        cols_list.append(info[i][j])

    return cols_list


def draw(info):
    string = ""
    for i in xrange(0, len(info)):
        for j in xrange(0, len(info[i])):
            max_length = get_max_length(get_cols_list(info, j))
            if j == len(info[i]) - 1:
                string = string + get_single_decollator(max_length) + "+\n"
            else:
                string = string + get_single_decollator(max_length)
        for j in xrange(0, len(info[i])):
            max_length = get_max_length(get_cols_list(info, j))
            if j == len(info[i]) - 1:
                string = string + get_single_value(info[i][j], max_length) + "|\n"
            else:
                string = string + get_single_value(info[i][j], max_length)
        if i == len(info) - 1:
            for j in xrange(0, len(info[i])):
                max_length = get_max_length(get_cols_list(info, j))
                if j == len(info[i]) - 1:
                    string = string + get_single_decollator(max_length) + "+\n"
                else:
                    string = string + get_single_decollator(max_length)
    return string


def format_data(data):
    info = []
    j = 0
    info = [[] for i in xrange(0, len(data.keys()) + 1)]
    for k1, v1 in data.items():
        j += 1
        info[j].append(k1)
        for v2 in v1:
            for k3, v3 in v2.items():
                info[j].append(v3)
    
    info[0].append("")
    
    for k1, v1 in data.items():
        for v2 in v1:
            for k3, v3 in v2.items():
                info[0].append(k3)
        break
    
    return info


if __name__ == '__main__':
    json_data=open(file_directory).read()
    data = json.loads(json_data)
    info = format_data(data)
    string = draw(info)
    print string
