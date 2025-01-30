#!/bin/bash

for i in {0..3}; do
    for j in {0..3}; do
        id=$((4*i+j))
        id=$(printf "%03d" "${id}")
        mkdir ${id}_t
    done
done