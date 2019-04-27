#!/bin/bash
pkgutil --only-files --files org.bug400.asm71 | sed 's!^!rm -i /!' 
echo "rm -d -i /usr/local/share/doc/asm71"
echo "rm -d -i /usr/local/share/asm71"
echo "pkgutil --forget org.bug400.asm71" 
