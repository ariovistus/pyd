module meta.Util;

import std.conv;

template itoa(int i) {
    enum itoa = to!string(i);
}
