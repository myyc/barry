#!/bin/sh
rm -rf *.love
zip -9 -x '*.piko' *.sh *.DS_Store -r barry.love .
