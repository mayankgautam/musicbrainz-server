package t::MusicBrainz::Server::Data::NES::Artist;

use utf8;
use Test::Routine;
use Test::More;
use MusicBrainz::Server::Data::NES::Artist;

with 't::Context';

test 'Create artist' => sub {
    my $test = shift;

    my $editor = $test->c->model ('NES::Editor')->register (
        { 'name' => 'Bulbasaur', 'password' => 'pokemons' });

    my $artist_create = {
        'name' => '倖田 來未',
        'sort-name' => 'Koda Kumi',
        # 'country' => 1,
        # 'gender' => 1,
        'ended' => 0,
        'begin-date' => {
            'year' => 1982,
            'month' => 11,
            'day' => 13,
        }
        # 'type' => 1
    };

    my $inserted = $test->c->model ('NES::Artist')->create (
        $editor->id, $artist_create);

    ok ($inserted > 0, "Artist has a positive id");

    my $artist = $test->c->model ('NES::Artist')->get_by_revision ($inserted);

    is ($artist->name, "\x{5016}\x{7530} \x{4f86}\x{672a}", "Artist name consists of expected unicode code points");
    is ($artist->sort_name, "Koda Kumi", "Artist sort-name correct");
    is ($artist->begin_date->format, "1982-11-13");
    is ($artist->end_date->format, "");
    ok (!$artist->ended, "Artist is still alive");
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
