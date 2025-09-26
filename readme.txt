Compofiller Studio 1.0
"IDE" for making Windows 4k intros
by Yzi

This readme updated: 2018-11-27



Benefits
* Create Windows .exe from GLSL shader and 4klang music
* No C/C++ or x86 coding needed
* No Visual Studio needed
* Ready-made templates, but you can customize everything

Missing features in version 1.0 (see changes.txt for wish list)
* Built-in support for other intro music engines than 4klang (or Forked Klang)
* (1k intro support ... I don't know yet how to do 1k music without requiring C/C++ or x86 coding skills)
* (Easier DAW-less music creation)



== COMPONENTS ==

Compofiller Studio is a bundling of components from several people and projects.

Main folder:
* Windows "IDE" application and make/build system written in FPC/Lazarus (Object Pascal)
	by Yrj� Fager (Yzi/Fit)

Templates folder:
* x86 intro runtime framework (x86 assembly code) and template build scripts
	by Yrj� Fager (Yzi/Fit)
	
Resources folder:
* default_music: Ableton Live project and 4klang patch bank for the default music (by Yzi)

Tools folder: 
* Shader Minifier 
	by Laurent Le Brun (LLB/Ctrl-Alt-Test)
* Crinkler compressing linker 
	by Rune L. H. Stubbe (Mentor/TBC) and Aske Simon Christensen (Blueberry/Loonies)
* NASM assembler
* GNU ld linker

Not really bundled as such, but Compofiller Studio is meant to work with
* 4klang, "Alcatraz Software Synthesizer"
	by Dominik Ries (Gopher/Alcatraz) and Paul Kraus (pOWL/Alcatraz)


See each individual folder for licensing information.


== LICENSE FOR PARTS MADE BY YZI ==

Copyright 2018 Yrj� Fager

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.




== HOW TO BUILD ==

To BUILD Compofiller Studio from source code, you'll need:

* Lazarus 4.8 https://www.lazarus-ide.org/
* TRichMemo component, install from Online Package Manager, search for richmemo


