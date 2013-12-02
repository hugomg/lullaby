#! /bin/bash
set -e

busted -l lua5.2 test.lua
busted -l lua5.1 test.lua
busted -l luajit test.lua

echo '*************************'
echo '* All tests successful! *'
echo '*************************'
