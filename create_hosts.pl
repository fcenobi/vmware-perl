#!/usr/bin/env perl

=head1 NAME

create_hosts.pl

=head1 SYNOPSIS

./create_hosts.pl --file hosts

=head1 ARGUMENTS

=over

=item --help

Show the arguments for this program.

=item --file

Select an output file. B<Warning:> The file will be clobbered.

=back

=head1 DESCRIPTION

Output an /etc/hosts style file from Virtual Center.

=head1 SEE ALSO

L<VMware Perl SDK|http://www.vmware.com/support/developer>

=head1 AUTHOR

Jonathan Barber - <jonathan.barber@gmail.com>

=cut

use strict;
use warnings;
use Data::Dumper;
use VMware::VIRuntime;

$Util::script_version = "1.0";

my %opts = (
	file => {
		type => "=s",
		help => "Output path, don't specify for standard out",
		required => 0,
	},
);

# read/validate options and connect to the server
Opts::add_options(%opts);
Opts::parse();
Opts::validate();
Util::connect();

my $fh = \*STDOUT;
{
	my $file = Opts::get_option('file');
	if ($file) {
		open $fh, ">$file" or die $!;
	}
}

# Get all VMs
my $vms = Vim::find_entity_views(
	view_type => 'VirtualMachine',
);

# Iterate over the VMs, printing their info
foreach my $vm (@{ $vms }) {
	my $powerStat = $vm->runtime->powerState->val;

	unless (defined $vm->guest->toolsStatus) {
		print $fh "# Don't know IP of: ", $vm->name, ": No Tools (power: $powerStat)\n";
		next;
	}

	if ($vm->guest) {
		my $nics = $vm->guest->net;
		unless ($nics) {
			print $fh "# No NICs for ", $vm->name,"\n";
			next;
		}
		for my $nic (@{ $vm->guest->net }) {
			my @names = keys %{ { map { $_ => 1 } ($vm->name, $vm->guest->hostName || ()) } };
			unless ($nic->ipAddress) {
				print $fh "# No IP address on NIC for ", $vm->name, "\n";
				next;
			}
			for my $ip (@{$nic->ipAddress}) {
				print $fh join(" ", $ip, @names), "\n";
			}
		}
	}
	else {
		print $fh "# VMware tools not available on ", $vm->name, ", tools status is", $vm->guest->toolsStatus->val, " (power: $powerStat)\n";
	}
}

Util::disconnect();
