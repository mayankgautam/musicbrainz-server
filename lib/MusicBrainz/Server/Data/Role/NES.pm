package MusicBrainz::Server::Data::Role::NES;
use Moose::Role;

with 'MusicBrainz::Server::Data::Role::Context';

use Devel::Dwarn;
use Encode;
use JSON;
use Try::Tiny;

sub request {
    my ($self, $path, $body) = @_;

    my $uri = DBDefs->DATA_ACCESS_SERVICE.$path;
    my $content = to_json ($body, { pretty => 1, canonical => 1 });

    my $response = $self->c->lwp->post($uri, Content => encode('utf8', $content));

    return try {
        my $response = decode_json($response->content);
        use Devel::Dwarn; Dwarn $response;
        return $response;
    }
    catch {
        die 'Failed to decode response: ' . $response->content;
    }
}

1;
