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

package StdDefs;
use strict;
use vars qw( @ISA @EXPORT );
use Exporter;

@ISA = qw( Exporter );
@EXPORT = qw( true false null );

use constant true => 1;
use constant false => 0;
use constant null => '';

