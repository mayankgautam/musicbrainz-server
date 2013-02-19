package MusicBrainz::Server::Controller::Role::Edit;
use MooseX::Role::Parameterized -metaclass => 'MusicBrainz::Server::Controller::Role::Meta::Parameterizable';

use MusicBrainz::Server::NES::Controller::Utils qw( create_update );

parameter 'form' => (
    isa => 'Str',
    required => 1
);

role {
    my $params = shift;
    my %extra = @_;

    requires 'tree';

    $extra{consumer}->name->config(
        action => {
            edit => { Chained => 'load', RequireAuth => undef, Edit => undef }
        }
    );

    method edit => sub {
        my ($self, $c) = @_;
        create_update(
            $self, $c,
            form => $params->form,
            subject => $c->stash->{entity},
            build_tree => sub { $self->tree(@_) }
        );
    }
};

1;
