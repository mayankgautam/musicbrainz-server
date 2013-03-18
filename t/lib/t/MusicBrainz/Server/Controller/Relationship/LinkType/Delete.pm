package t::MusicBrainz::Server::Controller::Relationship::LinkType::Delete;
use Test::Routine;
use Test::More;
use MusicBrainz::Server::Test qw( capture_edits html_ok );

use HTTP::Request::Common qw( POST );

around run_test => sub {
    my ($orig, $test, @args) = @_;
    $test->c->sql->do(<<'EOSQL');
INSERT INTO editor (id, name, password, email, privs, ha1) VALUES (1, 'editor1', '{CLEARTEXT}pass', 'editor1@example.com', 255, '16a4862191803cb596ee4b16802bb7ee')
EOSQL

    $test->mech->get('/login');
    $test->mech->submit_form( with_fields => { username => 'editor1', password => 'pass' } );

    $test->$orig(@args);
};

with 't::Mechanize', 't::Context';

test 'Delete an artist-artist link type' => sub {
    my $test = shift;
    my $mech = $test->mech;

    $test->c->sql->do(<<'EOSQL');
INSERT INTO link_type (id, gid, entity_type0, entity_type1, name,
    link_phrase, reverse_link_phrase, short_link_phrase)
  VALUES (1, '77a0f1d3-f9ec-4055-a6e7-24d7258c21f7', 'artist', 'artist',
          'member of band', 'lt', 'r', 's');
EOSQL

    $mech->get_ok('/relationship/77a0f1d3-f9ec-4055-a6e7-24d7258c21f7/delete');
    my @edits = capture_edits {
        $mech->request(POST $mech->uri, [ 'confirm.submit' => 1 ]);
        ok($mech->success);
    } $test->c;

    is(@edits, 1);
    isa_ok($edits[0], 'MusicBrainz::Server::Edit::Relationship::RemoveLinkType');
    my $data = $edits[0]->data;

    is($data->{link_type_id}, 1, 'edits correct link type');
};

1;
