package t::MusicBrainz::Server::Data::NES::Editor;

use utf8;
use Test::Routine;
use Test::More;
use MusicBrainz::Server::Data::NES::Editor;

with 't::Context';

test 'Register editor' => sub {
    my $test = shift;

    my $editor_form = {
        'name' => '박 상수',
        'password' => 'IchGofEnckucFibrajFecepNooHyfsUv',
    };

    my $editor = $test->c->model ('NES::Editor')->register ($editor_form);

    isa_ok ($editor, 'MusicBrainz::Server::Entity::Editor');
    is ($editor->name, '박 상수', "Editor has expected name");
    ok ($editor->id > 0, "Editor has a positive id");
};

1;

=head1 COPYRIGHT

Copyright (C) 2012 MetaBrainz Foundation

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

=cut
