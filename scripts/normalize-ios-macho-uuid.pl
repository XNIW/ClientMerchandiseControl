#!/usr/bin/env perl
use strict;
use warnings;

@ARGV == 1 && length $ARGV[0] or exit 1;
my $path = $ARGV[0];
open my $handle, "+<:raw", $path or exit 1;
my $file_size = -s $handle;
defined $file_size && $file_size >= 32 or exit 1;

read($handle, my $prefix, 8) == 8 or exit 1;
my $slice_offset = 0;
my $slice_size = $file_size;
if (substr($prefix, 0, 4) eq "\xcf\xfa\xed\xfe") {
  # Mach-O 64-bit little-endian già thin.
} elsif (substr($prefix, 0, 4) eq "\xca\xfe\xba\xbe") {
  my ($magic, $architecture_count) = unpack("NN", $prefix);
  $magic == 0xcafebabe && $architecture_count == 1 or exit 1;
  read($handle, my $architecture, 20) == 20 or exit 1;
  my ($cpu_type, undef, $offset, $size, undef) =
    unpack("NNNNN", $architecture);
  $cpu_type == 0x0100000c or exit 1;
  $offset >= 28 && $size >= 32 && $offset + $size == $file_size or exit 1;
  $slice_offset = $offset;
  $slice_size = $size;
} else {
  exit 1;
}

seek($handle, $slice_offset, 0) or exit 1;
read($handle, my $header, 32) == 32 or exit 1;
my ($thin_magic, $command_count, $commands_size) =
  unpack("Vx12VV", $header);
my $cpu_type = unpack("x4V", $header);
$thin_magic == 0xfeedfacf && $cpu_type == 0x0100000c or exit 1;
my $commands_start = $slice_offset + 32;
my $commands_end = $commands_start + $commands_size;
$commands_end <= $slice_offset + $slice_size or exit 1;

my $command_offset = $commands_start;
my $uuid_count = 0;
for (1 .. $command_count) {
  $command_offset + 8 <= $commands_end or exit 1;
  seek($handle, $command_offset, 0) or exit 1;
  read($handle, my $command_header, 8) == 8 or exit 1;
  my ($command, $size) = unpack("VV", $command_header);
  $size >= 8 && $command_offset + $size <= $commands_end or exit 1;
  if ($command == 0x1b) {
    $size == 24 or exit 1;
    seek($handle, $command_offset + 8, 0) or exit 1;
    print {$handle} "\0" x 16 or exit 1;
    $uuid_count += 1;
  }
  $command_offset += $size;
}
$command_offset == $commands_end && $uuid_count == 1 or exit 1;
close $handle or exit 1;
