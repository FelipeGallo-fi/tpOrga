#!/bin/bash

BUILD_DIR=build

rm -rf $BUILD_DIR
mkdir -p $BUILD_DIR
cmake -S . -B $BUILD_DIR
cmake --build $BUILD_DIR
./build/DisplayImage ./Casa.jpg
cd ..