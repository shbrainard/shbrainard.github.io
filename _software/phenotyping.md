---
title: "High-throughput phenotyping tools"
collection: software
permalink: /software/high-throughput-phenotyping
---

Python software for high-throughput digital image acquisition, pre-processing, and phenotyping of plant organs. 

This software was originally designed to phenotype carrots, as described in [this](https://shbrainard.github.io/publication/2021-06-16_FIPS) paper.  It makes uses of a standardized image format to automate image acquisition, utilizing QR codes to handle file management, and objects of known physical size to convert pixels to spatial resolution.  The OpenCV library is used to subsequently convert RGB images to binary masks, and measure various physical traits, which can be written to a MongoDB collection, or exported as CSV files.  It is now primarily used for phenotyping hazelnuts: [https://github.com/shbrainard/hazelnut-phenotyping](https://github.com/shbrainard/hazelnut-phenotyping)