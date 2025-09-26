#Copyright 2013 William Valdar
#This file is part of prephappy.

#prephappy is free software: you can redistribute it and/or modify
#it under the terms of the GNU General Public License as published by
#the Free Software Foundation, either version 3 of the License, or
#(at your option) any later version.

#prephappy is distributed in the hope that it will be useful,
#but WITHOUT ANY WARRANTY; without even the implied warranty of
#MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#GNU General Public License for more details.

#You should have received a copy of the GNU General Public License
#along with prephappy.  If not, see <http://www.gnu.org/licenses/>.

use strict;
package Debug;
use English;
use Exporter;
use Dumpvalue;
use FileIoHelper;

use base ('Exporter');
use vars qw(@EXPORT_OK @EXPORT);
@EXPORT_OK = qw( DumpObject DumpHere );
@EXPORT = qw(DumpObject DumpHere DumpSep);

my $ost = GetStdOut();

sub DumpHere()
{
    my($pkg, $file, $line) = caller();
    print $ost "Reached line $line [$file]\n";
}


sub DumpObject
{
    my $var = shift;
    my($pkg, $file, $line) = caller();
    print $ost "DumpObject() dumping from $file:$line\n";
    DumpValue($var);
    return 0;
}

sub DumpSep()
{
    print $ost "-" x 80, "\n";
}

sub DumpValue
{
    my $var = shift;
    my $oldFh = select $ost;
    (new Dumpvalue)->dumpValue($var);
    select $oldFh;
}

sub SetDumpStream($)
{
    $ost = shift;
    my $oldFh = select $ost;
    $OUTPUT_AUTOFLUSH = 1;
    select $oldFh;
}

1;
