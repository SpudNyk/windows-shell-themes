# -*- coding: utf-8 -*-
"""
    gen_theme
    ~~~~~~~~~

    ConEmu theme generator

    :copyright: (c) 2015 - 2016 by Radmon.
"""

import re
# This is a demo color scheme
palette = [
'#2d2a2e', # Black
'#fc9867', # DarkBlue
'#a9dc76', # DarkGreen
'#78dce8', # DarkCyan
'#ff6188', # DarkRed
'#ab9df2', # DarkMagenta
'#ffd866', # DarkYellow
'#fcfcfa', # Gray
'#727072', # DarkGray
'#fc9867', # Blue
'#a9dc76', # Green
'#78dce8', # Cyan
'#ff6188', # Red
'#ab9df2', # Magenta
'#ffd866', # Yellow
'#fcfcfa', # White
]

line = '<value name="ColorTable{0:02}" type="dword" data="00{3}{2}{1}"/>'


def get_rgb(color):
    m = re.match(r'#([0-9a-fA-F]{2})([0-9a-fA-F]{2})([0-9a-fA-F]{2})', color)
    if m is None:
        raise RuntimeError('Invalid color: %s' % color)
    else:
        return m.groups()


def gen_theme():
    for i in range(0, len(palette)):
        color = palette[i]
        r, g, b = map(lambda x: x.lower(), get_rgb(color))
        yield line.format(i, r, g, b)


if __name__ == '__main__':
    out = '\n'.join(gen_theme())
    print(out)
