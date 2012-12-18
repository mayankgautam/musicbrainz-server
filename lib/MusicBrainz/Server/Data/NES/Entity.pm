package MusicBrainz::Server::Data::NES::Entity;
use Moose;

with 'MusicBrainz::Server::Data::Role::Context';

sub _entity_class
{
    die("Not implemented");
}

sub _field_mapping
{
    return {};
}


sub new_from_service
{
    my ($self, $response, $field) = @_;

    return unless $response;

    my %data = %{ $response->{$field} };
    my %info;
    my %mapping = %{$self->_field_mapping};

    foreach my $key (keys %data)
    {
        my $attrib = $mapping{$key} // $key;
        my $val;
        if (ref($attrib) eq 'CODE') {
            $val = $attrib->(\%data, $key);
        }
        elsif (defined $data{$key}) {
            $val = $data{$key};
        }
        $info{$attrib} = $val if defined $val;
    }

    my $entity_class = $self->_entity_class(\%data);
    Class::MOP::load_class($entity_class);

    return $entity_class->new(%info);
}

sub new_from_response
{
    my ($self, $response) = @_;

    return unless $response;

    for my $key (grep { $_ ne 'data' } keys %$response)
    {
        $response->{data}->{$key} = $response->{$key};
    }

    return $self->new_from_service ($response, 'data');
}


__PACKAGE__->meta->make_immutable;
no Moose;
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
