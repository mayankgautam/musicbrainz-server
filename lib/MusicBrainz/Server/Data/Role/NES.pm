package MusicBrainz::Server::Data::Role::NES;
use MooseX::Role::Parameterized;

with 'MusicBrainz::Server::Data::Role::Context';

parameter root => (
    required => 1
);

role {
    my $params = shift;

    method scoped_request => sub {
        my ($self, $path, @args) = @_;
        $self->request($params->root . $path, @args)
    };

    method request => sub {
        my $self = shift;
        return $self->c->nes->request(@_);
    };
};

1;
