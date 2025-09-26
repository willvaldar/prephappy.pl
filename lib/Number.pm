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

#!./perl
package Number;
use strict;
use English;

sub IsEven($)
{
    return IsOdd($ARG[0]) ? 0 : 1;
}

sub IsOdd($)
{
    return ($ARG[0] % 2) ? 1 : 0;
}

1;


