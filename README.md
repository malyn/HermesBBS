# Hermes BBS #

Open source version of the Hermes BBS for Classic Mac OS (System 6 and
7) computers.  You will need a copy of THINK Pascal 4.0.2 in order to
compile Hermes.  The build environment is designed for a PowerPC-based
Mac OS X computer with a full Classic install.

See [the Hermes BBS web site](http://www.HermesBBS.com/) for more
information.

## Compilation ##

Open a Mac OS X terminal and type `./prepare.sh working`.  That will
create a Working directory with THINK Pascal project files, resource
files, and source files.  You can then build and edit the code in the
Working directory with THINK Pascal.

When you are ready to commit your changes, type `./prepare.sh source`.
That will copy changed source and resource files from Working back into
the Git source directory.  Note that the THINK Pascal project file will
not be copied as it changes on every build and rarely needs to be
checked in.  Actual changes to the project file can be prepared with
`./prepare.sh project`.

## Copyright and License ##

Copyright &copy; 1989-2013, Michael Alyn Miller <malyn@strangeGizmo.com>
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are
met:

1. Redistributions of source code must retain the above copyright notice
   unmodified, this list of conditions, and the following disclaimer.
2. Redistributions in binary form must reproduce the above copyright
   notice, this list of conditions and the following disclaimer in the
   documentation and/or other materials provided with the distribution.
3. Neither the name of Michael Alyn Miller nor the names of the
   contributors to this software may be used to endorse or promote
   products derived from this software without specific prior written
   permission.

THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS "AS IS" AND ANY
EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE
LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
THE POSSIBILITY OF SUCH DAMAGE.
