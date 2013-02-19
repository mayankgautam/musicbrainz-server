package MusicBrainz::Server::Controller::Role::Create;
use MooseX::Role::Parameterized -metaclass => 'MusicBrainz::Server::Controller::Role::Meta::Parameterizable';

use MusicBrainz::Server::NES::Controller::Utils qw( create_edit );

parameter 'form' => (
    isa => 'Str',
    required => 1
);

parameter 'model' => (
    isa => 'Str',
    required => 1
);

role {
    my $params = shift;
    my %extra = @_;

    requires 'tree';

    my %attrs = (
        RequireAuth => undef,
        Edit => undef,
        Local => undef,
    );

    $extra{consumer}->name->config(
        action => {
            create => \%attrs
        }
    );

    method 'create' => sub {
        my ($self, $c) = @_;

        create_edit(
            $self, $c,
            form => $params->form,
            on_post => sub {
                my ($values, $edit) = @_;

                return $c->model($params->model)->create(
                    $edit, $c->user,
                    $self->tree($values)
                );
            }
        );
    };
};

1;
