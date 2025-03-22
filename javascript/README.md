# javascript

JavaScript code that supports my personal workflows.


## Overview

I don't quite have a vision for this, but I have a sense I want to use some JS-ecosystem tools like markdown-lint in my
workflows. Also, would this be the right place to my plugin code for things like Raycast, Obsidian and browser extensions?
I actually don't really think so, those might be better as their own directories/sub-projects.

I'm using webpack and Node.js, but not because I particularly favor them over the alternatives, but because I have the
most experience with them, and I've whittled their footprint down to an amount I'm comfortable and productive with. Don't
be tempted to faff around with trying other tools in this project. I need to write my own software.


## Wish List

General clean-ups, TODOs and things I wish to implement for this project:

* [ ] Bring back the markdown linter code/config I had and make a JS launcher. This means extending my Go-based
  launcher.
* [x] DONE Scaffold.
* [ ] Create "json-validator" program (its own distributable?) that communicates via clients on Unix domain socket.
   * Update: I don't care about this anymore... will probably delete.
* [ ] Consider splitting into independent subprojects. npm workspaces aren't quite there and I want to isolate the
  incidental (large) complexity like webpack from one project to the next. 
* [ ] Do something interesting with AJV.
* [ ] Consider porting over my Raycast plugin or at least the notes I have about it. I never really used this plugin.
  I think opening projects from the commandline or from within Intellij is good. But I feel that there has to be some
  plugin idea somewhere for me, however small.
