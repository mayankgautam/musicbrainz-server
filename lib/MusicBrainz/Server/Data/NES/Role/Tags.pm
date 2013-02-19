package MusicBrainz::Server::Data::NES::Role::Tags;
use MooseX::Role::Parameterized;

parameter 'model' => (
    required => 1
);

role {
    my $params = shift;

    method tags => sub {
        my $self = shift;
        return $self->c->model($params->model)->tags;
    };
};

1;
