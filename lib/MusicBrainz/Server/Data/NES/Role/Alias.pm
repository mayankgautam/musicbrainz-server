package MusicBrainz::Server::Data::NES::Role::Alias;
use Moose::Role;

requires 'scoped_request';

sub get_aliases {
    my ($self, $work) = @_;
    my $response = $self->scoped_request('/view-aliases', {
        revision => $work->revision_id
    });
    return [
        map {
            MusicBrainz::Server::Entity::Alias->new(
                name => $_->{name},
                sort_name => $_->{'sort-name'},
                locale => $_->{locale},
                type_id => $_->{type},
                begin_date => MusicBrainz::Server::Entity::PartialDate->new($_->{'begin-date'}),
                end_date => MusicBrainz::Server::Entity::PartialDate->new($_->{'end-date'}),
                ended => $_->{ended},
                primary_for_locale => $_->{'primary-for-locale'}
            )
        } @$response
    ]
}

1;
