# Compofiller Studio 1.1.0
[![Build](https://github.com/tahtituho/compofillerstudio/actions/workflows/build.yml/badge.svg)](https://github.com/tahtituho/compofillerstudio/actions/workflows/build.yml)

"IDE" for making Windows 4k intros  
by Yzi, helgrima

This readme updated: 2026-11-13

## Benefits

- Create Windows .exe from GLSL shader and 4klang music
- No C/C++ or x86 coding needed
- No Visual Studio needed
- Ready-made templates, but you can customize everything

## Components

Compofiller Studio is a bundling of components from several people and projects.

### Main folder

- Windows "IDE" application and make/build system written in FPC/Lazarus (Object Pascal)  
  by Yrjö Fager (Yzi/Fit)

### Templates folder

- x86 intro runtime framework (x86 assembly code) and template build scripts  
  by Yrjö Fager (Yzi/Fit)

### Resources folder

- default_music: Ableton Live project and 4klang patch bank for the default music  
  by Yrjö Fager (Yzi/Fit)

### Tools folder

- Shader Minifier 1.6.1 <https://github.com/laurentlb/shader-minifier>
  by Laurent Le Brun (LLB/Ctrl-Alt-Test) 
- Crinkler compressing linker 3.0b <https://github.com/runestubbe/Crinkler>
  by Rune L. H. Stubbe (Mentor/TBC) and Aske Simon Christensen (Blueberry/Loonies)
- NASM assembler 3.02
- GNU ld linker 2.38

Not really bundled as such, but Compofiller Studio is meant to work with:

- 4klang, "Alcatraz Software Synthesizer"  
  by Dominik Ries (Gopher/Alcatraz) and Paul Kraus (pOWL/Alcatraz)

See each individual folder for licensing information.

## License for parts made by Yzi

Copyright 2018 Yrjö Fager

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

<http://www.apache.org/licenses/LICENSE-2.0>

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

## How to build

To build Compofiller Studio from source code, you'll need:

- Lazarus 4.8 <https://www.lazarus-ide.org/>
- FPC 3.2.2
- TRichMemo component, install from Online Package Manager, search for `richmemo`
- Set Lazarus to use 32 bit FPC
