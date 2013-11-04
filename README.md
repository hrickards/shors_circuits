Shor's Circuits
===============
Symbolic simulation of quantum circuits, as seen at [shorscircuits.com](http://shorscircuits.com).

To try out, run
* Import example data with `bundle exec padrino rake data:import`
* Register for oauth access at Google, Twitter, Github & Facebook, and put the keys and secrets into `config/application.yml` (see `config/application.yml.sample`)
* Start the server with `padrino start`
* Open the app at `localhost:3000`

Requirements
------------
(Package names given are for Debian wheezy)
* Python 2.7 with sympy (`python2.7` and `python-sympy`)
* pdf2svg (`pdf2svg`)
* pdfcrop (`texlive-extra-utils`)
* pdflatex with QCircuit (install `texlive` and `texlive-pictures`, and create `/etc/texmf/tex/plain` and put `Qcircuit.tex` in it)
* inkscape (SVG to PNG) (`inkscape`)
* Ruby with gems in Gemfile
* Redis & Mongo
