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
* Python 2.7 with sympy
* pdf2svg
* pdfcrop (`texlive-extra-utils`)
* pdflatex with QCircuit
* inkscape (SVG to PNG)
* Ruby with gems in Gemfile
* Redis & Mongo
