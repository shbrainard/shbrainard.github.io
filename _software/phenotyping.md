---
title: "High-throughput phenotyping tools"
collection: software
permalink: /software/high-throughput-phenotyping
---

Python software for high-throughput digital image acquisition, pre-processing, and phenotyping of plant organs. 

This software was originally designed to phenotype carrots, as described in [this](https://shbrainard.github.io/files/publications/2021FIPS.pdf) paper.  

It makes uses of a standardized image layout to automate image acquisition, utilizing QR codes to handle file management, and features of known physical size to convert pixels to spatial resolution.  

The [OpenCV](https://pypi.org/project/opencv-python/) library is used to subsequently convert RGB images to binary masks, and measure various physical traits, which can be written to a MongoDB collection, or exported as CSV files.  It is now primarily used for phenotyping hazelnuts: [https://github.com/shbrainard/hazelnut-phenotyping](https://github.com/shbrainard/hazelnut-phenotyping).

This software was developed in collaboration with [Julian Bustamante](https://github.com/jbustamante35), a graduate student in the [Spalding Lab](https://spalding.botany.wisc.edu/) at the University of Wisconsin-Madison, and [Christoph Reimers](https://github.com/creimers), inventor of the [skateboard trivet](https://www.lockengeloet.com/fuer-die-kueche/topfuntersetzer/topfuntersetzer).