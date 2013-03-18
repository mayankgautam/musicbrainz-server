package t::MusicBrainz::Server::Controller::Edit::Relationship::Delete;
use Test::Routine;
use Test::More;
use MusicBrainz::Server::Test qw( capture_edits html_ok );

with 't::Context', 't::Mechanize';

test 'Test deleting a relationship' => sub {
    my $test = shift;
    my $c = $test->c;
    my $mech = $test->mech;

    $c->sql->do(<<'EOSQL');
INSERT INTO label_name (id, name) VALUES (1, 'label 1');
INSERT INTO label (id, gid, name, sort_name)
    VALUES (1, '8900d437-6cc7-4b4c-bdd3-e83634c128df', 1, 1);

INSERT INTO url (id, gid, url)
    VALUES (1, '1900d437-6cc7-4b4c-bdd3-e83634c128df', 'http://www.myspace.com/lizardopenmind');

INSERT INTO link_type (id, gid, entity_type0, entity_type1, name, link_phrase,
                       reverse_link_phrase, short_link_phrase, description)
    VALUES (1, '7610b0e9-40c1-48b3-b06c-2c1d30d9dc3e', 'label', 'url',
            'myspace', 'myspace', 'myspace', 'myspace', 'myspace');
INSERT INTO link (id, link_type, attribute_count) VALUES (1, 1, 0);
INSERT INTO l_label_url (id, entity0, entity1, link) VALUES (1, 1 , 1, 1);

INSERT INTO editor (id, name, password, privs, email, website, bio, email_confirm_date, member_since, last_login_date, edits_accepted, edits_rejected, auto_edits_accepted, edits_failed, ha1) VALUES (1, 'new_editor', '{CLEARTEXT}password', 0, 'test@editor.org', 'http://musicbrainz.org', 'biography', '2005-10-20', '1989-07-23', '2009-01-01', 12, 2, 59, 9, 'e1dd8fee8ee728b0ddc8027d3a3db478');
EOSQL

    $mech->get_ok('/login');
    $mech->submit_form( with_fields => { username => 'new_editor', password => 'password' } );

    $mech->get_ok('/edit/relationship/delete?type1=url&type0=label&id=1');
    my @edits = capture_edits {
        $mech->submit_form(
            with_fields => {
                'confirm.edit_note' => ''
            }
        );
    } $c;

    is(@edits, 1);
    my ($edit) = @edits;

    isa_ok($edit, 'MusicBrainz::Server::Edit::Relationship::Delete');
    is($edit->data->{relationship}{id}, 1);
};

1;
